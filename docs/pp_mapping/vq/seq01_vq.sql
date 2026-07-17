-- ============================================================
-- Seq 1 (losshistory) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-16 Cause caption-vs-code (P1), G-15 unparseable dates (P2)
-- ============================================================

-- G-16: Cause values vs DCT code list
SELECT CAUSE, COUNT(*) AS CNT,
       CASE WHEN CAUSE IN ('AtFault','NotAtFault','Theft','Fire','Flood','Burglary','Other')
            THEN 'VALID CODE' ELSE 'INVALID (caption/raw text)' END AS DCT_CHECK
FROM AGGNE.DEV.PER_VW_CLAIM_HISTORY
GROUP BY CAUSE ORDER BY CNT DESC;

-- G-15: claims whose date failed parsing (empty DateOfClaim on a required field)
SELECT COUNT(*) AS DATE_PARSE_FAILURES
FROM AGGNE.DEV.PER_VW_CLAIM_HISTORY
WHERE DATEOFCLAIM IS NULL OR TRIM(DATEOFCLAIM) = '';

-- raw source dates that fail (for the fallback decision)
SELECT DISTINCT T1.DATEOFCLAIM AS RAW_SOURCE_DATE
FROM AGGNE.DEV.CLAIMHISTORY T1
WHERE TRY_TO_DATE(REGEXP_REPLACE(TRIM(T1.DATEOFCLAIM), '[A-Za-z]', ''), 'YYYY-MM-DD') IS NULL
  AND COALESCE(TRIM(T1.DATEOFCLAIM),'') <> ''
LIMIT 50;

-- Line code distribution (sanity)
SELECT LINE, COUNT(*) FROM AGGNE.DEV.PER_VW_CLAIM_HISTORY GROUP BY LINE ORDER BY 2 DESC;
