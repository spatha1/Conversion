-- ============================================================
-- READY BATCH 2026-07-10 — PER_COM_PAYLOAD view, remaining fix with NO open client question
-- VIEW: AGGNE.DEV.PER_COM_PAYLOAD
-- Covers: G-05 (part 1b) — the only "ready" gap on this view not already deployed (G-02/G-08/G-12/
-- G-42 were confirmed live-deployed 2026-07-10 via DDL check — comments "-- FIX (G-02)" etc. are
-- present and the surrounding logic matches the fixed pattern).
--
-- Live-reconfirmed 2026-07-10, immediately before writing this file: line 277 of the current view
-- still reads COALESCE(NUMBEROFCYLINDERS,0) — NOT yet fixed.
-- Code-only patch — PER_COM_PAYLOAD is shared by many gaps; do not paste a full CREATE OR REPLACE
-- from this file alone. Apply after (or together with) READY_BATCH_20260710_SP_PURE_TO_WRITE.sql,
-- since that SP change is what starts producing real (non-zero-defaulted) NumberOfCylinders values
-- for this COALESCE removal to actually matter for.
-- ============================================================

-- ┌─── NumberOfCylinders (final SELECT, ~line 277) — G-05 part 1b ────────────────
-- │ OLD CODE (current, live):
-- │   CAST(CAST(COALESCE(NUMBEROFCYLINDERS,0)AS NUMBER(20,0)) AS VARCHAR) AS  NUMBEROFCYLINDERS
-- │
-- │ NEW CODE:
    CAST(NUMBEROFCYLINDERS AS VARCHAR) AS NUMBEROFCYLINDERS   -- NULL stays NULL/blank, not the invalid '0'
-- └─────────────────────────────────────────────────────────────────────────────

-- NOTE (unchanged, still open — NOT part of this batch, needs Aggne policy input):
-- 512 vehicles carry a DELIBERATE 0 from PM_01's RedBook code 11 ("no cylinders" — trailers, EVs,
-- etc.). Whether DCT wants the tag omitted entirely for those VehicleTypes rather than any value at
-- all is still an open question — see G-05 part 2, not resolved by this patch.


-- ============================================================
-- PRE-VALIDATION (2026-07-10 baseline)
-- ============================================================
SELECT NUMBEROFCYLINDERS, COUNT(*),
       CASE WHEN NUMBEROFCYLINDERS BETWEEN '1' AND '16' THEN 'VALID'
            WHEN NUMBEROFCYLINDERS = '0' THEN 'INVALID (0)'
            ELSE 'OTHER' END AS CHECK_
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
-- Baseline: ~3,105 of 3,304 rows show '0' (94%) — largely because PM_01 was blank pre-SP-fix and
-- this COALESCE turned every NULL into '0'


-- ============================================================
-- POST-VALIDATION — run after both this view AND the SP batch are deployed and re-run
-- ============================================================
SELECT NUMBEROFCYLINDERS, COUNT(*),
       CASE WHEN NUMBEROFCYLINDERS BETWEEN '1' AND '16' THEN 'VALID'
            WHEN NUMBEROFCYLINDERS = '0' THEN 'INVALID (0)'
            WHEN NUMBEROFCYLINDERS IS NULL THEN 'BLANK (acceptable, no tag/empty tag)'
            ELSE 'OTHER' END AS CHECK_
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
-- Target: 'INVALID (0)' bucket collapses to ~512 (the genuine no-cylinder RedBook-code-11 vehicles,
-- still open per G-05 part 2) instead of 3,105; VALID (1-16) bucket grows to match the SP fix's
-- newly-populated real cylinder counts
-- ============================================================
