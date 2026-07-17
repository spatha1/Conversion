-- See the AdjustmentAmount blank issue directly in the real UAT batch XML.
-- Extracts <UnderwritingAdjustment> blocks per policy (occurrences 1-10, covers every policy in
-- this batch) and shows both fields side by side. Tested live 2026-07-15 -- returns real rows.

WITH adj AS (
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 1, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 2, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 3, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 4, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 5, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 6, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 7, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 8, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 9, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
    UNION ALL
    SELECT LEGACYPOLICYNUMBER, REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, 10, 'es') AS BLOCK FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT WHERE RESULTS_JSON IS NOT NULL
)
SELECT
    LEGACYPOLICYNUMBER,
    REGEXP_SUBSTR(BLOCK, '<Type>(.*?)</Type>', 1, 1, 'e', 1)                               AS COVERAGE_TYPE,
    REGEXP_SUBSTR(BLOCK, '<AdjustmentDollarAndPercent>(.*?)</AdjustmentDollarAndPercent>', 1, 1, 'e', 1) AS ADJUSTMENT_DOLLAR_AND_PERCENT,
    REGEXP_SUBSTR(BLOCK, '<AdjustmentAmount>(.*?)</AdjustmentAmount>', 1, 1, 'e', 1)        AS ADJUSTMENT_AMOUNT,
    REGEXP_SUBSTR(BLOCK, '<UnderwritingDescription>(.*?)</UnderwritingDescription>', 1, 1, 'e', 1) AS DESCRIPTION
FROM adj
WHERE BLOCK IS NOT NULL
ORDER BY LEGACYPOLICYNUMBER;

-- Simple aggregate version -- just the blank rate:
SELECT
    COUNT(*) TOTAL_ADJUSTMENT_BLOCKS,
    SUM(CASE WHEN REGEXP_SUBSTR(BLOCK, '<AdjustmentAmount>(.*?)</AdjustmentAmount>', 1, 1, 'e', 1) IS NULL
              OR TRIM(REGEXP_SUBSTR(BLOCK, '<AdjustmentAmount>(.*?)</AdjustmentAmount>', 1, 1, 'e', 1)) = ''
         THEN 1 ELSE 0 END) AS BLANK_ADJUSTMENT_AMOUNT,
    SUM(CASE WHEN REGEXP_SUBSTR(BLOCK, '<AdjustmentDollarAndPercent>(.*?)</AdjustmentDollarAndPercent>', 1, 1, 'e', 1) IS NOT NULL
              AND TRIM(REGEXP_SUBSTR(BLOCK, '<AdjustmentDollarAndPercent>(.*?)</AdjustmentDollarAndPercent>', 1, 1, 'e', 1)) NOT IN ('', '0', '0.00')
         THEN 1 ELSE 0 END) AS HAS_REAL_DOLLARANDPERCENT
FROM (
    SELECT REGEXP_SUBSTR(REQUEST_XML, '<UnderwritingAdjustment>.*?</UnderwritingAdjustment>', 1, SEQ4()+1, 'es') AS BLOCK
    FROM AGGNE.UAT.PER_POLICY_MIGRATION_DCT,
         TABLE(GENERATOR(ROWCOUNT => 20))
    WHERE RESULTS_JSON IS NOT NULL
      AND REQUEST_XML LIKE '%<UnderwritingAdjustment>%'
)
WHERE BLOCK IS NOT NULL;
