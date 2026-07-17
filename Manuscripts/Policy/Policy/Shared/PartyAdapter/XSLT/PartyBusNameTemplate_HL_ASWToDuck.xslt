<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:import href="CommonTemplates.xslt"/>
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:template name="PartyBusName">
    <PartyOtherName>
      <PartyOtherNameId>
        <xsl:value-of select="PartyBusNameID"/>
      </PartyOtherNameId>
      <OtherNameTypeCode>
        <xsl:value-of select="string(Util:GetChildKey('DCTNameType',NameTypeCode,'29'))"/>
      </OtherNameTypeCode>
      <OtherNamePartyName>
        <xsl:value-of select="Name"/>
      </OtherNamePartyName>
      <OtherNameIsPrimary>
        <xsl:choose>
          <xsl:when test="(../PartyName/IsPrimary) = 'true'">1</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </OtherNameIsPrimary>
      <OtherNameIsDefault>
        <xsl:choose>
          <xsl:when test="(../PartyName/IsDefault) = 'true'">1</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </OtherNameIsDefault>
      <OtherNameCountryCode>
        <xsl:value-of select="string(Util:GetChildKey('DCTCountryType',../PartyName/CountryCode,'243'))"/>
      </OtherNameCountryCode>
	  
	  <xsl:for-each select="./BusinessNameExtendedData/ExtendedFields/ExtendedFieldDTO">
		   <xsl:call-template name="ASWExtendedDataToDuck">
			<xsl:with-param name="TagName">OtherNameExtendedData</xsl:with-param>		
		  </xsl:call-template>
	  </xsl:for-each>	  
	  <PartyOtherNameSuiteExtendedData>
		<xsl:for-each select="./BusinessNameExtendedData/ExtendedFields/ExtendedFieldDTO">
			<xsl:call-template name="SuiteASWExtendedDataToDuck">
				<xsl:with-param name="SuiteTagName">PartyOtherNameSuiteExtendedData</xsl:with-param>
			</xsl:call-template>
		</xsl:for-each>
		</PartyOtherNameSuiteExtendedData>
      <OtherNameComments>
        <xsl:value-of select="Comment"/>
      </OtherNameComments>
      <OtherNameEffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToDuckFormat(../PartyName/EffectiveDate))"/>
      </OtherNameEffectiveDate>
      <OtherNameExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToDuckFormat(../PartyName/ExpirationDate))"/>
      </OtherNameExpirationDate>
      <IsExpired>
        <xsl:value-of select="string(Util:IsExpiredRecord(../PartyName/ExpirationDate))"/>
      </IsExpired>
      <PartyBusNamesLockingTS>
        <xsl:value-of select="LastTransactionID"/>
      </PartyBusNamesLockingTS>
      <PartyOtherNamesLockingTS>
        <xsl:value-of select="../PartyName/LastTransactionID"/>
      </PartyOtherNamesLockingTS>
    </PartyOtherName>
  </xsl:template>

   <xsl:template name="PartyName">
    <PartyOtherName>
      <PartyOtherNameId>
        <xsl:value-of select="PartyNameID"/>
      </PartyOtherNameId>
      <OtherNameTypeCode>
        <xsl:value-of select="string(Util:GetChildKey('DCTNameType',NameTypeCode,'29'))"/>
      </OtherNameTypeCode>
      <OtherNameIsPrimary>
        <xsl:choose>
          <xsl:when test="(IsPrimary) = 'true'">1</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </OtherNameIsPrimary>
      <OtherNameIsDefault>
        <xsl:choose>
          <xsl:when test="(IsDefault) = 'true'">1</xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose>
      </OtherNameIsDefault>
      <OtherNameCountryCode>
        <xsl:value-of select="string(Util:GetChildKey('DCTCountryType',CountryCode,'243'))"/>
      </OtherNameCountryCode>
      <OtherNameComments>
        <xsl:value-of select="Comment"/>
      </OtherNameComments>
      <OtherNameEffectiveDate>
        <xsl:value-of select="string(Util:ConvertDateToDuckFormat(EffectiveDate))"/>
      </OtherNameEffectiveDate>
      <OtherNameExpirationDate>
        <xsl:value-of select="string(Util:ConvertDateToDuckFormat(ExpirationDate))"/>
      </OtherNameExpirationDate>
      <PartyOtherNamesLockingTS>
        <xsl:value-of select="LastTransactionID"/>
      </PartyOtherNamesLockingTS>
    </PartyOtherName>
  </xsl:template>
</xsl:stylesheet>