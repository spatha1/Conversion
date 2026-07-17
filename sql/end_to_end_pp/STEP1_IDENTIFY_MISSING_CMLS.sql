-- ============================================================
-- STEP 1 — Identify missing CMLs for pilot PP policies
-- Run on: Snowflake, AGGNE.DEV (id=14 connection)
-- Type: READ-ONLY
--
-- Logic: a PP policy's CML must already have a resolved PartyId
-- (via the proven VW_PARTYDET chain) before policy conversion can
-- send a correct {PARTYID} token. This finds CMLs with no PartyId
-- yet, scoped to the pilot list from Step 0.
-- ============================================================

SELECT DISTINCT
    P.LEGACYPOLICYNUMBER,
    P.CMLNUMBER,
    V.PARTYID,
    CASE WHEN V.PARTYID IS NULL THEN 'MISSING — needs Party push'
         ELSE 'OK — PartyId already resolved' END AS STATUS
FROM AGGNE.DEV.PP_PILOT_POLICIES P                 -- from Step 0
LEFT JOIN AGGNE.DEV.VW_MAX_PARTYDET V
       ON TRIM(P.CMLNUMBER) = TRIM(V.CML_NUMBER)
ORDER BY STATUS DESC, P.LEGACYPOLICYNUMBER;

-- Summary count
SELECT
    SUM(CASE WHEN V.PARTYID IS NULL THEN 1 ELSE 0 END) AS MISSING_CMLS,
    SUM(CASE WHEN V.PARTYID IS NOT NULL THEN 1 ELSE 0 END) AS RESOLVED_CMLS,
    COUNT(DISTINCT P.CMLNUMBER) AS TOTAL_DISTINCT_CMLS
FROM AGGNE.DEV.PP_PILOT_POLICIES P
LEFT JOIN AGGNE.DEV.VW_MAX_PARTYDET V
       ON TRIM(P.CMLNUMBER) = TRIM(V.CML_NUMBER);

-- Take the MISSING CMLNUMBER list from the query above into Step 2's filter.
