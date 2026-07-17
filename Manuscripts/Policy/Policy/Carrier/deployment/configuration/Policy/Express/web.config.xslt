<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />
  <xsl:template match="@* | node()">
   <xsl:copy >
    <xsl:apply-templates select="@* | node()"/>
  </xsl:copy>
  </xsl:template>
  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
   <xsl:variable name="CarrierName">#{CarrierName}</xsl:variable>

  <!-- 
      update attributes and elements with values or substitution variables
      Note: if specifying the a substituion value, value will be substituted in this file
      prior to running the transform.
  
  <xsl:template match="/configuration/appSettings/add[@key='CarrierName']/@value">
    <xsl:attribute name="{name()}"><xsl:value-of select="$CarrierName" /></xsl:attribute>
  </xsl:template>
-->

</xsl:stylesheet>

