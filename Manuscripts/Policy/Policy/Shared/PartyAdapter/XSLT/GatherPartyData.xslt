<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<!--xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util"-->
	<xsl:import href="updatePartyPhone_ASWToDuck.xslt"/>
	<!--xsl:import href="updatePartyEmail_ASWToDuck.xslt"/-->
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes" />

	<xsl:variable name="PartyType" select="string(Util:getBasePartyTypeFromASWPartyType(/PartyData/PartyDetailDTO/PartyType))" />
	<xsl:variable name="BASEPARTYTYPEIND" select="string(Util:GetValueByKey('BASEPARTYTYPEIND'))" />
	<xsl:variable name="BASEPARTYTYPEBUS" select="string(Util:GetValueByKey('BASEPARTYTYPEBUS'))" />

	<xsl:variable name="updateOtherNameRecord" select="string(Util:GetValueByKey('updateOtherNameRecord'))" />
	<xsl:variable name="updatePhonePrimaryRecord" select="string(Util:GetValueByKey('updatePhonePrimaryRecord'))" />
	<xsl:variable name="updatePhoneFaxRecord" select="string(Util:GetValueByKey('updatePhoneFaxRecord'))" />
	<xsl:variable name="updateEmailRecord" select="string(Util:GetValueByKey('updateEmailRecord'))" />
	<xsl:variable name="updateLocationRecord" select="string(Util:GetValueByKey('updateLocationRecord'))" />
	
	<xsl:variable name="classicMode" select="string(Util:GetValueByKey('classicMode'))" />

	<!-- Location Details-->
	<xsl:variable name="address1" select="/PartyData/clientDetails/mailingAddress/address1" />
	<xsl:variable name="address2" select="/PartyData/clientDetails/mailingAddress/address2" />
	<xsl:variable name="address3" select="/PartyData/clientDetails/mailingAddress/address3" />
	<xsl:variable name="address4" select="/PartyData/clientDetails/mailingAddress/address4" />
	<xsl:variable name="attention" select="/PartyData/clientDetails/mailingAddress/attention" />
	<xsl:variable name="city" select="/PartyData/clientDetails/mailingAddress/city" />
	<xsl:variable name="county" select="/PartyData/clientDetails/mailingAddress/county" />
	<xsl:variable name="state" select="/PartyData/clientDetails/mailingAddress/state" />
	<xsl:variable name="addresseffdate" select="/PartyData/clientDetails/mailingAddress/addresseffdate" />
	<xsl:variable name="addressexpdate" select="/PartyData/clientDetails/mailingAddress/addressexpdate" />
	<xsl:variable name="zip" select="/PartyData/clientDetails/mailingAddress/ZIP" />
	<xsl:variable name="zipcode" select="/PartyData/clientDetails/mailingAddress/zipcode" />
	<xsl:variable name="locationCountry" select="/PartyData/clientDetails/mailingAddress/countryCode" />
	<!-- Location Details-->


	<xsl:variable name="name" select="/PartyData/clientDetails/name" />
	<xsl:variable name="dba" select="/PartyData/clientDetails/dba" />
	<xsl:variable name="primaryContact" select="/PartyData/clientDetails/primaryContact" />
	<xsl:variable name="type" select="/PartyData/clientDetails/type" />
	<xsl:variable name="PartyName" select="/PartyData/clientDetails/PartyName" />
	<xsl:variable name="partyName" select="/PartyData/clientDetails/partyName" />
	<xsl:variable name="PartyNamePrefixCode" select="/PartyData/clientDetails/PartyNamePrefixCode" />
	<xsl:variable name="prefix" select="/PartyData/clientDetails/prefix" />
	<xsl:variable name="PartyNameSuffixCode" select="/PartyData/clientDetails/PartyNameSuffixCode" />
	<xsl:variable name="suffix" select="/PartyData/clientDetails/suffix" />
	<xsl:variable name="PartyFirstName" select="/PartyData/clientDetails/PartyFirstName" />
	<xsl:variable name="firstName" select="/PartyData/clientDetails/firstName" />
	<xsl:variable name="PartyMiddleName" select="/PartyData/clientDetails/PartyMiddleName" />
	<xsl:variable name="middleName" select="/PartyData/clientDetails/middleName" />
	<xsl:variable name="PartyCorrespondenceName" select="/PartyData/clientDetails/PartyCorrespondenceName" />

	<xsl:variable name="deleted" select="/PartyData/clientDetails/deleted" />
	<xsl:variable name="phoneNumber" select="/PartyData/clientDetails/phoneNumber" />
	<xsl:variable name="phoneExtension" select="/PartyData/clientDetails/phoneExtension" />
	<xsl:variable name="phoneTypeCode" select="/PartyData/clientDetails/PhoneTypeCode" />
	<xsl:variable name="phoneCountryCode" select="/PartyData/clientDetails/PhoneCountryCode" />
	<xsl:variable name="faxNumber" select="/PartyData/clientDetails/faxNumber" />
	<xsl:variable name="misc" select="/PartyData/clientDetails/misc" />
	<xsl:variable name="emailAddress" select="/PartyData/clientDetails/emailAddress" />

	<xsl:variable name="partyDeathDate" select="/PartyData/clientDetails/PartyDeathDate" />
	<xsl:variable name="partyComments" select="/PartyData/clientDetails/PartyComments" />
	<xsl:variable name="preferredContactMethod" select="/PartyData/clientDetails/PreferredContactMethod" />
	<xsl:variable name="replaceContact" select="/PartyData/clientDetails/replaceContact" />
	<xsl:variable name="PartyRecordPartyId" select="/PartyData/PartyRecordPartyId" />

	<xsl:variable name="lower">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="upper">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	
	<xsl:template match="/PartyData">
		<PartyRecord>
			<PartyRecordPartyId>
				<xsl:value-of select="$PartyRecordPartyId"/>
			</PartyRecordPartyId>
			
			<Party>
        <ExternalId>
					<xsl:choose>
						<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
							<xsl:value-of select="/PartyData/PartyDetailDTO/PartyIndividualDetail/Party/ExternalID" />
						</xsl:when>
						<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
							<xsl:value-of select="/PartyData/PartyDetailDTO/PartyBusinessDetail/Party/ExternalID" />
						</xsl:when>
					</xsl:choose>
				</ExternalId>
				<xsl:choose>
					<xsl:when test="string($PartyName) != '' or string($partyName) != '' ">
						<xsl:choose>
							<xsl:when test="string($PartyName) != ''">
								<PartyName>
									<xsl:value-of select="$PartyName"/>
								</PartyName>
							</xsl:when>
							<xsl:when test="string($partyName) != '' ">
								<PartyName>
									<xsl:value-of select="$partyName"/>
								</PartyName>
							</xsl:when>
						</xsl:choose>

						<xsl:choose>
							<xsl:when test="string($PartyFirstName) != ''">
								<PartyFirstName>
									<xsl:value-of select="$PartyFirstName"/>
								</PartyFirstName>
							</xsl:when>
							<xsl:when test="string($firstName) != '' ">
								<PartyFirstName>
									<xsl:value-of select="$firstName"/>
								</PartyFirstName>
							</xsl:when>
						</xsl:choose>

						<xsl:choose>
							<xsl:when test="string($PartyMiddleName) != ''">
								<PartyMiddleName>
									<xsl:value-of select="$PartyMiddleName"/>
								</PartyMiddleName>
							</xsl:when>
							<xsl:when test="string($middleName) != '' ">
								<PartyMiddleName>
									<xsl:value-of select="$middleName"/>
								</PartyMiddleName>
							</xsl:when>
						</xsl:choose>

						<xsl:choose>
							<xsl:when test="string($PartyNamePrefixCode) != ''">
								<PartyNamePrefixCode>
									<xsl:value-of select="$PartyNamePrefixCode"/>
								</PartyNamePrefixCode>
							</xsl:when>
							<xsl:when test="string($prefix) != '' ">
								<PartyNamePrefixCode>
									<xsl:value-of select="$prefix"/>
								</PartyNamePrefixCode>
							</xsl:when>
						</xsl:choose>

						<xsl:choose>
							<xsl:when test="string($PartyNameSuffixCode) != ''">
								<PartyNameSuffixCode>
									<xsl:value-of select="$PartyNameSuffixCode"/>
								</PartyNameSuffixCode>
							</xsl:when>
							<xsl:when test="string($suffix) != '' ">
								<PartyNameSuffixCode>
									<xsl:value-of select="$suffix"/>
								</PartyNameSuffixCode>
							</xsl:when>
						</xsl:choose>

						<PartyLegacyName>
							<xsl:value-of select="string(Util:GetLegacyName($PartyNamePrefixCode,$prefix,$PartyFirstName,$firstName
										  ,$PartyMiddleName,$middleName,$PartyName,$partyName,$PartyNameSuffixCode,$suffix))"/>
						</PartyLegacyName>

					</xsl:when>
					<xsl:otherwise>
						<xsl:if test="string($name) != ''">
							<PartyName>
								<xsl:value-of select="string(Util:parseLegacyName('LASTNAME',$name))"/>
							</PartyName>
						</xsl:if>
						<xsl:if test="string($name) != ''">
							<PartyFirstName>
								<xsl:value-of select="string(Util:parseLegacyName('FIRSTNAME',$name))"/>
							</PartyFirstName>
						</xsl:if>
						<xsl:if test="string($name) != ''">
							<PartyMiddleName>
								<xsl:value-of select="string(Util:parseLegacyName('MIDDLENAME',$name))"/>
							</PartyMiddleName>
						</xsl:if>
						<xsl:if test="string($name) != ''">
							<PartyNamePrefixCode>
								<xsl:value-of select="string(Util:parseLegacyName('PREFIXCODE',$name))"/>
							</PartyNamePrefixCode>
						</xsl:if>
						<xsl:if test="string($name) != ''">
							<PartyNameSuffixCode>
								<xsl:value-of select="string(Util:parseLegacyName('SUFFIXCODE',$name))"/>
							</PartyNameSuffixCode>
						</xsl:if>
						<xsl:if test="string($name) != ''">
							<PartyLegacyName>
								<xsl:value-of select="$name"/>
							</PartyLegacyName>
						</xsl:if>
					</xsl:otherwise>
				</xsl:choose>

        
         <PartyGenderCode>
            <xsl:choose>
              <xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
                <xsl:value-of select="/PartyData/PartyDetailDTO/PartyIndividualDetail/PartyIndividual/GenderCode"/>
              </xsl:when>
            </xsl:choose>
				</PartyGenderCode>

        <PartyMaritalStatusCode>
          <xsl:choose>
            <xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
              <xsl:value-of select="/PartyData/PartyDetailDTO/PartyIndividualDetail/PartyIndividual/MaritalStatusCode"/>
            </xsl:when>
          </xsl:choose>
        </PartyMaritalStatusCode>
        
        <PartyPreferredLanguageCode>
					    <xsl:value-of select="string(Util:GetChildKey('DCTLanguageType',..//PreferredLanguage,'8037'))"/>
				</PartyPreferredLanguageCode>
        <!--<PartyBirthDate>
					<xsl:value-of select="Party/PartyBirthDate"/>
				</PartyBirthDate-->

				<xsl:if test="string($replaceContact) != ''">
					<ReplaceContactInfo>
						<xsl:value-of select="$replaceContact"/>
					</ReplaceContactInfo>
				</xsl:if>


				<xsl:if test="string($partyDeathDate) != ''">
					<PartyDeathDate>
						<xsl:value-of select="$partyDeathDate"/>
					</PartyDeathDate>
				</xsl:if>

				<xsl:if test="string($partyComments) != ''">
					<PartyComments>
						<xsl:value-of select="$partyComments"/>
					</PartyComments>
				</xsl:if>

				<xsl:if test="string($preferredContactMethod) != ''">
					<PreferredContactMethod>
						<xsl:value-of select="$preferredContactMethod"/>
					</PreferredContactMethod>
				</xsl:if>

				<xsl:if test="string($PartyCorrespondenceName) != ''">
					<PartyCorrespondenceName>
						<xsl:value-of select="$PartyCorrespondenceName"/>
					</PartyCorrespondenceName>
				</xsl:if>

				<xsl:if test="string($deleted) != ''">
					<xsl:choose>
						<xsl:when test="$deleted = '1' or translate($type,$lower,$upper) = 'TRUE' or translate($type,$lower,$upper) = 'YES'">
							<PartyDeletedIndicator>Y</PartyDeletedIndicator>
						</xsl:when>
						<xsl:when test="$deleted = '0' or translate($type,$lower,$upper) = 'FALSE' or translate($type,$lower,$upper) = 'NO'">
							<PartyDeletedIndicator>N</PartyDeletedIndicator>
						</xsl:when>
						<xsl:otherwise>
							<PartyDeletedIndicator>
								<xsl:value-of select="$deleted"/>
							</PartyDeletedIndicator>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:if>

				<xsl:if test="string($name) != ''">
					<PartyTypeCode>
						<xsl:value-of select="$type"/>
					</PartyTypeCode>
				</xsl:if>

				<!--PartyTaxId>
					<xsl:value-of select="Party/PartyTaxId"/>
				</PartyTaxId-->
				<PartyLockingTS>
					<xsl:choose>
						<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
							<xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/LastTransactionID"/>
						</xsl:when>
						<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
							<xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/LastTransactionID"/>
						</xsl:when>
					</xsl:choose>

				</PartyLockingTS>

        <PartyOFACCheckNotRequired>
          <xsl:choose>
            <xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
              <xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/Party/BusinessPermitted"/>
            </xsl:when>
            <xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
							<xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/Party/BusinessPermitted"/>
						</xsl:when>
          </xsl:choose>
        </PartyOFACCheckNotRequired>
			</Party>

			<xsl:if test="$updateLocationRecord = 'True' and (string($address1) != '' or string($state) != '')">
				<xsl:variable name="IsLocationDetailsChanged">
					<xsl:choose>
						<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
							<xsl:choose>
								<xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address) > 0">
									<xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address">
										<xsl:call-template name="CheckLocationDetailsChange" />
									</xsl:for-each>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="string('true')"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
							<xsl:choose>
								<xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address) > 0">
									<xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address">
										<xsl:call-template name="CheckLocationDetailsChange" />
									</xsl:for-each>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="string('true')"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
					</xsl:choose>
				</xsl:variable>
				<xsl:if test="contains($IsLocationDetailsChanged, 'true') = 'true'">
					<Locations>
						<Location>
							<DefaultLocationIndicator>Y</DefaultLocationIndicator>
							<LocationAddressLine1>
								<xsl:value-of select="$address1"/>
							</LocationAddressLine1>
							<LocationAddressLine2>
								<xsl:value-of select="$address2"/>
							</LocationAddressLine2>
							<LocationAddressLine3>
								<xsl:value-of select="$address3"/>
							</LocationAddressLine3>
							<LocationAddressLine4>
								<xsl:value-of select="$address4"/>
							</LocationAddressLine4>
							<Attention>
								<xsl:value-of select="$attention"/>
							</Attention>
							<LocationEffectiveDate>
								<xsl:value-of select="$addresseffdate"/>
							</LocationEffectiveDate>
							<LocationExpirationDate>
								<xsl:value-of select="$addressexpdate"/>
							</LocationExpirationDate>
							<LocationCity>
								<xsl:value-of select="$city"/>
							</LocationCity>
							<LocationStateCode>
								<xsl:value-of select="$state"/>
							</LocationStateCode>
							<xsl:choose>
								<xsl:when test="string($zip) != ''">
									<LocationPostalCode>
										<xsl:value-of select="string(Util:CheckZipCodeFormat('ZIPCODE',$zip))"/>
									</LocationPostalCode>
									<LocationPostalCodeExtension>
										<xsl:value-of select="string(Util:CheckZipCodeFormat('ZIPEXTENSION',$zip))"/>
									</LocationPostalCodeExtension>
								</xsl:when>
								<xsl:when test="string($zipcode) != ''">
									<LocationPostalCode>
										<xsl:value-of select="string(Util:CheckZipCodeFormat('ZIPCODE',$zipcode))"/>
									</LocationPostalCode>
									<LocationPostalCodeExtension>
										<xsl:value-of select="string(Util:CheckZipCodeFormat('ZIPEXTENSION',$zipcode))"/>
									</LocationPostalCodeExtension>
								</xsl:when>
								<xsl:otherwise>
									<LocationPostalCode></LocationPostalCode>
									<LocationPostalCodeExtension></LocationPostalCodeExtension>
								</xsl:otherwise>
							</xsl:choose>

							<LocationCounty>
								<xsl:value-of select="$county"/>
							</LocationCounty>
							<LocationCountryCode>
								<xsl:value-of select="$locationCountry"/>
							</LocationCountryCode>

							<xsl:choose>
								<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
									<LocationId>
										<xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/PartyAddressID"/>
									</LocationId>
									<LocationLockingTS>
										<xsl:value-of select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/LastTransactionID"/>
									</LocationLockingTS>
								</xsl:when>
								<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
									<LocationId>
										<xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/PartyAddressID"/>
									</LocationId>
									<LocationLockingTS>
										<xsl:value-of select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/PartyAddress/LastTransactionID"/>
									</LocationLockingTS>
								</xsl:when>
							</xsl:choose>

							<LocationLatitude/>
							<LocationLongitude/>
							<LocationExtendedData/>
							<LocationInvolvements>
							
							<xsl:choose>
							<xsl:when test="$classicMode = '0'">
									
									
								<xsl:choose>
									<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
										<xsl:choose>
											<xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO[AddressTypeAssociationDTO = 'LA']) > 0">
												<xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO[AddressTypeAssociationDTO = 'LA']">
													<LocationInvolvement>
														<ObjectTypeCode>PTY</ObjectTypeCode>
														<ObjectId>
															<xsl:value-of select="$PartyRecordPartyId"/>
														</ObjectId>
														<RoleCode/>
														<LocationInvolvementTypeCode>LA</LocationInvolvementTypeCode>
														<EffectiveDate>
															<xsl:value-of select="EffectiveDate"/>
														</EffectiveDate>
														<ExpirationDate>
															<xsl:value-of select="ExpirationDate"/>
														</ExpirationDate>
														<LocationInvolvementExtendedData/>
													</LocationInvolvement>
												</xsl:for-each>
											</xsl:when>
											<xsl:otherwise>
												<LocationInvolvement>
													<ObjectTypeCode>PTY</ObjectTypeCode>
													<ObjectId>
														<xsl:value-of select="$PartyRecordPartyId"/>
													</ObjectId>
													<RoleCode/>
													<LocationInvolvementTypeCode>LA</LocationInvolvementTypeCode>
													<EffectiveDate>
														<xsl:value-of select="string(Util:GetCurrentDate())"/>
													</EffectiveDate>
													<ExpirationDate>
														<xsl:value-of select="string(Util:GetMaxDate())"/>
													</ExpirationDate>
													<LocationInvolvementExtendedData/>
												</LocationInvolvement>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
										<xsl:choose>
											<xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO[AddressTypeAssociationDTO = 'LA']) > 0">
												<xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO[AddressTypeAssociationDTO = 'LA']">
													<LocationInvolvement>
														<ObjectTypeCode>PTY</ObjectTypeCode>
														<ObjectId>
															<xsl:value-of select="$PartyRecordPartyId"/>
														</ObjectId>
														<RoleCode/>
														<LocationInvolvementTypeCode>LA</LocationInvolvementTypeCode>
														<EffectiveDate>
															<xsl:value-of select="EffectiveDate"/>
														</EffectiveDate>
														<ExpirationDate>
															<xsl:value-of select="ExpirationDate"/>
														</ExpirationDate>
														<LocationInvolvementExtendedData/>
													</LocationInvolvement>
												</xsl:for-each>
											</xsl:when>
											<xsl:otherwise>
												<LocationInvolvement>
													<ObjectTypeCode>PTY</ObjectTypeCode>
													<ObjectId>
														<xsl:value-of select="$PartyRecordPartyId"/>
													</ObjectId>
													<RoleCode/>
													<LocationInvolvementTypeCode>LA</LocationInvolvementTypeCode>
													<EffectiveDate>
														<xsl:value-of select="string(Util:GetCurrentDate())"/>
													</EffectiveDate>
													<ExpirationDate>
														<xsl:value-of select="string(Util:GetMaxDate())"/>
													</ExpirationDate>
													<LocationInvolvementExtendedData/>
												</LocationInvolvement>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
								</xsl:choose>
								
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
										<xsl:choose>
											<xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO[AddressTypeAssociationDTO = 'LEG']) > 0">
												<xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO[AddressTypeAssociationDTO = 'LEG']">
													<LocationInvolvement>
														<ObjectTypeCode>PTY</ObjectTypeCode>
														<ObjectId>
															<xsl:value-of select="$PartyRecordPartyId"/>
														</ObjectId>
														<RoleCode/>
														<LocationInvolvementTypeCode>_LEG</LocationInvolvementTypeCode>
														<EffectiveDate>
															<xsl:value-of select="EffectiveDate"/>
														</EffectiveDate>
														<ExpirationDate>
															<xsl:value-of select="ExpirationDate"/>
														</ExpirationDate>
														<LocationInvolvementExtendedData/>
													</LocationInvolvement>
												</xsl:for-each>
											</xsl:when>
											<xsl:otherwise>
												<LocationInvolvement>
													<ObjectTypeCode>PTY</ObjectTypeCode>
													<ObjectId>
														<xsl:value-of select="$PartyRecordPartyId"/>
													</ObjectId>
													<RoleCode/>
													<LocationInvolvementTypeCode>_LEG</LocationInvolvementTypeCode>
													<EffectiveDate>
														<xsl:value-of select="string(Util:GetCurrentDate())"/>
													</EffectiveDate>
													<ExpirationDate>
														<xsl:value-of select="string(Util:GetMaxDate())"/>
													</ExpirationDate>
													<LocationInvolvementExtendedData/>
												</LocationInvolvement>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
									<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
										<xsl:choose>
											<xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO[AddressTypeAssociationDTO = 'LEG']) > 0">
												<xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address/AddressTypeAssociations/AddressTypeAssociationDTO[AddressTypeAssociationDTO = 'LEG']">
													<LocationInvolvement>
														<ObjectTypeCode>PTY</ObjectTypeCode>
														<ObjectId>
															<xsl:value-of select="$PartyRecordPartyId"/>
														</ObjectId>
														<RoleCode/>
														<LocationInvolvementTypeCode>_LEG</LocationInvolvementTypeCode>
														<EffectiveDate>
															<xsl:value-of select="EffectiveDate"/>
														</EffectiveDate>
														<ExpirationDate>
															<xsl:value-of select="ExpirationDate"/>
														</ExpirationDate>
														<LocationInvolvementExtendedData/>
													</LocationInvolvement>
												</xsl:for-each>
											</xsl:when>
											<xsl:otherwise>
												<LocationInvolvement>
													<ObjectTypeCode>PTY</ObjectTypeCode>
													<ObjectId>
														<xsl:value-of select="$PartyRecordPartyId"/>
													</ObjectId>
													<RoleCode/>
													<LocationInvolvementTypeCode>_LEG</LocationInvolvementTypeCode>
													<EffectiveDate>
														<xsl:value-of select="string(Util:GetCurrentDate())"/>
													</EffectiveDate>
													<ExpirationDate>
														<xsl:value-of select="string(Util:GetMaxDate())"/>
													</ExpirationDate>
													<LocationInvolvementExtendedData/>
												</LocationInvolvement>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:when>
								</xsl:choose>
							</xsl:otherwise>
							</xsl:choose>
							</LocationInvolvements>
						</Location>
					</Locations>
				</xsl:if>
			</xsl:if>

			<xsl:if test="$updateEmailRecord = 'True'">
				<PartyEmails>
					<xsl:choose>
						<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
							<xsl:choose>
								<xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyEmail/PartyEmailDTO[IsPrimary = 'true']) > 0">
									<xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyEmail/PartyEmailDTO[IsPrimary = 'true']">
										<xsl:sort select="IsPrimary" order="descending" />
										<xsl:if test="position()=1">
											<xsl:if test="EmailAddress != $emailAddress">
												<xsl:call-template name="UpdateEmailAddress">
													<xsl:with-param name="EmailAddress" select="$emailAddress"/>
												</xsl:call-template>
											</xsl:if>
										</xsl:if>
									</xsl:for-each>
								</xsl:when>
								<xsl:otherwise>
									<xsl:if test="string($emailAddress) != ''">
										<PartyEmail>
											<EmailTypeCode>H</EmailTypeCode>
											<PrimaryIndicator>Y</PrimaryIndicator>
											<EmailAddress>
												<xsl:value-of select="$emailAddress"/>
											</EmailAddress>
										</PartyEmail>
									</xsl:if>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
							<xsl:choose>
								<xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyEmail/PartyEmailDTO[IsPrimary = 'true']) > 0">
									<xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyEmail/PartyEmailDTO[IsPrimary = 'true']">
										<xsl:sort select="IsPrimary" order="descending" />
										<xsl:if test="position()=1">
											<xsl:if test="EmailAddress != $emailAddress">
											<xsl:call-template name="UpdateEmailAddress">
												<xsl:with-param name="EmailAddress" select="$emailAddress"/>
											</xsl:call-template>
											</xsl:if>
										</xsl:if>
									</xsl:for-each>
								</xsl:when>
								<xsl:otherwise>
									<xsl:if test="string($emailAddress) != ''">
										<PartyEmail>
											<EmailTypeCode>H</EmailTypeCode>
											<PrimaryIndicator>Y</PrimaryIndicator>
											<EmailAddress>
												<xsl:value-of select="$emailAddress"/>
											</EmailAddress>
										</PartyEmail>
									</xsl:if>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
					</xsl:choose>
				</PartyEmails>
			</xsl:if>

			<xsl:if test="$updatePhonePrimaryRecord = 'True' and string(Util:FormatPhoneNumber(string($phoneNumber))) != ''
					or $updatePhoneFaxRecord = 'True' and string(Util:FormatPhoneNumber(string($faxNumber))) != ''">
				<PartyPhones>
					<xsl:if test="$updatePhonePrimaryRecord = 'True' and string(Util:FormatPhoneNumber(string($phoneNumber))) != ''">
						<xsl:choose>
							<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
								<xsl:choose>
									<xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true']) > 0">
										<xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true']">
                      <xsl:sort select="IsPrimary" order="descending" />
                      <xsl:sort select="LastUpdatedDate" order="descending" />
                      <xsl:if test="position()=1">
											  <xsl:if test ="FullPhoneNumber != $phoneNumber or PhoneExtension != $phoneExtension or PhoneTypeCode != $phoneTypeCode" >
												  <xsl:call-template name="UpdatePartyPhone">
													  <xsl:with-param name="PhoneNumber" select="string(Util:FormatPhoneNumber($phoneNumber))"/>
													  <xsl:with-param name="PhoneExtension" select="$phoneExtension"/>
													  <xsl:with-param name="PhoneTypeCode" select="$phoneTypeCode"/>
												  </xsl:call-template>
											  </xsl:if>
                      </xsl:if>
										</xsl:for-each>
									</xsl:when>
									<xsl:otherwise>
										<PartyPhone>
											<xsl:choose>
												<xsl:when test="string($phoneTypeCode) != ''">
													<PhoneTypeCode>
														<xsl:value-of select="$phoneTypeCode"/>
													</PhoneTypeCode>
												</xsl:when>
												<xsl:otherwise>
													<PhoneTypeCode>H</PhoneTypeCode>
												</xsl:otherwise>
											</xsl:choose>
											<PhoneNumber>
												<xsl:value-of select="string(Util:FormatPhoneNumber($phoneNumber))"/>
											</PhoneNumber>
											<PhoneExtension>
												<xsl:value-of select="$phoneExtension"/>
											</PhoneExtension>
											<PhoneCountryCode>
												<xsl:value-of select="$phoneCountryCode"/>
											</PhoneCountryCode>
											<PhoneFormatCode>US1</PhoneFormatCode>
											<PrimaryIndicator>Y</PrimaryIndicator>
											<PhoneExtendedData>
												<BestTimeToCallFrom/>
												<BestTimeToCallTo/>
											</PhoneExtendedData>
										</PartyPhone>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
								<xsl:choose>
									<xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true']) > 0">
										<xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO[IsPrimary = 'true']">
                      <xsl:sort select="IsPrimary" order="descending" />
                      <xsl:sort select="LastUpdatedDate" order="descending" />
                      <xsl:if test="position()=1">
											<xsl:if test ="FullPhoneNumber != $phoneNumber or PhoneExtension != $phoneExtension or PhoneTypeCode != $phoneTypeCode" >
												<xsl:call-template name="UpdatePartyPhone">
													<xsl:with-param name="PhoneNumber" select="string(Util:FormatPhoneNumber($phoneNumber))"/>
													<xsl:with-param name="PhoneExtension" select="$phoneExtension"/>
													<xsl:with-param name="PhoneTypeCode" select="$phoneTypeCode"/>
												</xsl:call-template>
											</xsl:if>
                      </xsl:if>
										</xsl:for-each>
									</xsl:when>
									<xsl:otherwise>
										<PartyPhone>
											<xsl:choose>
												<xsl:when test="string($phoneTypeCode) != ''">
													<PhoneTypeCode>
														<xsl:value-of select="$phoneTypeCode"/>
													</PhoneTypeCode>
												</xsl:when>
												<xsl:otherwise>
													<PhoneTypeCode>H</PhoneTypeCode>
												</xsl:otherwise>
											</xsl:choose>
											<PhoneNumber>
												<xsl:value-of select="string(Util:FormatPhoneNumber($phoneNumber))"/>
											</PhoneNumber>
											<PhoneExtension>
												<xsl:value-of select="$phoneExtension"/>
											</PhoneExtension>
											<PhoneCountryCode>
												<xsl:value-of select="$phoneCountryCode"/>
											</PhoneCountryCode>
											<PhoneFormatCode>US1</PhoneFormatCode>
											<PrimaryIndicator>Y</PrimaryIndicator>
											<PhoneExtendedData>
												<BestTimeToCallFrom/>
												<BestTimeToCallTo/>
											</PhoneExtendedData>
										</PartyPhone>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
						</xsl:choose>
					</xsl:if>

					<xsl:if test="$updatePhoneFaxRecord = 'True' and string(Util:FormatPhoneNumber(string($faxNumber))) != ''">
						<xsl:choose>
							<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
								<xsl:choose>
									<xsl:when test="count(PartyDetailDTO/PartyIndividualDetail/PartyPhone/PartyPhoneDTO[PhoneTypeCode = string(Util:GetOneRelatedItem('DCTPhoneType','F','26'))]) > 0">
										<xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyPhone/PartyPhoneDTO[PhoneTypeCode = string(Util:GetOneRelatedItem('DCTPhoneType','F','26'))]">
											<xsl:if test ="FullPhoneNumber != $faxNumber" >
												<xsl:call-template name="UpdatePartyPhone">
													<xsl:with-param name="PhoneNumber" select="string(Util:FormatPhoneNumber($faxNumber))"/>
												</xsl:call-template>
											</xsl:if>
										</xsl:for-each>
									</xsl:when>
									<xsl:otherwise>
										<PartyPhone>
											<PhoneTypeCode>F</PhoneTypeCode>
											<PhoneNumber>
												<xsl:value-of select="string(Util:FormatPhoneNumber($faxNumber))"/>
											</PhoneNumber>
											<PhoneExtension></PhoneExtension>
											<PhoneCountryCode>
												<xsl:value-of select="$phoneCountryCode"/>
											</PhoneCountryCode>
											<PhoneFormatCode>US1</PhoneFormatCode>
											<PhoneExtendedData>
												<BestTimeToCallFrom/>
												<BestTimeToCallTo/>
											</PhoneExtendedData>
										</PartyPhone>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
							<xsl:when test ="$PartyType = $BASEPARTYTYPEBUS">
								<xsl:choose>
									<xsl:when test="count(PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO[PhoneTypeCode = string(Util:GetOneRelatedItem('DCTPhoneType','F','26'))]) > 0">
										<xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyPhone/PartyPhoneDTO[PhoneTypeCode = string(Util:GetOneRelatedItem('DCTPhoneType','F','26'))]">
											<xsl:if test ="FullPhoneNumber != $faxNumber" >
												<xsl:call-template name="UpdatePartyPhone">
													<xsl:with-param name="PhoneNumber" select="string(Util:FormatPhoneNumber($faxNumber))"/>
												</xsl:call-template>
											</xsl:if>
										</xsl:for-each>
									</xsl:when>
									<xsl:otherwise>
										<PartyPhone>
											<PhoneTypeCode>F</PhoneTypeCode>
											<PhoneNumber>
												<xsl:value-of select="string(Util:FormatPhoneNumber($faxNumber))"/>
											</PhoneNumber>
											<PhoneExtension></PhoneExtension>
											<PhoneCountryCode>
												<xsl:value-of select="$phoneCountryCode"/>
											</PhoneCountryCode>
											<PhoneFormatCode>US1</PhoneFormatCode>
											<PhoneExtendedData>
												<BestTimeToCallFrom/>
												<BestTimeToCallTo/>
											</PhoneExtendedData>
										</PartyPhone>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:when>
						</xsl:choose>
					</xsl:if>
				</PartyPhones>
			</xsl:if>

			<xsl:if test="$updateOtherNameRecord = 'True' and string($dba) != ''">
				<PartyOtherNames>
					<PartyOtherName>
						<OtherNameTypeCode>DBA</OtherNameTypeCode>
						<OtherNamePartyName>
							<xsl:value-of select="$dba"/>
						</OtherNamePartyName>
						<xsl:choose>
							<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
								<xsl:if test="count(PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO/PartyIndName[NameTypeCode = '04']) > 0">
									<xsl:for-each select="PartyDetailDTO/PartyIndividualDetail/PartyIndNameDetail/PartyIndNameDetailDTO[PartyIndName/NameTypeCode = '04']">
										<PartyOtherNameId>
											<xsl:value-of select="PartyName/PartyNameID"/>
										</PartyOtherNameId>
										<PartyOtherNamesLockingTS>
											<xsl:value-of select="PartyName/LastTransactionID"/>
										</PartyOtherNamesLockingTS>
                    <PartyIndNamesLockingTS>
                      <xsl:value-of select="PartyName/LastTransactionID"/>
                    </PartyIndNamesLockingTS>
									</xsl:for-each>
								</xsl:if>
							</xsl:when>
							<xsl:when test ="$PartyType = $BASEPARTYTYPEIND">
								<xsl:if test="count(PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO/PartyBusName[NameTypeCode = '04']) > 0">
									<xsl:for-each select="PartyDetailDTO/PartyBusinessDetail/PartyBusNameDetail/PartyBusNameDetailDTO[PartyBusName/NameTypeCode = '04']">
										<PartyOtherNameId>
											<xsl:value-of select="PartyName/PartyNameID"/>
										</PartyOtherNameId>
										<PartyOtherNamesLockingTS>
											<xsl:value-of select="PartyName/LastTransactionID"/>
										</PartyOtherNamesLockingTS>
                    <PartyIndNamesLockingTS>
                      <xsl:value-of select="PartyName/LastTransactionID"/>
                    </PartyIndNamesLockingTS>
									</xsl:for-each>
								</xsl:if>
							</xsl:when>
						</xsl:choose>
						<OtherNameFirstName/>
						<OtherNameMiddleName/>
						<OtherNamePrefixCode/>
						<OtherNameSuffixCode/>
						<OtherNameExtendedData/>
					</PartyOtherName>
				</PartyOtherNames>
			</xsl:if>

		</PartyRecord>
	</xsl:template>
	<xsl:template name="CheckLocationDetailsChange">
		<xsl:variable name="varPostalCode">
			<xsl:call-template name="GetPostalCode" />
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="LocationDetailsLine1 != $address1">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="LocationDetailsLine2 != string($address2)">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="LocationDetailsLine3 != $address3">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="LocationDetailsLine4 != $address4">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="Attention != $attention">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="EffectiveDate != $addresseffdate">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="ExpirationDate != $addressexpdate">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="AdminDivisionPrimary != $city">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="NationalDivisionPrimary != string(Util:GetOneRelatedItem('DCTStateType',$state,'240'))">
				<xsl:value-of select="string('true')"/>
			</xsl:when>

			<xsl:when test="PostalCode != $varPostalCode">
				<xsl:value-of select="string('true')"/>
			</xsl:when>

			<xsl:when test="NationalDivisionSecondary != $county">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:when test="CountryCode != string(Util:GetOneRelatedItem('DCTCountryType',$locationCountry,'243'))">
				<xsl:value-of select="string('true')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="string('false')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="GetPostalCode">
		<xsl:choose>
			<xsl:when test="string($zip) != ''">
				<xsl:variable name="LocationPostalCode" select="string(Util:CheckZipCodeFormat('ZIPCODE',$zip))"/>
				<xsl:variable name="LocationPostalCodeExtension" select="string(Util:CheckZipCodeFormat('ZIPEXTENSION',$zip))"/>

				<xsl:choose>
					<xsl:when test="string(Util:GetValidPostalCode($LocationPostalCode,$LocationPostalCodeExtension)) != ''">
						<xsl:value-of select="string(Util:GetValidPostalCode($LocationPostalCode,$LocationPostalCodeExtension))"/>

					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="''"/>
					</xsl:otherwise>
				</xsl:choose>

			</xsl:when>
			<xsl:when test="string($zipcode) != ''">
				<xsl:variable name="LocationPostalCode" select="string(Util:CheckZipCodeFormat('ZIPCODE',$zipcode))"/>
				<xsl:variable name="LocationPostalCodeExtension" select="string(Util:CheckZipCodeFormat('ZIPEXTENSION',$zipcode))"/>

				<xsl:choose>
					<xsl:when test="string(Util:GetValidPostalCode($LocationPostalCode,$LocationPostalCodeExtension)) != ''">
						<xsl:value-of select="string(Util:GetValidPostalCode($LocationPostalCode,$LocationPostalCodeExtension))"/>

					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="''"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="UpdateEmailAddress">
		<xsl:param name="EmailAddress"/>
		<PartyEmail>
			<PartyEmailId>
				<xsl:value-of select="PartyEmailID"/>
			</PartyEmailId>
			<EmailTypeCode>
				<xsl:value-of select="string(Util:GetChildKey('DCTEmailType',EmailTypeCode,'31'))"/>
			</EmailTypeCode>
			<EmailAddress>
				<xsl:choose>
					<xsl:when test="string($EmailAddress) != ''">
						<xsl:value-of select="$EmailAddress"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="EmailAddress"/>
					</xsl:otherwise>
				</xsl:choose>
			</EmailAddress>
			<PartyEmailLockingTS>
				<xsl:value-of select="LastTransactionID"/>
			</PartyEmailLockingTS>
			<xsl:value-of disable-output-escaping="yes" select="string(Util:GetValueByKey('ExtendedData'))"/>
			<xsl:choose>
				<xsl:when test="IsPrimary='true'">
					<PrimaryIndicator>1</PrimaryIndicator>
				</xsl:when>
				<xsl:otherwise>
					<PrimaryIndicator>0</PrimaryIndicator>
				</xsl:otherwise>
			</xsl:choose>
		</PartyEmail>
	</xsl:template>

	
</xsl:stylesheet>
