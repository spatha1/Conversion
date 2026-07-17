-- ============================================================
-- Seq 8 (HC items exceeding) — validation queries (READ-ONLY, AGGNE.DEV)
-- Filter is in place; these verify it + G-21 escaping
-- ============================================================

-- Volume: rows only for Yes + value>0 policies
SELECT COUNT(*) AS ROWS_, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE;

-- Escape check on descriptions (G-21)
SELECT COUNT(*) AS UNSAFE_DESCRIPTIONS
FROM AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE
WHERE DESCRIPTION LIKE '%&%' AND DESCRIPTION NOT LIKE '%&amp;%';

-- Source-side eligible rows (should reconcile with view volume)
SELECT COUNT(*) AS ELIGIBLE_SOURCE_ROWS
FROM AGGNE.DEV.HC_02
WHERE ANYITEMSEXCEEDVALUE = 'Yes' AND VALUE IS NOT NULL AND VALUE > 0;
