<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="PartyLocationTemplate_DuckToASW.xslt"/>
  <xsl:import href="CorrectPartyLocationTemplate_DuckToAsw.xslt"/>
  <xsl:import href="PartyEmailTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyPhoneTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyIndNameTemplate_DuckToASW.xslt"/>
  <xsl:import href="PartyBusNameTemplate_DuckToASW.xslt"/>
  <xsl:import href="CommonTemplates.xslt"/>

  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes" />

  <xsl:variable name="TransactionDate" select="string(Util:GetValueByKey('TransactionDate'))" />
  <xsl:variable name="AFSCurrentDate" select="string(Util:GetValueByKey('AFSCurrentDate'))" />
  <xsl:variable name="BASEPARTYTYPEIND" select="string(Util:GetValueByKey('BASEPARTYTYPEIND'))" />
  <xsl:variable name="BASEPARTYTYPEBUS" select="string(Util:GetValueByKey('BASEPARTYTYPEBUS'))" />
  <xsl:variable name="updatePartyNameRecord" select="string(Util:GetValueByKey('updatePartyNameRecord'))" />
  <xsl:variable name="updateOtherNameRecord" select="string(Util:GetValueByKey('updateOtherNameRecord'))" />
  <xsl:variable name="updatePhonePrimaryRecord" select="string(Util:GetValueByKey('updatePhonePrimaryRecord'))" />
  <xsl:variable name="updatePhoneFaxRecord" select="string(Util:GetValueByKey('updatePhoneFaxRecord'))" />
  <xsl:variable name="updateEmailRecord" select="string(Util:GetValueByKey('updateEmailRecord'))" />
  <xsl:variable name="updateLocationRecord" select="string(Util:GetValueByKey('updateLocationRecord'))" />

  <xsl:variable name="PartyType" select="string(Util:getBasePartyTypeFromASWPartyType(/PartyData/PartyDetailDTO/PartyType))" />

  <xsl:variable name="PartyId" select="/PartyData/PartyRecord/PartyRecordPartyId" />
  <xsl:variable name="PartyComments" select="/PartyData/PartyRecord/Party/PartyComments" />
  <xsl:variable name="PartyBirthDate" select="/PartyData/PartyRecord/Party/PartyBirthDate" />
  <xsl:variable name="PartyDeathDate" select="/PartyData/PartyRecord/Party/PartyDeathDate" />
  <xsl:variable name="PartyGenderCode" select="/PartyData/PartyRecord/Party/PartyGenderCode" />
  <xsl:variable name="PartyMaritalStatusCode" select="/PartyData/PartyRecord/Party/PartyMaritalStatusCode" />
  <xsl:variable name="PartyPreferredLanguageCode" select="/PartyData/PartyRecord/Party/PartyPreferredLanguageCode" />
  <xsl:variable name="PartyNumberOfDependents" select="/PartyData/PartyRecord/Party/PartyNumberOfDependents" />
  <xsl:variable name="PreferredContactMethod" select="/PartyData/PartyRecord/Party/PreferredContactMethod" />
  <xsl:variable name="PartyProfession" select="/PartyData/PartyRecord/Party/PartyProfession" />
  <xsl:variable name="PartyTaxId" select="/PartyData/PartyRecord/Party/PartyTaxId" />
  <xsl:variable name="PartyTaxId2" select="/PartyData/PartyRecord/Party/PartyTaxId2" />  <!--#5814-Added for nzbn mapping  -->
  <xsl:variable name="PartyIsCompanyPersonnel" select="/PartyData/PartyRecord/Party/PartyIsCompanyPersonnel" />
  <xsl:variable name="PartySupplier" select="/PartyData/PartyRecord/Party/PartySupplier" />
  <xsl:variable name="PartyOFACCheckNotRequired" select="/PartyData/PartyRecord/Party/PartyOFACCheckNotRequired" />
  <xsl:variable name="replaceContact" select="/PartyData/PartyRecord/Party/ReplaceContactInfo" />
  <xsl:variable name="PartyCountryCode" select="/PartyData/PartyRecord/Party/PartyCountryCode" />
  <xsl:variable name="PartyNameCountryCode" select="/PartyData/PartyRecord/Party/PartyNameCountryCode" />
  <xsl:variable name="PartyTimeZone" select="/PartyData/PartyRecord/Party/PartyTimeZone" />



  <xsl:variable name="firstName" select="/PartyData/PartyRecord/Party/PartyFirstName" />
  <xsl:variable name="middleName" select="/PartyData/PartyRecord/Party/PartyMiddleName" />
  <xsl:variable name="lastName" select="/PartyData/PartyRecord/Party/PartyName" />
  <xsl:variable name="partyCorrespondenceName" select="/PartyData/PartyRecord/Party/PartyCorrespondenceName" />
  <xsl:variable name="partyLegacyName" select="/PartyData/PartyRecord/Party/PartyLegacyName" />
  <xsl:variable name="prefixCode" select="/PartyData/PartyRecord/Party/PartyNamePrefixCode" />
  <xsl:variable name="suffixCode" select="/PartyData/PartyRecord/Party/PartyNameSuffixCode" />
  <xsl:variable name="partySubTypeCode" select="/PartyData/PartyRecord/Party/PartySubTypeCode" />
  <!--<xsl:variable name="extendedData" select="/PartyData/PartyRecord/Party/PartyExtendedData" />-->
  <xsl:variable name="PartyNameEffDate" select="/PartyData/PartyRecord/Party/PartyNameEffectiveDate" />
  <xsl:variable name="PartyNameExpDate" select="/PartyData/PartyRecord/Party/PartyNameExpirationDate" />
  <xsl:variable name="PartyNameComments" select="/PartyData/PartyRecord/Party/PartyNameComments" />
  <xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
  <xsl:variable name="personFullName" select="/PartyData/PartyRecord/Party/CalculatePersonFullName" />

  <xsl:variable name="ACHPartyExternalId" select="/PartyData/PartyRecord/Party/ACHPartyExternalId" />
  <xsl:variable name="PartyExternalId" select="/PartyData/PartyRecord/Party/ExternalId" />

  <xsl:variable name="externalPartyNameId" select="/PartyData/PartyRecord/Party/ExternalPartyNameId" />

  <!--<xsl:template match="/PartyData" xmlns="Party.Types">-->
  <xsl:template match="/PartyData" xmlns="Party.Types">
    <xsl:choose>
      <xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
        <xsl:call-template name="UpdatePartyIndividual" />
      </xsl:when>
      <xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
        <xsl:call-template name="UpdatePartyBus" />
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="UpdatePartyIndividual" xmlns="Party.Types">
    <PartyIndividualBulkDetailsDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" >
      <!-- Party Details -->
      <Party>
        <ACHPartyExternalID>
          <xsl:value-of select="$ACHPartyExternalId"/>
        </ACHPartyExternalID>
        <BusinessPermitted>
          <xsl:value-of select="$PartyOFACCheckNotRequired"/>
        </BusinessPermitted>
        <CountryCode>
          <xsl:choose>
            <xsl:when test="$PartyCountryCode !=''">
              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',$PartyCountryCode,'243'))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/CountryCode"/>
            </xsl:otherwise>
          </xsl:choose>
        </CountryCode>

        <xsl:choose>
          <xsl:when test="$PartyExternalId != '' or count(/PartyData/PartyRecord/Party/ExternalId) > 0">
            <ExternalID>
              <xsl:value-of select="$PartyExternalId"/>
            </ExternalID>
          </xsl:when>
          <xsl:otherwise>
            <ExternalID>
              <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/ExternalID"/>
            </ExternalID>
          </xsl:otherwise>
        </xsl:choose>
        <!--        <ExternalID>
          <xsl:value-of select="$PartyExternalId"/>
        </ExternalID>-->
        <GeographicFormatCode>
          <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/GeographicFormatCode"/>
        </GeographicFormatCode>
        <IsInActive>
          <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/IsInActive"/>
        </IsInActive>
        <xsl:choose>
          <xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/Party/LastTransactionID) > 0">
            <LastTransactionID>
              <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/LastTransactionID"/>
            </LastTransactionID>
          </xsl:when>
          <xsl:otherwise>
            <LastTransactionID i:nil="true" />
          </xsl:otherwise>
        </xsl:choose>
        <LastUpdatedDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>
        <Number>
          <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/Number"/>
        </Number>
        <PartyID>
          <xsl:value-of select="$PartyId"/>
        </PartyID>
        <PartyTypeCode>
          <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/PartyTypeCode"/>
        </PartyTypeCode>
        <PartySubTypeCode>
          <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/PartySubTypeCode"/>
        </PartySubTypeCode>
		<xsl:if test="string(Util:ShowPartyTimeZone($PartyTimeZone)) != ''">
      <PartyTimeZone>
        <xsl:value-of select="string(Util:GetOneRelatedItem('DCTTimeZones',$PartyTimeZone,'TimeZones'))"/>
			</PartyTimeZone>
		</xsl:if>
        <!--<SkipLoadingExtendedData>
					<xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/SkipLoadingExtendedData"/>
				</SkipLoadingExtendedData>-->
        <!--<xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/Party">
					<xsl:call-template name="ExtendedData">
						<xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>
						<xsl:with-param name="AswTagName">IndividualExtendedData</xsl:with-param>
						<xsl:with-param name="PhysicalTableName">PARTY_INDVDL</xsl:with-param>
						<xsl:with-param name="LogicalTableName">lgclPartyIndv</xsl:with-param>
						<xsl:with-param name="LogicalColumnName">PartyIndExtData</xsl:with-param>
					</xsl:call-template>
				</xsl:for-each>-->
      </Party>
      <PartyAddressesToDelete i:nil="true" />
      <xsl:choose>
        <xsl:when test="$updateLocationRecord = 'True' and count(/PartyData/PartyRecord/Locations/Location) > 0">
          <xsl:choose>
            <xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO) = 0">
              <xsl:for-each select="/PartyData/PartyRecord">
                <PartyAddressesToInsert>
                  <xsl:call-template name="partyLocationExtendedData" />
                </PartyAddressesToInsert>
              </xsl:for-each>
              <PartyAddressesToUpdate i:nil="true" />
            </xsl:when>
            <xsl:otherwise>
              <PartyAddressesToInsert i:nil="true" />

              <xsl:for-each select="/PartyData">
                <PartyAddressesToUpdate>
                  <xsl:call-template name="CorrectPartyLocation_Ind" />
                </PartyAddressesToUpdate>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <PartyAddressesToInsert i:nil="true" />
          <PartyAddressesToUpdate i:nil="true" />
        </xsl:otherwise>
      </xsl:choose>

      <PartyAgent i:nil="true" />

      <xsl:if test="$PartyComments != '' or count(PartyDetailDTO/PartyIndividualDetail/PartyComment/Comment) > 0">
        <PartyComment>
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>

          <xsl:choose>
            <xsl:when test="count($PartyComments) = 0 and count(PartyDetailDTO/PartyIndividualDetail/PartyComment/Comment)>0">
              <Comment>
                <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyComment/Comment"/>
              </Comment>
            </xsl:when>
            <xsl:when test="$PartyComments = ''">
              <Comment i:nil="true"/>
            </xsl:when>
            <xsl:otherwise>
              <Comment>
                <xsl:value-of select="$PartyComments"/>
              </Comment>
            </xsl:otherwise>
          </xsl:choose>

          <EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </EffectiveDate>
          <ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </ExpirationDate>
          <xsl:choose>
            <xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyComment/LastTransactionID) > 0">
              <LastTransactionID>
                <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyComment/LastTransactionID"/>
              </LastTransactionID>
            </xsl:when>
            <xsl:otherwise>
              <LastTransactionID i:nil="true" />
            </xsl:otherwise>
          </xsl:choose>

          <LastUpdatedDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </LastUpdatedDate>
          <PartyID>
            <xsl:value-of select="$PartyId"/>
          </PartyID>
        </PartyComment>
      </xsl:if>
      <PartyEmailsToDelete i:nil="true" />

      <xsl:choose>
        <xsl:when test="$updateEmailRecord = 'True'  and count(/PartyData/PartyRecord/PartyEmails/PartyEmail) > 0">
          <xsl:for-each select="/PartyData/PartyRecord">
            <PartyEmailsToInsert>
              <xsl:for-each select="./PartyEmails/PartyEmail">
                <xsl:if test="count(PartyEmailId) = 0 or PartyEmailId = ''">
                  <xsl:call-template name="partyEmailInsert" />
                </xsl:if>
              </xsl:for-each>
            </PartyEmailsToInsert>
            
            <xsl:choose>
              <xsl:when test="count(./PartyEmails/PartyEmail[PartyEmailId != '']) > 0">
                <PartyEmailsToUpdate>
                  <xsl:for-each select="./PartyEmails/PartyEmail[PartyEmailId != '']">
                    <PartyEmailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
                      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                      <xsl:call-template name ="commonEmailFields" />
                    </PartyEmailDTO>
                  </xsl:for-each>
                </PartyEmailsToUpdate>
              </xsl:when>
            </xsl:choose>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <PartyEmailsToInsert i:nil="true" />
          <PartyEmailsToUpdate i:nil="true" />
        </xsl:otherwise>
      </xsl:choose>

      <xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyIndividual">
        <PartyIndividual>
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
          <xsl:choose>
            <!--xsl:when test="string($PartyBirthDate) = ''"-->
            <xsl:when test="count(../../../PartyRecord/Party/PartyBirthDate) = 0">
              <xsl:choose>
                <xsl:when test ="DateOfBirth !=''">
                  <DateOfBirth>
                    <xsl:value-of select="string(Util:GetDateTimeWithDefault(DateOfBirth))"/>
                  </DateOfBirth>
                </xsl:when>
                <xsl:otherwise>
                  <DateOfBirth i:nil="true"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <DateOfBirth>
                <xsl:value-of select="string(Util:GetDateTimeWithDefault($PartyBirthDate))"/>
              </DateOfBirth>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:choose>
            <xsl:when test="count($PartyDeathDate) = 0 and DateOfDeath =''">
              <DateOfDeath i:nil="true"/>
            </xsl:when>
            <xsl:when test="count($PartyDeathDate) = 0 and DateOfDeath !=''">
              <DateOfDeath>
                <xsl:value-of select="string(Util:ConvertDateToAswFormat(Util:GetDateTimeWithDefault(DateOfDeath)))"/>
              </DateOfDeath>
            </xsl:when>
            <xsl:when test="$PartyDeathDate = ''">
              <DateOfDeath i:nil="true"/>
            </xsl:when>
            <xsl:otherwise>
              <DateOfDeath>
                <xsl:value-of select="string(Util:ConvertDateToAswFormat(Util:GetDateTimeWithDefault($PartyDeathDate)))"/>
              </DateOfDeath>
            </xsl:otherwise>
          </xsl:choose>

          <EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(EffectiveDate))"/>
          </EffectiveDate>
          <ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(ExpirationDate))"/>
          </ExpirationDate>
          <xsl:choose>
            <xsl:when test="$MethodName = 'SetPartyClientDetails'">
              <GenderCode>
                <xsl:value-of select="$PartyGenderCode"/>
              </GenderCode>
            </xsl:when>
            <xsl:otherwise>
              <GenderCode>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTGender',$PartyGenderCode,'51'))"/>
              </GenderCode>
            </xsl:otherwise>
          </xsl:choose>

          <IsAgent>
            <xsl:value-of select="IsAgent"/>
          </IsAgent>

          <xsl:choose>
            <xsl:when test="count($PartyIsCompanyPersonnel) = 0">
              <IsCompanyPersonnel>
                <xsl:value-of select="IsCompanyPersonnel"/>
              </IsCompanyPersonnel>
            </xsl:when>
            <xsl:when test="$PartyIsCompanyPersonnel !=''">
              <IsCompanyPersonnel>
                <xsl:value-of select="$PartyIsCompanyPersonnel"/>
              </IsCompanyPersonnel>
            </xsl:when>
            <xsl:otherwise>
              <IsCompanyPersonnel>0</IsCompanyPersonnel>
            </xsl:otherwise>
          </xsl:choose>

          <LastTransactionID>
            <xsl:value-of select="LastTransactionID"/>
          </LastTransactionID>
          <LastUpdatedDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </LastUpdatedDate>
          <xsl:choose>
            <xsl:when test="$MethodName = 'SetPartyClientDetails'">
              <MaritalStatusCode>
                <xsl:value-of select="$PartyMaritalStatusCode"/>
              </MaritalStatusCode>
            </xsl:when>
            <xsl:otherwise>
              <MaritalStatusCode>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTMaritalStatus',$PartyMaritalStatusCode,'35'))"/>
              </MaritalStatusCode>
            </xsl:otherwise>
          </xsl:choose>

          <NationalID i:nil="true" />

          <xsl:choose>
            <xsl:when test="count($PartyNumberOfDependents) = 0 and NumberOfDependents != ''">
              <NumberOfDependents>
                <xsl:value-of select="NumberOfDependents"/>
              </NumberOfDependents>
            </xsl:when>
            <xsl:when test="NumberOfDependents = ''">
              <NumberOfDependents>0</NumberOfDependents>
            </xsl:when>
            <xsl:when test="$PartyNumberOfDependents !=''">
              <NumberOfDependents>
                <xsl:value-of select="$PartyNumberOfDependents"/>
              </NumberOfDependents>
            </xsl:when>
            <xsl:otherwise>
              <NumberOfDependents>0</NumberOfDependents>
            </xsl:otherwise>
          </xsl:choose>

          <PartyID>
            <xsl:value-of select="PartyID"/>
          </PartyID>

          <xsl:choose>
            <xsl:when test="count($PreferredContactMethod) = 0 and count(PreferredContactType)>0">
              <PreferredContactType>
                <xsl:value-of select="PreferredContactType"/>
              </PreferredContactType>
            </xsl:when>
            <xsl:when test="$PreferredContactMethod = ''">
              <PreferredContactType i:nil="true"/>
            </xsl:when>
            <xsl:otherwise>
              <PreferredContactType>
                <xsl:value-of select="$PreferredContactMethod"/>
              </PreferredContactType>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:choose>
            <xsl:when test="$MethodName = 'SetPartyClientDetails'">
              <PreferredLanguage>
                <xsl:value-of select="$PartyPreferredLanguageCode"/>
              </PreferredLanguage>
            </xsl:when>
            <xsl:otherwise>
              <PreferredLanguage>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTLanguageType',$PartyPreferredLanguageCode,'8037'))"/>
              </PreferredLanguage>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:choose>
            <xsl:when test="count($PartyProfession) = 0">
              <ProfessionCode>
                <xsl:value-of select="ProfessionCode"/>
              </ProfessionCode>
            </xsl:when>
            <xsl:otherwise>
              <ProfessionCode>
                <xsl:value-of select="$PartyProfession"/>
              </ProfessionCode>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:choose>
            <xsl:when test="count($PartyTaxId) = 0">
              <SpecificPurposeID>
                <xsl:value-of select="SpecificPurposeID"/>
              </SpecificPurposeID>
            </xsl:when>
            <xsl:when test="string($PartyTaxId) = ''">
              <SpecificPurposeID i:nil="true" />
            </xsl:when>
            <xsl:otherwise>
              <SpecificPurposeID>
                <xsl:value-of select="string(Util:GetSSNForASW($PartyTaxId))"/>
              </SpecificPurposeID>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:choose>
            <xsl:when test="$MethodName = 'SetPartyClientDetails'">

              <!-- <xsl:copy-of select="/PartyData/PartyDetailDTO/PartyIndividualDetail/PartyIndividual/IndividualExtendedData" xmlns="Party.Types" /> -->

              <!--<IndividualExtendedData>
								<xsl:apply-templates mode="copy" select="IndividualExtendedData/*" />
							</IndividualExtendedData>-->

              <xsl:if test="/PartyData/PartyDetailDTO/PartyIndividualDetail/PartyIndividual/IndividualExtendedData/ExtendedFields/ExtendedFieldDTO/XMLValue/PartyExtendedData != ''">
                <xsl:call-template name="ExtendedDataOurs">
                  <xsl:with-param name="ExtDataPath" select="/PartyData/PartyDetailDTO/PartyIndividualDetail/PartyIndividual/IndividualExtendedData/ExtendedFields/ExtendedFieldDTO/XMLValue/PartyExtendedData" />
                  <xsl:with-param name="AswTagName">IndividualExtendedData</xsl:with-param>
                  <xsl:with-param name="PhysicalTableName">PARTY_INDVDL</xsl:with-param>
                  <xsl:with-param name="LogicalTableName">lgclPartyIndv</xsl:with-param>
                  <xsl:with-param name="LogicalColumnName">PartyIndExtData</xsl:with-param>
                </xsl:call-template>
              </xsl:if>


            </xsl:when>
            <xsl:otherwise>
              <xsl:for-each select="/PartyData/PartyRecord/Party">
                <xsl:call-template name="ExtendedData">
                  <xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>
				  <xsl:with-param name="SuiteTagName">PartyIndividualSuiteExtendedData</xsl:with-param>
                  <xsl:with-param name="AswTagName">IndividualExtendedData</xsl:with-param>
                  <xsl:with-param name="PhysicalTableName">PARTY_INDVDL</xsl:with-param>
                  <xsl:with-param name="LogicalTableName">lgclPartyIndv</xsl:with-param>
                  <xsl:with-param name="LogicalColumnName">PartyIndExtData</xsl:with-param>
                </xsl:call-template>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>

        </PartyIndividual>
      </xsl:for-each>

      <PartyIndNamesToDelete i:nil="true" />
      <xsl:choose>
        <xsl:when test="$updatePartyNameRecord = 'True' or $updateOtherNameRecord = 'True'">
          <PartyIndNamesToInsert>
            <xsl:if test="$updatePartyNameRecord = 'True'">
              <xsl:if test="count(PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '07']) = 0">
                <PartyIndNameDetailWithExtendedDataDTO>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <PartyIndName>
                    <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                     <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>
                    <FirstName>
                      <xsl:value-of select="$firstName"/>
                    </FirstName>
                    <FirstNamePhonetic i:nil="true" />
                    <FirstNameSoundex i:nil="true" />
                    <FirstNameUpperCase i:nil="true" />
                    <FullName>
                      <xsl:choose>
                        <xsl:when test ="$personFullName !=''">
                          <xsl:value-of select="$personFullName"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat(string(Util:GetOneRelatedItem('DCTNamePrefix',$prefixCode,'34')),' ', $firstName,' ', $middleName,' ', $lastName,' ', string(Util:GetOneRelatedItem('DCTNameSuffix',$suffixCode,'48')))"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </FullName>
                    <LastName>
                      <xsl:value-of select="$lastName"/>
                    </LastName>
                    <LastNamePhonetic i:nil="true" />
                    <LastNameSoundex i:nil="true" />
                    <LastNameUpperCase i:nil="true" />
                    <!--<LastTransactionID>3106d0f4cb1540c38c2e39b831e58848:1</LastTransactionID>-->
                    <LastUpdatedDate>
                      <xsl:value-of select="string(Util:GetCurrentDate())"/>
                    </LastUpdatedDate>
                    <MiddleName>
                      <xsl:value-of select="$middleName"/>
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

                  <!--<ExtendedData>Party Name Extended data</ExtendedData>-->
                  <xsl:call-template name="InsertPartyName" />

                </PartyIndNameDetailWithExtendedDataDTO>
              </xsl:if>

              <xsl:if test="count(PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '06']) = 0">
                <PartyIndNameDetailWithExtendedDataDTO>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>

                  <!--<ExtendedData>Party Individual Name Extended data</ExtendedData>-->
                  <PartyIndName>
                    <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                     <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>
                    <FirstName>
                      <xsl:value-of select="$firstName"/>
                    </FirstName>
                    <FirstNamePhonetic i:nil="true" />
                    <FirstNameSoundex i:nil="true" />
                    <FirstNameUpperCase i:nil="true" />
                    <FullName>
                      <xsl:choose>
                        <xsl:when test ="$personFullName !=''">
                          <xsl:value-of select="$personFullName"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat(string(Util:GetOneRelatedItem('DCTNamePrefix',$prefixCode,'34')),' ', $firstName,' ', $middleName,' ', $lastName,' ', string(Util:GetOneRelatedItem('DCTNameSuffix',$suffixCode,'48')))"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </FullName>
                    <LastName>
                      <xsl:value-of select="$lastName"/>
                    </LastName>
                    <LastNamePhonetic i:nil="true" />
                    <LastNameSoundex i:nil="true" />
                    <LastNameUpperCase i:nil="true" />

                    <LastUpdatedDate>
                      <xsl:value-of select="string(Util:GetCurrentDate())"/>
                    </LastUpdatedDate>
                    <MiddleName>
                      <xsl:value-of select="$middleName"/>
                    </MiddleName>
                    <MiddleNamePhonetic i:nil="true" />
                    <MiddleNameSoundex i:nil="true" />
                    <MiddleNameUpperCase i:nil="true" />
                    <NameTypeCode>06</NameTypeCode>
                    <PrefixCode>
                      <!--<xsl:value-of select="Party/PartyNamePrefixCode"/>-->
                    </PrefixCode>
                    <SuffixCode>
                      <!--<xsl:value-of select="Party/PartyNameSuffixCode"/>-->
                    </SuffixCode>
                  </PartyIndName>


                  <!--<ExtendedData>Party Name Extended data</ExtendedData>-->
                  <xsl:call-template name="InsertPartyName" />

                </PartyIndNameDetailWithExtendedDataDTO>
              </xsl:if>
            </xsl:if>

            <xsl:if test="$updateOtherNameRecord = 'True'">
              <xsl:if test="count(PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '04']) = 0">
                <xsl:for-each select="PartyRecord">
                  <xsl:call-template name="partyIndNameExtData" />
                </xsl:for-each>
              </xsl:if>
            </xsl:if>
          </PartyIndNamesToInsert>
          <PartyIndNamesToUpdate>
            <xsl:if test="$updatePartyNameRecord = 'True'">
              <xsl:if test="string($replaceContact) != 'Y'">
                <xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyName/IsDefault = 'true']">
                  <xsl:if test ="string(PartyIndName/FirstName) != string($firstName) 
								or string(PartyIndName/MiddleName) != string($middleName)
								or string(PartyIndName/LastName) !=  string($lastName) 
								or string(PartyIndName/PrefixCode) !=  string(Util:GetOneRelatedItem('DCTNamePrefix',$prefixCode,'34'))
								or string(PartyIndName/SuffixCode) !=  string(Util:GetOneRelatedItem('DCTNameSuffix',$suffixCode,'48'))
                or string(PartyIndName/Comment) !=  string($PartyNameComments)">
                    <PartyIndNameDetailDTO>
                      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                      <PartyIndName>
                        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                        <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>
                        <FirstName>
                          <xsl:value-of select="$firstName"/>
                        </FirstName>
                        <FirstNamePhonetic i:nil="true" />
                        <FirstNameSoundex i:nil="true" />
                        <FirstNameUpperCase i:nil="true" />
                        <FullName>
                          <xsl:value-of select="PartyIndName/FullName"/>
                        </FullName>
                        <LastName>
                          <xsl:value-of select="$lastName"/>
                        </LastName>
                        <LastNamePhonetic i:nil="true" />
                        <LastNameSoundex i:nil="true" />
                        <LastNameUpperCase i:nil="true" />
                        <LastTransactionID>
                          <xsl:value-of select="PartyIndName/LastTransactionID"/>
                        </LastTransactionID>
                        <LastUpdatedDate>
                          <xsl:value-of select="string(Util:GetCurrentDate())"/>
                        </LastUpdatedDate>

                        <xsl:choose>
                          <xsl:when test="count(/PartyData/PartyRecord/Party/PartyMiddleName) > 0">
                            <MiddleName>
                              <xsl:value-of select="$middleName"/>
                            </MiddleName>
                          </xsl:when>
                          <xsl:otherwise>
                            <MiddleName>
                              <xsl:value-of select="PartyIndName/MiddleName"/>
                            </MiddleName>
                          </xsl:otherwise>
                        </xsl:choose>

                        <MiddleNamePhonetic i:nil="true" />
                        <MiddleNameSoundex i:nil="true" />
                        <MiddleNameUpperCase i:nil="true" />
                        <NameTypeCode>
                          <xsl:value-of select="PartyIndName/NameTypeCode"/>
                        </NameTypeCode>
                        <PartyIndNameID>
                          <xsl:value-of select="PartyIndName/PartyIndNameID"/>
                        </PartyIndNameID>

                        <xsl:choose>
                          <xsl:when test="count(/PartyData/PartyRecord/Party/PartyNamePrefixCode) > 0">
                            <PrefixCode>
                              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNamePrefix',$prefixCode,'34'))"/>
                            </PrefixCode>
                          </xsl:when>
                          <xsl:otherwise>
                            <PrefixCode>
                              <xsl:value-of select="PartyIndName/PrefixCode"/>
                            </PrefixCode>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="count(/PartyData/PartyRecord/Party/PartyNameSuffixCode) > 0">
                            <SuffixCode>
                              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameSuffix',$suffixCode,'48'))"/>
                            </SuffixCode>
                          </xsl:when>
                          <xsl:otherwise>
                            <SuffixCode>
                              <xsl:value-of select="PartyIndName/SuffixCode"/>
                            </SuffixCode>
                          </xsl:otherwise>
                        </xsl:choose>

                      </PartyIndName>
                      <xsl:variable name="partyNameAFSCountryCode">
                        <xsl:choose>
                          <xsl:when test="$PartyNameCountryCode !=''">
                            <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',$PartyNameCountryCode,'243'))"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="PartyName/CountryCode"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:variable>
                      <PartyName>
                        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                        <AllowPartial>true</AllowPartial>
                        <CountryCode>
                          <xsl:value-of select="$partyNameAFSCountryCode"/>
                        </CountryCode>

                        <xsl:choose>
                          <xsl:when test="$PartyNameEffDate !=''">
                            <EffectiveDate>
                              <xsl:value-of select ="string(Util:ConvertDateToAswFormat($PartyNameEffDate))"/>
                            </EffectiveDate>
                          </xsl:when>
                          <xsl:otherwise>
                            <EffectiveDate>
                              <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyName/EffectiveDate))"/>
                            </EffectiveDate>
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                          <xsl:when test="$PartyNameExpDate !=''">
                            <ExpirationDate>
                              <xsl:value-of select ="string(Util:ConvertDateToAswFormat($PartyNameExpDate))"/>
                            </ExpirationDate>
                          </xsl:when>
                          <xsl:otherwise>
                            <ExpirationDate>
                              <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyName/ExpirationDate))"/>
                            </ExpirationDate>
                          </xsl:otherwise>
                        </xsl:choose>
                        <ExternalPartyNameID>
                          <xsl:value-of select="$externalPartyNameId"/>
                        </ExternalPartyNameID>
                        <GeographicFormatCode>
                          <xsl:value-of select="string(Util:GetChildKey('8036',$partyNameAFSCountryCode,'243'))"/>
                        </GeographicFormatCode>
                        <IsPrimary>
                          <xsl:value-of select="PartyName/IsPrimary"/>
                        </IsPrimary>
                        <IsTaxName>
                          <xsl:value-of select="PartyName/IsTaxName"/>
                        </IsTaxName>
                        <LastTransactionID>
                          <xsl:value-of select="PartyName/LastTransactionID"/>
                        </LastTransactionID>
                        <LastUpdatedDate>
                          <xsl:value-of select="string(Util:GetCurrentDate())"/>
                        </LastUpdatedDate>
                        <PartyID>
                          <xsl:value-of select="PartyName/PartyID"/>
                        </PartyID>
                        <PartyNameID>
                          <xsl:value-of select="PartyName/PartyNameID"/>
                        </PartyNameID>
                        <IsDefault>
                          <xsl:value-of select="PartyName/IsDefault"/>
                        </IsDefault>
                      </PartyName>
                    </PartyIndNameDetailDTO>
                  </xsl:if>
                </xsl:for-each>
              </xsl:if>
              <xsl:if test="count(PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '07']) > 0">
                <xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '07']">
                  <xsl:if test="PartyIndName/FullName != $partyCorrespondenceName 
                          or string(PartyIndName/Comment) !=  string($PartyNameComments)">
                    <PartyIndNameDetailDTO>
                      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                      <PartyIndName>
                        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                         <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>
                        <FirstName>
                          <xsl:value-of select="string(Util:GetPartialNameFromFullName('FirstName',$partyCorrespondenceName))"/>
                        </FirstName>
                        <FirstNamePhonetic i:nil="true" />
                        <FirstNameSoundex i:nil="true" />
                        <FirstNameUpperCase i:nil="true" />
                        <FullName>
                          <xsl:value-of select="$partyCorrespondenceName"/>
                        </FullName>
                        <LastName>
                          <xsl:value-of select="string(Util:GetPartialNameFromFullName('LastName',$partyCorrespondenceName))"/>
                        </LastName>
                        <LastNamePhonetic i:nil="true" />
                        <LastNameSoundex i:nil="true" />
                        <LastNameUpperCase i:nil="true" />
                        <LastTransactionID>
                          <xsl:value-of select="PartyIndName/LastTransactionID"/>
                        </LastTransactionID>
                        <LastUpdatedDate>
                          <xsl:value-of select="string(Util:GetCurrentDate())"/>
                        </LastUpdatedDate>
                        <MiddleName>
                          <xsl:value-of select="string(Util:GetPartialNameFromFullName('MiddleName',$partyCorrespondenceName))"/>
                        </MiddleName>
                        <MiddleNamePhonetic i:nil="true" />
                        <MiddleNameSoundex i:nil="true" />
                        <MiddleNameUpperCase i:nil="true" />
                        <NameTypeCode>
                          <xsl:value-of select="PartyIndName/NameTypeCode"/>
                        </NameTypeCode>
                        <PartyIndNameID>
                          <xsl:value-of select="PartyIndName/PartyIndNameID"/>
                        </PartyIndNameID>
                        <PrefixCode>
                          <xsl:value-of select="PartyIndName/PrefixCode"/>
                        </PrefixCode>
                        <SuffixCode>
                          <xsl:value-of select="PartyIndName/SuffixCode"/>
                        </SuffixCode>
                      </PartyIndName>
                      <xsl:call-template name="UpdatePartyName" />
                    </PartyIndNameDetailDTO>
                  </xsl:if>
                </xsl:for-each>
              </xsl:if>

              <xsl:if test="count(PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '06']) > 0">
                <xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '06']">
                  <xsl:if test="PartyIndName/FullName != string($partyLegacyName)
                          or string(PartyIndName/Comment) !=  string($PartyNameComments)">
                    <PartyIndNameDetailDTO>
                      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                      <PartyIndName>
                        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                         <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>
                        <FirstName>
                          <!--xsl:value-of select="string(Util:GetPartialNameFromFullName('FirstName',$partyLegacyName))"/-->
                          <xsl:value-of select="$firstName"/>                          
                        </FirstName>
                        <FirstNamePhonetic i:nil="true" />
                        <FirstNameSoundex i:nil="true" />
                        <FirstNameUpperCase i:nil="true" />
                        <FullName>
                          <xsl:value-of select="$partyLegacyName"/>
                        </FullName>
                        <LastName>
                          <!--xsl:value-of select="string(Util:GetPartialNameFromFullName('LastName',$partyLegacyName))"/-->
                          <xsl:value-of select="$lastName"/>
                        </LastName>
                        <LastNamePhonetic i:nil="true" />
                        <LastNameSoundex i:nil="true" />
                        <LastNameUpperCase i:nil="true" />
                        <LastTransactionID>
                          <xsl:value-of select="PartyIndName/LastTransactionID"/>
                        </LastTransactionID>
                        <LastUpdatedDate>
                          <xsl:value-of select="string(Util:GetCurrentDate())"/>
                        </LastUpdatedDate>
                        <xsl:choose>
                          <xsl:when test="count(/PartyData/PartyRecord/Party/PartyMiddleName) > 0">
                            <MiddleName>
                              <xsl:value-of select="$middleName"/>
                            </MiddleName>
                          </xsl:when>
                          <xsl:otherwise>
                            <MiddleName>
                              <xsl:value-of select="PartyIndName/MiddleName"/>
                            </MiddleName>
                          </xsl:otherwise>
                        </xsl:choose>
                        <MiddleNamePhonetic i:nil="true" />
                        <MiddleNameSoundex i:nil="true" />
                        <MiddleNameUpperCase i:nil="true" />
                        <NameTypeCode>
                          <xsl:value-of select="PartyIndName/NameTypeCode"/>
                        </NameTypeCode>
                        <PartyIndNameID>
                          <xsl:value-of select="PartyIndName/PartyIndNameID"/>
                        </PartyIndNameID>
                        <xsl:choose>
                          <xsl:when test="count(/PartyData/PartyRecord/Party/PartyNamePrefixCode) > 0">
                            <PrefixCode>
                              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNamePrefix',$prefixCode,'34'))"/>
                            </PrefixCode>
                          </xsl:when>
                          <xsl:otherwise>
                            <PrefixCode>
                              <xsl:value-of select="PartyIndName/PrefixCode"/>
                            </PrefixCode>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="count(/PartyData/PartyRecord/Party/PartyNameSuffixCode) > 0">
                            <SuffixCode>
                              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameSuffix',$suffixCode,'48'))"/>
                            </SuffixCode>
                          </xsl:when>
                          <xsl:otherwise>
                            <SuffixCode>
                              <xsl:value-of select="PartyIndName/SuffixCode"/>
                            </SuffixCode>
                          </xsl:otherwise>
                        </xsl:choose>
                      </PartyIndName>
                      <xsl:call-template name="UpdatePartyName" />
                    </PartyIndNameDetailDTO>
                  </xsl:if>
                </xsl:for-each>
              </xsl:if>
            </xsl:if>

            <xsl:if test="$updateOtherNameRecord = 'True'">
              <xsl:if test="count(PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '04']) > 0">
                <xsl:for-each select="PartyRecord">
                  <xsl:call-template name="partyIndName" />
                </xsl:for-each>
              </xsl:if>
            </xsl:if>
          </PartyIndNamesToUpdate>
        </xsl:when>
        <xsl:otherwise>
          <PartyIndNamesToInsert i:nil="true" />
          <PartyIndNamesToUpdate i:nil="true"/>
        </xsl:otherwise>
      </xsl:choose>

      <PartyLicensesToDelete i:nil="true" />
      <PartyLicensesToInsert i:nil="true" />
      <PartyLicensesToUpdate i:nil="true" />
      <PartyMembershipsToDelete i:nil="true" />
      <PartyMembershipsToInsert i:nil="true" />
      <PartyMembershipsToUpdate i:nil="true" />

      <PartyPhonesToDelete i:nil="true" />

      <!--shabbir 1-->
      <xsl:choose>
        <xsl:when test="($updatePhonePrimaryRecord = 'True' or $updatePhoneFaxRecord = 'True') and count(/PartyData/PartyRecord/PartyPhones/PartyPhone) > 0">
          <xsl:for-each select="/PartyData/PartyRecord">
            <PartyPhonesToInsert>
              <xsl:for-each select="./PartyPhones/PartyPhone">
                <xsl:if test="count(PartyPhoneId) = 0 or PartyPhoneId = ''">
                  <xsl:call-template name="partyPhoneInsert" />
                </xsl:if>
              </xsl:for-each>
            </PartyPhonesToInsert>

          </xsl:for-each>
          <xsl:for-each select="/PartyData/PartyRecord">
            <xsl:choose>
              <xsl:when test="count(./PartyPhones/PartyPhone[PartyPhoneId != '']) > 0">
                <PartyPhonesToUpdate>
                  <xsl:for-each select="./PartyPhones/PartyPhone[PartyPhoneId != '']">
                    <PartyPhoneDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
                      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                      <xsl:call-template name="commonPhoneTemplate" />
                    </PartyPhoneDTO>
                  </xsl:for-each>
                </PartyPhonesToUpdate>
              </xsl:when>
            </xsl:choose>
          </xsl:for-each>

        </xsl:when>
        <xsl:otherwise>
          <PartyPhonesToInsert i:nil="true" />
          <PartyPhonesToUpdate i:nil="true" />
        </xsl:otherwise>
      </xsl:choose>
      <!--//-->
      <PartyRelationsToDelete i:nil="true" />
      <PartyRelationsToInsert i:nil="true" />
      <PartyIndNamesToReplace>
        <xsl:if test="string($replaceContact) = 'Y'">
          <xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyName/IsDefault = 'true']">
            <xsl:if test ="string(PartyIndName/FirstName) != string($firstName) 
								or  string(PartyIndName/MiddleName)  != string($middleName)
								or string(PartyIndName/LastName)  !=  string($lastName)
								or string(PartyIndName/PrefixCode)  !=  string(Util:GetOneRelatedItem('DCTNamePrefix',$prefixCode,'34'))
								or string(PartyIndName/SuffixCode)  !=  string(Util:GetOneRelatedItem('DCTNameSuffix',$suffixCode,'48'))
                or string(PartyIndName/Comment) !=  string($PartyNameComments)">
              <ReplacePartyIndNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyIndNameDetailOld>
                  <xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(PartyIndName,'PartyIndName')" />
                  <xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(PartyName,'PartyName')" />
                </PartyIndNameDetailOld>

                <PartyIndNameDetailWithExtendedData>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <PartyIndName>
                    <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                    <Comment>
                      <xsl:value-of select ="$PartyNameComments"/>
                    </Comment>

                    <FirstName>
                      <xsl:value-of select="$firstName"/>
                    </FirstName>
                    <FirstNamePhonetic i:nil="true" />
                    <FirstNameSoundex i:nil="true" />
                    <FirstNameUpperCase i:nil="true" />
                    <FullName i:nil="true" />

                    <LastName>
                      <xsl:value-of select="$lastName"/>
                    </LastName>
                    <LastNamePhonetic i:nil="true" />
                    <LastNameSoundex i:nil="true" />
                    <LastNameUpperCase i:nil="true" />
                    <LastTransactionID i:nil="true" />
                    <LastUpdatedDate>
                      <xsl:value-of select="string(Util:GetCurrentDate())"/>
                    </LastUpdatedDate>

                    <xsl:choose>
                      <xsl:when test="count(/PartyData/PartyRecord/Party/PartyMiddleName) > 0">
                        <MiddleName>
                          <xsl:value-of select="$middleName"/>
                        </MiddleName>
                      </xsl:when>
                      <xsl:otherwise>
                        <MiddleName i:nil="true" />
                      </xsl:otherwise>
                    </xsl:choose>

                    <MiddleNamePhonetic i:nil="true" />
                    <MiddleNameSoundex i:nil="true" />
                    <MiddleNameUpperCase i:nil="true" />
                    <NameTypeCode>
                      <xsl:value-of select="PartyIndName/NameTypeCode"/>
                    </NameTypeCode>
                    <PartyIndNameID i:nil="true" />

                    <xsl:choose>
                      <xsl:when test="count(/PartyData/PartyRecord/Party/PartyNamePrefixCode) > 0">
                        <PrefixCode>
                          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNamePrefix',$prefixCode,'34'))"/>
                        </PrefixCode>
                      </xsl:when>
                      <xsl:otherwise>
                        <PrefixCode i:nil="true" />
                      </xsl:otherwise>
                    </xsl:choose>

                    <xsl:choose>
                      <xsl:when test="count(/PartyData/PartyRecord/Party/PartyNameSuffixCode) > 0">
                        <SuffixCode>
                          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameSuffix',$suffixCode,'48'))"/>
                        </SuffixCode>
                      </xsl:when>
                      <xsl:otherwise>
                        <SuffixCode i:nil="true" />
                      </xsl:otherwise>
                    </xsl:choose>

                  </PartyIndName>
                  <PartyIndNameExtendedData nil="true" />
                  <PartyName>
                    <xsl:variable name="partyIndNameAFSCountryCode">
                      <xsl:choose>
                        <xsl:when test="$PartyNameCountryCode !=''">
                          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',$PartyNameCountryCode,'243'))"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="PartyName/CountryCode"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>
                    <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                    <AllowPartial>true</AllowPartial>
                    <CountryCode>
                      <xsl:value-of select="$partyIndNameAFSCountryCode"/>
                    </CountryCode>
                    <xsl:choose>
                      <xsl:when test="$PartyNameEffDate !=''">
                        <EffectiveDate>
                          <xsl:value-of select ="$PartyNameEffDate"/>
                        </EffectiveDate>
                      </xsl:when>
                      <xsl:otherwise>
                        <EffectiveDate>
                          <xsl:value-of select="string(Util:GetCurrentDate())"/>
                        </EffectiveDate>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                      <xsl:when test="$PartyNameExpDate !=''">
                        <ExpirationDate>
                          <xsl:value-of select ="$PartyNameExpDate"/>
                        </ExpirationDate>
                      </xsl:when>
                      <xsl:otherwise>
                        <ExpirationDate>
                          <xsl:value-of select="string(Util:GetMaxDate())"/>
                        </ExpirationDate>
                      </xsl:otherwise>
                    </xsl:choose>

                    <ExternalPartyNameID>
                      <xsl:value-of select="$externalPartyNameId"/>
                    </ExternalPartyNameID>
                    <GeographicFormatCode>
                      <xsl:value-of select="string(Util:GetChildKey('8036',$partyIndNameAFSCountryCode,'243'))"/>
                    </GeographicFormatCode>
                    <IsPrimary>
                      <xsl:value-of select="PartyName/IsPrimary"/>
                    </IsPrimary>
                    <IsTaxName>false</IsTaxName>
                    <LastTransactionID i:nil="true" />
                    <LastUpdatedDate>
                      <xsl:value-of select="string(Util:GetCurrentDate())"/>
                    </LastUpdatedDate>
                    <PartyID>
                      <xsl:value-of select="$PartyId"/>
                    </PartyID>
                    <PartyNameID i:nil="true" />
                    <IsDefault>
                      <xsl:value-of select="PartyName/IsDefault"/>
                    </IsDefault>
                  </PartyName>
                  <PartyNameExtendedData nil="true" />
                </PartyIndNameDetailWithExtendedData>
              </ReplacePartyIndNameDetailDTO>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </PartyIndNamesToReplace>
    </PartyIndividualBulkDetailsDTO>
  </xsl:template>

  <xsl:template name="UpdatePartyBus">
    <PartyBusinessBulkDetailsDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>

      <!-- Party Details -->
      <Party>
        <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
        <ACHPartyExternalID>
          <xsl:value-of select="$ACHPartyExternalId"/>
        </ACHPartyExternalID>
        <BusinessPermitted>
          <xsl:value-of select="$PartyOFACCheckNotRequired"/>
        </BusinessPermitted>
        <CountryCode>
          <xsl:choose>
            <xsl:when test="$PartyCountryCode !=''">
              <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',$PartyCountryCode,'243'))"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/CountryCode"/>
            </xsl:otherwise>
          </xsl:choose>
        </CountryCode>

        <xsl:choose>
          <xsl:when test="$PartyExternalId != '' or count(/PartyData/PartyRecord/Party/ExternalId) > 0">
            <ExternalID>
              <xsl:value-of select="$PartyExternalId"/>
            </ExternalID>
          </xsl:when>
          <xsl:otherwise>
            <ExternalID>
              <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/ExternalID"/>
            </ExternalID>
          </xsl:otherwise>
        </xsl:choose>

        <!--<ExternalID>					<xsl:value-of select="$PartyExternalId"/>
					</ExternalID>-->
        <GeographicFormatCode>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/GeographicFormatCode"/>
        </GeographicFormatCode>
        <IsInActive>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/IsInActive"/>
        </IsInActive>
        <xsl:choose>
          <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/Party/LastTransactionID) > 0">
            <LastTransactionID>
              <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/LastTransactionID"/>
            </LastTransactionID>
          </xsl:when>
          <xsl:otherwise>
            <LastTransactionID i:nil="true" />
          </xsl:otherwise>
        </xsl:choose>
        <LastUpdatedDate>
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>
        <Number>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/Number"/>
        </Number>
        <PartyID>
          <xsl:value-of select="$PartyId"/>
        </PartyID>
        <PartyTypeCode>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/PartyTypeCode"/>
        </PartyTypeCode>
        <PartySubTypeCode>
          <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/PartySubTypeCode"/>
        </PartySubTypeCode>
		<xsl:if test="string(Util:ShowPartyTimeZone($PartyTimeZone)) != ''">
      <PartyTimeZone>
				<xsl:value-of select="string(Util:GetOneRelatedItem('DCTTimeZones',$PartyTimeZone,'TimeZones'))"/>
			</PartyTimeZone>
		</xsl:if>
        <!--<SkipLoadingExtendedData>
					<xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/SkipLoadingExtendedData"/>
				</SkipLoadingExtendedData>-->
      </Party>
      <PartyAddressesToDelete i:nil="true" />
      <xsl:choose>
        <xsl:when test="$updateLocationRecord = 'True'  and count(/PartyData/PartyRecord/Locations/Location) > 0">
          <xsl:choose>
            <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO) = 0">
              <xsl:for-each select="/PartyData/PartyRecord">
                <PartyAddressesToInsert>
                  <xsl:call-template name="partyLocationExtendedData" />
                </PartyAddressesToInsert>
              </xsl:for-each>
              <PartyAddressesToUpdate i:nil="true" />
            </xsl:when>
            <xsl:otherwise>
              <PartyAddressesToInsert i:nil="true" />
              <xsl:for-each select="/PartyData">
                <PartyAddressesToUpdate>
                  <xsl:call-template name="CorrectPartyLocation_Bus" />
                </PartyAddressesToUpdate>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <PartyAddressesToInsert i:nil="true" />
          <PartyAddressesToUpdate i:nil="true" />
        </xsl:otherwise>
      </xsl:choose>

      <PartyAgency i:nil="true" />

      <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyBusiness">
        <PartyBusiness>
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>

          <xsl:choose>
            <xsl:when test="count($partySubTypeCode) = 0">
              <BusinessTypeCode>
                <xsl:value-of select="BusinessTypeCode"/>
              </BusinessTypeCode>
            </xsl:when>
            <xsl:when test="string($partySubTypeCode) = ''">
              <BusinessTypeCode i:nil="true" />
            </xsl:when>
            <xsl:otherwise>
              <BusinessTypeCode>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTBusinessType',$partySubTypeCode,'427'))"/>
              </BusinessTypeCode>
            </xsl:otherwise>
          </xsl:choose>
		  <xsl:if test="string(Util:ShowPartyTimeZone($PartyTimeZone)) != ''">
			  <PartyTimeZone>
					<xsl:value-of select="string(Util:GetOneRelatedItem('DCTTimeZones',$PartyTimeZone,'TimeZones'))"/>
				</PartyTimeZone>
		  </xsl:if>
          <EffectiveDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(EffectiveDate))"/>
          </EffectiveDate>
          <ExpirationDate>
            <xsl:value-of select="string(Util:ConvertDateToAswFormat(ExpirationDate))"/>
          </ExpirationDate>


          <IsAgency>
            <xsl:value-of select="IsAgency"/>
          </IsAgency>

          <xsl:choose>
            <xsl:when test="$PartySupplier !=''">
              <IsSupplier>
                <xsl:value-of select="$PartySupplier"/>
              </IsSupplier>
            </xsl:when>
            <xsl:otherwise>
              <IsSupplier>0</IsSupplier>
            </xsl:otherwise>
          </xsl:choose>

          <LastTransactionID>
            <xsl:value-of select="LastTransactionID"/>
          </LastTransactionID>
          <LastUpdatedDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </LastUpdatedDate>
          <PartyID>
            <xsl:value-of select="PartyID"/>
          </PartyID>

          <xsl:choose>
            <xsl:when test="count($PreferredContactMethod) = 0 and count(PreferredContactType)>0">
              <PreferredContactType>
                <xsl:value-of select="PreferredContactType"/>
              </PreferredContactType>
            </xsl:when>
            <xsl:when test="$PreferredContactMethod = ''">
              <PreferredContactType i:nil="true"/>
            </xsl:when>
            <xsl:otherwise>
              <PreferredContactType>
                <xsl:value-of select="$PreferredContactMethod"/>
              </PreferredContactType>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:choose>
            <xsl:when test="$MethodName = 'SetPartyClientDetails'">
              <PreferredLanguage>
                <xsl:value-of select="$PartyPreferredLanguageCode"/>
              </PreferredLanguage>
            </xsl:when>
            <xsl:otherwise>
              <PreferredLanguage>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTLanguageType',$PartyPreferredLanguageCode,'8037'))"/>
              </PreferredLanguage>
            </xsl:otherwise>
          </xsl:choose>

          <!--<RegistrationID1>
						<xsl:value-of select="$PartyTaxId"/>
					</RegistrationID1>-->

          <xsl:choose>
            <xsl:when test="count($PartyTaxId) = 0">
              <RegistrationID1>
                <xsl:value-of select="RegistrationID1"/>
              </RegistrationID1>
            </xsl:when>
            <xsl:when test="string($PartyTaxId) = ''">
              <RegistrationID1 i:nil="true" />
            </xsl:when>
            <xsl:otherwise>
              <RegistrationID1>
                <xsl:value-of select="$PartyTaxId"/>
              </RegistrationID1>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:choose>
            <xsl:when test="count($PartyTaxId2) = 0">
              <RegistrationID2>
                <xsl:value-of select="RegistrationID2"/>
              </RegistrationID2>
            </xsl:when>
            <xsl:when test="string($PartyTaxId2) = ''">
              <RegistrationID2 i:nil="true" />
            </xsl:when>
            <xsl:otherwise>
              <RegistrationID2>
                <xsl:value-of select="$PartyTaxId2"/>
              </RegistrationID2>
            </xsl:otherwise>
          </xsl:choose>
          <RegistrationID3 i:nil="true" />

          <xsl:if test="$MethodName != 'SetPartyClientDetails'">
            <xsl:for-each select="/PartyData/PartyRecord/Party">
              <xsl:call-template name="ExtendedData">
                <xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>
				<xsl:with-param name="SuiteTagName">PartyBusinessSuiteExtendedData</xsl:with-param>
                <xsl:with-param name="AswTagName">BusinessExtendedData</xsl:with-param>
                <xsl:with-param name="PhysicalTableName">PARTY_BUS</xsl:with-param>
                <xsl:with-param name="LogicalTableName">lgclPartyBus</xsl:with-param>
                <xsl:with-param name="LogicalColumnName">PartyBusExtData</xsl:with-param>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:if>
        </PartyBusiness>
      </xsl:for-each>

      <PartyBusNamesToDelete i:nil="true" />
      <PartyBusNamesToInsert>
        <xsl:if test="count(PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '07']) = 0">
          <PartyBusNameDetailWithExtendedDataDTO>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <PartyBusName>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>
              <LastUpdatedDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </LastUpdatedDate>

              <Name>
                <xsl:value-of select="$lastName"/>
              </Name>
              <NamePhonetic i:nil="true" />
              <NameSoundex i:nil="true" />
              <NameTypeCode>07</NameTypeCode>
              <NameUpperCase i:nil="true" />
            </PartyBusName>
            <!--<ExtendedData>Party Name Extended data</ExtendedData>-->
            <xsl:call-template name="InsertPartyName" />
          </PartyBusNameDetailWithExtendedDataDTO>
        </xsl:if>

        <xsl:if test="count(PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '06']) = 0">
          <PartyBusNameDetailWithExtendedDataDTO>
            <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
            <!--<ExtendedData>Party Bus Name Extended data</ExtendedData>-->
            <PartyBusName>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
               <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>
              <LastUpdatedDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </LastUpdatedDate>

              <Name>
                <xsl:value-of select="$lastName"/>
              </Name>
              <NamePhonetic i:nil="true" />
              <NameSoundex i:nil="true" />
              <NameTypeCode>06</NameTypeCode>
              <NameUpperCase i:nil="true" />
            </PartyBusName>
            <!--<ExtendedData>Party Name Extended data</ExtendedData>-->
            <xsl:call-template name="InsertPartyName" />
          </PartyBusNameDetailWithExtendedDataDTO>
        </xsl:if>

        <xsl:if test="$updateOtherNameRecord = 'True'">
          <xsl:if test="count(PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '04']) = 0">
            <xsl:for-each select="PartyRecord">
              <xsl:call-template name="partyBusNameExtData" />
            </xsl:for-each>
          </xsl:if>
        </xsl:if>
      </PartyBusNamesToInsert>
      <PartyBusNamesToUpdate>
        <xsl:if test="string($replaceContact) != 'Y'">
          <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyName/IsDefault = 'true']">
            <xsl:if test ="string(PartyBusName/Name) != string($lastName)
            or string(PartyBusName/Comment) !=  string($PartyNameComments)">
              <PartyBusNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyBusName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <Comment>
                    <xsl:value-of select ="$PartyNameComments"/>
                  </Comment>

                  <LastTransactionID>
                    <xsl:value-of select="PartyBusName/LastTransactionID"/>
                  </LastTransactionID>
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>

                  <Name>
                    <xsl:value-of select="$lastName"/>
                  </Name>
                  <NamePhonetic i:nil="true" />
                  <NameSoundex i:nil="true" />
                  <NameTypeCode>
                    <xsl:value-of select="PartyBusName/NameTypeCode"/>
                  </NameTypeCode>
                  <NameUpperCase i:nil="true" />
                  <PartyBusNameID>
                    <xsl:value-of select="PartyBusName/PartyBusNameID"/>
                  </PartyBusNameID>
                </PartyBusName>
                <xsl:variable name="partyNameAFSCountryCode">
                  <xsl:choose>
                    <xsl:when test="$PartyNameCountryCode !=''">
                      <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',$PartyNameCountryCode,'243'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="PartyName/CountryCode"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <PartyName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <AllowPartial>true</AllowPartial>
                  <CountryCode>
                    <xsl:value-of select="$partyNameAFSCountryCode"/>
                  </CountryCode>
                  <xsl:choose>
                    <xsl:when test="$PartyNameEffDate !=''">
                      <EffectiveDate>
                        <xsl:value-of select ="string(Util:ConvertDateToAswFormat($PartyNameEffDate))"/>
                      </EffectiveDate>
                    </xsl:when>
                    <xsl:otherwise>
                      <EffectiveDate>
                        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyName/EffectiveDate))"/>
                      </EffectiveDate>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="$PartyNameExpDate !=''">
                      <ExpirationDate>
                        <xsl:value-of select ="string(Util:ConvertDateToAswFormat($PartyNameExpDate))"/>
                      </ExpirationDate>
                    </xsl:when>
                    <xsl:otherwise>
                      <ExpirationDate>
                        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyName/ExpirationDate))"/>
                      </ExpirationDate>
                    </xsl:otherwise>
                  </xsl:choose>

                  <ExternalPartyNameID>
                    <xsl:value-of select="$externalPartyNameId"/>
                  </ExternalPartyNameID>
                  <GeographicFormatCode>
                    <xsl:value-of select="string(Util:GetChildKey('8036',$partyNameAFSCountryCode,'243'))"/>
                  </GeographicFormatCode>
                  <IsPrimary>
                    <xsl:value-of select="PartyName/IsPrimary"/>
                  </IsPrimary>
                  <IsTaxName>
                    <xsl:value-of select="PartyName/IsTaxName"/>
                  </IsTaxName>
                  <LastTransactionID>
                    <xsl:value-of select="PartyName/LastTransactionID"/>
                  </LastTransactionID>
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <PartyID>
                    <xsl:value-of select="PartyName/PartyID"/>
                  </PartyID>
                  <PartyNameID>
                    <xsl:value-of select="PartyName/PartyNameID"/>
                  </PartyNameID>
                  <IsDefault>
                    <xsl:value-of select="PartyName/IsDefault"/>
                  </IsDefault>
                </PartyName>
              </PartyBusNameDetailDTO>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>

        <xsl:if test="count(PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '07']) > 0">
          <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '07']">
            <xsl:if test="PartyBusName/Name != $partyCorrespondenceName 
              or string(PartyBusName/Comment) !=  string($PartyNameComments)">
              <PartyBusNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyBusName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                   <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>

                  <LastTransactionID>
                    <xsl:value-of select="PartyBusName/LastTransactionID"/>
                  </LastTransactionID>
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <Name>
                    <xsl:value-of select="$partyCorrespondenceName"/>
                  </Name>
                  <NamePhonetic i:nil="true" />
                  <NameSoundex i:nil="true" />

                  <NameTypeCode>
                    <xsl:value-of select="PartyBusName/NameTypeCode"/>
                  </NameTypeCode>
                  <NameUpperCase i:nil="true" />
                  <PartyBusNameID>
                    <xsl:value-of select="PartyBusName/PartyBusNameID"/>
                  </PartyBusNameID>
                </PartyBusName>
                <xsl:call-template name="UpdatePartyName" />
              </PartyBusNameDetailDTO>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>

        <xsl:if test="count(PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '06']) > 0">
          <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '06']">
            <xsl:if test="PartyBusName/Name != $partyLegacyName
                    or string(PartyBusName/Comment) !=  string($PartyNameComments)">
              <PartyBusNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyBusName>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                   <Comment>
                          <xsl:value-of select="$PartyNameComments"/>
                        </Comment>

                  <LastTransactionID>
                    <xsl:value-of select="PartyBusName/LastTransactionID"/>
                  </LastTransactionID>
                  <LastUpdatedDate>
                    <xsl:value-of select="string(Util:GetCurrentDate())"/>
                  </LastUpdatedDate>
                  <Name>
                    <xsl:value-of select="$partyLegacyName"/>
                  </Name>
                  <NamePhonetic i:nil="true" />
                  <NameSoundex i:nil="true" />

                  <NameTypeCode>
                    <xsl:value-of select="PartyBusName/NameTypeCode"/>
                  </NameTypeCode>
                  <NameUpperCase i:nil="true" />
                  <PartyBusNameID>
                    <xsl:value-of select="PartyBusName/PartyBusNameID"/>
                  </PartyBusNameID>
                </PartyBusName>
                <xsl:call-template name="UpdatePartyName" />
              </PartyBusNameDetailDTO>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>

        <xsl:if test="$updateOtherNameRecord = 'True'">
          <xsl:if test="count(PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '04']) > 0">
            <xsl:for-each select="PartyRecord">
              <xsl:call-template name="partyBusName" />
            </xsl:for-each>
          </xsl:if>
        </xsl:if>
      </PartyBusNamesToUpdate>

      <xsl:if test="$PartyComments != '' or count(PartyDetailDTO/PartyBusinessDetail/PartyComment/Comment) > 0">
        <PartyComment>
          <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
          <xsl:choose>
            <xsl:when test="count($PartyComments) = 0 and count(PartyDetailDTO/PartyBusinessDetail/PartyComment/Comment)>0">
              <Comment>
                <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyComment/Comment"/>
              </Comment>
            </xsl:when>
            <xsl:when test="$PartyComments = ''">
              <Comment i:nil="true"/>
            </xsl:when>
            <xsl:otherwise>
              <Comment>
                <xsl:value-of select="$PartyComments"/>
              </Comment>
            </xsl:otherwise>
          </xsl:choose>

          <EffectiveDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </EffectiveDate>
          <ExpirationDate>
            <xsl:value-of select="string(Util:GetMaxDate())"/>
          </ExpirationDate>

          <xsl:choose>
            <xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyComment/LastTransactionID) > 0">
              <LastTransactionID>
                <xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyComment/LastTransactionID"/>
              </LastTransactionID>
            </xsl:when>
            <xsl:otherwise>
              <LastTransactionID i:nil="true" />
            </xsl:otherwise>
          </xsl:choose>

          <LastUpdatedDate>
            <xsl:value-of select="string(Util:GetCurrentDate())"/>
          </LastUpdatedDate>
          <PartyID>
            <xsl:value-of select="$PartyId"/>
          </PartyID>
        </PartyComment>
      </xsl:if>
      <PartyEmailsToDelete i:nil="true" />
      <xsl:choose>
        <xsl:when test="$updateEmailRecord = 'True'  and count(/PartyData/PartyRecord/PartyEmails/PartyEmail) > 0">
          <xsl:for-each select="/PartyData/PartyRecord">
            <xsl:choose>
              <xsl:when test="count(./PartyEmails/PartyEmail[PartyEmailId != '']) > 0">
                <PartyEmailsToUpdate>
                  <xsl:for-each select="./PartyEmails/PartyEmail[PartyEmailId != '']">
                    <PartyEmailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
                      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                      <xsl:call-template name ="commonEmailFields" />
                    </PartyEmailDTO>
                  </xsl:for-each>
                </PartyEmailsToUpdate>
              </xsl:when>
            </xsl:choose>

            <PartyEmailsToInsert>
              <xsl:for-each select="./PartyEmails/PartyEmail">
                <xsl:if test="count(PartyEmailId) = 0 or PartyEmailId = ''">
                  <xsl:call-template name="partyEmailInsert" />
                </xsl:if>
              </xsl:for-each>
            </PartyEmailsToInsert>


          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <PartyEmailsToInsert i:nil="true" />
          <PartyEmailsToUpdate i:nil="true" />
        </xsl:otherwise>
      </xsl:choose>

      <PartyLicensesToDelete i:nil="true" />
      <PartyLicensesToInsert i:nil="true" />
      <PartyLicensesToUpdate i:nil="true" />
      <PartyMembershipsToDelete i:nil="true" />
      <PartyMembershipsToInsert i:nil="true" />
      <PartyMembershipsToUpdate i:nil="true" />
      <PartyPhonesToDelete i:nil="true" />

      <xsl:choose>
        <xsl:when test="($updatePhonePrimaryRecord = 'True' or $updatePhoneFaxRecord = 'True') and count(/PartyData/PartyRecord/PartyPhones/PartyPhone) > 0">
          <xsl:for-each select="/PartyData/PartyRecord">
            <PartyPhonesToInsert>
              <xsl:for-each select="./PartyPhones/PartyPhone">
                <xsl:if test="count(PartyPhoneId) = 0 or PartyPhoneId = ''">
                  <xsl:call-template name="partyPhoneInsert" />
                </xsl:if>
              </xsl:for-each>
            </PartyPhonesToInsert>

          </xsl:for-each>
          <xsl:for-each select="/PartyData/PartyRecord">
            <xsl:choose>
              <xsl:when test="count(./PartyPhones/PartyPhone[PartyPhoneId != '']) > 0">
                <PartyPhonesToUpdate>
                  <xsl:for-each select="./PartyPhones/PartyPhone[PartyPhoneId != '']">
                    <PartyPhoneDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
                      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                      <xsl:call-template name="commonPhoneTemplate" />
                    </PartyPhoneDTO>
                  </xsl:for-each>
                </PartyPhonesToUpdate>
              </xsl:when>
            </xsl:choose>

          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <PartyPhonesToInsert i:nil="true" />
          <PartyPhonesToUpdate i:nil="true" />
        </xsl:otherwise>
      </xsl:choose>

      <PartyRelationsToDelete i:nil="true" />
      <PartyRelationsToInsert i:nil="true" />

      <PartyBusNamesToReplace>
        <xsl:if test="string($replaceContact) = 'Y'">
          <xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyName/IsDefault = 'true']">
            <xsl:if test ="string(PartyBusName/Name) != string($lastName) 
                    or string(PartyBusName/Comment) !=  string($PartyNameComments)">
              <ReplacePartyBusNameDetailDTO>
                <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                <PartyBusNameDetailOld>
                  <xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(PartyBusName,'PartyBusName')" />
                  <xsl:value-of disable-output-escaping="yes" select="Util:GetXMLNode(PartyName,'PartyName')" />
                </PartyBusNameDetailOld>

                <PartyBusNameDetailWithExtendedData>
                  <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                  <PartyBusName>
                    <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                    <Comment>
                      <xsl:value-of select ="$PartyNameComments"/>
                    </Comment>
                    <LastTransactionID i:nil ="true"/>
                    <LastUpdatedDate>
                      <xsl:value-of select="string(Util:GetCurrentDate())"/>
                    </LastUpdatedDate>

                    <Name>
                      <xsl:value-of select="$lastName"/>
                    </Name>
                    <NamePhonetic i:nil="true" />
                    <NameSoundex i:nil="true" />
                    <NameTypeCode>
                      <xsl:value-of select="PartyBusName/NameTypeCode"/>
                    </NameTypeCode>
                    <NameUpperCase i:nil="true" />
                    <PartyBusNameID i:nil ="true"/>
                  </PartyBusName>
                  <PartyBusNameExtendedData nil="true" />
                  <PartyName>
                    <xsl:variable name="partyBusNameReplaceAFSCountryCode">
                      <xsl:choose>
                        <xsl:when test="$PartyNameCountryCode !=''">
                          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',$PartyNameCountryCode,'243'))"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="PartyName/CountryCode"/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>
                    <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
                    <AllowPartial>true</AllowPartial>
                    <CountryCode>
                      <xsl:value-of select="$partyBusNameReplaceAFSCountryCode"/>
                    </CountryCode>
                    <xsl:choose>
                      <xsl:when test="$PartyNameEffDate !=''">
                        <EffectiveDate>
                          <xsl:value-of select ="$PartyNameEffDate"/>
                        </EffectiveDate>
                      </xsl:when>
                      <xsl:otherwise>
                        <EffectiveDate>
                          <xsl:value-of select="string(Util:GetCurrentDate())"/>
                        </EffectiveDate>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                      <xsl:when test="$PartyNameExpDate !=''">
                        <ExpirationDate>
                          <xsl:value-of select ="$PartyNameExpDate"/>
                        </ExpirationDate>
                      </xsl:when>
                      <xsl:otherwise>
                        <ExpirationDate>
                          <xsl:value-of select="string(Util:GetMaxDate())"/>
                        </ExpirationDate>
                      </xsl:otherwise>
                    </xsl:choose>

                    <ExternalPartyNameID>
                      <xsl:value-of select="$externalPartyNameId"/>
                    </ExternalPartyNameID>
                    <GeographicFormatCode>
                      <xsl:value-of select="string(Util:GetChildKey('8036',$partyBusNameReplaceAFSCountryCode,'243'))"/>
                    </GeographicFormatCode>
                    <IsPrimary>
                      <xsl:value-of select="PartyName/IsPrimary"/>
                    </IsPrimary>
                    <IsTaxName>false</IsTaxName>
                    <LastTransactionID i:nil="true" />
                    <LastUpdatedDate>
                      <xsl:value-of select="string(Util:GetCurrentDate())"/>
                    </LastUpdatedDate>
                    <PartyID>
                      <xsl:value-of select="$PartyId"/>
                    </PartyID>
                    <PartyNameID i:nil="true" />
                    <IsDefault>
                      <xsl:value-of select="PartyName/IsDefault"/>
                    </IsDefault>
                  </PartyName>
                  <PartyNameExtendedData nil="true" />
                </PartyBusNameDetailWithExtendedData>
              </ReplacePartyBusNameDetailDTO>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
      </PartyBusNamesToReplace>
    </PartyBusinessBulkDetailsDTO>
  </xsl:template>

  <xsl:template name="UpdatePartyName">
    <xsl:variable name="partyNameAFSCountryCode">
      <xsl:choose>
        <xsl:when test="$PartyNameCountryCode !=''">
          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',$PartyNameCountryCode,'243'))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="PartyName/CountryCode"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <PartyName>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <AllowPartial>true</AllowPartial>
      <CountryCode>
        <xsl:value-of select="$partyNameAFSCountryCode"/>
      </CountryCode>
      <EffectiveDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </EffectiveDate>
      <ExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyName/ExpirationDate))"/>
      </ExpirationDate>

      <ExternalPartyNameID>
        <xsl:value-of select="$externalPartyNameId"/>
      </ExternalPartyNameID>
      <GeographicFormatCode>
        <xsl:value-of select="string(Util:GetChildKey('8036',$partyNameAFSCountryCode,'243'))"/>
      </GeographicFormatCode>
      <IsPrimary>
        <xsl:value-of select="PartyName/IsPrimary"/>
      </IsPrimary>
      <IsTaxName>
        <xsl:value-of select="PartyName/IsTaxName"/>
      </IsTaxName>
      <LastTransactionID>
        <xsl:value-of select="PartyName/LastTransactionID"/>
      </LastTransactionID>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <PartyID>
        <xsl:value-of select="PartyName/PartyID"/>
      </PartyID>
      <PartyNameID>
        <xsl:value-of select="PartyName/PartyNameID"/>
      </PartyNameID>
      <IsDefault>
        <xsl:value-of select="PartyName/IsDefault"/>
      </IsDefault>
    </PartyName>
  </xsl:template>

  <xsl:template name="InsertPartyName">
    <xsl:variable name="partyNameAFSCountryCode">
      <xsl:choose>
        <xsl:when test="$PartyNameCountryCode !=''">
          <xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',$PartyNameCountryCode,'243'))"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="PartyName/CountryCode"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <PartyName>
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <AllowPartial>true</AllowPartial>
      <CountryCode>
        <xsl:value-of select="$partyNameAFSCountryCode"/>
      </CountryCode>
      <EffectiveDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </EffectiveDate>
      <ExpirationDate>
        <xsl:value-of select="string(Util:GetMaxDate())"/>
      </ExpirationDate>

      <ExternalPartyNameID>
        <xsl:value-of select="$externalPartyNameId"/>
      </ExternalPartyNameID>
      <GeographicFormatCode>
        <xsl:value-of select="string(Util:GetChildKey('8036',$partyNameAFSCountryCode,'243'))"/>
      </GeographicFormatCode>
      <IsPrimary>false</IsPrimary>
      <IsTaxName>false</IsTaxName>
      <LastUpdatedDate>
        <xsl:value-of select="string(Util:GetCurrentDate())"/>
      </LastUpdatedDate>
      <PartyID>
        <xsl:value-of select="$PartyId"/>
      </PartyID>
    </PartyName>
  </xsl:template>

  <xsl:template name="UpdatePhoneToNonPrimaryTemplate" >
    <Comment>
      <xsl:value-of select="Comment"/>
    </Comment>

    <CountryCode>
      <xsl:value-of select="CountryCode"/>
    </CountryCode>
    <EffectiveDate>
      <xsl:value-of select="string(Util:ConvertDateToAswFormat(EffectiveDate))"/>
    </EffectiveDate>
    <ExpirationDate>
      <xsl:value-of select="string(Util:ConvertDateToAswFormat(ExpirationDate))"/>
    </ExpirationDate>
    <FullPhoneNumber>
      <xsl:value-of select="FullPhoneNumber"/>
    </FullPhoneNumber>
    <GeographicFormatCode>
      <xsl:value-of select="GeographicFormatCode"/>
    </GeographicFormatCode>
    <IsPrimary>false</IsPrimary>
    <LastTransactionID>
      <xsl:value-of select="LastTransactionID"/>
    </LastTransactionID>
    <LastUpdatedDate>
      <xsl:value-of select="string(Util:GetCurrentDate())"/>
    </LastUpdatedDate>
    <PartyID>
      <xsl:value-of select="PartyID"/>
    </PartyID>
    <PartyPhoneID>
      <xsl:value-of select="PartyPhoneID"/>
    </PartyPhoneID>
    <PhoneExtension>
      <xsl:value-of select="PhoneExtension"/>
    </PhoneExtension>
    <PhoneTypeCode>
      <xsl:value-of select="PhoneTypeCode"/>
    </PhoneTypeCode>
  </xsl:template>


  <xsl:template match="*" mode="copy" xmlns:ExtType="AFS.AEF.WCF.Types" xmlns="AFS.AEF.WCF.Types">
    <xsl:element name="{name()}">
      <xsl:copy-of select="namespace::*"/>
      <xsl:apply-templates select="@*|node()" mode="copy" />
    </xsl:element>
  </xsl:template>

  <xsl:template match="@*|text()|comment()" mode="copy">
    <xsl:copy/>
  </xsl:template>
  <xsl:template name="ExtendedDataOurs" xmlns="Party.Types" xmlns:d2p1="AFS.AEF.WCF.Types">
    <xsl:param name="ExtDataPath"/>
    <xsl:param name="AswTagName"/>
    <xsl:param name="PhysicalTableName"/>
    <xsl:param name="LogicalTableName"/>
    <xsl:param name="LogicalColumnName"/>
    <xsl:variable name="OutTag">
      <xsl:choose>
        <xsl:when test="$AswTagName!=''">
          <xsl:value-of select="$AswTagName" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$ExtDataPath" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$OutTag}">
      <d2p1:PhysicalTableName>
        <xsl:value-of select="$PhysicalTableName" />
      </d2p1:PhysicalTableName>
      <d2p1:ExtendedFields>
        <d2p1:ExtendedFieldDTO>
          <d2p1:LogicalTableName>
            <xsl:value-of select="$LogicalTableName" />
          </d2p1:LogicalTableName>
          <d2p1:LogicalColumnName>
            <xsl:value-of select="$LogicalColumnName" />
          </d2p1:LogicalColumnName>
          <d2p1:DataType>XElement</d2p1:DataType>
          <d2p1:XMLValue>
            <xsl:copy-of select="$ExtDataPath"/>
          </d2p1:XMLValue>
        </d2p1:ExtendedFieldDTO>
      </d2p1:ExtendedFields>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
