<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:output method="xml" omit-xml-declaration="yes" cdata-section-elements="ExtendedData" encoding="UTF-8" indent="yes"/>
	<xsl:template match="PartyDuplicateRecord" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
		<ArrayOfPartyMatchDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
			<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
			<xsl:for-each select="PartyDuplicates/PartyDuplicate[@PartyDuplicateRecordIndicator='1']|PartyDuplicates/PartyDuplicate[(@PartyDuplicateRecordIndicator='on')]">
				<PartyMatchDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="Party.Types">
					<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
					<xsl:call-template name ="commonDuplicateFields" />
				</PartyMatchDTO>
			</xsl:for-each>
		</ArrayOfPartyMatchDTO>
	</xsl:template>
	<xsl:template name="commonDuplicateFields">
		<PartyMatchID>
			<xsl:value-of select="PartyMatchId"/>
		</PartyMatchID>
		<PartyID>
			<xsl:value-of select="PartyId"/>
		</PartyID>
		<RelatedPartyID>
			<xsl:value-of select="RelatedPartyId"/>
		</RelatedPartyID>
		<xsl:choose>
			<xsl:when test="MatchPercent !=''">
				<MatchPercent>
					<xsl:value-of select="MatchPercent"/>
				</MatchPercent>
			</xsl:when>
			<xsl:otherwise>

			</xsl:otherwise>
		</xsl:choose>
		<LastUpdatedDate>
			<xsl:value-of select="string(Util:GetCurrentDate())"/>
		</LastUpdatedDate>
		<LastTransactionID>
			<xsl:value-of select="PartyMatchLockingTS"/>
		</LastTransactionID>
		<MatchTypeCode>
			<xsl:value-of select="MatchTypeCode"/>
		</MatchTypeCode>

	</xsl:template>
</xsl:stylesheet>




