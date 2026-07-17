-- ============================================================================
-- G-BP-79 fix — RISK_BUILDING_EN_COVERAGES missing active-term filter
-- (same root cause and pattern as G-BP-76 / BC, applied to Engineering —
-- follow-up from the client's ATP-10947 duplicate-coverage comment)
-- ============================================================================
-- Same bug as G-BP-76: this view selects directly from Location_EN_Coverage
-- with no filter restricting to the current/active policy term, so any
-- policy with more than one staging row gets duplicate CWS_SD/DET_SD/
-- ICW_SD/LOI_SD/MAC_SD entries — one set per term.
--
-- Live check (2026-07-11): 1,008 of 4,823 distinct EN policies (20.9%) have
-- more than one Location_EN_Coverage row. Directly confirmed in the view's
-- own output: 5,040 (policy, Type) combinations currently return more than
-- one row.
--
-- FIX: add the same active-term EXISTS filter used in G-BP-76, to all 5
-- UNION ALL branches. No other logic changed — this was checked as part of
-- SEQ 46-49 (G-BP-52, closed 2026-07-11) but that pass compared source vs
-- rendered VALUE correctness, not row-count/duplication, so it didn't
-- surface this separate structural bug.
--
-- Scope: view-only, one view. No config change.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
--
-- *** SUPERSEDED — RUN fixes/G-BP-82_fix.sql INSTEAD ***
-- The Indicator hardcode ('1' on all 5 branches) was wrongly closed
-- correct-by-design during the SEQ 46-49 pass (2026-07-11) — CWS_SD is
-- actually wrong on 99.7% of rows. G-BP-82_fix.sql includes this file's
-- active-term filter PLUS the dynamic-Indicator fix. Kept only as the
-- standalone record for the active-term gap.
-- ============================================================================

create or replace view RISK_BUILDING_EN_COVERAGES(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	CMLNUMBER,
	COVERAGE,
	COVERAGETYPE,
	DESCRIPTION,
	TYPE,
	CODE,
	IVALUE,
	INDICATOR,
	EXCESSINFO,
	EXP_PREM
) as
SELECT DISTINCT
    CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_EN' AS CoverageType,
    'Car Wash' AS Description,
    'CWS_SD' AS Type,
    'ENCWS_SD' AS Code,
    CAST(COALESCE(CARWASHLIMIT,0) AS VARCHAR) AS iValue,
    cast('1' as varchar) AS Indicator,
    CONCAT('<Excess>',
		'<Standard/>',
		'<Voluntary>',cast(COALESCE(VOLUNTARYEXCESS,0) as varchar),'</Voluntary>',
		'<Imposed/>',
		'<Amount/>',
	'</Excess> <Code>EN</Code>') AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='ENCWS_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_EN_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='ENCWS_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')

UNION ALL
SELECT DISTINCT
CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_EN' AS CoverageType,
    'Deterioration of Stock' AS Description,
    'DET_SD' AS Type,
    'ENDET_SD' AS Code,
    cast(COALESCE(DETERIORATIONOFSTOCKLIMIT ,0) as varchar) AS iValue,
   cast('1' as varchar) AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='ENDET_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_EN_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='ENDET_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
UNION ALL
SELECT DISTINCT
CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_EN' AS CoverageType,
    'Increased Cost of Working' AS Description,
    'ICW_SD' AS Type,
    'ENICW_SD' AS Code,
    cast(COALESCE(INCREASEDCOSTOFWORKINGLIMIT,0) as varchar) AS iValue,
    cast('1' as varchar) AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='ENICW_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_EN_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='ENICW_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
UNION ALL
SELECT DISTINCT
CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_EN' AS CoverageType,
    'Loss of Information' AS Description,
    'LOI_SD' AS Type,
    'ENLOI_SD' AS Code,
    cast(COALESCE(LOSSOFINFORMATIONLIMIT ,0) as varchar) AS iValue,
    cast('1' as varchar) AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='ENLOI_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_EN_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='ENLOI_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')

UNION ALL
SELECT DISTINCT
CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_EN' AS CoverageType,
    'Machinery' AS Description,
    'MAC_SD' AS Type,
    'ENMAC_SD' AS Code,
    cast(COALESCE(MACHINERYELECTRONICEQUIP,0) as varchar) AS iValue,
    cast('1' as varchar) AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='ENMAC_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_EN_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='ENMAC_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01');

-- POST-CHECK (Snowflake)
-- Group by the FULL composite key (PUREPOLICYNUMBER already includes
-- EXPIRINGID_P as its 3rd '|'-delimited part) — do NOT strip it out with
-- SPLIT_PART, or policies with multiple legitimately-active locations
-- (different EXPIRINGID_P, both currently in force) will show as false
-- "duplicates" even though the fix is working correctly.
-- SELECT COUNT(*) FROM (
--   SELECT PUREPOLICYNUMBER, TYPE, COUNT(*) c
--   FROM AGGNE.DEV.RISK_BUILDING_EN_COVERAGES GROUP BY 1,2 HAVING COUNT(*)>1
-- );
-- Expect 0 — the earlier 5,040 count was true same-term duplication.
