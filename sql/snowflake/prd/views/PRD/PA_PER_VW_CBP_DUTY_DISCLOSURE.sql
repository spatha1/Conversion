create or replace view PA_PER_VW_CBP_DUTY_DISCLOSURE(
	ID,
	ACTUALID,
	PUREPOLICYNUMBER,
	CMLNUMBER,
	EXPIRINGID_P,
	INSURANCE_FILE_CNT,
	EXPIRYDATE,
	COUNTRY,
	PRODUCT,
	CRIMINALCONVICTION,
	CRIMINALCONVICTIONDETAILS,
	REFUSEDINSURANCE,
	REFUSEDINSURANCEDETAILS
) as 
SELECT 
T1.*
FROM AGGNE.PRD.Duty_Disclosure_policyattach_IDENTIFIER t1   INNER JOIN AGGNE.PRD.Policyattach_PER_IDENTIFIER T2 ON T1.ID=T2.ID
------------------------------------------------------------------------------------------------------------------------------------------------------------------
;