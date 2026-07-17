<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="data/policy">
		<xsl:call-template name="Policy.Body"/>
	</xsl:template>

	<xsl:template name="Policy.Body">
		<Policy id="{@id}">
			<EffectiveDate>
				<xsl:value-of select="EffectiveDate"/>
			</EffectiveDate>
			<ExpirationDate>
				<xsl:value-of select="ExpirationDate"/>
			</ExpirationDate>
			<PolicyStatus>
				<xsl:value-of select="Status"/>
			</PolicyStatus>
			<PolicyTerm>
				<xsl:value-of select="Term"/>
			</PolicyTerm>
			<CSLNumber>
				<xsl:value-of select="//data/account/CSLNumber"/>
			</CSLNumber>
			<CMLNumber>
				<xsl:value-of select="//data/account/CMLNumber"/>
			</CMLNumber>
			<RAMName>
				<xsl:value-of select="//data/account/CMLRiskAccountManager"/>
			</RAMName>
			<LineOfBusiness>CarrierPersonalPackage</LineOfBusiness>
			<PackagePolicy>0</PackagePolicy>
			<PolicyNumber>
				<xsl:value-of select="PolicyNumber"/>
			</PolicyNumber>
			<PolicyCurrencyCode>
				<xsl:value-of select="Currency"/>
			</PolicyCurrencyCode>
			<PrimaryRatingState>
				<xsl:value-of select="PrimaryRatingState"/>
			</PrimaryRatingState>
			<SICCode>
				<xsl:value-of select="SICCode"/>
			</SICCode>
			<xsl:copy-of select="//data/account/Contact/AdditionalContactInfo"/>
			<xsl:for-each select="//data/policy/line/risk[Type='Building' and @deleted!='1']">
            <xsl:if test="normalize-space(InterestedPartyDescription) != ''">
                <AdditionalInterest>
                  <EntityType>AI</EntityType>
                  <Type>M</Type>
                  <TypeDetails>
                    <xsl:value-of select="normalize-space(InterestedPartyDescription)"/>
                  </TypeDetails>
                </AdditionalInterest>
            </xsl:if>
            </xsl:for-each>
			<xsl:call-template name="Policy.Extensions"/>
			<xsl:call-template name="Policy.Relationships"/>
		</Policy>
	</xsl:template>

	<xsl:template name="Policy.Extensions"/>
	<xsl:template name="Policy.Relationships"/>

</xsl:stylesheet>