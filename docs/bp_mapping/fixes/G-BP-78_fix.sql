-- ============================================================================
-- G-BP-78 fix — RISK_BUILDING_BG_COVERAGES missing active-term filter
-- (same root cause and pattern as G-BP-76 / BC, applied to Burglary —
-- follow-up from the client's ATP-10947 duplicate-coverage comment)
-- ============================================================================
-- Same bug as G-BP-76: this view selects directly from Location_BG_Coverage
-- with no filter restricting to the current/active policy term, so any
-- policy with more than one staging row gets duplicate sub-coverage entries
-- across all 10 branches — one set per term.
--
-- Live check (2026-07-11): 2,544 of 10,371 distinct BG policies (24.5%) have
-- more than one Location_BG_Coverage row. Directly confirmed in the view's
-- own output: 25,442 (policy, Type) combinations currently return more than
-- one row — the largest raw duplicate count found across all 5 Building
-- coverage lines checked.
--
-- FIX: add the same active-term EXISTS filter used in G-BP-76, to all 10
-- UNION ALL branches. No other logic changed — the G-BP-73 ($10,000 floor
-- on STD_SD/EMP_SD/TFT_SD-NZ) and G-BP-01 (TFT_SD NZ override) fixes
-- already live in this view are preserved exactly as-is.
--
-- Scope: view-only, one view. No config change.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
--
-- *** SUPERSEDED — RUN fixes/G-BP-81_fix.sql INSTEAD ***
-- Applying this fix alone left 5 true duplicates (all CUV_SD) caused by a
-- SEPARATE bug: VW_OUTPUT_SUBCOVERAGE_BSP has duplicate premium rows for
-- the same (policy, location, sub-coverage) key on 5 policies, and this
-- view's LEFT JOIN fans out when that happens. G-BP-81_fix.sql includes
-- this file's active-term filter PLUS a premium pre-aggregation (SUM) that
-- closes that out too. Kept only as the standalone record for this gap.
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
      CASE
        WHEN SUB_COVERAGE = 'BGTFT_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
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
    AND SUB_COVERAGE = 'BGTFT_SD'
WHERE EXISTS (SELECT 1 FROM AGGNE.DEV.Location_01 L1 INNER JOIN AGGNE.DEV.SAMPLE_CBP L2 ON TRIM(L1.PUREPOLICYNUMBER)=TRIM(L2.PUREPOLICYNUMBER) WHERE TRIM(L1.PUREPOLICYNUMBER)=TRIM(T1.PUREPOLICYNUMBER) AND L1.EXPIRINGID=T1.EXPIRINGID_P AND L1.EXPIRYDATE>='2026-01-01');

-- POST-CHECK (Snowflake)
-- Group by the FULL composite key (PUREPOLICYNUMBER already includes
-- EXPIRINGID_P as its 3rd '|'-delimited part) — do NOT strip it out with
-- SPLIT_PART, or policies with multiple legitimately-active locations
-- (different EXPIRINGID_P, both currently in force) will show as false
-- "duplicates" even though the fix is working correctly.
-- SELECT COUNT(*) FROM (
--   SELECT PUREPOLICYNUMBER, TYPE, COUNT(*) c
--   FROM AGGNE.DEV.RISK_BUILDING_BG_COVERAGES GROUP BY 1,2 HAVING COUNT(*)>1
-- );
-- Expect 0 — the earlier 25,442 count was true same-term duplication.
