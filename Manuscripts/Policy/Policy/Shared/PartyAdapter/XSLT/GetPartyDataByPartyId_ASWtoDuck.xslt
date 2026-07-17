<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	
	<xsl:template match="/ArrayOfPartyDetailDTO">
		<Party>
			<xsl:for-each select ="PartyDetailDTO">
				<PartyData>
					<xsl:call-template name="partyNameTemplate" >
					</xsl:call-template>
					<xsl:call-template name="partyReferenceTemplate" >
					</xsl:call-template>
				</PartyData>
			</xsl:for-each>
		</Party>
		
	</xsl:template>

	<xsl:template name="partyNameTemplate">
		<xsl:variable name="PartyID" select="PartyID" />
		<xsl:variable name="PartyName" select="string(Util:GetValueByKey($PartyID))" />

		<PartyName>
			<xsl:value-of select="$PartyName"/>
		</PartyName>
	</xsl:template>

		
	<xsl:template name="partyReferenceTemplate">
		<xsl:choose>
			<!--Party Type = Individual-->
			<xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyType)) = string(Util:getBasePartyTypeFromASWPartyType('IND'))">
				<xsl:call-template name="indPartyRefInfo" />
			</xsl:when>

			<!--Party Type = Business-->
			<xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyType)) = string(Util:getBasePartyTypeFromASWPartyType('BUS'))">
				<xsl:call-template name="busPartyRefInfo" />
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="indPartyRefInfo" >
		<xsl:for-each select="PartyIndividualDetail/PartyMembership/PartyMembershipDTO">
			<Reference>
				<xsl:value-of select="MembershipID"/>
			</Reference>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="busPartyRefInfo" >
			<xsl:for-each select="PartyBusinessDetail/PartyMembership/PartyMembershipDTO">
				<Reference>
					<xsl:value-of select="MembershipID"/>
				</Reference>
			</xsl:for-each>	
	</xsl:template>
</xsl:stylesheet>
