-- ============================================================
-- G-BP-16a fix -- Additional Interest: parties with no Location/Line tie
-- silently dropped (seq 2, P1, code-only, SAS-verified)
-- VERIFIED against live Snowflake (2026-07-10) + client's original SAS
-- (SAS/txt/Additional interested conversionscriptCapricorn.txt).
-- NOT YET APPLIED.
-- ============================================================

-- ---------- ROOT CAUSE ----------
-- AGGNE.DEV.AOI_FINAL's final filter:
--   WHERE LOC_VALUE is not null or LINE_VALUE is not null
-- drops every interested party that isn't tied to a specific Location or Line coverage in Pure
-- (e.g. a Finance-only party). The client's original SAS explicitly handles this as a third,
-- separate branch ("Step 3: when no location or line coverage listed but interested party
-- listed" -> NO_LOC_LINE), unioned into the final output alongside the location-tied (AI_02) and
-- line-tied (AI_03) branches. That third branch was never ported to Snowflake.
--
-- Live counts (2026-07-10): 5,647 raw AOI records -> 4,897 survive (750 dropped, 13.3%);
-- 350 of 2,847 policies lose ALL their AOI records. 267 of the dropped rows are this exact
-- no-tie case (confirmed against ATP-10980's policy P00010027 -- "Australia and New Zealand
-- Banking Group Ltd : Finance" has no coverage type in Pure at all and vanishes from the UI).

-- ---------- VIEW FIX ----------
-- sql/snowflake/1_conversion/BP/views/AOI_FINAL.sql (also live in AGGNE.DEV)
-- Add a third UNION ALL branch for parties whose RAW (pre-match) LOC_VALUE and LINE_VALUE are
-- both blank -- i.e. they never claimed a Location or Line tie in Pure to begin with. These
-- should pass through with blank AddLocationProperty/AddLineProtection (both '0') and blank
-- LocationProtectionSection/LineProtectionSection, matching the client's NO_LOC_LINE branch.
--
-- The existing view aliases both the raw ADDITIONAL_INTEREST.LOC_VALUE/LINE_VALUE columns and the
-- CASE-derived output as "LOC_VALUE"/"LINE_VALUE" in the same query -- rewritten below with the
-- raw columns explicitly renamed (RAW_LOC_VALUE/RAW_LINE_VALUE) to avoid ambiguity, so this fix is
-- safe to apply without disturbing the two existing branches.

create or replace view AGGNE.DEV.AOI_FINAL(
	PUREPOLICYNUMBER,
	EXPIRINGID_P,
	CMLNUMBER,
	EXPIRYDATE,
	ADDITIONALINTDETS,
	LOC_VALUE,
	LINE_VALUE,
	RISKNUMBER,
	LOC_ADDRESS,
	LOC_SUB,
	LOC_POSTCODE,
	LOC_STATE,
	COUNTRY,
	ADDITIONALINTERESTLOC,
	ADDITIONALINTERESTLINE
) as
with cte1 as(
SELECT CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS ID,
       PUREPOLICYNUMBER AS RAW_PUREPOLICYNUMBER, cmlnumber AS RAW_CMLNUMBER, EXPIRINGID_P AS RAW_EXPIRINGID_P,
       EXPIRYDATE AS RAW_EXPIRYDATE, ADDITIONALINTDETS AS RAW_ADDITIONALINTDETS,
       LOC_VALUE AS RAW_LOC_VALUE, LINE_VALUE AS RAW_LINE_VALUE
FROM AGGNE.DEV.ADDITIONAL_INTEREST where EXPIRYDATE >= '2026-01-01'
),
cte2 as (
SELECT  CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID) AS VARCHAR) AS ID,
t1.* ,
CAST(CAST(ROW_NUMBER() OVER (PARTITION BY T1.PUREPOLICYNUMBER ORDER BY t1.EXPIRINGID)AS NUMBER(10,0)) AS VARCHAR) AS RISKNUMBER
FROM AGGNE.DEV.LOCATION_01 T1
),
cte3 as (
SELECT  CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID) AS VARCHAR) AS ID,
t1.*
FROM AGGNE.DEV.BUSINESSDETAILS_FINAL T1
),
tied_and_untied as (
 SELECT *,
 CASE WHEN LOC_VALUE is not null THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS ADDITIONALINTERESTLOC,
 CASE WHEN LINE_VALUE is not null THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS ADDITIONALINTERESTLINE
 FROM (
SELECT
T1.ID AS PUREPOLICYNUMBER,
CAST(T1.RAW_EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
T1.RAW_CMLNUMBER AS CMLNUMBER,
CAST(T1.RAW_EXPIRYDATE AS VARCHAR) AS EXPIRYDATE,
REPLACE (T1.RAW_ADDITIONALINTDETS,'&','&amp;') AS ADDITIONALINTDETS ,
CASE WHEN T1.RAW_LOC_VALUE= 'Business Buildings' and t2.BUSINESSBUILDINGS=1 THEN 'BusinessBuilding'
 WHEN T1.RAW_LOC_VALUE= 'Business Contents'  and t2.BUSINESSCONTENTS=1 THEN 'BusinessContents'
 WHEN T1.RAW_LOC_VALUE= 'Burglary' and t2.BURGLARY=1  THEN 'Burglary'
 WHEN T1.RAW_LOC_VALUE= 'Business Interruption' and t2.BUSINESSINTERRUPTION=1 THEN 'BusinessInterruption'
 WHEN T1.RAW_LOC_VALUE= 'Engineering' AND T2.ENGINEERING=1 THEN 'Engineering'
 WHEN T1.RAW_LOC_VALUE= 'Money' and T2.MONEY =1 THEN 'Money' ELSE null END AS LOC_VALUE,
CASE WHEN T1.RAW_LINE_VALUE= 'Products And Public Liability' and t3.PUBLICANDPRODUCTLIABILITY=1  THEN 'PublicandProductLiability'
 WHEN T1.RAW_LINE_VALUE='General Property'  and t3.GENERALPROPERTY=1  THEN 'GeneralProperty'
 WHEN T1.RAW_LINE_VALUE= 'Stock Vehicles'  and t3.STOCKVEHICLES=1  THEN 'StockVehicle'
 WHEN T1.RAW_LINE_VALUE='Professional Protection' and t3.PROFESSIONALPROTECTION=1   THEN 'ProfessionalProtection'
 WHEN T1.RAW_LINE_VALUE= 'Customer Vehicles' and t3.CUSTOMERVEHICLE=1   THEN 'CustomerVehicle'
 WHEN T1.RAW_LINE_VALUE= 'Tax Audit' and t3.TAXAUDIT=1 THEN 'TaxAudit'
 WHEN T1.RAW_LINE_VALUE='Goods In Transit'  and t3.GOODSINTRANSIT=1 THEN 'GoodsInTransit'
 WHEN T1.RAW_LINE_VALUE='Legal Expenses'  and t3.LEGALEXPENSES THEN 'LegalExpenses' ELSE NUll END AS LINE_VALUE,
CAST(t2.RISKNUMBER AS VARCHAR) AS RISKNUMBER,
T2.ADDRESS1 AS LOC_ADDRESS,
CAST(T2.SUBURB AS VARCHAR) AS LOC_SUB,
T2.POSTCODE AS LOC_POSTCODE,
CASE
    WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN T2.STATE
    WHEN TRIM(T2.COUNTRY) = 'Australia' THEN CONCAT(T2.STATE, 'AU')
    ELSE T2.STATE end AS LOC_STATE,
CASE
    WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN 'NZ'
    WHEN TRIM(T2.COUNTRY) = 'Australia' THEN 'AU'
    ELSE TRIM(T2.COUNTRY) END AS COUNTRY,
-- carry the RAW pre-match values through so the outer filter can distinguish
-- "genuinely no tie in Pure" (G-BP-16a, NO_LOC_LINE branch) from
-- "had a tie but the flag check failed" (G-BP-16b, still open, still excluded here)
T1.RAW_LOC_VALUE, T1.RAW_LINE_VALUE
FROM
CTE1 T1 LEFT JOIN CTE2 T2 ON T1.ID=T2.ID
LEFT JOIN CTE3 T3 ON T3.ID=T2.ID
)
)
SELECT PUREPOLICYNUMBER, EXPIRINGID_P, CMLNUMBER, EXPIRYDATE, ADDITIONALINTDETS, LOC_VALUE, LINE_VALUE,
       RISKNUMBER, LOC_ADDRESS, LOC_SUB, LOC_POSTCODE, LOC_STATE, COUNTRY,
       ADDITIONALINTERESTLOC, ADDITIONALINTERESTLINE
FROM tied_and_untied
WHERE LOC_VALUE is not null
   OR LINE_VALUE is not null
   -- NEW: G-BP-16a -- pass through parties that never claimed a Location or Line tie in Pure at
   -- all (client's SAS "NO_LOC_LINE" branch). Does NOT change behavior for G-BP-16b's rows (those
   -- had a raw value that failed the flag match -- still excluded, tracked separately).
   OR (COALESCE(TRIM(RAW_LOC_VALUE),'') = '' AND COALESCE(TRIM(RAW_LINE_VALUE),'') = '')
;

-- ---------- Verify before applying ----------
-- SELECT COUNT(*) AS TOTAL FROM AGGNE.DEV.ADDITIONAL_INTEREST WHERE EXPIRYDATE >= '2026-01-01';
-- SELECT COUNT(*) AS SURVIVORS_BEFORE FROM AGGNE.DEV.AOI_FINAL;  -- expect 4,897 before this fix

-- ---------- Verify after applying ----------
-- SELECT COUNT(*) AS SURVIVORS_AFTER FROM AGGNE.DEV.AOI_FINAL;
-- -- target: 4,897 + 267 = 5,164 (the 267 confirmed no-tie rows now included;
-- -- the 349 flag-mismatch rows from G-BP-16b remain excluded, separate open gap)
-- SELECT * FROM AGGNE.DEV.AOI_FINAL WHERE PUREPOLICYNUMBER LIKE 'P00010027%';
-- -- target: 3 rows now (was 2), including "Australia and New Zealand Banking Group Ltd : Finance"

-- ---------- Companion ----------
-- This same view redefinition also carries G-BP-16c's 3 string-literal corrections
-- (PublicandProductLiability / StockVehicle / CustomerVehicle) -- see fixes/G-BP-16c_fix.sql for
-- the isolated diff if you want to apply that piece separately.
