<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
	<xsl:variable name="ReferenceType" select="string(Util:GetValueByKey('ReferenceType'))" />

	<xsl:template match="/PartyDetailDTO">
		<ClientDetailsDTO>
			<xsl:variable name="partyId">
				<xsl:value-of select="PartyID" />
			</xsl:variable>
			<ClientID>
				<xsl:value-of select="$partyId"/>
			</ClientID>
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
		</ClientDetailsDTO>
	</xsl:template>
	<xsl:template name="indPartyInfo">
		<PartyCountryCode>
			<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',PartyIndividualDetail/Party/CountryCode,'243'))"/>
		</PartyCountryCode>
		<xsl:for-each select="PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO/PartyName[IsDefault = 'true']">
			<FirstName>
				<xsl:value-of select="../PartyIndName/FirstName" />
			</FirstName>
			<MiddleName>
				<xsl:value-of select="../PartyIndName/MiddleName" />
			</MiddleName>
			<PartyName>
				<xsl:value-of select="../PartyIndName/LastName" />
			</PartyName>
			<Prefix>
				<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',../PartyIndName/PrefixCode,'34'))"/>
			</Prefix>
			<Suffix>
				<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',../PartyIndName/SuffixCode,'48'))"/>
			</Suffix>
			
			<xsl:variable name="FirstName" select="../PartyIndName/FirstName"  />
			<xsl:variable name="MiddleName" select="../PartyIndName/MiddleName"  />
			<xsl:variable name="LastName" select="../PartyIndName/LastName" />
			<xsl:variable name="PrefixCode" select="string(Util:GetChildKey('DCTNamePrefixValue',../PartyIndName/PrefixCode,'34'))" />
			<xsl:variable name="SuffixCode" select="string(Util:GetChildKey('DCTNameSuffixValue',../PartyIndName/SuffixCode,'48'))" />		
			
			<xsl:for-each select="../../PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '06' or NameTypeCode = '07']">
				<xsl:choose>
					<xsl:when test="NameTypeCode='07'">
						<CorrespondenceName>
							<xsl:value-of select="FullName" />
						</CorrespondenceName>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="$MethodName != 'GetPartyDetails'">
							<Name>
								<xsl:value-of select="FullName" />
							</Name>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			
			<xsl:for-each select="../../PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '01']">
				<xsl:if test="$MethodName != 'GetPartyDetails'">
							<Name>
								<xsl:value-of select="concat($PrefixCode,' ', $FirstName,' ', $MiddleName,' ', $LastName,' ', $SuffixCode)"/>
							</Name>
						</xsl:if>
			</xsl:for-each>
			
			

			<PartyComments>
				<xsl:value-of select="../../../PartyComment/Comment"/>
			</PartyComments>
			<PartyDeathDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(../../../PartyIndividual/DateOfDeath, false))" />
			</PartyDeathDate>
			<PrefContactMethod>
				<xsl:value-of select="../../../PartyIndividual/PreferredContactType" />
			</PrefContactMethod>
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
			<Deleted>
				<xsl:value-of select="../../../Party/IsInActive"/>
			</Deleted>
			<xsl:for-each select="../../PartyIndNameDetailDTO/PartyIndName[NameTypeCode = string(Util:GetOneRelatedItem('DCTNameType','DBA', '29'))]">
				<DBA>
					<xsl:value-of select="LastName" />
				</DBA>
			</xsl:for-each>
		</xsl:for-each>

		<xsl:for-each select="PartyIndividualDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true' or PhoneTypeCode = string(Util:GetOneRelatedItem('DCTPhoneType','F','26'))]">
			<xsl:sort select="IsPrimary" order="descending" />
			<xsl:sort select="LastUpdatedDate" order="descending" />
			<xsl:choose>
				<xsl:when test="IsPrimary = 'true'">
					<PhoneNumber>
						<xsl:value-of select="FullPhoneNumber" />
					</PhoneNumber>
					<PhoneCountryCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
					</PhoneCountryCode>
					<Extension>
						<xsl:value-of select="PhoneExtension" />
					</Extension>
				</xsl:when>
				<xsl:otherwise>
					<Fax>
						<xsl:value-of select="FullPhoneNumber" />
					</Fax>
					<PhoneCountryCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
					</PhoneCountryCode>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<xsl:for-each select="PartyIndividualDetail/PartyEmail/PartyEmailDTO[IsPrimary = 'true']">
			<xsl:sort select="IsPrimary" order="descending" />
			<EmailAddress>
				<xsl:value-of select="EmailAddress" />
			</EmailAddress>
		</xsl:for-each>

		<xsl:for-each select="PartyIndividualDetail/PartyMembership/PartyMembershipDTO[MembershipTypeCode = $ReferenceType]">
			<Reference>
				<xsl:value-of select="MembershipID" />
			</Reference>
			<xsl:call-template name="ExtendedDataASWToDuck">
				<xsl:with-param name="TagName">ReferenceExtendedData</xsl:with-param>
				<xsl:with-param name="AswTagName">MembershipExtendedData</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>

		<xsl:for-each select="PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address[../PartyAddress/IsDefault = 'true']">
			<xsl:variable name="countryCode" select="CountryCode"/>
			<LocationCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',$countryCode,'243'))"/>
			</LocationCountryCode>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine1'" />
				<xsl:with-param name="TagName" select="'Address1'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>
			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine2'" />
				<xsl:with-param name="TagName" select="'Address2'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>
			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine3'" />
				<xsl:with-param name="TagName" select="'Address3'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>
			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine4'" />
				<xsl:with-param name="TagName" select="'Address4'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>
			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'Attention'" />
				<xsl:with-param name="TagName" select="'Attention'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>
			<AddressEffDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
			</AddressEffDate>
			<AddressExpDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
			</AddressExpDate>
			<IsExpired>
				<xsl:value-of select="string(Util:IsExpiredRecord(ExpirationDate))"/>
			</IsExpired>
			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationCountyCode'" />
				<xsl:with-param name="TagName" select="'County'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>
			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationCity'" />
				<xsl:with-param name="TagName" select="'City'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationStateCode'" />
				<xsl:with-param name="TagName" select="'State'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationPostalCode'" />
				<xsl:with-param name="TagName" select="'ZIPCode'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

		</xsl:for-each>

		<xsl:for-each select="PartyIndividualDetail/PartyIndividual">
		
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

	</xsl:template>

	<xsl:template name="busPartyInfo">
		<PartyCountryCode>
			<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',PartyBusinessDetail/Party/CountryCode,'243'))"/>
		</PartyCountryCode>
		<xsl:for-each select="PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO/PartyName[IsDefault = 'true']">
			<FirstName>
				<!--<xsl:value-of select="../PartyIndName/FirstName" />-->
			</FirstName>
			<MiddleName>
				<!--<xsl:value-of select="../PartyIndName/MiddleName" />-->
			</MiddleName>
			<PartyName>
				<xsl:value-of select="../PartyBusName/Name" />
			</PartyName>
			<Prefix>
				<!--<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',../PartyIndName/PrefixCode,'34'))"/>-->
			</Prefix>
			<Suffix>
				<!--<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',../PartyIndName/SuffixCode,'48'))"/>-->
			</Suffix>

			<xsl:for-each select="../../PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '06' or NameTypeCode = '07' or NameTypeCode = '01']">
				<xsl:choose>
					<xsl:when test="NameTypeCode='07'">
						<CorrespondenceName>
							<xsl:value-of select="Name" />
						</CorrespondenceName>
					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="$MethodName != 'GetPartyDetails'">
							<Name>
								<xsl:value-of select="Name" />
							</Name>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>

			<PartyComments>
				<xsl:value-of select="../../../PartyComment/Comment"/>
			</PartyComments>
			<PartyDeathDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(../../../PartyBusiness/DateOfDeath, false))" />
			</PartyDeathDate>
			<PrefContactMethod>
				<xsl:value-of select="../../../PartyBusiness/PreferredContactType" />
			</PrefContactMethod>
			<xsl:choose>
				<xsl:when test="../../../Party/PartyTypeCode != ''">
					<PartyTypeCode>
						<!--IsAgency Added for AG Party Type Code-->
						<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',../../../Party/PartySubTypeCode,'PartySubType',../../../PartyBusiness/IsAgency))"/>
					</PartyTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<PartyTypeCode>
						<!--IsAgency Added for AG Party Type Code-->
						<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',../../../Party/PartyTypeCode,'8001',../../../PartyBusiness/IsAgency))"/>
					</PartyTypeCode>
				</xsl:otherwise>
			</xsl:choose>
			<Deleted>
				<xsl:value-of select="../../../Party/IsInActive"/>
			</Deleted>
			<xsl:for-each select="../../PartyBusNameDetailDTO/PartyBusName[NameTypeCode = string(Util:GetOneRelatedItem('DCTNameType','DBA', '29'))]">
				<DBA>
					<xsl:value-of select="Name" />
				</DBA>
			</xsl:for-each>
		</xsl:for-each>

		<xsl:for-each select="PartyBusinessDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true' or PhoneTypeCode = string(Util:GetOneRelatedItem('DCTPhoneType','F','26'))]">
			<xsl:sort select="IsPrimary" order="descending" />
			<xsl:sort select="LastUpdatedDate" order="descending" />
			<xsl:choose>
				<xsl:when test="IsPrimary = 'true'">
					<PhoneNumber>
						<xsl:value-of select="FullPhoneNumber" />
					</PhoneNumber>
					<PhoneCountryCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
					</PhoneCountryCode>
					<PhoneExtension>
						<xsl:value-of select="Extension" />
					</PhoneExtension>
				</xsl:when>
				<xsl:otherwise>
					<Fax>
						<xsl:value-of select="FullPhoneNumber" />
					</Fax>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>

		<xsl:for-each select="PartyBusinessDetail/PartyEmail/PartyEmailDTO[IsPrimary = 'true']">
			<xsl:sort select="IsPrimary" order="descending" />
			<EmailAddress>
				<xsl:value-of select="EmailAddress" />
			</EmailAddress>
		</xsl:for-each>

		<xsl:for-each select="PartyBusinessDetail/PartyMembership/PartyMembershipDTO[MembershipTypeCode = $ReferenceType]">
			<Reference>
				<xsl:value-of select="MembershipID" />
			</Reference>
			<xsl:call-template name="ExtendedDataASWToDuck">
				<xsl:with-param name="TagName">ReferenceExtendedData</xsl:with-param>
				<xsl:with-param name="AswTagName">MembershipExtendedData</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>

		<xsl:for-each select="PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address[../PartyAddress/IsDefault = 'true']">
			<xsl:variable name="countryCode" select="CountryCode"/>
			<LocationCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',$countryCode,'243'))"/>
			</LocationCountryCode>
			<xsl:if test="../PartyAddress/IsDefault = 'true'">
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationAddressLine1'" />
					<xsl:with-param name="TagName" select="'Address1'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationAddressLine2'" />
					<xsl:with-param name="TagName" select="'Address2'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationAddressLine3'" />
					<xsl:with-param name="TagName" select="'Address3'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationAddressLine4'" />
					<xsl:with-param name="TagName" select="'Address4'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'Attention'" />
					<xsl:with-param name="TagName" select="'Attention'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>
				<AddressEffDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
				</AddressEffDate>
				<AddressExpDate>
					<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
				</AddressExpDate>
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationCountyCode'" />
					<xsl:with-param name="TagName" select="'County'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationCity'" />
					<xsl:with-param name="TagName" select="'City'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>

				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationStateCode'" />
					<xsl:with-param name="TagName" select="'State'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>

				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationPostalCode'" />
					<xsl:with-param name="TagName" select="'ZIPCode'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>

				<!--<xsl:variable name="varPostalCode" select="PostalCode" />
        <xsl:if test="contains($varPostalCode, '-')">
          <xsl:variable name="varLocationPostalCode" select="substring-before($varPostalCode,'-')"/>
          <xsl:variable name="varLocationPostalCodeExtension" select="substring-after($varPostalCode,'-')"/>
          <ZIPCode>
            <xsl:value-of select="$varLocationPostalCode" />
          </ZIPCode>
          <xsl:if test="$MethodName != 'GetPartyDetails'">
            <ZIPCodeExt>
              <xsl:value-of select="$varLocationPostalCodeExtension" />
            </ZIPCodeExt>
          </xsl:if>
        </xsl:if>
        <xsl:if test="not(contains($varPostalCode, '-'))">
          <ZIPCode>
            <xsl:value-of select="PostalCode"/>
          </ZIPCode>
          <xsl:if test="$MethodName != 'GetPartyDetails'">
            <ZIPCodeExt>
              <xsl:value-of select="SubPostalCode"/>
            </ZIPCodeExt>
          </xsl:if>
        </xsl:if>-->
			</xsl:if>
		</xsl:for-each>

	</xsl:template>

	<xsl:template name="GenerateDCTFieldForAddress">
		<xsl:param name="DCTFieldName" />
		<xsl:param name="CountryCode" />
		<xsl:param name="TagName" />
		<!--xsl:choose>
			<xsl:when test="string(Util:CheckDCTNodeConfigurability($DCTFieldName,$CountryCode,'ADDRESS')) = 'true'"-->
		<xsl:call-template name="GenerateDCTField">
			<xsl:with-param name="DCTFieldName" select="$DCTFieldName" />
			<xsl:with-param name="CountryCode" select="$CountryCode" />
			<xsl:with-param name="ComponentName" select="'ADDRESS'" />
			<xsl:with-param name="TagPrefix" select="''" />
			<xsl:with-param name="TagName" select="$TagName" />
		</xsl:call-template>
		<!--/xsl:when>
		</xsl:choose-->
	</xsl:template>

	<xsl:template name="GenerateDCTField">
		<xsl:param name="DCTFieldName" />
		<xsl:param name="CountryCode" />
		<xsl:param name="ComponentName" />
		<xsl:param name="TagPrefix" />
		<xsl:param name="TagName" />

		<xsl:variable name="elementName">
			<xsl:choose>
				<xsl:when test="$TagName != ''" >
					<xsl:value-of select="$TagName"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$DCTFieldName"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="valueOfElement" select="string(Util:GenerateDCTFieldWithValue(.,$DCTFieldName,$CountryCode,$ComponentName,''))" />

		<xsl:choose>
			<xsl:when test="$DCTFieldName != 'LocationPostalCode'">
				<!--actual processing-->
				<xsl:element name="{$elementName}">
					<xsl:choose>
						<xsl:when test="$valueOfElement != ''">
							<xsl:value-of disable-output-escaping="no" select="$valueOfElement"/>
						</xsl:when>
					</xsl:choose>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<!--Postal code split conditions-->
				<xsl:call-template name="PostalCodeProcessing">
					<xsl:with-param name="elementName" select="$elementName" />
					<xsl:with-param name="valueOfElement" select="$valueOfElement" />
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--Postal code split conditions-->
	<xsl:template name="PostalCodeProcessing">
		<xsl:param name="elementName" />
		<xsl:param name="valueOfElement" />
		<xsl:choose>
			<xsl:when test="contains($valueOfElement, '-')">
				<xsl:variable name="varLocationPostalCode" select="substring-before($valueOfElement,'-')"/>
				<xsl:variable name="varLocationPostalCodeExtension" select="substring-after($valueOfElement,'-')"/>
				<xsl:element name="{$elementName}">
					<xsl:value-of select="$varLocationPostalCode" />
				</xsl:element>
				<xsl:if test="$MethodName != 'GetPartyDetails'">
					<xsl:choose>
						<xsl:when test="$elementName != 'ZIPCode'">
							<xsl:element name="LocationPostalCodeExtension">
								<xsl:value-of select="$varLocationPostalCodeExtension" />
							</xsl:element>
						</xsl:when>
						<xsl:otherwise>
							<xsl:element name="ZIPCodeExt">
								<xsl:value-of select="$varLocationPostalCodeExtension" />
							</xsl:element>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="{$elementName}">
					<xsl:value-of select="$valueOfElement" />
				</xsl:element>
				<xsl:if test="$MethodName != 'GetPartyDetails'">
					<xsl:choose>
						<xsl:when test="$elementName != 'ZIPCode'">
							<xsl:element name="LocationPostalCodeExtension">
							</xsl:element>
						</xsl:when>
						<xsl:otherwise>
							<xsl:element name="ZIPCodeExt">
							</xsl:element>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

</xsl:stylesheet>
