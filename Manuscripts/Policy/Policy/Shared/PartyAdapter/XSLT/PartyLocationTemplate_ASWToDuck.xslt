<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="i xs msxsl xsl Util">
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:include href="CommonTemplates.xslt" />
	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
	<xsl:template name="indPartyAddress">
	
	
		<xsl:param name ="InsertIndicator" />
		<xsl:param name ="UpdateIndicator" />
		<Location>
			<xsl:variable name="countryCode" select="CountryCode"/>
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

			<xsl:if test="$MethodName != 'GetPartyDetails'">
				<LocationId>
					<xsl:value-of select="AddressID"/>
				</LocationId>
			</xsl:if>
			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine1'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine2'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine3'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine4'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'Attention'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:if test="$MethodName != 'GetPartyDetails'">
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationAddressLine5'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>
			</xsl:if>

			<LocationEffectiveDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
			</LocationEffectiveDate>
			<LocationExpirationDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
			</LocationExpirationDate>
 
			<IsExpired>
				<xsl:value-of select="string(Util:IsExpiredRecord(ExpirationDate))"/>
			</IsExpired>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationCity'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationStateCode'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationStateName'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationPostalCode'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress">
				<xsl:with-param name="DCTFieldName" select="'LocationCountyCode'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<LocationCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
			</LocationCountryCode>
			
			<xsl:choose>
				<xsl:when test="../PartyAddress/IsPrimary='true'">
					<PrimaryIndicator>1</PrimaryIndicator>
				</xsl:when> 
				<xsl:otherwise>
					<PrimaryIndicator>0</PrimaryIndicator>
				</xsl:otherwise>
			</xsl:choose>
			
			<LocationComments>
				<xsl:value-of select="../PartyAddress/Comment"/>
			</LocationComments>
      <ExternalPartyAddressID>
        <xsl:value-of select="../PartyAddress/ExternalPartyAddressID"/>
      </ExternalPartyAddressID>
			<xsl:if test="$MethodName != 'GetPartyDetails'">
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationLatitude'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>
				<xsl:call-template name="GenerateDCTFieldForAddress">
					<xsl:with-param name="DCTFieldName" select="'LocationLongitude'" />
					<xsl:with-param name="CountryCode" select="$countryCode" />
				</xsl:call-template>

				<LocationLockingTS>
					<xsl:value-of select="LastTransactionID"/>
				</LocationLockingTS>
		
				<LocationInvolvements>
					<xsl:if test="../PartyAddress/IsDefault = 'true'">
						<LocationInvolvement>
							<ObjectTypeCode>PTY</ObjectTypeCode>
							<ObjectId>
								<xsl:value-of select="../PartyAddress/PartyID"/>
							</ObjectId>
							<RoleCode />
							<LocationId>
								<xsl:value-of select="AddressID"/>
							</LocationId>
							<LocationInvolvementId>
								<xsl:value-of select="string(Util:CreateUniqueId())"/>
							</LocationInvolvementId>
							<LocationInvolvementTypeCode>_DF_</LocationInvolvementTypeCode>
							<EffectiveDate>
								<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
							</EffectiveDate>
							<ExpirationDate>
								<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
							</ExpirationDate>
							<LocationInvolvementLockingTS>
								<xsl:value-of select="LastTransactionID"/>
							</LocationInvolvementLockingTS>

						</LocationInvolvement>
					</xsl:if>
					<xsl:for-each select="./AddressTypeAssociations/AddressTypeAssociationDTO">
						<xsl:call-template name="addressTypeAssociationTemplate" />
					</xsl:for-each>
				</LocationInvolvements>
			</xsl:if>
			
			 <xsl:for-each select="./AddressExtendedData/ExtendedFields/ExtendedFieldDTO">
				<xsl:call-template name="ASWExtendedDataToDuck">
				  <xsl:with-param name="TagName">LocationExtendedData</xsl:with-param>
				</xsl:call-template>
			  </xsl:for-each>
			
			<LocationSuiteExtendedData>
				<xsl:for-each select="./AddressExtendedData/ExtendedFields/ExtendedFieldDTO">
				  <xsl:call-template name="SuiteASWExtendedDataToDuck">
					<xsl:with-param name="SuiteTagName">LocationSuiteExtendedData</xsl:with-param>
				  </xsl:call-template>
				</xsl:for-each>
			  </LocationSuiteExtendedData>		

    </Location>
	</xsl:template>
	
	<xsl:template name ="addressTypeAssociationTemplate">
		<!--<xsl:if test="string(Util:IsExpiredRecord(ExpirationDate)) = '0'">-->
		<LocationInvolvement>
			<ObjectTypeCode>PTY</ObjectTypeCode>
			<ObjectId>
				<xsl:value-of select="../../../PartyAddress/PartyID"/>
			</ObjectId>
			<RoleCode />
			<LocationId>
				<xsl:value-of select="AddressID"/>
			</LocationId>
			<LocationInvolvementTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTLocationInvolvementType',AddressType,'8501'))"/>
			</LocationInvolvementTypeCode>
			<LocationInvolvementId>
				<xsl:value-of select="AddressTypeAssociationID"/>
			</LocationInvolvementId>
			<EffectiveDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
				<!--<xsl:value-of select="EffectiveDate"/>-->
			</EffectiveDate>
			<ExpirationDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
			</ExpirationDate>
			<LocationInvolvementLockingTS>
				<xsl:value-of select="LastTransactionID"/>
			</LocationInvolvementLockingTS>

		</LocationInvolvement>
		<!--</xsl:if>-->
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




