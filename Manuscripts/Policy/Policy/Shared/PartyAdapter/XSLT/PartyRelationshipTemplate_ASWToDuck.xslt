<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>

	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

	<xsl:template name="indPartyRelationship">
		<xsl:param name="showRelatedName">yes</xsl:param>		
		<PartyRelationship>
			<PartyRelationshipId>
				<xsl:value-of select="RelationshipID" />
			</PartyRelationshipId>
			<RelatedPartyId>
				<xsl:value-of select="RelatedPartyID" />
			</RelatedPartyId>
			<!-- <RelatedPartyIdValue>
				<xsl:value-of select="RelatedPartyID" />
			</RelatedPartyIdValue> -->
			<RelationshipTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTRelationshipType',RelationshipTypeCode,'PTYRelshpTyp'))" />
			</RelationshipTypeCode>
			<xsl:if test="$showRelatedName='yes'">
				<RelatedPartyName>
					<xsl:value-of select="string(Util:GetRelatedPartyName(RelatedPartyID))" />
				</RelatedPartyName>
			</xsl:if>
			<PartyRelationshipLockingTS>
				<xsl:value-of select="LastTransactionID" />
			</PartyRelationshipLockingTS>
			<xsl:call-template name="ExtendedDataASWToDuck">
				<xsl:with-param name="TagName">RelationshipExtendedData</xsl:with-param>
			</xsl:call-template>
		</PartyRelationship>
	</xsl:template>
</xsl:stylesheet>