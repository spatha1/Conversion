-- ============================================================
-- Snowflake-only execution: re-run seq 13 (RISK_Building_HC)
-- Root cause: PER_HC_TARGET has a stale RISK_Building_HC payload
-- produced by an older template that contained {FLOODDAMAGE},
-- {IMPOSEDEXCESS}, {FLOODEXCESS}, {EARTHQUAKEEXCESS},
-- {STANDARDEXCESS}, {HC_EV}, {HC_SC} as live placeholders.
-- The current template has all those hardcoded — re-running
-- seq 13 will overwrite with a clean payload.
--
-- CHANGE LOG
-- v1  original  : <Indicator>1</Indicator> hardcoded in template
-- v2  2026-07-01: <Indicator>{HC_INDICATOR}</Indicator> — driven by
--                 HC_INDICATOR column in PER_HOME_BUILDING_PAYLOAD.
--                 Fixes: HB-only policies were getting HC checkbox ticked
--                 in DCT because HC_INDICATOR was always 1.
-- ============================================================


-- ── Step 1: Verify sub-payloads (seqs 8-12) exist for today ─────────────
-- Seq 13 reads HC_exceed_values, HC_Specified_Contents, Building_SubCov
-- from PER_HC_TARGET via PER_HOME_BUILDING_PAYLOAD.CTE_LISTAGG.
-- These must already be present for today before we run seq 13.
SELECT ITR_TYPE, COUNT(*) AS CNT
FROM   AGGNE.DEV.PER_HC_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE
ORDER  BY ITR_TYPE;


-- ── Step 2: Delete today's stale RISK_Building_HC row ────────────────────
DELETE FROM AGGNE.DEV.PER_HC_TARGET
WHERE  ITR_TYPE  = 'RISK_Building_HC'
  AND  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE);


-- ── Step 3: Re-run DYNAMIC_XML_V1 for seq 13 (RISK_Building_HC) ─────────
-- Template sourced from PolicyConversion.dbo.PP_ConversionConfig SequenceID=13.
-- Key change vs old template: FloodDamage=Taken hardcoded; Excess tags empty.
-- {FLOODDAMAGE}/{HC_EV}/{HC_SC} do NOT appear → those tokens will be gone.
-- {clauses} and {UW} remain — they are resolved by PER_BUILDING_FINAL_AGG.hc_agg.
--
-- INDICATOR CHANGE (v1 → v2, 2026-07-01):
--   v1 (old): <Indicator>1</Indicator>  ← hardcoded; HB-only policies got
--             HC checkbox ticked in DCT even though they have no HC coverage.
--   v2 (new): <Indicator>{HC_INDICATOR}</Indicator>  ← sourced from
--             HC_INDICATOR column in PER_HOME_BUILDING_PAYLOAD.
--             HC_INDICATOR = 1 only when policy is in HC_02 (has HC coverage).
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD',
    $$<coverage>
	<Type>ContentsAndStocks</Type>
	<Indicator>{HC_INDICATOR}</Indicator>
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
	<Premium>{HBEXPPREM}</Premium>  {clauses}  {UW} </coverage>$$,
    'AGGNE.DEV.PER_HC_TARGET',
    'RISK_Building_HC'
);


-- ── Step 4: Confirm new payload has no stale tokens ──────────────────────
-- Should show only {clauses} and {UW} remaining (handled by PER_BUILDING_FINAL_AGG)
SELECT ID, PAYLOAD
FROM   AGGNE.DEV.PER_HC_TARGET
WHERE  ITR_TYPE  = 'RISK_Building_HC'
  AND  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
  AND  ID LIKE '%P00002676%';


-- ── Step 5: Regenerate final XML ─────────────────────────────────────────
CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();


-- ── Step 6: Final token check ─────────────────────────────────────────────
SELECT LEGACYPOLICYNUMBER,
       CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 'TOKENS REMAIN' ELSE 'CLEAN' END AS STATUS
FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE  LEGACYPOLICYNUMBER = 'P00002676';
