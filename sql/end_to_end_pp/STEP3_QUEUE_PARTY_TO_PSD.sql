-- ============================================================
-- STEP 3 — Queue Party identifiers into PSD (SQL Server)
-- Run on: Capricorn-Dev-SwiftConversion (SQL Server)
-- Type: DML (new CONFIGREQUEST row) + DDL (ALTER VIEW x9 to add
--       the new ConfigRequestId into the Timer Trigger's polling set)
--
-- WHY new config needed: the Timer Trigger's 10 Process_N views only
-- poll ConfigrequestId IN (33,35,17,42) today. None of those target
-- our new DEV-scoped Party table (AGGNE.DEV.CML_MIGRATION_DCT).
-- Reusing config 11 (CML_Create_DCT_Party) is NOT enough on its own —
-- it isn't in the polling rotation either, so anything queued under
-- it would sit forever. We need a new, DEV-targeted config that IS
-- added to the rotation.
-- ============================================================

-- 3a. Register a new ConfigRequest for DEV Party pushes
--     (let ConfigrequestId auto-generate; do not hardcode it)
INSERT INTO PSD.Configrequest
    (RequestName, ConfigSourceTypeId, SourceTableName, RequestBody,
     API_URL, IsActive, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate,
     ModRequest)
SELECT
    'PP_Party_DEV_Create',
    2,
    'CML_MIGRATION_DCT_DEV_PENDING',   -- logical name; actual query below
    '[{"requestName": "PP_Party_DEV_Create",
       "requestURL": "https://aued1026.duckcreekondemand.com/ServerPolicy/DCTServer.aspx",
       "requestBody": "<see REQUEST_XML column, already fully built>",
       "Identifier": "[CML_NUMBER]",
       "mappingObj": [],
       "responseConfigObj": []}]',
    'https://capricorn.devdps.aggne.com/dctRequest',
    1,
    1, GETDATE(), 1, GETDATE(),
    NULL;

DECLARE @NewConfigRequestId INT = SCOPE_IDENTITY();
SELECT @NewConfigRequestId AS NEW_CONFIG_REQUEST_ID;
-- >>> WRITE THIS NUMBER DOWN — needed for 3b, 3c, Step 4, and the
--     ALTER VIEW statements below. <<<

-- 3b. Queue the actual identifiers (mirrors Party_FinalRun's pattern —
--     source query pulls pending DEV party requests, one row per CML)
INSERT INTO PSD.Configdata
    (ConfigrequestId, Identifier, HeaderOrder, RequestBody, RequestName,
     UtilRequest, api_url, ResponseKeys, LoadDate, IsBegin, IsProcessed)
SELECT
    @NewConfigRequestId,
    CML_NUMBER,
    0,
    REQUEST_XML,
    'PP_Party_DEV_Create',
    'https://aued1026.duckcreekondemand.com/ServerPolicy/DCTServer.aspx',
    'https://capricorn.devdps.aggne.com/dctRequest',
    NULL,
    GETDATE(), 0, 0
FROM OPENQUERY([<SNOWFLAKE_LINKED_SERVER_NAME>],   -- confirm linked server name before running
    'SELECT CML_NUMBER, REQUEST_XML FROM AGGNE.DEV.CML_MIGRATION_DCT
     WHERE RESPONSE_XML IS NULL
       AND CML_NUMBER IN (SELECT CMLNUMBER FROM AGGNE.DEV.PP_MISSING_PARTY_CMLS)')
     AS SRC;

-- 3c. Confirm queued
SELECT ConfigrequestId, COUNT(*) AS QUEUED
FROM PSD.Configdata WHERE ConfigrequestId = @NewConfigRequestId
GROUP BY ConfigrequestId;

-- ============================================================
-- 3d. DDL — add the new ConfigRequestId to the Timer Trigger's
--     active polling rotation (all 10 Process_N views).
--     *** This is the DDL step that should sit behind the password
--     gate you mentioned for the future UI. ***
--
--     Pattern per view (repeat for Process_2 through Process_10 —
--     Process_1 is currently fully commented out/dormant, skip it
--     unless you also want to reactivate it):
--
--     ALTER VIEW PSD.Process_N AS
--     select top 1 * from (
--     select top 1 t1.ConfigdataId,t1.RequestBody,t1.RequestName,t1.api_url,
--            t1.Bucket,t1.UtilRequest,T1.Identifier,t1.ConfigrequestId,
--            HeaderType='XML', 1 as Rorder
--     from  psd.Configdata t1
--     where ConfigrequestId in (33,35,17,42,@NewConfigRequestId)   -- ADDED
--       and t1.IsBegin=0 and t1.IsProcessed=0  AND BUCKET in (N)
--     union all
--     select top 1 t1.ConfigdataId,t1.RequestBody,t1.RequestName,t1.api_url,
--            t1.Bucket,t1.UtilRequest,T1.Identifier,t1.ConfigrequestId,
--            HeaderType='XML', 2 as Rorder
--     from  psd.Configdata t1
--     where ConfigrequestId in (33,35,17,42,@NewConfigRequestId)   -- ADDED
--       AND BUCKET in (N) and (Response like '%502 Bad Gateway%'
--                           or  Response like '%504 Gateway Time-out%')
--     ) a
--     where 1=(select IsEnable from PSD.Enable_View)
--     order by Rorder;
--
--     DO NOT run this until: (a) 3a-3c succeeded, (b) you've confirmed
--     the Snowflake linked server name, (c) whoever owns the Timer
--     Trigger infra is aware a new config ID is entering rotation.
-- ============================================================
