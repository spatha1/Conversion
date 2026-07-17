<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="location">
		<xsl:call-template name="Location.Body"/>
	</xsl:template>
	
	<xsl:template name="Location.Body">
		<Location id="{@id}">
			<Description><xsl:value-of select="Description" /></Description>		
			<xsl:call-template name="Location.Relationships"/>
		</Location>
	</xsl:template>

	<xsl:template name="Location.Relationships"/>

</xsl:stylesheet>