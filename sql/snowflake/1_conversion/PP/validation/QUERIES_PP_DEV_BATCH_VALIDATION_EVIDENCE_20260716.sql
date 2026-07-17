-- ============================================================================
-- Query-level evidence against AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
-- (46-policy UAT batch, re-submitted to DCT DEV, 2026-07-16)
--
-- Read-only. Run after INSERT_PP_DEV_BATCH_VALIDATION_EVIDENCE_20260716.sql.
-- ============================================================================

-- 1. Overview: how many submitted cleanly, how many had failures/errors
SELECT
    COUNT(*)                                              AS TOTAL_POLICIES,
    SUM(CASE WHEN ERROR_NOTE IS NULL THEN 1 ELSE 0 END)   AS SUBMITTED_OK,
    SUM(CASE WHEN ERROR_NOTE IS NOT NULL THEN 1 ELSE 0 END) AS SUBMIT_ERRORS,
    SUM(CASE WHEN FAILURE_COUNT > 0 THEN 1 ELSE 0 END)    AS HAD_DCT_FAILURE_STATUS,
    SUM(CASE WHEN PARTY_ID_BLANK THEN 1 ELSE 0 END)       AS BLANK_PARTY_ID_COUNT
FROM AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE;

-- 2. Full policy-by-policy summary (the main evidence table)
SELECT
    LEGACY_POLICY_NUMBER,
    UAT_QUOTE_NUMBER, UAT_QUOTE_STATUS,
    DEV_QUOTE_NUMBER,
    PARTY_ID_BLANK,
    RISK_TOTAL_PREMIUMS_VEHICLE, RISK_TOTAL_PREMIUMS_PROPERTY, TOTAL_PREMIUM,
    FAILURE_COUNT, HTTP_STATUS, ERROR_NOTE
FROM AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
ORDER BY LEGACY_POLICY_NUMBER;

-- 3. Policies to prioritize for UI recording -- blank PartyID (most likely to hit
--    the culture=en-NZ Express crash; confirming these navigate cleanly closes
--    out that open item across the batch, not just the single test case)
SELECT LEGACY_POLICY_NUMBER, DEV_QUOTE_NUMBER, UAT_QUOTE_STATUS
FROM AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
WHERE PARTY_ID_BLANK = TRUE
ORDER BY LEGACY_POLICY_NUMBER;

-- 4. Any policy where DCT returned a failure status anywhere in the response
SELECT LEGACY_POLICY_NUMBER, DEV_QUOTE_NUMBER, FAILURE_COUNT, RESPONSE_XML
FROM AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
WHERE FAILURE_COUNT > 0
ORDER BY LEGACY_POLICY_NUMBER;

-- 5. Zero-premium check -- any Motor risk still computing $0 (the item fixed
--    2026-07-16; this should return 0 rows across the batch)
SELECT LEGACY_POLICY_NUMBER, DEV_QUOTE_NUMBER, RISK_TOTAL_PREMIUMS_VEHICLE
FROM AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
WHERE RISK_TOTAL_PREMIUMS_VEHICLE = 0
   OR RISK_TOTAL_PREMIUMS_VEHICLE IS NULL
ORDER BY LEGACY_POLICY_NUMBER;

-- 6. Pull one policy's full request/response pair (for spot-checking a specific
--    field, e.g. confirming the PersonalMotor/UW Adjustment fixes on a given
--    policy without re-querying PER_POLICY_MIGRATION_DCT)
SELECT REQUEST_XML, RESPONSE_XML
FROM AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
WHERE LEGACY_POLICY_NUMBER = 'P00026339';

-- 7. DEV vs UAT quote status side-by-side (for spotting anything that changed
--    Approve/Refer between the two environments -- shouldn't happen from a
--    conversion-logic change, worth flagging if it does)
SELECT
    LEGACY_POLICY_NUMBER, UAT_QUOTE_STATUS, UAT_QUOTE_NUMBER, DEV_QUOTE_NUMBER
FROM AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
ORDER BY UAT_QUOTE_STATUS, LEGACY_POLICY_NUMBER;
