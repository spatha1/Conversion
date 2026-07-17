-- ============================================================
-- ATP-11112 — "Age of regular driver has increased" — pass/fail query
-- Compares AgeOfYoungestRegularDriver in the CURRENT converted XML against the PREVIOUS run's
-- snapshot (PER_POLICY_MIGRATION_DCT_PREVDATA, backed up before each reload) — since a single
-- snapshot can't show "increased," this needs two points in time.
-- 2026-07-13 test run: 1,705 policies matched between snapshots, 1,295 unchanged, 410 changed.
-- "Changed" isn't automatically wrong — could be a legitimate driver update — but this is the
-- candidate list to pick a concrete example from.
-- ============================================================

WITH gen AS (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS i FROM TABLE(GENERATOR(ROWCOUNT => 20))),
cur AS (
    SELECT LEGACYPOLICYNUMBER,
        LISTAGG(DISTINCT REGEXP_SUBSTR(REQUEST_XML, '<AgeOfYoungestRegularDriver>(.*?)</AgeOfYoungestRegularDriver>', 1, gen.i, 'e', 1), ',')
            WITHIN GROUP (ORDER BY 1) AS AGES_NOW
    FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT, gen
    WHERE REGEXP_SUBSTR(REQUEST_XML, '<AgeOfYoungestRegularDriver>(.*?)</AgeOfYoungestRegularDriver>', 1, gen.i, 'e', 1) IS NOT NULL
    GROUP BY LEGACYPOLICYNUMBER
),
prev AS (
    SELECT LEGACYPOLICYNUMBER,
        LISTAGG(DISTINCT REGEXP_SUBSTR(REQUEST_XML, '<AgeOfYoungestRegularDriver>(.*?)</AgeOfYoungestRegularDriver>', 1, gen.i, 'e', 1), ',')
            WITHIN GROUP (ORDER BY 1) AS AGES_PREV
    FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT_PREVDATA, gen
    WHERE REGEXP_SUBSTR(REQUEST_XML, '<AgeOfYoungestRegularDriver>(.*?)</AgeOfYoungestRegularDriver>', 1, gen.i, 'e', 1) IS NOT NULL
    GROUP BY LEGACYPOLICYNUMBER
)

-- 1) Summary counts
SELECT COUNT(*) AS TOTAL_MATCHED,
    SUM(CASE WHEN c.AGES_NOW = p.AGES_PREV THEN 1 ELSE 0 END) AS PASS_UNCHANGED,
    SUM(CASE WHEN c.AGES_NOW <> p.AGES_PREV THEN 1 ELSE 0 END) AS FAIL_CHANGED
FROM cur c JOIN prev p ON c.LEGACYPOLICYNUMBER = p.LEGACYPOLICYNUMBER;

-- 2) The actual candidate list — pick one of these to trace precisely
-- SELECT c.LEGACYPOLICYNUMBER, p.AGES_PREV AS AGE_BEFORE, c.AGES_NOW AS AGE_NOW
-- FROM cur c JOIN prev p ON c.LEGACYPOLICYNUMBER = p.LEGACYPOLICYNUMBER
-- WHERE c.AGES_NOW <> p.AGES_PREV
-- ORDER BY c.LEGACYPOLICYNUMBER
-- LIMIT 50;
-- ============================================================
