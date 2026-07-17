-- ══════════════════════════════════════════════════════════════════════════
-- PP_XML_VALIDATE_AND_REPORT.sql
-- Target  : Snowflake — AGGNE.DEV (read-only)
-- Date    : 2026-07-01
--
-- Validates generated XML (DEV.PA_PER_POLICY_MIGRATION_DCT) against
-- the core source tables (COVERAGE_PER_POLICYATTACH, OUTPUT_SUBCOVER_PER_POLICYATTACH)
-- for PP policies only.
--
-- Four validation sections, UNION ALL:
--   1. POLICY PRESENCE    — is every in-scope PP policy in the XML?
--   2. COVERAGE PRESENCE  — does XML have the right Building/Contents/Motor blocks?
--   3. UNRESOLVED TOKENS  — are any {TOKEN} placeholders still in the XML?
--   4. SUBCOVERAGE FAMILY — are HB/HC/PM sub-coverage families present where expected?
-- ══════════════════════════════════════════════════════════════════════════

WITH

-- ─────────────────────────────────────────────────────────────────────────
-- CTE 1: PP in-scope policies (from SAMPLE_PER conversion scope)
-- ─────────────────────────────────────────────────────────────────────────
PP_SCOPE AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER
    FROM AGGNE.DEV.SAMPLE_PER
),

-- ─────────────────────────────────────────────────────────────────────────
-- CTE 2: Generated XML — one row per PP policy (most recent run only)
-- QUALIFY deduplicates: PA_PER_POLICY_MIGRATION_DCT may have multiple rows
-- per policy from separate ETL runs; we take the latest.
-- ─────────────────────────────────────────────────────────────────────────
XML_OUT AS (
    SELECT
        TRIM(X.LEGACYPOLICYNUMBER)                              AS PUREPOLICYNUMBER,
        X.REQUEST_XML,
        CASE WHEN CONTAINS(X.REQUEST_XML, '<Type>Building</Type>')           THEN 1 ELSE 0 END AS XML_HAS_BUILDING,
        CASE WHEN CONTAINS(X.REQUEST_XML, '<Type>ContentsAndStocks</Type>')   THEN 1 ELSE 0 END AS XML_HAS_CONTENTS,
        CASE WHEN CONTAINS(X.REQUEST_XML, '<Type>CommercialVehicle</Type>')   THEN 1 ELSE 0 END AS XML_HAS_MOTOR,
        CASE WHEN REGEXP_LIKE(X.REQUEST_XML, '.*\\{[A-Z_]+\\}.*') THEN 1 ELSE 0 END AS HAS_UNRESOLVED_TOKENS,
        REGEXP_SUBSTR(X.REQUEST_XML, '(\\{[A-Z_]+\\})', 1, 1)  AS TOKEN_1,
        REGEXP_SUBSTR(X.REQUEST_XML, '(\\{[A-Z_]+\\})', 1, 2)  AS TOKEN_2,
        REGEXP_SUBSTR(X.REQUEST_XML, '(\\{[A-Z_]+\\})', 1, 3)  AS TOKEN_3,
        REGEXP_SUBSTR(X.REQUEST_XML, '(\\{[A-Z_]+\\})', 1, 4)  AS TOKEN_4,
        REGEXP_SUBSTR(X.REQUEST_XML, '(\\{[A-Z_]+\\})', 1, 5)  AS TOKEN_5
    FROM AGGNE.DEV.PA_PER_POLICY_MIGRATION_DCT X
    JOIN PP_SCOPE S ON TRIM(X.LEGACYPOLICYNUMBER) = S.PUREPOLICYNUMBER
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(X.LEGACYPOLICYNUMBER) ORDER BY X.LEGACYPOLICYNUMBER) = 1
),

-- ─────────────────────────────────────────────────────────────────────────
-- CTE 3: Source coverage ground truth — most recent policy version per policy
-- COVERAGE_PER_POLICYATTACH is the PRD_T5 core table with policy + risk + coverage detail
-- ─────────────────────────────────────────────────────────────────────────
SOURCE_COV_BASE AS (
    SELECT
        TRIM(C.PUREPOLICYNUMBER)                                AS PUREPOLICYNUMBER,
        C.EXPIRINGID_P,
        C.RISK_NUMBER,
        C.CMLNUMBER,
        C.LINEOFBUSINESS,
        C.HMEXPPREM,
        C.PMEXPPREM,
        -- Expected coverage flags derived from premiums
        CASE WHEN COALESCE(C.HMEXPPREM, 0) > 0 THEN 1 ELSE 0 END AS EXPECT_HOME,
        CASE WHEN COALESCE(C.PMEXPPREM, 0) > 0 THEN 1 ELSE 0 END AS EXPECT_MOTOR,
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(C.PUREPOLICYNUMBER)
            ORDER BY C.PUREEXPIRYDATE DESC, C.EXPIRINGID_P DESC
        ) AS RN
    FROM AGGNE.DEV.COVERAGE_PER_POLICYATTACH C
    JOIN PP_SCOPE S ON TRIM(C.PUREPOLICYNUMBER) = S.PUREPOLICYNUMBER
),

-- Most recent record per policy
SOURCE_COV AS (
    SELECT * FROM SOURCE_COV_BASE WHERE RN = 1
),

-- ─────────────────────────────────────────────────────────────────────────
-- CTE 4: Sub-coverage families per policy (from OUTPUT_SUBCOVER_PER_POLICYATTACH)
-- SUB_COVERAGE prefix: HB = Building, HC = Contents, PM = Motor
-- ─────────────────────────────────────────────────────────────────────────
SUBCOV_FAMILIES AS (
    SELECT
        TRIM(SC.PUREPOLICYNUMBER)                               AS PUREPOLICYNUMBER,
        MAX(CASE WHEN SC.SUB_COVERAGE LIKE 'HB%' THEN 1 ELSE 0 END) AS SRC_HAS_HB_SUBCOV,
        MAX(CASE WHEN SC.SUB_COVERAGE LIKE 'HC%' THEN 1 ELSE 0 END) AS SRC_HAS_HC_SUBCOV,
        MAX(CASE WHEN SC.SUB_COVERAGE LIKE 'PM%' THEN 1 ELSE 0 END) AS SRC_HAS_PM_SUBCOV,
        COUNT(DISTINCT SC.SUB_COVERAGE)                         AS TOTAL_SUBCOV_COUNT,
        LISTAGG(DISTINCT SC.SUB_COVERAGE, ', ')
            WITHIN GROUP (ORDER BY SC.SUB_COVERAGE)             AS SUBCOV_LIST
    FROM AGGNE.DEV.OUTPUT_SUBCOVER_PER_POLICYATTACH SC
    JOIN PP_SCOPE S ON TRIM(SC.PUREPOLICYNUMBER) = S.PUREPOLICYNUMBER
    GROUP BY TRIM(SC.PUREPOLICYNUMBER)
),

-- ─────────────────────────────────────────────────────────────────────────
-- CTE 5: Count unresolved tokens per XML (one row per policy — same dedup)
-- ─────────────────────────────────────────────────────────────────────────
TOKEN_COUNTS AS (
    SELECT
        TRIM(X.LEGACYPOLICYNUMBER)                              AS PUREPOLICYNUMBER,
        REGEXP_COUNT(X.REQUEST_XML, '\\{[A-Z_]+\\}')           AS UNRESOLVED_TOKEN_COUNT
    FROM AGGNE.DEV.PA_PER_POLICY_MIGRATION_DCT X
    JOIN PP_SCOPE S ON TRIM(X.LEGACYPOLICYNUMBER) = S.PUREPOLICYNUMBER
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(X.LEGACYPOLICYNUMBER) ORDER BY X.LEGACYPOLICYNUMBER) = 1
)

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 1: POLICY PRESENCE
-- Every PP policy in scope should appear in the XML output table
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    'POLICY PRESENCE'                                           AS CHECK_TYPE,
    S.PUREPOLICYNUMBER,
    NULL                                                        AS RISK_NUMBER,
    NULL                                                        AS SOURCE_VALUE,
    NULL                                                        AS XML_VALUE,
    CASE WHEN X.PUREPOLICYNUMBER IS NULL
         THEN 'FAIL — policy not found in XML output'
         ELSE 'PASS'
    END                                                         AS STATUS,
    NULL                                                        AS DETAIL
FROM PP_SCOPE S
LEFT JOIN XML_OUT X ON S.PUREPOLICYNUMBER = X.PUREPOLICYNUMBER

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 2A: BUILDING COVERAGE PRESENCE
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    'COVERAGE — Building',
    SC.PUREPOLICYNUMBER,
    CAST(SC.RISK_NUMBER AS VARCHAR),
    CAST(SC.EXPECT_HOME AS VARCHAR)                             AS SOURCE_VALUE,
    CAST(X.XML_HAS_BUILDING AS VARCHAR)                        AS XML_VALUE,
    CASE
        WHEN X.PUREPOLICYNUMBER IS NULL     THEN 'SKIP — not in XML output'
        WHEN SC.EXPECT_HOME = 1 AND X.XML_HAS_BUILDING = 0  THEN 'FAIL — Building expected but missing from XML'
        WHEN SC.EXPECT_HOME = 0 AND X.XML_HAS_BUILDING = 1  THEN 'WARN — Building in XML but no home premium in source'
        ELSE 'PASS'
    END,
    'Source HMEXPPREM: ' || CAST(COALESCE(SC.HMEXPPREM, 0) AS VARCHAR)
FROM SOURCE_COV SC
LEFT JOIN XML_OUT X ON SC.PUREPOLICYNUMBER = X.PUREPOLICYNUMBER

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 2B: MOTOR COVERAGE PRESENCE
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    'COVERAGE — Motor',
    SC.PUREPOLICYNUMBER,
    CAST(SC.RISK_NUMBER AS VARCHAR),
    CAST(SC.EXPECT_MOTOR AS VARCHAR),
    CAST(X.XML_HAS_MOTOR AS VARCHAR),
    CASE
        WHEN X.PUREPOLICYNUMBER IS NULL     THEN 'SKIP — not in XML output'
        WHEN SC.EXPECT_MOTOR = 1 AND X.XML_HAS_MOTOR = 0    THEN 'FAIL — Motor expected but missing from XML'
        WHEN SC.EXPECT_MOTOR = 0 AND X.XML_HAS_MOTOR = 1    THEN 'WARN — Motor in XML but no motor premium in source'
        ELSE 'PASS'
    END,
    'Source PMEXPPREM: ' || CAST(COALESCE(SC.PMEXPPREM, 0) AS VARCHAR)
FROM SOURCE_COV SC
LEFT JOIN XML_OUT X ON SC.PUREPOLICYNUMBER = X.PUREPOLICYNUMBER

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 3: UNRESOLVED TOKEN CHECK
-- No {TOKEN} placeholders should remain in the final XML
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    'TOKEN — Unresolved',
    TC.PUREPOLICYNUMBER,
    NULL,
    '0'                                                         AS SOURCE_VALUE,
    CAST(TC.UNRESOLVED_TOKEN_COUNT AS VARCHAR)                  AS XML_VALUE,
    CASE WHEN TC.UNRESOLVED_TOKEN_COUNT > 0
         THEN 'FAIL — ' || CAST(TC.UNRESOLVED_TOKEN_COUNT AS VARCHAR) || ' unresolved token(s) in XML'
         ELSE 'PASS'
    END,
    COALESCE(X.TOKEN_1, '') || ' ' ||
    COALESCE(X.TOKEN_2, '') || ' ' ||
    COALESCE(X.TOKEN_3, '') || ' ' ||
    COALESCE(X.TOKEN_4, '') || ' ' ||
    COALESCE(X.TOKEN_5, '')                                     AS DETAIL
FROM TOKEN_COUNTS TC
JOIN XML_OUT X ON TC.PUREPOLICYNUMBER = X.PUREPOLICYNUMBER

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 4A: SUBCOVERAGE FAMILY — Building (HB%)
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    'SUBCOV — HB (Building)',
    SF.PUREPOLICYNUMBER,
    NULL,
    CAST(SF.SRC_HAS_HB_SUBCOV AS VARCHAR),
    CAST(X.XML_HAS_BUILDING AS VARCHAR),
    CASE
        WHEN X.PUREPOLICYNUMBER IS NULL          THEN 'SKIP — not in XML output'
        WHEN SF.SRC_HAS_HB_SUBCOV = 1 AND X.XML_HAS_BUILDING = 0 THEN 'FAIL — HB sub-coverages in source but Building absent from XML'
        WHEN SF.SRC_HAS_HB_SUBCOV = 0 AND X.XML_HAS_BUILDING = 1 THEN 'WARN — Building in XML but no HB sub-coverages in source'
        ELSE 'PASS'
    END,
    'Sub-coverages: ' || COALESCE(SF.SUBCOV_LIST, 'none')
FROM SUBCOV_FAMILIES SF
LEFT JOIN XML_OUT X ON SF.PUREPOLICYNUMBER = X.PUREPOLICYNUMBER

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 4B: SUBCOVERAGE FAMILY — Contents (HC%)
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    'SUBCOV — HC (Contents)',
    SF.PUREPOLICYNUMBER,
    NULL,
    CAST(SF.SRC_HAS_HC_SUBCOV AS VARCHAR),
    CAST(X.XML_HAS_CONTENTS AS VARCHAR),
    CASE
        WHEN X.PUREPOLICYNUMBER IS NULL          THEN 'SKIP — not in XML output'
        WHEN SF.SRC_HAS_HC_SUBCOV = 1 AND X.XML_HAS_CONTENTS = 0 THEN 'FAIL — HC sub-coverages in source but Contents absent from XML'
        WHEN SF.SRC_HAS_HC_SUBCOV = 0 AND X.XML_HAS_CONTENTS = 1 THEN 'WARN — Contents in XML but no HC sub-coverages in source'
        ELSE 'PASS'
    END,
    'Sub-coverages: ' || COALESCE(SF.SUBCOV_LIST, 'none')
FROM SUBCOV_FAMILIES SF
LEFT JOIN XML_OUT X ON SF.PUREPOLICYNUMBER = X.PUREPOLICYNUMBER

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 4C: SUBCOVERAGE FAMILY — Motor (PM%)
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    'SUBCOV — PM (Motor)',
    SF.PUREPOLICYNUMBER,
    NULL,
    CAST(SF.SRC_HAS_PM_SUBCOV AS VARCHAR),
    CAST(X.XML_HAS_MOTOR AS VARCHAR),
    CASE
        WHEN X.PUREPOLICYNUMBER IS NULL          THEN 'SKIP — not in XML output'
        WHEN SF.SRC_HAS_PM_SUBCOV = 1 AND X.XML_HAS_MOTOR = 0 THEN 'FAIL — PM sub-coverages in source but Motor absent from XML'
        WHEN SF.SRC_HAS_PM_SUBCOV = 0 AND X.XML_HAS_MOTOR = 1 THEN 'WARN — Motor in XML but no PM sub-coverages in source'
        ELSE 'PASS'
    END,
    'Sub-coverages: ' || COALESCE(SF.SUBCOV_LIST, 'none')
FROM SUBCOV_FAMILIES SF
LEFT JOIN XML_OUT X ON SF.PUREPOLICYNUMBER = X.PUREPOLICYNUMBER

ORDER BY CHECK_TYPE, STATUS DESC, PUREPOLICYNUMBER
;
