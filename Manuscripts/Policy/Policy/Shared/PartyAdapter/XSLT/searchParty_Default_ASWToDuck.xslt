<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="PartyReferenceTemplate_ASWToDuck.xslt" />
	
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	
	<xsl:variable name="MethodName" select="string(Util:GetValueByKey('MethodName'))" />

	<xsl:template match="/PartySearchOutput">
		<CandidateList>
			<SearchControl>
				<Paging>
					<ReturnCount>
						<xsl:value-of select="PageRecordCount"/>
					</ReturnCount>
					<xsl:if test="TotalRecordCount != '' and TotalRecordCount != '0' and TotalRecordCount &gt; 0">
						<TotalCount>
							<xsl:value-of select="TotalRecordCount" />
						</TotalCount>
					</xsl:if>
				</Paging>
			</SearchControl>
			<xsl:for-each select="PartySearchResult">
				<xsl:variable name="BasePartyType" select="string(Util:getBasePartyTypeFromASWPartyType(PartyTypeCode))" />
				<ListItem>
					<ItemData>
						<PartyRecord xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
							<PartyRecordPartyId>
								<xsl:value-of select="PartyId"/>
							</PartyRecordPartyId>

							<xsl:if test="PartyBusinessDetail/IsAgency = '1'">
								<xsl:for-each select="PartyMemberships/PartyMembership">
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
										<xsl:for-each select="PartyIndividualNames/PartyIndividualName[IsDefault = '1']">
											<PartyName>
												<xsl:value-of select="LastName" />
											</PartyName>
											<PartyFirstName>
												<xsl:value-of select="FirstName" />
											</PartyFirstName>
											<PartyMiddleName>
												<xsl:value-of select="MiddleName" />
											</PartyMiddleName>
											<PartyNamePrefix>
												<xsl:value-of select="string(Util:GetChildKey('DCTNamePrefixValue',NamePrefixCode,'34'))"/>
											</PartyNamePrefix>
											<PartyNameSuffix>
												<xsl:value-of select="string(Util:GetChildKey('DCTNameSuffixValue',NameSuffixCode,'48'))"/>
											</PartyNameSuffix>
										</xsl:for-each>
										<PartyGender>
											<xsl:value-of select="string(Util:GetChildKey('DCTGenderValue',PartyIndividualDetail/Gender,'51'))"/>
										</PartyGender>
										<PartyBirthDate>
											<xsl:value-of select="string(Util:ConvertDateToDuckFormat(PartyIndividualDetail/DateOfBirth))" />
										</PartyBirthDate>
										<xsl:for-each select="PartyIndividualNames/PartyIndividualName[NameTypeCode = '07']">
											<PartyCorrespondenceName>
												<xsl:value-of select="FullName" />
											</PartyCorrespondenceName>
										</xsl:for-each>
										<xsl:choose>
											<xsl:when test="string(PartySubTypeCode) != ''">
												<PartyTypeCode>
													<xsl:value-of select="string(Util:GetChildKey('DCTPartyType',PartySubTypeCode,'PartySubType'))"/>
												</PartyTypeCode>
											</xsl:when>
											<xsl:otherwise>
												<PartyTypeCode>
													<xsl:value-of select="string(Util:GetChildKey('DCTPartyType',PartyTypeCode,'8001'))"/>
												</PartyTypeCode>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:otherwise>
										<xsl:for-each select="PartyBusinessNames/PartyBusinessName[IsDefault = '1']">
											<PartyName>
												<xsl:value-of select="Name" />
											</PartyName>
											<PartyFirstName>
											</PartyFirstName>
											<PartyMiddleName>
											</PartyMiddleName>
											<PartyNamePrefix>
											</PartyNamePrefix>
											<PartyNameSuffix>
											</PartyNameSuffix>
										</xsl:for-each>
										<PartyGender>
										</PartyGender>
										<PartyBirthDate>
										</PartyBirthDate>
										<xsl:for-each select="PartyBusinessNames/PartyBusinessName[NameTypeCode = '07']">
											<PartyCorrespondenceName>
												<xsl:value-of select="Name" />
											</PartyCorrespondenceName>
										</xsl:for-each>
										<xsl:choose>
											<xsl:when test="string(PartySubTypeCode) != ''">
												<PartyTypeCode>
													<xsl:choose>
														<xsl:when test="PartyBusinessDetail/IsAgency = '1'">
															<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',PartySubTypeCode,'PartySubType','true'))"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',PartySubTypeCode,'PartySubType','false'))"/>
														</xsl:otherwise>
													</xsl:choose>
												</PartyTypeCode>
											</xsl:when>
											<xsl:otherwise>
												<PartyTypeCode>
													<xsl:choose>
														<xsl:when test="PartyBusinessDetail/IsAgency = '1'">
															<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',PartyTypeCode,'8001','true'))"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:value-of select="string(Util:GetChildKeyForAgency('DCTPartyType',PartyTypeCode,'8001','false'))"/>
														</xsl:otherwise>
													</xsl:choose>
												</PartyTypeCode>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</Party>
							<PartyPhones>
								<xsl:for-each select="PartyPhones/PartyPhone">
									<xsl:call-template name="Srch_indPartyPhones" />
								</xsl:for-each>
							</PartyPhones>
							<PartyEmails>
								<xsl:for-each select="PartyEmails/PartyEmail">
									<xsl:call-template name="Srch_indPartyEmails" />
								</xsl:for-each>
							</PartyEmails>
							<Locations>
								<xsl:for-each select="PartyAddresses/PartyAddress/Address">
									<xsl:call-template name="Srch_indPartyAddress" />
								</xsl:for-each>
							</Locations>
							<xsl:if test="PartyBusinessDetail/IsAgency = '1'">
								<PartyReferences>
									<xsl:for-each select="PartyMemberships/PartyMembership">
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

	<xsl:template name="Srch_indPartyPhones">
		<PartyPhone>
			<PhoneNumber>
				<xsl:value-of select="PhoneNumber" />
			</PhoneNumber>
			<PhoneExtension>
				<xsl:value-of select="PhoneExt" />
			</PhoneExtension>
			<PhoneCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',PhoneCountryCode,'243'))"/>
			</PhoneCountryCode>
			<PhoneFormatCode>US1</PhoneFormatCode>

			<xsl:choose>
				<xsl:when test="Primary='1'">
					<PrimaryIndicator>1</PrimaryIndicator>
				</xsl:when>
				<xsl:otherwise>
					<PrimaryIndicator>0</PrimaryIndicator>
				</xsl:otherwise>
			</xsl:choose>
		</PartyPhone>
	</xsl:template>

	<xsl:template name="Srch_indPartyEmails">
		<PartyEmail>
			<EmailAddress>
				<xsl:value-of select="EmailAddress" />
			</EmailAddress>
			<xsl:choose>
				<xsl:when test="Primary='1'">
					<PrimaryIndicator>1</PrimaryIndicator>
				</xsl:when>
				<xsl:otherwise>
					<PrimaryIndicator>0</PrimaryIndicator>
				</xsl:otherwise>
			</xsl:choose>
		</PartyEmail>
	</xsl:template>

	<xsl:template name="Srch_indPartyAddress">
		<Location>
			<xsl:variable name="countryCode" select="CountryCode"/>

			<!--LocationAddressLine1>
				<xsl:value-of select="AddressLine1"/>
			  </LocationAddressLine1>
			  <LocationAddressLine2>
				<xsl:value-of select="AddressLine2"/>
			  </LocationAddressLine2-->
			<xsl:call-template name="GenerateDCTFieldForAddress_Search">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine1'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress_Search">
				<xsl:with-param name="DCTFieldName" select="'LocationAddressLine2'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress_Search">
				<xsl:with-param name="DCTFieldName" select="'LocationCity'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress_Search">
				<xsl:with-param name="DCTFieldName" select="'LocationStateCode'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress_Search">
				<xsl:with-param name="DCTFieldName" select="'LocationStateName'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<!--xsl:variable name="varPostalCode" select="PostalCode" />
			<xsl:if test="contains($varPostalCode, '-')">
				<xsl:variable name="varLocationPostalCode" select="substring-before($varPostalCode,'-')"/>
				<xsl:variable name="varLocationPostalCodeExtension" select="substring-after($varPostalCode,'-')"/>
				<LocationPostalCode>
					<xsl:value-of select="$varLocationPostalCode" />
				</LocationPostalCode>
			</xsl:if>
			<xsl:if test="not(contains($varPostalCode, '-'))">
				<LocationPostalCode>
					<xsl:value-of select="PostalCode"/>
				</LocationPostalCode>
			</xsl:if-->

			<xsl:call-template name="GenerateDCTFieldForAddress_Search">
				<xsl:with-param name="DCTFieldName" select="'LocationPostalCode'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<xsl:call-template name="GenerateDCTFieldForAddress_Search">
				<xsl:with-param name="DCTFieldName" select="'LocationCountyCode'" />
				<xsl:with-param name="CountryCode" select="$countryCode" />
			</xsl:call-template>

			<LocationCountryCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
			</LocationCountryCode>
		</Location>
	</xsl:template>

	<xsl:template name="GenerateDCTFieldForAddress_Search">
		<xsl:param name="DCTFieldName" />
		<xsl:param name="CountryCode" />
		<xsl:param name="TagName" />
		<xsl:call-template name="GenerateDCTField_Search">
			<xsl:with-param name="DCTFieldName" select="$DCTFieldName" />
			<xsl:with-param name="CountryCode" select="$CountryCode" />
			<xsl:with-param name="ComponentName" select="'ADDRESS'" />
			<xsl:with-param name="TagPrefix" select="''" />
			<xsl:with-param name="TagName" select="$TagName" />
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="GenerateDCTField_Search">
		<xsl:param name="DCTFieldName" />
		<xsl:param name="CountryCode" />
		<xsl:param name="ComponentName" />
		<xsl:param name="TagPrefix" />
		<xsl:param name="TagName" />

		<xsl:variable name="elementName">
			<xsl:choose>
				<xsl:when test="$TagName != ''" >
					<xsl:value-of select="$TagName"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$DCTFieldName"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="valueOfElement" select="string(Util:GenerateDCTFieldWithValue(.,$DCTFieldName,$CountryCode,$ComponentName,''))" />

		<xsl:choose>
			<xsl:when test="$DCTFieldName != 'LocationPostalCode'">
				<!--actual processing-->
				<xsl:element name="{$elementName}">
					<xsl:choose>
						<xsl:when test="$valueOfElement != ''">
							<xsl:value-of disable-output-escaping="no" select="$valueOfElement"/>
						</xsl:when>
					</xsl:choose>
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<!--Postal code split conditions-->
				<xsl:call-template name="PostalCodeProcessing_Search">
					<xsl:with-param name="elementName" select="$elementName" />
					<xsl:with-param name="valueOfElement" select="$valueOfElement" />
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!--Postal code split conditions-->
	<xsl:template name="PostalCodeProcessing_Search">
		<xsl:param name="elementName" />
		<xsl:param name="valueOfElement" />
		<xsl:choose>
			<xsl:when test="contains($valueOfElement, '-')">
				<xsl:variable name="varLocationPostalCode" select="substring-before($valueOfElement,'-')"/>
				<xsl:variable name="varLocationPostalCodeExtension" select="substring-after($valueOfElement,'-')"/>
				<xsl:element name="{$elementName}">
					<xsl:value-of select="$varLocationPostalCode" />
				</xsl:element>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="{$elementName}">
					<xsl:value-of select="$valueOfElement" />
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

</xsl:stylesheet>
