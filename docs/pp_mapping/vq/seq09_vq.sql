-- ============================================================
-- Seq 9 (HC specified contents) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gap: G-27 missing empty-item filter (P2)
-- ============================================================

-- G-27: empty nodes being emitted (no specified item, but a row still flows)
SELECT COUNT(*) AS EMPTY_SPECIFIED_NODES
FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS
WHERE VALUE = '<Value></Value>' OR VALUE = '<Value>0</Value>';

-- Split: real vs empty
SELECT CASE WHEN VALUE IN ('<Value></Value>','<Value>0</Value>') THEN 'EMPTY/ZERO' ELSE 'REAL ITEM' END AS KIND,
       COUNT(*) AS CNT, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS
GROUP BY 1;

-- Escape check (G-21)
SELECT COUNT(*) AS UNSAFE_DESCRIPTIONS
FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS
WHERE DESCRIPTION LIKE '%&%' AND DESCRIPTION NOT LIKE '%&amp;%';
