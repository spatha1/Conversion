-- ==========================================================================
-- ATP-10973: Run-Off Policy Exclusion Bug — Fix Verification
-- ==========================================================================
--
-- BUG: ATP-10973
--
-- ROOT CAUSE:
--   The PP1RunOffLiab exclusion filter was incorrectly present in the
--   ATTACH stored procedure. This filter only belongs in CONVERSION.
--
-- CONVERSION SP (correct — by design):
--   File   : DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql  (lines 122, 1504, 1968, 4156)
--   Table  : PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PUBLICPRODUCTS (PP1RunOffLiab)
--   Code   : WHERE NOT (COALESCE(IsRunOffLiab,NULL,0) > 0 AND PublicAndProductLiability = 1)
--   Reason : Run-off policies follow a different path during conversion. Intentional exclusion.
--
-- ATTACH SP (bug — incorrect copy of conversion filter):
--   File   : SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD.sql  (line 5186, PP_01_Policyattach section)
--   Tables : AGGNE.PRD.policyattach_bp                                   (source)
--            PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PUBLICPRODUCTS t3   (PP1RunOffLiab)
--            PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION  t4   (RLPublicProducts)
--
--   BEFORE (buggy):
--     WHERE COALESCE(t3.PP1RunOffLiab, NULL, 0) < 1
--       AND COALESCE(t4.RLPublicProducts, NULL, 0) = 1
--
--   AFTER (fixed):
--     WHERE COALESCE(t4.RLPublicProducts, NULL, 0) = 1
--
-- IMPACT:
--   426 BP policies with PP1RunOffLiab = 1 AND RLPublicProducts = 1
--   were never loaded into POLICY_ATTACH_TABLE.
--   Fix: removed PP1RunOffLiab condition from attach SP and re-ran attach.
-- ==========================================================================


-- --------------------------------------------------------------------------
-- QUERY 1: The 426 affected policies with current attach status
-- --------------------------------------------------------------------------
WITH runoff_426 AS (
    SELECT DISTINCT
        t2.PUREPolicyNumber,
        t2.PUREExpiryDate,
        COALESCE(t3.PP1RunOffLiab, 0)    AS PP1RunOffLiab,    -- = 1 for all 426 (was the bug trigger)
        COALESCE(t4.RLPublicProducts, 0) AS RLPublicProducts   -- = 1 for all 426 (attach include condition)
    FROM AGGNE.PRD.policyattach_bp t2
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PUBLICPRODUCTS t3
        ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4
        ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    WHERE COALESCE(t3.PP1RunOffLiab, NULL, 0)    >= 1
      AND COALESCE(t4.RLPublicProducts, NULL, 0)  = 1
),
latest_attach AS (
    SELECT POLICY_NUMBER, POLICY_ATTACH_XML, LOAD_TS,
           ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS RNO
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    WHERE POLICY_NUMBER IN (SELECT PUREPolicyNumber FROM runoff_426)
)
SELECT
    r.PUREPolicyNumber                                                               AS POLICY_NUMBER,
    r.PUREExpiryDate                                                                 AS EXPIRY_DATE,
    CASE WHEN r.PUREExpiryDate >= CURRENT_DATE() THEN 'IN-FORCE' ELSE 'EXPIRED' END AS POLICY_STATUS,
    r.PP1RunOffLiab,
    r.RLPublicProducts,
    CASE
        WHEN la.POLICY_NUMBER IS NULL                                                THEN 'NOT_LOADED'
        WHEN REGEXP_INSTR(la.POLICY_ATTACH_XML, '<ABNNumber>[^<]+</ABNNumber>') = 0
          OR REGEXP_INSTR(la.POLICY_ATTACH_XML, '<Line type="[^"]+">') = 0          THEN 'LOADED_BAD_XML'
        ELSE 'LOADED_OK'
    END                                                                              AS ATTACH_STATUS,
    la.LOAD_TS                                                                       AS LAST_LOAD_TS
FROM runoff_426 r
LEFT JOIN latest_attach la ON la.POLICY_NUMBER = r.PUREPolicyNumber AND la.RNO = 1
ORDER BY ATTACH_STATUS, POLICY_STATUS, r.PUREPolicyNumber;


-- --------------------------------------------------------------------------
-- QUERY 2: Summary count
-- --------------------------------------------------------------------------
WITH runoff_426 AS (
    SELECT DISTINCT t2.PUREPolicyNumber
    FROM AGGNE.PRD.policyattach_bp t2
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PUBLICPRODUCTS t3
        ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4
        ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    WHERE COALESCE(t3.PP1RunOffLiab, NULL, 0)    >= 1
      AND COALESCE(t4.RLPublicProducts, NULL, 0)  = 1
),
latest_attach AS (
    SELECT POLICY_NUMBER, POLICY_ATTACH_XML, LOAD_TS,
           ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS RNO
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    WHERE POLICY_NUMBER IN (SELECT PUREPolicyNumber FROM runoff_426)
),
status_check AS (
    SELECT
        r.PUREPolicyNumber,
        CASE
            WHEN la.POLICY_NUMBER IS NULL THEN 'NOT_LOADED'
            WHEN REGEXP_INSTR(la.POLICY_ATTACH_XML, '<ABNNumber>[^<]+</ABNNumber>') = 0
              OR REGEXP_INSTR(la.POLICY_ATTACH_XML, '<Line type="[^"]+">') = 0 THEN 'LOADED_BAD_XML'
            ELSE 'LOADED_OK'
        END AS ATTACH_STATUS
    FROM runoff_426 r
    LEFT JOIN latest_attach la ON la.POLICY_NUMBER = r.PUREPolicyNumber AND la.RNO = 1
)
SELECT
    COUNT(*)                                                           AS TOTAL_RUN_OFF_POLICIES,
    SUM(CASE WHEN ATTACH_STATUS = 'LOADED_OK'      THEN 1 ELSE 0 END) AS LOADED_OK,
    SUM(CASE WHEN ATTACH_STATUS = 'LOADED_BAD_XML' THEN 1 ELSE 0 END) AS LOADED_BAD_XML,
    SUM(CASE WHEN ATTACH_STATUS = 'NOT_LOADED'     THEN 1 ELSE 0 END) AS NOT_LOADED
FROM status_check;
-- Expected after fix: TOTAL = 426, LOADED_OK = 426, NOT_LOADED = 0
