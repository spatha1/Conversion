-- ============================================================
-- Snowflake-only execution: re-run seq 7 (RISK_Building_HB)
-- after applying the updated PER_HOME_BUILDING_PAYLOAD view.
--
-- Run each step in order. Apply views first (before this script).
-- ============================================================


-- ── Step 1: Verify the updated view is in place ───────────────────────────
-- Should return rows with the new HB columns populated (non-zero/non-null).
-- If HOMEBUILDINGSLIMIT is all 0, the HB_02 join key may need checking.
SELECT PUREPOLICYNUMBER, HOMEBUILDINGSLIMIT, LANDLORDPROTECTIONS,
       MINIMUMRENTALPERIOD, WEEKLYRENT, HBCLMCNT, HBCLMINCD, EXPPREM
FROM   AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
LIMIT  10;


-- ── Step 2: Remove today's stale RISK_Building_HB rows ───────────────────
-- Prevents duplicate rows when we re-insert in Step 3.
DELETE FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE  ITR_TYPE   = 'RISK_Building_HB'
  AND  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE);


-- ── Step 3: Re-run DYNAMIC_XML_V1 for seq 7 (RISK_Building_HB) ───────────
-- Template sourced from PolicyConversion.dbo.PP_ConversionConfig SequenceID=7.
-- $$ dollar-quoting used so XML content is passed safely.
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
</coverage>$$,
    'AGGNE.DEV.PER_BUILDING_TARGET',
    'RISK_Building_HB'
);


-- ── Step 4: Verify rows inserted into PER_BUILDING_TARGET ────────────────
SELECT ITR_TYPE, COUNT(*) AS ROW_COUNT
FROM   AGGNE.DEV.PER_BUILDING_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE
ORDER  BY ITR_TYPE;


-- ── Step 5: Verify seq 14 data exists (needed by PER_BUILDING_FINAL_AGG) ─
-- If count = 0 → contact your middleware team to run seq 14 first.
SELECT COUNT(*) AS RISK_BUILDING_ROWS
FROM   AGGNE.DEV.PER_RISK_BUILDING_TARGET
WHERE  ITR_TYPE   = 'RISK_Building'
  AND  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE);


-- ── Step 6: Spot-check PER_BUILDING_FINAL_AGG (view — no load needed) ────
-- {HB_CLAUSE}, {clauses}, {UW} should now be resolved in AOI.
SELECT PUREPOLICYNUMBER, LEFT(AOI, 500) AS AOI_PREVIEW
FROM   AGGNE.DEV.PER_BUILDING_FINAL_AGG
WHERE  PUREPOLICYNUMBER = 'p00002676'  -- change to any test policy
LIMIT  5;


-- ── Step 7: Regenerate final XML ─────────────────────────────────────────
CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();


-- ── Step 8: Check for any remaining {TOKEN} placeholders ─────────────────
SELECT POLICYNUMBER, XMLDATA
FROM   AGGNE.DEV.PER_CONVERSION_FINAL
WHERE  POLICYNUMBER = 'p00002676'
  AND  XMLDATA LIKE '%{%}%';
