-- ============================================================
-- STEP 10 — Validate assigned bugs + dropdown/length/mandatory scenarios
-- Run on: Snowflake, AGGNE.DEV
-- Type: READ-ONLY — reuses tooling already built and proven this session
-- ============================================================

-- 10a. Full XML validation (rules-based: INVALID_CODE, MISSING_TAG,
--      BLANK_REQUIRED) — same SP used in Step 5's gate, re-run here
--      scoped to the pilot for a final post-DCT-push check.
--      Full script: sql/snowflake/1_conversion/PP/validation/
--                   PP_XML_VALIDATE_AND_REPORT.sql
CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, NULL);
-- then run Step 5's queries (5b-5e in PP_XML_VALIDATE_AND_REPORT.sql)
-- scoped to PP_PILOT_POLICIES

-- 10b. Dropdown/mandatory field gap analysis — existing views
SELECT * FROM AGGNE.DEV.PER_DROPDOWN_ALL_VALIDATION
WHERE LEGACYPOLICYNUMBER IN (SELECT LEGACYPOLICYNUMBER FROM AGGNE.DEV.PP_PILOT_POLICIES)
  AND IS_IN_DCT_LIST = 'No';

-- 10c. ATP-10963-style Redbook/YMM gap check
--      Full script: sql/snowflake/1_conversion/PP/validation/
--                   ATP10963_REDBOOK_YMM_GAP.sql (scope to pilot as needed)

-- 10d. Bug-to-policy cross-reference — for each JIRA ticket that cites
--      a specific LegacyPolicyNumber or QuoteID, confirm the field it
--      complains about now matches expectation in the pilot's XML +
--      Clarity landing (from Step 8). This is manual per-ticket
--      confirmation using the queries built earlier this session
--      (see project_pp_field_bugs.md memory for the reconciled list:
--      ATP-10965, ATP-10962, ATP-10961, ATP-10963).

-- 10e. NEW — length / mandatory field scan across ALL required fields
--      (not just RoofConstruction/MainWall) — this generalizes the
--      dropdown-gap pattern. Not yet built as a standing view; can be
--      added as its own deliverable once PP_XML_VALIDATION_RULES has
--      full mandatory-field coverage entered for every screen (currently
--      only HB/HC/RISK_Building_PM/motor fields are in v1.0/v1.2 —
--      HC sub-coverages, additional-interest, and business-details
--      mandatory fields are not yet in the rule table).
