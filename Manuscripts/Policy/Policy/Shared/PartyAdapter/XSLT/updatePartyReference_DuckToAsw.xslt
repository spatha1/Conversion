<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
<xsl:import href="CommonTemplates.xslt"/>
  <xsl:template match="/">
    <xsl:for-each select="PartyRecord">
      <PartyMembershipDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <xsl:for-each select="./PartyReferences/PartyReference">
          <LastTransactionID>
            <xsl:value-of select="PartyReferenceLockingTS"/>
          </LastTransactionID>
          <LastUpdatedDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </LastUpdatedDate>
          <MembershipID>
            <xsl:value-of select="Reference"/>
          </MembershipID>
          <MembershipTypeCode>
            <xsl:value-of select="string(Util:GetOneRelatedItem('DCTReferenceType',ReferenceTypeCode,'PTYMbrshpTyp'))"/>
          </MembershipTypeCode>
          <PartyID>
            <xsl:value-of select="../../PartyRecordPartyId"/>
          </PartyID>
          <PartyMembershipID>
            <xsl:value-of select="PartyReferenceId"/>
          </PartyMembershipID>
		  <xsl:call-template name="ExtendedData">
			<xsl:with-param name="TagName">ReferenceExtendedData</xsl:with-param>
			<xsl:with-param name="AswTagName">MembershipExtendedData</xsl:with-param>
			<xsl:with-param name="PhysicalTableName">PARTY_MBRSHP</xsl:with-param>
			<xsl:with-param name="LogicalTableName">lgclPartyMbrshp</xsl:with-param>
			<xsl:with-param name="LogicalColumnName">PartyMembershipExtData</xsl:with-param>
		</xsl:call-template>
        </xsl:for-each>
      </PartyMembershipDTO>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>

