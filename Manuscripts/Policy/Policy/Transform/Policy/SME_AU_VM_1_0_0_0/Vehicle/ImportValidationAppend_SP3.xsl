<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output omit-xml-declaration="yes" method="xml"/>
    
    <!-- Group by Registration -->
    <xsl:key name="ItemsGroupedByNameNode" match="/data/policy/import/NewDataSet/Table" use="Registration"/>

    <xsl:template match="/ | @* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="data/policy/import/NewDataSet">
        <processedItemData>
            <xsl:for-each select="Table">
                <xsl:variable name="RegVar" select="Registration"/>
                <xsl:variable name="RegOfCurrentNode" select="concat('x', Registration)"/>
                <xsl:variable name="RegOfFirstNodeInNameGroup" select="concat('x', key('ItemsGroupedByNameNode', Registration)[1]/Registration)"/>

                
                <xsl:if test="string-length(normalize-space(Registration)) &gt; 0">
                    
                    <!-- Non-Fleet -->
                    <xsl:if test="not(/data/policy/line/risk[Type='Motor' and FleetType='Fleet'])">
                        <xsl:call-template name="vehicle">
                            <xsl:with-param name="Registration" select="Registration"/>
                            <xsl:with-param name="Year" select="Year"/>
                            <xsl:with-param name="Make" select="Make"/>
                            <xsl:with-param name="Model" select="Model"/>
                            <xsl:with-param name="PrincipalUse" select="PrincipalUse"/>
                            <xsl:with-param name="AccessoriesDescription" select="AccessoriesDescription"/>
                            <xsl:with-param name="AccessoriesValue" select="AccessoriesValue"/>
                            <xsl:with-param name="AdditionalParty" select="AdditionalParty"/>
                            <xsl:with-param name="RegoStatus" select="RegoStatus"/>
                            <xsl:with-param name="State" select="State"/>
                        </xsl:call-template>
                    </xsl:if>

                    <!-- Fleet -->
                    <xsl:if test="/data/policy/line/risk[Type='Motor' and FleetType='Fleet']">
                        <xsl:call-template name="vehicle">
                            <xsl:with-param name="Registration" select="Registration"/>
                            <xsl:with-param name="Year" select="Year"/>
                            <xsl:with-param name="Make" select="Make"/>
                            <xsl:with-param name="Model" select="Model"/>
                            <xsl:with-param name="PrincipalUse" select="PrincipalUse"/>
                            <xsl:with-param name="AccessoriesDescription" select="AccessoriesDescription"/>
                            <xsl:with-param name="AccessoriesValue" select="AccessoriesValue"/>
                            <xsl:with-param name="AdditionalParty" select="AdditionalParty"/>
                            <xsl:with-param name="RegoStatus" select="RegoStatus"/>
                            <xsl:with-param name="State" select="State"/>
                        </xsl:call-template>
                    </xsl:if>
                </xsl:if>
            </xsl:for-each>
        </processedItemData>
    </xsl:template>

    <xsl:template name="vehicle">
        <xsl:param name="Registration"/>
        <xsl:param name="Year"/>
        <xsl:param name="Make"/>
        <xsl:param name="Model"/>
        <xsl:param name="PrincipalUse"/>
        <xsl:param name="AccessoriesDescription"/>
        <xsl:param name="AccessoriesValue"/>
        <xsl:param name="AdditionalParty"/>
        <xsl:param name="RegoStatus"/>
        <xsl:param name="State"/>
        
        <xsl:element name="Vehicle">
            <xsl:attribute name="deleted">0</xsl:attribute>
            <Type>FleetVehicle</Type>
            <Registration><xsl:value-of select="$Registration"/></Registration>
            <Imported>
                <Year><xsl:value-of select="$Year"/></Year>
                <Make><xsl:value-of select="$Make"/></Make>
                <Model><xsl:value-of select="$Model"/></Model>
                <xsl:element name="HighestRiskUse">
                    <xsl:choose>
                        <xsl:when test="normalize-space($PrincipalUse)  = 'General Business'">Business</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$PrincipalUse"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element><VehicleAccessoriesDescription><xsl:value-of select="$AccessoriesDescription"/></VehicleAccessoriesDescription>
                <VehicleAccessoriesValue><xsl:value-of select="$AccessoriesValue"/></VehicleAccessoriesValue>
                <AdditonalParty><xsl:value-of select="$AdditionalParty"/></AdditonalParty>
            </Imported>
            <AddAccessoriesOrModification>
                <xsl:choose>
                    <xsl:when test="normalize-space($AccessoriesValue) != '' or normalize-space($AccessoriesDescription) != ''">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </AddAccessoriesOrModification>
            <HaveInterestedParty>
                <xsl:choose>
                    <xsl:when test="normalize-space($AdditionalParty) != ''">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </HaveInterestedParty>
            <RegoStatus><xsl:value-of select="$RegoStatus"/></RegoStatus>
            <State><xsl:value-of select="$State"/></State>
            <FleetVehicleOverrideInfo>0</FleetVehicleOverrideInfo>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>