-- ==========================================================================
-- ATP-10973: Run-off Exclusion Bug — 426 Affected Policies
-- Root cause: COALESCE(t3.PP1RunOffLiab, NULL, 0) < 1 incorrectly excluded
--             BP policies that have both PP1RunOffLiab > 0 AND RLPublicProducts = 1.
-- Fix applied: Removed the PP1RunOffLiab filter; kept only RLPublicProducts = 1.
-- ==========================================================================


-- Source tables (confirmed from SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD.sql):
--   CBP_PUBLICPRODUCTS  — contains PP1RunOffLiab (was t21/t3 in the SP)
--   CBP_RISKSELECTION   — contains RLPublicProducts (was t7/t4 in the SP)


-- --------------------------------------------------------------------------
-- QUERY 1: Identify the 426 policies (the exact set the bug excluded)
-- --------------------------------------------------------------------------
SELECT DISTINCT t2.PUREPolicyNumber AS POLICY_NUMBER
FROM AGGNE.PRD.policyattach_bp t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PUBLICPRODUCTS t3
    ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4
    ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
WHERE COALESCE(t3.PP1RunOffLiab, NULL, 0) >= 1    -- previously excluded by the bug
  AND COALESCE(t4.RLPublicProducts, NULL, 0) = 1   -- should have been included (fix condition)
ORDER BY 1;
-- Expected: 426 rows


-- --------------------------------------------------------------------------
-- QUERY 2: Current load status for all 426 in POLICY_ATTACH_TABLE
-- --------------------------------------------------------------------------
WITH runoff_426 AS (
    SELECT DISTINCT t2.PUREPolicyNumber
    FROM AGGNE.PRD.policyattach_bp t2
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PUBLICPRODUCTS t3
        ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4
        ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    WHERE COALESCE(t3.PP1RunOffLiab, NULL, 0) >= 1
      AND COALESCE(t4.RLPublicProducts, NULL, 0) = 1
),
latest_attach AS (
    SELECT POLICY_NUMBER, POLICY_ATTACH_XML, LOAD_TS,
           ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS RNO
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    WHERE POLICY_NUMBER IN (SELECT PUREPolicyNumber FROM runoff_426)
)
SELECT
    r.PUREPolicyNumber                                             AS POLICY_NUMBER,
    CASE
        WHEN la.POLICY_NUMBER IS NULL                  THEN 'NEVER_LOADED'
        WHEN LEN(TRIM(la.POLICY_ATTACH_XML)) = 0       THEN 'EMPTY_XML'
        ELSE 'LOADED'
    END                                                            AS STATUS,
    la.LOAD_TS                                                     AS LAST_LOAD_TS
FROM runoff_426 r
LEFT JOIN latest_attach la ON la.POLICY_NUMBER = r.PUREPolicyNumber AND la.RNO = 1
ORDER BY STATUS, POLICY_NUMBER;


-- --------------------------------------------------------------------------
-- QUERY 3: Summary count (to share with claims team)
-- --------------------------------------------------------------------------
WITH runoff_426 AS (
    SELECT DISTINCT t2.PUREPolicyNumber
    FROM AGGNE.PRD.policyattach_bp t2
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PUBLICPRODUCTS t3
        ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4
        ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    WHERE COALESCE(t3.PP1RunOffLiab, NULL, 0) >= 1
      AND COALESCE(t4.RLPublicProducts, NULL, 0) = 1
),
latest_attach AS (
    SELECT POLICY_NUMBER, LOAD_TS,
           ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS RNO
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    WHERE POLICY_NUMBER IN (SELECT PUREPolicyNumber FROM runoff_426)
)
SELECT
    COUNT(DISTINCT r.PUREPolicyNumber)                             AS total_runoff_policies,
    COUNT(DISTINCT la.POLICY_NUMBER)                               AS loaded_in_attach_table,
    COUNT(DISTINCT r.PUREPolicyNumber)
        - COUNT(DISTINCT la.POLICY_NUMBER)                         AS not_yet_loaded,
    MIN(la.LOAD_TS)                                                AS earliest_load,
    MAX(la.LOAD_TS)                                                AS latest_load
FROM runoff_426 r
LEFT JOIN latest_attach la ON la.POLICY_NUMBER = r.PUREPolicyNumber AND la.RNO = 1;
-- Expected: total_runoff_policies = 426
