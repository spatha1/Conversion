-- ============================================================
-- PP SOURCE VIEW DDL COLLECTION — Snowflake
-- Date    : 2026-07-01
-- Purpose : Retrieve the CURRENTLY DEPLOYED definition for every
--           PP ConversionConfig source view.
--           Run each GET_DDL() individually or as a batch.
--           Compare output against repo files to confirm deployed
--           versions match the latest code.
--
-- Run with: USE DATABASE AGGNE; USE SCHEMA DEV;
-- ============================================================

-- ── PP ConversionConfig source views (all sequences) ─────────────────────────

-- Seq 1  : Claim history
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_VW_CLAIM_HISTORY');

-- Seq 2  : Prior/competitor information
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION');

-- Seq 3  : Account / location (address)
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_ACCOUNT_LOC');

-- Seq 4  : Building sub-coverages (BB)
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_BB_SUBCOVERAGES');

-- Seq 5  : HB underwriting adjustments
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_HC_BUILDING_UW');

-- Seq 6  : HB clause rows
SELECT GET_DDL('VIEW', 'AGGNE.DEV.HB_CLAUSE');

-- Seq 7  : HB payload (RISK_Building_HB) — shared with seq 13
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD');

-- Seq 8  : HC exceed-value items
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE');

-- Seq 9  : HC specified contents
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS');

-- Seq 10 : HC building sub-coverages
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_HC_SUBCOVERAGES');

-- Seq 11 : HC clause rows
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_HC_CLAUSE');

-- Seq 12 : HC underwriting adjustments
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_PM_BUILDING_UW');

-- Seq 13 : HC payload (RISK_Building_HC) — same source view as seq 7
-- (already retrieved above)

-- Seq 14 : Building risk final (address + construction + security)
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_RISK_BUILDING_FINAL');

-- Seq 15 : Motor coverages / subcoverages
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_COM_COVERAGES');

-- Seq 16 : Motor clause
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_COM_CLAUSE');

-- Seq 17 : Motor UW
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_PM_BUILDING_UW');

-- Seq 18 : Motor payload (RISK_COM)
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_COM_PAYLOAD');

-- ── Supporting aggregation views ──────────────────────────────────────────────
SELECT GET_DDL('VIEW', 'AGGNE.DEV.PER_BUILDING_FINAL_AGG');

-- ── Summary: all PP source views in one result set ───────────────────────────
-- Useful for a single export / diff against repo
SELECT TABLE_NAME AS VIEW_NAME, VIEW_DEFINITION
FROM   AGGNE.INFORMATION_SCHEMA.VIEWS
WHERE  TABLE_SCHEMA = 'DEV'
  AND  TABLE_NAME IN (
           'PER_VW_CLAIM_HISTORY',
           'PER_VW_CBP_COMPETITOR_INFORMATION',
           'PER_ACCOUNT_LOC',
           'PER_BB_SUBCOVERAGES',
           'PER_HC_BUILDING_UW',
           'HB_CLAUSE',
           'PER_HOME_BUILDING_PAYLOAD',
           'PER_HC_ITEMS_EXCEED_VALUE',
           'PER_HC_SPECIFIEDCONTENTS',
           'PER_HC_SUBCOVERAGES',
           'PER_HC_CLAUSE',
           'PER_PM_BUILDING_UW',
           'PER_RISK_BUILDING_FINAL',
           'PER_COM_COVERAGES',
           'PER_COM_PAYLOAD',
           'PER_BUILDING_FINAL_AGG'
       )
ORDER BY TABLE_NAME;
