<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="PartyEmailTemplate_ASWToDuck.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
	<xsl:template match="/ArrayOfPartyEmailDTO">
		<PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyEmailDTO">
				<xsl:call-template name ="indPartyEmails"/>
			</xsl:for-each>
		</PartyEmails>
	</xsl:template>
</xsl:stylesheet>



