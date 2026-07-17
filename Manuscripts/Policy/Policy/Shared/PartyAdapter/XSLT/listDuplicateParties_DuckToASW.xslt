<xsl:stylesheet version="1.0" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/Filters">
		<PartyMatchFilterCriteriaDTO  xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
			<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
			<xsl:variable name="MatchCount" select="count(./Filter[@Type = 'MatchType'])"/>
			<xsl:variable name="NumberOfRecords" select="count(./Filter[@Type = 'NumberOfRecords'])"/>
			<xsl:if test="$MatchCount > 0">
				<MatchTypeCodes xmlns:d2p1="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
					<xsl:for-each select="./Filter[@Type = 'MatchType']">
						<d2p1:string>
							<xsl:value-of select="@Value"/>
						</d2p1:string>
					</xsl:for-each>
				</MatchTypeCodes>
			</xsl:if>
			<xsl:if test="$NumberOfRecords > 0">
				<NumberOfRecordsToRetrieve>
					<xsl:value-of select="./Filter[@Type = 'NumberOfRecords']/@Value"/>
				</NumberOfRecordsToRetrieve>
			</xsl:if>
		</PartyMatchFilterCriteriaDTO>
	</xsl:template>
</xsl:stylesheet>
