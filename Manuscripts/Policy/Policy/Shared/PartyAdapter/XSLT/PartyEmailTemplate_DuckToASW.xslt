<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:Util="urn:Util" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

  <xsl:template name="partyEmail">
		<xsl:for-each select="./PartyEmails/PartyEmail">
			<PartyEmailDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
				<!-- <_x003C_IsValidated_x003E_k__BackingField>false</_x003C_IsValidated_x003E_k__BackingField> -->
				<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
				<xsl:call-template name ="commonEmailFields" />
			</PartyEmailDTO>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="partyEmailExtData">
		<xsl:for-each select="./PartyEmails/PartyEmail">
			<xsl:call-template name="partyEmailInsert"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="partyEmailInsert">
		<PartyEmailWithExtendedDataDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
			<_x003C_IsValidated_x003E_k__BackingField>true</_x003C_IsValidated_x003E_k__BackingField>
			<EntityAuthLevel>FullAccess</EntityAuthLevel>
			<!--<xsl:if test="EmailExtendedData != '' or count(EmailExtendedData) > 0">
				<xsl:call-template name="ExtendedData">
					<xsl:with-param name="TagName">EmailExtendedData</xsl:with-param>
					<xsl:with-param name="PhysicalTableName">PARTY_EMAIL</xsl:with-param>
					<xsl:with-param name="LogicalTableName">lgclPartyEmail</xsl:with-param>
					<xsl:with-param name="LogicalColumnName">PartyEmailExtData</xsl:with-param>
				</xsl:call-template>-->
				<!--<ExtendedData xmlns:d4p1="http://epc.accenture.com/2013/06/26/Type">
					<xsl:value-of disable-output-escaping="yes" select="Util:CreateArrayObjectExtendedData('PARTY_EMAIL','PartyEmailID','lgclPartyEmail','PartyEmailExtData', EmailExtendedData,'d4p1')" />
				</ExtendedData>-->
			<!--</xsl:if>-->
			<PartyEmail>
				<_x003C_IsValidated_x003E_k__BackingField>true</_x003C_IsValidated_x003E_k__BackingField>
				<EntityAuthLevel>FullAccess</EntityAuthLevel>
				<xsl:call-template name ="commonEmailFields" />
			</PartyEmail>
		</PartyEmailWithExtendedDataDTO>
	</xsl:template>

	<xsl:template name="commonEmailFields">
		<!--<EntityAuthLevel>None</EntityAuthLevel>
		<EntityAuthLevel xmlns="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common">None</EntityAuthLevel>-->
		<Comment>
			<xsl:value-of select="EmailComments"/>
		</Comment>
		<xsl:choose>
			<xsl:when test="EmailEffectiveDate !=''">
				<EffectiveDate>
					<xsl:value-of select="string(Util:ConvertDateToAswFormat(EmailEffectiveDate))"/>
				</EffectiveDate>
			</xsl:when>
			<xsl:otherwise>
				<EffectiveDate>
					<xsl:value-of select="string(Util:GetCurrentDate())"/>
				</EffectiveDate>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:variable name="partyEmailId" select="PartyEmailId"/>
   
    <EmailAddress>
			<xsl:value-of select="EmailAddress"/>
		</EmailAddress>
		<EmailTypeCode>
			<xsl:value-of select="string(Util:GetOneRelatedItem('DCTEmailType',EmailTypeCode,'31'))"/>
		</EmailTypeCode>
		<xsl:choose>
			<xsl:when test="EmailExpirationDate !=''">
				<ExpirationDate>
					<xsl:value-of select="string(Util:ConvertDateToAswFormat(EmailExpirationDate))"/>
				</ExpirationDate>
			</xsl:when>
			<xsl:otherwise>
				<ExpirationDate>
					<xsl:value-of select="string(Util:GetMaxDate())"/>
				</ExpirationDate>
			</xsl:otherwise>
		</xsl:choose>

    <ExternalPartyEmailID>
      <xsl:value-of select="ExternalPartyEmailId"/>
    </ExternalPartyEmailID>

    <!--TO DO : We need to pass the first email as primary while using addPartyRq -->
		<IsPrimary>
			<xsl:value-of select="string(Util:ConvertPrimaryIndicatorToASWFormat(PrimaryIndicator, 1))"/>
		</IsPrimary>
		<xsl:choose>
			<xsl:when test="$partyEmailId != ''">
				<LastTransactionID>
					<xsl:value-of select="PartyEmailLockingTS"/>
				</LastTransactionID>
				<LastUpdatedDate>
					<xsl:value-of select="string(Util:GetCurrentDate())"/>
				</LastUpdatedDate>
				<PartyEmailID>
					<xsl:value-of select="PartyEmailId"/>
				</PartyEmailID>
			</xsl:when>
			<xsl:otherwise>
				<LastTransactionID nil="true" />
				<LastUpdatedDate>
					<xsl:value-of select="string(Util:GetCurrentDate())"/>
				</LastUpdatedDate>
        <PartyEmailID nil="true" />
			</xsl:otherwise>
		</xsl:choose>		
		<xsl:if test="../../PartyRecordPartyId !=''">
			<PartyID>
				<xsl:value-of select="../../PartyRecordPartyId"/>
			</PartyID>
		</xsl:if>
		<xsl:call-template name="ExtendedData">
			<xsl:with-param name="TagName">EmailExtendedData</xsl:with-param>
			<xsl:with-param name="PhysicalTableName">PARTY_EMAIL</xsl:with-param>
			<xsl:with-param name="LogicalTableName">lgclPartyEmail</xsl:with-param>
			<xsl:with-param name="LogicalColumnName">PartyEmailExtData</xsl:with-param>
		</xsl:call-template>
	
</xsl:template>
</xsl:stylesheet>


