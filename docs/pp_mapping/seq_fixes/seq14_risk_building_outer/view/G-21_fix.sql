-- ============================================================
-- G-21 fix (seq 14 portion) — SecurityMeasures free text not XML-escaped
-- VIEW: AGGNE.DEV.PER_RISK_BUILDING_FINAL (~pos 15, SECURITYDETAILS column)
-- Code-only patch — this view is shared with G-36 (dropdown hardening); do not paste a full
-- CREATE OR REPLACE from this file alone or you will drop G-36's changes.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-09): 14 of 1,392 rows contain an unescaped `&`, `<`, or `>` in
-- SECURITYDETAILS — real, live-breaking impact (this field maps straight to
-- <SecurityMeasures>{SECURITYDETAILS}</SecurityMeasures> with no escaping in the template).
--
-- ┌─── SECURITYDETAILS (CTE1, pos 15) ─────────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   -- pos 15: free-text, no code translation
-- │   SECURITYDETAILS,
-- │
-- │ NEW CODE:
-- │   -- pos 15: free-text — escape XML-breaking characters
-- │   REPLACE(REPLACE(REPLACE(CAST(SECURITYDETAILS AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS SECURITYDETAILS,
-- └─────────────────────────────────────────────────────────────────────────────


-- ============================================================
-- PRE/POST-VALIDATION
-- ============================================================

-- PRE (2026-07-09 baseline: 14)
SELECT COUNT(*) AS UNESCAPED_ROWS FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL
WHERE (SECURITYDETAILS LIKE '%&%' AND SECURITYDETAILS NOT LIKE '%&amp;%') OR SECURITYDETAILS LIKE '%<%' OR SECURITYDETAILS LIKE '%>%';

-- POST — target 0
SELECT COUNT(*) AS STILL_UNESCAPED FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL
WHERE (SECURITYDETAILS LIKE '%&%' AND SECURITYDETAILS NOT LIKE '%&amp;%' AND SECURITYDETAILS NOT LIKE '%&lt;%' AND SECURITYDETAILS NOT LIKE '%&gt;%')
   OR SECURITYDETAILS LIKE '%<%' OR SECURITYDETAILS LIKE '%>%';
-- ============================================================
