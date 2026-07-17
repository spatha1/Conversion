-- ══════════════════════════════════════════════════════════════════════════
-- PP_DEPLOY_INDICATOR_FIX_20260701.sql
--
-- Fix: <Indicator>1</Indicator> hardcoded in seq 7 (HB) and seq 13 (HC)
-- templates caused all building-coverage checkboxes to appear ticked in DCT
-- even when a policy lacked that coverage type.
--
-- Root cause:
--   PER_HOME_BUILDING_PAYLOAD serves both seq 7 (HB) and seq 13 (HC) via a
--   UNION of HC_02 (HC policies) + HB_01 (HB-only policies).
--   - HB-only policies (HB_01 branch) were processed by seq 13 (HC template)
--     with Indicator=1 → HC checkbox ticked in DCT even with no HC data.
--   - HC-only policies (HC_02 branch, not in HB_01) were processed by seq 7
--     (HB template) with Indicator=1 → HB checkbox ticked with no HB data.
--
-- Fix applied:
--   1. Added HB_INDICATOR and HC_INDICATOR columns to PER_HOME_BUILDING_PAYLOAD.
--      - HC_02 branch: HC_INDICATOR=1, HB_INDICATOR=CASE EXISTS(HB_01)
--      - HB_01 branch: HC_INDICATOR=0, HB_INDICATOR=1
--   2. Seq 7 template: <Indicator>{HB_INDICATOR}</Indicator>
--   3. Seq 13 template: <Indicator>{HC_INDICATOR}</Indicator>
--
-- Motor (seq 18) is NOT changed — PER_COM_PAYLOAD is INNER JOIN on PM_03
-- so every row represents a genuine motor policy; Indicator=1 is correct.
--
-- ARCHITECTURE NOTE:
--   PP conversion batch runs AGGNE.DEV views → AGGNE.DEV targets only.
--   UAT and main/XML are downstream output flows from the same DEV batch result.
--   One DEV view change covers both DEV and UAT output flows — no separate UAT
--   Snowflake view deploy needed (Section 2 is NOT APPLICABLE).
--
-- DEPLOYMENT ORDER:
--   1. Apply Snowflake DEV view (Section 1) — covers both DEV and UAT output flows
--   2. Apply SQL Server ConversionConfig updates (Section 3)
--   3. Trigger new batch via Aggne middleware — middleware runs full seq 1-18 automatically
-- ══════════════════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 1: SNOWFLAKE — AGGNE.DEV
-- Run in: Snowflake worksheet connected to AGGNE database (DEV schema context)
-- ══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD(
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
    -- ── HB-specific columns (seq 7 RISK_Building_HB) ─────────────────────
    HOMEBUILDINGSLIMIT,   -- {HOMEBUILDINGSLIMIT}  : from HB_02
    LANDLORDPROTECTIONS,  -- {LANDLORDPROTECTIONS} : from HB_02
    MINIMUMRENTALPERIOD,  -- {MINIMUMRENTALPERIOD} : from HB_02
    WEEKLYRENT,           -- {WEEKLYRENT}          : from HB_02
    HBCLMCNT,             -- {HBCLMCNT}            : from Output_Coverage_PER
    HBCLMINCD,            -- {HBCLMINCD}           : from Output_Coverage_PER
    EXPPREM,              -- {EXPPREM}             : HB premium (HMEXPPREM alias)
    -- ── Clause / UW columns ───────────────────────────────────────────────
    HB_CLAUSE,            -- {HB_CLAUSE}           : aggregated from PER_BUILDING_TARGET
    HC_CLAUSE,            -- {HC_CLAUSE}           : aggregated from PER_HC_TARGET
    UW,                   -- {UW}                  : '' default
    LOAD_DATE,
    -- ── v2 2026-07-01: coverage indicator columns (indicator fix) ──────────
    HB_INDICATOR,         -- {HB_INDICATOR}    : 1 if policy has Home Building coverage (HB_01), else 0
    HC_INDICATOR          -- {HC_INDICATOR}    : 1 if policy has Home Contents coverage (HC_02), else 0
) AS

WITH cte_SAMPLE_CBP_LOCATION AS (
    SELECT DISTINCT
        TRIM(T1.PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
        TRIM(T1.CMLNUMBER)        AS CMLNUMBER,
        T1.EXPIRINGID_P
    FROM AGGNE.DEV.Locationdetails_PER T1
    INNER JOIN AGGNE.DEV.SAMPLE_PER T2
        ON TRIM(T1.PUREPOLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
    WHERE T1.EFFECTIVEDATE >= '2026-01-01'
),

cte_COVERAGES AS (
    -- HC_02 branch: policies with Home Contents coverage
    -- v2 2026-07-01: HC_INDICATOR=1, HB_INDICATOR checks HB_01 existence
    SELECT DISTINCT
        HC.PUREPOLICYNUMBER, HC.CMLNUMBER, HC.EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        HC.VOLUNTARYEXCESS,
        HC.ACCIDENTALLOSSORDAMAGE,
        HC.SPECIFIEDITEMSAWAY, HC.UNSPECIFIEDITEMSAWAY, HC.UNSPECIFIEDITEMSAWAYLIMIT,
        HC.ANYITEMSEXCEEDVALUE,
        1 AS HC_INDICATOR,
        CASE WHEN EXISTS (
            SELECT 1 FROM AGGNE.DEV.HB_01 H2
            WHERE TRIM(H2.PUREPOLICYNUMBER) = TRIM(HC.PUREPOLICYNUMBER)
              AND H2.EXPIRINGID_P           = HC.EXPIRINGID_P
        ) THEN 1 ELSE 0 END AS HB_INDICATOR
    FROM AGGNE.DEV.HC_02 HC

    UNION

    -- HB_01 branch: HB-only policies absent from HC_02
    -- v2 2026-07-01: HC_INDICATOR=0, HB_INDICATOR=1
    SELECT DISTINCT
        H.PUREPOLICYNUMBER, H.CMLNUMBER, H.EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        COALESCE(H.VOLUNTARYEXCESS, 0) AS VOLUNTARYEXCESS,
        H.ACCIDENTALLOSSORDAMAGE,
        NULL AS SPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAYLIMIT,
        NULL AS ANYITEMSEXCEEDVALUE,
        0 AS HC_INDICATOR,
        1 AS HB_INDICATOR
    FROM AGGNE.DEV.HB_01 H
    WHERE NOT EXISTS (
        SELECT 1 FROM AGGNE.DEV.HC_02 HC2
        WHERE TRIM(H.PUREPOLICYNUMBER) = TRIM(HC2.PUREPOLICYNUMBER)
          AND H.EXPIRINGID_P           = HC2.EXPIRINGID_P
    )
),

CTE_EXCESS AS (
    SELECT
        CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.CMLNUMBER) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
        T2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        T2.CMLNUMBER,
        T2.EXPIRINGID_P,
        COVERAGE,
        T2.VOLUNTARYEXCESS,
        CASE WHEN T2.ACCIDENTALLOSSORDAMAGE = 'Taken'
             THEN CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR)
             ELSE CAST(CAST(0 AS NUMBER(1,0)) AS VARCHAR)
        END AS ACCIDENTALLOSSORDAMAGE,
        SPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAYLIMIT,
        ANYITEMSEXCEEDVALUE,
        T2.HC_INDICATOR,
        T2.HB_INDICATOR
    FROM cte_SAMPLE_CBP_LOCATION T1
    INNER JOIN cte_COVERAGES T2
        ON  T1.EXPIRINGID_P           = T2.EXPIRINGID_P
        AND TRIM(T1.PUREPOLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
),

CTE_LISTAGG AS (
    SELECT
        ID,
        LISTAGG(CASE WHEN ITR_TYPE = 'Building_SubCov'        THEN PAYLOAD END, '\n') AS SUBCOV,
        LISTAGG(CASE WHEN ITR_TYPE = 'HC_exceed_values'       THEN PAYLOAD END, '\n') AS HC_EXCEED_VALUES,
        LISTAGG(CASE WHEN ITR_TYPE = 'HC_Specified_Contents'  THEN PAYLOAD END, '\n') AS HC_SPECIFIED_CONTENTS,
        CAST(LOAD_DATE AS DATE) AS LOAD_DATE
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE IN ('Building_SubCov', 'HC_exceed_values', 'HC_Specified_Contents')
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID, CAST(LOAD_DATE AS DATE)
),

CTE_BUILDING_CLAUSES AS (
    SELECT
        ID,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS HB_CLAUSE_PAYLOAD
    FROM AGGNE.DEV.PER_BUILDING_TARGET
    WHERE ITR_TYPE = 'HB_CLAUSE'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
),

CTE_HC_CLAUSES AS (
    SELECT
        ID,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS HC_CLAUSE_PAYLOAD
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE = 'HC_CLAUSE'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
)

SELECT DISTINCT
    T1.PUREPOLICYNUMBER,
    T1.COVERAGE,
    CAST(T3.SUBCOV                AS VARCHAR) AS SUBCOV,
    CAST(T3.HC_EXCEED_VALUES      AS VARCHAR) AS HC_EXCEED_VALUES,
    CAST(T3.HC_SPECIFIED_CONTENTS AS VARCHAR) AS HC_SPECIFIED_CONTENTS,
    CAST(CAST(COALESCE(T1.VOLUNTARYEXCESS, 0) AS NUMBER(20,0)) AS VARCHAR) AS VOLUNTARYEXCESS,
    T1.ACCIDENTALLOSSORDAMAGE,
    CASE WHEN T1.SPECIFIEDITEMSAWAY   = 'Taken' THEN 'Taken' ELSE 'Not Taken' END AS SPECIFIEDITEMSAWAY,
    CASE WHEN T1.UNSPECIFIEDITEMSAWAY = 'Taken' THEN 'Taken' ELSE 'Not Taken' END AS UNSPECIFIEDITEMSAWAY,
    CASE WHEN T1.UNSPECIFIEDITEMSAWAYLIMIT = '$2,000 per item up to $10,000 per event'
              THEN '2000peritemupto10000perevent'
         WHEN T1.UNSPECIFIEDITEMSAWAYLIMIT = '$1,250 per item up to $5,000 per event'
              THEN '1250peritemupto5000perevent'
         ELSE ''
    END AS UNSPECIFIEDITEMSAWAYLIMIT,
    CAST(COALESCE(T1.ANYITEMSEXCEEDVALUE, 'No') AS VARCHAR) AS ANYITEMSEXCEEDVALUE,
    CAST(COALESCE(T4.HCCLMCNT,  0) AS VARCHAR) AS HCCLMCNT,
    CAST(COALESCE(T4.HCCLMINCD, 0) AS VARCHAR) AS HCCLMINCD,
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS HBEXPPREM,
    CAST(CAST(COALESCE(T5.HOMEBUILDINGSLIMIT, 0) AS NUMBER(10,0)) AS VARCHAR) AS HOMEBUILDINGSLIMIT,
    CAST(COALESCE(T5.LANDLORDPROTECTIONS, '')                      AS VARCHAR) AS LANDLORDPROTECTIONS,
    CASE TRIM(T5.MINIMUMRENTALPERIOD)
        WHEN 'More than 90 Days' THEN 'Morethan90Days'
        WHEN 'Less than 90 Days' THEN 'Lessthan90Days'
        ELSE CAST(COALESCE(T5.MINIMUMRENTALPERIOD, '') AS VARCHAR)
    END AS MINIMUMRENTALPERIOD,
    CAST(CAST(COALESCE(T5.WEEKLYRENT, 0) AS NUMBER(10,0)) AS VARCHAR) AS WEEKLYRENT,
    CAST(COALESCE(T4.HBCLMCNT,  0) AS VARCHAR) AS HBCLMCNT,
    CAST(COALESCE(T4.HBCLMINCD, 0) AS VARCHAR) AS HBCLMINCD,
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS EXPPREM,
    CAST(COALESCE(T6.HB_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HB_CLAUSE,
    CAST(COALESCE(T7.HC_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HC_CLAUSE,
    CAST('' AS VARCHAR) AS UW,
    CAST(GETDATE() AS DATE) AS LOAD_DATE,
    -- v2 2026-07-01: indicator columns
    CAST(T1.HB_INDICATOR AS VARCHAR) AS HB_INDICATOR,
    CAST(T1.HC_INDICATOR AS VARCHAR) AS HC_INDICATOR

FROM CTE_EXCESS T1
LEFT JOIN AGGNE.DEV.PER_HC_TARGET    T2 ON T1.PUREPOLICYNUMBER = T2.ID
LEFT JOIN CTE_LISTAGG                T3 ON T1.PUREPOLICYNUMBER = T3.ID
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4 ON T1.PUREPOLICYNUMBER = T4.POLICYNUMBER
LEFT JOIN AGGNE.DEV.HB_02            T5 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.PUREPOLICYNUMBER)
                                        AND T1.EXPIRINGID_P             = T5.EXPIRINGID_P
LEFT JOIN CTE_BUILDING_CLAUSES       T6 ON T1.PUREPOLICYNUMBER = T6.ID
LEFT JOIN CTE_HC_CLAUSES             T7 ON T1.PUREPOLICYNUMBER = T7.ID

WHERE COVERAGE = 'Building';


-- ── Verify DEV view ───────────────────────────────────────────────────────
-- Expected: HB-only policies → HB_INDICATOR=1, HC_INDICATOR=0
--           HC-only policies → HB_INDICATOR=0, HC_INDICATOR=1
--           HB+HC policies  → HB_INDICATOR=1, HC_INDICATOR=1
SELECT PUREPOLICYNUMBER,
       HB_INDICATOR, HC_INDICATOR,
       HOMEBUILDINGSLIMIT, ANYITEMSEXCEEDVALUE
FROM   AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
LIMIT  20;


-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 2: NOT APPLICABLE
-- The PP conversion batch runs DEV views → DEV targets only.
-- UAT is a downstream output flow from the same DEV batch — there is no
-- separate UAT Snowflake schema for the conversion run. No UAT view deploy needed.
-- ══════════════════════════════════════════════════════════════════════════



-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 3: SQL SERVER — PolicyConversion DB
-- Run on: SQL Server, database PolicyConversion
-- NOTE: PP_ConversionConfig is shared by DEV and UAT Snowflake runs.
--       Apply once; it affects both environments.
-- ══════════════════════════════════════════════════════════════════════════

-- ── Seq 7 (RISK_Building_HB): replace hardcoded Indicator with {HB_INDICATOR} ──
-- v1 (old): <Indicator>1</Indicator>  — hardcoded
-- v2 (new): <Indicator>{HB_INDICATOR}</Indicator>  — driven by PER_HOME_BUILDING_PAYLOAD
UPDATE dbo.PP_ConversionConfig
SET    ConversionScript = REPLACE(
           ConversionScript,
           '<Indicator>1</Indicator>',
           '<Indicator>{HB_INDICATOR}</Indicator>'
       )
WHERE  SequenceID = 7
  AND  IsActive   = 1
  AND  ConversionScript LIKE '%<Indicator>1</Indicator>%';

-- Verify seq 7 update
SELECT SequenceID, ScriptName,
       CASE WHEN ConversionScript LIKE '%{HB_INDICATOR}%' THEN 'FIXED' ELSE 'NOT UPDATED' END AS Status
FROM   dbo.PP_ConversionConfig
WHERE  SequenceID = 7 AND IsActive = 1;


-- ── Seq 13 (RISK_Building_HC): replace hardcoded Indicator with {HC_INDICATOR} ──
-- v1 (old): <Indicator>1</Indicator>  — hardcoded
-- v2 (new): <Indicator>{HC_INDICATOR}</Indicator>  — driven by PER_HOME_BUILDING_PAYLOAD
UPDATE dbo.PP_ConversionConfig
SET    ConversionScript = REPLACE(
           ConversionScript,
           '<Indicator>1</Indicator>',
           '<Indicator>{HC_INDICATOR}</Indicator>'
       )
WHERE  SequenceID = 13
  AND  IsActive   = 1
  AND  ConversionScript LIKE '%<Indicator>1</Indicator>%';

-- Verify seq 13 update
SELECT SequenceID, ScriptName,
       CASE WHEN ConversionScript LIKE '%{HC_INDICATOR}%' THEN 'FIXED' ELSE 'NOT UPDATED' END AS Status
FROM   dbo.PP_ConversionConfig
WHERE  SequenceID = 13 AND IsActive = 1;


-- ══════════════════════════════════════════════════════════════════════════
-- POST-DEPLOY VALIDATION (Snowflake DEV)
-- Run after re-executing the full batch (seqs 1-18)
-- ══════════════════════════════════════════════════════════════════════════

-- Check: HB-only policy should have HB=1, HC=0 in RISK_Building_HB payload
-- (run after seq 7 re-executes)
SELECT ID, LEFT(PAYLOAD, 200) AS PAYLOAD_PREVIEW
FROM   AGGNE.DEV.PER_BUILDING_TARGET
WHERE  ITR_TYPE = 'RISK_Building_HB'
  AND  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
  AND  PAYLOAD LIKE '%<Indicator>%'
LIMIT  10;

-- Check: HC-only policy should have HB=0, HC=1 in RISK_Building_HC payload
SELECT ID, LEFT(PAYLOAD, 200) AS PAYLOAD_PREVIEW
FROM   AGGNE.DEV.PER_HC_TARGET
WHERE  ITR_TYPE = 'RISK_Building_HC'
  AND  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
  AND  PAYLOAD LIKE '%<Indicator>%'
LIMIT  10;
