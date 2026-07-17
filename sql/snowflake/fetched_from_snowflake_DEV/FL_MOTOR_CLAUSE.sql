create or replace view FL_MOTOR_CLAUSE(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	LEGACYPOLICYNUMBER,
	EXPIRINGID_P,
	DCCLAUSETYPE,
	CLAUSEDESCRIPTION
) as 
    select CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,cmlnumber, purepolicynumber AS legacypolicynumber, expiringid_p,CASE
  WHEN DCCLAUSETYPE = 'CM_C01_LEARNER' THEN 'CM_C01_LEARNER'
  WHEN DCCLAUSETYPE = 'CM_C03_NOAR' THEN 'CM_C03_NOAR'
  WHEN DCCLAUSETYPE = 'CM_C04_EFF_DATE' THEN 'CM_C04_EFF_DATE'
  WHEN DCCLAUSETYPE = 'CM_C05_HVNOAR' THEN 'CM_C05_HVNOAR'
  WHEN DCCLAUSETYPE = 'CM_C06_MODSACCS' THEN 'CM_C06_MODSACCS'
  WHEN DCCLAUSETYPE = 'CM_C07_ADDBENEXT' THEN 'CM_C07_ADDBENEXT'
  WHEN DCCLAUSETYPE = 'CM_C08_RISKEXT' THEN 'CM_C08_RISKEXT'
  WHEN DCCLAUSETYPE = 'CM_C09_RISKEXC' THEN 'CM_C09_RISKEXC'
  WHEN DCCLAUSETYPE = 'CM_C10_FTLIAB' THEN 'CM_C10_FTLIAB'
  WHEN DCCLAUSETYPE = 'CM_C11_EXCESS' THEN 'CM_C11_EXCESS'
  WHEN DCCLAUSETYPE = 'CM Learner Extension' THEN 'CMLearnerExtension'
  WHEN DCCLAUSETYPE = 'CM Hire Under 21 Extension' THEN 'CMHireUnderExtension'
  WHEN DCCLAUSETYPE = 'CM Additional Benefit 4 Increase' THEN 'CMAdditionalBenefitFourIncrease'
  WHEN DCCLAUSETYPE = 'CM Additional Benefit 10 Increase' THEN 'CMAdditionalBenefitTenIncrease'
  WHEN DCCLAUSETYPE = 'CM Additional Benefit 12 Increase' THEN 'CMAdditionalBenefitTwelveIncrease'
  WHEN DCCLAUSETYPE = 'CM F&T Only - Liability Extension' THEN 'CMF&TOnlyLiabilityExtension'
  WHEN DCCLAUSETYPE = 'CM General Exclusion OD' THEN 'CMGeneralExclusionOD'
  WHEN DCCLAUSETYPE = 'CM General Exclusion PL' THEN 'CMGeneralExclusionPL'
  WHEN DCCLAUSETYPE = 'FV Max Value' THEN 'FVMaxValue'
  WHEN DCCLAUSETYPE = 'FV Already Protected' THEN 'FVAlreadyProtected'
  WHEN DCCLAUSETYPE = 'FV Age  Restriction Override' THEN 'AgeRestrictionOverride'
  WHEN DCCLAUSETYPE = 'FV Entity  Limitation' THEN 'EntityLimitation'
  WHEN DCCLAUSETYPE = 'FV Usage  Exclusion' THEN 'UsageRestriction'
  WHEN DCCLAUSETYPE = 'FV Forklift TP Exclusion' THEN 'FVForkliftTPExclusion'
  WHEN DCCLAUSETYPE = 'FV General Exclusion OD' THEN 'FVGeneralExclusionOD'
  WHEN DCCLAUSETYPE = 'FV General Exclusion PL' THEN 'FVGeneralExclusionPL'
  WHEN DCCLAUSETYPE = 'CM Optional Benefit 1 Increase' THEN 'CMOptionalBenefitOneIncrease'
END AS DCCLAUSETYPE,dcinput AS CLAUSEDESCRIPTION from AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
where dcinput is not null;