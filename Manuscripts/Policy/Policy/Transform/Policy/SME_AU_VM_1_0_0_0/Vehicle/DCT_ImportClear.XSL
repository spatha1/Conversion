<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format">

<xsl:output omit-xml-declaration="yes" method="xml" />

<xsl:template match="*">
	<xsl:copy>
		<xsl:copy-of select="@*" />
		<xsl:apply-templates />		
	</xsl:copy>
</xsl:template>

<xsl:template match="import">
	<import/>
</xsl:template>

</xsl:stylesheet>
