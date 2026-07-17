-- ============================================================================
-- G-BP-77 fix — RISK_BUILDING_BI_COVERAGES missing active-term filter
-- (same root cause and pattern as G-BP-76 / BC, applied to Business
-- Interruption — follow-up from the client's ATP-10947 duplicate-coverage
-- comment, checked proactively across the sibling Building coverage views)
-- ============================================================================
-- Same bug as G-BP-76: this view selects directly from Location_BI_Coverage
-- with no filter restricting to the current/active policy term, so any
-- policy with more than one staging row (renewal, term change, etc.) gets
-- duplicate CLP_SD/ACR_SD/ICW_SD entries — one per term.
--
-- Live check (2026-07-11): 1,817 of 7,592 distinct BI policies (23.9%) have
-- more than one Location_BI_Coverage row. Directly confirmed in the view's
-- own output: 5,451 (policy, Type) combinations currently return more than
-- one row.
--
-- FIX: add the same active-term EXISTS filter used in G-BP-76, to all 3
-- UNION ALL branches. No other logic changed — the G-BP-27 indicator fix
-- (2026-07-11, dynamic Indicator per branch) is preserved as-is.
--
-- Scope: view-only, one view. No config change.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- ============================================================================

create or replace view RISK_BUILDING_BI_COVERAGES(
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
	EXP_PREM,
	INDICATOR
) as
-- ── CLP_SD : Claim Preparation ───────────────────────────────
SELECT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BI' AS CoverageType,
    'Claim Preparation' AS Description,
    'CLP_SD' AS Type,
    'BICLP_SD' AS Code,
    cast(CAST("CLAIMSPREPARATIONCOSTLIMIT" AS NUMBER(20,0)) as varchar) AS iValue,
    '' AS sValue,
    CASE WHEN SUB_COVERAGE='BICLP_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM,
    CASE WHEN COALESCE("CLAIMSPREPARATIONCOSTLIMIT",0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR
FROM AGGNE.DEV.Location_BI_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P and SUB_COVERAGE='BICLP_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')

UNION ALL

-- ── ACR_SD : Accounts Receivable ─────────────────────────────
SELECT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BI' AS CoverageType,
    'Accounts Receivable' AS Description,
    'ACR_SD' AS Type,
    'BIACR_SD' AS Code,
    cast(CAST("ACCOUNTSRECEIVABLELIMIT" AS NUMBER(20,0)) as varchar) AS iValue,
    '' AS sValue,
    CASE WHEN SUB_COVERAGE='BIACR_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM,
    CASE WHEN COALESCE("ACCOUNTSRECEIVABLELIMIT",0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR
FROM AGGNE.DEV.Location_BI_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON  CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P and SUB_COVERAGE='BIACR_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')

UNION ALL

-- ── ICW_SD : Additional Increased Cost of Working ────────────
SELECT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BI' AS CoverageType,
    'Additional Increased Cost of Working' AS Description,
    'ICW_SD' AS Type,
    'BIICW_SD' AS Code,
    cast(CAST("ADDITIONALCOSTOFWORKINGLIMIT" AS NUMBER(20,0)) as varchar) AS iValue,
    '' AS sValue,
    CASE WHEN SUB_COVERAGE='BIICW_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM,
    CASE WHEN COALESCE("ADDITIONALCOSTOFWORKINGLIMIT",0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR
FROM AGGNE.DEV.Location_BI_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON  CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P and SUB_COVERAGE='BIICW_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01');

-- POST-CHECK (Snowflake)
-- Group by the FULL composite key (PUREPOLICYNUMBER already includes
-- EXPIRINGID_P as its 3rd '|'-delimited part) — do NOT strip it out with
-- SPLIT_PART, or policies with multiple legitimately-active locations
-- (different EXPIRINGID_P, both currently in force) will show as false
-- "duplicates" even though the fix is working correctly.
-- SELECT COUNT(*) FROM (
--   SELECT PUREPOLICYNUMBER, TYPE, COUNT(*) c
--   FROM AGGNE.DEV.RISK_BUILDING_BI_COVERAGES GROUP BY 1,2 HAVING COUNT(*)>1
-- );
-- Expect 0 (confirmed 0 after applying, 2026-07-11 — the earlier 5,451 count
-- was true same-term duplication, now eliminated).
