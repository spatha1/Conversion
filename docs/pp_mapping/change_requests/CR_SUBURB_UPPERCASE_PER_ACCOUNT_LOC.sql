-- CR: Suburb/City must be uppercase - policy team expects consistent case, requested 2026-07-13.
--
-- RCA: confirmed live in AGGNE.DEV.Locationdetails_PER (raw Pure source) - 677 of 4,996 (13.5%)
-- SUBURB values are already mixed/Title case at the source (e.g. 'Norwood', 'Tauranga', 'Acton'),
-- not something introduced by conversion. PER_ACCOUNT_LOC passes T1.SUBURB straight through with
-- no case normalization, so the real generated XML inherits the same inconsistency: of 3,939
-- policies' primary (Location 1) <City> values, 529 (13.4%) are mixed-case instead of uppercase.
-- Same pattern on secondary locations (Location 2-9).
--
-- Not a client-data-quality question -- this is a simple, safe display-normalization fix (no
-- ambiguity, no business rule needed), so applying UPPER() directly rather than raising a client
-- question.
--
-- Fix: wrap SUBURB in UPPER() at the one place it's selected into the final view (line ~51 of the
-- current view, T1.SUBURB -> T1.SUBURB unchanged elsewhere in the CTEs, only the final SELECT
-- needs the wrap since that's the one column actually returned to callers).
--
-- Verified before drafting (per "verify live, not repo" discipline): pulled the current DDL fresh
-- via GET_DDL('VIEW', 'AGGNE.DEV.PER_ACCOUNT_LOC') this session - only one line changes.
--
-- STATUS: Fixed - pending redeploy for next batch. Not yet applied to the live 46-policy UAT batch
-- below; these are known issues in that batch until this view is redeployed and the batch re-run.
--
-- Known issues (2026-07-13 UAT batch) - lowercase/mixed-case City, will be corrected once this
-- fix is deployed and the batch re-run:
--   Quote        Policy        Location   City value (as generated)
--   Q0114999     P00034443     1          Rangiuru
--   Q0115003     P00018499     1          Spotswood
--   Q0114994     P00030171     1          Normanby
--   Q0115016     P00034447     1          Te Puke
--   Q0115015     P00000371     2          Cannington
--   Q0114995     P00018498     1          Spotswood
--   Q0115007     P00034444     1          Rangiuru

CREATE OR REPLACE VIEW PER_ACCOUNT_LOC(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	RISKNUMBER,
	STATE,
	ADDRESS1,
	SUBURB,
	POSTCODE,
	LOC_COUNTRY,
	ADDRESSOVERRIDE
) as
WITH cte1 as
(
SELECT  CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS ID,
T1.* FROM AGGNE.DEV.Locationdetails_PER T1 inner join AGGNE.DEV.SAMPLE_PER T2 on t1.PUREPOLICYNUMBER=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P
WHERE   T1.EFFECTIVEDATE >= '2026-01-01'
),
cte2  AS (
SELECT CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
TRIM(PUREPOLICYNUMBER) as LEGACYPOLICYNUMBER,
STATE,
ADDRESS1,
SUBURB,
CAST(POSTCODE AS VARCHAR) AS POSTCODE,
-- CAST(COALESCE(GNAFPID ,'0')AS VARCHAR) AS GNAFPID,
COUNTRY,
-- LOCATIONANZSICCODE,
EXPIRINGID_P,
-- Fix ATP-9746 Issue 3: use source RISKNUMBER instead of ROW_NUMBER() to preserve the
-- original location ordering (EXPIRINGID_P order != RISKNUMBER order for multi-period policies)
CAST(COALESCE(CAST(RISKNUMBER AS NUMBER(10,0)), 0) AS VARCHAR) AS RISKNUMBER,
-- PP-CF-25 (2026-07-02, supersedes ATP-9746 Issue 2): AddressOverride must be 1 for ALL
-- converted locations, per Aggne QA. Converted addresses never pass Duck Creek address
-- validation, so OVERRIDE=0 (83% of in-scope source rows) triggers the blocking alert
-- "One or more locations are neither validated nor overridden" and prevents navigation
-- past the Locations screen. Source OVERRIDE column intentionally ignored:
-- CAST(COALESCE(OVERRIDE, 0) AS VARCHAR)  -- ATP-9746 Issue 2 mapping, kept for reference
CAST('1' AS VARCHAR) AS ADDRESSOVERRIDE
FROM AGGNE.DEV.Locationdetails_PER
)
SELECT
T1.PUREPOLICYNUMBER,
-- T1.LOCATIONANZSICCODE,
LEGACYPOLICYNUMBER,
T1.RISKNUMBER,
CASE
    WHEN TRIM(T1.COUNTRY) = 'New Zealand' THEN T1.STATE
    WHEN TRIM(T1.COUNTRY) = 'Australia' AND T1.STATE IS NOT NULL THEN CONCAT(T1.STATE, 'AU')
    ELSE T1.STATE end as STATE,
T1.ADDRESS1,
UPPER(T1.SUBURB) AS SUBURB,   -- CR 2026-07-13: policy team expects uppercase; 13.5% of Pure source values are mixed-case
-- CAST(COALESCE(T1.GNAFPID ,'0')AS VARCHAR) AS GNAFPID,
CAST(T1.POSTCODE AS VARCHAR) AS POSTCODE,
CASE
    WHEN TRIM(T1.COUNTRY) = 'New Zealand' THEN 'NZ'
    WHEN TRIM(T1.COUNTRY) = 'Australia' THEN 'AU'
    ELSE TRIM(T1.COUNTRY) END AS LOC_COUNTRY,
T1.ADDRESSOVERRIDE
FROM ctE2 T1 INNER JOIN  CTE1 T2  ON T1.PUREPOLICYNUMBER=T2.ID ;

-- Verify after deploy:
SELECT COUNT(*) TOTAL,
    SUM(CASE WHEN SUBURB = UPPER(SUBURB) THEN 1 ELSE 0 END) NOW_UPPER
FROM AGGNE.DEV.PER_ACCOUNT_LOC
WHERE SUBURB IS NOT NULL AND TRIM(SUBURB) != '';
-- Expected: TOTAL = NOW_UPPER (100%)
