<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt" />

	<xsl:template name="busPartyInfo" >
		<Party>
			<PartyId>
				<xsl:value-of select="Party/PartyID"/>
			</PartyId>
			<PartyCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',Party/CountryCode,'243'))"/>
			</PartyCountryCode>

			<PartyName>
				<xsl:value-of select="PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName/Name" />
			</PartyName>

			<PartyNameCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyName/CountryCode,'243'))" />
			</PartyNameCountryCode>

			<PartyFirstName>
				<xsl:value-of select="PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName/Name" />
			</PartyFirstName>
			<PartyMiddleName>
				<xsl:value-of select="PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName/Name" />
			</PartyMiddleName>
			<PartyNamePrefixCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName/PrefixCode,'34'))"/>
			</PartyNamePrefixCode>
			<PartyNameSuffixCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName/SuffixCode,'48'))"/>
			</PartyNameSuffixCode>
			<xsl:choose>
				<xsl:when test="string(Party/PartySubTypeCode) != ''">
					<PartyTypeCode>
						<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',Party/PartySubTypeCode,'PartySubType',PartyBusiness/IsAgency))"/>
					</PartyTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<PartyTypeCode>
						<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',Party/PartyTypeCode,'8001',PartyBusiness/IsAgency))"/>
					</PartyTypeCode>
				</xsl:otherwise>
			</xsl:choose>
			<PartySubTypeCode xsi:nil="true" />
			<PartyGenderCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTGender',PartyBusiness/GenderCode,'51'))"/>
			</PartyGenderCode>
			<PartyBirthDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(PartyBusiness/DateOfBirth, false))" />
			</PartyBirthDate>
			<PartyMaritalStatusCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTMaritalStatus',PartyBusiness/MaritalStatusCode,'35'))"/>
			</PartyMaritalStatusCode>
			<PartyTaxId>
				<xsl:value-of select="PartyBusiness/RegistrationID1" />
			</PartyTaxId>
			<PartyTaxId2>
				<xsl:value-of select="PartyBusiness/RegistrationID2" />  <!--#5814-Added for nzbn mapping  -->
			</PartyTaxId2>
			<PartyNationality xsi:nil="true" />
			<PartyPartyOwner xsi:nil="true" />
			<!--/-->
			<PartyPreferredLanguageCode >
				<xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',PartyBusiness/PreferredLanguage,'8037'))"/>
			</PartyPreferredLanguageCode>
			<xsl:for-each select="PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '06' or NameTypeCode = '07']">
				<xsl:choose>
					<xsl:when test="NameTypeCode='07'">
						<PartyCorrespondenceName>
							<xsl:value-of select="Name" />
						</PartyCorrespondenceName>
					</xsl:when>
					<xsl:when test="NameTypeCode='06'">
						<PartyLegacyName>
							<xsl:value-of select="Name" />
						</PartyLegacyName>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
			<PartyDeletedIndicator>0</PartyDeletedIndicator>
			<PartyLockingTS>
				<xsl:value-of select="Party/LastTransactionID" />
			</PartyLockingTS>
			<xsl:for-each select="PartyBusiness">
				
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
			
		</Party>
	</xsl:template>

	<xsl:template name="indPartyInfo" >
		<Party>
			<PartyId>
				<xsl:value-of select="Party/PartyID"/>
			</PartyId>
			<PartyCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',Party/CountryCode,'243'))"/>
			</PartyCountryCode>

			<PartyName>
				<xsl:value-of select="PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName/LastName" />
			</PartyName>
			<PartyNameCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyName/CountryCode,'243'))" />
			</PartyNameCountryCode>

			<PartyFirstName>
				<xsl:value-of select="PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName/FirstName" />
			</PartyFirstName>
			<PartyMiddleName>
				<xsl:value-of select="PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName/MiddleName" />
			</PartyMiddleName>
			<PartyNamePrefixCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName/PrefixCode,'34'))"/>
			</PartyNamePrefixCode>
			<PartyNameSuffixCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName/SuffixCode,'48'))"/>
			</PartyNameSuffixCode>
			<xsl:choose>
				<xsl:when test="string(Party/PartySubTypeCode) != ''">
					<PartyTypeCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTPartyType',Party/PartySubTypeCode,'PartySubType'))"/>
					</PartyTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<PartyTypeCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTPartyType',Party/PartyTypeCode,'8001'))"/>
					</PartyTypeCode>
				</xsl:otherwise>
			</xsl:choose>
			<PartySubTypeCode xsi:nil="true" />
			<PartyGenderCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTGender',PartyIndividual/GenderCode,'51'))"/>
			</PartyGenderCode>
			<PartyBirthDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(PartyIndividual/DateOfBirth, false))" />
			</PartyBirthDate>
			<PartyMaritalStatusCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTMaritalStatus',PartyIndividual/MaritalStatusCode,'35'))"/>
			</PartyMaritalStatusCode>
			<!--<PartyTaxId>
						<xsl:value-of select="PartyIndividual/SpecificPurposeID" />
					</PartyTaxId>-->
			<PartyTaxId>
				<xsl:value-of select="../../../PartyIndividual/SpecificPurposeID" />  <!--#5814-Removed SSN format mask as its not required for ird number-->
			</PartyTaxId>
			<PartyNationality xsi:nil="true" />
			<PartyPartyOwner xsi:nil="true" />
			<!--/-->
			<PartyPreferredLanguageCode >
				<xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',PartyIndividual/PreferredLanguage,'8037'))"/>
			</PartyPreferredLanguageCode>

			<xsl:for-each select="PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '06' or NameTypeCode = '07']">
				<xsl:choose>
					<xsl:when test="NameTypeCode='07'">
						<PartyCorrespondenceName>
							<xsl:value-of select="FullName" />
						</PartyCorrespondenceName>
					</xsl:when>
					<xsl:when test="NameTypeCode='06'">
						<PartyLegacyName>
							<xsl:value-of select="FullName" />
						</PartyLegacyName>
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>
			<PartyDeletedIndicator>0</PartyDeletedIndicator>
			<PartyLockingTS>
				<xsl:value-of select="Party/LastTransactionID" />
			</PartyLockingTS>
			<xsl:for-each select="PartyIndividual">
				
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
			<xsl:value-of disable-output-escaping="yes" select="string(Util:GetValueByKey('ExtendedData'))"/>
		</Party>
	</xsl:template>

	<xsl:template name="PartyPhones">
		<xsl:param name ="InsertIndicator" />
		<xsl:param name ="UpdateIndicator" />
		<PartyPhone>
			<xsl:if test="$InsertIndicator != ''">
				<InsertIndicator>
					<xsl:value-of select="$InsertIndicator"/>
				</InsertIndicator>
			</xsl:if>
			<xsl:if test="$UpdateIndicator != ''">
				<UpdateIndicator>
					<xsl:value-of select="$UpdateIndicator"/>
				</UpdateIndicator>
			</xsl:if>
			<PartyPhoneId>
				<xsl:value-of select="PartyPhoneID"/>
			</PartyPhoneId>
			<PhoneTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTPhoneType',PhoneTypeCode,'26'))"/>
				<!--<xsl:value-of select="PhoneTypeCode"/>-->
			</PhoneTypeCode>
			<PhoneNumber>
				<xsl:value-of select="FullPhoneNumber"/>
			</PhoneNumber>
			<PrimaryIndicator>
				<xsl:choose>
					<xsl:when test="IsPrimary = 'true'">1</xsl:when>
					<xsl:otherwise>0</xsl:otherwise>
				</xsl:choose>
			</PrimaryIndicator>
			<xsl:choose>
				<xsl:when test="PhoneExtension !=''">
					<PhoneExtension>
						<xsl:value-of select="PhoneExtension" />
					</PhoneExtension>
				</xsl:when>
				<xsl:otherwise>
					<PhoneExtension xsi:nil="true"/>
				</xsl:otherwise>
			</xsl:choose>
			<PhoneCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
			</PhoneCountryCode>
			<PhoneFormatCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTFormatMask',CountryCode,'243'))"/>
			</PhoneFormatCode>
			<PartyPhoneLockingTS>
				<xsl:value-of select="LastTransactionID"/>
			</PartyPhoneLockingTS>
      
      <xsl:for-each select="./PhoneExtendedData/ExtendedFields/ExtendedFieldDTO">
        <xsl:call-template name="ASWExtendedDataToDuck">
          <xsl:with-param name="TagName">PhoneExtendedData</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>

      <PhoneSuiteExtendedData>
        <xsl:for-each select="./PhoneExtendedData/ExtendedFields/ExtendedFieldDTO">
          <xsl:call-template name="SuiteASWExtendedDataToDuck">
			  <xsl:with-param name="SuiteTagName">PhoneSuiteExtendedData</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </PhoneSuiteExtendedData>
		</PartyPhone>
	</xsl:template>

	<xsl:template name="PartyOtherName">
		<xsl:param name ="InsertIndicator" />
		<xsl:param name ="UpdateIndicator" />
		<PartyOtherName>
			<xsl:if test="$InsertIndicator != ''">
				<InsertIndicator>
					<xsl:value-of select="$InsertIndicator"/>
				</InsertIndicator>
			</xsl:if>
			<xsl:if test="$UpdateIndicator != ''">
				<UpdateIndicator>
					<xsl:value-of select="$UpdateIndicator"/>
				</UpdateIndicator>
			</xsl:if>
			<PartyOtherNameId>
				<xsl:value-of select="PartyIndNameID"/>
			</PartyOtherNameId>
			<OtherNameTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTNameType',NameTypeCode,'29'))"/>
			</OtherNameTypeCode>
			<OtherNameCountryCode>
				<xsl:value-of select="../PartyName/CountryCode"/>
			</OtherNameCountryCode>
			<OtherNamePartyName>
				<xsl:value-of select="LastName"/>
			</OtherNamePartyName>
			<OtherNameFirstName>
				<xsl:value-of select="FirstName"/>
			</OtherNameFirstName>
			<OtherNameMiddleName>
				<xsl:value-of select="MiddleName"/>
			</OtherNameMiddleName>
			<OtherNamePrefixCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',PrefixCode,'34'))"/>
				<!--<xsl:value-of select="PrefixCode"/>-->
			</OtherNamePrefixCode>
			<OtherNameSuffixCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',SuffixCode,'48'))"/>
				<!--<xsl:value-of select="SuffixCode"/>-->
			</OtherNameSuffixCode>
			<PartyOtherNamesLockingTS>
				<xsl:value-of select="LastTransactionID"/>
			</PartyOtherNamesLockingTS>
			<xsl:value-of disable-output-escaping="yes" select="string(Util:GetValueByKey('ExtendedData'))"/>
		</PartyOtherName>
	</xsl:template>


</xsl:stylesheet>