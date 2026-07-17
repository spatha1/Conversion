<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="PartyEmailTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyReferenceTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyLicenseTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyPhoneTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyIndNameTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyRelationTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyBusNameTemplate_DuckToASW.xslt"/>
  <xsl:template match="/">
    <xsl:for-each select="PartyRecord">
      <xsl:choose>
        <xsl:when test="Party/PartyTypeCode = 'P'">
          <PartyIndividualDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://epc.accenture.com/2013/06/26/Type">
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <Party>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <ACHPartyExternalID i:nil="true" />
              <BusinessPermitted>U</BusinessPermitted>
              <CountryCode>8A</CountryCode>
              <!--<ExternalID i:nil="true" />-->
              <GeographicFormatCode>US</GeographicFormatCode>
              <!--<IsInActive>false</IsInActive>-->
              <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
              <LastUpdatedDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </LastUpdatedDate>
              <Number>1</Number>
              <!--<PartyID>A20499A5206B2D0D</PartyID>-->
              <PartyTypeCode>
                <!--<xsl:value-of select="Party/PartyTypeCode"/>-->
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',Party/PartyTypeCode,'8001'))"/>
              </PartyTypeCode>
            </Party>
            <PartyAddressDetail>
          <PartyAddressDetailDTO>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <Address xmlns:d4p1="http://schemas.datacontract.org/2004/07/AFS.Address.Types">
              <!--<d4p1:AddressID>F6947906167ECAF7</d4p1:AddressID>-->
              <d4p1:AddressType>VACTN</d4p1:AddressType>
              <d4p1:AdminDivisionPrimary>Schenectady</d4p1:AdminDivisionPrimary>
              <d4p1:AdminDivisionSecondary i:nil="true" />
              <d4p1:AdminDivisionTertiary i:nil="true" />
              <d4p1:AllowPartial>false</d4p1:AllowPartial>
              <d4p1:Attention i:nil="true" />
              <d4p1:CountryCode>8A</d4p1:CountryCode>
              <d4p1:EffectiveDate>2013-04-26T12:56:05.6183955+05:30</d4p1:EffectiveDate>
              <d4p1:ExpirationDate>9999-12-31T00:00:00</d4p1:ExpirationDate>
              <d4p1:FullAddress i:nil="true" />
              <d4p1:GeographicFormatCode>US</d4p1:GeographicFormatCode>
              <!--<d4p1:LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</d4p1:LastTransactionID>-->
              <d4p1:LastUpdatedDate>2013-04-26T12:56:05.6183955+05:30</d4p1:LastUpdatedDate>
              <d4p1:Latitude>42.780477</d4p1:Latitude>
              <d4p1:LocationDetailsLine1>123 street</d4p1:LocationDetailsLine1>
              <d4p1:LocationDetailsLine2 i:nil="true" />
              <d4p1:LocationDetailsLine3 i:nil="true" />
              <d4p1:LocationDetailsLine4 i:nil="true" />
              <d4p1:Longitude>-73.955187</d4p1:Longitude>
              <d4p1:NationalDivisionPrimary>31</d4p1:NationalDivisionPrimary>
              <d4p1:NationalDivisionSecondary>36007</d4p1:NationalDivisionSecondary>
              <d4p1:OldAddressCountryCode i:nil="true" />
              <d4p1:PostalCode>12345</d4p1:PostalCode>
              <d4p1:SubAddressType i:nil="true" />
              <d4p1:SubAdminDivisionPrimary i:nil="true" />
              <d4p1:SubAdminDivisionSecondary i:nil="true" />
              <d4p1:SubAdminDivisionTertiary i:nil="true" />
              <d4p1:SubAttention i:nil="true" />
              <d4p1:SubCountryCode>8A</d4p1:SubCountryCode>
              <d4p1:SubEffectiveDate>2013-04-26T12:56:05.6183955+05:30</d4p1:SubEffectiveDate>
              <d4p1:SubExpirationDate>9999-12-31T00:00:00</d4p1:SubExpirationDate>
              <!--<d4p1:SubLastTransactionID i:nil="true" />-->
              <d4p1:SubLastUpdatedDate>2013-04-26T12:56:05.6183955+05:30</d4p1:SubLastUpdatedDate>
              <d4p1:SubLatitude i:nil="true" />
              <d4p1:SubLocationDetailsLine1 i:nil="true" />
              <d4p1:SubLocationDetailsLine2 i:nil="true" />
              <d4p1:SubLocationDetailsLine3 i:nil="true" />
              <d4p1:SubLocationDetailsLine4 i:nil="true" />
              <d4p1:SubLongitude i:nil="true" />
              <d4p1:SubNationalDivisionPrimary i:nil="true" />
              <d4p1:SubNationalDivisionSecondary i:nil="true" />
              <d4p1:SubPostalCode i:nil="true" />
            </Address>
            <PartyAddress>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <AddressID>F6947906167ECAF7</AddressID>
              <Comment i:nil="true" />
              <EffectiveDate>2013-04-26T12:56:05.6183955+05:30</EffectiveDate>
              <ExpirationDate>9999-12-31T00:00:00</ExpirationDate>
              <ExternalPartyAddressID i:nil="true" />
              <IsPrimary>true</IsPrimary>
              <IsTaxAddress>false</IsTaxAddress>
              <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
              <LastUpdatedDate>2013-04-26T12:56:05.6183955+05:30</LastUpdatedDate>
              <!--<PartyAddressID>3A599FC7181E8289</PartyAddressID>-->
              <!--<PartyID>A20499A5206B2D0D</PartyID>-->
              <SubComment i:nil="true" />
            </PartyAddress>
          </PartyAddressDetailDTO>
        </PartyAddressDetail>
            <PartyAgent i:nil="true" />
            <PartyEmail>
              <xsl:call-template name="partyEmail" />
            </PartyEmail>
            <PartyIndNameDetail>
              <PartyIndNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyIndName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <Comment i:nil="true" />
                  <FirstName>
                    <xsl:value-of select="Party/PartyFirstName"/>
                  </FirstName>
                  <FirstNamePhonetic i:nil="true" />
                  <FirstNameSoundex i:nil="true" />
                  <FirstNameUpperCase i:nil="true" />
                  <LastName>
                    <xsl:value-of select="Party/PartyName"/>
                  </LastName>
                  <LastNamePhonetic i:nil="true" />
                  <LastNameSoundex i:nil="true" />
                  <LastNameUpperCase i:nil="true" />
                  <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <MiddleName>
                    <xsl:value-of select="Party/PartyMiddleName"/>
                  </MiddleName>
                  <MiddleNamePhonetic i:nil="true" />
                  <MiddleNameSoundex i:nil="true" />
                  <MiddleNameUpperCase i:nil="true" />
                  <NameTypeCode>01</NameTypeCode>
                  <!--<PartyIndNameID>5BEB717A8528E678</PartyIndNameID>-->
                  <PrefixCode>
                    <xsl:value-of select="Party/PartyNamePrefixCode"/>
                  </PrefixCode>
                  <SuffixCode>
                    <xsl:value-of select="Party/PartyNameSuffixCode"/>
                  </SuffixCode>
                </PartyIndName>
                <PartyName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <AllowPartial>false</AllowPartial>
                  <CountryCode>8A</CountryCode>
                  <EffectiveDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </EffectiveDate>
                  <ExpirationDate>
                    <xsl:value-of select="string(Util:GetMaxDate())"/>
                  </ExpirationDate>
                  <ExternalPartyNameID i:nil="true" />
                  <GeographicFormatCode>US</GeographicFormatCode>
                  <IsPrimary>true</IsPrimary>
                  <IsTaxName>false</IsTaxName>
                  <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <!--<PartyID>A20499A5206B2D0D</PartyID>-->
                  <!--<PartyNameID>5BEB717A8528E678</PartyNameID>-->
                </PartyName>
              </PartyIndNameDetailDTO>
              <PartyIndNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyIndName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <Comment i:nil="true" />
                  <FirstName>
                    <xsl:value-of select="Party/PartyFirstName"/>
                  </FirstName>
                  <FirstNamePhonetic i:nil="true" />
                  <FirstNameSoundex i:nil="true" />
                  <FirstNameUpperCase i:nil="true" />
                  <FullName>
                    <xsl:value-of select="Party/PartyCorrespondenceName"/>
                  </FullName>
                  <LastName>
                    <xsl:value-of select="Party/PartyName"/>
                  </LastName>
                  <LastNamePhonetic i:nil="true" />
                  <LastNameSoundex i:nil="true" />
                  <LastNameUpperCase i:nil="true" />
                  <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <MiddleName>
                    <xsl:value-of select="Party/PartyMiddleName"/>
                  </MiddleName>
                  <MiddleNamePhonetic i:nil="true" />
                  <MiddleNameSoundex i:nil="true" />
                  <MiddleNameUpperCase i:nil="true" />
                  <NameTypeCode>07</NameTypeCode>
                  <!--<PartyIndNameID>5BEB717A8528E678</PartyIndNameID>-->
                  <PrefixCode>
                    <!--<xsl:value-of select="Party/PartyNamePrefixCode"/>-->
                  </PrefixCode>
                  <SuffixCode>
                    <!--<xsl:value-of select="Party/PartyNameSuffixCode"/>-->
                  </SuffixCode>
                </PartyIndName>
                <PartyName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <AllowPartial>false</AllowPartial>
                  <CountryCode>8A</CountryCode>
                  <EffectiveDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </EffectiveDate>
                  <ExpirationDate>
                    <xsl:value-of select="string(Util:GetMaxDate())"/>
                  </ExpirationDate>
                  <ExternalPartyNameID i:nil="true" />
                  <GeographicFormatCode>US</GeographicFormatCode>
                  <IsPrimary>false</IsPrimary>
                  <IsTaxName>false</IsTaxName>
                  <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <!--<PartyID>A20499A5206B2D0D</PartyID>-->
                  <!--<PartyNameID>5BEB717A8528E678</PartyNameID>-->
                </PartyName>
              </PartyIndNameDetailDTO>
              <PartyIndNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyIndName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <Comment i:nil="true" />
                  <FirstName>
                    <xsl:value-of select="Party/PartyFirstName"/>
                  </FirstName>
                  <FirstNamePhonetic i:nil="true" />
                  <FirstNameSoundex i:nil="true" />
                  <FirstNameUpperCase i:nil="true" />
                  <FullName>
                    <xsl:value-of select="Party/PartyLegacyName"/>
                  </FullName>
                  <LastName>
                    <xsl:value-of select="Party/PartyName"/>
                  </LastName>
                  <LastNamePhonetic i:nil="true" />
                  <LastNameSoundex i:nil="true" />
                  <LastNameUpperCase i:nil="true" />
                  <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <MiddleName>
                    <xsl:value-of select="Party/PartyMiddleName"/>
                  </MiddleName>
                  <MiddleNamePhonetic i:nil="true" />
                  <MiddleNameSoundex i:nil="true" />
                  <MiddleNameUpperCase i:nil="true" />
                  <NameTypeCode>06</NameTypeCode>
                  <!--<PartyIndNameID>5BEB717A8528E678</PartyIndNameID>-->
                  <PrefixCode>
                    <!--<xsl:value-of select="Party/PartyNamePrefixCode"/>-->
                  </PrefixCode>
                  <SuffixCode>
                    <!--<xsl:value-of select="Party/PartyNameSuffixCode"/>-->
                  </SuffixCode>
                </PartyIndName>
                <PartyName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <AllowPartial>false</AllowPartial>
                  <CountryCode>8A</CountryCode>
                  <EffectiveDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </EffectiveDate>
                  <ExpirationDate>
                    <xsl:value-of select="string(Util:GetMaxDate())"/>
                  </ExpirationDate>
                  <ExternalPartyNameID i:nil="true" />
                  <GeographicFormatCode>US</GeographicFormatCode>
                  <IsPrimary>false</IsPrimary>
                  <IsTaxName>false</IsTaxName>
                  <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <!--<PartyID>A20499A5206B2D0D</PartyID>-->
                  <!--<PartyNameID>5BEB717A8528E678</PartyNameID>-->
                </PartyName>
              </PartyIndNameDetailDTO>
              <xsl:call-template name="partyIndName" />
            </PartyIndNameDetail>
            <PartyIndividual>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <DateOfBirth>2013-06-01</DateOfBirth>
              <!--<xsl:value-of select="Party/PartyBirthDate"/>-->
              <DateOfDeath i:nil="true" />
              <EffectiveDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </EffectiveDate>
              <ExpirationDate>
                <xsl:value-of select="string(Util:GetMaxDate())"/>
              </ExpirationDate>
              <GenderCode>
                <xsl:value-of select="Party/PartyGenderCode"/>
              </GenderCode>
              <IsAgent>false</IsAgent>
              <IsCompanyPersonnel>false</IsCompanyPersonnel>
              <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
              <LastUpdatedDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </LastUpdatedDate>
              <MaritalStatusCode>
                <xsl:value-of select="Party/PartyMaritalStatusCode"/>
              </MaritalStatusCode>
              <NationalID i:nil="true" />
              <NumberOfDependents i:nil="true" />
              <!--<PartyID>A20499A5206B2D0D</PartyID>-->
              <PreferredContactType>

              </PreferredContactType>
              <PreferredLanguage>
                <xsl:value-of select="Party/PartyPreferredLanguageCode"/>
              </PreferredLanguage>
              <ProfessionCode i:nil="true" />
              <SpecificPurposeID>
                <xsl:value-of select="Party/PartyTaxId"/>
              </SpecificPurposeID>
            </PartyIndividual>
            <!--<PartyIndividualDriverLicence>
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
          <EffectiveDate>2013-04-26T12:56:05.6069354+05:30</EffectiveDate>
          <ExpirationDate>9999-12-31T00:00:00</ExpirationDate>
          <ExpirationLicenseDate i:nil="true" />
          <LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>
          <LastUpdatedDate>2013-04-26T12:56:05.6069354+05:30</LastUpdatedDate>
          <PartyID>A20499A5206B2D0D</PartyID>
          <PartyLicenseCountry>8A</PartyLicenseCountry>
          <PartyLicenseID>A039C8BB1D354270</PartyLicenseID>
          <PartyLicenseIss i:nil="true" />
          <PartyLicenseNumber>54454547878878545464</PartyLicenseNumber>
          <PartyLicensePlcIss>04</PartyLicensePlcIss>
          <PartyLicenseStatus i:nil="true" />
          <PartyLicenseType i:nil="true" />
        </PartyIndividualDriverLicence>-->
            <PartyLicense>
              <xsl:call-template name="partyLicense" />
            </PartyLicense>
            <PartyMembership>
              <xsl:call-template name="partyReference" />
            </PartyMembership>
            <PartyPhone>
              <xsl:call-template name="partyPhone" />
            </PartyPhone>
            <PartyRelation>
              <xsl:call-template name="partyRelation" />
            </PartyRelation>
          </PartyIndividualDetailDTO>
        </xsl:when>
        <xsl:otherwise>
          <PartyBusinessDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://epc.accenture.com/2013/06/26/Type">
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <Party>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <ACHPartyExternalID i:nil="true" />
              <BusinessPermitted>U</BusinessPermitted>
              <CountryCode>8A</CountryCode>
              <ExternalID i:nil="true" />
              <GeographicFormatCode>US</GeographicFormatCode>
              <IsInActive>false</IsInActive>
              <!--<LastTransactionID>NO TRANSACTION ID</LastTransactionID>-->
              <LastUpdatedDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </LastUpdatedDate>
              <Number>PARTY1000</Number>
              <!--<PartyID>PARTYBUS1000</PartyID>-->
              <PartyTypeCode>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',Party/PartyTypeCode,'8001'))"/>
              </PartyTypeCode>
            </Party>
            <PartyAddressDetail>
              <PartyAddressDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <Address xmlns:d4p1="http://schemas.datacontract.org/2004/07/AFS.Address.Types">
                  <!--<d4p1:AddressID>ADDRBUSUS1</d4p1:AddressID>-->
                  <d4p1:AddressType>BUS</d4p1:AddressType>
                  <d4p1:AdminDivisionPrimary>Denville</d4p1:AdminDivisionPrimary>
                  <d4p1:AdminDivisionSecondary i:nil="true" />
                  <d4p1:AdminDivisionTertiary i:nil="true" />
                  <d4p1:AllowPartial>false</d4p1:AllowPartial>
                  <d4p1:Attention i:nil="true" />
                  <d4p1:CountryCode>8A</d4p1:CountryCode>
                  <d4p1:EffectiveDate>2011-08-03T19:25:42.58</d4p1:EffectiveDate>
                  <d4p1:ExpirationDate>9999-12-31T19:25:42.58</d4p1:ExpirationDate>
                  <d4p1:FullAddress>1 Main Street,&lt;br /&gt; Denville, New Jersey, United States, 07834.</d4p1:FullAddress>
                  <d4p1:GeographicFormatCode>US</d4p1:GeographicFormatCode>
                  <!--<d4p1:LastTransactionID>NO TRANSACTION ID</d4p1:LastTransactionID>-->
                  <d4p1:LastUpdatedDate>2011-08-03T19:25:42.58</d4p1:LastUpdatedDate>
                  <d4p1:Latitude i:nil="true" />
                  <d4p1:LocationDetailsLine1>1 Main Street</d4p1:LocationDetailsLine1>
                  <d4p1:LocationDetailsLine2 i:nil="true" />
                  <d4p1:LocationDetailsLine3 i:nil="true" />
                  <d4p1:LocationDetailsLine4 i:nil="true" />
                  <d4p1:Longitude i:nil="true" />
                  <d4p1:NationalDivisionPrimary>29</d4p1:NationalDivisionPrimary>
                  <d4p1:NationalDivisionSecondary i:nil="true" />
                  <d4p1:OldAddressCountryCode i:nil="true" />
                  <d4p1:PostalCode>07834</d4p1:PostalCode>
                  <d4p1:SubAddressType i:nil="true" />
                  <d4p1:SubAdminDivisionPrimary i:nil="true" />
                  <d4p1:SubAdminDivisionSecondary i:nil="true" />
                  <d4p1:SubAdminDivisionTertiary i:nil="true" />
                  <d4p1:SubAttention i:nil="true" />
                  <d4p1:SubCountryCode i:nil="true" />		  
					<d4p1:SubEffectiveDate>
						<xsl:value-of select="string(Util:GetCurrentDate())"/>
					</d4p1:SubEffectiveDate>
					<d4p1:SubExpirationDate>
						<xsl:value-of select="string(Util:GetMaxDate())"/>
					</d4p1:SubExpirationDate>
					<d4p1:SubLastUpdatedDate>
						<xsl:value-of select="string(Util:GetCurrentDate())"/>
					</d4p1:SubLastUpdatedDate>
                  <d4p1:SubLatitude i:nil="true" />
                  <d4p1:SubLocationDetailsLine1 i:nil="true" />
                  <d4p1:SubLocationDetailsLine2 i:nil="true" />
                  <d4p1:SubLocationDetailsLine3 i:nil="true" />
                  <d4p1:SubLocationDetailsLine4 i:nil="true" />
                  <d4p1:SubLongitude i:nil="true" />
                  <d4p1:SubNationalDivisionPrimary i:nil="true" />
                  <d4p1:SubNationalDivisionSecondary i:nil="true" />
                  <d4p1:SubPostalCode i:nil="true" />
                </Address>
                <PartyAddress>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <AddressID>ADDRBUSUS1</AddressID>
                  <Comment i:nil="true" />
                  <EffectiveDate>2008-01-01T00:00:00</EffectiveDate>
                  <ExpirationDate>9999-12-31T00:00:00</ExpirationDate>
                  <ExternalPartyAddressID i:nil="true" />
                  <IsPrimary>true</IsPrimary>
                  <IsTaxAddress>false</IsTaxAddress>
                  <!--<LastTransactionID>ad3104c6f5024PARTYADDRBUS1</LastTransactionID>-->
                  <LastUpdatedDate>2010-10-14T00:00:00</LastUpdatedDate>
                  <!--<PartyAddressID>PARTYADDRBUS1</PartyAddressID>-->
                  <!--<PartyID>PARTYBUS1000</PartyID>-->
                  <SubComment i:nil="true" />
                </PartyAddress>
              </PartyAddressDetailDTO>
              <PartyAddressDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <Address xmlns:d4p1="http://schemas.datacontract.org/2004/07/AFS.Address.Types">
                  <!--<d4p1:AddressID>ADDRBUSUS2</d4p1:AddressID>-->
                  <d4p1:AddressType>CBLNG</d4p1:AddressType>
                  <d4p1:AdminDivisionPrimary>Denville</d4p1:AdminDivisionPrimary>
                  <d4p1:AdminDivisionSecondary i:nil="true" />
                  <d4p1:AdminDivisionTertiary i:nil="true" />
                  <d4p1:AllowPartial>false</d4p1:AllowPartial>
                  <d4p1:Attention i:nil="true" />
                  <d4p1:CountryCode>8A</d4p1:CountryCode>
                  <d4p1:EffectiveDate>2011-08-03T19:25:42.59</d4p1:EffectiveDate>
                  <d4p1:ExpirationDate>9999-12-31T19:25:42.59</d4p1:ExpirationDate>
                  <d4p1:FullAddress>12 Broadway,&lt;br /&gt; Denville, New Jersey, United States, 07834.</d4p1:FullAddress>
                  <d4p1:GeographicFormatCode>US</d4p1:GeographicFormatCode>
                  <!--<d4p1:LastTransactionID>NO TRANSACTION ID</d4p1:LastTransactionID>-->
                  <d4p1:LastUpdatedDate>2011-08-03T19:25:42.59</d4p1:LastUpdatedDate>
                  <d4p1:Latitude i:nil="true" />
                  <d4p1:LocationDetailsLine1>12 Broadway</d4p1:LocationDetailsLine1>
                  <d4p1:LocationDetailsLine2 i:nil="true" />
                  <d4p1:LocationDetailsLine3 i:nil="true" />
                  <d4p1:LocationDetailsLine4 i:nil="true" />
                  <d4p1:Longitude i:nil="true" />
                  <d4p1:NationalDivisionPrimary>29</d4p1:NationalDivisionPrimary>
                  <d4p1:NationalDivisionSecondary i:nil="true" />
                  <d4p1:OldAddressCountryCode i:nil="true" />
                  <d4p1:PostalCode>07834</d4p1:PostalCode>
                  <d4p1:SubAddressType i:nil="true" />
                  <d4p1:SubAdminDivisionPrimary i:nil="true" />
                  <d4p1:SubAdminDivisionSecondary i:nil="true" />
                  <d4p1:SubAdminDivisionTertiary i:nil="true" />
                  <d4p1:SubAttention i:nil="true" />
                  <d4p1:SubCountryCode i:nil="true" />
				  
					<d4p1:SubEffectiveDate>
						<xsl:value-of select="string(Util:GetCurrentDate())"/>
					</d4p1:SubEffectiveDate>
					<d4p1:SubExpirationDate>
						<xsl:value-of select="string(Util:GetMaxDate())"/>
					</d4p1:SubExpirationDate>
					<d4p1:SubLastUpdatedDate>
						<xsl:value-of select="string(Util:GetCurrentDate())"/>
					</d4p1:SubLastUpdatedDate>
				  
				  
                  <d4p1:SubLatitude i:nil="true" />
                  <d4p1:SubLocationDetailsLine1 i:nil="true" />
                  <d4p1:SubLocationDetailsLine2 i:nil="true" />
                  <d4p1:SubLocationDetailsLine3 i:nil="true" />
                  <d4p1:SubLocationDetailsLine4 i:nil="true" />
                  <d4p1:SubLongitude i:nil="true" />
                  <d4p1:SubNationalDivisionPrimary i:nil="true" />
                  <d4p1:SubNationalDivisionSecondary i:nil="true" />
                  <d4p1:SubPostalCode i:nil="true" />
                </Address>
                <PartyAddress>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <!--<AddressID>ADDRBUSUS2</AddressID>-->
                  <Comment i:nil="true" />
                  <EffectiveDate>2008-01-01T00:00:00</EffectiveDate>
                  <ExpirationDate>9999-12-31T00:00:00</ExpirationDate>
                  <ExternalPartyAddressID i:nil="true" />
                  <IsPrimary>false</IsPrimary>
                  <IsTaxAddress>false</IsTaxAddress>
                  <LastTransactionID>ad3104c6f5024PARTYADDRBUS2</LastTransactionID>
                  <LastUpdatedDate>2010-10-14T00:00:00</LastUpdatedDate>
                  <!--<PartyAddressID>PARTYADDRBUS2</PartyAddressID>-->
                  <!--<PartyID>PARTYBUS1000</PartyID>-->
                  <SubComment i:nil="true" />
                </PartyAddress>
              </PartyAddressDetailDTO>
            </PartyAddressDetail>
            <!--<PartyAgency>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <AgencySpecialityType i:nil="true" />
              <AgencySubCode i:nil="true" />
              <EffectiveDate>0001-01-01T00:00:00</EffectiveDate>
              <ExpirationDate>0001-01-01T00:00:00</ExpirationDate>
              <LastTransactionID i:nil="true" />
              <LastUpdatedDate>0001-01-01T00:00:00</LastUpdatedDate>
              <PartyID i:nil="true" />
              <ProducerNumber i:nil="true" />
            </PartyAgency>-->
            <PartyBusNameDetail>
              <PartyBusNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyBusName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <Comment i:nil="true" />
                  <!--<LastTransactionID>NO TRANSACTION ID</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <Name>
                    <xsl:value-of select="Party/PartyName"/>
                  </Name>
                  <NamePhonetic i:nil="true" />
                  <NameSoundex i:nil="true" />
                  <NameTypeCode>01</NameTypeCode>
                  <NameUpperCase i:nil="true" />
                  <!--<PartyBusNameID>NAME10</PartyBusNameID>-->
                </PartyBusName>
                <PartyName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <AllowPartial>false</AllowPartial>
                  <CountryCode>8A</CountryCode>
                  <EffectiveDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </EffectiveDate>
                  <ExpirationDate>
                    <xsl:value-of select="string(Util:GetMaxDate())"/>
                  </ExpirationDate>
                  <ExternalPartyNameID i:nil="true" />
                  <GeographicFormatCode>US</GeographicFormatCode>
                  <IsPrimary>true</IsPrimary>
                  <IsTaxName>false</IsTaxName>
                  <!--<LastTransactionID>NO TRANSACTION ID</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <!--<PartyID>PARTYBUS1000</PartyID>-->
                  <!--<PartyNameID>NAME10</PartyNameID>-->
                </PartyName>
              </PartyBusNameDetailDTO>
              <PartyBusNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyBusName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <Comment i:nil="true" />
                  <!--<LastTransactionID>NO TRANSACTION ID</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <Name>
                    <xsl:value-of select="Party/PartyName"/>
                  </Name>
                  <NamePhonetic i:nil="true" />
                  <NameSoundex i:nil="true" />
                  <NameTypeCode>07</NameTypeCode>
                  <NameUpperCase i:nil="true" />
                  <!--<PartyBusNameID>NAME10</PartyBusNameID>-->
                </PartyBusName>
                <PartyName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <AllowPartial>false</AllowPartial>
                  <CountryCode>8A</CountryCode>
                  <EffectiveDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </EffectiveDate>
                  <ExpirationDate>
                    <xsl:value-of select="string(Util:GetMaxDate())"/>
                  </ExpirationDate>
                  <ExternalPartyNameID i:nil="true" />
                  <GeographicFormatCode>US</GeographicFormatCode>
                  <IsPrimary>false</IsPrimary>
                  <IsTaxName>false</IsTaxName>
                  <!--<LastTransactionID>NO TRANSACTION ID</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <!--<PartyID>PARTYBUS1000</PartyID>-->
                  <!--<PartyNameID>NAME10</PartyNameID>-->
                </PartyName>
              </PartyBusNameDetailDTO>
              <PartyBusNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyBusName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <Comment i:nil="true" />
                  <!--<LastTransactionID>NO TRANSACTION ID</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <Name>
                    <xsl:value-of select="Party/PartyLegacyName"/>
                  </Name>
                  <NamePhonetic i:nil="true" />
                  <NameSoundex i:nil="true" />
                  <NameTypeCode>06</NameTypeCode>
                  <NameUpperCase i:nil="true" />
                  <!--<PartyBusNameID>NAME10</PartyBusNameID>-->
                </PartyBusName>
                <PartyName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <AllowPartial>false</AllowPartial>
                  <CountryCode>8A</CountryCode>
                  <EffectiveDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </EffectiveDate>
                  <ExpirationDate>
                    <xsl:value-of select="string(Util:GetMaxDate())"/>
                  </ExpirationDate>
                  <ExternalPartyNameID i:nil="true" />
                  <GeographicFormatCode>US</GeographicFormatCode>
                  <IsPrimary>false</IsPrimary>
                  <IsTaxName>false</IsTaxName>
                  <!--<LastTransactionID>NO TRANSACTION ID</LastTransactionID>-->
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <!--<PartyID>PARTYBUS1000</PartyID>-->
                  <!--<PartyNameID>NAME10</PartyNameID>-->
                </PartyName>
              </PartyBusNameDetailDTO>
              <xsl:call-template name="partyBusName" />
            </PartyBusNameDetail>
            <PartyBusiness>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <BusinessTypeCode>
                <!--TODO:code decode mapping-->
                <xsl:value-of select="Party/PartySubTypeCode"/>
              </BusinessTypeCode>
              <EffectiveDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </EffectiveDate>
              <ExpirationDate>
                <xsl:value-of select="string(Util:GetMaxDate())"/>
              </ExpirationDate>
              <IsAgency>false</IsAgency>
              <IsSupplier>false</IsSupplier>
              <!--<LastTransactionID>NO TRANSACTION ID</LastTransactionID>-->
              <LastUpdatedDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </LastUpdatedDate>
              <!--<PartyID>PARTYBUS1000</PartyID>-->
              <PreferredContactType></PreferredContactType>
              <PreferredLanguage>
                <!--TODO:code decode mapping-->
                <xsl:value-of select="Party/PartyPreferredLanguageCode"/>
              </PreferredLanguage>
              <RegistrationID1>
                <xsl:value-of select="Party/PartyTaxId"/>
              </RegistrationID1>
               <RegistrationID2>
                 <xsl:value-of select="Party/PartyTaxId2"/>   <!--#5814-Added for nzbn mapping  -->
               </RegistrationID2>
              <RegistrationID3 i:nil="true" />
            </PartyBusiness>
            <!--<PartyComment>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <Comment i:nil="true" />
              <EffectiveDate>2010-10-20T00:00:00</EffectiveDate>
              <ExpirationDate>9999-12-31T00:00:00</ExpirationDate>
              <LastTransactionID>NO TRANSACTION ID</LastTransactionID>
              <LastUpdatedDate>2010-10-14T00:00:00</LastUpdatedDate>
              <PartyID>PARTYBUS1000</PartyID>
            </PartyComment>-->
            <PartyEmail>
              <xsl:call-template name="partyEmail" />
            </PartyEmail>
            <PartyLicense>
              <xsl:call-template name="partyLicense" />
            </PartyLicense>
            <PartyMembership>
              <xsl:call-template name="partyReference" />
            </PartyMembership>
            <PartyPhone>
              <xsl:call-template name="partyPhone" />
            </PartyPhone>
            <PartyRelation>
              <xsl:call-template name="partyRelation" />
            </PartyRelation>
          </PartyBusinessDetailDTO>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>

