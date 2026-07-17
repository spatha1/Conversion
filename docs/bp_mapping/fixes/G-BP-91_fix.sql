-- G-BP-91 (new, self-identified) — CV sub-coverage premium-join fan-out
-- CV_COVERAGE_VEHICLE_SUBCOV (SEQ 62) — same bug class as G-BP-81 (Building BG), different LOB.
--
-- Found while verifying G-BP-90's fix in the final AGGNE.UAT.POLICY_MIGRATION_DCT.REQUEST_XML
-- output: after G-BP-90 correctly isolated each vehicle's own key, a broad sample of vehicle
-- payloads still showed duplicate <Code> sub-coverage blocks WITHIN a single vehicle's own XML
-- (e.g. two <Code>CMULG_SD</Code> blocks with different <iValue>/<Premium> in one vehicle).
--
-- Root cause: SEQ 62's SUB_COV_EXP_PRM CTE reads AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP
-- (WHERE sub_coverage LIKE 'CM%') and the final SELECT LEFT JOINs it onto CM_BASE keyed only on
-- (POLICYNUMBER, cmlnumber, CMCODE) -- NOT vehicleid or expiringid_p, because this premium table
-- is genuinely policy-level, not vehicle-level. VW_OUTPUT_SUBCOVERAGE_BSP has DUPLICATE rows for
-- some (policy, cml, sub_coverage) keys -- confirmed live, policy P00023483/CML00022885/CMULG_SD
-- has two rows, EXPPREMIUM 2635.00 and 71.00 -- so the LEFT JOIN fans out, and EVERY vehicle at
-- that policy/cml gets duplicated for that sub-coverage code. This bug predates G-BP-90 and was
-- always in this view; it was simply invisible before because the much larger cross-vehicle
-- contamination bug swamped it. G-BP-88 and the original ATP-10947 Building fixes (G-BP-76 thru
-- 82) already established this exact "duplicate premium rows fan out the LEFT JOIN" pattern
-- against the same underlying VW_OUTPUT_SUBCOVERAGE_BSP-family tables -- G-BP-81 fixed it for
-- Building BG with the identical technique used below.
--
-- Live impact (2026-07-12): 4,392 of the (policy,cml,sub_coverage) keys in
-- VW_OUTPUT_SUBCOVERAGE_BSP (WHERE sub_coverage LIKE 'CM%') have duplicate premium rows,
-- affecting 1,939 distinct policies. Sampled 3,000 random BP_CV_vehicle_Cov vehicle rows post
-- G-BP-90: ~41% had a duplicate <Code> block traceable to this fan-out (the remainder traced to
-- the separate, already-documented G-BP-06 staging dedup issue in cm_03 itself, unrelated to
-- this view).
--
-- Fix: pre-aggregate SUB_COV_EXP_PRM with SUM(EXPPREMIUM) grouped by (POLICYNUMBER, CMLNUMBER,
-- SUB_COVERAGE) before joining -- verified live this collapses to exactly 1 row per key
-- (35,268 aggregated rows == 35,268 distinct keys). Only this one CTE changes; CM_BASE and the
-- rest of the view are unchanged from the current (G-BP-90-hotfixed) live definition.
--
-- Scope: SEQ 62 (CV_COVERAGE_VEHICLE_SUBCOV) only. Does not touch SEQ 63/64/65/66/67 -- none of
-- those join VW_OUTPUT_SUBCOVERAGE_BSP directly.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.

create or replace view CV_COVERAGE_VEHICLE_SUBCOV(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	POLICYNUMBER,
	EXPIRINGID_P,
	VEHICLEID,
	PROTECTIONTYPE,
	CMTYPE,
	CMCODE,
	EXPPREMIUM,
	ACCESSORIESVALUE
) as
with base as (SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, protectiontype, NVL(CAST(cmcvagreedvalue AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
UNION ALL
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, 'choiceofrepair' AS protectiontype, NVL(CAST(cmcvchoicerepair AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
UNION ALL
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, 'OnHookTowingProtection' AS protectiontype, NVL(CAST(cmcvcoverhookliab AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
union all
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, 'HireCarHireAfterIncident' AS protectiontype, NVL(CAST(cmcvcarhire AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
union all
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, 'ExcessWaiverForGlass' AS protectiontype, NVL(CAST(cmcvunlimglass AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03),
-- FIX (G-BP-91): pre-aggregate with SUM(EXPPREMIUM) grouped by the join key, so the LEFT JOIN
-- below can never fan out even if VW_OUTPUT_SUBCOVERAGE_BSP has duplicate premium rows.
SUB_COV_EXP_PRM AS (
    SELECT TRIM(POLICYNUMBER) AS POLICYNUMBER, TRIM(CMLNUMBER) AS CMLNUMBER, SUB_COVERAGE,
           SUM(EXPPREMIUM) AS EXPPREMIUM
    FROM AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP
    WHERE SUB_COVERAGE LIKE 'CM%'
    GROUP BY 1,2,3
),
CM_BASE AS (select  CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) ||'|' || TRIM(vehicleid) AS VARCHAR) AS purepolicynumber,cmlnumber,PUREPOLICYNUMBER AS POLICYNUMBER,expiringid_p,vehicleid,CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'Comprehensive Property'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'Comprehensive Property'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'Fire &amp; Theft excluding Liability'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'On Hook Liability'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'Unlimited Glass'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'Third Party Only'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'Third Party Fire &amp; Theft'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'Choice of Repairer'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'Car Hire'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'Comprehensive Liability'
            end as PROTECTIONTYPE ,
CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'CMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'CMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'FTL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'OHL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'ULG_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'TPO_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'TFT_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'COR_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'PCH_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'LIA_SD'
                ELSE ''
            END AS CMTYPE,CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'CMCMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'CMCMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'CMFTL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'CMOHL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'CMULG_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'CMTPO_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'CMTFT_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'CMCOR_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'CMPCH_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'CMLIA_SD'
                ELSE ''
            END AS CMCODE,NVL(CAST(marketvaluewithoutaccessories AS VARCHAR),0) AS accessoriesvalue from base)
SELECT purepolicynumber,A.cmlnumber,A.POLICYNUMBER,A.expiringid_p,vehicleid,PROTECTIONTYPE,CMTYPE,CMCODE,CAST(EXPPREMIUM AS VARCHAR) AS EXPPREMIUM,accessoriesvalue FROM CM_BASE A
left join SUB_COV_EXP_PRM B ON TRIM(A.POLICYNUMBER) = TRIM(B.POLICYNUMBER)
AND TRIM(A.cmlnumber) = TRIM(B.cmlnumber)
AND TRIM(A.CMCODE) = TRIM(B.sub_coverage);

-- ============================================================
-- POST-CHECK 1: no more duplicate CMCODE within a single vehicle's SEQ62 rows
-- (excluding the small set of vehicles affected by the separate, already-known G-BP-06 staging
-- dedup issue in cm_03 itself -- that one is a different root cause, not fixed by this script)
-- ============================================================
-- SELECT PUREPOLICYNUMBER, CMCODE, COUNT(*) FROM AGGNE.DEV.CV_COVERAGE_VEHICLE_SUBCOV
-- GROUP BY 1,2 HAVING COUNT(*) > 1;
-- Expect this to only return rows for vehicleids with >1 raw cm_03 row (the G-BP-06 population),
-- not the 1,939 policies newly fixed here.

-- POST-CHECK 2: spot check the exact example from the diagnosis
-- SELECT PUREPOLICYNUMBER, PROTECTIONTYPE, CMCODE, EXPPREMIUM FROM AGGNE.DEV.CV_COVERAGE_VEHICLE_SUBCOV
-- WHERE PUREPOLICYNUMBER = 'P00023483|CML00022885|2519919|1751293';
-- Expect exactly 5 rows (one per protection-type branch), CMULG_SD EXPPREMIUM=2706.000000000000
-- (2635+71 summed), CMCMP_SD EXPPREMIUM=73244.666666670000 (642+72602.666666670000 summed).
