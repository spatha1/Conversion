<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="PartyIndNameTemplate_DuckToASW.xslt"/>
  <xsl:param name="IsDefault"/>
  <xsl:template match="/">
    <xsl:for-each select="PartyOtherName[OtherNameIsDefault = $IsDefault]">
      <xsl:call-template name="PartyOtherName" />
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>