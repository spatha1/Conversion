-- ============================================================
-- READY BATCH 2026-07-10 — Pure-to-Write SP, all fixes with NO open client question
-- STORED PROCEDURE: AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()
-- Covers: G-03 (part 1), G-05 (part 1a), G-06, G-09, G-10, G-39 (SP part)
-- SP is 435,608 chars — too large to paste as a full CREATE OR REPLACE. This is a set of 7
-- code-only patches inside the PM_01/PM_02 build sections (~line 7789-9108). Apply all 7 in one
-- editing pass, then redeploy the whole SP once. Every OLD CODE block below was re-confirmed live
-- against the current SP on 2026-07-10, immediately before writing this file — none of these 7 are
-- deployed yet.
--
-- All 7 share one root cause family: PM_01's Override-driven CASE blocks only compute a value when
-- MVCVOverride = 1 (a RedBook override actually matched); every other vehicle (89% of them, 6,488
-- of 7,312) falls through to blank/NULL instead of the plain non-override RedBook value that PM_01
-- already has on hand. Fix 7 (Clause_Desc) is a separate, unrelated cosmetic bug in the same SP,
-- bundled here purely because it's also a same-SP code-only patch ready with no blocker.
-- ============================================================


-- ┌─── FIX 1 — BodyType (~line 8185-8209) — G-03 part 1 ──────────────────────────
-- │ Impact: PER_COM_PAYLOAD.BODYTYPE blank for 3,217 of 3,304 rows (97.4%) live-confirmed 2026-07-10.
-- │
-- │ OLD CODE (current, live):
-- │   CASE
-- │       WHEN t3.MVCVOverride = 1
-- │           THEN CASE
-- │                   WHEN t3.MVCVBodyTypeOV = 1 THEN 'Sedan'
-- │                   WHEN t3.MVCVBodyTypeOV = 2 THEN 'Coupe'
-- │                   WHEN t3.MVCVBodyTypeOV = 3 THEN 'Wagon'
-- │                   WHEN t3.MVCVBodyTypeOV = 4 THEN 'Hatchback'
-- │                   WHEN t3.MVCVBodyTypeOV = 5 THEN 'Van'
-- │                   WHEN t3.MVCVBodyTypeOV = 6 THEN 'Cab Chassis'
-- │                   WHEN t3.MVCVBodyTypeOV = 7 THEN 'Utility'
-- │                   WHEN t3.MVCVBodyTypeOV = 8 THEN 'Convertible'
-- │                   WHEN t3.MVCVBodyTypeOV = 9 THEN 'Other'
-- │                   ELSE ''
-- │                   END
-- │       ELSE ''
-- │       END AS BodyType
-- │
-- │ NEW CODE:
    CASE
        WHEN t3.MVCVOverride = 1
            THEN CASE
                    WHEN t3.MVCVBodyTypeOV = 1 THEN 'Sedan'
                    WHEN t3.MVCVBodyTypeOV = 2 THEN 'Coupe'
                    WHEN t3.MVCVBodyTypeOV = 3 THEN 'Wagon'
                    WHEN t3.MVCVBodyTypeOV = 4 THEN 'Hatchback'
                    WHEN t3.MVCVBodyTypeOV = 5 THEN 'Van'
                    WHEN t3.MVCVBodyTypeOV = 6 THEN 'Cab Chassis'
                    WHEN t3.MVCVBodyTypeOV = 7 THEN 'Utility'
                    WHEN t3.MVCVBodyTypeOV = 8 THEN 'Convertible'
                    WHEN t3.MVCVBodyTypeOV = 9 THEN 'Other'
                    ELSE ''
                    END
        -- ADDED: fallback to the plain (non-override) RedBook value — already free text in the
        -- same vocabulary as the OV lookup's THEN branches
        ELSE t3.MVCVBodyType
        END AS BodyType
-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 2 — NumberOfCylinders (~line 8210-8240) — G-05 part 1a ────────────────
-- │ OLD CODE (current, live):
-- │   CASE
-- │       WHEN t3.MVCVOverride = 1
-- │           THEN CASE
-- │                   WHEN t3.MVRBCylindersOV = 1 THEN 1   WHEN t3.MVRBCylindersOV = 2 THEN 2
-- │                   WHEN t3.MVRBCylindersOV = 3 THEN 3   WHEN t3.MVRBCylindersOV = 4 THEN 4
-- │                   WHEN t3.MVRBCylindersOV = 5 THEN 5   WHEN t3.MVRBCylindersOV = 6 THEN 6
-- │                   WHEN t3.MVRBCylindersOV = 7 THEN 8   WHEN t3.MVRBCylindersOV = 8 THEN 10
-- │                   WHEN t3.MVRBCylindersOV = 9 THEN 12  WHEN t3.MVRBCylindersOV = 10 THEN 16
-- │                   WHEN t3.MVRBCylindersOV = 11 THEN 0
-- │                   ELSE NULL
-- │                   END
-- │       ELSE NULL
-- │       END AS NumberOfCylinders
-- │
-- │ NEW CODE:
    CASE
        WHEN t3.MVCVOverride = 1
            THEN CASE
                    WHEN t3.MVRBCylindersOV = 1 THEN 1   WHEN t3.MVRBCylindersOV = 2 THEN 2
                    WHEN t3.MVRBCylindersOV = 3 THEN 3   WHEN t3.MVRBCylindersOV = 4 THEN 4
                    WHEN t3.MVRBCylindersOV = 5 THEN 5   WHEN t3.MVRBCylindersOV = 6 THEN 6
                    WHEN t3.MVRBCylindersOV = 7 THEN 8   WHEN t3.MVRBCylindersOV = 8 THEN 10
                    WHEN t3.MVRBCylindersOV = 9 THEN 12  WHEN t3.MVRBCylindersOV = 10 THEN 16
                    WHEN t3.MVRBCylindersOV = 11 THEN 0
                    ELSE NULL
                    END
        -- ADDED: fallback — plain MVRBCylinders is already a real count, just cast it
        ELSE TRY_TO_NUMBER(t3.MVRBCylinders)
        END AS NumberOfCylinders
-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 3 — DriveDescription (~line 8241-8257) — G-06 family ──────────────────
-- │ OLD CODE (current, live):
-- │   CASE
-- │       WHEN t3.MVCVOverride = 1
-- │           THEN CASE
-- │                   WHEN t3.MVRBDriveDescriptionOV = 1 THEN 'Front wheel drive'
-- │                   WHEN t3.MVRBDriveDescriptionOV = 2 THEN 'Rear wheel drive'
-- │                   WHEN t3.MVRBDriveDescriptionOV = 3 THEN '4 wheel drive'
-- │                   WHEN t3.MVRBDriveDescriptionOV = 4 THEN 'N/A'
-- │                   ELSE ''
-- │                   END
-- │       ELSE ''
-- │       END AS DriveDescription
-- │
-- │ NEW CODE:
    CASE
        WHEN t3.MVCVOverride = 1
            THEN CASE
                    WHEN t3.MVRBDriveDescriptionOV = 1 THEN 'Front wheel drive'
                    WHEN t3.MVRBDriveDescriptionOV = 2 THEN 'Rear wheel drive'
                    WHEN t3.MVRBDriveDescriptionOV = 3 THEN '4 wheel drive'
                    WHEN t3.MVRBDriveDescriptionOV = 4 THEN 'N/A'
                    ELSE ''
                    END
        -- ADDED: fallback — plain RedBook description text collapsed to the DCT 4-value enum
        WHEN UPPER(TRIM(t3.MVRBDriveDescription)) = 'FRONT WHEEL DRIVE' THEN 'Front wheel drive'
        WHEN UPPER(TRIM(t3.MVRBDriveDescription)) = 'REAR WHEEL DRIVE'  THEN 'Rear wheel drive'
        WHEN UPPER(TRIM(t3.MVRBDriveDescription)) IN (
                'FOUR WHEEL DRIVE', '4X4', '4X4 CONSTANT', '4X4 DUAL RANGE', '4X4 ON DEMAND'
             ) THEN '4 wheel drive'
        WHEN t3.MVRBDriveDescription IS NOT NULL AND TRIM(t3.MVRBDriveDescription) <> ''
             THEN 'N/A'   -- Chain/Belt/Shaft/4x2/6x2/6x4 and other non-passenger-vehicle drive notations
        ELSE ''
        END AS DriveDescription
-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 4 — InductionType (~line 8258-8276) — G-06 ─────────────────────────────
-- │ OLD CODE (current, live):
-- │   CASE
-- │       WHEN t3.MVCVOverride = 1
-- │           THEN CASE
-- │                   WHEN t3.MVRBInductionOV = 1 THEN 'Aspirated'
-- │                   WHEN t3.MVRBInductionOV = 2 THEN 'Turbocharged'
-- │                   WHEN t3.MVRBInductionOV = 3 THEN 'Supercharged'
-- │                   WHEN t3.MVRBInductionOV = 4 THEN 'Turbo and supercharged'
-- │                   WHEN t3.MVRBInductionOV = 5 THEN ''
-- │                   ELSE ''
-- │                   END
-- │       ELSE ''
-- │       END AS InductionType
-- │
-- │ NEW CODE:
    CASE
        WHEN t3.MVCVOverride = 1
            THEN CASE
                    WHEN t3.MVRBInductionOV = 1 THEN 'Aspirated'
                    WHEN t3.MVRBInductionOV = 2 THEN 'Turbocharged'
                    WHEN t3.MVRBInductionOV = 3 THEN 'Supercharged'
                    WHEN t3.MVRBInductionOV = 4 THEN 'Turbo and supercharged'
                    WHEN t3.MVRBInductionOV = 5 THEN ''
                    ELSE ''
                    END
        -- ADDED: fallback to the plain RedBook value — downstream PER_COM_PAYLOAD already maps
        -- this exact free text to the DCT enum, no further translation needed here
        ELSE t3.MVRBInduction
        END AS InductionType
-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 5 — ImportFlag (~line 8279-8291) — G-09 ────────────────────────────────
-- │ OLD CODE (current, live):
-- │   CASE
-- │       WHEN t3.MVCVOverride = 1
-- │           THEN CASE
-- │                   WHEN t3.MVRBImportFlagOV = 1 THEN 'I'
-- │                   WHEN t3.MVRBImportFlagOV = 2 THEN 'L'
-- │                   WHEN t3.MVRBImportFlagOV = 3 THEN 'N/A '
-- │                   ELSE ''
-- │                   END
-- │       ELSE ''
-- │       END AS ImportFlag
-- │
-- │ NEW CODE:
    CASE
        WHEN t3.MVCVOverride = 1
            THEN CASE
                    WHEN t3.MVRBImportFlagOV = 1 THEN 'I'
                    WHEN t3.MVRBImportFlagOV = 2 THEN 'L'
                    WHEN t3.MVRBImportFlagOV = 3 THEN 'N/A'          -- also trims the trailing space
                    ELSE ''
                    END
        -- ADDED: fallback to the plain RedBook value — live-confirmed already 'I'/'L' text
        ELSE COALESCE(TRIM(t3.MVRBImportFlag), '')
        END AS ImportFlag
-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 6 — EngineSize / GrossVehicleMass (~line 7789-7790) — G-10 ─────────────
-- │ OLD CODE (current, live — no CASE at all, unconditional OV passthrough):
-- │   ,t3.MVRBEngineSizeOV AS EngineSize
-- │   ,TO_NUMBER(REPLACE(t3.MVRBGrossVehMassOV, ',', '')) AS GrossVehicleMass
-- │
-- │ NEW CODE:
    ,CASE
        WHEN t3.MVCVOverride = 1 THEN t3.MVRBEngineSizeOV
        ELSE t3.MVRBEngineSize   -- already NUMBER-typed in PM_01, no cleanup needed
     END AS EngineSize
    ,CASE
        WHEN t3.MVCVOverride = 1 THEN TO_NUMBER(REPLACE(t3.MVRBGrossVehMassOV, ',', ''))
        ELSE t3.MVRBGrossVehMass  -- already NUMBER-typed in PM_01, no cleanup needed
     END AS GrossVehicleMass
-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 7 — Clause_Desc forced ALL CAPS (~line 8902, PM_02 build) — G-39 SP part ─
-- │ Unrelated root cause to fixes 1-6 (Motor clauses, not vehicle attributes) — bundled here as it's
-- │ also a ready, no-question, same-SP code-only patch. 178 of 1,861 clause rows forced ALL CAPS.
-- │
-- │ OLD CODE (current, live):
-- │   /* SAS: Clause_Desc = UPCASE(CADescription); */
-- │   UPPER(CADescription) AS Clause_Desc,
-- │
-- │ NEW CODE:
    /* Case preserved — forcing ALL CAPS is cosmetic-only and not required by DCT */
    CADescription AS Clause_Desc,
-- └─────────────────────────────────────────────────────────────────────────────
-- NOTE: do not touch the OTHER uses of UPPER(CADescription) just below this line (the
-- POSITION(...IN UPPER(CADescription))... keyword-matching logic) — those are correct
-- case-insensitive text searches, unrelated to this bug.


-- ============================================================
-- PRE-VALIDATION — run before applying, to capture today's baseline
-- ============================================================
SELECT
    COUNT(*) AS TOTAL_PM_VEHICLE_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 THEN 1 ELSE 0 END) AS AFFECTED_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(BodyType), '') IS NULL THEN 1 ELSE 0 END)          AS BLANK_BODYTYPE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NumberOfCylinders IS NULL THEN 1 ELSE 0 END)                   AS NULL_CYLINDERS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(DriveDescription), '') IS NULL THEN 1 ELSE 0 END)  AS BLANK_DRIVEDESC,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(InductionType), '') IS NULL THEN 1 ELSE 0 END)     AS BLANK_INDUCTIONTYPE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(ImportFlag), '') IS NULL THEN 1 ELSE 0 END)        AS BLANK_IMPORTFLAG,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND EngineSize IS NULL AND MVRBEngineSize IS NOT NULL THEN 1 ELSE 0 END)       AS FIXABLE_ENGINESIZE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND GrossVehicleMass IS NULL AND MVRBGrossVehMass IS NOT NULL THEN 1 ELSE 0 END) AS FIXABLE_GVM
FROM AGGNE.DEV.PM_01;

SELECT COUNT(*) TOTAL,
    SUM(CASE WHEN DCINPUT = UPPER(DCINPUT) AND DCINPUT <> LOWER(DCINPUT) THEN 1 ELSE 0 END) AS FORCED_CAPS
FROM AGGNE.DEV.COM_CLAUSE;


-- ============================================================
-- POST-VALIDATION — run after the patched SP is redeployed AND re-run
-- (CALL AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD(); then CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE);)
-- ============================================================

-- 1) All blank counts should collapse to ~0 for the 89% override<>1 population
SELECT
    COUNT(*) AS TOTAL_PM_VEHICLE_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 THEN 1 ELSE 0 END) AS AFFECTED_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(BodyType), '') IS NULL THEN 1 ELSE 0 END)          AS STILL_BLANK_BODYTYPE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NumberOfCylinders IS NULL THEN 1 ELSE 0 END)                   AS STILL_NULL_CYLINDERS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(DriveDescription), '') IS NULL THEN 1 ELSE 0 END)  AS STILL_BLANK_DRIVEDESC,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(InductionType), '') IS NULL THEN 1 ELSE 0 END)     AS STILL_BLANK_INDUCTIONTYPE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(ImportFlag), '') IS NULL THEN 1 ELSE 0 END)        AS STILL_BLANK_IMPORTFLAG
FROM AGGNE.DEV.PM_01;
-- Target: all STILL_* columns near 0 (residual = genuinely blank raw source, not a pipeline bug)

-- 2) Regression check — true-override rows (MVCVOverride=1) must be completely unaffected
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

-- 3) Clause caps fix
SELECT COUNT(*) TOTAL,
    SUM(CASE WHEN DCINPUT = UPPER(DCINPUT) AND DCINPUT <> LOWER(DCINPUT) THEN 1 ELSE 0 END) AS STILL_FORCED_CAPS
FROM AGGNE.DEV.COM_CLAUSE;
-- Target: STILL_FORCED_CAPS near 0 (excluding genuinely all-caps source text)

-- 4) End-to-end payload check
SELECT COUNT(*) AS TOTAL,
    SUM(CASE WHEN COALESCE(TRIM(BODYTYPE),'')='' THEN 1 ELSE 0 END) AS STILL_BLANK_BODYTYPE
FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- Target: STILL_BLANK_BODYTYPE drops sharply from the 3,217/3,304 (97.4%) baseline
-- ============================================================
