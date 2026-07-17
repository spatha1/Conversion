-- ============================================================
-- STEP 7 — Validate policy response (partial — see note below)
-- Run on: SQL Server + Snowflake (AGGNE.DEV)
-- Type: READ-ONLY checks + ONE piece of DDL still to be finalized
--
-- STATUS: this step is only half-buildable right now. The Timer
-- Trigger already calls DCT for config 42 (confirmed: 388/430
-- processed historically) — but nothing parses the response into
-- PER_POLICY_MIGRATION_DCT.RESULTS_JSON (confirmed: 0/3812 populated
-- as of this session). Party's equivalent works because Party_FinalRun
-- explicitly registers a target/parser (TargetQuery + ConnectionString
-- JSON) — PP has no equivalent registration yet.
--
-- 7a-7b below are checks you CAN run today. 7c (the parser) needs one
-- real raw DCT response body for a PP policy before it can be written
-- accurately — the field names for QuoteID/Status/etc. are currently
-- unknown; guessing them would be worse than leaving this open.
-- ============================================================

-- 7a. SQL Server: did the Timer Trigger process our pilot's queued rows?
SELECT CD.ConfigdataId, CD.Identifier, CD.IsProcessed,
       LEFT(ISNULL(CD.Response,''),300) AS RESPONSE_PREVIEW
FROM PSD.Configdata CD
INNER JOIN PP_Policy_Request_Load_v1 SRC ON SRC.LegacyPolicyNumber = CD.Identifier
WHERE CD.ConfigrequestId = 42
ORDER BY CD.ConfigdataId DESC;

-- >>> If RESPONSE_PREVIEW shows real XML (not just an echoed identifier
--     like ["P00010162"]), COPY ONE FULL Response value out and share
--     it — that's what unlocks 7c. <<<

-- 7b. Snowflake: confirm (as expected) RESULTS_JSON is still empty
--     for the pilot policies — this documents the gap, not fixes it
SELECT LEGACYPOLICYNUMBER, RESPONSE_XML, RESULTS_JSON, UPDATED_AT
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE LEGACYPOLICYNUMBER IN (SELECT LEGACYPOLICYNUMBER FROM AGGNE.DEV.PP_PILOT_POLICIES);

-- ============================================================
-- 7c. TO BE FINALIZED once a real response body is available.
--     Template (mirrors Party_FinalRun's TargetQuery pattern) —
--     DO NOT run until field names below are confirmed real:
--
-- UPDATE AGGNE.DEV.PER_POLICY_MIGRATION_DCT
-- SET RESPONSE_XML = @F@RESPONSE@L@,
--     RESULTS_JSON = @F@RESULT@L@,     -- shape TBD: [{"QuoteId": "...", "PolicyNumber": "...", "Status": "..."}]
--     UPDATED_AT = CURRENT_TIMESTAMP()
-- WHERE TRIM(LEGACYPOLICYNUMBER) = @F@Identifier@L@;
--
-- GetResultnodes  = 'QuoteId,PolicyNumber,Status'   -- TBD, confirm actual node names
-- GetResultattributes = 'QuoteId'                    -- TBD
-- ============================================================
