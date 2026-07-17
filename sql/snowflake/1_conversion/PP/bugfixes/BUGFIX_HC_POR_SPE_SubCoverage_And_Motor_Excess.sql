-- BUG: 3 fields structurally mismatched against the live DCT manuscript (Carrier_PP_AU_VM_1_0_0_0,
-- pulled via ManuScript.getModelImageRq 2026-07-15) -- values may be correct but are being sent
-- to XML paths DCT's ViewModel doesn't recognize, so they're likely silently dropped/ignored.
--
-- 1) Motor Voluntary Excess (seq 18): we send a flat <VoluntaryExcess> tag directly under
--    <risk>. The manuscript has NO field at that path at all -- the real field,
--    VehicleInput.VoluntaryExcess, is at risk[Type="Motor"]/Excess/Voluntary, a child of the
--    <Excess> wrapper that ALREADY EXISTS in our template (currently holding only 3 empty
--    age-band excess fields, and with the wrong tag names -- LessThanAge20/Age20To21/Age22To25
--    instead of the manuscript's AgeLessThan20/AgeBetween20To21/AgeBetween22To25). Fixed both:
--    moved VOLUNTARYEXCESS into the existing Excess block as <Voluntary>, added an empty
--    <Standard/> sibling (no source data for Standard Excess -- checked PM_03, only
--    VOLUNTARYEXCESS exists), and corrected the 3 age-band tag names to match the manuscript.
--    Cross-checked: Building's own Excess block (seq 7) already nests Voluntary correctly --
--    only Motor had this bug.
--
-- 2) & 3) HC "Unspecified/Specified Items Away Premises" (seq 13): the manuscript defines these
--    as distinct nested sub-coverages, not flat tags --
--      ContentsAndStocksInput.UnspecifiedItemsAwayPremises -> coverage[Type="POR_SD"]/sValue
--      ContentsAndStocksInput.SpecifiedItemsAwayPremises    -> coverage[Type="SPE_SD"]/sValue
--    (POR_SD = "Portable Items", SPE_SD = "Specified Items", per the manuscript's reference
--    table -- same naming convention as every other HC/HB sub-coverage in this project, e.g.
--    BLI_SD/BLD_SD/BFL_SD). We were sending flat <SpecifiedItemsPremises>/
--    <UnspecifiedItemsAwayPremises> tags matching no manuscript path. Fixed by nesting the
--    SAME existing tokens ({SPECIFIEDITEMSAWAY}/{UNSPECIFIEDITEMSAWAY}, already correctly
--    computed as Taken/Not Taken) inside proper <coverage> sub-blocks, adding the Indicator
--    each sub-coverage needs (POR_SD_INDICATOR/SPE_SD_INDICATOR -- see the companion view fix,
--    BUGFIX_HB_INDICATOR_WrongSourceTable.sql, amended same day to add these two columns --
--    DEPLOY THAT VIEW FIX FIRST, this SP fix depends on it).
--    NOTE: <UnspecifiedItemsAwayPremisesLimit> (the coded enum, e.g.
--    "2000peritemupto10000perevent") is UNCHANGED -- confirmed correct and already flat at the
--    ContentsAndStocks level; the manuscript shows DCT derives POR_SD's own numeric limit
--    (ContentsAndStocksInput.PortableLimit) automatically from that enum via an internal rule,
--    so we don't need to send it ourselves.
--
-- Both fixes are structural only (tag placement/naming) -- no new source data, no changed
-- values, so risk is low. Full procedure body below is the live DDL with only these targeted
-- sections changed; everything else (all other 16 sequences) is untouched.

CREATE OR REPLACE PROCEDURE "PP_CONVERSION_RUN"("P_RELOAD_ALL_SEQS" BOOLEAN DEFAULT TRUE)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN

IF (P_RELOAD_ALL_SEQS) THEN

    DELETE FROM AGGNE.DEV.PER_CLAIM_HISTORY_TARGET
        WHERE CAST(LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_CLAIM_HISTORY_TARGET);
    DELETE FROM AGGNE.DEV.PER_COMPETITOR_INFORMATION_TARGET
        WHERE CAST(LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_COMPETITOR_INFORMATION_TARGET);
    DELETE FROM AGGNE.DEV.PER_ACCOUNT_LOC_TARGET
        WHERE CAST(LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_ACCOUNT_LOC_TARGET);
    DELETE FROM AGGNE.DEV.PER_BUILDING_TARGET
        WHERE CAST(LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_BUILDING_TARGET);
    DELETE FROM AGGNE.DEV.PER_HC_TARGET
        WHERE CAST(LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_HC_TARGET);
    DELETE FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
        WHERE CAST(LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET);
    DELETE FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET
        WHERE CAST(LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET);

    -- Seq 1: account_info_claim_history -> AGGNE.DEV.PER_CLAIM_HISTORY_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_VW_CLAIM_HISTORY'',
        ''<losshistory>
<DateOfClaim>{DATEOFCLAIM}</DateOfClaim>
<AmmountPaid>{AMOUNTPAID}</AmmountPaid>
<Line>{LINE}</Line>
<Cause>{CAUSE}</Cause>
<Source>Perf</Source>
</losshistory>'',
        ''AGGNE.DEV.PER_CLAIM_HISTORY_TARGET'',
        ''account_info_claim_history''
    );

    -- Seq 2: Prior_INFO -> AGGNE.DEV.PER_COMPETITOR_INFORMATION_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION'',
        ''<priorinsuranceinfo>
			<PriorCarrier>{PRIORCARRIER}</PriorCarrier>
			<Price>{PRICE}</Price>
		</priorinsuranceinfo>'',
        ''AGGNE.DEV.PER_COMPETITOR_INFORMATION_TARGET'',
        ''Prior_INFO''
    );

    -- Seq 3: ACC_LOC -> AGGNE.DEV.PER_ACCOUNT_LOC_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_ACCOUNT_LOC'',
        ''<location>
				<Number>{RISKNUMBER}</Number>
				<address>
					<State>{STATE}</State>
					<Address1>{ADDRESS1}</Address1>
					<Address2></Address2>
					<City>{SUBURB}</City>
					<ZipCode>{POSTCODE}</ZipCode>
					<Country>{LOC_COUNTRY}</Country>
				</address>
				<GeocodeStatusDisplay>Unverified</GeocodeStatusDisplay>
				<LocationType/>
				<BusinessType/>
				<AddressOverride>{ADDRESSOVERRIDE}</AddressOverride>
				<AddressVerified>0</AddressVerified>
			</location>'',
        ''AGGNE.DEV.PER_ACCOUNT_LOC_TARGET'',
        ''ACC_LOC''
    );

    -- Seq 4: Building_SubCov -> AGGNE.DEV.PER_BUILDING_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_BB_SUBCOVERAGES'',
        ''<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>{INDICATOR}</Indicator>
		{SVALUE}
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
        <Premium>{EXP_PREM}</Premium>
	</coverage>'',
        ''AGGNE.DEV.PER_BUILDING_TARGET'',
        ''Building_SubCov''
    );

    -- Seq 5: BUILDING_UW -> AGGNE.DEV.PER_BUILDING_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.BUILDING_UW'',
        ''<UnderwritingAdjustment>
<Type>{COVERAGE}</Type>
<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
<AdjustmentAmount></AdjustmentAmount>
<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>'',
        ''AGGNE.DEV.PER_BUILDING_TARGET'',
        ''BUILDING_UW''
    );

    -- Seq 6: HB_CLAUSE -> AGGNE.DEV.PER_BUILDING_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.HB_CLAUSE'',
        ''<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>'',
        ''AGGNE.DEV.PER_BUILDING_TARGET'',
        ''HB_CLAUSE''
    );

    -- Seq 7: RISK_Building_HB -> AGGNE.DEV.PER_BUILDING_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD'',
        ''<coverage>

	<Type>Building</Type>

	<Excess>

		<Amount/>

		<Imposed/>

		<Flood/>

		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>

		<Earthquake/>

		<Standard/>

		<Glass/>

	</Excess>       <SetExcessAmount>0</SetExcessAmount>

	<Indicator>{HB_INDICATOR}</Indicator>

	<CoverageLevel>Per Occurrence</CoverageLevel>

	<LossOfRentLimit>0</LossOfRentLimit>

	<Glass/>

	<AccidentalLossOrDamage>{ACCIDENTALLOSSORDAMAGE}</AccidentalLossOrDamage>

	<UWAdjustmentIndicator>{HB_UW_INDICATOR}</UWAdjustmentIndicator>

	<GlassLimit>{HOMEBUILDINGSLIMIT}</GlassLimit>

	<Code>HB</Code>

	<LandlordProtections>{LANDLORDPROTECTIONS}</LandlordProtections>

	<MinimumRentalPeriod>{MINIMUMRENTALPERIOD}</MinimumRentalPeriod>

	<WeeklyRent>{WEEKLYRENT}</WeeklyRent>

	<ClassCode>

		<APRA>FISR</APRA>

		<Business>BSP</Business>

	</ClassCode>     {HB_CLAUSE}{HB_UW}     <ClaimsIncurred>{HBCLMINCD}</ClaimsIncurred>

	<NumberOfClaims>{HBCLMCNT}</NumberOfClaims>

	<Premium>{EXPPREM}</Premium>

</coverage>'',
        ''AGGNE.DEV.PER_BUILDING_TARGET'',
        ''RISK_Building_HB''
    );

    -- Seq 8: HC_exceed_values -> AGGNE.DEV.PER_HC_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE'',
        ''<HomeContents>
		{VALUE}
		{DESCRIPTION}
	</HomeContents>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''HC_exceed_values''
    );

    -- Seq 9: HC_Specified_Contents -> AGGNE.DEV.PER_HC_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS'',
        ''<SpecifiedContents>
		{VALUE}
		{DESCRIPTION}
	</SpecifiedContents>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''HC_Specified_Contents''
    );

    -- Seq 10: Building_SubCov -> AGGNE.DEV.PER_HC_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_SUBCOVERAGES'',
        ''<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>{INDICATOR}</Indicator>
		{SVALUE}
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
        <Premium>{EXP_PREM}</Premium>
	</coverage>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''Building_SubCov''
    );

    -- Seq 11: BUILDING_UW -> AGGNE.DEV.PER_HC_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_BUILDING_UW'',
        ''<UnderwritingAdjustment>
<Type>{COVERAGE}</Type>
<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
<AdjustmentAmount></AdjustmentAmount>
<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''BUILDING_UW''
    );

    -- Seq 12: LOC_HC_CLAUSE -> AGGNE.DEV.PER_HC_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_CLAUSE'',
        ''<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''LOC_HC_CLAUSE''
    );

    -- Seq 13: RISK_Building_HC -> AGGNE.DEV.PER_HC_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD'',
        ''<coverage>

	<Type>ContentsAndStocks</Type>

	<Indicator>{HC_INDICATOR}</Indicator>

	<CoverageLevel>Per Occurrence</CoverageLevel>

	<FloodDamage>{FLOODDAMAGE}</FloodDamage>

	<Excess>

		<Flood/>

		<Earthquake/>

		<Imposed/>

		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>

		<Standard/>

		<Hail/>

	</Excess>

	<StockLimitExcludingVehiclesWatercraft/>

	<EmployeeToolsofTradeLimit/>

	<PersonalEffectsLimit/>

	<MotorFuelsLimit/>

	<VehiclesInStockLimit/>

	<CustomersVehiclesLimit/>

	<WatercraftInStockUnder8mLimit/>

	<CustomersWatercraftUnder8mLimit/>

	<HailDamagetoVehiclesorWatercraftsInStockLimit/>

	<Code>HC</Code>

	<AccidentalLossOrDamage>{ACCIDENTALLOSSORDAMAGE}</AccidentalLossOrDamage>

	<HomeContentsLimits>{ANYITEMSEXCEEDVALUE}</HomeContentsLimits>

	<UnspecifiedItemsAwayPremisesLimit>{UNSPECIFIEDITEMSAWAYLIMIT}</UnspecifiedItemsAwayPremisesLimit>

	<coverage>
		<Type>SPE_SD</Type>
		<Indicator>{SPE_SD_INDICATOR}</Indicator>
		<sValue>{SPECIFIEDITEMSAWAY}</sValue>
		<Code>HCSPE_SD</Code>
		<Description>Specified Items</Description>
	</coverage>

	<coverage>
		<Type>POR_SD</Type>
		<Indicator>{POR_SD_INDICATOR}</Indicator>
		<sValue>{UNSPECIFIEDITEMSAWAY}</sValue>
		<Code>HCPOR_SD</Code>
		<Description>Portable Items</Description>
	</coverage>

	<HomeContentsTotal></HomeContentsTotal>

	<SpecifiedContentsTotal></SpecifiedContentsTotal>  {HC_EXCEED_VALUES}  {HC_SPECIFIED_CONTENTS}  {SUBCOV}  <ClassCode>

		<APRA>FISR</APRA>

		<Business>BSP</Business>

	</ClassCode>

	<ClaimsIncurred>{HCCLMINCD}</ClaimsIncurred>

	<NumberOfClaims>{HCCLMCNT}</NumberOfClaims>

	<Premium>{HBEXPPREM}</Premium>  {HC_CLAUSE}  {UW} </coverage>	'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''RISK_Building_HC''
    );

    -- Seq 14: RISK_Building -> AGGNE.DEV.PER_RISK_BUILDING_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_RISK_BUILDING_FINAL'',
        ''<risk>
	<Type>Building</Type>
	<SICCode>General Mechanical Workshop</SICCode>
	<LocationNumber>{RISKNUMBER}</LocationNumber>
	<NumberOfSprayBoothsAtThisLocation/>
	<Condition/>
	<IsTheSurroundingAreaFreeOfAccelerantsAndHeatWork/>
	<SurroundingAreaHousekeeping/>
	<MixingRoomHousekeeping/>
	<OldestBoothAgeYears/>
	<ApproximateReplacementCostOfHighestValueBooth/>
	<YearOfLastProfessionalService/>
	<IsThereEvidenceOfRegularBoothCleaningOrServicing/>
	<IsBoothInteriorWallProtectionUsed/>
	<HasTheExhaustFanBeenReconditionedOrReplacedInTheLast5yrs/>
	<DismantlerFloorCondition/>
	<DismantlerAreaHousekeeping/>
	<LocationOfDefueling/>
	<LocationOfDismantlingArea/>
	<AreHoistsUsedForDismantling/>
	<FireSuppressionEquipmentNearDismantlingAreas/>
	<IsMetalRecyclingConductedOnSite/>
	<AreMetalRecyclingActivitiesConductedInsideABuilding/>
	<StockStorageHousekeeping/>
	<TyresOrBatteriesStorageHousekeeping/>
	<StorageOfEVsAndTheirBatteries/>
	<AreVehiclesStackedOrRacked/>
	<HowIsFuelStored/>
	<AverageNumberOfVehiclesInTheYard/>
	<YardFloorOrHousekeeping/>
	<ClearLandSqm/>
	<AdequateSecurityForOvernightStorage/>
	<HighRiskSpecialisedEquipment/>
	<Detail/>
	<EvidenceOfInadequateFuelStorageProcedures/>
	<AreThereMoreThanAFewTyresStackedUpAgainstTheBuilding/>
	<VolumeOfTyresStackedOutside/>
	<VolumeOfTyresStackedInside/>
	<AreTheTyresOutsideStoredInAnOrderlyManner/>
	<IsExcessiveOilResiduePresentOnTheOutsideGround/>
	<SatisfactoryRiskMitigationProcessesEvident/>
	<Embargoes>
		<MatchingRestrictions/>
	</Embargoes>
	<StandardExcess></StandardExcess>
	<ImposedExcess></ImposedExcess>
	<Details>Building 1</Details>
	<IsBuildingHeritage>0</IsBuildingHeritage>
	<AmoutOfEPS>0</AmoutOfEPS>
	<ExternalDoors>1</ExternalDoors>
	<SecurityAccessibleWindows>1</SecurityAccessibleWindows>
	<SecurityAlarm>0</SecurityAlarm>
	<VehicleDetails>Vehicle 1</VehicleDetails>
	<VehicleYardShowingAnySecurity>0</VehicleYardShowingAnySecurity>
	<VehicleKeyStorage>0</VehicleKeyStorage>
	<HireVehicleContractSupplied>0</HireVehicleContractSupplied>
	<LocationANZSICCode/>
	<LocationConnectedToTownWaterMain>0</LocationConnectedToTownWaterMain>
	<StoreFlammableGoods>0</StoreFlammableGoods>
	<WhatQuantity/>
	<IsAusStandardFollowed>1</IsAusStandardFollowed>
	{RISK_BUILDING}
	{RISK_BC}
	<RoofConstruction>{ROOFCONSTRUCTION_FINAL}</RoofConstruction>
	<NumberOfStories>{STOREYS}</NumberOfStories>
	<WhatYearWasTheBuildingConstructed>{YEARBUILDINGCONSTRUCTED}</WhatYearWasTheBuildingConstructed>
	<OccupationOfHighestRiskTenant/>
	<YearTheBuildingWasLastReWired>{YEARLASTREWIRED}</YearTheBuildingWasLastReWired>
	<YearTheBuildingWasLastRePlumbed>{YEARLASTREPLUMBED}</YearTheBuildingWasLastRePlumbed>
	<YearTheBuildingWasLastReRoofed></YearTheBuildingWasLastReRoofed>
	<MainWallConstruction>{MAINWALLCONSTRUCTION_FINAL}</MainWallConstruction>
	<FloorConstruction>{FLOORCONSTRUCTION_FINAL}</FloorConstruction>
	<YearLastReWiredCalculation></YearLastReWiredCalculation>
	<WhatTypeOfAlarmSystemIsInstalled>{ALARMSYSTEMINSTALLED_FINAL}</WhatTypeOfAlarmSystemIsInstalled>
	<DoYouHaveSecurityCamerasOrCCTVInstalled></DoYouHaveSecurityCamerasOrCCTVInstalled>
	<IsThereATwoMeterHighPerimeterFenceEnclosingThePremises></IsThereATwoMeterHighPerimeterFenceEnclosingThePremises>
	<AreSecurityBollardsInPlace></AreSecurityBollardsInPlace>
	<AreYourPremisesPatrolledByASecurityGuard/>
	<AreDeadlocksInstalledOnAllExternalDoors>{DEADLOCKSINSTALLED_FINAL}</AreDeadlocksInstalledOnAllExternalDoors>
	<IsThereExteriorSecurityLighting/>
	<BarsOrGrillsInstalledOnAllWindows>{GRILLKEYLOCKINSTALLED_FINAL}</BarsOrGrillsInstalledOnAllWindows>
	<TwentyFourHoursAttendanceOnSite>0</TwentyFourHoursAttendanceOnSite>
	<SecurityMeasures>{SECURITYDETAILS}</SecurityMeasures>
	<WhatYearWasARiskAssessmentReviewLastUndertaken></WhatYearWasARiskAssessmentReviewLastUndertaken>
	<ConditionOfBuilding></ConditionOfBuilding>
	<ConditionOfRoof></ConditionOfRoof>
	<RoofConstructionAon/>
	<RoofSqmAon>0</RoofSqmAon>
	<LandSqm></LandSqm>
	<PropertyInputGeocodeURL/>
	<HomeBuildingOccupied>{HOWOCCUPPIED}</HomeBuildingOccupied>
	<InterestedPartyDescription>{INTERESTEDPARTY}</InterestedPartyDescription>
</risk>'',
        ''AGGNE.DEV.PER_RISK_BUILDING_TARGET'',
        ''RISK_Building''
    );

    -- Seq 15: Risk_CM -> AGGNE.DEV.PER_COM_COVERAGES_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_COM_COVERAGES'',
        ''<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>{INDICATOR}</Indicator>
		{SVALUE}
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
        <Premium>{EXP_PREM}</Premium>
	</coverage>'',
        ''AGGNE.DEV.PER_COM_COVERAGES_TARGET'',
        ''Risk_CM''
    );

    -- Seq 16: PER_PM_BUILDING_UW -> AGGNE.DEV.PER_COM_COVERAGES_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_PM_BUILDING_UW'',
        ''<UnderwritingAdjustment>
<Type>{COVERAGE}</Type>
<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
<AdjustmentAmount></AdjustmentAmount>
<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>'',
        ''AGGNE.DEV.PER_COM_COVERAGES_TARGET'',
        ''PER_PM_BUILDING_UW''
    );

    -- Seq 17: COM_CLAUSE -> AGGNE.DEV.PER_COM_COVERAGES_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.COM_CLAUSE'',
        ''<Clauses>
	    <Type>Motor</Type>
	    <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
	    <SelectClauseDescription>{DCINPUT} </SelectClauseDescription>
	    <IsClauseReadOnly>0</IsClauseReadOnly>
	    <IsEditable>1</IsEditable>
	    <Value>{DCINPUT}</Value>
	    <DescriptionValue>{DCINPUT}</DescriptionValue>
	</Clauses>'',
        ''AGGNE.DEV.PER_COM_COVERAGES_TARGET'',
        ''COM_CLAUSE''
    );

    -- Seq 18: RISK_Building_PM -> AGGNE.DEV.PER_COM_COVERAGES_TARGET
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_COM_PAYLOAD'',
        ''<risk>

	<Type>Motor</Type>

	<ExcessWaiverForGlass>{EXCESSWAIVERFORGLASS}</ExcessWaiverForGlass>

	<OnHookTowingProtection>0</OnHookTowingProtection>


	<ProtectionType>{PROTECTIONTYPE}</ProtectionType>

	<HireVehicleExcess>0</HireVehicleExcess>

	<CourtesyVehicleExcess>0</CourtesyVehicleExcess>

	<ValueAccessoriesOption>2</ValueAccessoriesOption>

	<MarketValueWithoutAccessories>{MVVALUEWITHOUTACCESSORIES}</MarketValueWithoutAccessories>

	<ValueWithoutAccessories>{AVVALUEWITHOUTACCESSORIES}</ValueWithoutAccessories>

	<HireCourtesyDeliveryUse/>

	<UnlimitedGlass>1</UnlimitedGlass>

	<OnHook>0</OnHook>

	<DeliveryVehicleExcess>0</DeliveryVehicleExcess>

	<InterestedParties>{VEHHAVEANINTERESTEDPARTY}</InterestedParties>

	<InterestedPartiesAddress/>

	<InterestedPartiesName/>

	<IsVehicleImportedorNot>0</IsVehicleImportedorNot>

	<NonClaimDiscount>0</NonClaimDiscount>

	<LocationID/>

	<FleetType>Default</FleetType>

	<VehicleDetails>Vehicle 0</VehicleDetails>

	<GaragingPostcode/>

	<Usage/>

	<Performance/>

	<PrincipalOperator>Yes</PrincipalOperator>

	<Included>1</Included>

	<HighestValueVehicleinFleet>0</HighestValueVehicleinFleet>

	<MaximumOneVehiclePay>0</MaximumOneVehiclePay>

	<State>NSW</State>

	<Segment/>

	<PerformanceSafetyModifications>0</PerformanceSafetyModifications>

	<IsNonStandardAccessoriesIncludedinCover>0</IsNonStandardAccessoriesIncludedinCover>

	<CarHaveAnyModifications>0</CarHaveAnyModifications>

	<WindscreenExtFlag>0</WindscreenExtFlag>

	<Code>PM</Code>

	<ImportType>{IMPORTFLAG}</ImportType>

	<AddedHistoryID>2069</AddedHistoryID>

	<CommercialVehicleNumber>1</CommercialVehicleNumber>

	<coverage>

		<Type>CommercialVehicle</Type>

		<limit>

			<Type>CommercialVehicle</Type>

			<iValue>{MARKETVALUEWITHACCESSORIESAMOUNT}</iValue>

		</limit>

		<Indicator>1</Indicator>

		<ClassCode>

			<APRA>DMV</APRA>

			<Business>DMV</Business>

		</ClassCode>

		<Code>PM</Code>                         {SUBCOV}       <Description>Commercial Motor</Description>

		<ExpiringPurePremium>0</ExpiringPurePremium>

		<ExpiringPremium>0</ExpiringPremium>

		<ClaimsIncurred>{PMCLMINCD}</ClaimsIncurred>

		<NumberOfClaims>{PMCLMCNT}</NumberOfClaims>

		<Premium>{PMEXPPREM}</Premium>

	</coverage>

	<HireCarHireAfterIncident>{HIRECARHIREAFTERINCIDENT}</HireCarHireAfterIncident>

	<CoverType/>

	<VehicleType>{VEHICLETYPE}</VehicleType>

	<VehicleInfoOverride>{OVERRIDE}</VehicleInfoOverride>

	<RegistrationNumber>{REGISTRATIONNUMBER}</RegistrationNumber>

	<VinNumber/>

	<Year>{YEAR}</Year>

	<RegoStatus>500</RegoStatus>

	<Make>{MAKE}</Make>

	<Model>{MODEL}</Model>

	<Description>{DESCRIPTION}</Description>

	<NightParkingLocation/>

	<NightParkingPostcode/>

	<DayParkingLocation/>

	<DayParkingPostcode/>

	<SecurityType/>

	<FinanceType/>

	<DateOfPurchase/>

	<AnnualMileage/>

	<CoverValue/>

	<Excess>

		<Standard/>

		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>

		<AgeLessThan20/>

		<AgeBetween20To21/>

		<AgeBetween22To25/>

	</Excess>

	<NonStandardAccessories/>

	<NonStandardAccessoriesSumInsured/>

	<ModificationType/>

	<ModificationSumInsured/>

	<TotalSumInsured>0</TotalSumInsured>

	<LocationDescription>Primary Location</LocationDescription>

	<VehicleFullDescription>{DESCRIPTION} </VehicleFullDescription>

	<BodyType>{BODYTYPE}</BodyType>

	<EngineSize>{ENGINESIZE}</EngineSize>

	<NumberOfCylinders>{NUMBEROFCYLINDERS}</NumberOfCylinders>

	<DriveDescription>{DRIVEDESCRIPTION}</DriveDescription>

	<InductionType>{INDUCTIONTYPE}</InductionType>

	<GrossVehicleMass>{GROSSVEHICLEMASS}</GrossVehicleMass>

	<WouldYouLikeToAddAccessoriesOrModifications>{MVADDACCORMODS}</WouldYouLikeToAddAccessoriesOrModifications>

	<AgreedValueAmount>{AGREEDVALUEAMOUNT}</AgreedValueAmount>

	<AgreedValueDescription/>

	<AgreedValueDescriptionValue/>

	<MarketValueDescription>{MARKETVALUEDESCRIPTION}</MarketValueDescription>

	<WouldYouLikeToAddAccessoriesOrModificationsMarket>{MVADDACCORMODS}</WouldYouLikeToAddAccessoriesOrModificationsMarket>

	<MarketValueDescriptionValue>{MARKETVALUEDESCRIPTIONVALUE}</MarketValueDescriptionValue>

	<MarketValueWithAccessories>{MARKETVALUEWITHACCESSORIESAMOUNT}</MarketValueWithAccessories>

	<HighestRiskUse/>

	<AgeOfYoungestRegularDriver>{AGEOFYOUNGESTREGULARDRIVER}</AgeOfYoungestRegularDriver>

	<RestrictionOfDriverAge>{RESTRICTIONOFDRIVERAGE}</RestrictionOfDriverAge>

	<DoesTheVehicleHaveAnInterestedParty>{VEHHAVEANINTERESTEDPARTY}</DoesTheVehicleHaveAnInterestedParty>

	<AddDetailsForTheInterestedParty>{ADDDETAILSFORTHEINTERESTEDPARTY}</AddDetailsForTheInterestedParty>

	<HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime/>

	<HowOftenDoYouPickUpOrDeliverVehicles/>

	<ChoiceOfRepair>{CHOICEOFREPAIR}</ChoiceOfRepair>

	<WhatIsTheTypicalRadiusOfTravelFromTheBaseLocation/>

	<WillTheVehicleTransportMotorVehiclesOrTheMembersGeneralProperty/>

	<AreAnyVehiclesDriverSuppliedPM/>

	<Details/>

	<IsThisVehicleUsedForRideShareOperation/>

	<AreHireContractsRestrictedToNamedDriversOnly/>

	<AreAnyVehiclesDriverSupplied/>

	<WillAnyContractorsOperateThisVehicle/>

	<WillThisVehicleBeUsedToDeliverDangerousGoods/>

	<StandardExcess/>

	<ImposedExcess/>

	<OnHookExcess/>

	<UWAdjustmentTotal/>

	<MarketValue/>

	<NumberofVehicles/>

	<TotalValueofNonStandard/>

	<GeneralBusinessUse/>

	<CarHire/>

	<HowManyOfYourVehiclesMayRequireOnHook/>

	<DoAnyOfYourVehiclesHaveATaxiRegistration/>

	<DoesTheMemberOwnAnyOtherBusinesses/>

	<WhereAreIdleVehiclesStored/>

	<DetailsOfVehicleLocationRiskMitigation/>

	<AreAnyVehiclesHiredOutForRideShareOperations/>

	<WhatPercentOfTheFleetIsHiredOutToRideShareOperators/>

	<HowManyYearsExperienceDoesThisMemberHaveOperatingAHireFleet/>

	<AreContractorsEmployedAsDrivers/>

	<AreAnyVehiclesUsedToDeliverDangerousGoods/>

	<HowManyYearsExperienceDoesThisMemberHaveOperatingADeliveryFleet/>

	<HowOftenIsTheVehicleUsed/>

	<IsTheVehicleUsedForMembersBusinessNeedsOnly/>

	<IsTheVehicleUsedForMembersBusinessNeedsOnlyDetails/>

	<VehicleTransportHazardousDangerousGoods/>

	<VehicleTransportHazardousDangerousGoodsDetails/>

	<IsTheVehicleUsedToTransportAnyCustomerItemsReward/>

	<IsTheVehicleUsedToTransportAnyCustomerItemsRewardDetails/>

	<MaximumRangeVehicleWillTravelBusinessUse/>

	<IsTheVehicleDrivenByDirectEmployeesOnly/>

	<IsTheVehicleDrivenByDirectEmployeesOnlyDetails/>

	<IfPrimeMoverWillItTowMoreThan1TrailerAtTime/>

	<IfPrimeMoverWillItTowMoreThan1TrailerAtTimeDetails/>

	<MakeOther/>

	<ModelOther/>

	<MakeID/>

	<FamilyID/>

	<RedbookCode>{MVRBVEHICLEKEY}</RedbookCode>

	<RedBookStatus/>

	<FuelType>{FUELTYPE}</FuelType>

	<TrackRear>{TRACKREAR}</TrackRear>

	<PowerKW>{POWERKW}</PowerKW>

	<BuildingID/>

	<OccupancyID/>  {COM_CLAUSE}  {UW}  </risk> '',
        ''AGGNE.DEV.PER_COM_COVERAGES_TARGET'',
        ''RISK_Building_PM''
    );

END IF;

CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();

RETURN ''Done -- '' || CASE WHEN P_RELOAD_ALL_SEQS THEN ''full reload (all 18 seqs + final)'' ELSE ''final only (skip seqs)'' END;

END;
';