-- ============================================================
-- STEP 2 — Create Party XMLs for missing parties, DEV-scoped
-- Run on: Snowflake, AGGNE.DEV
-- Type: DDL (creates a new procedure) + DML (populates a staging
--       table + calls the procedure). NEW OBJECT, does not touch
--       the existing AGGNE.UAT.INSERT_PARTY_TO_DCTTABLE_SEC_CONTACT.
--
-- What this is: a DEV-targeted copy of the proven
-- AGGNE.UAT.INSERT_PARTY_TO_DCTTABLE_SEC_CONTACT() procedure.
-- Same DCT manuscript template (add/update party, email, phone,
-- location) — only two things changed:
--   1. Target table: AGGNE.UAT.CML_MIGRATION_DCT -> AGGNE.DEV.CML_MIGRATION_DCT
--   2. Source view:  AGGNE.UAT.VW_DIM_PARTY_SEC_CONTACT -> AGGNE.DEV.VW_DIM_PARTY_SEC_CONTACT
--   3. Filter: the old ad-hoc TEMP_ATP_10515_List -> our pilot's
--      missing-CML list from Step 1.
-- ============================================================

-- 2a. Staging table to hold Step 1's missing-CML output
--     (small, reusable — truncate + reload each pilot run)
CREATE OR REPLACE TABLE AGGNE.DEV.PP_MISSING_PARTY_CMLS (
    CMLNUMBER VARCHAR
);

-- Populate from Step 1's output (paste the MISSING rows' CMLNUMBER here,
-- or run this INSERT...SELECT directly against Step 1's query):
INSERT INTO AGGNE.DEV.PP_MISSING_PARTY_CMLS (CMLNUMBER)
SELECT DISTINCT P.CMLNUMBER
FROM AGGNE.DEV.PP_PILOT_POLICIES P
LEFT JOIN AGGNE.DEV.VW_MAX_PARTYDET V
       ON TRIM(P.CMLNUMBER) = TRIM(V.CML_NUMBER)
WHERE V.PARTYID IS NULL;

SELECT * FROM AGGNE.DEV.PP_MISSING_PARTY_CMLS;
-- Review this list before proceeding — every CML here will get a
-- real Party create/update request queued in Step 3.

-- ============================================================
-- 2b. New procedure — DEV-scoped Party XML generator
--     (copy of INSERT_PARTY_TO_DCTTABLE_SEC_CONTACT, retargeted)
-- ============================================================
-- NOTE: paste the full manuscript body from
-- AGGNE.UAT.INSERT_PARTY_TO_DCTTABLE_SEC_CONTACT() here (GET_DDL
-- already captured separately) with these three substitutions:
--   INSERT INTO AGGNE.UAT.CML_MIGRATION_DCT   -> INSERT INTO AGGNE.DEV.CML_MIGRATION_DCT
--   FROM AGGNE.UAT.VW_DIM_PARTY_SEC_CONTACT   -> FROM AGGNE.DEV.VW_DIM_PARTY_SEC_CONTACT
--   WHERE TRIM(CMLNUMBER) IN (SELECT CMLNUMBER FROM AGGNE.DEV.TEMP_ATP_10515_List)
--       -> WHERE TRIM(CMLNUMBER) IN (SELECT CMLNUMBER FROM AGGNE.DEV.PP_MISSING_PARTY_CMLS)
--
-- CREATE OR REPLACE PROCEDURE AGGNE.DEV.PP_INSERT_PARTY_TO_DCTTABLE_DEV()
-- RETURNS VARCHAR
-- LANGUAGE SQL
-- EXECUTE AS OWNER
-- AS '<same manuscript body as UAT version, retargeted as above>';
--
-- Full retargeted body is provided as a companion file:
-- STEP2b_PP_INSERT_PARTY_TO_DCTTABLE_DEV_PROCEDURE.sql
-- (kept separate because of its size — review it before running)

-- 2c. Run it
-- CALL AGGNE.DEV.PP_INSERT_PARTY_TO_DCTTABLE_DEV();

-- 2d. Verify rows landed
-- SELECT CML_NUMBER, BUCKET, LEN(REQUEST_XML) AS XML_LEN, CREATED_AT
-- FROM AGGNE.DEV.CML_MIGRATION_DCT
-- WHERE CML_NUMBER IN (SELECT CMLNUMBER FROM AGGNE.DEV.PP_MISSING_PARTY_CMLS)
-- ORDER BY CREATED_AT DESC;
