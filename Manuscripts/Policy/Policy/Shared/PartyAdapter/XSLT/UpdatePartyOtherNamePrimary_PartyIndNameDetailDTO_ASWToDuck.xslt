<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="CommonTemplates.xslt"/>
  <xsl:import href="PartyIndNameTemplate_HL_ASWToDuck.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/*">
    <PartyRecord>
      <PartyOtherNames>
        <xsl:apply-templates />
      </PartyOtherNames>
    </PartyRecord>
  </xsl:template>

  <xsl:template match="ExistingPrimaryName | NewPrimaryName">
    <xsl:call-template name ="PartyIndName"/>
  </xsl:template>

  <xsl:template match="EntityAuthLevel"/>
</xsl:stylesheet>