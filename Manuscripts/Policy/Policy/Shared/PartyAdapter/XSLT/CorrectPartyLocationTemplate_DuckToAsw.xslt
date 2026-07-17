<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:d4p1="Address.Types" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="d4p1 xs msxsl xsl Util">
  <xsl:import href="CommonTemplates.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes" />

  <xsl:variable name="AFSCurrentDate" select="string(Util:GetValueByKey('AFSCurrentDate'))" />
  <xsl:variable name="CurrentDate" select="string(Util:GetValueByKey('CurrentDate'))" />
  <xsl:variable name="MaxDate" select="string(Util:GetValueByKey('MaxDate'))" />
  <xsl:variable name="transactionDate" select="string(Util:GetValueByKey('transactionDate'))" />

  <xsl:template name="CorrectPartyLocation">
    <PartyAddressDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:call-template name="Address" />
      <xsl:call-template name="PartyAddress" />
    </PartyAddressDetailDTO>
  </xsl:template>

  <xsl:template name="CorrectPartyLocation_Ind">
    <PartyAddressDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:call-template name="IndAddress" />
      <xsl:call-template name="IndPartyAddress" />
    </PartyAddressDetailDTO>
  </xsl:template>

  <xsl:template name="CorrectPartyLocation_Bus">
    <PartyAddressDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:call-template name="BusAddress" />
      <xsl:call-template name="BusPartyAddress" />
    </PartyAddressDetailDTO>
  </xsl:template>

  <xsl:template name="Address">
    <Address>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:variable name="countryCode" select="string(Util:GetOneRelatedItem('DCTCountryType',PartyRecord/Locations/Location/LocationCountryCode,'243'))"/>
      <xsl:variable name="CurrentDate" select="string(Util:GetValueByKey('CurrentDate'))" />
      <xsl:variable name="AddressID" select="PartyAddressDetailDTO/Address/AddressID" />
      <d4p1:AddressID>
        <xsl:value-of select="$AddressID"/>
      </d4p1:AddressID>
      <d4p1:AddressType>
        <xsl:value-of select="PartyAddressDetailDTO/Address/AddressType"/>
      </d4p1:AddressType>

      <d4p1:AddressTypeAssociations>
        <xsl:for-each select="PartyRecord/Locations/Location/LocationInvolvements/LocationInvolvement">
          <xsl:variable name="LocationInvolvementTypeCode" select="LocationInvolvementTypeCode" />
          <xsl:if test="string($LocationInvolvementTypeCode) != '_DF_'">
            <d4p1:AddressTypeAssociationDTO>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <d4p1:AddressID>
                <xsl:value-of select="$AddressID" />
              </d4p1:AddressID>
              <d4p1:AddressType>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTLocationInvolvementType',LocationInvolvementTypeCode,'8501'))"/>
              </d4p1:AddressType>

              <d4p1:AddressTypeAssociationID>
                <xsl:for-each select="../../../../../PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO">
                  <xsl:variable name="AddressType" select="AddressType" />
                  <xsl:if test="string($AddressType) = string($LocationInvolvementTypeCode)">
                    <xsl:value-of select="AddressTypeAssociationID"/>
                  </xsl:if>
                </xsl:for-each>
              </d4p1:AddressTypeAssociationID>

              <d4p1:EffectiveDate>
                <xsl:choose>
                  <xsl:when test="count(EffectiveDate) > 0">
                    <xsl:choose>
                      <xsl:when test="EffectiveDate != ''">
                        <xsl:value-of select="string(Util:ConvertDateToAswFormat(EffectiveDate))" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="string(Util:GetCurrentDate())"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <d4p1:EffectiveDate i:nil ="true" />
                  </xsl:otherwise>
                </xsl:choose>
              </d4p1:EffectiveDate>

              <d4p1:ExpirationDate>
                <xsl:choose>
                  <xsl:when test="count(ExpirationDate) > 0">
                    <xsl:choose>
                      <xsl:when test="ExpirationDate != ''">
                        <xsl:value-of select="string(Util:ConvertDateToAswFormat(ExpirationDate))" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="string(Util:GetMaxDate())"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="string(Util:GetMaxDate())"/>
                  </xsl:otherwise>
                </xsl:choose>
              </d4p1:ExpirationDate>
              <d4p1:LastTransactionID>
                <xsl:for-each select="../../../../../PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO">
                  <xsl:variable name="AddressType" select="AddressType" />
                  <xsl:if test="string($AddressType) = string($LocationInvolvementTypeCode)">
                    <xsl:value-of select="LastTransactionID"/>
                  </xsl:if>
                </xsl:for-each>
              </d4p1:LastTransactionID>
              <d4p1:LastUpdatedDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </d4p1:LastUpdatedDate>
            </d4p1:AddressTypeAssociationDTO>
          </xsl:if>
        </xsl:for-each>

      </d4p1:AddressTypeAssociations>


      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionTertiary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:choose>
        <xsl:when test ="string(PartyAddressDetailDTO/PartyAddress/IsPrimary) != 'true'">
          <d4p1:AllowPartial>true</d4p1:AllowPartial>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:AllowPartial>
            <xsl:value-of select="PartyAddressDetailDTO/Address/AllowPartial"/>
          </d4p1:AllowPartial>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Attention'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <!-- Throw execption if the LocationCountryCode tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationCountryCode) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>
      <d4p1:CountryCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',PartyRecord/Locations/Location/LocationCountryCode,'243'))"/>
      </d4p1:CountryCode>
      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationEffectiveDate) != ''">
          <d4p1:EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationEffectiveDate))"/>
          </d4p1:EffectiveDate>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </d4p1:EffectiveDate>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationExpirationDate) != ''">
          <d4p1:ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationExpirationDate))"/>
          </d4p1:ExpirationDate>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </d4p1:ExpirationDate>
        </xsl:otherwise>
      </xsl:choose>

      <d4p1:FullAddress i:nil="true" />
      <d4p1:GeographicFormatCode>
        <xsl:value-of select="PartyAddressDetailDTO/Address/GeographicFormatCode"/>
      </d4p1:GeographicFormatCode>
      <d4p1:LastTransactionID>
        <xsl:value-of select="PartyRecord/Locations/Location/LocationLockingTS"/>
      </d4p1:LastTransactionID>
      <d4p1:LastUpdatedDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyAddressDetailDTO/Address/LastUpdatedDate))"/>
      </d4p1:LastUpdatedDate>

      <!-- Throw execption if the LocationLatitude tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationLatitude) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Latitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:if test ="count(PartyRecord/Locations/Location/LocationAddressLine1) = 0">
        <!-- Throw execption if the LocationAddressLine1 tag is missing -->
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine1'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine2'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine3'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine4'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Longitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'NationalDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'NationalDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <d4p1:OldAddressCountryCode i:nil="true" />

      <!-- Throw execption if the LocationPostalCode tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationPostalCode) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>
      <!-- Throw execption if the LocationPostalCodeExtension tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationPostalCodeExtension) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'PostalCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <d4p1:SubAddressType i:nil="true" />
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionTertiary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAttention'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <d4p1:SubCountryCode i:nil="true" />
      <d4p1:SubEffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyAddressDetailDTO/Address/SubEffectiveDate))"/>
      </d4p1:SubEffectiveDate>
      <d4p1:SubExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyAddressDetailDTO/Address/SubExpirationDate))"/>
      </d4p1:SubExpirationDate>
      <d4p1:SubLastTransactionID i:nil="true" />
      <d4p1:SubLastUpdatedDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyAddressDetailDTO/Address/SubLastUpdatedDate))"/>
      </d4p1:SubLastUpdatedDate>

      <!--<xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAttention'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>-->

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLatitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine1'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine2'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine3'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine4'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLongitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubNationalDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubNationalDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubPostalCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <!--<xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationAttribute1Code'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimaryCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'PostalCodeCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
        <xsl:with-param name="TagPrefix" select="d4p1" />
      </xsl:call-template>-->

      <!-- One location expected, the loop is to select the proper context for the ExtendedData template -->
      <xsl:for-each select="PartyRecord/Locations[1]/Location[1]">
        <xsl:call-template name="ExtendedData">
          <xsl:with-param name="TagName">LocationExtendedData</xsl:with-param>
		  <xsl:with-param name="SuiteTagName">LocationSuiteExtendedData</xsl:with-param>
          <xsl:with-param name="AswTagName">d4p1:AddressExtendedData</xsl:with-param>
          <xsl:with-param name="PhysicalTableName">ADDRESS</xsl:with-param>
          <xsl:with-param name="LogicalTableName">lgclAddr</xsl:with-param>
          <xsl:with-param name="LogicalColumnName">AddressExtData</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>

    </Address>
  </xsl:template>

  <xsl:template name="PartyAddress">
    <PartyAddress>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <AddressID>
        <xsl:value-of select="PartyAddressDetailDTO/PartyAddress/AddressID"/>
      </AddressID>
      <Comment>
        <xsl:value-of select="PartyRecord/Locations/Location/LocationComments"/>
      </Comment>
      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationEffectiveDate) != ''">
          <EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationEffectiveDate))"/>
          </EffectiveDate>
        </xsl:when>
        <xsl:otherwise>
          <EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </EffectiveDate>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationExpirationDate) != ''">
          <ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationExpirationDate))"/>
          </ExpirationDate>
        </xsl:when>
        <xsl:otherwise>
          <ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </ExpirationDate>
        </xsl:otherwise>
      </xsl:choose>
      <ExternalPartyAddressID>
        <xsl:value-of select="PartyAddressDetailDTO/PartyAddress/ExternalPartyAddressID"/>
      </ExternalPartyAddressID>
      <IsPrimary>
        <xsl:value-of select="PartyAddressDetailDTO/PartyAddress/IsPrimary"/>
      </IsPrimary>
      <IsTaxAddress>
        <xsl:value-of select="PartyAddressDetailDTO/PartyAddress/IsTaxAddress"/>
      </IsTaxAddress>
      <LastTransactionID>
        <xsl:value-of select="PartyAddressDetailDTO/PartyAddress/LastTransactionID"/>
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <PartyAddressID>
        <xsl:value-of select="PartyAddressDetailDTO/PartyAddress/PartyAddressID"/>
      </PartyAddressID>
      <PartyID>
        <xsl:value-of select="PartyAddressDetailDTO/PartyAddress/PartyID"/>
      </PartyID>
      <SubComment i:nil="true" />
      <IsDefault>
        <xsl:value-of select="PartyAddressDetailDTO/PartyAddress/IsDefault"/>
      </IsDefault>
    </PartyAddress>
  </xsl:template>

  <xsl:template name="IndAddress">
    <Address>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:variable name="countryCode" select="string(Util:GetOneRelatedItem('DCTCountryType',PartyRecord/Locations/Location/LocationCountryCode,'243'))"/>
      <d4p1:AddressID>
        <!--PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO-->
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressID"/>
      </d4p1:AddressID>
      <d4p1:AddressType>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressType"/>
      </d4p1:AddressType>
      <d4p1:AddressTypeAssociations i:nil="true" />

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionTertiary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:choose>
        <xsl:when test ="string(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/IsPrimary) != 'true'">
          <d4p1:AllowPartial>true</d4p1:AllowPartial>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:AllowPartial>
            <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AllowPartial"/>
          </d4p1:AllowPartial>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Attention'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <!-- Throw execption if the LocationCountryCode tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationCountryCode) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>
      <d4p1:CountryCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',PartyRecord/Locations/Location/LocationCountryCode,'243'))"/>
      </d4p1:CountryCode>
      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationEffectiveDate) != ''">
          <d4p1:EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationEffectiveDate))"/>
          </d4p1:EffectiveDate>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </d4p1:EffectiveDate>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationExpirationDate) != ''">
          <d4p1:ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationExpirationDate))"/>
          </d4p1:ExpirationDate>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </d4p1:ExpirationDate>
        </xsl:otherwise>
      </xsl:choose>

      <d4p1:FullAddress i:nil="true" />
      <d4p1:GeographicFormatCode>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/GeographicFormatCode"/>
      </d4p1:GeographicFormatCode>
      <d4p1:LastTransactionID>
        <xsl:choose>
          <xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/LocationLockingTS) > 0">
            <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/LocationLockingTS"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/LastTransactionID"/>
          </xsl:otherwise>
        </xsl:choose>
      </d4p1:LastTransactionID>
      <d4p1:LastUpdatedDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/LastUpdatedDate))"/>
      </d4p1:LastUpdatedDate>

      <!-- Throw execption if the LocationLatitude tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationLatitude) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Latitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <!-- Throw execption if the LocationAddressLine1 tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationAddressLine1) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine1'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine2'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine3'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine4'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Longitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'NationalDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'NationalDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <d4p1:OldAddressCountryCode i:nil="true" />

      <!-- Throw execption if the LocationPostalCode tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationPostalCode) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>
      <!-- Throw execption if the LocationPostalCodeExtension tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationPostalCodeExtension) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'PostalCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <d4p1:SubAddressType i:nil="true" />

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionTertiary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAttention'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <d4p1:SubCountryCode i:nil="true" />
      <d4p1:SubEffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/SubEffectiveDate))"/>
      </d4p1:SubEffectiveDate>
      <d4p1:SubExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/SubExpirationDate))"/>
      </d4p1:SubExpirationDate>
      <d4p1:SubLastTransactionID i:nil="true" />
      <d4p1:SubLastUpdatedDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/SubLastUpdatedDate))"/>
      </d4p1:SubLastUpdatedDate>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLatitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine1'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine2'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine3'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine4'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLongitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubNationalDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubNationalDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubPostalCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <!--<xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationAttribute1Code'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimaryCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'PostalCodeCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>-->
    </Address>
  </xsl:template>

  <xsl:template name="IndPartyAddress">
    <PartyAddress>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <AddressID>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/AddressID"/>
      </AddressID>
      <Comment>
        <xsl:value-of select="PartyRecord/Locations/Location/LocationComments"/>
      </Comment>
      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationEffectiveDate) != ''">
          <EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationEffectiveDate))"/>
          </EffectiveDate>
        </xsl:when>
        <xsl:otherwise>
          <EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </EffectiveDate>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationExpirationDate) != ''">
          <ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationExpirationDate))"/>
          </ExpirationDate>
        </xsl:when>
        <xsl:otherwise>
          <ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </ExpirationDate>
        </xsl:otherwise>
      </xsl:choose>
      <ExternalPartyAddressID>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/ExternalPartyAddressID"/>
      </ExternalPartyAddressID>
      <IsPrimary>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/IsPrimary"/>
      </IsPrimary>
      <IsTaxAddress>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/IsTaxAddress"/>
      </IsTaxAddress>
      <LastTransactionID>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/LastTransactionID"/>
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <PartyAddressID>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/PartyAddressID"/>
      </PartyAddressID>
      <PartyID>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/PartyID"/>
      </PartyID>
      <SubComment i:nil="true" />
      <IsDefault>
        <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/IsDefault"/>
      </IsDefault>
    </PartyAddress>
  </xsl:template>

  <xsl:template name="BusAddress">
    <Address>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:variable name="countryCode" select="string(Util:GetOneRelatedItem('DCTCountryType',LocationCountryCode,'243'))"/>
      <d4p1:AddressID>
        <!--PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO-->
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressID"/>
      </d4p1:AddressID>
      <d4p1:AddressType>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressType"/>
      </d4p1:AddressType>
      <d4p1:AddressTypeAssociations i:nil="true" />
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionTertiary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:choose>
        <xsl:when test ="string(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/IsPrimary) != 'true'">
          <d4p1:AllowPartial>true</d4p1:AllowPartial>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:AllowPartial>
            <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AllowPartial"/>
          </d4p1:AllowPartial>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Attention'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <!-- Throw execption if the LocationCountryCode tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationCountryCode) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>
      <d4p1:CountryCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',PartyRecord/Locations/Location/LocationCountryCode,'243'))"/>
      </d4p1:CountryCode>
      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationEffectiveDate) != ''">
          <d4p1:EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationEffectiveDate))"/>
          </d4p1:EffectiveDate>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </d4p1:EffectiveDate>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationExpirationDate) != ''">
          <d4p1:ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationExpirationDate))"/>
          </d4p1:ExpirationDate>
        </xsl:when>
        <xsl:otherwise>
          <d4p1:ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </d4p1:ExpirationDate>
        </xsl:otherwise>
      </xsl:choose>

      <d4p1:FullAddress i:nil="true" />
      <d4p1:GeographicFormatCode>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/GeographicFormatCode"/>
      </d4p1:GeographicFormatCode>
      <d4p1:LastTransactionID>
        <xsl:choose>
          <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/LocationLockingTS) > 0">
            <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/LocationLockingTS"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/LastTransactionID"/>
          </xsl:otherwise>
        </xsl:choose>
      </d4p1:LastTransactionID>
      <d4p1:LastUpdatedDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/LastUpdatedDate))"/>
      </d4p1:LastUpdatedDate>

      <!-- Throw execption if the LocationLatitude tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationLatitude) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Latitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <!-- Throw execption if the LocationAddressLine1 tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationAddressLine1) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine1'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine2'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine3'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine4'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'Longitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'NationalDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'NationalDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <d4p1:OldAddressCountryCode i:nil="true" />

      <!-- Throw execption if the LocationPostalCode tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationPostalCode) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>
      <!-- Throw execption if the LocationPostalCodeExtension tag is missing -->
      <xsl:if test ="count(PartyRecord/Locations/Location/LocationPostalCodeExtension) = 0">
        <xsl:value-of select="Util:ThrowException('Object reference not set to an instance of an object.')"/>
      </xsl:if>
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'PostalCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <d4p1:SubAddressType i:nil="true" />
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAdminDivisionTertiary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubAttention'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <d4p1:SubCountryCode i:nil="true" />
      <d4p1:SubEffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/SubEffectiveDate))"/>
      </d4p1:SubEffectiveDate>
      <d4p1:SubExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/SubExpirationDate))"/>
      </d4p1:SubExpirationDate>
      <d4p1:SubLastTransactionID i:nil="true" />
      <d4p1:SubLastUpdatedDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/SubLastUpdatedDate))"/>
      </d4p1:SubLastUpdatedDate>
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLatitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine1'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine2'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine3'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine4'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>


      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubLongitude'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubNationalDivisionPrimary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubNationalDivisionSecondary'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'SubPostalCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>

      <!--<xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'LocationAttribute1Code'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimaryCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>
      <xsl:call-template name="GenerateAFSFieldForAddress">
        <xsl:with-param name="AFSFieldName" select="'PostalCodeCode'"/>
        <xsl:with-param name="CountryCode" select="$countryCode" />
      </xsl:call-template>-->
    </Address>
  </xsl:template>

  <xsl:template name="BusPartyAddress">
    <PartyAddress>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <AddressID>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/AddressID"/>
      </AddressID>
      <Comment>
        <xsl:value-of select="PartyRecord/Locations/Location/LocationComments"/>
      </Comment>
      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationEffectiveDate) != ''">
          <EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationEffectiveDate))"/>
          </EffectiveDate>
        </xsl:when>
        <xsl:otherwise>
          <EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </EffectiveDate>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:choose>
        <xsl:when test ="string(PartyRecord/Locations/Location/LocationExpirationDate) != ''">
          <ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyRecord/Locations/Location/LocationExpirationDate))"/>
          </ExpirationDate>
        </xsl:when>
        <xsl:otherwise>
          <ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </ExpirationDate>
        </xsl:otherwise>
      </xsl:choose>
      <ExternalPartyAddressID>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/ExternalPartyAddressID"/>
      </ExternalPartyAddressID>
      <IsPrimary>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/IsPrimary"/>
      </IsPrimary>
      <IsTaxAddress>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/IsTaxAddress"/>
      </IsTaxAddress>
      <LastTransactionID>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/LastTransactionID"/>
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <PartyAddressID>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/PartyAddressID"/>
      </PartyAddressID>
      <PartyID>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/PartyID"/>
      </PartyID>
      <SubComment i:nil="true" />
      <IsDefault>
        <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/IsDefault"/>
      </IsDefault>
    </PartyAddress>
  </xsl:template>

  <xsl:template name="GenerateAFSFieldForAddress">
    <xsl:param name="AFSFieldName" />
    <xsl:param name="CountryCode" />
    <xsl:param name="TagName" />
    <!--xsl:choose>
			<xsl:when test="string(Util:CheckASWNodeConfigurability($AFSFieldName,$CountryCode,'ADDRESS')) = 'true'"-->
    <xsl:call-template name="GenerateAFSField">
      <xsl:with-param name="AFSFieldName" select="$AFSFieldName" />
      <xsl:with-param name="CountryCode" select="$CountryCode" />
      <xsl:with-param name="ComponentName" select="'ADDRESS'" />
      <xsl:with-param name="TagPrefix" select="'d4p1'" />
    </xsl:call-template>
    <!--/xsl:when>
			<xsl:otherwise>
				<xsl:variable name="DCTFieldName" select="Util:GetDCTFieldName($AFSFieldName)"/>
				<xsl:if test ="$DCTFieldName != ''">
					<xsl:if test="string(Util:checkNodePassed(PartyRecord/Locations/Location,$DCTFieldName)) = 'true'">
						<xsl:value-of select="string(Util:ThrowException(concat('Invalid address node ',$DCTFieldName)))"/>
					</xsl:if>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose-->
  </xsl:template>

  <xsl:template name="GenerateAFSField">
    <xsl:param name="AFSFieldName" />
    <xsl:param name="CountryCode" />
    <xsl:param name="ComponentName" />
    <xsl:param name="TagPrefix" />
    <xsl:param name="TagName" />

    <xsl:variable name="elementName">
      <xsl:choose>
        <xsl:when test="$TagPrefix != ''" >
          <xsl:value-of select="concat($TagPrefix,':',$AFSFieldName)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$AFSFieldName"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:element name="{$elementName}">
      <xsl:variable name="valueOfElement" select="string(Util:GenerateAFSFieldWithValue(PartyRecord/Locations/Location,$AFSFieldName,$CountryCode,$ComponentName,''))" />
      <xsl:choose>
        <xsl:when test="$valueOfElement != ''">
          <xsl:value-of disable-output-escaping="no" select="$valueOfElement"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="i:nil">true</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
    <!--<xsl:value-of disable-output-escaping="yes" select="string(Util:GenerateAFSFieldWithValue(PartyRecord/Locations/Location,$AFSFieldName,$CountryCode,$ComponentName,'',$TagPrefix,$TagName))"/>-->
  </xsl:template>


</xsl:stylesheet>
