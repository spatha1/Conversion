<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes" method="xml"/>
	<xsl:template match="*">
		<!-- CATCH ALL FOR EVERYTHING ELSE -->
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	<!-- Inject -->
	<xsl:template match="data/policy/line/risk[Type=&quot;Motor&quot; and FleetType='Fleet' and @deleted!='1']">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="*[not(self::Vehicle)]"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="data/policy/import/*"/>
</xsl:stylesheet>
<!-- Stylesheet edited using Stylus Studio - (c) 2004-2006. Progress Software Corporation. All rights reserved. -->