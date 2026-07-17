<xsl:stylesheet version="1.0"  xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:d2p1="AFS.AEF.WCF.Types" xmlns:d4p1="Address.Types" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="d4p1 xs msxsl xsl Util">
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

  <xsl:template name="Party" xmlns="Party.Types">
    <xsl:param name="party"></xsl:param>
    <Party>
      <EntityAuthLevel xmlns="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common">None</EntityAuthLevel>
      <ACHPartyExternalID>
        <xsl:value-of select="$party/ACHPartyExternalID" />
      </ACHPartyExternalID>
      <BusinessPermitted>
        <xsl:value-of select="$party/BusinessPermitted" />
      </BusinessPermitted>
      <CountryCode>
        <xsl:value-of select="$party/CountryCode" />
      </CountryCode>
      <ExternalID>
        <xsl:value-of select="$party/ExternalID" />
      </ExternalID>
      <GeographicFormatCode>
        <xsl:value-of select="$party/GeographicFormatCode" />
      </GeographicFormatCode>
      <IsInActive>
        <xsl:value-of select="$party/IsInActive" />
      </IsInActive>
      <LastTransactionID>
        <xsl:value-of select="$party/LastTransactionID" />
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="$party/LastUpdatedDate" />
      </LastUpdatedDate>
      <Number>
        <xsl:value-of select="$party/Number" />
      </Number>
      <PartyID>
        <xsl:value-of select="$party/PartyID" />
      </PartyID>
      <PartyTypeCode>
        <xsl:value-of select="$party/PartyTypeCode" />
      </PartyTypeCode>
      <SkipLoadingExtendedData>
        <xsl:value-of select="$party/SkipLoadingExtendedData" />
      </SkipLoadingExtendedData>
      <PartySubTypeCode>
        <xsl:value-of select="$party/PartySubTypeCode" />
      </PartySubTypeCode>
	  <xsl:if test="string(Util:ShowPartyTimeZone($party/PartyTimeZone)) != ''">
		  <PartyTimeZone>
			<xsl:value-of select="$party/PartyTimeZone" />
		  </PartyTimeZone>
	  </xsl:if>
      <PartyExtendedData xmlns:d2p1="AFS.AEF.WCF.Types">
        <xsl:call-template name="ExtendedDataNS">
          <xsl:with-param name="extendedData" select="$party/PartyExtendedData" />
        </xsl:call-template>
      </PartyExtendedData>
    </Party>
  </xsl:template>

  <xsl:template name="PartyBusiness" xmlns="Party.Types">
    <xsl:param name="partyBusiness"></xsl:param>
    <PartyBusiness>
      <EntityAuthLevel xmlns="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common">None</EntityAuthLevel>
      <BusinessTypeCode>
        <xsl:value-of select="$partyBusiness/BusinessTypeCode" />
      </BusinessTypeCode>
      <EffectiveDate>
        <xsl:value-of select="$partyBusiness/EffectiveDate" />
      </EffectiveDate>
      <ExpirationDate>
        <xsl:value-of select="$partyBusiness/ExpirationDate" />
      </ExpirationDate>
      <IsAgency>
        <xsl:value-of select="$partyBusiness/IsAgency" />
      </IsAgency>
      <IsSupplier>
        <xsl:value-of select="$partyBusiness/IsSupplier" />
      </IsSupplier>
      <LastTransactionID>
        <xsl:value-of select="$partyBusiness/LastTransactionID" />
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="$partyBusiness/LastUpdatedDate" />
      </LastUpdatedDate>
      <PartyID>
        <xsl:value-of select="$partyBusiness/PartyID" />
      </PartyID>
      <PreferredContactType>
        <xsl:value-of select="$partyBusiness/PreferredContactType" />
      </PreferredContactType>
      <PreferredLanguage>
        <xsl:value-of select="$partyBusiness/PreferredLanguage" />
      </PreferredLanguage>
      <RegistrationID1>
        <xsl:value-of select="$partyBusiness/RegistrationID1" />
      </RegistrationID1>
      <RegistrationID2>
        <xsl:value-of select="$partyBusiness/RegistrationID2" />
      </RegistrationID2>
      <RegistrationID3>
        <xsl:value-of select="$partyBusiness/RegistrationID3" />
      </RegistrationID3>
      <BusinessExtendedData>
        <xsl:call-template name="ExtendedDataNS">
          <xsl:with-param name="extendedData" select="$partyBusiness/BusinessExtendedData" />
        </xsl:call-template>
      </BusinessExtendedData>
    </PartyBusiness>
  </xsl:template>

  <xsl:template name="ExtendedDataNS" xmlns="Party.Types">
    <xsl:param name="extendedData"></xsl:param>
    <d2p1:PhysicalTableName>
      <xsl:value-of select="$extendedData/d2p1:PhysicalTableName" />
    </d2p1:PhysicalTableName>
    <d2p1:ExtendedFields>
      <xsl:for-each select="$extendedData/d2p1:ExtendedFields/d2p1:ExtendedFieldDTO">
        <d2p1:ExtendedFieldDTO>
          <d2p1:LogicalTableName>
            <xsl:value-of select="d2p1:LogicalTableName" />
          </d2p1:LogicalTableName>
          <d2p1:LogicalColumnName>
            <xsl:value-of select="d2p1:LogicalColumnName" />
          </d2p1:LogicalColumnName>
          <d2p1:DataType>
            <xsl:value-of select="d2p1:DataType" />
          </d2p1:DataType>
          <xsl:choose>
            <xsl:when test ="d2p1:TextValue !=''">
              <d2p1:TextValue>
                <xsl:value-of select="d2p1:TextValue"/>
              </d2p1:TextValue>
            </xsl:when>
            <xsl:otherwise>
              <d2p1:TextValue i:nil="true"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test ="d2p1:IntegerValue !=''">
              <d2p1:IntegerValue>
                <xsl:value-of select="d2p1:IntegerValue"/>
              </d2p1:IntegerValue>
            </xsl:when>
            <xsl:otherwise>
              <d2p1:IntegerValue i:nil="true"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test ="d2p1:FloatingValue !=''">
              <d2p1:FloatingValue>
                <xsl:value-of select="d2p1:FloatingValue"/>
              </d2p1:FloatingValue>
            </xsl:when>
            <xsl:otherwise>
              <d2p1:FloatingValue i:nil="true"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test ="d2p1:DateTimeValue !=''">
              <d2p1:DateTimeValue>
                <xsl:value-of select="d2p1:DateTimeValue"/>
              </d2p1:DateTimeValue>
            </xsl:when>
            <xsl:otherwise>
              <d2p1:DateTimeValue i:nil="true"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test ="d2p1:BooleanValue !=''">
              <d2p1:BooleanValue>
                <xsl:value-of select="d2p1:BooleanValue"/>
              </d2p1:BooleanValue>
            </xsl:when>
            <xsl:otherwise>
              <d2p1:BooleanValue i:nil="true"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test ="d2p1:CurrencyValue !=''">
              <d2p1:CurrencyValue>
                <xsl:value-of select="d2p1:CurrencyValue"/>
              </d2p1:CurrencyValue>
            </xsl:when>
            <xsl:otherwise>
              <d2p1:CurrencyValue i:nil="true"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test ="not(normalize-space(d2p1:XMLValue)='')">
              <d2p1:XMLValue>
                <xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(d2p1:XMLValue/PartyExtendedData,'')" />      				
              </d2p1:XMLValue>
            </xsl:when>
            <xsl:otherwise>
              <d2p1:XMLValue i:nil="true"/>
            </xsl:otherwise>
          </xsl:choose>
        </d2p1:ExtendedFieldDTO>
      </xsl:for-each>
    </d2p1:ExtendedFields>
  </xsl:template>
</xsl:stylesheet>