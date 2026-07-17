-- ============================================================
-- P00022895 (HIGHWAY AUTOBARN) — CoverEndDate step-by-step trace
-- Shows exactly how each record flows through the pipeline
-- and why 19 Jul 2022 appears instead of 19 Jul 2026
-- ============================================================

WITH

lags AS (
    SELECT
        PUREPolicyNumber,
        insurance_file_cnt,
        CoverStartDate,
        rn3,
        PUREExpiryDate,
        CoverEndDate_pre,
        RISK_FOLDER_CNT,
        RISK_ADDRESS,
        Pol_type_adj,
        LAG(Pol_type_adj) OVER (
            PARTITION BY TRIM(PUREPolicyNumber)
            ORDER BY RISK_FOLDER_CNT DESC, insurance_file_cnt DESC
        ) AS LagPolType
    FROM AGGNE.PRD.T_Policyattach_002
    WHERE TRIM(PUREPolicyNumber) = 'P00022895'
),

trace AS (
    SELECT
        PUREPolicyNumber,
        RISK_FOLDER_CNT,
        insurance_file_cnt,
        RISK_ADDRESS,
        Pol_type_adj,
        CoverStartDate,
        PUREExpiryDate,
        rn3,
        LagPolType,
        CoverEndDate_pre,

        -- Filter condition breakdown
        (rn3 = 1)                                                        AS "is_first_in_folder",
        COALESCE(LagPolType, '__NOT_MTA__')                              AS "LagPolType_coalesced",
        (rn3 = 1 AND COALESCE(LagPolType,'__NOT_MTA__') <> 'MTA Cancelled') AS "branch1_fires",
        (LagPolType = 'MTA Cancelled')                                   AS "branch2_fires",
        (CoverEndDate_pre < CoverStartDate)                              AS "safety_check_would_fire",

        -- BEFORE (current SP logic)
        CASE
            WHEN rn3 = 1 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN PUREExpiryDate
            WHEN LagPolType = 'MTA Cancelled'
                THEN CoverEndDate_pre
            ELSE DATEADD(DAY, -1, CoverEndDate_pre)
        END                                                               AS CoverEndDate_BEFORE,

        -- AFTER (with safety check)
        CASE
            WHEN rn3 = 1 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN PUREExpiryDate
            WHEN LagPolType = 'MTA Cancelled'
                THEN IFF(CoverEndDate_pre < CoverStartDate, PUREExpiryDate, CoverEndDate_pre)
            WHEN DATEADD(DAY, -1, CoverEndDate_pre) < CoverStartDate
                THEN PUREExpiryDate
            ELSE DATEADD(DAY, -1, CoverEndDate_pre)
        END                                                               AS CoverEndDate_AFTER,

        -- Which branch fired
        CASE
            WHEN rn3 = 1 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN 'Branch 1 → PUREExpiryDate'
            WHEN LagPolType = 'MTA Cancelled'
                THEN 'Branch 2 → CoverEndDate_pre (MTA Cancelled)'
            ELSE 'Branch 3 (ELSE) → CoverEndDate_pre - 1'
        END                                                               AS "branch_taken_BEFORE",

        CASE
            WHEN rn3 = 1 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN 'Branch 1 → PUREExpiryDate'
            WHEN LagPolType = 'MTA Cancelled' AND CoverEndDate_pre < CoverStartDate
                THEN 'Branch 2 safety → PUREExpiryDate (FIXED)'
            WHEN LagPolType = 'MTA Cancelled'
                THEN 'Branch 2 → CoverEndDate_pre'
            WHEN DATEADD(DAY, -1, CoverEndDate_pre) < CoverStartDate
                THEN 'Branch 3 safety → PUREExpiryDate (FIXED)'
            ELSE 'Branch 3 (ELSE) → CoverEndDate_pre - 1'
        END                                                               AS "branch_taken_AFTER"

    FROM lags
)

SELECT
    RISK_FOLDER_CNT                                         AS "Risk Folder",
    insurance_file_cnt                                      AS "Ins File CNT",
    RISK_ADDRESS                                            AS "Risk Address",
    Pol_type_adj                                            AS "Pol Type",
    CoverStartDate                                          AS "Cover Start",
    PUREExpiryDate                                          AS "PURE Expiry",
    rn3                                                     AS "rn3",
    LagPolType                                              AS "Lag Pol Type",
    CoverEndDate_pre                                        AS "CoverEndDate_pre (LAG)",
    "branch_taken_BEFORE"                                   AS "Branch Taken (BEFORE Fix)",
    CoverEndDate_BEFORE                                     AS "CoverEndDate BEFORE",
    "branch_taken_AFTER"                                    AS "Branch Taken (AFTER Fix)",
    CoverEndDate_AFTER                                      AS "CoverEndDate AFTER",
    IFF(CoverEndDate_BEFORE <> CoverEndDate_AFTER, '*** CHANGED ***', '') AS "Impact"
FROM trace
ORDER BY RISK_FOLDER_CNT DESC, insurance_file_cnt DESC;
