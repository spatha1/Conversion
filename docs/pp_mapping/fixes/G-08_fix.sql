-- ============================================================
-- G-08 fix — RegistrationNumber format mask violations (seq 18, Motor, P2)
-- 484 total; NOT a single-cause fix — split into fixable formatting vs. genuine bad data.
-- NOT YET APPLIED.
-- ============================================================

-- ---------- 1. CODE FIX — covers 352 of 484 (73%) ----------
-- sql/snowflake/1_conversion/PP/views/PER_COM_PAYLOAD.sql
-- Current: CAST(REGISTRATIONNUMBER AS VARCHAR)  -- raw pass-through, no cleanup
--
-- Replace with:
--   UPPER(REGEXP_REPLACE(REGISTRATIONNUMBER, '[^A-Za-z0-9]', ''))
-- (uppercase + strip every non-alphanumeric character, not just spaces — safer than a plain
-- REPLACE(' ','') since some values had other separators)

-- ---------- 2. NOT CODE-FIXABLE — ~105+ vehicles, genuine source data problem ----------
-- Real registration numbers were never entered for these vehicles — a VIN, engine number,
-- chassis number, or serial number was typed into the registration field instead
-- (e.g. 'VIN: KMHH351EMPU201141', 'Engine # 06089', 'Serial # XCH3V13D347433').
-- No formatting rule can turn a VIN into a valid registration number — this needs the
-- validation report (PR-01) to flag these for manual correction at the source, not a view fix.
--
-- Suggested validation rule: flag any REGISTRATIONNUMBER containing 'VIN', 'ENGINE', 'CHASSIS',
-- 'SERIAL', or 'S/N' as WRONG_DATA_TYPE rather than a formatting issue, so the report doesn't
-- just say "invalid format" (which reads like our bug) when it's actually a source data gap.

-- ---------- 3. Verify after applying ----------
-- SELECT COUNT(*) AS BAD_REGO FROM AGGNE.DEV.PER_COM_PAYLOAD
-- WHERE NOT REGEXP_LIKE(COALESCE(REGISTRATIONNUMBER,''), '^[A-Z0-9]*$');
-- -- target: only the genuine-bad-data population remains (~105-132), all flagged by validation
