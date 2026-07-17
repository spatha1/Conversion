-- ============================================================
-- Prerequisite fix for G-30 (seq 13 FloodDamage hardcode) — apply this BEFORE running
-- FIX for G-30 in PP_ConversionConfig_FIXES_20260710.sql (the commented-out block at the
-- bottom of that file).
--
-- View: AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD (this is a full CREATE OR REPLACE — Snowflake
-- views can't be partially ALTERed, so this is the complete corrected view definition, not a
-- diff. Only change vs. the current live view: FLOODDAMAGE added end-to-end, following the
-- exact same pattern already used for ANYITEMSEXCEEDVALUE — same source table (HC_02), same
-- CTE branches, same NULL-in-HB_01-branch handling, same COALESCE default in the final SELECT.
--
-- NOT APPLIED — Snowflake access for this review is read-only; run this yourself.
--
-- Fix applied (2026-07-10): G-30 — added FLOODDAMAGE column end-to-end (HC_02.FLOODDAMAGE
-- already carries the real 'Taken'/'Not Taken' status — it already correctly drives the seq 10
-- Flood sub-coverage sValue, it just wasn't threaded through to this view for seq 13's
-- coverage-level <FloodDamage> tag, which is hardcoded 'Taken' in the template as a result).
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
    FLOODDAMAGE,           -- {FLOODDAMAGE} : 'Taken'/'Not Taken' → seq 13 <FloodDamage> (G-30 fix, 2026-07-10)
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
cte_COVERAGES as
(
    -- HC_02 branch: preserves HC-specific fields for policies with Home Contents
    select distinct
        HC.PUREPOLICYNUMBER, HC.cmlnumber, HC.EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        HC.VOLUNTARYEXCESS,
        HC.ACCIDENTALLOSSORDAMAGE,       -- raw 'Taken'/'Not Taken'; CTE_EXCESS converts
        HC.SPECIFIEDITEMSAWAY, HC.UNSPECIFIEDITEMSAWAY, HC.UNSPECIFIEDITEMSAWAYLIMIT,
        HC.ANYITEMSEXCEEDVALUE,
        HC.FLOODDAMAGE,                  -- G-30 fix: real Taken/Not Taken, same source as seq 10 sValue
        1 AS HC_INDICATOR,               -- row from HC_02 → policy has HC coverage
        CASE WHEN EXISTS (
            SELECT 1 FROM AGGNE.DEV.HB_01 H2
            WHERE TRIM(H2.PUREPOLICYNUMBER) = TRIM(HC.PUREPOLICYNUMBER)
              AND H2.EXPIRINGID_P           = HC.EXPIRINGID_P
        ) THEN 1 ELSE 0 END AS HB_INDICATOR  -- 1 if policy also has HB coverage
    from AGGNE.DEV.HC_02 HC

    UNION

    -- HB_01 branch: adds HB-only policies absent from HC_02 (ATP-9638 fix)
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
        NULL AS FLOODDAMAGE,             -- G-30 fix: HB_01 has no HC-side flood data — NULL, same as the other HC-only fields on this branch
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
        FLOODDAMAGE,                     -- G-30 fix: pass through
        T2.HC_INDICATOR,                 -- v2 2026-07-01: pass through indicator columns
        T2.HB_INDICATOR
    FROM cte_SAMPLE_CBP_LOCATION T1
    INNER JOIN cte_COVERAGES T2
        ON  T1.EXPIRINGID_P             = T2.EXPIRINGID_P
        AND TRIM(T1.PUREPOLICYNUMBER)   = TRIM(T2.PUREPOLICYNUMBER)
),

-- ── CTE 4: Aggregate HC sub-payloads already loaded into PER_HC_TARGET ───
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
    -- Requires SQL Server fix (see PP_ConversionConfig_FIXES_20260710.sql, Fix 6 / G-31).
    CAST(COALESCE(T1.ANYITEMSEXCEEDVALUE, 'No') AS VARCHAR) AS ANYITEMSEXCEEDVALUE,
    -- G-30 fix (2026-07-10): real Taken/Not Taken for seq 13 <FloodDamage>, replacing the
    -- template's hardcoded 'Taken'. Requires SQL Server fix (PP_ConversionConfig_FIXES_20260710.sql,
    -- commented-out G-30 block) to actually wire {FLOODDAMAGE} into the template once this column
    -- is confirmed live.
    CAST(COALESCE(T1.FLOODDAMAGE, 'Not Taken') AS VARCHAR) AS FLOODDAMAGE,

    -- HC claims and premium (Output_Coverage_PER — for seq 13 HC template)
    CAST(COALESCE(T4.HCCLMCNT,  0) AS VARCHAR) AS HCCLMCNT,
    CAST(COALESCE(T4.HCCLMINCD, 0) AS VARCHAR) AS HCCLMINCD,
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS HBEXPPREM,

    -- ── HB-specific columns (for seq 7 RISK_Building_HB template) ───
    -- Source: HB_02 joined on LEGACYPOLICYNUMBER + EXPIRINGID_P (alias T5)
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
    CAST(COALESCE(T6.HB_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HB_CLAUSE,
    CAST(COALESCE(T7.HC_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HC_CLAUSE,
    CAST(COALESCE(T3.UW_ADJUST, '') AS VARCHAR) AS UW,

    CAST(GETDATE() AS DATE) AS LOAD_DATE,

    -- ── v2 2026-07-01: coverage indicator columns ─────────────────────────
    CAST(T1.HB_INDICATOR AS VARCHAR) AS HB_INDICATOR,
    CAST(T1.HC_INDICATOR AS VARCHAR) AS HC_INDICATOR

FROM CTE_EXCESS T1
LEFT JOIN AGGNE.DEV.PER_HC_TARGET T2
    ON T1.PUREPOLICYNUMBER = T2.ID
LEFT JOIN CTE_LISTAGG T3
    ON T1.PUREPOLICYNUMBER = T3.ID
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4
    ON T1.PUREPOLICYNUMBER = T4.POLICYNUMBER
LEFT JOIN AGGNE.DEV.HB_02 T5
    ON  TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.PUREPOLICYNUMBER)
    AND T1.EXPIRINGID_P             = T5.EXPIRINGID_P
LEFT JOIN CTE_BUILDING_CLAUSES T6
    ON T1.PUREPOLICYNUMBER = T6.ID
LEFT JOIN CTE_HC_CLAUSES T7
    ON T1.PUREPOLICYNUMBER = T7.ID

WHERE COVERAGE = 'Building';

-- ── Verify after applying ──────────────────────────────────────────────────
-- SELECT FLOODDAMAGE, COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD GROUP BY 1;
-- -- target: 'Taken'/'Not Taken' values present, roughly matching HC_02's 545 Taken / 2,008 Not Taken
