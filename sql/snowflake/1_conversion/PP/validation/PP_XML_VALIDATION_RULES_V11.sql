-- ============================================================
-- PP XML Validation Rules — v1.1  (PL101 full extract)
-- Schema  : AGGNE.DEV
-- Purpose : Adds 108 new fields from all PP PL101 sections.
--           Run this AFTER PP_XML_VALIDATION_SETUP.sql.
--
-- New coverage (beyond v1.0):
--   RISK_Building   — BuildingRiskSMEInput (26), BuildingRiskClausesInput (4),
--                     SituationDetailsInput (1), ConstructionOfBuildingInput (3),
--                     SecurityDetailsInput (1)
--   RISK_Building_HC — ContentsAndStocksInput (44), HomeContentsClausesInput (4),
--                      HomeContentsInput (2), SpecifiedContentsInput (2)
--   RISK_Building_PM — VehicleInput (13 new beyond v1.0),
--                      CommercialVehicleClausesInput (2), CommercialVehicleInput (1)
--   POLICY           — PolicyInput (2), LineInput (3)
--
--   Enum fields (VALID_VALUES set)  : 34
--   Free-text / numeric             : 74
--   Total new rules                 : 108
--
-- To remove v1.1 rules: DELETE FROM AGGNE.DEV.PP_XML_VALIDATION_RULES WHERE RULE_VERSION = '1.1';
-- ============================================================

-- ── Enum fields (34 rules with dropdown validation) ──────────────────────────

INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT ver, field_name, xml_tag, payload_type, is_required, PARSE_JSON(valid_json), notes
FROM (
    SELECT '1.1' AS ver, 'Product' AS field_name, 'Product' AS xml_tag,
           'POLICY' AS payload_type, FALSE AS is_required,
           '["Carrier_Product_CW_01", "DuckCreekTech_Product_CW_01"]' AS valid_json,
           'PL101 No. Section: PolicyInput. Caption: Product.' AS notes
    UNION ALL
    SELECT '1.1', 'LineOfBusiness', 'LineOfBusiness',
           'POLICY', FALSE,
           '["PersonalPackage"]',
           'PL101 No. Section: PolicyInput. Caption: Line of Business.'
    UNION ALL
    SELECT '1.1', 'ExcessWaiverForGlass', 'ExcessWaiverForGlass',
           'RISK_Building_PM', FALSE,
           '["0", "1"]',
           'PL101 No. Section: VehicleInput. Caption: Glass.'
    UNION ALL
    SELECT '1.1', 'Excess/Voluntary', 'Excess/Voluntary',
           'RISK_Building_PM', FALSE,
           '["0", "1000", "1250", "1500", "250", "500", "750"]',
           'PL101 No. Section: VehicleInput. Caption: Voluntary Excess.'
    UNION ALL
    SELECT '1.1', 'ChoiceOfRepair', 'ChoiceOfRepair',
           'RISK_Building_PM', FALSE,
           '["0", "1"]',
           'PL101 Conditional. Section: VehicleInput. Caption: COR.'
    UNION ALL
    SELECT '1.1', 'HireCarHireAfterIncident', 'HireCarHireAfterIncident',
           'RISK_Building_PM', FALSE,
           '["NotTaken", "Taken"]',
           'PL101 Conditional. Section: VehicleInput. Caption: Hire.'
    UNION ALL
    SELECT '1.1', 'RestrictionOfDriverAge', 'RestrictionOfDriverAge',
           'RISK_Building_PM', FALSE,
           '["0", "20", "24", "29", "39"]',
           'PL101 Conditional. Section: VehicleInput. Caption: Restriction of driver age.'
    UNION ALL
    SELECT '1.1', 'WouldYouLikeToAddAccessoriesOrModifications', 'WouldYouLikeToAddAccessoriesOrModifications',
           'RISK_Building_PM', TRUE,
           '["No", "Yes"]',
           'PL101 Yes. Section: VehicleInput. Caption: Would you like to add accessories or modifications.'
    UNION ALL
    SELECT '1.1', 'WouldYouLikeToAddAccessoriesOrModificationsMarket', 'WouldYouLikeToAddAccessoriesOrModificationsMarket',
           'RISK_Building_PM', TRUE,
           '["No", "Yes"]',
           'PL101 Yes. Section: VehicleInput. Caption: Would you like to add accessories or modifications (market).'
    UNION ALL
    SELECT '1.1', 'DoesTheVehicleHaveAnInterestedParty', 'DoesTheVehicleHaveAnInterestedParty',
           'RISK_Building_PM', TRUE,
           '["0", "1"]',
           'PL101 Yes. Section: VehicleInput. Caption: Does the Vehicle have an interested Party?'
    UNION ALL
    SELECT '1.1', 'HighestRiskUse', 'HighestRiskUse',
           'RISK_Building_PM', FALSE,
           '["Business", "Courtesy", "Delivery", "Hire"]',
           'PL101 No. Section: VehicleInput. Caption: Highest Risk Use.'
    UNION ALL
    SELECT '1.1', 'CommercialVehicleClausesType', 'Type',
           'RISK_Building_PM', FALSE,
           '["AgeRestrictionOverride","CMAdditionalBenefitFourIncrease","CMAdditionalBenefitTenIncrease","CMAdditionalBenefitTwelveIncrease","CMF&TOnlyLiabilityExtension","CMGeneralExclusionOD","CMGeneralExclusionPL","CMHireUnderExtension","CMLearnerExtension","CM_C01_LEARNER","CM_C03_NOAR","CM_C04_EFF_DATE","CM_C05_HVNOAR","CM_C06_MODSACCS","CM_C07_ADDBENEXT","CM_C08_RISKEXT","CM_C09_RISKEXC","CM_C10_FTLIAB","CM_C11_EXCESS","EntityLimitation","FVAlreadyProtected","FVForkliftTPExclusion","FVGeneralExclusionOD","FVGeneralExclusionPL","FVMaxValue","PMAVCaravancontents","PMAdditionalbenefit11increase","PMAdditionalbenefit12increase","PMAdditionalbenefit4increase","PMAdditionalbenefit7increase","PMGeneralexclusionliability","PMGeneralexclusionproperty","PMGeneralextension","PMLearnerextension","PMMVCaravancontents","UsageRestriction"]',
           'PL101 No. Section: CommercialVehicleClausesInput. Caption: Select Clause.'
    UNION ALL
    -- Building — coverage/clause enum fields
    SELECT '1.1', 'coverage[BAD_SD]/sValue', 'coverage[Type="BAD_SD"]/sValue',
           'RISK_Building', TRUE,
           '["NotTaken", "Taken"]',
           'PL101 Yes. Section: BuildingRiskSMEInput. Caption: Accidental Loss Or Damage.'
    UNION ALL
    SELECT '1.1', 'coverage[LLB_SD]/sValue', 'coverage[Type="LLB_SD"]/sValue',
           'RISK_Building', TRUE,
           '["NotTaken", "Taken"]',
           'PL101 Yes. Section: BuildingRiskSMEInput. Caption: Landlord Protections.'
    UNION ALL
    SELECT '1.1', 'MinimumRentalPeriod', 'MinimumRentalPeriod',
           'RISK_Building', TRUE,
           '["Lessthan90Days", "Morethan90Days"]',
           'PL101 Yes. Section: BuildingRiskSMEInput. Caption: Minimum Rental Period.'
    UNION ALL
    SELECT '1.1', 'Excess/Voluntary_Building', 'Excess/Voluntary',
           'RISK_Building', FALSE,
           '["0", "1000", "1500", "2000", "2500", "300", "500"]',
           'PL101 No. Section: BuildingRiskSMEInput. Caption: Voluntary Excess.'
    UNION ALL
    SELECT '1.1', 'coverage[BAD_SD]/limit/iValue', 'coverage[Type="BAD_SD"]/limit[Type="BAD_SD"]/iValue',
           'RISK_Building', TRUE,
           '["0", "10000", "15000", "20000", "5000"]',
           'PL101 Yes. Section: BuildingRiskSMEInput. Caption: Accidental Loss or Damage Limit.'
    UNION ALL
    SELECT '1.1', 'FixedGlass', 'FixedGlass',
           'RISK_Building', TRUE,
           '["15", "25", "35", "45", "5"]',
           'PL101 Yes. Section: BuildingRiskSMEInput. Caption: Fixed Glass (Area Sq.).'
    UNION ALL
    SELECT '1.1', 'Glass', 'Glass',
           'RISK_Building', TRUE,
           '["NotTaken", "Taken"]',
           'PL101 Yes. Section: BuildingRiskSMEInput. Caption: Glass.'
    UNION ALL
    SELECT '1.1', 'coverage[BFL_SD]/sValue', 'coverage[Type="BFL_SD"]/sValue',
           'RISK_Building', TRUE,
           '["NotTaken", "Taken"]',
           'PL101 Yes. Section: BuildingRiskSMEInput. Caption: Flood Damage.'
    UNION ALL
    SELECT '1.1', 'BuildingRiskClausesType', 'Type',
           'RISK_Building', FALSE,
           '["HBAdditionalbenefitincreasePartB8","HBAdditionalbenefitincreasePartB9","HBDefinitionlimitation","HBDomesticliability","HBExcessfreeglassclaims","HBInclusionofjetty","HBRetainingwallsextension","HBSolarcellsextension","HBUnattendedbuilding"]',
           'PL101 No. Section: BuildingRiskClausesInput. Caption: Select Clause.'
    UNION ALL
    -- Home Contents enum fields
    SELECT '1.1', 'HomeContentsLimits', 'HomeContentsLimits',
           'RISK_Building_HC', FALSE,
           '["No", "Yes"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Home contents with fixed limits?'
    UNION ALL
    SELECT '1.1', 'coverage[CAD_SD]/sValue', 'coverage[Type="CAD_SD"]/sValue',
           'RISK_Building_HC', TRUE,
           '["NotTaken", "Taken"]',
           'PL101 Yes. Section: ContentsAndStocksInput. Caption: Accidental Loss Or Damage.'
    UNION ALL
    SELECT '1.1', 'coverage[SPE_SD]/sValue', 'coverage[Type="SPE_SD"]/sValue',
           'RISK_Building_HC', FALSE,
           '["No", "Yes"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Specified Items Away from the Premises.'
    UNION ALL
    SELECT '1.1', 'coverage[POR_SD]/sValue', 'coverage[Type="POR_SD"]/sValue',
           'RISK_Building_HC', FALSE,
           '["No", "Yes"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Unspecified Items Away from the Premises.'
    UNION ALL
    SELECT '1.1', 'UnspecifiedItemsAwayPremisesLimit', 'UnspecifiedItemsAwayPremisesLimit',
           'RISK_Building_HC', FALSE,
           '["1250peritemupto5000perevent", "2000peritemupto10000perevent"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Unspecified Items Away from the Premises Limit.'
    UNION ALL
    SELECT '1.1', 'coverage[CAD_SD]/limit/iValue', 'coverage[Type="CAD_SD"]/limit[Type="CAD_SD"]/iValue',
           'RISK_Building_HC', TRUE,
           '["10000", "15000", "20000", "5000"]',
           'PL101 Yes. Section: ContentsAndStocksInput. Caption: Accidental Loss or Damage Limit.'
    UNION ALL
    SELECT '1.1', 'Excess/Voluntary_HC', 'Excess/Voluntary',
           'RISK_Building_HC', FALSE,
           '["0", "1000", "1500", "2000", "2500", "300", "500"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Voluntary Excess.'
    UNION ALL
    SELECT '1.1', 'SpecifiedItemsAwayPremisesLimit', 'SpecifiedItemsAwayPremisesLimit',
           'RISK_Building_HC', FALSE,
           '["0", "1"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Specified Items Away from the Premises.'
    UNION ALL
    SELECT '1.1', 'Excess/Amount', 'Excess/Amount',
           'RISK_Building_HC', FALSE,
           '["100", "1000", "2000", "250", "500", "5000", "750", "7500"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Contents & Stock Excess Amount.'
    UNION ALL
    SELECT '1.1', 'Excess/Hail', 'Excess/Hail',
           'RISK_Building_HC', FALSE,
           '["1000"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Hail Damage to Stock Vehicles/Watercraft (per Vehicle).'
    UNION ALL
    SELECT '1.1', 'MaliciousDamagetoStockCustomerVehiclesWatercraft', 'MaliciousDamagetoStockCustomerVehiclesWatercraft',
           'RISK_Building_HC', FALSE,
           '["1000"]',
           'PL101 No. Section: ContentsAndStocksInput. Caption: Malicious Damage to Stock/Customer Vehicles/Watercraft (per Vehicle).'
    UNION ALL
    SELECT '1.1', 'coverage[CFL_SD]/sValue', 'coverage[Type="CFL_SD"]/sValue',
           'RISK_Building_HC', TRUE,
           '["NotTaken", "Taken"]',
           'PL101 Yes. Section: ContentsAndStocksInput. Caption: Flood Damage.'
    UNION ALL
    SELECT '1.1', 'HomeContentsClausesType', 'Type',
           'RISK_Building_HC', FALSE,
           '["HCAdditionalbenefitincreasePartA4","HCDefinitionextension","HCSpecifieditems15k","HCUnattendedcontents"]',
           'PL101 No. Section: HomeContentsClausesInput. Caption: Select Clause.'
);

-- ── Free-text / numeric fields (74 rules, no enum restriction) ────────────────

INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT '1.1', field_name, xml_tag, payload_type, is_required, NULL, notes
FROM (
    -- POLICY
    SELECT 'Indicators[Selected]/bValue'        AS field_name,
           'Indicators[Type="Selected"]/bValue' AS xml_tag,
           'POLICY'                              AS payload_type,
           FALSE                                 AS is_required,
           'PL101 No. Section: LineInput. Type: boolean. Caption: Select.'  AS notes
    UNION ALL
    SELECT 'Excess[PPLPPCV]/Standard',
           'Excess[Type="PPLPPCV"]/Standard',
           'POLICY', FALSE,
           'PL101 No. Section: LineInput. Type: int. Caption: Standard Excess.'
    UNION ALL
    SELECT 'Excess[GPGTLETA]/Standard',
           'Excess[Type="GPGTLETA"]/Standard',
           'POLICY', FALSE,
           'PL101 No. Section: LineInput. Type: int. Caption: Standard Excess.'
    UNION ALL
    -- RISK_Building_PM
    SELECT 'RegistrationNumber', 'RegistrationNumber', 'RISK_Building_PM', FALSE,
           'PL101 Conditional. Section: VehicleInput. Type: string. Caption: Registration Number.'
    UNION ALL
    SELECT 'MakeOther', 'MakeOther', 'RISK_Building_PM', FALSE,
           'PL101 No. Section: VehicleInput. Type: string. Caption: Other Make, please Specify.'
    UNION ALL
    SELECT 'Excess/Standard_PM', 'Excess/Standard', 'RISK_Building_PM', FALSE,
           'PL101 No. Section: VehicleInput. Type: int. Caption: Standard Excess.'
    UNION ALL
    SELECT 'MarketValue', 'MarketValue', 'RISK_Building_PM', FALSE,
           'PL101 No. Section: VehicleInput. Type: float. Caption: Market Value.'
    UNION ALL
    SELECT 'CommercialVehicleClausesDescription', 'Description', 'RISK_Building_PM', FALSE,
           'PL101 No. Section: CommercialVehicleClausesInput. Type: string. Caption: Description.'
    UNION ALL
    SELECT 'limit[PersonalMotor]/iValue',
           'limit[Type="PersonalMotor"]/iValue',
           'RISK_Building_PM', FALSE,
           'PL101 No. Section: CommercialVehicleInput. Type: int. Caption: Limit.'
    UNION ALL
    -- RISK_Building
    SELECT 'coverage[BLD_SD]/limit/iValue',
           'coverage[Type="BLD_SD"]/limit[Type="BLD_SD"]/iValue',
           'RISK_Building', TRUE,
           'PL101 Yes. Section: BuildingRiskSMEInput. Type: int. Caption: Home Buildings Limit.'
    UNION ALL
    SELECT 'WeeklyRent', 'WeeklyRent', 'RISK_Building', TRUE,
           'PL101 Yes. Section: BuildingRiskSMEInput. Type: int. Caption: Weekly Rent.'
    UNION ALL
    SELECT 'coverage[BLD_BF]/limit/iValue',
           'coverage[Type="BLD_BF"]/limit[Type="BLD_BF"]/iValue',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Business Buildings Flood Limit.'
    UNION ALL
    SELECT 'coverage[BLD_CY]/limit/iValue',
           'coverage[Type="BLD_CY"]/limit[Type="BLD_CY"]/iValue',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Business Buildings Cyclone Limit.'
    UNION ALL
    SELECT 'coverage[BLD_EQ]/limit/iValue',
           'coverage[Type="BLD_EQ"]/limit[Type="BLD_EQ"]/iValue',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Business Buildings Earthquake Limit.'
    UNION ALL
    SELECT 'coverage[BLD_ST]/limit/iValue',
           'coverage[Type="BLD_ST"]/limit[Type="BLD_ST"]/iValue',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Business Buildings Storm Limit.'
    UNION ALL
    SELECT 'coverage[BFL_SD]/limit/iValue',
           'coverage[Type="BFL_SD"]/limit[Type="BFL_SD"]/iValue',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Flood Damage Limit.'
    UNION ALL
    SELECT 'BusinessBuildingsLandSlideLimit', 'BusinessBuildingsLandSlideLimit', 'RISK_Building', TRUE,
           'PL101 Yes. Section: BuildingRiskSMEInput. Type: int. Caption: Business Buildings Land Slide Limit.'
    UNION ALL
    SELECT 'LossOfRentLimit', 'LossOfRentLimit', 'RISK_Building', TRUE,
           'PL101 Yes. Section: BuildingRiskSMEInput. Type: int. Caption: Loss of Rent Limit.'
    UNION ALL
    SELECT 'coverage[BLI_SD]/limit/iValue',
           'coverage[Type="BLI_SD"]/limit[Type="BLI_SD"]/iValue',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Liability Limit.'
    UNION ALL
    SELECT 'coverage[LLB_SD]/limit/iValue',
           'coverage[Type="LLB_SD"]/limit[Type="LLB_SD"]/iValue',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Landlord Protection Limit.'
    UNION ALL
    SELECT 'Excess/Imposed', 'Excess/Imposed', 'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Imposed Excess.'
    UNION ALL
    SELECT 'coverage[BFL_SD]/Indicator',
           'coverage[Type="BFL_SD"]/Indicator',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: boolean. Caption: Flood Damage Indicator.'
    UNION ALL
    SELECT 'coverage[LLB_SD]/Indicator',
           'coverage[Type="LLB_SD"]/Indicator',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: boolean. Caption: Landlord Protections Indicator.'
    UNION ALL
    SELECT 'Excess/Standard_Building', 'Excess/Standard', 'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Standard Excess.'
    UNION ALL
    SELECT 'GlassIndicator', 'GlassIndicator', 'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: boolean. Caption: Glass Indicator.'
    UNION ALL
    SELECT 'coverage[BFL_SD]/@termDateAdded',
           'coverage[Type="BFL_SD"]/@termDateAdded',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: string. Caption: Flood Damage Term Date Added.'
    UNION ALL
    SELECT 'limit[LegalLiability_Bld]/iValue',
           'limit[Type="LegalLiability"]/iValue',
           'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskSMEInput. Type: int. Caption: Legal Liability Limit.'
    UNION ALL
    SELECT 'BuildingRiskClausesStaticDescription', 'StaticDescription', 'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskClausesInput. Type: string. Caption: Description.'
    UNION ALL
    SELECT 'BuildingRiskClausesValue', 'Value', 'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskClausesInput. Type: string. Caption: Values.'
    UNION ALL
    SELECT 'BuildingRiskClausesDescription', 'Description', 'RISK_Building', FALSE,
           'PL101 No. Section: BuildingRiskClausesInput. Type: string. Caption: Description.'
    UNION ALL
    SELECT 'NumberOfStories', 'NumberOfStories', 'RISK_Building', FALSE,
           'PL101 No. Section: SituationDetailsInput. Type: int. Caption: Number of stories.'
    UNION ALL
    SELECT 'YearTheBuildingWasLastReWired', 'YearTheBuildingWasLastReWired', 'RISK_Building', FALSE,
           'PL101 No. Section: ConstructionOfBuildingInput. Type: int. Caption: Year the building was last re-wired.'
    UNION ALL
    SELECT 'YearTheBuildingWasLastReRoofed', 'YearTheBuildingWasLastReRoofed', 'RISK_Building', FALSE,
           'PL101 No. Section: ConstructionOfBuildingInput. Type: int. Caption: Year the building was last re-roofed.'
    UNION ALL
    SELECT 'YearTheBuildingWasLastRePlumbed', 'YearTheBuildingWasLastRePlumbed', 'RISK_Building', FALSE,
           'PL101 No. Section: ConstructionOfBuildingInput. Type: int. Caption: Year the building was last re-plumbed.'
    UNION ALL
    SELECT 'SecurityMeasures', 'SecurityMeasures', 'RISK_Building', FALSE,
           'PL101 No. Section: SecurityDetailsInput. Type: string. Caption: Please list any other security measures.'
    UNION ALL
    -- RISK_Building_HC
    SELECT 'coverage[CNT_SD]/limit/iValue',
           'coverage[Type="CNT_SD"]/limit[Type="CNT_SD"]/iValue',
           'RISK_Building_HC', TRUE,
           'PL101 Yes. Section: ContentsAndStocksInput. Type: int. Caption: Home Contents Limit.'
    UNION ALL
    SELECT 'coverage[CNT_BF]/limit/iValue',
           'coverage[Type="CNT_BF"]/limit[Type="CNT_BF"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Bushfire Limit.'
    UNION ALL
    SELECT 'coverage[CNT_CY]/limit/iValue',
           'coverage[Type="CNT_CY"]/limit[Type="CNT_CY"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Cyclone Limit.'
    UNION ALL
    SELECT 'coverage[CNT_EQ]/limit/iValue',
           'coverage[Type="CNT_EQ"]/limit[Type="CNT_EQ"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Earthquake Limit.'
    UNION ALL
    SELECT 'coverage[CFL_SD]/limit/iValue',
           'coverage[Type="CFL_SD"]/limit[Type="CFL_SD"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Flood Damage Limit.'
    UNION ALL
    SELECT 'coverage[CNT_ST]/limit/iValue',
           'coverage[Type="CNT_ST"]/limit[Type="CNT_ST"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Storm Limit.'
    UNION ALL
    SELECT 'WatercraftInStockUnder8mLimit', 'WatercraftInStockUnder8mLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Watercraft in Stock under 8m Limit.'
    UNION ALL
    SELECT 'VehiclesInStockLimit', 'VehiclesInStockLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Vehicles in Stock Limit.'
    UNION ALL
    SELECT 'StockLimitExcludingVehiclesWatercraft', 'StockLimitExcludingVehiclesWatercraft', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Stock Limit excluding vehicles/watercraft.'
    UNION ALL
    SELECT 'PersonalEffectsLimit', 'PersonalEffectsLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Personal Effects Limit (if > $5,000).'
    UNION ALL
    SELECT 'MotorFuelsLimit', 'MotorFuelsLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Motor Fuels Limit.'
    UNION ALL
    SELECT 'HandToolsLimit', 'HandToolsLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Hand Tools Limit.'
    UNION ALL
    SELECT 'HailDamagetoVehiclesorWatercraftsInStockLimitStandard',
           'HailDamagetoVehiclesorWatercraftsInStockLimitStandard',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Hail Damage to Vehicles/Watercraft in Stock (standard).'
    UNION ALL
    SELECT 'HailDamagetoVehiclesorWatercraftsInStockLimit',
           'HailDamagetoVehiclesorWatercraftsInStockLimit',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Hail Damage to Vehicles/Watercraft in Stock Limit.'
    UNION ALL
    SELECT 'EmployeeToolsofTradeLimit', 'EmployeeToolsofTradeLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Employee Tools of Trade Limit (if > $10,000).'
    UNION ALL
    SELECT 'CustomersWatercraftUnder8mLimit', 'CustomersWatercraftUnder8mLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Customer''s Watercraft under 8m Limit.'
    UNION ALL
    SELECT 'CustomersVehiclesLimit', 'CustomersVehiclesLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Customer''s Vehicles Limit.'
    UNION ALL
    SELECT 'ContentsAndStocksLandSlideLimit', 'ContentsAndStocksLandSlideLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Contents And Stocks Land Slide Limit.'
    UNION ALL
    SELECT 'coverage[SPE_SD]/limit/iValue',
           'coverage[Type="SPE_SD"]/limit[Type="SPE_SD"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Specified Items Limit.'
    UNION ALL
    SELECT 'coverage[POR_SD]/limit/iValue',
           'coverage[Type="POR_SD"]/limit[Type="POR_SD"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Unspecified Items Limit.'
    UNION ALL
    SELECT 'coverage[CLI_SD]/limit/iValue',
           'coverage[Type="CLI_SD"]/limit[Type="CLI_SD"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Contents Liability Limit.'
    UNION ALL
    SELECT 'LandSlideLimit', 'LandSlideLimit', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Landslide Limit.'
    UNION ALL
    SELECT 'WhatProportionOfTheLotIsCoveredByHailNetting',
           'WhatProportionOfTheLotIsCoveredByHailNetting',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Proportion of lot covered by hail netting (%).'
    UNION ALL
    SELECT 'StandardPerilIndicator', 'StandardPerilIndicator', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: boolean. Caption: Standard Peril Indicator.'
    UNION ALL
    SELECT 'coverage[CFL_SD]/Indicator',
           'coverage[Type="CFL_SD"]/Indicator',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: boolean. Caption: Flood Damage Indicator.'
    UNION ALL
    SELECT 'coverage[POR_SD]/Indicator',
           'coverage[Type="POR_SD"]/Indicator',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: boolean. Caption: Unspecified Items Away from the Premises indicator.'
    UNION ALL
    SELECT 'coverage[SPE_SD]/Indicator',
           'coverage[Type="SPE_SD"]/Indicator',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: boolean. Caption: Specified Items Away from the Premises indicator.'
    UNION ALL
    SELECT 'SpecifiedContentsAtThePremises', 'SpecifiedContentsAtThePremises', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: string. Caption: Specified Contents at the premises.'
    UNION ALL
    SELECT 'SpecifiedContentsAwayFromThePremises', 'SpecifiedContentsAwayFromThePremises', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: string. Caption: Specified Contents items away from the premises details.'
    UNION ALL
    SELECT 'coverage[CFL_SD]/@termDateAdded',
           'coverage[Type="CFL_SD"]/@termDateAdded',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: string. Caption: Flood Damage Term Date Added.'
    UNION ALL
    SELECT 'Excess/Earthquake', 'Excess/Earthquake', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Earthquake Excess.'
    UNION ALL
    SELECT 'limit[LegalLiability_HC]/iValue',
           'limit[Type="LegalLiability"]/iValue',
           'RISK_Building_HC', FALSE,
           'PL101 No. Section: ContentsAndStocksInput. Type: int. Caption: Legal Liability Limit.'
    UNION ALL
    SELECT 'HomeContentsDescription', 'Description', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: HomeContentsInput. Type: string. Caption: Description.'
    UNION ALL
    SELECT 'HomeContentsValue', 'Value', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: HomeContentsInput. Type: int. Caption: Value.'
    UNION ALL
    SELECT 'SpecifiedContentsDescription', 'Description', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: SpecifiedContentsInput. Type: string. Caption: Description.'
    UNION ALL
    SELECT 'SpecifiedContentsValue', 'Value', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: SpecifiedContentsInput. Type: int. Caption: Value.'
    UNION ALL
    SELECT 'HomeContentsClausesStaticDescription', 'StaticDescription', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: HomeContentsClausesInput. Type: string. Caption: Description.'
    UNION ALL
    SELECT 'HomeContentsClausesDescription', 'Description', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: HomeContentsClausesInput. Type: string. Caption: Description With Value.'
    UNION ALL
    SELECT 'HomeContentsClausesValue', 'Value', 'RISK_Building_HC', FALSE,
           'PL101 No. Section: HomeContentsClausesInput. Type: string. Caption: Values.'
);

-- ── Verify ───────────────────────────────────────────────────────────────────

SELECT RULE_VERSION,
       PAYLOAD_TYPE,
       COUNT(*)                                     AS RULE_COUNT,
       SUM(CASE WHEN IS_REQUIRED THEN 1 ELSE 0 END) AS REQUIRED_COUNT,
       SUM(CASE WHEN VALID_VALUES IS NOT NULL
                THEN 1 ELSE 0 END)                  AS ENUM_COUNT
FROM   AGGNE.DEV.PP_XML_VALIDATION_RULES
WHERE  ACTIVE = TRUE
GROUP  BY RULE_VERSION, PAYLOAD_TYPE
ORDER  BY RULE_VERSION, PAYLOAD_TYPE;
