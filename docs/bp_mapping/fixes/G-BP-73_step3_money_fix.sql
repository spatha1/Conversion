-- ============================================================================
-- G-BP-73 Step 3 — RISK_BUILDING_MONEY_COVERAGES: rewrite MSB_SD's existing
-- $2,000 floor using GREATEST(), for consistency with Steps 1-2
-- (G-BP-73_fix.sql) and robustness against any future value between $1-$1,999
-- ============================================================================
-- NOT a bug fix — the current CASE-based logic (`WHEN =0 THEN 2000 ELSE
-- <raw value>`) already satisfies ATP-10775's $2,000 minimum for every row in
-- the live data (0 of 1,339 rows below $2,000, confirmed earlier). It works
-- today ONLY because the Pure-to-Write SP bands MONEYDURINGBUSINESSHOURS into
-- discrete tiers (NULL/2000/5000/10000/20000) before it ever reaches this
-- view — so no value between $1-$1,999 can currently occur. GREATEST() gets
-- the same result today but doesn't depend on that upstream banding staying
-- exactly as-is, and matches the pattern already used for STD_SD/EMP_SD
-- (Burglary) and ANNUALGROSSPROFIT (BI) in G-BP-73's first two steps.
--
-- Scope: VIEW-ONLY, single UNION ALL branch (MSB_SD). No config change.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- Whitespace/structure confirmed byte-exact via live pull immediately before
-- drafting.
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
    -- REWRITTEN (G-BP-73 Step 3): same $2,000 floor as before, now via
    -- GREATEST() instead of a CASE that only handled the exact-zero case.
SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_MY' AS CoverageType,
    'Money at Situation during Business Hours' AS Description,
    'MSB_SD' AS Type,
    'MYMSB_SD' AS Code,
    CAST(GREATEST(COALESCE(MONEYDURINGBUSINESSHOURS, 0), 2000) AS VARCHAR) AS iValue,
    cast('1' as varchar) AS Indicator,
    '' AS EXCESSINFO,
    CASE WHEN SUB_COVERAGE='MYMSB_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_Money_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='MYMSB_SD';

-- POST-CHECK (Snowflake)
-- SELECT MIN(CAST(IVALUE AS INT)) FROM AGGNE.DEV.RISK_BUILDING_MONEY_COVERAGES WHERE TYPE='MSB_SD';
-- Expect >= 2000 (same as before this rewrite — confirms no behavior change).
