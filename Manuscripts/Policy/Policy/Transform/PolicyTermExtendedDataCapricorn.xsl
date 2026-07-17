<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes"/>
	<!-- This is a line specific template for building the MPR structure inside the PolicyTermExtended data node -->
	<!-- the context is established by the calling template so all paths here are relative to the established context-->
	<xsl:template name="PolicyTermExtendedDataCapricorn">
		<!-- the context node when this template is called is <policy> -->
		<xsl:if test="MPRPolicy='1'">
			<MPRData>
				<xsl:for-each select="../account/location">
					<xsl:call-template name="Capricorn_Location"/>
				</xsl:for-each>
			</MPRData>
		</xsl:if>
		<ModNumber>
			<xsl:value-of select="ModNumber"/>
		</ModNumber>
		<xsl:choose>
			<xsl:when test="MembershipFlag = 1">
				<MembershipFlag>1</MembershipFlag>
			</xsl:when>
			<xsl:otherwise>
				<MembershipFlag>0</MembershipFlag>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="Capricorn_Location">
		<xsl:variable name="description" select="Description"/>
		<xsl:variable name="id" select="@id"/>
		<Location>
			<xsl:attribute name="description">
				<xsl:value-of select="$description"/>
			</xsl:attribute>
			<xsl:for-each select="../../policy/line/risk[LocationID=$id and not(@deleted = 1)]">
				<xsl:call-template name="Capricorn_Risk"/>
			</xsl:for-each>
		</Location>
	</xsl:template>
	<xsl:template name="Capricorn_Risk">
		<Risk>
			<xsl:attribute name="classCode"/>
			<xsl:attribute name="NetRate">
				<xsl:value-of select="RiskFactor"/>
			</xsl:attribute>
			<xsl:attribute name="GrossWages"/>
			<xsl:attribute name="ExcessOT"/>
			<xsl:attribute name="ChargeableWages">
				<xsl:value-of select="InsurableAmount"/>
			</xsl:attribute>
			<xsl:attribute name="Premium"/>
			<xsl:attribute name="description">
				<xsl:value-of select="exposure[Type='Description']/Description"/>
			</xsl:attribute>
		</Risk>
	</xsl:template>
</xsl:stylesheet>