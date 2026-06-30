-- ============================================================
-- Pure to Write — CoverEndDate SIMULATION (STATUS_FLAG = D excluded)
-- Policies : P00022895, P00031597
-- Simulates the fix: excludes deleted/rolled-back MTA records (STATUS_FLAG=D)
-- from the LAG chain to show corrected CoverEndDate values.
-- Safe: SELECT only, no writes
-- ============================================================

WITH

-- ── Step 1 ───────────────────────────────────────────────────────────────
-- Same as SP T_Policyattach_000
-- FIX APPLIED: STATUS_FLAG = 'D' records excluded from source pull
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
      AND ifrl.status_flag <> 'D'        -- FIX: exclude deleted/rolled-back MTA records
),

-- ── Step 2 ───────────────────────────────────────────────────────────────
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
STEP3 AS (
    SELECT *,
        LAG(Pol_type_adj) OVER (
            PARTITION BY PUREPolicyNumber
            ORDER BY risk_folder_cnt DESC, insurance_file_cnt DESC
        ) AS LagPolType
    FROM STEP2
),

-- ── Step 5 ───────────────────────────────────────────────────────────────
FINAL AS (
    SELECT *,
        CASE
            WHEN rn3 = 1
                 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN PUREExpiryDate
            WHEN LagPolType = 'MTA Cancelled'
                THEN CoverEndDate_pre
            ELSE DATEADD(DAY, -1, CoverEndDate_pre)
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
    status_flag                              AS STATUS_FLAG,
    TransactionType                          AS TRANSACTION_TYPE,

    CASE
        WHEN CoverEndDate = PUREExpiryDate
            THEN 'FIXED: CoverEndDate now correctly = PUREExpiryDate ('
              || TO_CHAR(PUREExpiryDate, 'YYYY-MM-DD')
              || '). Premise will be included in DOL combinations.'

        WHEN insurance_file_status_id = 3
             AND CoverEndDate <> PUREExpiryDate
            THEN 'STILL ISSUE: Renewal remains Under Renewal in PURE. '
              || 'CoverEndDate = ' || TO_CHAR(CoverEndDate, 'YYYY-MM-DD')
              || '. Renewal must be finalised in PURE to resolve.'

        WHEN LagPolType = 'MTA Cancelled'
             AND CoverEndDate <> PUREExpiryDate
            THEN 'STILL ISSUE: CoverEndDate truncated to '
              || TO_CHAR(CoverEndDate, 'YYYY-MM-DD')
              || '. Another MTA Cancelled record still in LAG chain.'

        ELSE 'OK: Normal MTA boundary — CoverEndDate ('
          || TO_CHAR(CoverEndDate, 'YYYY-MM-DD')
          || ') differs from PUREExpiryDate ('
          || TO_CHAR(PUREExpiryDate, 'YYYY-MM-DD')
          || ') as expected.'
    END AS COMMENTS

FROM FINAL
ORDER BY
    PUREPolicyNumber,
    risk_folder_cnt DESC,
    insurance_file_cnt DESC
;
