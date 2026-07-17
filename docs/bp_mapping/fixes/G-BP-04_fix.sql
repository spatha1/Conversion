-- ============================================================================
-- G-BP-04 fix — SEQ 42 (BP_Risk_Building_Money_Subcov), Money: MSB_SD ("Money
-- at Situation during Business Hours") wrong $0 default + hardcoded Indicator
-- ============================================================================
-- Root cause (confirmed against PL101 + live data, 2026-07-11):
--   PL101 (Location v1.1, MoneyInput.MoneyOnThePremisesDuringBusinessHoursLimit):
--     "If MYDURINGBUSHOURS = 0 THEN Select" (i.e. blank/no selection) —
--     NOT a dollar tier. Options are $2,000/$5,000/$10,000/$20,000 only.
--   RISK_BUILDING_MONEY_COVERAGES' MSB_SD branch currently does:
--     case when COALESCE(MONEYDURINGBUSINESSHOURS,0)=0 then 2000 else ... end AS iValue,
--     cast('1' as varchar) AS Indicator   -- dynamic version commented out just above it
--   i.e. forces a fabricated $2,000 value (never sent by Pure) instead of blank,
--   and hardcodes Indicator=1 regardless of whether there's a real limit at all
--   — inconsistent with every sibling branch in this same view (MSO_SD/MSS_SD/
--   MPC_SD/MIT_SD/EMP_SD), which all correctly compute Indicator from
--   `limit > 0`. The correct dynamic Indicator logic is present in the file,
--   just commented out.
--
--   Live data (Location_Money_Coverage, EXPIRYDATE>='2026-01-01', 1,339 rows):
--   MONEYDURINGBUSINESSHOURS is never literally 0 — only NULL (32 rows, 2.4%),
--   which COALESCE(...,0) treats the same way. Confirmed: 32 of 1,339 records
--   (2.4%) get a fabricated $2,000 MSB_SD limit and an always-Taken indicator
--   when Pure recorded no value for this field at all.
--
-- Scope: VIEW-ONLY, single UNION ALL branch (MSB_SD). SEQ 42's config already
--   references the generic {IVALUE}/{INDICATOR} tokens — no config change
--   needed.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead before running.
-- ============================================================================

create or replace view RISK_BUILDING_MONEY_COVERAGES(
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
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_MY' AS CoverageType,
    'Money at the Situation outside Business Hours' AS Description,
    'MSO_SD' AS Type,
    'MYMSO_SD' AS Code,
    CAST(COALESCE(MONEYOUTSIDEBUSINESSHOURS,0) AS VARCHAR) AS iValue,
    case when COALESCE(MONEYOUTSIDEBUSINESSHOURS,0)::int>0 then '1' else '0' end  AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='MYMSO_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_Money_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='MYMSO_SD'

UNION ALL
SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_MY' AS CoverageType,
    'Money at the Situation held in secure locked safe or strongroom' AS Description,
    'MSS_SD' AS Type,
    'MYMSS_SD' AS Code,
    cast(COALESCE(MONEYINALOCKEDSAFE ,0) as varchar) AS iValue,
    case when COALESCE(MONEYINALOCKEDSAFE,0)::int>0 then '1' else '0' end   AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='MYMSS_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_Money_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='MYMSS_SD'

UNION ALL
SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_MY' AS CoverageType,
    'Money in personal custody or private residence outside Business Hours' AS Description,
    'MPC_SD' AS Type,
    'MYMPC_SD' AS Code,
    cast(COALESCE(MONEYATPRIVATERESIDENCELIMIT,0) as varchar) AS iValue,
    case when COALESCE(MONEYATPRIVATERESIDENCELIMIT,0)::int>0 then '1' else '0' end   AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='MYMPC_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_Money_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='MYMPC_SD'

UNION ALL
SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_MY' AS CoverageType,
    'Money in Transit' AS Description,
    'MIT_SD' AS Type,
    'MYMIT_SD' AS Code,
    cast(COALESCE(MONEYINTRANSITLIMIT ,0) as varchar) AS iValue,
    case when COALESCE(MONEYINTRANSITLIMIT,0)::int>0 then '1' else '0' end   AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='MYMIT_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_Money_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='MYMIT_SD'

UNION ALL
SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_MY' AS CoverageType,
    'Employee Dishonesty' AS Description,
    'EMP_SD' AS Type,
    'MYEMP_SD' AS Code,
    cast(COALESCE(EMPLOYEEDISHONESTYLIMIT,0) as varchar) AS iValue,
    case when COALESCE(EMPLOYEEDISHONESTYLIMIT,0)::int>0 then '1' else '0' end   AS Indicator,
    CONCAT('<Excess>',
		'<Standard/>',
		'<Voluntary>',cast(COALESCE(VOLUNTARYEXCESS,0) as varchar),'</Voluntary>',
		'<Imposed/>',
		'<Amount/>',
	'</Excess> <Code>MY</Code>
	<moneysd/>') AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='MYEMP_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_Money_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='MYEMP_SD'

UNION ALL
    -- ── MSB_SD : Money at Situation during Business Hours ────────
    -- FIXED: 0/NULL now correctly maps to blank (PL101: "If MYDURINGBUSHOURS
    -- = 0 THEN Select"), not a fabricated $2,000. Indicator restored to the
    -- dynamic limit>0 logic already used by every sibling branch above.
SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_MY' AS CoverageType,
    'Money at Situation during Business Hours' AS Description,
    'MSB_SD' AS Type,
    'MYMSB_SD' AS Code,
    CASE WHEN COALESCE(MONEYDURINGBUSINESSHOURS,0)=0 THEN ''
         ELSE CAST(CAST(COALESCE(MONEYDURINGBUSINESSHOURS,0) AS NUMBER(10,0)) AS VARCHAR)
    END AS iValue,
    case when COALESCE(MONEYDURINGBUSINESSHOURS,0)::int>0 then '1' else '0' end  AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='MYMSB_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_Money_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='MYMSB_SD';

-- POST-CHECK (Snowflake)
-- SELECT IVALUE, INDICATOR, COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_MONEY_COVERAGES
-- WHERE TYPE='MSB_SD' GROUP BY 1,2 ORDER BY 3 DESC;
-- Expect: no rows with IVALUE='2000' AND the row corresponds to a NULL source
-- (i.e. the 53 previously-fabricated $2,000 rows now show '' / Indicator '0').
