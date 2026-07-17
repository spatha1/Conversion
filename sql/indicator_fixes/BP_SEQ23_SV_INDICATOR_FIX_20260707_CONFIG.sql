-- ============================================================
-- SEQ 23 BP_LINE_SV Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 23  (ScriptName = 'BP_LINE_SV')
--
-- 4 hardcoded in template order: SVLIA_SD, SVSTD_SD, SVTPO_SD, SVSTD_ST.
-- Uses EXISTING view columns COM_INDICATOR / TPO_INDICATOR
-- (PROTECTIONTYPE-based, already built in LINE_SV_PAYLOAD but never wired).
-- CONFIG-ONLY fix: no Snowflake view change required.
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 4)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV';

-- STEP 1: replace occurrence 1 (SVLIA_SD Comprehensive Liability)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{COM_INDICATOR}</Indicator>')
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- STEP 2: replace occurrence 2 (SVSTD_SD Comprehensive Property)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{COM_INDICATOR}</Indicator>')
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- STEP 3: replace occurrence 3 (SVTPO_SD Third Party Only)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{TPO_INDICATOR}</Indicator>')
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- STEP 4: replace occurrence 4 (SVSTD_ST Storm)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{COM_INDICATOR}</Indicator>')
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV';
