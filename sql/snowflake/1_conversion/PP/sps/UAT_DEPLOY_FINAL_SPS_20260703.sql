-- ============================================================
-- UAT DEPLOYMENT — PP Final SPs (2026-07-03)
-- Collected from LIVE AGGNE.DEV (fixed/validated versions),
-- DEV refs swapped to UAT — same promotion procedure as before:
--   PER_FINAL, VW_PARTYDET, PER_POLICY_MIGRATION_DCT(+PREVDATA) -> UAT
--   PP_RUN_CONTROL filter -> AGGNE.UAT.VW_PP_POLICYCONVERSION_LIST
--   Config views / target tables stay on AGGNE.DEV (UAT architecture)
--
-- Brings to UAT: INCEPTIONDATE (ATP-10962), data-driven
-- HB_HC_INDICATOR / MOTOR_INDICATOR (ATP-10965), account handler
-- tokens (ATP-10961).
--
-- Run order after deploy:
--   CALL AGGNE.UAT.PER_CONVERSION_FINAL_LOAD();
--   CALL AGGNE.UAT.PER_CONVERSION_FINAL_XML();
-- ============================================================

CREATE OR REPLACE PROCEDURE AGGNE.UAT."PER_CONVERSION_FINAL_LOAD"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 'BEGIN
CREATE OR REPLACE TABLE AGGNE.UAT.PER_FINAL AS
SELECT DISTINCT 
  T1.ID ,
  TRIM(T1.LEGACYPOLICYNUMBER) AS LEGACYPOLICYNUMBER
  ,T1.EXPIRINGID_P,
  CAST(TRIM(T2.CMLNUMBER) AS VARCHAR ) AS CMLNUMBER,
  CAST(T1.ID AS VARCHAR) AS PUREPOLICYNUMBER,
  CAST(T2.ABN_NZBN AS VARCHAR) AS ABN_NZBN,
  REPLACE(T2.CMLTRADINGNAME, ''&'', ''&amp;'') AS CMLTRADINGNAME,
  REPLACE(T2.CML_LEGAL_ENTITY, ''&'', ''&amp;'') AS CMLLEGALENTITY,
  CASE
    WHEN TRIM(T2.COUNTRY) = ''New Zealand'' THEN ''NZ''
    WHEN TRIM(T2.COUNTRY) = ''Australia'' THEN ''AU''
    ELSE TRIM(T2.COUNTRY)
  END AS COUNTRY,
  T2.SITE_SUBURB,
  T2.STATE,
  CAST(T2.SITE_POSTCODE  AS VARCHAR) AS SITE_POSTCODE,
  CAST(T2.POSTCODE  AS VARCHAR) AS POSTCODE,
  CASE
    WHEN TRIM(T2.COUNTRY) = ''New Zealand'' THEN SITE_STATE
    WHEN TRIM(T2.COUNTRY) = ''Australia'' THEN CONCAT(SITE_STATE, ''AU'')
    ELSE SITE_STATE
  END AS SITE_STATE,
  T2.SUBURB,
  REPLACE(T2.SITE_STREET, ''&'', ''&amp;'')AS SITE_STREET,
  REPLACE(T2.STREET, ''&'', ''&amp;'')AS STREET,
  CASE
    WHEN TRIM(SITE_COUNTRY) = ''New Zealand'' THEN ''NZ''
    WHEN TRIM(SITE_COUNTRY) = ''Australia'' THEN ''AU''
    ELSE TRIM(SITE_COUNTRY)
  END AS SITE_COUNTRY,
  T2.PRIMARY_PHONE_TYPE,
  REPLACE(T2.CSL_ZONE, ''&'', ''&amp;'') AS CSL_ZONE,
  CAST(T2.PRIMARY_PHONE  AS VARCHAR) AS PRIMARY_PHONE,
  T2.CSL_REGION,
  T2.CSL_AREA_MANAGER,
  CAST(T2.STANDARD_INDUSTRY_CODE  AS VARCHAR) AS STANDARD_INDUSTRY_CODE,
  T2.PHONE,
  REPLACE(T2.CML_LEGAL_ENTITY, ''&'', ''&amp;'') AS CML_LEGAL_ENTITY,
  T2.PRIMARY_EMAIL,
  T2.EMAIL,
  T2.CML_RISK_ACCOUNT_MANAGER,
  REPLACE(T2.MAINCONTACT, ''&'', ''&amp;'') AS MAINCONTACT,
  CAST(T2.CSL_CREDIT_LIMIT  AS VARCHAR) AS CSL_CREDIT_LIMIT,
 CAST(T2.CSL_MEMBER_STATUS AS VARCHAR)AS CSL_MEMBER_STATUS, 
 CAST( CAST(T2.PROBABILITY_OF_DEFAULT AS NUMBER(5,2)) AS VARCHAR) AS PROBABILITY_OF_DEFAULT,
REPLACE(T2.STANDARD_INDUSTRY_CODE_DESCRIPTION, ''&'', ''&amp;'') AS STANDARD_INDUSTRY_CODE_DESCRIPTION,
  CAST(T2.STOP_CREDIT  AS VARCHAR)AS  STOP_CREDIT,
  CASE WHEN CRIMINALCONVICTION = 1 THEN ''Yes'' ELSE ''No'' END AS QU3CRIMINALCONVICTION,
  CASE WHEN REFUSEDINSURANCE =  1 THEN ''Yes'' ELSE ''No'' END AS QU3INSURANCEREFUSEDCANCELLED,
  CRIMINALCONVICTIONDETAILS,
  REFUSEDINSURANCEDETAILS,
    TRIM(T2.CSLNUMBER) as CSLNUMBER,
   TRIM(PRIMARYRATINGSTATE) AS PRIMARYRATINGSTATE  ,
   ''PersonalPackage'' as LINEOFBUSINESS ,
    TO_CHAR(T1."EFFECTIVEDATE"::DATE, ''YYYY-MM-DD'') AS EFFECTIVEDATE ,
    TO_CHAR(T1."EXPIRATIONDATE"::DATE, ''YYYY-MM-DD'')  AS EXPIRATIONDATE,
    TO_CHAR(COALESCE(PA.INCEPTIONDATE, T1."EFFECTIVEDATE")::DATE, ''YYYY-MM-DD'') AS INCEPTIONDATE,
    TO_CHAR("MEMBERSHIPSYSTEMDATE"::DATE, ''YYYY-MM-DD'')  AS MEMBERSHIPSYSTEMDATE,
    ''PP'' AS  CHOOSEPROTECTION ,
    T21.CML_NUMBER AS PARTY_CML_NUMBER,
    T21.PARTYID  ,
    T4.PAYLOAD AS CLAIMS_PAYLOAD,
  T5.PAYLOAD AS PRIOR_INFO,
 CAST(T9.AOI AS VARCHAR) AS ACC_LOC,
 CAST(T12.AOI AS VARCHAR) AS LOC,
 CAST(T24.CM  AS VARCHAR)AS PM,
 CASE WHEN T12.AOI IS NOT NULL AND TRIM(CAST(T12.AOI AS VARCHAR)) != '''' THEN ''1'' ELSE ''0'' END AS HB_HC_INDICATOR,
 CASE WHEN T24.CM  IS NOT NULL AND TRIM(CAST(T24.CM  AS VARCHAR)) != '''' THEN ''1'' ELSE ''0'' END AS MOTOR_INDICATOR,
    CASE
    WHEN TRIM(T2.COUNTRY) = ''New Zealand'' THEN ''Carrier_PersonalProtection_VM_NZ_1_0_0_0''
    WHEN TRIM(T2.COUNTRY) = ''Australia'' THEN ''Carrier_PersonalProtection_VM_AU_1_0_0_0''
    ELSE NULL
  END AS MANUSCRIPT, 
  CASE
    WHEN TRIM(T2.COUNTRY) = ''New Zealand'' THEN ''NZD''
    WHEN TRIM(T2.COUNTRY) = ''Australia'' THEN ''AUD''
    ELSE NULL
  END AS COUNTRYCODE, 
  CASE
    WHEN TRIM(T2.COUNTRY) = ''New Zealand'' THEN ''en-NZ''
    WHEN TRIM(T2.COUNTRY) = ''Australia'' THEN ''en-AU''
    ELSE NULL
  END AS CURRENCY, 
  CASE
    WHEN TRIM(T2.COUNTRY) = ''New Zealand'' THEN ''PPNZ''
    WHEN TRIM(T2.COUNTRY) = ''Australia'' THEN ''PPAU''
    ELSE NULL
  END AS LINETYPE,
  CASE
    WHEN TRIM(T2.COUNTRY) = ''New Zealand'' THEN ''NEWZEASTA''
    WHEN TRIM(T2.COUNTRY) = ''Australia'' THEN ''WAUSSTATI''
    ELSE NULL
  END AS COUNTRYTIMEZONE,
    CASE
    WHEN TRIM(T2.COUNTRY) = ''New Zealand'' THEN ''Personal Protection (NZ)''
    WHEN TRIM(T2.COUNTRY) = ''Australia'' THEN ''Personal Protection (AUS)''
    ELSE NULL
  END AS DESCRIPTION,T28.PAYMENT_METHOD,
  COALESCE(TRIM(T31.ACCOUNTHANDLEREMAIL), ''Aaron.Pang@capricorn.coop'') AS HANDLERMAIL,
  COALESCE(TRIM(T31.FULLNAME), ''Aaron Pang'') AS HANDLERFULLNAME,
  GETDATE() AS LOAD_DATE
 FROM AGGNE.DEV.PER_VW_SAMPLE_FINAL T1
 LEFT JOIN AGGNE.DEV.DIM_PARTY_CML_CSL_NEW T2
   ON TRIM(T1.CMLNUMBER) = TRIM(T2.CMLNUMBER)
LEFT JOIN AGGNE.DEV.PER_VW_CBP_DUTY_DISCLOSURE T3
  ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T3.ID), ''|'', 1)
LEFT JOIN AGGNE.DEV.PER_VW_CLAIM_HISTORY_AGG T4 
  ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T4.ID), ''|'', 1) AND  CAST(T4.LOAD_DATE AS DATE)= (SELECT MAX(CAST(LOAD_DATE AS DATE)) from AGGNE.DEV.VW_CLAIM_HISTORY_AGG)
LEFT JOIN AGGNE.DEV.PER_VW_COMP_INFO_AGG T5
  ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.ID) AND T5.ITR_TYPE=''Prior_INFO'' AND  CAST(T5.LOAD_DATE AS DATE)= (SELECT MAX(CAST(LOAD_DATE AS DATE)) from AGGNE.DEV.VW_COMP_INFO_AGG)
LEFT JOIN AGGNE.DEV.PER_ACCOUNT_LOC_AGG T9 
  ON TRIM(T1.LEGACYPOLICYNUMBER) =  TRIM(T9.PUREPOLICYNUMBER) AND   CAST(T9.LOAD_DATE AS DATE)= (SELECT MAX(CAST(LOAD_DATE AS DATE)) from AGGNE.DEV.PER_ACCOUNT_LOC_AGG)
LEFT JOIN AGGNE.DEV.PER_BUILDING_FINAL_AGG T12
ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T12.PUREPOLICYNUMBER) AND  CAST(T12.LOAD_DATE AS DATE)= (SELECT MAX(CAST(LOAD_DATE AS DATE)) from AGGNE.DEV.PER_BUILDING_FINAL_AGG)
LEFT JOIN AGGNE.UAT.VW_PARTYDET T21 
ON T2.CMLNUMBER=T21.CML_NUMBER
 LEFT JOIN AGGNE.DEV.PER_VW_CM T24
 ON TRIM(T1.LEGACYPOLICYNUMBER) =  TRIM(T24.PUREPOLICYNUMBER)  AND  CAST(T24.LOAD_DATE AS DATE)= (SELECT MAX(CAST(LOAD_DATE AS DATE)) from AGGNE.DEV.PER_VW_CM)
 LEFT JOIN AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD T28 ON TRIM(T1.EXPIRINGID_P)=TRIM(T28.POLICY_BINDER_ID)
 LEFT JOIN (
     SELECT TRIM(PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
            MIN(INCEPTIONDATE) AS INCEPTIONDATE
     FROM AGGNE.DEV.POLICYATTACH_PER
     GROUP BY TRIM(PUREPOLICYNUMBER)
 ) PA ON TRIM(PA.PUREPOLICYNUMBER) = TRIM(T1.LEGACYPOLICYNUMBER)
 LEFT JOIN AGGNE.DEV.ACCOUNT_HANDLER T30
   ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T30.PUREPOLICYNUMBER) AND T30._IS_CURRENT = TRUE
 LEFT JOIN AGGNE.DEV.VW_ACCOUNT_HANDLER_POLICYTEAM T31
   ON TRIM(LOWER(T31.ACCOUNTHANDLEREMAIL)) = TRIM(LOWER(T30.EMAIL))
 ;


insert into AGGNE.DEV.LOAD_AUDIT_LOG (PROCESS_NAME, SOUREC_TABLE_NAME, TARGET_TABLE_NAME, TARGET_RECORD_COUNT, LOAD_DATE)
select ''SP'',''AGGNE.UAT.PER_CONVERSION_FINAL_LOAD'',''AGGNE.UAT.PER_CONVERSION_FINAL_LOAD'' ,null,getdate() ;
-- select PAYMENT_METHOD from AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD 
END';
;

CREATE OR REPLACE PROCEDURE AGGNE.UAT."PER_CONVERSION_FINAL_XML"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 'BEGIN

insert into AGGNE.UAT.PER_POLICY_MIGRATION_DCT_PREVDATA
select *,getdate() as LoadDate from AGGNE.UAT.PER_POLICY_MIGRATION_DCT;

TRUNCATE TABLE  AGGNE.UAT.PER_POLICY_MIGRATION_DCT;

INSERT INTO AGGNE.UAT.PER_POLICY_MIGRATION_DCT (CML_NUMBER,BUCKET,LEGACYPOLICYNUMBER,REQUEST_XML)
        SELECT DISTINCT CMLNUMBER, NTILE(10) OVER (ORDER BY LEGACYPOLICYNUMBER) BUCKET, LEGACYPOLICYNUMBER, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(''<server>
	<requests>
		<Session.loginRq userName="ConversionUser5" password="Pass@123"/>
		<Session.setPropertyRq name="ProductManuscriptId" value="{MANUSCRIPT}"/>
		<Session.setPropertyRq name="WorkflowManuscriptId" value="Carrier_Package_Workflow_1_0_0_0"/>
		<Request.setVarRq name="ImportManuscriptId" value="Carrier_Import_BusinessProtection_1_0_0_0"/>
		<Session.setPropertyRq name="InputClientID" value="{PARTYID}"/>
		<Session.setPropertyRq name="Producer" value="{HANDLERMAIL}"/>
		<ManuScript.getValueRq manuscript="~ImportManuscriptId~" field="PolicyImportPrivate.ImportProcess1"/>
		<Session.setDocumentRq document="_Payload" addIDs="1">
			<_Payload>
				<session>
					<data>
						<account>
							<PartyType>P</PartyType>
							<ABNNumber>{ABN_NZBN}</ABNNumber>
							<Name>{CMLLEGALENTITY}</Name>
							<Country>{COUNTRY}</Country>
							<PhoneCountryCode>{SITE_COUNTRY}</PhoneCountryCode>
							<address>
								<City>{SITE_SUBURB}</City>
								<ZipCode>{SITE_POSTCODE}</ZipCode>
								<State>{SITE_STATE}</State>
								<Address1>{SITE_STREET}</Address1>
								<Address2/>
								<Country>{SITE_COUNTRY}</Country>
							</address>
							<Language>EN</Language>
							<PhoneTypeCode>{PRIMARY_PHONE_TYPE}</PhoneTypeCode>
							<PrimaryPhone>{PRIMARY_PHONE}</PrimaryPhone>
							<MobilePhone>{PRIMARY_PHONE}</MobilePhone>
							<AccountHandler fullName="{HANDLERFULLNAME}" >{HANDLERMAIL}</AccountHandler>
							<RAMRegion>{CSL_REGION}</RAMRegion>
							<RAMName/>
							<CMLNumber>{CMLNUMBER}</CMLNumber>
							<CurrentCML>{CMLNUMBER}</CurrentCML>
							<CSLNumber>{CSLNUMBER}</CSLNumber>
							<CurrentCSL>{CSLNUMBER}</CurrentCSL>
							<CSLLegalEntityName>{CSL_LEGAL_ENTITY}</CSLLegalEntityName>
							<CMLLegalEntityName>{CMLLEGALENTITY}</CMLLegalEntityName>
							<RAMRegion>{CSL_REGION}</RAMRegion>
							<AccountType>CSL</AccountType>
							<CMLRiskAccountManager>{CML_RISK_ACCOUNT_MANAGER}</CMLRiskAccountManager>
							<AccountNumber/>
							<CSLContactName>{MAINCONTACT}</CSLContactName>
							<CSLEmail>{EMAIL}</CSLEmail>
							<CSLPhone>{PHONE}</CSLPhone>
							<CSLAccountManager>{CSL_AREA_MANAGER}</CSLAccountManager>
							<CSLRegion>{CSL_REGION}</CSLRegion>
							<CSLRiskAccountManager>{CSL_AREA_MANAGER}</CSLRiskAccountManager>
							<CSLZone>{CSL_ZONE}</CSLZone>
							<CSLPostcode>{POSTCODE}</CSLPostcode>
							<CSLState>{STATE}</CSLState>
							<CSLStreet>{STREET}</CSLStreet>
							<CSLSuburb>{SUBURB}</CSLSuburb>
							<CSLStartDate/>
							<StandardIndustryCode>{STANDARD_INDUSTRY_CODE}</StandardIndustryCode>
							<CSLTradingName/>
							<CSLMonthlySpend/>
							<CSLCreditUsage/>
							<CSLCreditLimit>{CSL_CREDIT_LIMIT}</CSLCreditLimit>
							<CSLPaymentDefault>0</CSLPaymentDefault>
							<CSLPaymentMethod>CASH</CSLPaymentMethod>
							<CSLCreditRisk/>
							<CSLMemberStatus>{CSL_MEMBER_STATUS}</CSLMemberStatus>
							<ProbabilityOfDefault>{PROBABILITY_OF_DEFAULT}</ProbabilityOfDefault>
							<StandardCodeDescription>{STANDARD_INDUSTRY_CODE_DESCRIPTION}</StandardCodeDescription>
							<StopCredits>{STOP_CREDIT}</StopCredits>
							<StopCreditsReason/>
							<CSLTenure/>
							<LocationScheduleFilter>Description</LocationScheduleFilter>
			{ACC_LOC}
<dutyofdisclosure>
								<CriminalConviction>{QU3CRIMINALCONVICTION}</CriminalConviction>
								<RefusedInsurance>{QU3INSURANCEREFUSEDCANCELLED}</RefusedInsurance>
								<CriminalConvictionDetails>{CRIMINALCONVICTIONDETAILS}</CriminalConvictionDetails>
								<RefusedInsuranceDetails>{REFUSEDINSURANCEDETAILS}</RefusedInsuranceDetails>
							</dutyofdisclosure>
							<FirstName>{CML_LEGAL_ENTITY}</FirstName>
							<MiddleName>{CML_LEGAL_ENTITY}</MiddleName>
							<Street>{STREET}</Street>
							<Suburb>{SUBURB}</Suburb>
							<State>{STATE}</State>
							<Postcode>{POSTCODE}</Postcode>
			{PRIOR_INFO}
			{CLAIMS_PAYLOAD}
			<IsOwnersNameSameAsCMLLegalEntity>Yes</IsOwnersNameSameAsCMLLegalEntity>
							<OwnersName>{CMLLEGALENTITY}</OwnersName>
							<MembershipEffectiveDate/>
						</account>
						<policy>
							<HonorRates>0</HonorRates>
							<EffectiveDate>{EFFECTIVEDATE}</EffectiveDate>
							<Term>12</Term>
							<TimeZone>{COUNTRYTIMEZONE}</TimeZone>
							<ExpirationDate>{EXPIRATIONDATE}</ExpirationDate>
							<LastStatusChange>{LOAD_DATE}</LastStatusChange>
							<LineOfBusiness>PersonalPackage</LineOfBusiness>
							<Status>Application</Status>
							<Currency>{COUNTRYCODE}</Currency>
							<CultureCode>{CURRENCY}</CultureCode>
							<ModNumber>10</ModNumber>
							<InceptionDate>{INCEPTIONDATE}</InceptionDate>
							<TransactionDate>{LOAD_DATE}</TransactionDate>
							<IsConversionPolicy>1</IsConversionPolicy>
							<LegacyPolicyNumber>{LEGACYPOLICYNUMBER}</LegacyPolicyNumber>
							<ReportingPeriod>Monthly</ReportingPeriod>
							<AuditPeriod>Annual</AuditPeriod>
							<PrimaryRatingState>{PRIMARYRATINGSTATE}</PrimaryRatingState>
							<line>
								<HonorRates>0</HonorRates>
								<Type>{LINETYPE}</Type>
								<Indicators>
									<Type>Selected</Type>
									<bValue>1</bValue>
								</Indicators>
								<exposure>
									<Type>DescriptionOverride</Type>
									<Description/>
								</exposure>
								<Excess>
									<Type>PPLPPCV</Type>
									<Voluntary>0</Voluntary>
									<Imposed>0</Imposed>
								</Excess>
								<Excess>
									<Type>GPGTLETA</Type>
									<Imposed>0</Imposed>
									<Voluntary>0</Voluntary>
								</Excess>
								<NewFleetType>Fleet</NewFleetType>
								<CSLSpend>2000</CSLSpend>
								<CSLTenure>1</CSLTenure>
								<GNAFCheck>1</GNAFCheck>
								<NewFleetCode>CM</NewFleetCode>
								<exposure>
									<Type>Description</Type>
									<Description>{DESCRIPTION}</Description>
								</exposure>
				{LOC}
				{PM}

			</line>
							<PackagePolicyIndicator>1</PackagePolicyIndicator>
							<businessinformation>
								<products>
									<HomeBuildingsContents>{HB_HC_INDICATOR}</HomeBuildingsContents>
									<PrivateMotorVehicles>{MOTOR_INDICATOR}</PrivateMotorVehicles>
									<Motor>0</Motor>
									<CommercialVehicles>0</CommercialVehicles>
								</products>
							</businessinformation>
							<RunOffProtection>0</RunOffProtection>
						</policy>
                         <BillingKeys>
							<BillClass>{PAYMENT_METHOD}</BillClass>
							</BillingKeys>
					</data>
				</session>
			</_Payload>
		</Session.setDocumentRq>
		<ManuScript.getValueRq manuscript="~ImportManuscriptId~" field="PolicyImportPrivate.ImportProcess2"/>
		<Session.getDocumentRq/>
		<Session.getElementRq path="data/policy/policyProcessing/CurrentPolicyNumberIdentifier"/>
		<Session.getElementRq path="@id"/>
		<Session.getElementRq path="@clientId"/>
        </Session.closeRq>
	</requests>
</server>'', ''{CML_RISK_ACCOUNT_MANAGER}'', IFNULL (CML_RISK_ACCOUNT_MANAGER,'''')), ''{CMLTRADINGNAME}'', IFNULL (CMLTRADINGNAME,'''')), ''{SITE_POSTCODE}'', IFNULL (SITE_POSTCODE,'''')), ''{COUNTRYTIMEZONE}'', IFNULL (COUNTRYTIMEZONE,'''')), ''{CHOOSEPROTECTION}'', IFNULL (CHOOSEPROTECTION,'''')), ''{SITE_STREET}'', IFNULL (SITE_STREET,'''')), ''{LOC}'', IFNULL (LOC,'''')), ''{PRIMARY_EMAIL}'', IFNULL (PRIMARY_EMAIL,'''')), ''{PRIMARY_PHONE}'', IFNULL (PRIMARY_PHONE,'''')), ''{CSL_CREDIT_LIMIT}'', IFNULL (CSL_CREDIT_LIMIT,'''')), ''{CSL_AREA_MANAGER}'', IFNULL (CSL_AREA_MANAGER,'''')), ''{LOAD_DATE}'', IFNULL (LOAD_DATE,'''')), ''{STANDARD_INDUSTRY_CODE}'', IFNULL (STANDARD_INDUSTRY_CODE,'''')), ''{ACC_LOC}'', IFNULL (ACC_LOC,'''')), ''{CSL_REGION}'', IFNULL (CSL_REGION,'''')), ''{SITE_COUNTRY}'', IFNULL (SITE_COUNTRY,'''')), ''{CMLNUMBER}'', IFNULL (CMLNUMBER,'''')), ''{LINETYPE}'', IFNULL (LINETYPE,'''')), ''{QU3CRIMINALCONVICTION}'', IFNULL (QU3CRIMINALCONVICTION,'''')), ''{MAINCONTACT}'', IFNULL (MAINCONTACT,'''')), ''{CURRENCY}'', IFNULL (CURRENCY,'''')), ''{COUNTRYCODE}'', IFNULL (COUNTRYCODE,'''')), ''{CSL_ZONE}'', IFNULL (CSL_ZONE,'''')), ''{EXPIRINGID_P}'', IFNULL (EXPIRINGID_P,'''')), ''{DESCRIPTION}'', IFNULL (DESCRIPTION,'''')), ''{STREET}'', IFNULL (STREET,'''')), ''{ABN_NZBN}'', IFNULL (ABN_NZBN,'''')), ''{CLAIMS_PAYLOAD}'', IFNULL (CLAIMS_PAYLOAD,'''')), ''{QU3INSURANCEREFUSEDCANCELLED}'', IFNULL (QU3INSURANCEREFUSEDCANCELLED,'''')), ''{EFFECTIVEDATE}'', IFNULL (EFFECTIVEDATE,'''')), ''{STANDARD_INDUSTRY_CODE_DESCRIPTION}'', IFNULL (STANDARD_INDUSTRY_CODE_DESCRIPTION,'''')), ''{COUNTRY}'', IFNULL (COUNTRY,'''')), ''{LEGACYPOLICYNUMBER}'', IFNULL (LEGACYPOLICYNUMBER,'''')), ''{PARTYID}'', IFNULL (PARTYID,'''')), ''{STOP_CREDIT}'', IFNULL (STOP_CREDIT,'''')), ''{POSTCODE}'', IFNULL (POSTCODE,'''')), ''{EXPIRATIONDATE}'', IFNULL (EXPIRATIONDATE,'''')), ''{CSL_MEMBER_STATUS}'', IFNULL (CSL_MEMBER_STATUS,'''')), ''{STATE}'', IFNULL (STATE,'''')), ''{ID}'', IFNULL (ID,'''')), ''{CML_LEGAL_ENTITY}'', IFNULL (CML_LEGAL_ENTITY,'''')), ''{PM}'', IFNULL (PM,'''')), ''{CSLNUMBER}'', IFNULL (CSLNUMBER,'''')), ''{SITE_SUBURB}'', IFNULL (SITE_SUBURB,'''')), ''{PRIOR_INFO}'', IFNULL (PRIOR_INFO,'''')), ''{PARTY_CML_NUMBER}'', IFNULL (PARTY_CML_NUMBER,'''')), ''{PHONE}'', IFNULL (PHONE,'''')), ''{CMLLEGALENTITY}'', IFNULL (CMLLEGALENTITY,'''')), ''{EMAIL}'', IFNULL (EMAIL,'''')), ''{SUBURB}'', IFNULL (SUBURB,'''')), ''{REFUSEDINSURANCEDETAILS}'', IFNULL (REFUSEDINSURANCEDETAILS,'''')), ''{MEMBERSHIPSYSTEMDATE}'', IFNULL (MEMBERSHIPSYSTEMDATE,'''')), ''{LINEOFBUSINESS}'', IFNULL (LINEOFBUSINESS,'''')), ''{SITE_STATE}'', IFNULL (SITE_STATE,'''')), ''{PRIMARY_PHONE_TYPE}'', IFNULL (PRIMARY_PHONE_TYPE,'''')), ''{CRIMINALCONVICTIONDETAILS}'', IFNULL (CRIMINALCONVICTIONDETAILS,'''')), ''{PUREPOLICYNUMBER}'', IFNULL (PUREPOLICYNUMBER,'''')), ''{PROBABILITY_OF_DEFAULT}'', IFNULL (PROBABILITY_OF_DEFAULT,'''')), ''{MANUSCRIPT}'', IFNULL (MANUSCRIPT,'''')), ''{PAYMENT_METHOD}'', IFNULL (PAYMENT_METHOD,'''')), ''{PRIMARYRATINGSTATE}'', IFNULL (PRIMARYRATINGSTATE,'''')), ''{CSL_LEGAL_ENTITY}'', IFNULL (CML_LEGAL_ENTITY,'''')), ''{INCEPTIONDATE}'', IFNULL (INCEPTIONDATE,'''')), ''{HANDLERMAIL}'', IFNULL (HANDLERMAIL,'''')), ''{HANDLERFULLNAME}'', IFNULL (HANDLERFULLNAME,'''')), ''{HB_HC_INDICATOR}'', IFNULL (HB_HC_INDICATOR,'''')), ''{MOTOR_INDICATOR}'', IFNULL (MOTOR_INDICATOR,''''))
FROM AGGNE.UAT.PER_FINAL
--WHERE CAST(LOAD_DATE AS DATE)=CAST(GETDATE() AS DATE)  AND
 WHERE PHONE<>''''
and  trim(LEGACYPOLICYNUMBER) in(
select trim(LEGACYPOLICYNUMBER) from AGGNE.UAT.VW_PP_POLICYCONVERSION_LIST
)
IN (SELECT TRIM(LEGACYPOLICYNUMBER) FROM AGGNE.DEV.PP_RUN_CONTROL)
)
;
END';
;
