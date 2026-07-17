-- ============================================================================
-- New table: AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
--
-- Holds a request/response record for every policy in the existing 46-policy
-- UAT pilot batch (AGGNE.UAT_XML.PP_CONVERSIONINFORMATION), re-submitted to
-- DCT DEV for validation. UAT_QUOTE_NUMBER/UAT_QUOTE_STATUS are carried across
-- as reference columns (what UAT already produced) so DEV and UAT results can
-- be compared side by side; DEV_QUOTE_NUMBER and the extracted premium fields
-- are the new evidence from this run.
--
-- REQUEST_XML/RESPONSE_XML are stored in full so any field can be re-checked
-- later without resubmitting. PARTY_ID_BLANK flags policies affected by the
-- still-open PartyID root-cause item (see Session_Summary_20260716...md,
-- Section 6) -- these are the ones to prioritize for UI recording, since
-- they're the ones most likely to hit the culture=en-NZ Express crash.
--
-- STATUS: DRAFTED, NOT APPLIED. SAFE_MODE -- user must run this.
-- ============================================================================

CREATE TABLE IF NOT EXISTS AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE (
    LEGACY_POLICY_NUMBER         VARCHAR,
    UAT_QUOTE_NUMBER             VARCHAR,
    UAT_QUOTE_STATUS             VARCHAR,
    DEV_QUOTE_NUMBER             VARCHAR,
    PARTY_ID_BLANK                BOOLEAN,
    RISK_TOTAL_PREMIUMS_VEHICLE  NUMBER(18,2),
    RISK_TOTAL_PREMIUMS_PROPERTY NUMBER(18,2),
    TOTAL_PREMIUM                NUMBER(18,2),
    FAILURE_COUNT                NUMBER(5,0),
    HTTP_STATUS                  NUMBER(5,0),
    ERROR_NOTE                   VARCHAR,
    REQUEST_XML                  VARCHAR,
    RESPONSE_XML                 VARCHAR,
    SUBMITTED_AT                 TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
