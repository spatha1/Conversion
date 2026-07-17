-- ============================================================================
-- G-BP-73 fix — ATP-10775 minimum-value enforcement ("Standard Protection"
-- limit fields must never go below DC's UI minimum, or migration FAILS)
-- ============================================================================
-- Client instruction (2026-07-11), ATP-10775: "Policy Conversion - Current
-- policies that will fail migration due to field restriction in UI -
-- Business Contents, Burglary, Business Interruption, Money." Description:
-- "Limits fields for coverages have minimum LOP set up on UI causing
-- migration failures." This is a hard DC import validation, not a display
-- preference — sending a value below the stated minimum (including $0/blank)
-- can make the whole policy fail to migrate.
--
-- Client-provided minimums (5 fields):
--   Total Annual Turnover (Business Details)         min $50,000  -- NOT YET CHECKED, different SEQ area
--   Contents Limit (Business Contents STD_SD)         min $30,000  -- NOT YET CHECKED, BC coverage not reached yet
--   Contents/Stock/EmployeeTools Limit (Burglary EMP_SD) min $10,000 -- FIXED HERE
--   Annual Gross Profit (BI GRP_SD)                   min $30,000  -- FIXED HERE
--   Money on premises during business hours (MSB_SD)  min $2,000   -- ALREADY COMPLIANT, see note below
--
-- G-BP-04 RETRACTED: the previously-drafted fix (docs/bp_mapping/fixes/G-BP-04_fix.sql)
-- would have made MSB_SD blank at $0/NULL, which is exactly the failure mode
-- ATP-10775 describes. Checked live: RISK_BUILDING_MONEY_COVERAGES's existing
-- hardcoded "0 -> 2000" already satisfies the $2,000 minimum (0 of 1,339 rows
-- below $2,000) — this was apparently a deliberate workaround for this same
-- DC restriction, not a bug. DO NOT APPLY G-BP-04_fix.sql.
--
-- Live compliance check (2026-07-11), before this fix:
--   EMP_SD/STD_SD/TFT_SD(NZ) shared source CONTENTSSTOCKEMPLOYEETOOLSLIMIT
--     (Location_BG_Coverage, 13,440 rows): 118 rows = $0/NULL, 7 rows between
--     $1-$9,999 -> 125 of 13,440 (0.93%) below the $10,000 minimum.
--   GRP_SD/CY/EQ/ST/BF shared source ANNUALGROSSPROFIT
--     (Location_BI_Coverage, EXPIRYDATE>='2026-01-01', 6,708 rows): 6 rows
--     output literal '0' in BUILDING_BI_PAYLOAD -> 6 of 6,708 (0.09%) below
--     the $30,000 minimum.
--
-- Scope: view-only, two views. No config change — both SEQ 38's and SEQ 37's
-- configs already reference the generic tokens.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 (Snowflake) — RISK_BUILDING_BG_COVERAGES: floor STD_SD/EMP_SD/
-- TFT_SD(NZ) to $10,000. Built on top of the already-live G-BP-01 fix
-- (TFT_SD's NZ country-conditional branch) — only STD_SD, EMP_SD, and the NZ
-- half of TFT_SD change; everything else (ALC_SD/CUV_SD/MFL_SD/PER_SD/
-- MVH_SD/TOB_SD/ETH_SD/TFT_SD-Australia) is untouched.
-- Re-pull GET_DDL immediately before applying and diff against this.
-- ---------------------------------------------------------------------------

create or replace view RISK_BUILDING_BG_COVERAGES(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	CMLNUMBER,
	COVERAGE,
	COVERAGETYPE,
	DESCRIPTION,
	TYPE,
	CODE,
	IVALUE,
	SVALUE,
	EXCESSINFO,
	EXTRAINFO,
	EXP_PREM,
	INDICATOR
) as -- ── ALC_SD : Alcohol ─────────────────────────────────────────
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BG' AS CoverageType,
    'Alcohol' AS Description,
    'ALC_SD' AS Type,
    'BGALC_SD' AS Code,
    CAST(CAST(ALCOHOLLIMIT AS NUMBER(10, 0)) AS VARCHAR) AS iValue,
    '' AS sValue,
    CONCAT(
        '<Excess>',
        '<CustomerVehicles/>',
        '<Imposed/>',
        '<Standard/>',
        '<Voluntary>',
        CAST(
            CAST(COALESCE(VOLUNTARYEXCESS, 0) AS NUMBER(10, 0)) AS VARCHAR
        ),
        '</Voluntary>',
        '<Amount/>',
        '</Excess>'
    ) AS EXCESSINFO,
    '' AS EXTRAINFO,
    CASE
        WHEN SUB_COVERAGE = 'BGALC_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END AS EXP_PREM,
    CASE
        WHEN COALESCE(ALCOHOLLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END AS INDICATOR
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGALC_SD'
UNION ALL
    -- ── CUV_SD : Customer Vehicles / Watercraft ──────────────────
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Customer Vehicles / Watercraft',
    'CUV_SD',
    'BGCUV_SD',
    CAST(
        CAST(
            "CUSTOMERVEHICLESWATERCRAFTLIMIT" AS NUMBER(10, 0)
        ) AS VARCHAR
    ) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGCUV_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CASE
        WHEN COALESCE("CUSTOMERVEHICLESWATERCRAFTLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGCUV_SD'
UNION ALL
    -- ── MFL_SD : Motor Fuels ─────────────────────────────────────
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Motor Fuels',
    'MFL_SD',
    'BGMFL_SD',
    CAST(
        CAST("MOTORFUELSLIMIT" AS NUMBER(10, 0)) AS VARCHAR
    ) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGMFL_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CASE
        WHEN COALESCE("MOTORFUELSLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGMFL_SD'
UNION ALL
    -- ── PER_SD : Personal Effects ────────────────────────────────
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Personal Effects',
    'PER_SD',
    'BGPER_SD',
    CAST(
        CAST("PERSONALEFFECTSLIMIT" AS NUMBER(10, 0)) AS VARCHAR
    ) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGPER_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CASE
        WHEN COALESCE("PERSONALEFFECTSLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGPER_SD'
UNION ALL
    -- ── MVH_SD : Stock Vehicles / Watercraft ─────────────────────
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Stock Vehicles / Watercraft',
    'MVH_SD',
    'BGMVH_SD',
    CAST(
        CAST("STOCKVEHICLESWATERCRAFTLIMIT" AS NUMBER(10, 0)) AS VARCHAR
    ) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGMVH_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CASE
        WHEN COALESCE("STOCKVEHICLESWATERCRAFTLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGMVH_SD'
UNION ALL
    -- ── TOB_SD : Tobacco ─────────────────────────────────────────
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Tobacco',
    'TOB_SD',
    'BGTOB_SD',
    CAST(CAST("TOBACCOLIMIT" AS NUMBER(10, 0)) AS VARCHAR) AS iValue,
    '',
    '',
    '<ContentsStockInsuredAmount>0</ContentsStockInsuredAmount>
 <TobaccoInsuredAmount>0</TobaccoInsuredAmount>
 <LiquorInsuredAmount>0</LiquorInsuredAmount>
 <Code>BG</Code>',
    CASE
        WHEN SUB_COVERAGE = 'BGTOB_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CASE
        WHEN COALESCE("TOBACCOLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGTOB_SD'
UNION ALL
    -- ── STD_SD : Standard ────────────────────────────────────────
    -- FIXED (ATP-10775): floored to $10,000 minimum. Indicator now always 1
    -- once floored — this is the mandatory "Standard Protection" limit for
    -- Burglary, per the client's own field table.
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Standard',
    'STD_SD',
    'BGSTD_SD',
    CAST(GREATEST(COALESCE("CONTENTSSTOCKEMPLOYEETOOLSLIMIT", 0), 10000) AS VARCHAR) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGSTD_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CAST(1 AS VARCHAR) AS INDICATOR
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGSTD_SD'
UNION ALL
    -- ── EMP_SD : Employee Handtools ──────────────────────────────
    -- FIXED (ATP-10775): same $10,000 floor, same source column as STD_SD.
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Employee Handtools',
    'EMP_SD',
    'BGEMP_SD',
    CAST(GREATEST(COALESCE("CONTENTSSTOCKEMPLOYEETOOLSLIMIT", 0), 10000) AS VARCHAR) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGEMP_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CAST(1 AS VARCHAR)
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGEMP_SD'
UNION ALL
    -- ── ETH_SD : Employee Theft ───────────────────────────────────
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Employee Theft',
    'ETH_SD',
    'BGETH_SD',
    CAST(
        CAST("EMPLOYEETHEFTLIMIT" AS NUMBER(10, 0)) AS VARCHAR
    ) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGETH_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CASE
        WHEN COALESCE("EMPLOYEETHEFTLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGETH_SD'
UNION ALL
    -- ── TFT_SD : Theft ───────────────────────────────────────────
    -- NZ override per PL101 (already fixed, G-BP-01). FIXED HERE (ATP-10775):
    -- the NZ branch now floors to the same $10,000 minimum as its source
    -- (CONTENTSSTOCKEMPLOYEETOOLSLIMIT). Australia branch (raw THEFTLIMIT)
    -- is untouched — the client's minimum-value table does not list a
    -- separate Theft Limit minimum.
SELECT
    CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ),
    T1.PUREPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P,
    'Building_BG',
    'Theft',
    'TFT_SD',
    'BGTFT_SD',
    CASE
        WHEN TRIM(COUNTRY) = 'New Zealand' THEN CAST(GREATEST(COALESCE("CONTENTSSTOCKEMPLOYEETOOLSLIMIT", 0), 10000) AS VARCHAR)
        ELSE CAST(CAST(COALESCE("THEFTLIMIT", 0) AS NUMBER(10, 0)) AS VARCHAR)
    END AS iValue,
    '',
    '',
    '',
    CASE
        WHEN TRIM(COUNTRY) = 'New Zealand' THEN CAST(1 AS VARCHAR)
        ELSE
            CASE WHEN COALESCE("THEFTLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END
    END AS INDICATOR
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGTFT_SD';

-- POST-CHECK (Snowflake)
-- SELECT TYPE, MIN(CAST(IVALUE AS INT)) FROM AGGNE.DEV.RISK_BUILDING_BG_COVERAGES
-- WHERE TYPE IN ('STD_SD','EMP_SD') GROUP BY 1;
-- Expect MIN >= 10000 for both.
-- SELECT COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_BG_COVERAGES r
-- JOIN AGGNE.DEV.Location_BG_Coverage l ON r.PUREPOLICYNUMBER=CAST(trim(l.PUREPOLICYNUMBER)||'|'||TRIM(l.cmlnumber)||'|'||TRIM(l.EXPIRINGID_P) AS VARCHAR)
-- WHERE r.TYPE='TFT_SD' AND TRIM(l.COUNTRY)='New Zealand' AND CAST(r.IVALUE AS INT) < 10000;
-- Expect 0.


-- ============================================================================
-- STEP 2 (Snowflake) — BUILDING_BI_PAYLOAD: floor ANNUALGROSSPROFIT to
-- $30,000. This single token feeds all 5 BI sub-coverage limits in SEQ 37's
-- config (GRP_SD/GRP_CY/GRP_EQ/GRP_ST/GRP_BF), so fixing it once here covers
-- all five.
-- Re-pull GET_DDL immediately before applying and diff against this.
-- ============================================================================

create or replace view BUILDING_BI_PAYLOAD(
	PUREPOLICYNUMBER,
	COVERAGE,
	SUBCOV,
	UW,
	LOC_BI_CLAUSE,
	VOLUNTARYEXCESS,
	INDEMNITYPERIOD,
	ANNUALGROSSPROFIT,
	BICLMCNT,
	BICLMINCD,
	BIEXPPREM,
	EXP_PREM_BIGRP_SD,
	EXP_PREM_BIGRP_CY,
	EXP_PREM_BIGRP_EQ,
	EXP_PREM_BIGRP_ST,
	EXP_PREM_BIGRP_BF,
	LOAD_DATE
) as

 with cte_SAMPLE_CBP_LOCATION as
(
select distinct T1.PUREPOLICYNUMBER,T1.cmlnumber,T1.EXPIRINGID from AGGNE.DEV.Location_01 T1
INNER JOIN AGGNE.DEV.SAMPLE_CBP
T2 ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
-- and
-- T1.EXPIRINGID=T2.EXPIRINGID_P
WHERE T1.EXPIRYDATE>='2026-01-01'  --3236
),cte_COVERAGES as
(
select distinct PUREPOLICYNUMBER,cmlnumber,EXPIRINGID_P,'BI' AS CLAUSE,'Interruption' AS  COVERAGE, CAST(VOLUNTARYEXCESS AS VARCHAR) AS VOLUNTARYEXCESS,
INDEMNITYPERIOD,
CAST(GREATEST(COALESCE(CAST(ANNUALGROSSPROFIT AS NUMBER(25,3)),0), 30000) AS VARCHAR ) AS ANNUALGROSSPROFIT   -- FIXED (ATP-10775): floored to $30,000
FROM AGGNE.DEV.LOCATION_BI_COVERAGE T1  WHERE EXPIRYDATE>='2026-01-01'  --6916
)
, CTE_EXCESS AS(
SELECT
    CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,T2.cmlnumber,T2.EXPIRINGID_P,COVERAGE,CAST(T2.VOLUNTARYEXCESS AS VARCHAR) AS VOLUNTARYEXCESS,INDEMNITYPERIOD,
CAST(ANNUALGROSSPROFIT AS VARCHAR) AS ANNUALGROSSPROFIT
FROM
cte_SAMPLE_CBP_LOCATION T1
INNER JOIN cte_COVERAGES T2 ON T1.EXPIRINGID=T2.EXPIRINGID_P
AND TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)  --462
)
,CTE_LISTAGG AS(
SELECT
  ID,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_Risk_Building_BI_Subcov' THEN payload END, '\n') AS SUBCOV,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_Risk_Building_BI_UW'     THEN payload END, '\n') AS UW,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_LOC_BI_CLAUSE'     THEN payload END, '\n') AS LOC_BI_CLAUSE,
   CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM AGGNE.DEV.RISK_BUILDING_BI_TARGET
WHERE ITR_TYPE IN ('BP_Risk_Building_BI_Subcov', 'BP_Risk_Building_BI_UW','BP_LOC_BI_CLAUSE')
GROUP BY ID, CAST(LOAD_DATE AS DATE)
)
,SUB_COV_PREM AS (
SELECT
  PUREPOLICYNUMBER,
BIGRP_SD,
BIGRP_CY,
BIGRP_EQ,
BIGRP_ST,
BIGRP_BF
FROM (
  SELECT PUREPOLICYNUMBER, SUB_COVERAGE, EXPPREMIUM
  FROM AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP
) src
PIVOT (
  SUM(EXPPREMIUM) FOR SUB_COVERAGE IN (
    ('BIGRP_SD') AS BIGRP_SD,
    ('BIGRP_CY') AS BIGRP_CY,
    ('BIGRP_EQ') AS BIGRP_EQ,
    ('BIGRP_ST') AS BIGRP_ST,
    ('BIGRP_BF') AS BIGRP_BF
  )
) p
)
SELECT distinct
T1.PUREPOLICYNUMBER,
COVERAGE,CAST(SUBCOV AS VARCHAR) AS SUBCOV,
CAST(UW AS VARCHAR) AS UW,
CASE WHEN LOC_BI_CLAUSE IS NOT NULL AND LOC_BI_CLAUSE<> '' THEN '<Clauses><Type>BusinessInterruption</Type>'||CAST(LOC_BI_CLAUSE AS VARCHAR)||'</Clauses>' ELSE '' END AS LOC_BI_CLAUSE,
-- CAST(LOC_BI_CLAUSE AS VARCHAR) AS LOC_BI_CLAUSE,
CASE WHEN VOLUNTARYEXCESS='NA'  THEN  'NA'
WHEN VOLUNTARYEXCESS='5 days'  THEN  '5days' ELSE 'NA' END AS VOLUNTARYEXCESS,
CASE  WHEN INDEMNITYPERIOD='9 months'  THEN  '9months'
WHEN INDEMNITYPERIOD='12 months'  THEN  '12months'
WHEN INDEMNITYPERIOD='18 months'  THEN  '18months'
WHEN INDEMNITYPERIOD='24 months'  THEN  '24months' ELSE INDEMNITYPERIOD END AS INDEMNITYPERIOD,
 CAST(COALESCE(CAST(ANNUALGROSSPROFIT AS NUMBER(25,0)),0) AS VARCHAR) AS ANNUALGROSSPROFIT,
 CAST(cast(COALESCE(T4.BICLMCNT, 0) AS NUMBER(10,0)) AS VARCHAR) AS BICLMCNT,
 CAST(CAST(COALESCE(T4.BICLMINCD, 0)AS NUMBER(10,0)) AS VARCHAR) AS BICLMINCD,
 CAST(COALESCE(T4.BIEXPPREM, 0) AS VARCHAR) AS BIEXPPREM,
 CAST(COALESCE(CAST(BIGRP_SD AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BIGRP_SD,
 CAST(COALESCE(CAST(BIGRP_CY AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BIGRP_CY,
 CAST(COALESCE(CAST(BIGRP_EQ AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BIGRP_EQ ,
 CAST(COALESCE(CAST(BIGRP_ST AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BIGRP_ST,
 CAST(COALESCE(CAST(BIGRP_BF AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BIGRP_BF,
 CAST(GETDATE() AS DATE) AS LOAD_DATE
 FROM CTE_EXCESS T1
 --INNER JOIN  AGGNE.DEV.RISK_BUILDING_BI_TARGET T2
-- ON T1.PUREPOLICYNUMBER=T2.ID
LEFT JOIN CTE_LISTAGG T3 ON T1.PUREPOLICYNUMBER = T3.ID
LEFT JOIN AGGNE.DEV.VW_OUTPUT_COVERAGE_BSP T4 ON T1.PUREPOLICYNUMBER=T4.PUREPOLICYNUMBER
LEFT JOIN SUB_COV_PREM T5 ON T1.PUREPOLICYNUMBER=T5.PUREPOLICYNUMBER
WHERE   COVERAGE='Interruption';

-- POST-CHECK (Snowflake)
-- SELECT MIN(CAST(ANNUALGROSSPROFIT AS INT)) FROM AGGNE.DEV.BUILDING_BI_PAYLOAD;
-- Expect >= 30000 (was 0 for 6 rows before this fix).
