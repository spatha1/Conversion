<!--xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util"-->
<!--xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util"-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">

	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/PartyPhoneDTO">
		<PartyRecord>
			<xsl:variable name="partyId">
				<xsl:value-of select="string(Util:GetValueByKey('PartyId'))" />
			</xsl:variable>
			<xsl:if test="$partyId != ''">
				<PartyRecordPartyId>
					<xsl:value-of select="$partyId"/>
				</PartyRecordPartyId>
			</xsl:if>
			<PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<xsl:call-template name="UpdatePartyPhone" />
			</PartyPhones>
			<xsl:call-template name="ResponseInfo">
				<xsl:with-param name="ReturnCode">0</xsl:with-param>
				<xsl:with-param name="NotificationResponse"/>
			</xsl:call-template>
		</PartyRecord>
	</xsl:template>
	<xsl:template name="UpdatePartyPhone">
		<xsl:param name="PhoneNumber"/>
		<xsl:param name="PhoneExtension"/>
		<xsl:param name="PhoneTypeCode"/>
		<PartyPhone>
			<PartyPhoneId>
				<xsl:value-of select="PartyPhoneID"/>
			</PartyPhoneId>
      <ExternalPartyPhoneID>
        <xsl:value-of select="ExternalPartyPhoneID"/>
      </ExternalPartyPhoneID>
			<PhoneTypeCode>
				<xsl:choose>
					<xsl:when test="string($PhoneTypeCode) != ''">
						<xsl:value-of select="$PhoneTypeCode"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="string(Util:GetChildKey('DCTPhoneType',PhoneTypeCode,'26'))"/>
					</xsl:otherwise>
				</xsl:choose>
			</PhoneTypeCode>
			<PhoneNumber>
				<xsl:choose>
					<xsl:when test="string($PhoneNumber) != ''">
						<xsl:value-of select="$PhoneNumber"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="FullPhoneNumber"/>
					</xsl:otherwise>
				</xsl:choose>
			</PhoneNumber>
			<PhoneExtension>
				<xsl:choose>
					<xsl:when test="string($PhoneExtension) != ''">
						<xsl:value-of select="$PhoneExtension"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="PhoneExtension"/>
					</xsl:otherwise>
				</xsl:choose>

			</PhoneExtension>
			<PhoneCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
			</PhoneCountryCode>
			<PhoneFormatCode>US1</PhoneFormatCode>
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
      

			<xsl:choose>
				<xsl:when test="IsPrimary='true'">
					<PrimaryIndicator>1</PrimaryIndicator>
				</xsl:when>
				<xsl:otherwise>
					<PrimaryIndicator>0</PrimaryIndicator>
				</xsl:otherwise>
			</xsl:choose>
			<PhoneComments>
				<xsl:value-of select="Comment" />
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