-- ============================================================================
-- G-BP-81 fix — RISK_BUILDING_BG_COVERAGES premium-join fan-out duplicate
-- (found while verifying G-BP-78's active-term fix — a SEPARATE bug)
-- ============================================================================
-- After applying G-BP-78 (active-term filter), the correct POST-CHECK
-- (grouping by the FULL composite key, not the coarser policy+type key)
-- still showed 5 true duplicates — all Type='CUV_SD' (Customer Vehicles /
-- Watercraft), same PUREPOLICYNUMBER+EXPIRINGID_P on both rows.
--
-- ROOT CAUSE (confirmed live, 2026-07-11): VW_OUTPUT_SUBCOVERAGE_BSP has
-- TWO rows for the same (PUREPOLICYNUMBER, EXPIRINGID_P, SUB_COVERAGE)
-- key on 5 policies — e.g. P00027392|CML00025971|2262193 / BGCUV_SD has
-- EXPPREMIUM 29.00 on one row and 103.00 on another. Every branch's LEFT
-- JOIN to this table matches on that same 3-part key, so when it isn't
-- unique, the join fans out and produces one output row per premium row
-- instead of one row per coverage. Location_BG_Coverage itself (the main
-- FROM table) has exactly one row for each of these 5 keys — the source of
-- the fan-out is entirely on the premium side of the join.
--
-- Confirmed via a broader check: this fan-out risk is structural to all 10
-- branches (any of them could hit it if VW_OUTPUT_SUBCOVERAGE_BSP ever has
-- a duplicate premium row for their SUB_COVERAGE code), even though only
-- CUV_SD currently has live duplicate premium rows. Checked the same
-- premium-duplication pattern against the other 4 Building coverage lines
-- (BC/BI/EN/Money) — 0 duplicate premium keys in all 4, so this fix is
-- BG-only for now.
--
-- FIX: pre-aggregate VW_OUTPUT_SUBCOVERAGE_BSP by
-- (PUREPOLICYNUMBER-composite-key, SUB_COVERAGE) with SUM(EXPPREMIUM)
-- before joining, in a CTE, so every branch's join target has at most one
-- row per key regardless of how many raw premium records exist underneath.
-- SUM (not MAX/first) because multiple premium rows for the same
-- sub-coverage most likely represent a genuine split that should total to
-- the real premium, not a value to arbitrarily pick between.
--
-- Builds on top of fixes/G-BP-78_fix.sql (already includes the active-term
-- EXISTS filter) — this file supersedes it; run this one instead.
--
-- Scope: view-only, one view. No config change.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- ============================================================================

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
) as
WITH SUBCOV_PREM AS (
    SELECT
        PUREPOLICYNUMBER,
        SUB_COVERAGE,
        SUM(COALESCE(EXPPREMIUM, 0)) AS EXPPREMIUM
    FROM AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP
    WHERE SUB_COVERAGE LIKE 'BG%'
    GROUP BY PUREPOLICYNUMBER, SUB_COVERAGE
)
    -- ── ALC_SD : Alcohol ─────────────────────────────────────────
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR) AS EXP_PREM,
    CASE
        WHEN COALESCE(ALCOHOLLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END AS INDICATOR
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGALC_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CASE
        WHEN COALESCE("CUSTOMERVEHICLESWATERCRAFTLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGCUV_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CASE
        WHEN COALESCE("MOTORFUELSLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGMFL_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CASE
        WHEN COALESCE("PERSONALEFFECTSLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGPER_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CASE
        WHEN COALESCE("STOCKVEHICLESWATERCRAFTLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGMVH_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CASE
        WHEN COALESCE("TOBACCOLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGTOB_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
UNION ALL
    -- ── STD_SD : Standard ────────────────────────────────────────
    -- FIXED (ATP-10775, G-BP-73): floored to $10,000 minimum. Indicator
    -- now always 1 once floored.
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CAST(1 AS VARCHAR) AS INDICATOR
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGSTD_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
UNION ALL
    -- ── EMP_SD : Employee Handtools ──────────────────────────────
    -- FIXED (ATP-10775, G-BP-73): same $10,000 floor, same source column.
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CAST(1 AS VARCHAR)
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGEMP_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CASE
        WHEN COALESCE("EMPLOYEETHEFTLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGETH_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01')
UNION ALL
    -- ── TFT_SD : Theft ───────────────────────────────────────────
    -- NZ override per PL101 (already fixed, G-BP-01), floored to $10,000
    -- (already fixed, G-BP-73). Australia branch (raw THEFTLIMIT) unchanged.
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
    CAST(CAST(COALESCE(T2.EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR),
    CASE
        WHEN TRIM(COUNTRY) = 'New Zealand' THEN CAST(1 AS VARCHAR)
        ELSE
            CASE WHEN COALESCE("THEFTLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END
    END AS INDICATOR
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN SUBCOV_PREM T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T2.SUB_COVERAGE = 'BGTFT_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01');

-- POST-CHECK (Snowflake)
-- SELECT COUNT(*) FROM (
--   SELECT PUREPOLICYNUMBER, TYPE, COUNT(*) c
--   FROM AGGNE.DEV.RISK_BUILDING_BG_COVERAGES GROUP BY 1,2 HAVING COUNT(*)>1
-- );
-- Expect 0 (was 5 after G-BP-78 alone; this fix closes those out too).
-- SELECT MIN(CAST(IVALUE AS INT)) FROM AGGNE.DEV.RISK_BUILDING_BG_COVERAGES WHERE TYPE IN ('STD_SD','EMP_SD');
-- Expect >= 10000 (confirms G-BP-73's floor is still intact).
