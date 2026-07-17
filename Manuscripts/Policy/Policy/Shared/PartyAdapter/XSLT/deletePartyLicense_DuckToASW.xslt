<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://epc.accenture.com/2013/06/26/Type" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:template match="/">
    <PartyLicenseDTO xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://epc.accenture.com/2013/06/26/Type">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <xsl:for-each select="PartyRecord/PartyLicenses/PartyLicense">

        <EffectiveDate>
          <xsl:value-of select="string(Util:ConvertDateToAswFormat(LicenseEffectiveDate))"/>
        </EffectiveDate>
        <ExpirationDate>
          <xsl:value-of select="string(Util:ConvertDateToAswFormat(LicenseExpirationDate))"/>
        </ExpirationDate>
        <LastTransactionID>
          <xsl:value-of select="PartyLicenseLockingTS"/>
        </LastTransactionID>
        <!--<xsl:value-of select="string(Util:GetMaxDate())"/>-->
        <LastUpdatedDate>
          <!--<xsl:value-of select="string(Util:GetValueByKey('TransactionDate'))"/>-->
          <xsl:value-of select="string(Util:GetCurrentDate())"/>
        </LastUpdatedDate>
        <PartyID>
          <xsl:value-of select="../../PartyRecordPartyId"/>
        </PartyID>
        <PartyLicenseID>
          <xsl:value-of select="PartyLicenseId"/>
        </PartyLicenseID>
        <PartyLicenseNumber>
          <xsl:value-of select="LicenseNumber"/>
        </PartyLicenseNumber>

      </xsl:for-each>
    </PartyLicenseDTO>
  </xsl:template>
</xsl:stylesheet>