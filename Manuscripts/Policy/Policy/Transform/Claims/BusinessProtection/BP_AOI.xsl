<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="additionalinterestsme">
		<xsl:call-template name="AOI.Body"/>
	</xsl:template>

	<xsl:template name="AOI.Body">
		<AdditionalInterest id="{@id}">
		    <EntityType>AI</EntityType>
			<Type><xsl:value-of select="Type" /></Type>
			<TypeDetails><xsl:value-of select="TypeDetails" /></TypeDetails>
			<LocationProtectionSection><xsl:value-of select="LocationProtectionSection" /></LocationProtectionSection>
			<LineProtectionSection><xsl:value-of select="LineProtectionSection" /></LineProtectionSection>
			<xsl:variable name="LocID" select="LocationAddress"/>
			<xsl:apply-templates select="ancestor::data/account/location[@id=$LocID]"/>
		</AdditionalInterest>
	</xsl:template>


</xsl:stylesheet>