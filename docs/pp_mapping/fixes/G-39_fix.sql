-- ============================================================
-- G-39 — Clause descriptions forced ALL CAPS (seq 17, P3)
-- Pure code fix, no decision needed, cosmetic. NOT YET APPLIED.
-- ============================================================

-- ---------- Data ----------
-- SELECT COUNT(*) AS TOTAL,
--   SUM(CASE WHEN DCINPUT = UPPER(DCINPUT) THEN 1 ELSE 0 END) AS ALL_CAPS,
--   SUM(CASE WHEN DCINPUT LIKE '%&%' OR DCINPUT LIKE '%<%' THEN 1 ELSE 0 END) AS UNSAFE
-- FROM AGGNE.DEV.COM_CLAUSE;
-- Result: 1,862 total, 178 ALL_CAPS (case-insensitive text is naturally caps-equal for many short/
-- numeric values, so this isn't 100% — but every one of the 178 is a genuine forced-uppercase
-- description), 4 unsafe (shares G-21, already covered there).

-- ---------- CODE FIX ----------
-- PM_02 build: CLAUSE_DESC = UPPER(CADescription)
-- Replace with: CLAUSE_DESC = CADescription   (carry the original case through — cosmetic only,
-- client-visible on the quote, no functional DCT validation depends on this being uppercase).

-- ---------- Verify after applying ----------
-- SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN DCINPUT = UPPER(DCINPUT) AND DCINPUT <> LOWER(DCINPUT) THEN 1 ELSE 0 END) AS STILL_FORCED_CAPS
-- FROM AGGNE.DEV.COM_CLAUSE;
-- -- target: STILL_FORCED_CAPS should drop to ~0 (excluding genuinely all-caps source text, if any)
