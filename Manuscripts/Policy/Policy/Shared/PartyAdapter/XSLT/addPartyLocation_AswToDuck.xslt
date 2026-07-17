<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="CommonTemplates.xslt"/>
	<xsl:import href="PartyLocationTemplate_ASWToDuck.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/PartyAddressDetailDTO">
    <PartyRecord>       
      <Locations  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <xsl:for-each select="Address">
					<xsl:call-template name="indPartyAddress" />
        </xsl:for-each>
      </Locations>
      <xsl:call-template name="ResponseInfo">
        <xsl:with-param name="ReturnCode">0</xsl:with-param>
        <xsl:with-param name="NotificationResponse"></xsl:with-param>
      </xsl:call-template>
    </PartyRecord>
  </xsl:template>
</xsl:stylesheet>