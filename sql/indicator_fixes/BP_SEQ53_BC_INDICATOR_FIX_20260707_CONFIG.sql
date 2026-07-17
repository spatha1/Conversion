-- ============================================================
-- SEQ 53 BP_RISK_Building_BC Indicator Fix -- ConversionConfig (SQL Server)
-- Date   : 2026-07-07
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 53  (ScriptName = 'BP_RISK_Building_BC')
--
-- 5 hardcoded in template order: BCSTD_BF, BCSTD_CY, BCSTD_EQ, BCSTD_ST
-- (iValue={CONTENTSLIMIT}) then BCHAL_SD (iValue={HAILDAMAGE}).
-- Uses NEW view columns CONTENTSLIMIT_INDICATOR / HAILDAMAGE_INDICATOR
-- (same pattern as existing LND_SD_INDICATOR).
-- DEPLOY VIEW FIRST: BP_SEQ53_BC_INDICATOR_FIX_20260707_SNOWFLAKE.sql
-- ============================================================

-- PRE-CHECK (expected hardcoded_indicator_count = 5)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 53 AND ScriptName = 'BP_RISK_Building_BC';

-- STEP 1: replace occurrence 1 (BCSTD_BF Bushfire)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{CONTENTSLIMIT_INDICATOR}</Indicator>')
WHERE SequenceID = 53 AND ScriptName = 'BP_RISK_Building_BC'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- STEP 2: replace occurrence 2 (BCSTD_CY Cyclone)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{CONTENTSLIMIT_INDICATOR}</Indicator>')
WHERE SequenceID = 53 AND ScriptName = 'BP_RISK_Building_BC'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- STEP 3: replace occurrence 3 (BCSTD_EQ Earthquake)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{CONTENTSLIMIT_INDICATOR}</Indicator>')
WHERE SequenceID = 53 AND ScriptName = 'BP_RISK_Building_BC'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- STEP 4: replace occurrence 4 (BCSTD_ST Storm)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{CONTENTSLIMIT_INDICATOR}</Indicator>')
WHERE SequenceID = 53 AND ScriptName = 'BP_RISK_Building_BC'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- STEP 5: replace occurrence 5 (BCHAL_SD Hail Standard)
UPDATE dbo.ConversionConfig
SET ConversionScript = STUFF(ConversionScript,
    CHARINDEX('<Indicator>1</Indicator>', ConversionScript),
    LEN('<Indicator>1</Indicator>'),
    '<Indicator>{HAILDAMAGE_INDICATOR}</Indicator>')
WHERE SequenceID = 53 AND ScriptName = 'BP_RISK_Building_BC'
  AND CHARINDEX('<Indicator>1</Indicator>', ConversionScript) > 0;

-- POST-CHECK (hardcoded_indicator_count must be 0)
SELECT SequenceID, ScriptName,
    (LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')))
        / LEN('<Indicator>1</Indicator>') AS hardcoded_indicator_count
FROM dbo.ConversionConfig
WHERE SequenceID = 53 AND ScriptName = 'BP_RISK_Building_BC';
