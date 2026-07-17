-- ============================================================================
-- G-BP-01 fix — SEQ 38 (BP_Risk_Building_BG_Subcov), Burglary: TFT_SD (Theft)
-- NZ override missing (ATP-10960)
-- ============================================================================
-- Root cause (confirmed against PL101 + live data, 2026-07-11):
--   PL101 (Location v1.1, TheftInput.TheftLimit) states explicitly:
--     "For (NZ) Theft Limit should always default to the Contents, Stock &
--      Employee Tools Limit."
--   RISK_BUILDING_BG_COVERAGES' TFT_SD branch sends Pure's raw THEFTLIMIT
--   (BGTHEFTPROTECTION) unconditionally for every country — no NZ override.
--   The correct value (CONTENTSSTOCKEMPLOYEETOOLSLIMIT, = BGCONTENTS +
--   BGEMPLOYEETOOLS per PL101) is already computed in the SAME staging table
--   (Location_BG_Coverage) and already used correctly for STD_SD/EMP_SD's own
--   branches in this same view — no new data sourcing needed, purely a
--   missing country-conditional swap on one branch.
--
--   Live data (Location_BG_Coverage):
--     Australia: 11,462 rows, 11,355 where THEFTLIMIT <> ContentsStockEmployeeToolsLimit (expected — no override applies)
--     New Zealand: 1,978 rows, 1,265 where THEFTLIMIT <> ContentsStockEmployeeToolsLimit
--   Confirmed: 1,265 of 1,978 NZ Burglary records (63.9%) send the wrong Theft
--   limit — Pure's raw theft-specific figure instead of the PL101-mandated
--   Contents+Stock+EmployeeTools total.
--
-- Scope: VIEW-ONLY, single UNION ALL branch (TFT_SD). SEQ 38's config already
--   references the generic {IVALUE}/{INDICATOR} tokens — no config change
--   needed, the branch-level fix is entirely in the view.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead before running.
-- Whitespace/structure confirmed byte-exact via live pull immediately before drafting.
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
    CAST(
        CAST(
            "CONTENTSSTOCKEMPLOYEETOOLSLIMIT" AS NUMBER(10, 0)
        ) AS VARCHAR
    ) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGSTD_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CASE
        WHEN COALESCE("CONTENTSSTOCKEMPLOYEETOOLSLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END AS INDICATOR
FROM
    AGGNE.DEV.Location_BG_Coverage T1
    LEFT JOIN AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(
        trim(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR
    ) = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    AND SUB_COVERAGE = 'BGSTD_SD'
UNION ALL
    -- ── EMP_SD : Employee Handtools ──────────────────────────────
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
    CAST(
        CAST(
            "CONTENTSSTOCKEMPLOYEETOOLSLIMIT" AS NUMBER(10, 0)
        ) AS VARCHAR
    ) AS iValue,
    '',
    '',
    '',
    CASE
        WHEN SUB_COVERAGE = 'BGEMP_SD' THEN CAST(
            CAST(COALESCE(EXPPREMIUM, 0) AS NUMBER(36, 3)) AS VARCHAR
        )
        ELSE CAST(0 AS VARCHAR)
    END,
    CASE
        WHEN COALESCE("CONTENTSSTOCKEMPLOYEETOOLSLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR)
        ELSE CAST(0 AS VARCHAR)
    END
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
    -- FIXED: NZ override per PL101 (TheftInput.TheftLimit comment:
    -- "For (NZ) Theft Limit should always default to the Contents, Stock &
    -- Employee Tools Limit"). iValue and INDICATOR both now branch on COUNTRY.
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
        WHEN TRIM(COUNTRY) = 'New Zealand' THEN CAST(CAST(COALESCE("CONTENTSSTOCKEMPLOYEETOOLSLIMIT", 0) AS NUMBER(10, 0)) AS VARCHAR)
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
        WHEN TRIM(COUNTRY) = 'New Zealand' THEN
            CASE WHEN COALESCE("CONTENTSSTOCKEMPLOYEETOOLSLIMIT", 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END
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
-- SELECT COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_BG_COVERAGES r
-- JOIN AGGNE.DEV.Location_BG_Coverage l
--   ON r.PUREPOLICYNUMBER = CAST(trim(l.PUREPOLICYNUMBER)||'|'||TRIM(l.cmlnumber)||'|'||TRIM(l.EXPIRINGID_P) AS VARCHAR)
-- WHERE r.TYPE='TFT_SD' AND TRIM(l.COUNTRY)='New Zealand'
--   AND r.IVALUE <> CAST(CAST(COALESCE(l."CONTENTSSTOCKEMPLOYEETOOLSLIMIT",0) AS NUMBER(10,0)) AS VARCHAR);
-- Expect 0.
