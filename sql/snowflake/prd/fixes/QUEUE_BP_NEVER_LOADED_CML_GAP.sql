-- ==========================================================================
-- Queue: Never-loaded BP policies with fixed CML, filtered by 2-year rule
-- Context: 5,706 policies in policyattach_bp had missing CML and were never
--          loaded into POLICY_ATTACH_TABLE. After analysing by expiry:
--            - In-force         :    0  (all in-force are in the already-loaded 2,707)
--            - Expired ≤ 2yr    :  226  ← load these (Batch 1)
--            - Expired > 2yr    : 5,480 ← excluded by business rule
-- Target queue: AGGNE.PRD.POLICYATTACH_TO_PROCESS
-- Date: 2026-07-09
-- ==========================================================================


-- ==========================================================================
-- PREVIEW: Confirm counts before inserting
-- ==========================================================================
WITH policy_expiry AS (
    SELECT
        pb.PUREPOLICYNUMBER,
        MAX(pb.PUREEXPIRYDATE) AS MAX_EXPIRY,
        MAX(pb.CMLNUMBER)      AS CMLNUMBER
    FROM AGGNE.PRD.policyattach_bp pb
    WHERE
        -- CML was missing (not in pre-fix backup)
        NOT EXISTS (
            SELECT 1 FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026 bkp
            WHERE TRIM(bkp.CMLNUMBER) = TRIM(pb.CMLNUMBER)
        )
        -- Never loaded before
        AND NOT EXISTS (
            SELECT 1 FROM AGGNE.PRD.POLICY_ATTACH_TABLE pat
            WHERE pat.POLICY_NUMBER = pb.PUREPOLICYNUMBER
        )
    GROUP BY pb.PUREPOLICYNUMBER
)
SELECT
    SUM(CASE WHEN MAX_EXPIRY >= CURRENT_DATE()                                   THEN 1 ELSE 0 END) AS inforce,
    SUM(CASE WHEN MAX_EXPIRY <  CURRENT_DATE()
              AND MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE())              THEN 1 ELSE 0 END) AS expired_within_2yr,
    SUM(CASE WHEN MAX_EXPIRY <  DATEADD('year', -2, CURRENT_DATE())              THEN 1 ELSE 0 END) AS expired_over_2yr_excluded,
    COUNT(*)                                                                                        AS total
FROM policy_expiry;
-- Expected: inforce=0, expired_within_2yr=226, expired_over_2yr=5480, total=5706


-- ==========================================================================
-- PREVIEW DETAIL: List the 226 eligible policies (check before inserting)
-- ==========================================================================
WITH policy_expiry AS (
    SELECT
        pb.PUREPOLICYNUMBER,
        MAX(pb.PUREEXPIRYDATE) AS MAX_EXPIRY,
        MAX(pb.CMLNUMBER)      AS CMLNUMBER,
        MAX(pb.Product)        AS PRODUCT,
        MAX(pb.Country)        AS COUNTRY
    FROM AGGNE.PRD.policyattach_bp pb
    WHERE
        NOT EXISTS (
            SELECT 1 FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026 bkp
            WHERE TRIM(bkp.CMLNUMBER) = TRIM(pb.CMLNUMBER)
        )
        AND NOT EXISTS (
            SELECT 1 FROM AGGNE.PRD.POLICY_ATTACH_TABLE pat
            WHERE pat.POLICY_NUMBER = pb.PUREPOLICYNUMBER
        )
    GROUP BY pb.PUREPOLICYNUMBER
)
SELECT
    PUREPOLICYNUMBER,
    CMLNUMBER,
    PRODUCT,
    COUNTRY,
    MAX_EXPIRY,
    DATEDIFF('day', MAX_EXPIRY, CURRENT_DATE()) AS DAYS_SINCE_EXPIRY
FROM policy_expiry
WHERE MAX_EXPIRY >= DATEADD('year', -2, CURRENT_DATE())
ORDER BY MAX_EXPIRY DESC;


-- ==========================================================================
-- INSERT BATCH 1: In-force policies (priority)
-- Note: 0 policies currently — in-force with missing CML are in the
--       already-loaded 2,707 group. This block is included for completeness
--       and in case new in-force policies appear after future delta syncs.
-- ==========================================================================
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT pb.PUREPOLICYNUMBER, MAX(pb.PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_bp pb
    WHERE
        NOT EXISTS (
            SELECT 1 FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026 bkp
            WHERE TRIM(bkp.CMLNUMBER) = TRIM(pb.CMLNUMBER)
        )
        AND NOT EXISTS (
            SELECT 1 FROM AGGNE.PRD.POLICY_ATTACH_TABLE pat
            WHERE pat.POLICY_NUMBER = pb.PUREPOLICYNUMBER
        )
    GROUP BY pb.PUREPOLICYNUMBER
)
SELECT PUREPOLICYNUMBER
FROM policy_expiry
WHERE MAX_EXPIRY >= CURRENT_DATE()           -- IN-FORCE
AND NOT EXISTS (
    SELECT 1 FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
    WHERE q.PUREPOLICYNUMBER = policy_expiry.PUREPOLICYNUMBER
);
-- Expected rows inserted: 0


-- ==========================================================================
-- VERIFY BATCH 1
-- ==========================================================================
SELECT COUNT(*) AS batch1_queued FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;
-- Run attach SP here before proceeding to Batch 2


-- ==========================================================================
-- INSERT BATCH 2: Expired within 2 years (226 policies)
-- Run after Batch 1 has been processed by the attach SP.
-- ==========================================================================
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH policy_expiry AS (
    SELECT pb.PUREPOLICYNUMBER, MAX(pb.PUREEXPIRYDATE) AS MAX_EXPIRY
    FROM AGGNE.PRD.policyattach_bp pb
    WHERE
        NOT EXISTS (
            SELECT 1 FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_bkp_09072026 bkp
            WHERE TRIM(bkp.CMLNUMBER) = TRIM(pb.CMLNUMBER)
        )
        AND NOT EXISTS (
            SELECT 1 FROM AGGNE.PRD.POLICY_ATTACH_TABLE pat
            WHERE pat.POLICY_NUMBER = pb.PUREPOLICYNUMBER
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
-- Expected rows inserted: 226


-- ==========================================================================
-- VERIFY BATCH 2
-- ==========================================================================
SELECT COUNT(*) AS batch2_queued FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;
