create or replace view COM_CLAUSE(
	PUREPOLICYNUMBER,
	EXPIRINGID_P,
	DCCLAUSETYPE,
	DCINPUT
) as
SELECT DISTINCT
CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
CAST(EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
CAST(CLAUSE_TEXT AS VARCHAR) AS DCCLAUSETYPE,
REPLACE(REPLACE(REPLACE(CAST(CLAUSE_DESC AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
FROM AGGNE.DEV.PM_03
WHERE EXPIRYDATE>='2026-01-01'
  -- NEW: exclude garbage/placeholder clause rows (confirmed live: 'NA' and NULL both present in
  -- CLAUSE_TEXT) -- these aren't real clause selections and shouldn't be converted as if they were.
  AND CLAUSE_TEXT IS NOT NULL
  AND TRIM(CLAUSE_TEXT) <> 'NA';