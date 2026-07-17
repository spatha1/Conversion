<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:at="AFS.Address.Types" xmlns:WCFTypes="AFS.AEF.WCF.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="WCFTypes xs msxsl xsl Util">
  <xsl:import href="CommonTemplates.xslt"/>
  <xsl:import href="CommonPartyTemplates.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:variable name="ActionName" select="string(Util:GetValueByKey('ActionName'))" />
  <xsl:variable name="ActionPhone" select="string(Util:GetValueByKey('ActionPhone'))" />
  <xsl:variable name="ActionAddress" select="string(Util:GetValueByKey('ActionAddress'))" />
  <xsl:variable name="ActionReference" select="string(Util:GetValueByKey('ActionReference'))" />
  <xsl:variable name="AFSCurrentDate" select="string(Util:GetValueByKey('AFSCurrentDate'))" />
  <xsl:variable name="partyCountryCode" select="string(Util:GetOneRelatedItem('DCTCountryType',PartyData/Entity/Country,'243'))" />
  <xsl:template match="/PartyData">
    <PartyBusinessBulkDetailsDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:if test="/PartyData/PartyDetailDTO/PartyBusinessDetail">
        <!-- Party Details -->
        <!--<xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(PartyDetailDTO/PartyBusinessDetail/Party,'Party')" />-->
        <!--<xsl:copy-of select="PartyDetailDTO/PartyBusinessDetail/Party" />-->
        <xsl:call-template name="Party">
          <xsl:with-param name="party" select="PartyDetailDTO/PartyBusinessDetail/Party" />
        </xsl:call-template>
        <!-- Party Address Details -->
        <PartyAddressesToDelete i:nil="true"/>
        <xsl:choose>
          <xsl:when test="$ActionAddress = 'True'">
            <xsl:choose>
              <xsl:when test="count(//PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO) > 0">
                <PartyAddressesToInsert i:nil="true" />
                <PartyAddressesToUpdate>
                  <!--<xsl:for-each select="//PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO[PartyAddress/IsDefault = 'true']">-->
                  <xsl:call-template name="PartyAddressesToUpdateTemplate_V2">
                    <xsl:with-param name="partyAddressDetail" select="//PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO[PartyAddress/IsDefault = 'true']" />
                  </xsl:call-template>
                  <!--</xsl:for-each>-->
                </PartyAddressesToUpdate>
              </xsl:when>
              <xsl:otherwise>
                <PartyAddressesToInsert>
                  <!--<xsl:call-template name="PartyAddressesToInsertTemplate"/>-->
                  <xsl:call-template name="PartyAddressesToInsertTemplate_V2"/>
                </PartyAddressesToInsert>
                <PartyAddressesToUpdate i:nil="true" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <PartyAddressesToInsert i:nil="true" />
            <PartyAddressesToUpdate i:nil="true" />
          </xsl:otherwise>
        </xsl:choose>
        <PartyAgency i:nil="true" />
        <!-- Party Business Details -->
        <!--<xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(PartyDetailDTO/PartyBusinessDetail/PartyBusiness,'PartyBusiness')" />-->
        <!--<xsl:copy-of select="PartyDetailDTO/PartyBusinessDetail/PartyBusiness" />-->
        <xsl:call-template name="PartyBusiness">
          <xsl:with-param name="partyBusiness" select="PartyDetailDTO/PartyBusinessDetail/PartyBusiness" />
        </xsl:call-template>
        <!-- Party BUS Names Details -->
        <PartyBusNamesToDelete i:nil="true" />
        <PartyBusNamesToInsert i:nil="true" />
        <PartyBusNamesToUpdate>
          <xsl:if test="$ActionName = 'True'">
            <xsl:call-template name="PartyBusNamesToUpdateTemplate" />
          </xsl:if>
        </PartyBusNamesToUpdate>
        <PartyComment i:nil="true" />
        <PartyEmailsToDelete i:nil="true" />
        <PartyEmailsToInsert i:nil="true" />
        <PartyEmailsToUpdate i:nil="true" />
        <PartyLicensesToDelete i:nil="true" />
        <PartyLicensesToInsert i:nil="true" />
        <PartyLicensesToUpdate i:nil="true" />
        <PartyMembershipsToDelete i:nil="true" />
        <xsl:choose>
          <xsl:when test="$ActionReference = 'True'">
            <xsl:choose>
              <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyMembership/PartyMembershipDTO) > 0">
                <xsl:choose>
                  <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyMembership/PartyMembershipDTO[MembershipTypeCode = 'A']) > 0">
                    <PartyMembershipsToInsert i:nil="true" />
                    <PartyMembershipsToUpdate>
                      <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyMembership/PartyMembershipDTO[MembershipTypeCode = 'A']">
                        <xsl:call-template name="PartyMembershipsToUpdateTemplate" />
                      </xsl:for-each>
                    </PartyMembershipsToUpdate>
                  </xsl:when>
                  <xsl:otherwise>
                    <PartyMembershipsToInsert>
                      <xsl:call-template name="PartyMembershipsToInsertTemplate" />
                    </PartyMembershipsToInsert>
                    <PartyMembershipsToUpdate i:nil="true" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <PartyMembershipsToInsert>
                  <xsl:call-template name="PartyMembershipsToInsertTemplate" />
                </PartyMembershipsToInsert>
                <PartyMembershipsToUpdate i:nil="true" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <PartyMembershipsToInsert i:nil="true" />
            <PartyMembershipsToUpdate i:nil="true" />
          </xsl:otherwise>
        </xsl:choose>
        <!-- Party Phone Details -->
        <PartyPhonesToDelete i:nil="true" />
        <xsl:choose>
          <xsl:when test="$ActionPhone = 'True'">
            <xsl:choose>
              <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO) > 0">
                <xsl:choose>
                  <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO[PhoneTypeCode = '17']) > 0">
                    <PartyPhonesToInsert i:nil="true" />
                    <PartyPhonesToUpdate>
                      <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO[PhoneTypeCode = '17']">
                        <xsl:call-template name="PartyPhonesToUpdateTemplate" />
                      </xsl:for-each>
                    </PartyPhonesToUpdate>
                  </xsl:when>
                  <xsl:otherwise>
                    <PartyPhonesToInsert>
                      <xsl:call-template name="PartyPhonesToInsertTemplate" />
                    </PartyPhonesToInsert>
                    <PartyPhonesToUpdate i:nil="true" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <PartyPhonesToInsert>
                  <xsl:call-template name="PartyPhonesToInsertTemplate" />
                </PartyPhonesToInsert>
                <PartyPhonesToUpdate i:nil="true" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <PartyPhonesToInsert i:nil="true" />
            <PartyPhonesToUpdate i:nil="true" />
          </xsl:otherwise>
        </xsl:choose>
        <PartyRelationsToDelete i:nil="true" />
        <PartyRelationsToInsert i:nil="true" />
        <PartyBusNamesToReplace i:nil="true" />
      </xsl:if>
    </PartyBusinessBulkDetailsDTO>
  </xsl:template>

  <xsl:template name="PartyBusNamesToUpdateTemplate">
    <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO">
      <xsl:if test="PartyName/IsDefault = 'true' or PartyBusName/NameTypeCode='06' or PartyBusName/NameTypeCode='07' ">
        <PartyBusNameDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
          <PartyBusName>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <Comment i:nil="true" />
            <LastTransactionID>
              <xsl:value-of select="PartyBusName/LastTransactionID" />
            </LastTransactionID>
            <LastUpdatedDate>
              <xsl:value-of select="string(Util:GetCurrentDate())"/>
            </LastUpdatedDate>
            <Name>
              <xsl:value-of select="/PartyData/Entity/Name" />
            </Name>
            <NamePhonetic i:nil="true" />
            <NameSoundex  i:nil="true" />
            <NameTypeCode>
              <xsl:value-of select="PartyBusName/NameTypeCode" />
            </NameTypeCode>
            <NameUpperCase  i:nil="true" />
            <PartyBusNameID>
              <xsl:value-of select="PartyBusName/PartyBusNameID" />
            </PartyBusNameID>
          </PartyBusName>
          <PartyName>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <AllowPartial>true</AllowPartial>
            <CountryCode>
              <xsl:value-of select="$partyCountryCode"/>
            </CountryCode>
            <EffectiveDate>
              <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyName/EffectiveDate))" />
            </EffectiveDate>
            <ExpirationDate>
              <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyName/ExpirationDate))" />
            </ExpirationDate>
            <ExternalPartyNameID i:nil="true" />
            <GeographicFormatCode>
              <xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
            </GeographicFormatCode>
            <IsPrimary>
              <xsl:value-of select="PartyName/IsPrimary" />
            </IsPrimary>
            <IsTaxName>
              <xsl:value-of select="PartyName/IsTaxName" />
            </IsTaxName>
            <LastTransactionID>
              <xsl:value-of select="PartyName/LastTransactionID" />
            </LastTransactionID>
            <LastUpdatedDate>
              <xsl:value-of select="string(Util:GetCurrentDate())" />
            </LastUpdatedDate>
            <PartyID>
              <xsl:value-of select="PartyName/PartyID" />
            </PartyID>
            <PartyNameID>
              <xsl:value-of select="PartyName/PartyNameID" />
            </PartyNameID>
            <IsDefault>
              <xsl:value-of select="PartyName/IsDefault" />
            </IsDefault>
          </PartyName>
        </PartyBusNameDetailDTO>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="PartyPhonesToInsertTemplate">
    <PartyPhoneWithExtendedDataDTO>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <PartyPhone>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <Comment i:nil="true" />
        <CountryCode>
          <xsl:value-of select="$partyCountryCode"/>
        </CountryCode>
        <EffectiveDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </EffectiveDate>
        <ExpirationDate>
          <xsl:value-of select="string(Util:GetMaxDate())"/>
        </ExpirationDate>
        <ExternalPartyPhoneID i:nil="true" />
        <FullPhoneNumber>
          <xsl:value-of select="string(Util:FormatPhoneNumber(Entity/PhoneNumber))"/>
        </FullPhoneNumber>
        <!--<xsl:value-of select="GeographicFormatCode" />-->
        <GeographicFormatCode>
          <xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
        </GeographicFormatCode>
        <xsl:choose>
          <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO) > 0">
            <xsl:choose>
              <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true']) > 0">
                <IsPrimary>false</IsPrimary>
              </xsl:when>
              <xsl:otherwise>
                <IsPrimary>true</IsPrimary>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <IsPrimary>true</IsPrimary>
          </xsl:otherwise>
        </xsl:choose>
        <LastTransactionID i:nil="true" />
        <LastUpdatedDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>
        <PartyID>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/PartyID" />
        </PartyID>
        <PartyPhoneID i:nil="true" />

        <PhoneExtension>
          <xsl:value-of select="Entity/PhoneExtension" />
        </PhoneExtension>
        <PhoneTypeCode>
          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPhoneType', 'B', '26'))"/>
        </PhoneTypeCode>
      </PartyPhone>
    </PartyPhoneWithExtendedDataDTO>
  </xsl:template>

  <xsl:template name="PartyPhonesToUpdateTemplate">
    <PartyPhoneDTO>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <Comment i:nil="true" />
      <CountryCode>
        <xsl:value-of select="CountryCode" />
      </CountryCode>
      <EffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(EffectiveDate))" />
      </EffectiveDate>
      <ExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(ExpirationDate))" />
      </ExpirationDate>
      <ExternalPartyPhoneID i:nil="true" />
      <FullPhoneNumber>
        <xsl:value-of select="string(Util:FormatPhoneNumber(/PartyData/Entity/PhoneNumber))"/>
      </FullPhoneNumber>
      <GeographicFormatCode>
        <xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
      </GeographicFormatCode>
      <IsPrimary>
        <xsl:value-of select="IsPrimary" />
      </IsPrimary>
      <LastTransactionID>
        <xsl:value-of select="LastTransactionID" />
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <PartyID>
        <xsl:value-of select="PartyID" />
      </PartyID>
      <PartyPhoneID>
        <xsl:value-of select="PartyPhoneID" />
      </PartyPhoneID>
      <PhoneExtension>
        <xsl:value-of select="/PartyData/Entity/PhoneExtension" />
      </PhoneExtension>
      <PhoneTypeCode>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPhoneType', 'B', '26'))"/>
      </PhoneTypeCode>
    </PartyPhoneDTO>
  </xsl:template>

  <xsl:template name="PartyAddressesToInsertTemplate"  xmlns="Party.Types">
    <PartyAddressDetailWithExtendedDataDTO xmlns:at="AFS.Address.Types">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <at:Address>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <at:AddressID i:nil="true" />
        <at:AddressType i:nil="true" />
        <at:AddressTypeAssociations>
          <at:AddressTypeAssociationDTO>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <at:AddressID i:nil="true" />
            <at:AddressType>
              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTLocationInvolvementType','_LEG','8501'))"/>
            </at:AddressType>
            <at:AddressTypeAssociationID i:nil="true" />
            <at:EffectiveDate>
              <xsl:value-of select="$AFSCurrentDate"/>
            </at:EffectiveDate>
            <at:ExpirationDate>
              <xsl:value-of select="string(Util:GetMaxDate())"/>
            </at:ExpirationDate>
            <at:LastTransactionID i:nil="true" />
            <at:LastUpdatedDate>
              <xsl:value-of select="$AFSCurrentDate"/>
            </at:LastUpdatedDate>
          </at:AddressTypeAssociationDTO>
        </at:AddressTypeAssociations>
        <at:AdminDivisionPrimary>
          <xsl:value-of select="Entity/City" />
        </at:AdminDivisionPrimary>
        <at:AdminDivisionSecondary i:nil="true" />
        <at:AdminDivisionTertiary i:nil="true" />
        <at:AllowPartial>false</at:AllowPartial>
        <at:Attention i:nil="true" />
        <at:CountryCode>
          <xsl:value-of select="$partyCountryCode"/>
        </at:CountryCode>
        <at:EffectiveDate>
          <xsl:value-of select="$AFSCurrentDate"/>
        </at:EffectiveDate>
        <at:ExpirationDate>
          <xsl:value-of select="string(Util:GetMaxDate())"/>
        </at:ExpirationDate>
        <at:FullAddress i:nil="true" />
        <at:GeographicFormatCode>
          <xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
        </at:GeographicFormatCode>
        <at:LastTransactionID i:nil="true" />
        <at:LastUpdatedDate>
          <xsl:value-of select="$AFSCurrentDate"/>
        </at:LastUpdatedDate>
        <at:Latitude i:nil="true" />
        <at:LocationDetailsLine1>
          <xsl:value-of select="Entity/Address1" />
        </at:LocationDetailsLine1>
        <at:LocationDetailsLine2>
          <xsl:value-of select="Entity/Address2" />
        </at:LocationDetailsLine2>
        <at:LocationDetailsLine3 i:nil="true" />
        <at:LocationDetailsLine4 i:nil="true" />
        <at:Longitude i:nil="true" />
        <at:NationalDivisionPrimary>
          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTStateType',Entity/State,'240'))"/>
        </at:NationalDivisionPrimary>
        <at:NationalDivisionSecondary i:nil="true" />
        <at:OldAddressCountryCode i:nil="true" />
        <at:PostalCode>
          <xsl:value-of select="Entity/ZIPCode" />
     </at:PostalCode>
        <at:SubAddressType i:nil="true" />
        <at:SubAdminDivisionPrimary i:nil="true" />
        <at:SubAdminDivisionSecondary i:nil="true" />
        <at:SubAdminDivisionTertiary i:nil="true" />
        <at:SubAttention i:nil="true" />
        <at:SubCountryCode i:nil="true" />
        <at:SubEffectiveDate>
			<xsl:value-of select="string(Util:GetCurrentDate())"/>
		</at:SubEffectiveDate>
        <at:SubExpirationDate>
		    <xsl:value-of select="string(Util:GetMaxDate())"/>
		</at:SubExpirationDate>
        <at:SubLastTransactionID i:nil="true" />
        <at:SubLastUpdatedDate>
			<xsl:value-of select="string(Util:GetMaxDate())"/>
		</at:SubLastUpdatedDate>
        <at:SubLatitude i:nil="true" />
        <at:SubLocationDetailsLine1 i:nil="true" />
        <at:SubLocationDetailsLine2 i:nil="true" />
        <at:SubLocationDetailsLine3 i:nil="true" />
        <at:SubLocationDetailsLine4 i:nil="true" />
        <at:SubLongitude i:nil="true" />
        <at:SubNationalDivisionPrimary i:nil="true" />
        <at:SubNationalDivisionSecondary i:nil="true" />
        <at:SubPostalCode i:nil="true" />
      </at:Address>
      <AddressExtendedData i:nil="true" />
      <PartyAddress>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <AddressID i:nil="true" />
        <Comment i:nil="true" />
        <EffectiveDate>
          <xsl:value-of select="$AFSCurrentDate"/>
        </EffectiveDate>
        <ExpirationDate>
          <xsl:value-of select="string(Util:GetMaxDate())"/>
        </ExpirationDate>
        <ExternalPartyAddressID i:nil="true" />
        <IsPrimary>false</IsPrimary>
        <IsTaxAddress>false</IsTaxAddress>
        <LastTransactionID i:nil="true" />
        <LastUpdatedDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>
        <PartyAddressID i:nil="true" />
        <PartyID>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/PartyID" />
        </PartyID>
        <SubComment i:nil="true" />
        <IsDefault>true</IsDefault>
      </PartyAddress>
      <PartyAddressExtendedData i:nil="true" />
    </PartyAddressDetailWithExtendedDataDTO>
  </xsl:template>

  <xsl:template name="PartyAddressesToUpdateTemplate">
    <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO[PartyAddress/IsDefault = 'true']">
      <PartyAddressDetailDTO xmlns:at="AFS.Address.Types">
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <at:Address>
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
          <at:AddressID>
            <xsl:value-of select="Address/AddressID" />
          </at:AddressID>
          <at:AddressType>
            <xsl:value-of select="Address/AddressType" />
          </at:AddressType>
          <AddressTypeAssociations>
            <xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(Address/AddressTypeAssociations/AddressTypeAssociationDTO,'AddressTypeAssociationDTO')" />
          </AddressTypeAssociations>
          <at:AdminDivisionPrimary>
            <xsl:value-of select="/PartyData/Entity/City" />
          </at:AdminDivisionPrimary>
          <at:AdminDivisionSecondary i:nil="true" />
          <at:AdminDivisionTertiary i:nil="true" />
          <at:AllowPartial>
            <xsl:value-of select="Address/AllowPartial" />
          </at:AllowPartial>
          <at:Attention i:nil="true" />
          <at:CountryCode>
            <xsl:value-of select="$partyCountryCode"/>
          </at:CountryCode>
          <at:EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(Address/EffectiveDate))" />
          </at:EffectiveDate>
          <at:ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(Address/ExpirationDate))" />
          </at:ExpirationDate>
          <at:FullAddress>
            <xsl:value-of select="Address/FullAddress" />
          </at:FullAddress>
          <at:GeographicFormatCode>
            <xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
          </at:GeographicFormatCode>
          <at:LastTransactionID>
            <xsl:value-of select="Address/LastTransactionID" />
          </at:LastTransactionID>
          <at:LastUpdatedDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(Address/LastUpdatedDate))" />
          </at:LastUpdatedDate>
          <at:Latitude i:nil="true" />
          <at:LocationDetailsLine1>
            <xsl:value-of select="/PartyData/Entity/Address1" />
          </at:LocationDetailsLine1>
          <at:LocationDetailsLine2>
            <xsl:value-of select="/PartyData/Entity/Address2" />
          </at:LocationDetailsLine2>
          <at:LocationDetailsLine3 i:nil="true" />
          <at:LocationDetailsLine4 i:nil="true" />
          <at:Longitude i:nil="true" />
          <at:NationalDivisionPrimary>
            <xsl:value-of select="string(Util:GetOneRelatedItem('DCTStateType',/PartyData/Entity/State,'240'))"/>
          </at:NationalDivisionPrimary>
          <at:NationalDivisionSecondary i:nil="true" />
          <at:OldAddressCountryCode i:nil="true" />
          <at:PostalCode>
            <xsl:value-of select="/PartyData/Entity/ZIPCode" />
          </at:PostalCode>
          <at:SubAddressType i:nil="true" />
          <at:SubAdminDivisionPrimary i:nil="true" />
          <at:SubAdminDivisionSecondary i:nil="true" />
          <at:SubAdminDivisionTertiary i:nil="true" />
          <at:SubAttention i:nil="true" />
          <at:SubCountryCode i:nil="true" />
          <at:SubEffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(Address/SubEffectiveDate))" />
          </at:SubEffectiveDate>
          <at:SubExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(Address/SubExpirationDate))" />
          </at:SubExpirationDate>
          <at:SubLastTransactionID i:nil="true" />
          <at:SubLastUpdatedDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(Address/SubLastUpdatedDate))" />
          </at:SubLastUpdatedDate>
          <at:SubLatitude i:nil="true" />
          <at:SubLocationDetailsLine1 i:nil="true" />
          <at:SubLocationDetailsLine2 i:nil="true" />
          <at:SubLocationDetailsLine3 i:nil="true" />
          <at:SubLocationDetailsLine4 i:nil="true" />
          <at:SubLongitude i:nil="true" />
          <at:SubNationalDivisionPrimary i:nil="true" />
          <at:SubNationalDivisionSecondary i:nil="true" />
          <at:SubPostalCode i:nil="true" />
        </at:Address>
        <xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(PartyAddress,'PartyAddress')" />
      </PartyAddressDetailDTO>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="PartyAddressesToInsertTemplate_V2" xmlns="Party.Types">
    <PartyAddressDetailWithExtendedDataDTO xmlns:at="AFS.Address.Types">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <Address>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <at:AddressID i:nil="true"  xmlns:at="Address.Types"/>
        <at:AddressType i:nil="true" xmlns:at="Address.Types"/>
        <at:AddressTypeAssociations xmlns:at="Address.Types">
          <at:AddressTypeAssociationDTO xmlns:at="Address.Types">
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <at:AddressID i:nil="true" xmlns:at="Address.Types"/>
            <at:AddressType  xmlns:at="Address.Types">
              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTLocationInvolvementType','_LEG','8501'))"/>
            </at:AddressType>
            <at:AddressTypeAssociationID i:nil="true" xmlns:at="Address.Types"/>
            <at:EffectiveDate xmlns:at="Address.Types">
              <xsl:value-of select="string(Util:ConvertDateToAswFormat($AFSCurrentDate))"/>
            </at:EffectiveDate>
            <at:ExpirationDate xmlns:at="Address.Types">
              <xsl:value-of select="string(Util:GetMaxDate())"/>
            </at:ExpirationDate>
            <at:LastTransactionID i:nil="true" xmlns:at="Address.Types"/>
            <at:LastUpdatedDate xmlns:at="Address.Types">
              <xsl:value-of select="string(Util:ConvertDateToAswFormat($AFSCurrentDate))"/>
            </at:LastUpdatedDate>
          </at:AddressTypeAssociationDTO>
        </at:AddressTypeAssociations>
        <at:AdminDivisionPrimary xmlns:at="Address.Types">
          <xsl:value-of select="Entity/City" />
        </at:AdminDivisionPrimary>
        <at:AdminDivisionSecondary i:nil="true" xmlns:at="Address.Types"/>
        <at:AdminDivisionTertiary i:nil="true" xmlns:at="Address.Types"/>
        <at:AllowPartial xmlns:at="Address.Types">false</at:AllowPartial>
        <at:Attention i:nil="true" xmlns:at="Address.Types"/>
        <at:CountryCode xmlns:at="Address.Types">
          <xsl:value-of select="$partyCountryCode"/>
        </at:CountryCode>
        <at:EffectiveDate xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:ConvertDateToAswFormat($AFSCurrentDate))"/>
        </at:EffectiveDate>
        <at:ExpirationDate xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:GetMaxDate())"/>
        </at:ExpirationDate>
        <at:FullAddress i:nil="true" xmlns:at="Address.Types"/>
        <at:GeographicFormatCode xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
        </at:GeographicFormatCode>
        <at:LastTransactionID i:nil="true" xmlns:at="Address.Types"/>
        <at:LastUpdatedDate xmlns:at="Address.Types">
          <xsl:value-of select="$AFSCurrentDate"/>
        </at:LastUpdatedDate>
        <at:Latitude i:nil="true" xmlns:at="Address.Types"/>
        <at:LocationDetailsLine1 xmlns:at="Address.Types">
          <xsl:value-of select="Entity/Address1" />
        </at:LocationDetailsLine1>
        <at:LocationDetailsLine2 xmlns:at="Address.Types">
          <xsl:value-of select="Entity/Address2" />
        </at:LocationDetailsLine2>
        <at:LocationDetailsLine3 i:nil="true" xmlns:at="Address.Types"/>
        <at:LocationDetailsLine4 i:nil="true" xmlns:at="Address.Types"/>
        <at:Longitude i:nil="true" />
        <at:NationalDivisionPrimary xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTStateType',Entity/State,'240'))"/>
        </at:NationalDivisionPrimary>
        <at:NationalDivisionSecondary i:nil="true" xmlns:at="Address.Types"/>
        <at:OldAddressCountryCode i:nil="true" xmlns:at="Address.Types"/>
        <at:PostalCode xmlns:at="Address.Types">
          <xsl:value-of select="Entity/ZIPCode" />
        </at:PostalCode>
        <at:SubAddressType i:nil="true" xmlns:at="Address.Types"/>
        <at:SubAdminDivisionPrimary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubAdminDivisionSecondary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubAdminDivisionTertiary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubAttention i:nil="true" xmlns:at="Address.Types"/>
        <at:SubCountryCode i:nil="true" xmlns:at="Address.Types"/>
        <at:SubEffectiveDate xmlns:at="Address.Types">0001-01-01T00:00:00</at:SubEffectiveDate>
        <at:SubExpirationDate xmlns:at="Address.Types">0001-01-01T00:00:00</at:SubExpirationDate>
        <at:SubLastTransactionID i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLastUpdatedDate xmlns:at="Address.Types">0001-01-01T00:00:00</at:SubLastUpdatedDate>
        <at:SubLatitude i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLocationDetailsLine1 i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLocationDetailsLine2 i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLocationDetailsLine3 i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLocationDetailsLine4 i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLongitude i:nil="true" xmlns:at="Address.Types"/>
        <at:SubNationalDivisionPrimary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubNationalDivisionSecondary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubPostalCode i:nil="true" xmlns:at="Address.Types"/>
      </Address>
      <AddressExtendedData i:nil="true" xmlns:at="Address.Types"/>
      <PartyAddress>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <AddressID i:nil="true" />
        <Comment i:nil="true" />
        <EffectiveDate>
          <xsl:value-of select="$AFSCurrentDate"/>
        </EffectiveDate>
        <ExpirationDate>
          <xsl:value-of select="string(Util:GetMaxDate())"/>
        </ExpirationDate>
        <ExternalPartyAddressID i:nil="true" />
        <IsPrimary>false</IsPrimary>
        <IsTaxAddress>false</IsTaxAddress>
        <LastTransactionID i:nil="true" />
        <LastUpdatedDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>
        <PartyAddressID i:nil="true" />
        <PartyID>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/PartyID" />
        </PartyID>
        <SubComment i:nil="true" />
        <IsDefault>true</IsDefault>
      </PartyAddress>
      <PartyAddressExtendedData i:nil="true" />
    </PartyAddressDetailWithExtendedDataDTO>
  </xsl:template>

  <xsl:template name="PartyAddressesToUpdateTemplate_V2" xmlns="Party.Types">
    <xsl:param name="partyAddressDetail"></xsl:param>
    <PartyAddressDetailDTO xmlns:at="AFS.Address.Types">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <Address>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <at:AddressID xmlns:at="Address.Types">
          <xsl:value-of select="$partyAddressDetail/Address/*[local-name()='AddressID']" />
        </at:AddressID>
        <at:AddressType xmlns:at="Address.Types">
          <xsl:value-of select="$partyAddressDetail/Address/*[local-name()='AddressType']" />
        </at:AddressType>
        <at:AddressTypeAssociations xmlns:at="Address.Types">
          <xsl:for-each select="$partyAddressDetail/*[local-name()='Address']/*[local-name()='AddressTypeAssociations']/*[local-name()='AddressTypeAssociationDTO']">
            <xsl:call-template name="AddressTypeAssociation">
              <xsl:with-param name="addrTypAssoc" select="$partyAddressDetail/*[local-name()='Address']/*[local-name()='AddressTypeAssociations']/*[local-name()='AddressTypeAssociationDTO']" />
            </xsl:call-template>
          </xsl:for-each>
        </at:AddressTypeAssociations>
        <at:AdminDivisionPrimary xmlns:at="Address.Types">
          <xsl:value-of select="/PartyData/Entity/City" />
        </at:AdminDivisionPrimary>
        <at:AdminDivisionSecondary i:nil="true" xmlns:at="Address.Types"/>
        <at:AdminDivisionTertiary i:nil="true" xmlns:at="Address.Types"/>
        <at:AllowPartial xmlns:at="Address.Types">
          <xsl:value-of select="$partyAddressDetail/Address/*[local-name()='AllowPartial']" />
        </at:AllowPartial>
        <at:Attention i:nil="true" xmlns:at="Address.Types"/>
        <at:CountryCode xmlns:at="Address.Types">
          <xsl:value-of select="$partyCountryCode"/>
        </at:CountryCode>
        <at:EffectiveDate xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:ConvertDateToAswFormat($partyAddressDetail/Address/*[local-name()='EffectiveDate']))" />
        </at:EffectiveDate>
        <at:ExpirationDate xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:ConvertDateToAswFormat($partyAddressDetail/Address/*[local-name()='ExpirationDate']))" />
        </at:ExpirationDate>
        <at:FullAddress xmlns:at="Address.Types">
          <xsl:value-of select="$partyAddressDetail/Address/*[local-name()='FullAddress']" />
        </at:FullAddress>
        <at:GeographicFormatCode xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:GetChildKey('8036',$partyCountryCode,'243'))"/>
        </at:GeographicFormatCode>
        <at:LastTransactionID xmlns:at="Address.Types">
          <xsl:value-of select="$partyAddressDetail/Address/*[local-name()='LastTransactionID']" />
        </at:LastTransactionID>
        <at:LastUpdatedDate xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:ConvertDateToAswFormat($partyAddressDetail/Address/*[local-name()='LastUpdatedDate']))" />
        </at:LastUpdatedDate>
        <at:Latitude i:nil="true" xmlns:at="Address.Types"/>
        <at:LocationDetailsLine1 xmlns:at="Address.Types">
          <xsl:value-of select="/PartyData/Entity/Address1" />
        </at:LocationDetailsLine1>
        <at:LocationDetailsLine2 xmlns:at="Address.Types">
          <xsl:value-of select="/PartyData/Entity/Address2" />
        </at:LocationDetailsLine2>
        <at:LocationDetailsLine3 i:nil="true" xmlns:at="Address.Types"/>
        <at:LocationDetailsLine4 i:nil="true" xmlns:at="Address.Types"/>
        <at:Longitude i:nil="true" xmlns:at="Address.Types"/>
        <at:NationalDivisionPrimary xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTStateType',/PartyData/Entity/State,'240'))"/>
        </at:NationalDivisionPrimary>
        <at:NationalDivisionSecondary i:nil="true" xmlns:at="Address.Types"/>
        <at:OldAddressCountryCode i:nil="true" xmlns:at="Address.Types"/>
        <at:PostalCode xmlns:at="Address.Types">
          <xsl:value-of select="/PartyData/Entity/ZIPCode" />
        </at:PostalCode>
        <at:SubAddressType i:nil="true" xmlns:at="Address.Types"/>
        <at:SubAdminDivisionPrimary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubAdminDivisionSecondary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubAdminDivisionTertiary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubAttention i:nil="true" xmlns:at="Address.Types"/>
        <at:SubCountryCode i:nil="true" xmlns:at="Address.Types"/>
        <at:SubEffectiveDate xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:ConvertDateToAswFormat($partyAddressDetail/Address/*[local-name()='SubEffectiveDate']))" />
        </at:SubEffectiveDate>
        <at:SubExpirationDate xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:ConvertDateToAswFormat($partyAddressDetail/Address/*[local-name()='SubExpirationDate']))" />
        </at:SubExpirationDate>
        <at:SubLastTransactionID i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLastUpdatedDate xmlns:at="Address.Types">
          <xsl:value-of select="string(Util:ConvertDateToAswFormat($partyAddressDetail/Address/*[local-name()='SubLastUpdatedDate']))" />
        </at:SubLastUpdatedDate>
        <at:SubLatitude i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLocationDetailsLine1 i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLocationDetailsLine2 i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLocationDetailsLine3 i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLocationDetailsLine4 i:nil="true" xmlns:at="Address.Types"/>
        <at:SubLongitude i:nil="true" xmlns:at="Address.Types"/>
        <at:SubNationalDivisionPrimary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubNationalDivisionSecondary i:nil="true" xmlns:at="Address.Types"/>
        <at:SubPostalCode i:nil="true" xmlns:at="Address.Types"/>
      </Address>
      <xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode($partyAddressDetail/PartyAddress,'PartyAddress')" />
    </PartyAddressDetailDTO>
  </xsl:template>

  <xsl:template name="AddressTypeAssociation" xmlns="Party.Types">
    <xsl:param name="addrTypAssoc"></xsl:param>
    <at:AddressTypeAssociationDTO xmlns:at="Address.Types">
      <afs:EntityAuthLevel xmlns="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common">None</afs:EntityAuthLevel>
      <at:AddressID>
        <xsl:value-of select="*[local-name()='AddressID']" />
      </at:AddressID>
      <at:AddressType>
        <xsl:value-of select="*[local-name()='AddressType']" />
      </at:AddressType>
      <at:AddressTypeAssociationID>
        <xsl:value-of select="*[local-name()='AddressTypeAssociationID']" />
      </at:AddressTypeAssociationID>
      <at:EffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(*[local-name()='EffectiveDate']))" />
      </at:EffectiveDate>
      <at:ExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(*[local-name()='ExpirationDate']))" />
      </at:ExpirationDate>
      <at:LastTransactionID>
        <xsl:value-of select="*[local-name()='LastTransactionID']" />
      </at:LastTransactionID>
      <at:LastUpdatedDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(*[local-name()='LastUpdatedDate']))" />
      </at:LastUpdatedDate>
    </at:AddressTypeAssociationDTO>
  </xsl:template>

  <xsl:template name="PartyMembershipsToInsertTemplate">
    <PartyMembershipWithExtendedDataDTO>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <ExtendedData nil="true" />
      <PartyMembership>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <LastTransactionID nil="true" />
        <LastUpdatedDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>
        <MembershipID>
          <xsl:value-of select="Entity/Reference" />
        </MembershipID>
        <MembershipTypeCode>A</MembershipTypeCode>
        <PartyID>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/PartyID" />
        </PartyID>
        <PartyMembershipID nil="true" />
      </PartyMembership>
    </PartyMembershipWithExtendedDataDTO>
  </xsl:template>

  <xsl:template name="PartyMembershipsToUpdateTemplate">
    <PartyMembershipDTO>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <LastTransactionID>
        <xsl:value-of select="LastTransactionID" />
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <MembershipID>
        <xsl:value-of select="/PartyData/Entity/Reference" />
      </MembershipID>
      <MembershipTypeCode>A</MembershipTypeCode>
      <PartyID>
        <xsl:value-of select="PartyID" />
      </PartyID>
      <PartyMembershipID>
        <xsl:value-of select="PartyMembershipID" />
      </PartyMembershipID>
    </PartyMembershipDTO>
  </xsl:template>
</xsl:stylesheet>