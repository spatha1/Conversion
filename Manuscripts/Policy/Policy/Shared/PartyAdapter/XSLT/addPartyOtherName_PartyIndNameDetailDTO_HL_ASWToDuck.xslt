<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="PartyIndNameTemplate_HL_ASWToDuck.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
		<PartyRecord>
			<xsl:variable name="partyId">
				<xsl:value-of select="string(Util:GetValueByKey('PartyId'))" />
			</xsl:variable>
			<xsl:variable name="primary">
				<xsl:value-of select="string(Util:GetValueByKey('primary'))" />
			</xsl:variable>
			<xsl:if test="$primary != ''">
				<Primary>
					<xsl:value-of select="$primary"/>
				</Primary>
			</xsl:if>
			<xsl:if test="$partyId != ''">
				<PartyRecordPartyId>
					<xsl:value-of select="$partyId"/>
				</PartyRecordPartyId>
			</xsl:if>
			<PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<xsl:for-each select="PartyIndNameDetailDTO/PartyIndName">
					<xsl:call-template name="PartyIndName" />
				</xsl:for-each>
			</PartyOtherNames>
			<xsl:call-template name="ResponseInfo">
				<xsl:with-param name="ReturnCode">0</xsl:with-param>
				<xsl:with-param name="NotificationResponse"/>
			</xsl:call-template>
		</PartyRecord>
	</xsl:template>
</xsl:stylesheet>
