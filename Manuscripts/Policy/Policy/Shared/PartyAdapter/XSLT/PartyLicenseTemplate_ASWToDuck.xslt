<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

	<xsl:template name="indPartyLicences">
		<PartyLicense>
			<PartyLicenseId>
				<xsl:value-of select="PartyLicenseID" />
			</PartyLicenseId>
			<LicenseTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTLicenseType',PartyLicenseType,'PTYLicTyp'))" />
			</LicenseTypeCode>
			<LicenseStateCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTLicenseStateType',PartyLicensePlaceIssued,'8051'))"/>
			</LicenseStateCode>
			<LicenseNumber>
				<xsl:value-of select="PartyLicenseNumber" />
			</LicenseNumber>
			<LicenseStatusCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTLicenseStatus',PartyLicenseStatus,'PTYLicStatus'))" />
			</LicenseStatusCode>
			<xsl:choose>
				<xsl:when test="PartyLicenseIssuedDate != ''">
					<LicenseEffectiveDate>
						<xsl:value-of select="string(Util:ConvertDateToDuckFormat(PartyLicenseIssuedDate))"/>
					</LicenseEffectiveDate>
				</xsl:when>
				<xsl:otherwise>
					<LicenseEffectiveDate/>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="LicenseExpirationDate != ''">
					<LicenseExpirationDate>
						<xsl:value-of select="string(Util:ConvertDateToDuckFormat(LicenseExpirationDate))"/>
					</LicenseExpirationDate>
				</xsl:when>
				<xsl:otherwise>
					<LicenseExpirationDate/>
				</xsl:otherwise>
			</xsl:choose>
			<LicenseCountryIssued>
				<xsl:value-of select="PartyLicenseCountry"/>
			</LicenseCountryIssued>
			<PartyLicenseLockingTS>
				<xsl:value-of select="LastTransactionID" />
			</PartyLicenseLockingTS>
			<xsl:call-template name="ExtendedDataASWToDuck">
				<xsl:with-param name="TagName">LicenseExtendedData</xsl:with-param>
				<xsl:with-param name="AswTagName">LicenseExtendedData</xsl:with-param>
			</xsl:call-template>
		</PartyLicense>

	</xsl:template>

</xsl:stylesheet>




