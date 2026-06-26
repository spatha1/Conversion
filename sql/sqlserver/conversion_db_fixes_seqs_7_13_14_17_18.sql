-- ===========================================================================
-- CONVERSION DB: PP_ConversionConfig fixes for seqs 7, 13, 14, 17, 18
-- Run against: CONVERSION DB (dbo.PP_ConversionConfig)
-- SAFE_MODE: Run VERIFY queries first; then UPDATE queries
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- SEQ 7: Full template replacement (removes {IMPOSEDEXCESS}/{FLOODEXCESS}/{EARTHQUAKEEXCESS}/{FLOODDAMAGE})
-- NOTE: Template still contains tokens with no matching view column:
--   {HB_CLAUSE} -- NOT a column in PER_HOME_BUILDING_PAYLOAD; will stay as token unless column added to view
-- These need PER_HOME_BUILDING_PAYLOAD view update OR token removal (see separate task)
-- ---------------------------------------------------------------------------
-- VERIFY: check current CONVERSION DB template begins with expected content
SELECT SUBSTRING(ConversionScript, 1, 150) AS preview, LEN(ConversionScript) AS len
FROM dbo.PP_ConversionConfig WHERE SequenceID=7 AND IsActive=1;

-- UPDATE seq 7:
UPDATE dbo.PP_ConversionConfig SET ConversionScript = '<coverage>
	<Type>Building</Type>
	<Excess>
		<Amount/>
		<Imposed/>
		<Flood/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Earthquake/>
		<Standard/>
		<Glass/>
	</Excess>     {SUBCOV}  <SetExcessAmount>0</SetExcessAmount>
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
</coverage>'
WHERE SequenceID=7 AND IsActive=1;

-- ---------------------------------------------------------------------------
-- SEQ 13: Full template replacement (removes {IMPOSEDEXCESS}/{FLOODEXCESS}/{EARTHQUAKEEXCESS}/{FLOODDAMAGE})
-- NOTE: Template still contains tokens with no matching view column:
--   {clauses} -- lowercase AND not a column in PER_HOME_BUILDING_PAYLOAD; will stay as token
--   {UW} -- NOT a column in PER_HOME_BUILDING_PAYLOAD; will stay as token
-- These need PER_HOME_BUILDING_PAYLOAD view update OR token removal (see separate task)
-- ---------------------------------------------------------------------------
-- VERIFY: check current CONVERSION DB template begins with expected content
SELECT SUBSTRING(ConversionScript, 1, 150) AS preview, LEN(ConversionScript) AS len
FROM dbo.PP_ConversionConfig WHERE SequenceID=13 AND IsActive=1;

-- UPDATE seq 13:
UPDATE dbo.PP_ConversionConfig SET ConversionScript = '<coverage>
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
	<Premium>{HBEXPPREM}</Premium>  {clauses}  {UW} </coverage>	'
WHERE SequenceID=13 AND IsActive=1;

-- ---------------------------------------------------------------------------
-- SEQ 14: {HB} -> {RISK_BUILDING}, {HC} -> {RISK_BC}
-- (CONVERSION DB uses wrong token names vs PER_RISK_BUILDING_FINAL columns)
-- ---------------------------------------------------------------------------
SELECT CHARINDEX('{HB}', ConversionScript) AS pos_HB, CHARINDEX('{HC}', ConversionScript) AS pos_HC
FROM dbo.PP_ConversionConfig WHERE SequenceID=14 AND IsActive=1;

UPDATE dbo.PP_ConversionConfig
SET ConversionScript = REPLACE(REPLACE(ConversionScript, '{HB}', '{RISK_BUILDING}'), '{HC}', '{RISK_BC}')
WHERE SequenceID=14 AND IsActive=1;

-- ---------------------------------------------------------------------------
-- SEQ 17: {CLAUSESSELECTION} -> {DCCLAUSETYPE}, {SELECTCLAUSEDESCRIPTION} -> {DCINPUT}
-- ---------------------------------------------------------------------------
SELECT CHARINDEX('{CLAUSESSELECTION}', ConversionScript) AS pos_old1, CHARINDEX('{SELECTCLAUSEDESCRIPTION}', ConversionScript) AS pos_old2
FROM dbo.PP_ConversionConfig WHERE SequenceID=17 AND IsActive=1;

UPDATE dbo.PP_ConversionConfig
SET ConversionScript = REPLACE(REPLACE(ConversionScript, '{CLAUSESSELECTION}', '{DCCLAUSETYPE}'), '{SELECTCLAUSEDESCRIPTION}', '{DCINPUT}')
WHERE SequenceID=17 AND IsActive=1;

-- ---------------------------------------------------------------------------
-- SEQ 18: {CLAUSE} -> {COM_CLAUSE}, {Description} -> {DESCRIPTION}
-- ---------------------------------------------------------------------------
SELECT CHARINDEX('{CLAUSE}', ConversionScript) AS pos_clause, CHARINDEX('{Description}', ConversionScript) AS pos_desc
FROM dbo.PP_ConversionConfig WHERE SequenceID=18 AND IsActive=1;

UPDATE dbo.PP_ConversionConfig
SET ConversionScript = REPLACE(REPLACE(ConversionScript, '{CLAUSE}', '{COM_CLAUSE}'), '{Description}', '{DESCRIPTION}')
WHERE SequenceID=18 AND IsActive=1;

-- ---------------------------------------------------------------------------
-- FINAL VERIFY: all bad tokens should show 0 after fixes applied
-- ---------------------------------------------------------------------------
SELECT SequenceID,
       CHARINDEX('{HB}',                     ConversionScript) AS has_HB,
       CHARINDEX('{HC}',                     ConversionScript) AS has_HC,
       CHARINDEX('{IMPOSEDEXCESS}',           ConversionScript) AS has_IMPOSEDEXCESS,
       CHARINDEX('{FLOODEXCESS}',             ConversionScript) AS has_FLOODEXCESS,
       CHARINDEX('{EARTHQUAKEEXCESS}',        ConversionScript) AS has_EARTHQUAKEEXCESS,
       CHARINDEX('{FLOODDAMAGE}',             ConversionScript) AS has_FLOODDAMAGE,
       CHARINDEX('{CLAUSESSELECTION}',        ConversionScript) AS has_CLAUSESSELECTION,
       CHARINDEX('{SELECTCLAUSEDESCRIPTION}', ConversionScript) AS has_SELECTCLAUSEDESC,
       CHARINDEX('{CLAUSE}',                  ConversionScript) AS has_CLAUSE_raw,
       CHARINDEX('{Description}',             ConversionScript) AS has_Description_mixed
FROM dbo.PP_ConversionConfig
WHERE SequenceID IN (7,13,14,17,18)
ORDER BY SequenceID;
-- All columns should be 0