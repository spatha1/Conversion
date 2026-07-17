<xsl:stylesheet version="1.0" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template name="partyLicense">
		<xsl:for-each select="./PartyLicenses/PartyLicense">
			<PartyLicenseDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
				<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
				<xsl:call-template name="commonLicenseTemaplate" />
			</PartyLicenseDTO>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="partyLicenseExtData">
    <xsl:for-each select="./PartyLicenses/PartyLicense">
      <PartyLicenseWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
		<!--<xsl:call-template name="ExtendedData">
			<xsl:with-param name="TagName">LicenseExtendedData</xsl:with-param>
			<xsl:with-param name="PhysicalTableName">PARTY_LIC</xsl:with-param>
			<xsl:with-param name="LogicalTableName">lgclPartyLic</xsl:with-param>
			<xsl:with-param name="LogicalColumnName">PartyLicenseExtData</xsl:with-param>
		</xsl:call-template>-->
        <!--<xsl:if test="LicenseExtendedData != '' or count(LicenseExtendedData) > 0">
          <ExtendedData xmlns:d4p1="http://epc.accenture.com/2013/06/26/Type">
            <xsl:value-of disable-output-escaping="yes" select="Util:CreateArrayObjectExtendedData('PARTY_LIC','PartyLicenseID','lgclPartyLic','PartyLicenseExtData', LicenseExtendedData, 'd4p1')" />
          </ExtendedData>
        </xsl:if>-->
        <PartyLicense>
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
          <xsl:call-template name="commonLicenseTemaplate" />
        </PartyLicense>
      </PartyLicenseWithExtendedDataDTO>
    </xsl:for-each>
  </xsl:template>
	<xsl:template name="commonLicenseTemaplate">
		<EffectiveDate>
			<xsl:value-of select="string(Util:GetCurrentDate())"/>
		</EffectiveDate>
		<ExpirationDate>
			<xsl:value-of select="string(Util:GetMaxDate())"/>
		</ExpirationDate>
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
		<!--TO DO : code decode-->
		<PartyLicenseCountry>
			<xsl:value-of select="LicenseCountryIssued"/>
		</PartyLicenseCountry>
		<xsl:if test="PartyLicenseId !=''">
			<PartyLicenseID>
				<xsl:value-of select="PartyLicenseId"/>
			</PartyLicenseID>  
		</xsl:if>

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
	</xsl:template>
</xsl:stylesheet>




