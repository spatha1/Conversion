<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:output omit-xml-declaration="yes" indent="yes"/>

  <xsl:template match="/">
    <protectiondetails>
      <xsl:for-each select="//session/data">
        <xsl:variable name="policyNode" select="policy"/>
        <xsl:for-each select="account/location">
          <protection>
            <EffectiveDate>
              <xsl:value-of select="$policyNode/EffectiveDate"/>
            </EffectiveDate>
            <PolicyId>
              <xsl:value-of select="ancestor::session/@id"/>
            </PolicyId>
            <ExpirationDate>
              <xsl:value-of select="$policyNode/ExpirationDate"/>
            </ExpirationDate>
            <MembershipStatus>
              <xsl:value-of select="$policyNode/Status"/>
            </MembershipStatus>
            <ProtectionNumber>
              <xsl:value-of select="$policyNode/policyProcessing/CurrentPolicyNumberIdentifier"/>
            </ProtectionNumber>
			<xsl:variable name="State">
				<xsl:choose>
				  <xsl:when test="address/State = '100'"><xsl:value-of select="'NEW ZEALAND'" /></xsl:when>				  
				  <xsl:otherwise><xsl:value-of select="address/State" /></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
            <RiskAddress>
              <xsl:value-of select="concat(address/Address1, ',', address/City, ',', $State, ',', address/ZipCode)"/>
            </RiskAddress>
          </protection>
        </xsl:for-each>
      </xsl:for-each>
    </protectiondetails>
  </xsl:template>

</xsl:stylesheet>
