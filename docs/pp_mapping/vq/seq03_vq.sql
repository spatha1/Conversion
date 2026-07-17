-- ============================================================
-- Seq 3 (location) — validation queries (READ-ONLY, AGGNE.DEV)
-- Confirm item: STATE code form (NSWAU pattern); blanks on required address fields
-- ============================================================

-- State code distribution (confirm NSWAU-style values against a working quote)
SELECT STATE, LOC_COUNTRY, COUNT(*) AS CNT
FROM AGGNE.DEV.PER_ACCOUNT_LOC
GROUP BY STATE, LOC_COUNTRY ORDER BY CNT DESC;

-- Blanks on required address fields
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN COALESCE(TRIM(ADDRESS1),'')='' THEN 1 ELSE 0 END) AS ADDRESS1_BLANK,
  SUM(CASE WHEN COALESCE(TRIM(SUBURB),'')=''   THEN 1 ELSE 0 END) AS SUBURB_BLANK,
  SUM(CASE WHEN COALESCE(TRIM(POSTCODE),'')='' THEN 1 ELSE 0 END) AS POSTCODE_BLANK,
  SUM(CASE WHEN COALESCE(TRIM(STATE),'')=''    THEN 1 ELSE 0 END) AS STATE_BLANK
FROM AGGNE.DEV.PER_ACCOUNT_LOC;

-- Risk number integrity (multi-location ordering)
SELECT LEGACYPOLICYNUMBER, COUNT(*) AS LOCS, COUNT(DISTINCT RISKNUMBER) AS DISTINCT_RISKNUMS
FROM AGGNE.DEV.PER_ACCOUNT_LOC
GROUP BY LEGACYPOLICYNUMBER HAVING COUNT(*) <> COUNT(DISTINCT RISKNUMBER);
