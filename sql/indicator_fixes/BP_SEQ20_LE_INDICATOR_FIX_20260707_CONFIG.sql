-- ============================================================
-- SEQ 20 BP_LINE_LE Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 20  (ScriptName = 'BP_LINE_LE')
--
-- 1 hardcoded (line-level). Uses EXISTING view column
-- LEGALEXPENSES_IND (already used by the LESTD_SD block).
-- CONFIG-ONLY fix: no Snowflake view change required.
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 1)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 20 AND ScriptName = 'BP_LINE_LE';

-- UPDATE: all hardcoded indicators get the same token
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{LEGALEXPENSES_IND}</Indicator>')
WHERE SequenceID = 20 AND ScriptName = 'BP_LINE_LE'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 20 AND ScriptName = 'BP_LINE_LE';
