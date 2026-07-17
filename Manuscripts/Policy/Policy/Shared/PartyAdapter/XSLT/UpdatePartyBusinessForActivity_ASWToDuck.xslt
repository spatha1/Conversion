<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:import href="UpdatePartyForActivity_CommonTemplate.xslt"/>
	<xsl:import href="PartyLocationTemplate_ASWToDuck.xslt"/>
	
	<xsl:template match="/PartyBusinessBulkDetailsDTO">
		<PartyRecord xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<PartyRecordPartyId>
				<xsl:value-of select="Party/PartyID"/>
			</PartyRecordPartyId>
				<xsl:call-template name="busPartyInfo" />

			<xsl:if test="count(PartyAddressesToInsert/PartyAddressDetailWithExtendedDataDTO/Address) > 0
					or count(PartyAddressesToUpdate/PartyAddressDetailDTO/Address) > 0">
				<Locations  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
					<xsl:for-each select="PartyAddressesToInsert/PartyAddressDetailWithExtendedDataDTO/Address">
						<xsl:call-template name="indPartyAddress" >
							<xsl:with-param name="InsertIndicator" select="'1'"/>
							<xsl:with-param name="UpdateIndicator" select="'0'"/>
						</xsl:call-template>
					</xsl:for-each>
					<xsl:for-each select="PartyAddressesToUpdate/PartyAddressDetailDTO/Address">
						<xsl:call-template name="indPartyAddress">
							<xsl:with-param name="InsertIndicator" select="'0'"/>
							<xsl:with-param name="UpdateIndicator" select="'1'"/>
						</xsl:call-template>
					</xsl:for-each>
				</Locations>
			</xsl:if>

			<xsl:if test="count(PartyPhonesToInsert/PartyPhoneWithExtendedDataDTO/PartyPhone) > 0
					or count(PartyPhonesToUpdate/PartyPhoneDTO) > 0">
				<PartyPhones xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
					<xsl:for-each select="PartyPhonesToInsert/PartyPhoneWithExtendedDataDTO/PartyPhone">
						<xsl:call-template name="PartyPhones">
							<xsl:with-param name="InsertIndicator" select="'1'"/>
							<xsl:with-param name="UpdateIndicator" select="'0'"/>
						</xsl:call-template>
					</xsl:for-each>
					<xsl:for-each select="PartyPhonesToUpdate/PartyPhoneDTO">
						<xsl:call-template name="PartyPhones">
							<xsl:with-param name="InsertIndicator" select="'0'"/>
							<xsl:with-param name="UpdateIndicator" select="'1'"/>
						</xsl:call-template>
					</xsl:for-each>
				</PartyPhones>
			</xsl:if>

			<xsl:if test="count(PartyBusNamesToInsert/PartyBusNameDetailWithExtendedDataDTO/PartyBusName[NameTypeCode = '04']) > 0
					or count(PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '04']) > 0">
				<PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
					<xsl:for-each select="PartyBusNamesToInsert/PartyBusNameDetailWithExtendedDataDTO/PartyBusName[NameTypeCode = '04']">
						<xsl:call-template name="PartyOtherName" >
							<xsl:with-param name="InsertIndicator" select="'1'"/>
							<xsl:with-param name="UpdateIndicator" select="'0'"/>
						</xsl:call-template>
					</xsl:for-each>
					<xsl:for-each select="PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '04']">
						<xsl:call-template name="PartyOtherName" >
							<xsl:with-param name="InsertIndicator" select="'0'"/>
							<xsl:with-param name="UpdateIndicator" select="'1'"/>
						</xsl:call-template>
					</xsl:for-each>
				</PartyOtherNames>
			</xsl:if>

			<xsl:call-template name="ResponseInfo">
				<xsl:with-param name="ReturnCode">0</xsl:with-param>
				<xsl:with-param name="NotificationResponse"></xsl:with-param>
			</xsl:call-template>
			
		</PartyRecord>
	</xsl:template>

	<xsl:template name="busPartyInfo" >
		<Party>
			<PartyId>
				<xsl:value-of select="Party/PartyID"/>
			</PartyId>
      <PartyName>
				<xsl:value-of select="PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName/Name" />
			</PartyName>
      <PartyFirstName>
        <!-- TO DO : this field is not available in ASW-->
      </PartyFirstName>
      <PartyMiddleName>
        <!-- TO DO : this field is not available in ASW-->
      </PartyMiddleName>
      <PartyNamePrefixCode>
        <!-- TO DO : this field is not available in ASW-->
      </PartyNamePrefixCode>
      <PartyNameSuffixCode>
        <!-- TO DO : this field is not available in ASW-->
      </PartyNameSuffixCode>
      <xsl:choose>
        <xsl:when test="string(Party/PartySubTypeCode) !=''">
          <PartyTypeCode>
				    <xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',Party/PartySubTypeCode,'PartySubType',PartyBusiness/IsAgency))"/>
			    </PartyTypeCode>
        </xsl:when>
        <xsl:otherwise>
          <PartyTypeCode>
            <xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',Party/PartyTypeCode,'8001',PartyBusiness/IsAgency))"/>
          </PartyTypeCode>
        </xsl:otherwise>
      </xsl:choose>
      <PartySubTypeCode xsi:nil="true" />
			<PartyGenderCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTGender',PartyBusiness/GenderCode,'51'))"/>
			</PartyGenderCode>
			<PartyBirthDate>
				<xsl:value-of select="string(Util:ConvertDateToDuckFormat(PartyBusiness/DateOfBirth, false))" />
			</PartyBirthDate>
			<PartyMaritalStatusCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTMaritalStatus',PartyBusiness/MaritalStatusCode,'35'))"/>
			</PartyMaritalStatusCode>
			<PartyTaxId>
				<xsl:value-of select="PartyBusiness/RegistrationID1" />
			</PartyTaxId>
			<PartyTaxId2>
				<xsl:value-of select="PartyBusiness/RegistrationID2" />  <!--#5814-Added for nzbn mapping  -->
			</PartyTaxId2>
			<PartyNationality xsi:nil="true" />
			<PartyPartyOwner xsi:nil="true" />
			<!--/-->
			<PartyPreferredLanguageCode >
				<xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',PartyBusiness/PreferredLanguage,'8037'))"/>
			</PartyPreferredLanguageCode>
      <xsl:for-each select="PartyBusNamesToUpdate/PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '06' or NameTypeCode = '07']">
        <xsl:choose>
          <xsl:when test="NameTypeCode='07'">
            <PartyCorrespondenceName>
              <xsl:value-of select="Name" />
            </PartyCorrespondenceName>
          </xsl:when>
          <xsl:when test="NameTypeCode='06'">
            <PartyLegacyName>
              <xsl:value-of select="Name" />
            </PartyLegacyName>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each>
			<PartyDeletedIndicator>0</PartyDeletedIndicator>
			<PartyLockingTS>
				<xsl:value-of select="Party/LastTransactionID" />
			</PartyLockingTS>
      <xsl:value-of disable-output-escaping="yes" select="string(Util:GetValueByKey('ExtendedData'))"/>
		</Party>
	</xsl:template>




</xsl:stylesheet>