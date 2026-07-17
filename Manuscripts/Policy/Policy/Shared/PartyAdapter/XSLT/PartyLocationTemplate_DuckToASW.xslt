<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template name="partyLocation">
		<xsl:for-each select="./Locations/Location">
			<PartyAddressDetailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
				<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
				<xsl:call-template name="commonAddressTemaplate" />
				<xsl:call-template name="commonPartyAddressTemaplate" />
			</PartyAddressDetailDTO>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="partyLocationExtendedData">
		<xsl:for-each select="./Locations/Location">
			<PartyAddressDetailWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
				<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
				<xsl:call-template name="commonAddressTemaplate" />
				<!--<xsl:if test="LocationExtendedData != '' or count(LocationExtendedData) > 0">
				
					<xsl:call-template name="ExtendedData">
						<xsl:with-param name="TagName">LocationExtendedData</xsl:with-param>
						<xsl:with-param name="AswTagName">d4p1:AddressExtendedData</xsl:with-param>
						<xsl:with-param name="PhysicalTableName">ADDRESS</xsl:with-param>
						<xsl:with-param name="LogicalTableName">lgclAddr</xsl:with-param>
						<xsl:with-param name="LogicalColumnName">AddressExtData</xsl:with-param>
					</xsl:call-template>-->
					
					<!--<AddressExtendedData>
						<_x003C_IsValidated_x003E_k__BackingField xmlns="Address.Types">true</_x003C_IsValidated_x003E_k__BackingField>
						<xsl:value-of disable-output-escaping="yes" select="Util:CreateArrayObjectExtendedData('ADDRESS','AddressID','lgclAddr','AddressExtData', LocationExtendedData, 'd4p1')" />
					</AddressExtendedData>-->
				<!--</xsl:if>-->
				<xsl:call-template name="commonPartyAddressTemaplate" />
			</PartyAddressDetailWithExtendedDataDTO>
		</xsl:for-each>

	</xsl:template>

	<!--AddressDTO Captures the Detail of an Address-->
	<xsl:template name="commonAddressTemaplate">
		<Address xmlns:d4p1="Address.Types">
			<xsl:variable name="countryCode" select="string(Util:GetOneRelatedItem('DCTCountryType',LocationCountryCode,'243'))"/>
			<xsl:variable name="VarLocationId" select="../../OriginalLocationId"/>
			<xsl:choose>
				<xsl:when test="$VarLocationId !=''">
					<d4p1:AddressID>
						<xsl:value-of select="../../OriginalLocationId"/>
					</d4p1:AddressID>
				</xsl:when>
			</xsl:choose>
			<xsl:if test="LocationId !=null">
				<d4p1:AddressID>
					<xsl:value-of select="LocationId"/>
				</d4p1:AddressID>    
			</xsl:if>
			<d4p1:AddressType>BUS</d4p1:AddressType>
			<d4p1:AddressTypeAssociations>
				<xsl:for-each select="./LocationInvolvements/LocationInvolvement[LocationInvolvementTypeCode != '_DF_']">
					<xsl:call-template name="addressTypeAssociationTemplate" />
				</xsl:for-each>
			</d4p1:AddressTypeAssociations>
			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'AdminDivisionSecondary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'AdminDivisionTertiary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<d4p1:AllowPartial>true</d4p1:AllowPartial>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'Attention'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<d4p1:CountryCode>
				<xsl:choose>
					<xsl:when test="LocationCountryCode != ''">
						<xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType',LocationCountryCode,'243'))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="string(Util:GetOneRelatedItem('DCTCountryType','USA','243'))"/>
					</xsl:otherwise>
				</xsl:choose>
			</d4p1:CountryCode>
			<xsl:choose>
				<xsl:when test="LocationEffectiveDate !=''">
					<d4p1:EffectiveDate>
						<xsl:value-of select="string(Util:ConvertDateToAswFormat(LocationEffectiveDate))"/>
					</d4p1:EffectiveDate>
				</xsl:when>
				<xsl:otherwise>
					<d4p1:EffectiveDate>
						<xsl:value-of select="string(Util:GetCurrentDate())"/>
					</d4p1:EffectiveDate>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="LocationExpirationDate !=''">
					<d4p1:ExpirationDate>
						<xsl:value-of select="string(Util:ConvertDateToAswFormat(LocationExpirationDate))"/>
					</d4p1:ExpirationDate>
				</xsl:when>
				<xsl:otherwise>
					<d4p1:ExpirationDate>
						<xsl:value-of select="string(Util:GetMaxDate())"/>
					</d4p1:ExpirationDate>
				</xsl:otherwise>
			</xsl:choose>
			<d4p1:FullAddress i:nil="true"/>
			<!--To do code Decode Mapping -->
			<d4p1:GeographicFormatCode>
				<xsl:value-of select="string(Util:GetChildKey('8036',$countryCode,'243'))"/>
			</d4p1:GeographicFormatCode>
			<d4p1:LastTransactionID i:nil="true" />
			<d4p1:LastUpdatedDate>
				<xsl:value-of select="string(Util:GetCurrentDate())"/>
			</d4p1:LastUpdatedDate>
			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'Latitude'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'LocationDetailsLine1'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'LocationDetailsLine2'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'LocationDetailsLine3'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'LocationDetailsLine4'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'Longitude'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<!--To do code Decode Mapping -->
			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'NationalDivisionPrimary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'NationalDivisionSecondary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<d4p1:OldAddressCountryCode i:nil="true"/>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'PostalCode'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>
		
			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubAddressType'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubAdminDivisionPrimary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubAdminDivisionSecondary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubAdminDivisionTertiary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubAttention'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<d4p1:SubCountryCode i:nil="true" />
			<d4p1:SubEffectiveDate>
				<xsl:value-of select="string(Util:GetCurrentDate())"/>
			</d4p1:SubEffectiveDate>
			<d4p1:SubExpirationDate>
				<xsl:value-of select="string(Util:GetMaxDate())"/>
			</d4p1:SubExpirationDate>
			<d4p1:SubLastTransactionID i:nil="true"/>
			<d4p1:SubLastUpdatedDate>
				<xsl:value-of select="string(Util:GetCurrentDate())"/>
			</d4p1:SubLastUpdatedDate>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubLatitude'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine1'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine2'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine3'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubLocationDetailsLine4'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubLongitude'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubNationalDivisionPrimary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubNationalDivisionSecondary'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'SubPostalCode'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

      <!--<d4p1:AddressExtendedData xmlns="AFS.AEF.WCF.Types">-->
      <xsl:call-template name="ExtendedData">
        <xsl:with-param name="TagName">LocationExtendedData</xsl:with-param>
		<xsl:with-param name="SuiteTagName">LocationSuiteExtendedData</xsl:with-param>
        <xsl:with-param name="AswTagName">d4p1:AddressExtendedData</xsl:with-param>
        <xsl:with-param name="PhysicalTableName">ADDRESS</xsl:with-param>
        <xsl:with-param name="LogicalTableName">lgclAddr</xsl:with-param>
        <xsl:with-param name="LogicalColumnName">AddressExtData</xsl:with-param>
      </xsl:call-template>
			<!--<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'LocationAttribute1Code'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'AdminDivisionPrimaryCode'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateAFSFieldForAddress_Add">
				<xsl:with-param name="AFSFieldName" select="'PostalCodeCode'"/>
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>-->
		</Address>

	</xsl:template>
	<!--PartyAddressDTO Captures the Party Address-->
	<xsl:template name="commonPartyAddressTemaplate">
		<PartyAddress>
			<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
			<xsl:variable name="VarLocationId" select="../../OriginalLocationId"/>
			<xsl:variable name="VarPartyId" select="../../PartyRecordPartyId"/>
			<xsl:choose>
				<xsl:when test="$VarLocationId !=''">
					<AddressID>
						<xsl:value-of select="../../OriginalLocationId"/>
					</AddressID>
				</xsl:when>
				<xsl:when test="LocationId !=''">
					<AddressID>
						<xsl:value-of select="LocationId"/>
					</AddressID>
				</xsl:when>
				<xsl:otherwise>
					<AddressID i:nil="true"/>
				</xsl:otherwise>
			</xsl:choose>
			<Comment>
				<xsl:value-of select="LocationComments"/>
			</Comment>
			<xsl:choose>
				<xsl:when test="LocationEffectiveDate !=''">
					<EffectiveDate>
						<xsl:value-of select="string(Util:ConvertDateToAswFormat(LocationEffectiveDate))"/>
					</EffectiveDate>
				</xsl:when>
				<xsl:otherwise>
					<EffectiveDate>
						<xsl:value-of select="string(Util:GetCurrentDate())"/>
					</EffectiveDate>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="LocationExpirationDate !=''">
					<ExpirationDate>
						<xsl:value-of select="string(Util:ConvertDateToAswFormat(LocationExpirationDate))"/>
					</ExpirationDate>
				</xsl:when>
				<xsl:otherwise>
					<ExpirationDate>
						<xsl:value-of select="string(Util:GetMaxDate())"/>
					</ExpirationDate>
				</xsl:otherwise>
			</xsl:choose>
      <ExternalPartyAddressID>
        <xsl:value-of select="ExternalPartyAddressId"/>
      </ExternalPartyAddressID>
      <IsPrimary>
        <xsl:value-of select="string(Util:ConvertPrimaryIndicatorToASWFormat(PrimaryIndicator, 1))"/>
      </IsPrimary>
			<IsTaxAddress>false</IsTaxAddress>
			<LastTransactionID i:nil="true" />
			<LastUpdatedDate>
				<xsl:value-of select="string(Util:GetCurrentDate())"/>
			</LastUpdatedDate>
			<PartyAddressID i:nil="true"/>
			<xsl:choose>
				<xsl:when test="$VarPartyId !=''">
					<PartyID>
						<xsl:value-of select="../../PartyRecordPartyId"/>
					</PartyID>
				</xsl:when>
			</xsl:choose>
			<SubComment i:nil="true"/>
			<IsDefault>
				<xsl:value-of select="string(Util:ConvertPrimaryIndicatorToASWFormat(DefaultLocationIndicator, 1))"/>
			</IsDefault>
		</PartyAddress>
	</xsl:template>


	<!--AddressTypeAssociationDTO Captures the Address Type Associations for Address-->
	<xsl:template name ="addressTypeAssociationTemplate">
		<AddressTypeAssociationDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Address.Types">
			<xsl:if test="LocationId != NULL">
				<AddressID>
					<xsl:value-of select="LocationId"/>
				</AddressID>
			</xsl:if>
			<AddressType>
				<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLocationInvolvementType',LocationInvolvementTypeCode,'8501'))"/>
			</AddressType>
			<xsl:if test="LocationInvolvementId !=NULL">
				<AddressTypeAssociationID>
					<xsl:value-of select="LocationInvolvementId"/>
				</AddressTypeAssociationID>
			</xsl:if>
			<EffectiveDate>
				<xsl:choose>
					<xsl:when test="EffectiveDate != ''">
						<xsl:value-of select="string(Util:GetFormatedDate(EffectiveDate))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="string(Util:GetValueByKey('TransactionDate'))"/>
					</xsl:otherwise>
				</xsl:choose>
			</EffectiveDate>
			<ExpirationDate>
				<xsl:choose>
					<xsl:when test="ExpirationDate != ''">
						<xsl:value-of select="string(Util:ConvertDateToAswFormat(ExpirationDate))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="string(Util:GetMaxDate())"/>
					</xsl:otherwise>
				</xsl:choose>

			</ExpirationDate>
			<LastTransactionID i:nil="true" />
			<LastUpdatedDate>
				<xsl:value-of select="string(Util:GetCurrentDate())"/>
			</LastUpdatedDate>
		</AddressTypeAssociationDTO>
	</xsl:template>
	<xsl:template name="GenerateAFSFieldForAddress_Add">
		<xsl:param name="AFSFieldName" />
		<xsl:param name="CountryCode" />
		<xsl:param name="TagName" />
		<!--xsl:choose>
			<xsl:when test="string(Util:CheckASWNodeConfigurability($AFSFieldName,$CountryCode,'ADDRESS')) = 'true'"-->
		<xsl:call-template name="GenerateAFSField_Add">
			<xsl:with-param name="AFSFieldName" select="$AFSFieldName" />
			<xsl:with-param name="CountryCode" select="$CountryCode" />
			<xsl:with-param name="ComponentName" select="'ADDRESS'" />
			<xsl:with-param name="TagPrefix" select="'d4p1'" />
		</xsl:call-template>
		<!--/xsl:when>
			<xsl:otherwise>
				<xsl:variable name="DCTFieldName" select="Util:GetDCTFieldName($AFSFieldName)"/>
				<xsl:if test ="$DCTFieldName != ''">
					<xsl:if test="string(Util:checkNodePassed(.,$DCTFieldName)) = 'true'">
						<xsl:value-of select="string(Util:ThrowException(concat('Invalid address node ',$DCTFieldName)))"/>
					</xsl:if>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose-->
	</xsl:template>

	<xsl:template name="GenerateAFSField_Add">
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

		<xsl:element name="{$elementName}" namespace="Address.Types">
			<xsl:variable name="valueOfElement" select="string(Util:GenerateAFSFieldWithValue(.,$AFSFieldName,$CountryCode,$ComponentName,''))" />
			<xsl:choose>
				<xsl:when test="$valueOfElement != ''">
					<xsl:value-of disable-output-escaping="no" select="$valueOfElement"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="i:nil">true</xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
		<!--<xsl:value-of disable-output-escaping="yes" select="string(Util:GenerateAFSFieldWithValue(.,$AFSFieldName,$CountryCode,$ComponentName,'',$TagPrefix,$TagName))"/>-->
	</xsl:template>

</xsl:stylesheet>




