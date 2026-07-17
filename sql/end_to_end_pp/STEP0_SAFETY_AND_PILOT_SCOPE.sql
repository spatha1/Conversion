-- ============================================================
-- STEP 0 — Safety check + pilot scope definition
-- Run on: Capricorn-Dev-SwiftConversion (SQL Server, AZURE_SQLSERVER_HOST)
-- Type: READ-ONLY (safe to run any time)
-- ============================================================

-- 0a. Is the Timer Trigger polling globally enabled?
--     If IsEnable=0, none of the 10 Process_N views return work and
--     nothing queued below will ever get picked up.
SELECT * FROM PSD.Enable_View;
-- Expected: IsEnable = 1. If 0, STOP and ask whoever owns the Timer
-- Trigger before proceeding — queuing work now would just pile up.

-- 0b. Confirm which ConfigRequestIds are actively polled right now
--     (cross-check against the 10 Process_N view definitions —
--     currently 33, 35, 17, 42; Process_1 is fully commented out/dormant).
SELECT ConfigrequestId, RequestName, SourceTableName, IsActive
FROM PSD.Configrequest
WHERE ConfigrequestId IN (33, 35, 17, 42)
ORDER BY ConfigrequestId;

-- 0c. Current backlog per active config — sanity check before adding more work
SELECT ConfigrequestId,
       COUNT(*)                                   AS TOTAL,
       SUM(CASE WHEN IsProcessed=1 THEN 1 ELSE 0 END) AS PROCESSED,
       SUM(CASE WHEN IsProcessed=0 THEN 1 ELSE 0 END) AS PENDING
FROM PSD.Configdata
WHERE ConfigrequestId IN (33, 35, 17, 42)
GROUP BY ConfigrequestId;

-- ============================================================
-- 0d. PILOT SCOPE — define a small, fixed policy set before running
--     anything against the full DEV population. Everything downstream
--     (Steps 1-10) should filter to this list until the chain is
--     proven end to end.
--
--     Recommendation: 5-10 policies, mix of HB/HC/motor, at least one
--     already-known-good policy (e.g. from the 38-policy UAT batch)
--     so we have a comparison point.
-- ============================================================
-- Run this on Snowflake (AGGNE.DEV) to pick the pilot set, then paste
-- the resulting LEGACYPOLICYNUMBER list into a fixed table/list used
-- by every later step:
--
-- SELECT LEGACYPOLICYNUMBER, CMLNUMBER
-- FROM AGGNE.DEV.PER_VW_SAMPLE_FINAL
-- ORDER BY LEGACYPOLICYNUMBER
-- LIMIT 10;
--
-- Paste the chosen LEGACYPOLICYNUMBER values into PP_PILOT_POLICIES
-- below (create once, reuse across all steps):

-- CREATE OR REPLACE TABLE AGGNE.DEV.PP_PILOT_POLICIES (
--     LEGACYPOLICYNUMBER VARCHAR,
--     CMLNUMBER VARCHAR,
--     ADDED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
-- );
-- INSERT INTO AGGNE.DEV.PP_PILOT_POLICIES (LEGACYPOLICYNUMBER, CMLNUMBER)
-- VALUES
--   ('P0xxxxxxx','CMLxxxxxxx'),
--   ...;
-- (DDL — run only after reviewing the picked policies)
