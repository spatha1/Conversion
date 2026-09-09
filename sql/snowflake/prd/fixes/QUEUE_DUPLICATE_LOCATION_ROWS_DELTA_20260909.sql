-- ============================================================================
-- DELTA/REPROCESS: Queue IN-FORCE policies impacted by the duplicate-location /
-- orphaned-risk bug for reprocessing, now that the Snowflake-side fix is live
-- Date: 2026-09-09
-- SAFE_MODE -- NOT APPLIED. Review and confirm before running.
--
-- CONTEXT:
--   See docs/bp_mapping/Duplicate_Location_Rows_OrphanedRisk_Investigation_20260907.md
--   and sql/snowflake/prd/bugfixes/BUGFIX_PA_RISK_BUILDING_FINAL_DuplicateLocationOrphanedRisk_20260908.sql
--   (deployed and confirmed live 2026-09-09 14:08:23 -- DENSE_RANK() confirmed
--   in GET_DDL, impacted-ACTUALID count in the current live batch is 0).
--
--   The Snowflake-side fix to PA_RISK_BUILDING_FINAL stops a duplicated
--   location row from producing an orphaned/phantom risk block. It only takes
--   effect for policies that get reprocessed through the attach pipeline
--   AFTER the fix went live -- it does not retroactively touch XML that was
--   already generated and sent. This script queues the affected policies so
--   they get reprocessed and pick up the corrected output.
--
--   NOTE: this does NOT fix the underlying duplicate row itself -- that's
--   still introduced upstream in the external load into AGGNE.PRD.policyattach_bp
--   (confirmed not a PURE issue -- separate, already-flagged handoff item).
--   Reprocessed policies will still have a duplicate location internally;
--   they just won't send an orphaned risk block for it anymore.
--
--   Going straight to POLICYATTACH_TO_PROCESS rather than re-inserting into
--   policyattach_bp -- same DELTA_PROCESS/POLICYATTACH_BP_MAX_OLD blind spot
--   documented in FORCE_QUEUE_79_NULL_RESPONSE_POLICIES_20260808.sql: these
--   policies' binder already matches POLICYATTACH_BP_MAX_OLD, so DELTA_PROCESS
--   would silently skip them if queued that way.
--
--   SCOPE -- narrowed to IN-FORCE only (per request): a policy counts as
--   in-force when today falls inside its actual cover term --
--   AGGNE.PRD.policyattach_bp.COVERSTARTDATE <= CURRENT_DATE() <=
--   policyattach_bp.COVERENDDATE -- joined from the duplicate-location list
--   (LOCATION_01_POLICYATTACH) via PUREPOLICYNUMBER + EXPIRINGID = EXPIRINGID_P.
--   This is narrower than just "not yet expired" (LOCATION_01_POLICYATTACH's
--   own EXPIRYDATE >= today alone would give 1,741) because it also requires
--   the term to have actually started.
--
--   Scale (checked 2026-09-09):
--     Book-wide impacted policies (all terms, any status): 3,208
--     Of those, currently IN-FORCE:                        1,560
--     Already sitting in the queue (in-force subset):         16
--     Net new to queue this run:                            1,544
-- ============================================================================


-- STEP 1: VERIFY -- current queue state before inserting (read-only, run first)
SELECT COUNT(*) AS ALREADY_QUEUED
FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
        FROM AGGNE.PRD.LOCATION_01_POLICYATTACH
        GROUP BY PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
        HAVING COUNT(*) > 1
    ) d
    JOIN AGGNE.PRD.policyattach_bp b
      ON TRIM(b.PUREPOLICYNUMBER) = TRIM(d.PUREPOLICYNUMBER)
     AND b.EXPIRINGID_P = d.EXPIRINGID
    WHERE CURRENT_DATE() BETWEEN b.COVERSTARTDATE AND b.COVERENDDATE
      AND TRIM(d.PUREPOLICYNUMBER) = TRIM(q.PUREPOLICYNUMBER)
);
-- Expected (as of 2026-09-09): 16


-- STEP 2: INSERT -- queue every IN-FORCE impacted policy not already in the queue
-- >>> SAFE_MODE: review STEP 1 result before running <<<
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
SELECT DISTINCT d.PUREPOLICYNUMBER
FROM (
    SELECT PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
    FROM AGGNE.PRD.LOCATION_01_POLICYATTACH
    GROUP BY PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
    HAVING COUNT(*) > 1
) d
JOIN AGGNE.PRD.policyattach_bp b
  ON TRIM(b.PUREPOLICYNUMBER) = TRIM(d.PUREPOLICYNUMBER)
 AND b.EXPIRINGID_P = d.EXPIRINGID
WHERE CURRENT_DATE() BETWEEN b.COVERSTARTDATE AND b.COVERENDDATE
  AND NOT EXISTS (
    SELECT 1
    FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
    WHERE TRIM(q.PUREPOLICYNUMBER) = TRIM(d.PUREPOLICYNUMBER)
);
-- Expected: ~1,544 rows inserted (exact count = STEP1's complement of the
-- in-force impacted total at run time; re-run the STEP1-style count before
-- inserting if time has passed, since normal batch churn and policies
-- entering/leaving their cover term change the totals slightly)


-- STEP 3: VERIFY after insert -- total in-force impacted policies now in queue
SELECT COUNT(DISTINCT q.PUREPOLICYNUMBER) AS TOTAL_INFORCE_IMPACTED_NOW_QUEUED
FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
        FROM AGGNE.PRD.LOCATION_01_POLICYATTACH
        GROUP BY PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
        HAVING COUNT(*) > 1
    ) d
    JOIN AGGNE.PRD.policyattach_bp b
      ON TRIM(b.PUREPOLICYNUMBER) = TRIM(d.PUREPOLICYNUMBER)
     AND b.EXPIRINGID_P = d.EXPIRINGID
    WHERE CURRENT_DATE() BETWEEN b.COVERSTARTDATE AND b.COVERENDDATE
      AND TRIM(d.PUREPOLICYNUMBER) = TRIM(q.PUREPOLICYNUMBER)
);
-- Expected: full in-force impacted count (~1,560, matching STEP 1's universe)


-- STEP 4: POST-REPROCESSING CHECK -- run after the next attach batch completes.
-- Spot-check the original trigger policy directly (confirmed in-force:
-- current term 2026-08-19 to 2027-08-19, so it IS included in this queue):
SELECT PUREPOLICYNUMBER, RISKNUMBER, ADDRESSDESCRIPTION
FROM AGGNE.PRD.PA_RISK_BUILDING_FINAL
WHERE LEGACYPOLICYNUMBER = 'P00029683'
ORDER BY RISKNUMBER;
-- Expected (once it's next processed): RISKNUMBER 1-4 only (no orphaned 5),
-- even though the duplicate location row still exists upstream in policyattach_bp.

-- Book-wide check -- should stay at 0 for any policy that has been
-- reprocessed since the fix went live (2026-09-09 14:08:23):
SELECT COUNT(*) FROM (
    SELECT ACTUALID, COUNT(DISTINCT RISKNUMBER) AS RISK_COUNT, COUNT(DISTINCT ADDRESSDESCRIPTION) AS ADDR_COUNT
    FROM AGGNE.PRD.PA_RISK_BUILDING_FINAL
    GROUP BY ACTUALID
    HAVING RISK_COUNT > ADDR_COUNT
);
-- Expected: 0
-- ============================================================================
