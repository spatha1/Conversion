-- ============================================================
-- Seq 16 (motor UW adjustments) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gap: G-19 (shared) hardcoded $/recurring
-- ============================================================

-- Volume
SELECT COUNT(*) AS ROWS_, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.PER_PM_BUILDING_UW;

-- G-19: percent-like magnitudes being sent as dollars
SELECT MIN(TRY_TO_NUMBER(ADJUSTMENTDOLLARANDPERCENT)) AS MIN_AMT,
       MAX(TRY_TO_NUMBER(ADJUSTMENTDOLLARANDPERCENT)) AS MAX_AMT,
       SUM(CASE WHEN ABS(TRY_TO_NUMBER(ADJUSTMENTDOLLARANDPERCENT)) <= 100 THEN 1 ELSE 0 END) AS LOOKS_PERCENT_LIKE,
       COUNT(*) AS TOTAL
FROM AGGNE.DEV.PER_PM_BUILDING_UW;
