-- ============================================================
-- Seq 6 (HB clauses) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-21 unescaped text (P2); clause-code validity (confirm)
-- ============================================================

-- Clause codes actually flowing for HB
SELECT DCCLAUSETYPE, COUNT(*) AS CNT
FROM AGGNE.DEV.HB_CLAUSE
GROUP BY DCCLAUSETYPE ORDER BY CNT DESC;

-- G-21: descriptions containing XML-breaking characters
SELECT COUNT(*) AS UNSAFE_DESCRIPTIONS
FROM AGGNE.DEV.HB_CLAUSE
WHERE DCINPUT LIKE '%&%' OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%';

SELECT DCINPUT FROM AGGNE.DEV.HB_CLAUSE
WHERE DCINPUT LIKE '%&%' OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%'
LIMIT 20;
