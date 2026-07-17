-- G-BP-93 (ATP-10980 / G-BP-16b) — Additional Interest: LINE-tied parties dropped by a stale flag
-- AOI_FINAL (SEQ 2)
--
-- ROOT CAUSE (fully traced 2026-07-13, resolving the "not yet resolved which" open question left in
-- the original G-BP-16b note):
--
-- AOI_FINAL's LINE_VALUE CASE gates each line tie on a flag from BUSINESSDETAILS_FINAL (t3), e.g.
-- `WHEN RAW_LINE_VALUE='Products And Public Liability' AND t3.PUBLICANDPRODUCTLIABILITY=1 THEN ...`.
-- When the flag is 0/NULL, LINE_VALUE goes NULL and (if LOC_VALUE is also NULL) the whole
-- interested-party row is dropped by the final WHERE.
--
-- Checked BOTH populations empirically against the real coverage-presence ground truth:
--   LOCATION-tied drops (BusinessBuildings/Contents/Burglary/BusinessInterruption/Engineering/
--   Money, gated on LOCATION_01's flags): 224 dropped rows checked against the true per-type
--   staging tables (LOCATION_BB/BC/BG/BI/EN/MONEY_COVERAGE) -- 0 of 224 have real coverage.
--   LOCATION_01's flags are CORRECT. These drops are correct-by-design (stale ties in Pure) --
--   NOT touched by this fix.
--
--   LINE-tied drops (gated on BUSINESSDETAILS_FINAL's flags): 258 dropped rows checked against the
--   real LINE_xx_Target tables (the same tables VW_CBP_OUTPUT_CONVERSION itself reads for
--   PUBLICANDPRODUCTLIABILITY/GENERALPROPERTY/etc.) -- 213 of 258 (82.6%) DO have real coverage:
--     Products And Public Liability: 179 dropped, 160 (89.4%) should be restored
--     Stock Vehicles:                 35 dropped,  27 (77.1%) should be restored
--     Professional Protection:        20 dropped,  11 (55.0%) should be restored
--     Tax Audit:                       6 dropped,   5 (83.3%) should be restored
--     Customer Vehicles:               5 dropped,   5 (100%)  should be restored
--     General Property:                9 dropped,   4 (44.4%) should be restored
--     Goods In Transit:                2 dropped,   1 (50.0%) should be restored
--     Legal Expenses:                  2 dropped,   0 (0.0%)
--   BUSINESSDETAILS_FINAL's line-presence flags are the broken signal -- LINE_xx_Target row
--   existence is the reliable one (same source the master output view already trusts).
--
-- FIX: replace the 8 `t3.<FLAG>=1` conditions in the LINE_VALUE CASE with EXISTS checks against
-- the real LINE_xx_Target tables (matched on bare PUREPOLICYNUMBER, same key shape
-- VW_CBP_OUTPUT_CONVERSION already uses via SPLIT_PART(ID,'|',1)). LOC_VALUE's 6 conditions are
-- UNCHANGED (confirmed correct-by-design above). The G-BP-16a NO_LOC_LINE branch (3rd OR in the
-- final WHERE) is UNCHANGED.
--
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.

create or replace view AOI_FINAL(
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
-- FIX (G-BP-93 / G-BP-16b): real per-line coverage presence, keyed on bare PUREPOLICYNUMBER --
-- replaces BUSINESSDETAILS_FINAL's unreliable per-line flags below.
line_ppl AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_PPL_Target WHERE ITR_TYPE='BP_LINE_PPL'),
line_gp  AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_GP_Target  WHERE ITR_TYPE='BP_LINE_GP'),
line_sv  AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_SV_Target  WHERE ITR_TYPE='BP_LINE_SV'),
line_pf  AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_PF_Target  WHERE ITR_TYPE='BP_LINE_PF'),
line_cv  AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_CV_Target  WHERE ITR_TYPE='BP_LINE_CV'),
line_ta  AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_TA_Target  WHERE ITR_TYPE='BP_LINE_TA'),
line_gt  AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_GT_Target  WHERE ITR_TYPE='BP_LINE_GT'),
line_le  AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS PUREPOLICYNUMBER FROM AGGNE.DEV.LINE_LE_Target  WHERE ITR_TYPE='BP_LINE_LE'),
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
-- UNCHANGED (confirmed correct-by-design 2026-07-13): LOCATION_01's flags matched real coverage
-- presence exactly (0 of 224 dropped rows disagreed) -- these 6 branches are not touched.
CASE WHEN T1.RAW_LOC_VALUE= 'Business Buildings' and t2.BUSINESSBUILDINGS=1 THEN 'BusinessBuilding'
 WHEN T1.RAW_LOC_VALUE= 'Business Contents'  and t2.BUSINESSCONTENTS=1 THEN 'BusinessContents'
 WHEN T1.RAW_LOC_VALUE= 'Burglary' and t2.BURGLARY=1  THEN 'Burglary'
 WHEN T1.RAW_LOC_VALUE= 'Business Interruption' and t2.BUSINESSINTERRUPTION=1 THEN 'BusinessInterruption'
 WHEN T1.RAW_LOC_VALUE= 'Engineering' AND T2.ENGINEERING=1 THEN 'Engineering'
 WHEN T1.RAW_LOC_VALUE= 'Money' and T2.MONEY =1 THEN 'Money' ELSE null END AS LOC_VALUE,
-- FIX (G-BP-93 / G-BP-16b): each t3.<FLAG>=1 replaced with the real LINE_xx_Target presence check.
CASE WHEN T1.RAW_LINE_VALUE= 'Products And Public Liability' and line_ppl.PUREPOLICYNUMBER is not null  THEN 'PublicandProductLiability'
 WHEN T1.RAW_LINE_VALUE='General Property'  and line_gp.PUREPOLICYNUMBER is not null  THEN 'GeneralProperty'
 WHEN T1.RAW_LINE_VALUE= 'Stock Vehicles'  and line_sv.PUREPOLICYNUMBER is not null  THEN 'StockVehicle'
 WHEN T1.RAW_LINE_VALUE='Professional Protection' and line_pf.PUREPOLICYNUMBER is not null   THEN 'ProfessionalProtection'
 WHEN T1.RAW_LINE_VALUE= 'Customer Vehicles' and line_cv.PUREPOLICYNUMBER is not null   THEN 'CustomerVehicle'
 WHEN T1.RAW_LINE_VALUE= 'Tax Audit' and line_ta.PUREPOLICYNUMBER is not null THEN 'TaxAudit'
 WHEN T1.RAW_LINE_VALUE='Goods In Transit'  and line_gt.PUREPOLICYNUMBER is not null THEN 'GoodsInTransit'
 WHEN T1.RAW_LINE_VALUE='Legal Expenses'  and line_le.PUREPOLICYNUMBER is not null THEN 'LegalExpenses' ELSE NUll END AS LINE_VALUE,
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
T1.RAW_LOC_VALUE, T1.RAW_LINE_VALUE
FROM
CTE1 T1 LEFT JOIN CTE2 T2 ON T1.ID=T2.ID
LEFT JOIN CTE3 T3 ON T3.ID=T2.ID
LEFT JOIN line_ppl ON TRIM(line_ppl.PUREPOLICYNUMBER) = TRIM(T1.RAW_PUREPOLICYNUMBER)
LEFT JOIN line_gp  ON TRIM(line_gp.PUREPOLICYNUMBER)  = TRIM(T1.RAW_PUREPOLICYNUMBER)
LEFT JOIN line_sv  ON TRIM(line_sv.PUREPOLICYNUMBER)  = TRIM(T1.RAW_PUREPOLICYNUMBER)
LEFT JOIN line_pf  ON TRIM(line_pf.PUREPOLICYNUMBER)  = TRIM(T1.RAW_PUREPOLICYNUMBER)
LEFT JOIN line_cv  ON TRIM(line_cv.PUREPOLICYNUMBER)  = TRIM(T1.RAW_PUREPOLICYNUMBER)
LEFT JOIN line_ta  ON TRIM(line_ta.PUREPOLICYNUMBER)  = TRIM(T1.RAW_PUREPOLICYNUMBER)
LEFT JOIN line_gt  ON TRIM(line_gt.PUREPOLICYNUMBER)  = TRIM(T1.RAW_PUREPOLICYNUMBER)
LEFT JOIN line_le  ON TRIM(line_le.PUREPOLICYNUMBER)  = TRIM(T1.RAW_PUREPOLICYNUMBER)
)
)
SELECT PUREPOLICYNUMBER, EXPIRINGID_P, CMLNUMBER, EXPIRYDATE, ADDITIONALINTDETS, LOC_VALUE, LINE_VALUE,
       RISKNUMBER, LOC_ADDRESS, LOC_SUB, LOC_POSTCODE, LOC_STATE, COUNTRY,
       ADDITIONALINTERESTLOC, ADDITIONALINTERESTLINE
FROM tied_and_untied
WHERE LOC_VALUE is not null
   OR LINE_VALUE is not null
   OR (COALESCE(TRIM(RAW_LOC_VALUE),'') = '' AND COALESCE(TRIM(RAW_LINE_VALUE),'') = '')
;

-- ============================================================
-- POST-CHECK 1: row count should increase by roughly 213 (the genuine line-tie restorations)
-- ============================================================
-- SELECT COUNT(*) FROM AGGNE.DEV.AOI_FINAL;
-- Baseline before this fix: 4,897 (post G-BP-16a). Expect ~5,110.

-- POST-CHECK 2: spot-check a known-affected policy shows its line tie restored
-- (pick any PUREPOLICYNUMBER from the quantification query with RAW_LINE_VALUE='Products And
--  Public Liability' that previously dropped -- confirm LINE_VALUE is no longer NULL)

-- POST-CHECK 3: confirm the location side is still untouched (should still be 0 restored)
-- SELECT COUNT(*) FROM AGGNE.DEV.AOI_FINAL WHERE LOC_VALUE = 'BusinessBuilding';
-- Should match the pre-fix count exactly -- this fix does not change LOC_VALUE logic at all.
