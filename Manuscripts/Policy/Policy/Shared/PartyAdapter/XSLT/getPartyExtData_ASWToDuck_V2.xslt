<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="PartyLocationTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyPhoneTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyBusNameTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyIndNameTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyEmailTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyReferenceTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyLicenseTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyRelationshipTemplate_ASWToDuck.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />


	<xsl:template match="/">
		<xsl:choose>
			<!--This condition is to add the Parties tag over the response in case of getpartylite-->
			<xsl:when test="$MethodName = 'GetPartyDetails'">
				<Parties>
					<xsl:call-template name="partyRecordTemplate">
					</xsl:call-template>
				</Parties>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="partyRecordTemplate">
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="partyRecordTemplate">
		<PartyRecord xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<!-- If condition on Party Type, seperate templates for both Individual and Business party-->
			<xsl:choose>
				<!--Party Type = Individual-->
				<xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyIndividualDetailWithExtendedDataDTO/Party/PartyTypeCode)) = string(Util:getBasePartyTypeFromASWPartyType('IND'))">
					<xsl:for-each select="PartyIndividualDetailWithExtendedDataDTO">
						<PartyRecordPartyId>
							<xsl:value-of select="Party/PartyID"/>
						</PartyRecordPartyId>
						<xsl:call-template name="indPartyInfo" />
      			<xsl:if test="count(PartyAddressesDetailWithExtendedData/PartyAddressDetailWithExtendedDataDTO/Address) > 0">
							<Locations  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
								<xsl:for-each select="PartyAddressesDetailWithExtendedData/PartyAddressDetailWithExtendedDataDTO/Address">
									<xsl:call-template name="indPartyAddress" />
								</xsl:for-each>
							</Locations>
						</xsl:if>
						<xsl:if test="count(PartyEmailsWithExtendedData/PartyEmailWithExtendedDataDTO/PartyEmail) > 0">
							<PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
								<xsl:for-each select="PartyEmailsWithExtendedData/PartyEmailWithExtendedDataDTO/PartyEmail">
									<xsl:call-template name="indPartyEmails" />
								</xsl:for-each>
							</PartyEmails>
						</xsl:if>
						<xsl:if test="count(PartyPhonesWithExtendedData/PartyPhoneWithExtendedDataDTO/PartyPhone) > 0">
							<PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
								<xsl:for-each select="PartyPhonesWithExtendedData/PartyPhoneWithExtendedDataDTO/PartyPhone">
									<xsl:call-template name="indPartyPhones" />
								</xsl:for-each>
							</PartyPhones>
						</xsl:if>
						<xsl:if test="$MethodName != 'GetPartyDetails'">
							<xsl:if test="count(PartyMembershipsWithExtendedData/PartyMembershipWithExtendedDataDTO/PartyMembership) > 0">
								<PartyReferences xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
									<xsl:for-each select="PartyMembershipsWithExtendedData/PartyMembershipWithExtendedDataDTO/PartyMembership">
										<xsl:call-template name="indPartyReferences" />
									</xsl:for-each>
								</PartyReferences>
							</xsl:if>
							<xsl:if test="count(PartyLicensesWithExtendedData/PartyLicenseWithExtendedDataDTO/PartyLicense) > 0">
								<PartyLicenses xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
									<xsl:for-each select="PartyLicensesWithExtendedData/PartyLicenseWithExtendedDataDTO/PartyLicense">
										<xsl:call-template name="indPartyLicences" />
									</xsl:for-each>
								</PartyLicenses>
							</xsl:if>
							<xsl:if test="count(PartyRelationsWithExtendedData/PartyRelationWithExtendedDataDTO/PartyRelation) > 0">
								<PartyRelationships xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
									<xsl:for-each select="PartyRelationsWithExtendedData/PartyRelationWithExtendedDataDTO/PartyRelation">
										<xsl:call-template name="indPartyRelationship" />
									</xsl:for-each>
								</PartyRelationships>
							</xsl:if>
							<xsl:if test="count(PartyIndNamesDetailWithExtendedData/PartyIndNameDetailWithExtendedDataDTO/PartyName[IsDefault != 'true']) > 0">
								<PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
									<xsl:for-each select="PartyIndNamesDetailWithExtendedData/PartyIndNameDetailWithExtendedDataDTO[PartyName[IsDefault != 'true']]">
										<xsl:if test="PartyIndName/NameTypeCode != '06' and PartyIndName/NameTypeCode != '07'">
											<xsl:for-each select="PartyIndName">
												<xsl:call-template name="PartyIndName"/>
											</xsl:for-each>
										</xsl:if>
									</xsl:for-each>
								</PartyOtherNames>
							</xsl:if>
						</xsl:if>
					</xsl:for-each>
				</xsl:when>

				<!--Party Type = Business-->
				<xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyBusinessDetailWithExtendedDataDTO/Party/PartyTypeCode)) = string(Util:getBasePartyTypeFromASWPartyType('BUS'))">
					<xsl:for-each select="PartyBusinessDetailWithExtendedDataDTO">
						<PartyRecordPartyId>
							<xsl:value-of select="Party/PartyID"/>
						</PartyRecordPartyId>

						<xsl:variable name="AgencyID">
							<xsl:if test="PartyBusiness/IsAgency = 'true' and $MethodName = 'GetPartyDetails'">
								<xsl:for-each select="PartyMembership/PartyMembershipDTO[MembershipTypeCode = 'AGCX']">
									<xsl:value-of select="MembershipID" />
								</xsl:for-each>
							</xsl:if>
						</xsl:variable>

						<xsl:choose>
							<!--If its an agency party then do not return all data, just partyid, agencyid and partytypecode is required in the response-->
							<xsl:when test="$AgencyID != ''">
								<AgencyId>
									<xsl:value-of select="$AgencyID" />
								</AgencyId>
								<Party>
									<PartyTypeCode>AG</PartyTypeCode>
								</Party>
							</xsl:when>
							<!--if not agency, then return all data-->
							<xsl:otherwise>
								<xsl:call-template name="busPartyInfo" />

								<xsl:if test="count(PartyAddressesDetailWithExtendedData/PartyAddressDetailWithExtendedDataDTO/Address) > 0">
									<Locations  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
										<xsl:for-each select="PartyAddressesDetailWithExtendedData/PartyAddressDetailWithExtendedDataDTO/Address">
											<xsl:call-template name="indPartyAddress" />
										</xsl:for-each>
									</Locations>
								</xsl:if>

								<xsl:if test="count(PartyEmailsWithExtendedData/PartyEmailWithExtendedDataDTO/PartyEmail) > 0">
									<PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
										<xsl:for-each select="PartyEmailsWithExtendedData/PartyEmailWithExtendedDataDTO/PartyEmail">
											<xsl:call-template name="indPartyEmails" />
										</xsl:for-each>
									</PartyEmails>
								</xsl:if>

								<xsl:if test="count(PartyPhonesWithExtendedData/PartyPhoneWithExtendedDataDTO/PartyPhone) > 0">
									<PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
										<xsl:for-each select="PartyPhonesWithExtendedData/PartyPhoneWithExtendedDataDTO/PartyPhone">
											<xsl:call-template name="indPartyPhones" />
										</xsl:for-each>
									</PartyPhones>
								</xsl:if>

								<xsl:if test="$MethodName != 'GetPartyDetails'">
									<xsl:if test="count(PartyMembershipsWithExtendedData/PartyMembershipWithExtendedDataDTO/PartyMembership) > 0">
										<PartyReferences xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
											<xsl:for-each select="PartyMembershipsWithExtendedData/PartyMembershipWithExtendedDataDTO/PartyMembership">
												<xsl:call-template name="indPartyReferences" />
											</xsl:for-each>
										</PartyReferences>
									</xsl:if>
									<xsl:if test="count(PartyLicensesWithExtendedData/PartyLicenseWithExtendedDataDTO/PartyLicense) > 0">
										<PartyLicenses xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
											<xsl:for-each select="PartyLicensesWithExtendedData/PartyLicenseWithExtendedDataDTO/PartyLicense">
												<xsl:call-template name="indPartyLicences" />
											</xsl:for-each>
										</PartyLicenses>
									</xsl:if>
									<xsl:if test="count(PartyRelationsWithExtendedData/PartyRelationWithExtendedDataDTO/PartyRelation) > 0">
										<PartyRelationships xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
											<xsl:for-each select="PartyRelationsWithExtendedData/PartyRelationWithExtendedDataDTO/PartyRelation">
												<xsl:call-template name="indPartyRelationship" />
											</xsl:for-each>
										</PartyRelationships>
									</xsl:if>
									<xsl:if test="count(PartyBusNamesDetailWithExtendedData/PartyBusNameDetailWithExtendedDataDTO/PartyName[IsDefault != 'true']) > 0">
										<PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
											<xsl:for-each select="PartyBusNamesDetailWithExtendedData/PartyBusNameDetailWithExtendedDataDTO[PartyName[IsDefault != 'true']]/PartyBusName">
												<xsl:if test="NameTypeCode != '06' and NameTypeCode != '07'">
													<xsl:call-template name="PartyBusName" />
												</xsl:if>
											</xsl:for-each>
										</PartyOtherNames>
									</xsl:if>
								</xsl:if>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:when>
			</xsl:choose>

			<xsl:if test="$MethodName != 'GetPartyDetails'">
				<xsl:call-template name="ResponseInfo">
					<xsl:with-param name="ReturnCode">0</xsl:with-param>
					<xsl:with-param name="NotificationResponse"/>
				</xsl:call-template>
			</xsl:if>
		</PartyRecord>
	</xsl:template>

	<xsl:template name="indPartyInfo" >
		<Party>
			<PartyId>
				<xsl:value-of select="Party/PartyID" />
			</PartyId>
			<PartyNumber>
				<xsl:value-of select="Party/Number" />
			</PartyNumber>

      <PartyExternalId>
        <xsl:value-of select="Party/ExternalID" />
      </PartyExternalId>
      <ACHPartyExternalId>
        <xsl:value-of select="Party/ACHPartyExternalID" />
      </ACHPartyExternalId>
      <ExternalPartyNameId>
        <xsl:value-of select="PartyIndNamesDetailWithExtendedData/PartyIndNameDetailWithExtendedDataDTO/PartyName/ExternalPartyNameID" />
      </ExternalPartyNameId>
			<xsl:for-each select="PartyIndNamesDetailWithExtendedData/PartyIndNameDetailWithExtendedDataDTO/PartyName[IsDefault = 'true']">
				<xsl:variable name="partyName" select="concat(../../PartyIndName/FirstName,' ',../../PartyIndName/LastName)" />

				<PartyName>
					<xsl:value-of select="../PartyIndName/LastName" />
				</PartyName>
				<PartyFirstName>
					<xsl:value-of select="../PartyIndName/FirstName" />
				</PartyFirstName>
				<PartyMiddleName>
					<xsl:value-of select="../PartyIndName/MiddleName" />
				</PartyMiddleName>
				<PartyNamePrefixCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',../PartyIndName/PrefixCode,'34'))"/>
				</PartyNamePrefixCode>
				<PartyNameSuffixCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',../PartyIndName/SuffixCode,'48'))"/>
				</PartyNameSuffixCode>
				<xsl:choose>
					<xsl:when test="string(../../../Party/PartySubTypeCode) !=''">
						<PartyTypeCode>
							<xsl:value-of select="string(Util:GetChildKey('DCTPartyType',../../../Party/PartySubTypeCode,'PartySubType'))"/>
						</PartyTypeCode>
					</xsl:when>
					<xsl:otherwise>
						<PartyTypeCode>
							<xsl:value-of select="string(Util:GetChildKey('DCTPartyType',../../../Party/PartyTypeCode,'8001'))"/>
						</PartyTypeCode>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$MethodName != 'GetPartyDetails'">
					<!--TO DO : Find what is subtype-->
					<PartySubTypeCode xsi:nil="true" />
				</xsl:if>
				<PartyGenderCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTGender',../../../PartyIndividual/GenderCode,'51'))"/>
				</PartyGenderCode>
				<PartyBirthDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(../../../PartyIndividual/DateOfBirth, false))" />
				</PartyBirthDate>
				<PartyDeathDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(../../../PartyIndividual/DateOfDeath, false))" />
				</PartyDeathDate>
				<PreferredContactMethod>
					<xsl:value-of select="../../../PartyIndividual/PreferredContactType" />
				</PreferredContactMethod>
				<PartyNumberOfDependents>
					<xsl:value-of select="../../../PartyIndividual/NumberOfDependents" />
				</PartyNumberOfDependents>
				<xsl:choose>
					<xsl:when test ="../../../PartyIndividual/IsCompanyPersonnel='false'">
						<PartyIsCompanyPersonnel>0</PartyIsCompanyPersonnel>
					</xsl:when>
					<xsl:otherwise>
						<PartyIsCompanyPersonnel>1</PartyIsCompanyPersonnel>
					</xsl:otherwise>
				</xsl:choose>
				<PartyProfession>
					<xsl:value-of select="../../../PartyIndividual/ProfessionCode" />
				</PartyProfession>
				<PartyOFACCheckNotRequired>
					<xsl:value-of select="../../../Party/BusinessPermitted"/>
				</PartyOFACCheckNotRequired>
				<PartyComments>
					<xsl:value-of select="../../../PartyComment/Comment"/>
				</PartyComments>
				<PartyNameEffectiveDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
				</PartyNameEffectiveDate>
				<PartyNameExpirationDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
				</PartyNameExpirationDate>
				<PartyNameComments>
					<xsl:value-of select="../PartyIndName/Comment"/>
				</PartyNameComments>
				<xsl:if test="$MethodName != 'GetPartyDetails'">
					<PartyMaritalStatusCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTMaritalStatus',../../../PartyIndividual/MaritalStatusCode,'35'))"/>
					</PartyMaritalStatusCode>
					<PartyTaxId>
						<!--Mapping it to SSN in ASW-->
						<xsl:value-of select="../../../PartyIndividual/SpecificPurposeID"/>  <!--#5814-Removed SSN format mask as its not required for ird number-->
					</PartyTaxId>
					<PartyNationality xsi:nil="true" />
					<PartyPartyOwner xsi:nil="true" />
					<!--/-->
					<PartyPreferredLanguageCode >
						<xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',../../../PartyIndividual/PreferredLanguage,'8037'))"/>
					</PartyPreferredLanguageCode>
				</xsl:if>

				<xsl:for-each select="../../PartyIndNameDetailWithExtendedDataDTO/PartyIndName[NameTypeCode = '06' or NameTypeCode = '07']">
					<xsl:choose>
						<xsl:when test="NameTypeCode='07'">
							<PartyCorrespondenceName>
								<xsl:value-of select="FullName" />
							</PartyCorrespondenceName>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test="$MethodName != 'GetPartyDetails'">
								<PartyLegacyName>
									<xsl:value-of select="FullName" />
								</PartyLegacyName>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
				<PartyCountryCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../../../Party/CountryCode,'243'))"/>
				</PartyCountryCode>
				<PartyNameCountryCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../PartyName/CountryCode,'243'))"/>
				</PartyNameCountryCode>
				<xsl:if test="$MethodName != 'GetPartyDetails'">
					<PartyLockingTS>
						<xsl:value-of select="../../../Party/LastTransactionID" />
					</PartyLockingTS>
					<xsl:for-each select="../../../PartyIndividual">

						<xsl:for-each select="./IndividualExtendedData/ExtendedFields/ExtendedFieldDTO">
							<xsl:call-template name="ASWExtendedDataToDuck">
							  <xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>
							</xsl:call-template>
						</xsl:for-each>
						
						<PartyIndividualSuiteExtendedData>
							<xsl:for-each select="./IndividualExtendedData/ExtendedFields/ExtendedFieldDTO">
								<xsl:call-template name="SuiteASWExtendedDataToDuck">
									<xsl:with-param name="SuiteTagName">PartyIndividualSuiteExtendedData</xsl:with-param>
								</xsl:call-template>
							</xsl:for-each>
						</PartyIndividualSuiteExtendedData>
						
					</xsl:for-each>
				</xsl:if>
			</xsl:for-each>

		
  </Party>
	</xsl:template>
	<xsl:template name="busPartyInfo">
		<Party>
			<PartyId>
				<xsl:value-of select="Party/PartyID" />
			</PartyId>
			<PartyNumber>
				<xsl:value-of select="Party/Number" />
			</PartyNumber>
      <PartyExternalId>
        <xsl:value-of select="Party/ExternalID" />
      </PartyExternalId>
      <ACHPartyExternalId>
        <xsl:value-of select="Party/ACHPartyExternalID" />
      </ACHPartyExternalId>
      <ExternalPartyNameId>
        <xsl:value-of select="PartyBusNamesDetailWithExtendedData/PartyBusNameDetailWithExtendedDataDTO/PartyName/ExternalPartyNameID" />
      </ExternalPartyNameId>
			<xsl:for-each select="PartyBusNamesDetailWithExtendedData/PartyBusNameDetailWithExtendedDataDTO/PartyName[IsDefault = 'true']">
				<PartyName>
					<xsl:value-of select="../PartyBusName/Name" />
				</PartyName>
				<PartyFirstName>
					<!-- TO DO : this field is not available in ASW-->
				</PartyFirstName>
				<PartyMiddleName>
					<!-- TO DO : this field is not available in ASW-->
				</PartyMiddleName>
				<PartyNamePrefixCode>
					<!-- TO DO : this field is not available in ASW-->
				</PartyNamePrefixCode>
				<PartyNameSuffixCode>
					<!-- TO DO : this field is not available in ASW-->
				</PartyNameSuffixCode>
				<xsl:choose>
					<xsl:when test="string(../../../Party/PartySubTypeCode) != ''">
						<PartyTypeCode>
							<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',../../../Party/PartySubTypeCode,'PartySubType',../../../PartyBusiness/IsAgency))"/>
						</PartyTypeCode>
					</xsl:when>
					<xsl:otherwise>
						<PartyTypeCode>
							<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',../../../Party/PartyTypeCode,'8001',../../../PartyBusiness/IsAgency))"/>
						</PartyTypeCode>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:if test="$MethodName != 'GetPartyDetails'">
					<PartySubTypeCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTBusinessType',../../../PartyBusiness/BusinessTypeCode,'427'))"/>
					</PartySubTypeCode>
				</xsl:if>
				<PartyGenderCode>
					<!-- TO DO : this field is not available in ASW-->
				</PartyGenderCode>
				<PartyBirthDate>
					<!-- TO DO : this field is not available in ASW-->
				</PartyBirthDate>
				<xsl:choose>
					<xsl:when test ="../../../PartyBusiness/IsSupplier='false'">
						<PartySupplier>0</PartySupplier>
					</xsl:when>
					<xsl:otherwise>
						<PartySupplier>1</PartySupplier>
					</xsl:otherwise>
				</xsl:choose>
				<PreferredContactMethod>
					<xsl:value-of select="../../../PartyBusiness/PreferredContactType" />
				</PreferredContactMethod>
				<PartyOFACCheckNotRequired>
					<xsl:value-of select="../../../Party/BusinessPermitted"/>
				</PartyOFACCheckNotRequired>
				<PartyComments>
					<xsl:value-of select="../../../PartyComment/Comment"/>
				</PartyComments>
				<PartyNameEffectiveDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
				</PartyNameEffectiveDate>
				<PartyNameExpirationDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
				</PartyNameExpirationDate>
				<PartyNameComments>
					<xsl:value-of select="../PartyBusName/Comment"/>
				</PartyNameComments>
				<xsl:if test="$MethodName != 'GetPartyDetails'">
					<PartyMaritalStatusCode>
						<!-- TO DO : this field is not available in ASW-->
					</PartyMaritalStatusCode>
					<!--TO DO : properties not found in ASW-->
					<PartyTaxId>
						<!--Mapping it to TIN of ASW-->
						<xsl:value-of select="../../../PartyBusiness/RegistrationID1" />
					</PartyTaxId>
					<PartyTaxId2>
						<!--Mapping it to TIN of ASW-->
						<xsl:value-of select="../../../PartyBusiness/RegistrationID2" />  <!--#5814-Added for nzbn mapping  -->
					</PartyTaxId2>
					<PartyNationality xsi:nil="true" />
					<PartyPartyOwner xsi:nil="true" />
					<PartyPreferredLanguageCode >
						<xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',../../../PartyBusiness/PreferredLanguage,'8037'))"/>
					</PartyPreferredLanguageCode>
				</xsl:if>
				<xsl:for-each select="../../PartyBusNameDetailWithExtendedDataDTO/PartyBusName[NameTypeCode = '06' or NameTypeCode = '07']">
					<xsl:choose>
						<xsl:when test="NameTypeCode='07'">
							<PartyCorrespondenceName>
								<xsl:value-of select="Name" />
							</PartyCorrespondenceName>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test="$MethodName != 'GetPartyDetails'">
								<PartyLegacyName>
									<xsl:value-of select="Name" />
								</PartyLegacyName>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
				<PartyCountryCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../../../Party/CountryCode,'243'))"/>
				</PartyCountryCode>
				<PartyNameCountryCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../PartyName/CountryCode,'243'))"/>
				</PartyNameCountryCode>
				<xsl:if test="$MethodName != 'GetPartyDetails'">
					<PartyLockingTS>
						<xsl:value-of select="../../../Party/LastTransactionID" />
					</PartyLockingTS>
					<xsl:for-each select="../../../PartyBusiness">
						
						<xsl:for-each select="./BusinessExtendedData/ExtendedFields/ExtendedFieldDTO">
							<xsl:call-template name="ASWExtendedDataToDuck">
							  <xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>
							</xsl:call-template>
						</xsl:for-each>
						
						<PartyBusinessSuiteExtendedData>
							<xsl:for-each select="./BusinessExtendedData/ExtendedFields/ExtendedFieldDTO">
								<xsl:call-template name="SuiteASWExtendedDataToDuck">
									<xsl:with-param name="SuiteTagName">PartyBusinessSuiteExtendedData</xsl:with-param>
								</xsl:call-template>
							</xsl:for-each>
						</PartyBusinessSuiteExtendedData>
						
					</xsl:for-each>
				</xsl:if>
			</xsl:for-each>
		</Party>
	</xsl:template>
</xsl:stylesheet>