-- =============================================================================
-- DEPLOYMENT SCRIPT: US-5977 Fix
-- Date   : 2026-06-26
-- Author : Conversion Team
-- =============================================================================
-- IMPORTANT — Schema rules:
--   VW_CBP_OUTPUT_CONVERSION  →  deploy to AGGNE.UAT  (UAT master view)
--   VW_CLAIM_HISTORY          →  deploy to AGGNE.DEV  (config/source view stays DEV)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- STEP 1: Deploy to AGGNE.UAT
-- Run this block in a Snowflake session with USE SCHEMA AGGNE.UAT
-- -----------------------------------------------------------------------------

-- FIX: T4/T5/T9 date filter changed from CAST(GETDATE() AS DATE) to MAX(LOAD_DATE).
-- Reason: GETDATE() caused claim history, competitor info and account-loc to return
-- NULL on any day ETL4 didn't run. MAX(LOAD_DATE) picks the latest ETL4 load
-- regardless of run date, consistent with DEV_POLICY_SOURCEDATA SP.
-- File: sql/snowflake/1_conversion/BP/views/VW_CBP_OUTPUT_CONVERSION.sql

-- Paste the full contents of VW_CBP_OUTPUT_CONVERSION.sql here and execute
-- within context: USE DATABASE AGGNE; USE SCHEMA UAT;


-- -----------------------------------------------------------------------------
-- STEP 2: Deploy to AGGNE.DEV
-- Run this block in a Snowflake session with USE SCHEMA AGGNE.DEV
-- -----------------------------------------------------------------------------

-- FIX: CAUSE field translation added in VW_CLAIM_HISTORY.
-- Reason: PURE CAUSE values (e.g. 'Motor', 'Customer Property Damage', 'At Fault')
-- do not match DCT Cause dropdown captions, causing DCT to silently ignore the field.
-- PP already had this fix; BP was missed. Any unrecognised value defaults to 'Other'.
-- File: sql/snowflake/1_conversion/BP/views/VW_CLAIM_HISTORY.sql

-- Paste the full contents of VW_CLAIM_HISTORY.sql here and execute
-- within context: USE DATABASE AGGNE; USE SCHEMA DEV;


-- -----------------------------------------------------------------------------
-- STEP 3: Verify after deployment
-- Run against AGGNE.UAT / AGGNE.DEV as appropriate
-- -----------------------------------------------------------------------------

-- Verify competitor info now populates for a known good policy (Scenario 2 test):
-- Expected: PRIOR_INFO column is non-null for policies with competitor data.
SELECT LEGACYPOLICYNUMBER, PRIOR_INFO
FROM AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION
WHERE TRIM(LEGACYPOLICYNUMBER) IN ('P00020218','P00030237','P00012972','P00023250')
  AND PARTYID IS NOT NULL;

-- Verify CAUSE translation in claim history (DEV):
-- Expected: No raw PURE values — all values should match DCT caption list.
SELECT DISTINCT CAUSE FROM AGGNE.DEV.VW_CLAIM_HISTORY
WHERE CAUSE NOT IN ('Fire','Flood','Burglary','Theft','Other',
                    'CustomerPropertyDamage','CustomerInjury','AtFault','NotAtFault');
-- Expected result: 0 rows (all causes mapped correctly)
