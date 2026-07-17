-- ============================================================
-- G-06 / G-09 / G-10 fix — Personal Motor vehicle attributes blank when not RedBook-overridden
-- STORED PROCEDURE: AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()  (builds AGGNE.DEV.PM_01)
-- (SP is 435,608 chars total — too large to paste as a full CREATE OR REPLACE. This is a code-only
-- patch: find each OLD CODE block below inside the PM_01 SELECT — around line 8172-8291 — and
-- replace with NEW CODE. No other part of the SP needs to change.)
--
-- ============================================================
-- LIVE-VERIFIED ROOT CAUSE (2026-07-09, queried AGGNE.DEV.PM_01 directly)
-- ============================================================
-- Every one of these fields is only populated when MVCVOverride = 1 (a RedBook override lookup
-- actually matched), reading the paired *OV code column. When MVCVOverride <> 1, the CASE has no
-- ELSE branch back to the plain (non-OV) RedBook column that PM_01 already selects — it just goes
-- blank/NULL. EngineSize/GrossVehicleMass are worse: no CASE at all, they unconditionally read the
-- OV column regardless of MVCVOverride.
--
-- Our original draft (kept below in OLD CODE / superseded reasoning) assumed the fallback should be
-- gated on "Override = 'Yes' AND MVCVOverride = 0", copying the pattern documented in the client's
-- original SAS logic and mirrored (as a CTE called override_fill) in this SP's Commercial Motor
-- section. LIVE-QUERYING PM_01 DISPROVES THAT GATE: OVERRIDE is itself a CASE derived ONLY from
-- MVCVOverride (`WHEN MVCVOverride=1 THEN 'Yes' ELSE ''`, line ~8173-8180) — so OVERRIDE='Yes' AND
-- MVCVOverride=0 can never both be true in this table. Sampling confirmed it: all 6,488 rows with
-- MVCVOverride<>1 show OVERRIDE=''. (The Commercial Motor override_fill CTE that inspired our
-- original draft is, by the same logic, ALSO dead code today — its own Override-redefinition line
-- that would make the condition reachable is commented out at line 3151. Out of scope for PP, but
-- worth flagging to the BP/CM team separately.)
--
-- CORRECTED FIX: drop the Override='Yes' condition entirely. Fall back straight off MVCVOverride:
-- WHEN MVCVOverride = 1 THEN <OV lookup> ELSE <plain RedBook column, cleaned to DCT's format> END.
--
-- IMPACT (live count against AGGNE.DEV.PM_01, 2026-07-09):
--   Total PM vehicle rows:            7,312
--   Rows with MVCVOverride <> 1:      6,488  (89% of all personal-motor vehicles)
--   Of those 6,488 rows, currently blank/NULL:
--     InductionType    : 6,488  (100%)
--     ImportFlag       : 6,488  (100%)
--     NumberOfCylinders: 6,488  (100%)  -- not in the original G-06/G-09/G-10 draft scope, same root cause
--     DriveDescription : 6,488  (100%)  -- not in the original G-06/G-09/G-10 draft scope, same root cause
--     EngineSize       : 3,647  (56%, only when MVRBEngineSizeOV also happened to be NULL)
--     GrossVehicleMass : 2,554  (35%, same reason)
--
-- NumberOfCylinders and DriveDescription share the identical bug pattern and the identical PR-04
-- SAS rule ("...NumberOfCylinders=MVRBCylinders; DriveDescription=MVRBDriveDescription...") but were
-- not covered in the original G-06/G-09/G-10 drafts — added here as FIX 4 / FIX 5 since they're the
-- same root cause, same CTE, same patch. Recommend filing as G-06/G-10 sub-items (or new gap numbers
-- if the tracker needs them split out) — flagging for the user to decide, not deciding unilaterally.
-- ============================================================


-- ┌─── FIX 1 — InductionType (~line 8258-8276) — G-06 ────────────────────────

-- OLD CODE (current, live):
--   CASE
--       WHEN t3.MVCVOverride = 1
--           THEN CASE
--                   WHEN t3.MVRBInductionOV = 1 THEN 'Aspirated'
--                   WHEN t3.MVRBInductionOV = 2 THEN 'Turbocharged'
--                   WHEN t3.MVRBInductionOV = 3 THEN 'Supercharged'
--                   WHEN t3.MVRBInductionOV = 4 THEN 'Turbo and supercharged'
--                   WHEN t3.MVRBInductionOV = 5 THEN ''
--                   ELSE ''
--                   END
--       ELSE ''
--       END AS InductionType

-- NEW CODE (paste in place of the block above):
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
        -- ADDED: fallback to the plain RedBook value (already free text, e.g. 'Aspirated',
        -- 'Turbo Intercooled' — the downstream PER_COM_PAYLOAD view already has a CASE that maps
        -- this exact free text to the DCT InductionType enum, so no further translation needed here)
        ELSE t3.MVRBInduction
        END AS InductionType

-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 2 — ImportFlag (~line 8279-8291) — G-09 ────────────────────────────

-- OLD CODE (current, live):
--   CASE
--       WHEN t3.MVCVOverride = 1
--           THEN CASE
--                   WHEN t3.MVRBImportFlagOV = 1 THEN 'I'
--                   WHEN t3.MVRBImportFlagOV = 2 THEN 'L'
--                   WHEN t3.MVRBImportFlagOV = 3 THEN 'N/A '
--                   ELSE ''
--                   END
--       ELSE ''
--       END AS ImportFlag

-- NEW CODE (paste in place of the block above):
    CASE
        WHEN t3.MVCVOverride = 1
            THEN CASE
                    WHEN t3.MVRBImportFlagOV = 1 THEN 'I'
                    WHEN t3.MVRBImportFlagOV = 2 THEN 'L'
                    WHEN t3.MVRBImportFlagOV = 3 THEN 'N/A'          -- also trims the trailing space (G-09's other finding)
                    ELSE ''
                    END
        -- ADDED: fallback to the plain RedBook value — live-confirmed already 'I'/'L' text, no lookup needed
        ELSE COALESCE(TRIM(t3.MVRBImportFlag), '')
        END AS ImportFlag

-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 3 — EngineSize / GrossVehicleMass (~line 7789-7790) — G-10 ─────────

-- OLD CODE (current, live — no CASE at all, unconditional OV passthrough):
--   ,t3.MVRBEngineSizeOV AS EngineSize
--   ,TO_NUMBER(REPLACE(t3.MVRBGrossVehMassOV, ',', '')) AS GrossVehicleMass

-- NEW CODE (paste in place of the block above):
    ,CASE
        WHEN t3.MVCVOverride = 1 THEN t3.MVRBEngineSizeOV
        ELSE t3.MVRBEngineSize   -- already NUMBER-typed in PM_01, no cleanup needed (live-confirmed)
     END AS EngineSize
    ,CASE
        WHEN t3.MVCVOverride = 1 THEN TO_NUMBER(REPLACE(t3.MVRBGrossVehMassOV, ',', ''))
        ELSE t3.MVRBGrossVehMass  -- already NUMBER-typed in PM_01, no cleanup needed (live-confirmed)
     END AS GrossVehicleMass

-- └─────────────────────────────────────────────────────────────────────────────


-- ┌─── FIX 4 (NEW — same root cause, not in original draft) — NumberOfCylinders ─
-- │ Live-confirmed: MVRBCylinders (plain) is ALREADY a real cylinder count as text ('4','6','8',
-- │ '5','2','1','3','10','12') — NOT a code needing the OV lookup table. Direct CAST works.

-- OLD CODE (current, live, ~line 8210-8240):
--   CASE
--       WHEN t3.MVCVOverride = 1
--           THEN CASE
--                   WHEN t3.MVRBCylindersOV = 1 THEN 1   WHEN t3.MVRBCylindersOV = 2 THEN 2
--                   WHEN t3.MVRBCylindersOV = 3 THEN 3   WHEN t3.MVRBCylindersOV = 4 THEN 4
--                   WHEN t3.MVRBCylindersOV = 5 THEN 5   WHEN t3.MVRBCylindersOV = 6 THEN 6
--                   WHEN t3.MVRBCylindersOV = 7 THEN 8   WHEN t3.MVRBCylindersOV = 8 THEN 10
--                   WHEN t3.MVRBCylindersOV = 9 THEN 12  WHEN t3.MVRBCylindersOV = 10 THEN 16
--                   WHEN t3.MVRBCylindersOV = 11 THEN 0
--                   ELSE NULL
--                   END
--       ELSE NULL
--       END AS NumberOfCylinders

-- NEW CODE (paste in place of the block above):
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


-- ┌─── FIX 5 (NEW — same root cause, not in original draft) — DriveDescription ─
-- │ Live-confirmed: MVRBDriveDescription (plain) holds much more granular text than the 4-value
-- │ DCT enum the OV path produces (Front/Rear/4-wheel-drive/N/A). Distinct values seen (6,488 rows,
-- │ MVCVOverride<>1): Rear Wheel Drive (984), Front Wheel Drive (949), 4X4 Dual Range (541), Four
-- │ Wheel Drive (366), 4X4 Constant (268), 4X4 (231), 4X4 On Demand (177), Chain (64), Belt (41),
-- │ 4x2 (28), Shaft (23), plus small counts of chain/belt sub-variants and 6x2/6x4/4X2 axle
-- │ notations. Chain/Belt/Shaft are motorcycle drivetrain types with no DCT equivalent — mapped to
-- │ 'N/A' (the same bucket the OV path already uses for its own unmapped code). Axle notations
-- │ (4x2/6x2/6x4, 36 rows total) are ambiguous for wheel-drive purposes without Make/Model context —
-- │ also defaulted to 'N/A' rather than guessed; flag to client/business if this volume matters.

-- OLD CODE (current, live, ~line 8241-8257):
--   CASE
--       WHEN t3.MVCVOverride = 1
--           THEN CASE
--                   WHEN t3.MVRBDriveDescriptionOV = 1 THEN 'Front wheel drive'
--                   WHEN t3.MVRBDriveDescriptionOV = 2 THEN 'Rear wheel drive'
--                   WHEN t3.MVRBDriveDescriptionOV = 3 THEN '4 wheel drive'
--                   WHEN t3.MVRBDriveDescriptionOV = 4 THEN 'N/A'
--                   ELSE ''
--                   END
--       ELSE ''
--       END AS DriveDescription

-- NEW CODE (paste in place of the block above):
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


-- ============================================================
-- PRE-VALIDATION — run BEFORE applying the SP patch (values below are what was live-measured on
-- 2026-07-09; re-run to get current-day counts before you deploy)
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_PM_VEHICLE_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 THEN 1 ELSE 0 END) AS AFFECTED_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(InductionType), '') IS NULL THEN 1 ELSE 0 END)   AS BLANK_INDUCTIONTYPE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(ImportFlag), '') IS NULL THEN 1 ELSE 0 END)      AS BLANK_IMPORTFLAG,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NumberOfCylinders IS NULL THEN 1 ELSE 0 END)                 AS NULL_CYLINDERS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(DriveDescription), '') IS NULL THEN 1 ELSE 0 END) AS BLANK_DRIVEDESC,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND EngineSize IS NULL AND MVRBEngineSize IS NOT NULL THEN 1 ELSE 0 END)       AS FIXABLE_ENGINESIZE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND GrossVehicleMass IS NULL AND MVRBGrossVehMass IS NOT NULL THEN 1 ELSE 0 END) AS FIXABLE_GVM
FROM AGGNE.DEV.PM_01;
-- 2026-07-09 baseline: TOTAL=7312, AFFECTED=6488, BLANK_INDUCTIONTYPE=6488, BLANK_IMPORTFLAG=6488,
-- NULL_CYLINDERS=6488, BLANK_DRIVEDESC=6488, FIXABLE_ENGINESIZE=3647, FIXABLE_GVM=2554


-- ============================================================
-- POST-VALIDATION — run AFTER the SP patch is deployed and PM_01/PM_02/PM_03 have been rebuilt
-- ============================================================

-- 1) Same counts as pre-validation — all four "100%" fields should now be 0
SELECT
    COUNT(*) AS TOTAL_PM_VEHICLE_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 THEN 1 ELSE 0 END) AS AFFECTED_ROWS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(InductionType), '') IS NULL THEN 1 ELSE 0 END)   AS BLANK_INDUCTIONTYPE,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(ImportFlag), '') IS NULL THEN 1 ELSE 0 END)      AS BLANK_IMPORTFLAG,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NumberOfCylinders IS NULL THEN 1 ELSE 0 END)                 AS NULL_CYLINDERS,
    SUM(CASE WHEN COALESCE(MVCVOverride,0) <> 1 AND NULLIF(TRIM(DriveDescription), '') IS NULL THEN 1 ELSE 0 END) AS BLANK_DRIVEDESC
FROM AGGNE.DEV.PM_01;
-- Target: BLANK_INDUCTIONTYPE, BLANK_IMPORTFLAG, NULL_CYLINDERS, BLANK_DRIVEDESC all = 0

-- 2) Confirm downstream payload picks the fix up (InductionType text now translates through the
--    existing PER_COM_PAYLOAD CASE instead of arriving blank)
SELECT INDUCTIONTYPE, COUNT(*)
FROM AGGNE.DEV.PER_COM_PAYLOAD
GROUP BY 1 ORDER BY 2 DESC;
-- Target: 'blank' bucket count drops from its pre-fix level; 'Aspirated'/'Turbocharged'/
-- 'Supercharged'/'TurboandSupercharged' buckets grow correspondingly

-- 3) Spot-check 20 affected rows end to end (PM_01 → PER_COM_PAYLOAD)
SELECT p.PUREPOLICYNUMBER,
       p.INDUCTIONTYPE AS PAYLOAD_INDUCTION, m.MVRBInduction AS SRC_INDUCTION,
       p.IMPORTFLAG    AS PAYLOAD_IMPORTFLAG, m.MVRBImportFlag AS SRC_IMPORTFLAG,
       p.NUMBEROFCYLINDERS AS PAYLOAD_CYL, m.MVRBCylinders AS SRC_CYL,
       p.DRIVEDESCRIPTION AS PAYLOAD_DRIVE, m.MVRBDriveDescription AS SRC_DRIVE
FROM AGGNE.DEV.PER_COM_PAYLOAD p
JOIN AGGNE.DEV.PM_01 m ON SPLIT_PART(p.PUREPOLICYNUMBER, '|', 1) = m.PUREPOLICYNUMBER
WHERE COALESCE(m.MVCVOverride,0) <> 1
LIMIT 20;

-- 4) Regression check — MVCVOverride = 1 (true override) rows must be byte-for-byte unchanged
SELECT COUNT(*) AS OVERRIDE_ROWS_CHANGED
FROM AGGNE.DEV.PM_01 t3
WHERE t3.MVCVOverride = 1
  AND (
       InductionType <> CASE WHEN t3.MVRBInductionOV=1 THEN 'Aspirated' WHEN t3.MVRBInductionOV=2 THEN 'Turbocharged'
                              WHEN t3.MVRBInductionOV=3 THEN 'Supercharged' WHEN t3.MVRBInductionOV=4 THEN 'Turbo and supercharged'
                              ELSE '' END
    OR EngineSize IS DISTINCT FROM t3.MVRBEngineSizeOV
  );
-- Target: 0 — the true-override path must be completely unaffected by this patch
-- ============================================================
