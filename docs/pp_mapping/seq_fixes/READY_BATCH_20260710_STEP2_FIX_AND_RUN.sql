-- ============================================================
-- READY BATCH 2026-07-10 — STEP 2: correct the misplaced Clause_Desc patch, then rebuild data
-- Run this AFTER confirming the SP/view/orchestrator CREATE OR REPLACE statements from Step 1 are
-- live (they are, per live DDL check 2026-07-10 — 6 of 7 SP patches confirmed correct).
-- ============================================================


-- ┌─── FIX A — REVERT the accidental CM_01 edit (~line 3103-3104, Commercial Motor section) ──────
-- │ This block is OUTSIDE G-39's scope (G-39/COM_CLAUSE only concerns Personal Motor, PM_02) and
-- │ was not supposed to change. Currently live (confirmed via GET_DDL 2026-07-10):
-- │
-- │ CURRENT (accidentally changed, needs reverting):
-- │   -- UPPER(CADescription) AS Clause_Desc
-- │    CADescription AS Clause_Desc,
-- │
-- │ REVERT TO (original):
    UPPER(CADescription) AS Clause_Desc,
-- └─────────────────────────────────────────────────────────────────────────────
-- NOTE: if this CM_01/base CTE is confirmed to feed only Commercial/BP-scope objects (not touched by
-- any PP validation), reverting is precautionary — but safer than leaving an unreviewed, out-of-scope
-- change live. Confirm downstream usage of this CTE before assuming zero impact either way.


-- ┌─── FIX B — APPLY the real G-39 fix at the correct location (~line 8993-8999, PM_02 build) ────
-- │ This is the block that actually feeds AGGNE.DEV.PM_02 -> PM_03 -> COM_CLAUSE (G-39's real
-- │ target) — still unfixed, confirmed via GET_DDL 2026-07-10 (still forcing ALL CAPS).
-- │
-- │ OLD CODE (current, live — find this exact block under the PM_02 CTE, NOT the CM_01 one):
-- │   /* SAS: Clause_Desc = UPCASE(CADescription); */
-- │   UPPER(CADescription) AS Clause_Desc,
-- │
-- │ NEW CODE:
    /* Case preserved — forcing ALL CAPS is cosmetic-only and not required by DCT */
    CADescription AS Clause_Desc,
-- └─────────────────────────────────────────────────────────────────────────────
-- HOW TO FIND THE RIGHT ONE: search the SP for "UPPER(CADescription) AS Clause_Desc" — there are
-- two matches. The wrong one (already fixed, now to revert) sits right after
-- ",/*PURE Field for testing only*/\n\tt5.CADescription" inside a CTE that ends with
-- "FROM AGGNE.DEV.CM_01". The right one (still needs fixing) sits right after
-- "UPPER(CAText) AS Clause_Text," and is followed immediately by the "SAS Result_String logic"
-- CASE block that also uses UPPER(CADescription) for keyword matching (leave those other
-- UPPER(CADescription) calls alone — they're correct case-insensitive searches, not display text).


-- ============================================================
-- STEP 3 — rebuild the actual data (nothing above takes effect until these run)
-- ============================================================
CALL AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD();
-- Rebuilds PM_01, PM_02, PM_03, CM_01, and everything else this SP owns, from raw PURE data,
-- using the corrected logic (BodyType/Cylinders/DriveDescription/InductionType/ImportFlag/
-- EngineSize/GrossVehicleMass fallbacks + the now-correctly-located Clause_Desc fix).

CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE);
-- Rebuilds all 18 seq payloads (including seq 4/10's {INDICATOR} token from the regenerated
-- orchestrator) + PER_CONVERSION_FINAL_LOAD + PER_CONVERSION_FINAL_XML, from the freshly rebuilt
-- PM_03/HB_02/etc and the current PP_ConversionConfig-synced templates.


-- ============================================================
-- STEP 4 — full re-verification (all "code fixed, need to run" rows from the status table)
-- ============================================================

-- 1) PM_01 vehicle-attribute blanks should collapse from the 6,488 baseline
SELECT
    COUNT(*) AS TOTAL_PM_VEHICLE_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 THEN 1 ELSE 0 END) AS AFFECTED_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(BodyType), '') IS NULL THEN 1 ELSE 0 END)          AS STILL_BLANK_BODYTYPE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NumberOfCylinders IS NULL THEN 1 ELSE 0 END)                   AS STILL_NULL_CYLINDERS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(DriveDescription), '') IS NULL THEN 1 ELSE 0 END)  AS STILL_BLANK_DRIVEDESC,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(InductionType), '') IS NULL THEN 1 ELSE 0 END)     AS STILL_BLANK_INDUCTIONTYPE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(ImportFlag), '') IS NULL THEN 1 ELSE 0 END)        AS STILL_BLANK_IMPORTFLAG
FROM AGGNE.DEV.PM_01;
-- Target: all STILL_* columns near 0 (G-03pt1/G-05pt1a/G-06/G-09/G-10)

-- 2) Regression check — true-override rows must be unaffected
SELECT COUNT(*) AS OVERRIDE_ROWS_CHANGED
FROM AGGNE.DEV.PM_01 t3
WHERE t3.MVCVOverride = 1
  AND (
       InductionType <> CASE WHEN t3.MVRBInductionOV=1 THEN 'Aspirated' WHEN t3.MVRBInductionOV=2 THEN 'Turbocharged'
                              WHEN t3.MVRBInductionOV=3 THEN 'Supercharged' WHEN t3.MVRBInductionOV=4 THEN 'Turbo and supercharged'
                              ELSE '' END
    OR EngineSize IS DISTINCT FROM t3.MVRBEngineSizeOV
  );
-- Target: 0

-- 3) PER_COM_PAYLOAD end-to-end — BodyType and NumberOfCylinders blank rates should drop sharply
SELECT COUNT(*) AS TOTAL,
    SUM(CASE WHEN COALESCE(TRIM(BODYTYPE),'')='' THEN 1 ELSE 0 END) AS STILL_BLANK_BODYTYPE,
    SUM(CASE WHEN NUMBEROFCYLINDERS = '0' THEN 1 ELSE 0 END) AS STILL_ZERO_CYLINDERS
FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- Target: STILL_BLANK_BODYTYPE drops from 3,217/3,304 baseline; STILL_ZERO_CYLINDERS drops from
-- 3,105/3,304 toward ~512 (the genuine no-cylinder RedBook-code-11 population, G-05pt2, still open)

-- 4) G-39 — clause caps, now checking the CORRECT (PM_02 -> COM_CLAUSE) population
SELECT COUNT(*) TOTAL,
    SUM(CASE WHEN DCINPUT = UPPER(DCINPUT) AND DCINPUT <> LOWER(DCINPUT) THEN 1 ELSE 0 END) AS STILL_FORCED_CAPS
FROM AGGNE.DEV.COM_CLAUSE;
-- Target: STILL_FORCED_CAPS drops from the 175-178 baseline toward 0 (excluding genuinely all-caps
-- source text)

-- 5) G-47 — seq 4/10 Indicator should now vary in the real payload, not be hardcoded 1
SELECT SUBSTR(PAYLOAD, POSITION('<Indicator>' IN PAYLOAD), 20) AS IND_SNIPPET, COUNT(*)
FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE ITR_TYPE = 'Building_SubCov'
GROUP BY 1 ORDER BY 2 DESC;
-- Target: two buckets now (Indicator=1 and Indicator=0), roughly matching PER_BB_SUBCOVERAGES'
-- known 20,891 / 6,595 split — not 100% Indicator=1 like before
-- ============================================================
