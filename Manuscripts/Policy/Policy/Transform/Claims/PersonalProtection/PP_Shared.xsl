<xsl:stylesheet	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

	<xsl:import href="PP_Line.xsl"/>
	<xsl:import href="PP_Building.xsl"/>
	<xsl:import href="PP_Risk_Vehicle.xsl"/>
	<xsl:import href="PP_Coverage.xsl"/>

	<xsl:template name="Policy.Extensions">
		<PolicyType>C</PolicyType>
		<ANZSICCode><xsl:value-of select="//GetANZSICCode" /></ANZSICCode>
	</xsl:template>
	
	<xsl:template name="PP_Line.Relationships">
		<xsl:call-template name="PP_Line.Excess"/>
		<xsl:apply-templates select="risk[Type='Building'][normalize-space(@deleted)!='1'][.//coverage[normalize-space(Indicator)='1']]" />
		<xsl:apply-templates select="risk[Type='Motor'][normalize-space(@deleted)!='1'][.//coverage[normalize-space(Indicator)='1']]" />		
	</xsl:template>

	<xsl:template name="Vehicle.Relationships">
		<xsl:apply-templates select=".//coverage[Indicator = '1'][Code != 'PM']"/>			
	</xsl:template>
	
	<xsl:template name="Building.Relationships">
		<xsl:apply-templates select=".//coverage[Indicator = '1'][Code != 'HB']
                              [Code != 'HC']
							  [Type != 'BLD_CY']
							  [Type != 'BLD_BF']
							  [Type != 'BLD_EQ']
							  [Type != 'BLD_ST']
							  [Type != 'CNT_CY']
							  [Type != 'CNT_BF']
							  [Type != 'CNT_EQ']
							  [Type != 'CNT_ST']
							  "/>	
	</xsl:template>

	<xsl:template name="BuildingDetails">		
		<xsl:for-each select="//risk[Type='Building']" >
			<Building id="{@id}">				
				<LocationId>
					<xsl:value-of select="LocationID"/>
				</LocationId>
				<Type>
					<xsl:value-of select="Type"/>
				</Type>
				<Details>
					<xsl:value-of select="Details"/>
				</Details>
				<Description><xsl:value-of select="BuildingName"/></Description>
			</Building>
		</xsl:for-each>
	</xsl:template>

    <xsl:template name="SPP.Relationships">
		<xsl:param name="id" select="@id"/>
		<xsl:param name="Type" select="Type"/>
		<xsl:param name="Ded">0</xsl:param>
		<xsl:param name="DedType">Total</xsl:param>
		<xsl:param name="Limit">0</xsl:param>
		<xsl:param name="LimitType">Total</xsl:param>
		<xsl:param name="Premium" select="change"/>
		<Coverage id="{$id}">
			<Type>SPP</Type>
			<Deductible type="{$DedType}" value="{$Ded}"/>
			<Limit type="{$LimitType}" value="{$Limit}"/>
			<Premium><xsl:value-of select="$Premium"/></Premium>
		</Coverage>
	</xsl:template>
	
	<xsl:template name="Address.Body">
		<Address>
			<Address1><xsl:value-of select="Address1"/></Address1>
			<Address2><xsl:value-of select="Address2"/></Address2>
			<City><xsl:value-of select="City"/></City>
			<State><xsl:value-of select="State"/></State>
			<ZipCode><xsl:value-of select="ZipCode"/></ZipCode>
			<xsl:choose>
				<xsl:when test="Country != ''">
					<Country><xsl:value-of select="Country"/></Country>
				</xsl:when>
				<xsl:when test="../Country != ''">
					<Country><xsl:value-of select="../Country"/></Country>
				</xsl:when>
				<xsl:when test="../CountryCode != ''">
					<Country><xsl:value-of select="../CountryCode"/></Country>
				</xsl:when>
				<xsl:when test="LocationCountryCode != ''">
					<Country><xsl:value-of select="LocationCountryCode"/></Country>
				</xsl:when>				
				<xsl:otherwise>
					<Country>AU</Country>
				</xsl:otherwise>
			</xsl:choose>	
			<xsl:call-template name="Address.Relationships"/>
		</Address>
	</xsl:template>

	<xsl:template match="mailingAddress">
		<xsl:call-template name="Address2.Body"/>
	</xsl:template>

	<xsl:template name="Address2.Body">
		<Address>
			<Address1><xsl:value-of select="address1"/></Address1>
			<Address2><xsl:value-of select="address2"/></Address2>
			<City><xsl:value-of select="city"/></City>
			<State><xsl:value-of select="state"/></State>
			<ZipCode><xsl:value-of select="ZIP"/></ZipCode>
			<xsl:choose>
				<xsl:when test="Country != ''">
					<Country><xsl:value-of select="Country"/></Country>
				</xsl:when>				
				<xsl:when test="../Country != ''">
					<Country><xsl:value-of select="../Country"/></Country>
				</xsl:when>
				<xsl:when test="../CountryCode != ''">
					<Country><xsl:value-of select="../CountryCode"/></Country>
				</xsl:when>
				<xsl:when test="LocationCountryCode != ''">
					<Country><xsl:value-of select="LocationCountryCode"/></Country>
				</xsl:when>				
				<xsl:otherwise>
					<Country>AU</Country>
				</xsl:otherwise>
			</xsl:choose>		
			<xsl:call-template name="Address2.Relationships"/>
		</Address>
	</xsl:template>

</xsl:stylesheet>

