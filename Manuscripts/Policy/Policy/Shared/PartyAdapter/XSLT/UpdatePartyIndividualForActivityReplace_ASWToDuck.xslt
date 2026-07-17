<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:template match="/PartyIndividualBulkDetailsDTO">
		<PartyRecord xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<PartyRecordPartyId>
				<xsl:value-of select="Party/PartyID"/>
			</PartyRecordPartyId>
			
					<xsl:call-template name="indPartyInfo" />
			
		</PartyRecord>
	</xsl:template>

	<xsl:template name="indPartyInfo" >
		<Party>
			<PartyId>
				<xsl:value-of select="Party/PartyID"/>
			</PartyId>
      <!--For replace party default name-->
      <xsl:for-each select="PartyIndNamesToReplace/ReplacePartyIndNameDetailDTO">
        <PartyName>
          <xsl:value-of select="PartyIndNameDetailWithExtendedData/PartyIndName/LastName" />
        </PartyName>
        <PartyFirstName>
          <xsl:value-of select="PartyIndNameDetailWithExtendedData/PartyIndName/FirstName" />
        </PartyFirstName>
        <PartyMiddleName>
          <xsl:value-of select="PartyIndNameDetailWithExtendedData/PartyIndName/MiddleName" />
        </PartyMiddleName>
        <PartyNamePrefixCode>
          <xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',PartyIndNameDetailWithExtendedData/PartyIndName/PrefixCode,'34'))"/>
        </PartyNamePrefixCode>
        <PartyNameSuffixCode>
          <xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',PartyIndNameDetailWithExtendedData/PartyIndName/SuffixCode,'48'))"/>
        </PartyNameSuffixCode>
      </xsl:for-each>
      <xsl:choose>
        <xsl:when test="string(Party/PartySubTypeCode) != ''">
          <PartyTypeCode>
            <xsl:value-of select="string(Util:GetChildKey('DCTPartyType',Party/PartySubTypeCode,'PartySubType'))"/>
          </PartyTypeCode>
        </xsl:when>
        <xsl:otherwise>
          <PartyTypeCode>
            <xsl:value-of select="string(Util:GetChildKey('DCTPartyType',Party/PartyTypeCode,'8001'))"/>
          </PartyTypeCode>
        </xsl:otherwise>
      </xsl:choose>
      <PartySubTypeCode xsi:nil="true" />
      <PartyGenderCode>
        <xsl:value-of select="string(Util:GetChildKey('DCTGender',PartyIndividual/GenderCode,'51'))"/>
      </PartyGenderCode>
      <PartyBirthDate>
        <xsl:value-of select="string(Util:ConvertDateToDuckFormat(PartyIndividual/DateOfBirth, false))" />
      </PartyBirthDate>
      <PartyMaritalStatusCode>
        <xsl:value-of select="string(Util:GetChildKey('DCTMaritalStatus',PartyIndividual/MaritalStatusCode,'35'))"/>
      </PartyMaritalStatusCode>
      <!--<PartyTaxId>
						<xsl:value-of select="PartyIndividual/SpecificPurposeID" />
					</PartyTaxId>-->
          <PartyTaxId>
            <xsl:value-of select="string(Util:GetSSNForDuck(PartyIndividual/SpecificPurposeID))"/>
          </PartyTaxId>
          <PartyNationality xsi:nil="true" />
          <PartyPartyOwner xsi:nil="true" />
					<!--/-->
					<PartyPreferredLanguageCode >
            <xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',PartyIndividual/PreferredLanguage,'8037'))"/>
					</PartyPreferredLanguageCode>

      <xsl:for-each select="PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '06' or NameTypeCode = '07']">
        <xsl:choose>
          <xsl:when test="NameTypeCode='07'">
            <PartyCorrespondenceName>
              <xsl:value-of select="FullName" />
            </PartyCorrespondenceName>
          </xsl:when>
          <xsl:when test="NameTypeCode='06'">
            <PartyLegacyName>
              <xsl:value-of select="FullName" />
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