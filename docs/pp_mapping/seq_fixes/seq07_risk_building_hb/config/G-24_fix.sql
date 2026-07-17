-- ============================================================
-- G-24 — {HOMEBUILDINGSLIMIT} lands in <GlassLimit> (seq 7, P2)
-- DECISION NEEDED. Affects 100% of HB policies (3,054/3,054 rows have this populated). NOT YET APPLIED.
-- ============================================================

-- ---------- Data ----------
-- SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN HOMEBUILDINGSLIMIT IS NULL OR HOMEBUILDINGSLIMIT=0 THEN 1 ELSE 0 END) AS ZERO_BLANK
-- FROM AGGNE.DEV.HB_02;
-- Result: 3,054 total, 0 blank — every single HB policy has a real building-limit number, and that
-- exact number is currently also being sent as <GlassLimit>. Since the building sum insured
-- already flows correctly via the seq 4 sub-coverage iValues, this looks like the same number
-- accidentally reused for a differently-named tag, not a deliberate design choice.

-- ---------- DECISION NEEDED — Aggne policy team / client ----------
-- <GlassLimit> reads like a genuine glass-cover sub-limit (a much smaller dollar figure than a
-- full building sum insured, typically). Confirm:
--   (a) should GlassLimit be blank/omitted (no PP glass-specific limit concept exists), or
--   (b) is there a real, distinct glass limit value in Pure that should be sourced instead of
--       reusing HOMEBUILDINGSLIMIT?
-- Do not guess — sending the wrong number here on every single policy is a meaningful risk if (a)
-- or (b) turns out to be correct and the current value materially differs from intent.

-- ---------- Fix (once confirmed) ----------
-- If (a): seq 7 template — remove {HOMEBUILDINGSLIMIT} from <GlassLimit>, leave it empty.
-- If (b): source the correct glass-limit column instead.

-- ---------- Verify after a decision is made ----------
-- (depends on the decision — re-run the population/value-range check against whatever the correct
-- source turns out to be)
