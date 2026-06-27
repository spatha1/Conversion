-- =============================================================================
-- DIAGNOSTIC: US-5977 P00020218 "data was not migrated"
-- Purpose : Identify why policy P00020218 competitor info is missing in DCT.
--           Run each block separately and review results before deploying fixes.
-- =============================================================================

-- STEP 1: Is P00020218 in the BP conversion scope (SAMPLE_CBP)?
-- Expected: 1+ rows. If 0 rows → policy not in conversion scope, data issue.
SELECT PUREPOLICYNUMBER, EXPIRYDATE, EFFECTIVEDATE, EXPIRINGID_P
FROM AGGNE.DEV.SAMPLE_CBP
WHERE TRIM(PUREPOLICYNUMBER) = 'P00020218';

-- STEP 2: Does P00020218 have competitor data in the source table?
-- Expected: 1+ rows with EXPIRYDATE >= 2026-01-01.
-- If EXPIRYDATE < 2026-01-01 → VW_CBP_COMPETITOR_INFORMATION filters it out.
SELECT PUREPOLICYNUMBER, PRIORCARRIER, PRICE, EXPIRYDATE
FROM AGGNE.DEV.CBP_COMPETITOR_INFORMATION
WHERE TRIM(PUREPOLICYNUMBER) = 'P00020218';

-- STEP 3: Does the competitor view expose P00020218?
-- Expected: 1+ rows. If 0 → date filter or missing source row is the cause.
SELECT * FROM AGGNE.DEV.VW_CBP_COMPETITOR_INFORMATION
WHERE TRIM(PUREPOLICYNUMBER) = 'P00020218';

-- STEP 4: Is VW_COMP_INFO_AGG populated for P00020218?
-- Expected: 1+ rows with ITR_TYPE = 'Prior_INFO'.
-- Check LOAD_DATE — if it differs from today the old GETDATE() filter would drop it.
SELECT ID, ITR_TYPE, LOAD_DATE
FROM AGGNE.DEV.VW_COMP_INFO_AGG
WHERE TRIM(ID) = 'P00020218' AND ITR_TYPE = 'Prior_INFO'
ORDER BY LOAD_DATE DESC;

-- STEP 5: Is P00020218 visible in the master output view?
-- Expected: 1 row. If 0 → policy fails VW_SAMPLE_FINAL filter (ANZSIC, BED, etc.)
SELECT LEGACYPOLICYNUMBER, PARTYID, EFFECTIVEDATE, SELECTANZSICLOOKUP, BUSINESSESTABLISHMENTDATE, PRIOR_INFO
FROM AGGNE.DEV.VW_CBP_OUTPUT_CONVERSION
WHERE TRIM(LEGACYPOLICYNUMBER) = 'P00020218';
