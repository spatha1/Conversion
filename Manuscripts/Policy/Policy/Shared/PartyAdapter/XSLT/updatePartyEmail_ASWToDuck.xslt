<xsl:stylesheet version="1.0" xmlns:party="Party.Types" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util party">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

	<xsl:template match="/PartyEmailDTO" >
		<PartyRecord>
			<PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<PartyEmail>
          
					<PartyEmailId>
						<xsl:value-of select="PartyEmailID"/>
					</PartyEmailId>
          <ExternalPartyEmailId>
            <xsl:value-of select="ExternalPartyEmailID"/>
          </ExternalPartyEmailId>
					<EmailTypeCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTEmailType',EmailTypeCode,'31'))"/>
					</EmailTypeCode>
					<EmailAddress>
						<xsl:value-of select="EmailAddress"/>
					</EmailAddress>
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
					<PartyEmailLockingTS>
						<xsl:value-of select="LastTransactionID"/>
					</PartyEmailLockingTS>
					<xsl:call-template name="ExtendedDataASWToDuck">
						<xsl:with-param name="TagName">EmailExtendedData</xsl:with-param>
						<xsl:with-param name="AswTagName">EmailExtendedData</xsl:with-param>
					</xsl:call-template>
					<xsl:choose>
						<xsl:when test="IsPrimary='true'">
							<PrimaryIndicator>1</PrimaryIndicator>
						</xsl:when>
						<xsl:otherwise>
							<PrimaryIndicator>0</PrimaryIndicator>
						</xsl:otherwise>
					</xsl:choose>
				</PartyEmail>
			</PartyEmails>
			<xsl:call-template name="ResponseInfo">
				<xsl:with-param name="ReturnCode">0</xsl:with-param>
				<xsl:with-param name="NotificationResponse"/>
			</xsl:call-template>
		</PartyRecord>
	</xsl:template>
</xsl:stylesheet>



