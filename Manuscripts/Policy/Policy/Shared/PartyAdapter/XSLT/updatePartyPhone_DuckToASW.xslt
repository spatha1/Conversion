<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>

  <xsl:template match="/">
    <PartyPhoneDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:for-each select="PartyRecord/PartyPhones/PartyPhone">
        <Comment>
          <xsl:value-of select="PhoneComments"/>
        </Comment>
        <xsl:variable name="phoneCountryCode" select="string(Util:GetOneRelatedItem('DCTCountryType',PhoneCountryCode,'243'))"/>
      
        <CountryCode>
          <xsl:value-of select="$phoneCountryCode"/>
        </CountryCode>
   
        <xsl:choose>
          <xsl:when test="PhoneEffectiveDate !=''">
            <EffectiveDate>
              <xsl:value-of select="string(Util:ConvertDateToAswFormat(PhoneEffectiveDate))"/>
            </EffectiveDate>
          </xsl:when>
          <xsl:otherwise>
            <EffectiveDate>
              <xsl:value-of select="string(Util:GetCurrentDate())"/>
            </EffectiveDate>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="PhoneExpirationDate !=''">
            <ExpirationDate>
              <xsl:value-of select="string(Util:ConvertDateToAswFormat(PhoneExpirationDate))"/>
            </ExpirationDate>
          </xsl:when>
          <xsl:otherwise>
            <ExpirationDate>
              <xsl:value-of select="string(Util:GetMaxDate())"/>
            </ExpirationDate>
          </xsl:otherwise>
        </xsl:choose>

        <ExternalPartyPhoneID>
          <xsl:value-of select="ExternalPartyPhoneId"/>
        </ExternalPartyPhoneID>
        
        <FullPhoneNumber>
          <xsl:value-of select="string(Util:FormatPhoneNumber(PhoneNumber))"/>
        </FullPhoneNumber>
        <GeographicFormatCode>
          <xsl:value-of select="string(Util:GetChildKey('8036',$phoneCountryCode,'243'))"/>
        </GeographicFormatCode>
        <IsPrimary>
          <xsl:value-of select="string(Util:ConvertPrimaryIndicatorToASWFormat(PrimaryIndicator, 1))"/>
        </IsPrimary>
        <LastTransactionID>
          <xsl:value-of select="PartyPhoneLockingTS"/>
        </LastTransactionID>
        <LastUpdatedDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>

        <PartyID>
          <xsl:value-of select="../../PartyRecordPartyId"/>
        </PartyID>
        <PartyPhoneID>
          <xsl:value-of select="PartyPhoneId"/>
        </PartyPhoneID>
        <PhoneExtension>
          <xsl:value-of select="PhoneExtension"/>
        </PhoneExtension>
        <PhoneTypeCode>
          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPhoneType',PhoneTypeCode,'26'))"/>
        </PhoneTypeCode>
     
		<xsl:call-template name="ExtendedData">
			<xsl:with-param name="TagName">PhoneExtendedData</xsl:with-param>
			<xsl:with-param name="SuiteTagName">PhoneSuiteExtendedData</xsl:with-param>
			<xsl:with-param name="PhysicalTableName">PARTY_PHN</xsl:with-param>
			<xsl:with-param name="LogicalTableName">lgclPartyPhone</xsl:with-param>
			<xsl:with-param name="LogicalColumnName">PartyPhoneExtData</xsl:with-param>
		</xsl:call-template>
      </xsl:for-each>
    </PartyPhoneDTO>
  </xsl:template>
</xsl:stylesheet>