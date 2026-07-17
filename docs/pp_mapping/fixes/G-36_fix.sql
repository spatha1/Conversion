-- ============================================================
-- G-36 — Unmapped construction/security values pass through raw (seq 14, P2)
-- RE-CHECKED WITH FRESH DATA — 0% invalid today, latent risk only. NOT YET APPLIED (hardening only).
-- ============================================================

-- ---------- Data — every current value is actually valid ----------
-- Ran the full per-field validity check (ROOF/MAINWALL/ALARM/DEADLOCKS/GRILLS) against
-- AGGNE.DEV.PER_RISK_BUILDING_FINAL — every single distinct value returned in the current dataset
-- classified as 'VALID'. The specific problem values named in the original gap register (Fibro
-- (Non-Asbestos) roof, Some Asbestos and Brick wall, alarm Local-Monitored/Mobile Mechanic,
-- deadlocks/grills 'Other') do not appear anywhere in the current data — 0 live impact today.
-- (Full distribution logged in VALIDATION_RULES.md.)

-- ---------- Not a live defect, but the CASE logic itself is still a silent-passthrough risk ----------
-- The view's CASE statements for these fields presumably still have an ELSE-passthrough branch for
-- genuinely unmapped values (consistent with the original gap description, even though nothing
-- currently triggers it) — same shape as G-06/G-12's "0 hit today, real risk waiting" pattern.

-- ---------- RECOMMENDED HARDENING (low urgency, optional given 0 live impact) ----------
-- Per PR-01: route any future unmapped value to a validation-report flag instead of a silent raw
-- passthrough, so a genuinely new source value (e.g. if Pure ever adds "Fibro" as a distinct roof
-- type) is caught rather than silently forwarded as an invalid DCT code.

-- ---------- Verify (informational) ----------
-- SELECT 'ROOF' AS FIELD, ROOFCONSTRUCTION_FINAL AS VALUE, COUNT(*) AS CNT,
--        CASE WHEN ROOFCONSTRUCTION_FINAL IN ('Asbestos','Colourbond','Concrete','IronSteelTin','Tile','Wood')
--             THEN 'VALID' WHEN COALESCE(TRIM(ROOFCONSTRUCTION_FINAL),'')='' THEN 'BLANK' ELSE 'INVALID' END AS DCT_CHECK
-- FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL GROUP BY 2 ORDER BY CNT DESC;
-- (repeat per field: MAINWALL/FLOOR/ALARM/DEADLOCKS/GRILLS/OCCUPIED — see seq14_vq.sql for the
-- full UNION ALL version)
