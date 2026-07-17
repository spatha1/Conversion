<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="i xs msxsl xsl Util">
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/AddressDTO">
    <PartyRecord>
      <PartyRecordPartyId></PartyRecordPartyId>
      <Locations>
		<xsl:call-template name="indPartyAddress" />
      </Locations>
    </PartyRecord>
  </xsl:template>
 </xsl:stylesheet>




