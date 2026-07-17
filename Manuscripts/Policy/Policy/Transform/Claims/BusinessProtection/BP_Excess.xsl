<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!-- I have found order of these matter -->
	
	<xsl:template name="BP_Line.Excess">
		<xsl:apply-templates select="coverage[Indicator = '1' and not(ancestor::coverage)]"/>
	</xsl:template>		
	<xsl:template match="coverage[Indicator = '1' and not(ancestor::coverage)]">
        <xsl:call-template name="Coverage.Excess"/>
    </xsl:template>

	
	<xsl:template name="Coverage.Excess">
            
            <!-- Clean raw values -->
                <xsl:variable name="standardRaw" select="translate(Excess/Standard, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ', '')"/>
                <xsl:variable name="voluntaryRaw" select="translate(Excess/Voluntary, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ', '')"/>
                <xsl:variable name="imposedRaw" select="translate(Excess/Imposed, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ', '')"/>
                
                <!-- Safe numeric assignment -->
                <xsl:variable name="standardNum">
                  <xsl:choose>
                    <xsl:when test="string-length($standardRaw) &gt; 0 and $standardRaw != 'NaN'">
                      <xsl:value-of select="number($standardRaw)"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                
                <xsl:variable name="voluntaryNum">
                  <xsl:choose>
                    <xsl:when test="string-length($voluntaryRaw) &gt; 0 and $voluntaryRaw != 'NaN'">
                      <xsl:value-of select="number($voluntaryRaw)"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                
                <xsl:variable name="imposedNum">
                  <xsl:choose>
                    <xsl:when test="string-length($imposedRaw) &gt; 0 and $imposedRaw != 'NaN'">
                      <xsl:value-of select="number($imposedRaw)"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                
                <!-- Total -->
                <xsl:variable name="totalExcess" select="$standardNum + $voluntaryNum + $imposedNum"/>
			
            <Excess>
			  <xsl:attribute name="type">
			  			<xsl:value-of select="Type"/>
			  </xsl:attribute>
              <Total><xsl:value-of select="$totalExcess"/></Total>
              <Earthquake><xsl:value-of select="Excess/Earthquake"/></Earthquake>
              <Glass><xsl:value-of select="Excess/Glass"/></Glass>
              <Flood><xsl:value-of select="Excess/Flood"/></Flood>
              <CustomerVehicle><xsl:value-of select="Excess/CustomerVehicles"/></CustomerVehicle>
              <HailDamage>
                    <xsl:choose>
                      <xsl:when test="string(Excess/Hail)">
                        <xsl:value-of select="Excess/Hail"/>
                      </xsl:when>
                      <xsl:when test="string(Excess/HailAndMaliciousDamage)">
                        <xsl:value-of select="Excess/HailAndMaliciousDamage"/>
                      </xsl:when>
                      <xsl:when test="string(HailAndMaliciousDamage)">
                        <xsl:value-of select="HailAndMaliciousDamage"/>
                      </xsl:when>
                      <xsl:otherwise/>
                    </xsl:choose>
              </HailDamage>
			        <MaliDamage>
                    <xsl:choose>
                      <xsl:when test="string(Excess/MaliciousDamage)">
                        <xsl:value-of select="Excess/MaliciousDamage"/>
                      </xsl:when>
                      <xsl:when test="string(MaliciousDamagetoStockCustomerVehiclesWatercraft)">
                        <xsl:value-of select="MaliciousDamagetoStockCustomerVehiclesWatercraft"/>
                      </xsl:when>
                      <xsl:otherwise/>
                    </xsl:choose>
              </MaliDamage>
              <Wind><xsl:value-of select="Excess/WindscreenAndWindowGlass"/></Wind>
              <StolenKey><xsl:value-of select="Excess/StockVehiclesStolenKeys"/></StolenKey>
            </Excess>
    </xsl:template>
	
</xsl:stylesheet>