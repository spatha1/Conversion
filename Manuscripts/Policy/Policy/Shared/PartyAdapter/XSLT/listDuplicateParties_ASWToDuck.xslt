<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="PartyRecordPartyId" select="string(Util:GetValueByKey('PartyRecordPartyId'))" />
	<xsl:variable name="NumberOfRecords" select="string(Util:GetValueByKey('NumberOfRecords'))" />
	<xsl:template match="/ArrayOfPartyMatchDTO">
		<PartyRecord>
			<PartyRecordPartyId>
				<xsl:value-of select="$PartyRecordPartyId"/>
			</PartyRecordPartyId>
			<PartyMatches>
				<NumberOfRecords>
					<xsl:value-of select="$NumberOfRecords"/>
				</NumberOfRecords>
				<xsl:for-each select="PartyMatchDTO">
					<PartyMatch>
						<PartyMatchId>
							<xsl:value-of select="PartyMatchID"/>
						</PartyMatchId>
						<PartyId>
							<xsl:value-of select="PartyID"/>
						</PartyId>
						<RelatedPartyId>
							<xsl:value-of select="RelatedPartyID"/>
						</RelatedPartyId>
						<MatchPercent>
							<xsl:value-of select="MatchPercent"/>
						</MatchPercent>
						<LastUpdatedDate>
							<xsl:value-of select="string(Util:ConvertDateToDuckFormat(LastUpdatedDate))"/>
						</LastUpdatedDate>
						<PartyMatchLockingTS>
							<xsl:value-of select="LastTransactionID"/>
						</PartyMatchLockingTS>
						<MatchTypeCode>
							<xsl:value-of select="MatchTypeCode"/>
						</MatchTypeCode>
					</PartyMatch>
				</xsl:for-each>
			</PartyMatches>
		</PartyRecord>
	</xsl:template>
</xsl:stylesheet>

