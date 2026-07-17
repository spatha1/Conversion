<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:output method="text" cdata-section-elements="EmailExtendedData"  indent="yes"/>
  <xsl:template name="ExtendedData">
    <xsl:text disable-output-escaping="yes">&lt;![CDATA[</xsl:text>
    <xsl:copy-of select="EmailExtendedData" />
    <xsl:text disable-output-escaping="yes">]]&gt;</xsl:text>
  </xsl:template>
</xsl:stylesheet>
