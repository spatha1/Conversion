-- ============================================================
-- G-12 fix — VehicleType: unvalidated ELSE passthrough + 4 structurally-invalid captions (seq 18, P2)
-- VIEW: AGGNE.DEV.PER_COM_PAYLOAD (~line 239-255)
-- Code-only patch — this view is shared by G-01/G-02/G-04/G-08/G-12/G-42, do not paste a full
-- CREATE OR REPLACE from this file alone or you will drop the other gaps' fixes.
-- ============================================================
--
-- CONTEXT (manuscript CoverageLibrary line 30891-30919): VehicleInput.VehicleType has TWO
-- <options> blocks — one gated on VehicleInfoOverride=1 (9 codes: PassengerVehicle,
-- LightCommercial, HeavyCommercial, Motorcycle, Trailer, CamperVan, Caravan, Forklift, TowTruck),
-- one gated on Override=0 (adds MobileEquipment, Tractor, Transporter, HeavyVehicle — 13 total).
-- OVERRIDE is hardcoded to '1' for every converted vehicle (PP-CF-26) — the Override=0 branch can
-- structurally never apply in this pipeline, so MobileEquipment/Tractor/Transporter/HeavyVehicle
-- are not valid codes to send, ever. The current CASE treats all 13 as equally valid and its ELSE
-- forwards whatever raw text Pure sends, completely unvalidated.
--
-- LIVE-VERIFIED (2026-07-09, AGGNE.DEV.PER_COM_PAYLOAD, 3,304 rows): 0 rows currently use
-- MobileEquipment/Tractor/Transporter/HeavyVehicle or hit the raw ELSE — this is a latent defect,
-- not a live incident. Current distribution: PassengerVehicle 2689, Caravan 200, Motorcycle 174,
-- Trailer 132, HeavyCommercial 91, CamperVan 13, Forklift 3, LightCommercial 2 (all 9-code-set
-- valid; TowTruck currently 0 rows). Fixing now is hardening against future/new source data, not a
-- correction of current output.
--
-- ┌─── VehicleType (~line 239-255) ────────────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   CASE
-- │       WHEN TRIM(VEHICLETYPE) = 'Passenger Vehicle'  THEN 'PassengerVehicle'
-- │       WHEN TRIM(VEHICLETYPE) = 'Caravan'            THEN 'Caravan'
-- │       WHEN TRIM(VEHICLETYPE) = 'Camper Van'         THEN 'CamperVan'
-- │       WHEN TRIM(VEHICLETYPE) = 'Trailer'            THEN 'Trailer'
-- │       WHEN TRIM(VEHICLETYPE) = 'Motorcycle'         THEN 'Motorcycle'
-- │       WHEN TRIM(VEHICLETYPE) = 'Light Commercial'   THEN 'LightCommercial'
-- │       WHEN TRIM(VEHICLETYPE) = 'Heavy Commercial'   THEN 'HeavyCommercial'
-- │       WHEN TRIM(VEHICLETYPE) = 'Heavy Vehicle'      THEN 'HeavyVehicle'          -- invalid (Override=0-only code)
-- │       WHEN TRIM(VEHICLETYPE) = 'Mobile Equipment'   THEN 'MobileEquipment'       -- invalid (Override=0-only code)
-- │       WHEN TRIM(VEHICLETYPE) = 'Forklift'           THEN 'Forklift'
-- │       WHEN TRIM(VEHICLETYPE) = 'Tow Truck'          THEN 'TowTruck'
-- │       WHEN TRIM(VEHICLETYPE) = 'Transporter'        THEN 'Transporter'          -- invalid (Override=0-only code)
-- │       WHEN TRIM(VEHICLETYPE) = 'Tractor'            THEN 'Tractor'              -- invalid (Override=0-only code)
-- │       WHEN VEHICLETYPE IS NULL OR TRIM(VEHICLETYPE) = '' THEN 'PassengerVehicle'  -- 32 blank policies default to PassengerVehicle
-- │       ELSE VEHICLETYPE   -- raw, unvalidated passthrough
-- │       END AS VEHICLETYPE,
-- │
-- │ NEW CODE:
-- │   CASE
-- │       WHEN TRIM(VEHICLETYPE) = 'Passenger Vehicle'  THEN 'PassengerVehicle'
-- │       WHEN TRIM(VEHICLETYPE) = 'Caravan'            THEN 'Caravan'
-- │       WHEN TRIM(VEHICLETYPE) = 'Camper Van'         THEN 'CamperVan'
-- │       WHEN TRIM(VEHICLETYPE) = 'Trailer'            THEN 'Trailer'
-- │       WHEN TRIM(VEHICLETYPE) = 'Motorcycle'         THEN 'Motorcycle'
-- │       WHEN TRIM(VEHICLETYPE) = 'Light Commercial'   THEN 'LightCommercial'
-- │       WHEN TRIM(VEHICLETYPE) = 'Heavy Commercial'   THEN 'HeavyCommercial'
-- │       WHEN TRIM(VEHICLETYPE) = 'Forklift'           THEN 'Forklift'
-- │       WHEN TRIM(VEHICLETYPE) = 'Tow Truck'          THEN 'TowTruck'
-- │       WHEN VEHICLETYPE IS NULL OR TRIM(VEHICLETYPE) = '' THEN 'PassengerVehicle'  -- still pending explicit client sign-off, unrelated to this gap
-- │       ELSE NULL   -- was: ELSE VEHICLETYPE (raw passthrough) — do not forward an unvalidated/
-- │                   -- invalid code; let the validation report (PR-01) flag it instead
-- │       END AS VEHICLETYPE,
-- └─────────────────────────────────────────────────────────────────────────────
--
-- Not resolved by this fix (pre-existing, separate topic): the blank-defaults-to-PassengerVehicle
-- rule is still awaiting explicit client sign-off — left unchanged here, not part of G-12.
-- ============================================================


-- ============================================================
-- PRE-VALIDATION — run BEFORE applying (2026-07-09 baseline; re-run for current counts)
-- ============================================================

SELECT VEHICLETYPE, COUNT(*) FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
-- 2026-07-09 baseline: PassengerVehicle 2689, Caravan 200, Motorcycle 174, Trailer 132,
-- HeavyCommercial 91, CamperVan 13, Forklift 3, LightCommercial 2 — 0 rows currently in the
-- 4 invalid codes or raw ELSE (confirms this is hardening, not a live-defect correction)


-- ============================================================
-- POST-VALIDATION — run AFTER deploying
-- ============================================================

SELECT VEHICLETYPE, COUNT(*),
    CASE WHEN VEHICLETYPE IN ('PassengerVehicle','LightCommercial','HeavyCommercial','Motorcycle',
                               'Trailer','CamperVan','Caravan','Forklift','TowTruck') THEN 'VALID'
         WHEN VEHICLETYPE IS NULL THEN 'FLAGGED FOR VALIDATION REPORT'
         ELSE 'STILL INVALID' END AS CHECK_RESULT
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
-- Target: 0 'STILL INVALID' rows; distribution otherwise unchanged from pre-validation since
-- today's live data has no rows in the 4 removed codes
-- ============================================================
