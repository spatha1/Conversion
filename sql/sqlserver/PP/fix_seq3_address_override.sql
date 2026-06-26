-- ============================================================
-- SQL Server: Fix seq 3 ACC_LOC template
--
-- Problem (ATP-9746 Issue 2):
--   <AddressOverride>1</AddressOverride> is hardcoded in the
--   seq 3 template.  Source LOCATIONDETAILS_PER.OVERRIDE is 0
--   for most policies (4042 rows) and 1 for only 912 rows.
--   Every migrated location incorrectly has AddressOverride=1.
--
-- Fix applied here:
--   Replace hardcoded <AddressOverride>1</AddressOverride>
--   with token <AddressOverride>{ADDRESSOVERRIDE}</AddressOverride>
--
-- Companion view change (already applied):
--   PER_ACCOUNT_LOC now exposes ADDRESSOVERRIDE column from
--   LOCATIONDETAILS_PER.OVERRIDE (COALESCE to 0 when NULL).
--   The RISKNUMBER column is also fixed (ATP-9746 Issue 3):
--   now reads source RISKNUMBER instead of ROW_NUMBER() to
--   preserve the original location ordering.
--
-- SAFE_MODE: Run manually against PolicyConversion DB.
-- After applying, re-run seq 3 via DYNAMIC_XML_V1 and
-- re-run final SPs.
-- ============================================================


-- Step 1: Preview — confirm hardcoded value exists
SELECT
    SequenceID,
    ScriptName,
    CHARINDEX('<AddressOverride>1</AddressOverride>',      ConversionScript) AS HARDCODED_POS,
    CHARINDEX('{ADDRESSOVERRIDE}',                         ConversionScript) AS TOKEN_POS
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 3
  AND IsActive   = 1;
-- Expected: HARDCODED_POS > 0, TOKEN_POS = 0


-- Step 2: Apply fix
UPDATE dbo.PP_ConversionConfig
SET    ConversionScript = REPLACE(
           ConversionScript,
           '<AddressOverride>1</AddressOverride>',
           '<AddressOverride>{ADDRESSOVERRIDE}</AddressOverride>'
       )
WHERE  SequenceID = 3
  AND  IsActive   = 1;


-- Step 3: Verify fix
SELECT
    SequenceID,
    ScriptName,
    CASE
        WHEN CHARINDEX('<AddressOverride>1</AddressOverride>', ConversionScript) > 0
             THEN 'FAIL — hardcoded 1 still present'
        WHEN CHARINDEX('{ADDRESSOVERRIDE}', ConversionScript) > 0
             THEN 'OK — {ADDRESSOVERRIDE} token in place'
        ELSE 'CHECK — neither found'
    END AS CHECK_STATUS
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 3
  AND IsActive   = 1;
-- Expected: CHECK_STATUS = 'OK — {ADDRESSOVERRIDE} token in place'
