<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="getParty_ASWToDuck.xslt"/>
	
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
  
	
  <xsl:template match="/ArrayOfPartyDetailDTO">
    <xsl:choose>
      <!--This condition is to add the Parties tag over the response in case of getpartylit <Parties>e-->
		<xsl:when test="$MethodName = 'GetPartyDetails'">
		  <Parties>
			<xsl:for-each select="PartyDetailDTO">
				<xsl:call-template name="partyRecordTemplate"/>
			</xsl:for-each>
		  </Parties>
      </xsl:when>
      <xsl:otherwise>
		  <xsl:for-each select="PartyDetailDTO">
			<xsl:call-template name="partyRecordTemplate"/>
		  </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>