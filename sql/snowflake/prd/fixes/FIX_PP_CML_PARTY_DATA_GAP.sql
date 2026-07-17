-- ==========================================================================
-- FIX: PP CML member data gap in AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2
-- Issue : PP policies in policyattach_per whose CML is missing from
--         DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 get empty ABN/Name/Address
--         in the PP attach XML (PA_PER_FINAL_OUTPUT joins to this SCD2 table).
-- Source: AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2_DELTA
-- Target: AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2
-- Date  : 2026-07-09
-- Ref   : P00037360 / PP parallel to FIX_CML_PARTY_DATA_GAP.sql (BP)
--
-- KEY DIFFERENCES FROM BP FIX:
--   BP   → target = AGGNE.DEV.DIM_PARTY_CML_CSL_NEW (column name fixes needed)
--   PP   → target = AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2
--            • All column names are IDENTICAL to delta (no renaming)
--            • PARTY_DIM_ID is AUTOINCREMENT — excluded from INSERT
--            • IS_CURRENT / EFFECTIVE_FROM / EFFECTIVE_TO set explicitly for SCD2
--   PP delta queue = AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS
--                   (not POLICYATTACH_TO_PROCESS)
--
-- DEDICATED SYNC SP (PREFERRED FOR FULL REFRESH):
--   CALL AGGNE.PRD.SP_SYNC_PARTY_SCD2_FROM_DELTA_MERGE();
--   This MERGES the entire delta into SCD2 (expire changed rows + insert new).
--   WARNING: it also marks SCD2 rows as inactive if they are absent from delta.
--   Use the TARGETED INSERT in Step 1 below when you only want to add missing
--   CMLs without touching existing rows.
--
-- EXECUTION ORDER:
--   Step 0 — Validation queries (SELECT only, safe to run any time)
--   Step 1 — Targeted INSERT of missing CMLs only (safe, no updates to existing)
--   Step 2 — Queue impacted PP policies for re-attach
-- ==========================================================================


-- ==========================================================================
-- STEP 0A: How many distinct CMLs are missing from SCD2?
-- ==========================================================================
SELECT COUNT(DISTINCT pb.CMLNUMBER) AS missing_cml_count
FROM AGGNE.PRD.policyattach_per pb
WHERE NOT EXISTS (
    SELECT 1
    FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 s
    WHERE TRIM(s.CMLNUMBER) = TRIM(pb.CMLNUMBER)
      AND s.IS_CURRENT = TRUE
);


-- ==========================================================================
-- STEP 0B: How many of those are covered by the delta table?
-- ==========================================================================
SELECT COUNT(DISTINCT pb.CMLNUMBER) AS will_be_fixed
FROM AGGNE.PRD.policyattach_per pb
WHERE NOT EXISTS (
    SELECT 1
    FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 s
    WHERE TRIM(s.CMLNUMBER) = TRIM(pb.CMLNUMBER)
      AND s.IS_CURRENT = TRUE
)
AND EXISTS (
    SELECT 1
    FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2_DELTA d
    WHERE TRIM(d.CMLNUMBER) = TRIM(pb.CMLNUMBER)
    AND d.ACTIVE_FLAG = TRUE
);


-- ==========================================================================
-- STEP 0C: How many distinct PP policies will be queued?
-- ==========================================================================
SELECT COUNT(DISTINCT pb.PUREPOLICYNUMBER) AS pp_policies_to_requeue
FROM AGGNE.PRD.policyattach_per pb
WHERE NOT EXISTS (
    SELECT 1
    FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 s
    WHERE TRIM(s.CMLNUMBER) = TRIM(pb.CMLNUMBER)
      AND s.IS_CURRENT = TRUE
)
AND EXISTS (
    SELECT 1
    FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2_DELTA d
    WHERE TRIM(d.CMLNUMBER) = TRIM(pb.CMLNUMBER)
    AND d.ACTIVE_FLAG = TRUE
);


-- ==========================================================================
-- STEP 1: Targeted INSERT — missing CMLs from delta → SCD2
-- --------------------------------------------------------------------------
-- Inserts one IS_CURRENT=TRUE row per missing CML, taking latest EFFECTIVE_FROM
-- from delta where ACTIVE_FLAG=TRUE. Does NOT touch existing SCD2 rows.
-- PARTY_DIM_ID auto-assigned by Snowflake sequence.
-- ==========================================================================
INSERT INTO AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 (
    -- PARTY_DIM_ID omitted — autoincrement
    BK_CMLNUMBER,
    MEMBER_TA_NUMBER,
    CSL_LEGAL_ENTITY,
    CML_RISK_ACCOUNT_MANAGER,
    CSL_AREA_MANAGER,
    CSL_ZONE,
    CSL_REGION,
    CSL_NUMBER,
    CML_LEGAL_ENTITY,
    CSL_MEMBER_STATUS,
    ABN_NZBN,
    STOP_CREDIT,
    STOP_CREDIT_REASON,
    CSL_TENURE,
    CSL_MONTHLY_SPEND,
    STANDARD_INDUSTRY_CODE,
    STANDARD_INDUSTRY_CODE_DESCRIPTION,
    CSL_CREDIT_LIMIT,
    CSL_CREDIT_RISK,
    CSL_CREDIT_USAGE,
    PROBABILITY_OF_DEFAULT,
    TA_PAYMENT_METHOD,
    STREET,
    SUBURB,
    STATE,
    POSTCODE,
    CONTACT_NAME,
    PHONE,
    EMAIL,
    SITE_COUNTRY,
    MESSAGE,
    CMLNUMBER,
    COUNTRY,
    CMLLEGALENTITY,
    CMLTRADINGNAME,
    MAINCONTACT,
    CORRESPONDENCELINE1,
    CORRESPONDENCELINE2,
    CORRESPONDENCELINE3,
    CORRESPONDENCELINE4,
    CORRESPONDENCEPOSTCODE,
    SITE_STREET,
    SITE_SUBURB,
    SITE_STATE,
    SITE_POSTCODE,
    CSLNUMBER,
    PRIMARY_PHONE,
    PRIMARY_PHONE_TYPE,
    PRIMARY_EMAIL,
    PRIMARY_EMAIL_TYPE,
    PHONE_COUNT,
    EMAIL_COUNT,
    SECONDARYCONTACT_COUNT,
    SCONDARYCONTACT,
    SCONDARYCONTACTKEY,
    OTHERPHONE,
    OTHEREMAIL,
    SECONDARYCONTACT_XMLDATA,
    EMAIL_XMLDATA,
    PHONE_XMLDATA,
    PAID2DATE,
    MEM_REF,
    EFFECTIVE_DATE,
    AMOUNT,
    HASH_DIFF,
    EFFECTIVE_FROM,
    EFFECTIVE_TO,
    IS_CURRENT,
    ACTIVE_FLAG
)
WITH LATEST_DELTA AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY CMLNUMBER
            ORDER BY EFFECTIVE_FROM DESC
        ) AS RN
    FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2_DELTA
    WHERE ACTIVE_FLAG = TRUE
)
SELECT
    BK_CMLNUMBER,
    MEMBER_TA_NUMBER,
    CSL_LEGAL_ENTITY,
    CML_RISK_ACCOUNT_MANAGER,
    CSL_AREA_MANAGER,
    CSL_ZONE,
    CSL_REGION,
    CSL_NUMBER,
    CML_LEGAL_ENTITY,
    CSL_MEMBER_STATUS,
    ABN_NZBN,
    STOP_CREDIT,
    STOP_CREDIT_REASON,
    CSL_TENURE,
    CSL_MONTHLY_SPEND,
    STANDARD_INDUSTRY_CODE,
    STANDARD_INDUSTRY_CODE_DESCRIPTION,
    CSL_CREDIT_LIMIT,
    CSL_CREDIT_RISK,
    CSL_CREDIT_USAGE,
    PROBABILITY_OF_DEFAULT,
    TA_PAYMENT_METHOD,
    STREET,
    SUBURB,
    STATE,
    POSTCODE,
    CONTACT_NAME,
    PHONE,
    EMAIL,
    SITE_COUNTRY,
    MESSAGE,
    CMLNUMBER,
    COUNTRY,
    CMLLEGALENTITY,
    CMLTRADINGNAME,
    MAINCONTACT,
    CORRESPONDENCELINE1,
    CORRESPONDENCELINE2,
    CORRESPONDENCELINE3,
    CORRESPONDENCELINE4,
    CORRESPONDENCEPOSTCODE,
    SITE_STREET,
    SITE_SUBURB,
    SITE_STATE,
    SITE_POSTCODE,
    CSLNUMBER,
    PRIMARY_PHONE,
    PRIMARY_PHONE_TYPE,
    PRIMARY_EMAIL,
    PRIMARY_EMAIL_TYPE,
    PHONE_COUNT,
    EMAIL_COUNT,
    SECONDARYCONTACT_COUNT,
    SCONDARYCONTACT,
    SCONDARYCONTACTKEY,
    OTHERPHONE,
    OTHEREMAIL,
    SECONDARYCONTACT_XMLDATA,
    EMAIL_XMLDATA,
    PHONE_XMLDATA,
    PAID2DATE,
    MEM_REF,
    EFFECTIVE_DATE,
    AMOUNT,
    HASH_DIFF,
    CURRENT_TIMESTAMP() AS EFFECTIVE_FROM,  -- set to now for traceability
    NULL               AS EFFECTIVE_TO,
    TRUE               AS IS_CURRENT,
    ACTIVE_FLAG
FROM LATEST_DELTA
WHERE RN = 1
  AND NOT EXISTS (
      SELECT 1
      FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 tgt
      WHERE TRIM(tgt.CMLNUMBER) = TRIM(LATEST_DELTA.CMLNUMBER)
        AND tgt.IS_CURRENT = TRUE
  );


-- ==========================================================================
-- STEP 1 VERIFY: Confirm the INSERT worked (spot-check CML00034653 if PP)
-- ==========================================================================
SELECT CMLNUMBER, CMLTRADINGNAME, ABN_NZBN, CSL_MEMBER_STATUS, IS_CURRENT, EFFECTIVE_FROM
FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2
WHERE CMLNUMBER = 'CML00034653'
  AND IS_CURRENT = TRUE;
-- Expected: 1 row, ABN_NZBN = 79674193992, CMLTRADINGNAME = JK ADVENTURE CO PTY LTD


-- ==========================================================================
-- STEP 2: Queue impacted PP policies for re-attach
-- --------------------------------------------------------------------------
-- Inserts into PER_POLICYATTACH_TO_PROCESS (PP delta queue).
-- Targets policies whose CML is now present (freshly inserted by Step 1).
-- Run AFTER Step 1 completes.
-- ==========================================================================
INSERT INTO AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
SELECT DISTINCT pb.PUREPOLICYNUMBER
FROM AGGNE.PRD.policyattach_per pb
WHERE
    EXISTS (
        SELECT 1
        FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 s
        WHERE TRIM(s.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND s.IS_CURRENT = TRUE
          AND s.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
    )
    AND NOT EXISTS (
        SELECT 1
        FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS q
        WHERE q.PUREPOLICYNUMBER = pb.PUREPOLICYNUMBER
    );


-- ==========================================================================
-- STEP 2 VERIFY: Confirm PP queue was populated
-- ==========================================================================
SELECT COUNT(*) AS queued_count
FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS;
