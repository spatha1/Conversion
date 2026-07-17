-- ============================================================
-- Seq 11 (HC UW adjustments) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-19 (shared) hardcoded $/recurring; zero-amount rows (align with seq 16)
-- ============================================================

-- Zero-dollar adjustments flowing (seq 16 filters these; seq 11 doesn't)
SELECT COUNT(*) AS ZERO_AMOUNT_ROWS
FROM AGGNE.DEV.PER_HC_BUILDING_UW
WHERE TRY_TO_NUMBER(ADJUSTMENTDOLLARANDPERCENT) = 0;

-- G-19: percent-like magnitudes being sent as dollars
SELECT MIN(TRY_TO_NUMBER(ADJUSTMENTDOLLARANDPERCENT)) AS MIN_AMT,
       MAX(TRY_TO_NUMBER(ADJUSTMENTDOLLARANDPERCENT)) AS MAX_AMT,
       SUM(CASE WHEN ABS(TRY_TO_NUMBER(ADJUSTMENTDOLLARANDPERCENT)) <= 100 THEN 1 ELSE 0 END) AS LOOKS_PERCENT_LIKE,
       COUNT(*) AS TOTAL
FROM AGGNE.DEV.PER_HC_BUILDING_UW;

-- Volume
SELECT COUNT(*) AS ROWS_, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.PER_HC_BUILDING_UW;
