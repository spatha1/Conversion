-- ==========================================================================
-- FIX: CML member data gap in AGGNE.DEV.DIM_PARTY_CML_CSL_NEW
-- Issue : 8,414 policy-CML combinations in policyattach_bp have no matching
--         row in DIM_PARTY_CML_CSL_NEW, causing empty ABN/Name/Address XML
-- Source: AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2_DELTA
-- Target: AGGNE.DEV.DIM_PARTY_CML_CSL_NEW
-- Date  : 2026-07-09
-- Ref   : P00037360 / ATP-XXXXX
--
-- EXECUTION ORDER:
--   Step 0 — Run validation queries (SELECT only, safe to run any time)
--   Step 1 — Insert missing CMLs into DIM_PARTY_CML_CSL_NEW
--   Step 2 — Queue impacted policies for re-attach
--
-- COLUMN MAPPING NOTE:
--   Delta table has two typo columns:
--     SCONDARYCONTACT   → maps to → SECONDARYCONTACT   (target)
--     SCONDARYCONTACTKEY → maps to → SECONDARYCONTACTKEY (target)
--   Delta-only columns excluded (not present in target):
--     OTHERPHONE, OTHEREMAIL, SECONDARYCONTACT_XMLDATA, EMAIL_XMLDATA, PHONE_XMLDATA
-- ==========================================================================


-- ==========================================================================
-- STEP 0A: How many distinct CMLs are missing from DIM_PARTY_CML_CSL_NEW?
-- ==========================================================================
SELECT COUNT(DISTINCT pb.CMLNUMBER) AS missing_cml_count
FROM AGGNE.PRD.policyattach_bp pb
WHERE NOT EXISTS (
    SELECT 1 FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW dim
    WHERE TRIM(dim.CMLNUMBER) = TRIM(pb.CMLNUMBER)
);
-- Expected: a large number (in the thousands).
-- Any CML in this gap has empty ABN/Name/Address in its attach XML.


-- ==========================================================================
-- STEP 0B: How many of those missing CMLs exist in the delta table?
--          (only these will be fixed by Step 1)
-- ==========================================================================
SELECT COUNT(DISTINCT pb.CMLNUMBER) AS will_be_fixed
FROM AGGNE.PRD.policyattach_bp pb
WHERE NOT EXISTS (
    SELECT 1 FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW dim
    WHERE TRIM(dim.CMLNUMBER) = TRIM(pb.CMLNUMBER)
)
AND EXISTS (
    SELECT 1 FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2_DELTA dlt
    WHERE TRIM(dlt.CMLNUMBER) = TRIM(pb.CMLNUMBER)
    AND dlt.ACTIVE_FLAG = TRUE
);


-- ==========================================================================
-- STEP 0C: How many impacted policies will be queued in Step 2?
-- ==========================================================================
SELECT COUNT(DISTINCT pb.PUREPOLICYNUMBER) AS policies_to_requeue
FROM AGGNE.PRD.policyattach_bp pb
WHERE NOT EXISTS (
    SELECT 1 FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW dim
    WHERE TRIM(dim.CMLNUMBER) = TRIM(pb.CMLNUMBER)
)
AND EXISTS (
    SELECT 1 FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2_DELTA dlt
    WHERE TRIM(dlt.CMLNUMBER) = TRIM(pb.CMLNUMBER)
    AND dlt.ACTIVE_FLAG = TRUE
);


-- ==========================================================================
-- STEP 1: INSERT missing CMLs from delta → DIM_PARTY_CML_CSL_NEW
-- --------------------------------------------------------------------------
-- Inserts one row per missing CML, taking the latest EFFECTIVE_FROM record
-- where ACTIVE_FLAG = TRUE. Skips CMLs already present in the target.
-- ==========================================================================
INSERT INTO AGGNE.DEV.DIM_PARTY_CML_CSL_NEW (
    PARTY_DIM_ID,
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
    SECONDARYCONTACT,      -- delta column is SCONDARYCONTACT (typo)
    SECONDARYCONTACTKEY,   -- delta column is SCONDARYCONTACTKEY (typo)
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
        PARTY_DIM_ID,
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
        SCONDARYCONTACT    AS SECONDARYCONTACT,     -- typo in delta source
        SCONDARYCONTACTKEY AS SECONDARYCONTACTKEY,  -- typo in delta source
        PAID2DATE,
        MEM_REF,
        EFFECTIVE_DATE,
        AMOUNT,
        HASH_DIFF,
        EFFECTIVE_FROM,
        EFFECTIVE_TO,
        IS_CURRENT,
        ACTIVE_FLAG,
        ROW_NUMBER() OVER (
            PARTITION BY CMLNUMBER
            ORDER BY EFFECTIVE_FROM DESC
        ) AS RN
    FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2_DELTA
    WHERE ACTIVE_FLAG = TRUE
)
SELECT
    PARTY_DIM_ID,
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
    SECONDARYCONTACT,
    SECONDARYCONTACTKEY,
    PAID2DATE,
    MEM_REF,
    EFFECTIVE_DATE,
    AMOUNT,
    HASH_DIFF,
    EFFECTIVE_FROM,
    EFFECTIVE_TO,
    IS_CURRENT,
    ACTIVE_FLAG
FROM LATEST_DELTA
WHERE RN = 1
  AND NOT EXISTS (
      SELECT 1
      FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW tgt
      WHERE TRIM(tgt.CMLNUMBER) = TRIM(LATEST_DELTA.CMLNUMBER)
  );


-- ==========================================================================
-- STEP 1 VERIFY: Confirm the INSERT worked for P00037360 / CML00034653
-- ==========================================================================
SELECT CMLNUMBER, CMLTRADINGNAME, ABN_NZBN, CSL_MEMBER_STATUS, EFFECTIVE_FROM
FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW
WHERE CMLNUMBER = 'CML00034653';
-- Expected: 1 row, ABN_NZBN = 79674193992, CMLTRADINGNAME = JK ADVENTURE CO PTY LTD


-- ==========================================================================
-- STEP 2: Queue impacted policies for re-attach
-- --------------------------------------------------------------------------
-- Uses DIM_PARTY_CML_CSL_NEW_bkp_09072026 (taken before Step 1) to precisely
-- identify CMLs that were newly inserted — avoids re-queuing policies whose
-- CML was already present before today's fix.
-- Run AFTER Step 1 completes.
-- ==========================================================================

-- STEP 2 PREVIEW (run first to check count):
SELECT DISTINCT pb.PUREPOLICYNUMBER
FROM AGGNE.PRD.policyattach_bp pb
WHERE
    EXISTS (
        SELECT 1
        FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW dim
        WHERE TRIM(dim.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND dim.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
          AND dim.BK_CMLNUMBER NOT IN (
              SELECT BK_CMLNUMBER FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026
          )
    )
    AND NOT EXISTS (
        SELECT 1
        FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
        WHERE q.PUREPOLICYNUMBER = pb.PUREPOLICYNUMBER
    );

-- STEP 2 INSERT (run after confirming preview count):
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
SELECT DISTINCT pb.PUREPOLICYNUMBER
FROM AGGNE.PRD.policyattach_bp pb
WHERE
    EXISTS (
        SELECT 1
        FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW dim
        WHERE TRIM(dim.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND dim.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
          AND dim.BK_CMLNUMBER NOT IN (
              SELECT BK_CMLNUMBER FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026
          )
    )
    AND NOT EXISTS (
        SELECT 1
        FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
        WHERE q.PUREPOLICYNUMBER = pb.PUREPOLICYNUMBER
    );


-- ==========================================================================
-- STEP 2 VERIFY: Confirm queue was populated
-- ==========================================================================
SELECT COUNT(*) AS queued_count
FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;

-- Spot-check P00037360 is in the queue
SELECT * FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS
WHERE PUREPOLICYNUMBER = 'P00037360';
