create or replace view VW_CLAIM_HISTORY(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	DATEOFCLAIM,
	AMOUNTPAID,
	LINE,
	CAUSE
) as 
WITH CTE1 AS(
SELECT DISTINCT
    TRIM(T1.PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
    TRIM(T1.CMLNUMBER) AS CMLNUMBER,
    TRY_TO_DATE(REGEXP_REPLACE(TRIM(T1.DATEOFCLAIM), '[A-Za-z]', ''), 'YYYY-MM-DD')AS DATEOFCLAIM,
    TO_VARCHAR(TRIM(T1.AMOUNTPAID)) AS AMOUNTPAID,
    TO_VARCHAR(TRIM(T1.LINE)) AS LINE,
    TO_VARCHAR(TRIM(T1.CAUSE)) AS CAUSE
FROM AGGNE.DEV.CLAIMHISTORY AS T1  --7592
INNER JOIN AGGNE.DEV.SAMPLE_CBP AS T2 --6869
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND T1.EXPIRINGID_P=T2.EXPIRINGID_P 
WHERE  T2.EXPIRYDATE>='2026-01-01' --5167
) SELECT DISTINCT 
    TRIM(T1.PUREPOLICYNUMBER)AS PUREPOLICYNUMBER,
    TRIM(T1.CMLNUMBER)AS CMLNUMBER,
    -- Clean and parse DATEOFCLAIM safely
    TO_CHAR(DATEOFCLAIM::DATE, 'YYYY-MM-DD') AS DATEOFCLAIM ,
    TO_VARCHAR(T1.AMOUNTPAID) AS AMOUNTPAID,
    TO_VARCHAR(T1.LINE) AS LINE,
    -- FIX US-5977: CAUSE was passed raw from PURE causing DCT dropdown mismatch.
    -- DCT Cause dropdown (PL101) accepts: Fire, Flood, Burglary, Theft, Other,
    -- CustomerPropertyDamage, CustomerInjury, AtFault, NotAtFault.
    -- PURE values with spaces are mapped to PascalCase DCT codes.
    -- Any unrecognised PURE value defaults to 'Other' (safe fallback).
    CASE TRIM(T1.CAUSE)
        WHEN 'Fire'                     THEN 'Fire'
        WHEN 'Flood'                    THEN 'Flood'
        WHEN 'Burglary'                 THEN 'Burglary'
        WHEN 'Theft'                    THEN 'Theft'
        WHEN 'Other'                    THEN 'Other'
        WHEN 'Motor'                    THEN 'Other'
        WHEN 'Customer Property Damage' THEN 'CustomerPropertyDamage'
        WHEN 'Customer Injury'          THEN 'CustomerInjury'
        WHEN 'At Fault'                 THEN 'AtFault'
        WHEN 'Not At Fault'             THEN 'NotAtFault'
        ELSE                                 'Other'
    END AS CAUSE
    FROM CTE1 T1 ;