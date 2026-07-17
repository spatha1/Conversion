<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes" method="xml"/>
	<xsl:template match="/ | @* | node()">
		<xsl:copy>
			<xsl:apply-templates select="@* | node()"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="data/policy/import/NewDataSet">
		<processedItemData>
			<xsl:for-each select="Table">
				<xsl:call-template name="FleetVehicle"/>
			</xsl:for-each>
		</processedItemData>
	</xsl:template>
	<xsl:template name="FleetVehicle">
		<Vehicle>
			<Type>FleetVehicle</Type>
			<xsl:element name="Registration">
				<xsl:value-of select="Registration"/>
			</xsl:element>
			<Imported>
				<xsl:element name="Year">
					<xsl:value-of select="Year"/>
				</xsl:element>
				<xsl:element name="Make">
					<xsl:value-of select="Make"/>
				</xsl:element>
				<xsl:element name="Model">
					<xsl:value-of select="Model"/>
				</xsl:element>
				<xsl:element name="HighestRiskUse">
                    <xsl:choose>
                        <xsl:when test="PrincipalUse = 'General Business'">Business</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="PrincipalUse"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
				<xsl:element name="VehicleAccessoriesDescription">
					<xsl:value-of select="AccessoriesDescription"/>
				</xsl:element>
				<xsl:element name="VehicleAccessoriesValue">
					<xsl:value-of select="AccessoriesValue"/>
				</xsl:element>
				<xsl:element name="AdditonalParty">
					<xsl:value-of select="AdditionalParty"/>
				</xsl:element>
			</Imported>
			<xsl:element name="AddAccessoriesOrModification">
					<xsl:choose>
						<xsl:when test="normalize-space(AccessoriesValue) != '' or normalize-space(AccessoriesDescription) != ''">1</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
		    </xsl:element>
			<xsl:element name="HaveInterestedParty">
					<xsl:choose>
						<xsl:when test="normalize-space(AdditionalParty) != ''">1</xsl:when>
						<xsl:otherwise>0</xsl:otherwise>
					</xsl:choose>
		    </xsl:element>
			<xsl:element name="RegoStatus">
				<xsl:value-of select="RegoStatus"/>
			</xsl:element>
			<xsl:element name="State">
				<xsl:value-of select="State"/>
			</xsl:element>
            <FleetVehicleOverrideInfo>0</FleetVehicleOverrideInfo>
		</Vehicle>
	</xsl:template>
</xsl:stylesheet>