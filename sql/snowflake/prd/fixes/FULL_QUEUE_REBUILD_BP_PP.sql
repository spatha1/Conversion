-- ==========================================================================
-- Full queue rebuild — BP and PP policy attach
-- Triggered by: CML data gap fix (new members inserted into
--               DEV.DIM_PARTY_CML_CSL_NEW + PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2)
-- Both queue tables truncated and re-populated with all eligible policies.
--
-- Rule  : Include IN-FORCE policies + policies expired within 2 years only.
--         Exclude anything expired > 2 years ago.
-- Order : Batch 1 (in-force) processed first — priority for claims team.
--         Batch 2 (expired ≤ 2yr) processed second.
--
-- Expected counts (as of 2026-07-09):
--   BP  — Batch 1 in-force      : 16,076
--   BP  — Batch 2 expired ≤ 2yr :  4,302
--   PP  — Batch 1 in-force      :  4,578
--   PP  — Batch 2 expired ≤ 2yr :  1,297
--
-- Queues:
--   BP → AGGNE.PRD.POLICYATTACH_TO_PROCESS
--   PP → AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS
-- Expiry column: PUREEXPIRYDATE (both tables)
-- ==========================================================================


-- ==========================================================================
-- STEP 0: PREVIEW — Validate counts before truncating
-- Run all three blocks and confirm numbers match expectations above.
-- ==========================================================================

-- BP breakdown
WITH bp AS (
    SELECT PUREPOLICYNUMBER, MAX(PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_bp
    GROUP BY PUREPOLICYNUMBER
)
SELECT
    'BP' AS LOB,
    SUM(CASE WHEN MAX_EXPIRY >= CURRENT_DATE()                                  THEN 1 ELSE 0 END) AS batch1_inforce,
    SUM(CASE WHEN MAX_EXPIRY <  CURRENT_DATE()
              AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE())             THEN 1 ELSE 0 END) AS batch2_expired_2yr,
    SUM(CASE WHEN MAX_EXPIRY <  DATEADD('year', -2, CURRENT_DATE())             THEN 1 ELSE 0 END) AS excluded_over_2yr,
    COUNT(*) AS total_policies
FROM bp;

-- PP breakdown
WITH pp AS (
    SELECT PUREPOLICYNUMBER, MAX(PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_per
    GROUP BY PUREPOLICYNUMBER
)
SELECT
    'PP' AS LOB,
    SUM(CASE WHEN MAX_EXPIRY >= CURRENT_DATE()                                  THEN 1 ELSE 0 END) AS batch1_inforce,
    SUM(CASE WHEN MAX_EXPIRY <  CURRENT_DATE()
              AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE())             THEN 1 ELSE 0 END) AS batch2_expired_2yr,
    SUM(CASE WHEN MAX_EXPIRY <  DATEADD('year', -2, CURRENT_DATE())             THEN 1 ELSE 0 END) AS excluded_over_2yr,
    COUNT(*) AS total_policies
FROM pp;

-- Current queue state (snapshot before truncate)
SELECT 'BP_QUEUE' AS queue, COUNT(*) AS rows_before_truncate FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS
UNION ALL
SELECT 'PP_QUEUE',          COUNT(*)                          FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS;


-- ==========================================================================
-- STEP 1: TRUNCATE BOTH QUEUES
-- WARNING: This removes all rows currently waiting to be processed.
--          Confirm with your team before running.
-- ==========================================================================
TRUNCATE TABLE AGGNE.PRD.POLICYATTACH_TO_PROCESS;
TRUNCATE TABLE AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS;


-- ==========================================================================
-- STEP 2: BP — BATCH 1 (In-force, priority)
-- Expected: 16,076 rows
-- ==========================================================================
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT PUREPOLICYNUMBER, MAX(PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_bp
    GROUP BY PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY >= CURRENT_DATE();   -- IN-FORCE

SELECT COUNT(*) AS bp_batch1_queued FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;
-- Expected: 16,076


-- ==========================================================================
-- STEP 3: PP — BATCH 1 (In-force, priority)
-- Expected: 4,578 rows
-- ==========================================================================
INSERT INTO AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT PUREPOLICYNUMBER, MAX(PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_per
    GROUP BY PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY >= CURRENT_DATE();   -- IN-FORCE

SELECT COUNT(*) AS pp_batch1_queued FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS;
-- Expected: 4,578


-- ==========================================================================
-- STEP 4: RUN ATTACH SPs FOR BATCH 1
-- Execute the BP and PP attach stored procedures to process in-force policies.
-- Only proceed to Batch 2 after both SPs complete successfully.
--
--   CALL AGGNE.PRD.SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD();   -- BP
--   CALL AGGNE.PRD.SP_PP_DATEDIM_IDENTIFIER_SETUP();         -- PP (confirm SP name)
-- ==========================================================================


-- ==========================================================================
-- STEP 5: BP — BATCH 2 (Expired within 2 years)
-- Expected: 4,302 rows
-- Run AFTER Batch 1 SP has completed.
-- ==========================================================================
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT PUREPOLICYNUMBER, MAX(PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_bp
    GROUP BY PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY <  CURRENT_DATE()                       -- EXPIRED
  AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE()); -- WITHIN 2 YEARS

SELECT COUNT(*) AS bp_batch2_queued FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;
-- Expected: 4,302


-- ==========================================================================
-- STEP 6: PP — BATCH 2 (Expired within 2 years)
-- Expected: 1,297 rows
-- Run AFTER Batch 1 SP has completed.
-- ==========================================================================
INSERT INTO AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT PUREPOLICYNUMBER, MAX(PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_per
    GROUP BY PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY <  CURRENT_DATE()                       -- EXPIRED
  AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE()); -- WITHIN 2 YEARS

SELECT COUNT(*) AS pp_batch2_queued FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS;
-- Expected: 1,297


-- ==========================================================================
-- STEP 7: RUN ATTACH SPs FOR BATCH 2
-- Execute the BP and PP attach stored procedures again to process
-- the expired-within-2yr policies.
--
--   CALL AGGNE.PRD.SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD();   -- BP
--   CALL AGGNE.PRD.SP_PP_DATEDIM_IDENTIFIER_SETUP();         -- PP (confirm SP name)
-- ==========================================================================


-- ==========================================================================
-- FINAL VERIFY: Check POLICY_ATTACH_TABLE loaded correctly after both batches
-- ==========================================================================
SELECT
    'BP' AS LOB,
    COUNT(DISTINCT POLICY_NUMBER) AS policies_in_attach_table
FROM AGGNE.PRD.POLICY_ATTACH_TABLE
WHERE POLICY_NUMBER LIKE 'P%'

UNION ALL

SELECT
    'PP',
    COUNT(DISTINCT POLICY_NUMBER)
FROM AGGNE.PRD.POLICY_ATTACH_TABLE
WHERE POLICY_NUMBER LIKE 'Q%';  -- adjust prefix if PP uses different prefix
