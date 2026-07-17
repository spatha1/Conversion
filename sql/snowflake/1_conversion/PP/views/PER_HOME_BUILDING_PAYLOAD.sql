-- ============================================================
-- View   : AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
-- Schema : DEV (PP Conversion)
-- Purpose: Source view for DYNAMIC_XML_V1 — feeds TWO config rows:
--            Seq 7  → RISK_Building_HB template → PER_BUILDING_TARGET
--            Seq 13 → RISK_Building_HC template → PER_HC_TARGET
--          DYNAMIC_XML_V1 reads column names from INFORMATION_SCHEMA
--          and auto-generates REPLACE(payload, '{COLNAME}', value).
--          Every {TOKEN} in the PP_ConversionConfig template must have
--          a matching column name here or it will remain unresolved.
--
-- Fix applied (2026-06-24):
--   Added LEFT JOIN to AGGNE.DEV.HB_02 (alias T5) to expose HB-specific
--   fields that were missing from the original view.  These are needed
--   by the RISK_Building_HB template (seq 7):
--     {HOMEBUILDINGSLIMIT}  ← T5.HOMEBUILDINGSLIMIT
--     {LANDLORDPROTECTIONS} ← T5.LANDLORDPROTECTIONS
--     {MINIMUMRENTALPERIOD} ← T5.MINIMUMRENTALPERIOD
--     {WEEKLYRENT}          ← T5.WEEKLYRENT
--   Also exposed from the existing Output_Coverage_PER join (T4):
--     {HBCLMCNT}   ← T4.HBCLMCNT   (view had HCCLMCNT only)
--     {HBCLMINCD}  ← T4.HBCLMINCD  (view had HCCLMINCD only)
--     {EXPPREM}    ← T4.HMEXPPREM   (view had HBEXPPREM only)
--
-- Fix applied (ATP-9638 Issue-2, 2026-06-25):
--   HOMEBUILDINGSLIMIT and WEEKLYRENT were cast directly to VARCHAR from
--   a NUMERIC/FLOAT column, producing strings like '1146000.0000' instead
--   of '1146000'.  The seq 7 template substitutes these into <GlassLimit>
--   and <WeeklyRet> — DCT failed to parse the decimal-format values.
--   Fixed by casting through NUMBER(10,0) first to strip decimals.
--
-- Fix applied (2026-07-01):
--   CTE_HC_CLAUSES was querying ITR_TYPE='HC_CLAUSE' but seq 12 stores HC
--   clause rows with ITR_TYPE='LOC_HC_CLAUSE'. HC clauses were silently
--   dropped for all HC policies. Fixed by correcting the ITR_TYPE filter.
--
-- Fix applied (2026-07-01):
--   UW column was hardcoded ''. Seq 11 (BUILDING_UW) loads HC UW adjustment
--   rows into PER_HC_TARGET. Added BUILDING_UW aggregation to CTE_LISTAGG
--   so {UW} in the seq 13 template is correctly populated.
-- ============================================================

create or replace view PER_HOME_BUILDING_PAYLOAD(
    PUREPOLICYNUMBER,
    COVERAGE,
    -- ── HC sub-payload columns (seq 13 RISK_Building_HC) ──────────────────
    SUBCOV,               -- {SUBCOV}              : Building sub-coverage rows
    HC_EXCEED_VALUES,     -- {HC_EXCEED_VALUES}     : Items exceeding value rows
    HC_SPECIFIED_CONTENTS,-- {HC_SPECIFIED_CONTENTS}: Specified contents rows
    -- ── Shared HC / HB columns ────────────────────────────────────────────
    VOLUNTARYEXCESS,      -- {VOLUNTARYEXCESS}
    ACCIDENTALLOSSORDAMAGE,-- {ACCIDENTALLOSSORDAMAGE}
    SPECIFIEDITEMSAWAY,   -- {SPECIFIEDITEMSAWAY}   : 'Taken' / 'Not Taken' (PL101 #104)
    UNSPECIFIEDITEMSAWAY, -- {UNSPECIFIEDITEMSAWAY} : 'Taken' / 'Not Taken' (PL101 #113)
    UNSPECIFIEDITEMSAWAYLIMIT, -- {UNSPECIFIEDITEMSAWAYLIMIT}
    ANYITEMSEXCEEDVALUE,  -- {ANYITEMSEXCEEDVALUE}  : 'Yes' / 'No' → seq 13 <HomeContentsLimits>
    -- ── HC claims/premium (seq 13) ────────────────────────────────────────
    HCCLMCNT,             -- {HCCLMCNT}
    HCCLMINCD,            -- {HCCLMINCD}
    HBEXPPREM,            -- {HBEXPPREM}  (HC premium — sourced from HMEXPPREM)
    -- ── HB-specific columns added 2026-06-24 (seq 7 RISK_Building_HB) ─────
    HOMEBUILDINGSLIMIT,   -- {HOMEBUILDINGSLIMIT}  : from HB_02
    LANDLORDPROTECTIONS,  -- {LANDLORDPROTECTIONS} : from HB_02
    MINIMUMRENTALPERIOD,  -- {MINIMUMRENTALPERIOD} : from HB_02
    WEEKLYRENT,           -- {WEEKLYRENT}          : from HB_02
    HBCLMCNT,             -- {HBCLMCNT}            : from Output_Coverage_PER
    HBCLMINCD,            -- {HBCLMINCD}           : from Output_Coverage_PER
    EXPPREM,              -- {EXPPREM}             : HB premium (HMEXPPREM alias)
    -- ── Clause / UW columns ───────────────────────────────────────────────
    HB_CLAUSE,            -- {HB_CLAUSE}           : aggregated from PER_BUILDING_TARGET
    HC_CLAUSE,            -- {HC_CLAUSE}           : LOC_HC_CLAUSE rows from PER_HC_TARGET (seq 12)
    UW,                   -- {UW}                  : BUILDING_UW rows from PER_HC_TARGET (seq 11)
    LOAD_DATE,
    -- ── v2 2026-07-01: coverage indicator columns (indicator fix) ──────────
    HB_INDICATOR,         -- {HB_INDICATOR}    : 1 if policy has Home Building coverage (HB_01), else 0
    HC_INDICATOR          -- {HC_INDICATOR}    : 1 if policy has Home Contents coverage (HC_02), else 0
) as

-- ── CTE 1: Active PP locations in scope ──────────────────────────────────
with cte_SAMPLE_CBP_LOCATION as
(
    select distinct
        trim(T1.PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
        trim(t1.CMLNUMBER)        AS CMLNUMBER,
        T1.EXPIRINGID_P
    from AGGNE.DEV.Locationdetails_PER T1
    INNER JOIN AGGNE.DEV.SAMPLE_PER T2
        ON TRIM(T1.PUREPOLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
    WHERE t1.EFFECTIVEDATE >= '2026-01-01'
),

-- ── CTE 2: Coverage data for Building locations ───────────────────────────
-- ATP-9638 fix (2026-06-26): Original CTE used only HC_02 (Home Contents)
-- with an INNER JOIN in CTE_EXCESS.  This excluded 1,679 HB-only policies
-- (in HB_01 but not HC_02), causing PER_RISK_BUILDING_FINAL to fall back to
-- <Indicator>0</Indicator> for both Home Buildings and Home Contents in DCT.
--
-- Fix: UNION HC_02 with HB_01 rows not already covered by HC_02.
--   HC_02 branch  → policies with Home Contents coverage (HC-specific fields populated)
--   HB_01 branch  → HB-only policies added by this fix (HC-specific fields NULL;
--                   they default gracefully in the final SELECT via COALESCE/CASE)
--
-- ACCIDENTALLOSSORDAMAGE: raw 'Taken'/'Not Taken' is returned here (no pre-conversion).
-- CTE_EXCESS performs the single '1'/'0' conversion.  Prior code converted twice
-- (once here, once in CTE_EXCESS), always producing '0' regardless of source value.
cte_COVERAGES as
(
    -- HC_02 branch: preserves HC-specific fields for policies with Home Contents
    -- v2 2026-07-01: added HC_INDICATOR=1 and HB_INDICATOR (check HB_01) for indicator fix
    select distinct
        HC.PUREPOLICYNUMBER, HC.cmlnumber, HC.EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        HC.VOLUNTARYEXCESS,
        HC.ACCIDENTALLOSSORDAMAGE,       -- raw 'Taken'/'Not Taken'; CTE_EXCESS converts
        HC.SPECIFIEDITEMSAWAY, HC.UNSPECIFIEDITEMSAWAY, HC.UNSPECIFIEDITEMSAWAYLIMIT,
        HC.ANYITEMSEXCEEDVALUE,
        1 AS HC_INDICATOR,               -- row from HC_02 → policy has HC coverage
        CASE WHEN EXISTS (
            SELECT 1 FROM AGGNE.DEV.HB_01 H2
            WHERE TRIM(H2.PUREPOLICYNUMBER) = TRIM(HC.PUREPOLICYNUMBER)
              AND H2.EXPIRINGID_P           = HC.EXPIRINGID_P
        ) THEN 1 ELSE 0 END AS HB_INDICATOR  -- 1 if policy also has HB coverage
    from AGGNE.DEV.HC_02 HC

    UNION

    -- HB_01 branch: adds HB-only policies absent from HC_02 (ATP-9638 fix)
    -- v2 2026-07-01: added HC_INDICATOR=0, HB_INDICATOR=1 for indicator fix
    select distinct
        H.PUREPOLICYNUMBER, H.cmlnumber, H.EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        COALESCE(H.VOLUNTARYEXCESS, 0)   AS VOLUNTARYEXCESS,
        H.ACCIDENTALLOSSORDAMAGE,        -- raw 'Taken'/'Not Taken'; CTE_EXCESS converts
        NULL AS SPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAYLIMIT,
        NULL AS ANYITEMSEXCEEDVALUE,
        0 AS HC_INDICATOR,               -- NOT in HC_02 (WHERE NOT EXISTS) → no HC coverage
        1 AS HB_INDICATOR                -- this row from HB_01 → policy has HB coverage
    from AGGNE.DEV.HB_01 H
    WHERE NOT EXISTS (
        SELECT 1 FROM AGGNE.DEV.HC_02 HC2
        WHERE TRIM(H.PUREPOLICYNUMBER) = TRIM(HC2.PUREPOLICYNUMBER)
          AND H.EXPIRINGID_P           = HC2.EXPIRINGID_P
    )
),

-- ── CTE 3: Build composite ID (PUREPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P) ──
CTE_EXCESS AS (
    SELECT
        CAST(
            TRIM(T2.PUREPOLICYNUMBER) || '|' ||
            TRIM(T2.cmlnumber)        || '|' ||
            TRIM(T2.EXPIRINGID_P)
        AS VARCHAR) AS PUREPOLICYNUMBER,           -- composite key used in target tables
        t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER, -- original legacy policy number
        T2.cmlnumber,
        T2.EXPIRINGID_P,
        COVERAGE,
        T2.VOLUNTARYEXCESS,
        -- Single conversion: cte_COVERAGES now returns raw 'Taken'/'Not Taken'
        CASE WHEN T2.ACCIDENTALLOSSORDAMAGE = 'Taken'
             THEN CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR)
             ELSE CAST(CAST(0 AS NUMBER(1,0)) AS VARCHAR)
        END AS ACCIDENTALLOSSORDAMAGE,
        SPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAYLIMIT,
        ANYITEMSEXCEEDVALUE,
        T2.HC_INDICATOR,                 -- v2 2026-07-01: pass through indicator columns
        T2.HB_INDICATOR
    FROM cte_SAMPLE_CBP_LOCATION T1
    INNER JOIN cte_COVERAGES T2
        ON  T1.EXPIRINGID_P             = T2.EXPIRINGID_P
        AND TRIM(T1.PUREPOLICYNUMBER)   = TRIM(T2.PUREPOLICYNUMBER)
),

-- ── CTE 4: Aggregate HC sub-payloads already loaded into PER_HC_TARGET ───
-- Rows 8 and 9 of PP_ConversionConfig (HC_exceed_values, HC_Specified_Contents)
-- and row 10 (Building_SubCov for HC) are inserted into PER_HC_TARGET BEFORE
-- row 13 runs, so this CTE correctly picks them up for {HC_EXCEED_VALUES},
-- {HC_SPECIFIED_CONTENTS}, and {SUBCOV} substitution in the HC template.
CTE_LISTAGG AS (
    SELECT
        ID,
        LISTAGG(CASE WHEN ITR_TYPE = 'Building_SubCov'        THEN payload END, '\n') AS SUBCOV,
        LISTAGG(CASE WHEN ITR_TYPE = 'HC_exceed_values'       THEN payload END, '\n') AS HC_exceed_values,
        LISTAGG(CASE WHEN ITR_TYPE = 'HC_Specified_Contents'  THEN payload END, '\n') AS HC_Specified_Contents,
        LISTAGG(CASE WHEN ITR_TYPE = 'BUILDING_UW'            THEN payload END, '\n') AS UW_ADJUST,
        CAST(LOAD_DATE AS DATE) AS LOAD_DATE
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE IN ('Building_SubCov', 'HC_exceed_values', 'HC_Specified_Contents', 'BUILDING_UW')
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID, CAST(LOAD_DATE AS DATE)
)

-- ── CTE 5: Aggregate HB clause rows from PER_BUILDING_TARGET ─────────────
-- Provides {HB_CLAUSE} for the seq 7 RISK_Building_HB template
, CTE_BUILDING_CLAUSES AS (
    SELECT
        ID,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS HB_CLAUSE_PAYLOAD
    FROM AGGNE.DEV.PER_BUILDING_TARGET
    WHERE ITR_TYPE = 'HB_CLAUSE'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
)

-- ── CTE 6: Aggregate HC clause rows from PER_HC_TARGET ───────────────────
-- Provides {HC_CLAUSE} for the seq 13 RISK_Building_HC template.
-- Seq 12 (LOC_HC_CLAUSE) stores clause rows with ITR_TYPE='LOC_HC_CLAUSE'.
, CTE_HC_CLAUSES AS (
    SELECT
        ID,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS HC_CLAUSE_PAYLOAD
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE = 'LOC_HC_CLAUSE'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
)

-- ── Final SELECT ──────────────────────────────────────────────────────────
SELECT distinct
    T1.PUREPOLICYNUMBER,
    T1.COVERAGE,

    -- HC sub-payload columns (resolved by DYNAMIC_XML_V1 for seq 13)
    CAST(T3.SUBCOV               AS VARCHAR) AS SUBCOV,
    CAST(T3.HC_exceed_values     AS VARCHAR) AS HC_EXCEED_VALUES,
    CAST(T3.HC_Specified_Contents AS VARCHAR) AS HC_SPECIFIED_CONTENTS,

    -- Shared fields (used by both HB seq 7 and HC seq 13 templates)
    CAST(CAST(COALESCE(T1.VOLUNTARYEXCESS, 0) AS NUMBER(20,0)) AS VARCHAR) AS VOLUNTARYEXCESS,
    -- CTE_EXCESS already converted 'Taken'/'Not Taken' → '1'/'0'; pass through directly.
    T1.ACCIDENTALLOSSORDAMAGE AS ACCIDENTALLOSSORDAMAGE,
    -- PL101 #104: SpecifiedItemsPremises expects 'Taken' / 'Not Taken' (not 1/0)
    CASE WHEN T1.SPECIFIEDITEMSAWAY = 'Taken' THEN 'Taken' ELSE 'Not Taken' END AS SPECIFIEDITEMSAWAY,
    -- PL101 #113: UnspecifiedItemsAwayPremises expects 'Taken' / 'Not Taken' (not 1/0)
    CASE WHEN T1.UNSPECIFIEDITEMSAWAY = 'Taken' THEN 'Taken' ELSE 'Not Taken' END AS UNSPECIFIEDITEMSAWAY,
    CASE WHEN T1.UNSPECIFIEDITEMSAWAYLIMIT = '$2,000 per item up to $10,000 per event'
              THEN '2000peritemupto10000perevent'
         WHEN T1.UNSPECIFIEDITEMSAWAYLIMIT = '$1,250 per item up to $5,000 per event'
              THEN '1250peritemupto5000perevent'
         ELSE ''
    END AS UNSPECIFIEDITEMSAWAYLIMIT,
    -- Seq 13 <HomeContentsLimits>: reference payload shows 'Yes'/'No', not hardcoded '1'.
    -- Requires SQL Server fix: UPDATE PP_ConversionConfig SET ConversionScript =
    --   REPLACE(ConversionScript,'<HomeContentsLimits>1</HomeContentsLimits>',
    --           '<HomeContentsLimits>{ANYITEMSEXCEEDVALUE}</HomeContentsLimits>')
    --   WHERE SequenceID = 13
    CAST(COALESCE(T1.ANYITEMSEXCEEDVALUE, 'No') AS VARCHAR) AS ANYITEMSEXCEEDVALUE,

    -- HC claims and premium (Output_Coverage_PER — for seq 13 HC template)
    CAST(COALESCE(T4.HCCLMCNT,  0) AS VARCHAR) AS HCCLMCNT,
    CAST(COALESCE(T4.HCCLMINCD, 0) AS VARCHAR) AS HCCLMINCD,
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS HBEXPPREM,

    -- ── NEW: HB-specific columns (for seq 7 RISK_Building_HB template) ───
    -- Source: HB_02 joined on LEGACYPOLICYNUMBER + EXPIRINGID_P (alias T5)
    -- ATP-9638 Issue-2: cast through NUMBER(10,0) to remove decimal places
    -- (e.g. '1146000.0000' → '1146000') before VARCHAR conversion.
    CAST(CAST(COALESCE(T5.HOMEBUILDINGSLIMIT, 0) AS NUMBER(10, 0)) AS VARCHAR) AS HOMEBUILDINGSLIMIT,
    CAST(COALESCE(T5.LANDLORDPROTECTIONS, '')                       AS VARCHAR) AS LANDLORDPROTECTIONS,
    CASE TRIM(T5.MINIMUMRENTALPERIOD)
        WHEN 'More than 90 Days' THEN 'Morethan90Days'
        WHEN 'Less than 90 Days' THEN 'Lessthan90Days'
        ELSE CAST(COALESCE(T5.MINIMUMRENTALPERIOD, '') AS VARCHAR)
    END AS MINIMUMRENTALPERIOD,
    CAST(CAST(COALESCE(T5.WEEKLYRENT, 0) AS NUMBER(10, 0))          AS VARCHAR) AS WEEKLYRENT,
    -- HB claims from Output_Coverage_PER (T4 already joined above)
    CAST(COALESCE(T4.HBCLMCNT,  0) AS VARCHAR) AS HBCLMCNT,
    CAST(COALESCE(T4.HBCLMINCD, 0) AS VARCHAR) AS HBCLMINCD,
    -- HB premium: template uses {EXPPREM}; source is HMEXPPREM (total home premium)
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS EXPPREM,

    -- ── Clause / UW columns ───────────────────────────────────────────────
    -- {HB_CLAUSE}: HB clause rows from PER_BUILDING_TARGET (seq 6 HB_CLAUSE)
    CAST(COALESCE(T6.HB_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HB_CLAUSE,
    -- {HC_CLAUSE}: HC clause rows from PER_HC_TARGET (seq 12 LOC_HC_CLAUSE)
    CAST(COALESCE(T7.HC_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HC_CLAUSE,
    -- {UW}: HC UW adjustment rows from PER_HC_TARGET (seq 11 BUILDING_UW)
    CAST(COALESCE(T3.UW_ADJUST, '') AS VARCHAR) AS UW,

    CAST(GETDATE() AS DATE) AS LOAD_DATE,

    -- ── v2 2026-07-01: coverage indicator columns ─────────────────────────
    -- Used by seq 7 ({HB_INDICATOR}) and seq 13 ({HC_INDICATOR}) templates
    -- to set <Indicator> correctly instead of hardcoding 1.
    CAST(T1.HB_INDICATOR AS VARCHAR) AS HB_INDICATOR,
    CAST(T1.HC_INDICATOR AS VARCHAR) AS HC_INDICATOR

FROM CTE_EXCESS T1
-- HC payload rows (for HC_EXCEED_VALUES / HC_SPECIFIED_CONTENTS inline check)
LEFT JOIN AGGNE.DEV.PER_HC_TARGET T2
    ON T1.PUREPOLICYNUMBER = T2.ID
-- HC sub-payload aggregates
LEFT JOIN CTE_LISTAGG T3
    ON T1.PUREPOLICYNUMBER = T3.ID
-- Claims and premium for both HB and HC
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4
    ON T1.PUREPOLICYNUMBER = T4.POLICYNUMBER
-- NEW: HB_02 for Home Building-specific fields
-- Join on the original legacy policy number (not the composite ID) + expiry
LEFT JOIN AGGNE.DEV.HB_02 T5
    ON  TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.PUREPOLICYNUMBER)
    AND T1.EXPIRINGID_P             = T5.EXPIRINGID_P
-- HB clause rows (feeds {HB_CLAUSE} in seq 7 template)
LEFT JOIN CTE_BUILDING_CLAUSES T6
    ON T1.PUREPOLICYNUMBER = T6.ID
-- HC clause rows (feeds {HC_CLAUSE} in seq 13 template)
LEFT JOIN CTE_HC_CLAUSES T7
    ON T1.PUREPOLICYNUMBER = T7.ID

WHERE COVERAGE = 'Building';
