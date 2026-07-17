<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<!-- I have found order of these matter -->
	<xsl:template match="coverage[Indicator = '1']
                              [Code != 'BB']
                              [Code != 'BC']
                              [Code != 'BI']
                              [Code != 'BG']
                              [Code != 'MY']
                              [Code != 'EN']
                              [Code != 'FL']
                              [Code != 'CM']
							  [Type != 'STD_CY']
							  [Type != 'STD_BF']
							  [Type != 'STD_EQ']
							  [Type != 'STD_ST']
							  [Type != 'GRP_CY']
							  [Type != 'GRP_BF']
							  [Type != 'GRP_EQ']
							  [Type != 'GRP_ST']
							  [Type != 'HAL_ST']
							  ">
    <xsl:call-template name="Coverage.Body">
        <xsl:with-param name="Ded" select="Deductible"/>
        <xsl:with-param name="Limit" select="limit/iValue"/>
        <xsl:with-param name="LimitType" select="CoverageLevel"/>
        <xsl:with-param name="Premium" select="Premium"/>
    </xsl:call-template>
    </xsl:template>
 

<xsl:template match="coverage[not(ancestor::risk)]
                              [Indicator = '1']
                              [Code != 'GP']
                              [Code != 'PP']
                              [Code != 'PF']
                              [Code != 'CV']
                              [Code != 'SV']
                              [Code != 'LE']
                              [Code != 'GT']
                              [Code != 'TA']
							  [Type != 'STD_CY']
							  [Type != 'STD_BF']
							  [Type != 'STD_EQ']
							  [Type != 'STD_ST']
							  [Type != 'GRP_CY']
							  [Type != 'GRP_BF']
							  [Type != 'GRP_EQ']
							  [Type != 'GRP_ST']
							  [Type != 'HAL_ST']
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

    <!-- 1) Gather LegalLiability from the nearest Vehicle ancestor -->
    <xsl:variable name="LLFromVehicleNode" select="ancestor::Vehicle[1]/limit[Type='LegalLiability'][normalize-space(iValue)!=''][1]/iValue[1]"/>
    <xsl:variable name="LLFromVehicle" select="string($LLFromVehicleNode)"/>
    <!-- 2) Gather LegalLiability from the nearest risk ancestor -->
    <xsl:variable name="LLFromRiskNode" select="ancestor::risk[Type='Motor'][1]/limit[Type='LegalLiability'][normalize-space(iValue)!=''][1]/iValue[1]"/>
    <xsl:variable name="LLFromRisk" select="string($LLFromRiskNode)"/>
	<xsl:variable name="LLFromSVNode" select="ancestor::coverage[Type='StockVehicles']/limit[Type='LegalLiability'][normalize-space(iValue)!=''][1]/iValue[1]"/>
    <xsl:variable name="LLFromSV" select="string($LLFromSVNode)"/>
    <!-- 3) FinalLimit -->
    <xsl:variable name="FinalLimit">
    	<xsl:choose>
    		<!-- Special case when the current node's Type element equals LIA_SD -->
    		<xsl:when test="normalize-space(Type) = 'LIA_SD'">
    			<xsl:choose>
						<xsl:when test="normalize-space(Code) = 'FLLIA_SD' and normalize-space($LLFromVehicle) != ''">
							<xsl:value-of select="$LLFromVehicle"/>
						</xsl:when>
						<xsl:when test="normalize-space(Code) = 'CMLIA_SD' and normalize-space($LLFromRisk) != ''">
							<xsl:value-of select="$LLFromRisk"/>
						</xsl:when>
						<xsl:when test="normalize-space(Code) = 'SVLIA_SD' and normalize-space($LLFromSV) != ''">
							<xsl:value-of select="$LLFromSV"/>
						</xsl:when>
						<xsl:otherwise>20000000</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<!-- New condition: If ProtectionType is Comprehensive or ComprehensiveMarket and Type is CMP_SD => limit 0 -->
				<xsl:when test="
              normalize-space(Type) = 'CMP_SD'
              and (
                normalize-space(ancestor::risk/ProtectionType) = 'Comprehensive'
                or normalize-space(ancestor::risk/ProtectionType) = 'ComprehensiveMarket'
              )
            ">0</xsl:when>

    		<!-- Base rule for other Type values -->
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