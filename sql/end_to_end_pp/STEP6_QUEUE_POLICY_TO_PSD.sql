-- ============================================================
-- STEP 6 — Queue policy identifiers into PSD (SQL Server)
-- Run on: Capricorn-Dev-SwiftConversion (SQL Server)
-- Type: DML — mirrors Party_FinalRun's pattern exactly, but for
--       ConfigRequestId=42 (PP_CreatePolicy), which is ALREADY in
--       the Timer Trigger's active polling rotation. No DDL needed
--       here — unlike Step 3, this config already exists and is
--       already polled.
--
-- NOTE on HB_PP_PolicyConversion_LoadViews: that SP currently ends
-- with `EXEC PSD.udf_generate_configdata 16`, but 16 is
-- BP_ConfigRequest, not PP. Do NOT rely on that SP for this step —
-- it's queuing into the wrong config (a bug worth fixing separately).
-- This script queues directly into config 42 instead.
-- ============================================================

-- 6-PRECHECK: confirm actual column names before running 6a.
-- I inferred SNO/LegacyPolicyNumber/RequestBody by analogy to
-- Party_Request_Load_V1 (which I did inspect) — PP_Policy_Request_Load_v1
-- itself I have NOT queried directly. Run this first and adjust 6a's
-- column names to match whatever comes back:
EXEC sp_columns 'PP_Policy_Request_Load_v1';
SELECT TOP 5 * FROM PP_Policy_Request_Load_v1;  -- see real column names + sample data

-- 6a. Insert pilot policies' XML into the source table config 42 reads
-- (adjust column names per the precheck above before running)
INSERT INTO PP_Policy_Request_Load_v1 (SNO, LegacyPolicyNumber, RequestBody)
SELECT
    CAST(REPLACE(NEWID(),'-','') AS VARCHAR(100)),
    SRC.LEGACYPOLICYNUMBER,
    SRC.REQUEST_XML
FROM OPENQUERY([<SNOWFLAKE_LINKED_SERVER_NAME>],   -- confirm linked server name before running
    'SELECT LEGACYPOLICYNUMBER, REQUEST_XML
     FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
     WHERE LEGACYPOLICYNUMBER IN (SELECT LEGACYPOLICYNUMBER FROM AGGNE.DEV.PP_PILOT_POLICIES)')
     AS SRC
LEFT JOIN PP_Policy_Request_Load_v1 EXIST
       ON EXIST.LegacyPolicyNumber = SRC.LEGACYPOLICYNUMBER
WHERE EXIST.LegacyPolicyNumber IS NULL;   -- dedupe: don't re-queue already-queued policies

-- 6b. Generate the CONFIGDATA rows for config 42
EXEC PSD.udf_generate_configdata 42;

-- 6c. Bucket assignment (matches Party_FinalRun's final step)
UPDATE t1
SET Bucket = t2.SNO
FROM PSD.Configdata t1
INNER JOIN PP_Policy_Request_Load_v1 t2 ON t1.Identifier = t2.SNO
WHERE t1.ConfigrequestId = 42;

-- 6d. Confirm queued (joins back through PP_Policy_Request_Load_v1,
--     which only contains rows we just inserted in 6a — already
--     pilot-scoped, no extra filter needed)
SELECT CD.ConfigdataId, CD.Identifier, CD.Bucket, CD.IsProcessed
FROM PSD.Configdata CD
INNER JOIN PP_Policy_Request_Load_v1 SRC ON SRC.LegacyPolicyNumber = CD.Identifier
WHERE CD.ConfigrequestId = 42
ORDER BY CD.ConfigdataId DESC;
