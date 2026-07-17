-- ============================================================
-- SUPERSEDED (2026-07-10) — do not use. Kept only for history of why the approach changed.
--
-- Use PP_CONVERSION_RUN_REGENERATED_FROM_CONFIG.sql instead. This file hand-patched 2 lines
-- (G-25, G-32); the replacement pulls all 18 templates fresh from live PP_ConversionConfig
-- instead, so it can't drift or contain a transcription error, and it covers every future
-- config change automatically — not just today's two. Standing rule going forward: any
-- PP_ConversionConfig change gets synced into PP_CONVERSION_RUN via full regeneration from
-- config, never a hand-patch like this one.
-- ============================================================

-- ============================================================
-- PP_CONVERSION_RUN_SYNC_G25_G32.sql (original content below, historical only)
--
-- CRITICAL FINDING (2026-07-10): AGGNE.DEV.PP_CONVERSION_RUN is the real, complete PP
-- conversion orchestrator — it does the truncate-equivalent (DELETE latest batch), all 18
-- DYNAMIC_XML_V1 calls, AND Phase 2 (PER_CONVERSION_FINAL_LOAD + PER_CONVERSION_FINAL_XML).
-- Its 18 templates are HARDCODED INLINE in the procedure body — it does NOT read the SQL
-- Server PP_ConversionConfig table at call time. That table and this procedure are two
-- separate copies of the same templates that must be kept in sync MANUALLY.
--
-- Diffed this procedure's embedded templates against the live PP_ConversionConfig
-- (Azure host) on 2026-07-10:
--   - In sync: G-13, G-22, G-28, G-29, G-31 (all already reflected here)
--   - OUT OF SYNC: G-25 (ClassCode still HH/HBC here, not FISR/BSP) and G-32 (totals still
--     9100/622221 here, not blanked) — both fixed in PP_ConversionConfig today but NOT yet
--     reflected in this procedure. Running PP_CONVERSION_RUN right now would still produce
--     the old, wrong ClassCode and totals despite the SQL Server config fix.
--
-- This script is a CREATE OR REPLACE of the full procedure with ONLY those two changes
-- applied (seq 7 and seq 13 ClassCode -> FISR/BSP; seq 13 totals blanked). Every other line
-- is byte-identical to the live GET_DDL output captured today — do not treat this as a
-- rewrite, it is a full-body replace with two surgical edits (Snowflake procedures can't be
-- partially altered).
--
-- NOT APPLIED — run this yourself, then re-run the validation (see
-- PP_VALIDATION_RUN.sql, replacing the earlier 3-step plan — see note at the bottom of that
-- file for why it changed).
-- ============================================================

CREATE OR REPLACE PROCEDURE "PP_CONVERSION_RUN"("P_RELOAD_ALL_SEQS" BOOLEAN DEFAULT TRUE)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN

-- ═══════════════════════════════════════════════════════════
-- PHASE 1: Re-run all 18 DYNAMIC_XML_V1 sequences
--          Skipped when P_RELOAD_ALL_SEQS = FALSE
-- ═══════════════════════════════════════════════════════════
IF (P_RELOAD_ALL_SEQS) THEN

    -- Clear latest-batch rows from all target tables
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


    -- ── Seq 1: Claim History ──────────────────────────────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_VW_CLAIM_HISTORY'',
        ''<losshistory> <DateOfClaim>{DATEOFCLAIM}</DateOfClaim> <AmmountPaid>{AMOUNTPAID}</AmmountPaid> <Line>{LINE}</Line> <Cause>{CAUSE}</Cause> <Source>Perf</Source> </losshistory>'',
        ''AGGNE.DEV.PER_CLAIM_HISTORY_TARGET'',
        ''account_info_claim_history''
    );

    -- ── Seq 2: Prior Insurance Info ───────────────────────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION'',
        ''<priorinsuranceinfo> <PriorCarrier>{PRIORCARRIER}</PriorCarrier> <Price>{PRICE}</Price> </priorinsuranceinfo>'',
        ''AGGNE.DEV.PER_COMPETITOR_INFORMATION_TARGET'',
        ''Prior_INFO''
    );

    -- ── Seq 3: Account Location ───────────────────────────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_ACCOUNT_LOC'',
        ''<location> <Number>{RISKNUMBER}</Number> <address> <State>{STATE}</State> <Address1>{ADDRESS1}</Address1> <Address2></Address2> <City>{SUBURB}</City> <ZipCode>{POSTCODE}</ZipCode> <Country>{LOC_COUNTRY}</Country> </address> <GeocodeStatusDisplay>Unverified</GeocodeStatusDisplay> <LocationType/> <BusinessType/> <AddressOverride>{ADDRESSOVERRIDE}</AddressOverride> </location>'',
        ''AGGNE.DEV.PER_ACCOUNT_LOC_TARGET'',
        ''ACC_LOC''
    );

    -- ── Seq 4: BB Sub-Coverages → PER_BUILDING_TARGET ─────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_BB_SUBCOVERAGES'',
        ''<coverage> <Type>{TYPE}</Type> <limit> <Type>{TYPE}</Type> <iValue>{IVALUE}</iValue> </limit> <Indicator>1</Indicator> {SVALUE} <Code>{CODE}</Code> <Description>{DESCRIPTION}</Description> <Premium>{EXP_PREM}</Premium> </coverage>'',
        ''AGGNE.DEV.PER_BUILDING_TARGET'',
        ''Building_SubCov''
    );

    -- ── Seq 5: HB UW Adjustments → PER_BUILDING_TARGET ───────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.BUILDING_UW'',
        ''<UnderwritingAdjustment> <Type>{COVERAGE}</Type> <AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection> <AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent> <AdjustmentAmount></AdjustmentAmount> <Recurring> <Indicator>{RECURRINGINDICATOR}</Indicator> </Recurring> <UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription> </UnderwritingAdjustment>'',
        ''AGGNE.DEV.PER_BUILDING_TARGET'',
        ''BUILDING_UW''
    );

    -- ── Seq 6: HB Clauses → PER_BUILDING_TARGET ──────────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.HB_CLAUSE'',
        ''<Clause> <Type>{DCCLAUSETYPE}</Type> <Indicator>1</Indicator> <Description>{DCINPUT}</Description> <DisableFlag>1</DisableFlag> </Clause>'',
        ''AGGNE.DEV.PER_BUILDING_TARGET'',
        ''HB_CLAUSE''
    );

    -- ── Seq 8: HC Items Exceeding Value → PER_HC_TARGET ───────
    -- Must run BEFORE seq 7 (PER_HOME_BUILDING_PAYLOAD reads HC_exceed_values rows)
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE'',
        ''<HomeContents> {VALUE} {DESCRIPTION} </HomeContents>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''HC_exceed_values''
    );

    -- ── Seq 9: HC Specified Contents → PER_HC_TARGET ──────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS'',
        ''<SpecifiedContents> {VALUE} {DESCRIPTION} </SpecifiedContents>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''HC_Specified_Contents''
    );

    -- ── Seq 10: HC Sub-Coverages → PER_HC_TARGET ──────────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_SUBCOVERAGES'',
        ''<coverage> <Type>{TYPE}</Type> <limit> <Type>{TYPE}</Type> <iValue>{IVALUE}</iValue> </limit> <Indicator>1</Indicator> {SVALUE} <Code>{CODE}</Code> <Description>{DESCRIPTION}</Description> <Premium>{EXP_PREM}</Premium> </coverage>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''Building_SubCov''
    );

    -- ── Seq 11: HC UW Adjustments → PER_HC_TARGET ────────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_BUILDING_UW'',
        ''<UnderwritingAdjustment> <Type>{COVERAGE}</Type> <AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection> <AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent> <AdjustmentAmount></AdjustmentAmount> <Recurring> <Indicator>{RECURRINGINDICATOR}</Indicator> </Recurring> <UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription> </UnderwritingAdjustment>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''BUILDING_UW''
    );

    -- ── Seq 12: HC Clauses → PER_HC_TARGET ───────────────────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HC_CLAUSE'',
        ''<Clause> <Type>{DCCLAUSETYPE}</Type> <Indicator>1</Indicator> <Description>{DCINPUT}</Description> <DisableFlag>1</DisableFlag> </Clause>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''LOC_HC_CLAUSE''
    );

    -- ── Seq 7: RISK_Building_HB → PER_BUILDING_TARGET ─────────
    -- Runs AFTER seqs 4-6 (BB sub-covs in PER_BUILDING_TARGET) and
    --                  8-12 (HC sub-covs in PER_HC_TARGET — for SUBCOV/HC_EXCEED tokens)
    -- NOTE: {SUBCOV} OMITTED from template (BUG-NEW-01 local fix).
    --       BB sub-coverages are injected inside </coverage> by PER_BUILDING_FINAL_AGG.
    --       SQL Server ConversionConfig still has {SUBCOV} — update it to match this.
    -- G-25 FIX (2026-07-10): ClassCode APRA/Business HH/HBC -> FISR/BSP
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD'',
        ''<coverage> <Type>Building</Type> <Excess> <Amount/> <Imposed/> <Flood/> <Voluntary>{VOLUNTARYEXCESS}</Voluntary> <Earthquake/> <Standard/> <Glass/> </Excess> <SetExcessAmount>0</SetExcessAmount> <Indicator>{HB_INDICATOR}</Indicator> <CoverageLevel>Per Occurrence</CoverageLevel> <LossOfRentLimit>0</LossOfRentLimit> <Glass/> <AccidentalLossOrDamage>{ACCIDENTALLOSSORDAMAGE}</AccidentalLossOrDamage> <UWAdjustmentIndicator>0</UWAdjustmentIndicator> <GlassLimit>{HOMEBUILDINGSLIMIT}</GlassLimit> <Code>HB</Code> <LandlordProtections>{LANDLORDPROTECTIONS}</LandlordProtections> <MinimumRentalPeriod>{MINIMUMRENTALPERIOD}</MinimumRentalPeriod> <WeeklyRent>{WEEKLYRENT}</WeeklyRent> <ClassCode> <APRA>FISR</APRA> <Business>BSP</Business> </ClassCode> {HB_CLAUSE} <ClaimsIncurred>{HBCLMINCD}</ClaimsIncurred> <NumberOfClaims>{HBCLMCNT}</NumberOfClaims> <Premium>{EXPPREM}</Premium> </coverage>'',
        ''AGGNE.DEV.PER_BUILDING_TARGET'',
        ''RISK_Building_HB''
    );

    -- ── Seq 13: RISK_Building_HC → PER_HC_TARGET ──────────────
    -- Runs AFTER seqs 8-12 (all HC sub-payloads must be in PER_HC_TARGET first)
    -- G-25 FIX (2026-07-10): ClassCode APRA/Business HH/HBC -> FISR/BSP
    -- G-32 FIX (2026-07-10): HomeContentsTotal/SpecifiedContentsTotal test residue blanked
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD'',
        ''<coverage> <Type>ContentsAndStocks</Type> <Indicator>{HC_INDICATOR}</Indicator> <CoverageLevel>Per Occurrence</CoverageLevel> <FloodDamage>Taken</FloodDamage> <Excess> <Flood/> <Earthquake/> <Imposed/> <Voluntary>{VOLUNTARYEXCESS}</Voluntary> <Standard/> <Hail/> </Excess> <StockLimitExcludingVehiclesWatercraft/> <EmployeeToolsofTradeLimit/> <PersonalEffectsLimit/> <MotorFuelsLimit/> <VehiclesInStockLimit/> <CustomersVehiclesLimit/> <WatercraftInStockUnder8mLimit/> <CustomersWatercraftUnder8mLimit/> <HailDamagetoVehiclesorWatercraftsInStockLimit/> <Code>HC</Code> <AccidentalLossOrDamage>{ACCIDENTALLOSSORDAMAGE}</AccidentalLossOrDamage> <HomeContentsLimits>{ANYITEMSEXCEEDVALUE}</HomeContentsLimits> <SpecifiedItemsPremises>{SPECIFIEDITEMSAWAY}</SpecifiedItemsPremises> <UnspecifiedItemsAwayPremises>{UNSPECIFIEDITEMSAWAY}</UnspecifiedItemsAwayPremises> <UnspecifiedItemsAwayPremisesLimit>{UNSPECIFIEDITEMSAWAYLIMIT}</UnspecifiedItemsAwayPremisesLimit> <HomeContentsTotal></HomeContentsTotal> <SpecifiedContentsTotal></SpecifiedContentsTotal> {HC_EXCEED_VALUES} {HC_SPECIFIED_CONTENTS} {SUBCOV} <ClassCode> <APRA>FISR</APRA> <Business>BSP</Business> </ClassCode> <ClaimsIncurred>{HCCLMINCD}</ClaimsIncurred> <NumberOfClaims>{HCCLMCNT}</NumberOfClaims> <Premium>{HBEXPPREM}</Premium> {HC_CLAUSE} {UW} </coverage>'',
        ''AGGNE.DEV.PER_HC_TARGET'',
        ''RISK_Building_HC''
    );

    -- ── Seq 14: RISK_Building (outer risk block) → PER_RISK_BUILDING_TARGET ──
    -- Runs AFTER seqs 7 and 13 (PER_BUILDING_FINAL_AGG reads both target tables)
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_RISK_BUILDING_FINAL'',
        ''<risk> <Type>Building</Type> <SICCode>General Mechanical Workshop</SICCode> <LocationNumber>{RISKNUMBER}</LocationNumber> <NumberOfSprayBoothsAtThisLocation/> <Condition/> <IsTheSurroundingAreaFreeOfAccelerantsAndHeatWork/> <SurroundingAreaHousekeeping/> <MixingRoomHousekeeping/> <OldestBoothAgeYears/> <ApproximateReplacementCostOfHighestValueBooth/> <YearOfLastProfessionalService/> <IsThereEvidenceOfRegularBoothCleaningOrServicing/> <IsBoothInteriorWallProtectionUsed/> <HasTheExhaustFanBeenReconditionedOrReplacedInTheLast5yrs/> <DismantlerFloorCondition/> <DismantlerAreaHousekeeping/> <LocationOfDefueling/> <LocationOfDismantlingArea/> <AreHoistsUsedForDismantling/> <FireSuppressionEquipmentNearDismantlingAreas/> <IsMetalRecyclingConductedOnSite/> <AreMetalRecyclingActivitiesConductedInsideABuilding/> <StockStorageHousekeeping/> <TyresOrBatteriesStorageHousekeeping/> <StorageOfEVsAndTheirBatteries/> <AreVehiclesStackedOrRacked/> <HowIsFuelStored/> <AverageNumberOfVehiclesInTheYard/> <YardFloorOrHousekeeping/> <ClearLandSqm/> <AdequateSecurityForOvernightStorage/> <HighRiskSpecialisedEquipment/> <Detail/> <EvidenceOfInadequateFuelStorageProcedures/> <AreThereMoreThanAFewTyresStackedUpAgainstTheBuilding/> <VolumeOfTyresStackedOutside/> <VolumeOfTyresStackedInside/> <AreTheTyresOutsideStoredInAnOrderlyManner/> <IsExcessiveOilResiduePresentOnTheOutsideGround/> <SatisfactoryRiskMitigationProcessesEvident/> <Embargoes> <MatchingRestrictions/> </Embargoes> <StandardExcess></StandardExcess> <ImposedExcess></ImposedExcess> <Details>Building 1</Details> <IsBuildingHeritage>0</IsBuildingHeritage> <AmoutOfEPS>0</AmoutOfEPS> <ExternalDoors>1</ExternalDoors> <SecurityAccessibleWindows>1</SecurityAccessibleWindows> <SecurityAlarm>0</SecurityAlarm> <VehicleDetails>Vehicle 1</VehicleDetails> <VehicleYardShowingAnySecurity>0</VehicleYardShowingAnySecurity> <VehicleKeyStorage>0</VehicleKeyStorage> <HireVehicleContractSupplied>0</HireVehicleContractSupplied> <LocationANZSICCode/> <LocationConnectedToTownWaterMain>0</LocationConnectedToTownWaterMain> <StoreFlammableGoods>0</StoreFlammableGoods> <WhatQuantity/> <IsAusStandardFollowed>1</IsAusStandardFollowed> {RISK_BUILDING} {RISK_BC} <RoofConstruction>{ROOFCONSTRUCTION_FINAL}</RoofConstruction> <NumberOfStories>{STOREYS}</NumberOfStories> <WhatYearWasTheBuildingConstructed>{YEARBUILDINGCONSTRUCTED}</WhatYearWasTheBuildingConstructed> <OccupationOfHighestRiskTenant/> <YearTheBuildingWasLastReWired>{YEARLASTREWIRED}</YearTheBuildingWasLastReWired> <YearTheBuildingWasLastRePlumbed>{YEARLASTREPLUMBED}</YearTheBuildingWasLastRePlumbed> <YearTheBuildingWasLastReRoofed></YearTheBuildingWasLastReRoofed> <MainWallConstruction>{MAINWALLCONSTRUCTION_FINAL}</MainWallConstruction> <FloorConstruction>{FLOORCONSTRUCTION_FINAL}</FloorConstruction> <YearLastReWiredCalculation></YearLastReWiredCalculation> <WhatTypeOfAlarmSystemIsInstalled>{ALARMSYSTEMINSTALLED_FINAL}</WhatTypeOfAlarmSystemIsInstalled> <DoYouHaveSecurityCamerasOrCCTVInstalled></DoYouHaveSecurityCamerasOrCCTVInstalled> <IsThereATwoMeterHighPerimeterFenceEnclosingThePremises></IsThereATwoMeterHighPerimeterFenceEnclosingThePremises> <AreSecurityBollardsInPlace></AreSecurityBollardsInPlace> <AreYourPremisesPatrolledByASecurityGuard/> <AreDeadlocksInstalledOnAllExternalDoors>{DEADLOCKSINSTALLED_FINAL}</AreDeadlocksInstalledOnAllExternalDoors> <IsThereExteriorSecurityLighting/> <BarsOrGrillsInstalledOnAllWindows>{GRILLKEYLOCKINSTALLED_FINAL}</BarsOrGrillsInstalledOnAllWindows> <TwentyFourHoursAttendanceOnSite>0</TwentyFourHoursAttendanceOnSite> <SecurityMeasures>{SECURITYDETAILS}</SecurityMeasures> <WhatYearWasARiskAssessmentReviewLastUndertaken></WhatYearWasARiskAssessmentReviewLastUndertaken> <ConditionOfBuilding></ConditionOfBuilding> <ConditionOfRoof></ConditionOfRoof> <RoofConstructionAon/> <RoofSqmAon>0</RoofSqmAon> <LandSqm></LandSqm> <PropertyInputGeocodeURL/> <HomeBuildingOccupied>{HOWOCCUPPIED}</HomeBuildingOccupied> <InterestedPartyDescription>{INTERESTEDPARTY}</InterestedPartyDescription> </risk>'',
        ''AGGNE.DEV.PER_RISK_BUILDING_TARGET'',
        ''RISK_Building''
    );

    -- ── Seq 15: Motor Sub-Coverages (Risk_CM) → PER_COM_COVERAGES_TARGET ──
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_COM_COVERAGES'',
        ''<coverage> <Type>{TYPE}</Type> <limit> <Type>{TYPE}</Type> <iValue>{IVALUE}</iValue> </limit> <Indicator>1</Indicator> {SVALUE} <Code>{CODE}</Code> <Description>{DESCRIPTION}</Description> <Premium>{EXP_PREM}</Premium> </coverage>'',
        ''AGGNE.DEV.PER_COM_COVERAGES_TARGET'',
        ''Risk_CM''
    );

    -- ── Seq 16: PM Building UW → PER_COM_COVERAGES_TARGET ────
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_PM_BUILDING_UW'',
        ''<UnderwritingAdjustment> <Type>{COVERAGE}</Type> <AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection> <AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent> <AdjustmentAmount></AdjustmentAmount> <Recurring> <Indicator>{RECURRINGINDICATOR}</Indicator> </Recurring> <UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription> </UnderwritingAdjustment>'',
        ''AGGNE.DEV.PER_COM_COVERAGES_TARGET'',
        ''PER_PM_BUILDING_UW''
    );

    -- ── Seq 17: COM_CLAUSE → PER_COM_COVERAGES_TARGET ─────────
    -- Must run BEFORE seq 18 — PER_COM_PAYLOAD reads COM_CLAUSE rows
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.COM_CLAUSE'',
        ''<Clauses> <Type>Motor</Type> <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection> <SelectClauseDescription>{DCINPUT}</SelectClauseDescription> <IsClauseReadOnly>0</IsClauseReadOnly> <IsEditable>1</IsEditable> <Value>{DCINPUT}</Value> <DescriptionValue>{DCINPUT}</DescriptionValue> </Clauses>'',
        ''AGGNE.DEV.PER_COM_COVERAGES_TARGET'',
        ''COM_CLAUSE''
    );

    -- ── Seq 18: RISK_Building_PM (motor risk) → PER_COM_COVERAGES_TARGET ──
    -- Runs AFTER seq 17 (reads COM_CLAUSE rows from PER_COM_COVERAGES_TARGET)
    -- NOTE: {MVADDACCORMODS} used for WouldYouLikeToAddAccessoriesOrModifications
    --       (PP-CF-22 fix — SQL Server ConversionConfig has empty element, update it to match)
    -- NOTE: <Code>PM</Code> is correct (SQL Server confirmed PM, not CM)
    CALL AGGNE.DEV.DYNAMIC_XML_V1(
        ''AGGNE.DEV.PER_COM_PAYLOAD'',
        ''<risk> <Type>Motor</Type> <ExcessWaiverForGlass>{EXCESSWAIVERFORGLASS}</ExcessWaiverForGlass> <OnHookTowingProtection>0</OnHookTowingProtection> <VoluntaryExcess>{VOLUNTARYEXCESS}</VoluntaryExcess> <ProtectionType>{PROTECTIONTYPE}</ProtectionType> <HireVehicleExcess>0</HireVehicleExcess> <CourtesyVehicleExcess>0</CourtesyVehicleExcess> <ValueAccessoriesOption>2</ValueAccessoriesOption> <MarketValueWithoutAccessories>{MVVALUEWITHOUTACCESSORIES}</MarketValueWithoutAccessories> <ValueWithoutAccessories>{AVVALUEWITHOUTACCESSORIES}</ValueWithoutAccessories> <HireCourtesyDeliveryUse/> <UnlimitedGlass>1</UnlimitedGlass> <OnHook>0</OnHook> <DeliveryVehicleExcess>0</DeliveryVehicleExcess> <InterestedParties>{VEHHAVEANINTERESTEDPARTY}</InterestedParties> <InterestedPartiesAddress/> <InterestedPartiesName/> <IsVehicleImportedorNot>0</IsVehicleImportedorNot> <NonClaimDiscount>0</NonClaimDiscount> <LocationID/> <FleetType>Default</FleetType> <VehicleDetails>Vehicle 0</VehicleDetails> <GaragingPostcode/> <Usage/> <Performance/> <PrincipalOperator>Yes</PrincipalOperator> <Included>1</Included> <HighestValueVehicleinFleet>0</HighestValueVehicleinFleet> <MaximumOneVehiclePay>0</MaximumOneVehiclePay> <State>NSW</State> <Segment/> <PerformanceSafetyModifications>0</PerformanceSafetyModifications> <IsNonStandardAccessoriesIncludedinCover>0</IsNonStandardAccessoriesIncludedinCover> <CarHaveAnyModifications>0</CarHaveAnyModifications> <WindscreenExtFlag>0</WindscreenExtFlag> <Code>PM</Code> <ImportType>{IMPORTFLAG}</ImportType> <AddedHistoryID>2069</AddedHistoryID> <CommercialVehicleNumber>1</CommercialVehicleNumber> <coverage> <Type>CommercialVehicle</Type> <limit> <Type>CommercialVehicle</Type> <iValue>{MARKETVALUEWITHACCESSORIESAMOUNT}</iValue> </limit> <Indicator>1</Indicator> <ClassCode> <APRA>DMV</APRA> <Business>DMV</Business> </ClassCode> <Code>PM</Code> {SUBCOV} <Description>Commercial Motor</Description> <ExpiringPurePremium>0</ExpiringPurePremium> <ExpiringPremium>0</ExpiringPremium> <ClaimsIncurred>{PMCLMINCD}</ClaimsIncurred> <NumberOfClaims>{PMCLMCNT}</NumberOfClaims> <Premium>{PMEXPPREM}</Premium> </coverage> <HireCarHireAfterIncident>{HIRECARHIREAFTERINCIDENT}</HireCarHireAfterIncident> <CoverType/> <VehicleType>{VEHICLETYPE}</VehicleType> <VehicleInfoOverride>{OVERRIDE}</VehicleInfoOverride> <RegistrationNumber>{REGISTRATIONNUMBER}</RegistrationNumber> <VinNumber/> <Year>{YEAR}</Year> <RegoStatus>500</RegoStatus> <Make>{MAKE}</Make> <Model>{MODEL}</Model> <Description>{DESCRIPTION}</Description> <NightParkingLocation/> <NightParkingPostcode/> <DayParkingLocation/> <DayParkingPostcode/> <SecurityType/> <FinanceType/> <DateOfPurchase/> <AnnualMileage/> <CoverValue/> <Excess> <LessThanAge20/> <Age20To21/> <Age22To25/> </Excess> <NonStandardAccessories/> <NonStandardAccessoriesSumInsured/> <ModificationType/> <ModificationSumInsured/> <TotalSumInsured>0</TotalSumInsured> <LocationDescription>Primary Location</LocationDescription> <VehicleFullDescription>{DESCRIPTION} </VehicleFullDescription> <BodyType>{BODYTYPE}</BodyType> <EngineSize>{ENGINESIZE}</EngineSize> <NumberOfCylinders>{NUMBEROFCYLINDERS}</NumberOfCylinders> <DriveDescription>{DRIVEDESCRIPTION}</DriveDescription> <InductionType>{INDUCTIONTYPE}</InductionType> <GrossVehicleMass>{GROSSVEHICLEMASS}</GrossVehicleMass> <WouldYouLikeToAddAccessoriesOrModifications>{MVADDACCORMODS}</WouldYouLikeToAddAccessoriesOrModifications> <AgreedValueAmount>{AGREEDVALUEAMOUNT}</AgreedValueAmount> <AgreedValueDescription/> <AgreedValueDescriptionValue/> <MarketValueDescription>{MARKETVALUEDESCRIPTION}</MarketValueDescription> <WouldYouLikeToAddAccessoriesOrModificationsMarket>{MVADDACCORMODS}</WouldYouLikeToAddAccessoriesOrModificationsMarket> <MarketValueDescriptionValue>{MARKETVALUEDESCRIPTIONVALUE}</MarketValueDescriptionValue> <MarketValueWithAccessories>{MARKETVALUEWITHACCESSORIESAMOUNT}</MarketValueWithAccessories> <HighestRiskUse/> <AgeOfYoungestRegularDriver>{AGEOFYOUNGESTREGULARDRIVER}</AgeOfYoungestRegularDriver> <RestrictionOfDriverAge>{RESTRICTIONOFDRIVERAGE}</RestrictionOfDriverAge> <DoesTheVehicleHaveAnInterestedParty>{VEHHAVEANINTERESTEDPARTY}</DoesTheVehicleHaveAnInterestedParty> <AddDetailsForTheInterestedParty>{ADDDETAILSFORTHEINTERESTEDPARTY}</AddDetailsForTheInterestedParty> <HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime/> <HowOftenDoYouPickUpOrDeliverVehicles/> <ChoiceOfRepair>{CHOICEOFREPAIR}</ChoiceOfRepair> <WhatIsTheTypicalRadiusOfTravelFromTheBaseLocation/> <WillTheVehicleTransportMotorVehiclesOrTheMembersGeneralProperty/> <AreAnyVehiclesDriverSuppliedPM/> <Details/> <IsThisVehicleUsedForRideShareOperation/> <AreHireContractsRestrictedToNamedDriversOnly/> <AreAnyVehiclesDriverSupplied/> <WillAnyContractorsOperateThisVehicle/> <WillThisVehicleBeUsedToDeliverDangerousGoods/> <StandardExcess/> <ImposedExcess/> <OnHookExcess/> <UWAdjustmentTotal/> <MarketValue/> <NumberofVehicles/> <TotalValueofNonStandard/> <GeneralBusinessUse/> <CarHire/> <HowManyOfYourVehiclesMayRequireOnHook/> <DoAnyOfYourVehiclesHaveATaxiRegistration/> <DoesTheMemberOwnAnyOtherBusinesses/> <WhereAreIdleVehiclesStored/> <DetailsOfVehicleLocationRiskMitigation/> <AreAnyVehiclesHiredOutForRideShareOperations/> <WhatPercentOfTheFleetIsHiredOutToRideShareOperators/> <HowManyYearsExperienceDoesThisMemberHaveOperatingAHireFleet/> <AreContractorsEmployedAsDrivers/> <AreAnyVehiclesUsedToDeliverDangerousGoods/> <HowManyYearsExperienceDoesThisMemberHaveOperatingADeliveryFleet/> <HowOftenIsTheVehicleUsed/> <IsTheVehicleUsedForMembersBusinessNeedsOnly/> <IsTheVehicleUsedForMembersBusinessNeedsOnlyDetails/> <VehicleTransportHazardousDangerousGoods/> <VehicleTransportHazardousDangerousGoodsDetails/> <IsTheVehicleUsedToTransportAnyCustomerItemsReward/> <IsTheVehicleUsedToTransportAnyCustomerItemsRewardDetails/> <MaximumRangeVehicleWillTravelBusinessUse/> <IsTheVehicleDrivenByDirectEmployeesOnly/> <IsTheVehicleDrivenByDirectEmployeesOnlyDetails/> <IfPrimeMoverWillItTowMoreThan1TrailerAtTime/> <IfPrimeMoverWillItTowMoreThan1TrailerAtTimeDetails/> <MakeOther/> <ModelOther/> <MakeID/> <FamilyID/> <RedbookCode>{MVRBVEHICLEKEY}</RedbookCode> <RedBookStatus/> <FuelType/> <TrackRear/> <PowerKW>0</PowerKW> <BuildingID/> <OccupancyID/> {COM_CLAUSE} {UW} </risk>'',
        ''AGGNE.DEV.PER_COM_COVERAGES_TARGET'',
        ''RISK_Building_PM''
    );

END IF;
-- ═══════════════════════════════════════════════════════════
-- PHASE 2: Final Load → Final XML
-- PP_RUN_CONTROL: empty = all policies; populated = listed only
-- ═══════════════════════════════════════════════════════════
CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();

RETURN ''Done — '' || CASE WHEN P_RELOAD_ALL_SEQS THEN ''full reload (all 18 seqs + final)'' ELSE ''final only (skip seqs)'' END;

END;
';

-- ── Verify after applying ──────────────────────────────────────────────────
-- SELECT GET_DDL('PROCEDURE', 'AGGNE.DEV.PP_CONVERSION_RUN(BOOLEAN)');
-- -- confirm it now contains '<APRA>FISR</APRA>' / '<Business>BSP</Business>' (both seq 7 and
-- -- seq 13 occurrences) and '<HomeContentsTotal></HomeContentsTotal>' /
-- -- '<SpecifiedContentsTotal></SpecifiedContentsTotal>'
