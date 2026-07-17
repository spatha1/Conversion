-- ============================================================
-- G-31 — HomeContentsLimits=1 hardcoded, invalid value (seq 13, P1)
-- CONFIRMED via manuscript. Pure code fix, no decision needed. NOT YET APPLIED.
-- ============================================================

-- ---------- CONFIRMED — fresh manuscript check ----------
-- Carrier_PersonalProtectionBase_1_0_0_0.xml line 6602-6611:
--   ContentsAndStocksInput.HomeContentsLimits, type=string
--   caption: "Do you have any individual items exceeding the values set out in the PDS under
--   'Home contents with fixed limits'?"
--   <options><option value="Yes"/><option value="No"/></options>
-- "1" is not a valid option value at all — this isn't a captions-vs-codes mismatch, it's a
-- straightforwardly invalid dropdown value on every single HC policy.

-- ---------- Data ----------
-- SELECT ANYITEMSEXCEEDVALUE, COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD GROUP BY 1;
-- Result: 'Yes' = 167, 'No' = 1,676 (total 1,843 — matches the HC block scope exactly). The view
-- already exposes the correct Yes/No value in {ANYITEMSEXCEEDVALUE}; it's just not wired to this
-- tag.

-- ---------- CODE FIX ----------
-- seq 13 template (PP_ConversionConfig, RISK_Building_HC): <HomeContentsLimits>1</HomeContentsLimits>
-- Replace with: <HomeContentsLimits>{ANYITEMSEXCEEDVALUE}</HomeContentsLimits>
-- Config-only — no view change needed.

-- ---------- Verify after applying ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_TARGET
-- WHERE ITR_TYPE='RISK_Building_HC' AND PAYLOAD LIKE '%<HomeContentsLimits>1</HomeContentsLimits>%';
-- -- target: 0 (no more literal invalid "1" value remaining)
