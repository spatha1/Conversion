-- ============================================================
-- STEP 5 — Create PP policy XMLs, pilot-scoped, with validation gate
-- Run on: Snowflake, AGGNE.DEV
-- Type: DML (existing, proven SP — PP_CONVERSION_RUN)
--
-- Runs only for the pilot policies (via PP_RUN_CONTROL), then gates
-- on the existing SP_PP_XML_VALIDATE before letting Step 6 push
-- anything to DCT. This closes the "validation missing for now" note
-- from the original plan — the validation already exists, use it.
-- ============================================================

-- 5a. Scope the run to the pilot list only (empty PP_RUN_CONTROL = all
--     policies — do NOT leave it empty for a pilot run)
TRUNCATE TABLE AGGNE.DEV.PP_RUN_CONTROL;
INSERT INTO AGGNE.DEV.PP_RUN_CONTROL (LEGACYPOLICYNUMBER)
SELECT LEGACYPOLICYNUMBER FROM AGGNE.DEV.PP_PILOT_POLICIES;

-- 5b. Run the full pipeline (all 18 seqs + FINAL_LOAD + FINAL_XML)
--     for the pilot policies only
CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE);

-- 5c. Confirm scope — should equal pilot count, not full DEV volume
SELECT COUNT(*), COUNT(DISTINCT LEGACYPOLICYNUMBER)
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE LEGACYPOLICYNUMBER IN (SELECT LEGACYPOLICYNUMBER FROM AGGNE.DEV.PP_PILOT_POLICIES);

-- ============================================================
-- 5d. VALIDATION GATE — run the existing XML validator before
--     anything in Step 6 pushes these to DCT.
--     (Full script: sql/snowflake/1_conversion/PP/validation/
--      PP_XML_VALIDATE_AND_REPORT.sql — Steps 1-4 there refresh
--      rules + recreate the SP; run those once if not done recently.)
-- ============================================================
CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, NULL);
-- copy the RUN_ID from the result, then:

SELECT ISSUE_TYPE, COUNT(*) AS ISSUE_COUNT, COUNT(DISTINCT POLICY_ID) AS POLICIES_AFFECTED
FROM AGGNE.DEV.PP_XML_VALIDATION_REPORT
WHERE RUN_ID = '<<RUN_ID>>'
  AND LEGACY_POLICY_NO IN (SELECT LEGACYPOLICYNUMBER FROM AGGNE.DEV.PP_PILOT_POLICIES)
GROUP BY ISSUE_TYPE;

-- GATE: if any MISSING_TAG or BLANK_REQUIRED issues appear for the
-- pilot policies, resolve them (or knowingly accept + document) BEFORE
-- running Step 6 — pushing a policy with a known mandatory-field gap
-- to a live DCT environment creates a quote that will just need
-- cleanup or re-work later.
