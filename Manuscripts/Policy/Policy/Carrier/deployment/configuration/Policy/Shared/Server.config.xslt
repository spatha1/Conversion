<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

<!-- Example

  <xsl:template match="/configuration/Policy/add[@key='HistoryStorageMethod']/@value">
     <xsl:attribute name="{name()}">GZipped</xsl:attribute>
  </xsl:template>
  <xsl:template match="/configuration/Policy/add[@key='HistoryStorageThreshold']/@value">
     <xsl:attribute name="{name()}">100</xsl:attribute>
  </xsl:template>
  <xsl:template match="/configuration/Policy/add[@key='ExtendedDataStorageMethod']/@value">
     <xsl:attribute name="{name()}">GZipped</xsl:attribute>
  </xsl:template>
  <xsl:template match="/configuration/Policy/add[@key='ExtendedDataStorageThreshold']/@value">
     <xsl:attribute name="{name()}">100</xsl:attribute>
  </xsl:template>
  <xsl:template match="/configuration/Manuscript/add[@key='CacheCount']/@value">
     <xsl:attribute name="{name()}">500</xsl:attribute>
  </xsl:template>
-->



</xsl:stylesheet>