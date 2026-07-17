-- ============================================================
-- BP_Risk_Building_BG_Subcov Indicator Fix — ConversionConfig
-- Date   : 2026-07-06
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 38  (ScriptName = 'BP_Risk_Building_BG_Subcov')
--
-- Issue  : Template has <Indicator>1</Indicator> hardcoded.
--          The source view (RISK_BUILDING_BG_COVERAGES) uses a
--          repeating row pattern — one row per sub-coverage — so
--          the hardcoded Indicator fires as 1 even when limit = 0.
--
-- Fix    : Replace the single <Indicator>1</Indicator> with
--          <Indicator>{INDICATOR}</Indicator>.
--          The new INDICATOR column in the source view returns 1
--          when iValue > 0, 0 otherwise (STD_SD always 1).
--
-- Companion: BP_BG_SUBCOV_INDICATOR_FIX_20260706_SNOWFLAKE.sql
-- ============================================================

-- ── PRE-CHECK ────────────────────────────────────────────────
-- Expected before fix: hardcoded_indicator_count = 1, indicator_token = 0
SELECT
    SequenceID,
    ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count,
    CHARINDEX('{INDICATOR}', ConversionScript) AS indicator_token
FROM dbo.ConversionConfig
WHERE SequenceID = 38 AND ScriptName = 'BP_Risk_Building_BG_Subcov';

-- ── UPDATE — Replace hardcoded Indicator with {INDICATOR} token ──
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(
    ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{INDICATOR}</Indicator>'
)
WHERE SequenceID = 38 AND ScriptName = 'BP_Risk_Building_BG_Subcov'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- ── POST-CHECK ───────────────────────────────────────────────
-- Expected after fix: hardcoded_indicator_count = 0, indicator_token > 0
SELECT
    SequenceID,
    ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count,
    CHARINDEX('{INDICATOR}', ConversionScript) AS indicator_token
FROM dbo.ConversionConfig
WHERE SequenceID = 38 AND ScriptName = 'BP_Risk_Building_BG_Subcov';
