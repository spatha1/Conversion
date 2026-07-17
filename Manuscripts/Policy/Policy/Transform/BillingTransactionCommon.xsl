<?xml version="1.0"?>
<!-- Used by Renew, Rewrite, and Reissue -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes"/>
	
	<xsl:template name="LookupTransactionTypeCode">
		<xsl:param name="code" />
		<xsl:param name="effectiveDate"/>
		<xsl:param name="termEffectiveDate"/>
		<xsl:param name="deprecatedBy" />
		<xsl:param name="onsetBy" />

		<xsl:variable name="packedEffectiveDate" select="number(translate($effectiveDate,'-',''))" />
		<xsl:variable name="packedTermEffectiveDate" select="number(translate($termEffectiveDate,'-',''))" />
		<xsl:variable name="IsConversion" select="//data/policy/IsConversionPolicy" />

		<xsl:choose>
		    <xsl:when test="$code = 'New' and $IsConversion='1'">RNEW</xsl:when>
			<xsl:when test="$code = 'New'">NBUS</xsl:when>
			<xsl:when test="$code = 'Endorse'">ENDT</xsl:when>
			<xsl:when test="$code = 'EndorseWorkComp'">ENDT</xsl:when>
			<xsl:when test="$code = 'Cancel'">
				<xsl:choose>
					<xsl:when test="string($packedEffectiveDate)=string($packedTermEffectiveDate)">FCAN</xsl:when>
					<xsl:otherwise>PCAN</xsl:otherwise>
				</xsl:choose>
			</xsl:when>

			<xsl:when test="$code = 'CancelPending'">PCN</xsl:when>
			<xsl:when test="$code = 'Renew'">RNEW</xsl:when>
			<xsl:when test="$code = 'Reinstate'">REIN</xsl:when>
			<xsl:when test="$code = 'Reissue'">REIS</xsl:when>
			<xsl:when test="$code = 'Rewrite'">RWRI</xsl:when>
			<xsl:when test="$code = 'Restart'">RSTR</xsl:when>
			<xsl:when test="$code = 'Information'">INFO</xsl:when>
			<xsl:when test="$code = 'BookPolicy'">INFO</xsl:when>
			<xsl:when test="$code = 'IssuePolicy'">INFO</xsl:when>
			<xsl:when test="$code = 'RescindNonRenew'">INFO</xsl:when>
			<xsl:when test="$code = 'NonRenew'">INFO</xsl:when>
			<xsl:when test="$code = 'RenewalChange'">INFO</xsl:when>
			<xsl:when test="$code = 'FinalAudit'">FAUD</xsl:when>
			<xsl:when test="$code = 'RevisedFinalAudit'">RAUD</xsl:when>
			<xsl:when test="$code = 'InterimAudit'">IAUD</xsl:when>
			<xsl:when test="$code = 'VoidFinalAudit'">VAUD</xsl:when>
			<xsl:when test="$code = 'Rescind'">RESC</xsl:when>
			<xsl:when test="$code = 'RescindCancelPending'">RESC</xsl:when>
			<xsl:when test="$code = 'PaidInFull' or $code = 'PIF'">PIF</xsl:when>
			<xsl:when test="$code = 'TermModification'">TMOD</xsl:when>
			<xsl:otherwise>OTHR</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>