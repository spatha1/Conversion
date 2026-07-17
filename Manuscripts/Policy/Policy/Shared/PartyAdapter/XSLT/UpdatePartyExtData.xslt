<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<!--xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util"-->
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes" />

	<xsl:variable name="misc" select="/PartyData/clientDetails/misc" />
	<xsl:variable name="primaryContact" select="/PartyData/clientDetails/primaryContact" />

	<xsl:template match="/PartyData">
		<PartyExtendedData>
			<BusinessType>
				<xsl:value-of select="PartyExtendedData/BusinessType"/>
			</BusinessType>
			<Occupation>
				<xsl:value-of select="PartyExtendedData/Occupation"/>
			</Occupation>
			<PreferredContact>
				<Method>
					<xsl:value-of select="PartyExtendedData/PreferredContact/Method"/>
				</Method>
				<Value>
					<xsl:value-of select="PartyExtendedData/PreferredContact/Value"/>
				</Value>
				<MethodType>
					<xsl:value-of select="PartyExtendedData/PreferredContact/MethodType"/>
				</MethodType>
			</PreferredContact>
			<OriginationDate>
				<xsl:value-of select="PartyExtendedData/OriginationDate"/>
			</OriginationDate>
			<xsl:choose>
				<xsl:when test="string($primaryContact) != ''">
					<PreferredContactPerson>
						<xsl:value-of select="$primaryContact"/>
					</PreferredContactPerson>
				</xsl:when>
				<xsl:otherwise>
					<PreferredContactPerson>
						<xsl:value-of select="PartyExtendedData/PreferredContactPerson"/>
					</PreferredContactPerson>
				</xsl:otherwise>
			</xsl:choose>
			<VisaId>
				<xsl:value-of select="PartyExtendedData/VisaId"/>
			</VisaId>
			<GreenCardId>
				<xsl:value-of select="PartyExtendedData/GreenCardId"/>
			</GreenCardId>
			<WorkPermitId>
				<xsl:value-of select="PartyExtendedData/WorkPermitId"/>
			</WorkPermitId>
			<PassportId>
				<xsl:value-of select="PartyExtendedData/PassportId"/>
			</PassportId>
			<Ethnicity>
				<xsl:value-of select="PartyExtendedData/Ethnicity"/>
			</Ethnicity>
			<USCitizen>
				<xsl:value-of select="PartyExtendedData/USCitizen"/>
			</USCitizen>
			<FullName>
				<xsl:value-of select="PartyExtendedData/FullName"/>
			</FullName>
			<AdditionalTaxInformation>
				<AdditionalTaxId>
					<xsl:value-of select="PartyExtendedData/AdditionalTaxInformation/AdditionalTaxId"/>
				</AdditionalTaxId>
				<JurisdictionCode>
					<xsl:value-of select="PartyExtendedData/AdditionalTaxInformation/JurisdictionCode"/>
				</JurisdictionCode>
				<TaxTypeCode>
					<xsl:value-of select="PartyExtendedData/AdditionalTaxInformation/TaxTypeCode"/>
				</TaxTypeCode>
			</AdditionalTaxInformation>
			<xsl:choose>
				<xsl:when test="string(clientDetails/misc) != ''">
					<xsl:copy-of select ="clientDetails/misc"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select ="PartyExtendedData/misc"/>
				</xsl:otherwise>
			</xsl:choose>
		</PartyExtendedData>
	</xsl:template>

</xsl:stylesheet>
