<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:template match="/SearchRequestRecord">
    <xsl:variable name="PartyTypeCount" select="count(SearchControl/Filters/Filter[@Type = 'PartyType'])"></xsl:variable>
    <xsl:variable name="SearchType" select="string(Util:GetValueByKey('SearchType'))" />
    <xsl:variable name="NameSearchType" select="SearchCriteria/PartyNameSearchType"/>
    <xsl:variable name="SearchPartyMethod" select="string(Util:GetValueByKey('SearchPartyMethod'))"/>
    <PartySearchInput>
      <!--Party Name-->
      <Individual>
        <xsl:choose>
          <xsl:when test="$NameSearchType = 'S'">
            <LastName IsSoundex="true">
              <xsl:value-of select="string(SearchCriteria/PartyRecord/Party/PartyName)"/>
            </LastName>
          </xsl:when>
          <xsl:otherwise>
            <LastName IsSoundex="false">
              <xsl:value-of select="string(SearchCriteria/PartyRecord/Party/PartyName)"/>
            </LastName>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="SearchCriteria/PartyRecord/Party/PartyFirstName != ''">
          <FirstName>
            <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyFirstName"/>
          </FirstName>
        </xsl:if>
        <xsl:if test="SearchCriteria/PartyRecord/Party/PartyMiddleName != ''">
          <MiddleName>
            <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyMiddleName"/>
          </MiddleName>
        </xsl:if>
        <xsl:if test="SearchCriteria/PartyRecord/Party/PartyBirthDate != ''">
          <DateOfBirth>
            <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyBirthDate"/>
          </DateOfBirth>
        </xsl:if>
		<xsl:if test="SearchCriteria/PartyRecord/Party/PartyTaxId != ''">
          <SpecificPurposeID>
            <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyTaxId"/>
          </SpecificPurposeID>
        </xsl:if>

        <xsl:if test="SearchCriteria/PartyRecord/Party/PartyGenderCode != ''">
          <Gender>
            <xsl:value-of select="string(Util:GetOneRelatedItem('DCTGender',SearchCriteria/PartyRecord/Party/PartyGenderCode,'51'))"/>
          </Gender>
        </xsl:if>

        <ExtendedData>
          <xsl:if test="SearchCriteria/PartyRecord/Party/PartyExtendedData/Ethnicity != ''">
            <Ethnicity>
              <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyExtendedData/Ethnicity"/>
            </Ethnicity>
          </xsl:if>
        </ExtendedData>
      </Individual>
      <Business>
        <xsl:choose>
          <xsl:when test="$NameSearchType = 'S'">
            <Name IsSoundex ="true">
              <xsl:value-of select="string(SearchCriteria/PartyRecord/Party/PartyName)"/>
            </Name>
          </xsl:when>
          <xsl:otherwise>
            <Name IsSoundex ="false">
              <xsl:if test="string(SearchCriteria/PartyRecord/Party/PartyName) != ''">
                <xsl:text>%</xsl:text>
              </xsl:if>
              <xsl:value-of select="string(SearchCriteria/PartyRecord/Party/PartyName)"/>
            </Name>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
          <xsl:if test="@Value != ''">
            <IsAgency>
              <xsl:choose>
                <xsl:when test="@Value = 'AG'">1</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
              </xsl:choose>
            </IsAgency>
          </xsl:if>
        </xsl:for-each>
		<xsl:if test="SearchCriteria/PartyRecord/Party/PartyTaxId != ''">
          <RegistrationID1>
            <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyTaxId"/>
          </RegistrationID1>
        </xsl:if>
		<xsl:if test="SearchCriteria/PartyRecord/Party/PartyTaxId2 != ''">
          <RegistrationID2>
            <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyTaxId2"/>  <!--#5814-Added for nzbn mapping  -->
          </RegistrationID2>
        </xsl:if>
        <ExtendedData>
          <xsl:if test="SearchCriteria/PartyRecord/Party/PartyExtendedData/Ethnicity != ''">
            <Ethnicity>
              <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyExtendedData/Ethnicity"/>
            </Ethnicity>
          </xsl:if>
        </ExtendedData>
      </Business>
      <OutputNameTypeCodes>
        <OutputNameTypeCode>01</OutputNameTypeCode>
        <OutputNameTypeCode>07</OutputNameTypeCode>
      </OutputNameTypeCodes>
      <Party>
        <xsl:choose>
          <xsl:when test="$PartyTypeCount > 0">
            <PartyTypeCodes>
              <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
                <PartyTypeCode>
                  <xsl:value-of select="string(Util:getASWPartyType(@Value))"/>
                </PartyTypeCode>
              </xsl:for-each>
            </PartyTypeCodes>
            <PartySubTypeCodes>
              <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
                <PartySubTypeCode>
                  <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',@Value,'PartySubType'))"/>
                </PartySubTypeCode>
              </xsl:for-each>
            </PartySubTypeCodes>
          </xsl:when>
          <xsl:otherwise>
            <PartyTypeCodes>
              <PartyTypeCode>IND</PartyTypeCode>
              <PartyTypeCode>BUS</PartyTypeCode>
            </PartyTypeCodes>
            <PartySubTypeCodes>
              <PartySubTypeCode>IND</PartySubTypeCode>
              <PartySubTypeCode>BUS</PartySubTypeCode>
            </PartySubTypeCodes>
          </xsl:otherwise>
        </xsl:choose>
      </Party>
      <Address>
        <xsl:if test="count(SearchCriteria/PartyRecord/Locations/Location) > 0">
          <xsl:variable name="countryCode" select="string(Util:GetOneRelatedItem('DCTCountryType',LocationCountryCode,'243'))"/>
          <!--xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine1 != ''">
			  <AddressLine1>
				  <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine1"/>
			  </AddressLine1>
		  </xsl:if>
		  <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine2 != ''">
			  <AddressLine2>
				  <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine2"/>
			  </AddressLine2>
		  </xsl:if>
		  <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine3 != ''">
			  <AddressLine3>
				  <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine3"/>
			  </AddressLine3>
		  </xsl:if>
		  <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine4 != ''">
			  <AddressLine4>
				  <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine4"/>
			  </AddressLine4>
		  </xsl:if-->

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine1'"/>
            <xsl:with-param name="TagName" select="'AddressLine1'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine2'"/>
            <xsl:with-param name="TagName" select="'AddressLine2'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine3'"/>
            <xsl:with-param name="TagName" select="'AddressLine3'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'LocationDetailsLine4'"/>
            <xsl:with-param name="TagName" select="'AddressLine4'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimary'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'AdminDivisionSecondary'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'AdminDivisionTertiary'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'NationalDivisionPrimary'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'NationalDivisionSecondary'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'PostalCode'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <!--xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationPostalCode != ''">
					<PostalCode>
						<xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationPostalCode"/>
					</PostalCode>
				</xsl:if-->
          <!--Do not pass any country code if want to search on all countries-->
          <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationCountryCode != ''">
            <CountryCode>
              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',SearchCriteria/PartyRecord/Locations/Location/LocationCountryCode,'243'))"/>
            </CountryCode>
          </xsl:if>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'Latitude'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'Longitude'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>

          <xsl:call-template name="GenerateAFSFieldForAddress_Search">
            <xsl:with-param name="AFSFieldName" select="'Attention'"/>
            <xsl:with-param name="CountryCode" select="$countryCode" />
          </xsl:call-template>
        </xsl:if>
      </Address>

      <xsl:if test="SearchCriteria/PartyRecord/PartyPhones/PartyPhone/PhoneNumber != ''" >
        <Phone>
          <PhoneNumber>
            <xsl:value-of select="string(Util:FormatPhoneNumber(SearchCriteria/PartyRecord/PartyPhones/PartyPhone/PhoneNumber))"/>
          </PhoneNumber>
        </Phone>
      </xsl:if>
      <xsl:if test="SearchCriteria/PartyRecord/PartyLicenses/PartyLicense/LicenseNumber != ''" >
        <License>
          <PartyLicenseNumber>
            <xsl:value-of select="string(SearchCriteria/PartyRecord/PartyLicenses/PartyLicense/LicenseNumber)"/>
          </PartyLicenseNumber>
        </License>
      </xsl:if>
      <xsl:if test="SearchCriteria/PartyRecord/PartyReferences/PartyReference/Reference != ''">
        <Membership>
          <MembershipID>
            <xsl:value-of select="string(SearchCriteria/PartyRecord/PartyReferences/PartyReference/Reference)"/>
          </MembershipID>
          <xsl:if test="SearchCriteria/PartyRecord/PartyReferences/PartyReference/ReferenceTypeCode != ''">
            <MembershipTypeCodes>
              <MembershipTypeCode>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTReferenceType',SearchCriteria/PartyRecord/PartyReferences/PartyReference/ReferenceTypeCode,'PTYMbrshpTyp'))"/>
              </MembershipTypeCode>
            </MembershipTypeCodes>
          </xsl:if>
        </Membership>
      </xsl:if>

      <!--Party IDs, these are going to be overwritten in code by authorization interest-->
      <SearchPartyIDs>
        <SearchPartyID></SearchPartyID>
      </SearchPartyIDs>

      <!--Exclude Party-->
      <Exclude>
        <ExcludePartyIDs>
          <ExcludePartyID></ExcludePartyID>
        </ExcludePartyIDs>
        <ExcludePartyIDRelationshipTypeCodes>
          <ExcludePartyIDRelationshipTypeCode>IS</ExcludePartyIDRelationshipTypeCode>
        </ExcludePartyIDRelationshipTypeCodes>
      </Exclude>
      <NumberOfRecords>
        <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListLength,'ListLength'))"/>
      </NumberOfRecords>
      <RecordStart>
        <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListStart,'ListStart'))"/>
      </RecordStart>
      <SearchType>
        <xsl:value-of select="$SearchType" />
      </SearchType>
      <!--<AsOfDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </AsOfDate>-->
    </PartySearchInput>
  </xsl:template>

  <xsl:template name="GenerateAFSFieldForAddress_Search">
    <xsl:param name="AFSFieldName" />
    <xsl:param name="CountryCode" />
    <xsl:param name="TagName" />
    <xsl:variable name="FinalTagName">
        <xsl:choose>
            <xsl:when test="not($TagName)" >
                <xsl:value-of select="$AFSFieldName"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$TagName"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

      <xsl:call-template name="GenerateAFSField_Search">
      <xsl:with-param name="AFSFieldName" select="$AFSFieldName" />
      <xsl:with-param name="CountryCode" select="$CountryCode" />
      <xsl:with-param name="ComponentName" select="'ADDRESS'" />
      <xsl:with-param name="TagPrefix" select="''" />
      <xsl:with-param name="TagName" select="$FinalTagName" />
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="GenerateAFSField_Search">
    <xsl:param name="AFSFieldName" />
    <xsl:param name="CountryCode" />
    <xsl:param name="ComponentName" />
    <xsl:param name="TagPrefix" />
    <xsl:param name="TagName" />

    <xsl:variable name="elementName">
      <xsl:choose>
        <xsl:when test="$TagPrefix != ''" >
          <xsl:value-of select="concat($TagPrefix,':',$TagName)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$TagName"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:element name="{$elementName}">
      <xsl:variable name="valueOfElement" select="string(Util:GenerateAFSFieldWithValue(SearchCriteria/PartyRecord/Locations/Location,$AFSFieldName,$CountryCode,$ComponentName,''))" />
      <xsl:choose>
        <xsl:when test="$valueOfElement != ''">
          <xsl:value-of disable-output-escaping="no" select="$valueOfElement"/>
        </xsl:when>
      </xsl:choose>
    </xsl:element>
    <!--<xsl:value-of disable-output-escaping="yes" select="string(Util:GenerateAFSFieldWithValue(.,$AFSFieldName,$CountryCode,$ComponentName,'',$TagPrefix,$TagName))"/>-->
  </xsl:template>

</xsl:stylesheet>
