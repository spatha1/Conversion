<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:import href="PolicyTermExtendedDataLine1.xsl"/>
	<xsl:import href="PolicyTermExtendedDataCapricorn.xsl"/>
	<xsl:output omit-xml-declaration="yes"/>

	<!-- the context is established by the calling template so all paths here are relative to the established context-->
	<!-- the root node could be <root> or <Session.getAllDocumentsRs> depending on how the transform is called -->

	<xsl:template name="PolicyTermExtendedData">
		<xsl:variable name="LOB" select="LineOfBusiness"/>
		<PolicyTermExtendedData>

			<!-- Copy any existing PolicyTermExtendedData -->
			<xsl:copy-of select="PolicyTermExtendedData/*" />

			<AuditData>
				<Auditable>
					<xsl:value-of select="Indicators[Type='IsAuditable']/bValue"/>
				</Auditable>
			</AuditData>
			<xsl:choose>
				<xsl:when test="$LOB='Line1'">
					<xsl:call-template name="PolicyTermExtendedDataLine1"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="PolicyTermExtendedDataCapricorn"/>
				</xsl:otherwise>
			</xsl:choose>
		</PolicyTermExtendedData>
	</xsl:template>
</xsl:stylesheet>