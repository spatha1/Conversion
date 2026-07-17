-- ============================================================
-- Seq 10 (HC sub-coverages) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-18 (shared) unconditional blocks; Portable Items disabled (confirm)
-- ============================================================

-- Block volume per code (9 active blocks; HCPOR_SD should be absent)
SELECT CODE, COUNT(*) AS ROWS_, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.PER_HC_SUBCOVERAGES
GROUP BY CODE ORDER BY CODE;

-- Portable Items exposure: does the source premium table have HCPOR_SD rows we are dropping?
SELECT COUNT(*) AS HCPOR_SOURCE_ROWS, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP
WHERE SUB_COVERAGE = 'HCPOR_SD';

-- Flood limit proxy check: hobby-farm flood column population
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN HCHOMEHOBBYFARMFLOODPROTECTION IS NOT NULL AND HCHOMEHOBBYFARMFLOODPROTECTION > 0 THEN 1 ELSE 0 END) AS FLOOD_LIMIT_POPULATED
FROM AGGNE.DEV.HC_02;

-- Zero contents limits on live blocks
SELECT COUNT(*) AS ZERO_LIMIT_BLOCKS
FROM AGGNE.DEV.PER_HC_SUBCOVERAGES
WHERE CODE LIKE 'HCCNT%' AND IVALUE = '0';
