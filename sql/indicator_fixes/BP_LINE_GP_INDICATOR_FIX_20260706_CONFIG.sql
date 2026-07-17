-- ============================================================
-- BP_LINE_GP Indicator Fix — ConversionConfig (SQL Server)
-- Date   : 2026-07-06
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 8  (ScriptName = 'BP_LINE_GP')
--
-- Issue  : GPUNT_SD, GPUNS_SD, GPSPT_SD sub-coverages have
--          <Indicator>1</Indicator> hardcoded while their limit
--          tokens are dynamic. Indicator should be 0 when no
--          coverage is taken (limit = 0 / status = NotTaken).
--
-- Fix    : Replace the 3 hardcoded Indicators with tokens sourced
--          from new columns added to AGGNE.DEV.LINE_GP_PAYLOAD:
--            {UNSPECIFIEDTOOLSLIMIT_INDICATOR}  (1 if limit > 0)
--            {UNSPECIFIEDSTOCKLIMIT_INDICATOR}  (1 if limit > 0)
--            {SPECIFIEDTOOL_INDICATOR}          (1 if Taken)
--
-- Note   : Uses sequential STUFF (whitespace-agnostic).
--          The 3 hardcoded Indicators appear in this fixed order
--          in the XML:  UNT_SD → UNS_SD → GPSPT_SD
--          Each step replaces the first remaining occurrence.
--
-- Companion: BP_LINE_GP_INDICATOR_FIX_20260706_SNOWFLAKE.sql
-- ============================================================

-- ── PRE-CHECK ────────────────────────────────────────────────
-- Count how many hardcoded <Indicator>1</Indicator> remain.
-- Expected BEFORE fix : 3
-- Expected AFTER  fix : 0
SELECT
    SequenceID,
    ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count,
    CHARINDEX('{UNSPECIFIEDTOOLSLIMIT_INDICATOR}', ConversionScript) AS unt_token,
    CHARINDEX('{UNSPECIFIEDSTOCKLIMIT_INDICATOR}', ConversionScript) AS uns_token,
    CHARINDEX('{SPECIFIEDTOOL_INDICATOR}',         ConversionScript) AS spt_token
FROM dbo.ConversionConfig
WHERE SequenceID = 8 AND ScriptName = 'BP_LINE_GP';

-- ── STEP 1 — Replace 1st occurrence → GPUNT_SD ──────────────
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(
    ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{UNSPECIFIEDTOOLSLIMIT_INDICATOR}</Indicator>'
)
WHERE SequenceID = 8 AND ScriptName = 'BP_LINE_GP'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- ── STEP 2 — Replace 2nd occurrence → GPUNS_SD ──────────────
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(
    ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{UNSPECIFIEDSTOCKLIMIT_INDICATOR}</Indicator>'
)
WHERE SequenceID = 8 AND ScriptName = 'BP_LINE_GP'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- ── STEP 3 — Replace 3rd occurrence → GPSPT_SD ──────────────
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(
    ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{SPECIFIEDTOOL_INDICATOR}</Indicator>'
)
WHERE SequenceID = 8 AND ScriptName = 'BP_LINE_GP'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- ── POST-CHECK ───────────────────────────────────────────────
-- hardcoded_indicator_count must be 0; all 3 tokens must be > 0
SELECT
    SequenceID,
    ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count,
    CHARINDEX('{UNSPECIFIEDTOOLSLIMIT_INDICATOR}', ConversionScript) AS unt_token,
    CHARINDEX('{UNSPECIFIEDSTOCKLIMIT_INDICATOR}', ConversionScript) AS uns_token,
    CHARINDEX('{SPECIFIEDTOOL_INDICATOR}',         ConversionScript) AS spt_token
FROM dbo.ConversionConfig
WHERE SequenceID = 8 AND ScriptName = 'BP_LINE_GP';
