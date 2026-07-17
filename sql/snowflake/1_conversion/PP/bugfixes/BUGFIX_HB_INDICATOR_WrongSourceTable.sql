-- BUG: HB_INDICATOR (Home Building coverage indicator, seq 7 <Indicator>{HB_INDICATOR}</Indicator>)
-- is wrong for a large share of policies -- both over- and under-counting -- which matters a lot
-- more than a normal field bug: per the client's Extract Mapper manuscript
-- (Manuscripts/ServerExtract/.../Shared/Carrier_Coverages_ExtractMap.xml), Clarity's extract only
-- picks up a <coverage> block when
--     (written != 0) OR (change != 0) OR (Indicator = 1) OR (@x != '')
-- Our DCT XML never emits <written>, <change>, or an x attribute on <coverage> at all (confirmed
-- live against real generated XML) -- so Indicator = 1 is the ONLY thing that makes Clarity show a
-- Building coverage block at all. A wrong Indicator doesn't just mis-tag a field, it makes the
-- whole coverage disappear from Clarity even though real data is sitting in our XML.
--
-- ROOT CAUSE (found 2026-07-15, investigating a client report of Pure-vs-Clarity mismatches):
-- The original 2026-07-01 indicator fix (PP_DEPLOY_INDICATOR_FIX_20260701.sql) computed
-- HB_INDICATOR as "does ANY row exist in HB_01 for this policy+term", while the actual Building
-- payload fields (HomeBuildingsLimit, LandlordProtections, WeeklyRent, etc.) are pulled from a
-- DIFFERENT table, HB_02. HB_01 and HB_02 are not a current/stale pair -- they're two
-- independently-extracted, only-partially-overlapping populations (of 4,340 HB_01 rows and 3,522
-- HB_02 rows, only 1,273 policy+term keys exist in both). Two distinct problems fall out of this:
--   1. OVER-counting: HB_01 has its own real indicator column, BUILDINGCONTENTS_IND, which the
--      2026-07-01 fix never checked -- it only checked row EXISTENCE. 1,088 of HB_01's 4,340 rows
--      have BUILDINGCONTENTS_IND=0 (only 6% of those have a real HomeBuildingsLimit, vs 94% for
--      BUILDINGCONTENTS_IND=1 -- a clean, trustworthy signal) but were still being counted as
--      HB_INDICATOR=1 just because the row existed.
--   2. UNDER-counting / silent drop: 1,809 real, in-scope (confirmed against SAMPLE_PER) policies
--      have a genuine non-zero HomeBuildingsLimit in HB_02 (sample values $550K-$1.15M) but no
--      matching row in HB_01 at all. Of those, 1,334 at least get a row in this view via the HC_02
--      branch (with HB_INDICATOR wrongly=0 -- confirmed live: 1,338 of 3,217 in-scope rows,
--      i.e. 92% of all HB_INDICATOR=0 rows, have a real non-zero HomeBuildingsLimit). The other
--      475 don't exist in HB_01 OR HC_02, so they get NO ROW AT ALL in the current view -- their
--      Building coverage is completely absent from the XML, not just wrongly flagged.
--
-- FIX: HB_INDICATOR = 1 if EITHER HB_01.BUILDINGCONTENTS_IND = 1 OR HB_02 has a real non-zero
-- HomeBuildingsLimit, for that policy+term -- because neither table alone covers the full real
-- population. Added a third UNION branch for the 475 policies that were previously missing
-- entirely (real HB_02 building data, no HB_01 row, no HC_02 row).
--
-- HC_INDICATOR and Motor's coverage-level Indicator were both checked and are correct (HC_INDICATOR
-- correlates cleanly with real SUBCOV data: 2,516/2,523 vs 0/694; Motor's Indicator is hardcoded
-- literal 1, never at risk of being wrongly 0) -- this fix is HB_INDICATOR / Building only.
--
-- AMENDED same day: added POR_SD_INDICATOR / SPE_SD_INDICATOR. Per the live DCT manuscript
-- (Carrier_PP_AU_VM_1_0_0_0, pulled via ManuScript.getModelImageRq), "Unspecified/Specified Items
-- Away Premises" are NOT flat fields under ContentsAndStocks -- they're distinct nested
-- sub-coverages (coverage[Type="POR_SD"] / coverage[Type="SPE_SD"]), each with their own
-- Indicator. Seq 13's template is being fixed in the same batch (see
-- BUGFIX_HC_POR_SPE_SubCoverage_And_Motor_Excess.sql) to nest {UNSPECIFIEDITEMSAWAY} /
-- {SPECIFIEDITEMSAWAY} under those sub-coverages instead of sending them as flat tags DCT
-- doesn't recognize -- this view change supplies the Indicator each one needs.

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
	HB_UW_INDICATOR,
	POR_SD_INDICATOR,
	SPE_SD_INDICATOR
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
-- FIX (2026-07-15): HB_INDICATOR now driven by HB_01.BUILDINGCONTENTS_IND (the real flag,
-- previously ignored) OR HB_02 having a real non-zero HomeBuildingsLimit -- see header note.
-- Added branch 3 for policies that only exist in HB_02 (previously dropped from the view
-- entirely, not just mis-flagged).
cte_COVERAGES as
(
    -- Branch 1: policies with Home Contents coverage (HC_02) -- HB_INDICATOR now checks both
    -- HB_01's flag and HB_02's real data, not just HB_01 row existence.
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
              AND H2.BUILDINGCONTENTS_IND   = 1
        ) OR EXISTS (
            SELECT 1 FROM AGGNE.DEV.HB_02 H3
            WHERE TRIM(H3.PUREPOLICYNUMBER)        = TRIM(HC.PUREPOLICYNUMBER)
              AND H3.EXPIRINGID_P                   = HC.EXPIRINGID_P
              AND COALESCE(H3.HOMEBUILDINGSLIMIT,0) <> 0
        ) THEN 1 ELSE 0 END AS HB_INDICATOR
    from AGGNE.DEV.HC_02 HC

    UNION

    -- Branch 2: HB_01 policies flagged as real Building coverage, absent from HC_02.
    -- CHANGED: added "AND H.BUILDINGCONTENTS_IND = 1" -- previously any HB_01 row counted,
    -- regardless of the flag (the over-counting half of the bug).
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
    WHERE H.BUILDINGCONTENTS_IND = 1
      AND NOT EXISTS (
        SELECT 1 FROM AGGNE.DEV.HC_02 HC2
        WHERE TRIM(H.PUREPOLICYNUMBER) = TRIM(HC2.PUREPOLICYNUMBER)
          AND H.EXPIRINGID_P           = HC2.EXPIRINGID_P
    )

    UNION

    -- Branch 3 (NEW): HB_02 policies with a real HomeBuildingsLimit, absent from BOTH HC_02 and
    -- a flagged HB_01 row -- previously these got NO row in this view at all (475 real, in-scope
    -- policies confirmed live), so their Building coverage never made it into the DCT XML.
    select distinct
        H2.PUREPOLICYNUMBER, H2.cmlnumber, H2.EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        COALESCE(H2.VOLUNTARYEXCESS, 0)   AS VOLUNTARYEXCESS,
        H2.ACCIDENTALLOSSORDAMAGE,
        NULL AS SPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAYLIMIT,
        NULL AS ANYITEMSEXCEEDVALUE,
        H2.FLOODDAMAGE,
        0 AS HC_INDICATOR,
        1 AS HB_INDICATOR
    from AGGNE.DEV.HB_02 H2
    WHERE COALESCE(H2.HOMEBUILDINGSLIMIT,0) <> 0
      AND NOT EXISTS (
        SELECT 1 FROM AGGNE.DEV.HC_02 HC3
        WHERE TRIM(H2.PUREPOLICYNUMBER) = TRIM(HC3.PUREPOLICYNUMBER)
          AND H2.EXPIRINGID_P           = HC3.EXPIRINGID_P
    )
      AND NOT EXISTS (
        SELECT 1 FROM AGGNE.DEV.HB_01 H4
        WHERE TRIM(H4.PUREPOLICYNUMBER) = TRIM(H2.PUREPOLICYNUMBER)
          AND H4.EXPIRINGID_P           = H2.EXPIRINGID_P
          AND H4.BUILDINGCONTENTS_IND   = 1
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
    CASE WHEN COALESCE(T6.HB_UW_PAYLOAD, '') <> '' THEN '1' ELSE '0' END AS HB_UW_INDICATOR,

    -- NEW: POR_SD ("Portable Items" / Unspecified Items Away) and SPE_SD ("Specified Items" /
    -- Specified Items Away) sub-coverage indicators -- same 'Taken' check already used to derive
    -- the flat SPECIFIEDITEMSAWAY/UNSPECIFIEDITEMSAWAY display values above, just also exposed
    -- as a 1/0 indicator for the new nested sub-coverage blocks (see seq 13 template fix).
    CASE WHEN T1.UNSPECIFIEDITEMSAWAY = 'Taken' THEN '1' ELSE '0' END AS POR_SD_INDICATOR,
    CASE WHEN T1.SPECIFIEDITEMSAWAY   = 'Taken' THEN '1' ELSE '0' END AS SPE_SD_INDICATOR

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
SELECT
    HB_INDICATOR,
    SUM(CASE WHEN HOMEBUILDINGSLIMIT NOT IN ('0','0.00') THEN 1 ELSE 0 END) AS HAS_REAL_LIMIT,
    COUNT(*) TOTAL
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
GROUP BY HB_INDICATOR;
-- Expected: HB_INDICATOR=1 should now capture the large majority of real-limit rows; the
-- HB_INDICATOR=0 / HAS_REAL_LIMIT count (currently 1,338) should drop sharply.

SELECT COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD;
-- Expected: row count should be higher than the current 3,217 (picks up the 475 previously-missing
-- Branch-3 policies, minus whatever the old HB_01-no-flag rows that now correctly drop out).

-- After deploy, regenerate DEV's stored XML to see the fix in real output:
-- CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE);
