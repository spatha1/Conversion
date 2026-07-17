-- ============================================================
-- STEP 8 — Collect quotes, validate data landed in Clarity (bronze)
-- Run on: Snowflake, connection id=13 (Clarity DEV_01 credentials
--         from dbo.Calrity_Connection, account DUCKCREEK-CAPM_DEV01 —
--         confirmed this session, NOT the id=13 UAT01 credential we
--         used earlier by mistake)
-- Type: READ-ONLY
--
-- Proven chain this session:
--   PER_POLICY_MIGRATION_DCT.LEGACYPOLICYNUMBER
--     -> CLARITY_BRONZE.RAW_QUOTE_SUBMISSION.V_QUOTES_EXTRA_DATA
--        (COLUMN_NAME='LegacyPolicyNumber' -> COLUMN_VALUE match)
--     -> POLICY_KEY (format Q||<QuoteID>||1)
--     -> any other COLUMN_NAME on that POLICY_KEY (e.g. InceptionDate)
-- Verified with real data: P00009911, P00010027, etc.
--
-- NOT yet confirmed: vehicle/building-level fields (RoofConstruction,
-- VehicleType, ExcessWaiverForGlass) — expected in
-- V_QUOTES_INSURED_OBJECT_EXTRA_DATA, awaiting view definitions.
-- ============================================================

-- 8a. Did each pilot policy reach DCT at all? (quote exists in bronze)
SELECT
    PP.LEGACYPOLICYNUMBER,
    E.POLICY_KEY,
    SPLIT_PART(E.POLICY_KEY,'||',2) AS QUOTE_ID
FROM AGGNE.DEV.PP_PILOT_POLICIES PP
LEFT JOIN CLARITY_BRONZE.RAW_QUOTE_SUBMISSION.V_QUOTES_EXTRA_DATA E
       ON E.COLUMN_NAME = 'LegacyPolicyNumber'
      AND E.COLUMN_VALUE = PP.LEGACYPOLICYNUMBER
ORDER BY PP.LEGACYPOLICYNUMBER;
-- NULL POLICY_KEY = quote never reached DCT / bronze — investigate
-- via Step 7 first (was it even processed by the Timer Trigger?)

-- 8b. For policies that DID reach DCT: pull all policy-level fields
--     landed for that quote (cross-reference target for Step 9)
SELECT
    PP.LEGACYPOLICYNUMBER,
    E.COLUMN_NAME,
    E.COLUMN_VALUE
FROM AGGNE.DEV.PP_PILOT_POLICIES PP
JOIN CLARITY_BRONZE.RAW_QUOTE_SUBMISSION.V_QUOTES_EXTRA_DATA E0
     ON E0.COLUMN_NAME = 'LegacyPolicyNumber' AND E0.COLUMN_VALUE = PP.LEGACYPOLICYNUMBER
JOIN CLARITY_BRONZE.RAW_QUOTE_SUBMISSION.V_QUOTES_EXTRA_DATA E
     ON E.POLICY_KEY = E0.POLICY_KEY
ORDER BY PP.LEGACYPOLICYNUMBER, E.COLUMN_NAME;
