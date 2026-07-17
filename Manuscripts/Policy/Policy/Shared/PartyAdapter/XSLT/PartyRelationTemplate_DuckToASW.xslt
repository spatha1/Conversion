<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template name="partyRelation">
		<xsl:for-each select="./PartyRelationships/PartyRelationship">
			<PartyRelationDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
				<!--<_x003C_IsValidated_x003E_k__BackingField xmlns="http://schemas.datacontract.org/2004/07/AFS.AEF">false</_x003C_IsValidated_x003E_k__BackingField>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>-->
				<xsl:call-template name="partyRelationCommonTemplate" />
			</PartyRelationDTO>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="partyRelationExtData">
		<xsl:for-each select="./PartyRelationships/PartyRelationship">
			<PartyRelationWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
				<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
				<xsl:call-template name="ExtendedData">
					<xsl:with-param name="TagName">RelationshipExtendedData</xsl:with-param>
					<xsl:with-param name="PhysicalTableName">PARTY_RELSHP</xsl:with-param>
					<xsl:with-param name="LogicalTableName">lgclPartyRelshp</xsl:with-param>
					<xsl:with-param name="LogicalColumnName">PartyRelationshipExtData</xsl:with-param>
				</xsl:call-template>
				<PartyRelation>
					<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
					<xsl:call-template name="partyRelationCommonTemplate" />
				</PartyRelation>
			</PartyRelationWithExtendedDataDTO>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="partyRelationCommonTemplate">
		<IsRelatedPartyLeader>false</IsRelatedPartyLeader>
		<LastTransactionID>
			<xsl:value-of select="PartyRelationshipLockingTS"/>
		</LastTransactionID>
		<LastUpdatedDate>
			<xsl:value-of select="string(Util:GetCurrentDate())"/>
		</LastUpdatedDate>
		<PartyID>
			<xsl:value-of select="../../PartyRecordPartyId"/>
		</PartyID>
		<RelatedPartyID>
			<xsl:value-of select="RelatedPartyId"/>
		</RelatedPartyID>
		<!--<RelatedPartyIDValue>
      <xsl:value-of select="RelatedPartyId"/>
    </RelatedPartyIDValue>-->
		<RelationshipID>
			<xsl:value-of select="PartyRelationshipId"/>
		</RelationshipID>
		<RelationshipTypeCode>
			<xsl:value-of select="string(Util:GetOneRelatedItem('DCTRelationshipType',RelationshipTypeCode,'PTYRelshpTyp'))"/>
		</RelationshipTypeCode>
		<xsl:call-template name="ExtendedData">
			<xsl:with-param name="TagName">RelationshipExtendedData</xsl:with-param>
			<xsl:with-param name="PhysicalTableName">PARTY_RELSHP</xsl:with-param>
			<xsl:with-param name="LogicalTableName">lgclPartyRelshp</xsl:with-param>
			<xsl:with-param name="LogicalColumnName">PartyRelationshipExtData</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
</xsl:stylesheet>