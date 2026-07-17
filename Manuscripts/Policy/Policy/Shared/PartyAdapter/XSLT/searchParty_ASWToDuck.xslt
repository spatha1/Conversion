<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="PartyLocationTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyPhoneTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyEmailTemplate_ASWToDuck.xslt"/>
	<xsl:import href="PartyReferenceTemplate_ASWToDuck.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />

	<xsl:template match="/PartySearchResultsDTO">
		<CandidateList>
			<SearchControl>
				<Paging>
					<ReturnCount>
						<xsl:value-of select="count(PartySearchResultList/PartySearchResultDTO)"/>
					</ReturnCount>
					<xsl:if test="SearchResultCount != '' and SearchResultCount != ''">
						<TotalCount>
							<xsl:value-of select="SearchResultCount" />
						</TotalCount>
					</xsl:if>
				</Paging>
			</SearchControl>
			<xsl:for-each select="PartySearchResultList/PartySearchResultDTO">
				<xsl:variable name="BasePartyType" select="string(Util:getBasePartyTypeFromASWPartyType(PartyType))" />
				<ListItem>
					<ItemData>
						<PartyRecord xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
							<PartyRecordPartyId>
								<xsl:if test="$BasePartyType=string(Util:getBasePartyTypeFromASWPartyType('IND'))">
									<xsl:value-of select="PartyIndividual/PartyID"/>
								</xsl:if>
								<xsl:if test="$BasePartyType=string(Util:getBasePartyTypeFromASWPartyType('BUS'))">
									<xsl:value-of select="PartyBusiness/PartyID"/>
								</xsl:if>
							</PartyRecordPartyId>
							<xsl:if test="PartyBusiness/IsAgency = 'true'">
								<xsl:for-each select="PartyMembership">
									<xsl:if test="string(Util:GetChildKey('DCTReferenceType',MembershipTypeCode,'PTYMbrshpTyp')) = 'AGCX'">
										<AgencyId>
											<xsl:value-of select="MembershipID" />
										</AgencyId>
									</xsl:if>
								</xsl:for-each>
							</xsl:if>
							<Party>
								<xsl:choose>
									<xsl:when test="$BasePartyType=string(Util:getBasePartyTypeFromASWPartyType('IND'))">
										<xsl:for-each select="PartyIndNamesDetail/PartyIndNameDetailDTO/PartyName[IsDefault = 'true']">
											<PartyName>
												<xsl:value-of select="../PartyIndName/LastName" />
											</PartyName>
											<PartyFirstName>
												<xsl:value-of select="../PartyIndName/FirstName" />
											</PartyFirstName>
											<PartyMiddleName>
												<xsl:value-of select="../PartyIndName/MiddleName" />
											</PartyMiddleName>
											<PartyNamePrefix>
												<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefixValue',../PartyIndName/PrefixCode,'34'))"/>
											</PartyNamePrefix>
											<PartyNameSuffix>
												<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffixValue',../PartyIndName/SuffixCode,'48'))"/>
											</PartyNameSuffix>
										</xsl:for-each>
										<PartyGender>
											<xsl:value-of select="string(Util:GetChildKey('DCTGenderValue',PartyIndividual/GenderCode,'51'))"/>
										</PartyGender>
										<PartyBirthDate>
											<xsl:value-of select="string(Util:ConvertDateToDuckFormat(PartyIndividual/DateOfBirth, false))" />
										</PartyBirthDate>
										<xsl:for-each select="PartyIndNamesDetail/PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '07']">
											<PartyCorrespondenceName>
												<xsl:value-of select="FullName" />
											</PartyCorrespondenceName>
										</xsl:for-each>
										<PartyTypeCode>
											<xsl:value-of select="string(Util:GetChildKey('DCTPartyType',PartyType,'8001'))"/>
										</PartyTypeCode>
									</xsl:when>
									<xsl:otherwise>
										<xsl:for-each select="PartyBusNamesDetail/PartyBusNameDetailDTO/PartyName[IsDefault = 'true']">
											<PartyName>
												<xsl:value-of select="../PartyBusName/Name" />
											</PartyName>
											<PartyFirstName>
												<!--<xsl:value-of select="../PartyBusName/FirstName" />-->
											</PartyFirstName>
											<PartyMiddleName>
												<!--<xsl:value-of select="../PartyBusName/MiddleName" />-->
											</PartyMiddleName>
											<PartyNamePrefix>
												<!--<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefix',../PartyBusName/PrefixCode,'34'))"/>-->
											</PartyNamePrefix>
											<PartyNameSuffix>
												<!--<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffix',../PartyBusName/SuffixCode,'48'))"/>-->
											</PartyNameSuffix>
										</xsl:for-each>
										<PartyGender>
											<!--<xsl:value-of select="PartyBusiness/GenderCode"/>-->
										</PartyGender>
										<PartyBirthDate>
											<!--<xsl:value-of select="PartyBusiness/DateOfBirth"/>-->
										</PartyBirthDate>
										<xsl:for-each select="PartyBusNamesDetail/PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '07']">
											<PartyCorrespondenceName>
												<xsl:value-of select="Name" />
											</PartyCorrespondenceName>
										</xsl:for-each>
										<PartyTypeCode>
											<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',PartyType,'8001',PartyBusiness/IsAgency))"/>
										</PartyTypeCode>
									</xsl:otherwise>
								</xsl:choose>
							</Party>
							<PartyPhones>
								<xsl:for-each select="PartyPhone">
									<xsl:call-template name="indPartyPhones" />
								</xsl:for-each>
							</PartyPhones>
							<PartyEmails>
								<xsl:for-each select="PartyEmail">
									<xsl:call-template name="indPartyEmails" />
								</xsl:for-each>
							</PartyEmails>
							<Locations>
								<xsl:for-each select="PartyAddressDetail/Address">
									<xsl:call-template name="indPartyAddress" />
								</xsl:for-each>
							</Locations>
							<xsl:if test="PartyBusiness/IsAgency = 'true'">
								<PartyReferences>
									<xsl:for-each select="PartyMembership">
										<xsl:call-template name="indPartyReferences" />
									</xsl:for-each>
								</PartyReferences>
							</xsl:if>
							<AuthorizedInterest>
								<Name>1</Name>
							</AuthorizedInterest>
						</PartyRecord>
					</ItemData>
				</ListItem>
			</xsl:for-each>
		</CandidateList>
	</xsl:template>

</xsl:stylesheet>