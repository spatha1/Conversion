<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="address">
		<xsl:call-template name="Address.Body"/>
	</xsl:template>

	<xsl:template name="Address.Body">
		<Address>
			<Address1><xsl:value-of select="Address1"/></Address1>
			<Address2><xsl:value-of select="Address2"/></Address2>
			<City><xsl:value-of select="City"/></City>
			<State><xsl:value-of select="State"/></State>
			<ZipCode><xsl:value-of select="ZipCode"/></ZipCode>
			<Country>AU</Country>
			<xsl:call-template name="Address.Relationships"/>
		</Address>
	</xsl:template>

	<xsl:template name="Address.Relationships"/>

	<xsl:template match="mailingAddress">
		<xsl:call-template name="Address2.Body"/>
	</xsl:template>

	<xsl:template name="Address2.Body">
		<Address>
			<Address1><xsl:value-of select="address1"/></Address1>
			<Address2><xsl:value-of select="address2"/></Address2>
			<City><xsl:value-of select="city"/></City>
			<State><xsl:value-of select="state"/></State>
			<ZipCode><xsl:value-of select="ZIP"/></ZipCode>
			<Country>AU</Country>
			<xsl:call-template name="Address2.Relationships"/>
		</Address>
	</xsl:template>

	<xsl:template name="Address2.Relationships"/>

</xsl:stylesheet>