<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:import href="BP_Excess.xsl"/>
	
	<xsl:template match="risk[Type='Motor' and FleetType!='Fleet'][normalize-space(@deleted)!='1'][.//coverage[normalize-space(Indicator)='1']]">
		<xsl:call-template name="Vehicle.Body"/>
	</xsl:template>
	<xsl:template match="risk[Type='Motor' and FleetType='Fleet'][normalize-space(@deleted)!='1']/Vehicle[.//coverage[normalize-space(Indicator)='1']][normalize-space(@deleted)!='1']">
		<xsl:call-template name="FleetVehicle.Body"/>
	</xsl:template>
	
	<xsl:template name="Vehicle.Body">
		<Risk id="{@id}">
		    <Type><xsl:value-of select="Type"/></Type>
		    <RegistrationNumber><xsl:value-of select="RegistrationNumber"/></RegistrationNumber>
			<CoverType><xsl:value-of select="CoverType"/></CoverType>
			<VIN><xsl:value-of select="VinNumber"/></VIN>
			<State><xsl:value-of select="State"/></State>
			<BodyType><xsl:value-of select="BodyType"/></BodyType>
			<Make><xsl:value-of select="Make"/></Make>
			<Model><xsl:value-of select="Model"/></Model>
			<Year><xsl:value-of select="Year"/></Year>
			<Description><xsl:value-of select="MarketValueDescription"/></Description>
			<TotalValue><xsl:value-of select="MarketValueDescriptionValue"/></TotalValue>
			<Usage><xsl:value-of select="Use"/></Usage>
			<VehicleType><xsl:value-of select="VehicleType"/></VehicleType>
			<Mileage><xsl:value-of select="AnnualMileage"/></Mileage>
			<VehicleFullDescription><xsl:value-of select="VehicleFullDescription"/></VehicleFullDescription>
			<WindscreenExtensionBenefitUsed><xsl:value-of select="WindscreenExtFlag"/></WindscreenExtensionBenefitUsed>
			<AdditonalParty><xsl:value-of select="AddDetailsForTheInterestedParty"/></AdditonalParty>
			<Excess type="CommercialVehicle">
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
			    <Total><xsl:value-of select="$totalExcess"/></Total>
				<OnHookTowing><xsl:value-of select="Excess/OnHook"/></OnHookTowing>
				<Age>
                	<AgeOfYoungestRegularDriver>
                		<xsl:value-of select="AgeOfYoungestRegularDriver"/>
                	</AgeOfYoungestRegularDriver>
					<RestrictionOfDriverAge>
                    <xsl:choose>
                        <xsl:when test="RestrictionOfDriverAge = 0">0</xsl:when>
                        <xsl:when test="RestrictionOfDriverAge = 20">21</xsl:when>
                        <xsl:when test="RestrictionOfDriverAge = 24">25</xsl:when>
                        <xsl:when test="RestrictionOfDriverAge = 29">30</xsl:when>
                        <xsl:when test="RestrictionOfDriverAge = 39">40</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="RestrictionOfDriverAge"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </RestrictionOfDriverAge>
                	<AgeLessThan20>
                		<xsl:value-of select="Excess/AgeLessThan20"/>
                	</AgeLessThan20>
                	<AgeBetween20To21>
                		<xsl:value-of select="Excess/AgeBetween20To21"/>
                	</AgeBetween20To21>
                	<AgeBetween22To25>
                		<xsl:value-of select="Excess/AgeBetween22To25"/>
                	</AgeBetween22To25>
                </Age>
		    </Excess>
		<xsl:call-template name="Vehicle.Relationships"/>
		</Risk>
	</xsl:template>
	<xsl:template name="FleetVehicle.Body">
		<Risk id="{@id}">
		    <RiskID><xsl:value-of select="parent::risk/@id"/></RiskID>
		    <Type><xsl:value-of select="Type"/></Type>
		    <RegistrationNumber><xsl:value-of select="Registration"/></RegistrationNumber>
			<CoverType><xsl:value-of select="CoverType"/></CoverType>
			<VIN><xsl:value-of select="VinNumber"/></VIN>
			<State><xsl:value-of select="State"/></State>
			<BodyType><xsl:value-of select="BodyType"/></BodyType>
			<Make><xsl:value-of select="Make"/></Make>
			<Model><xsl:value-of select="Model"/></Model>
			<Year><xsl:value-of select="Year"/></Year>
			<Description><xsl:value-of select="VehicleAccessoriesDescription"/></Description>
			<TotalValue><xsl:value-of select="VehicleAccessoriesValue"/></TotalValue>
			<Usage><xsl:value-of select="Use"/></Usage>
			<VehicleType><xsl:value-of select="VehicleType"/></VehicleType>
			<Mileage><xsl:value-of select="AnnualMileage"/></Mileage>
			<VehicleFullDescription><xsl:value-of select="VehicleFullDescription"/></VehicleFullDescription>
			<WindscreenExtensionBenefitUsed><xsl:value-of select="WindscreenExtFlag"/></WindscreenExtensionBenefitUsed>
			<AdditonalParty><xsl:value-of select="AdditonalParty"/></AdditonalParty>
			<Excess type="FleetVehicle">
			<!-- Clean raw values -->
                <xsl:variable name="standardRaw" select="translate(parent::risk/Excess/Standard, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ', '')"/>
                <xsl:variable name="voluntaryRaw" select="translate(parent::risk/Excess/Voluntary, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ', '')"/>
                <xsl:variable name="imposedRaw" select="translate(parent::risk/Excess/Imposed, 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ ', '')"/>
                
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
			
			<Total><xsl:value-of select="$totalExcess"/></Total>
			<OnHookTowing><xsl:value-of select="parent::risk/Excess/OnHook"/></OnHookTowing>
			<Age>
            	<AgeOfYoungestRegularDriver>
            		<xsl:value-of select="parent::risk/AgeOfYoungestRegularDriver"/>
            	</AgeOfYoungestRegularDriver>
				<RestrictionOfDriverAge>
                    <xsl:choose>
                        <xsl:when test="parent::risk/RestrictionOfDriverAge = 0">0</xsl:when>
                        <xsl:when test="parent::risk/RestrictionOfDriverAge = 20">21</xsl:when>
                        <xsl:when test="parent::risk/RestrictionOfDriverAge = 24">25</xsl:when>
                        <xsl:when test="parent::risk/RestrictionOfDriverAge = 29">30</xsl:when>
                        <xsl:when test="parent::risk/RestrictionOfDriverAge = 39">40</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="parent::risk/RestrictionOfDriverAge"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </RestrictionOfDriverAge>
            	<AgeLessThan20>
            		<xsl:value-of select="parent::risk/Excess/AgeLessThan20"/>
            	</AgeLessThan20>
            	<AgeBetween20To21>
            		<xsl:value-of select="parent::risk/Excess/AgeBetween20To21"/>
            	</AgeBetween20To21>
            	<AgeBetween22To25>
            		<xsl:value-of select="parent::risk/Excess/AgeBetween22To25"/>
            	</AgeBetween22To25>
            </Age>
		    </Excess>
			<xsl:call-template name="Vehicle.Relationships"/>
		</Risk>
	</xsl:template>


</xsl:stylesheet>