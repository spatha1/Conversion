<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:template match="/">
		<PartyLicenseDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="PartyRecord/PartyLicenses/PartyLicense">
				<EffectiveDate>
					<!--<xsl:value-of select="string(Util:ConvertDateToAswFormat(LicenseEffectiveDate))"/>-->
					<xsl:value-of select="string(Util:GetCurrentDate())"/>
				</EffectiveDate>
				<ExpirationDate>
					<xsl:value-of select="string(Util:GetMaxDate())"/>
					<!--<xsl:value-of select="string(Util:ConvertDateToAswFormat(LicenseExpirationDate))"/>-->
				</ExpirationDate>
				<LastTransactionID>
					<xsl:value-of select="PartyLicenseLockingTS"/>
				</LastTransactionID>
				<LastUpdatedDate>
					<xsl:value-of select="string(Util:GetCurrentDate())"/>
				</LastUpdatedDate>
				<xsl:if test="LicenseExpirationDate != ''">
					<LicenseExpirationDate>
						<xsl:value-of select="string(Util:ConvertDateToAswFormat(LicenseExpirationDate))"/>
					</LicenseExpirationDate>
				</xsl:if>

				<PartyID>
					<xsl:value-of select="../../PartyRecordPartyId"/>
				</PartyID>
				<PartyLicenseCountry>
					<xsl:value-of select="LicenseCountryIssued"/>
				</PartyLicenseCountry>
				<PartyLicenseID>
					<xsl:value-of select="PartyLicenseId"/>
				</PartyLicenseID>
				<xsl:if test="LicenseEffectiveDate != ''">
					<PartyLicenseIssuedDate>
						<xsl:value-of select="string(Util:ConvertDateToAswFormat(LicenseEffectiveDate))"/>
					</PartyLicenseIssuedDate>
				</xsl:if>
				<PartyLicenseNumber>
					<xsl:value-of select="LicenseNumber"/>
				</PartyLicenseNumber>
				<PartyLicensePlaceIssued>
					<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLicenseStateType',LicenseStateCode,'8051'))"/>
				</PartyLicensePlaceIssued>
				<PartyLicenseStatus>
					<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLicenseStatus',LicenseStatusCode,'PTYLicStatus'))"/>
				</PartyLicenseStatus>
				<PartyLicenseType>
					<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLicenseType',LicenseTypeCode,'PTYLicTyp'))"/>
				</PartyLicenseType>
				<xsl:call-template name="ExtendedData">
					<xsl:with-param name="TagName">LicenseExtendedData</xsl:with-param>
					<xsl:with-param name="PhysicalTableName">PARTY_LIC</xsl:with-param>
					<xsl:with-param name="LogicalTableName">lgclPartyLic</xsl:with-param>
					<xsl:with-param name="LogicalColumnName">PartyLicenseExtData</xsl:with-param>
				</xsl:call-template>
			</xsl:for-each>
		</PartyLicenseDTO>
	</xsl:template>
</xsl:stylesheet>