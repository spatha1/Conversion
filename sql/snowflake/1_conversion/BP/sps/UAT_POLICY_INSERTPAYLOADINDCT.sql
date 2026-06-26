CREATE OR REPLACE PROCEDURE "POLICY_INSERTPAYLOADINDCT"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '

BEGIN 

insert into AGGNE.UAT.POLICY_MIGRATION_DCT_PREVDATA
select  *,getdate() from AGGNE.UAT.POLICY_MIGRATION_DCT ;
truncate table  AGGNE.UAT.POLICY_MIGRATION_DCT;

     INSERT INTO AGGNE.UAT.POLICY_MIGRATION_DCT (CML_NUMBER,BUCKET,LEGACYPOLICYNUMBER,REQUEST_XML)
        SELECT DISTINCT CMLNUMBER, ROW_NUMBER()Over(order by LEGACYPOLICYNUMBER), LEGACYPOLICYNUMBER, parse_xml(
      REGEXP_REPLACE(   REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(''<server>
	<requests>
		<Session.loginRq userName="ConversionUser5" password="Pass@123"/>
		<Session.setPropertyRq name="ProductManuscriptId" value="{MANUSCRIPT}"/>
		<Session.setPropertyRq name="WorkflowManuscriptId" value="Carrier_Package_Workflow_1_0_0_0"/>
		<Request.setVarRq name="ImportManuscriptId" value="Carrier_Import_BusinessProtection_1_0_0_0"/>
		<Session.setPropertyRq name="InputClientID" value="{PARTYID}"/>
		<Session.setPropertyRq name="Producer" value="{HANDLERMAIL}"/>
		<ManuScript.getValueRq manuscript="~ImportManuscriptId~" field="PolicyImportPrivate.ImportProcess1"/>
		<Session.setDocumentRq document="_Payload" addIDs="1">
			<_Payload>
				<session>
					<data>
						<account>
							<PartyType>O</PartyType>
							<ABNNumber>{ABN_NZBN}</ABNNumber>
							<Name>{CMLLEGALENTITY}</Name>
							<Country>{COUNTRY}</Country>
							<PhoneCountryCode>{SITE_COUNTRY}</PhoneCountryCode>
							<address>
								<City>{SITE_SUBURB}</City>
								<ZipCode>{SITE_POSTCODE}</ZipCode>
								<State>{SITE_STATE}</State>
								<Address1>{SITE_STREET}</Address1>
								<Address2/>
								<Country>{SITE_COUNTRY}</Country>
							</address>
							<Language>EN</Language>
							<PhoneTypeCode>{PRIMARY_PHONE_TYPE}</PhoneTypeCode>
							<PrimaryPhone>{PRIMARY_PHONE}</PrimaryPhone>
							<MobilePhone>{PRIMARY_PHONE}</MobilePhone>							
                            <AccountHandler fullName="{HANDLERFULLNAME}" >{HANDLERMAIL}</AccountHandler>
							<RAMRegion>{CSL_REGION}</RAMRegion>
							<RAMName></RAMName>
							<CMLNumber>{CMLNUMBER}</CMLNumber>
							<CSLNumber>{CSLNUMBER}</CSLNumber>
							<CSLLegalEntityName>{CSL_LEGAL_ENTITY}</CSLLegalEntityName>
							<CMLLegalEntityName>{CMLLEGALENTITY}</CMLLegalEntityName>
							<AccountType>CSL</AccountType>
							<CMLRiskAccountManager>{CML_RISK_ACCOUNT_MANAGER}</CMLRiskAccountManager>
							<CSLContactName>{MAINCONTACT}</CSLContactName>
							<CSLEmail>{EMAIL}</CSLEmail>
							<CSLPhone>{PHONE}</CSLPhone>
							<CSLAccountManager>{CSL_AREA_MANAGER}</CSLAccountManager>
							<CSLRegion>{CSL_REGION}</CSLRegion>
							<CSLRiskAccountManager>{CSL_AREA_MANAGER}</CSLRiskAccountManager>
							<CSLZone>{CSL_ZONE}</CSLZone>
							<CSLPostcode>{POSTCODE}</CSLPostcode>
							<CSLState>{STATE}</CSLState>
							<CSLStreet>{STREET}</CSLStreet>
							<CSLSuburb>{SUBURB}</CSLSuburb>
							<CSLStartDate/>
							<StandardIndustryCode>{STANDARD_INDUSTRY_CODE}</StandardIndustryCode>
							<CSLTradingName/>
							<CSLMonthlySpend/>
							<CSLCreditUsage/>
							<CSLCreditLimit>{CSL_CREDIT_LIMIT}</CSLCreditLimit>
							<CSLPaymentDefault>0</CSLPaymentDefault>
							<CSLPaymentMethod>CASH</CSLPaymentMethod>
							<CSLCreditRisk/>
							<CSLMemberStatus>{CSL_MEMBER_STATUS}</CSLMemberStatus>
							<ProbabilityOfDefault>{PROBABILITY_OF_DEFAULT}</ProbabilityOfDefault>
							<StandardCodeDescription>{STANDARD_INDUSTRY_CODE_DESCRIPTION}</StandardCodeDescription>
							<StopCredits>{STOP_CREDIT}</StopCredits>
							<StopCreditsReason/>
							<CSLTenure/>
							<DateOfBirth/>
		{ACC_LOC}
		<Latitude/>
							<Longitude/>
							<dutyofdisclosure>
								<CriminalConviction>{QU3CRIMINALCONVICTION}</CriminalConviction>
								<RefusedInsurance>{QU3INSURANCEREFUSEDCANCELLED}</RefusedInsurance>
								<CriminalConvictionDetails>{CRIMINALCONVICTIONDETAILS}</CriminalConvictionDetails>
								<RefusedInsuranceDetails>{REFUSEDINSURANCEDETAILS}</RefusedInsuranceDetails>
							</dutyofdisclosure>
							<Email>{PRIMARY_EMAIL}</Email>
							<Street>{STREET}</Street>
							<Suburb>{SUBURB}</Suburb>
							<State>{STATE}</State>
							<Postcode>{CSL_ZONE}</Postcode>
							<CSLAddress>{STREET}, {SUBURB}, {STATE}, {CSL_ZONE}</CSLAddress>
							<RAMContact/>
							<MembershipEffectiveDate/>
							{PRIOR_INFO}
							{CLAIMS_PAYLOAD}
						</account>
						<policy>
							<LastStatusChange>2025-09-25</LastStatusChange>
							<EffectiveDate>{EFFECTIVEDATE}</EffectiveDate>
							<Term>12</Term>
							<TimeZone>{COUNTRYTIMEZONE}</TimeZone>
							<ExpirationDate>{EXPIRATIONDATE}</ExpirationDate>
							<LineOfBusiness>BusinessPackage</LineOfBusiness>
							<IsConversionPolicy>1</IsConversionPolicy>
							<Status>Application</Status>
							<Currency>{COUNTRYCODE}</Currency>
							<CultureCode>{CURRENCY}</CultureCode>
							<PolicyNumber></PolicyNumber>
							<InceptionDate>{POLICYINCEPTIONDATE}</InceptionDate>
							<ReportingPeriod>Monthly</ReportingPeriod>
							<AuditPeriod>Annual</AuditPeriod>
							<PrimaryRatingState>{PRIMARYRATINGSTATE}</PrimaryRatingState>
							<ManualReferral>{ALWAYSREFERATRENEWAL}</ManualReferral>
                            <Underwritingnotes>{UNDERWRITINGDETAILS}</Underwritingnotes>
							<line>
								<Type>{LINETYPE}</Type>
								<Indicators>
									<Type>Selected</Type>
									<bValue>1</bValue>
								</Indicators>
			{TA}
			{GP}
			{PPL}
			{PF}
			{CV}
			{GT}
			{LE}
			{SV}
            <Excess>
	<Type>GPGTLETA</Type>
	<Voluntary>{GPGTLETA_EXCESS}</Voluntary>
	<Imposed></Imposed>
	<Standard></Standard>
</Excess>
<Excess>
	<Type>PPLPPCV</Type>
	<Voluntary>{PPLPPCV_EXCESS}</Voluntary>
	<Imposed></Imposed>
	<Standard></Standard>
</Excess>
			<exposure>
									<Type>DescriptionOverride</Type>
									<Description/>
								</exposure>
								<CSLSpend>2000</CSLSpend>
								<CSLTenure>1</CSLTenure>
								<GNAFCheck>1</GNAFCheck>
								<NewFleetCode>FL</NewFleetCode>
								<exposure>
									<Type>Description</Type>
									<Description>{DESCRIPTION}</Description>
								</exposure>
			{RISK_BUILDING}
			{RISK_CM_PAYLOAD}
			<CurrentVehicleIteration>2</CurrentVehicleIteration>
			{RISK_FLEETVEHICLE_PAYLOAD}
			<ExpiringPremium>0</ExpiringPremium>
								{LINE_UW}
							</line>
							<PackagePolicyIndicator>1</PackagePolicyIndicator>
							<businessinformation>
								<products>
									<PublicAndProductLiability>{PUBLICANDPRODUCTLIABILITY}</PublicAndProductLiability>
									<ProfessionalProtection>{PROFESSIONALPROTECTION}</ProfessionalProtection>
									<CustomerVehicle>{CUSTOMERVEHICLE}</CustomerVehicle>
									<GeneralProperty>{GENERALPROPERTY}</GeneralProperty>
									<GoodsInTransit>{GOODSINTRANSIT}</GoodsInTransit>
									<LegalExpenses>{LEGALEXPENSES}</LegalExpenses>
									<TaxAudit>{TAXAUDIT}</TaxAudit>
									<StockVehicle>{STOCKVEHICLES}</StockVehicle>
									<CommercialVehicles>{COMMERCIALVEHICLES}</CommercialVehicles>
									<Motor>0</Motor>
								</products>
								<IsBusinessEngageContractor>0</IsBusinessEngageContractor>
								<NumberOfContractor>0</NumberOfContractor>
								<AnnualPaymentContractor/>
								<IsBusinessEngageStaffLabourHireFirms>0</IsBusinessEngageStaffLabourHireFirms>
								<NumberOfLabourHire/>
								<AnnualPaymentLabour/>
								<IsTurnoverMultiState>0</IsTurnoverMultiState>
								<BusinessEstablishmentDate>{BUSINESSESTABLISHMENTDATE}</BusinessEstablishmentDate>
								<AnnualTurnover>{TURNOVER_LESS_FUEL}</AnnualTurnover>
								<NumberOfInternalEmployees/>
								<BusinessEligibleStampDutyExemption>0</BusinessEligibleStampDutyExemption>
								<NumberOfManagementProprietorsAndPartners>{MANAGEMENTPROPRIETORSANDPARTNERS}</NumberOfManagementProprietorsAndPartners>
								<EngagedSalesorWorkshopActivities>{ENGAGEDSALESORWORKSHOPACTIVITIES}</EngagedSalesorWorkshopActivities>
								<IsWebPage>{ISWEBPAGE}</IsWebPage>
								<WebPageDetails>{WEBSITEADDRESS}</WebPageDetails>
								<IsVehicleTurnoverMorethan30Percent>{ISVEHICLETURNOVERMORETHAN30}</IsVehicleTurnoverMorethan30Percent>
								<VehicleTurnoverDetails>{VEHICLETURNOVERDETAILS_PERF}</VehicleTurnoverDetails>
								<VehicleTurnoverDisplayValue>{VEHICLETURNOVERDISPLAY_PERF}</VehicleTurnoverDisplayValue>
								<IsWatercraftRepair>{ISWATERCRAFTREPAIR}</IsWatercraftRepair>
								<WatercraftRepairTurnoverDetails>{VEHICLETURNOVERDETAILS_WATER}</WatercraftRepairTurnoverDetails>
								<WatercraftRepairTurnoverDisplayValue>{VEHICLETURNOVERDISPLAY_WATER}</WatercraftRepairTurnoverDisplayValue>
								<IsWaterWorkPerformed>{ISWATERWORKPERFORMED}</IsWaterWorkPerformed>
								<IsHeavyTransportVehicles>{ISHEAVYTRANSPORTVEHICLES}</IsHeavyTransportVehicles>
								<HeavyVehiclesTransportDetails>{VEHICLETURNOVERDETAILS_HEAVY}</HeavyVehiclesTransportDetails>
								<HeavyVehiclesTransportDisplayValue>{VEHICLETURNOVERDISPLAY_HEAVY}</HeavyVehiclesTransportDisplayValue>
								<IsProductsManufacturedorImported>{ISPRODUCTSMANUFACTUREDORIMPORTED}</IsProductsManufacturedorImported>
								<ProductsDetails>{VEHICLETURNOVERDETAILS_MANIM}</ProductsDetails>
								<ProductsDisplayValue>{VEHICLETURNOVERDISPLAY_MANIM}</ProductsDisplayValue>
								<IsGearboxesRecondition>{ISGEARBOXESRECONDITION}</IsGearboxesRecondition>
								<GearboxesDetails>{VEHICLETURNOVERDETAILS_RECON}</GearboxesDetails>
								<GearboxesDisplayValue>{VEHICLETURNOVERDISPLAY_RECON}</GearboxesDisplayValue>
								<IsConstructionServices>{ISCONSTRUCTIONSERVICES}</IsConstructionServices>
								<ConstructionDetails>{VEHICLETURNOVERDETAILS_CONST}</ConstructionDetails>
								<ConstructionDisplayValue>{VEHICLETURNOVERDISPLAY_CONST}</ConstructionDisplayValue>
								<IsMiningEquipmentServices>{ISMININGEQUIPMENTSERVICES}</IsMiningEquipmentServices>
								<MiningDetails>{VEHICLETURNOVERDETAILS_MINE}</MiningDetails>
								<MiningDisplayValue>{VEHICLETURNOVERDISPLAY_MINE}</MiningDisplayValue>
								<IsUndergroundMining>{ISUNDERGROUNDMINING}</IsUndergroundMining>
								<IsSidelineBusinessEntity>{ISSIDELINEBUSINESSENTITY}</IsSidelineBusinessEntity>
								<SidelineBusinessType>{SIDELINEBUSINESSTYPE}</SidelineBusinessType>
								<TurnoverOfSidelineBusiness>{VEHICLETURNOVERDISPLAY_SIDE}</TurnoverOfSidelineBusiness>
								<PercentageOfTurnoverFromLightVehiclesUnder10Tons>0</PercentageOfTurnoverFromLightVehiclesUnder10Tons>
								<PercentageOfTurnoverFromMediumVehicles10To20Tons>0</PercentageOfTurnoverFromMediumVehicles10To20Tons>
								<PercentageOfTurnoverFromHeavyVehicles20To40Tons>0</PercentageOfTurnoverFromHeavyVehicles20To40Tons>
								<PercentageOfTurnoverFromVeryHeavyVehicles40TonsPlus>0</PercentageOfTurnoverFromVeryHeavyVehicles40TonsPlus>
								<IsRoadTestingOfPrimeMoverTrailersPerformed>{ROADTESTPRIME}</IsRoadTestingOfPrimeMoverTrailersPerformed>
								<ArePreDeterminedTestDriveRoutesUsedOnly>{TESTDRIVEROUTES}</ArePreDeterminedTestDriveRoutesUsedOnly>
								<AreCustomerPrimeMoverTrailersStoredOvernight>{CUSTPRIMESTOV}</AreCustomerPrimeMoverTrailersStoredOvernight>
								<AreCourtesyTrucksOrTtrailersSupplied>{COURTESYTRAILERSSUPPLY}</AreCourtesyTrucksOrTtrailersSupplied>
								<CourtesyDetails>{DETAILSCOURTESYVEH}</CourtesyDetails>
								<PercentageOfTurnoverFromConstructionOrMiningVehicles>{PERCTOCONSORMINING}</PercentageOfTurnoverFromConstructionOrMiningVehicles>
								<CouldTheBusinessBeClassifiedAsAFranchise>{FRANCHISE}</CouldTheBusinessBeClassifiedAsAFranchise>
								<PercentageOfTurnoverFromVehicleServicing>{PERTOVEHSERVICE}</PercentageOfTurnoverFromVehicleServicing>
								<IsRetreadingOrManufacturingConducted>{RETREADINGMANUFACTURING}</IsRetreadingOrManufacturingConducted>
								<ManufacturingDetails/>
								<IsTheSaleOfSecondHandTyresConducted>{SALESECHANDTYRES}</IsTheSaleOfSecondHandTyresConducted>
								<SecondHandTyresDetails>{DETAILSSECHAND}</SecondHandTyresDetails>
								<AreTyresFittedForNonPassengerVehicles>{TYREFITTEDNONPASSVEH}</AreTyresFittedForNonPassengerVehicles>
								<NonPassengerVehiclesDetails>{DETAILSNONPASSVEH}</NonPassengerVehiclesDetails>
								<DoYouRetailOrManufacturerTyres>{DOYOURETAILORMANUFACTURERTYRES}</DoYouRetailOrManufacturerTyres>
								<TyreSalesPercentageTurnover/>
								<TyreSalesTurnoverDisplay>{TYRESALESTURNOVERDISPLAY}</TyreSalesTurnoverDisplay>
								<ReTreadingPercentageTurnover/>
								<ReTreadingTurnoverDisplay>{RETREADINGTURNOVERDISPLAY}</ReTreadingTurnoverDisplay>
								<ImportingTyresPercentageTurnover/>
								<ImportingTyresTurnoverDisplay>{IMPORTINGTYRESTURNOVERDISPLAY}</ImportingTyresTurnoverDisplay>
								<ManufacturingTyresPercentageTurnover/>
								<ManufacturingTyresTurnoverDisplay>{MANUFACTURINGTYRESTURNDISPLAY}</ManufacturingTyresTurnoverDisplay>
								<SalesOfSecondHandTyresPercentageTurnover/>
								<SalesOfSecondHandTyresTurnoverDisplay>{SALESOFSECONDHANDTURNDISPLAY}</SalesOfSecondHandTyresTurnoverDisplay>
								<HeavyTransportTyresPercentageTurnover/>
								<HeavyTransportTyresTurnoverDisplay>{HEAVYTRANSPORTTYRESTURNDISPLAY}</HeavyTransportTyresTurnoverDisplay>
							</businessinformation>
							<RunOffProtection>0</RunOffProtection>
							<IsMPRPolicy>0</IsMPRPolicy>
							<IssueSystem>DCT</IssueSystem>
							<MasterCompany>DCT</MasterCompany>
							<ExpiringPremium>0</ExpiringPremium>
							<MembershipFlag>1</MembershipFlag>
							<ModNumber/>
							<TermFactor>1</TermFactor>
							<Description/>
							<LegacyPolicyNumber>{LEGACYPOLICYNUMBER}</LegacyPolicyNumber>
							<SelectANZSICLookup>{SELECTANZSICLOOKUP}</SelectANZSICLookup>
							<SecondaryANZSICLookup>{SECONDARYANZSICLOOKUP}</SecondaryANZSICLookup>
							{AOI}
                            
						</policy>
                        <BillingKeys>
							<BillClass>{PAYMENT_METHOD}</BillClass>
							</BillingKeys>
					</data>
				</session>
			</_Payload>
		</Session.setDocumentRq>
		<ManuScript.getValueRq manuscript="~ImportManuscriptId~" field="PolicyImportPrivate.ImportProcess2"/>
		<Session.getDocumentRq/>
		<Session.getElementRq path="data/policy/policyProcessing/CurrentPolicyNumberIdentifier"/>
		<Session.getElementRq path="@id"/>
		<Session.getElementRq path="@clientId"/>
        <Session.closeRq/>
	</requests>
</server>'', ''{ISHIGHPERFORMANCE}'', IFNULL (CAST(ISHIGHPERFORMANCE AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_MANIM}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_MANIM AS VARCHAR),'''')),
''{GT}'', IFNULL (CAST(GT AS VARCHAR),'''')),
''{PRIMARYRATINGSTATE}'', IFNULL (CAST(PRIMARYRATINGSTATE AS VARCHAR),'''')),
''{SECONDARYANZSICLOOKUP}'', IFNULL (CAST(SECONDARYANZSICLOOKUP AS VARCHAR),'''')),
''{SITE_STREET}'', IFNULL (CAST(SITE_STREET AS VARCHAR),'''')),
''{RETREADINGTURNOVERDISPLAY}'', IFNULL (CAST(RETREADINGTURNOVERDISPLAY AS VARCHAR),'''')),
''{AOI}'', IFNULL (CAST(AOI AS VARCHAR),'''')),
''{TA}'', IFNULL (CAST(TA AS VARCHAR),'''')),
''{PRIMARY_PHONE_TYPE}'', IFNULL (CAST(PRIMARY_PHONE_TYPE AS VARCHAR),'''')),
''{COUNTRYTIMEZONE}'', IFNULL (CAST(COUNTRYTIMEZONE AS VARCHAR),'''')),
''{LEGALEXPENSES}'', IFNULL (CAST(LEGALEXPENSES AS VARCHAR),'''')),
''{SITE_COUNTRY}'', IFNULL (CAST(SITE_COUNTRY AS VARCHAR),'''')),
''{TYRESALESPERCENTAGETURNOVER}'', IFNULL (CAST(TYRESALESPERCENTAGETURNOVER AS VARCHAR),'''')),
''{SUBURB}'', IFNULL (CAST(SUBURB AS VARCHAR),'''')),
''{EFFECTIVEDATE}'', IFNULL (CAST(EFFECTIVEDATE AS VARCHAR),'''')),
''{PROBABILITY_OF_DEFAULT}'', IFNULL (CAST(PROBABILITY_OF_DEFAULT AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_CONST}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_CONST AS VARCHAR),'''')),
''{PERTOVEHSERVICE}'', IFNULL (CAST(PERTOVEHSERVICE AS VARCHAR),'''')),
''{LINETYPE}'', IFNULL (CAST(LINETYPE AS VARCHAR),'''')),
''{ISANTIQUECLASSICCOLLECTOR}'', IFNULL (CAST(ISANTIQUECLASSICCOLLECTOR AS VARCHAR),'''')),
''{PROFESSIONALPROTECTION}'', IFNULL (CAST(PROFESSIONALPROTECTION AS VARCHAR),'''')),
''{ISCONSTRUCTIONSERVICES}'', IFNULL (CAST(ISCONSTRUCTIONSERVICES AS VARCHAR),'''')),
''{MANUFACTURINGTYRESPERCTURNOVER}'', IFNULL (CAST(MANUFACTURINGTYRESPERCTURNOVER AS VARCHAR),'''')),
''{LINEOFBUSINESS}'', IFNULL (CAST(LINEOFBUSINESS AS VARCHAR),'''')),
''{CRIMINALCONVICTIONDETAILS}'', IFNULL (CAST(CRIMINALCONVICTIONDETAILS AS VARCHAR),'''')),
''{CMLNUMBER}'', IFNULL (CAST(CMLNUMBER AS VARCHAR),'''')),
''{BUSINESSINTERRUPTION}'', IFNULL (CAST(BUSINESSINTERRUPTION AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_MINE}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_MINE AS VARCHAR),'''')),
''{QU3CRIMINALCONVICTION}'', IFNULL (CAST(QU3CRIMINALCONVICTION AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_WATER}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_WATER AS VARCHAR),'''')),
''{ISPRODUCTSMANUFACTUREDORIMPORTED}'', IFNULL (CAST(ISPRODUCTSMANUFACTUREDORIMPORTED AS VARCHAR),'''')),
''{CMLLEGALENTITY}'', IFNULL (CAST(CMLLEGALENTITY AS VARCHAR),'''')),
''{ISVEHICLETURNOVERMORETHAN30}'', IFNULL (CAST(ISVEHICLETURNOVERMORETHAN30 AS VARCHAR),'''')),
''{MAINCONTACT}'', IFNULL (CAST(MAINCONTACT AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_PERF}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_PERF AS VARCHAR),'''')),
''{DETAILSSECHAND}'', IFNULL (CAST(DETAILSSECHAND AS VARCHAR),'''')),
''{TESTDRIVEROUTES}'', IFNULL (CAST(TESTDRIVEROUTES AS VARCHAR),'''')),
''{REFUSEDINSURANCEDETAILS}'', IFNULL (CAST(REFUSEDINSURANCEDETAILS AS VARCHAR),'''')),
''{CSL_MEMBER_STATUS}'', IFNULL (CAST(CSL_MEMBER_STATUS AS VARCHAR),'''')),
''{ISGEARBOXESRECONDITION}'', IFNULL (CAST(ISGEARBOXESRECONDITION AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_MANIM}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_MANIM AS VARCHAR),'''')),
''{TYREFITTEDNONPASSVEH}'', IFNULL (CAST(TYREFITTEDNONPASSVEH AS VARCHAR),'''')),
''{LOAD_DATE}'', IFNULL (CAST(LOAD_DATE AS VARCHAR),'''')),
''{PPLPPCV_EXCESS}'', IFNULL (CAST(PPLPPCV_EXCESS AS VARCHAR),'''')),
''{COUNTRY}'', IFNULL (CAST(COUNTRY AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_ACC}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_ACC AS VARCHAR),'''')),
''{PF}'', IFNULL (CAST(PF AS VARCHAR),'''')),
''{HEAVYTRANSPORTTYRESTURNDISPLAY}'', IFNULL (CAST(HEAVYTRANSPORTTYRESTURNDISPLAY AS VARCHAR),'''')),
''{BUSINESSCONTENTS}'', IFNULL (CAST(BUSINESSCONTENTS AS VARCHAR),'''')),
''{ENGINEERING}'', IFNULL (CAST(ENGINEERING AS VARCHAR),'''')),
''{ROADTESTPRIME}'', IFNULL (CAST(ROADTESTPRIME AS VARCHAR),'''')),
''{ACC_LOC}'', IFNULL (CAST(ACC_LOC AS VARCHAR),'''')),
''{STOP_CREDIT}'', IFNULL (CAST(STOP_CREDIT AS VARCHAR),'''')),
''{MEMBERSHIPSYSTEMDATE}'', IFNULL (CAST(MEMBERSHIPSYSTEMDATE AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_RECON}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_RECON AS VARCHAR),'''')),
''{STATE}'', IFNULL (CAST(STATE AS VARCHAR),'''')),
''{QU3INSURANCEREFUSEDCANCELLED}'', IFNULL (CAST(QU3INSURANCEREFUSEDCANCELLED AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_PERF}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_PERF AS VARCHAR),'''')),
''{CUSTPRIMESTOV}'', IFNULL (CAST(CUSTPRIMESTOV AS VARCHAR),'''')),
''{DOYOURETAILORMANUFACTURERTYRES}'', IFNULL (CAST(DOYOURETAILORMANUFACTURERTYRES AS VARCHAR),'''')),
''{ISWATERCRAFTREPAIR}'', IFNULL (CAST(ISWATERCRAFTREPAIR AS VARCHAR),'''')),
''{WEBSITEADDRESS}'', IFNULL (CAST(WEBSITEADDRESS AS VARCHAR),'''')),
''{CML_RISK_ACCOUNT_MANAGER}'', IFNULL (CAST(CML_RISK_ACCOUNT_MANAGER AS VARCHAR),'''')),
''{CSL_REGION}'', IFNULL (CAST(CSL_REGION AS VARCHAR),'''')),
''{CURRENCY}'', IFNULL (CAST(CURRENCY AS VARCHAR),'''')),
''{SITE_SUBURB}'', IFNULL (CAST(SITE_SUBURB AS VARCHAR),'''')),
''{STANDARD_INDUSTRY_CODE_DESCRIPTION}'', IFNULL (CAST(STANDARD_INDUSTRY_CODE_DESCRIPTION AS VARCHAR),'''')),
''{LINE_UW}'', IFNULL (CAST(LINE_UW AS VARCHAR),'''')),
''{MANUFACTURINGTYRESTURNDISPLAY}'', IFNULL (CAST(MANUFACTURINGTYRESTURNDISPLAY AS VARCHAR),'''')),
''{CUSTOMERVEHICLE}'', IFNULL (CAST(CUSTOMERVEHICLE AS VARCHAR),'''')),
''{POLICYINCEPTIONDATE}'', IFNULL (CAST(POLICYINCEPTIONDATE AS VARCHAR),'''')),
''{CSLNUMBER}'', IFNULL (CAST(CSLNUMBER AS VARCHAR),'''')),
''{RISK_CM_PAYLOAD}'', IFNULL (CAST(RISK_CM_PAYLOAD AS VARCHAR),'''')),
''{RETREADINGPERCENTAGETURNOVER}'', IFNULL (CAST(RETREADINGPERCENTAGETURNOVER AS VARCHAR),'''')),
''{PRIMARY_EMAIL}'', IFNULL (CAST(PRIMARY_EMAIL AS VARCHAR),'''')),
''{CLAIMS_PAYLOAD}'', IFNULL (CAST(CLAIMS_PAYLOAD AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_HEAVY}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_HEAVY AS VARCHAR),'''')),
''{CSL_ZONE}'', IFNULL (CAST(CSL_ZONE AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_RECON}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_RECON AS VARCHAR),'''')),
''{CV}'', IFNULL (CAST(CV AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_SIDE}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_SIDE AS VARCHAR),'''')),
''{TAXAUDIT}'', IFNULL (CAST(TAXAUDIT AS VARCHAR),'''')),
''{SALESOFSECONDHANDTURNDISPLAY}'', IFNULL (CAST(SALESOFSECONDHANDTURNDISPLAY AS VARCHAR),'''')),
''{TYRESALESTURNOVERDISPLAY}'', IFNULL (CAST(TYRESALESTURNOVERDISPLAY AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_ACC}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_ACC AS VARCHAR),'''')),
''{SALESECHANDTYRES}'', IFNULL (CAST(SALESECHANDTYRES AS VARCHAR),'''')),
''{PUREPOLICYNUMBER}'', IFNULL (CAST(PUREPOLICYNUMBER AS VARCHAR),'''')),
''{CML_LEGAL_ENTITY}'', IFNULL (CAST(CML_LEGAL_ENTITY AS VARCHAR),'''')),
''{STOCKVEHICLES}'', IFNULL (CAST(STOCKVEHICLES AS VARCHAR),'''')),
''{PRIOR_INFO}'', IFNULL (CAST(PRIOR_INFO AS VARCHAR),'''')),
''{EXPIRATIONDATE}'', IFNULL (CAST(EXPIRATIONDATE AS VARCHAR),'''')),
''{ISSIDELINEBUSINESSENTITY}'', IFNULL (CAST(ISSIDELINEBUSINESSENTITY AS VARCHAR),'''')),
''{RETREADINGMANUFACTURING}'', IFNULL (CAST(RETREADINGMANUFACTURING AS VARCHAR),'''')),
''{EXPIRINGID_P}'', IFNULL (CAST(EXPIRINGID_P AS VARCHAR),'''')),
''{FRANCHISE}'', IFNULL (CAST(FRANCHISE AS VARCHAR),'''')),
''{BURGLARY}'', IFNULL (CAST(BURGLARY AS VARCHAR),'''')),
''{SIDELINEBUSINESSTYPE}'', IFNULL (CAST(SIDELINEBUSINESSTYPE AS VARCHAR),'''')),
''{HEAVYTRANSPORTTYRESPERCTURNOVER}'', IFNULL (CAST(HEAVYTRANSPORTTYRESPERCTURNOVER AS VARCHAR),'''')),
''{PPL}'', IFNULL (CAST(PPL AS VARCHAR),'''')),
''{DETAILSCOURTESYVEH}'', IFNULL (CAST(DETAILSCOURTESYVEH AS VARCHAR),'''')),
''{ENGAGEDSALESORWORKSHOPACTIVITIES}'', IFNULL (CAST(ENGAGEDSALESORWORKSHOPACTIVITIES AS VARCHAR),'''')),
''{COURTESYTRAILERSSUPPLY}'', IFNULL (CAST(COURTESYTRAILERSSUPPLY AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_CONST}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_CONST AS VARCHAR),'''')),
''{IMPORTINGTYRESTURNOVERDISPLAY}'', IFNULL (CAST(IMPORTINGTYRESTURNOVERDISPLAY AS VARCHAR),'''')),
''{PUBLICANDPRODUCTLIABILITY}'', IFNULL (CAST(PUBLICANDPRODUCTLIABILITY AS VARCHAR),'''')),
''{PHONE}'', IFNULL (CAST(PHONE AS VARCHAR),'''')),
''{GENERALPROPERTY}'', IFNULL (CAST(GENERALPROPERTY AS VARCHAR),'''')),
''{VEHICLETURNOVERDISPLAY_HEAVY}'', IFNULL (CAST(VEHICLETURNOVERDISPLAY_HEAVY AS VARCHAR),'''')),
''{CMLTRADINGNAME}'', IFNULL (CAST(CMLTRADINGNAME AS VARCHAR),'''')),
''{DESCRIPTION}'', IFNULL (CAST(DESCRIPTION AS VARCHAR),'''')),
''{MANAGEMENTPROPRIETORSANDPARTNERS}'', IFNULL (CAST(MANAGEMENTPROPRIETORSANDPARTNERS AS VARCHAR),'''')),
''{ISHEAVYTRANSPORTVEHICLES}'', IFNULL (CAST(ISHEAVYTRANSPORTVEHICLES AS VARCHAR),'''')),
''{BUSINESSBUILDINGS}'', IFNULL (CAST(BUSINESSBUILDINGS AS VARCHAR),'''')),
''{CHOOSEPROTECTION}'', IFNULL (CAST(CHOOSEPROTECTION AS VARCHAR),'''')),
''{TURNOVER_LESS_FUEL}'', IFNULL (CAST(TURNOVER_LESS_FUEL AS VARCHAR),'''')),
''{MONEY}'', IFNULL (CAST(MONEY AS VARCHAR),'''')),
''{MANUSCRIPT}'', IFNULL (CAST(MANUSCRIPT AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_MINE}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_MINE AS VARCHAR),'''')),
''{PRIMARY_PHONE}'', IFNULL (CAST(PRIMARY_PHONE AS VARCHAR),'''')),
''{RISK_FLEETVEHICLE_PAYLOAD}'', IFNULL (CAST(RISK_FLEETVEHICLE_PAYLOAD AS VARCHAR),'''')),
''{FLEET}'', IFNULL (CAST(FLEET AS VARCHAR),'''')),
''{ISMININGEQUIPMENTSERVICES}'', IFNULL (CAST(ISMININGEQUIPMENTSERVICES AS VARCHAR),'''')),
''{DETAILSNONPASSVEH}'', IFNULL (CAST(DETAILSNONPASSVEH AS VARCHAR),'''')),
''{GP}'', IFNULL (CAST(GP AS VARCHAR),'''')),
''{SITE_POSTCODE}'', IFNULL (CAST(SITE_POSTCODE AS VARCHAR),'''')),
''{CSL_CREDIT_LIMIT}'', IFNULL (CAST(CSL_CREDIT_LIMIT AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_WATER}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_WATER AS VARCHAR),'''')),
''{TIMEZONE}'', IFNULL (CAST(TIMEZONE AS VARCHAR),'''')),
''{SELECTANZSICLOOKUP}'', IFNULL (CAST(SELECTANZSICLOOKUP AS VARCHAR),'''')),
''{GOODSINTRANSIT}'', IFNULL (CAST(GOODSINTRANSIT AS VARCHAR),'''')),
''{LEGACYPOLICYNUMBER}'', IFNULL (CAST(LEGACYPOLICYNUMBER AS VARCHAR),'''')),
''{ISWATERWORKPERFORMED}'', IFNULL (CAST(ISWATERWORKPERFORMED AS VARCHAR),'''')),
''{SELECTANZSICLOOKUP_NUMBER}'', IFNULL (CAST(SELECTANZSICLOOKUP_NUMBER AS VARCHAR),'''')),
''{SALESOFSECONDHANDPERCTURNOVER}'', IFNULL (CAST(SALESOFSECONDHANDPERCTURNOVER AS VARCHAR),'''')),
''{LE}'', IFNULL (CAST(LE AS VARCHAR),'''')),
''{COMMERCIALVEHICLES}'', IFNULL (CAST(COMMERCIALVEHICLES AS VARCHAR),'''')),
''{IMPORTINGTYRESPERCENTAGETURNOVER}'', IFNULL (CAST(IMPORTINGTYRESPERCENTAGETURNOVER AS VARCHAR),'''')),
''{EMAIL}'', IFNULL (CAST(EMAIL AS VARCHAR),'''')),
''{STREET}'', IFNULL (CAST(STREET AS VARCHAR),'''')),
''{ID}'', IFNULL (CAST(ID AS VARCHAR),'''')),
''{ISWEBPAGE}'', IFNULL (CAST(ISWEBPAGE AS VARCHAR),'''')),
''{CSL_AREA_MANAGER}'', IFNULL (CAST(CSL_AREA_MANAGER AS VARCHAR),'''')),
''{VEHICLETURNOVERDETAILS_SIDE}'', IFNULL (CAST(VEHICLETURNOVERDETAILS_SIDE AS VARCHAR),'''')),
''{PARTY_CML_NUMBER}'', IFNULL (CAST(PARTY_CML_NUMBER AS VARCHAR),'''')),
''{ABN_NZBN}'', IFNULL (CAST(ABN_NZBN AS VARCHAR),'''')),
''{PERCTOCONSORMINING}'', IFNULL (CAST(PERCTOCONSORMINING AS VARCHAR),'''')),
''{POSTCODE}'', IFNULL (CAST(POSTCODE AS VARCHAR),'''')),
''{SV}'', IFNULL (CAST(SV AS VARCHAR),'''')),
''{GPGTLETA_EXCESS}'', IFNULL (CAST(GPGTLETA_EXCESS AS VARCHAR),'''')),
''{PARTYID}'', IFNULL (CAST(PARTYID AS VARCHAR),'''')),
''{EFFECTIVETIME}'', IFNULL (CAST(EFFECTIVETIME AS VARCHAR),'''')),
''{BUSINESSESTABLISHMENTDATE}'', IFNULL (CAST(BUSINESSESTABLISHMENTDATE AS VARCHAR),'''')),
''{RISK_BUILDING}'', IFNULL (CAST(RISK_BUILDING AS VARCHAR),'''')),
''{STANDARD_INDUSTRY_CODE}'', IFNULL (CAST(STANDARD_INDUSTRY_CODE AS VARCHAR),'''')),
''{COUNTRYCODE}'', IFNULL (CAST(COUNTRYCODE AS VARCHAR),'''')),
''{PAYMENT_METHOD}'', IFNULL (CAST(PAYMENT_METHOD AS VARCHAR),'''')),
''{ALWAYSREFERATRENEWAL}'', IFNULL (CAST(ALWAYSREFERATRENEWAL AS VARCHAR),'''')),
''{UNDERWRITINGDETAILS}'', IFNULL (CAST(UNDERWRITINGDETAILS AS VARCHAR),'''')),
''{SITE_STATE}'', IFNULL (CAST(SITE_STATE AS VARCHAR),'''')),
''{ISUNDERGROUNDMINING}'', IFNULL (CAST(ISUNDERGROUNDMINING AS VARCHAR),'''')) ,
''{HANDLERMAIL}'', IFNULL (CAST(HANDLERMAIL AS VARCHAR),'''')) ,
''{CSL_LEGAL_ENTITY}'', IFNULL (CAST(CSL_LEGAL_ENTITY AS VARCHAR),'''')) ,

''{HANDLERFULLNAME}'', IFNULL (CAST(HANDLERFULLNAME AS VARCHAR),'''')) ,


''<([0-9])'', ''&lt;\\1'')

) as XMLData from 
 AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION WHERE PARTYID IS NOT NULL;
END;
';