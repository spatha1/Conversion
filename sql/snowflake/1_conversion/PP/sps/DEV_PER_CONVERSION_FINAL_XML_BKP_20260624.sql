-- ============================================================
-- BACKUP: PER_CONVERSION_FINAL_XML (Snowflake PRD version as-at 2026-06-24)
-- Retrieved via GET_DDL before deploying {CSL_LEGAL_ENTITY} fix.
-- DO NOT DEPLOY — for reference only.
-- Change made in deployed version: added last REPLACE entry:
--   ''{CSL_LEGAL_ENTITY}'', IFNULL (CML_LEGAL_ENTITY,''''))
-- ============================================================
CREATE OR REPLACE PROCEDURE "PER_CONVERSION_FINAL_XML"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS 'BEGIN

insert into AGGNE.DEV.PER_POLICY_MIGRATION_DCT_PREVDATA
select *,getdate() as LoadDate from AGGNE.DEV.PER_POLICY_MIGRATION_DCT;

TRUNCATE TABLE  AGGNE.DEV.PER_POLICY_MIGRATION_DCT;

INSERT INTO AGGNE.DEV.PER_POLICY_MIGRATION_DCT (CML_NUMBER,BUCKET,LEGACYPOLICYNUMBER,REQUEST_XML)
        SELECT DISTINCT CMLNUMBER, NTILE(10) OVER (ORDER BY LEGACYPOLICYNUMBER) BUCKET, LEGACYPOLICYNUMBER, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(''<server>
	<requests>
		<Session.loginRq userName="ConversionUser5" password="Pass@123"/>
		<Session.setPropertyRq name="ProductManuscriptId" value="{MANUSCRIPT}"/>
		<Session.setPropertyRq name="WorkflowManuscriptId" value="Carrier_Package_Workflow_1_0_0_0"/>
		<Request.setVarRq name="ImportManuscriptId" value="Carrier_Import_BusinessProtection_1_0_0_0"/>
		<Session.setPropertyRq name="InputClientID" value="{PARTYID}"/>
		<Session.setPropertyRq name="Producer" value="Aaron.Pang@capricorn.coop"/>
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
							<AccountHandler/>
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
							<InceptionDate>{EFFECTIVEDATE}</InceptionDate>
							<TransactionDate>{LOAD_DATE}</TransactionDate>
							<IsConversionPolicy>1</IsConversionPolicy>
							<LegacyPolicyNumber>{LEGACYPOLICYNUMBER}</LegacyPolicyNumber>
							<InceptionDate>{EFFECTIVEDATE}</InceptionDate>
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
									<HomeBuildingsContents>1</HomeBuildingsContents>
									<PrivateMotorVehicles>1</PrivateMotorVehicles>
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
</server>'', ''{CML_RISK_ACCOUNT_MANAGER}'', IFNULL (CML_RISK_ACCOUNT_MANAGER,'''')), ''{CMLTRADINGNAME}'', IFNULL (CMLTRADINGNAME,'''')), ''{SITE_POSTCODE}'', IFNULL (SITE_POSTCODE,'''')), ''{COUNTRYTIMEZONE}'', IFNULL (COUNTRYTIMEZONE,'''')), ''{CHOOSEPROTECTION}'', IFNULL (CHOOSEPROTECTION,'''')), ''{SITE_STREET}'', IFNULL (SITE_STREET,'''')), ''{LOC}'', IFNULL (LOC,'''')), ''{PRIMARY_EMAIL}'', IFNULL (PRIMARY_EMAIL,'''')), ''{PRIMARY_PHONE}'', IFNULL (PRIMARY_PHONE,'''')), ''{CSL_CREDIT_LIMIT}'', IFNULL (CSL_CREDIT_LIMIT,'''')), ''{CSL_AREA_MANAGER}'', IFNULL (CSL_AREA_MANAGER,'''')), ''{LOAD_DATE}'', IFNULL (LOAD_DATE,'''')), ''{STANDARD_INDUSTRY_CODE}'', IFNULL (STANDARD_INDUSTRY_CODE,'''')), ''{ACC_LOC}'', IFNULL (ACC_LOC,'''')), ''{CSL_REGION}'', IFNULL (CSL_REGION,'''')), ''{SITE_COUNTRY}'', IFNULL (SITE_COUNTRY,'''')), ''{CMLNUMBER}'', IFNULL (CMLNUMBER,'''')), ''{LINETYPE}'', IFNULL (LINETYPE,'''')), ''{QU3CRIMINALCONVICTION}'', IFNULL (QU3CRIMINALCONVICTION,'''')), ''{MAINCONTACT}'', IFNULL (MAINCONTACT,'''')), ''{CURRENCY}'', IFNULL (CURRENCY,'''')), ''{COUNTRYCODE}'', IFNULL (COUNTRYCODE,'''')), ''{CSL_ZONE}'', IFNULL (CSL_ZONE,'''')), ''{EXPIRINGID_P}'', IFNULL (EXPIRINGID_P,'''')), ''{DESCRIPTION}'', IFNULL (DESCRIPTION,'''')), ''{STREET}'', IFNULL (STREET,'''')), ''{ABN_NZBN}'', IFNULL (ABN_NZBN,'''')), ''{CLAIMS_PAYLOAD}'', IFNULL (CLAIMS_PAYLOAD,'''')), ''{QU3INSURANCEREFUSEDCANCELLED}'', IFNULL (QU3INSURANCEREFUSEDCANCELLED,'''')), ''{EFFECTIVEDATE}'', IFNULL (EFFECTIVEDATE,'''')), ''{STANDARD_INDUSTRY_CODE_DESCRIPTION}'', IFNULL (STANDARD_INDUSTRY_CODE_DESCRIPTION,'''')), ''{COUNTRY}'', IFNULL (COUNTRY,'''')), ''{LEGACYPOLICYNUMBER}'', IFNULL (LEGACYPOLICYNUMBER,'''')), ''{PARTYID}'', IFNULL (PARTYID,'''')), ''{STOP_CREDIT}'', IFNULL (STOP_CREDIT,'''')), ''{POSTCODE}'', IFNULL (POSTCODE,'''')), ''{EXPIRATIONDATE}'', IFNULL (EXPIRATIONDATE,'''')), ''{CSL_MEMBER_STATUS}'', IFNULL (CSL_MEMBER_STATUS,'''')), ''{STATE}'', IFNULL (STATE,'''')), ''{ID}'', IFNULL (ID,'''')), ''{CML_LEGAL_ENTITY}'', IFNULL (CML_LEGAL_ENTITY,'''')), ''{PM}'', IFNULL (PM,'''')), ''{CSLNUMBER}'', IFNULL (CSLNUMBER,'''')), ''{SITE_SUBURB}'', IFNULL (SITE_SUBURB,'''')), ''{PRIOR_INFO}'', IFNULL (PRIOR_INFO,'''')), ''{PARTY_CML_NUMBER}'', IFNULL (PARTY_CML_NUMBER,'''')), ''{PHONE}'', IFNULL (PHONE,'''')), ''{CMLLEGALENTITY}'', IFNULL (CMLLEGALENTITY,'''')), ''{EMAIL}'', IFNULL (EMAIL,'''')), ''{SUBURB}'', IFNULL (SUBURB,'''')), ''{REFUSEDINSURANCEDETAILS}'', IFNULL (REFUSEDINSURANCEDETAILS,'''')), ''{MEMBERSHIPSYSTEMDATE}'', IFNULL (MEMBERSHIPSYSTEMDATE,'''')), ''{LINEOFBUSINESS}'', IFNULL (LINEOFBUSINESS,'''')), ''{SITE_STATE}'', IFNULL (SITE_STATE,'''')), ''{PRIMARY_PHONE_TYPE}'', IFNULL (PRIMARY_PHONE_TYPE,'''')), ''{CRIMINALCONVICTIONDETAILS}'', IFNULL (CRIMINALCONVICTIONDETAILS,'''')), ''{PUREPOLICYNUMBER}'', IFNULL (PUREPOLICYNUMBER,'''')), ''{PROBABILITY_OF_DEFAULT}'', IFNULL (PROBABILITY_OF_DEFAULT,'''')), ''{MANUSCRIPT}'', IFNULL (MANUSCRIPT,'''')), ''{PAYMENT_METHOD}'', IFNULL (PAYMENT_METHOD,'''')), ''{PRIMARYRATINGSTATE}'', IFNULL (PRIMARYRATINGSTATE,''''))
FROM AGGNE.DEV.PER_FINAL
--WHERE CAST(LOAD_DATE AS DATE)=CAST(GETDATE() AS DATE)  AND
 WHERE PHONE<>''''
and  trim(LEGACYPOLICYNUMBER) in(
select trim(LEGACYPOLICYNUMBER) from AGGNE.DEV.PP_Conversion_FIxList
)
;
END';
