-- ============================================================
-- SEQ 14 BP_LINE_PF Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 14  (ScriptName = 'BP_LINE_PF')
--
-- 2 hardcoded (line-level + PFSTD_SD), both tied to
-- {PROFESSIONALPROTECTIONLIMIT}. Uses NEW view column
-- PROFESSIONALPROTECTIONLIMIT_INDICATOR.
-- DEPLOY VIEW FIRST: BP_SEQ14_PF_INDICATOR_FIX_20260707_SNOWFLAKE.sql
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 2)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 14 AND ScriptName = 'BP_LINE_PF';

-- UPDATE: all hardcoded indicators get the same token
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{PROFESSIONALPROTECTIONLIMIT_INDICATOR}</Indicator>')
WHERE SequenceID = 14 AND ScriptName = 'BP_LINE_PF'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 14 AND ScriptName = 'BP_LINE_PF';
