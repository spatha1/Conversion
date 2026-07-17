-- ============================================================
-- Seq 4 (HB sub-coverages) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gap: G-18 unconditional Indicator=1 blocks (P2)
-- ============================================================

-- Block volume: 8 blocks per HB policy expected
SELECT CODE, COUNT(*) AS ROWS_, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.PER_BB_SUBCOVERAGES
GROUP BY CODE ORDER BY CODE;

-- G-18 signal: Landlords block emitted for owner-occupied policies
SELECT COUNT(DISTINCT S.PUREPOLICYNUMBER) AS LLB_ON_OWNER_OCCUPIED
FROM AGGNE.DEV.PER_BB_SUBCOVERAGES S
JOIN AGGNE.DEV.Locationdetails_PER L
  ON TRIM(SPLIT_PART(S.PUREPOLICYNUMBER,'|',1)) = TRIM(L.PUREPOLICYNUMBER)
WHERE S.CODE = 'HBLLB_SD' AND L.HOWOCCUPPIED = 'Owner Occupied';

-- Zero building limits on live blocks (data-quality signal)
SELECT COUNT(*) AS ZERO_LIMIT_BLOCKS
FROM AGGNE.DEV.PER_BB_SUBCOVERAGES
WHERE CODE IN ('HBBLD_SD','HBBLD_BF','HBBLD_CY','HBBLD_EQ','HBBLD_ST','HBBLI_SD','HBLLB_SD')
  AND IVALUE = '0';

-- Taken/NotTaken distribution on the optioned blocks
SELECT CODE, SVALUE, COUNT(*) FROM AGGNE.DEV.PER_BB_SUBCOVERAGES
WHERE CODE IN ('HBBFL_SD','HBBAD_SD') GROUP BY CODE, SVALUE ORDER BY CODE;
