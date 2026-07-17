<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="PartyRelationTemplate_DuckToASW.xslt"/>
  <xsl:template match="/">
    <xsl:for-each select="PartyRecord">
      <xsl:call-template name="partyRelation" />
    </xsl:for-each>
    <!--<PartyRelationDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://epc.accenture.com/2013/06/26/Type">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:for-each select="PartyRecord/PartyRelationships/PartyRelationship">
        <LastUpdatedDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>
        <PartyID>
          <xsl:value-of select="../../PartyRecordPartyId"/>
        </PartyID>
        <RelatedPartyID>
          <xsl:value-of select="RelatedPartyId"/>
        </RelatedPartyID>
        <RelationshipTypeCode>
          <xsl:value-of select="RelationshipTypeCode"/>
        </RelationshipTypeCode>
      </xsl:for-each>
    </PartyRelationDTO>-->
  </xsl:template>
</xsl:stylesheet>

