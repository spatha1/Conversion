-- ============================================================
-- G-BP-67 fix -- SEQ 1 Address2 missing from ACCOUNT_LOC (seq 1, P2, code-only)
-- VERIFIED against live Snowflake (2026-07-09): LOCATION_01 has ADDRESS2, ACCOUNT_LOC doesn't select it.
-- NOT YET APPLIED.
-- ============================================================

-- ---------- ROOT CAUSE ----------
-- AGGNE.DEV.LOCATION_01 (raw Pure staging, 78 columns) has an ADDRESS2 column with real data.
-- AGGNE.DEV.ACCOUNT_LOC (SEQ 1 source view, 11 columns) never selects it -- confirmed via live
-- GET_DDL, 2026-07-09. SEQ 1's ConversionConfig template has <Address2/> as a bare empty tag,
-- no token -- consistent with the view never having produced the column to reference.

-- ---------- VIEW FIX ----------
-- sql/snowflake/1_conversion/BP/views/ACCOUNT_LOC.sql (also live in AGGNE.DEV)
-- Add ADDRESS2 to the column list and both CTEs:
--
--   create or replace view ACCOUNT_LOC(
--       PUREPOLICYNUMBER, LOCATIONANZSICCODE, LEGACYPOLICYNUMBER, RISKNUMBER, STATE,
--       ADDRESS1, ADDRESS2, SUBURB, GNAFPID, POSTCODE, LOC_COUNTRY, LOCATIONADDRESSTAKEN
--   ) as
--   ...
--   cte2 AS (
--       SELECT ..., ADDRESS1, ADDRESS2, SUBURB, ...
--       FROM AGGNE.DEV.location_01
--   )
--   ...
--   SELECT ..., T1.ADDRESS1, T1.ADDRESS2, T1.SUBURB, ...
--   FROM cte2 T1 ...

-- ---------- CONFIG CHANGE REQUIRED ----------
-- YES. dbo.ConversionConfig, SEQ 1 (BP_ACC_LOC), Azure (aggneswiftconversion-dev).
-- Replace the bare empty tag with a token:
--
--   UPDATE dbo.ConversionConfig
--   SET ConversionScript = REPLACE(ConversionScript, '<Address2/>', '<Address2>{ADDRESS2}</Address2>')
--   WHERE SequenceID = 1 AND ScriptName = 'BP_ACC_LOC'
--     AND ConversionScript LIKE '%<Address2/>%';
--
-- (Whitespace-agnostic REPLACE, single occurrence -- safe to re-run.)

-- ---------- Verify before applying ----------
-- SELECT COUNT(*) AS TOTAL,
--   SUM(CASE WHEN COALESCE(TRIM(ADDRESS2),'') = '' THEN 1 ELSE 0 END) AS ADDRESS2_BLANK
-- FROM AGGNE.DEV.LOCATION_01;

-- ---------- Verify after applying ----------
-- SELECT ADDRESS2 FROM AGGNE.DEV.ACCOUNT_LOC WHERE ADDRESS2 IS NOT NULL LIMIT 20;
