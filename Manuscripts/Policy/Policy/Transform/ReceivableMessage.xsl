<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt">

	<xsl:import href="PolicyTermExtendedData.xsl"/>
	<xsl:import href="BillingTransactionCommon.xsl"/>
	<xsl:import href="BORFinancial_To_BillingPostPolicy.xsl"/>
	<xsl:output omit-xml-declaration="yes"/>
	
	<!-- Key that stores only the first item for each share commission plan(if any). This should help group the commission share plans by terms. Keep this key as is, changing it could break the grouping or not match any nodes. -->
  <xsl:key name="TermCounterParent" match="/*/_BillingWorkingDoc/TransactReport/report/entry/premiums/premium/CommissionPlans/CommissionPlan[@type='CSHP' and not(preceding-sibling::*/TermCounter = TermCounter)]" use="generate-id()"/>
  <!-- Key that stores the rest of items for each share commission plan(if any). This should help group the commission share plans by terms. Keep this key as is, changing it could break the grouping or not match any nodes. -->
  <xsl:key name="TermCounterSiblings" match="/*/_BillingWorkingDoc/TransactReport/report/entry/premiums/premium/CommissionPlans/CommissionPlan[@type='CSHP' and preceding-sibling::*/TermCounter=TermCounter]" use="generate-id(preceding-sibling::*[TermCounter=current()/TermCounter][last()])" />

	<xsl:template match="/*">
		<Billing.postPolicyRq>
			<PolicyData>
				<xsl:apply-templates select="session/data/policy"/>
				<CurrencyCulture>
					<xsl:choose>
							<!-- This section left for backward compatibility with Billing Base Product. It can be removed once we switche to the new sample product -->							<xsl:when test="session/properties/@currencyCode = 'AUD' ">en-AU</xsl:when>
							<xsl:when test="//session/data/policy/CultureCode = 'NZD' ">en-NZ</xsl:when>
							<xsl:when test="//session/data/policy/CultureCode = 'USD' ">en-US</xsl:when>
							<xsl:otherwise>
							<xsl:value-of select="//session/data/policy/CultureCode"/>
							</xsl:otherwise>
				</xsl:choose>

				</CurrencyCulture>
				<PolicyCurrencyCode>
					<xsl:value-of select="session/data/policy/Currency"/>
				</PolicyCurrencyCode>
				<BillItemExtendedData/>
			</PolicyData>
		</Billing.postPolicyRq>
	</xsl:template>

	<xsl:template match="policy">
		<xsl:variable name="activeTransactionId" select="(/*/_processingData/activeTransactionID)" />
		<AccountId>
			<xsl:value-of select="AccountId"/>
		</AccountId>
		<PolicyTermId>
			<xsl:value-of select="PolicyTermId"/>
		</PolicyTermId>
		<PolicyLineOfBusinessCode>
			<xsl:value-of select="LineOfBusinessCode"/>
		</PolicyLineOfBusinessCode>
		<PolicyProductCode>
			<xsl:value-of select="ProductCode"/>
		</PolicyProductCode>
		<MembershipFlag>
			<xsl:value-of select="MembershipFlag"/>
		</MembershipFlag>
		<PolicyIssueSystemCode>
			<xsl:value-of select="IssueSystem"/>
		</PolicyIssueSystemCode>
		<PolicyMasterCompanyCode>
			<xsl:value-of select="MasterCompany"/>
		</PolicyMasterCompanyCode>
		<PolicyReference>
			<xsl:value-of select="PolicyNumber"/>
		</PolicyReference>
		<PolicyStatus>
			<xsl:value-of select="Status"/>
		</PolicyStatus>
		<BillingStatus>
			<xsl:value-of select="../policy/BillingStatus"/>
		</BillingStatus>
		<InforceStatus>
			<xsl:value-of select="../policy/InforceStatus"/>
		</InforceStatus>
		<RenewStatus>
			<xsl:value-of select="../policy/RenewStatus"/>
		</RenewStatus>
		<TransactionReference>
			<xsl:value-of select="../policyAdmin/transactions/transaction[last()]/HistoryID"/>
		</TransactionReference>
		<ReasonTypeCode>
			<xsl:call-template name="LookupReasonTypeCode">
				<xsl:with-param name="code">
					<xsl:value-of select="//report/entry[@type = 'onset'][1]/transaction/reasons/reason[1]/Code"/>
				</xsl:with-param>
			</xsl:call-template>
		</ReasonTypeCode>
		<Auditable>
			<xsl:value-of select="Indicators[Type='IsAuditable']/bValue"/>
		</Auditable>
		<IssuedUserName>
			<xsl:value-of select="(/*/_processingData/transactions/transaction[@id=$activeTransactionId]/IssuedUserName)" />
		</IssuedUserName>
		<Producer>
			<xsl:value-of select="../userDetails/userName"/>
		</Producer>
		<xsl:variable name="V.TransactionEffDate" select="//report/entry[@type = 'onset'][1]/transaction/EffectiveDate"/>
		<TransactionEffectiveDate>
			<xsl:value-of select="$V.TransactionEffDate"/>
		</TransactionEffectiveDate>
		<xsl:call-template name="LookupPolicyTermTrans">
			<xsl:with-param name="EffectiveDate" select="$V.TransactionEffDate"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="LookupPolicyTermEffectiveDate">
		<xsl:param name="EffectiveDate"/>
		<xsl:param name="HistoryID" />
		
		<xsl:param name="ExpirationDate"/>
		<xsl:variable name ="termCreationTransactions" select="(/*/_processingData/transactions/transaction[Type = 'New' or Type = 'Renew' or Type = 'Reissue' or Type = 'Rewrite' or Type = 'Restart'])" />
		<xsl:variable name="packedEffectiveDate" select="number(translate($EffectiveDate,'-',''))" />
		<xsl:variable name="packedExpirationDate" select="number(translate($ExpirationDate,'-',''))" />
		<xsl:variable name="creationPolicyTermTransaction">
			<xsl:choose>
				<xsl:when test="//report/entry[@type = 'onset'][1]/@transactionType = 'FinalAudit' or //report/entry[@type = 'onset'][1]/@transactionType = 'RevisedFinalAudit' or //report/entry[@type = 'onset'][1]/@transactionType = 'VoidFinalAudit'">
					<xsl:copy-of select="msxsl:node-set($termCreationTransactions)[number(translate(EffectiveDate,'-','')) &lt;= $packedEffectiveDate][number(translate(ExpirationDate,'-','')) &gt;= $packedEffectiveDate][HistoryID &lt; number($HistoryID)]" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="msxsl:node-set($termCreationTransactions)[number(translate(EffectiveDate,'-','')) &lt;= $packedEffectiveDate][number(translate(ExpirationDate,'-','')) &gt; $packedEffectiveDate][HistoryID &lt; number($HistoryID)]" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:copy-of select="msxsl:node-set($creationPolicyTermTransaction)/transaction[number(translate(ExpirationDate,'-','')) &lt;= $packedExpirationDate ][last()]/EffectiveDate" />
	</xsl:template>	
	
	<xsl:template name="LookupPolicyTermTrans">
		<xsl:param name="EffectiveDate"/>
		<xsl:variable name ="termCreationTransactions" select="(/*/session/data/policyAdmin/transactions/transaction[Type = 'New' or Type = 'Renew' or Type = 'Reissue' or Type = 'Rewrite' or Type = 'Restart'])" />
		<xsl:variable name="packedEffectiveDate" select="number(translate($EffectiveDate,'-',''))" />		
		<xsl:variable name="transGroup" select="//report/entry[@type = 'onset'][1]/@transGroup" />
		<xsl:variable name="transType" select="//report/entry[@type = 'onset'][1]/@transactionType" />
		<xsl:variable name="creationPolicyTermTransaction">
			<xsl:choose>
				<xsl:when test="$transType = 'FinalAudit' or $transType = 'RevisedFinalAudit' or $transType = 'VoidFinalAudit' or $transType = 'Endorse' or $transType = 'Cancel' or $transType = 'Reinstate'">
					<xsl:copy-of select="msxsl:node-set($termCreationTransactions)[number(translate(EffectiveDate,'-','')) &lt;= $packedEffectiveDate][number(translate(ExpirationDate,'-','')) &gt;= $packedEffectiveDate]" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="msxsl:node-set($termCreationTransactions)[number(translate(EffectiveDate,'-','')) &lt;= $packedEffectiveDate][number(translate(ExpirationDate,'-','')) &gt; $packedEffectiveDate]" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<PolicyTermEffectiveDate>
			<xsl:value-of select="msxsl:node-set($creationPolicyTermTransaction)/transaction[last()]/EffectiveDate" />
		</PolicyTermEffectiveDate>
		<PolicyTermExpirationDate>
			<xsl:value-of select="msxsl:node-set($creationPolicyTermTransaction)/transaction[last()]/ExpirationDate" />
		</PolicyTermExpirationDate>
		<xsl:if test="$transType = 'Reinstate'">
			<PairedCancelDate>
				<xsl:value-of select="//report/entry[@type = 'onset'][1]/transaction/PairedCancelDate"/>
			</PairedCancelDate>
			<PairedCancelTransactionId>
				<xsl:value-of select="//report/entry[@type = 'onset'][1]/transaction/PairedCancelTransactionId"/>
			</PairedCancelTransactionId>
		</xsl:if>
		<xsl:if test="$transType = 'TermModification'">
			<NewPolicyTermExpirationDate>
				<xsl:value-of select="//report/entry[@type = 'onset'][1]/transaction/ExpirationDate" />
			</NewPolicyTermExpirationDate>
		</xsl:if>
		<TransactionTypeCode>
			<xsl:call-template name="LookupTransactionTypeCode">
				<xsl:with-param name="code">
					<xsl:value-of select="//report/entry[@type = 'onset'][1]/transaction/Type"/>
				</xsl:with-param>
				<xsl:with-param name="termEffectiveDate">
					<xsl:value-of select="msxsl:node-set($creationPolicyTermTransaction)/transaction[last()]/EffectiveDate"/>
				</xsl:with-param>
				<xsl:with-param name="effectiveDate">
					<xsl:value-of select="$EffectiveDate"/>
				</xsl:with-param>
			</xsl:call-template>
		</TransactionTypeCode>
		<xsl:call-template name="BuildItemList">
			<xsl:with-param name="termEffectiveDate">
				<xsl:value-of select="msxsl:node-set($creationPolicyTermTransaction)/transaction[last()]/EffectiveDate"/>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:call-template name="PolicyTermExtendedData"/>
	</xsl:template>

	<xsl:template name="BuildItemList">
		<xsl:param name="termEffectiveDate" />
		<AmountItems>
			<xsl:for-each select="/*/_BillingWorkingDoc/TransactReport/report/entry">				
				<xsl:variable name="bOrdered">
					<xsl:call-template name="ReverseOffsetRecordsOrder">
						<xsl:with-param name="bindex" select="@index"/>
						<xsl:with-param name="btype" select="@type"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:call-template name="BuildAmountItem">
					<xsl:with-param name="entryindex" select="$bOrdered"/>
					<xsl:with-param name="tranEffectiveDate" select="$termEffectiveDate"/>
					<xsl:with-param name="recordType" select="@type"/>
				</xsl:call-template>
			</xsl:for-each>
		</AmountItems>
	</xsl:template>

	<!--Created this template to print the account items offset record in reverse order and onset record in the same order in which is being sent from policy. - Starts -->
	<xsl:template name="BuildAmountItem">
		<xsl:param name="tranEffectiveDate"/>
		<xsl:param name="entryindex"/>
		<xsl:param name="recordType" />
		<xsl:for-each select="/*/_BillingWorkingDoc/TransactReport/report/entry[@type=$recordType][position()=$entryindex]/premiums/premium">
			<xsl:variable name="TransactionTypeCode">
				<xsl:call-template name="LookupTransactionTypeCode">
					<xsl:with-param name="code">
						<xsl:value-of select="../../transaction/Type" />
					</xsl:with-param>
					<xsl:with-param name="effectiveDate">
						<xsl:value-of select="../../transaction/EffectiveDate" />
					</xsl:with-param>
					<xsl:with-param name="termEffectiveDate">
						<xsl:value-of select="$tranEffectiveDate" />
					</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:if test="$TransactionTypeCode != 'INFO'">
				<xsl:call-template name="BuildItem">
					<xsl:with-param name="termEffectiveDate">
						<xsl:value-of select="$tranEffectiveDate"/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<!--Created this template to print the account items offset record in reverse order and onset record in the same order in which is being sent from policy. - Ends -->
	<!--Reverse Ordering of the offset records - Starts-->
	<xsl:template name="ReverseOffsetRecordsOrder">
		<xsl:param name="bindex"/>
		<xsl:param name="btype"/>
		<xsl:variable name="bOrder">
			<xsl:if test="$btype='onset'">
				<xsl:value-of select="count(..//entry[@index=$bindex]/preceding-sibling::entry[@type='onset'])+1"/>
			</xsl:if>
			<xsl:if test="$btype='offset'">
				<xsl:value-of select="count(..//entry[@index=$bindex and @type='offset']/following-sibling::entry[@type='offset'])+1"/>
			</xsl:if>
		</xsl:variable>
		<xsl:value-of select="$bOrder"/>
	</xsl:template>
	<!--Reverse Ordering of the offset records - Ends-->

	<xsl:template name="BuildItem">
		<xsl:variable name="transaction" select="../../transaction"/>
		<xsl:variable name="isMPR">
			<xsl:value-of select="/*/session/data/policy/MPRPolicy"/>
		</xsl:variable>
		<xsl:variable name="currentReceivableGroup" select="@ReceivableGroup" />
		<xsl:variable name="currentPremiumClass" select="@premiumClass" />

		<xsl:variable name="childsCharge">
			<xsl:choose>
				<xsl:when test="$isMPR = 1">
					<xsl:if test="$transaction/Type = 'FinalAudit'">
						<xsl:value-of select="sum(../premium[@ParentReceivableGroup = $currentReceivableGroup and @premiumClass = $currentPremiumClass]/@TotalPremium)" />
					</xsl:if>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="sum(../premium[@ParentReceivableGroup = $currentReceivableGroup and @premiumClass = $currentPremiumClass]/@term)" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="charge">
			<xsl:choose>
				<xsl:when test="$isMPR = 1">
					<xsl:choose>
						<xsl:when test="$transaction/Type = 'FinalAudit'">
							<xsl:value-of select="@TotalPremium - $childsCharge" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$transaction/Deposit"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@term - $childsCharge" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="childsCommissionAmount">
			<xsl:if test="@CommissionType = 'FLAT'">
				<xsl:value-of select="sum(../premium[@ParentReceivableGroup = $currentReceivableGroup and @premiumClass = $currentPremiumClass and @CommissionType = 'FLAT']/@CommissionValue)"/>
			</xsl:if>
		</xsl:variable>

		<xsl:variable name="policyTermEffectiveDate">
			<xsl:call-template name="LookupPolicyTermEffectiveDate">
				<xsl:with-param name="EffectiveDate" select="$transaction/EffectiveDate"/>
				<xsl:with-param name="HistoryID" select="$transaction/HistoryID" />
				<xsl:with-param name="ExpirationDate" select="$transaction/ExpirationDate"/>
			</xsl:call-template>
		</xsl:variable>

		<xsl:variable name="transGroup" select="$transaction/../../../report/entry[@type = 'onset'][1]/@transGroup" />

		<xsl:variable name="FavorCommissionSharePlan">
			<xsl:choose>
				<xsl:when test="count(CommissionPlans/CommissionPlan[@type='CSHP']) &gt; 0">
					<xsl:text><![CDATA[1]]></xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text><![CDATA[0]]></xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<xsl:variable name="FavorCommissionPlan">
			<xsl:choose>
				<xsl:when test="$FavorCommissionSharePlan = '0' and (boolean(@CommissionPlanId) or count(CommissionPlans/CommissionPlan[@type='COMM']) &gt; 0)">
					<xsl:text><![CDATA[1]]></xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text><![CDATA[0]]></xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<AmountItem>
			<xsl:if test="$transaction/@id = $transGroup or $transaction/OriginalID = $transGroup">
				<CurrentTermTrans>1</CurrentTermTrans>
			</xsl:if>
			<id>
				<xsl:value-of select="$transaction/@id"/>
			</id>
			<TransactionTypeCode>
				<xsl:call-template name="LookupTransactionTypeCode">
					<xsl:with-param name="code">
						<xsl:value-of select="$transaction/Type"/>
					</xsl:with-param>
					<xsl:with-param name="termEffectiveDate">
						<xsl:value-of select="$policyTermEffectiveDate"/>
					</xsl:with-param>
					<xsl:with-param name="effectiveDate">
						<xsl:value-of select="$transaction/EffectiveDate"/>
					</xsl:with-param>
					<xsl:with-param name="deprecatedBy">
						<xsl:value-of select="$transaction/DeprecatedBy"/>
					</xsl:with-param>
					<xsl:with-param name="onsetBy">
						<xsl:value-of select="$transaction/OnsetBy"/>
					</xsl:with-param>
				</xsl:call-template>
			</TransactionTypeCode>
			<ReasonTypeCode>
				<xsl:call-template name="LookupReasonTypeCode">
					<xsl:with-param name="code">
						<xsl:value-of select="$transaction/reasons/reason[last()]/Code"/>
					</xsl:with-param>
				</xsl:call-template>
			</ReasonTypeCode>
			<ReasonCode>
				<xsl:value-of select="$transaction/reasons/reason[last()]/Code"/>
			</ReasonCode>
			<ItemEffectiveDate>
				<xsl:value-of select="$transaction/EffectiveDate"/>
			</ItemEffectiveDate>
			<ItemExpirationDate>
				<xsl:value-of select="$transaction/ExpirationDate"/>
			</ItemExpirationDate>
			<CoverageReference>
				<xsl:choose>
					<xsl:when test="@Line != ''">
						<xsl:value-of select="@Line"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="@ReceivableGroup"/>
					</xsl:otherwise>
				</xsl:choose>
			</CoverageReference>
			<ReceivableTypeCode>
				<xsl:call-template name="LookupReceivableTypeCode">
					<xsl:with-param name="code">
						<xsl:value-of select="@premiumClass"/>
					</xsl:with-param>
					<xsl:with-param name="effectiveDate">
						<xsl:value-of select="$transaction/EffectiveDate"/>
					</xsl:with-param>
					<xsl:with-param name="termEffectiveDate">
						<xsl:value-of select="$policyTermEffectiveDate"/>
					</xsl:with-param>
				</xsl:call-template>
			</ReceivableTypeCode>
			<ReceivableSubTypeCode>
				<xsl:choose>
					<xsl:when test="$isMPR = 1 and $transaction/Type != 'FinalAudit'">DPST</xsl:when>
					<xsl:otherwise/>
				</xsl:choose>
			</ReceivableSubTypeCode>
			<ItemAmount>
				<xsl:choose>
					<xsl:when test="$transaction/../@type = 'offset'">
						<xsl:value-of select="round($charge * 100) div 100.0 * -1"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="round($charge * 100) div 100.0"/>
					</xsl:otherwise>
				</xsl:choose>
			</ItemAmount>
			<CurrencyCode>
				<xsl:value-of select="/*/session/data/policy/Currency"/>								
			</CurrencyCode>
			<AggregationReference/>
			<CommissionGroupReference/>
			<ItemCommissionAmount>
				<xsl:if test="@CommissionType = 'FLAT'">
					<xsl:value-of select="round((@CommissionValue - $childsCommissionAmount) * 100) div 100"/>
				</xsl:if>
			</ItemCommissionAmount>
			<ItemCommissionPercent>
				<xsl:if test="@CommissionType = 'PCT'">
					<xsl:value-of select="@CommissionValue div 100"/>
				</xsl:if>
			</ItemCommissionPercent>
			<xsl:choose>
				<xsl:when test="$FavorCommissionSharePlan = '0' and not($FavorCommissionPlan = '0')">
					<xsl:element name="ItemCommissionPlanId">
						<xsl:choose>
							<xsl:when test="count(CommissionPlans/CommissionPlan[@type='COMM']) &gt; 0">
								<xsl:value-of select="CommissionPlans/CommissionPlan[@type='COMM']/CommissionPlanId" />
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="@CommissionPlanId" />
							</xsl:otherwise>
						</xsl:choose>
					</xsl:element>
				</xsl:when>
				<xsl:otherwise>
					<xsl:element name="ItemCommissionPlanId" />
				</xsl:otherwise>
			</xsl:choose>
			<ItemCommissionType>
				<xsl:value-of select="@CommissionType"/>
			</ItemCommissionType>
			<UnitReference/>
			<CallingProcess>UPTM</CallingProcess>
			<xsl:choose>
				<xsl:when test="not($FavorCommissionSharePlan = '0')">
					<xsl:element name="ItemCommissionSharePlans">
             <xsl:apply-templates select ="CommissionPlans/CommissionPlan[@type='CSHP']" mode="GroupingMode"/> 
					</xsl:element>
				</xsl:when>
				<xsl:otherwise>
					<xsl:element name="ItemCommissionSharePlans" />
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="not($FavorCommissionPlan = '0') or not($FavorCommissionSharePlan = '0')">
				<xsl:element name="PlanKeys">
					<xsl:element name="UserKeys">
						<xsl:copy-of select="CommissionPlans/Keys/LineOfBusinessCode" />
						<xsl:copy-of select="CommissionPlans/Keys/MasterCompanyCode" />
						<xsl:copy-of select="CommissionPlans/Keys/PlanActivationDate" />
						<xsl:copy-of select="CommissionPlans/Keys/PlanExpirationDate" />
						<xsl:copy-of select="CommissionPlans/Keys/PolicyInceptionDate" />
						<xsl:copy-of select="CommissionPlans/Keys/ProductCode" />
						<xsl:copy-of select="CommissionPlans/Keys/StateCode" />
						<xsl:copy-of select="CommissionPlans/Keys/UserKey1" />
						<xsl:copy-of select="CommissionPlans/Keys/UserKey2" />
						<xsl:copy-of select="CommissionPlans/Keys/UserKey3" />
						<xsl:copy-of select="CommissionPlans/Keys/UserKey4" />
						<xsl:copy-of select="CommissionPlans/Keys/UserKey5" />
					</xsl:element>
				</xsl:element>
			</xsl:if>
		</AmountItem>
	</xsl:template>


  <!-- Only the items under the termCounterParent key agrupation are processed. Only, if the initiating term is found, the rest of siblings are processed (TermCounterSiblings) -->
  <xsl:template match="CommissionPlan[key('TermCounterParent',generate-id())]" mode="GroupingMode">
    <xsl:element name="CommissionSharedMapping">
    <xsl:for-each select=".|key('TermCounterSiblings', generate-id())">
					<xsl:apply-templates select="." mode="CommissionSharePlan"/>
			</xsl:for-each> 
    </xsl:element> 
  </xsl:template>
  
  <!-- Template used to avoid the processing of not initiating term items -->
  <xsl:template match="CommissionPlan[not(key('TermCounterParent',generate-id()))]" mode="GroupingMode">
      <xsl:call-template name='no-data'/>
  </xsl:template>
  <xsl:template name='no-data'>
      <!-- Empty template -->  
  </xsl:template>      

	<xsl:template match="CommissionPlan" mode="CommissionSharePlan">
		<xsl:element name="CommissionSharedPlanDistribution">
			<xsl:element name="CommissionSharePlanId">
				<xsl:value-of select="CommissionSharePlanId" />
			</xsl:element>
			<xsl:element name="PlanAssignmentId">
				<xsl:value-of select="PlanAssignmentId" />
			</xsl:element>
			<xsl:element name="DestinationAgentId">
				<xsl:value-of select="DestinationAgentId" />
			</xsl:element>
			<xsl:element name="DestinationAgentCommissionPlanId">
				<xsl:value-of select="CommissionPlanId" />
			</xsl:element>
			<xsl:element name="PercentageAsEntered">
				<xsl:value-of select="PercentageAsEntered" />
			</xsl:element>
			<xsl:element name="CommissionIndicator">
				<xsl:value-of select="CommissionIndicator" />
			</xsl:element>
			<xsl:element name="TermCounter">
				<xsl:value-of select="TermCounter" />
			</xsl:element>
		</xsl:element>
	</xsl:template>

	<xsl:template name="LookupReasonTypeCode">
		<xsl:param name="code"/>
		<xsl:choose>
			<xsl:when test="$code = 'nonPay'">NPAY</xsl:when>
			<xsl:when test="$code = 'Other'">OTHR</xsl:when>
			<xsl:when test="$code = 'PaymentReceived'">PAID</xsl:when>
			<xsl:when test="$code = ''"/>
			<xsl:otherwise>UKWN</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="LookupReceivableTypeCode">
		<xsl:param name="code"/>
		<xsl:choose>
			<xsl:when test="$code = 'BillingInterfacePremium'">PREM</xsl:when>
			<xsl:when test="$code = 'BillingInterfaceTax'">TAX</xsl:when>
			<xsl:when test="$code = 'BillingInterfaceFee'">FEE</xsl:when>
			<xsl:when test="$code = 'BillingInterfaceGST'">GST</xsl:when>
			<xsl:when test="$code = 'BillingInterfaceSD'">SD</xsl:when>
			<xsl:when test="$code = 'BillingInterfaceFSL'">FSL</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>

</xsl:stylesheet>

