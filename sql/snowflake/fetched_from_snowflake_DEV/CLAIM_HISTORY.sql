create or replace view CLAIM_HISTORY(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	EXPIRINGID_P,
	DATEOFCLAIM,
	AMOUNTPAID,
	LINE,
	CAUSE
) as
select CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,cmlnumber,expiringid_p,CAST(dateofclaim AS VARCHAR) AS dateofclaim,CAST(amountpaid AS VARCHAR) AS amountpaid, line,cause from AGGNE.DEV.CLAIMHISTORY;