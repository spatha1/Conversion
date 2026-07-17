-- ============================================================
-- DRY-RUN VALIDATED 2026-07-10 — ran both SELECTs below read-only (no table created) against live
-- data before inserting into the SP. Results confirmed correct:
--   HB_02: P00010162 now resolves EXPIRINGID_P=2530787 (current Location 1) with $906,000 — was
--   previously trapped under the stale ID 2178092. Location 2 (2178093, $395,000) unchanged.
--   HC_02: same policy, EXPIRINGID_P=2530787 now shows $202,000 (was trapped under 2178092).
--   Row counts: HB_02 3,054->3,518, HC_02 2,553->2,995 (more rows = picks up locations added since
--   the one-time snapshot, expected). 0 null limits, 0 below-floor violations, 0 bad excess bands,
--   0 duplicate EXPIRINGID_P in HC_02. Safe to insert into the SP.
--
-- INSERTION POINT confirmed live: right after AGGNE.DEV.Sample_PER finishes building (ends
-- "ORDER BY ExpiryDate ,PUREPolicyNumber;") and before ";CREATE OR REPLACE TRANSIENT TABLE
-- AGGNE.DEV.Sample_PER_Applicant AS" begins — search the SP for that exact anchor.
-- ============================================================


-- ============================================================
-- G-49 fix — Rebuild HB_02/HC_02 fresh inside SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD
-- (currently one-time manual loads, never refreshed — see G-49_investigation_note.md for the full
-- root-cause writeup and live evidence).
--
-- NEXT STEP TO ADD to the Pure-to-Write SP — insert these two CREATE OR REPLACE TABLE blocks into
-- SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD (anywhere after AGGNE.DEV.SAMPLE_PER is available — it
-- already is, SAMPLE_PER is a separately-maintained table this SP already reads from for PM_01 etc,
-- confirmed current/live). NOT a patch on existing SP text — a brand new addition, so there is no
-- "OLD CODE" block here, only NEW CODE to insert.
--
-- Translated from the client's original SAS logic:
--   SAS/txt/HomeBuilding_coversionscriptCapricorn.txt   (HB_01 -> HB_02)
--   SAS/txt/HomeContents_coversionscriptCapricorn.txt   (HC_SPITEMS, HC_AWAY, HC_01 -> HC_02)
-- Every business rule below (minimum limits, accidental-damage/landslide capping, landlord
-- clearing, delete conditions) is a direct translation of that SAS — not invented. Source PURE
-- tables and join column confirmed live: PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HOMECONTENTS /
-- PER_RISKSELECTION / PER_SPECIFICITEMS / PER_ITEMSAWAYFROMPREM, all joined via PER_POLICY_BINDER_ID
-- to AGGNE.DEV.SAMPLE_PER.EXPIRINGID_P.
--
-- HC_AWAY and HC_SPITEMS already exist as live tables in AGGNE.DEV and are used elsewhere (HC_AWAY
-- backs G-40's "Specified Items Away From Premises" work) — reused here rather than rebuilt, but
-- NOT YET CONFIRMED whether those two are themselves current/regularly refreshed or share the same
-- one-time-load staleness as HB_02/HC_02. Check before relying on them — flagged, not verified.
-- ============================================================


-- ============================================================
-- HB_02 — translated from HomeBuilding_coversionscriptCapricorn.txt (HB_01 -> HB_02)
-- ============================================================

CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.HB_02 AS
WITH HB_01 AS (
    SELECT
        s.PUREPOLICYNUMBER,
        s.EXPIRINGID_P,
        s.CMLNUMBER,
        s.EFFECTIVEDATE,
        s.COUNTRY,
        s.PRODUCT,
        t3.HCPROTECTION,
        t4.RLHOMEBUILDINGSCONTENTS AS BUILDINGCONTENTS_IND,
        t4.RLMOTORVEHICLES         AS VEHICLES_IND,
        -- standard protection
        t3.HCREBUILDCOST AS HOMEBUILDINGSLIMIT,
        -- optional protections
        t3.HCACCIDENTALDAMAGEHOME,
        CASE WHEN t3.HCACCIDENTALDAMAGEHOME > 0 THEN 'Taken' ELSE 'Not Taken' END AS ACCIDENTALLOSSORDAMAGE,
        t3.HCFLOODPROTECTIONHOME,
        CASE WHEN t3.HCFLOODPROTECTIONHOME > 0 THEN 'Taken' ELSE 'Not Taken' END AS FLOODDAMAGE,
        t3.HCHBLANDLORD,
        CASE WHEN t3.HCHBLANDLORD = 1 THEN 'Taken' ELSE 'Not Taken' END AS LANDLORDPROTECTIONS,
        t3.HCHBMINRENTPERIOD,
        CASE WHEN t3.HCHBMINRENTPERIOD IS NULL THEN ''
             WHEN t3.HCHBMINRENTPERIOD = 1 THEN 'More than 90 Days'
             ELSE 'Less than 90 Days' END AS MINIMUMRENTALPERIOD,
        t3.HCHBWEEKLYRENTAMOUNT AS WEEKLYRENT,
        t3.HCHBLANDSLIDELIMIT   AS LANDSLIDELIMIT,   -- applies to NZ only, see below
        -- excess
        t3.HCHBEXVOLUNTARY,
        CASE
            WHEN t3.HCHBEXVOLUNTARY IS NULL THEN 0
            WHEN t3.HCHBEXVOLUNTARY = 0     THEN 0
            WHEN t3.HCHBEXVOLUNTARY <= 300  THEN 300
            WHEN t3.HCHBEXVOLUNTARY <= 500  THEN 500
            WHEN t3.HCHBEXVOLUNTARY <= 1000 THEN 1000
            WHEN t3.HCHBEXVOLUNTARY <= 1500 THEN 1500
            WHEN t3.HCHBEXVOLUNTARY <= 2000 THEN 2000
            WHEN t3.HCHBEXVOLUNTARY <= 2500 THEN 2500
            ELSE 2500
        END AS VOLUNTARYEXCESS
    FROM AGGNE.DEV.SAMPLE_PER s
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HOMECONTENTS  t3 ON s.EXPIRINGID_P = t3.PER_POLICY_BINDER_ID
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RISKSELECTION t4 ON s.EXPIRINGID_P = t4.PER_POLICY_BINDER_ID
)
SELECT
    PUREPOLICYNUMBER,
    EXPIRINGID_P,
    CMLNUMBER,
    EFFECTIVEDATE,
    COUNTRY,
    PRODUCT,
    ACCIDENTALLOSSORDAMAGE,
    FLOODDAMAGE,
    VOLUNTARYEXCESS,
    -- Minimum limit: HB rebuild cost floors at 40,000
    CASE WHEN HOMEBUILDINGSLIMIT < 40000 THEN 40000 ELSE HOMEBUILDINGSLIMIT END AS HOMEBUILDINGSLIMIT,
    -- Accidental Damage Limit: null if Not Taken; AU caps at 20,000; NZ uses the (post-floor) building limit
    CASE
        WHEN ACCIDENTALLOSSORDAMAGE = 'Not Taken' THEN NULL
        WHEN COUNTRY = 'Australia' AND HCACCIDENTALDAMAGEHOME > 20000 THEN 20000
        WHEN COUNTRY = 'New Zealand' AND HCACCIDENTALDAMAGEHOME > 0
            THEN CASE WHEN HOMEBUILDINGSLIMIT < 40000 THEN 40000 ELSE HOMEBUILDINGSLIMIT END
        ELSE HCACCIDENTALDAMAGEHOME
    END AS ACCIDENTALLOSSORDAMAGELIMIT,
    -- Landslide Limit: NZ only, based on (post-floor) building limit, capped at 300,000
    CASE
        WHEN COUNTRY = 'Australia' THEN NULL
        WHEN (CASE WHEN HOMEBUILDINGSLIMIT < 40000 THEN 40000 ELSE HOMEBUILDINGSLIMIT END) > 300000 THEN 300000
        ELSE (CASE WHEN HOMEBUILDINGSLIMIT < 40000 THEN 40000 ELSE HOMEBUILDINGSLIMIT END)
    END AS LANDSLIDELIMIT,
    -- Landlords: clear rental fields when Not Taken, or when HCProtection=3 (forces Not Taken too)
    CASE WHEN HCPROTECTION = 3 OR LANDLORDPROTECTIONS = 'Not Taken' THEN '' ELSE MINIMUMRENTALPERIOD END AS MINIMUMRENTALPERIOD,
    CASE WHEN HCPROTECTION = 3 OR LANDLORDPROTECTIONS = 'Not Taken' THEN NULL ELSE WEEKLYRENT END AS WEEKLYRENT,
    CASE WHEN HCPROTECTION = 3 THEN 'Not Taken' ELSE LANDLORDPROTECTIONS END AS LANDLORDPROTECTIONS
FROM HB_01
WHERE BUILDINGCONTENTS_IND = 1                              -- "Delete if Home Building is not selected" (was: IF BuildingContents_Ind = 0 THEN DELETE)
  AND NOT (BUILDINGCONTENTS_IND = 1 AND HCPROTECTION = 2);   -- IF BuildingContents_Ind=1 AND HCProtection=2 THEN DELETE


-- ============================================================
-- HC_02 — translated from HomeContents_coversionscriptCapricorn.txt (HC_SPITEMS, HC_AWAY, HC_01 -> HC_02)
-- Reuses the existing AGGNE.DEV.HC_AWAY / AGGNE.DEV.HC_SPITEMS tables rather than rebuilding them —
-- confirm those two are current before relying on this (see header note above).
-- ============================================================

CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.HC_02 AS
WITH HC_01 AS (
    SELECT
        s.PUREPOLICYNUMBER,
        s.EXPIRINGID_P,
        s.CMLNUMBER,
        s.EFFECTIVEDATE,
        s.COUNTRY,
        s.PRODUCT,
        t3.HCPROTECTION,
        t4.RLHOMEBUILDINGSCONTENTS AS BUILDINGCONTENTS_IND,
        t4.RLMOTORVEHICLES         AS VEHICLES_IND,
        -- standard protection
        t3.HCCONTENTSREPLACECOST AS HOMECONTENTSLIMIT,
        t3.HCITEMSEXCEEDINGVALUE,
        CASE WHEN t3.HCITEMSEXCEEDINGVALUE = 1 THEN 'Yes' ELSE 'No' END AS ANYITEMSEXCEEDVALUE,
        -- optional protections
        t3.HCACCIDENTALLOSSDAMAGE,
        CASE WHEN t3.HCACCIDENTALLOSSDAMAGE > 0 THEN 'Taken' ELSE 'Not Taken' END AS ACCIDENTALLOSSORDAMAGE,
        away.DESCRIPTION,
        away.VALUE,
        spitems.DESCRIPTIONSPECIFIED,
        spitems.VALUESPECIFIED,
        t3.HCUNSPECIFIEDITEMS,
        CASE WHEN t3.HCUNSPECIFIEDITEMS IN (1, 2) THEN 'Taken' ELSE 'Not Taken' END AS UNSPECIFIEDITEMSAWAY,
        CASE
            WHEN t3.HCUNSPECIFIEDITEMS = 1 THEN '$1,250 per item up to $5,000 per event'
            WHEN t3.HCUNSPECIFIEDITEMS = 2 THEN '$2,000 per item up to $10,000 per event'
            ELSE ''
        END AS UNSPECIFIEDITEMSAWAYLIMIT,
        t3.HCHOMEHOBBYFARMFLOODPROTECTION,
        CASE WHEN t3.HCHOMEHOBBYFARMFLOODPROTECTION > 0 THEN 'Taken' ELSE 'Not Taken' END AS FLOODDAMAGE,
        t3.HCHCLANDSLIDELIMIT AS LANDSLIDELIMIT,   -- applies to NZ only, see below
        -- excess
        t3.HCHCEXVOLUNTARY,
        CASE
            WHEN t3.HCHCEXVOLUNTARY IS NULL THEN 0
            WHEN t3.HCHCEXVOLUNTARY = 0     THEN 0
            WHEN t3.HCHCEXVOLUNTARY <= 300  THEN 300
            WHEN t3.HCHCEXVOLUNTARY <= 500  THEN 500
            WHEN t3.HCHCEXVOLUNTARY <= 1000 THEN 1000
            WHEN t3.HCHCEXVOLUNTARY <= 1500 THEN 1500
            WHEN t3.HCHCEXVOLUNTARY <= 2000 THEN 2000
            WHEN t3.HCHCEXVOLUNTARY <= 2500 THEN 2500
            ELSE 2500
        END AS VOLUNTARYEXCESS,
        -- SAS "BY ExpiringID_P; ... IF LAST.ExpiringID_P" dedup — Snowflake equivalent
        ROW_NUMBER() OVER (PARTITION BY s.EXPIRINGID_P ORDER BY away.DESCRIPTION NULLS FIRST, spitems.DESCRIPTIONSPECIFIED NULLS FIRST) AS RN_LAST
    FROM AGGNE.DEV.SAMPLE_PER s
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HOMECONTENTS  t3 ON s.EXPIRINGID_P = t3.PER_POLICY_BINDER_ID
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RISKSELECTION t4 ON s.EXPIRINGID_P = t4.PER_POLICY_BINDER_ID
    LEFT JOIN AGGNE.DEV.HC_AWAY    away    ON s.EXPIRINGID_P = away.EXPIRINGID_P
    LEFT JOIN AGGNE.DEV.HC_SPITEMS spitems ON s.EXPIRINGID_P = spitems.EXPIRINGID_P
)
SELECT
    PUREPOLICYNUMBER,
    EXPIRINGID_P,
    CMLNUMBER,
    EFFECTIVEDATE,
    COUNTRY,
    PRODUCT,
    HCPROTECTION,
    BUILDINGCONTENTS_IND,
    VEHICLES_IND,
    HOMECONTENTSLIMIT,
    HCITEMSEXCEEDINGVALUE,
    HCACCIDENTALLOSSDAMAGE,
    ACCIDENTALLOSSORDAMAGE,
    DESCRIPTION,
    VALUE,
    DESCRIPTIONSPECIFIED,
    VALUESPECIFIED,
    HCUNSPECIFIEDITEMS,
    UNSPECIFIEDITEMSAWAY,
    UNSPECIFIEDITEMSAWAYLIMIT,
    HCHOMEHOBBYFARMFLOODPROTECTION,
    FLOODDAMAGE,
    HCHCEXVOLUNTARY,
    VOLUNTARYEXCESS,
    -- Minimum limit (post-floor value kept as its own column, matching the live schema's
    -- HOMECONTENTSLIMIT_NEW alongside the raw HOMECONTENTSLIMIT above)
    CASE WHEN HOMECONTENTSLIMIT < 20000 THEN 20000 ELSE HOMECONTENTSLIMIT END AS HOMECONTENTSLIMIT_NEW,
    -- Accidental Damage Limit: null if Not Taken; AU caps at 20,000; NZ uses the (post-floor) contents limit
    CASE
        WHEN ACCIDENTALLOSSORDAMAGE = 'Not Taken' THEN NULL
        WHEN COUNTRY = 'Australia' AND HCACCIDENTALLOSSDAMAGE > 20000 THEN 20000
        WHEN COUNTRY = 'New Zealand' AND HCACCIDENTALLOSSDAMAGE > 0
            THEN CASE WHEN HOMECONTENTSLIMIT < 20000 THEN 20000 ELSE HOMECONTENTSLIMIT END
        ELSE HCACCIDENTALLOSSDAMAGE
    END AS ACCIDENTALLOSSORDAMAGELIMIT,
    -- Specified items: overridden to Yes/No based on whether a real specified-item row joined in
    CASE WHEN DESCRIPTIONSPECIFIED IS NULL AND VALUESPECIFIED IS NULL THEN 'No' ELSE 'Yes' END AS ANYITEMSEXCEEDVALUE,
    -- Specified items away: Taken/Not Taken based on whether a real away-from-premises row joined in
    CASE WHEN DESCRIPTION IS NULL AND VALUE IS NULL THEN 'Not Taken' ELSE 'Taken' END AS SPECIFIEDITEMSAWAY,
    -- Landslide Limit: NZ only, based on (post-floor) contents limit, capped at 300,000
    CASE
        WHEN COUNTRY = 'Australia' THEN NULL
        WHEN (CASE WHEN HOMECONTENTSLIMIT < 20000 THEN 20000 ELSE HOMECONTENTSLIMIT END) > 300000 THEN 300000
        ELSE (CASE WHEN HOMECONTENTSLIMIT < 20000 THEN 20000 ELSE HOMECONTENTSLIMIT END)
    END AS LANDSLIDELIMIT,
    RN_LAST
FROM HC_01
WHERE BUILDINGCONTENTS_IND = 1                              -- "Delete if Home Contents is not selected" (was: IF BuildingContents_Ind = 0 THEN DELETE)
  AND NOT (BUILDINGCONTENTS_IND = 1 AND HCPROTECTION = 1)    -- IF BuildingContents_Ind=1 AND HCProtection=1 THEN DELETE
  AND RN_LAST = 1;                                           -- keep one row per EXPIRINGID_P (SAS: IF LAST.ExpiringID_P)


-- ============================================================
-- PRE-VALIDATION — confirm the P00010162 mismatch exists today (baseline before this runs)
-- ============================================================
SELECT '['||PUREPOLICYNUMBER||']' AS PADDED_POLICY, EXPIRINGID_P, EFFECTIVEDATE, HOMEBUILDINGSLIMIT
FROM AGGNE.DEV.HB_02 WHERE TRIM(PUREPOLICYNUMBER)='P00010162';
-- Baseline: EXPIRINGID_P 2178093 ($395,000) and 2178092 ($906,000) — 2178092 does not match
-- PER_ACCOUNT_LOC's Location 1 (2530787)


-- ============================================================
-- POST-VALIDATION — after this runs (as part of, or immediately after, Pure-to-Write)
-- ============================================================

-- 1) P00010162 should now show EXPIRINGID_P values matching PER_ACCOUNT_LOC exactly
SELECT h.EXPIRINGID_P AS HB02_ID, a.EXPIRINGID_P AS ACCOUNTLOC_ID, h.HOMEBUILDINGSLIMIT
FROM AGGNE.DEV.HB_02 h
FULL OUTER JOIN AGGNE.DEV.PER_ACCOUNT_LOC a
    ON TRIM(h.PUREPOLICYNUMBER) = 'P00010162' AND a.LEGACYPOLICYNUMBER = 'P00010162'
    AND h.EXPIRINGID_P = a.RISKNUMBER  -- adjust join if RISKNUMBER isn't the right comparison field
WHERE TRIM(h.PUREPOLICYNUMBER) = 'P00010162' OR a.LEGACYPOLICYNUMBER = 'P00010162';
-- Target: every HB_02 EXPIRINGID_P for this policy has a matching PER_ACCOUNT_LOC row

-- 2) Broader check — no policy should have an EXPIRINGID_P in HB_02/HC_02 that doesn't exist
--    anywhere in PER_ACCOUNT_LOC for the same policy (this is the general form of the P00010162 bug)
SELECT COUNT(*) AS ORPHANED_HB02_ROWS
FROM AGGNE.DEV.HB_02 h
WHERE NOT EXISTS (
    SELECT 1 FROM AGGNE.DEV.PER_ACCOUNT_LOC a
    WHERE TRIM(a.LEGACYPOLICYNUMBER) = TRIM(h.PUREPOLICYNUMBER)
      AND CAST(a.PUREPOLICYNUMBER AS VARCHAR) LIKE '%|' || h.EXPIRINGID_P
);
-- Target: 0 (every HB_02 row's EXPIRINGID_P should trace back to a real PER_ACCOUNT_LOC location)
-- ============================================================
