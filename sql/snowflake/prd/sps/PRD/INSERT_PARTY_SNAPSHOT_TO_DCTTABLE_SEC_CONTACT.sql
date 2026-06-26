-- SP: AGGNE.PRD.INSERT_PARTY_SNAPSHOT_TO_DCTTABLE_SEC_CONTACT
-- Signature: ()
-- Language:  SQL
-- Collected: 2026-06-25

BEGIN

INSERT INTO AGGNE.PRD_XML.CML_MIGRATION_DCT (CML_NUMBER,BUCKET,PARTY_DIM_ID,REQUEST_XML)
SELECT CMLNUMBER,
 NTILE(10) OVER (ORDER BY PARTY_DIM_ID),
ROW_NUMBER()over(ORDER BY PARTY_DIM_ID)+(select max(PARTY_DIM_ID) from AGGNE.PRD_XML.CML_MIGRATION_DCT) as PARTY_DIM_ID,
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
'<server>
	<requests>
		<Session.openRq userName="{USERNAME}" password="C0nv3rsionUs3r1!"/>
		<Search.queryIndexRq index="party" count="500" start="0" var.PartyID="//Search.queryIndexRs/items/item/@recordId" var.PartyCount="//Search.queryIndexRs/items/@total">
			<IndexInfo>
				<DomainLevel>1</DomainLevel>
				<DomainName>party</DomainName>
			</IndexInfo>
			<keys>
				<key name="CMLNumber" value="{CMLNUMBER}" connect="and" op="contains"/>
			</keys>
			<sort>
				<field name="PartyName" order="asc"/>
			</sort>
		</Search.queryIndexRq>
		<Request.echoRq>~PartyID~</Request.echoRq>
		<Request.ifRq condition="var(PartyCount)=0">
			<then>
				<PartyObj.addPartyRq var.PartyID="//PartyRecord/PartyRecordPartyId">
					<PartyRecord>
						<Party>
							<PartyFirstName/>
							<PartyMiddleName/>
							<PartyName>{CMLTRADINGNAME}</PartyName>
							<PartyTypeCode>O</PartyTypeCode>
							<PartyNamePrefixCode/>
							<PartyNameSuffixCode/>
							<PartyExtendedData>
								<PreferredContactPerson>{MAINCONTACT}</PreferredContactPerson>
								<USCitizen>0</USCitizen>
								<CSLNumber>{CSLNUMBER}</CSLNumber>
								<CMLNumber>{CMLNUMBER}</CMLNumber>
								<CSLLegalEntity>{CSL_LEGAL_ENTITY}</CSLLegalEntity>
								<CMLRiskAccountManager>{CML_RISK_ACCOUNT_MANAGER}</CMLRiskAccountManager>
								<CMLLegalEntity>{CMLLEGALENTITY}</CMLLegalEntity>
								<AccountType/>
								<AccountID/>
								<cmladdress>
									<Street>{SITE_STREET}</Street>
									<Suburb>{SITE_SUBURB}</Suburb>
									<State>{SITE_STATE}</State>
									<Postcode>{SITE_POSTCODE}</Postcode>
								</cmladdress>
								<AccountNumber/>
								<csldetails>
									<CSLContactName>{CONTACT_NAME}</CSLContactName>
									<Phone>{PHONE}</Phone>
									<Email>{EMAIL}</Email>
									<Street>{STREET}</Street>
									<Suburb>{SUBURB}</Suburb>
									<State>{STATE}</State>
									<Postcode>{POSTCODE}</Postcode>
									<CSLMemberStatus>{CSL_MEMBER_STATUS}</CSLMemberStatus>
									<StopCredits>{STOP_CREDIT}</StopCredits>
									<StopCreditsReason>{STOP_CREDIT_REASON}</StopCreditsReason>
									<CSLTenure>{CSL_TENURE}</CSLTenure>
									<CSLMonthlySpend>{CSL_MONTHLY_SPEND}</CSLMonthlySpend>
									<ABN>{ABN_NZBN}</ABN>
									<StandardIndustryCode>{STANDARD_INDUSTRY_CODE}</StandardIndustryCode>
									<StandardCodeDescription>{STANDARD_INDUSTRY_CODE_DESCRIPTION}</StandardCodeDescription>
									<CSLCreditLimit>{CSL_CREDIT_LIMIT}</CSLCreditLimit>
									<CSLCreditRisk>{CSL_CREDIT_RISK}</CSLCreditRisk>
									<CSLCreditUsage>{CSL_CREDIT_USAGE}</CSLCreditUsage>
									<ProbabilityOfDefault>{PROBABILITY_OF_DEFAULT}</ProbabilityOfDefault>
									<TAPaymentMethod>{TA_PAYMENT_METHOD}</TAPaymentMethod>
									<CSLStartDate/>
									<CSLAccountManager>{CSL_AREA_MANAGER}</CSLAccountManager>
									<CSLRegion>{CSL_REGION}</CSLRegion>
									<CSLZone>{CSL_ZONE}</CSLZone>
									<CSLRiskAccountManager>{CSL_AREA_MANAGER}</CSLRiskAccountManager>
								</csldetails>
								<membervalidity>
									<EffectiveDate>{EFFECTIVE_DATE}</EffectiveDate>
									<ExpirationDate>{PAID2DATE}</ExpirationDate>
								</membervalidity>
								<membershipvalidity>
									<membership EffectiveDate="{EFFECTIVE_DATE}" ExpirationDate="{PAID2DATE}" Amount="{AMOUNT}"/>
								</membershipvalidity>
								<PartyExtendedOtherNames>
									{SECONDARYCONTACT_XMLDATA}
								</PartyExtendedOtherNames>
							</PartyExtendedData>
							<PartyBusinessSuiteExtendedData>
								<CMLNumber>{CMLNUMBER}</CMLNumber>
								<CSLNumber>{CSLNUMBER}</CSLNumber>
							</PartyBusinessSuiteExtendedData>
							<PartyGenderCode/>
							<PartyBirthDate/>
							<PartyMaritalStatusCode/>
							<PartySubTypeCode/>
							<PartyCorrespondenceName/>
							<PartyLegacyName>{CMLTRADINGNAME}</PartyLegacyName>
							<PartyNumberOfDependents>0</PartyNumberOfDependents>
							<PartyIsCompanyPersonnel>0</PartyIsCompanyPersonnel>
							<PartySupplier>0</PartySupplier>
							<PartyCountryCode>{SITE_COUNTRY}</PartyCountryCode>
                            <PartyTaxId>{ABN_NZBN}</PartyTaxId>
						</Party>
						<PartyEmails>
							<PartyEmail>
								<PrimaryIndicator>1</PrimaryIndicator>
								<PartyEmailId/>
								<EmailAddress>{PRIMARY_EMAIL}</EmailAddress>
								<EmailTypeCode>B</EmailTypeCode>
								<EmailEffectiveDate>{LOAD_DATE}</EmailEffectiveDate>
								<EditFlag>0</EditFlag>
							</PartyEmail>
						</PartyEmails>
						<PartyPhones>
							<PartyPhone>
								<PhoneNumber>{PRIMARY_PHONE}</PhoneNumber>
								<PhoneTypeCode>{PRIMARY_PHONE_TYPE}</PhoneTypeCode>
								<PrimaryIndicator>1</PrimaryIndicator>
								<PartyPhoneId/>
								<PhoneExtension>{PHONE_DETAILS}</PhoneExtension>
								<PhoneCountryCode>{SITE_COUNTRY}</PhoneCountryCode>
								<PhoneComments/>
								<PhoneEffectiveDate>{LOAD_DATE}</PhoneEffectiveDate>
								<PhoneFormatCode>US1</PhoneFormatCode>
							</PartyPhone>
						</PartyPhones>
						<Locations>
							<Location>
								<LocationId>~LocationId~</LocationId>
								<LocationAddressLine1>{CORRESPONDENCELINE1}</LocationAddressLine1>
								<LocationCountryCode>{COUNTRY}</LocationCountryCode>
								<LocationAddressLine2>{CORRESPONDENCELINE2}</LocationAddressLine2>
								<LocationAddressLine3/>
								<LocationAddressLine4>{CORRESPONDENCELINE4}</LocationAddressLine4>
								<LocationAddressLine5/>
								<LocationCity>{CORRESPONDENCELINE3}</LocationCity>
								<LocationPostalCode>{CORRESPONDENCEPOSTCODE}</LocationPostalCode>
								<LocationPostalCodeExtension/>
								<LocationComments/>
								<Attention/>
								<LocationEffectiveDate>{LOAD_DATE}</LocationEffectiveDate>
								<LocationExpirationDate>9999-12-31</LocationExpirationDate>
								<LocationCityDropDown>{CORRESPONDENCELINE3}</LocationCityDropDown>
								<LocationPostalCodeDropDown>{CORRESPONDENCEPOSTCODE}</LocationPostalCodeDropDown>
								<LocationStateDropDown>{LOCATIONSTATECODE}</LocationStateDropDown>
								<LocationStateCode>{LOCATIONSTATECODE}</LocationStateCode>
								<LocationStateName>{LOCATIONSTATECODE}</LocationStateName>
								<LocationLatitude/>
								<LocationLongitude/>
                                <PrimaryIndicator>1</PrimaryIndicator>
								<LocationLockingTS>~LocationLockingTS~</LocationLockingTS>
								<Number>1</Number>
							</Location>
							<IsAddOnSummary>0</IsAddOnSummary>
						</Locations>
						<PartyRecordPartyId/>
					</PartyRecord>
					<TransactionDate>{LOAD_DATE}</TransactionDate>
					<EntityID>1</EntityID>
					<ReturnParty>Y</ReturnParty>
				</PartyObj.addPartyRq>
			</then>
			<else>
				<CustomServer.processRq>
					<dataRequests>
						<PartyObj.updatePartyRq var.PartyEmailLockingTS="//PartyEmails/PartyEmail[PrimaryIndicator=1]/PartyEmailLockingTS" var.PartyEmailId="//PartyEmails/PartyEmail[PrimaryIndicator=1]/PartyEmailId" var.LocationLockingTS="//Locations/Location[PrimaryIndicator=1]/LocationLockingTS" var.LocationId="//Locations/Location[PrimaryIndicator=1]/LocationId" var.PartyPhoneLockingTS="//PartyPhones/PartyPhone[PrimaryIndicator=1]/PartyPhoneLockingTS" var.PartyPhoneId="//PartyPhones/PartyPhone[PrimaryIndicator=1]/PartyPhoneId">
							<PartyRecord>
								<PartyRecordPartyId>~PartyID~</PartyRecordPartyId>
								<Party>
									<PartyFirstName/>
									<PartyMiddleName/>
									<PartyName>{CMLTRADINGNAME}</PartyName>
									<PartyTypeCode>O</PartyTypeCode>
									<PartyNamePrefixCode/>
									<PartyNameSuffixCode/>
									<PartyExtendedData>
										<PreferredContactPerson>{MAINCONTACT}</PreferredContactPerson>
										<USCitizen>0</USCitizen>
										<CSLNumber>{CSLNUMBER}</CSLNumber>
										<CMLNumber>{CMLNUMBER}</CMLNumber>
										<CSLLegalEntity>{CSL_LEGAL_ENTITY}</CSLLegalEntity>
										<CMLRiskAccountManager>{CML_RISK_ACCOUNT_MANAGER}</CMLRiskAccountManager>
										<CMLLegalEntity>{CMLLEGALENTITY}</CMLLegalEntity>
										<AccountType/>
										<AccountID/>
										<cmladdress>
											<Street>{SITE_STREET}</Street>
											<Suburb>{SITE_SUBURB}</Suburb>
											<State>{SITE_STATE}</State>
											<Postcode>{SITE_POSTCODE}</Postcode>
										</cmladdress>
										<csldetails>
											<CSLContactName>{CONTACT_NAME}</CSLContactName>
											<Phone>{PHONE}</Phone>
											<Email>{EMAIL}</Email>
											<Street>{STREET}</Street>
											<Suburb>{SUBURB}</Suburb>
											<State>{STATE}</State>
											<Postcode>{POSTCODE}</Postcode>
											<CSLMemberStatus>{CSL_MEMBER_STATUS}</CSLMemberStatus>
											<StopCredits>{STOP_CREDIT}</StopCredits>
											<StopCreditsReason>{STOP_CREDIT_REASON}</StopCreditsReason>
											<CSLTenure>{CSL_TENURE}</CSLTenure>
											<CSLMonthlySpend>{CSL_MONTHLY_SPEND}</CSLMonthlySpend>
											<ABN>{ABN_NZBN}</ABN>
											<StandardIndustryCode>{STANDARD_INDUSTRY_CODE}</StandardIndustryCode>
											<StandardCodeDescription>{STANDARD_INDUSTRY_CODE_DESCRIPTION}</StandardCodeDescription>
											<CSLCreditLimit>{CSL_CREDIT_LIMIT}</CSLCreditLimit>
											<CSLCreditRisk>{CSL_CREDIT_RISK}</CSLCreditRisk>
											<CSLCreditUsage>{CSL_CREDIT_USAGE}</CSLCreditUsage>
											<ProbabilityOfDefault>{PROBABILITY_OF_DEFAULT}</ProbabilityOfDefault>
											<TAPaymentMethod>{TA_PAYMENT_METHOD}</TAPaymentMethod>
											<CSLStartDate/>
											<CSLAccountManager>{CSL_AREA_MANAGER}</CSLAccountManager>
											<CSLRegion>{CSL_REGION}</CSLRegion>
											<CSLZone>{CSL_ZONE}</CSLZone>
											<CSLRiskAccountManager>{CSL_AREA_MANAGER}</CSLRiskAccountManager>
										</csldetails>
										<membervalidity>
											<EffectiveDate>{EFFECTIVE_DATE}</EffectiveDate>
											<ExpirationDate>{PAID2DATE}</ExpirationDate>
										</membervalidity>
										<membershipvalidity>
											<membership EffectiveDate="{EFFECTIVE_DATE}" ExpirationDate="{PAID2DATE}" Amount="{AMOUNT}"/>
										</membershipvalidity>
										<PartyExtendedOtherNames>
											{SECONDARYCONTACT_XMLDATA}
										</PartyExtendedOtherNames>
									</PartyExtendedData>
									<PartyBusinessSuiteExtendedData>
										<CMLNumber>{CMLNUMBER}</CMLNumber>
										<CSLNumber>{CSLNUMBER}</CSLNumber>
									</PartyBusinessSuiteExtendedData>
									<PartyGenderCode/>
									<PartyBirthDate/>
									<PartyMaritalStatusCode/>
									<PartySubTypeCode/>
									<PartyCorrespondenceName/>
									<PartyLegacyName>{CMLTRADINGNAME}</PartyLegacyName>
									<PartyNumberOfDependents>0</PartyNumberOfDependents>
									<PartyIsCompanyPersonnel>0</PartyIsCompanyPersonnel>
									<PartySupplier>0</PartySupplier>
									<PartyCountryCode>{SITE_COUNTRY}</PartyCountryCode>
                                    <PartyTaxId>{ABN_NZBN}</PartyTaxId>
								</Party>
							</PartyRecord>
							<TransactionDate>{LOAD_DATE}</TransactionDate>
							<RequestReturnData>Y</RequestReturnData>
						</PartyObj.updatePartyRq>
						<PartyObj.updatePartyEmailRq>
							<PartyRecord>
								<PartyRecordPartyId>~PartyID~</PartyRecordPartyId>
								<PartyEmails>
									<PartyEmail>
										<PartyEmailId>~PartyEmailId~</PartyEmailId>
										<EmailTypeCode>B</EmailTypeCode>
										<EmailAddress>{PRIMARY_EMAIL}</EmailAddress>
										<PartyEmailLockingTS>~PartyEmailLockingTS~</PartyEmailLockingTS>
										<PrimaryIndicator>1</PrimaryIndicator>
										<EmailComments/>
										<EmailEffectiveDate/>
										<EmailExpirationDate/>
										<IsExpired/>
									</PartyEmail>
								</PartyEmails>
							</PartyRecord>
							<TransactionDate>{LOAD_DATE}</TransactionDate>
							<RequestReturnData>Y</RequestReturnData>
						</PartyObj.updatePartyEmailRq>
						<PartyObj.updatePartyPhoneRq>
							<PartyRecord>
								<PartyRecordPartyId>~PartyID~</PartyRecordPartyId>
								<PartyPhones>
									<PartyPhone>
										<PartyPhoneId>~PartyPhoneId~</PartyPhoneId>
										<PhoneTypeCode>{PRIMARY_PHONE_TYPE}</PhoneTypeCode>
										<PhoneNumber>{PRIMARY_PHONE}</PhoneNumber>
										<PhoneExtension>{PHONE_DETAILS}</PhoneExtension>
										<PhoneCountryCode>{SITE_COUNTRY}</PhoneCountryCode>
										<PhoneFormatCode/>
										<PartyPhoneLockingTS>~PartyPhoneLockingTS~</PartyPhoneLockingTS>
										<PrimaryIndicator>1</PrimaryIndicator>
										<PhoneComments/>
										<PhoneEffectiveDate/>
										<PhoneExpirationDate/>
										<IsExpired/>
									</PartyPhone>
								</PartyPhones>
							</PartyRecord>
							<TransactionDate>{LOAD_DATE}</TransactionDate>
							<RequestReturnData>Y</RequestReturnData>
						</PartyObj.updatePartyPhoneRq>
						<PartyObj.correctPartyLocationRq>
							<PartyRecord>
								<PartyRecordPartyId>~PartyID~</PartyRecordPartyId>
								<Locations>
									<Location>
										<LocationId>~LocationId~</LocationId>
										<LocationAddressLine1>{CORRESPONDENCELINE1}</LocationAddressLine1>
										<LocationCountryCode>{COUNTRY}</LocationCountryCode>
										<LocationAddressLine2>{CORRESPONDENCELINE2}</LocationAddressLine2>
										<LocationAddressLine3/>
										<LocationAddressLine4>{CORRESPONDENCELINE4}</LocationAddressLine4>
										<LocationAddressLine5/>
										<LocationCity>{CORRESPONDENCELINE3}</LocationCity>
										<LocationPostalCode>{CORRESPONDENCEPOSTCODE}</LocationPostalCode>
										<LocationPostalCodeExtension/>
										<LocationComments/>
										<Attention/>
										<LocationEffectiveDate>{LOAD_DATE}</LocationEffectiveDate>
										<LocationExpirationDate>9999-12-31</LocationExpirationDate>
										<LocationCityDropDown>{CORRESPONDENCELINE3}</LocationCityDropDown>
										<LocationPostalCodeDropDown>{CORRESPONDENCEPOSTCODE}</LocationPostalCodeDropDown>
										<LocationStateDropDown>{LOCATIONSTATECODE}</LocationStateDropDown>
										<LocationStateCode>{LOCATIONSTATECODE}</LocationStateCode>
										<LocationStateName>{LOCATIONSTATECODE}</LocationStateName>
										<LocationLatitude/>
										<LocationLongitude/>
										<LocationLockingTS>~LocationLockingTS~</LocationLockingTS>
										<Number>1</Number>
                                        <PrimaryIndicator>1</PrimaryIndicator>
									</Location>
								</Locations>
							</PartyRecord>
							<TransactionDate>{LOAD_DATE}</TransactionDate>
							<RequestReturnData>Y</RequestReturnData>
						</PartyObj.correctPartyLocationRq>
						<PartyObj.getPartyRq>
							<PartyId>~PartyID~</PartyId>
						</PartyObj.getPartyRq>
					</dataRequests>
					<customData/>
					<xsltRequests xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
						<xsl:for-each select="//PartyObj.getPartyRs/PartyRecord/PartyEmails/PartyEmail[normalize-space(PrimaryIndicator) = ''0'']">
							<PartyObj.deletePartyEmailRq>
								<TransactionDate>{LOAD_DATE}</TransactionDate>
								<PartyEmailId>
									<xsl:value-of select="PartyEmailId"/>
								</PartyEmailId>
								<PartyEmailLockingTS>
									<xsl:value-of select="PartyEmailLockingTS"/>
								</PartyEmailLockingTS>
							</PartyObj.deletePartyEmailRq>
						</xsl:for-each>
						<xsl:for-each select="//PartyObj.getPartyRs/PartyRecord/PartyPhones/PartyPhone[normalize-space(PrimaryIndicator) = ''0'']">
							<PartyObj.deletePartyPhoneRq>
								<TransactionDate>{LOAD_DATE}</TransactionDate>
								<PartyPhoneId>
									<xsl:value-of select="PartyPhoneId"/>
								</PartyPhoneId>
								<PartyPhoneLockingTS>
									<xsl:value-of select="PartyPhoneLockingTS"/>
								</PartyPhoneLockingTS>
							</PartyObj.deletePartyPhoneRq>
						</xsl:for-each>
					</xsltRequests>
				</CustomServer.processRq>
			</else>
		</Request.ifRq>
		{EMAIL_XMLDATA}
		{PHONE_XMLDATA}
		<PartyObj.getPartyRq>
			<PartyId>~PartyID~</PartyId>
		</PartyObj.getPartyRq>
		<Session.closeRq/>
	</requests>
</server>  ',
'{CORRESPONDENCELINE1}', IFNULL(CORRESPONDENCELINE1, '')),
'{LOCATIONSTATECODE}', IFNULL(LOCATIONSTATECODE, '')),
'{PHONE}', IFNULL(PHONE, '')),
'{COUNTRY}', IFNULL(COUNTRY, '')),
'{SITE_STREET}', IFNULL(SITE_STREET, '')),
'{PHONE_COUNT}', IFNULL(TO_VARCHAR(PHONE_COUNT), '')),
'{STREET}', IFNULL(STREET, '')),
'{HASH_DIFF}', IFNULL(HASH_DIFF, '')),
'{ACTIVE_FLAG}', IFNULL(TO_VARCHAR(ACTIVE_FLAG), '')),
'{STOP_CREDIT}', IFNULL(STOP_CREDIT, '')),
'{CORRESPONDENCELINE2}', IFNULL(CORRESPONDENCELINE2, '')),
'{EMAIL}', IFNULL(EMAIL, '')),
'{PARTY_DIM_ID}', IFNULL(TO_VARCHAR(PARTY_DIM_ID), '')),
'{STATE}', IFNULL(STATE, '')),
'{CSL_AREA_MANAGER}', IFNULL(CSL_AREA_MANAGER, '')),
'{SITE_COUNTRY}', IFNULL(SITE_COUNTRY, '')),
'{CORRESPONDENCEPOSTCODE}', IFNULL(CORRESPONDENCEPOSTCODE, '')),
'{PRIMARY_EMAIL}', IFNULL(PRIMARY_EMAIL, '')),
'{CMLNUMBER}', IFNULL(CMLNUMBER, '')),
'{CMLLEGALENTITY}', IFNULL(CMLLEGALENTITY, '')),
'{CMLTRADINGNAME}', IFNULL(CMLTRADINGNAME, '')),
'{PRIMARY_PHONE}', IFNULL(PRIMARY_PHONE, '')),
'{CORRESPONDENCELINE3}', IFNULL(CORRESPONDENCELINE3, '')),
'{TA_PAYMENT_METHOD}', IFNULL(TA_PAYMENT_METHOD, '')),
'{MAINCONTACT}', IFNULL(MAINCONTACT, '')),
'{CML_RISK_ACCOUNT_MANAGER}', IFNULL(CML_RISK_ACCOUNT_MANAGER, '')),
'{BK_CMLNUMBER}', IFNULL(BK_CMLNUMBER, '')),
'{EFFECTIVE_DATE}', IFNULL(TO_VARCHAR(EFFECTIVE_DATE), '')),
'{STOP_CREDIT_REASON}', IFNULL(STOP_CREDIT_REASON, '')),
'{EFFECTIVE_FROM}', IFNULL(TO_VARCHAR(EFFECTIVE_FROM), '')),
'{AMOUNT}', IFNULL(TO_VARCHAR(AMOUNT), '')),
'{PRIMARY_PHONE_TYPE}', IFNULL(PRIMARY_PHONE_TYPE, '')),
'{MESSAGE}', IFNULL(MESSAGE, '')),
'{STANDARD_INDUSTRY_CODE_DESCRIPTION}', IFNULL(STANDARD_INDUSTRY_CODE_DESCRIPTION, '')),
'{CSL_CREDIT_LIMIT}', IFNULL(TO_VARCHAR(CSL_CREDIT_LIMIT), '')),
'{SITE_STATE}', IFNULL(SITE_STATE, '')),
'{EFFECTIVE_TO}', IFNULL(TO_VARCHAR(EFFECTIVE_TO), '')),
'{STANDARD_INDUSTRY_CODE}', IFNULL(STANDARD_INDUSTRY_CODE, '')),
'{CSL_MEMBER_STATUS}', IFNULL(CSL_MEMBER_STATUS, '')),
'{CONTACT_NAME}', IFNULL(CONTACT_NAME, '')),
-- '{SECONDARYCONTACTKEY}', IFNULL(SECONDARYCONTACTKEY, '')),
'{PROBABILITY_OF_DEFAULT}', IFNULL(TO_VARCHAR(PROBABILITY_OF_DEFAULT), '')),
'{CSL_ZONE}', IFNULL(CSL_ZONE, '')),
'{SITE_POSTCODE}', IFNULL(SITE_POSTCODE, '')),
'{CSL_REGION}', IFNULL(CSL_REGION, '')),
'{PRIMARY_EMAIL_TYPE}', IFNULL(PRIMARY_EMAIL_TYPE, '')),
'{CSL_CREDIT_RISK}', IFNULL(CSL_CREDIT_RISK, '')),
'{CSL_LEGAL_ENTITY}', IFNULL(CSL_LEGAL_ENTITY, '')),
'{MEMBER_TA_NUMBER}', IFNULL(MEMBER_TA_NUMBER, '')),
'{IS_CURRENT}', IFNULL(TO_VARCHAR(IS_CURRENT), '')),
'{CSL_MONTHLY_SPEND}', IFNULL(TO_VARCHAR(CSL_MONTHLY_SPEND), '')),
'{CORRESPONDENCELINE4}', IFNULL(CORRESPONDENCELINE4, '')),
'{CSL_NUMBER}', IFNULL(CSL_NUMBER, '')),
'{CSL_TENURE}', IFNULL(TO_VARCHAR(CSL_TENURE), '')),
'{EMAIL_COUNT}', IFNULL(TO_VARCHAR(EMAIL_COUNT), '')),
'{CSLNUMBER}', IFNULL(CSLNUMBER, '')),
'{ABN_NZBN}', IFNULL(ABN_NZBN, '')),
'{SUBURB}', IFNULL(SUBURB, '')),
'{POSTCODE}', IFNULL(POSTCODE, '')),
'{CMLLEGALENTITY}', IFNULL(CMLLEGALENTITY, '')),
-- '{SECONDARYCONTACT_COUNT}', IFNULL(TO_VARCHAR(SECONDARYCONTACT_COUNT), '')),
'{MEM_REF}', IFNULL(MEM_REF, '')),
'{CSL_CREDIT_USAGE}', IFNULL(TO_VARCHAR(CSL_CREDIT_USAGE), '')),
'{SITE_SUBURB}', IFNULL(SITE_SUBURB, '')),
'{PAID2DATE}', IFNULL(TO_VARCHAR(PAID2DATE), '')),
'{LOAD_DATE}', IFNULL(TO_VARCHAR(LOAD_DATE), '')),
'{USERNAME}', IFNULL(TO_VARCHAR(USERNAME), '')),
'{SECONDARYCONTACT_XMLDATA}', IFNULL(TO_VARCHAR(SECONDARYCONTACT_XMLDATA), '')),
'{EMAIL_XMLDATA}', IFNULL(TO_VARCHAR(EMAIL_XMLDATA), '')),
'{PHONE_XMLDATA}', IFNULL(TO_VARCHAR(PHONE_XMLDATA), '')),
'{PHONE_DETAILS}', IFNULL(TO_VARCHAR(PHONE_DETAILS), ''))
FROM 
AGGNE.PRD.VW_DIM_PARTY_SNAPSHOT_SEC_CONTACT;


RETURN ('Inserted Successfully');
END