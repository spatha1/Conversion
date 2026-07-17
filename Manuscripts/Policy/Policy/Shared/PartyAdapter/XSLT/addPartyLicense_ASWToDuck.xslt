<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="PartyLicenseTemplate_ASWToDuck.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes" cdata-section-elements="LicenseExtendedData"/>
	<xsl:template match="/">
		<PartyRecord>
			<PartyLicenses xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<xsl:for-each select="PartyLicenseDTO">
					<xsl:call-template name="indPartyLicences"/>
				</xsl:for-each>
			</PartyLicenses>
			<xsl:call-template name="ResponseInfo">
				<xsl:with-param name="ReturnCode">0</xsl:with-param>
				<xsl:with-param name="NotificationResponse"/>
			</xsl:call-template>
		</PartyRecord>
	</xsl:template>
</xsl:stylesheet>