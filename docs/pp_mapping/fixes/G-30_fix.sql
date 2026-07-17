-- ============================================================
-- G-30 — FloodDamage=Taken hardcoded (seq 13, P2)
-- Pure code fix, no decision needed. Large confirmed live impact. NOT YET APPLIED.
-- ============================================================

-- ---------- Data ----------
-- SELECT FLOODDAMAGE, COUNT(*) FROM AGGNE.DEV.HC_02 GROUP BY 1 ORDER BY 2 DESC;
-- Result: 'Not Taken' = 2,008 (78.7%), 'Taken' = 545 (21.3%).
-- HC_02.FLOODDAMAGE already carries the real Taken/NotTaken status (it already correctly drives
-- the seq 10 flood sub-coverage sValue) — the coverage-level tag just hardcodes "Taken" instead of
-- reading the same column. 2,008 of 2,553 HC policies (78.7%) are told at coverage level that they
-- have flood cover when they actually don't.

-- ---------- CODE FIX ----------
-- seq 13 template (PP_ConversionConfig, RISK_Building_HC): <FloodDamage>Taken</FloodDamage>
-- Replace with: <FloodDamage>{FLOODDAMAGE}</FloodDamage>
-- (the view needs to expose FLOODDAMAGE as a token if it doesn't already — confirm column name
-- matches HC_02.FLOODDAMAGE exactly, values are already 'Taken'/'Not Taken' text matching DCT's
-- expected form per the seq 10 sValue usage.)

-- ---------- Verify after applying ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_TARGET
-- WHERE ITR_TYPE='RISK_Building_HC' AND PAYLOAD LIKE '%<FloodDamage>Taken</FloodDamage>%'
-- GROUP BY 1;
-- -- compare against the true 545/2,553 Taken count — target: emitted Taken count matches HC_02
