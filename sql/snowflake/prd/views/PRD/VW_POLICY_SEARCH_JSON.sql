create or replace view VW_POLICY_SEARCH_JSON(
	POLICYNUMBER,
	PAYLOAD,
	POLICYEFFECTIVEDATE,
	POLICYEXPIRATIONDATE
) as
SELECT DISTINCT 
  PUREPOLICYNUMBER as POLICYNUMBER ,
  ARRAY_CONSTRUCT(
    OBJECT_CONSTRUCT(
      'externalPolicySearchID', T1.EXTERNALPOLICYSEARCHID,
      'defaultCurrency', T1.DEFAULTCURRENCY,
      'manuscriptID', T1.MANUSCRIPTID,
      'policyMappedLOB', CASE 
                    WHEN UPPER(policysearchtype) = 'BSP' THEN 'CarrierBusinessPackage'
                    WHEN UPPER(policysearchtype) = 'PER'  THEN 'CarrierPersonalPackage'
                    ELSE POLICYMAPPEDLOB
                 END,
      'policyNumber', T1.PUREPOLICYNUMBER,
      'policyEffectiveDate',TO_CHAR(CAST(T2.EFFECTIVEDATE AS DATE), 'YYYY-MM-DD'),
      'policyExpirationDate',TO_CHAR(CAST(T2.EXPIRATIONDATE AS DATE), 'YYYY-MM-DD'),
      'claimsMadePolicy', NULL,
      'organizationName', T1.ORGANIZATIONNAME,
      'firstName', T1.FIRSTNAME,
      'middleName', NULL,
      'lastName', T1.LASTNAME,
      'street', T1.STREET,
      'additionalAddress1', T1.ADDITIONALADDRESS1,
      'city', T1.CITY,
      'state', T1.STATE,
      'zip', T1.ZIP,
      'country', CASE 
                    WHEN trim(T1.COUNTRY) = 'Australia' THEN '79'
                    WHEN trim(T1.COUNTRY) = 'New Zealand'  THEN '7R'
                    ELSE T1.COUNTRY
                 END,
      'policySearchType', CASE 
                    WHEN UPPER(policysearchtype) = 'BSP' THEN 'C'
                    WHEN UPPER(policysearchtype) = 'PER'  THEN 'P'
                    ELSE POLICYSEARCHTYPE
                 END,
      'policyStatus', POLICYSTATUS,
      'claimPolicyType', CASE 
                   WHEN UPPER(policysearchtype) = 'BSP' THEN 'ANZBU'
                   WHEN UPPER(policysearchtype) = 'PER' THEN 'ANZPE'
                    ELSE CLAIMPOLICYTYPE
                 END,
      'addressID', NULL,
      'searchPolicyAddressDTO', NULL,
      'lineOfBusiness', T1.LINEOFBUSINESS,
      'lineOfBusinessCategory', NULL,
      'recordDeleteIndicator', T1.RECORDDELETEINDICATOR,
      'lastTransaction', NULL,
      'policyHolderDOB', NULL,
      'agentName', NULL,
      'vehicleList', NULL,
      'propertyList', NULL,
      'personList', NULL,
      'policyHolderPhoneNumber', NULL,
      'prefixCode', NULL,
      'suffixCode', NULL
    )
  ) AS PAYLOAD, TO_CHAR(CAST(EFFECTIVEDATE AS DATE), 'YYYY-MM-DD') as POLICYEFFECTIVEDATE, TO_CHAR(CAST(EXPIRATIONDATE AS DATE), 'YYYY-MM-DD') as  POLICYEXPIRATIONDATE
FROM AGGNE.prd.PURE_POLICY_SEARCH_BP_PER T1 INNER JOIN AGGNE.prd.SAMPLE_POLICYATTACH_FINAL T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.LEGACYPOLICYNUMBER)
;