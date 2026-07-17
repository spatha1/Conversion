<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>

	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>

	<xsl:template name="indPartyReferences">
		<PartyReference>
			<PartyReferenceId>
				<xsl:value-of select="PartyMembershipID" />
			</PartyReferenceId>
			<Reference>
				<xsl:value-of select="MembershipID" />
			</Reference>
			<ReferenceTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTReferenceType',MembershipTypeCode,'PTYMbrshpTyp'))" />
			</ReferenceTypeCode>
			<PartyReferenceLockingTS>
				<xsl:value-of select="LastTransactionID" />
			</PartyReferenceLockingTS>
			<xsl:call-template name="ExtendedDataASWToDuck">
				<xsl:with-param name="TagName">ReferenceExtendedData</xsl:with-param>
				<xsl:with-param name="AswTagName">MembershipExtendedData</xsl:with-param>
			</xsl:call-template>
		</PartyReference>
	</xsl:template>

</xsl:stylesheet>




