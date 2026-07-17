<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes" method="xml"/>
	<xsl:template match="ManuScript.getFieldDetailRs">
		<BindingRestrictions>
			<xsl:for-each select="//table[@id='Embargoes']/data/row">
				<xsl:variable name="val" select="@value"/>
				<xsl:variable name="v1" select="substring-before($val, '|')"/>
				<xsl:variable name="rest1" select="substring-after($val, '|')"/>
				<xsl:variable name="v2" select="substring-before($rest1, '|')"/>
				<xsl:variable name="rest2" select="substring-after($rest1, '|')"/>
				<xsl:variable name="v3" select="substring-before($rest2, '|')"/>
				<xsl:variable name="rest3" select="substring-after($rest2, '|')"/>
				<xsl:variable name="v4" select="substring-before($rest3, '|')"/>
				<xsl:variable name="rest4" select="substring-after($rest3, '|')"/>
				<xsl:variable name="v5" select="substring-before($rest4, '|')"/>
				<xsl:variable name="rest5" select="substring-after($rest4, '|')"/>
				<xsl:variable name="v6" select="substring-before($rest5, '|')"/>
				<xsl:variable name="rest6" select="substring-after($rest5, '|')"/>
				<xsl:variable name="v7" select="substring-before($rest6, '|')"/>
				<xsl:variable name="rest7" select="substring-after($rest6, '|')"/>
				<xsl:variable name="v8" select="substring-before($rest7, '|')"/>
				<xsl:variable name="rest8" select="substring-after($rest7, '|')"/>
				<xsl:variable name="v9" select="substring-before($rest8, '|')"/>
				<xsl:variable name="rest9" select="substring-after($rest8, '|')"/>
				<xsl:variable name="v10" select="substring-before($rest9, '|')"/>
				<xsl:variable name="rest10" select="substring-after($rest9, '|')"/>
				<xsl:variable name="v11" select="substring-before($rest10, '|')"/>
				<xsl:variable name="postcodeList" select="substring-after($rest10, '|')"/>
				<Restriction>
					<Event>
						<xsl:value-of select="$v1"/>
					</Event>
					<RestrictionType>
						<xsl:value-of select="$v2"/>
					</RestrictionType>
					<Country>
						<xsl:value-of select="$v3"/>
					</Country>
					<Zone>
						<xsl:value-of select="$v4"/>
					</Zone>
					<CSLRegion>
						<xsl:value-of select="$v5"/>
					</CSLRegion>
					<CoverageType>
						<xsl:value-of select="$v6"/>
					</CoverageType>
					<State>
						<xsl:value-of select="$v7"/>
					</State>
					<Postcode>
						<xsl:value-of select="$v8"/>
					</Postcode>
					<FromDate>
						<xsl:value-of select="$v9"/>
					</FromDate>
					<ToDate>
						<xsl:value-of select="$v10"/>
					</ToDate>
					<LOB>
						<xsl:value-of select="$v11"/>
					</LOB>
					<Extended>
						<XMLData>
							<xsl:call-template name="split-postcodes">
								<xsl:with-param name="list" select="$postcodeList"/>
							</xsl:call-template>
						</XMLData>
					</Extended>
				</Restriction>
			</xsl:for-each>
		</BindingRestrictions>
	</xsl:template>
	<xsl:template name="split-postcodes">
		<xsl:param name="list"/>
		<xsl:if test="string-length($list) &gt; 0">
			<xsl:variable name="first" select="substring-before(concat($list, ','), ',')"/>
			<xsl:variable name="rest" select="substring-after($list, ',')"/>
			<row>
				<Postcode>
					<xsl:value-of select="$first"/>
				</Postcode>
			</row>
			<xsl:call-template name="split-postcodes">
				<xsl:with-param name="list" select="$rest"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
