<?xml version='1.0'?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="account">
		<xsl:call-template name="Insured.Body"/>
	</xsl:template>

	<xsl:template name="Insured.Body">
		<Insured id="{@id}">
			
            <xsl:choose>
                <!-- If EntityType is 'O', output only Name -->
                <xsl:when test="PartyType = 'O'">
                    <EntityType>O</EntityType>
                    <Name><xsl:value-of select="Name" /></Name>
                </xsl:when>
            
                <!-- Otherwise, output FirstName, LastName, and MiddleName -->
                <xsl:otherwise>
                    <EntityType>I</EntityType>
                    <FirstName><xsl:value-of select="FirstName" /></FirstName>
                    <LastName><xsl:value-of select="Name" /></LastName>
                    <MiddleName><xsl:value-of select="MiddleName" /></MiddleName>
                </xsl:otherwise>
            </xsl:choose>

			<PrimaryPhone><xsl:value-of select="PrimaryPhone" /></PrimaryPhone>
			<Email><xsl:value-of select="Email"/></Email>
			<Fax><xsl:value-of select="Fax" /></Fax>
			<ABNNumber><xsl:value-of select="ABNNumber" /></ABNNumber>
			<xsl:call-template name="Insured.Relationships"/>
		</Insured>
		<Contact>
			<xsl:choose>
				<!-- If EntityType is 'O', output only Name -->
				<xsl:when test="PartyType = 'O'">
					<xsl:variable name="name" select="normalize-space(CSLContactName)"/>
					<xsl:variable name="firstSpace" select="substring-before($name, ' ')"/>
					<xsl:variable name="restAfterFirst" select="substring-after($name, ' ')"/>
					<xsl:variable name="secondSpace" select="substring-before($restAfterFirst, ' ')"/>
					<xsl:variable name="restAfterSecond" select="substring-after($restAfterFirst, ' ')"/>
					<xsl:choose>
						<!-- No space -->
						<xsl:when test="not(contains($name, ' '))">
							<FirstName/>
							<MiddleName/>
							<LastName>
								<xsl:value-of select="$name"/>
							</LastName>
						</xsl:when>
						<!-- One space -->
						<xsl:when test="contains($name, ' ') and not(contains($restAfterFirst, ' '))">
							<FirstName>
								<xsl:value-of select="$firstSpace"/>
							</FirstName>
							<MiddleName/>
							<LastName>
								<xsl:value-of select="$restAfterFirst"/>
							</LastName>
						</xsl:when>
						<!-- Two spaces -->
						<xsl:when test="contains($restAfterFirst, ' ')">
							<FirstName>
								<xsl:value-of select="$firstSpace"/>
							</FirstName>
							<MiddleName>
								<xsl:value-of select="$secondSpace"/>
							</MiddleName>
							<LastName>
								<xsl:value-of select="$restAfterSecond"/>
							</LastName>
						</xsl:when>
					</xsl:choose>
					<Email>
						<xsl:value-of select="Email"/>
					</Email>
					<PhoneNumber>
						<xsl:value-of select="PrimaryPhone"/>
					</PhoneNumber>
				</xsl:when>
				<!-- Otherwise, output FirstName, LastName, and MiddleName -->
				<xsl:otherwise>
					<FirstName>
						<xsl:value-of select="FirstName"/>
					</FirstName>
					<LastName>
						<xsl:value-of select="Name"/>
					</LastName>
					<MiddleName>
						<xsl:value-of select="MiddleName"/>
					</MiddleName>
					<Email>
						<xsl:value-of select="Email"/>
					</Email>
					<PhoneNumber>
						<xsl:value-of select="PrimaryPhone"/>
					</PhoneNumber>
				</xsl:otherwise>
			</xsl:choose>
		</Contact>
	</xsl:template>

	<xsl:template name="Insured.Relationships"/>

</xsl:stylesheet>