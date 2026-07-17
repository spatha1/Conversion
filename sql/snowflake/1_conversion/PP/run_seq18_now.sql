-- ============================================================
-- Run seq 18 RISK_Building_PM — ready to execute
-- Template sourced from local PolicyConversion DB (post {COM_CLAUSE} fix)
-- Apply PER_COM_PAYLOAD view DDL first before running this.
--
-- NOTE on <Indicator>1</Indicator> (v1 — unchanged, no fix needed):
--   Motor Indicator stays hardcoded 1.  PER_COM_PAYLOAD (source view) only
--   produces rows for policies in PM_03 (INNER JOIN with SAMPLE_PER), so
--   every row represents a policy that genuinely has motor coverage.
--   The all-checkboxes bug was isolated to seq 7/13 (building/contents)
--   where PER_HOME_BUILDING_PAYLOAD serves HB-only and HC-only policies
--   from the same UNION view.
-- ============================================================

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
		<Code>CM</Code>	{SUBCOV}	<Description>Commercial Motor</Description>
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

-- ── Verify: check row count and token status ──────────────────────────────
SELECT COUNT(*) AS RISK_PM_ROWS,
       SUM(CASE WHEN PAYLOAD LIKE '%{%}%' THEN 1 ELSE 0 END) AS PAYLOADS_WITH_TOKENS
FROM   AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'RISK_Building_PM';
-- Expected: RISK_PM_ROWS > 0, PAYLOADS_WITH_TOKENS = 0

-- ── Regenerate final XML ──────────────────────────────────────────────────
CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();

-- ── Final token check ─────────────────────────────────────────────────────
SELECT LEGACYPOLICYNUMBER,
       CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 'TOKENS REMAIN' ELSE 'CLEAN' END AS STATUS,
       REGEXP_COUNT(REQUEST_XML, '\\{[^}]+\\}') AS TOKEN_COUNT
FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE  REQUEST_XML LIKE '%{%}%'
ORDER  BY LEGACYPOLICYNUMBER;
-- Expected: 0 rows
