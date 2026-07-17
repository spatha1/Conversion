<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:template match="/">
		<xsl:for-each select="PartyRecord">

			<PartyNameDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
				<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
				<PartyID>
					<xsl:value-of select="PartyRecordPartyId"/>
				</PartyID>        
			</PartyNameDTO>

		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>