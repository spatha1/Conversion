<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<!--xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util"-->
  <xsl:import href="CommonTemplates.xslt"/>
	
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/PartyEmailDTO">
    <PartyRecord>
      <!--<PartyRecordPartyId>
        <xsl:value-of select="PartyID"/>
      </PartyRecordPartyId>-->
      <PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
		  <xsl:call-template name="UpdateEmailAddress" />
      </PartyEmails>
      <xsl:call-template name="ResponseInfo">
        <xsl:with-param name="ReturnCode">0</xsl:with-param>
        <xsl:with-param name="NotificationResponse"></xsl:with-param>
      </xsl:call-template>
    </PartyRecord>
  </xsl:template>
	<xsl:template name="UpdateEmailAddress">
		<xsl:param name="EmailAddress"/>
		<PartyEmail>
			<PartyEmailId>
				<xsl:value-of select="PartyEmailID"/>
			</PartyEmailId>
			<EmailTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTEmailType',EmailTypeCode,'31'))"/>
			</EmailTypeCode>
			<EmailAddress>
				<xsl:choose>
					<xsl:when test="string($EmailAddress) != ''">
						<xsl:value-of select="$EmailAddress"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="EmailAddress"/>
					</xsl:otherwise>
				</xsl:choose>
			</EmailAddress>
			<PartyEmailLockingTS>
				<xsl:value-of select="LastTransactionID"/>
			</PartyEmailLockingTS>
			<xsl:value-of disable-output-escaping="yes" select="string(Util:GetValueByKey('ExtendedData'))"/>
			<xsl:choose>
				<xsl:when test="IsPrimary='true'">
					<PrimaryIndicator>1</PrimaryIndicator>
				</xsl:when>
				<xsl:otherwise>
					<PrimaryIndicator>0</PrimaryIndicator>
				</xsl:otherwise>
			</xsl:choose>
		</PartyEmail>
	</xsl:template>
</xsl:stylesheet>



