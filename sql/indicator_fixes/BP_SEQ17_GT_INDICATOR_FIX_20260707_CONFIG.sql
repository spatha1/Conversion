-- ============================================================
-- SEQ 17 BP_LINE_GT Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 17  (ScriptName = 'BP_LINE_GT')
--
-- 2 hardcoded (GTSTD_SD + line-level). Uses EXISTING view column
-- GOODSINTRANSIT_IND (Pure taken-flag, already in LINE_GT_PAYLOAD).
-- CONFIG-ONLY fix: no Snowflake view change required.
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 2)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 17 AND ScriptName = 'BP_LINE_GT';

-- UPDATE: all hardcoded indicators get the same token
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{GOODSINTRANSIT_IND}</Indicator>')
WHERE SequenceID = 17 AND ScriptName = 'BP_LINE_GT'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 17 AND ScriptName = 'BP_LINE_GT';
