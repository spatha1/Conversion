create or replace view PER_HC_CLAUSE(
	PUREPOLICYNUMBER,
	PUREPOLICYBINDERID,
	EXPIRINGID_P,
	DCCLAUSETYPE,
	DCCLAUSECODE,
	DCINPUT
) as

SELECT DISTINCT
CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
CAST(T1.PUREPOLICYBINDERID AS VARCHAR) AS PUREPOLICYBINDERID,
CAST(T2.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
CAST(DCCLAUSETYPE AS VARCHAR) AS DCCLAUSETYPE,
-- NEW: caption -> manuscript code lookup (Carrier_PP_AU_VM_1_0_0_0, HomeContentsClausesInput.SelectClause options)
CASE TRIM(DCCLAUSETYPE)
    WHEN 'HC Specified items ≥ $15k'                        THEN 'HCSpecifieditems15k'
    WHEN 'HC Unattended contents'                            THEN 'HCUnattendedcontents'
    WHEN 'HC Additional benefit increase - Part A, 4'       THEN 'HCAdditionalbenefitincreasePartA4'
    WHEN 'HC Definition extension'                           THEN 'HCDefinitionextension'
    ELSE NULL  -- unmapped caption -- surfaces as blank Type rather than sending a wrong/guessed code
END AS DCCLAUSECODE,
REPLACE(REPLACE(REPLACE(CAST(DCINPUT AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
FROM AGGNE.DEV.CLAUSES T1
INNER  JOIN AGGNE.DEV.HC_02 T2 ON trim(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND TRIM(T1.PUREPOLICYBINDERID)=TRIM(T2.EXPIRINGID_P)
WHERE T1.COVERAGE='HC' AND _IS_CURRENT='TRUE';