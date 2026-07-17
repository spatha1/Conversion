<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:import href="PartyPhoneTemplate_ASWToDuck.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
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
				<xsl:for-each select="PartyPhoneDTO">
					<xsl:call-template name="indPartyPhones"/>
				</xsl:for-each>
			</PartyPhones>
			<xsl:call-template name="ResponseInfo">
				<xsl:with-param name="ReturnCode">0</xsl:with-param>
				<xsl:with-param name="NotificationResponse"/>
			</xsl:call-template>
		</PartyRecord>
	</xsl:template>
</xsl:stylesheet>