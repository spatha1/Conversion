-- ============================================================
-- SEQ 29 BP_LINE_TA Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 29  (ScriptName = 'BP_LINE_TA')
--
-- 2 hardcoded (TASTD_SD + line-level). Uses EXISTING view column
-- TAXAUDIT_IND (Pure taken-flag, already in LINE_TA_PAYLOAD).
-- CONFIG-ONLY fix: no Snowflake view change required.
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 2)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 29 AND ScriptName = 'BP_LINE_TA';

-- UPDATE: all hardcoded indicators get the same token
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{TAXAUDIT_IND}</Indicator>')
WHERE SequenceID = 29 AND ScriptName = 'BP_LINE_TA'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 29 AND ScriptName = 'BP_LINE_TA';
