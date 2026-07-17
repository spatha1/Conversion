<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
	<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="yes"/>
	<xsl:template match="/">
		<xsl:variable name="Membernumber">		
			<xsl:value-of select="//data/account/CMLNumber"/>
		</xsl:variable>
		<xsl:variable name="TradingName">
			<xsl:value-of select="//data/account/Name"/>
		</xsl:variable>
		<xsl:variable name="ContactNumber">
			<xsl:variable name="FormatContactNumber">
			   <xsl:value-of select="//data/account/CSLPhoneNumber"/>
		    </xsl:variable>
			<xsl:value-of select="concat(substring($FormatContactNumber, 1, 4), ' ', substring($FormatContactNumber, 5, 3), ' ', substring($FormatContactNumber, 8, 3))" />
		</xsl:variable>
		<xsl:variable name="RAMName">
			<xsl:value-of select="//data/account/CMLRiskAccountManager"/>
		</xsl:variable>		
		<xsl:variable name="RAMContactNumber">
			<xsl:value-of select="//data/account/RAMContact"/>
		</xsl:variable>
		<xsl:variable name="RAMContactNumberFormatted">
			<xsl:variable name="RAMContactNumberPartOne" select="substring($RAMContactNumber, 1, 4)" />
			<xsl:variable name="RAMContactNumberPartTwo" select="substring($RAMContactNumber, 5, 3)" />
			<xsl:variable name="RAMContactNumberPartThree" select="substring($RAMContactNumber, 8, 3)" />			
			  <xsl:value-of select="concat($RAMContactNumberPartOne, ' ',$RAMContactNumberPartTwo, ' ', $RAMContactNumberPartThree)" />
		</xsl:variable>	
		<xsl:variable name="QuoteNumber">
			<xsl:value-of select="//data/policy/HeaderPolicyNumber"/>
		</xsl:variable>
		<xsl:variable name="ProductType">
			<xsl:choose>
				<xsl:when test="//data/policy/LineOfBusiness = 'BusinessPackage'">
					<xsl:value-of select="'Business Protections'"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="'Personal Protections'"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="oldExpirydate">
			<xsl:value-of select="//data/policy/EffectiveDate"/>
		</xsl:variable>
		<!-- Expiration Date -->
		<xsl:variable name="Expirydate">
			<xsl:variable name="year" select="substring($oldExpirydate, 1, 4)" />
			<xsl:variable name="month" select="substring($oldExpirydate, 6, 2)" />
			<xsl:variable name="day" select="substring($oldExpirydate, 9, 2)" />
			<xsl:variable name="MonthName">
				<xsl:choose>
				  <xsl:when test="$month = '01'"><xsl:value-of select="'Jan'" /></xsl:when>
				  <xsl:when test="$month = '02'"><xsl:value-of select="'Feb'" /></xsl:when>
				  <xsl:when test="$month = '03'"><xsl:value-of select="'Mar'" /></xsl:when>
				  <xsl:when test="$month = '04'"><xsl:value-of select="'Apr'" /></xsl:when>
				  <xsl:when test="$month = '05'"><xsl:value-of select="'May'" /></xsl:when>
				  <xsl:when test="$month = '06'"><xsl:value-of select="'Jun'" /></xsl:when>
				  <xsl:when test="$month = '07'"><xsl:value-of select="'Jul'" /></xsl:when>
				  <xsl:when test="$month = '08'"><xsl:value-of select="'Aug'" /></xsl:when>
				  <xsl:when test="$month = '09'"><xsl:value-of select="'Sep'" /></xsl:when>
				  <xsl:when test="$month = '10'"><xsl:value-of select="'Oct'" /></xsl:when>
				  <xsl:when test="$month = '11'"><xsl:value-of select="'Nov'" /></xsl:when>
				  <xsl:when test="$month = '12'"><xsl:value-of select="'Dec'" /></xsl:when>
				  <xsl:otherwise><xsl:value-of select="'Invalid'" /></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			 <xsl:value-of select="concat(' ',$day, ' ',$MonthName, ' ', $year)" />
		</xsl:variable>	
		<xsl:variable name="ExpiryDateWithoutTime">
			<xsl:variable name="year" select="substring($oldExpirydate, 1, 4)" />
			<xsl:variable name="month" select="substring($oldExpirydate, 6, 2)" />
			<xsl:variable name="day" select="substring($oldExpirydate, 9, 2)" />
			<xsl:variable name="MonthName">
				<xsl:choose>
				  <xsl:when test="$month = '01'"><xsl:value-of select="'Jan'" /></xsl:when>
				  <xsl:when test="$month = '02'"><xsl:value-of select="'Feb'" /></xsl:when>
				  <xsl:when test="$month = '03'"><xsl:value-of select="'Mar'" /></xsl:when>
				  <xsl:when test="$month = '04'"><xsl:value-of select="'Apr'" /></xsl:when>
				  <xsl:when test="$month = '05'"><xsl:value-of select="'May'" /></xsl:when>
				  <xsl:when test="$month = '06'"><xsl:value-of select="'Jun'" /></xsl:when>
				  <xsl:when test="$month = '07'"><xsl:value-of select="'Jul'" /></xsl:when>
				  <xsl:when test="$month = '08'"><xsl:value-of select="'Aug'" /></xsl:when>
				  <xsl:when test="$month = '09'"><xsl:value-of select="'Sep'" /></xsl:when>
				  <xsl:when test="$month = '10'"><xsl:value-of select="'Oct'" /></xsl:when>
				  <xsl:when test="$month = '11'"><xsl:value-of select="'Nov'" /></xsl:when>
				  <xsl:when test="$month = '12'"><xsl:value-of select="'Dec'" /></xsl:when>
				  <xsl:otherwise><xsl:value-of select="'Invalid'" /></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			 <xsl:value-of select="concat($day, ' ',$MonthName, ' ', $year)" />
		</xsl:variable>
		<xsl:variable name="ExpiryDay">
			<xsl:value-of select="//data/policy/ExpirationDay"/>
		</xsl:variable>
		<xsl:variable name="Phonenumber">
			<xsl:choose>
			<xsl:when test="normalize-space(//data/account/CRSPhoneNumber) = ''">
            <xsl:choose>
             <xsl:when test="//data/account/Country = 'NZ'">
             <xsl:value-of select="'0800 555 303'"/>
             </xsl:when>
            <xsl:otherwise>
            <xsl:value-of select="'1800 007 022'"/>
            </xsl:otherwise>
           </xsl:choose>
           </xsl:when>
           <xsl:otherwise>
           <xsl:value-of select="//data/account/CRSPhoneNumber"/>
           </xsl:otherwise>
            </xsl:choose>
		</xsl:variable>
		<EmailTemplate>
			<![CDATA[
			<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Letter to Lender</title>
  <style>
    body {
      font-family: Verdana, sans-serif;
      font-size: 9pt;
      color: #000;
      margin: 20px;
    }
    h1 {
      font-size: 10pt;
      font-weight: bold;
    }
    .section {
      margin: 10px 0;
    }
    .protection-table {
      width: 400px;
      background-color: #a6a6a6;
      color: #fff;
      padding: 5px;
      margin: 15px 0;
	  font-size: 9pt;
      font-weight: bold;
    }
    .footer {
      border-top: 2px solid #78278b;
      padding-top: 10px;
      margin-top: 20px;
      font-size: 7pt;
      color: #8b8b8b;
    }
    .footer a {
      color: #3c1053;
      text-decoration: none;
    }
    .footer .right {
      float: right;
    }
    img.logo, img.banner {
      display: block;
      margin-bottom: 15px;
    }
  </style>
</head>
<body>
<a href="https://www.capricornrisk.com">
  <img src="data:image/png;base64,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" alt="Capricorn Mutual" class="logo" width="206" height="56"/></a><br/><br/>

  <div class="section">Dear Member,</div>

  <div class="section">
    <h1>NOTIFICATION ]]> <xsl:text>-</xsl:text> <![CDATA[ EXPIRY OF PERSONAL PROTECTION</h1>
  </div>

  <div class="section">
    As per your recent instruction, your protection from Capricorn Mutual will expire from ]]><xsl:copy-of select="$ExpiryDay"/><![CDATA[, ]]><xsl:copy-of select="$ExpiryDateWithoutTime"/><![CDATA[ and below is a summary.
  </div>
<table class="protection-table">
  <tr>
    <td>Member number:</td>
    <td>]]><xsl:copy-of select="$Membernumber"/><![CDATA[</td>
  </tr>
  <tr>
    <td>Protection number:</td>
    <td>]]><xsl:copy-of select="$QuoteNumber"/><![CDATA[</td>
  </tr>
  <tr>
    <td>Product type:</td>
    <td>]]><xsl:copy-of select="$ProductType"/><![CDATA[</td>
  </tr>
  <tr>
    <td>Expiry date:</td>
    <td>]]><xsl:copy-of select="$Expirydate"/><![CDATA[</td>
  </tr>
</table>
<div class="section">
    Please find attached a letter from Capricorn Mutual confirming that you will no longer be protected after the above expiry date.
  </div>

  <div class="section">
    <b>What should I do now?</b>
  </div>
  
  <div class="section">
    If you would like to discuss this further, consider alternate protection/coverage options or reinstate your protection you can call Capricorn Risk Services on ]]><xsl:copy-of select="$Phonenumber"/><![CDATA[, who will be happy to help.
  </div>

  <div class="section">
  ]]>
	<xsl:for-each select="//_Communications/messagesandemail/emails/emailmessages">
	<xsl:if test="Messages != ''">
		<xsl:value-of select="Messages"/>
	</xsl:if>
    </xsl:for-each>
  <![CDATA[
  </div>
  <div class="section">
    Capricorn Risk Services<br>
    <a href="https://www.capricornrisk.com">www.capricornrisk.com</a>
  </div>

  <img src="data:image/png;base64,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" alt="Capricorn Risk Services" class="banner" width="324" height="89"/>

  <div class="footer">
    Capricorn Risk Services Pty Ltd
    <span class="right">ABN 93 111 632 789</span><br/><br/>
    Discretionary protection products are provided by Capricorn Mutual Limited (CML).  Corporate Authorised Representative of CML (ABN 24 104 601 194) (AFS Licence No: 230 038) (CAR 460893). A copy of the Financial Services Guide, Product Disclosure Statement and our Target Market Determination for its protection is available at
    <a href="https://www.capricorn.coop/about/capricorn-mutual">www.capricorn.coop/about/capricorn-mutual</a>.
    <br/><br/>
    Australia Freecall: 1800 007 022<br>
    New Zealand Freecall: 0800 555 303
  </div>

</body>
</html>]]></EmailTemplate>
	</xsl:template>
</xsl:stylesheet>