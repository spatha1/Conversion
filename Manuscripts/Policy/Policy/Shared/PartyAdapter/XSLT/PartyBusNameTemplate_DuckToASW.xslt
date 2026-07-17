<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="CommonTemplates.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

  <xsl:template name="partyBusName">
    <xsl:for-each select="./PartyOtherNames/PartyOtherName">
      <PartyBusNameDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <xsl:call-template name="partyBusNameCommonTemplate" />
        <xsl:call-template name="partyName_BusCommenTemplate" />
      </PartyBusNameDetailDTO>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="partyBusNameExtData">
    <xsl:for-each select="./PartyOtherNames/PartyOtherName">
      <PartyBusNameDetailWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <xsl:call-template name="partyBusNameCommonTemplate" />

        <xsl:call-template name="ExtendedData">
          <xsl:with-param name="TagName">OtherNameExtendedData</xsl:with-param>
		  <xsl:with-param name="SuiteTagName">PartyOtherNameSuiteExtendedData</xsl:with-param>
          <xsl:with-param name="AswTagName">BusinessNameExtendedData</xsl:with-param>
          <xsl:with-param name="PhysicalTableName">PARTY_BUS_NM</xsl:with-param>
          <xsl:with-param name="LogicalTableName">lgclPartyBusNm</xsl:with-param>
          <xsl:with-param name="LogicalColumnName">PartyBusNameExtData</xsl:with-param>
        </xsl:call-template>

        <xsl:call-template name="partyName_BusCommenTemplate" />
      </PartyBusNameDetailWithExtendedDataDTO>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="partyBusNameCommonTemplate">
    <PartyBusName>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <Comment>
        <xsl:value-of select="OtherNameComments"/>
      </Comment>
      <LastTransactionID>
        <xsl:value-of select="PartyBusNamesLockingTS"/>
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <Name>
        <xsl:value-of select="OtherNamePartyName"/>
      </Name>
      <NameTypeCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameType',OtherNameTypeCode,'29'))"/>
      </NameTypeCode>
      <PartyBusNameID>
        <xsl:value-of select="PartyOtherNameId"/>
      </PartyBusNameID>
      <xsl:call-template name="ExtendedData">
        <xsl:with-param name="TagName">OtherNameExtendedData</xsl:with-param>
		<xsl:with-param name="SuiteTagName">PartyOtherNameSuiteExtendedData</xsl:with-param>
        <xsl:with-param name="AswTagName">BusinessNameExtendedData</xsl:with-param>
        <xsl:with-param name="PhysicalTableName">PARTY_BUS_NM</xsl:with-param>
        <xsl:with-param name="LogicalTableName">lgclPartyBusNm</xsl:with-param>
        <xsl:with-param name="LogicalColumnName">PartyBusNameExtData</xsl:with-param>
      </xsl:call-template>
    </PartyBusName>
  </xsl:template>

  <xsl:template name="partyName_BusCommenTemplate" >
    <xsl:variable name="partyIndOtherNameCountry">
      <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',OtherNameCountryCode,'243'))"/>
    </xsl:variable>
    <PartyName>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <AllowPartial>false</AllowPartial>
      <CountryCode>
        <xsl:value-of select="$partyIndOtherNameCountry"/>
      </CountryCode>
      <xsl:choose>
        <xsl:when test="OtherNameEffectiveDate !=''">
          <EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(OtherNameEffectiveDate))"/>
          </EffectiveDate>
        </xsl:when>
        <xsl:otherwise>
          <EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </EffectiveDate>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="OtherNameExpirationDate !=''">
          <ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(OtherNameExpirationDate))"/>
          </ExpirationDate>
        </xsl:when>
        <xsl:otherwise>
          <ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </ExpirationDate>
        </xsl:otherwise>
      </xsl:choose>
      <GeographicFormatCode>
        <xsl:value-of select="string(Util:GetChildKey('8036',$partyIndOtherNameCountry,'243'))"/>
      </GeographicFormatCode>
      <IsPrimary>
        <xsl:choose>
          <xsl:when test="OtherNameIsPrimary = '1'">true</xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </IsPrimary>
      <IsTaxName>false</IsTaxName>
      <LastTransactionID>
        <xsl:value-of select="PartyOtherNamesLockingTS"/>
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <PartyID>
        <xsl:value-of select="../../PartyRecordPartyId"/>
      </PartyID>
      <PartyNameID>
        <xsl:value-of select="PartyOtherNameId"/>
      </PartyNameID>
      <IsDefault>
        <xsl:choose>
          <xsl:when test="OtherNameIsDefault = '1'">true</xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </IsDefault>
    </PartyName>
  </xsl:template>
</xsl:stylesheet>