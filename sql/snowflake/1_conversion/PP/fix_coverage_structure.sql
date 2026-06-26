-- ============================================================
-- Snowflake: Fix coverage node structure for PP Building block
--
-- Root causes fixed:
--   1. {SUBCOV} removed from seq 7 HB template (SQL Server UPDATE
--      applied first via fix_seq7_remove_subcov.sql).
--      Previously pulled HC sub-coverages into the HB Building block.
--
--   2. PER_BUILDING_FINAL_AGG.hb_agg updated to insert Building_SubCov
--      and BUILDING_UW payloads INSIDE </coverage> (not appended after).
--      Previously produced top-level orphan <coverage> nodes.
--
-- Prerequisites:
--   □ fix_seq7_remove_subcov.sql applied in PolicyConversion SQL Server DB
--   □ PER_BUILDING_FINAL_AGG view re-created (this session's views DDL)
--   □ All earlier seqs (4–6) already have today's data in PER_BUILDING_TARGET
--   □ All HC seqs (8–12) already have today's data in PER_HC_TARGET
--
-- Expected result after fix:
--   Building coverage block: 9 BB sub-coverages nested inside (BLD_ST etc.)
--   ContentsAndStocks block: 9 HC sub-coverages nested inside (CAD_SD etc.)
--   No top-level orphan <coverage> nodes for sub-coverages.
-- ============================================================


-- ── Step 1: Apply updated PER_BUILDING_FINAL_AGG view ────────────────────
-- Run the DDL from:
--   sql\snowflake\1_conversion\PP\views\PER_BUILDING_FINAL_AGG.sql
-- (hb_agg now inserts Building_SubCov INSIDE </coverage>)


-- ── Step 2: Confirm today's BB sub-coverage data exists ──────────────────
-- Must have Building_SubCov rows before re-running seq 7.
SELECT ITR_TYPE, COUNT(*) AS CNT
FROM   AGGNE.DEV.PER_BUILDING_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE
ORDER  BY ITR_TYPE;
-- Expected: Building_SubCov (9 rows), BUILDING_UW (≥0), HB_CLAUSE (≥0)
-- If RISK_Building_HB already exists with old template → delete it next


-- ── Step 3: Delete stale RISK_Building_HB row (old template had {SUBCOV}) ─
DELETE FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE  ITR_TYPE  = 'RISK_Building_HB'
  AND  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE);


-- ── Step 4: Re-run DYNAMIC_XML_V1 for seq 7 (updated HB template) ────────
-- Template no longer has {SUBCOV} — seq 7 will NOT embed HC sub-coverages.
-- IMPORTANT: ensure PolicyConversion UPDATE (step 1) is applied first.
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


-- ── Step 5: Verify seq 7 row inserted; confirm no {SUBCOV} in payload ────
SELECT ITR_TYPE, COUNT(*) AS CNT
FROM   AGGNE.DEV.PER_BUILDING_TARGET
WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
GROUP  BY ITR_TYPE
ORDER  BY ITR_TYPE;

-- Spot-check: RISK_Building_HB payload should NOT contain any HC sub-coverage
-- types (CAD_SD, CFL_SD, SPE_SD, CNT_SD, etc.)
SELECT ID, PAYLOAD
FROM   AGGNE.DEV.PER_BUILDING_TARGET
WHERE  ITR_TYPE  = 'RISK_Building_HB'
  AND  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
  AND  (ID LIKE '%P00002676%' OR 1=1)
LIMIT  3;


-- ── Step 6: Preview PER_BUILDING_FINAL_AGG for P00002676 ─────────────────
-- AOI should show Building block with BB sub-coverages nested inside it.
-- Look for BLD_ST, BLD_EQ, etc. appearing BETWEEN <coverage><Type>Building
-- ...and the CLOSING </coverage>, NOT after it.
SELECT PUREPOLICYNUMBER, AOI
FROM   AGGNE.DEV.PER_BUILDING_FINAL_AGG
WHERE  PUREPOLICYNUMBER = 'P00002676';


-- ── Step 7: Count coverage nodes in the AOI to validate structure ─────────
-- Expected for a single-building policy like P00002676:
--   <Type>Building</Type>     → 1  (top-level)
--   <Type>BLD_ST</Type> etc.  → 9  (nested inside Building)
--   <Type>ContentsAndStocks</Type> → 1 (top-level, in HC payload)
--   <Type>CAD_SD</Type> etc.  → 9  (nested inside ContentsAndStocks via {SUBCOV})
-- Total <Type> nodes = 20 (2 top-level + 9 BB + 9 HC)
SELECT PUREPOLICYNUMBER,
       REGEXP_COUNT(AOI, '<Type>') AS TYPE_NODE_COUNT,
       REGEXP_COUNT(AOI, '<Type>Building</Type>') AS BUILDING_TOP_LEVEL,
       REGEXP_COUNT(AOI, '<Type>BLD_') AS BB_SUBCOV_COUNT,
       REGEXP_COUNT(AOI, '<Type>ContentsAndStocks</Type>') AS HC_TOP_LEVEL,
       REGEXP_COUNT(AOI, '<Type>CAD_SD</Type>|<Type>CFL_SD</Type>|<Type>CNT_SD</Type>|<Type>CNT_EQ</Type>|<Type>CNT_ST</Type>|<Type>CNT_BF</Type>|<Type>CNT_CY</Type>|<Type>CLI_SD</Type>|<Type>SPE_SD</Type>') AS HC_SUBCOV_COUNT
FROM   AGGNE.DEV.PER_BUILDING_FINAL_AGG
WHERE  PUREPOLICYNUMBER = 'P00002676';


-- ── Step 8: Regenerate final XML ─────────────────────────────────────────
CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();


-- ── Step 9: Final status check ───────────────────────────────────────────
SELECT LEGACYPOLICYNUMBER,
       CASE WHEN REQUEST_XML LIKE '%{%}%' THEN 'TOKENS REMAIN' ELSE 'CLEAN' END AS STATUS,
       -- Count top-level coverage nodes in final XML
       REGEXP_COUNT(REQUEST_XML, '<Type>Building</Type>')         AS HB_TOP,
       REGEXP_COUNT(REQUEST_XML, '<Type>ContentsAndStocks</Type>') AS HC_TOP,
       REGEXP_COUNT(REQUEST_XML, '<Type>BLD_')                    AS BB_SUBCOV,
       REGEXP_COUNT(REQUEST_XML, '<Type>CAD_SD|CFL_SD|CNT_SD|CNT_EQ|CNT_ST|CNT_BF|CNT_CY|CLI_SD|SPE_SD') AS HC_SUBCOV
FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE  LEGACYPOLICYNUMBER = 'P00002676';
-- Expected: STATUS=CLEAN, HB_TOP=1, HC_TOP=1, BB_SUBCOV=9, HC_SUBCOV=9
