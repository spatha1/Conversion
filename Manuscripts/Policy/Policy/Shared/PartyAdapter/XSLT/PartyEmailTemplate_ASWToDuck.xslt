<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
	
	<xsl:template name="indPartyEmails">
		<PartyEmail>

			<xsl:if test="$MethodName != 'GetPartyDetails'">
				<PartyEmailId>
					<xsl:value-of select="PartyEmailID" />
				</PartyEmailId>
				<EmailTypeCode>
					<!--TO DO : Code decode mapping-->
					<xsl:value-of select="string(Util:GetChildKey('DCTEmailType',EmailTypeCode,'31'))"/>
				</EmailTypeCode>
			</xsl:if>
			<EmailAddress>
				<xsl:value-of select="EmailAddress" />
			</EmailAddress>
      <ExternalPartyEmailID>
        <xsl:value-of select="ExternalPartyEmailID"/>
      </ExternalPartyEmailID>
			<xsl:if test="$MethodName != 'GetPartyDetails'">
				<PartyEmailLockingTS>
					<xsl:value-of select="LastTransactionID" />
				</PartyEmailLockingTS>
				<xsl:call-template name="ExtendedDataASWToDuck">
					<xsl:with-param name="TagName">EmailExtendedData</xsl:with-param>
					<xsl:with-param name="AswTagName">EmailExtendedData</xsl:with-param>
				</xsl:call-template>
			</xsl:if>
			<xsl:choose>
				<xsl:when test="IsPrimary='true'">
					<PrimaryIndicator>1</PrimaryIndicator>
				</xsl:when> 
				<xsl:otherwise>
					<PrimaryIndicator>0</PrimaryIndicator>
				</xsl:otherwise>
			</xsl:choose>
			<EmailComments>
				<xsl:value-of select="Comment"/>
			</EmailComments>
			<EmailEffectiveDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
			</EmailEffectiveDate>
			<EmailExpirationDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
			</EmailExpirationDate>
			<IsExpired>
				<xsl:value-of select="string(Util:IsExpiredRecord(ExpirationDate))"/>
			</IsExpired>

		</PartyEmail>
	</xsl:template>

</xsl:stylesheet>




