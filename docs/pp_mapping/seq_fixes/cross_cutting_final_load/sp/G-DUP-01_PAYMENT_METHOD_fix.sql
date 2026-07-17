-- ============================================================
-- G-DUP-01 — POLICYCONVERSION_PAYMENT_METHOD produces duplicate PER_FINAL rows (P1)
-- Found 2026-07-13 while validating for duplicate final/XML rows per policy.
-- ============================================================
--
-- ROOT CAUSE: this table's build does SELECT DISTINCT POLICY_BINDER_ID, SCHEMENAME over the FULL
-- PFPREMIUMFINANCE history for each policy binder, with no way to pick the current plan. When a
-- policy's finance plan changed (revised, or renewed into a new plan with a different payment
-- frequency), two distinct (POLICY_BINDER_ID, PAYMENT_METHOD) rows survive instead of one.
--
-- CONFIRMED live (P00024003 / POLICY_BINDER_ID=2265957): 3 raw PFPREMIUMFINANCE rows —
--   PFPREM_FINANCE_CNT=305327 v1  'Monthly - AU'   STARTDATE=2024-11-25  (older renewal term)
--   PFPREM_FINANCE_CNT=334743 v1  'Monthly - AU'   STARTDATE=2025-05-14  (superseded)
--   PFPREM_FINANCE_CNT=334743 v2  'Annually - AU'  STARTDATE=2025-06-27  (current — later version
--                                                                          of the same plan)
-- The DISTINCT collapses the two 305327/334743-v1 'Monthly' rows into one, but 'Annually' (the
-- actually-current value) survives as a second, separate row — 2 rows total for 1 policy.
--
-- DOWNSTREAM IMPACT: PER_CONVERSION_FINAL_LOAD joins this table on EXPIRINGID_P=POLICY_BINDER_ID
-- with no de-dup, so every extra PAYMENT_METHOD row fans out into a full extra PER_FINAL row for
-- that policy. Confirmed live: 72 policies affected in AGGNE.DEV.PER_FINAL, propagating to the
-- real DCT-facing AGGNE.DEV.PER_POLICY_MIGRATION_DCT (71-72 duplicated there too) — i.e. this
-- would submit duplicate quotes to DCT if run as-is.
--
-- FIX: keep only the most recent finance-plan row per POLICY_BINDER_ID before collapsing to
-- (POLICY_BINDER_ID, PAYMENT_METHOD). "Most recent" = latest STARTDATE, tie-broken by the finance
-- plan's own versioning (PFPREM_FINANCE_CNT, then PFPREM_FINANCE_VERSION) — both are genuine
-- recency signals on this table (a higher CNT is a newer finance plan; a higher VERSION is a later
-- revision of the same plan), not a guess.
--
-- SCOPE NOTE: only the PAYMENT_METHOD/STARTDATE/recency columns are added to the two source CTEs
-- and the new de-dup step is inserted before the final CASE — the join chain, source tables, and
-- final output shape (POLICY_BINDER_ID, PAYMENT_METHOD) are unchanged.
--
-- Quoting: shown here with doubled single-quotes ('' instead of ') to match how this block is
-- embedded inside SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD's single-quoted procedure body — paste
-- as-is in place of the existing CREATE OR REPLACE TABLE AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD
-- statement inside that SP (search for the exact OLD CODE text below, do not rely on a line number
-- since BP edits this same SP concurrently and line numbers shift).
-- ============================================================

-- ┌─── OLD CODE (current, live) ───────────────────────────────────────────────
-- │ CREATE OR REPLACE TABLE AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD AS
-- │ WITH payment_method_per AS (
-- │     SELECT DISTINCT
-- │         t1.PER_POLICY_BINDER_ID AS POLICY_BINDER_ID,
-- │         t7.SCHEMENAME           AS PAYMENT_METHOD
-- │     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RiskSelection t1
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder t2
-- │         ON t1.RLEXPIRINGPOLICYBINDERID = t2.PER_POLICY_BINDER_ID
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t3
-- │         ON t2.GIS_POLICY_LINK_ID = t3.GIS_POLICY_LINK_ID
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t4
-- │         ON t4.RISK_CNT = t3.RISK_ID
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t6
-- │         ON t4.RISK_CNT = t6.RISK_CNT
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PFPREMIUMFINANCE t7
-- │         ON t6.INSURANCE_FILE_CNT = t7.INSURANCE_FILE_CNT
-- │ ),
-- │ payment_method_cbp AS (
-- │     SELECT DISTINCT
-- │         t1.CBP_POLICY_BINDER_ID AS POLICY_BINDER_ID,
-- │         t7.SCHEMENAME           AS PAYMENT_METHOD
-- │     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t1
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_Policy_Binder t2
-- │         ON t1.RLEXPIRINGPOLICYBINDERID = t2.CBP_POLICY_BINDER_ID
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t3
-- │         ON t2.GIS_POLICY_LINK_ID = t3.GIS_POLICY_LINK_ID
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk  t4
-- │         ON t4.RISK_CNT = t3.RISK_ID
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t6
-- │         ON t4.RISK_CNT = t6.RISK_CNT
-- │     INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PFPREMIUMFINANCE t7
-- │         ON t6.INSURANCE_FILE_CNT = t7.INSURANCE_FILE_CNT
-- │ ),
-- │ combined AS (
-- │     SELECT * FROM payment_method_per
-- │     UNION ALL
-- │     SELECT * FROM payment_method_cbp
-- │ )
-- │ SELECT
-- │     POLICY_BINDER_ID,
-- │     CASE
-- │         WHEN SUBSTR(PAYMENT_METHOD, 1, 1) = ''M'' THEN ''Monthly''
-- │         WHEN SUBSTR(PAYMENT_METHOD, 1, 1) = ''A'' THEN ''Annually''
-- │         ELSE PAYMENT_METHOD
-- │     END AS PAYMENT_METHOD
-- │ FROM combined;
-- └─────────────────────────────────────────────────────────────────────────────

-- NEW CODE (paste in place of the block above):
CREATE OR REPLACE TABLE AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD AS
WITH payment_method_per AS (
    SELECT DISTINCT
        t1.PER_POLICY_BINDER_ID AS POLICY_BINDER_ID,
        t7.SCHEMENAME           AS PAYMENT_METHOD,
        t7.STARTDATE            AS STARTDATE,
        t7.PFPREM_FINANCE_CNT   AS PFPREM_FINANCE_CNT,
        t7.PFPREM_FINANCE_VERSION AS PFPREM_FINANCE_VERSION
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RiskSelection t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder t2
        ON t1.RLEXPIRINGPOLICYBINDERID = t2.PER_POLICY_BINDER_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t3
        ON t2.GIS_POLICY_LINK_ID = t3.GIS_POLICY_LINK_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t4
        ON t4.RISK_CNT = t3.RISK_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t6
        ON t4.RISK_CNT = t6.RISK_CNT
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PFPREMIUMFINANCE t7
        ON t6.INSURANCE_FILE_CNT = t7.INSURANCE_FILE_CNT
),
payment_method_cbp AS (
    SELECT DISTINCT
        t1.CBP_POLICY_BINDER_ID AS POLICY_BINDER_ID,
        t7.SCHEMENAME           AS PAYMENT_METHOD,
        t7.STARTDATE            AS STARTDATE,
        t7.PFPREM_FINANCE_CNT   AS PFPREM_FINANCE_CNT,
        t7.PFPREM_FINANCE_VERSION AS PFPREM_FINANCE_VERSION
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_Policy_Binder t2
        ON t1.RLEXPIRINGPOLICYBINDERID = t2.CBP_POLICY_BINDER_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t3
        ON t2.GIS_POLICY_LINK_ID = t3.GIS_POLICY_LINK_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk  t4
        ON t4.RISK_CNT = t3.RISK_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t6
        ON t4.RISK_CNT = t6.RISK_CNT
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PFPREMIUMFINANCE t7
        ON t6.INSURANCE_FILE_CNT = t7.INSURANCE_FILE_CNT
),
combined AS (
    SELECT * FROM payment_method_per
    UNION ALL
    SELECT * FROM payment_method_cbp
),
-- FIX (G-DUP-01): keep only the most recent finance-plan row per policy binder — most recent
-- STARTDATE first, then the finance plan''s own recency signals (a higher PFPREM_FINANCE_CNT is a
-- newer plan; a higher PFPREM_FINANCE_VERSION is a later revision of the same plan) as tie-breaks.
ranked AS (
    SELECT
        POLICY_BINDER_ID,
        PAYMENT_METHOD,
        ROW_NUMBER() OVER (
            PARTITION BY POLICY_BINDER_ID
            ORDER BY STARTDATE DESC NULLS LAST,
                     PFPREM_FINANCE_CNT DESC NULLS LAST,
                     PFPREM_FINANCE_VERSION DESC NULLS LAST
        ) AS RN
    FROM combined
)
SELECT
    POLICY_BINDER_ID,
    CASE
        WHEN SUBSTR(PAYMENT_METHOD, 1, 1) = ''M'' THEN ''Monthly''
        WHEN SUBSTR(PAYMENT_METHOD, 1, 1) = ''A'' THEN ''Annually''
        ELSE PAYMENT_METHOD
    END AS PAYMENT_METHOD
FROM ranked
WHERE RN = 1;


-- ============================================================
-- PRE-VALIDATION (2026-07-13 baseline, confirmed live)
-- ============================================================
SELECT COUNT(*), COUNT(DISTINCT POLICY_BINDER_ID) FROM AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD;
-- Baseline: rows > distinct POLICY_BINDER_ID (duplicates present)

SELECT COUNT(*), COUNT(DISTINCT LEGACYPOLICYNUMBER) FROM AGGNE.DEV.PER_FINAL;
-- Baseline: 4059 rows / 3987 distinct policies (72 duplicated)

SELECT COUNT(*), COUNT(DISTINCT LEGACYPOLICYNUMBER) FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;
-- Baseline: 4010 rows / 3939 distinct policies (71 duplicated)


-- ============================================================
-- POST-VALIDATION — run after the SP patch is deployed, SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()
-- re-run (rebuilds POLICYCONVERSION_PAYMENT_METHOD), then PER_CONVERSION_FINAL_LOAD() and
-- PER_CONVERSION_FINAL_XML() re-run (rebuild PER_FINAL / PER_POLICY_MIGRATION_DCT)
-- ============================================================

-- 1) Exactly one row per policy binder now
SELECT COUNT(*), COUNT(DISTINCT POLICY_BINDER_ID) FROM AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD;
-- Target: equal counts

-- 2) P00024003 specifically resolves to the correct current value (Annually, per the live trace above)
SELECT * FROM AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD WHERE POLICY_BINDER_ID = 2265957;
-- Target: exactly 1 row, PAYMENT_METHOD = 'Annually'

-- 3) No more duplicate policies in PER_FINAL or the real DCT-facing table
SELECT COUNT(*), COUNT(DISTINCT LEGACYPOLICYNUMBER) FROM AGGNE.DEV.PER_FINAL;
SELECT COUNT(*), COUNT(DISTINCT LEGACYPOLICYNUMBER) FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;
-- Target: row count = distinct policy count, both tables
-- ============================================================
