<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="userDetails">
		<xsl:call-template name="User.Body"/>
	</xsl:template>
	
	<xsl:template name="User.Body">
		<User id="{@id}" producer="{userName/@producer}">
			<Name><xsl:value-of select="userName" /></Name>
			<FullName><xsl:value-of select="fullName" /></FullName>
			<Email><xsl:value-of select="email" /></Email>
			<InternalPartyId><xsl:value-of select="@userID" /></InternalPartyId>
		</User>
	</xsl:template>


</xsl:stylesheet>