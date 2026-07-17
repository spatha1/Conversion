-- ══════════════════════════════════════════════════════════════════════════
-- PP_DEPLOY_INDICATOR_FIX_20260701_SQLSERVER.sql
--
-- Target  : SQL Server — PolicyConversion database (dbo.PP_ConversionConfig)
-- Run in  : SQL Server Management Studio against PolicyConversion DB
-- Applies : Both DEV and UAT output flows (single shared ConversionConfig)
--
-- Fix: Update seq 7 and seq 13 ConversionScript templates to replace the
--      hardcoded <Indicator>1</Indicator> with dynamic tokens so that
--      building/contents coverage checkboxes in DCT only tick when the
--      policy actually has that coverage type.
--
-- Apply this script BEFORE running the Snowflake view deploy
-- (PP_DEPLOY_INDICATOR_FIX_20260701_SNOWFLAKE.sql) and BEFORE triggering
-- the Aggne batch — the Snowflake SP reads these templates at runtime.
-- ══════════════════════════════════════════════════════════════════════════


-- ── Pre-deploy check: confirm current state of seq 7 and seq 13 ──────────
-- Expected: ConversionScript contains hardcoded <Indicator>1</Indicator>
SELECT SequenceID, ScriptName,
       CASE WHEN ConversionScript LIKE '%<Indicator>1</Indicator>%'
            THEN 'CONTAINS HARDCODED INDICATOR — UPDATE NEEDED'
            ELSE 'No hardcoded indicator found — already patched or not present'
       END AS PreDeployStatus
FROM dbo.PP_ConversionConfig
WHERE SequenceID IN (7, 13)
  AND IsActive = 1;


-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 1 — Seq 7: RISK_Building_HB
-- v1 (old):  <Indicator>1</Indicator>   — hardcoded, caused all HB
--             checkboxes to appear ticked even for HC-only policies
-- v2 (new):  <Indicator>{HB_INDICATOR}</Indicator>
--             Token resolved by DYNAMIC_XML_V1 from PER_HOME_BUILDING_PAYLOAD
--             HB_INDICATOR = 1 when policy exists in HB_01, else 0
-- ══════════════════════════════════════════════════════════════════════════
UPDATE dbo.PP_ConversionConfig
SET ConversionScript = REPLACE(
    ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{HB_INDICATOR}</Indicator>'
)
WHERE SequenceID = 7
  AND IsActive   = 1
  AND ConversionScript LIKE '%<Indicator>1</Indicator>%';

-- Verify seq 7 update
SELECT SequenceID, ScriptName,
       CASE WHEN ConversionScript LIKE '%{HB_INDICATOR}%' THEN 'FIXED — {HB_INDICATOR} present'
            ELSE 'NOT UPDATED — check WHERE clause'
       END AS Seq7Status
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 7
  AND IsActive   = 1;


-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 2 — Seq 13: RISK_Building_HC
-- v1 (old):  <Indicator>1</Indicator>   — hardcoded, caused all HC
--             checkboxes to appear ticked even for HB-only policies
-- v2 (new):  <Indicator>{HC_INDICATOR}</Indicator>
--             Token resolved by DYNAMIC_XML_V1 from PER_HOME_BUILDING_PAYLOAD
--             HC_INDICATOR = 1 when policy exists in HC_02, else 0
-- ══════════════════════════════════════════════════════════════════════════
UPDATE dbo.PP_ConversionConfig
SET ConversionScript = REPLACE(
    ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{HC_INDICATOR}</Indicator>'
)
WHERE SequenceID = 13
  AND IsActive   = 1
  AND ConversionScript LIKE '%<Indicator>1</Indicator>%';

-- Verify seq 13 update
SELECT SequenceID, ScriptName,
       CASE WHEN ConversionScript LIKE '%{HC_INDICATOR}%' THEN 'FIXED — {HC_INDICATOR} present'
            ELSE 'NOT UPDATED — check WHERE clause'
       END AS Seq13Status
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 13
  AND IsActive   = 1;


-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 3 — Post-deploy summary check
-- Both sequences should show FIXED status after the updates above.
-- Seq 18 (RISK_Building_PM / motor) is intentionally NOT updated —
-- PER_COM_PAYLOAD is INNER JOINed on PM_03 so only genuine motor policies
-- produce rows; hardcoded <Indicator>1</Indicator> is correct for seq 18.
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    SequenceID,
    ScriptName,
    CASE
        WHEN SequenceID = 7  AND ConversionScript LIKE '%{HB_INDICATOR}%'
             THEN 'OK — HB_INDICATOR token present'
        WHEN SequenceID = 13 AND ConversionScript LIKE '%{HC_INDICATOR}%'
             THEN 'OK — HC_INDICATOR token present'
        WHEN ConversionScript LIKE '%<Indicator>1</Indicator>%'
             THEN 'WARNING — hardcoded indicator still present'
        ELSE 'CHECK — no indicator element found'
    END AS FinalStatus
FROM dbo.PP_ConversionConfig
WHERE SequenceID IN (7, 13)
  AND IsActive = 1
ORDER BY SequenceID;
