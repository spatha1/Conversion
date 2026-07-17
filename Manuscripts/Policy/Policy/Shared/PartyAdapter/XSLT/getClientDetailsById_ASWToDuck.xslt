<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="getDetails_ASWToDuck.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
  <xsl:variable name="ReferenceType" select="string(Util:GetValueByKey('ReferenceType'))" />

  <xsl:template match="/PartyDetailDTO">
    <ClientDetailsDataSet>
      <ClientDetails>
        <xsl:variable name="partyId">
          <xsl:value-of select="PartyID" />
        </xsl:variable>
        <ClientID>
          <xsl:value-of select="$partyId"/>
        </ClientID>
        <xsl:choose>
          <!--Party Type = Individual-->
          <xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyIndividualDetail/Party/PartyTypeCode)) = string(Util:getBasePartyTypeFromASWPartyType('IND'))">
            <xsl:call-template name="indPartyInfo" />
          </xsl:when>
          <!--Party Type = Business-->
          <xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyBusinessDetail/Party/PartyTypeCode)) = string(Util:getBasePartyTypeFromASWPartyType('BUS'))">
            <xsl:call-template name="busPartyInfo" />
          </xsl:when>
        </xsl:choose>
      </ClientDetails>
    </ClientDetailsDataSet>
  </xsl:template>
</xsl:stylesheet>
