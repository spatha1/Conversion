-- ============================================================
-- SEQ 62 BP_CV_Vehicle_SubCov Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 62  (ScriptName = 'BP_CV_Vehicle_SubCov')
--
-- 1 hardcoded in generic {CMTYPE}/{CMCODE} row template.
-- Uses NEW view column INDICATOR (per protection-type branch).
-- DEPLOY VIEW FIRST: BP_SEQ62_CM_SUBCOV_INDICATOR_FIX_20260707_SNOWFLAKE.sql
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 1)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 62 AND ScriptName = 'BP_CV_Vehicle_SubCov';

-- UPDATE: all hardcoded indicators get the same token
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{INDICATOR}</Indicator>')
WHERE SequenceID = 62 AND ScriptName = 'BP_CV_Vehicle_SubCov'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 62 AND ScriptName = 'BP_CV_Vehicle_SubCov';
