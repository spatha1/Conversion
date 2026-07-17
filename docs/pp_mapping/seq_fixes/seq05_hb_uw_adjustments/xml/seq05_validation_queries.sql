-- ============================================================
-- Seq 5 (HB UW adjustments) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-20 wrong-LOB source + output never consumed (P1), G-19 hardcoded $ / recurring (P2)
-- ============================================================

-- G-20a: does the BSP-sourced view produce ANY rows for PP policies?
SELECT COUNT(*) AS SEQ5_VIEW_ROWS FROM AGGNE.DEV.BUILDING_UW;

-- G-20b: rows loaded into the target that nothing consumes (seq 7 template has no {UW})
SELECT COUNT(*) AS ORPHANED_UW_ROWS
FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE ITR_TYPE = 'BUILDING_UW';

-- The PER-side UW rows that WOULD be in scope if seq 5 were repointed (COVERAGE='HB')
SELECT COUNT(*) AS PER_HB_UW_CANDIDATES, COUNT(DISTINCT POLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.Output_UWAdjust_PER
WHERE COVERAGE = 'HB' AND UWADJUSTAMOUNT IS NOT NULL;

-- G-19: adjustment amount signs/magnitudes (percent-like values would look small)
SELECT MIN(TRY_TO_NUMBER(UWADJUSTAMOUNT)) AS MIN_AMT,
       MAX(TRY_TO_NUMBER(UWADJUSTAMOUNT)) AS MAX_AMT,
       SUM(CASE WHEN ABS(TRY_TO_NUMBER(UWADJUSTAMOUNT)) <= 100 THEN 1 ELSE 0 END) AS LOOKS_PERCENT_LIKE,
       COUNT(*) AS TOTAL
FROM AGGNE.DEV.Output_UWAdjust_PER WHERE COVERAGE='HB';
