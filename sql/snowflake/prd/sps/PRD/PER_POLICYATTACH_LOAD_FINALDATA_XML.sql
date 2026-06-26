-- SP: AGGNE.PRD.PER_POLICYATTACH_LOAD_FINALDATA_XML
-- Signature: ()
-- Language:  SQL
-- Collected: 2026-06-25


BEGIN

INSERT INTO AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT_PREVDATA
SELECT *,getDate() LoadDate FROM AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT;

TRUNCATE TABLE AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT;

INSERT INTO AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT (BUCKET,ID,LEGACYPOLICYNUMBER,EFFECTIVEDATE,EXPIRATIONDATE,CREATED_AT,REQUEST_XML)
        SELECT DISTINCT 1,ACTUALID,LEGACYPOLICYNUMBER,TO_CHAR("EFFECTIVEDATE"::DATE, 'YYYY-MM-DD') AS EFFECTIVEDATE ,
    TO_CHAR("EXPIRATIONDATE"::DATE, 'YYYY-MM-DD')  AS EXPIRATIONDATE,GETDATE() AS CREATED_AT,REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE('<server>
	<requests>
		<Session.loginRq userName="{USERNAME}" password="{PASSWORD}"/>
		<Session.setAllDocumentsRq addIDs="1">
			<session clientId="{PARTYID}">
				<data>
					<account>
						<PartyType>O</PartyType>
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
						<CSLLegalEntityName>{CMLLEGALENTITY}</CSLLegalEntityName>
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
						<Status>InForce</Status>
						<Currency>{COUNTRYCODE}</Currency>
						<CultureCode>{CURRENCY}</CultureCode>
						<ModNumber>10</ModNumber>
						<InceptionDate>{EFFECTIVEDATE}</InceptionDate>
						<TransactionDate>{LOAD_DATE}</TransactionDate>
						<IsConversionPolicy>1</IsConversionPolicy>
						<LegacyPolicyNumber>{LEGACYPOLICYNUMBER}</LegacyPolicyNumber>
                        <PolicyNumber>{LEGACYPOLICYNUMBER}</PolicyNumber>
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
				</data>
			</session>
		</Session.setAllDocumentsRq>
		<OnlineData.getAgencyDetailsRq agencyID="1" responseSessionAppend="2" responseSessionPath="data" responseSelect="OnlineData.getAgencyDetailsRs/agencyDetails"/>
		<OnlineData.getUserDetailsRq userName="Aaron.Pang@capricorn.coop" agencyID="1" responseSessionAppend="2" responseSessionPath="data" responseSelect="OnlineData.getUserDetailsRs/userDetails"/>
		<ManuScript.getValueRq field="PolicyPrivate.ItrSetLocationProperty" manuscript="Carrier_Package_Data_CW_1_0_0_0"/>
		<ManuScript.getValueRq field="PolicyPrivate.ItrSetLocationAddressAOI" manuscript="Carrier_Package_Data_CW_1_0_0_0"/>
		<Session.getDocumentRq xsltOut="$server.rootpath$\\Transform\\Claims\\PersonalProtection\\PP_Model.xsl"/>
        <Session.closeRq/>
	</requests>
    
</server>', 
'{CMLTRADINGNAME}', CAST(IFNULL (CMLTRADINGNAME,'') AS VARCHAR)),
'{STANDARD_INDUSTRY_CODE_DESCRIPTION}', CAST(IFNULL (STANDARD_INDUSTRY_CODE_DESCRIPTION,'') AS VARCHAR)),
'{PRIMARY_PHONE_TYPE}', CAST(IFNULL (PRIMARY_PHONE_TYPE,'') AS VARCHAR)),
'{SITE_STATE}', CAST(IFNULL (SITE_STATE,'') AS VARCHAR)),
'{ABN_NZBN}', CAST(IFNULL (ABN_NZBN,'') AS VARCHAR)),
'{STANDARD_INDUSTRY_CODE}', CAST(IFNULL (STANDARD_INDUSTRY_CODE,'') AS VARCHAR)),
'{CMLLEGALENTITY}', CAST(IFNULL (CMLLEGALENTITY,'') AS VARCHAR)),
'{PM}', CAST(IFNULL (PM,'') AS VARCHAR)),
'{PASSWORD}', CAST(IFNULL (PASSWORD,'') AS VARCHAR)),
'{EFFECTIVEDATE}', CAST(IFNULL (EFFECTIVEDATE,'') AS VARCHAR)),
'{PRIMARY_EMAIL}', CAST(IFNULL (PRIMARY_EMAIL,'') AS VARCHAR)),
'{EMAIL}', CAST(IFNULL (EMAIL,'') AS VARCHAR)),
'{LINETYPE}', CAST(IFNULL (LINETYPE,'') AS VARCHAR)),
'{STATE}', CAST(IFNULL (STATE,'') AS VARCHAR)),
'{CSL_REGION}', CAST(IFNULL (CSL_REGION,'') AS VARCHAR)),
'{MAINCONTACT}', CAST(IFNULL (MAINCONTACT,'') AS VARCHAR)),
'{MANUSCRIPT}', CAST(IFNULL (MANUSCRIPT,'') AS VARCHAR)),
'{STOP_CREDIT}', CAST(IFNULL (STOP_CREDIT,'') AS VARCHAR)),
'{CML_RISK_ACCOUNT_MANAGER}', CAST(IFNULL (CML_RISK_ACCOUNT_MANAGER,'') AS VARCHAR)),
'{ID}', CAST(IFNULL (ID,'') AS VARCHAR)),
'{PRIMARY_PHONE}', CAST(IFNULL (PRIMARY_PHONE,'') AS VARCHAR)),
'{LOC}', CAST(IFNULL (LOC,'') AS VARCHAR)),
'{LEGACYPOLICYNUMBER}', CAST(IFNULL (LEGACYPOLICYNUMBER,'') AS VARCHAR)),
'{POSTCODE}', CAST(IFNULL (POSTCODE,'') AS VARCHAR)),
'{COUNTRYCODE}', CAST(IFNULL (COUNTRYCODE,'') AS VARCHAR)),
'{DESCRIPTION}', CAST(IFNULL (DESCRIPTION,'') AS VARCHAR)),
'{PUREPOLICYNUMBER}', CAST(IFNULL (PUREPOLICYNUMBER,'') AS VARCHAR)),
'{LINEOFBUSINESS}', CAST(IFNULL (LINEOFBUSINESS,'') AS VARCHAR)),
'{CSLNUMBER}', CAST(IFNULL (CSLNUMBER,'') AS VARCHAR)),
'{CSL_MEMBER_STATUS}', CAST(IFNULL (CSL_MEMBER_STATUS,'') AS VARCHAR)),
'{REFUSEDINSURANCEDETAILS}', CAST(IFNULL (REFUSEDINSURANCEDETAILS,'') AS VARCHAR)),
'{SUBURB}', CAST(IFNULL (SUBURB,'') AS VARCHAR)),
'{CSL_ZONE}', CAST(IFNULL (CSL_ZONE,'') AS VARCHAR)),
'{COUNTRYTIMEZONE}', CAST(IFNULL (COUNTRYTIMEZONE,'') AS VARCHAR)),
'{LOAD_DATE}', CAST(IFNULL (LOAD_DATE,'') AS VARCHAR)),
'{CHOOSEPROTECTION}', CAST(IFNULL (CHOOSEPROTECTION,'') AS VARCHAR)),
'{EXPIRINGID_P}', CAST(IFNULL (EXPIRINGID_P,'') AS VARCHAR)),
'{QU3INSURANCEREFUSEDCANCELLED}', CAST(IFNULL (QU3INSURANCEREFUSEDCANCELLED,'') AS VARCHAR)),
'{USERNAME}', CAST(IFNULL (USERNAME,'') AS VARCHAR)),
'{CLAIMS_PAYLOAD}', CAST(IFNULL (CLAIMS_PAYLOAD,'') AS VARCHAR)),
'{PRIOR_INFO}', CAST(IFNULL (PRIOR_INFO,'') AS VARCHAR)),
'{CML_LEGAL_ENTITY}', CAST(IFNULL (CML_LEGAL_ENTITY,'') AS VARCHAR)),
'{SITE_SUBURB}', CAST(IFNULL (SITE_SUBURB,'') AS VARCHAR)),
'{PHONE}', CAST(IFNULL (PHONE,'') AS VARCHAR)),
'{PRIMARYRATINGSTATE}', CAST(IFNULL (PRIMARYRATINGSTATE,'') AS VARCHAR)),
'{STREET}', CAST(IFNULL (STREET,'') AS VARCHAR)),
'{SITE_COUNTRY}', CAST(IFNULL (SITE_COUNTRY,'') AS VARCHAR)),
'{PARTYID}', CAST(IFNULL (PARTYID,'') AS VARCHAR)),
'{PARTY_CML_NUMBER}', CAST(IFNULL (PARTY_CML_NUMBER,'') AS VARCHAR)),
'{ACC_LOC}', CAST(IFNULL (ACC_LOC,'') AS VARCHAR)),
'{CSL_AREA_MANAGER}', CAST(IFNULL (CSL_AREA_MANAGER,'') AS VARCHAR)),
'{QU3CRIMINALCONVICTION}', CAST(IFNULL (QU3CRIMINALCONVICTION,'') AS VARCHAR)),
'{PROBABILITY_OF_DEFAULT}', CAST(IFNULL (PROBABILITY_OF_DEFAULT,'') AS VARCHAR)),
'{SITE_STREET}', CAST(IFNULL (SITE_STREET,'') AS VARCHAR)),
'{CURRENCY}', CAST(IFNULL (CURRENCY,'') AS VARCHAR)),
'{COUNTRY}', CAST(IFNULL (COUNTRY,'') AS VARCHAR)),
'{EXPIRATIONDATE}', CAST(IFNULL (EXPIRATIONDATE,'') AS VARCHAR)),
'{CRIMINALCONVICTIONDETAILS}', CAST(IFNULL (CRIMINALCONVICTIONDETAILS,'') AS VARCHAR)),
'{CMLNUMBER}', CAST(IFNULL (CMLNUMBER,'') AS VARCHAR)),
'{MEMBERSHIPSYSTEMDATE}', CAST(IFNULL (MEMBERSHIPSYSTEMDATE,'') AS VARCHAR)),
'{SITE_POSTCODE}', CAST(IFNULL (SITE_POSTCODE,'') AS VARCHAR)),
'{CSL_CREDIT_LIMIT}', CAST(IFNULL (CSL_CREDIT_LIMIT,'') AS VARCHAR))
FROM AGGNE.PRD.PA_PER_FINAL_OUTPUT_DISTINCT ;


insert into AGGNE.PRD.LOAD_Policyattach
select 'AGGNE.PRD.PER_POLICYATTACH_LOAD_FINALDATA_XML' as D_INFO,getdate() LoadDate;


RETURN 'INSERTED SUCCESSFULLY';

END
