<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:d2p1="AFS.AEF.WCF.Types" xmlns:d4p1="Address.Types" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="d2p1 d4p1 xs msxsl xsl Util">
  <xsl:import href="PartyLocationTemplate_ASWToDuck.xslt"/>
  <xsl:import href="PartyPhoneTemplate_ASWToDuck.xslt"/>
  <xsl:import href="PartyBusNameTemplate_HL_ASWToDuck.xslt"/>
  <xsl:import href="PartyIndNameTemplate_HL_ASWToDuck.xslt"/>
  <xsl:import href="PartyEmailTemplate_ASWToDuck.xslt"/>
  <xsl:import href="PartyReferenceTemplate_ASWToDuck.xslt"/>
  <xsl:import href="PartyLicenseTemplate_ASWToDuck.xslt"/>
  <xsl:import href="PartyRelationshipTemplate_ASWToDuck.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />
  <xsl:variable name="LegacyNameTypeCode" select="06" />
  <xsl:variable name="CorrespondenceNameTypeCode" select="07" />
  <xsl:template match="/PartyDetailDTO">
    <xsl:choose>
      <!--This condition is to add the Parties tag over the response in case of getpartylite-->
      <xsl:when test="$MethodName = 'GetPartyDetails'">
        <Parties>
          <xsl:call-template name="partyRecordTemplate">
          </xsl:call-template>
        </Parties>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="partyRecordTemplate">
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template name="partyRecordTemplate">
    <PartyRecord xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <PartyRecordPartyId>
        <xsl:value-of select="PartyID"/>
      </PartyRecordPartyId>
      <!-- If condition on Party Type, seperate templates for both Individual and Business party-->
      <xsl:choose>
        <!--Party Type = Individual-->
        <!--<xsl:when test="PartyType = 'IND'">-->
        <xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyType)) = string(Util:getBasePartyTypeFromASWPartyType('IND'))">
          <xsl:call-template name="indPartyInfo" />
          <xsl:choose>
            <xsl:when test="$MethodName = 'GetPartyDetails'">
              <PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <xsl:if test="count(PartyIndividualDetail/PartyEmail/PartyEmailDTO) > 0">
                  <xsl:for-each select="PartyIndividualDetail/PartyEmail/PartyEmailDTO">
                    <xsl:call-template name="indPartyEmails" />
                  </xsl:for-each>
                </xsl:if>
              </PartyEmails>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="count(PartyIndividualDetail/PartyEmail/PartyEmailDTO) > 0">
                <PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                  <xsl:for-each select="PartyIndividualDetail/PartyEmail/PartyEmailDTO">
                    <xsl:call-template name="indPartyEmails" />
                  </xsl:for-each>
                </PartyEmails>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test="$MethodName = 'GetPartyDetails'">
              <PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <xsl:if test="count(PartyIndividualDetail/PartyPhone/PartyPhoneDTO) > 0">
                  <xsl:for-each select="PartyIndividualDetail/PartyPhone/PartyPhoneDTO">
                    <xsl:call-template name="indPartyPhones" />
                  </xsl:for-each>
                </xsl:if>
              </PartyPhones>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="count(PartyIndividualDetail/PartyPhone/PartyPhoneDTO) > 0">
                <PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                  <xsl:for-each select="PartyIndividualDetail/PartyPhone/PartyPhoneDTO">
                    <xsl:call-template name="indPartyPhones" />
                  </xsl:for-each>
                </PartyPhones>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="$MethodName != 'GetPartyDetails'">
            <xsl:if test="count(PartyIndividualDetail/PartyMembership/PartyMembershipDTO) > 0">
              <PartyReferences xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <xsl:for-each select="PartyIndividualDetail/PartyMembership/PartyMembershipDTO">
                  <xsl:call-template name="indPartyReferences" />
                </xsl:for-each>
              </PartyReferences>
            </xsl:if>
            <xsl:if test="count(PartyIndividualDetail/PartyLicense/PartyLicenseDTO) > 0">
              <PartyLicenses xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <xsl:for-each select="PartyIndividualDetail/PartyLicense/PartyLicenseDTO">
                  <xsl:call-template name="indPartyLicences" />
                </xsl:for-each>
              </PartyLicenses>
            </xsl:if>
            <xsl:if test="count(PartyIndividualDetail/PartyRelation/PartyRelationDTO[RelationshipTypeCode != 'ORG']) > 0">
              <PartyRelationships xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <xsl:for-each select="PartyIndividualDetail/PartyRelation/PartyRelationDTO[RelationshipTypeCode != 'ORG']">
                  <xsl:call-template name="indPartyRelationship" />
                </xsl:for-each>
              </PartyRelationships>
            </xsl:if>
            <xsl:if test="count(PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO/PartyName) > 0">
              <PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                <xsl:for-each select="PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO">
                  <xsl:if test="PartyIndName/NameTypeCode != $LegacyNameTypeCode and PartyIndName/NameTypeCode != $CorrespondenceNameTypeCode and Util:ValidateOtherNameTypeFilter(PartyIndName/NameTypeCode) = 'true'">
                    <xsl:for-each select="PartyIndName">
                      <xsl:call-template name="PartyIndName"/>
                    </xsl:for-each>
                  </xsl:if>
                </xsl:for-each>
              </PartyOtherNames>
            </xsl:if>
          </xsl:if>
          <xsl:if test="count(PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address) > 0">
            <Locations>
              <xsl:for-each select="PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address">
                <xsl:if test="$MethodName != 'GetPartyDetails' or ../PartyAddress/IsDefault = 'true'">
                  <xsl:call-template name="indPartyAddress" />
                </xsl:if>
              </xsl:for-each>
            </Locations>
          </xsl:if>
          <xsl:if test="$MethodName = 'GetPartyDetails'">
            <AuthorizedInterest>
              <Name>1</Name>
            </AuthorizedInterest>
          </xsl:if>
        </xsl:when>

        <!--Party Type = Business-->
        <xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyType)) = string(Util:getBasePartyTypeFromASWPartyType('BUS'))">

          <xsl:variable name="AgencyID">
            <xsl:if test="PartyBusinessDetail/PartyBusiness/IsAgency = 'true' and $MethodName = 'GetPartyDetails'">
              <xsl:for-each select="PartyBusinessDetail/PartyMembership/PartyMembershipDTO[MembershipTypeCode = 'AGCX']">
                <xsl:value-of select="MembershipID" />
              </xsl:for-each>
            </xsl:if>
          </xsl:variable>

          <xsl:choose>
            <!--If its an agency party then do not return all data, just partyid, agencyid and partytypecode is required in the response-->
            <xsl:when test="$AgencyID != ''">
              <AgencyId>
                <xsl:value-of select="$AgencyID" />
              </AgencyId>
              <Party>
                <PartyTypeCode>AG</PartyTypeCode>
              </Party>
              <xsl:choose>
                <xsl:when test="$MethodName = 'GetPartyDetails'">
                  <PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <xsl:if test="count(PartyBusinessDetail/PartyEmail/PartyEmailDTO) > 0">
                      <xsl:for-each select="PartyBusinessDetail/PartyEmail/PartyEmailDTO">
                        <xsl:call-template name="indPartyEmails" />
                      </xsl:for-each>
                    </xsl:if>
                  </PartyEmails>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:if test="count(PartyBusinessDetail/PartyEmail/PartyEmailDTO) > 0">
                    <PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                      <xsl:for-each select="PartyBusinessDetail/PartyEmail/PartyEmailDTO">
                        <xsl:call-template name="indPartyEmails" />
                      </xsl:for-each>
                    </PartyEmails>
                  </xsl:if>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!--if not agency, then return all data-->
            <xsl:otherwise>
              <xsl:call-template name="busPartyInfo" />

              <xsl:choose>
                <xsl:when test="$MethodName = 'GetPartyDetails'">
                  <PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <xsl:if test="count(PartyBusinessDetail/PartyEmail/PartyEmailDTO) > 0">
                      <xsl:for-each select="PartyBusinessDetail/PartyEmail/PartyEmailDTO">
                        <xsl:call-template name="indPartyEmails" />
                      </xsl:for-each>
                    </xsl:if>
                  </PartyEmails>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:if test="count(PartyBusinessDetail/PartyEmail/PartyEmailDTO) > 0">
                    <PartyEmails xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                      <xsl:for-each select="PartyBusinessDetail/PartyEmail/PartyEmailDTO">
                        <xsl:call-template name="indPartyEmails" />
                      </xsl:for-each>
                    </PartyEmails>
                  </xsl:if>
                </xsl:otherwise>
              </xsl:choose>

              <xsl:choose>
                <xsl:when test="$MethodName = 'GetPartyDetails'">
                  <PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <xsl:if test="count(PartyBusinessDetail/PartyPhone/PartyPhoneDTO) > 0">
                      <xsl:for-each select="PartyBusinessDetail/PartyPhone/PartyPhoneDTO">
                        <xsl:call-template name="indPartyPhones" />
                      </xsl:for-each>
                    </xsl:if>
                  </PartyPhones>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:if test="count(PartyBusinessDetail/PartyPhone/PartyPhoneDTO) > 0">
                    <PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                      <xsl:for-each select="PartyBusinessDetail/PartyPhone/PartyPhoneDTO">
                        <xsl:call-template name="indPartyPhones" />
                      </xsl:for-each>
                    </PartyPhones>
                  </xsl:if>
                </xsl:otherwise>
              </xsl:choose>

              <xsl:if test="$MethodName != 'GetPartyDetails'">
                <xsl:if test="count(PartyBusinessDetail/PartyMembership/PartyMembershipDTO) > 0">
                  <PartyReferences xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <xsl:for-each select="PartyBusinessDetail/PartyMembership/PartyMembershipDTO">
                      <xsl:call-template name="indPartyReferences" />
                    </xsl:for-each>
                  </PartyReferences>
                </xsl:if>

                <xsl:if test="count(PartyBusinessDetail/PartyLicense/PartyLicenseDTO) > 0">
                  <PartyLicenses xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <xsl:for-each select="PartyBusinessDetail/PartyLicense/PartyLicenseDTO">
                      <xsl:call-template name="indPartyLicences" />
                    </xsl:for-each>
                  </PartyLicenses>
                </xsl:if>

                <xsl:if test="count(PartyBusinessDetail/PartyRelation/PartyRelationDTO[RelationshipTypeCode != 'ORG']) > 0">
                  <PartyRelationships xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <xsl:for-each select="PartyBusinessDetail/PartyRelation/PartyRelationDTO[RelationshipTypeCode != 'ORG']">
                      <xsl:call-template name="indPartyRelationship" />
                    </xsl:for-each>
                  </PartyRelationships>
                </xsl:if>
                <xsl:if test="count(PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO/PartyName) > 0">
                  <PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                    <xsl:for-each select="PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO">
                      <xsl:if test="PartyBusName/NameTypeCode != $LegacyNameTypeCode and PartyBusName/NameTypeCode != $CorrespondenceNameTypeCode and Util:ValidateOtherNameTypeFilter(PartyBusName/NameTypeCode) = 'true'">
                        <xsl:for-each select="PartyBusName">
                          <xsl:call-template name="PartyBusName"/>
                        </xsl:for-each>
                      </xsl:if>
                    </xsl:for-each>
                  </PartyOtherNames>
                </xsl:if>

              </xsl:if>
              <xsl:if test="count(PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address) > 0">
                <Locations>
                  <xsl:for-each select="PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address">
                    <xsl:if test="$MethodName != 'GetPartyDetails' or ../PartyAddress/IsDefault = 'true'">
                      <xsl:call-template name="indPartyAddress" />
                    </xsl:if>
                  </xsl:for-each>
                </Locations>
              </xsl:if>
              <xsl:if test="$MethodName = 'GetPartyDetails'">
                <AuthorizedInterest>
                  <Name>1</Name>
                </AuthorizedInterest>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>

      <xsl:if test="$MethodName != 'GetPartyDetails'">
        <xsl:call-template name="ResponseInfo">
          <xsl:with-param name="ReturnCode">0</xsl:with-param>
          <xsl:with-param name="NotificationResponse"/>
        </xsl:call-template>
      </xsl:if>
    </PartyRecord>
  </xsl:template>

  <xsl:template name="indPartyInfo" >
    <Party>
      <xsl:if test="$MethodName != 'GetPartyDetails'">
        <PartyId>
          <xsl:value-of select="PartyID" />
        </PartyId>
        <PartyOFACCheckNotRequired>
          <xsl:value-of select="PartyIndividualDetail/Party/BusinessPermitted" />
        </PartyOFACCheckNotRequired>
      </xsl:if>
      <PartyNumber>
        <xsl:value-of select="PartyIndividualDetail/Party/Number" />
      </PartyNumber>
      <xsl:for-each select="PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO/PartyName[IsDefault = 'true']">
        <xsl:variable name="partyName" select="concat(../PartyIndName/FirstName,' ',../PartyIndName/LastName)" />
        <PartyName>
          <xsl:value-of select="../PartyIndName/LastName" />
        </PartyName>
        <PartyFirstName>
          <xsl:value-of select="../PartyIndName/FirstName" />
        </PartyFirstName>
        <PartyMiddleName>
          <xsl:value-of select="../PartyIndName/MiddleName" />
        </PartyMiddleName>
        <xsl:choose>
          <xsl:when test="$MethodName = 'GetPartyDetails'">
            <PartyNamePrefix>
              <!--FOR GetPartyDetails it should not be code it should be value-->
              <xsl:value-of select="string(Util:GetChildKey('DCTNamePrefixValue',../PartyIndName/PrefixCode,'34'))"/>
            </PartyNamePrefix>
            <PartyNameSuffix>
              <!--TO DO : Code Decode value-->
              <xsl:value-of select="string(Util:GetChildKey('DCTNameSuffixValue',../PartyIndName/SuffixCode,'48'))"/>
            </PartyNameSuffix>
          </xsl:when>
          <xsl:otherwise>
            <PartyNamePrefixCode>
              <!--TO DO : Code Decode value-->
              <xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',../PartyIndName/PrefixCode,'34'))"/>
            </PartyNamePrefixCode>
            <PartyNameSuffixCode>
              <!--TO DO : Code Decode value-->
              <xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',../PartyIndName/SuffixCode,'48'))"/>
            </PartyNameSuffixCode>
          </xsl:otherwise>
        </xsl:choose>
        <PartyNameEffectiveDate>
          <xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
        </PartyNameEffectiveDate>
        <PartyNameExpirationDate>
          <xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
        </PartyNameExpirationDate>
        <PartyNameComments>
          <xsl:value-of select="../PartyIndName/Comment"/>
        </PartyNameComments>
        <xsl:choose>
          <xsl:when test="string(../../../Party/PartySubTypeCode) != ''">
            <PartyTypeCode>
              <!--TO DO : Code Decode value-->
              <xsl:value-of select="string(Util:GetChildKey('DCTPartyType',../../../Party/PartySubTypeCode,'PartySubType'))"/>
            </PartyTypeCode>
          </xsl:when>
          <xsl:otherwise>
            <PartyTypeCode>
              <!--TO DO : Code Decode value-->
              <xsl:value-of select="string(Util:GetChildKey('DCTPartyType',../../../Party/PartyTypeCode,'8001'))"/>
            </PartyTypeCode>
          </xsl:otherwise>
        </xsl:choose>
		<xsl:if test="string(Util:ShowPartyTimeZone(../../../Party/PartyTimeZone)) != ''">
			<PartyTimeZone>
				<xsl:value-of select="string(Util:GetChildKey('DCTTimeZones',../../../Party/PartyTimeZone,'TimeZones'))"/>
			</PartyTimeZone>
		</xsl:if>
        <xsl:if test="$MethodName != 'GetPartyDetails'">
          <!--TO DO : Find what is subtype-->
          <PartySubTypeCode xsi:nil="true" />
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$MethodName = 'GetPartyDetails'">
            <PartyGender>
              <!--TO DO : Code decode mapping-->
              <xsl:value-of select="string(Util:GetChildKey('DCTGenderValue',../../../PartyIndividual/GenderCode,'51'))"/>
            </PartyGender>
          </xsl:when>
          <xsl:otherwise>
            <PartyGenderCode>
              <!--TO DO : Code decode mapping-->
              <xsl:value-of select="string(Util:GetChildKey('DCTGender',../../../PartyIndividual/GenderCode,'51'))"/>
            </PartyGenderCode>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test ="../../../PartyIndividual/IsCompanyPersonnel='false'">
            <PartyIsCompanyPersonnel>0</PartyIsCompanyPersonnel>
          </xsl:when>
          <xsl:otherwise>
            <PartyIsCompanyPersonnel>1</PartyIsCompanyPersonnel>
          </xsl:otherwise>
        </xsl:choose>
        <PartyBirthDate>
          <xsl:value-of select="string(Util:ConvertDateToDuckFormat(../../../PartyIndividual/DateOfBirth, false))" />
        </PartyBirthDate>
        <PartyDeathDate>
          <xsl:value-of select="string(Util:ConvertDateToDuckFormat(../../../PartyIndividual/DateOfDeath, false))" />
        </PartyDeathDate>
        <PartyComments>
          <xsl:value-of select="../../../PartyComment/Comment"/>
        </PartyComments>
        <PartyNumberOfDependents>
          <xsl:value-of select="../../../PartyIndividual/NumberOfDependents"/>
        </PartyNumberOfDependents>
        <PartyProfession>
          <xsl:value-of select="../../../PartyIndividual/ProfessionCode"/>
        </PartyProfession>
        <PreferredContactMethod>
          <xsl:value-of select="../../../PartyIndividual/PreferredContactType"/>
        </PreferredContactMethod>
        <xsl:if test="$MethodName != 'GetPartyDetails'">
          <PartyMaritalStatusCode>
            <!--TO DO : Code Decode value-->
            <xsl:value-of select="string(Util:GetChildKey('DCTMaritalStatus',../../../PartyIndividual/MaritalStatusCode,'35'))"/>
          </PartyMaritalStatusCode>
          <!--TO DO : properties not found in ASW-->
          <!--<PartyTaxId>
						-->
          <!--Mapping it to SSN in ASW-->
          <!--
						<xsl:value-of select="../../../PartyIndividual/SpecificPurposeID" />
					</PartyTaxId>-->
          <PartyTaxId>
            <!--Mapping it to SSN in ASW-->
	    <!--#7439-AU specific code changes for tfn number display-->
           <xsl:choose>
	    <xsl:when test="../../../Party/CountryCode ='79' and ../../../PartyIndividual/SpecificPurposeID !='' ">
	    <xsl:value-of select="substring(../../../PartyIndividual/SpecificPurposeID, 1,3)"/>
	    <xsl:text>-</xsl:text>
	    <xsl:value-of select="substring(../../../PartyIndividual/SpecificPurposeID, 4,3)"/>
	    <xsl:text>-</xsl:text>
	    <xsl:value-of select="substring(../../../PartyIndividual/SpecificPurposeID, 7,3)"/>
	    </xsl:when>
	    <xsl:otherwise>
            <xsl:value-of select="../../../PartyIndividual/SpecificPurposeID" />  <!--#5814-Removed SSN format mask as its not required for ird number-->
	    </xsl:otherwise>
	   </xsl:choose>
          </PartyTaxId>
          <PartyNationality xsi:nil="true" />
          <PartyPartyOwner xsi:nil="true" />
          <!--/-->
          <PartyPreferredLanguageCode >
            <!--TO DO : Code decode mapping-->
            <xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',../../../PartyIndividual/PreferredLanguage,'8037'))"/>
          </PartyPreferredLanguageCode>
        </xsl:if>

        <xsl:for-each select="../../PartyIndNameDetailDTO/PartyIndName[NameTypeCode = $LegacyNameTypeCode or NameTypeCode = $CorrespondenceNameTypeCode]">
          <xsl:sort data-type="number" order="descending" select="NameTypeCode"/>
          <xsl:choose>
            <xsl:when test="NameTypeCode=$CorrespondenceNameTypeCode">
              <PartyCorrespondenceName>
                <xsl:value-of select="FullName" />
              </PartyCorrespondenceName>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="$MethodName != 'GetPartyDetails'">
                <PartyLegacyName>
                  <xsl:value-of select="FullName" />
                </PartyLegacyName>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>

        <PartyCountryCode>
          <xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../../../Party/CountryCode,'243'))"/>
        </PartyCountryCode>
        <PartyNameCountryCode>
          <xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../PartyName/CountryCode,'243'))"/>
        </PartyNameCountryCode>

        <!--<PartyCorrespondenceName>
          <xsl:value-of select="$partyName" />
        </PartyCorrespondenceName>-->
        <xsl:if test="$MethodName != 'GetPartyDetails'">
          <!--<PartyLegacyName>
            <xsl:value-of select="$partyName" />
          </PartyLegacyName>-->
          <PartyLockingTS>
            <xsl:value-of select="../../../Party/LastTransactionID" />
          </PartyLockingTS>
          <xsl:for-each select="../../../PartyIndividual">
			  <xsl:for-each select="./IndividualExtendedData/ExtendedFields/ExtendedFieldDTO">
				<xsl:call-template name="ASWExtendedDataToDuck">
				  <xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>
				</xsl:call-template>
			  </xsl:for-each>
			  
			  <PartyIndividualSuiteExtendedData>
				<xsl:for-each select="./IndividualExtendedData/ExtendedFields/ExtendedFieldDTO">
					<xsl:call-template name="SuiteASWExtendedDataToDuck">
						<xsl:with-param name="SuiteTagName">PartyIndividualSuiteExtendedData</xsl:with-param>
					</xsl:call-template>
				</xsl:for-each>
			</PartyIndividualSuiteExtendedData>
			
		  </xsl:for-each>
        </xsl:if>
      </xsl:for-each>
    </Party>
  </xsl:template>
  <xsl:template name="busPartyInfo">
    <Party>
      <xsl:if test="$MethodName != 'GetPartyDetails'">
        <PartyId>
          <xsl:value-of select="PartyID" />
        </PartyId>
        <PartyOFACCheckNotRequired>
          <xsl:value-of select="PartyBusinessDetail/Party/BusinessPermitted" />
        </PartyOFACCheckNotRequired>
        <xsl:choose>
          <xsl:when test ="PartyBusinessDetail/PartyBusiness/IsSupplier='false'">
            <PartySupplier>0</PartySupplier>
          </xsl:when>
          <xsl:otherwise>
            <PartySupplier>1</PartySupplier>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <PartyNumber>
        <xsl:value-of select="PartyBusinessDetail/Party/Number" />
      </PartyNumber>
      <xsl:for-each select="PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO/PartyName[IsDefault = 'true']">
        <PartyName>
          <xsl:value-of select="../PartyBusName/Name" />
        </PartyName>
        <PartyFirstName xsi:nil="true">
          <!-- TO DO : this field is not available in ASW-->
        </PartyFirstName>
        <PartyMiddleName xsi:nil="true">
          <!-- TO DO : this field is not available in ASW-->
        </PartyMiddleName>
        <xsl:choose>
          <xsl:when test="$MethodName = 'GetPartyDetails'">
            <PartyNamePrefix xsi:nil="true">
              <!-- TO DO : this field is not available in ASW-->
            </PartyNamePrefix>
            <PartyNameSuffix xsi:nil="true">
              <!-- TO DO : this field is not available in ASW-->
            </PartyNameSuffix>
          </xsl:when>
          <xsl:otherwise>
            <PartyNamePrefixCode>
              <!-- TO DO : this field is not available in ASW-->
            </PartyNamePrefixCode>
            <PartyNameSuffixCode>
              <!-- TO DO : this field is not available in ASW-->
            </PartyNameSuffixCode>
          </xsl:otherwise>
        </xsl:choose>
        <PartyNameEffectiveDate>
          <xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
        </PartyNameEffectiveDate>
        <PartyNameExpirationDate>
          <xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
        </PartyNameExpirationDate>
        <PartyNameComments>
          <xsl:value-of select="../PartyBusName/Comment"/>
        </PartyNameComments>
        <xsl:choose>
          <xsl:when test="string(../../../Party/PartySubTypeCode) != ''">
            <PartyTypeCode>
              <!--IsAgency Added for AG Party Type Code-->
              <xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',../../../Party/PartySubTypeCode,'PartySubType',../../../PartyBusiness/IsAgency))"/>
            </PartyTypeCode>
          </xsl:when>
          <xsl:otherwise>
            <PartyTypeCode>
              <!--IsAgency Added for AG Party Type Code-->
              <xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',../../../Party/PartyTypeCode,'8001',../../../PartyBusiness/IsAgency))"/>
            </PartyTypeCode>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$MethodName != 'GetPartyDetails'">
          <!--TO DO : Find what is subtype-->
          <PartySubTypeCode>
            <!--Mapping it to Business Type code of ASW-->
            <xsl:value-of select="string(Util:GetChildKey('DCTBusinessType',../../../PartyBusiness/BusinessTypeCode,'427'))"/>
          </PartySubTypeCode>
        </xsl:if>
		<xsl:if test="string(Util:ShowPartyTimeZone(../../../Party/PartyTimeZone)) != ''">
			<PartyTimeZone>
				<xsl:value-of select="string(Util:GetChildKey('DCTTimeZones',../../../Party/PartyTimeZone,'TimeZones'))"/>
			</PartyTimeZone>
		</xsl:if>
        <xsl:choose>
          <xsl:when test="$MethodName = 'GetPartyDetails'">
            <PartyGender xsi:nil="true">
              <!-- TO DO : this field is not available in ASW-->
            </PartyGender>
          </xsl:when>
          <xsl:otherwise>
            <PartyGenderCode>
              <!-- TO DO : this field is not available in ASW-->
            </PartyGenderCode>
          </xsl:otherwise>
        </xsl:choose>
        <PartyBirthDate xsi:nil="true">
          <!-- TO DO : this field is not available in ASW-->
        </PartyBirthDate>
        <PreferredContactMethod>
          <xsl:value-of select="../../../PartyBusiness/PreferredContactType"/>
        </PreferredContactMethod>
        <xsl:if test="$MethodName != 'GetPartyDetails'">
          <PartyMaritalStatusCode>
            <!-- TO DO : this field is not available in ASW-->
          </PartyMaritalStatusCode>
          <!--TO DO : properties not found in ASW-->
          <PartyTaxId>
            <!--Mapping it to TIN of ASW-->
            <xsl:value-of select="../../../PartyBusiness/RegistrationID1" />
          </PartyTaxId>
	  <PartyTaxId2>
            <!--Mapping it to TIN of ASW-->
            <xsl:value-of select="../../../PartyBusiness/RegistrationID2" />  <!--#5814-Added for nzbn mapping  -->
          </PartyTaxId2>
          <PartyNationality xsi:nil="true" />
          <PartyPartyOwner xsi:nil="true" />
          <!--/-->
          <PartyPreferredLanguageCode >
            <!--TO DO : Code decode mapping-->
            <xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',../../../PartyBusiness/PreferredLanguage,'8037'))"/>
          </PartyPreferredLanguageCode>
        </xsl:if>
        <xsl:for-each select="../../PartyBusNameDetailDTO/PartyBusName[NameTypeCode = $LegacyNameTypeCode or NameTypeCode = $CorrespondenceNameTypeCode]">
          <xsl:sort data-type="number" order="descending" select="NameTypeCode"/>
          <xsl:choose>
            <xsl:when test="NameTypeCode=$CorrespondenceNameTypeCode">
              <PartyCorrespondenceName>
                <xsl:value-of select="Name" />
              </PartyCorrespondenceName>
            </xsl:when>
            <xsl:otherwise>
              <xsl:if test="$MethodName != 'GetPartyDetails'">
                <PartyLegacyName>
                  <xsl:value-of select="Name" />
                </PartyLegacyName>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>

        <PartyCountryCode>
          <xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../../../Party/CountryCode,'243'))"/>
        </PartyCountryCode>
        <PartyNameCountryCode>
          <xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../PartyName/CountryCode,'243'))"/>
        </PartyNameCountryCode>

        <!--<PartyCorrespondenceName>
          <xsl:value-of select="../PartyBusName/Name" />
        </PartyCorrespondenceName>-->
        <xsl:if test="$MethodName != 'GetPartyDetails'">
          <!--<PartyLegacyName>
            <xsl:value-of select="../PartyBusName/Name" />
          </PartyLegacyName>-->
          <PartyLockingTS>
            <xsl:value-of select="../../../Party/LastTransactionID" />
          </PartyLockingTS>
          <xsl:for-each select="../../../PartyBusiness">
            <xsl:for-each select="./BusinessExtendedData/ExtendedFields/ExtendedFieldDTO">
              <xsl:call-template name="ASWExtendedDataToDuck">
                <xsl:with-param name="TagName">PartyExtendedData</xsl:with-param>                
              </xsl:call-template>
            </xsl:for-each>
			
			<PartyBusinessSuiteExtendedData>
				<xsl:for-each select="./BusinessExtendedData/ExtendedFields/ExtendedFieldDTO">
					<xsl:call-template name="SuiteASWExtendedDataToDuck">
						<xsl:with-param name="SuiteTagName">PartyBusinessSuiteExtendedData</xsl:with-param>
					</xsl:call-template>
				</xsl:for-each>
			</PartyBusinessSuiteExtendedData>
			
          </xsl:for-each>
        </xsl:if>
        <PartyComments>
          <xsl:value-of select="../../../PartyComment/Comment"/>
        </PartyComments>
      </xsl:for-each>
    </Party>
  </xsl:template>
</xsl:stylesheet>