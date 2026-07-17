-- ============================================================
-- G-20 DEPLOY — HB UW Adjustments: wrong-LOB source + output never consumed (seq 5, P1)
-- DECISION MADE 2026-07-13: HB UW adjustments ARE in scope for conversion (user's call, per the
-- original G-20_fix.sql's "if yes, in scope" branch). This is the full implementation.
-- ============================================================
--
-- THREE separate objects need to change, in this order:
--   1. AGGNE.DEV.BUILDING_UW (view)               — repoint from BP-scoped source to PP-scoped
--   2. AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD (view)  — add a NEW HB-specific UW column (see below
--      for why the existing UW column can't be reused)
--   3. PP_ConversionConfig SequenceID=7 (SQL Server) — add {HB_UW} token + real UWAdjustmentIndicator
-- Then: regenerate PP_CONVERSION_RUN from config (step 3 is a config change, same two-source-drift
-- risk as every other config fix this project) and re-run the full batch.
--
-- WHY THE EXISTING {UW} TOKEN CAN'T BE REUSED FOR HB:
-- PER_HOME_BUILDING_PAYLOAD is shared by seq 7 (HB template) and seq 13 (HC template). Its existing
-- UW column (confirmed live 2026-07-13, not from a stale repo copy) aggregates ONLY from
-- AGGNE.DEV.PER_HC_TARGET WHERE ITR_TYPE='BUILDING_UW' — i.e. HC's underwriting adjustments only
-- (seq 11's output). If seq 7's template referenced {UW} pointing at this same column, HB policies
-- would incorrectly show HC's adjustment text — a new cross-contamination bug, not a fix. HB needs
-- its own separate column, sourced from where seq 5's (now-fixed) BUILDING_UW output actually lands:
-- AGGNE.DEV.PER_BUILDING_TARGET WHERE ITR_TYPE='BUILDING_UW' (a different target table than HC's).
--
-- ============================================================
-- PART 1 — AGGNE.DEV.BUILDING_UW
-- ============================================================
--
-- CONFIRMED ROOT CAUSE (from G-20_fix.sql, re-verified 2026-07-13 — live DDL still matches):
--   FROM AGGNE.DEV.Output_UWAdjust_BSP T1 INNER JOIN AGGNE.DEV.LOCATION_BB_COVERAGE T2
--   — both Business Protection (BP) staging objects. 0 of 736 distinct PP policies match.
--
-- FIX: mirror the already-proven pattern from PER_HC_BUILDING_UW (seq 11, HC — confirmed working)
-- and PER_PM_BUILDING_UW (seq 16, Motor — confirmed working): join Output_UWAdjust_PER (COVERAGE=
-- 'HB', confirmed 3,529 real rows waiting, see G-20_fix.sql for the risk-level breakdown) to HB_02
-- (the PP-scoped, per-location table — now rebuilt fresh every run since today's G-49 fix, so this
-- join target is more trustworthy today than it would have been a week ago).
--
-- ┌─── OLD CODE (current, live, re-confirmed 2026-07-13) ─────────────────────────
-- │   create or replace view BUILDING_UW(
-- │       PUREPOLICYNUMBER, LEGACYPOLICYNUMBER, EXPIRINGID_P, CMLNUMBER,
-- │       RECURRINGINDICATOR, UNDERWRITINGDESCRIPTION, ADJUSTMENTDOLLARANDPERCENT,
-- │       ADJUSTMENTSELECTION, COVERAGE
-- │   ) as
-- │   SELECT DISTINCT
-- │       CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
-- │       CAST(T2.PUREPOLICYNUMBER AS VARCHAR) AS LEGACYPOLICYNUMBER,
-- │       CAST(T2.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
-- │       CAST(T2.cmlnumber AS VARCHAR) AS CMLNUMBER,
-- │       CAST('1' AS VARCHAR) AS RECURRINGINDICATOR,
-- │       CAST(REPLACE(REPLACE(T1.UWADJUSTNOTE,  '&', '&amp;'),'''', '''''') AS VARCHAR) AS UnderwritingDescription,
-- │       CAST(T1.UWADJUSTAMOUNT AS VARCHAR) AS AdjustmentDollarAndPercent,
-- │       CAST('1' AS VARCHAR) AS AdjustmentSelection,
-- │       CAST('Building' AS VARCHAR) AS COVERAGE
-- │   FROM AGGNE.DEV.Output_UWAdjust_BSP T1
-- │   INNER JOIN AGGNE.DEV.LOCATION_BB_COVERAGE T2
-- │       ON TRIM(T1.POLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
-- │       AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
-- │       WHERE T1.COVERAGE='BB' AND UWADJUSTAMOUNT IS NOT NULL;
-- └─────────────────────────────────────────────────────────────────────────────

create or replace view BUILDING_UW(
    PUREPOLICYNUMBER, LEGACYPOLICYNUMBER, EXPIRINGID_P, CMLNUMBER,
    RECURRINGINDICATOR, UNDERWRITINGDESCRIPTION, ADJUSTMENTDOLLARANDPERCENT,
    ADJUSTMENTSELECTION, COVERAGE
) as
SELECT DISTINCT
    CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    CAST(T2.PUREPOLICYNUMBER AS VARCHAR) AS LEGACYPOLICYNUMBER,
    CAST(T2.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
    CAST(T2.cmlnumber AS VARCHAR) AS CMLNUMBER,
    CAST('1' AS VARCHAR) AS RECURRINGINDICATOR,
    CAST(REPLACE(REPLACE(T1.UWADJUSTNOTE,  '&', '&amp;'),'''', '''''') AS VARCHAR) AS UnderwritingDescription,
    CAST(T1.UWADJUSTAMOUNT AS VARCHAR) AS AdjustmentDollarAndPercent,
    CAST('1' AS VARCHAR) AS AdjustmentSelection,
    CAST('Building' AS VARCHAR) AS COVERAGE
FROM AGGNE.DEV.Output_UWAdjust_PER T1
INNER JOIN AGGNE.DEV.HB_02 T2
    ON TRIM(T1.POLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
WHERE T1.COVERAGE = 'HB' AND UWADJUSTAMOUNT IS NOT NULL;


-- ============================================================
-- PART 2 — AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD (add HB_UW + HB_UW_INDICATOR columns)
-- ============================================================
-- Base pulled fresh live via GET_DDL 2026-07-13 (10,342 chars) — full text confirmed, not a repo
-- copy (per the G-40 lesson). Three targeted changes from that live text, shown as a full
-- CREATE OR REPLACE below. Everything except the 3 marked spots is untouched live code.
--
-- Change 1: column list — append HB_UW, HB_UW_INDICATOR at the very end (after HC_INDICATOR) so no
--           existing ordinal position shifts for any downstream consumer that isn't name-based.
-- Change 2: CTE_BUILDING_CLAUSES (live alias T6) already reads FROM PER_BUILDING_TARGET WHERE
--           ITR_TYPE = 'HB_CLAUSE' for exactly this policy/location grain — extended to also pull
--           ITR_TYPE = 'BUILDING_UW' in the same CTE (same source table, same ID grain, no new join).
-- Change 3: final SELECT — two new derived columns off the extended T6.

create or replace view PER_HOME_BUILDING_PAYLOAD(
	PUREPOLICYNUMBER,
	COVERAGE,
	SUBCOV,
	HC_EXCEED_VALUES,
	HC_SPECIFIED_CONTENTS,
	VOLUNTARYEXCESS,
	ACCIDENTALLOSSORDAMAGE,
	SPECIFIEDITEMSAWAY,
	UNSPECIFIEDITEMSAWAY,
	UNSPECIFIEDITEMSAWAYLIMIT,
	ANYITEMSEXCEEDVALUE,
	FLOODDAMAGE,
	HCCLMCNT,
	HCCLMINCD,
	HBEXPPREM,
	HOMEBUILDINGSLIMIT,
	LANDLORDPROTECTIONS,
	MINIMUMRENTALPERIOD,
	WEEKLYRENT,
	HBCLMCNT,
	HBCLMINCD,
	EXPPREM,
	HB_CLAUSE,
	HC_CLAUSE,
	UW,
	LOAD_DATE,
	HB_INDICATOR,
	HC_INDICATOR,
	HB_UW,            -- NEW (G-20): {HB_UW} token for seq 7 template
	HB_UW_INDICATOR   -- NEW (G-20): {HB_UW_INDICATOR} token, real UWAdjustmentIndicator value
) as

-- CTE 1: Active PP locations in scope
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

-- CTE 2: Coverage data for Building locations
cte_COVERAGES as
(
    select distinct
        HC.PUREPOLICYNUMBER, HC.cmlnumber, HC.EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        HC.VOLUNTARYEXCESS,
        HC.ACCIDENTALLOSSORDAMAGE,
        HC.SPECIFIEDITEMSAWAY, HC.UNSPECIFIEDITEMSAWAY, HC.UNSPECIFIEDITEMSAWAYLIMIT,
        HC.ANYITEMSEXCEEDVALUE,
        HC.FLOODDAMAGE,
        1 AS HC_INDICATOR,
        CASE WHEN EXISTS (
            SELECT 1 FROM AGGNE.DEV.HB_01 H2
            WHERE TRIM(H2.PUREPOLICYNUMBER) = TRIM(HC.PUREPOLICYNUMBER)
              AND H2.EXPIRINGID_P           = HC.EXPIRINGID_P
        ) THEN 1 ELSE 0 END AS HB_INDICATOR
    from AGGNE.DEV.HC_02 HC

    UNION

    select distinct
        H.PUREPOLICYNUMBER, H.cmlnumber, H.EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        COALESCE(H.VOLUNTARYEXCESS, 0)   AS VOLUNTARYEXCESS,
        H.ACCIDENTALLOSSORDAMAGE,
        NULL AS SPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAYLIMIT,
        NULL AS ANYITEMSEXCEEDVALUE,
        NULL AS FLOODDAMAGE,
        0 AS HC_INDICATOR,
        1 AS HB_INDICATOR
    from AGGNE.DEV.HB_01 H
    WHERE NOT EXISTS (
        SELECT 1 FROM AGGNE.DEV.HC_02 HC2
        WHERE TRIM(H.PUREPOLICYNUMBER) = TRIM(HC2.PUREPOLICYNUMBER)
          AND H.EXPIRINGID_P           = HC2.EXPIRINGID_P
    )
),

-- CTE 3: Build composite ID (PUREPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P)
CTE_EXCESS AS (
    SELECT
        CAST(
            TRIM(T2.PUREPOLICYNUMBER) || '|' ||
            TRIM(T2.cmlnumber)        || '|' ||
            TRIM(T2.EXPIRINGID_P)
        AS VARCHAR) AS PUREPOLICYNUMBER,
        t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        T2.cmlnumber,
        T2.EXPIRINGID_P,
        COVERAGE,
        T2.VOLUNTARYEXCESS,
        CASE WHEN T2.ACCIDENTALLOSSORDAMAGE = 'Taken'
             THEN CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR)
             ELSE CAST(CAST(0 AS NUMBER(1,0)) AS VARCHAR)
        END AS ACCIDENTALLOSSORDAMAGE,
        SPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAYLIMIT,
        ANYITEMSEXCEEDVALUE,
        FLOODDAMAGE,
        T2.HC_INDICATOR,
        T2.HB_INDICATOR
    FROM cte_SAMPLE_CBP_LOCATION T1
    INNER JOIN cte_COVERAGES T2
        ON  T1.EXPIRINGID_P             = T2.EXPIRINGID_P
        AND TRIM(T1.PUREPOLICYNUMBER)   = TRIM(T2.PUREPOLICYNUMBER)
),

-- CTE 4: Aggregate HC sub-payloads already loaded into PER_HC_TARGET
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

-- CTE 5: Aggregate HB clause + HB UW-adjustment rows from PER_BUILDING_TARGET
-- CHANGED (G-20): was HB_CLAUSE only; now also pulls BUILDING_UW in the same CTE/grain.
, CTE_BUILDING_CLAUSES AS (
    SELECT
        ID,
        LISTAGG(CASE WHEN ITR_TYPE = 'HB_CLAUSE'   THEN PAYLOAD END, '\n')
            WITHIN GROUP (ORDER BY PAYLOAD) AS HB_CLAUSE_PAYLOAD,
        LISTAGG(CASE WHEN ITR_TYPE = 'BUILDING_UW' THEN PAYLOAD END, '\n')
            WITHIN GROUP (ORDER BY PAYLOAD) AS HB_UW_PAYLOAD   -- NEW (G-20)
    FROM AGGNE.DEV.PER_BUILDING_TARGET
    WHERE ITR_TYPE IN ('HB_CLAUSE', 'BUILDING_UW')             -- CHANGED: added 'BUILDING_UW'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
)

-- CTE 6: Aggregate HC clause rows from PER_HC_TARGET
, CTE_HC_CLAUSES AS (
    SELECT
        ID,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS HC_CLAUSE_PAYLOAD
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE = 'LOC_HC_CLAUSE'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
)

-- Final SELECT
SELECT distinct
    T1.PUREPOLICYNUMBER,
    T1.COVERAGE,

    CAST(T3.SUBCOV               AS VARCHAR) AS SUBCOV,
    CAST(T3.HC_exceed_values     AS VARCHAR) AS HC_EXCEED_VALUES,
    CAST(T3.HC_Specified_Contents AS VARCHAR) AS HC_SPECIFIED_CONTENTS,

    CAST(CAST(COALESCE(T1.VOLUNTARYEXCESS, 0) AS NUMBER(20,0)) AS VARCHAR) AS VOLUNTARYEXCESS,
    T1.ACCIDENTALLOSSORDAMAGE AS ACCIDENTALLOSSORDAMAGE,
    CASE WHEN T1.SPECIFIEDITEMSAWAY = 'Taken' THEN 'Taken' ELSE 'Not Taken' END AS SPECIFIEDITEMSAWAY,
    CASE WHEN T1.UNSPECIFIEDITEMSAWAY = 'Taken' THEN 'Taken' ELSE 'Not Taken' END AS UNSPECIFIEDITEMSAWAY,
    CASE WHEN T1.UNSPECIFIEDITEMSAWAYLIMIT = '$2,000 per item up to $10,000 per event'
              THEN '2000peritemupto10000perevent'
         WHEN T1.UNSPECIFIEDITEMSAWAYLIMIT = '$1,250 per item up to $5,000 per event'
              THEN '1250peritemupto5000perevent'
         ELSE ''
    END AS UNSPECIFIEDITEMSAWAYLIMIT,
    CAST(COALESCE(T1.ANYITEMSEXCEEDVALUE, 'No') AS VARCHAR) AS ANYITEMSEXCEEDVALUE,
    CAST(COALESCE(T1.FLOODDAMAGE, 'Not Taken') AS VARCHAR) AS FLOODDAMAGE,

    CAST(COALESCE(T4.HCCLMCNT,  0) AS VARCHAR) AS HCCLMCNT,
    CAST(COALESCE(T4.HCCLMINCD, 0) AS VARCHAR) AS HCCLMINCD,
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS HBEXPPREM,

    CAST(CAST(COALESCE(T5.HOMEBUILDINGSLIMIT, 0) AS NUMBER(10, 0)) AS VARCHAR) AS HOMEBUILDINGSLIMIT,
    CAST(COALESCE(T5.LANDLORDPROTECTIONS, '')                       AS VARCHAR) AS LANDLORDPROTECTIONS,
    CASE TRIM(T5.MINIMUMRENTALPERIOD)
        WHEN 'More than 90 Days' THEN 'Morethan90Days'
        WHEN 'Less than 90 Days' THEN 'Lessthan90Days'
        ELSE CAST(COALESCE(T5.MINIMUMRENTALPERIOD, '') AS VARCHAR)
    END AS MINIMUMRENTALPERIOD,
    CAST(CAST(COALESCE(T5.WEEKLYRENT, 0) AS NUMBER(10, 0))          AS VARCHAR) AS WEEKLYRENT,
    CAST(COALESCE(T4.HBCLMCNT,  0) AS VARCHAR) AS HBCLMCNT,
    CAST(COALESCE(T4.HBCLMINCD, 0) AS VARCHAR) AS HBCLMINCD,
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS EXPPREM,

    CAST(COALESCE(T6.HB_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HB_CLAUSE,
    CAST(COALESCE(T7.HC_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HC_CLAUSE,
    CAST(COALESCE(T3.UW_ADJUST, '') AS VARCHAR) AS UW,

    CAST(GETDATE() AS DATE) AS LOAD_DATE,

    CAST(T1.HB_INDICATOR AS VARCHAR) AS HB_INDICATOR,
    CAST(T1.HC_INDICATOR AS VARCHAR) AS HC_INDICATOR,

    -- NEW (G-20, 2026-07-13): HB-specific UW adjustment columns.
    -- Separate from UW above (which is HC-scoped only, from PER_HC_TARGET) — see header note.
    CAST(COALESCE(T6.HB_UW_PAYLOAD, '') AS VARCHAR) AS HB_UW,
    CASE WHEN COALESCE(T6.HB_UW_PAYLOAD, '') <> '' THEN '1' ELSE '0' END AS HB_UW_INDICATOR

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


-- ============================================================
-- PART 3 — PP_ConversionConfig SequenceID=7 (SQL Server) — seq 7 template
-- ============================================================
-- ┌─── OLD (current, live, confirmed 2026-07-13) ──────────────────────────────
-- │   ...
-- │   <UWAdjustmentIndicator>0</UWAdjustmentIndicator>
-- │   ...
-- │   <WeeklyRent>{WEEKLYRENT}</WeeklyRent>
-- │   <ClassCode>
-- │       <APRA>FISR</APRA>
-- │       <Business>BSP</Business>
-- │   </ClassCode>     {HB_CLAUSE}     <ClaimsIncurred>{HBCLMINCD}</ClaimsIncurred>
-- │   <NumberOfClaims>{HBCLMCNT}</NumberOfClaims>
-- │   <Premium>{EXPPREM}</Premium>
-- │   </coverage>
-- │
-- │ NEW:
UPDATE [dbo].[PP_ConversionConfig]
SET ConversionScript = REPLACE(
        REPLACE(ConversionScript,
            '<UWAdjustmentIndicator>0</UWAdjustmentIndicator>',
            '<UWAdjustmentIndicator>{HB_UW_INDICATOR}</UWAdjustmentIndicator>'),
        '{HB_CLAUSE}     <ClaimsIncurred>',
        '{HB_CLAUSE}{HB_UW}     <ClaimsIncurred>')
WHERE SequenceID = 7
  AND ConversionScript LIKE '%<UWAdjustmentIndicator>0</UWAdjustmentIndicator>%';
-- Expected: 1 row affected
-- └─────────────────────────────────────────────────────────────────────────────
-- NOTE: same two-source-drift risk as every config change this project — PP_CONVERSION_RUN must be
-- regenerated from config after this (same regen script used for G-47/ATP-10842).


-- ============================================================
-- PRE-VALIDATION (2026-07-13 baseline — dry-run confirmed live before deploy)
-- ============================================================
SELECT COUNT(*) FROM AGGNE.DEV.BUILDING_UW;
-- Baseline (confirmed 2026-07-13): 877 rows, 0 overlapping real PP policies (wrong-sourced from BP)

SELECT COUNT(*) FROM AGGNE.DEV.Output_UWAdjust_PER WHERE COVERAGE='HB' AND UWADJUSTAMOUNT IS NOT NULL;
-- Baseline (confirmed 2026-07-13): 314 real HB adjustment rows, 301 distinct policies, 0 unmatched
-- against HB_02 (dry-run tested — the new join is clean). NOTE: all 314 have a blank UWADJUSTNOTE
-- (amount-only, no description text). Confirmed this is a pre-existing source-data pattern, not a
-- join defect: HC=243 blank, SU=39 blank, only PM(Motor)=437 has real note text — identical shape
-- to the population G-50 already validated. Expect <UnderwritingDescription></UnderwritingDescription>
-- to render empty with a real AdjustmentDollarAndPercent for all 314 HB rows; this is expected, not a bug.

SELECT COUNT(*) FROM AGGNE.DEV.PER_BUILDING_TARGET WHERE ITR_TYPE='BUILDING_UW';
-- Baseline (confirmed 2026-07-13): 877 rows (stale, from the old BSP-sourced view) — will drop to
-- 314 once BUILDING_UW is repointed AND SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD is re-run.


-- ============================================================
-- POST-VALIDATION — after all 3 parts deployed + SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD() re-run
-- + PP_CONVERSION_RUN regenerated from config + re-run
-- ============================================================

-- 1) BUILDING_UW now returns real PP-scoped rows
SELECT COUNT(*) FROM AGGNE.DEV.BUILDING_UW;
-- CONFIRMED live 2026-07-13: 314 rows (exact dry-run match)
SELECT COUNT(*) FROM (SELECT DISTINCT TRIM(LEGACYPOLICYNUMBER) AS POL FROM AGGNE.DEV.BUILDING_UW
    INTERSECT SELECT DISTINCT TRIM(LEGACYPOLICYNUMBER) AS POL FROM AGGNE.DEV.PER_ACCOUNT_LOC);
-- NOTE: LEGACYPOLICYNUMBER must be TRIM()'d on both sides — BUILDING_UW's LEGACYPOLICYNUMBER column
-- (unlike its composite PUREPOLICYNUMBER key) is not trimmed in the view definition, so it carries
-- trailing padding. Untrimmed comparison falsely shows 0 overlap. Confirmed live 2026-07-13: 297
-- real policies overlap once trimmed.

-- 2) Real payload check — UWAdjustmentIndicator no longer hardcoded 0 for every policy
SELECT SUBSTR(PAYLOAD, POSITION('<UWAdjustmentIndicator>' IN PAYLOAD), 30), COUNT(*)
FROM AGGNE.DEV.PER_BUILDING_TARGET WHERE ITR_TYPE='RISK_Building_HB'
GROUP BY 1 ORDER BY 2 DESC;
-- Target: two buckets now (0 and 1), not 100% hardcoded 0

-- 3) Real payload check — HB UW adjustment text actually appears for at least some policies
SELECT COUNT(*) FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE ITR_TYPE='RISK_Building_HB' AND PAYLOAD LIKE '%<UnderwritingAdjustment>%<Type>Building%'
  AND PAYLOAD NOT LIKE '%<UnderwritingAdjustment>%<Type>Building%</Type>%<AdjustmentDollarAndPercent></AdjustmentDollarAndPercent>%';
-- Target: > 0
-- ============================================================
