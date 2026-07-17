-- ============================================================
-- G-35 — Fabricated underwriting/risk-assessment answers hardcoded (seq 14, P2)
-- DECISION NEEDED — cannot determine correct values from code or data alone. NOT YET APPLIED.
-- ============================================================

-- ---------- Confirmed scope ----------
-- seq 14 template hardcodes these risk-assessment answers on every single risk node (1,399/1,399,
-- 100%), with no source column backing any of them:
--   ExternalDoors=1, SecurityAccessibleWindows=1, SecurityAlarm=0,
--   LocationConnectedToTownWaterMain=0, StoreFlammableGoods=0, IsAusStandardFollowed=1
-- Unlike G-33 (SICCode) these aren't classification codes with a sensible "leave blank" fallback —
-- they're factual yes/no assertions about a specific property (does it have external doors, is
-- there a security alarm, etc.) being asserted identically for every policy regardless of truth.

-- ---------- DECISION NEEDED — Aggne policy team / client ----------
-- These read as risk-assessment boilerplate possibly inherited from a shared/commercial (SME)
-- template — consistent with the ~40 empty commercial screening tags and 9 empty business stock
-- limits already flagged elsewhere in seq 13/14 as likely inapplicable to PP. But these six are NOT
-- empty — they're actively asserting specific (possibly false) answers, which is a different and
-- more serious problem than an empty/inapplicable tag.
-- Ask: (a) does Pure/PDS actually capture any of these six answers anywhere (even under a
-- different field name) that could be sourced instead of fabricated? (b) if not, should these tags
-- be blanked (matching the ~40 other inapplicable boilerplate tags), or does DCT require a non-blank
-- answer here that the client wants defaulted to a specific value regardless of truth?
-- Do not guess replacement values — these are factual property assertions, not display defaults.

-- ---------- Fix (once confirmed) ----------
-- If blanking: seq 14 template — remove the hardcoded 1/0 values, leave tags empty (or omit).
-- If a real source exists: wire the correct column instead.

-- ---------- Verify (informational — no target until decision made) ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET;  -- current scope: 1,399 risk nodes
