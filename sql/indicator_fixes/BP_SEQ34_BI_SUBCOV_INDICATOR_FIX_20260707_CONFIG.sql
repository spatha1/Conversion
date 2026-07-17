-- ============================================================
-- SEQ 34 BP_Risk_Building_BI_Subcov Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 34  (ScriptName = 'BP_Risk_Building_BI_Subcov')
--
-- 1 hardcoded in generic {TYPE}/{CODE}/{IVALUE} row template.
-- Uses NEW view column INDICATOR (per-branch limit > 0).
-- DEPLOY VIEW FIRST: BP_SEQ34_BI_SUBCOV_INDICATOR_FIX_20260707_SNOWFLAKE.sql
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 1)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 34 AND ScriptName = 'BP_Risk_Building_BI_Subcov';

-- UPDATE: all hardcoded indicators get the same token
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{INDICATOR}</Indicator>')
WHERE SequenceID = 34 AND ScriptName = 'BP_Risk_Building_BI_Subcov'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 34 AND ScriptName = 'BP_Risk_Building_BI_Subcov';
