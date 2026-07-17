<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!-- I have found order of these matter -->
	<xsl:template match="coverage[Indicator = '1'][Code != 'HB']
                              [Code != 'HC']
                              [Code != 'PM']
							  [Type != 'BLD_CY']
							  [Type != 'BLD_BF']
							  [Type != 'BLD_EQ']
							  [Type != 'BLD_ST']
							  [Type != 'CNT_CY']
							  [Type != 'CNT_BF']
							  [Type != 'CNT_EQ']
							  [Type != 'CNT_ST']
							  ">
    <xsl:call-template name="Coverage.Body">
        <xsl:with-param name="Ded" select="Deductible"/>
        <xsl:with-param name="Limit" select="limit/iValue"/>
        <xsl:with-param name="LimitType" select="CoverageLevel"/>
        <xsl:with-param name="Premium" select="Premium"/>
    </xsl:call-template>
    </xsl:template>
 


	<xsl:template name="Coverage.Body">
    <xsl:param name="id" select="@id"/>
    <xsl:param name="Type" select="substring-before(concat(Code, '_'), '_')"/>
    <xsl:param name="Ded">0</xsl:param>
    <xsl:param name="DedType">Total</xsl:param>
    <xsl:param name="Limit"/>
    <xsl:param name="LimitType"/>
    <xsl:param name="Premium" select="change"/>

    <!-- Set default for Limit if empty -->
		<!-- 1) Gather LegalLiability from the nearest Vehicle ancestor -->
		<xsl:variable name="LLFromVehicleNode" select="ancestor::risk[Type='Motor'][1]/limit[Type='LegalLiability'][normalize-space(iValue)!=''][1]/iValue[1]"/>
		<xsl:variable name="LLFromVehicle" select="string($LLFromVehicleNode)"/>
		<!-- 2) Gather LegalLiability from the nearest risk ancestor HB-->
		<xsl:variable name="LLFromRiskNodeHB" select="ancestor::risk[1]/coverage[Type='Building']/limit[Type='LegalLiability'][normalize-space(iValue)!=''][1]/iValue[1]"/>
		<xsl:variable name="LLFromRiskHB" select="string($LLFromRiskNodeHB)"/>
		<!-- 3) Gather LegalLiability from the nearest risk ancestor  HC-->
		<xsl:variable name="LLFromRiskNodeHC" select="ancestor::risk[1]/coverage[Type='ContentsAndStocks']/limit[Type='LegalLiability'][normalize-space(iValue)!=''][1]/iValue[1]"/>
		<xsl:variable name="LLFromRiskHC" select="string($LLFromRiskNodeHC)"/>
		<!-- 4) FinalLimit -->
		<xsl:variable name="FinalLimit">
			<xsl:choose>
				<!-- Special case: LIA_SD -> take from Vehicle -->
				<xsl:when test="normalize-space(Type) = 'LIA_SD'">
					<xsl:choose>
						<xsl:when test="$LLFromVehicle != ''">
							<xsl:value-of select="$LLFromVehicle"/>
						</xsl:when>
						<xsl:otherwise>20000000</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="normalize-space(Type) = 'BLI_SD'">
					<xsl:choose>
						<xsl:when test="$LLFromRiskHB != ''">
							<xsl:value-of select="$LLFromRiskHB"/>
						</xsl:when>
						<xsl:otherwise>20000000</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:when test="normalize-space(Type) = 'CLI_SD'">
					<xsl:choose>
						<xsl:when test="$LLFromRiskHC != ''">
							<xsl:value-of select="$LLFromRiskHC"/>
						</xsl:when>
						<xsl:otherwise>20000000</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
            <xsl:when test="
              normalize-space(Type) = 'CMP_SD'
              and (
                normalize-space(ancestor::risk/ProtectionType) = 'Comprehensive'
                or normalize-space(ancestor::risk/ProtectionType) = 'ComprehensiveMarket'
              )
            ">0</xsl:when>
    		<xsl:when test="
          normalize-space($Limit) != '' 
          and not(Type = 'ULG_SD' or Type = 'TCH_SD' or Type = 'PCH_SD' or Type = 'COR_SD')
        ">
                <xsl:value-of select="$Limit"/>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- Set default for LimitType if empty -->
    <xsl:variable name="FinalLimitType">
        <xsl:choose>
            <xsl:when test="string($LimitType) != ''">
                <xsl:value-of select="$LimitType"/>
            </xsl:when>
            <xsl:otherwise>Per Occurrence</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <!-- Set default for Premium if empty -->
    <xsl:variable name="FinalPremium">
        <xsl:choose>
            <xsl:when test="string($Premium) != ''">
                <xsl:value-of select="$Premium"/>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <Coverage id="{$id}">
        <Type><xsl:value-of select="$Type"/></Type>
        <Deductible type="{$DedType}" value="{$Ded}"/>
        <Limit type="{$FinalLimitType}" value="{$FinalLimit}"/>
        <Premium><xsl:value-of select="$FinalPremium"/></Premium>
    </Coverage>
</xsl:template>

</xsl:stylesheet>