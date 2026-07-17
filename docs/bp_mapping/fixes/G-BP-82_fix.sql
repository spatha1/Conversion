-- ============================================================================
-- G-BP-82 fix — RISK_BUILDING_EN_COVERAGES hardcoded Indicator, all 5 branches
-- (correction — user flagged this was wrongly closed correct-by-design
-- during the SEQ 46-49 pass, 2026-07-11)
-- ============================================================================
-- CORRECTION OF AN EARLIER MISTAKE: seq46-49_building_engineering.md's
-- "Checked clean" section closed this as by-design, reasoning that "staging
-- table only contains policies where Engineering is already active, so the
-- flag is trivially always 1" — the same class as several other correctly
-- closed line-level flags this session. That reasoning was never actually
-- checked against per-sub-coverage limit data (unlike every other indicator
-- fix this session, all of which quantified live limit-vs-indicator
-- mismatches before concluding). It was wrong.
--
-- Live check (2026-07-11), Location_EN_Coverage, 6,003 rows, limit column
-- vs the always-hardcoded Indicator='1':
--   CWS_SD (CARWASHLIMIT):                 5,985 / 6,003 = 99.7% $0/NULL
--   DET_SD (DETERIORATIONOFSTOCKLIMIT):     5,841 / 6,003 = 97.3% $0/NULL
--   LOI_SD (LOSSOFINFORMATIONLIMIT):        5,179 / 6,003 = 86.3% $0/NULL
--   ICW_SD (INCREASEDCOSTOFWORKINGLIMIT):   4,819 / 6,003 = 80.3% $0/NULL
--   MAC_SD (MACHINERYELECTRONICEQUIP):          2 / 6,003 =  0.0% $0/NULL
-- Confirmed live in the view: 100% Indicator='1' across all 5 branches,
-- 6,003/6,003 rows each. CWS_SD's 99.7% is the largest single-field
-- indicator-vs-limit mismatch found in this entire BP gap-analysis pass —
-- larger than G-BP-75's 97.8% (BC Hail Storm).
--
-- FIX: Indicator now derives from `COALESCE(<limit>, 0) > 0` per branch,
-- matching the standard dynamic pattern used everywhere else in this
-- codebase (BC/BI/BG/Money views). MAC_SD's Indicator will still be 1 for
-- effectively every row given its 0.0% zero rate — this is a correctness
-- fix, not expected to change MAC_SD's practical output.
--
-- Combines with G-BP-79's active-term EXISTS filter (already drafted,
-- fixes/G-BP-79_fix.sql) — this file supersedes it, includes both fixes in
-- one CREATE OR REPLACE. Run this file instead of G-BP-79_fix.sql.
--
-- Scope: view-only, one view. No config change — SEQ 46's config already
-- references the generic {INDICATOR} token per branch.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
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
    CASE WHEN COALESCE(CARWASHLIMIT,0) > 0 THEN '1' ELSE '0' END AS Indicator,
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
    CASE WHEN COALESCE(DETERIORATIONOFSTOCKLIMIT,0) > 0 THEN '1' ELSE '0' END AS Indicator,
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
    CASE WHEN COALESCE(INCREASEDCOSTOFWORKINGLIMIT,0) > 0 THEN '1' ELSE '0' END AS Indicator,
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
    CASE WHEN COALESCE(LOSSOFINFORMATIONLIMIT,0) > 0 THEN '1' ELSE '0' END AS Indicator,
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
    CASE WHEN COALESCE(MACHINERYELECTRONICEQUIP,0) > 0 THEN '1' ELSE '0' END AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='ENMAC_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_EN_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='ENMAC_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01');

-- POST-CHECK (Snowflake)
-- SELECT TYPE, INDICATOR, COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_EN_COVERAGES GROUP BY 1,2 ORDER BY 1,2;
-- Expect a mix of '0'/'1' for CWS_SD/DET_SD/ICW_SD/LOI_SD (matching the
-- zero-rate percentages above); MAC_SD should be ~100% '1' still (its
-- source is almost never $0).
-- SELECT COUNT(*) FROM (
--   SELECT PUREPOLICYNUMBER, TYPE, COUNT(*) c
--   FROM AGGNE.DEV.RISK_BUILDING_EN_COVERAGES GROUP BY 1,2 HAVING COUNT(*)>1
-- );
-- Expect 0 (active-term filter, from G-BP-79, still intact).
