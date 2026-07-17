-- ============================================================
-- G-26 — Premium double-carry: same HMEXPPREM on both HB and HC blocks (seq 7/13, P2)
-- DECISION NEEDED. Affects 1,109 policies (every policy with both HB and HC). NOT YET APPLIED.
-- ============================================================

-- ---------- Data ----------
-- 1,109 of 1,843 HB/HC policies (60.2%) have BOTH an HB block (seq 7, <Premium>{EXPPREM}</Premium>)
-- and an HC block (seq 13, <Premium>{HBEXPPREM}</Premium>) — and both are fed from the exact same
-- Output_Coverage_PER.HMEXPPREM total (the whole home policy's premium, not split by coverage).
-- Sample:
--   SELECT PUREPOLICYNUMBER, EXPPREM AS HB_PREMIUM, HBEXPPREM AS HC_PREMIUM
--   FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD WHERE HB_INDICATOR='1' AND HC_INDICATOR='1' LIMIT 20;
-- confirms both columns carry an identical value per policy.

-- ---------- DECISION NEEDED — Aggne policy team / client ----------
-- Does DCT sum coverage-level <Premium> values into a policy total? If yes, sending the full
-- HMEXPPREM on BOTH blocks would double the reported premium for every HB+HC policy — a
-- customer-facing dollar-amount error, not cosmetic. If DCT instead treats each block's Premium as
-- informational/independent (not summed), the current behavior may be harmless duplication rather
-- than a double-count.
-- No source data currently exists that splits HMEXPPREM into an HB-only and HC-only sub-total —
-- if a true split is required, that also needs to be sourced/confirmed, not invented.

-- ---------- Fix (once confirmed) ----------
-- If DCT sums premiums: need a genuine HB/HC premium split from Pure (ask whether one exists) or
-- a documented allocation rule (e.g. proportional to sum insured) — do not invent a 50/50 split.
-- If DCT does not sum them: no fix needed, document as intentional/harmless and close.

-- ---------- Verify (informational, not a fix target until decision made) ----------
-- SELECT PUREPOLICYNUMBER, EXPPREM AS HB_PREMIUM, HBEXPPREM AS HC_PREMIUM
-- FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD WHERE HB_INDICATOR='1' AND HC_INDICATOR='1' LIMIT 20;
