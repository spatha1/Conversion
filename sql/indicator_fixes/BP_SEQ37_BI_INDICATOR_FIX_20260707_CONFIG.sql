-- ============================================================
-- SEQ 37 BP_RISK_Building_BI Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 37  (ScriptName = 'BP_RISK_Building_BI')
--
-- 6 hardcoded (BI line + BIGRP_SD/CY/EQ/ST/BF), all with iValue =
-- {ANNUALGROSSPROFIT}. Uses NEW view column ANNUALGROSSPROFIT_INDICATOR.
-- DEPLOY VIEW FIRST: BP_SEQ37_BI_INDICATOR_FIX_20260707_SNOWFLAKE.sql
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 6)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 37 AND ScriptName = 'BP_RISK_Building_BI';

-- UPDATE: all hardcoded indicators get the same token
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{ANNUALGROSSPROFIT_INDICATOR}</Indicator>')
WHERE SequenceID = 37 AND ScriptName = 'BP_RISK_Building_BI'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 37 AND ScriptName = 'BP_RISK_Building_BI';
