<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="countryCode" select="string(Util:GetValueByKey('OtherNameCountryCode'))" />

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
			<PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<PartyOtherName>
					<PartyOtherNameId>
						<xsl:value-of select="PartyIndNameDTO/PartyIndNameID"/>
					</PartyOtherNameId>
					<OtherNameTypeCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTNameType',PartyIndNameDTO/NameTypeCode,'29'))"/>
					</OtherNameTypeCode>
					<OtherNamePartyName>
						<xsl:value-of select="PartyIndNameDTO/LastName"/>
					</OtherNamePartyName>
					<OtherNameFirstName>
						<xsl:value-of select="PartyIndNameDTO/FirstName"/>
					</OtherNameFirstName>
					<OtherNameMiddleName>
						<xsl:value-of select="PartyIndNameDTO/MiddleName"/>
					</OtherNameMiddleName>
					<OtherNamePrefixCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',PartyIndNameDTO/PrefixCode,'34'))"/>
						<!--<xsl:value-of select="PartyIndNameDTO/PrefixCode"/>-->
					</OtherNamePrefixCode>
					<OtherNameSuffixCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',PartyIndNameDTO/SuffixCode,'48'))"/>
						<!--<xsl:value-of select="PartyIndNameDTO/SuffixCode"/>-->
					</OtherNameSuffixCode>
					<OtherNameCountryCode>
						<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',$countryCode,'243'))"/>
					</OtherNameCountryCode>
					<PartyOtherNamesLockingTS>
						<xsl:value-of select="PartyIndNameDTO/LastTransactionID"/>
					</PartyOtherNamesLockingTS>
					<xsl:value-of disable-output-escaping="yes" select="string(Util:GetValueByKey('ExtendedData'))"/>
				</PartyOtherName>
			</PartyOtherNames>
			<xsl:call-template name="ResponseInfo">
				<xsl:with-param name="ReturnCode">0</xsl:with-param>
				<xsl:with-param name="NotificationResponse"></xsl:with-param>
			</xsl:call-template>
		</PartyRecord>
	</xsl:template>
</xsl:stylesheet>
