-- ==========================================================================
-- Queue: BP policies with BAD XML only (CML-affected, confirmed empty nodes)
-- Scope : 177 policies — 175 in-force + 2 expired ≤ 2yr
--         NEVER_LOADED (226) and XML_OK (2,424) are excluded.
-- Filter: CML freshly inserted today (not in backup) + empty ABN or Line type
-- Date  : 2026-07-09
-- ==========================================================================


-- ==========================================================================
-- STEP 0: PER-POLICY CHECK — confirm which policies have bad XML
-- Run this first to review the list before inserting into the queue.
-- ==========================================================================
WITH cml_affected AS (
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
    HAVING MAX(pb.PUREEXPIRYDATE) >= DATEADD('year', -2, CURRENT_DATE())
),
latest_xml AS (
    SELECT POLICY_NUMBER, POLICY_ATTACH_XML, LOAD_TS,
           ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS RNO
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    WHERE POLICY_NUMBER IN (SELECT PUREPOLICYNUMBER FROM cml_affected)
)
SELECT
    ca.PUREPOLICYNUMBER,
    CASE WHEN ca.MAX_EXPIRY >= CURRENT_DATE() THEN 'INFORCE' ELSE 'EXPIRED' END AS STATUS,
    ca.MAX_EXPIRY                                                                 AS EXPIRY_DATE,
    lx.LOAD_TS                                                                    AS LAST_LOADED,
    CASE WHEN REGEXP_INSTR(lx.POLICY_ATTACH_XML, '<ABNNumber>[^<]+</ABNNumber>') = 0
         THEN 'EMPTY' ELSE 'OK' END                                               AS ABN,
    CASE WHEN REGEXP_INSTR(lx.POLICY_ATTACH_XML, '<Line type="[^"]+">') = 0
         THEN 'EMPTY' ELSE 'OK' END                                               AS LINE_TYPE
FROM cml_affected ca
INNER JOIN latest_xml lx ON lx.POLICY_NUMBER = ca.PUREPOLICYNUMBER AND lx.RNO = 1
WHERE REGEXP_INSTR(lx.POLICY_ATTACH_XML, '<ABNNumber>[^<]+</ABNNumber>') = 0
   OR REGEXP_INSTR(lx.POLICY_ATTACH_XML, '<Line type="[^"]+">') = 0
ORDER BY STATUS, ca.PUREPOLICYNUMBER;
-- Expected: 177 rows (175 INFORCE + 2 EXPIRED)


-- ==========================================================================
-- STEP 1: INSERT BAD XML — In-force (175 policies)
-- ==========================================================================
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH cml_affected AS (
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
    HAVING MAX(pb.PUREEXPIRYDATE) >= CURRENT_DATE()   -- IN-FORCE
),
latest_xml AS (
    SELECT POLICY_NUMBER, POLICY_ATTACH_XML,
           ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS RNO
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    WHERE POLICY_NUMBER IN (SELECT PUREPOLICYNUMBER FROM cml_affected)
)
SELECT ca.PUREPOLICYNUMBER
FROM cml_affected ca
INNER JOIN latest_xml lx ON lx.POLICY_NUMBER = ca.PUREPOLICYNUMBER AND lx.RNO = 1
WHERE (
    REGEXP_INSTR(lx.POLICY_ATTACH_XML, '<ABNNumber>[^<]+</ABNNumber>') = 0
    OR REGEXP_INSTR(lx.POLICY_ATTACH_XML, '<Line type="[^"]+">') = 0
)
AND NOT EXISTS (
    SELECT 1 FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
    WHERE q.PUREPOLICYNUMBER = ca.PUREPOLICYNUMBER
);

SELECT COUNT(*) AS batch1_inforce_bad_xml FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;
-- Expected: 175


-- ==========================================================================
-- STEP 2: RUN ATTACH SP FOR IN-FORCE BAD XML
-- ==========================================================================


-- ==========================================================================
-- STEP 3: INSERT BAD XML — Expired ≤ 2 years (2 policies)
-- ==========================================================================
INSERT INTO AGGNE.PRD.POLICYATTACH_TO_PROCESS (PUREPOLICYNUMBER)
WITH cml_affected AS (
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
    HAVING MAX(pb.PUREEXPIRYDATE) <  CURRENT_DATE()
       AND MAX(pb.PUREEXPIRYDATE) >= DATEADD('year', -2, CURRENT_DATE())  -- EXPIRED ≤ 2yr
),
latest_xml AS (
    SELECT POLICY_NUMBER, POLICY_ATTACH_XML,
           ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS RNO
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    WHERE POLICY_NUMBER IN (SELECT PUREPOLICYNUMBER FROM cml_affected)
)
SELECT ca.PUREPOLICYNUMBER
FROM cml_affected ca
INNER JOIN latest_xml lx ON lx.POLICY_NUMBER = ca.PUREPOLICYNUMBER AND lx.RNO = 1
WHERE (
    REGEXP_INSTR(lx.POLICY_ATTACH_XML, '<ABNNumber>[^<]+</ABNNumber>') = 0
    OR REGEXP_INSTR(lx.POLICY_ATTACH_XML, '<Line type="[^"]+">') = 0
)
AND NOT EXISTS (
    SELECT 1 FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS q
    WHERE q.PUREPOLICYNUMBER = ca.PUREPOLICYNUMBER
);

SELECT COUNT(*) AS batch2_expired_bad_xml FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;
-- Expected: 177 total (175 + 2)


-- ==========================================================================
-- STEP 4: RUN ATTACH SP FOR EXPIRED ≤ 2yr BAD XML
-- ==========================================================================
