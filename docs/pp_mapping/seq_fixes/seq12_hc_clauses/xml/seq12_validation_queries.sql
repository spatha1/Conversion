-- ============================================================
-- Seq 12 (HC clauses) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-28 (consumed-side, see seq 13), G-21 unescaped text
-- ============================================================

-- HC clause codes flowing
SELECT DCCLAUSETYPE, COUNT(*) AS CNT
FROM AGGNE.DEV.PER_HC_CLAUSE
GROUP BY DCCLAUSETYPE ORDER BY CNT DESC;

-- Rows stranded in the target (loaded by seq 12 but never substituted — G-28)
SELECT COUNT(*) AS LOADED_HC_CLAUSE_ROWS, COUNT(DISTINCT ID) AS POLICIES
FROM AGGNE.DEV.PER_HC_TARGET
WHERE ITR_TYPE = 'LOC_HC_CLAUSE';

-- G-21: unsafe characters in clause text
SELECT COUNT(*) AS UNSAFE_DESCRIPTIONS
FROM AGGNE.DEV.PER_HC_CLAUSE
WHERE DCINPUT LIKE '%&%' OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%';
