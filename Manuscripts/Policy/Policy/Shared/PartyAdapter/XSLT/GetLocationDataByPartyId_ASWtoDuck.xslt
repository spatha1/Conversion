<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:import href="CommonTemplates.xslt"/>
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:variable name="LocationPartyName" select="string(Util:GetValueByKey('LocationPartyName'))" />
	<xsl:template match="/PartyDetailDTO">
		<PartyData>
			<xsl:call-template name="partyLocationRecordTemplate">
			</xsl:call-template>
		</PartyData>
	</xsl:template>

	<xsl:template name="partyLocationRecordTemplate">
		<xsl:if test="$LocationPartyName!=''">
			<PartyCorrespondenceName>
				<xsl:value-of select="$LocationPartyName" />
			</PartyCorrespondenceName>
		</xsl:if>
		<xsl:choose>
			<!--Party Type = Individual-->
			<xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyType)) = string(Util:getBasePartyTypeFromASWPartyType('IND'))">
				<xsl:call-template name="indPartyLocationInfo" />
			</xsl:when>

			<!--Party Type = Business-->
			<xsl:when test="string(Util:getBasePartyTypeFromASWPartyType(PartyType)) = string(Util:getBasePartyTypeFromASWPartyType('BUS'))">
				<xsl:call-template name="busPartyLocationInfo" />
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="indPartyLocationInfo" >
		<xsl:if test="count(PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address) > 0">
			<xsl:for-each select="PartyIndividualDetail/PartyAddressDetail/PartyAddressDetailDTO/Address">
				<xsl:if test="../PartyAddress/IsDefault = 'true'">
					<LocationData>
						<xsl:variable name="countryCode" select="CountryCode"/>
            <xsl:call-template name="GenerateDCTFieldForAddress">
							<xsl:with-param name="DCTFieldName" select="'LocationAddressLine1'" />
							<xsl:with-param name="CountryCode" select="$countryCode" />
						</xsl:call-template>
            
						<xsl:call-template name="GenerateDCTFieldForAddress">
							<xsl:with-param name="DCTFieldName" select="'LocationCity'" />
							<xsl:with-param name="CountryCode" select="$countryCode" />
						</xsl:call-template>

            <xsl:call-template name="GenerateDCTFieldForAddress">
              <xsl:with-param name="DCTFieldName" select="'LocationStateCode'" />
              <xsl:with-param name="CountryCode" select="$countryCode" />
            </xsl:call-template>

            <xsl:call-template name="GenerateDCTFieldForAddress">
              <xsl:with-param name="DCTFieldName" select="'LocationStateName'" />
              <xsl:with-param name="CountryCode" select="$countryCode" />
            </xsl:call-template>
            
						<xsl:call-template name="GenerateDCTFieldForAddress">
							<xsl:with-param name="DCTFieldName" select="'LocationPostalCode'" />
							<xsl:with-param name="CountryCode" select="$countryCode" />
						</xsl:call-template>
					</LocationData>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

	<xsl:template name="busPartyLocationInfo" >
		<xsl:if test="count(PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address) > 0">
			<xsl:for-each select="PartyBusinessDetail/PartyAddressDetail/PartyAddressDetailDTO/Address">
				<xsl:if test="../PartyAddress/IsDefault = 'true'">
					<LocationData>
						<xsl:variable name="countryCode" select="CountryCode"/>
            <xsl:call-template name="GenerateDCTFieldForAddress">
							<xsl:with-param name="DCTFieldName" select="'LocationAddressLine1'" />
							<xsl:with-param name="CountryCode" select="$countryCode" />
						</xsl:call-template>
            
						<xsl:call-template name="GenerateDCTFieldForAddress">
							<xsl:with-param name="DCTFieldName" select="'LocationCity'" />
							<xsl:with-param name="CountryCode" select="$countryCode" />
						</xsl:call-template>

            <xsl:call-template name="GenerateDCTFieldForAddress">
              <xsl:with-param name="DCTFieldName" select="'LocationStateCode'" />
              <xsl:with-param name="CountryCode" select="$countryCode" />
            </xsl:call-template>

            <xsl:call-template name="GenerateDCTFieldForAddress">
              <xsl:with-param name="DCTFieldName" select="'LocationStateName'" />
              <xsl:with-param name="CountryCode" select="$countryCode" />
            </xsl:call-template>
						
						<xsl:call-template name="GenerateDCTFieldForAddress">
							<xsl:with-param name="DCTFieldName" select="'LocationPostalCode'" />
							<xsl:with-param name="CountryCode" select="$countryCode" />
						</xsl:call-template>
					</LocationData>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

	<xsl:template name="GenerateDCTFieldForAddress">
		<xsl:param name="DCTFieldName" />
		<xsl:param name="CountryCode" />
		<xsl:param name="TagName" />
		<!--xsl:choose>
			<xsl:when test="string(Util:CheckDCTNodeConfigurability($DCTFieldName,$CountryCode,'ADDRESS')) = 'true'"-->

				<xsl:call-template name="GenerateDCTField">
					<xsl:with-param name="DCTFieldName" select="$DCTFieldName" />
					<xsl:with-param name="CountryCode" select="$CountryCode" />
					<xsl:with-param name="ComponentName" select="'ADDRESS'" />
					<xsl:with-param name="TagPrefix" select="''" />
					<xsl:with-param name="TagName" select="$TagName" />
				</xsl:call-template>
		<!--/xsl:when>
		</xsl:choose-->
	</xsl:template>

  <xsl:template name="GenerateDCTField">
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
        <xsl:call-template name="PostalCodeProcessing">
          <xsl:with-param name="elementName" select="$elementName" />
          <xsl:with-param name="valueOfElement" select="$valueOfElement" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--Postal code split conditions-->
  <xsl:template name="PostalCodeProcessing">
    <xsl:param name="elementName" />
    <xsl:param name="valueOfElement" />
    <xsl:choose>
      <xsl:when test="contains($valueOfElement, '-')">
        <xsl:variable name="varLocationPostalCode" select="substring-before($valueOfElement,'-')"/>
        <xsl:variable name="varLocationPostalCodeExtension" select="substring-after($valueOfElement,'-')"/>
        <xsl:element name="{$elementName}">
          <xsl:value-of select="$varLocationPostalCode" />
        </xsl:element>
          <xsl:choose>
            <xsl:when test="$elementName != 'ZIPCode'">
              <xsl:element name="LocationPostalCodeExtension">
                <xsl:value-of select="$varLocationPostalCodeExtension" />
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:element name="ZIPCodeExt">
                <xsl:value-of select="$varLocationPostalCodeExtension" />
              </xsl:element>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{$elementName}">
          <xsl:value-of select="$valueOfElement" />
        </xsl:element>
          <xsl:choose>
            <xsl:when test="$elementName != 'ZIPCode'">
              <xsl:element name="LocationPostalCodeExtension">
              </xsl:element>
            </xsl:when>
            <xsl:otherwise>
              <xsl:element name="ZIPCodeExt">
              </xsl:element>
            </xsl:otherwise>
          </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
