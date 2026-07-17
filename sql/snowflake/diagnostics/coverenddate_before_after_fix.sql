-- ============================================================
-- CoverEndDate Before vs After Fix — T_Policyattach_002 base
-- Root cause: missing safety check (CoverEndDate < CoverStartDate)
-- SAS equivalent: IF CoverEndDate < CoverStartDate THEN CoverEndDate = PUREExpiryDate
-- Known affected: P00022895 (19 Jul 2022 -> 19 Jul 2026)
-- ============================================================
-- Run Query 1 for SUMMARY, Query 2 for DETAIL
-- ============================================================


-- ============================================================
-- QUERY 1: SUMMARY + BREAKDOWN
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
    -- no filter here: LAG must see MTA Cancelled rows to correctly compute LagPolType
),

before_after AS (
    SELECT
        PUREPolicyNumber,
        insurance_file_cnt,
        RISK_FOLDER_CNT,
        RISK_ADDRESS,
        CoverStartDate,
        PUREExpiryDate,
        Pol_type_adj,
        LagPolType,
        rn3,
        CoverEndDate_pre,

        -- BEFORE: current Snowflake SP logic (no safety check)
        CASE
            WHEN rn3 = 1 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN PUREExpiryDate
            WHEN LagPolType = 'MTA Cancelled'
                THEN CoverEndDate_pre
            ELSE DATEADD(DAY, -1, CoverEndDate_pre)
        END AS CoverEndDate_BEFORE,

        -- AFTER: with safety check (SAS equivalent)
        CASE
            WHEN rn3 = 1 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN PUREExpiryDate
            WHEN LagPolType = 'MTA Cancelled'
                THEN IFF(CoverEndDate_pre < CoverStartDate, PUREExpiryDate, CoverEndDate_pre)
            WHEN DATEADD(DAY, -1, CoverEndDate_pre) < CoverStartDate
                THEN PUREExpiryDate
            ELSE DATEADD(DAY, -1, CoverEndDate_pre)
        END AS CoverEndDate_AFTER

    FROM lags
    WHERE Pol_type_adj IN ('Live Policy', 'MTA Permanent')
),

classified AS (
    SELECT
        *,
        CASE
            WHEN CoverEndDate_BEFORE IS DISTINCT FROM CoverEndDate_AFTER THEN 'CHANGED'
            ELSE 'NO CHANGE'
        END AS fix_impact,
        DATEDIFF(DAY, CoverEndDate_BEFORE, CoverEndDate_AFTER) AS days_corrected,
        CASE
            WHEN CoverEndDate_BEFORE IS DISTINCT FROM CoverEndDate_AFTER
                 AND LagPolType = 'MTA Cancelled'
                THEN 'MTA Cancelled cross-risk-folder contamination'
            WHEN CoverEndDate_BEFORE IS DISTINCT FROM CoverEndDate_AFTER
                THEN 'CoverEndDate < CoverStartDate (ELSE branch)'
            ELSE 'No change'
        END AS change_reason
    FROM before_after
)

-- SECTION 1: Overall summary
SELECT
    1                                      AS sort_key,
    'SUMMARY'                              AS section,
    fix_impact                             AS "Category",
    COUNT(DISTINCT PUREPolicyNumber)       AS "Distinct Policies",
    COUNT(*)                               AS "Total Records",
    MIN(CoverEndDate_BEFORE)::VARCHAR      AS "Earliest Wrong Date (Before)",
    MAX(CoverEndDate_BEFORE)::VARCHAR      AS "Latest Wrong Date (Before)",
    MIN(days_corrected)::VARCHAR           AS "Min Days Corrected",
    MAX(days_corrected)::VARCHAR           AS "Max Days Corrected",
    ROUND(AVG(days_corrected), 0)::VARCHAR AS "Avg Days Corrected"
FROM classified
GROUP BY fix_impact

UNION ALL

-- SECTION 2: Breakdown by reason
SELECT
    2                                      AS sort_key,
    'BY REASON'                            AS section,
    change_reason                          AS "Category",
    COUNT(DISTINCT PUREPolicyNumber)       AS "Distinct Policies",
    COUNT(*)                               AS "Total Records",
    MIN(CoverEndDate_BEFORE)::VARCHAR      AS "Earliest Wrong Date (Before)",
    MAX(CoverEndDate_BEFORE)::VARCHAR      AS "Latest Wrong Date (Before)",
    MIN(days_corrected)::VARCHAR           AS "Min Days Corrected",
    MAX(days_corrected)::VARCHAR           AS "Max Days Corrected",
    ROUND(AVG(days_corrected), 0)::VARCHAR AS "Avg Days Corrected"
FROM classified
GROUP BY change_reason

ORDER BY sort_key, "Category";


-- ============================================================
-- QUERY 2: DETAIL — all CHANGED records
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
    -- no filter here: LAG must see MTA Cancelled rows to correctly compute LagPolType
),

before_after AS (
    SELECT
        PUREPolicyNumber,
        insurance_file_cnt,
        RISK_FOLDER_CNT,
        RISK_ADDRESS,
        CoverStartDate,
        PUREExpiryDate,
        Pol_type_adj,
        LagPolType,
        rn3,
        CoverEndDate_pre,

        CASE
            WHEN rn3 = 1 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN PUREExpiryDate
            WHEN LagPolType = 'MTA Cancelled'
                THEN CoverEndDate_pre
            ELSE DATEADD(DAY, -1, CoverEndDate_pre)
        END AS CoverEndDate_BEFORE,

        CASE
            WHEN rn3 = 1 AND COALESCE(LagPolType, '__NOT_MTA__') <> 'MTA Cancelled'
                THEN PUREExpiryDate
            WHEN LagPolType = 'MTA Cancelled'
                THEN IFF(CoverEndDate_pre < CoverStartDate, PUREExpiryDate, CoverEndDate_pre)
            WHEN DATEADD(DAY, -1, CoverEndDate_pre) < CoverStartDate
                THEN PUREExpiryDate
            ELSE DATEADD(DAY, -1, CoverEndDate_pre)
        END AS CoverEndDate_AFTER

    FROM lags
    WHERE Pol_type_adj IN ('Live Policy', 'MTA Permanent')  -- match T_Policyattach_006 filter
)

SELECT
    PUREPolicyNumber                                          AS "Policy Number",
    RISK_FOLDER_CNT                                          AS "Risk Folder CNT",
    insurance_file_cnt                                       AS "Ins File CNT",
    RISK_ADDRESS                                             AS "Risk Address",
    Pol_type_adj                                             AS "Pol Type",
    rn3                                                      AS "rn3",
    LagPolType                                               AS "Lag Pol Type",
    CoverStartDate                                           AS "Cover Start",
    PUREExpiryDate                                           AS "PURE Expiry",
    CoverEndDate_pre                                         AS "CoverEndDate_pre (LAG value)",
    CoverEndDate_BEFORE                                      AS "CoverEndDate BEFORE Fix",
    CoverEndDate_AFTER                                       AS "CoverEndDate AFTER Fix",
    DATEDIFF(DAY, CoverEndDate_BEFORE, CoverEndDate_AFTER)  AS "Days Corrected",
    CASE
        WHEN LagPolType = 'MTA Cancelled'
            THEN 'MTA Cancelled cross-risk-folder contamination'
        ELSE 'CoverEndDate < CoverStartDate (ELSE branch)'
    END                                                      AS "Change Reason"
FROM before_after
WHERE CoverEndDate_BEFORE IS DISTINCT FROM CoverEndDate_AFTER
ORDER BY PUREPolicyNumber, RISK_FOLDER_CNT DESC, insurance_file_cnt DESC;
