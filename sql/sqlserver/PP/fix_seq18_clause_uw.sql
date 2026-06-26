-- ============================================================
-- SQL Server: Fix seq 18 RISK_Building_PM template
--
-- Problems:
--   1. Template uses {CLAUSE} but PER_COM_PAYLOAD column is COM_CLAUSE
--      → DYNAMIC_XML_V1 never resolves {CLAUSE} because no column
--        named CLAUSE exists in the source view.
--   2. {UW} was unresolvable because UW was commented out in
--      PER_COM_PAYLOAD (now fixed in view DDL).
--
-- Fixes applied here:
--   - Replace {CLAUSE} with {COM_CLAUSE} in seq 18 template.
--   - {UW} requires no template change — PER_COM_PAYLOAD now
--     exposes UW column (fix_com_payload view update).
--
-- SAFE_MODE: Run manually against PolicyConversion DB.
-- After applying, delete stale RISK_Building_PM rows and
-- re-run seq 18 via DYNAMIC_XML_V1, then re-run final SPs.
-- ============================================================


-- Step 1: Preview — confirm {CLAUSE} exists and check {UW} presence
SELECT
    SequenceID,
    ScriptName,
    CHARINDEX('{CLAUSE}',    ConversionScript) AS CLAUSE_POS,
    CHARINDEX('{COM_CLAUSE}',ConversionScript) AS COM_CLAUSE_POS,
    CHARINDEX('{UW}',        ConversionScript) AS UW_POS
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 18
  AND IsActive   = 1;
-- Expected: CLAUSE_POS > 0, COM_CLAUSE_POS = 0, UW_POS > 0


-- Step 2: Apply fix — {CLAUSE} → {COM_CLAUSE}
UPDATE dbo.PP_ConversionConfig
SET    ConversionScript = REPLACE(ConversionScript, '{CLAUSE}', '{COM_CLAUSE}')
WHERE  SequenceID = 18
  AND  IsActive   = 1;


-- Step 3: Verify fix
SELECT
    SequenceID,
    ScriptName,
    CASE WHEN CHARINDEX('{CLAUSE}',     ConversionScript) > 0
              AND CHARINDEX('{COM_CLAUSE}', ConversionScript) = 0
         THEN 'FAIL — old {CLAUSE} still present'
         WHEN CHARINDEX('{COM_CLAUSE}', ConversionScript) > 0
         THEN 'OK — {COM_CLAUSE} in place'
         ELSE 'CHECK — neither token found'
    END AS CHECK_STATUS,
    CHARINDEX('{UW}',         ConversionScript) AS UW_POS,
    CHARINDEX('{COM_CLAUSE}', ConversionScript) AS COM_CLAUSE_POS
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 18
  AND IsActive   = 1;
-- Expected: CHECK_STATUS = 'OK — {COM_CLAUSE} in place', UW_POS > 0
