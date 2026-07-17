<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
  <xsl:variable name="ReferenceType" select="string(Util:GetValueByKey('ReferenceType'))" />

  <xsl:template match="/ArrayOfPartyNameDetailsDTO">
    <ArrayOfKeyValueOfstringstring xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
      <xsl:for-each select="PartyNameDetailsDTO">
        <KeyValueOfstringstring>
          <Key>
            <xsl:value-of select="PartyID" />
          </Key>
          <xsl:choose>
            <!--Party Type = Individual-->
            <xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyType)) = string(Util:getBasePartyTypeFromASWPartyType('IND'))">
              <Value>
                <xsl:variable name="legacyName">
                  <xsl:for-each select="PartyIndNameDetails/PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '06']">
                    <xsl:value-of select="FullName" />
                  </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="correspondanceName">
                  <xsl:for-each select="PartyIndNameDetails/PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '07']">
                    <xsl:value-of select="FullName" />
                  </xsl:for-each>
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="normalize-space($legacyName) != ''">
                    <xsl:value-of select="$legacyName"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$correspondanceName"/>
                  </xsl:otherwise>
                </xsl:choose>
              </Value>
            </xsl:when>
            <!--Party Type = Business-->
            <xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyType)) = string(Util:getBasePartyTypeFromASWPartyType('BUS'))">
              <Value>
                <xsl:variable name="legacyName">
                  <xsl:for-each select="PartyBusNameDetails/PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '06']">
                    <xsl:value-of select="Name" />
                  </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="correspondanceName">
                  <xsl:for-each select="PartyBusNameDetails/PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '07']">
                    <xsl:value-of select="Name" />
                  </xsl:for-each>
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="normalize-space($legacyName) != ''">
                    <xsl:value-of select="$legacyName"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$correspondanceName"/>
                  </xsl:otherwise>
                </xsl:choose>
              </Value>
            </xsl:when>
          </xsl:choose>
        </KeyValueOfstringstring>
      </xsl:for-each>
    </ArrayOfKeyValueOfstringstring>
  </xsl:template>
</xsl:stylesheet>
