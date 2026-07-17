-- ============================================================
-- ⚠️ RETRACTED 2026-07-17, DO NOT RUN — the bug this "fixes" does not actually exist in live
-- output. This file patches PP_ConversionConfig (SQL Server), but per feedback_sp_only_source_of
-- _truth (this project's established rule), PP_ConversionConfig is a stale, disconnected copy —
-- the real live source of truth is the Snowflake PP_CONVERSION_RUN SP body, which was checked
-- directly and ALREADY has <State>{STATE}</State> (not hardcoded). Confirmed against real
-- generated XML for real NZ policies (P00010046, P00032991, P00036201): 16 of 17 <State> tags
-- already correctly show "NZ". State is not broken in DEV output today. Kept only for the record
-- of what was investigated — the analysis of VehicleInput.State having no manuscript validation
-- (see below) is still correct and worth keeping, just not the "fix" itself.
-- ============================================================
--
-- PP_ConversionConfig_FIX_Seq18_State_NZ_20260717.sql
--
-- Database : the TRUE live Azure SQL Server host reached via
--            middleware.sqlserver_client.get_azure_connection() — NOT the default
--            fetch_etl_config()/get_connection() host (see PP_ConversionConfig_FIXES_20260710.sql
--            header note; both hosts happened to agree for this row, re-verified 2026-07-17
--            directly against get_azure_connection() before drafting this fix).
-- Table    : [dbo].[PP_ConversionConfig]
-- Row      : ConversionConfigId = 17 (SequenceID 18, RISK_Building_PM / Motor)
--
-- ROOT CAUSE: the seq 18 XML template has <State>NSW</State> hardcoded as literal text — not a
-- token, no substitution ever happens. This was previously assumed to be a DCT platform
-- limitation ("DCT's State field only accepts the 8 AU states, no NZ option") — that assumption
-- was WRONG, confirmed by direct manuscript read: VehicleInput.State
-- (Carrier_Package_Data_CW_1_0_0_0.xml:11466) has NO <options> list and NO validation at all —
-- it's a plain type="string" field DCT will accept any value for. The 8-state list that led to
-- the wrong conclusion belongs to a completely different object (a rating/excess lookup table,
-- "VehicleStandardExcess", used to calculate an excess amount — not a field constraint).
--
-- The fix is also unblocked on the source-data side: AGGNE.DEV.PER_COM_PAYLOAD already has a
-- correct, populated STATE column (confirmed live 2026-07-17): VIC 959, WA 674, NSW 578, NZ 467,
-- QLD 299, SA 244, TAS 59, NT 14, ACT 4 — real values including "NZ" literal for New Zealand
-- policies, computed correctly at the Pure-to-Write SP level
-- (CASE WHEN Country='New Zealand' THEN 'NZ' ELSE RLState END) — it was simply never wired into
-- this one template token. No client input needed; this is purely a config fix.
--
-- APPLY ORDER:
--   Step 1 — Run the BEFORE select to confirm current state
--   Step 2 — Run the UPDATE
--   Step 3 — Run the AFTER select to verify
--   Step 4 — Re-run seq 18 (or the full PP_CONVERSION_RUN) so the change takes effect in the
--            generated XML
-- ============================================================

USE [Capricorn-Dev-SwiftConversion];
GO

-- ════════════════════════════════════════════════════════════
-- BEFORE: verify current state (expect BUG PRESENT)
-- ════════════════════════════════════════════════════════════

SELECT ConversionConfigId, SequenceID, ScriptName, LEN(ConversionScript) AS LenBefore,
    CASE WHEN ConversionScript LIKE '%<State>NSW</State>%' THEN 'BUG PRESENT' ELSE 'already clean' END AS StateStatus
FROM [dbo].[PP_ConversionConfig]
WHERE ConversionConfigId = 17;
GO

-- ════════════════════════════════════════════════════════════
-- FIX: replace the hardcoded literal with the {STATE} token
-- ════════════════════════════════════════════════════════════

UPDATE [dbo].[PP_ConversionConfig]
SET ConversionScript = REPLACE(ConversionScript, '<State>NSW</State>', '<State>{STATE}</State>')
WHERE ConversionConfigId = 17
  AND ConversionScript LIKE '%<State>NSW</State>%';
GO

-- ════════════════════════════════════════════════════════════
-- AFTER: verify the fix applied
-- ════════════════════════════════════════════════════════════

SELECT ConversionConfigId, SequenceID, ScriptName, LEN(ConversionScript) AS LenAfter,
    CASE WHEN ConversionScript LIKE '%<State>{STATE}%' THEN 'FIXED -- token present'
         WHEN ConversionScript LIKE '%<State>NSW</State>%' THEN 'STILL BROKEN'
         ELSE 'UNEXPECTED -- inspect manually' END AS StateStatus
FROM [dbo].[PP_ConversionConfig]
WHERE ConversionConfigId = 17;
GO

-- ════════════════════════════════════════════════════════════
-- NEXT STEP (Snowflake, after this SQL Server change is applied):
--   CALL AGGNE.DEV.PP_CONVERSION_RUN_REGENERATED_FROM_CONFIG.sql pattern --
--   the orchestrator's embedded copy of the seq18 template needs to be regenerated fresh from
--   this config (same two-source-drift step seen with G-47/ATP-10842 earlier this session),
--   otherwise this fix will be live in SQL Server but have zero effect on real output.
--   Then: CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE);
-- ════════════════════════════════════════════════════════════
