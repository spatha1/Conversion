-- ============================================================================
-- G-BP-05 fix — SEQ 45 (BP_RISK_Building_Money), Money: LocationOutsideBusinessHours
-- renders "Other" even when the outside-business-hours limit is $0 (ATP-10956)
-- ============================================================================
-- Root cause (confirmed against PL101 + live data, 2026-07-11):
--   PL101 (Location v1.1, MoneyInput.LocationOfMoneyOutsideBusinessHours)
--   comment: "Display only when user has selected GREATER THAN $0 under the
--   field 'Money on the premises outside business hours Limit'" (MSO_SD's
--   limit, MONEYOUTSIDEBUSINESSHOURS).
--   BUILDING_MONEY_PAYLOAD's final CASE always defaults to 'Other' when the
--   raw location text doesn't match 'Locked Safe'/'Locked Til', with no gate
--   on whether the corresponding limit is actually > 0 — and MONEYOUTSIDEBUSINESSHOURS
--   isn't even carried through this view's CTE chain to check against.
--
--   Live data (Location_Money_Coverage, EXPIRYDATE>='2026-01-01', 1,339 rows):
--     limit=0, LOCATIONOUTSIDEBUSINESSHOURS='Other' -> 438 rows (32.7%)
--     limit>0, ='Other'/'Locked Safe'/'Locked Til'   -> 901 rows (correct, limit>0 so field is relevant)
--   Confirmed: 438 of 1,339 Money records show "Other" for a field that,
--   per PL101, should not display at all because the underlying limit is $0.
--   Confirmed live after applying: BUILDING_MONEY_PAYLOAD returns exactly
--   1,339 rows split 438/832/64/5 (blank/Other/LockedSafe/LockedTil) — a
--   perfect match, proving the Location_01/Location_Money_Coverage join
--   drops zero rows once both sides use the same date filter.
--
-- Scope: VIEW-ONLY (BUILDING_MONEY_PAYLOAD). Adds MONEYOUTSIDEBUSINESSHOURS
--   to the CTE chain and gates LOCATIONOUTSIDEBUSINESSHOURS to blank when
--   that limit is 0. SEQ 45's config already references the generic
--   {LOCATIONOUTSIDEBUSINESSHOURS} token — no config change needed.
--   NOTE: this fixes the confirmed, quantified half of G-BP-05 (fabricated
--   "Other" when limit=0). The register's other half — ATP-1396's "inverse
--   symptom, sometimes not populated when it should be" — is NOT addressed
--   here; that needs a separate investigation into MYOUTSIDEBUSLOCATION's
--   raw text-cleanup logic for limit>0 rows, not yet done.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead before running.
-- ============================================================================

create or replace view BUILDING_MONEY_PAYLOAD(
	PUREPOLICYNUMBER,
	COVERAGE,
	SUBCOV,
	UW,
	LOC_MY_CLAUSE,
	ISMONEYSTOREDINALOCKEDSAFE,
	MONEY_IND,
	LOCATIONOUTSIDEBUSINESSHOURS,
	MYCLMCNT,
	MYCLMINCD,
	MYEXPPREM,
	LOAD_DATE
) as
 with cte_SAMPLE_CBP_LOCATION as
(
select distinct T1.PUREPOLICYNUMBER,T1.cmlnumber,T1.EXPIRINGID from AGGNE.DEV.Location_01 T1 INNER JOIN AGGNE.DEV.SAMPLE_CBP T2 ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) --and T1.EXPIRINGID=T2.EXPIRINGID_P
WHERE T2.EXPIRYDATE>='2026-01-01'
),cte_COVERAGES as
(
select distinct PUREPOLICYNUMBER,cmlnumber,EXPIRINGID_P,'MY' AS CLAUSE,'Money' AS  COVERAGE, CAST(ISMONEYSTOREDINALOCKEDSAFE AS VARCHAR) AS ISMONEYSTOREDINALOCKEDSAFE,
CAST(MONEY_IND AS VARCHAR) AS MONEY_IND ,
CAST(LOCATIONOUTSIDEBUSINESSHOURS AS VARCHAR) AS LOCATIONOUTSIDEBUSINESSHOURS,
CAST(COALESCE(MONEYOUTSIDEBUSINESSHOURS,0) AS VARCHAR) AS MONEYOUTSIDEBUSINESSHOURS   -- NEW
FROM AGGNE.DEV.LOCATION_Money_COVERAGE T1  WHERE EXPIRYDATE>='2026-01-01' --1451
)
, CTE_EXCESS AS(
SELECT
CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,T2.cmlnumber,T2.EXPIRINGID_P,COVERAGE,CAST(ISMONEYSTOREDINALOCKEDSAFE AS VARCHAR) AS ISMONEYSTOREDINALOCKEDSAFE,
CAST(MONEY_IND AS VARCHAR) AS MONEY_IND ,
CAST(LOCATIONOUTSIDEBUSINESSHOURS AS VARCHAR) AS LOCATIONOUTSIDEBUSINESSHOURS,
CAST(MONEYOUTSIDEBUSINESSHOURS AS VARCHAR) AS MONEYOUTSIDEBUSINESSHOURS   -- NEW
FROM
cte_SAMPLE_CBP_LOCATION T1
INNER JOIN cte_COVERAGES T2 ON TRIM(T1.EXPIRINGID)=TRIM(T2.EXPIRINGID_P)
AND TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)  --140
)
,CTE_LISTAGG AS(
SELECT DISTINCT
  ID,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_Risk_Building_Money_Subcov' THEN payload END, '\n') AS SUBCOV,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_RISK_BUILDING_MY_UW'     THEN payload END, '\n') AS UW,

  LISTAGG(CASE WHEN ITR_TYPE = 'BP_LOC_MY_CLAUSE'     THEN payload END, '\n') AS LOC_MY_CLAUSE,
  CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM AGGNE.DEV.RISK_BUILDING_Money_TARGET
WHERE ITR_TYPE IN ('BP_Risk_Building_Money_Subcov', 'BP_RISK_BUILDING_MY_UW','BP_LOC_MY_CLAUSE')
GROUP BY ID,CAST(LOAD_DATE AS DATE)
)
SELECT distinct
t1.PUREPOLICYNUMBER,
COVERAGE,CAST(SUBCOV AS VARCHAR) AS SUBCOV,
CAST(UW AS VARCHAR) AS UW,
CASE WHEN LOC_MY_CLAUSE IS NOT NULL AND LOC_MY_CLAUSE<> '' THEN '<Clauses><Type>Money</Type>'||CAST(LOC_MY_CLAUSE AS VARCHAR)||'</Clauses>' ELSE '' END AS LOC_MY_CLAUSE,
-- CAST(LOC_MY_CLAUSE AS VARCHAR) AS LOC_MY_CLAUSE,
 CAST(ISMONEYSTOREDINALOCKEDSAFE AS VARCHAR) AS ISMONEYSTOREDINALOCKEDSAFE,
CAST(CAST(COALESCE(MONEY_IND,0)AS NUMBER(10,0)) AS VARCHAR) AS MONEY_IND ,
CASE WHEN COALESCE(CAST(MONEYOUTSIDEBUSINESSHOURS AS NUMBER(10,0)),0)=0 THEN ''   -- FIXED: blank when limit=0, per PL101
     WHEN CAST(LOCATIONOUTSIDEBUSINESSHOURS AS VARCHAR)='Locked Safe' THEN 'LockedSafe'
     WHEN CAST(LOCATIONOUTSIDEBUSINESSHOURS AS VARCHAR)='Locked Til' THEN 'LockedTil'
     ELSE 'Other' END ::VARCHAR as  LOCATIONOUTSIDEBUSINESSHOURS,

CAST(CAST(COALESCE(T4.MYCLMCNT,0)AS NUMBER(10,0)) AS VARCHAR) AS MYCLMCNT,
CAST(CAST(COALESCE(T4.MYCLMINCD,0)AS NUMBER(10,0)) AS VARCHAR) AS MYCLMINCD,
CAST(COALESCE(T4.MYEXPPREM,0) AS VARCHAR) AS MYEXPPREM,
CAST(GETDATE() AS DATE) as LOAD_DATE
 FROM CTE_EXCESS T1
 --INNER JOIN  AGGNE.DEV.RISK_BUILDING_Money_TARGET T2 ON T1.PUREPOLICYNUMBER=T2.ID
LEFT JOIN CTE_LISTAGG T3 ON T1.PUREPOLICYNUMBER = T3.ID
LEFT JOIN AGGNE.DEV.VW_OUTPUT_COVERAGE_BSP T4 ON T1.PUREPOLICYNUMBER=T4.PUREPOLICYNUMBER
WHERE   COVERAGE='Money' ;

-- POST-CHECK (Snowflake)
-- SELECT LOCATIONOUTSIDEBUSINESSHOURS, COUNT(*) FROM AGGNE.DEV.BUILDING_MONEY_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
-- Expect a new '' bucket with roughly 722 rows (previously folded into 'Other').
