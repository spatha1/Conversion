<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="PartyLocationTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyPhoneTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyEmailTemplate_ASWToDuck.xslt"/>

	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
	<xsl:template match="/PartyDetailDTO">
		<PartyRecord xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:variable name="partyId">
				<xsl:value-of select="string(Util:GetValueByKey('PartyId'))" />
			</xsl:variable>
			<PartyRecordId>
				<xsl:value-of select="$partyId"/>
			</PartyRecordId>
			<!-- If condition on Party Type, seperate templates for both Individual and Business party-->
			<xsl:choose>
				<!--Party Type = Individual-->
				<xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyIndividualDetail/Party/PartyTypeCode)) = string(Util:getBasePartyTypeFromASWPartyType('IND'))">
					<xsl:call-template name="indPartyInfo" />
				</xsl:when>
				<!--Party Type = Business-->
				<xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyBusinessDetail/Party/PartyTypeCode)) = string(Util:getBasePartyTypeFromASWPartyType('BUS'))">
					<xsl:call-template name="busPartyInfo" />
				</xsl:when>
			</xsl:choose>
			<xsl:call-template name="ResponseInfo">
				<xsl:with-param name="ReturnCode">0</xsl:with-param>
				<xsl:with-param name="NotificationResponse"/>
			</xsl:call-template>
		</PartyRecord>
	</xsl:template>

	<xsl:template name="indPartyInfo" >
		<PartyCountryCode>
			<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',PartyIndividualDetail/Party/CountryCode,'243'))"/>
		</PartyCountryCode>
		<Party xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO/PartyName[IsDefault = 'true']">
				<xsl:variable name="partyName" select="concat(../PartyIndName/FirstName,' ',../PartyIndName/LastName)" />
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
					<!--TO DO : Code Decode value-->
					<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',../PartyIndName/PrefixCode,'34'))"/>
				</PartyNamePrefixCode>
				<PartyNameSuffixCode>
					<!--TO DO : Code Decode value-->
					<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',../PartyIndName/SuffixCode,'48'))"/>
				</PartyNameSuffixCode>
				<PartyGender>
					<xsl:value-of select="string(Util:GetChildKey('DCTGender',../../../PartyIndividual/GenderCode,'51'))" />
				</PartyGender>
				<PartyMaritalStatusCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTMaritalStatus',../../../PartyIndividual/MaritalStatusCode,'35'))" />
				</PartyMaritalStatusCode>
				<PreferredLanguageCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',../../../PartyIndividual/PreferredLanguage,'8037'))" />
				</PreferredLanguageCode>
				<PartyBirthDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(../../../PartyIndividual/DateOfBirth, false))" />
				</PartyBirthDate>
				<PartyDeathDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(../../../PartyIndividual/DateOfDeath, false))" />
				</PartyDeathDate>
				<PartyComments>
					<xsl:value-of select="../../../PartyComment/Comment"/>
				</PartyComments>
				<PreferredContactMethod>
					<xsl:value-of select="../../../PartyIndividual/PreferredContactType" />
				</PreferredContactMethod>
				<xsl:for-each select="../../PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '06' or NameTypeCode = '07']">
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
				<PartyDeletedIndicator>
					<xsl:value-of select="string(Util:GetDeletedIndicator(../../Party/IsInActive))"/>
				</PartyDeletedIndicator>
				<xsl:choose>
					<xsl:when test="string(../../../Party/PartySubTypeCode) != ''">
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
				<PartyTaxId>
					<!--Mapping it to SSN in ASW-->
					<xsl:value-of select="../../../PartyIndividual/SpecificPurposeID" />  <!--#5814-Removed SSN format mask as its not required for ird number-->
				</PartyTaxId>
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
				
				<PartyLockingTS>
					<xsl:value-of select="../../../Party/LastTransactionID" />
				</PartyLockingTS>
			</xsl:for-each>
		</Party>
		<PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO/PartyName[IsDefault != 'true']">
				<xsl:if test="string(Util:GetChildKey('DCTNameType',../PartyIndName/NameTypeCode,'29')) = 'DBA'">
					<PartyOtherName>
						<PartyOtherNameId>
							<xsl:value-of select="../PartyIndName/PartyIndNameID" />
						</PartyOtherNameId>
						<OtherNamePartyName>
							<xsl:value-of select="../PartyIndName/LastName" />
						</OtherNamePartyName>
						<PartyOtherNamesLockingTS>
							<xsl:value-of select="../PartyIndName/LastTransactionID" />
						</PartyOtherNamesLockingTS>
						<xsl:for-each select="../PartyIndName">
						
						<xsl:for-each select="./IndividualNameExtendedData/ExtendedFields/ExtendedFieldDTO">
								   <xsl:call-template name="ASWExtendedDataToDuck">
										<xsl:with-param name="TagName">OtherNameExtendedData</xsl:with-param>		
								  </xsl:call-template>
							</xsl:for-each>	
						<PartyOtherNameSuiteExtendedData>
							<xsl:for-each select="./IndividualNameExtendedData/ExtendedFields/ExtendedFieldDTO">
								<xsl:call-template name="SuiteASWExtendedDataToDuck">
									<xsl:with-param name="SuiteTagName">PartyOtherNameSuiteExtendedData</xsl:with-param>
								</xsl:call-template>
							</xsl:for-each>
						</PartyOtherNameSuiteExtendedData>
				
						</xsl:for-each>
					</PartyOtherName>
				</xsl:if>
			</xsl:for-each>
		</PartyOtherNames>
		<PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyIndividualDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true' or PhoneTypeCode = string(Util:GetOneRelatedItem('DCTPhoneType','F','26'))]">
				<xsl:sort select="IsPrimary" order="descending" />
				<xsl:sort select="LastUpdatedDate" order="descending" />
				<xsl:call-template name="indPartyPhones" />
			</xsl:for-each>
		</PartyPhones>
		<PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyIndividualDetail/PartyEmail/PartyEmailDTO[IsPrimary = 'true']">
				<xsl:sort select="IsPrimary" order="descending" />
				<xsl:call-template name="indPartyEmails" />
			</xsl:for-each>
		</PartyEmails>
		<!--TO DO Fix location fields-->
		<Locations xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address">
				<xsl:call-template name="indPartyAddress" />
			</xsl:for-each>
		</Locations>
	</xsl:template>
	<xsl:template name="busPartyInfo">
		<PartyCountryCode>
			<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',PartyBusinessDetail/Party/CountryCode,'243'))"/>
		</PartyCountryCode>
		<Party xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO/PartyName[IsDefault = 'true']">
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
				<PartyGender>
					<!-- TO DO : this field is not available in ASW-->
				</PartyGender>
				<PartyBirthDate>
					<!-- TO DO : this field is not available in ASW-->
				</PartyBirthDate>
				<PartyDeathDate>
					<!-- TO DO : this field is not available in ASW-->
				</PartyDeathDate>
				<PartyComments>
					<xsl:value-of select="../../../PartyComment/Comment"/>
				</PartyComments>
				<PreferredContactMethod>
					<xsl:value-of select="../../../PartyBusiness/PreferredContactType" />
				</PreferredContactMethod>
				<xsl:for-each select="../../PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '06' or NameTypeCode = '07']">
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
				<PartyDeletedIndicator>
					<xsl:value-of select="string(Util:GetDeletedIndicator(../../Party/IsInActive))"/>
				</PartyDeletedIndicator>
				<xsl:choose>
					<xsl:when test="string(../../../Party/PartySubTypeCode) != ''">
						<PartyTypeCode>
							<!--IsAgency added for AG Party type code-->
							<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',../../../Party/PartySubTypeCode,'PartySubType',../../../PartyBusiness/IsAgency))"/>
						</PartyTypeCode>
					</xsl:when>
					<xsl:otherwise>
						<PartyTypeCode>
							<!--IsAgency added for AG Party type code-->
							<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',../../../Party/PartyTypeCode,'8001',../../../PartyBusiness/IsAgency))"/>
						</PartyTypeCode>
					</xsl:otherwise>
				</xsl:choose>
				<!--TO DO : properties not found in ASW-->
				<PartyTaxId>
					<!--Mapping it to TIN of ASW-->
					<xsl:value-of select="../../../PartyBusiness/RegistrationID1" />
				</PartyTaxId>
				<PartyTaxId2>
					<xsl:value-of select="../../../PartyBusiness/RegistrationID2" />  <!--#5814-Added for nzbn mapping  -->
				</PartyTaxId2>
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
			</xsl:for-each>
			
		</Party>
		<PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO/PartyName[IsDefault != 'true']">
				<xsl:if test="string(Util:GetChildKey('DCTNameType',../PartyBusName/NameTypeCode,'29')) = 'DBA'">
					<PartyOtherName>
						<PartyOtherNameId>
							<xsl:value-of select="../PartyBusName/PartyBusNameID" />
						</PartyOtherNameId>
						<OtherNamePartyName>
							<xsl:value-of select="../PartyBusName/Name" />
						</OtherNamePartyName>
						<PartyOtherNamesLockingTS>
							<xsl:value-of select="../PartyBusName/LastTransactionID" />
						</PartyOtherNamesLockingTS>
						<xsl:for-each select="../PartyBusName">
							 <xsl:for-each select="./BusinessNameExtendedData/ExtendedFields/ExtendedFieldDTO">
								   <xsl:call-template name="ASWExtendedDataToDuck">
										<xsl:with-param name="TagName">OtherNameExtendedData</xsl:with-param>		
								  </xsl:call-template>
							</xsl:for-each>	
							<PartyOtherNameSuiteExtendedData>
								<xsl:for-each select="./BusinessNameExtendedData/ExtendedFields/ExtendedFieldDTO">
									<xsl:call-template name="SuiteASWExtendedDataToDuck">
										<xsl:with-param name="SuiteTagName">PartyOtherNameSuiteExtendedData</xsl:with-param>
									</xsl:call-template>
								</xsl:for-each>
							</PartyOtherNameSuiteExtendedData>
						</xsl:for-each>
					</PartyOtherName>
				</xsl:if>
			</xsl:for-each>
		</PartyOtherNames>
		<PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyBusinessDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true' or PhoneTypeCode = string(Util:GetOneRelatedItem('DCTPhoneType','F','26'))]">
				<xsl:sort select="IsPrimary" order="descending" />
				<xsl:sort select="LastUpdatedDate" order="descending" />
				<xsl:call-template name="indPartyPhones" />
			</xsl:for-each>
		</PartyPhones>
		<PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyBusinessDetail/PartyEmail/PartyEmailDTO[IsPrimary = 'true']">
				<xsl:sort select="IsPrimary" order="descending" />
				<xsl:call-template name="indPartyEmails" />
			</xsl:for-each>
		</PartyEmails>
		<!--TO DO Fix location fields-->
		<Locations xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address">
				<xsl:call-template name="indPartyAddress" />
			</xsl:for-each>
		</Locations>
	</xsl:template>
</xsl:stylesheet>