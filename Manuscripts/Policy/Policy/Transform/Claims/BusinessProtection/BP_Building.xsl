<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="risk[Type='Building' and name() != 'coverage'][normalize-space(@deleted)!='1']">
		<xsl:call-template name="Building.Body"/>
	</xsl:template>
	
	
	<xsl:template name="Building.Body">
		<Risk id="{@id}">
			<xsl:call-template name="OnlyBuilding.Body"/>
		    <xsl:call-template name="BP_Line.Excess"/>
		    <xsl:call-template name="Building.Relationships"/>
		</Risk>
	</xsl:template>
	
	<xsl:template name="OnlyBuilding.Body">		
			<BuildingId><xsl:value-of select="@id"/></BuildingId>
			<LocationId><xsl:value-of select="LocationID"/></LocationId>
			<Type><xsl:value-of select="Type"/></Type>
			<Details><xsl:value-of select="Details"/></Details>
			<Description><xsl:value-of select="BuildingName"/></Description>
			<xsl:variable name="LocID" select="LocationID"/>
			<xsl:apply-templates select="ancestor::data/account/location[@id=$LocID]"/>
	</xsl:template>
	
	

</xsl:stylesheet>