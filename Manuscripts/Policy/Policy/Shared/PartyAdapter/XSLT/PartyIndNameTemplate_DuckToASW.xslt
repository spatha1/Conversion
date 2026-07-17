<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="CommonTemplates.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:template name="PartyOtherName">
    <PartyNameDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
      <AllowPartial>false</AllowPartial>
      <CountryCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',OtherNameCountryCode,'243'))"/>
      </CountryCode>
      <EffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(OtherNameEffectiveDate))"/>
      </EffectiveDate>
      <ExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(OtherNameExpirationDate))"/>
      </ExpirationDate>
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
      <PartyNameID>
        <xsl:value-of select="PartyOtherNameId"/>
      </PartyNameID>
      <IsDefault>
        <xsl:choose>
          <xsl:when test="OtherNameIsDefault = '1'">true</xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </IsDefault>
    </PartyNameDTO>
  </xsl:template>
  <xsl:template name="partyIndName">
    <xsl:for-each select="./PartyOtherNames/PartyOtherName">
      <PartyIndNameDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <xsl:call-template name="partyIndNameCommonTemplate" />
        <xsl:call-template name="partyNameCommonTemplate" />
      </PartyIndNameDetailDTO>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="partyIndNameExtData">
    <xsl:for-each select="./PartyOtherNames/PartyOtherName">
      <PartyIndNameDetailWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>

        <xsl:call-template name="partyIndNameCommonTemplate" />

        <xsl:call-template name="partyNameCommonTemplate" />

      </PartyIndNameDetailWithExtendedDataDTO>
    </xsl:for-each>
  </xsl:template>
  <xsl:template name="partyIndNameCommonTemplate">
    <PartyIndName xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <Comment>
        <xsl:value-of select="OtherNameComments"/>
      </Comment>
      <FirstName>
        <xsl:value-of select="OtherNameFirstName"/>
      </FirstName>

      <FullName/>
      <LastName>
        <xsl:value-of select="OtherNamePartyName"/>
      </LastName>

      <LastTransactionID>
        <xsl:value-of select="PartyIndNamesLockingTS"/>
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <MiddleName>
        <xsl:value-of select="OtherNameMiddleName"/>
      </MiddleName>

      <NameTypeCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameType',OtherNameTypeCode,'29'))"/>
      </NameTypeCode>
      <PartyIndNameID>
        <xsl:value-of select="PartyOtherNameId"/>
      </PartyIndNameID>
      <PrefixCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNamePrefix',OtherNamePrefixCode,'34'))"/>
      </PrefixCode>
      <SuffixCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameSuffix',OtherNameSuffixCode,'48'))"/>
      </SuffixCode>
      <xsl:call-template name="ExtendedData">
        <xsl:with-param name="TagName">OtherNameExtendedData</xsl:with-param>
		<xsl:with-param name="SuiteTagName">PartyOtherNameSuiteExtendedData</xsl:with-param>
        <xsl:with-param name="AswTagName">IndividualNameExtendedData</xsl:with-param>
        <xsl:with-param name="PhysicalTableName">PARTY_INDVDL_NM</xsl:with-param>
        <xsl:with-param name="LogicalTableName">lgclPartyIndvNm</xsl:with-param>
        <xsl:with-param name="LogicalColumnName">PartyIndNameExtData</xsl:with-param>
      </xsl:call-template>
    </PartyIndName>
  </xsl:template>
  <xsl:template name="partyNameCommonTemplate">
    <xsl:variable name="partyBusOtherNameCountry">
      <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',OtherNameCountryCode,'243'))"/>
    </xsl:variable>
    <PartyName xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <AllowPartial>false</AllowPartial>
      <CountryCode>
        <xsl:value-of select="$partyBusOtherNameCountry"/>
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
      <ExternalPartyNameID/>
      <GeographicFormatCode>
        <xsl:value-of select="string(Util:GetChildKey('8036',$partyBusOtherNameCountry,'243'))"/>
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