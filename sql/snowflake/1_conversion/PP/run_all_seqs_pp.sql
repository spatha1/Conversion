-- ============================================================
-- Snowflake: Full PP Building/Contents ETL re-run (seqs 4–14)
--
-- Use this when:
--   • Date rolled over — GETDATE() no longer matches yesterday's LOAD_DATE
--   • Any source view or template was updated and a full refresh is needed
--
-- Run order is mandatory:
--   Seqs 4-6 (PER_BUILDING_TARGET sub-payloads)
--   Seqs 8-12 (PER_HC_TARGET sub-payloads)  ← BEFORE seqs 7 and 13
--   Seq 7  (RISK_Building_HB  — reads PER_HC_TARGET via SUBCOV in source view)
--   Seq 13 (RISK_Building_HC  — reads PER_HC_TARGET via SUBCOV/HC_EXCEED etc.)
--   Seq 14 (RISK_Building     — reads PER_RISK_BUILDING_FINAL)
--   Final SPs
--
-- Seq 7 template: {SUBCOV} REMOVED (structural fix — BB sub-coverages
-- are now injected inside </coverage> by PER_BUILDING_FINAL_AGG.hb_agg)
-- ============================================================


-- ════════════════════════════════════════════════════════════════
-- STEP 1: Clear most-recent-batch data from all target tables
-- (Deletes 2026-06-24 rows so today's run has no duplicates)
-- ════════════════════════════════════════════════════════════════

DELETE FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE CAST(LOAD_DATE AS DATE) = (
    SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_BUILDING_TARGET
);

DELETE FROM AGGNE.DEV.PER_HC_TARGET
WHERE CAST(LOAD_DATE AS DATE) = (
    SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_HC_TARGET
);

DELETE FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
WHERE CAST(LOAD_DATE AS DATE) = (
    SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
);

-- Verify tables are empty
SELECT 'PER_BUILDING_TARGET'     AS TBL, COUNT(*) AS CNT FROM AGGNE.DEV.PER_BUILDING_TARGET
UNION ALL
SELECT 'PER_HC_TARGET'           AS TBL, COUNT(*) AS CNT FROM AGGNE.DEV.PER_HC_TARGET
UNION ALL
SELECT 'PER_RISK_BUILDING_TARGET' AS TBL, COUNT(*) AS CNT FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET;
-- Expected: all 0


-- ════════════════════════════════════════════════════════════════
-- STEP 2: Seq 4 — Building_SubCov (BB sub-coverages → PER_BUILDING_TARGET)
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_BB_SUBCOVERAGES',
    $$<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>1</Indicator>
		{SVALUE}
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
        <Premium>{EXP_PREM}</Premium>
	</coverage>$$,
    'AGGNE.DEV.PER_BUILDING_TARGET',
    'Building_SubCov'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 3: Seq 5 — BUILDING_UW (UW adjustments → PER_BUILDING_TARGET)
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.BUILDING_UW',
    $$<UnderwritingAdjustment>
<Type>{COVERAGE}</Type>
<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
<AdjustmentAmount></AdjustmentAmount>
<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>$$,
    'AGGNE.DEV.PER_BUILDING_TARGET',
    'BUILDING_UW'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 4: Seq 6 — HB_CLAUSE (HB clauses → PER_BUILDING_TARGET)
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.HB_CLAUSE',
    $$<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>$$,
    'AGGNE.DEV.PER_BUILDING_TARGET',
    'HB_CLAUSE'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 5: Seq 8 — HC_exceed_values → PER_HC_TARGET
-- (must run before seq 7/13 — PER_HOME_BUILDING_PAYLOAD reads this)
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE',
    $$<HomeContents>
		{VALUE}
		{DESCRIPTION}
	</HomeContents>$$,
    'AGGNE.DEV.PER_HC_TARGET',
    'HC_exceed_values'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 6: Seq 9 — HC_Specified_Contents → PER_HC_TARGET
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS',
    $$<SpecifiedContents>
		{VALUE}
		{DESCRIPTION}
	</SpecifiedContents>$$,
    'AGGNE.DEV.PER_HC_TARGET',
    'HC_Specified_Contents'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 7: Seq 10 — Building_SubCov (HC sub-coverages → PER_HC_TARGET)
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_HC_SUBCOVERAGES',
    $$<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>1</Indicator>
		{SVALUE}
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
        <Premium>{EXP_PREM}</Premium>
	</coverage>$$,
    'AGGNE.DEV.PER_HC_TARGET',
    'Building_SubCov'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 8: Seq 11 — BUILDING_UW (HC UW adjustments → PER_HC_TARGET)
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_HC_BUILDING_UW',
    $$<UnderwritingAdjustment>
<Type>{COVERAGE}</Type>
<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
<AdjustmentAmount></AdjustmentAmount>
<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>$$,
    'AGGNE.DEV.PER_HC_TARGET',
    'BUILDING_UW'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 9: Seq 12 — LOC_HC_CLAUSE (HC clauses → PER_HC_TARGET)
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_HC_CLAUSE',
    $$<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>$$,
    'AGGNE.DEV.PER_HC_TARGET',
    'LOC_HC_CLAUSE'
);


-- Checkpoint: confirm seqs 4-6 and 8-12 loaded before continuing
SELECT ITR_TYPE, COUNT(*) AS CNT
FROM   AGGNE.DEV.PER_BUILDING_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE
ORDER  BY ITR_TYPE;

SELECT ITR_TYPE, COUNT(*) AS CNT
FROM   AGGNE.DEV.PER_HC_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE
ORDER  BY ITR_TYPE;
-- Expected in PER_BUILDING_TARGET: Building_SubCov, BUILDING_UW, HB_CLAUSE
-- Expected in PER_HC_TARGET: Building_SubCov, HC_exceed_values, HC_Specified_Contents, BUILDING_UW, LOC_HC_CLAUSE


-- ════════════════════════════════════════════════════════════════
-- STEP 10: Seq 7 — RISK_Building_HB (main HB block → PER_BUILDING_TARGET)
-- FIXED TEMPLATE: {SUBCOV} removed — BB sub-coverages are now injected
-- inside </coverage> by PER_BUILDING_FINAL_AGG.hb_agg
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD',
    $$<coverage>
	<Type>Building</Type>
	<Excess>
		<Amount/>
		<Imposed/>
		<Flood/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Earthquake/>
		<Standard/>
		<Glass/>
	</Excess>
	<SetExcessAmount>0</SetExcessAmount>
	<Indicator>1</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<LossOfRentLimit>0</LossOfRentLimit>
	<Glass/>
	<AccidentalLossOrDamage>{ACCIDENTALLOSSORDAMAGE}</AccidentalLossOrDamage>
	<UWAdjustmentIndicator>0</UWAdjustmentIndicator>
	<GlassLimit>{HOMEBUILDINGSLIMIT}</GlassLimit>
	<Code>HB</Code>
	<LandlordProtections>{LANDLORDPROTECTIONS}</LandlordProtections>
	<MinimumRentalPeriod>{MINIMUMRENTALPERIOD}</MinimumRentalPeriod>
	<WeeklyRent>{WEEKLYRENT}</WeeklyRent>
	<ClassCode>
		<APRA>HH</APRA>
		<Business>HBC</Business>
	</ClassCode>     {HB_CLAUSE}     <ClaimsIncurred>{HBCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{HBCLMCNT}</NumberOfClaims>
	<Premium>{EXPPREM}</Premium>
</coverage>$$,
    'AGGNE.DEV.PER_BUILDING_TARGET',
    'RISK_Building_HB'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 11: Seq 13 — RISK_Building_HC (main HC block → PER_HC_TARGET)
-- {SUBCOV} here is CORRECT — pulls HC sub-coverages (seq 10 rows)
-- inside the ContentsAndStocks coverage block
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD',
    $$<coverage>
	<Type>ContentsAndStocks</Type>
	<Indicator>1</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<FloodDamage>Taken</FloodDamage>
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
	<HomeContentsLimits>1</HomeContentsLimits>
	<SpecifiedItemsPremises>{SPECIFIEDITEMSAWAY}</SpecifiedItemsPremises>
	<UnspecifiedItemsAwayPremises>{UNSPECIFIEDITEMSAWAY}</UnspecifiedItemsAwayPremises>
	<UnspecifiedItemsAwayPremisesLimit>{UNSPECIFIEDITEMSAWAYLIMIT}</UnspecifiedItemsAwayPremisesLimit>
	<HomeContentsTotal>9100</HomeContentsTotal>
	<SpecifiedContentsTotal>622221</SpecifiedContentsTotal>  {HC_EXCEED_VALUES}  {HC_SPECIFIED_CONTENTS}  {SUBCOV}  <ClassCode>
		<APRA>HH</APRA>
		<Business>HBC</Business>
	</ClassCode>
	<ClaimsIncurred>{HCCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{HCCLMCNT}</NumberOfClaims>
	<Premium>{HBEXPPREM}</Premium>  {HC_CLAUSE}  {UW} </coverage>$$,
    'AGGNE.DEV.PER_HC_TARGET',
    'RISK_Building_HC'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 12: Seq 14 — RISK_Building (outer <risk> block → PER_RISK_BUILDING_TARGET)
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_RISK_BUILDING_FINAL',
    $$<risk>
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
</risk>$$,
    'AGGNE.DEV.PER_RISK_BUILDING_TARGET',
    'RISK_Building'
);


-- ════════════════════════════════════════════════════════════════
-- STEP 13: Final count check before running final SPs
-- ════════════════════════════════════════════════════════════════
SELECT ITR_TYPE, COUNT(*) AS CNT
FROM   AGGNE.DEV.PER_BUILDING_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE ORDER BY ITR_TYPE;

SELECT ITR_TYPE, COUNT(*) AS CNT
FROM   AGGNE.DEV.PER_HC_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE ORDER BY ITR_TYPE;

SELECT ITR_TYPE, COUNT(*) AS CNT
FROM   AGGNE.DEV.PER_RISK_BUILDING_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE ORDER BY ITR_TYPE;


-- ════════════════════════════════════════════════════════════════
-- STEP 14: Seq 17 — COM_CLAUSE (motor clauses → PER_COM_COVERAGES_TARGET)
-- Must run BEFORE seq 18 — seq 18 source view reads COM_CLAUSE rows
-- ════════════════════════════════════════════════════════════════
DELETE FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET WHERE ITR_TYPE = 'COM_CLAUSE';

CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.COM_CLAUSE',
    $$<Clauses>
    <Type>Motor</Type>
    <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
    <SelectClauseDescription>{DCINPUT} </SelectClauseDescription>
    <IsClauseReadOnly>0</IsClauseReadOnly>
    <IsEditable>1</IsEditable>
    <Value>{DCINPUT}</Value>
    <DescriptionValue>{DCINPUT}</DescriptionValue>
</Clauses>$$,
    'AGGNE.DEV.PER_COM_COVERAGES_TARGET',
    'COM_CLAUSE'
);

SELECT ITR_TYPE, COUNT(*) AS CNT,
       SUM(CASE WHEN PAYLOAD LIKE '%{%}%' THEN 1 ELSE 0 END) AS ROWS_WITH_TOKENS
FROM   AGGNE.DEV.PER_COM_COVERAGES_TARGET WHERE ITR_TYPE = 'COM_CLAUSE'
GROUP BY ITR_TYPE;
-- Expected: ROWS_WITH_TOKENS = 0


-- ════════════════════════════════════════════════════════════════
-- STEP 15: Seq 18 — RISK_Building_PM (motor risk → PER_COM_COVERAGES_TARGET)
-- ════════════════════════════════════════════════════════════════
DELETE FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET WHERE ITR_TYPE = 'RISK_Building_PM';

CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_COM_PAYLOAD',
    $$<risk>
<Type>Motor</Type>
<ExcessWaiverForGlass>{EXCESSWAIVERFORGLASS}</ExcessWaiverForGlass>
<OnHookTowingProtection>0</OnHookTowingProtection>
<VoluntaryExcess>{VOLUNTARYEXCESS}</VoluntaryExcess>
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
<Code>CM</Code>
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
	<Code>CM</Code>                         {SUBCOV}       <Description>Commercial Motor</Description>
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
	<LessThanAge20/>
	<Age20To21/>
	<Age22To25/>
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
<WouldYouLikeToAddAccessoriesOrModifications/>
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
<FuelType/>
<TrackRear/>
<PowerKW>0</PowerKW>
<BuildingID/>
<OccupancyID/>  {COM_CLAUSE}  {UW}  </risk>$$,
    'AGGNE.DEV.PER_COM_COVERAGES_TARGET',
    'RISK_Building_PM'
);

SELECT ITR_TYPE, COUNT(*) AS CNT,
       SUM(CASE WHEN PAYLOAD LIKE '%{%}%' THEN 1 ELSE 0 END) AS ROWS_WITH_TOKENS
FROM   AGGNE.DEV.PER_COM_COVERAGES_TARGET WHERE ITR_TYPE = 'RISK_Building_PM'
GROUP BY ITR_TYPE;
-- Expected: ROWS_WITH_TOKENS = 0


-- ════════════════════════════════════════════════════════════════
-- STEP 16: Regenerate final XML
-- ════════════════════════════════════════════════════════════════
CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();


-- ════════════════════════════════════════════════════════════════
-- STEP 17: Validate — token check across ALL policies
-- ════════════════════════════════════════════════════════════════
SELECT LEGACYPOLICYNUMBER,
       REGEXP_COUNT(REQUEST_XML, '\\{[^}]+\\}') AS TOKEN_COUNT
FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE  REQUEST_XML LIKE '%{%}%'
ORDER  BY TOKEN_COUNT DESC;
-- Expected: 0 rows

SELECT
    COUNT(*) AS TOTAL_POLICIES,
    SUM(CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 0 ELSE 1 END) AS CLEAN,
    SUM(CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 1 ELSE 0 END) AS TOKENS_REMAIN
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;


-- ════════════════════════════════════════════════════════════════
-- STEP 18: Validate structure for a sample policy (P00002676)
-- ════════════════════════════════════════════════════════════════
SELECT LEGACYPOLICYNUMBER,
       CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 'TOKENS REMAIN' ELSE 'CLEAN' END AS STATUS,
       REGEXP_COUNT(REQUEST_XML, '<Type>Building</Type>')          AS HB_TOP_LEVEL,
       REGEXP_COUNT(REQUEST_XML, '<Type>ContentsAndStocks</Type>') AS HC_TOP_LEVEL,
       REGEXP_COUNT(REQUEST_XML, '<Type>BLD_')                     AS BB_SUBCOV_COUNT,
       REGEXP_COUNT(REQUEST_XML, '<Type>CAD_SD|CFL_SD|CNT_SD|CNT_EQ|CNT_ST|CNT_BF|CNT_CY|CLI_SD|SPE_SD')
                                                                   AS HC_SUBCOV_COUNT
FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE  LEGACYPOLICYNUMBER = 'P00002676';
-- Expected: STATUS=CLEAN, HB_TOP_LEVEL=1, HC_TOP_LEVEL=1, BB_SUBCOV_COUNT=9, HC_SUBCOV_COUNT=9
