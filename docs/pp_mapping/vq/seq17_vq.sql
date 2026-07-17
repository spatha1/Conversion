-- ============================================================
-- Seq 17 (motor clauses) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-38 UPPER() breaks codes + CM_*/FV_* disabled in PP (P1), G-39 ALL-CAPS text (P3)
-- ============================================================

-- G-38: clause codes flowing vs PP-valid PM* set (mixed case!)
SELECT DCCLAUSETYPE, COUNT(*) AS CNT,
       CASE
         WHEN DCCLAUSETYPE IN ('PMAVCaravancontents','PMMVCaravancontents','PMLearnerextension',
                               'PMAdditionalbenefit4increase','PMAdditionalbenefit7increase',
                               'PMAdditionalbenefit11increase','PMAdditionalbenefit12increase',
                               'PMGeneralexclusionproperty','PMGeneralexclusionliability','PMGeneralextension')
              THEN 'VALID PP CODE'
         WHEN DCCLAUSETYPE = UPPER(DCCLAUSETYPE) AND DCCLAUSETYPE LIKE 'PM%'
              THEN 'UPPER-CASED PM CODE — INVALID (G-38.1)'
         WHEN DCCLAUSETYPE LIKE 'CM\\_%' OR DCCLAUSETYPE LIKE 'FV%'
              THEN 'DISABLED IN PP (G-38.2)'
         ELSE 'UNKNOWN CODE' END AS DCT_CHECK
FROM AGGNE.DEV.COM_CLAUSE
GROUP BY DCCLAUSETYPE ORDER BY CNT DESC;

-- G-39: ALL-CAPS descriptions + unsafe characters
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN DCINPUT = UPPER(DCINPUT) THEN 1 ELSE 0 END) AS ALL_CAPS,
  SUM(CASE WHEN DCINPUT LIKE '%&%' OR DCINPUT LIKE '%<%' THEN 1 ELSE 0 END) AS UNSAFE_CHARS
FROM AGGNE.DEV.COM_CLAUSE;
