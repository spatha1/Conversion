<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type"  xmlns:Util="urn:Util" >
  <xsl:import href="PartyLocationTemplate_DuckToASW.xslt"/>
  <xsl:output method="xml" encoding="UTF-8" indent="yes" />  
  <xsl:template match="/PartyRecord">
    <xsl:call-template name="partyLocation" />
  </xsl:template>
</xsl:stylesheet>