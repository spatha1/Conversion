create or replace view COMMON_EXCESS_GPGTLETA(
	PUREPOLICYNUMBER,
	COMMON_OR_SINGLE_EXCESS
) as
WITH
-- 1) Normalize distinct (policy, excess) pairs per line
gp AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
                    TRIM(VOLUNTARYEXCESS)   AS EXCESS
    FROM AGGNE.DEV.LINE_GP_COVERAGE
    WHERE VOLUNTARYEXCESS IS NOT NULL
),
gt AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
                    TRIM(VOLUNTARYEXCESS)   AS EXCESS
    FROM AGGNE.DEV.LINE_GT_COVERAGE
    WHERE VOLUNTARYEXCESS IS NOT NULL
),
le AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
                    TRIM(VOLUNTARYEXCESS)   AS EXCESS
    FROM AGGNE.DEV.LINE_LE_COVERAGE
    WHERE VOLUNTARYEXCESS IS NOT NULL
),
ta AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
                    TRIM(VOLUNTARYEXCESS)   AS EXCESS
    FROM AGGNE.DEV.LINE_TA_COVERAGE
    WHERE VOLUNTARYEXCESS IS NOT NULL
),

-- 2) Union the four sources to count how many lines carry each value
unioned AS (
    SELECT PUREPOLICYNUMBER, EXCESS, 'GP' AS src FROM gp
    UNION ALL
    SELECT PUREPOLICYNUMBER, EXCESS, 'GT' AS src FROM gt
    UNION ALL
    SELECT PUREPOLICYNUMBER, EXCESS, 'LE' AS src FROM le
    UNION ALL
    SELECT PUREPOLICYNUMBER, EXCESS, 'TA' AS src FROM ta
),

-- 3) Count (per policy, per excess) how many lines have that excess
excess_counts AS (
    SELECT
        PUREPOLICYNUMBER,
        EXCESS,
        COUNT(*) AS line_count
    FROM unioned
    GROUP BY PUREPOLICYNUMBER, EXCESS
),

-- 4) Per-policy stats: max count, number of winners (how many values tie at max), and how many distinct values exist
winners AS (
    SELECT
        PUREPOLICYNUMBER,
        MAX(line_count) AS max_cnt
    FROM excess_counts
    GROUP BY PUREPOLICYNUMBER
),
policy_stats AS (
    SELECT
        w.PUREPOLICYNUMBER,
        w.max_cnt,
        /* how many different values achieve the max count (detects 2–2 ties, etc.) */
        (SELECT COUNT(*) 
         FROM excess_counts ec2
         WHERE ec2.PUREPOLICYNUMBER = w.PUREPOLICYNUMBER
           AND ec2.line_count = w.max_cnt) AS winners,
        /* how many distinct non-null values exist across all 4 lines for the policy */
        (SELECT COUNT(DISTINCT ec3.EXCESS)
         FROM excess_counts ec3
         WHERE ec3.PUREPOLICYNUMBER = w.PUREPOLICYNUMBER) AS distinct_vals
    FROM winners w
),

-- 5) Base of all policies appearing in any of the four lines
base AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_GP_COVERAGE
    UNION
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) FROM AGGNE.DEV.LINE_GT_COVERAGE
    UNION
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) FROM AGGNE.DEV.LINE_LE_COVERAGE
    UNION
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) FROM AGGNE.DEV.LINE_TA_COVERAGE
)

-- 6) Final selection with correct tie handling
SELECT
    b.PUREPOLICYNUMBER,
    CASE
        /* Unique majority: one value appears in 2, 3, or 4 lines */
        WHEN ps.max_cnt >= 2 AND ps.winners = 1 THEN (
            SELECT MIN(ec.EXCESS)  -- MIN for deterministic pick (only 1 winner anyway)
            FROM excess_counts ec
            WHERE ec.PUREPOLICYNUMBER = b.PUREPOLICYNUMBER
              AND ec.line_count = ps.max_cnt
        )
        /* Only one distinct value exists overall (others are NULL) */
        WHEN ps.max_cnt = 1 AND ps.distinct_vals = 1 THEN (
            SELECT MIN(ec.EXCESS)
            FROM excess_counts ec
            WHERE ec.PUREPOLICYNUMBER = b.PUREPOLICYNUMBER
        )
        /* Conflicts (e.g., 2–2 tie or multiple different singletons) */
        ELSE NULL
    END AS COMMON_OR_SINGLE_EXCESS
FROM base b
LEFT JOIN policy_stats ps
    ON ps.PUREPOLICYNUMBER = b.PUREPOLICYNUMBER
ORDER BY b.PUREPOLICYNUMBER;