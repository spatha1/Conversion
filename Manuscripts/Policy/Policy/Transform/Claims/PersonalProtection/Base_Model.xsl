<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="root">
		<xsl:apply-templates select="session"/>
	</xsl:template>

	<xsl:template match="session">
		<xsl:apply-templates select="data/policy"/>
	</xsl:template>

	<xsl:template name="Policy.Relationships">
		<xsl:apply-templates select="../account"/>
		<xsl:apply-templates select="additionalinterestsme" />
		<xsl:apply-templates select="../account/location[not(deleted='1')]"/>
		<xsl:apply-templates select="../account/building"/>
		<xsl:apply-templates select="../agencyDetails"/>
		<xsl:apply-templates select="../userDetails"/>
		<xsl:apply-templates select="line"/>
	</xsl:template>
	
	<xsl:template match="line"/>
	
	<xsl:template name="Insured.Relationships">
		<xsl:apply-templates select="address"/>
    <xsl:call-template name="Insured.Party" />
	</xsl:template>
	
	<xsl:template name="Location.Relationships">
		<xsl:apply-templates select="address"/>
	</xsl:template>

	<xsl:template name="Agency.Relationships">
		<xsl:apply-templates select="agency/contactName"/>
		<xsl:apply-templates select="mailingAddress"/>
    <xsl:call-template name="Agency.Party"/>
	</xsl:template>
  
  <xsl:template name="Insured.Party">
    <InternalPartyId>
      <xsl:value-of select="ancestor::session/@clientId"/>
    </InternalPartyId>
  </xsl:template>

  <xsl:template name="Agency.Party">
    <InternalPartyId>1</InternalPartyId>
  </xsl:template>

</xsl:stylesheet>