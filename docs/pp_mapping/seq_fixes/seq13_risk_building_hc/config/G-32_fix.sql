-- ============================================================
-- G-32 — HomeContentsTotal / SpecifiedContentsTotal test-residue values (seq 13, P2)
-- Pure code fix, no decision needed — low urgency (both are DCT readOnly output fields). NOT YET APPLIED.
-- ============================================================

-- ---------- Context ----------
-- seq 13 template hardcodes:
--   <HomeContentsTotal>9100</HomeContentsTotal>
--   <SpecifiedContentsTotal>622221</SpecifiedContentsTotal>
-- on every HC block (1,843 rows, 100% of scope). Both are documented as readOnly *output* fields
-- in DCT (recalculated from the actual line items), so DCT likely overwrites these on load
-- regardless of what's sent — but they read as leftover test/sample values (9100, 622221 are
-- oddly specific, not zeros or blanks) that shouldn't ship as-is.

-- ---------- CODE FIX ----------
-- seq 13 template: remove the hardcoded numbers, leave both tags blank/empty (readOnly output
-- fields should not be pre-populated with fabricated data regardless of whether DCT overwrites
-- them — don't rely on DCT's recalculation as a safety net for shipping test residue).
--   <HomeContentsTotal></HomeContentsTotal>
--   <SpecifiedContentsTotal></SpecifiedContentsTotal>

-- ---------- Verify after applying ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_TARGET
-- WHERE ITR_TYPE='RISK_Building_HC'
--   AND (PAYLOAD LIKE '%9100%' OR PAYLOAD LIKE '%622221%');
-- -- target: 0 (confirms the specific test-residue numbers are gone; note this LIKE check could
-- -- false-positive on unrelated legitimate values containing the same digits — sanity check output)
