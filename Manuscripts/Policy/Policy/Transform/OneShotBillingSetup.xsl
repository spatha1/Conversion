<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:import href="BillingTransactionCommon.xsl"/>
	<xsl:output omit-xml-declaration="yes"/>
	<xsl:template match="/">
		<xsl:apply-templates/>
	</xsl:template>
	<!-- suppress default with this template -->
	<xsl:template match="text()"/>
	<xsl:template match="Session.getAllDocumentsRs/_BillingInputDoc/BillingKeys | root/_BillingInputDoc/BillingKeys">
		<!-- The template match sets the correct context node. If the oneshot is called locally, the root will be <root>
	     If the oneshot is called remotely the root will be <Session.getAllDocumentsRs> -->
		<xsl:variable name="activeTransactionId" select="(/*/_processingData/activeTransactionID)"/>
		<xsl:variable name="activeTransactionTypeCode" select="(/*/_processingData/transactions/transaction[@id=$activeTransactionId]/Type)"/>
		<xsl:variable name="IssuedUserName" select="(/*/_processingData/transactions/transaction[@id=$activeTransactionId]/IssuedUserName)"/>
		<xsl:variable name="transactionTypeCode">
			<xsl:call-template name="LookupTransactionTypeCode">
				<xsl:with-param name="code">
					<xsl:value-of select="$activeTransactionTypeCode"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<OneShotBillingSetUp status="success">
			<!--this attribute is here to give the manuscript something to look for to check for success. DO NOT REMOVE IT -->
			<xsl:call-template name="AccountSetup">
				<xsl:with-param name="IssuedUserName" select="$IssuedUserName"/>
			</xsl:call-template>
			<xsl:call-template name="PolicyTermSetup">
				<xsl:with-param name="transactionTypeCode" select="$transactionTypeCode"/>
				<xsl:with-param name="IssuedUserName" select="$IssuedUserName"/>
			</xsl:call-template>
			<xsl:call-template name="DownPayment"/>
		</OneShotBillingSetUp>
	</xsl:template>
	<xsl:template name="AccountSetup">
		<xsl:param name="IssuedUserName"/>
		<xsl:choose>
			<xsl:when test="normalize-space(AttachToAccountId) != ''">
				<!--Accountid or Account Reference -->
				<PartySetup>
					<LookupAgent name="AgentParty">
						<AgencyId>
							<xsl:value-of select="AgencyId"/>
						</AgencyId>
					</LookupAgent>
					<LookupRole name="InsuredParty">
						<RoleInPolicy>I</RoleInPolicy>
					</LookupRole>
				</PartySetup>
				<AccountSetup>
					<Use>
						<xsl:attribute name="AccountId">
							<xsl:value-of select="AttachToAccountId"/>
						</xsl:attribute>
					</Use>
				</AccountSetup>
			</xsl:when>
			<xsl:when test="normalize-space(AttachToAccountReference) != ''">
				<PartySetup>
					<LookupAgent name="AgentParty">
						<AgencyId>
							<xsl:value-of select="AgencyId"/>
						</AgencyId>
					</LookupAgent>
					<LookupRole name="InsuredParty">
						<RoleInPolicy>I</RoleInPolicy>
					</LookupRole>
				</PartySetup>
				<AccountSetup>
					<Lookup>
						<AccountReference>
							<xsl:value-of select="AttachToAccountReference"/>
						</AccountReference>
					</Lookup>
				</AccountSetup>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="NewAccountSetup">
					<xsl:with-param name="IssuedUserName" select="$IssuedUserName"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name="NewAccountSetup">
		<xsl:param name="IssuedUserName"/>
		<PartySetup>
			<LookupAgent name="AgentParty">
				<AgencyId>
					<xsl:value-of select="AgencyId"/>
				</AgencyId>
			</LookupAgent>
			<LookupRole name="InsuredParty">
				<RoleInPolicy>I</RoleInPolicy>
			</LookupRole>
			<Use name="PayorParty" party="InsuredParty"/>
			<Use name="PayeeParty" party="InsuredParty"/>
		</PartySetup>
		<AccountSetup>
			<Add>
				<LookupConfig>
					<AccountPlanCode>
						<xsl:value-of select="AccountPlanCode"/>
					</AccountPlanCode>
					<!-- BillClass is included here for backward compatibility. New Plan manuscripts will use Account Plan Code. -->
					<BillClass>
						<xsl:value-of select="BillClass"/>
					</BillClass>
					<BillType>
						<xsl:value-of select="BillType"/>
					</BillType>
					<CollectionMethod>
						<xsl:value-of select="CollectionMethod"/>
					</CollectionMethod>
					<!-- Target due day logic is typically in the account plan manuscript and would be based on the policy effective date 
						 The value can be overridden here if necessary -->
					<TargetDueDays>
						<xsl:choose>
							<xsl:when test="normalize-space(TargetDueDay) = ''"/>
							<xsl:otherwise>
								<xsl:value-of select="TargetDueDay"/>
							</xsl:otherwise>
						</xsl:choose>
					</TargetDueDays>
					<ElectronicInvoice>
						<xsl:value-of select="ElectronicInvoice"/>
					</ElectronicInvoice>
				</LookupConfig>
				<AccountRecord>
					<ReportingGroupCode>
						<xsl:value-of select="AccountProcessingOrgUnitCode"/>
					</ReportingGroupCode>
					<xsl:choose>
						<!-- This section left for backward compatibility with Billing Base Product. It can be removed once we switche to the new sample product -->
						<xsl:when test="EFTAccountNumber != ''">
							<EFTPaymentDetails>
								<BankAccountNumber>
									<xsl:value-of select="EFTAccountNumber"/>
								</BankAccountNumber>
								<AccountType>
									<xsl:value-of select="EFTAccountType"/>
								</AccountType>
								<LastName>
									<xsl:value-of select="EFTAccountLastName"/>
								</LastName>
								<FirstName>
									<xsl:value-of select="EFTAccountFirstName"/>
								</FirstName>
								<BankRoutingNumber>
									<xsl:value-of select="EFTRoutingNumber"/>
								</BankRoutingNumber>
								<BankName>
									<xsl:value-of select="EFTBankName"/>
								</BankName>
								<Activated>
									<xsl:choose>
										<xsl:when test="EFTActivated != ''">
											<xsl:value-of select="EFTActivated"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:text>0</xsl:text>
										</xsl:otherwise>
									</xsl:choose>
								</Activated>
							</EFTPaymentDetails>
						</xsl:when>
						<!-- This section populates the Auto Pay Bank details. EFT Payment Details would be populated if the collection method is Auto Pay Bank -->
						<xsl:when test="CollectionMethod = 'EFT'">
							<EFTPaymentDetails>
								<xsl:attribute name="id">
									<xsl:value-of select="@id"/>
								</xsl:attribute>
								<AccountName>
									<xsl:value-of select="EFTPaymentDetails/AccountName"/>
								</AccountName>
								<Activated>
									<xsl:value-of select="EFTPaymentDetails/Activated"/>
								</Activated>
								<LastName>
									<xsl:value-of select="EFTPaymentDetails/LastName"/>
								</LastName>
								<BankRoutingNumber>
									<xsl:value-of select="EFTPaymentDetails/BankRoutingNumber"/>
								</BankRoutingNumber>
								<BankAccountNumber>
									<xsl:value-of select="EFTPaymentDetails/BankAccountNumber"/>
								</BankAccountNumber>
								<AccountType>
									<xsl:value-of select="EFTPaymentDetails/AccountType"/>
								</AccountType>
								<BankName>
									<xsl:value-of select="EFTPaymentDetails/BankName"/>
								</BankName>
								<EFTTransactionDetails/>
							</EFTPaymentDetails>
						</xsl:when>
						<!-- This section left for Auto Pay Card. EFT Payment Details would be populated if the collection method is Auto Pay Card -->
						<xsl:when test="CollectionMethod = 'EFTC'">
							<EFTPaymentDetails>
								<CardPaymentDetails>
									<!--<xsl:attribute name="id">
										<xsl:value-of select="@id"/>
									</xsl:attribute>-->
									<!--<xsl:copy-of select="EFTPaymentDetails/CardPaymentDetails/Token"></xsl:copy-of>-->
									<Token>
										<ProfileID>
											<xsl:value-of select="EFTPaymentDetails/CardPaymentDetails/Token/ProfileID"/>
										</ProfileID>
										<PaymentProfileID>
											<xsl:value-of select="EFTPaymentDetails/CardPaymentDetails/Token/PaymentProfileID"/>
										</PaymentProfileID>
									</Token>
									<CardNumber>
										<xsl:value-of select="EFTPaymentDetails/CardPaymentDetails/CardNumberFormatted"/>
									</CardNumber>
									<ExpirationDate>
										<xsl:value-of select="EFTPaymentDetails/CardPaymentDetails/ExpirationDate"/>
									</ExpirationDate>
									<CardType>
										<xsl:value-of select="EFTPaymentDetails/CardPaymentDetails/CardType"/>
									</CardType>
									<CardTypeDescription>
										<xsl:value-of select="EFTPaymentDetails/CardPaymentDetails/CardTypeDescription"/>
									</CardTypeDescription>
									<PaymentMethod>
										<xsl:value-of select="EFTPaymentDetails/CardPaymentDetails/PaymentMethod"/>
									</PaymentMethod>
								</CardPaymentDetails>
							</EFTPaymentDetails>
						</xsl:when>
						<!-- This section left for Paper. EFT Payment Details should be NULL -->
						<xsl:when test="CollectionMethod = 'PA'"/>
						<!-- This is the replacement for the section above -->
						<xsl:otherwise>
							<xsl:copy-of select="EFTPaymentDetails"/>
						</xsl:otherwise>
					</xsl:choose>
					<ReportingGroupCode>
						<xsl:value-of select="ReportingGroupCode"/>
					</ReportingGroupCode>
					<AccountStateCode>
						<xsl:value-of select="PolicyStateCode"/>
					</AccountStateCode>
					<AccountReference>
						<xsl:choose>
							<xsl:when test="normalize-space(CustomAccountReference) != ''">
								<xsl:value-of select="CustomAccountReference"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="PolicyNumber"/>
							</xsl:otherwise>
						</xsl:choose>
					</AccountReference>
					<AccountStatusCode>ACV</AccountStatusCode>
					<AccountTypeCode>
						<xsl:value-of select="BillType"/>
					</AccountTypeCode>
					<CurrencyCulture>
						<xsl:choose>
							<!-- This section left for backward compatibility with Billing Base Product. It can be removed once we switche to the new sample product -->
							<xsl:when test="normalize-space(//session/data/policy/CultureCode) != ''">
								<xsl:value-of select="//session/data/policy/CultureCode"/>
							</xsl:when>
							<xsl:otherwise>en-AU</xsl:otherwise>
						</xsl:choose>
					</CurrencyCulture>
					<CurrencyCode>
						<xsl:choose>
							<!--<xsl:when test="normalize-space(AccountCurrencyCode) != ''">
								<xsl:value-of select="AccountCurrencyCode"/>
							</xsl:when>-->
							<xsl:when test="normalize-space(//session/data/policy/Currency) != ''">
								<xsl:value-of select="//session/data/policy/Currency"/>
							</xsl:when>
							<xsl:otherwise>USD</xsl:otherwise>
						</xsl:choose>
					</CurrencyCode>
					<PolicyCurrencyCode>
							<xsl:value-of select="//session/data/policy/Currency"/>
					</PolicyCurrencyCode>
					<AccountClassCode>
						<xsl:value-of select="BillClass"/>
					</AccountClassCode>
					<HoldTypeCode>
						<xsl:value-of select="HoldTypeCode"/>
					</HoldTypeCode>
					<HoldReasonCode>
						<xsl:value-of select="HoldReasonCode"/>
					</HoldReasonCode>
					<HoldStartDate>
						<xsl:value-of select="HoldStartDate"/>
					</HoldStartDate>
					<IssuedUserName>
						<xsl:value-of select="$IssuedUserName"/>
					</IssuedUserName>
					<Producer>
						<xsl:value-of select="//userDetails/userName"/>
					</Producer>
				</AccountRecord>
			</Add>
		</AccountSetup>
	</xsl:template>
	<xsl:template name="PolicyTermSetup">
		<xsl:param name="transactionTypeCode"/>
		<xsl:param name="IssuedUserName"/>
		<PolicyTermSetup>
			<LookupConfig>
				<PolicyPlanCode>
					<xsl:value-of select="PolicyPlanCode"/>
				</PolicyPlanCode>
				<!-- BillClass is included here for backward compatibility. New Plan manuscripts will use Policy Plan Code. -->
				<BillClass>
					<xsl:value-of select="BillClass"/>
				</BillClass>
				<PolicyLOB>
					<xsl:value-of select="PolicyLOB"/>
				</PolicyLOB>
				<PolicyLOBCode>
					<xsl:value-of select="PolicyLOBCode"/>
				</PolicyLOBCode>
				<PolicyTermEffectiveDate>
					<xsl:value-of select="PolicyTermEffectiveDate"/>
				</PolicyTermEffectiveDate>
				<UseMPR>
					<xsl:value-of select="UseMPR"/>
				</UseMPR>
			</LookupConfig>
			<PolicyTermRecord>
				<PolicyTermEffectiveDate>
					<xsl:value-of select="PolicyTermEffectiveDate"/>
				</PolicyTermEffectiveDate>
				<PolicyTermExpirationDate>
					<xsl:value-of select="PolicyTermExpirationDate"/>
				</PolicyTermExpirationDate>
				<PolicyReference>
					<xsl:value-of select="PolicyNumber"/>
				</PolicyReference>
				<SplitBillIndicator>N</SplitBillIndicator>
				<PolicyTermStatusCode>ACV</PolicyTermStatusCode>
				<PolicyIssueSystemCode>
					<xsl:value-of select="PolicyIssueSystemCode"/>
				</PolicyIssueSystemCode>
				<PolicyMasterCompanyCode>
					<xsl:value-of select="PolicyMasterCompanyCode"/>
				</PolicyMasterCompanyCode>
				<PolicyLineOfBusinessCode>
					<xsl:value-of select="PolicyLOBCode"/>
				</PolicyLineOfBusinessCode>
				<PolicyProductCode>
					<xsl:value-of select="PolicyProductCode"/>
				</PolicyProductCode>
				<PolicyStateCode>
					<xsl:value-of select="PolicyStateCode"/>
				</PolicyStateCode>
				<ProcessingOrgUnitCode>
					<xsl:value-of select="PolicyProcessingOrgUnitCode"/>
				</ProcessingOrgUnitCode>
				<TransactionTypeCode>
					<xsl:value-of select="$transactionTypeCode"/>
				</TransactionTypeCode>
				<IssuedUserName>
					<xsl:value-of select="$IssuedUserName"/>
				</IssuedUserName>
				<Producer>
					<xsl:value-of select="//userDetails/userName"/>
				</Producer>
				<CurrencyCode>
					<xsl:value-of select="//session/data/policy/Currency"/>
				</CurrencyCode>
			</PolicyTermRecord>
		</PolicyTermSetup>
	</xsl:template>
	<xsl:template name="DownPayment">
		<xsl:choose>
			<xsl:when test="normalize-space(//BillingDownPayment/Amount) != '' and normalize-space(//BillingDownPayment/Amount) != '0'">
				<PaymentSetup>
					<PaymentInformationRecord>
						<PaymentType>
							<xsl:value-of select="//BillingDownPayment/PaymentType"/>
						</PaymentType>
						<ApplyToOption>otherAmount</ApplyToOption>
					</PaymentInformationRecord>
					<PaymentRecord>
						<EntryDate>
							<xsl:value-of select="//BillingDownPayment/EntryDate"/>
						</EntryDate>
						<Amount>
							<xsl:value-of select="//BillingDownPayment/Amount"/>
						</Amount>
						<CurrencyCulture>
							<xsl:value-of select="//BillingDownPayment/CurrencyCulture"/>
						</CurrencyCulture>
						<CurrencyCode>
							<xsl:choose>
								<xsl:when test="normalize-space(//BillingDownPayment/CurrencyCode) != ''">
									<xsl:value-of select="//BillingDownPayment/CurrencyCode"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="//session/properties/@currencyCode"/>
								</xsl:otherwise>
							</xsl:choose>
						</CurrencyCode>
						<PaymentMethodCode>
							<xsl:value-of select="//BillingDownPayment/PaymentMethodCode"/>
						</PaymentMethodCode>
						<PostMarkDate/>
						<ReportingGroupCode>1</ReportingGroupCode>
						<EntryUserId>
							<xsl:value-of select="//BillingDownPayment/EntryUserId"/>
						</EntryUserId>
						<Description/>
						<xsl:copy-of select="//BillingDownPayment/PaymentMethodDetail"/>
					</PaymentRecord>
				</PaymentSetup>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>