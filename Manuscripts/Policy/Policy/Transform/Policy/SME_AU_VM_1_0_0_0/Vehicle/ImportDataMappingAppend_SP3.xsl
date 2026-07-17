<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output omit-xml-declaration="yes" method="xml" />
	
	<xsl:template match="*"> <!-- CATCH ALL FOR EVERYTHING ELSE -->
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>	
	</xsl:template>
	
	
	<!-- Risk -->

		<!-- INJECT WAGES THAT WERE BUILT IN IMPORT SECTION -->
		<xsl:template match="data/policy/line"> <!-- COPY OVER LINE ELEMENT WITH NEW AddModeCheck -->
			<xsl:copy>
				<xsl:copy-of select="@*"/>
				<xsl:apply-templates/>
				<xsl:copy-of select="/data/policy/import/processedItemData/risk"/>
			</xsl:copy>
		</xsl:template>	
	
	<!-- Fleet -->
	<xsl:template match="data/policy/line/risk[Type='Motor' and FleetType='Fleet']/Vehicle
         [Registration = /data/policy/import/processedItemData/Vehicle/Registration]">
		<xsl:variable name="reg" select="Registration"/>
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<!-- copy everything except nodes we replace -->
			<xsl:apply-templates select="node()
                    [not(self::Imported) and not(self::Year) and not(self::Make) and not(self::Model) and not(self::VehicleAccessoriesValue) and not(self::VehicleAccessoriesDescription) and not(self::HighestRiskUse) and not(self::AdditonalParty)
                     and not(self::AddAccessoriesOrModification)
                     and not(self::HaveInterestedParty)]"/>
			<!-- replace from processedItemData -->
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/Imported"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/Year"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/Make"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/Model"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/VehicleAccessoriesValue"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/VehicleAccessoriesDescription"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/HighestRiskUse"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/AdditonalParty"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/AddAccessoriesOrModification"/>
			<xsl:copy-of select="/data/policy/import/processedItemData/Vehicle
                    [Registration = $reg]/HaveInterestedParty"/>
		</xsl:copy>
	</xsl:template>
	<!-- INJECT Vehicles THAT WERE BUILT IN IMPORT SECTION -->
	<xsl:template match="data/policy/line/risk[Type='Motor' and FleetType='Fleet']">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
			<xsl:variable name="impReg" select="Vehicle/Registration"/>
			<!-- Inject imported vehicles ONLY if Registration is NOT already present -->
			<xsl:for-each select="/data/policy/import/processedItemData/Vehicle">
				<xsl:if test="not(Registration = $impReg)">
					<xsl:copy-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:copy>
	</xsl:template>

		
	<!-- Match add and edit mode indicators and reset to disabled value -->
	<xsl:template match="Vehicle/InVehicleEditMode">
		<xsl:element name="InVehicleEditMode"><xsl:value-of select="string('0')"/></xsl:element>
	</xsl:template>
	<xsl:template match="Vehicle/InVehicleAddMode">
		<xsl:element name="InVehicleAddMode"><xsl:value-of select="string('0')"/></xsl:element>
	</xsl:template>
	<!-- REMOVE EXISTING IMPORT DATA -->
	<xsl:template match="data/policy/import/*"/>
</xsl:stylesheet><!-- Stylesheet edited using Stylus Studio - (c) 2004-2006. Progress Software Corporation. All rights reserved. -->
