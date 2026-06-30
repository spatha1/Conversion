-- ============================================================
-- Pure to Write — CoverEndDate Diagnostic
-- Policies : P00022895, P00031597
-- Replicates SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD LAG logic
-- and adds a COMMENTS column explaining why a premise is missing.
-- Run against: AGGNE Snowflake (PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT)
-- Safe: SELECT only, no writes
-- ============================================================

WITH

-- ── Step 1 ───────────────────────────────────────────────────────────────
-- Mirrors T_Policyattach_000
-- Pull all Insurance_File records from PURE for the policies
-- Filter matches SP: Live Policy / MTA Cancelled / MTA Permanent only
BASE AS (
    SELECT
        TRIM(if3.insurance_ref)          AS PUREPolicyNumber,
        r.risk_cnt,
        r.risk_folder_cnt,
        r.description                    AS Risk_Address,
        if3.cover_start_date::DATE       AS CoverStartDate,
        if3.expiry_date::DATE            AS PUREExpiryDate,
        ift.description                  AS Pol_type,
        cbp.CBP_Policy_Binder_id         AS ExpiringID,
        if3.insurance_file_cnt,
        ifrl.status_flag,
        ifs.description                  AS TransactionType,
        ifs.insurance_file_status_id
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk                       r
    JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link   ifrl ON ifrl.risk_cnt             = r.risk_cnt
    JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File             if3  ON if3.insurance_file_cnt    = ifrl.insurance_file_cnt
    JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link            gpl  ON gpl.risk_id               = r.risk_cnt
    JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_Policy_Binder          cbp  ON cbp.gis_policy_link_id    = gpl.gis_policy_link_id
    JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File_Type        ift  ON ift.insurance_file_type_id = if3.insurance_file_type_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status ifs  ON ifs.insurance_file_status_id = if3.insurance_file_status_id
    WHERE TRIM(if3.insurance_ref) IN ('P00022895', 'P00031597')
      AND ift.description IN ('Live Policy', 'MTA Cancelled', 'MTA Permanent')
),

-- ── Step 2 ───────────────────────────────────────────────────────────────
-- Mirrors POLICYATTACH_TEMP
-- STATUS_FLAG = 'D' (deleted/rolled-back MTA) is treated as 'MTA Cancelled'
TEMP AS (
    SELECT DISTINCT
        PUREPolicyNumber,
        insurance_file_cnt,
        risk_folder_cnt,
        ExpiringID,
        Risk_Address,
        CoverStartDate,
        PUREExpiryDate,
        Pol_type,
        status_flag,
        TransactionType,
        insurance_file_status_id,
        CASE WHEN status_flag = 'D' THEN 'MTA Cancelled'
             ELSE Pol_type
        END AS Pol_type_adj
    FROM BASE
),

-- ── Step 3 ───────────────────────────────────────────────────────────────
-- Mirrors T_Policyattach_002
-- LAG gives CoverEndDate_pre (next row's CoverStartDate in time order)
-- rn3 = rank within each risk folder (1 = most recent)
-- QUALIFY removes rows where same start date appears twice in a folder
STEP2 AS (
    SELECT *,
        LAG(CoverStartDate) OVER (
            PARTITION BY PUREPolicyNumber
            ORDER BY risk_folder_cnt DESC, insurance_file_cnt DESC
        ) AS CoverEndDate_pre,
        ROW_NUMBER() OVER (
            PARTITION BY PUREPolicyNumber, risk_folder_cnt
            ORDER BY insurance_file_cnt DESC
        ) AS rn3
    FROM TEMP
    QUALIFY NOT (rn3 > 1 AND CoverStartDate = CoverEndDate_pre)
),

-- ── Step 4 ───────────────────────────────────────────────────────────────
-- Mirrors T_Policyattach_003
-- LagPolType is re-computed over the QUALIFY'd dataset
STEP3 AS (
    SELECT *,
        LAG(Pol_type_adj) OVER (
            PARTITION BY PUREPolicyNumber
            ORDER BY risk_folder_cnt DESC, insurance_file_cnt DESC
        ) AS LagPolType
    FROM STEP2
),

-- ── Step 5 ───────────────────────────────────────────────────────────────
-- Final CoverEndDate CASE (same logic as SP)
FINAL AS (
    SELECT *,
        CASE
            WHEN rn3 = 1
                 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN PUREExpiryDate                            -- correct: current term row
            WHEN LagPolType = 'MTA Cancelled'
                THEN CoverEndDate_pre                          -- truncated by cancelled/deleted MTA
            ELSE DATEADD(DAY, -1, CoverEndDate_pre)           -- normal MTA boundary
        END AS CoverEndDate
    FROM STEP3
)

-- ── Output ───────────────────────────────────────────────────────────────
SELECT
    PUREPolicyNumber                         AS POLICY_NUMBER,
    ExpiringID,
    insurance_file_cnt                       AS INS_FILE_CNT,
    Risk_Address                             AS RISK_ADDRESS,
    TO_CHAR(CoverStartDate,  'YYYY-MM-DD')   AS COVER_START_DATE,
    TO_CHAR(CoverEndDate,    'YYYY-MM-DD')   AS COVER_END_DATE,
    TO_CHAR(PUREExpiryDate,  'YYYY-MM-DD')   AS PURE_EXPIRY_DATE,
    Pol_type                                 AS POL_TYPE,
    Pol_type_adj                             AS POL_TYPE_ADJ,
    status_flag                              AS STATUS_FLAG,
    TransactionType                          AS TRANSACTION_TYPE,
    LagPolType                               AS LAG_POL_TYPE,

    CASE
        -- ── Root cause record: deleted / rolled-back MTA ──────────────
        WHEN status_flag = 'D'
            THEN 'ROOT CAUSE: This MTA record was deleted/rolled back in PURE '
              || '(STATUS_FLAG=D) but still exists in the data. '
              || 'It enters the LAG chain and forces the prior Live Policy''s '
              || 'CoverEndDate to ' || COALESCE(TO_CHAR(CoverEndDate_pre, 'YYYY-MM-DD'), 'N/A (first row)')
              || ' instead of PUREExpiryDate ' || TO_CHAR(PUREExpiryDate, 'YYYY-MM-DD') || '.'

        -- ── Renewal not finalised ─────────────────────────────────────
        WHEN insurance_file_status_id = 3
             AND CoverEndDate <> PUREExpiryDate
            THEN 'ISSUE: Renewal not finalised in PURE (status = Under Renewal). '
              || 'CoverEndDate resolved to ' || TO_CHAR(CoverEndDate, 'YYYY-MM-DD')
              || ' instead of ' || TO_CHAR(PUREExpiryDate, 'YYYY-MM-DD') || '. '
              || 'Premises excluded from all current-term DOL combinations.'

        -- ── Live Policy truncated by deleted/cancelled MTA ────────────
        WHEN LagPolType = 'MTA Cancelled'
             AND CoverEndDate <> PUREExpiryDate
            THEN 'ISSUE: CoverEndDate cut short to ' || TO_CHAR(CoverEndDate, 'YYYY-MM-DD')
              || ' by a deleted/cancelled MTA sitting above it in the LAG chain. '
              || 'Should be ' || TO_CHAR(PUREExpiryDate, 'YYYY-MM-DD') || '. '
              || 'Premises excluded from all DOL combinations after '
              || TO_CHAR(CoverEndDate, 'YYYY-MM-DD') || '.'

        -- ── Genuine MTA Cancelled transaction ─────────────────────────
        WHEN Pol_type_adj = 'MTA Cancelled' AND status_flag <> 'D'
            THEN 'INFO: Genuine MTA Cancelled transaction. Excluded from final output.'

        -- ── All good ──────────────────────────────────────────────────
        WHEN CoverEndDate = PUREExpiryDate
            THEN 'OK: CoverEndDate = PUREExpiryDate (' || TO_CHAR(PUREExpiryDate, 'YYYY-MM-DD')
              || '). Premises correctly included in DOL combinations.'

        ELSE 'CHECK: CoverEndDate (' || TO_CHAR(CoverEndDate, 'YYYY-MM-DD')
          || ') differs from PUREExpiryDate (' || TO_CHAR(PUREExpiryDate, 'YYYY-MM-DD')
          || ') — normal MTA boundary, review if unexpected.'
    END AS COMMENTS

FROM FINAL
ORDER BY
    PUREPolicyNumber,
    risk_folder_cnt DESC,
    insurance_file_cnt DESC
;
