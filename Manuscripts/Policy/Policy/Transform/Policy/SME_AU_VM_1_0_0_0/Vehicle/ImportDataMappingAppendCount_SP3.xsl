<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output omit-xml-declaration="yes" method="xml" />
	
	<xsl:template match="*"> <!-- CATCH ALL FOR EVERYTHING ELSE -->
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>	
	</xsl:template>
	
	<!-- Count of Vehicles added -->
	<xsl:template match="data/upload/mapping">
		<xsl:variable name="NewVehicleCount" select="count(/data/policy/import/processedItemData/Vehicle)" /> 
		<xsl:copy>	
			<NumberVehiclesImported><xsl:value-of select="$NewVehicleCount"/></NumberVehiclesImported>
		</xsl:copy>
	<!-- <xsl:call-template name="DeleteVehicle"/> -->
	</xsl:template>	
	
	
</xsl:stylesheet><!-- Stylesheet edited using Stylus Studio - (c) 2004-2006. Progress Software Corporation. All rights reserved. -->
