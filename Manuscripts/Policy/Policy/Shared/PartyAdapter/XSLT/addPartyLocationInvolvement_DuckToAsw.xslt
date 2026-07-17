<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Address.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="transactionDate" select="string(Util:GetValueByKey('transactionDate'))" />
	<xsl:variable name="MaxDate" select="string(Util:GetValueByKey('MaxDate'))" />
	<xsl:variable name="CurrentDate" select="string(Util:GetValueByKey('CurrentDate'))" />

	
	<xsl:template match="/">
		<AddressTypeAssociationsDTO i="http://www.w3.org/2001/XMLSchema-instance">
			<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
			<AddressTypeAssociations>
				<xsl:for-each select="PartyRecord/Locations/Location/LocationInvolvements/LocationInvolvement">
					<xsl:variable name="LocationInvolvementTypeCode" select="LocationInvolvementTypeCode" />
					<xsl:if test="string($LocationInvolvementTypeCode) != '_DF_'">
						<AddressTypeAssociationDTO>
							<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
							<AddressID>
								<xsl:value-of select="../../LocationId" />
							</AddressID>
							<AddressType>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLocationInvolvementType',LocationInvolvementTypeCode,'8501'))"/>
							</AddressType>

							<AddressTypeAssociationID nil="true" />
							
							<xsl:choose>
								<xsl:when test="count(EffectiveDate) > 0">
									<xsl:choose>
										<xsl:when test="EffectiveDate != ''">
											<EffectiveDate>
											<xsl:value-of select="string(Util:ConvertDateToAswFormat(EffectiveDate))" />
											</EffectiveDate>
										</xsl:when>
										<xsl:otherwise>
											<EffectiveDate>
											<xsl:value-of select="$CurrentDate"/>
											</EffectiveDate>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:when>
								<xsl:otherwise>
									<EffectiveDate i:nil ="true" />
								</xsl:otherwise>
							</xsl:choose>
							
							<ExpirationDate>
								<xsl:choose>
									<xsl:when test="count(ExpirationDate) > 0">
										<xsl:choose>
											<xsl:when test="ExpirationDate != ''">
												<xsl:value-of select="string(Util:ConvertDateToAswFormat(ExpirationDate))" />
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="$MaxDate"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$MaxDate"/>
									</xsl:otherwise>
								</xsl:choose>
							</ExpirationDate>
							<LastTransactionID nil="true" />
							<LastUpdatedDate>
								<xsl:value-of select="string(Util:GetCurrentDate())"/>
							</LastUpdatedDate>
						</AddressTypeAssociationDTO>
					</xsl:if>
				</xsl:for-each>
			</AddressTypeAssociations>
		</AddressTypeAssociationsDTO>
	</xsl:template>
</xsl:stylesheet>

