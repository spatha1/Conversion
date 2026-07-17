-- ============================================================
-- G-01 fix — risk/State hardcoded "NSW" for every vehicle (seq 18, Motor, P1)
-- Two changes: (1) Snowflake view — expose STATE; (2) SQL Server config — tokenize the template.
-- NOT YET APPLIED. Draft for batch review/implementation.
--
-- OPEN QUESTION (ask Aggne policy team before applying):
-- DCT's own State-dependent logic (Fleet excess-calc comparisons in the manuscript) only
-- has cases for the 8 AU state/territory codes (ACT, NSW, QLD, VIC, NT, SA, TAS, WA) — no
-- NZ case anywhere. What should this field carry for NZ risks? The fix below passes PM_03.STATE
-- through as-is (including literal 'NZ'), which may itself be wrong — confirm before deploying.
-- ============================================================

-- ---------- 1. Snowflake — sql/snowflake/1_conversion/PP/views/PER_COM_PAYLOAD.sql ----------
-- Add STATE to the view's declared column list and CTE_EXCESS select list, sourced from PM_03.

-- In cte_COVERAGES, add:
--   STATE,
-- (PM_03 already carries STATE — see PM_01 build, SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql line ~7511)

-- In CTE_EXCESS, add:
--   t2.STATE,

-- In the final SELECT, add:
--   CAST(STATE AS VARCHAR) AS STATE,

-- Update the view's declared column list (top of CREATE VIEW) to include STATE.

-- ---------- 2. SQL Server — PP_ConversionConfig, SequenceID = 18 ----------
-- Replace the hardcoded <State>NSW</State> with a token.
UPDATE PP_ConversionConfig
SET ConversionScript = REPLACE(ConversionScript, '<State>NSW</State>', '<State>{STATE}</State>')
WHERE SequenceID = 18 AND IsActive = 1;

-- ---------- 3. Verify after applying ----------
-- SELECT STATE, COUNT(*) FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY STATE ORDER BY 2 DESC;
-- Confirm no more 100% NSW concentration, and decide the NZ question before this is considered done.
