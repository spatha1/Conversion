-- ============================================================
-- Validation: PER_ACCOUNT_LOC_TARGET after seq 3 re-run
-- ATP-9746 Issue 2 (AddressOverride) + Issue 3 (RISKNUMBER)
-- Run in: AGGNE.DEV
-- ============================================================


-- Step 1: Row count + LOAD_DATE (confirm batch ran fresh)
SELECT
    COUNT(*)        AS TOTAL_ROWS,
    MAX(LOAD_DATE)  AS LATEST_LOAD_DATE
FROM AGGNE.DEV.PER_ACCOUNT_LOC_TARGET;
-- Expected: rows > 0, LOAD_DATE = today


-- Step 2: ADDRESSOVERRIDE distribution in payload
-- Issue 2 fix: should have both 0 and 1 (not all 1)
SELECT
    CASE
        WHEN PAYLOAD ILIKE '%<AddressOverride>0</AddressOverride>%' THEN '0'
        WHEN PAYLOAD ILIKE '%<AddressOverride>1</AddressOverride>%' THEN '1'
        ELSE 'OTHER'
    END AS ADDRESSOVERRIDE_VALUE,
    COUNT(*) AS CNT
FROM AGGNE.DEV.PER_ACCOUNT_LOC_TARGET
GROUP BY 1
ORDER BY 1;
-- Expected: both '0' and '1' rows present (NOT just '1')


-- Step 3: P00005468 — RISKNUMBER order in payload
-- Issue 3 fix: RISK=1 should map to 21 Merghiny Dr (Ceduna)
SELECT
    REGEXP_SUBSTR(PAYLOAD, '<Number>(.*?)</Number>', 1, 1, 'e', 1)   AS RISKNUMBER,
    REGEXP_SUBSTR(PAYLOAD, '<Address1>(.*?)</Address1>', 1, 1, 'e', 1) AS ADDRESS1,
    REGEXP_SUBSTR(PAYLOAD, '<City>(.*?)</City>', 1, 1, 'e', 1)        AS SUBURB,
    REGEXP_SUBSTR(PAYLOAD, '<AddressOverride>(.*?)</AddressOverride>', 1, 1, 'e', 1) AS ADDRESSOVERRIDE
FROM AGGNE.DEV.PER_ACCOUNT_LOC_TARGET
WHERE ID LIKE 'P00005468%'
ORDER BY RISKNUMBER;
-- Expected:
--   RISK=1  21 Merghiny Dr       CEDUNA   OVERRIDE=0
--   RISK=2  Lot 2A Point Sinclair Rd  PENONG  OVERRIDE=1
--   RISK=3  Lot 2B Point Sinclair Rd  PENONG  OVERRIDE=1


-- Step 4: Sanity — no rows should have unresolved {ADDRESSOVERRIDE} token
SELECT COUNT(*) AS UNRESOLVED_TOKEN_ROWS
FROM AGGNE.DEV.PER_ACCOUNT_LOC_TARGET
WHERE PAYLOAD ILIKE '%{ADDRESSOVERRIDE}%';
-- Expected: 0
