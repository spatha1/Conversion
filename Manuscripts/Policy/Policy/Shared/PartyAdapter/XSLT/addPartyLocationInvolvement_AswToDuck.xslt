<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="i xs msxsl xsl Util">
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/AddressTypeAssociationsDTO">
		<PartyRecord>
			<Locations>
				<Location>
					<LocationId>
						<xsl:value-of select="//AddressTypeAssociations/AddressTypeAssociationDTO/AddressID"/>
					</LocationId>
				<LocationInvolvements>
      <xsl:for-each select="./AddressTypeAssociations/AddressTypeAssociationDTO">
		  <xsl:call-template name="addressTypeAssociationTemplate" />
		  </xsl:for-each>
    </LocationInvolvements>
				</Location>
			</Locations>
		</PartyRecord>
	</xsl:template>
	<xsl:template name ="addressTypeAssociationTemplate">
		<LocationInvolvement>
      <ObjectTypeCode>PTY</ObjectTypeCode>
      <ObjectId></ObjectId>
      <RoleCode />
			<LocationId>
				<xsl:value-of select="AddressID"/>
			</LocationId>
			<LocationInvolvementTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTLocationInvolvementType',AddressType,'8501'))"/>
			</LocationInvolvementTypeCode>
			<!--<LocationInvolvementId>
				<xsl:value-of select="AddressTypeAssociationID"/>
			</LocationInvolvementId>-->
			<EffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
        <!--<xsl:value-of select="EffectiveDate"/>-->
			</EffectiveDate>
      <ExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>        
      </ExpirationDate>
      <LocationInvolvementLockingTS>
				<xsl:value-of select="LastTransactionID"/>
			</LocationInvolvementLockingTS>
			<!--<LastUpdatedDate>
				<xsl:value-of select="string(Util:GetCurrentDate())"/>
			</LastUpdatedDate>-->
		</LocationInvolvement>
	   </xsl:template>
  
</xsl:stylesheet>