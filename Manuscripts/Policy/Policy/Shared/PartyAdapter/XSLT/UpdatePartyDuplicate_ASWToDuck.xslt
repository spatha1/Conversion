<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="CommonTemplates.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:template match="ArrayOfPartyMatchDTO">
    <PartyDuplicateRecord>
	<PartyDuplicates>
      <xsl:for-each select="PartyMatchDTO">
        <PartyDuplicate>
          <xsl:call-template name ="commonDuplicateFields" />
           <xsl:call-template name="ResponseInfo">
            <xsl:with-param name="ReturnCode">0</xsl:with-param>
             <xsl:with-param name="NotificationResponse"></xsl:with-param>
          </xsl:call-template>
        </PartyDuplicate>
      </xsl:for-each>
	  </PartyDuplicates>
    </PartyDuplicateRecord>
  </xsl:template>

  <xsl:template name="commonDuplicateFields">
    <PartyMatchId>
      <xsl:value-of select="PartyMatchID"/>
    </PartyMatchId>
    <PartyId>
      <xsl:value-of select="PartyID"/>
    </PartyId>
    <RelatedPartyId>
      <xsl:value-of select="RelatedPartyID"/>
    </RelatedPartyId>
    <MatchPercent>
      <xsl:value-of select="MatchPercent"/>
    </MatchPercent>
    <LastUpdatedDate>
      <xsl:value-of select="string(Util:ConvertDateToDuckFormat(LastUpdatedDate))"/>
    </LastUpdatedDate>
    <PartyMatchLockingTS>
      <xsl:value-of select="LastTransactionID"/>
    </PartyMatchLockingTS>
    <MatchTypeCode>
      <xsl:value-of select="MatchTypeCode"/>
    </MatchTypeCode>

  </xsl:template>

</xsl:stylesheet>
