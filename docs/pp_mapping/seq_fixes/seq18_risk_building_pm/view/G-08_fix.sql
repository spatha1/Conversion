-- ============================================================
-- G-08 fix — RegistrationNumber format not cleaned (seq 18, Motor, P2)
-- VIEW: AGGNE.DEV.PER_COM_PAYLOAD (~line 210)
-- Code-only patch — this view is shared by G-01/G-02/G-04/G-08/G-12/G-42, do not paste a full
-- CREATE OR REPLACE from this file alone or you will drop the other gaps' fixes.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-09, AGGNE.DEV.PER_COM_PAYLOAD, 3,304 vehicle rows):
--   336 rows fail the format check (contain lowercase, spaces, or punctuation).
--   Of those 336: 273 are genuine source-data problems — a VIN, "Unregistered"/"Unreg"/"No Reg",
--   serial/engine/chassis number was typed into the registration field instead of a real rego
--   (e.g. 'VIN NO: KNAF241CMM5096691', 'Unregistered', 'SERIAL NO. 03DF00157102'). No formatting
--   rule turns these into valid registration numbers.
--   The remaining 63 rows are pure formatting issues (case, stray spaces/punctuation around an
--   otherwise-real rego, e.g. 'JRP 087', 'wjd983', '1VU 8JK') — genuinely fixable.
--
--   IMPORTANT: uppercasing + stripping non-alphanumeric characters makes ALL 336 rows pass a
--   naive "^[A-Z0-9]*$" regex check afterward — including the 273 genuine-bad-data rows, since
--   stripping punctuation from 'VIN: KMHP3811STU162796' still yields a clean alphanumeric string
--   'VINKMHP3811STU162796'. The format fix alone would silently hide the real defect from any
--   validation report that only checks character-class format. A content-based check (keyword scan)
--   is required in addition to the formatting fix — see the validation-report suggestion below.
--
-- ┌─── RegistrationNumber (~line 210) ─────────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   CAST(REGISTRATIONNUMBER AS VARCHAR) AS REGISTRATIONNUMBER,
-- │
-- │ NEW CODE:
-- │   UPPER(REGEXP_REPLACE(CAST(REGISTRATIONNUMBER AS VARCHAR), '[^A-Za-z0-9]', '')) AS REGISTRATIONNUMBER,
-- └─────────────────────────────────────────────────────────────────────────────
--
-- Suggested validation-report rule (PR-01) — NOT part of this view, a separate report query:
--   flag any REGISTRATIONNUMBER (pre-format-fix, i.e. from PM_03 directly) containing 'VIN',
--   'ENGINE', 'CHASSIS', 'SERIAL', 'S/N', 'UNREG', or 'NO REG' as WRONG_DATA_TYPE rather than a
--   formatting issue, so the report doesn't read as "our conversion bug" when it's a source data gap.
-- ============================================================


-- ============================================================
-- PRE-VALIDATION — run BEFORE applying (2026-07-09 baseline values shown; re-run for current counts)
-- ============================================================

SELECT COUNT(*) AS TOTAL_VEHICLES,
    SUM(CASE WHEN NOT REGEXP_LIKE(COALESCE(REGISTRATIONNUMBER,''), '^[A-Z0-9]*$') THEN 1 ELSE 0 END) AS INVALID_FORMAT
FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- 2026-07-09 baseline: TOTAL_VEHICLES=3304, INVALID_FORMAT=336

SELECT COUNT(*) AS WRONG_DATA_TYPE_CANDIDATES
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE UPPER(COALESCE(REGISTRATIONNUMBER,'')) LIKE '%VIN%'
   OR UPPER(COALESCE(REGISTRATIONNUMBER,'')) LIKE '%ENGINE%'
   OR UPPER(COALESCE(REGISTRATIONNUMBER,'')) LIKE '%CHASSIS%'
   OR UPPER(COALESCE(REGISTRATIONNUMBER,'')) LIKE '%SERIAL%'
   OR UPPER(COALESCE(REGISTRATIONNUMBER,'')) LIKE '%S/N%'
   OR UPPER(COALESCE(REGISTRATIONNUMBER,'')) LIKE '%UNREG%'
   OR UPPER(COALESCE(REGISTRATIONNUMBER,'')) LIKE '%NO REG%';
-- 2026-07-09 baseline: 273 (these will NOT be resolved by this view fix — they need the
-- validation-report rule above, and manual source correction)


-- ============================================================
-- POST-VALIDATION — run AFTER deploying
-- ============================================================

-- 1) Format check — should now only show the genuine-bad-data population (~273), not 336
SELECT COUNT(*) AS TOTAL_VEHICLES,
    SUM(CASE WHEN NOT REGEXP_LIKE(COALESCE(REGISTRATIONNUMBER,''), '^[A-Z0-9]*$') THEN 1 ELSE 0 END) AS STILL_INVALID_FORMAT
FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- Target: STILL_INVALID_FORMAT = 0 (the format-only issues are fixed; format check alone can no
-- longer distinguish the ~273 genuine-bad-data rows, since stripped punctuation makes them "valid
-- format" too — that's exactly why the separate keyword-based validation-report rule matters)

-- 2) Spot-check the 63 genuinely-fixable rows changed as expected
SELECT REGISTRATIONNUMBER FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE REGISTRATIONNUMBER IN ('JRP087','WJD983','1VU8JK')  -- adjust to real sample regos post-fix
LIMIT 10;

-- 3) Confirm the genuine-bad-data population is unchanged in content (still contains the keywords,
--    just uppercased/stripped of punctuation) so the validation-report rule still catches them
SELECT COUNT(*) FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE REGISTRATIONNUMBER LIKE '%VIN%' OR REGISTRATIONNUMBER LIKE '%ENGINE%'
   OR REGISTRATIONNUMBER LIKE '%CHASSIS%' OR REGISTRATIONNUMBER LIKE '%SERIAL%'
   OR REGISTRATIONNUMBER LIKE '%UNREG%' OR REGISTRATIONNUMBER LIKE '%NOREG%';
-- Target: ~273 (unchanged from pre-validation — confirms these are correctly still flaggable)
-- ============================================================
