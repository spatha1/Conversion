-- ============================================================
-- Seq 15 (motor sub-coverages) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gap: G-37 unconditional blocks vs ProtectionType (P2)
-- ============================================================

-- Block volume per code
SELECT CODE, COUNT(*) AS ROWS_, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.PER_COM_COVERAGES
GROUP BY CODE ORDER BY CODE;

-- G-37 signal: comprehensive blocks emitted for Third-Party-Only vehicles (and vice versa)
SELECT P.PROTECTIONTYPE, C.CODE, COUNT(*) AS CNT
FROM AGGNE.DEV.PER_COM_COVERAGES C
JOIN AGGNE.DEV.PER_COM_PAYLOAD P ON C.PUREPOLICYNUMBER = P.PUREPOLICYNUMBER
WHERE (P.PROTECTIONTYPE = 'ThirdPartyOnly'  AND C.CODE IN ('PMCMP_SD','PMPCH_SD','PMULG_SD','PMCOR_SD'))
   OR (P.PROTECTIONTYPE LIKE 'Comprehensive%' AND C.CODE = 'PMTPO_SD')
GROUP BY 1, 2 ORDER BY 1, 2;

-- Options not taken but block emitted (Car Hire / Choice of Repair / Glass)
SELECT 'CarHire_block_vs_NotTaken' AS CHECK_, COUNT(*) AS CNT
FROM AGGNE.DEV.PER_COM_COVERAGES C
JOIN AGGNE.DEV.PER_COM_PAYLOAD P ON C.PUREPOLICYNUMBER = P.PUREPOLICYNUMBER
WHERE C.CODE='PMPCH_SD' AND P.HIRECARHIREAFTERINCIDENT='NotTaken';
