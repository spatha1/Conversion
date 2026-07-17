-- ============================================================
-- STEP 4 — Validate Party response
-- Run on: SQL Server (Capricorn-Dev-SwiftConversion) + Snowflake (AGGNE.DEV)
-- Type: READ-ONLY
-- Run this AFTER waiting a few minutes for the Timer Trigger to
-- process the queued rows from Step 3.
-- ============================================================

-- ---------- SQL Server side: did the Timer Trigger process our rows? ----------
SELECT ConfigdataId, Identifier, IsProcessed,
       LEFT(ISNULL(Response,''),200) AS RESPONSE_PREVIEW
FROM PSD.Configdata
WHERE ConfigrequestId = @NewConfigRequestId   -- from Step 3
ORDER BY ConfigdataId DESC;

SELECT
  COUNT(*) AS TOTAL,
  SUM(CASE WHEN IsProcessed=1 THEN 1 ELSE 0 END) AS PROCESSED,
  SUM(CASE WHEN Response LIKE '%502%' OR Response LIKE '%504%' THEN 1 ELSE 0 END) AS GATEWAY_ERRORS
FROM PSD.Configdata
WHERE ConfigrequestId = @NewConfigRequestId;


-- ---------- Snowflake side: did RESPONSE_XML land on the live table? ----------
-- Run on AGGNE.DEV
SELECT CML_NUMBER, LEN(RESPONSE_XML) AS RESP_LEN,
       SUBSTR(RESPONSE_XML,1,300) AS RESP_PREVIEW,
       CREATED_AT
FROM AGGNE.DEV.CML_MIGRATION_DCT
WHERE CML_NUMBER IN (SELECT CMLNUMBER FROM AGGNE.DEV.PP_MISSING_PARTY_CMLS)
ORDER BY CREATED_AT DESC;

-- IMPORTANT CAVEAT: AGGNE.DEV.VW_PARTYDET reads from
-- CML_MIGRATION_DCT_PREVDATA, NOT the live CML_MIGRATION_DCT table.
-- We have not confirmed what process (if any) archives completed rows
-- from the live table into _PREVDATA for DEV. If the query below
-- returns nothing even though RESPONSE_XML above is populated, THIS
-- is the missing link — check PP's own FINAL_XML SP for the archive
-- pattern (INSERT INTO ..._PREVDATA SELECT * FROM live; TRUNCATE live)
-- and confirm whether Party has an equivalent for DEV.

SELECT * FROM AGGNE.DEV.VW_PARTYDET
WHERE CML_NUMBER IN (SELECT CMLNUMBER FROM AGGNE.DEV.PP_MISSING_PARTY_CMLS);

-- If VW_PARTYDET is empty for these CMLs but CML_MIGRATION_DCT.RESPONSE_XML
-- is populated, query CML_MIGRATION_DCT.RESULTS_JSON directly instead
-- (bypassing the view) to confirm the PartyId is at least present in the data:
SELECT CML_NUMBER,
       RESULTS_JSON,
       f.value:"PartyId"::STRING AS PARTY_ID_EXTRACTED
FROM AGGNE.DEV.CML_MIGRATION_DCT,
     LATERAL FLATTEN(input => TRY_PARSE_JSON(RESULTS_JSON)) f
WHERE CML_NUMBER IN (SELECT CMLNUMBER FROM AGGNE.DEV.PP_MISSING_PARTY_CMLS)
  AND NULLIF(TRIM(f.value:"PartyId"::STRING), '') IS NOT NULL;

-- GATE: do not proceed to Step 5 for a given policy until its CML
-- shows a non-null PartyId here (either via VW_PARTYDET or the
-- direct flatten query above).
