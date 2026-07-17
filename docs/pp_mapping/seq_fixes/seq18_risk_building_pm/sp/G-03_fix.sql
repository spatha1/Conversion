-- ============================================================
-- G-03 fix — BodyType: Override-gating mismatch + 34 RedBook names vs 17 DCT codes (seq 18, Motor, P1)
-- STORED PROCEDURE: AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD() (~line 8185, PM_01 build)
-- Two independent problems, two independent fixes. Part 1 confirmed and corrected below
-- (2026-07-10 re-investigation found the impact is far larger than originally scoped). Part 2
-- still needs a client/policy-team decision.
-- ============================================================
--
-- ---------- LIVE RE-INVESTIGATION (2026-07-10) — impact is much bigger than the original draft ----------
-- Original draft only flagged the two unmapped VALUES reaching the view (661 'Other', 10 'Cab
-- Chassis'). Checking live end-to-end found the real problem starts much earlier and is much
-- bigger:
--   PM_01.BodyType (the field this fix targets): 3,580 of 7,312 vehicle rows (49%) blank
--   PM_03.BodyType (after PM_02's "recalculate if blank" pass): 3,582 of 4,360 (82.2%) blank
--   PER_COM_PAYLOAD.BODYTYPE (final payload): 3,217 of 3,304 (97.4%) blank
--
-- ROOT CAUSE CONFIRMED: PM_01's BodyType CASE only computes a value WHEN t3.MVCVOverride = 1 (same
-- root cause pattern as G-06/G-09/G-10). But t3.MVCVBodyType (the plain, non-OV raw column) is
-- NOT actually missing data — live-checked: 3,732 of 7,312 rows (51%) have real values (Wagon 1419,
-- Sedan 612, Hatchback 454, Utility 453, Cab Chassis 233, Coupe 114, Van 84, plus others). PM_01
-- is simply discarding all of it whenever MVCVOverride <> 1.
--
-- PM_02's "Recalculate BodyType if blank" safety net (line ~9060) does NOT rescue this population
-- — its trigger condition is "MVCVBodyType IS NULL OR MVCVBodyType=''", i.e. it only fires when the
-- RAW column is itself blank. For vehicles where MVCVBodyType has real data but PM_01's computed
-- BodyType came out blank (the exact population this gap is about), that condition is false, the
-- recalculation never runs, and the CASE falls through to "ELSE BodyType" — silently keeping the
-- already-blank PM_01 value. This is a second, compounding bug on top of the PM_01 gating issue:
-- the safety net checks the wrong column for its trigger condition.
--
-- ┌─── BodyType (PM_01 build, ~line 8185-8209) ────────────────────────────────
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
-- │       -- ADDED: fallback to the plain (non-override) RedBook value — already free text in the
-- │       -- same vocabulary as the OV lookup's THEN branches (Wagon/Sedan/Hatchback/Utility/etc.)
-- │       ELSE t3.MVCVBodyType
-- │       END AS BodyType
-- └─────────────────────────────────────────────────────────────────────────────
--
-- NOTE: unlike G-06's fields, there is no separate "MVRB"-prefixed raw column for BodyType —
-- t3.MVCVBodyType IS the plain source (confirmed via DESCRIBE TABLE: only MVCVBODYTYPE,
-- MVCVBODYTYPEOV, and the computed BODYTYPE exist on PM_01). Its values are already free text in
-- the same vocabulary as the OV lookup's output (confirmed live: 'Wagon','Sedan','Hatchback',
-- 'Utility','Cab Chassis','Coupe','Van', plus some values with no direct DCT match like 'ROAD' and
-- 'Wellside' — those unmapped values become new instances of this fix's Part 2 problem, see below).
--
-- PM_02's "recalculate if blank" block does NOT need to change for this fix — once PM_01 stops
-- leaving BodyType blank for the ~51% of vehicles with real MVCVBodyType data, PM_02's trigger
-- condition (checking the raw column, not the computed one) becomes far less consequential since
-- the primary computation now succeeds for those rows directly.


-- ---------- 2. DATA/CLIENT DECISION NEEDED — unmapped raw values (unchanged from original draft) ----------
-- sql/snowflake/1_conversion/PP/views/PER_COM_PAYLOAD.sql, BodyType CASE (~line 164-200)
--
-- Once Part 1 is deployed, far more raw Pure values will reach the view's 34-way CASE than today
-- (currently only 'Other'/661 and 'Cab Chassis'/10 get through). Live-confirmed additional raw
-- MVCVBodyType values with no clean DCT path once they start flowing: 'ROAD' (88 rows), 'Wellside'
-- (37 rows), and others not yet enumerated — re-run the verify query below after deploying Part 1
-- to get the true, post-fix list of unmapped values before asking the client.
--
-- ASK AGGNE POLICY TEAM FIRST: has BP already solved this same BodyType mapping? If so, reuse its
-- mapping instead of asking the client to invent one.
--
-- PLACEHOLDER — replace <TBD> once confirmed, do not deploy with these left as TBD:
--   WHEN TRIM(BodyType) = 'Other'       THEN '<TBD_CONFIRM_WITH_POLICY_TEAM_OR_CLIENT>'
--   WHEN TRIM(BodyType) = 'Cab Chassis' THEN '<TBD_CONFIRM_WITH_POLICY_TEAM_OR_CLIENT>'
--   WHEN TRIM(BodyType) = 'ROAD'        THEN '<TBD>'   -- NEW, found during this re-investigation
--   WHEN TRIM(BodyType) = 'Wellside'    THEN '<TBD>'   -- NEW, found during this re-investigation


-- ============================================================
-- PRE-VALIDATION (2026-07-10 baseline)
-- ============================================================

SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN COALESCE(TRIM(BODYTYPE),'')='' THEN 1 ELSE 0 END) AS BLANK
FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- Baseline: TOTAL=3304, BLANK=3217 (97.4%)

SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN COALESCE(TRIM(MVCVBODYTYPE),'')='' THEN 1 ELSE 0 END) AS RAW_BLANK
FROM AGGNE.DEV.PM_01;
-- Baseline: TOTAL=7312, RAW_BLANK=3580 (49%) -- confirms real source data exists for the other 51%


-- ============================================================
-- POST-VALIDATION
-- ============================================================

-- 1) Blank rate should collapse to roughly match the raw-source blank rate, not stay near 100%
SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN COALESCE(TRIM(BODYTYPE),'')='' THEN 1 ELSE 0 END) AS STILL_BLANK
FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- Target: STILL_BLANK drops sharply (from 3,217 toward roughly the true raw-blank population)

-- 2) Full post-fix distribution — use this to build Part 2's final TBD list (the real, complete
--    set of unmapped values once real data is flowing, not just today's tiny visible subset)
SELECT BODYTYPE, COUNT(*),
    CASE WHEN BODYTYPE IN ('B-double','Bus','BusChassis','CabChassis','Cabriolet','Compactor',
        'Convertible','Coupe','Distributor','Dump','ExtraHeavyDuty','Fastback','Hardtop','Hatchback',
        'HeavyDuty','Highway','Liftback','Limousine','Mixer','PrimeMover','Rigid','RoadTrain',
        'Roadster','Sedan','Softtop','StreetSweeper','Targa','Tipper','Trailer','Traytop','Utility',
        'Van','VanWagon','Wagon')
        THEN 'VALID' WHEN COALESCE(TRIM(BODYTYPE),'')='' THEN 'BLANK' ELSE 'STILL UNMAPPED' END AS CHECK_
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
-- Use the 'STILL UNMAPPED' rows to finalize Part 2's TBD list with the client
-- ============================================================
