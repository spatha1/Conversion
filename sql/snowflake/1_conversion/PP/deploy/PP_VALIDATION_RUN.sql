-- ============================================================
-- PP_VALIDATION_RUN.sql — the correct, simplified validation run.
--
-- SUPERSEDES the earlier 3-file plan (PP_VALIDATION_RUN_STEP1_TRUNCATE.sql,
-- PP_VALIDATION_RUN_STEP2_PURE_TO_WRITE.sql, pp_validation_run_step3_generate_xml.py).
-- That plan assumed XML generation happens via middleware/etl4.py reading SQL Server
-- PP_ConversionConfig row-by-row. It doesn't — AGGNE.DEV.PP_CONVERSION_RUN is the real,
-- complete orchestrator: it already does the truncate-equivalent (DELETE latest batch),
-- all 18 DYNAMIC_XML_V1 calls (templates hardcoded in its own body, not read from SQL
-- Server), AND a Phase 2 (PER_CONVERSION_FINAL_LOAD + PER_CONVERSION_FINAL_XML) the
-- earlier plan didn't know about. Two steps, not three, and Step 1 (truncate) is now
-- built into Step 2.
--
-- STANDING RULE, going forward: PP_CONVERSION_RUN's 18 templates are hardcoded in its own
-- procedure body, NOT read from PP_ConversionConfig at call time (see
-- feedback_verify_live_not_repo.md). Any time PP_ConversionConfig changes — this fix, the
-- next one, all future ones — re-run PP_CONVERSION_RUN_REGENERATED_FROM_CONFIG.sql to
-- resync this procedure BEFORE running the validation below. Do not hand-patch individual
-- lines in PP_CONVERSION_RUN again (that's how G-25/G-32 drifted in the first place) —
-- always regenerate the whole procedure from the live config table.
--
-- PREREQUISITE — run this FIRST, every time PP_ConversionConfig has changed since the last run:
--   PP_CONVERSION_RUN_REGENERATED_FROM_CONFIG.sql
--
-- NOT APPLIED — run yourself, with SAFE_MODE=false if going through Python, or directly
-- in your Snowflake worksheet.
-- ============================================================

-- Step 1 — rebuild PM_01/PM_02/PM_03 and all staging tables from current Pure data
CALL AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD();

-- Step 2 — truncate-equivalent + all 18 sequences + final load + final XML, in one call
CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE);

-- ── Verify G-25 / G-32 landed in the real output ────────────────────────────
SELECT COUNT(*) AS STILL_WRONG_CLASSCODE
FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE ITR_TYPE = 'RISK_Building_HB' AND PAYLOAD LIKE '%<APRA>HH</APRA>%';

SELECT COUNT(*) AS STILL_WRONG_CLASSCODE
FROM AGGNE.DEV.PER_HC_TARGET
WHERE ITR_TYPE = 'RISK_Building_HC' AND PAYLOAD LIKE '%<APRA>HH</APRA>%';

SELECT COUNT(*) AS STILL_HAS_TEST_TOTALS
FROM AGGNE.DEV.PER_HC_TARGET
WHERE ITR_TYPE = 'RISK_Building_HC' AND (PAYLOAD LIKE '%>9100<%' OR PAYLOAD LIKE '%>622221<%');
-- target: 0 for all three
