<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:template name="partyReference">
    <xsl:for-each select="./PartyReferences/PartyReference">
      <PartyMembershipDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <xsl:call-template name="commentReferenceTemplate" />
      </PartyMembershipDTO>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="partyReferenceExtData">
    <xsl:for-each select="./PartyReferences/PartyReference">
      <PartyMembershipWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <!--<xsl:if test="ReferenceExtendedData != '' or count(ReferenceExtendedData) > 0">
		
			<xsl:call-template name="ExtendedData">
				<xsl:with-param name="TagName">ReferenceExtendedData</xsl:with-param>
				<xsl:with-param name="AswTagName">MembershipExtendedData</xsl:with-param>
				<xsl:with-param name="PhysicalTableName">PARTY_MBRSHP</xsl:with-param>
				<xsl:with-param name="LogicalTableName">lgclPartyMbrshp</xsl:with-param>
				<xsl:with-param name="LogicalColumnName">PartyMembershipExtData</xsl:with-param>
			</xsl:call-template>-->
          <!--<ExtendedData xmlns:d4p1="http://epc.accenture.com/2013/06/26/Type">
            <xsl:value-of disable-output-escaping="yes" select="Util:CreateArrayObjectExtendedData('PARTY_MBRSHP','PartyMembershipID','lgclPartyMbrshp','PartyMembershipExtData', ReferenceExtendedData,'d4p1')" />
          </ExtendedData>-->
        <!--</xsl:if>-->
        <PartyMembership>
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
          <xsl:call-template name="commentReferenceTemplate" />
        </PartyMembership>
      </PartyMembershipWithExtendedDataDTO>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="commentReferenceTemplate">
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
    <xsl:if test="PartyReferenceId !='' ">
      <PartyMembershipID>
        <xsl:value-of select="PartyReferenceId"/>
      </PartyMembershipID>
    </xsl:if>
	<xsl:call-template name="ExtendedData">
		<xsl:with-param name="TagName">ReferenceExtendedData</xsl:with-param>
		<xsl:with-param name="AswTagName">MembershipExtendedData</xsl:with-param>
		<xsl:with-param name="PhysicalTableName">PARTY_MBRSHP</xsl:with-param>
		<xsl:with-param name="LogicalTableName">lgclPartyMbrshp</xsl:with-param>
		<xsl:with-param name="LogicalColumnName">PartyMembershipExtData</xsl:with-param>
	</xsl:call-template>
  </xsl:template>
</xsl:stylesheet>




