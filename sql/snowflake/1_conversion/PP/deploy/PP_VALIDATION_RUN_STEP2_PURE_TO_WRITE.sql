-- ============================================================
-- Step 2 of 3 — Re-run the Pure-to-Write SP to rebuild PM_01/PM_02/PM_03 and every
-- staging table (HB_01, HB_02, HC_02, Output_Coverage_PER, etc.) from current Pure data.
-- Run AFTER Step 1 (truncate), BEFORE Step 3 (XML generation).
-- NOT APPLIED — Snowflake write access is yours, not mine. Run yourself.
--
-- Live object name confirmed via SHOW PROCEDURES (no DEV_ prefix — that's only the repo
-- filename convention, not the deployed Snowflake object name):
--   AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()
-- ============================================================

CALL AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD();

-- Quick sanity check afterward:
SELECT COUNT(*) AS PM_03_ROWS FROM AGGNE.DEV.PM_03;
SELECT COUNT(*) AS HC_02_ROWS FROM AGGNE.DEV.HC_02;
