<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"  xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:import href="PartyLocationTemplate_ASWToDuck.xslt"/>
	<xsl:import href="UpdatePartyForActivity_CommonTemplate.xslt"/>

	<xsl:template match="/PartyIndividualBulkDetailsDTO">
		<xsl:variable name="PartyType" select="string(Util:getBasePartyTypeFromASWPartyType(Party/PartyTypeCode))" />
		<PartyRecord xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
			<PartyRecordPartyId>
				<xsl:value-of select="Party/PartyID"/>
			</PartyRecordPartyId>

			<xsl:call-template name="indPartyInfo" />

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

			<xsl:if test="count(PartyIndNamesToInsert/PartyIndNameDetailWithExtendedDataDTO/PartyIndName[NameTypeCode = '04']) > 0
					or count(PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '04']) > 0">
				<PartyOtherNames xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
					<xsl:for-each select="PartyIndNamesToInsert/PartyIndNameDetailWithExtendedDataDTO/PartyIndName[NameTypeCode = '04']">
						<xsl:call-template name="PartyOtherName">
							<xsl:with-param name="InsertIndicator" select="'1'"/>
							<xsl:with-param name="UpdateIndicator" select="'0'"/>
						</xsl:call-template>
					</xsl:for-each>
					<xsl:for-each select="PartyIndNamesToUpdate/PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '04']">
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
</xsl:stylesheet>