-- BUG: HB Premium always $0 (100%), plus HCCLMCNT/HCCLMINCD/HBCLMCNT/HBCLMINCD always 0 too --
-- same root cause pattern as G-42 (Motor Premium), never applied to this view.
--
-- Found 2026-07-15 during a fresh end-to-end re-check of the UAT batch (Clauses/Adjustments/
-- HB/HC/Motor), requested after the client flagged "clauses, adjustments HB and HC and Personal
-- motor seems not right". Confirmed live: 36 of 36 HB Building <Premium> tags show 0.00 in the
-- real UAT XML.
--
-- ROOT CAUSE: PER_HOME_BUILDING_PAYLOAD joins Output_Coverage_PER on
--   T1.PUREPOLICYNUMBER = T4.POLICYNUMBER
-- but T1.PUREPOLICYNUMBER is the COMPOSITE key (PolicyNumber|CMLNumber|EXPIRINGID_P, built in
-- CTE_EXCESS) while T4.POLICYNUMBER is the PLAIN pure policy number -- this comparison can never
-- match, so T4.HMEXPPREM/HCCLMCNT/HCCLMINCD/HBCLMCNT/HBCLMINCD are always NULL -> COALESCE to 0
-- for every row. Identical shape to G-42's original bug in PER_COM_PAYLOAD (fixed 2026-07-10) --
-- that fix was never carried over to this view.
--
-- Verified live before drafting: old join returns 100% NULL (2,995/2,995).
--
-- CORRECTION 2026-07-15: an EARLIER version of this fix (SPLIT_PART only, no TRIM/number cast)
-- was deployed and STILL returned 100% zero on real data -- a simplified standalone proxy query
-- used to "verify" it beforehand happened to type-coerce correctly by accident and didn't catch
-- this. Root cause of the miss: Output_Coverage_PER.POLICYNUMBER carries padding spaces (needs
-- TRIM()), and SPLIT_PART's string result wasn't implicitly coercing against the NUMBER
-- EXPIRINGID_P column (needs TRY_TO_NUMBER()). With both added and tested against the exact live
-- view (not a proxy), the corrected join recovers 2,799 of 3,222 rows (87%) with a real non-zero
-- premium, vs 0 before.
--
-- Fix: same pattern as G-42 -- SPLIT_PART the composite key back to the plain policy number,
-- TRIM the far side, TRY_TO_NUMBER the EXPIRINGID_P comparison. One join changed, nothing else in
-- this view touched. Full DDL re-pulled fresh via GET_DDL this session before editing.

CREATE OR REPLACE VIEW PER_HOME_BUILDING_PAYLOAD(
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
	HB_UW,
	HB_UW_INDICATOR
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
-- FIX (2026-07-15, same pattern as G-42): T1.PUREPOLICYNUMBER is the COMPOSITE key
-- (PolicyNumber|CML|EXPIRINGID_P) but T4.POLICYNUMBER is the PLAIN pure policy number — the old
-- join (T1.PUREPOLICYNUMBER = T4.POLICYNUMBER) never matched, so HMEXPPREM/HCCLMCNT/HCCLMINCD/
-- HBCLMCNT/HBCLMINCD were always NULL -> COALESCE to 0 for every row (confirmed live: 100%).
-- CORRECTED 2026-07-15: first version of this fix (SPLIT_PART only, no TRIM/cast) was deployed
-- and STILL returned 100% zero -- Output_Coverage_PER.POLICYNUMBER has padding spaces requiring
-- TRIM(), and comparing SPLIT_PART's string result directly to the NUMBER EXPIRINGID_P column
-- didn't implicitly coerce -- needed TRY_TO_NUMBER(). Verified live with both added: recovers
-- 2,799 of 3,222 rows (87%) with a real non-zero premium, vs 0 before.
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4
    ON SPLIT_PART(T1.PUREPOLICYNUMBER, '|', 1) = TRIM(T4.POLICYNUMBER)
   AND TRY_TO_NUMBER(SPLIT_PART(T1.PUREPOLICYNUMBER, '|', 3)) = T4.EXPIRINGID_P
LEFT JOIN AGGNE.DEV.HB_02 T5
    ON  TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.PUREPOLICYNUMBER)
    AND T1.EXPIRINGID_P             = T5.EXPIRINGID_P
LEFT JOIN CTE_BUILDING_CLAUSES T6
    ON T1.PUREPOLICYNUMBER = T6.ID
LEFT JOIN CTE_HC_CLAUSES T7
    ON T1.PUREPOLICYNUMBER = T7.ID

WHERE COVERAGE = 'Building';

-- Verify:
SELECT COUNT(*) TOTAL,
    SUM(CASE WHEN EXPPREM IS NULL OR EXPPREM IN ('0','0.00','') THEN 1 ELSE 0 END) ZERO_HB_PREMIUM,
    SUM(CASE WHEN HBEXPPREM IS NULL OR HBEXPPREM IN ('0','0.00','') THEN 1 ELSE 0 END) ZERO_HC_PREMIUM,
    SUM(CASE WHEN HBCLMCNT = '0' THEN 1 ELSE 0 END) ZERO_HB_CLAIMS,
    SUM(CASE WHEN HCCLMCNT = '0' THEN 1 ELSE 0 END) ZERO_HC_CLAIMS
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD;
-- Expected: significant drop from the current 100% zero on EXPPREM.

-- After deploy, regenerate DEV's stored XML to see the fix in real output:
-- CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE);
