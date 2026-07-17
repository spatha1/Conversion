<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:variable name="PrefixCode" select="/PartyData/PartyIndNameDetailDTO/PartyIndName/PrefixCode" />
	<xsl:variable name="SuffixCode" select="/PartyData/PartyIndNameDetailDTO/PartyIndName/SuffixCode" />
	<xsl:variable name="FirstName" select="/PartyData/PartyIndNameDetailDTO/PartyIndName/FirstName" />
	<xsl:variable name="LastName" select="/PartyData/PartyIndNameDetailDTO/PartyIndName/LastName" />
	<xsl:variable name="MiddleName" select="/PartyData/PartyIndNameDetailDTO/PartyIndName/MiddleName" />
	<xsl:variable name="Comment" select="/PartyData/PartyIndNameDetailDTO/PartyIndName/Comment" />
	<xsl:template match="/">
		<ArrayOfPartyIndNameDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
			<xsl:for-each select="/PartyData/ArrayOfPartyNameDetailsDTO/PartyNameDetailsDTO/PartyIndNameDetails/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '06' or PartyIndName/NameTypeCode = '07']">
				<PartyIndNameDetailDTO>
					<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>

					<PartyIndName>
						<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
						<Comment>
							<xsl:value-of select="$Comment"/>
						</Comment>
						<FirstName>
							<xsl:value-of select="$FirstName"/>
						</FirstName>
						<FirstNamePhonetic i:nil="true" />
						<FirstNameSoundex i:nil="true" />
						<FirstNameUpperCase i:nil="true" />
						<FullName>
							<xsl:value-of select="concat($PrefixCode,' ', $FirstName,' ', $MiddleName,' ', $LastName,' ', $SuffixCode)"/>
						</FullName>
						<LastName>
							<xsl:value-of select="$LastName"/>
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
							<xsl:value-of select="$MiddleName"/>
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
							<xsl:value-of select="$PrefixCode"/>
						</PrefixCode>
						<SuffixCode>
							<xsl:value-of select="$SuffixCode"/>
						</SuffixCode>
						<xsl:call-template name="ExtendedData">
							<xsl:with-param name="TagName">OtherNameExtendedData</xsl:with-param>
							<xsl:with-param name="SuiteTagName">PartyOtherNameSuiteExtendedData</xsl:with-param>
							<xsl:with-param name="AswTagName">IndividualNameExtendedData</xsl:with-param>
							<xsl:with-param name="PhysicalTableName">PARTY_INDVDL_NM</xsl:with-param>
							<xsl:with-param name="LogicalTableName">lgclPartyIndvNm</xsl:with-param>
							<xsl:with-param name="LogicalColumnName">PartyIndNameExtData</xsl:with-param>
						</xsl:call-template>
					</PartyIndName>
					<PartyName>
						<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
						<AllowPartial>
							<xsl:value-of select="PartyName/AllowPartial"/>
						</AllowPartial>
						<CountryCode>
							<xsl:value-of select="PartyName/CountryCode"/>
						</CountryCode>
						<EffectiveDate>
							<xsl:value-of select="PartyName/EffectiveDate"/>
						</EffectiveDate>
						<ExpirationDate>
							<xsl:value-of select="string(Util:ConvertDateToAswFormat(PartyName/ExpirationDate))"/>
						</ExpirationDate>
						<ExternalPartyNameID i:nil="true" />
						<GeographicFormatCode>
							<xsl:value-of select="PartyName/GeographicFormatCode"/>
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
			</xsl:for-each>
		</ArrayOfPartyIndNameDetailDTO>
	</xsl:template>
</xsl:stylesheet>



