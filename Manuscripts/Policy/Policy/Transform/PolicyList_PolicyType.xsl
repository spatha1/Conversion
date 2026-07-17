<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">

	<xsl:output method="xml" indent="yes" omit-xml-declaration="yes" />


    <!-- Global Date of Loss from Request.echoRs -->
    <xsl:variable name="dateOfLoss" select="normalize-space(//Request.echoRs)" />

	<xsl:template match="/">
		<xsl:apply-templates select="*"/>
	</xsl:template>

	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="*"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="transaction">
	
		
        <xsl:variable name="dol" select="number(translate($dateOfLoss, '-', ''))"/>
        
            <!-- Current transaction's effective date -->
            <xsl:variable name="thisEff" select="number(translate(EffectiveDate, '-', ''))"/>
        
            <!-- Check if another transaction is closer to dateOfLoss -->
            <xsl:variable name="hasLater"
                select="../transaction[
                            number(translate(EffectiveDate, '-', '')) &lt;= $dol
                            and number(translate(EffectiveDate, '-', '')) &gt; $thisEff
                       ]"/>
        
            
            <xsl:variable name="thisHist" select="number(HistoryID)"/>
			
            <xsl:variable name="hasHigherHist"
                select="../transaction[
                            number(translate(EffectiveDate, '-', '')) = $thisEff
                            and number(HistoryID) > $thisHist
                       ]"/>
            
         
		<!--change to show Cancel and OOS transactions and hide NonRenew below -->
		<xsl:if test="(($dateOfLoss = '') or ($thisEff &lt;= $dol and not($hasLater) and not($hasHigherHist)))
                          and ((descendant::DeprecatedBy = '' and descendant::Status != 'Pending' and descendant::Type != 'NonRenew') or (not(descendant::DeprecatedBy) and (descendant::Type != 'NonRenew')))">
			<policy>
				<xsl:attribute name="policyID">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/policy/@id"/>
				</xsl:attribute>
				<xsl:attribute name="policyNumber">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/policy/policyNumber"/>
				</xsl:attribute>
				<xsl:attribute name="LOB">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/policy/LOB"/>
				</xsl:attribute>
				<xsl:attribute name="policyType">
					<xsl:choose>
						<xsl:when test="contains(../../preceding-sibling::*[1]/details/policy/LOB, 'Personal')">P</xsl:when>
						<xsl:otherwise>C</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
				<xsl:attribute name="TypeCaption">
					<xsl:value-of select="descendant::TypeCaption"/>
				</xsl:attribute>
				<xsl:attribute name="clientID">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/client/@id"/>
				</xsl:attribute>
				<xsl:attribute name="clientName">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/client/name"/>
				</xsl:attribute>
				<xsl:attribute name="firstName">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/client/firstName"/>
				</xsl:attribute>
				<xsl:attribute name="partyName">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/client/partyName"/>
				</xsl:attribute>
				<xsl:attribute name="address1">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/mailingAddress/address1"/>
				</xsl:attribute>
				<xsl:attribute name="city">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/mailingAddress/city"/>
				</xsl:attribute>
				<xsl:attribute name="state">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/mailingAddress/state"/>
				</xsl:attribute>
				<xsl:attribute name="zip">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/mailingAddress/ZIP"/>
				</xsl:attribute>
				<xsl:attribute name="country">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/mailingAddress/countryCode"/>
				</xsl:attribute>
				<xsl:attribute name="status">
					<xsl:value-of select="descendant::PolicyStatus"/>
				</xsl:attribute>
				<xsl:attribute name="currentPremium">
					<xsl:value-of select="descendant::NewPremium"/>
				</xsl:attribute>
				<xsl:attribute name="effectiveDate">
					<xsl:value-of select="descendant::EffectiveDate"/>
				</xsl:attribute>
				<xsl:attribute name="expirationDate">
					<xsl:value-of select="descendant::ExpirationDate"/>
				</xsl:attribute>

				<xsl:attribute name="retroActiveDate">
					<xsl:value-of select="descendant::RetroActiveDate"/>
				</xsl:attribute>
				<xsl:attribute name="policyExtendedDate">
					<xsl:value-of select="descendant::ExtendedDate"/>
				</xsl:attribute>
				<xsl:attribute name="producer">
					<xsl:value-of select="../../preceding-sibling::*[1]/details/policy/producer"/>
				</xsl:attribute>
				<xsl:attribute name="transactionDate">
					<xsl:value-of select="descendant::TransactionDate"/>
				</xsl:attribute>
				<xsl:attribute name="creationDate">
					<xsl:value-of select="descendant::CreatedDate"/>
				</xsl:attribute>
				<xsl:attribute name="currencyCode">
					<xsl:value-of select="../../preceding-sibling::OnlineData.listRs/policyList/policy/@currencyCode"/>
				</xsl:attribute>
				<xsl:attribute name="linePolicyName">
					<xsl:choose>
						<xsl:when test="contains(../../preceding-sibling::*[1]/details/policy/LOB, 'CommercialAutoMA')">
							<xsl:value-of select="../../../descendant::*/line/exposure[Type='CoverageForm']/sValue"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="../../../descendant::*/line/exposure[Type='PolicyType']/sValue"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
                <xsl:attribute name="policyCoverageType">
                                  	<xsl:value-of select="../../../../descendant::data/policy/propertypolicy/PolicyCoverage"/>
                </xsl:attribute>


			</policy>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="responses">
		<OnlineData.listRs>
		<xsl:attribute name="dateOfLoss">
                    <xsl:value-of select="$dateOfLoss"/>
                </xsl:attribute>
			<policyList>
                    <xsl:apply-templates select="descendant::TransACT.listTransactionsRs/transactions/transaction"/>
             
		</policyList>
		</OnlineData.listRs>
	</xsl:template>	

	<xsl:template match="OnlineData.loadPolicyRs">
	</xsl:template>
	
	<xsl:template match="OnlineData.getDetailsRs">
	</xsl:template>	
	
	<xsl:template match="TransACT.listTransactionsRs">
	</xsl:template>
	
	<xsl:template match="Session.resumeRs">
	</xsl:template>	
	
</xsl:stylesheet>