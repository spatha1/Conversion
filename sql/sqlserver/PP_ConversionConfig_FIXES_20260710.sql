-- ============================================================
-- PP_ConversionConfig_FIXES_20260710.sql
--
-- Database : the Azure SQL Server host reached via middleware.sqlserver_client.get_azure_connection()
--            — this is the TRUE live ETL config. Do not confuse with the default
--            get_connection()/fetch_etl_config() host, which is a different, non-live database
--            (see memory: feedback_verify_live_not_repo.md, 2026-07-10 addendum).
-- Table    : [dbo].[PP_ConversionConfig]
-- Date     : 2026-07-10 (revised same day after re-verifying against the true live host)
--
-- REVISION NOTE: this file originally batched 7 gaps. Re-checking against the correct Azure
-- host (not the host fetch_etl_config() was silently using) found 5 of the 7 ALREADY APPLIED
-- live: G-13, G-22, G-28, G-29, G-31. Only G-25 and G-32 remain open. Removed the 5 stale
-- UPDATEs entirely rather than leave misleading "BUG PRESENT" comments in a file meant to be run.
--
-- FIX 1 — G-25 (SeqID 7 and 13, ConversionConfigId 7 and 13): ClassCode HH/HBC is not a valid
--         APRA/Business code for Building or ContentsAndStocks — manuscript's own
--         BusinessAndAPRAClassCode lookup table gives FISR/BSP for both (cross-validated against
--         Motor's already-correct DMV/DMV entry in the same table). CONFIRMED STILL OPEN.
-- FIX 2 — G-32 (SeqID 13, ConversionConfigId 13): HomeContentsTotal/SpecifiedContentsTotal are
--         readOnly DCT output fields; 9100/622221 are leftover test values, not real data.
--         CONFIRMED STILL OPEN.
--
-- ALREADY LIVE, NOT INCLUDED HERE (verified 2026-07-10 against the true Azure host):
--   G-13 (RedbookCode)         — ConversionConfigId 17 already has {MVRBVEHICLEKEY}
--   G-22 (HB Indicator)        — ConversionConfigId 7  already has {HB_INDICATOR}
--   G-28 ({clauses} token)     — ConversionConfigId 13 already has {HC_CLAUSE}
--   G-29 (HC Indicator)        — ConversionConfigId 13 already has {HC_INDICATOR}
--   G-31 (HomeContentsLimits)  — ConversionConfigId 13 already has {ANYITEMSEXCEEDVALUE}
--
-- NOT INCLUDED: G-30 (FloodDamage hardcode) — confirmed still hardcoded 'Taken' on the true live
-- host, still blocked on the same Snowflake view prerequisite (PER_HOME_BUILDING_PAYLOAD does not
-- expose FLOODDAMAGE). See PER_HOME_BUILDING_PAYLOAD_ADD_FLOODDAMAGE.sql — apply that first,
-- confirm the column is live, THEN run the commented-out block at the bottom of this file.
--
-- APPLY ORDER:
--   Step 1 — Run the BEFORE selects to confirm current state
--   Step 2 — Run Fix 1 and Fix 2 UPDATEs
--   Step 3 — Run the AFTER selects to verify
--   Step 4 — Re-run seqs 7 and 13 via the orchestrator or Aggne ETL
-- ============================================================

USE [Capricorn-Dev-SwiftConversion];
GO


-- ════════════════════════════════════════════════════════════
-- BEFORE: Verify current state (run first, expect BUG markers)
-- ════════════════════════════════════════════════════════════

SELECT ConversionConfigId, SequenceID, ScriptName, LEN(ConversionScript) AS LenBefore,
    CASE WHEN ConversionScript LIKE '%<APRA>HH</APRA>%' THEN 'G-25 BUG PRESENT' ELSE 'G-25 already clean' END AS G25_HB_Status
FROM [dbo].[PP_ConversionConfig] WHERE ConversionConfigId = 7;

SELECT ConversionConfigId, SequenceID, ScriptName, LEN(ConversionScript) AS LenBefore,
    CASE WHEN ConversionScript LIKE '%<APRA>HH</APRA>%' THEN 'G-25 BUG PRESENT' ELSE 'G-25 already clean' END AS G25_HC_Status,
    CASE WHEN ConversionScript LIKE '%<HomeContentsTotal>9100</HomeContentsTotal>%' THEN 'G-32 BUG PRESENT' ELSE 'G-32 already clean' END AS G32_Status
FROM [dbo].[PP_ConversionConfig] WHERE ConversionConfigId = 13;
GO


-- ════════════════════════════════════════════════════════════
-- FIX 1 (G-25): ClassCode HH/HBC -> FISR/BSP — seq 7 (HB) AND seq 13 (HC)
-- ════════════════════════════════════════════════════════════
UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(REPLACE(ConversionScript,
           '<APRA>HH</APRA>', '<APRA>FISR</APRA>'),
           '<Business>HBC</Business>', '<Business>BSP</Business>')
WHERE  ConversionConfigId = 7
  AND  SequenceID         = 7
  AND  ScriptName         = 'RISK_Building_HB'
  AND  ConversionScript LIKE '%<APRA>HH</APRA>%';   -- no-op if already fixed
-- Expected: 1 row affected

UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(REPLACE(ConversionScript,
           '<APRA>HH</APRA>', '<APRA>FISR</APRA>'),
           '<Business>HBC</Business>', '<Business>BSP</Business>')
WHERE  ConversionConfigId = 13
  AND  SequenceID         = 13
  AND  ScriptName         = 'RISK_Building_HC'
  AND  ConversionScript LIKE '%<APRA>HH</APRA>%';   -- no-op if already fixed
-- Expected: 1 row affected
GO


-- ════════════════════════════════════════════════════════════
-- FIX 2 (G-32): HomeContentsTotal / SpecifiedContentsTotal — seq 13 / RISK_Building_HC
-- ════════════════════════════════════════════════════════════
UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(REPLACE(ConversionScript,
           '<HomeContentsTotal>9100</HomeContentsTotal>', '<HomeContentsTotal></HomeContentsTotal>'),
           '<SpecifiedContentsTotal>622221</SpecifiedContentsTotal>', '<SpecifiedContentsTotal></SpecifiedContentsTotal>')
WHERE  ConversionConfigId = 13
  AND  SequenceID         = 13
  AND  ScriptName         = 'RISK_Building_HC'
  AND  ConversionScript LIKE '%<HomeContentsTotal>9100</HomeContentsTotal>%';   -- no-op if already fixed
-- Expected: 1 row affected
GO


-- ════════════════════════════════════════════════════════════
-- AFTER: Verify both fixes applied correctly
-- ════════════════════════════════════════════════════════════

SELECT ConversionConfigId, SequenceID, ScriptName, LEN(ConversionScript) AS LenAfter,
    CASE WHEN ConversionScript LIKE '%<APRA>FISR</APRA>%' AND ConversionScript LIKE '%<Business>BSP</Business>%' THEN 'PASS — G-25 (HB) corrected' ELSE 'FAIL — G-25 (HB) still HH/HBC' END AS G25_HB_Result
FROM [dbo].[PP_ConversionConfig] WHERE ConversionConfigId = 7;

SELECT ConversionConfigId, SequenceID, ScriptName, LEN(ConversionScript) AS LenAfter,
    CASE WHEN ConversionScript LIKE '%<APRA>FISR</APRA>%' AND ConversionScript LIKE '%<Business>BSP</Business>%' THEN 'PASS — G-25 (HC) corrected' ELSE 'FAIL — G-25 (HC) still HH/HBC' END AS G25_HC_Result,
    CASE WHEN ConversionScript LIKE '%<HomeContentsTotal>9100%' THEN 'FAIL — G-32 still 9100' ELSE 'PASS — G-32 totals blanked' END AS G32_Result
FROM [dbo].[PP_ConversionConfig] WHERE ConversionConfigId = 13;
GO


-- ════════════════════════════════════════════════════════════
-- NOT RUN — G-30 (FloodDamage), blocked on a prerequisite Snowflake view fix.
-- Apply PER_HOME_BUILDING_PAYLOAD_ADD_FLOODDAMAGE.sql first, confirm
-- SELECT FLOODDAMAGE FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD LIMIT 1; returns a value,
-- THEN uncomment and run:
-- ════════════════════════════════════════════════════════════
-- UPDATE [dbo].[PP_ConversionConfig]
-- SET    ConversionScript = REPLACE(ConversionScript, '<FloodDamage>Taken</FloodDamage>', '<FloodDamage>{FLOODDAMAGE}</FloodDamage>')
-- WHERE  ConversionConfigId = 13
--   AND  SequenceID         = 13
--   AND  ScriptName         = 'RISK_Building_HC'
--   AND  ConversionScript LIKE '%<FloodDamage>Taken</FloodDamage>%';
-- -- Expected: 1 row affected
-- GO
