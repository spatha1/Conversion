<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:template match="/SearchRequestRecord">

    <PartySearchDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://epc.accenture.com/2013/06/26/Type">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:variable name="PartyTypeCount" select="count(SearchControl/Filters/Filter[@Type = 'PartyType'])"></xsl:variable>
      <xsl:variable name="SPName" select="string(Util:GetValueByKey('SPName'))" />

      <xsl:choose>
        <xsl:when test="$SPName = 'DC_SP_PTY_SearchPartyByPartialLastNameAndAddressComboV2'">
          <xsl:if test="count(SearchCriteria/PartyRecord/Party) &lt;= 0">
            <xsl:value-of select="string(Util:ValidateParameter('','Party',''))"/>
          </xsl:if>
          <PartyAddressSearchCriteria>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationCity != ''">
              <AdminDivisionPrimary>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationCity"/>
              </AdminDivisionPrimary>
            </xsl:if>
            <AdminDivisionSecondary i:nil="true" />
            <AdminDivisionTertiary i:nil="true" />
            <Attention i:nil="true" />
            <CountryCode i:nil="true" />
            <Latitude i:nil="true" />
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine1 != ''">
              <LocationDetailsLine1>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine1"/>
              </LocationDetailsLine1>
            </xsl:if>
            <LocationDetailsLine2 i:nil="true" />
            <LocationDetailsLine3 i:nil="true" />
            <LocationDetailsLine4 i:nil="true" />
            <Longitude i:nil="true" />

            <NationalDivisionPrimary>
              <xsl:value-of select="string(Util:ValidateParameter(Util:GetOneRelatedItem('DCTStateType',SearchCriteria/PartyRecord/Locations/Location/LocationStateCode,'240'),'State',''))"/>
            </NationalDivisionPrimary>

            <NationalDivisionSecondary i:nil="true" />
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationPostalCode != ''">
              <PostalCode>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationPostalCode"/>
              </PostalCode>
            </xsl:if>
          </PartyAddressSearchCriteria>

          <CountryCode>8A</CountryCode>

          <ExcludePartyIDRelationshipTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>IS</d2p1:string>
          </ExcludePartyIDRelationshipTypeCodes>
          <xsl:if test="SearchCriteria/PartyRecord/Party/PartyFirstName != ''">
            <FirstName>
              <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyFirstName"/>
            </FirstName>
          </xsl:if>

          <LastName>
            <xsl:value-of select="string(Util:ValidateParameter(SearchCriteria/PartyRecord/Party/PartyName,'Party Name','ZZZZNONAME'))"/>
          </LastName>


          <xsl:if test="SearchCriteria/PartyRecord/Party/PartyMiddleName != ''">
            <MiddleName>
              <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyMiddleName"/>
            </MiddleName>
          </xsl:if>

          <Name>
            <xsl:value-of select="string(Util:ValidateParameter(SearchCriteria/PartyRecord/Party/PartyName,'Party Name','ZZZZNONAME'))"/>
          </Name>

          <NumberOfRecords>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListLength,'ListLength'))"/>
          </NumberOfRecords>
          <OutputNameTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>01</d2p1:string>
            <d2p1:string>07</d2p1:string>
          </OutputNameTypeCodes>
          <PartyIDs xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">

          </PartyIDs>
          <xsl:choose>
            <xsl:when test="$PartyTypeCount > 0">
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
                  <d2p1:string>
                    <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',@Value,'8001'))"/>
                  </d2p1:string>
                </xsl:for-each>
              </PartyTypeCodes>
            </xsl:when>
            <xsl:otherwise>
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <d2p1:string>IND</d2p1:string>
                <d2p1:string>BUS</d2p1:string>

                
              </PartyTypeCodes>
            </xsl:otherwise>
          </xsl:choose>

          <RecordStart>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListStart,'ListStart'))"/>
          </RecordStart>
          <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
            <xsl:if test="@Value != ''">
              <IsAgency>
                <xsl:choose>
                  <xsl:when test="@Value = 'AG'">
                    true
                  </xsl:when>
                  <xsl:otherwise>
                    false
                  </xsl:otherwise>
                </xsl:choose>
              </IsAgency>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$SPName = 'DC_SP_PTY_SearchPartyBySoundexAndAddressV2'">
          <xsl:if test="count(SearchCriteria/PartyRecord/Party) &lt;= 0">
            <xsl:value-of select="string(Util:ValidateParameter('','Party',''))"/>
          </xsl:if>
          <PartyAddressSearchCriteria>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationCity != ''">
              <AdminDivisionPrimary>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationCity"/>
              </AdminDivisionPrimary>
            </xsl:if>
            <AdminDivisionSecondary i:nil="true" />
            <AdminDivisionTertiary i:nil="true" />
            <Attention i:nil="true" />
            <CountryCode i:nil="true" />
            <Latitude i:nil="true" />
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine1 != ''">
              <LocationDetailsLine1>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine1"/>
              </LocationDetailsLine1>
            </xsl:if>
            <LocationDetailsLine2 i:nil="true" />
            <LocationDetailsLine3 i:nil="true" />
            <LocationDetailsLine4 i:nil="true" />
            <Longitude i:nil="true" />
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationStateCode != ''">
              <NationalDivisionPrimary>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTStateType',SearchCriteria/PartyRecord/Locations/Location/LocationStateCode,'240'))"/>
              </NationalDivisionPrimary>
            </xsl:if>
            <NationalDivisionSecondary i:nil="true" />
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationPostalCode != ''">
              <PostalCode>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationPostalCode"/>
              </PostalCode>
            </xsl:if>
          </PartyAddressSearchCriteria>
          <CountryCode>8A</CountryCode>


          <ExcludePartyIDRelationshipTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>IS</d2p1:string>
          </ExcludePartyIDRelationshipTypeCodes>

          <NumberOfRecords>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListLength,'ListLength'))"/>
          </NumberOfRecords>
          <OutputNameTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>01</d2p1:string>
            <d2p1:string>07</d2p1:string>
          </OutputNameTypeCodes>
          <PartyIDs xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
          </PartyIDs>

          <xsl:choose>
            <xsl:when test="$PartyTypeCount > 0">
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
                  <d2p1:string>
                    <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',@Value,'8001'))"/>
                  </d2p1:string>
                </xsl:for-each>
              </PartyTypeCodes>
            </xsl:when>
            <xsl:otherwise>
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <d2p1:string>IND</d2p1:string>
                <d2p1:string>BUS</d2p1:string>

                
              </PartyTypeCodes>
            </xsl:otherwise>
          </xsl:choose>

          <RecordStart>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListStart,'ListStart'))"/>
          </RecordStart>


          <SoundsLikeLastName>
            <xsl:value-of select="string(Util:ValidateParameter(SearchCriteria/PartyRecord/Party/PartyName,'Party Name',''))"/>
          </SoundsLikeLastName>
          <SoundsLikeName>
            <xsl:value-of select="string(Util:ValidateParameter(SearchCriteria/PartyRecord/Party/PartyName,'Party Name',''))"/>
          </SoundsLikeName>

          <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
            <xsl:if test="@Value != ''">
              <IsAgency>
                <xsl:choose>
                  <xsl:when test="@Value = 'AG'">
                    true
                  </xsl:when>
                  <xsl:otherwise>
                    false
                  </xsl:otherwise>
                </xsl:choose>
              </IsAgency>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$SPName = 'DC_SP_PTY_SearchPartyByPhoneV2'">
          <CountryCode>8A</CountryCode>

          <ExcludePartyIDRelationshipTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>IS</d2p1:string>
          </ExcludePartyIDRelationshipTypeCodes>

          <NumberOfRecords>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListLength,'ListLength'))"/>
          </NumberOfRecords>
          <OutputNameTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>01</d2p1:string>
            <d2p1:string>07</d2p1:string>
          </OutputNameTypeCodes>
          <PartyIDs xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
          </PartyIDs>

          <xsl:choose>
            <xsl:when test="$PartyTypeCount > 0">
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
                  <d2p1:string>
                    <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',@Value,'8001'))"/>
                  </d2p1:string>
                </xsl:for-each>
              </PartyTypeCodes>
            </xsl:when>
            <xsl:otherwise>
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <d2p1:string>IND</d2p1:string>
                <d2p1:string>BUS</d2p1:string>

                
              </PartyTypeCodes>
            </xsl:otherwise>
          </xsl:choose>

          <PhoneNumber>
            <xsl:value-of select="string(Util:FormatPhoneNumber(Util:ValidateParameter(SearchCriteria/PartyRecord/PartyPhones/PartyPhone/PhoneNumber,'Phone Number','')))"/>
          </PhoneNumber>

          <RecordStart>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListStart,'ListStart'))"/>
          </RecordStart>
          <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
            <xsl:if test="@Value != ''">
              <IsAgency>
                <xsl:choose>
                  <xsl:when test="@Value = 'AG'">
                    true
                  </xsl:when>
                  <xsl:otherwise>
                    false
                  </xsl:otherwise>
                </xsl:choose>
              </IsAgency>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$SPName = 'DC_SP_PTY_SearchPartyByLicenseV2'">
          <CountryCode>8A</CountryCode>

          <ExcludePartyIDRelationshipTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>IS</d2p1:string>
          </ExcludePartyIDRelationshipTypeCodes>
          <NumberOfRecords>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListLength,'ListLength'))"/>
          </NumberOfRecords>
          <OutputNameTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>01</d2p1:string>
            <d2p1:string>07</d2p1:string>
          </OutputNameTypeCodes>
          <PartyIDs xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">

          </PartyIDs>

          <PartyLicenseNumber>
            <xsl:value-of select="string(Util:ValidateParameter(SearchCriteria/PartyRecord/PartyLicenses/PartyLicense/LicenseNumber,'License Number',''))"/>
          </PartyLicenseNumber>

          <xsl:choose>
            <xsl:when test="$PartyTypeCount > 0">
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
                  <d2p1:string>
                    <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',@Value,'8001'))"/>
                  </d2p1:string>
                </xsl:for-each>
              </PartyTypeCodes>
            </xsl:when>
            <xsl:otherwise>
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <d2p1:string>IND</d2p1:string>
                <d2p1:string>BUS</d2p1:string>

                

              </PartyTypeCodes>
            </xsl:otherwise>
          </xsl:choose>
          <RecordStart>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListStart,'ListStart'))"/>
          </RecordStart>
          <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
            <xsl:if test="@Value != ''">
              <IsAgency>
                <xsl:choose>
                  <xsl:when test="@Value = 'AG'">
                    true
                  </xsl:when>
                  <xsl:otherwise>
                    false
                  </xsl:otherwise>
                </xsl:choose>
              </IsAgency>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$SPName = 'DC_SP_PTY_SearchPartyByReferenceV2'">
          <CountryCode>8A</CountryCode>

          <ExcludePartyIDRelationshipTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>IS</d2p1:string>
          </ExcludePartyIDRelationshipTypeCodes>

          <MembershipID>
            <xsl:value-of select="string(Util:ValidateParameter(SearchCriteria/PartyRecord/PartyReferences/PartyReference/Reference,'Reference',''))"/>
          </MembershipID>

          <NumberOfRecords>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListLength,'ListLength'))"/>
          </NumberOfRecords>
          <OutputNameTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>01</d2p1:string>
            <d2p1:string>07</d2p1:string>
          </OutputNameTypeCodes>

          <PartyIDs xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
          </PartyIDs>

          <xsl:choose>
            <xsl:when test="$PartyTypeCount > 0">
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
                  <d2p1:string>
                    <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',@Value,'8001'))"/>
                  </d2p1:string>
                </xsl:for-each>
              </PartyTypeCodes>
            </xsl:when>
            <xsl:otherwise>
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <d2p1:string>IND</d2p1:string>
                <d2p1:string>BUS</d2p1:string>

                
              </PartyTypeCodes>
            </xsl:otherwise>
          </xsl:choose>
          <RecordStart>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListStart,'ListStart'))"/>
          </RecordStart>

          <xsl:if test="SearchCriteria/PartyRecord/PartyReferences/PartyReference/ReferenceTypeCode != ''">
            <MembershipTypeCode xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">

              <d2p1:string>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTReferenceType',SearchCriteria/PartyRecord/PartyReferences/PartyReference/ReferenceTypeCode,'PTYMbrshpTyp'))"/>
              </d2p1:string>

            </MembershipTypeCode>
          </xsl:if>
          <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
            <xsl:if test="@Value != ''">
              <IsAgency>
                <xsl:choose>
                  <xsl:when test="@Value = 'AG'">
                    true
                  </xsl:when>
                  <xsl:otherwise>
                    false
                  </xsl:otherwise>
                </xsl:choose>
              </IsAgency>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="$SPName = 'DC_SP_PTY_SearchPartyGenericV2'">
          <xsl:if test="count(SearchCriteria/PartyRecord/Party) &lt;= 0">
            <xsl:value-of select="string(Util:ValidateParameter('','Party',''))"/>
          </xsl:if>
          <PartyAddressSearchCriteria>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationCity != ''">
              <AdminDivisionPrimary>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationCity"/>
              </AdminDivisionPrimary>
            </xsl:if>
            <AdminDivisionSecondary i:nil="true" />
            <AdminDivisionTertiary i:nil="true" />
            <Attention i:nil="true" />
            <CountryCode i:nil="true" />
            <Latitude i:nil="true" />
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine1 != ''">
              <LocationDetailsLine1>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationAddressLine1"/>
              </LocationDetailsLine1>
            </xsl:if>
            <LocationDetailsLine2 i:nil="true" />
            <LocationDetailsLine3 i:nil="true" />
            <LocationDetailsLine4 i:nil="true" />
            <Longitude i:nil="true" />
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationStateCode != ''">
              <NationalDivisionPrimary>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTStateType',SearchCriteria/PartyRecord/Locations/Location/LocationStateCode,'240'))"/>
              </NationalDivisionPrimary>
            </xsl:if>
            <NationalDivisionSecondary i:nil="true" />
            <xsl:if test="SearchCriteria/PartyRecord/Locations/Location/LocationPostalCode != ''">
              <PostalCode>
                <xsl:value-of select="SearchCriteria/PartyRecord/Locations/Location/LocationPostalCode"/>
              </PostalCode>
            </xsl:if>
          </PartyAddressSearchCriteria>

          <CountryCode>8A</CountryCode>
          <xsl:if test="SearchCriteria/PartyRecord/Party/PartyBirthDate != ''">
            <DateOfBirth>
              <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyBirthDate"/>
            </DateOfBirth>
          </xsl:if>

          <ExcludePartyIDRelationshipTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>IS</d2p1:string>
          </ExcludePartyIDRelationshipTypeCodes>
          <xsl:if test="SearchCriteria/PartyRecord/Party/PartyFirstName != ''">
            <FirstName>
              <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyFirstName"/>
            </FirstName>
          </xsl:if>

          <LastName>
            <xsl:value-of select="string(Util:ValidateParameter(SearchCriteria/PartyRecord/Party/PartyName,'Party Name','ZZZZNONAME'))"/>
          </LastName>

          <xsl:if test="SearchCriteria/PartyRecord/Party/PartyMiddleName != ''">
            <MiddleName>
              <xsl:value-of select="SearchCriteria/PartyRecord/Party/PartyMiddleName"/>
            </MiddleName>
          </xsl:if>

          <Name>
            <xsl:value-of select="string(Util:ValidateParameter(SearchCriteria/PartyRecord/Party/PartyName,'Party Name','ZZZZNONAME'))"/>
          </Name>

          <NumberOfRecords>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListLength,'ListLength'))"/>
          </NumberOfRecords>
          <OutputNameTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
            <d2p1:string>01</d2p1:string>
            <d2p1:string>07</d2p1:string>
          </OutputNameTypeCodes>

          <PartyIDs xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">

          </PartyIDs>

          <xsl:choose>
            <xsl:when test="$PartyTypeCount > 0">
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
                  <d2p1:string>
                    <xsl:value-of select="string(Util:GetOneRelatedItem('DCTPartyType',@Value,'8001'))"/>
                  </d2p1:string>
                </xsl:for-each>
              </PartyTypeCodes>
            </xsl:when>
            <xsl:otherwise>
              <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
                <d2p1:string>IND</d2p1:string>
                <d2p1:string>BUS</d2p1:string>

                
              </PartyTypeCodes>
            </xsl:otherwise>
          </xsl:choose>
          <RecordStart>
            <xsl:value-of select="string(Util:GetListStartEndForSearch(SearchControl/Paging/ListStart,'ListStart'))"/>
          </RecordStart>
          <xsl:for-each select="SearchControl/Filters/Filter[@Type = 'PartyType']">
            <xsl:if test="@Value != ''">
              <IsAgency>
                <xsl:choose>
                  <xsl:when test="@Value = 'AG'">
                    true
                  </xsl:when>
                  <xsl:otherwise>
                    false
                  </xsl:otherwise>
                </xsl:choose>
              </IsAgency>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
      </xsl:choose>

      <!--<AddressSearchCriteria>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <AdminDivisionPrimary i:nil="true" />
        <AdminDivisionSecondary i:nil="true" />
        <AdminDivisionTertiary i:nil="true" />
        <Attention i:nil="true" />
        <CountryCode i:nil="true" />
        <Latitude i:nil="true" />
        <LocationDetailsLine1 i:nil="true" />
        <LocationDetailsLine2 i:nil="true" />
        <LocationDetailsLine3 i:nil="true" />
        <LocationDetailsLine4 i:nil="true" />
        <Longitude i:nil="true" />
        <NationalDivisionPrimary i:nil="true" />
        <NationalDivisionSecondary i:nil="true" />
        <PostalCode i:nil="true" />
      </AddressSearchCriteria>

      <CountryCode>8A</CountryCode>
      <DateOfBirth></DateOfBirth>
      
      <ExcludePartyIDRelationshipTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
        <d2p1:string>IS</d2p1:string>
      </ExcludePartyIDRelationshipTypeCodes>
      <FirstName></FirstName>
      <LastName></LastName>
      <MembershipID></MembershipID>
      <MiddleName></MiddleName>
      <Name></Name>
      <NumberOfRecords>100</NumberOfRecords>
      <OutputNameTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
        <d2p1:string>01</d2p1:string>
        <d2p1:string>07</d2p1:string>
      </OutputNameTypeCodes>
      <PartyIDs xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
        <d2p1:string>2680A8702B78D7A2</d2p1:string>
        <d2p1:string>359CE5FBBA4DED10</d2p1:string>
      </PartyIDs>
      <PartyLicenseNumber></PartyLicenseNumber>
      <PartyTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
        <d2p1:string>IND</d2p1:string>
        <d2p1:string>BUS</d2p1:string>
      </PartyTypeCodes>
      <PhoneNumber></PhoneNumber>
      <RecordStart>1</RecordStart>
      <SoundsLikeLastName></SoundsLikeLastName>
      <SoundsLikeName></SoundsLikeName>-->
    </PartySearchDTO>
  </xsl:template>
</xsl:stylesheet>


