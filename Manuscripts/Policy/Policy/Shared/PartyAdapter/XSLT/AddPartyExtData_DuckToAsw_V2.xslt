<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:d2p1="AFS.AEF.WCF.Types" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="PartyEmailTemplate_DuckToASW.xslt"/>
	<xsl:import href="PartyReferenceTemplate_DuckToASW.xslt"/>
	<xsl:import href="PartyLicenseTemplate_DuckToASW.xslt"/>
	<xsl:import href="PartyPhoneTemplate_DuckToASW.xslt"/>
	<xsl:import href="PartyIndNameTemplate_DuckToASW.xslt"/>
	<xsl:import href="PartyRelationTemplate_DuckToASW.xslt"/>
	<xsl:import href="PartyBusNameTemplate_DuckToASW.xslt"/>
	<xsl:import href="PartyLocationTemplate_DuckToASW.xslt"/>
	<xsl:import href="CommonTemplates.xslt"/>

	<xsl:template match="/">
		<xsl:for-each select="PartyRecord">
			<xsl:variable name="partyCountryCode" select="string(Util:GetOneRelatedItem('DCTCountryType',Party/PartyCountryCode,'243'))" />
			<xsl:choose>
				<xsl:when test="string(Util:getBasePartyTypeFromDCTPartyType(Party/PartyTypeCode)) = string(Util:getBasePartyTypeFromASWPartyType('IND'))">
					<PartyIndividualDetailWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
						<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
						<Party>
							<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
							<ACHPartyExternalID>
								<xsl:value-of select="Party/ACHPartyExternalId"/>
							</ACHPartyExternalID>
							<xsl:choose>
								<xsl:when test="Party/PartyOFACCheckNotRequired!=''">
									<BusinessPermitted>
										<xsl:value-of select="Party/PartyOFACCheckNotRequired"/>
									</BusinessPermitted>
								</xsl:when>
								<xsl:otherwise>
									<BusinessPermitted>U</BusinessPermitted>
								</xsl:otherwise>
							</xsl:choose>
							<CountryCode>
								<xsl:value-of select="$partyCountryCode"/>
							</CountryCode>
							<ExternalID>
								<xsl:value-of select="Party/ExternalId"/>
							</ExternalID>
							<GeographicFormatCode>
								<xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
							</GeographicFormatCode>							
							<LastUpdatedDate>
								<xsl:value-of select="string(Util:GetCurrentDate())"/>
							</LastUpdatedDate>
							<Number>
								<xsl:value-of select="Party/PartyNumber"/>
							</Number>
							<xsl:if test="PartyRecordPartyId !=''">
								<PartyID>
									<xsl:value-of select="PartyRecordPartyId"/>
								</PartyID>
							</xsl:if>
							<PartyTypeCode>
								<xsl:value-of select="string(Util:getASWPartyType(Party/PartyTypeCode))"/>
							</PartyTypeCode>
							<PartySubTypeCode>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',Party/PartyTypeCode,'PartySubType'))"/>
							</PartySubTypeCode>
							<xsl:if test="string(Util:ShowPartyTimeZone(Party/PartyTimeZone)) != ''">
								<PartyTimeZone>
									<xsl:value-of select="string(Util:GetChildKey('DCTTimeZones',Party/PartyTimeZone,'TimeZones'))"/>
								</PartyTimeZone>
							</xsl:if>
						</Party>
						<xsl:if test="count(./Locations/Location) > 0">
							<PartyAddressesDetailWithExtendedData>
								<xsl:call-template name="partyLocationExtendedData" />
							</PartyAddressesDetailWithExtendedData>
						</xsl:if>
						<PartyAgent i:nil="true" />
						<xsl:if test="Party/PartyComments != ''">
							<PartyComment>
								<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
								<Comment>
									<xsl:value-of select="Party/PartyComments"/>
								</Comment>
								<EffectiveDate>
									<xsl:value-of select="string(Util:GetCurrentDate())"/>
								</EffectiveDate>
								<ExpirationDate>
									<xsl:value-of select="string(Util:GetMaxDate())"/>
								</ExpirationDate>
								<LastUpdatedDate>
									<xsl:value-of select="string(Util:GetCurrentDate())"/>
								</LastUpdatedDate>
								<xsl:if test="PartyRecordPartyId !=''">
									<PartyID>
										<xsl:value-of select="PartyRecordPartyId"/>
									</PartyID>
								</xsl:if>
							</PartyComment>
						</xsl:if>
						<xsl:if test="count(./PartyEmails/PartyEmail) > 0">
							<PartyEmailsWithExtendedData>
								<xsl:call-template name="partyEmailExtData" />
							</PartyEmailsWithExtendedData>
						</xsl:if>
						<PartyIndividual>
							<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
							<xsl:choose>
								<xsl:when test ="Party/PartyBirthDate !=''">
									<DateOfBirth>
										<xsl:value-of select="string(Util:GetDateTimeWithDefault(Party/PartyBirthDate))"/>
									</DateOfBirth>
								</xsl:when>
								<xsl:otherwise>
									<DateOfBirth i:nil="true"/>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:choose>
								<xsl:when test ="Party/PartyDeathDate !=''">
									<DateOfDeath>
										<xsl:value-of select="string(Util:GetDateTimeWithDefault(Party/PartyDeathDate))"/>
									</DateOfDeath>
								</xsl:when>
								<xsl:otherwise>
									<DateOfDeath i:nil="true"/>
								</xsl:otherwise>
							</xsl:choose>
							<EffectiveDate>
								<xsl:value-of select="string(Util:GetCurrentDate())"/>
							</EffectiveDate>
							<ExpirationDate>
								<xsl:value-of select="string(Util:GetMaxDate())"/>
							</ExpirationDate>
							<GenderCode>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTGender',Party/PartyGenderCode,'51'))"/>
							</GenderCode>
							<IsAgent>false</IsAgent>
							<xsl:choose>
								<xsl:when test="Party/PartyIsCompanyPersonnel !=''">
									<IsCompanyPersonnel>
										<xsl:value-of select="Party/PartyIsCompanyPersonnel"/>
									</IsCompanyPersonnel>
								</xsl:when>
								<xsl:otherwise>
									<IsCompanyPersonnel>0</IsCompanyPersonnel>
								</xsl:otherwise>
							</xsl:choose>
							<LastUpdatedDate>
								<xsl:value-of select="string(Util:GetCurrentDate())"/>
							</LastUpdatedDate>
							<MaritalStatusCode>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTMaritalStatus',Party/PartyMaritalStatusCode,'35'))"/>
							</MaritalStatusCode>
							<NationalID i:nil="true" />
							<xsl:choose>
								<xsl:when test="Party/PartyNumberOfDependents !=''">
									<NumberOfDependents>
										<xsl:value-of select="Party/PartyNumberOfDependents"/>
									</NumberOfDependents>
								</xsl:when>
								<xsl:otherwise>
									<NumberOfDependents>0</NumberOfDependents>
								</xsl:otherwise>
							</xsl:choose>
							<xsl:if test="PartyRecordPartyId !=''">
								<PartyID>
									<xsl:value-of select="PartyRecordPartyId"/>
								</PartyID>
							</xsl:if>

							<PreferredContactType>
								<xsl:value-of select="Party/PreferredContactMethod"/>
							</PreferredContactType>
							<PreferredLanguage>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLanguageType',Party/PartyPreferredLanguageCode,'8037'))"/>
							</PreferredLanguage>
							<ProfessionCode>
								<xsl:value-of select="Party/PartyProfession"/>
							</ProfessionCode>

							<SpecificPurposeID>
								<xsl:value-of select="string(Util:GetSSNForASW(Party/PartyTaxId))"/>
							</SpecificPurposeID>
							<!-- this line will not produce any XML output, but will set the DATA DTO of asw with party extended data-->
							<xsl:for-each select="Party">
								<xsl:call-template name="ExtendedData">
									<xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>
									<xsl:with-param name="SuiteTagName">PartyIndividualSuiteExtendedData</xsl:with-param>
									<xsl:with-param name="AswTagName">IndividualExtendedData</xsl:with-param>
									<xsl:with-param name="PhysicalTableName">PARTY_INDVDL</xsl:with-param>
									<xsl:with-param name="LogicalTableName">lgclPartyIndv</xsl:with-param>
									<xsl:with-param name="LogicalColumnName">PartyIndExtData</xsl:with-param>
								</xsl:call-template>
							</xsl:for-each>
						</PartyIndividual>
						<PartyIndNamesDetailWithExtendedData>
							<xsl:variable name="partyIndNameCountryCode">
								<xsl:choose>
									<xsl:when test="Party/PartyNameCountryCode !=''">
										<xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',Party/PartyNameCountryCode,'243'))"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',Party/PartyCountryCode,'243'))"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<!-- Primary Name Type Code is 01 -->
							<PartyIndNameDetailWithExtendedDataDTO>
								<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
								<PartyIndName>
									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<Comment>
										<xsl:value-of select="Party/PartyNameComments"/>
									</Comment>
									<FirstName>
										<xsl:value-of select="Party/PartyFirstName"/>
									</FirstName>
									<FullName>
										<xsl:value-of select="concat(Party/PartyFirstName,' ', Party/PartyName)"/>
									</FullName>
									<LastName>
										<xsl:value-of select="Party/PartyName"/>
									</LastName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<MiddleName>
										<xsl:value-of select="Party/PartyMiddleName"/>
									</MiddleName>
									<NameTypeCode>01</NameTypeCode>
									<PrefixCode>
										<xsl:value-of select="string(Util:GetOneRelatedItem('DCTNamePrefix',Party/PartyNamePrefixCode,'34'))"/>
									</PrefixCode>
									<SuffixCode>
										<xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameSuffix',Party/PartyNameSuffixCode,'48'))"/>
									</SuffixCode>
								</PartyIndName>
								<PartyName>
									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<AllowPartial>true</AllowPartial>
									<CountryCode>
										<xsl:value-of select="$partyIndNameCountryCode"/>
									</CountryCode>
									<EffectiveDate>
										<xsl:choose>
											<xsl:when test="Party/PartyNameEffectiveDate !=''">
												<xsl:value-of select="string(Util:ConvertDateToAswFormat(Party/PartyNameEffectiveDate))"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="string(Util:GetCurrentDate())"/>
											</xsl:otherwise>
										</xsl:choose>
									</EffectiveDate>
									<ExpirationDate>
										<xsl:choose>
											<xsl:when test="Party/PartyNameExpirationDate !=''">
												<xsl:value-of select="string(Util:ConvertDateToAswFormat(Party/PartyNameExpirationDate))"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="string(Util:GetMaxDate())"/>
											</xsl:otherwise>
										</xsl:choose>
									</ExpirationDate>
									<ExternalPartyNameID>
										<xsl:value-of select="Party/ExternalPartyNameId"/>
									</ExternalPartyNameID>
									<GeographicFormatCode>
										<xsl:value-of select="string(Util:GetChildKey('8036',$partyIndNameCountryCode,'243'))"/>
									</GeographicFormatCode>
									<IsPrimary>false</IsPrimary>
									<IsTaxName>false</IsTaxName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<xsl:if test="PartyRecordPartyId !=''">
										<PartyID>
											<xsl:value-of select="PartyRecordPartyId"/>
										</PartyID>
									</xsl:if>
									<IsDefault>true</IsDefault>
								</PartyName>
							</PartyIndNameDetailWithExtendedDataDTO>
							<!-- Correspondencename Name Type Code is 07-->
							<PartyIndNameDetailWithExtendedDataDTO>
								<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
								<PartyIndName>
									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<Comment i:nil="true" />
									<FirstName>
										<xsl:value-of select="string(Util:GetPartialNameFromFullName('FirstName',Party/PartyCorrespondenceName))"/>
									</FirstName>

									<FullName>
										<xsl:value-of select="Party/PartyCorrespondenceName"/>
									</FullName>
									<LastName>
										<xsl:value-of select="string(Util:GetPartialNameFromFullName('LastName',Party/PartyCorrespondenceName))"/>
									</LastName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<MiddleName>
										<xsl:value-of select="string(Util:GetPartialNameFromFullName('MiddleName',Party/PartyCorrespondenceName))"/>
									</MiddleName>

									<NameTypeCode>07</NameTypeCode>
									<PrefixCode>
									</PrefixCode>
									<SuffixCode>
									</SuffixCode>
								</PartyIndName>
								<PartyName>
									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<AllowPartial>true</AllowPartial>
									<CountryCode>
										<xsl:value-of select="$partyIndNameCountryCode"/>
									</CountryCode>
									<EffectiveDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</EffectiveDate>
									<ExpirationDate>
										<xsl:value-of select="string(Util:GetMaxDate())"/>
									</ExpirationDate>
									<ExternalPartyNameID>
										<xsl:value-of select="Party/ExternalPartyNameId"/>
									</ExternalPartyNameID>
									<GeographicFormatCode>
										<xsl:value-of select="string(Util:GetChildKey('8036',$partyIndNameCountryCode,'243'))"/>
									</GeographicFormatCode>
									<IsPrimary>false</IsPrimary>
									<IsTaxName>false</IsTaxName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<xsl:if test="PartyRecordPartyId !=''">
										<PartyID>
											<xsl:value-of select="PartyRecordPartyId"/>
										</PartyID>
									</xsl:if>
									<IsDefault>false</IsDefault>
								</PartyName>
							</PartyIndNameDetailWithExtendedDataDTO>
							<!-- Legacy Name Type Code is 06-->
							<PartyIndNameDetailWithExtendedDataDTO>
								<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
								<PartyIndName>

									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<Comment>
										<xsl:value-of select="Party/PartyNameComments"/>
									</Comment>
									<FirstName>
										<xsl:value-of select="Party/PartyFirstName"/>
									</FirstName>
									<FullName>
										<xsl:value-of select="Party/PartyLegacyName"/>
									</FullName>
									<LastName>
										<xsl:value-of select="Party/PartyName"/>
									</LastName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<MiddleName>
										<xsl:value-of select="Party/PartyMiddleName"/>
									</MiddleName>
									<NameTypeCode>06</NameTypeCode>
									<PrefixCode>
										<xsl:value-of select="string(Util:GetOneRelatedItem('DCTNamePrefix',Party/PartyNamePrefixCode,'34'))"/>
									</PrefixCode>
									<SuffixCode>
										<xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameSuffix',Party/PartyNameSuffixCode,'48'))"/>
									</SuffixCode>
								</PartyIndName>
								<PartyName>
									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<AllowPartial>true</AllowPartial>
									<CountryCode>
										<xsl:value-of select="$partyIndNameCountryCode"/>
									</CountryCode>
									<EffectiveDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</EffectiveDate>
									<ExpirationDate>
										<xsl:value-of select="string(Util:GetMaxDate())"/>
									</ExpirationDate>
									<ExternalPartyNameID>
										<xsl:value-of select="Party/ExternalPartyNameId"/>
									</ExternalPartyNameID>
									<GeographicFormatCode>
										<xsl:value-of select="string(Util:GetChildKey('8036',$partyIndNameCountryCode,'243'))"/>
									</GeographicFormatCode>
									<IsPrimary>false</IsPrimary>
									<IsTaxName>false</IsTaxName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<xsl:if test="PartyRecordPartyId !=''">
										<PartyID>
											<xsl:value-of select="PartyRecordPartyId"/>
										</PartyID>
									</xsl:if>
									<IsDefault>false</IsDefault>
								</PartyName>
							</PartyIndNameDetailWithExtendedDataDTO>
							<xsl:call-template name="partyIndNameExtData" />
						</PartyIndNamesDetailWithExtendedData>

						<PartyLicensesWithExtendedData>
							<xsl:call-template name="partyLicenseExtData" />
						</PartyLicensesWithExtendedData>
						<PartyMembershipsWithExtendedData>
							<xsl:call-template name="partyReferenceExtData" />
						</PartyMembershipsWithExtendedData>
						<xsl:if test="count(./PartyPhones/PartyPhone) > 0">
							<PartyPhonesWithExtendedData>
								<xsl:call-template name="partyPhoneExtData" />
							</PartyPhonesWithExtendedData>
						</xsl:if>
						<PartyRelationsWithExtendedData>
							<xsl:call-template name="partyRelationExtData" />
						</PartyRelationsWithExtendedData>
					</PartyIndividualDetailWithExtendedDataDTO>
				</xsl:when>
				<xsl:otherwise>
					<PartyBusinessDetailWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
						<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
						<Party>
							<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
							<ACHPartyExternalID>
								<xsl:value-of select="Party/ACHPartyExternalId"/>
							</ACHPartyExternalID>
							<xsl:choose>
								<xsl:when test="Party/PartyOFACCheckNotRequired!=''">
									<BusinessPermitted>
										<xsl:value-of select="Party/PartyOFACCheckNotRequired"/>
									</BusinessPermitted>
								</xsl:when>
								<xsl:otherwise>
									<BusinessPermitted>U</BusinessPermitted>
								</xsl:otherwise>
							</xsl:choose>
							<CountryCode>
								<xsl:value-of select="$partyCountryCode"/>
							</CountryCode>
							<ExternalID>
								<xsl:value-of select="Party/ExternalId"/>
							</ExternalID>
							<!--TO DO : code decode-->
							<GeographicFormatCode>
								<xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
							</GeographicFormatCode>
							<IsInActive>false</IsInActive>
							<LastUpdatedDate>
								<xsl:value-of select="string(Util:GetCurrentDate())"/>
							</LastUpdatedDate>
							<Number i:nil="true" />
							<xsl:if test="PartyRecordPartyId !=''">
								<PartyID>
									<xsl:value-of select="PartyRecordPartyId"/>
								</PartyID>
							</xsl:if>
							<PartyTypeCode>
								<xsl:value-of select="string(Util:getASWPartyType(Party/PartyTypeCode))"/>
							</PartyTypeCode>
							<PartySubTypeCode>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',Party/PartyTypeCode,'PartySubType'))"/>
							</PartySubTypeCode>
							<xsl:if test="string(Util:ShowPartyTimeZone(Party/PartyTimeZone)) != ''">
								<PartyTimeZone>
									<xsl:value-of select="string(Util:GetChildKey('DCTTimeZones',Party/PartyTimeZone,'TimeZones'))"/>
								</PartyTimeZone>
							</xsl:if>
						</Party>
						<xsl:if test="count(./Locations/Location) > 0">
							<PartyAddressesDetailWithExtendedData>
								<xsl:call-template name="partyLocationExtendedData" />
							</PartyAddressesDetailWithExtendedData>
						</xsl:if>
						<PartyAgency i:nil="true" />
						<PartyBusiness>
							<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
							<BusinessTypeCode>
								<!--TODO:code decode mapping-->
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTBusinessType',Party/PartySubTypeCode,'427'))"/>
							</BusinessTypeCode>
							<EffectiveDate>
								<xsl:value-of select="string(Util:GetCurrentDate())"/>
							</EffectiveDate>
							<ExpirationDate>
								<xsl:value-of select="string(Util:GetMaxDate())"/>
							</ExpirationDate>
							<xsl:choose>
								<xsl:when test="Party/PartyTypeCode = 'AG'">
									<IsAgency>true</IsAgency>
								</xsl:when>
								<xsl:otherwise>
									<IsAgency>false</IsAgency>
								</xsl:otherwise>
							</xsl:choose>
							<IsSupplier>false</IsSupplier>
							<LastUpdatedDate>
								<xsl:value-of select="string(Util:GetCurrentDate())"/>
							</LastUpdatedDate>
							<xsl:if test="PartyRecordPartyId !=''">
								<PartyID>
									<xsl:value-of select="PartyRecordPartyId"/>
								</PartyID>
							</xsl:if>
							<PreferredContactType>
								<xsl:value-of select="Party/PreferredContactMethod"/>
							</PreferredContactType>
							<PreferredLanguage>
								<!--TODO:code decode mapping-->
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLanguageType',Party/PartyPreferredLanguageCode,'8037'))"/>
							</PreferredLanguage>
							<RegistrationID1>
								<xsl:value-of select="Party/PartyTaxId"/>
							</RegistrationID1>
                            <RegistrationID2>
                                <xsl:value-of select="Party/PartyTaxId2"/>  <!--#5814-Added for nzbn mapping  -->
                            </RegistrationID2>
							<RegistrationID3 i:nil="true" />
							<!-- the below line will not produce any xml output, but will set the party extended data in ASW Data DTO -->

							<xsl:for-each select="Party">
								<xsl:call-template name="ExtendedData">
									<xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>
									<xsl:with-param name="SuiteTagName">PartyBusinessSuiteExtendedData</xsl:with-param>
									<xsl:with-param name="AswTagName">BusinessExtendedData</xsl:with-param>
									<xsl:with-param name="PhysicalTableName">PARTY_BUS</xsl:with-param>
									<xsl:with-param name="LogicalTableName">lgclPartyBus</xsl:with-param>
									<xsl:with-param name="LogicalColumnName">PartyBusExtData</xsl:with-param>
								</xsl:call-template>
							</xsl:for-each>
						</PartyBusiness>
						<PartyBusNamesDetailWithExtendedData>
							<xsl:variable name="partyBusNameCountryCode">
								<xsl:choose>
									<xsl:when test="Party/PartyNameCountryCode !=''">
										<xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',Party/PartyNameCountryCode,'243'))"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',Party/PartyCountryCode,'243'))"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<!-- Primary Name Type Code is 01 -->
							<PartyBusNameDetailWithExtendedDataDTO>
								<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
								<PartyBusName>

									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<Comment>
										<xsl:value-of select="Party/PartyNameComments"/>
									</Comment>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<Name>
										<xsl:value-of select="Party/PartyName"/>
									</Name>
									<NameTypeCode>01</NameTypeCode>
								</PartyBusName>
								<PartyName>
									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<AllowPartial>true</AllowPartial>
									<CountryCode>
										<xsl:value-of select="$partyBusNameCountryCode"/>
									</CountryCode>
									<EffectiveDate>
										<xsl:choose>
											<xsl:when test="Party/PartyNameEffectiveDate !=''">
												<xsl:value-of select="string(Util:ConvertDateToAswFormat(Party/PartyNameEffectiveDate))"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="string(Util:GetCurrentDate())"/>
											</xsl:otherwise>
										</xsl:choose>
									</EffectiveDate>
									<ExpirationDate>
										<xsl:choose>
											<xsl:when test="Party/PartyNameExpirationDate !=''">
												<xsl:value-of select="string(Util:ConvertDateToAswFormat(Party/PartyNameExpirationDate))"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="string(Util:GetMaxDate())"/>
											</xsl:otherwise>
										</xsl:choose>
									</ExpirationDate>
									<ExternalPartyNameID>
										<xsl:value-of select="Party/ExternalPartyNameId"/>
									</ExternalPartyNameID>
									<!--TO DO : code decode-->
									<GeographicFormatCode>
										<xsl:value-of select="string(Util:GetChildKey('8036',$partyBusNameCountryCode,'243'))"/>
									</GeographicFormatCode>
									<IsPrimary>false</IsPrimary>
									<IsTaxName>false</IsTaxName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<xsl:if test="PartyRecordPartyId !=''">
										<PartyID>
											<xsl:value-of select="PartyRecordPartyId"/>
										</PartyID>
									</xsl:if>
									<IsDefault>true</IsDefault>
								</PartyName>
							</PartyBusNameDetailWithExtendedDataDTO>
							<!-- Correspondencename Name Type Code is 07-->
							<PartyBusNameDetailWithExtendedDataDTO>

								<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
								<PartyBusName>

									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<Comment i:nil="true" />
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<Name>
										<xsl:value-of select="Party/PartyCorrespondenceName"/>
									</Name>
									<NameTypeCode>07</NameTypeCode>
								</PartyBusName>
								<PartyName>

									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<AllowPartial>true</AllowPartial>
									<CountryCode>
										<xsl:value-of select="$partyBusNameCountryCode"/>
									</CountryCode>
									<EffectiveDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</EffectiveDate>
									<ExpirationDate>
										<xsl:value-of select="string(Util:GetMaxDate())"/>
									</ExpirationDate>
									<ExternalPartyNameID>
										<xsl:value-of select="Party/ExternalPartyNameId"/>
									</ExternalPartyNameID>
									<!--TO DO : code decode-->
									<GeographicFormatCode>
										<xsl:value-of select="string(Util:GetChildKey('8036',$partyBusNameCountryCode,'243'))"/>
									</GeographicFormatCode>
									<IsPrimary>false</IsPrimary>
									<IsTaxName>false</IsTaxName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<xsl:if test="PartyRecordPartyId !=''">
										<PartyID>
											<xsl:value-of select="PartyRecordPartyId"/>
										</PartyID>
									</xsl:if>
									<IsDefault>false</IsDefault>
								</PartyName>
							</PartyBusNameDetailWithExtendedDataDTO>
							<!-- Legacy Name Type Code is 06-->
							<PartyBusNameDetailWithExtendedDataDTO>

								<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
								<PartyBusName>

									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<Comment i:nil="true" />
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<Name>
										<xsl:value-of select="Party/PartyLegacyName"/>
									</Name>
									<NamePhonetic i:nil="true" />
									<NameSoundex i:nil="true" />
									<NameTypeCode>06</NameTypeCode>
									<NameUpperCase i:nil="true" />
								</PartyBusName>
								<PartyName>

									<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
									<AllowPartial>true</AllowPartial>
									<CountryCode>
										<xsl:value-of select="$partyBusNameCountryCode"/>
									</CountryCode>
									<EffectiveDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</EffectiveDate>
									<ExpirationDate>
										<xsl:value-of select="string(Util:GetMaxDate())"/>
									</ExpirationDate>
									<ExternalPartyNameID>
										<xsl:value-of select="Party/ExternalPartyNameId"/>
									</ExternalPartyNameID>
									<GeographicFormatCode>
										<xsl:value-of select="string(Util:GetChildKey('8036',$partyBusNameCountryCode,'243'))"/>
									</GeographicFormatCode>
									<IsPrimary>false</IsPrimary>
									<IsTaxName>false</IsTaxName>
									<LastUpdatedDate>
										<xsl:value-of select="string(Util:GetCurrentDate())"/>
									</LastUpdatedDate>
									<xsl:if test="PartyRecordPartyId !=''">
										<PartyID>
											<xsl:value-of select="PartyRecordPartyId"/>
										</PartyID>
									</xsl:if>
									<IsDefault>false</IsDefault>
								</PartyName>
							</PartyBusNameDetailWithExtendedDataDTO>
							<xsl:call-template name="partyBusNameExtData" />

						</PartyBusNamesDetailWithExtendedData>
						<xsl:if test="Party/PartyComments != ''">
							<PartyComment>

								<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
								<Comment>
									<xsl:value-of select="Party/PartyComments"/>
								</Comment>
								<EffectiveDate>
									<xsl:value-of select="string(Util:GetCurrentDate())"/>
								</EffectiveDate>
								<ExpirationDate>
									<xsl:value-of select="string(Util:GetMaxDate())"/>
								</ExpirationDate>
								<LastUpdatedDate>
									<xsl:value-of select="string(Util:GetCurrentDate())"/>
								</LastUpdatedDate>
								<xsl:if test="PartyRecordPartyId !=''">
									<PartyID>
										<xsl:value-of select="PartyRecordPartyId"/>
									</PartyID>
								</xsl:if>
							</PartyComment>
						</xsl:if>
						<xsl:if test="count(./PartyEmails/PartyEmail) > 0">
							<PartyEmailsWithExtendedData>
								<xsl:call-template name="partyEmailExtData" />
							</PartyEmailsWithExtendedData>
						</xsl:if>
						<PartyLicensesWithExtendedData>
							<xsl:call-template name="partyLicenseExtData" />
						</PartyLicensesWithExtendedData>
						<PartyMembershipsWithExtendedData>
							<xsl:call-template name="partyReferenceExtData" />
						</PartyMembershipsWithExtendedData>
						<xsl:if test="count(./PartyPhones/PartyPhone) > 0">
							<PartyPhonesWithExtendedData>
								<xsl:call-template name="partyPhoneExtData" />
							</PartyPhonesWithExtendedData>
						</xsl:if>
						<PartyRelationsWithExtendedData>
							<xsl:call-template name="partyRelationExtData" />
						</PartyRelationsWithExtendedData>
					</PartyBusinessDetailWithExtendedDataDTO>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>