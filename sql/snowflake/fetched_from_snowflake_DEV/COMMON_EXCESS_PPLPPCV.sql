create or replace view COMMON_EXCESS_PPLPPCV(
	PUREPOLICYNUMBER,
	COMMON_OR_SINGLE_EXCESS
) as
WITH
-- 1) Normalize distinct (policy, excess) pairs per line
pl AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
                    TRIM(VOLUNTARYEXCESS)   AS EXCESS
    FROM AGGNE.DEV.Line_PublicLiability_Coverage
    WHERE VOLUNTARYEXCESS IS NOT NULL
),
pp AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
                    TRIM(VOLUNTARYEXCESS)   AS EXCESS
    FROM AGGNE.DEV.LINE_PROFESSIONALPROTECTION_COVERAGE
    WHERE VOLUNTARYEXCESS IS NOT NULL
),
cv AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
                    TRIM(VOLUNTARYEXCESS)   AS EXCESS
    FROM AGGNE.DEV.LINE_CV_COVERAGE
    WHERE VOLUNTARYEXCESS IS NOT NULL
),

-- 2) Union the three sources to count how many lines support each value
unioned AS (
    SELECT PUREPOLICYNUMBER, EXCESS, 'PL' AS src FROM pl
    UNION ALL
    SELECT PUREPOLICYNUMBER, EXCESS, 'PP' AS src FROM pp
    UNION ALL
    SELECT PUREPOLICYNUMBER, EXCESS, 'CV' AS src FROM cv
),

-- 3) Count (per policy, per excess) how many lines have that excess
excess_counts AS (
    SELECT
        PUREPOLICYNUMBER,
        EXCESS,
        COUNT(*) AS line_count  -- number of lines (PL/PP/CV) carrying this EXCESS
    FROM unioned
    GROUP BY PUREPOLICYNUMBER, EXCESS
),

-- 4) Per policy: the maximum line_count for any excess, and total distinct excesses present
policy_stats AS (
    SELECT
        PUREPOLICYNUMBER,
        MAX(line_count)        AS max_cnt,
        COUNT(DISTINCT EXCESS) AS distinct_vals
    FROM excess_counts
    GROUP BY PUREPOLICYNUMBER
),

-- 5) Base of all policies appearing in any line (keeps policies with all NULLs too)
base AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_PUBLICLIABILITY_COVERAGE
    UNION
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_PROFESSIONALPROTECTION_COVERAGE
    UNION
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_CV_COVERAGE
)

-- 6) Final selection with tie-safe, deterministic pick
SELECT
    b.PUREPOLICYNUMBER,
    CASE
        -- Case A: some value appears in 2 or 3 lines → pick that (break ties deterministically by MIN)
        WHEN ps.max_cnt >= 2 THEN (
            SELECT MIN(ec.EXCESS)
            FROM excess_counts ec
            WHERE ec.PUREPOLICYNUMBER = b.PUREPOLICYNUMBER
              AND ec.line_count = ps.max_cnt
        )
        -- Case B: only one distinct value exists across all lines (i.e., two NULLs, one value)
        WHEN ps.distinct_vals = 1 THEN (
            SELECT MIN(ec.EXCESS)
            FROM excess_counts ec
            WHERE ec.PUREPOLICYNUMBER = b.PUREPOLICYNUMBER
        )
        -- Case C: conflicting values with no majority → NULL
        ELSE NULL
    END AS COMMON_OR_SINGLE_EXCESS
FROM base b
LEFT JOIN policy_stats ps
    ON ps.PUREPOLICYNUMBER = b.PUREPOLICYNUMBER
ORDER BY b.PUREPOLICYNUMBER;