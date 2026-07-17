-- ==========================================================================
-- Queue: CML-affected policies only (BP + PP), in-force first then ≤2yr
-- Filter: policies whose CML was freshly inserted today (not in backup)
-- Rule  : In-force (Batch 1) → Expired ≤ 2yr (Batch 2). >2yr excluded.
-- Date  : 2026-07-09
--
-- Queues:
--   BP → AGGNE.PRD.POLICYATTACH_TO_PROCESS
--   PP → AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS
-- ==========================================================================


-- ==========================================================================
-- STEP 0: PREVIEW COUNTS — run before any INSERT
-- ==========================================================================

-- BP counts
WITH cml_fixed AS (
    SELECT DISTINCT pb.PUREPOLICYNUMBER,
                    MAX(pb.PUREEXPIRYDATE) OVER (PARTITION BY pb.PUREPOLICYNUMBER) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_bp pb
    WHERE EXISTS (
        SELECT 1
        FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW dim
        WHERE TRIM(dim.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND dim.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
          AND dim.BK_CMLNUMBER NOT IN (
              SELECT BK_CMLNUMBER FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026
          )
    )
)
SELECT
    'BP' AS LOB,
    SUM(CASE WHEN MAX_EXPIRY >= CURRENT_DATE()                                  THEN 1 ELSE 0 END) AS batch1_inforce,
    SUM(CASE WHEN MAX_EXPIRY <  CURRENT_DATE()
              AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE())             THEN 1 ELSE 0 END) AS batch2_le2yr,
    SUM(CASE WHEN MAX_EXPIRY <  DATEADD('year', -2, CURRENT_DATE())             THEN 1 ELSE 0 END) AS excluded_gt2yr,
    COUNT(*) AS total_cml_affected
FROM cml_fixed;

-- PP counts
WITH cml_fixed AS (
    SELECT DISTINCT pb.PUREPOLICYNUMBER,
                    MAX(pb.PUREEXPIRYDATE) OVER (PARTITION BY pb.PUREPOLICYNUMBER) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_per pb
    WHERE EXISTS (
        SELECT 1
        FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 s
        WHERE TRIM(s.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND s.IS_CURRENT = TRUE
          AND s.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
    )
)
SELECT
    'PP' AS LOB,
    SUM(CASE WHEN MAX_EXPIRY >= CURRENT_DATE()                                  THEN 1 ELSE 0 END) AS batch1_inforce,
    SUM(CASE WHEN MAX_EXPIRY <  CURRENT_DATE()
              AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE())             THEN 1 ELSE 0 END) AS batch2_le2yr,
    SUM(CASE WHEN MAX_EXPIRY <  DATEADD('year', -2, CURRENT_DATE())             THEN 1 ELSE 0 END) AS excluded_gt2yr,
    COUNT(*) AS total_cml_affected
FROM cml_fixed;


-- ==========================================================================
-- STEP 1: BP BATCH 1 — In-force (priority)
-- ==========================================================================
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT pb.PUREPOLICYNUMBER, MAX(pb.PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_bp pb
    WHERE EXISTS (
        SELECT 1
        FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW dim
        WHERE TRIM(dim.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND dim.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
          AND dim.BK_CMLNUMBER NOT IN (
              SELECT BK_CMLNUMBER FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026
          )
    )
    GROUP BY pb.PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY >= CURRENT_DATE()    -- IN-FORCE
  AND NOT EXISTS (
      SELECT 1 FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
      WHERE q.PUREPOLICYNUMBER = policy_expiry.PUREPOLICYNUMBER
  );

SELECT COUNT(*) AS bp_batch1_queued FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;


-- ==========================================================================
-- STEP 2: PP BATCH 1 — In-force (priority)
-- ==========================================================================
INSERT INTO AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT pb.PUREPOLICYNUMBER, MAX(pb.PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_per pb
    WHERE EXISTS (
        SELECT 1
        FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 s
        WHERE TRIM(s.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND s.IS_CURRENT = TRUE
          AND s.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
    )
    GROUP BY pb.PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY >= CURRENT_DATE()    -- IN-FORCE
  AND NOT EXISTS (
      SELECT 1 FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS q
      WHERE q.PUREPOLICYNUMBER = policy_expiry.PUREPOLICYNUMBER
  );

SELECT COUNT(*) AS pp_batch1_queued FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS;


-- ==========================================================================
-- STEP 3: RUN ATTACH SPs FOR BATCH 1 (in-force)
-- After both SPs complete, proceed to Batch 2.
-- ==========================================================================


-- ==========================================================================
-- STEP 4: BP BATCH 2 — Expired within 2 years
-- ==========================================================================
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT pb.PUREPOLICYNUMBER, MAX(pb.PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_bp pb
    WHERE EXISTS (
        SELECT 1
        FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW dim
        WHERE TRIM(dim.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND dim.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
          AND dim.BK_CMLNUMBER NOT IN (
              SELECT BK_CMLNUMBER FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026
          )
    )
    GROUP BY pb.PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY <  CURRENT_DATE()                        -- EXPIRED
  AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE())  -- WITHIN 2 YEARS
  AND NOT EXISTS (
      SELECT 1 FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
      WHERE q.PUREPOLICYNUMBER = policy_expiry.PUREPOLICYNUMBER
  );

SELECT COUNT(*) AS bp_batch2_queued FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;


-- ==========================================================================
-- STEP 5: PP BATCH 2 — Expired within 2 years
-- ==========================================================================
INSERT INTO AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT pb.PUREPOLICYNUMBER, MAX(pb.PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_per pb
    WHERE EXISTS (
        SELECT 1
        FROM AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 s
        WHERE TRIM(s.CMLNUMBER) = TRIM(pb.CMLNUMBER)
          AND s.IS_CURRENT = TRUE
          AND s.EFFECTIVE_FROM >= DATEADD('day', -1, CURRENT_TIMESTAMP())
    )
    GROUP BY pb.PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY <  CURRENT_DATE()                        -- EXPIRED
  AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE())  -- WITHIN 2 YEARS
  AND NOT EXISTS (
      SELECT 1 FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS q
      WHERE q.PUREPOLICYNUMBER = policy_expiry.PUREPOLICYNUMBER
  );

SELECT COUNT(*) AS pp_batch2_queued FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS;


-- ==========================================================================
-- STEP 6: RUN ATTACH SPs FOR BATCH 2 (expired ≤2yr)
-- ==========================================================================
