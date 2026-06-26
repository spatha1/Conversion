-- ============================================================
-- Complete motor vehicle re-run: seq 17 (COM_CLAUSE) then seq 18 (RISK_Building_PM)
--
-- ORDER MATTERS: seq 18 source view (PER_COM_PAYLOAD) reads COM_CLAUSE
-- rows from PER_COM_COVERAGES_TARGET — run seq 17 FIRST.
--
-- Fixes applied (in local PolicyConversion DB):
--   Seq 17: {CLAUSESSELECTION} → {DCCLAUSETYPE}
--           {SELECTCLAUSEDESCRIPTION} → {DCINPUT}
--   Seq 18: {CLAUSE} → {COM_CLAUSE}
--           {Description} → {DESCRIPTION}
--   PER_COM_PAYLOAD view: UW column added, ITR_TYPE fixed to 'PER_PM_BUILDING_UW'
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- PART A  — SEQ 17: COM_CLAUSE
-- ════════════════════════════════════════════════════════════

-- A1. Confirm source data
SELECT COUNT(*) AS COM_CLAUSE_SRC_ROWS FROM AGGNE.DEV.COM_CLAUSE;

-- A2. Delete stale COM_CLAUSE rows (had wrong {CLAUSESSELECTION} tokens)
DELETE FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'COM_CLAUSE';

-- A3. Re-run seq 17
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

-- A4. Verify — expect ROWS_WITH_TOKENS = 0
SELECT COUNT(*) AS COM_CLAUSE_ROWS,
       SUM(CASE WHEN PAYLOAD LIKE '%{%}%' THEN 1 ELSE 0 END) AS ROWS_WITH_TOKENS
FROM   AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'COM_CLAUSE';


-- ════════════════════════════════════════════════════════════
-- PART B  — SEQ 18: RISK_Building_PM
-- (Run ONLY after Part A shows ROWS_WITH_TOKENS = 0)
-- ════════════════════════════════════════════════════════════

-- B1. Confirm PER_COM_PAYLOAD sees the new COM_CLAUSE rows
SELECT COUNT(*) AS PAYLOAD_ROWS FROM AGGNE.DEV.PER_COM_PAYLOAD;

-- B2. Quick sanity — check UW and COM_CLAUSE columns are populated for a sample
SELECT PUREPOLICYNUMBER,
       LEFT(SUBCOV,    80) AS SUBCOV_PREVIEW,
       LEFT(COM_CLAUSE,80) AS COM_CLAUSE_PREVIEW,
       LEFT(UW,        80) AS UW_PREVIEW
FROM   AGGNE.DEV.PER_COM_PAYLOAD
LIMIT  2;

-- B3. Delete stale RISK_Building_PM rows (had {IMPOSEDEXCESS}, {STANDARDEXCESS}, {CLAUSE} etc.)
DELETE FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'RISK_Building_PM';

-- B4. Re-run seq 18 with fully fixed template
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
	<RedbookCode/>
	<RedBookStatus/>
	<FuelType/>
	<TrackRear/>
	<PowerKW>0</PowerKW>
	<BuildingID/>
	<OccupancyID/>  {COM_CLAUSE}  {UW}  </risk>$$,
    'AGGNE.DEV.PER_COM_COVERAGES_TARGET',
    'RISK_Building_PM'
);

-- B5. Verify seq 18 — expect PAYLOADS_WITH_TOKENS = 0
SELECT COUNT(*) AS RISK_PM_ROWS,
       SUM(CASE WHEN PAYLOAD LIKE '%{%}%' THEN 1 ELSE 0 END) AS PAYLOADS_WITH_TOKENS
FROM   AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'RISK_Building_PM';


-- ════════════════════════════════════════════════════════════
-- PART C  — Final SPs + token check
-- (Run ONLY after B5 shows PAYLOADS_WITH_TOKENS = 0)
-- ════════════════════════════════════════════════════════════

CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();

-- C1. Final token check — expect 0 rows
SELECT LEGACYPOLICYNUMBER,
       CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 'TOKENS REMAIN' ELSE 'CLEAN' END AS STATUS,
       REGEXP_COUNT(REQUEST_XML, '\\{[^}]+\\}') AS TOKEN_COUNT
FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE  REQUEST_XML LIKE '%{%}%'
ORDER  BY LEGACYPOLICYNUMBER;

-- C2. Summary count
SELECT
    COUNT(*) AS TOTAL_POLICIES,
    SUM(CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 0 ELSE 1 END) AS CLEAN,
    SUM(CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 1 ELSE 0 END) AS TOKENS_REMAIN
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;
