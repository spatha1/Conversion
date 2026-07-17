create or replace view HB_CLAUSE(
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
-- NEW: caption -> manuscript code lookup (Carrier_PP_AU_VM_1_0_0_0, BuildingRiskClausesInput.SelectClause options)
CASE TRIM(DCCLAUSETYPE)
    WHEN 'HB Excess free glass claims'                     THEN 'HBExcessfreeglassclaims'
    WHEN 'HB Unattended building'                          THEN 'HBUnattendedbuilding'
    WHEN 'HB Inclusion of jetty'                            THEN 'HBInclusionofjetty'
    WHEN 'HB Domestic liability'                            THEN 'HBDomesticliability'
    WHEN 'HB Additional benefit increase - Part B, 8'      THEN 'HBAdditionalbenefitincreasePartB8'
    WHEN 'HB Additional benefit increase - Part B, 9'      THEN 'HBAdditionalbenefitincreasePartB9'
    WHEN 'HB Retaining walls extension'                     THEN 'HBRetainingwallsextension'
    WHEN 'HB Solar cells extension'                         THEN 'HBSolarcellsextension'
    WHEN 'HB Definition limitation'                         THEN 'HBDefinitionlimitation'
    ELSE NULL  -- unmapped caption -- surfaces as blank Type rather than sending a wrong/guessed code
END AS DCCLAUSECODE,
REPLACE(REPLACE(REPLACE(CAST(DCINPUT AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
FROM AGGNE.DEV.CLAUSES T1
INNER  JOIN AGGNE.DEV.HB_02 T2 ON trim(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND TRIM(T1.PUREPOLICYBINDERID)=TRIM(T2.EXPIRINGID_P)
WHERE T1.COVERAGE='HB' AND _IS_CURRENT='TRUE';