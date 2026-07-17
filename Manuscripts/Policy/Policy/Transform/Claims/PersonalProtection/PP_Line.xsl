<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="line">		
		<xsl:call-template name="BuildingDetails" />
		<Line>
			<xsl:attribute name="type">
				<xsl:choose>
					<xsl:when test="Type = 'PPAU'">CarrierPersonalPackage</xsl:when>
					<xsl:when test="Type = 'PPNZ'">CarrierPersonalPackage</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="line/Type"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:call-template name="PP_Line.Relationships"/>
		</Line>
	</xsl:template>

</xsl:stylesheet>