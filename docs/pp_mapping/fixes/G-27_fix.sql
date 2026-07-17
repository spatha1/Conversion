-- ============================================================
-- G-27 — HC Specified Contents missing empty-item filter (seq 9, P2)
-- Pure code fix, no decision needed — same fix pattern already applied to seq 8. NOT YET APPLIED.
-- ============================================================

-- ---------- Data ----------
-- SELECT CASE WHEN VALUE IN ('<Value></Value>','<Value>0</Value>') THEN 'EMPTY/ZERO' ELSE 'REAL ITEM' END AS KIND,
--        COUNT(*) AS CNT, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
-- FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS GROUP BY 1;
-- Result: REAL ITEM = 414 rows / 414 policies; EMPTY/ZERO = 2,139 rows / 2,139 policies.
-- 83.8% of all <SpecifiedContents> nodes emitted are empty — every HC_02 row produces a node
-- regardless of whether the policy has any specified item at all, which can mark the "Specified
-- Contents" section as selected on a policy with nothing to specify.

-- ---------- CODE FIX ----------
-- sql/snowflake/1_conversion/PP/views/PER_HC_SPECIFIEDCONTENTS.sql (find exact WHERE clause) —
-- apply the same filter already used for seq 8 (HC_exceed_values):
--   WHERE VALUESPECIFIED IS NOT NULL AND VALUESPECIFIED > 0
-- (matching the existing seq 8 pattern: ANYITEMSEXCEEDVALUE='Yes' AND VALUE > 0)

-- ---------- Verify after applying ----------
-- SELECT CASE WHEN VALUE IN ('<Value></Value>','<Value>0</Value>') THEN 'EMPTY/ZERO' ELSE 'REAL ITEM' END AS KIND,
--        COUNT(*) FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS GROUP BY 1;
-- -- target: 0 EMPTY/ZERO rows remaining
