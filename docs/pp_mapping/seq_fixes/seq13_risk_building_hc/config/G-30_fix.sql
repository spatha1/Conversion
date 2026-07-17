-- ============================================================
-- G-30 fix — FloodDamage hardcoded "Taken" for every HC policy (seq 13, RISK_Building_HC, P2)
-- TABLE: [dbo].[PP_ConversionConfig]  (Azure host reached via middleware.sqlserver_client.
--        get_azure_connection() — NOT get_connection()/fetch_etl_config(), which hits a stale host)
-- ============================================================
--
-- STATUS: prerequisite already done. The view PER_HOME_BUILDING_PAYLOAD now exposes FLOODDAMAGE
-- live-confirmed 2026-07-09: 'Not Taken' = 1,615 rows, 'Taken' = 216 rows (real, non-uniform
-- distribution). Only the config template token swap below remains.
--
-- Live-confirmed on the correct Azure host (2026-07-09): ConversionConfigId=13, SequenceID=13,
-- ScriptName='RISK_Building_HC' still contains the literal hardcode.
--
-- ┌─── FloodDamage token (ConversionConfigId = 13, SequenceID = 13, RISK_Building_HC) ─────
-- │ OLD CODE (current, live):
-- │   <FloodDamage>Taken</FloodDamage>
-- │
-- │ NEW CODE:
-- │   <FloodDamage>{FLOODDAMAGE}</FloodDamage>
-- └───────────────────────────────────────────────────────────────────────────────────────


-- ============================================================
-- PRE-VALIDATION — run BEFORE applying (Azure host)
-- ============================================================
USE [Capricorn-Dev-SwiftConversion];
GO

SELECT ConversionConfigId, SequenceID, ScriptName, LEN(ConversionScript) AS LenBefore,
    CASE WHEN ConversionScript LIKE '%<FloodDamage>Taken</FloodDamage>%'
         THEN 'G-30 BUG PRESENT' ELSE 'G-30 already tokenized' END AS G30_Status
FROM [dbo].[PP_ConversionConfig]
WHERE ConversionConfigId = 13;
GO


-- ============================================================
-- FIX — token swap
-- ============================================================
UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(ConversionScript,
           '<FloodDamage>Taken</FloodDamage>', '<FloodDamage>{FLOODDAMAGE}</FloodDamage>')
WHERE  ConversionConfigId = 13
  AND  SequenceID         = 13
  AND  ScriptName         = 'RISK_Building_HC'
  AND  ConversionScript LIKE '%<FloodDamage>Taken</FloodDamage>%';   -- no-op if already fixed
-- Expected: 1 row affected
GO


-- ============================================================
-- POST-VALIDATION — run AFTER applying + after PP_CONVERSION_RUN is regenerated from config and
-- seq 13 is re-run
-- ============================================================

-- 1) Config-level: token present, hardcode gone
SELECT ConversionConfigId, SequenceID, ScriptName, LEN(ConversionScript) AS LenAfter,
    CASE WHEN ConversionScript LIKE '%<FloodDamage>{FLOODDAMAGE}</FloodDamage>%'
         THEN 'PASS — G-30 tokenized' ELSE 'FAIL — still hardcoded/missing' END AS G30_Result
FROM [dbo].[PP_ConversionConfig]
WHERE ConversionConfigId = 13;
GO

-- 2) IMPORTANT: AGGNE.DEV.PP_CONVERSION_RUN has all 18 templates hardcoded in its own procedure
--    body and does NOT read PP_ConversionConfig at call time (see feedback_verify_live_not_repo.md
--    addendum 2). After this UPDATE, PP_CONVERSION_RUN must be regenerated from config before this
--    fix reaches real output — re-run PP_CONVERSION_RUN_REGENERATED_FROM_CONFIG.sql (Snowflake).

-- 3) Snowflake — confirm the real generated payload/XML now carries the true value, not a uniform
--    "Taken" for every policy
-- SELECT FLOODDAMAGE_EMITTED, COUNT(*) FROM (
--   SELECT REGEXP_SUBSTR(PAYLOAD, '<FloodDamage>(.*?)</FloodDamage>', 1, 1, 'e') AS FLOODDAMAGE_EMITTED
--   FROM AGGNE.DEV.PER_HC_TARGET WHERE ITR_TYPE = 'RISK_Building_HC'
-- ) GROUP BY 1 ORDER BY 2 DESC;
-- Target: distribution matches the live view (roughly 1,615 Not Taken / 216 Taken), not 100% Taken
-- ============================================================
