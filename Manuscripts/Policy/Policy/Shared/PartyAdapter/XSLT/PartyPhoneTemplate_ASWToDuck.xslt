<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
  <xsl:template name="indPartyPhones">
		<PartyPhone>

			<xsl:if test="$MethodName != 'GetPartyDetails'">
				<PartyPhoneId>
					<xsl:value-of select="PartyPhoneID" />
				</PartyPhoneId>
 
				<PhoneTypeCode>
					<xsl:value-of select="string(Util:GetChildKey('DCTPhoneType',PhoneTypeCode,'26'))" />
				</PhoneTypeCode>
			</xsl:if>
      <ExternalPartyPhoneID>
        <xsl:value-of select="ExternalPartyPhoneID"/>
      </ExternalPartyPhoneID>

			<PhoneNumber>
				<xsl:value-of select="FullPhoneNumber" />
			</PhoneNumber>
			<PhoneExtension>
				<xsl:value-of select="PhoneExtension" />
			</PhoneExtension>
			<PhoneCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
			</PhoneCountryCode>
			<PhoneFormatCode>US1</PhoneFormatCode>
			<!--TO DO : Code decode mapping-->
			<!--<xsl:value-of select="string(Util:GetChildKey('DCTFormatMask',CountryCode,'243'))" />-->
			<!--</PhoneFormatCode>-->
			<xsl:if test="$MethodName != 'GetPartyDetails'">
				<PartyPhoneLockingTS>
					<xsl:value-of select="LastTransactionID" />
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
			
			</xsl:if>
			
			<PrimaryIndicator>
				<xsl:choose>
					<xsl:when test="IsPrimary = 'true'">1</xsl:when>
					<xsl:otherwise>0</xsl:otherwise>
				</xsl:choose>
			</PrimaryIndicator>
			<PhoneComments>
				<xsl:value-of select="Comment"/>
			</PhoneComments>
			<PhoneEffectiveDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
			</PhoneEffectiveDate>
			<PhoneExpirationDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
			</PhoneExpirationDate>
			<IsExpired>
				<xsl:value-of select="string(Util:IsExpiredRecord(ExpirationDate))"/>
			</IsExpired>
		</PartyPhone>
	</xsl:template>

</xsl:stylesheet>




