-- ============================================================
-- BP CONVERSION — SP FIX DEPLOYMENT SCRIPT
-- Generated : 2026-07-04
-- Scope     : DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql
-- Prepared by: Conversion Team (SAI)
-- SAFE_MODE  : ON — Apply manually to DEV SP only
-- ============================================================
-- HOW TO USE:
--   Each fix block below shows:
--     • JIRA ticket + SP line reference
--     • BEFORE: current code in the SP (exact text to locate)
--     • AFTER : fixed code to replace it with
--   Open DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql in
--   Snowsight and use Ctrl+F to find the BEFORE text, then
--   replace with the AFTER block.
--   After all SP changes are applied, re-execute the SP to
--   refresh all transient/target tables.
-- ============================================================
-- TICKETS COVERED IN THIS SCRIPT:
--   CM   : ATP-11004, ATP-11003, ATP-11017, ATP-10999, ATP-11002
--   FL   : ATP-11037
--   BG/BC: ATP-10960, ATP-10287, ATP-10951, ATP-10949
--   BLDG : ATP-10918, ATP-10919, ATP-10920, ATP-10921, ATP-10922, ATP-10990
--   SCHEMA: ATP-10920 (partial), ATP-10922 (partial)
-- ============================================================




-- ============================================================
-- FIX CM-1 — ATP-11004
-- SP Line: ~2704–2720  (CM_01 ImportFlag mapping)
-- Issue  : ImportFlag = 'L' (locally supplied) passes as-is;
--          DCT expects 'N/A' for locally supplied vehicles
-- BEFORE : (exact ELSE clause in ImportFlag CASE)
-- ============================================================

-- BEFORE (SP lines 2704–2720):
/*
    ,t3.CMRBImportFlag
    ,/*PURE Field for testing only*/
    t3.CMRBImportFlagOV
    ,/*PURE Field for testing only*/
    CASE
        WHEN t3.CMCVOverride = 1
            THEN CASE
                    WHEN t3.CMRBImportFlagOV = 1
                        THEN ''I''
                    WHEN t3.CMRBImportFlagOV = 2
                        THEN ''L''
                    WHEN t3.CMRBImportFlagOV = 3
                        THEN ''N/A ''
                    ELSE ''''
                    END
        ELSE CMRBImportFlag
        END AS ImportFlag
*/

-- AFTER — add ATP-11004 fix (map 'L' to 'N/A' in non-override path):
/*
    ,t3.CMRBImportFlag
    ,/*PURE Field for testing only*/
    t3.CMRBImportFlagOV
    ,/*PURE Field for testing only*/
    -- ATP-11004: ImportFlag='L' (locally supplied) must map to 'N/A' for DCT
    CASE
        WHEN t3.CMCVOverride = 1
            THEN CASE
                    WHEN t3.CMRBImportFlagOV = 1
                        THEN ''I''
                    WHEN t3.CMRBImportFlagOV = 2
                        THEN ''L''
                    WHEN t3.CMRBImportFlagOV = 3
                        THEN ''N/A''
                    ELSE ''''
                    END
        ELSE
            -- ATP-11004: Non-override path: if Redbook returns 'L', map to 'N/A'
            CASE WHEN TRIM(CMRBImportFlag) = ''L'' THEN ''N/A'' ELSE CMRBImportFlag END
        END AS ImportFlag
*/


-- ============================================================
-- FIX CM-2 — ATP-11003
-- SP Line: ~3085 (end of CM_01 SELECT — add missing column)
-- Issue  : ExcessWaiverForGlass not selected from CBP_VEHICLEDETAIL
--          into CM_01; CV_RISK_COV_FINAL_VIEW maps it at line 109
--          but gets NULL from CM_01/CM_03
-- Source : t3.CMCVExcessWaiver in CBP_VEHICLEDETAIL
--          (verify exact column name: CMCVExcessWaiver / CMCVExcessWaiverGlass)
-- BEFORE : (last column before FROM in CM_01)
-- ============================================================

-- BEFORE (SP lines ~3069–3089, end of CM_01 SELECT):
/*
        END AS VoluntaryExcess
    FROM AGGNE.DEV.Sample_CBP_CommercialVechicle t2
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL t3 ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_CLAUSEAMENDMENTCM t5 ON t2.ExpiringID_P = t5.CBP_Policy_Binder_id
*/

-- AFTER — add ExcessWaiverForGlass before FROM:
/*
        END AS VoluntaryExcess
    -- ATP-11003: ExcessWaiverForGlass not previously selected; CV_RISK_COV_FINAL_VIEW expects it
    -- VERIFY exact source column name in CBP_VEHICLEDETAIL before applying:
    ,CASE
        WHEN t3.CMCVExcessWaiver = 1 THEN ''Yes''
        WHEN t3.CMCVExcessWaiver = 0 THEN ''No''
        ELSE ''No''
     END AS ExcessWaiverForGlass
    FROM AGGNE.DEV.Sample_CBP_CommercialVechicle t2
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL t3 ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_CLAUSEAMENDMENTCM t5 ON t2.ExpiringID_P = t5.CBP_Policy_Binder_id
*/

-- ⚠ BEFORE APPLYING: verify column name with:
SELECT column_name FROM information_schema.columns
WHERE table_name = 'CBP_VEHICLEDETAIL'
  AND column_name ILIKE '%excess%waiver%'
  AND table_schema = 'PURE_SNAPSHOT';


-- ============================================================
-- FIX CM-3 — ATP-11017
-- SP Line: ~2174–2177 (CM_01 Redbook columns section)
-- Issue  : CMRBPower and CMRBTrackrear (fuel/power/traction) not
--          selected from CBP_VEHICLEDETAIL; appear blank in DCT
-- BEFORE : (lines ~2174–2177, after CMRBGrossVehMassOV)
-- ============================================================

-- BEFORE (SP lines ~2174–2177):
/*
    ,t3.CMRBGrossVehMass /*PURE Field for testing only*/
    ,t3.CMRBEngineSize /*PURE Field for testing only*/
    ,t3.CMRBEngineSizeOV AS EngineSize
    ,t3.CMRBGrossVehMassOV AS GrossVehicleMass
*/

-- AFTER — add ATP-11017 columns after GrossVehicleMass:
/*
    ,t3.CMRBGrossVehMass /*PURE Field for testing only*/
    ,t3.CMRBEngineSize /*PURE Field for testing only*/
    ,t3.CMRBEngineSizeOV AS EngineSize
    ,t3.CMRBGrossVehMassOV AS GrossVehicleMass
    -- ATP-11017: CMRBPower and CMRBTrackrear not previously selected
    -- VERIFY exact column names in CBP_VEHICLEDETAIL before applying:
    ,t3.CMRBPower AS CMRBPower
    ,t3.CMRBTrackrear AS CMRBTrackrear
*/

-- ⚠ BEFORE APPLYING: verify column names with:
SELECT column_name FROM information_schema.columns
WHERE table_name = 'CBP_VEHICLEDETAIL'
  AND column_name ILIKE '%CMRBPower%' OR column_name ILIKE '%CMRBTrack%'
  AND table_schema = 'PURE_SNAPSHOT';


-- ============================================================
-- FIX CM-4 — ATP-10999
-- SP Line: 3086–3088 (CM_01 JOIN to CBP_VEHICLEDETAIL)
-- Issue  : CM_01 joins CBP_VEHICLEDETAIL on ExpiringID_P only
--          (policy binder). If one policy has N vehicles, all N
--          rows in CBP_VEHICLEDETAIL multiply against each other,
--          causing wrong vehicle's market value to appear on all
--          vehicles, or values being duplicated.
-- Root cause: JOIN missing vehicle-level identifier
-- ============================================================

-- BEFORE (SP line 3087):
/*
    FROM AGGNE.DEV.Sample_CBP_CommercialVechicle t2
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL t3 ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
*/

-- AFTER — add vehicle ID to join (verify t2 has vehicle key and match column name in CBP_VEHICLEDETAIL):
/*
    -- ATP-10999: Added VehicleID to join to prevent cross-vehicle market value duplication
    FROM AGGNE.DEV.Sample_CBP_CommercialVechicle t2
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL t3
        ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
        AND t2.VehicleID   = t3.CBP_VEHICLEDETAIL_id   -- ATP-10999: vehicle-level join
*/

-- ⚠ BEFORE APPLYING: verify Sample_CBP_CommercialVechicle has VehicleID column:
SELECT column_name FROM information_schema.columns
WHERE table_name = 'SAMPLE_CBP_COMMERCIALVECHICLE'
  AND table_schema = 'DEV'
ORDER BY ordinal_position;


-- ============================================================
-- FIX CM-5 — ATP-11002
-- SP Line: ~2606–2630 (CM_01 BodyType CASE)
-- Issue  : When CMCVOverride = 0 (no override), BodyType passes
--          raw CMCVBodyType which is a numeric integer from Redbook
--          (e.g., 5 for Trailer), not a string like 'Trailer'.
--          CV_RISK_COV_FINAL_VIEW:155 maps 'Trailer'→'Trailer'
--          but receives '5' — so body type shows as blank/0 in DCT.
-- ============================================================

-- BEFORE (SP lines ~2606–2630, the ELSE clause in BodyType CASE):
/*
        ELSE CMCVBodyType
        END AS BodyType
*/

-- AFTER — map raw CMCVBodyType numeric codes in ELSE path:
/*
        -- ATP-11002: When Override=0, CMCVBodyType is a raw Redbook integer.
        -- Map to text values so CV_RISK_COV_FINAL_VIEW can match correctly.
        ELSE CASE CAST(CMCVBodyType AS VARCHAR)
                WHEN ''1'' THEN ''Sedan''
                WHEN ''2'' THEN ''Coupe''
                WHEN ''3'' THEN ''Wagon''
                WHEN ''4'' THEN ''Hatchback''
                WHEN ''5'' THEN ''Van''
                WHEN ''6'' THEN ''Cab Chassis''
                WHEN ''7'' THEN ''Utility''
                WHEN ''8'' THEN ''Convertible''
                WHEN ''9'' THEN ''Other''
                ELSE CMCVBodyType
             END
        END AS BodyType
*/
-- ⚠ VERIFY: run the following first to check what values CMCVBodyType actually holds:
SELECT DISTINCT CMCVBodyType, CMCVBodyTypeOV, CMCVOverride
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL
WHERE CBP_Policy_Binder_id IN (SELECT DISTINCT ExpiringID_P FROM AGGNE.DEV.Sample_CBP_CommercialVechicle)
LIMIT 100;


-- ============================================================
-- FIX FL-1 — ATP-11037
-- SP Line: 3796–3842 (VEHICLECOVERAGES_FLEETVEHICLE creation)
-- Issue  : SELECT DISTINCT on full row set may not deduplicate
--          at the vehicle level — if FL_01 produces duplicate
--          rows per vehicle (e.g. from multiple LEFT JOINs
--          returning multiple rows), DISTINCT on all columns
--          won't collapse them.
--          Result: Multiple vehicle rows appear in DCT Fleet
--          Vehicle Details Summary.
-- ============================================================

-- BEFORE (SP line 3796):
/*
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.VehicleCoverages_FleetVehicle AS
SELECT  DISTINCT
PUREPOLICYNUMBER,
EXPIRINGID_P,
CMLNUMBER,
...all columns...
FROM FL_01
ORDER BY PUREPOLICYNUMBER;
*/

-- AFTER — wrap with ROW_NUMBER() dedup keyed on policy+vehicle registration:
/*
-- ATP-11037: Replace SELECT DISTINCT with ROW_NUMBER() dedup to ensure
-- one row per PUREPOLICYNUMBER + EXPIRINGID_P + REGISTRATIONNUMBER
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.VehicleCoverages_FleetVehicle AS
WITH ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY PUREPOLICYNUMBER, EXPIRINGID_P, CMLNUMBER, REGISTRATIONNUMBER
            ORDER BY PUREPOLICYNUMBER
        ) AS rn
    FROM FL_01
)
SELECT
PUREPOLICYNUMBER, EXPIRINGID_P, CMLNUMBER, EXPIRYDATE, COUNTRY, HaveInterestedParty,
AdditonalParty, PROTECTIONTYPE, RESTRICTIONOFDRIVERAGE, CHOICEOFREPAIR, CARHIRE,
UNLIMITEDGLASS, ONHOOK, VOLUNTARYEXCESS, REGISTRATIONSTATE, REGISTRATIONNUMBER,
HIGHESTRISKUSE, ACCESSORIESDESCRIPTION, ACCESSORIESVALUE, year, MAKE, MODEL,
DESCRIPTION, BODYTYPE, ENGINESIZE, NUMBEROFCYLINDERS, INDUCTIONTYPE, GROSSVEHICLEMASS,
ADDACCESSORIES, TAXIREGISTRATION, OWNOTHERBUS, IDLEVEHSTORED, DETAILS_LOCRISKMIT,
AreContEmpDriver, DeliverDangerousGood, YearsExperienceDelivery,
Rideshare, PercFLRideshare, ContractRestriction, HireVehDriverSupplied, YearsExperiencehire,
dcinput, dcclausetype
FROM ranked
WHERE rn = 1
ORDER BY PUREPOLICYNUMBER;
*/

-- ⚠ NOTE: Before applying, verify that REGISTRATIONNUMBER is the right dedup key.
-- If a fleet vehicle has multiple coverage types, use a broader partition key.
-- Verify first with:
SELECT PUREPOLICYNUMBER, EXPIRINGID_P, REGISTRATIONNUMBER, COUNT(*) AS cnt
FROM AGGNE.DEV.VehicleCoverages_FleetVehicle
GROUP BY 1,2,3
HAVING COUNT(*) > 1
LIMIT 20;


-- ============================================================
-- FIX FL-2 — ATP-11029 / ATP-11034 / ATP-11033 / ATP-11035
-- SP Line: FL_01 (~L3627) — columns ARE already selected
-- STATUS : NOT AN SP CODE BUG
-- ============================================================
/*
   After reading FL_01 (SP L3627–3793), the following columns ARE
   already selected:
     MAKE, MODEL         : from FLEET_TEMPLATE t6 (L3761–3762)
     TAXIREGISTRATION    : from QU_FLGENERAL t7 (L3770)
     Rideshare,          : from QU_FLHIRE t9 (L3777–3781)
     ContractRestriction
     ADDACCESSORIES      : from FLEET_TEMPLATE t6 (L3769)

   These are NULL in DC because the source tables (FLEET_TEMPLATE,
   QU_FLGENERAL, QU_FLHIRE) do not have matching records for
   those policies. This is a SOURCE DATA GAP, not an SP code bug.

   ACTION REQUIRED:
   1. Check if FLEET_TEMPLATE t6 has rows for affected policies:
      SELECT COUNT(*) FROM PRD_T5_EXTERNAL_AGGNE.RISK.FLEET_TEMPLATE
      WHERE purepolicybinderid IN ('<affected policy IDs>');
   2. Check QU_FLGENERAL:
      SELECT COUNT(*) FROM PRD_T5_EXTERNAL_AGGNE.RISK.QU_FLGENERAL
      WHERE purepolicybinder IN ('<affected policy IDs>');
   3. Check QU_FLHIRE:
      SELECT COUNT(*) FROM PRD_T5_EXTERNAL_AGGNE.RISK.QU_FLHIRE
      WHERE purepolicybinder IN ('<affected policy IDs>');
   If source is empty → escalate to Pure/data team.
*/


-- ============================================================
-- FIX BG-1 — ATP-10960 / ATP-10287
-- SP Line: 6584–6626 (BG_01 creation)
-- Issue  : NZ TheftLimit reported as halved (50% applied when
--          TheftLimit >= ContentsLimit). Root cause NOT found in
--          SP — BG_01 reads t3.BGTheftProtection AS TheftLimit
--          directly without any halving logic.
-- STATUS : SOURCE DATA INVESTIGATION REQUIRED
-- ============================================================
/*
   BG_01 (SP L6584–6626) reads:
     t3.BGTheftProtection AS TheftLimit   (L6605)

   No halving/NZ conditional is present in BG_01.

   POSSIBILITIES:
   a) The BGTheftProtection value in Pure (cbp_burglary) is already
      half the expected value for NZ policies — a Pure-side calculation.
   b) There is halving logic in the BUILDING_BG_PAYLOAD view.
   c) DCT applies a rule server-side.

   VERIFICATION QUERY — run before making any SP changes:
*/
SELECT
    T1.PUREPOLICYNUMBER,
    T1.COUNTRY,
    T1.THEFTLIMIT,
    T2.CONTENTSSTOCKEMPLOYEETOOLSLIMIT,
    T1.THEFTLIMIT / NULLIF(T2.CONTENTSSTOCKEMPLOYEETOOLSLIMIT, 0) AS ratio
FROM AGGNE.DEV.LOCATION_BG_COVERAGE T1
JOIN AGGNE.DEV.LOCATION_BG_COVERAGE T2 USING (PUREPOLICYNUMBER, EXPIRINGID_P)
WHERE T1.COUNTRY = 'NZ'
  AND T1.THEFTLIMIT > 0
LIMIT 30;
-- If ratio is ~0.5 → source already halved → escalate to Pure team
-- If ratio is 1.0  → halving is in view or DCT → check BUILDING_BG_PAYLOAD.sql


-- ============================================================
-- FIX BG-2 — ATP-10951
-- SP Line: 6596 (BG_01 ContentsStockEmployeeToolsLimit)
-- Issue  : BG limits populating non-zero value when Pure = 0
-- STATUS : LIKELY SOURCE DATA — verify before SP change
-- ============================================================
/*
   BG_01 (SP L6596):
     t3.BGContents + t3.BGEmployeeTools AS ContentsStockEmployeeToolsLimit

   If BGContents = 0 and BGEmployeeTools = 0 in Pure, the sum = 0.
   If DC shows non-zero, either:
   a) Pure has a non-zero default (BGContents = 10000 from product template)
   b) BGEmployeeTools is non-zero when BGContents = 0

   VERIFICATION:
*/
SELECT PUREPOLICYNUMBER, EXPIRINGID_P, BGCONTENTS, BGEMPLOYEETOOLS,
       BGCONTENTS + BGEMPLOYEETOOLS AS computed
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_BURGLARY
WHERE BGCONTENTS = 0
  AND BGCONTENTS + BGEMPLOYEETOOLS > 0
LIMIT 20;
-- If BGEMPLOYEETOOLS is non-zero when BGCONTENTS=0 → separate the fields:
-- BEFORE: t3.BGContents + t3.BGEmployeeTools AS ContentsStockEmployeeToolsLimit
-- AFTER (if needed):
--   t3.BGContents AS ContentsStockLimit,
--   t3.BGEmployeeTools AS EmployeeToolsLimit
-- And update view BUILDING_BG_PAYLOAD accordingly


-- ============================================================
-- FIX BC-1 — ATP-10949 / ATP-10947
-- SP Line: 6393 (BC_01 creation)
-- Issue  : BC ContentLimit = 10000 when Pure = 0; Landslide
--          Limit wrong value (Pure 105000 → DC 83000)
-- STATUS : SOURCE DATA INVESTIGATION REQUIRED
-- ============================================================
/*
   BC_01 (SP L6404):  t3.BCContents AS ContentsLimit
   BC_01 (SP L6423):  t3.BCLandslideLimit AS LandslideLimit

   Both read directly from Pure — no transformation in SP.

   For ATP-10949 (ContentsLimit = 10000 when Pure = 0):
   If Pure BCContents = 0 but DCT shows 10000, this is a Pure
   default value OR a DCT product minimum. Run:
*/
SELECT COUNT(*) AS zero_in_pure
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_BUSINESSCONTENTS
WHERE BCCONTENTS = 0;
-- If count > 0 and DC shows 10000 → DCT product minimum, not SP bug

/*
   For ATP-10947 (LandslideLimit Pure 105000 → DC 83000):
   Check if BUILDING_BC_PAYLOAD applies a NZD→AUD currency conversion:
*/
SELECT 105000 * 0.789;  -- ~82845 ≈ 83000 — NZD→AUD conversion rate?
-- If this matches, the issue is a currency conversion in the view/DCT
-- Check BUILDING_BC_PAYLOAD.sql for any currency conversion logic


-- ============================================================
-- FIX BLDG-1 — ATP-10918, 10919, 10920, 10921, 10922, 10990
-- SP Line: Building UW adj sections ALL COMMENTED OUT
-- Issue  : ALL building protection UW adjustment inserts
--          (BB, BC, BG, BI, EN, MY) are commented out in the SP.
--          SP never writes UW adj rows to RISK_BUILDING_*_TARGET.
--          Payload views read from RISK_BUILDING_*_TARGET — so
--          UW adj section in DCT is always empty for all building
--          protections.
-- ============================================================
/*
   CURRENT STATE:
   - BBAdj_01/BBAdj_02: fully commented out (~L6353–6386 in BB section)
   - BCAdj_01/BCAdj_02: fully commented out (~L6442–6510)
   - BGAdj_01/BGAdj_02: fully commented out (~L6631–6728)
   - BIAdj, ENAdj, MYAdj: similarly commented out

   The commented sections reference:
     OUTPUT_UWADJUST_BSP_POLICYATTACH (WRONG — this is the Attach table)
   Should be:
     AGGNE.DEV.OUTPUT_UWADJUST_BSP (Conversion version)

   Also, the SP needs to INSERT into RISK_BUILDING_*_TARGET
   (which the payload views read from), but those inserts are MISSING.
   The SP creates Location_BG_Coverage/BC_01 etc. but never writes
   to RISK_BUILDING_BG_TARGET / RISK_BUILDING_BC_TARGET etc.

   FIX APPROACH (example for BG — repeat for BB, BC, BI, EN, MY):
   After Location_BG_Coverage is created (~L6731), ADD:
*/

-- EXAMPLE FIX for BG — insert UW adj rows into RISK_BUILDING_BG_TARGET:
-- (Add this block after Location_BG_Coverage creation at SP L6732)
/*
-- ATP-10920: Insert BG UW adj rows into RISK_BUILDING_BG_TARGET
-- Source: OUTPUT_UWADJUST_BSP (Conversion version, not _POLICYATTACH)
INSERT INTO AGGNE.DEV.RISK_BUILDING_BG_TARGET (ID, ITR_TYPE, PAYLOAD, LOAD_DATE)
SELECT
    CAST(TRIM(T2.PUREPOLICYNUMBER)||'|'||TRIM(T2.CMLNUMBER)||'|'||TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS ID,
    'BP_RISK_BUILDING_BG_UW' AS ITR_TYPE,
    '<UnderwritingAdjustment>'
        || '<RecurringIndicator>' || CAST(0 AS VARCHAR) || '</RecurringIndicator>'
        || '<AdjustmentType>1</AdjustmentType>'
        || '<UnderwritingDescription>' || COALESCE(REPLACE(REPLACE(T1.UWADJUSTNOTE,'&','&amp;'),'''',''''''),'') || '</UnderwritingDescription>'
        || '<AdjustmentDollarAndPercent>' || CAST(T1.UWADJUSTAMOUNT AS VARCHAR) || '</AdjustmentDollarAndPercent>'
        || '<AdjustmentSelection>1</AdjustmentSelection>'
        || '</UnderwritingAdjustment>' AS PAYLOAD,
    CAST(GETDATE() AS DATE) AS LOAD_DATE
FROM AGGNE.DEV.OUTPUT_UWADJUST_BSP T1
INNER JOIN AGGNE.DEV.LOCATION_BG_COVERAGE T2
    ON TRIM(T1.POLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
WHERE T1.COVERAGE = 'BG'
  AND T1.UWADJUSTAMOUNT IS NOT NULL
  AND T1.UWADJUSTAMOUNT <> 0;

-- Repeat the same pattern for: BB, BC, BI, EN, MY
-- Change T2 table: LOCATION_BB_COVERAGE, LOCATION_BC_COVERAGE,
--                 LOCATION_BI_COVERAGE, LOCATION_EN_COVERAGE, Location_Money_Coverage
-- Change ITR_TYPE: 'BP_RISK_BUILDING_BB_UW', 'BP_RISK_BUILDING_BC_UW',
--                 'BP_RISK_BUILDING_BI_UW', 'BP_RISK_BUILDING_EN_UW', 'BP_RISK_BUILDING_MY_UW'
-- Change COVERAGE filter: 'BB', 'BC', 'BI', 'EN', 'MY'
*/

-- ⚠ BEFORE APPLYING: verify RISK_BUILDING_BG_TARGET exists and confirm column structure:
SELECT column_name FROM information_schema.columns
WHERE table_name = 'RISK_BUILDING_BG_TARGET'
  AND table_schema = 'DEV'
ORDER BY ordinal_position;

-- ⚠ Also check what COVERAGE codes exist in OUTPUT_UWADJUST_BSP:
SELECT DISTINCT COVERAGE, COUNT(*) AS cnt
FROM AGGNE.DEV.OUTPUT_UWADJUST_BSP
GROUP BY COVERAGE
ORDER BY COVERAGE;


-- ============================================================
-- FIX SCHEMA-1 — SP consistency: schema prefix on transient tables
-- Issue  : Some LOCATION_* tables are created without AGGNE.DEV
--          schema prefix, meaning they resolve to the SP's session
--          schema. Inconsistent with fully-qualified view references.
-- ============================================================

-- BEFORE (SP line 6553):
/*
CREATE OR REPLACE  TRANSIENT TABLE Location_BC_Coverage AS
SELECT    DISTINCT * FROM AGGNE.DEV.BC_01;
*/
-- AFTER:
/*
-- Schema prefix added for consistency with view references (AGGNE.DEV.LOCATION_BC_COVERAGE)
CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Location_BC_Coverage AS
SELECT DISTINCT * FROM AGGNE.DEV.BC_01;
*/

-- BEFORE (SP line 6731):
/*
    ;CREATE OR REPLACE TRANSIENT  TABLE Location_BG_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.BG_01;
*/
-- AFTER:
/*
    ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Location_BG_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.BG_01;
*/

-- BEFORE (SP line 7405):
/*
   ;CREATE OR REPLACE TRANSIENT  TABLE Location_Money_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.MY_01;
*/
-- AFTER:
/*
   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Location_Money_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.MY_01;
*/

-- NOTE: Location_BB_Coverage (L6361) and Location_BI_Coverage (L6940)
-- and Location_EN_Coverage (L7171) already have AGGNE.DEV prefix — no change needed.


-- ============================================================
-- POST-APPLY VERIFICATION
-- Run after SP re-execution to confirm fixes took effect
-- ============================================================

-- V1: CM ImportFlag — confirm no 'L' values remain
SELECT DISTINCT IMPORTFLAG, COUNT(*) AS CNT
FROM AGGNE.DEV.CM_01
WHERE IMPORTFLAG = 'L'
GROUP BY IMPORTFLAG;
-- Expected: 0 rows

-- V2: CM market value dedup — confirm no duplicate vehicles per policy
SELECT PUREPOLICYNUMBER, EXPIRINGID_P, VEHICLEID, COUNT(*) AS CNT
FROM AGGNE.DEV.CM_01
GROUP BY 1,2,3
HAVING COUNT(*) > 1
LIMIT 10;
-- Expected: 0 rows

-- V3: FL Vehicle dedup
SELECT PUREPOLICYNUMBER, EXPIRINGID_P, REGISTRATIONNUMBER, COUNT(*) AS CNT
FROM AGGNE.DEV.VehicleCoverages_FleetVehicle
GROUP BY 1,2,3
HAVING COUNT(*) > 1
LIMIT 10;
-- Expected: 0 rows

-- V4: Building UW adj — confirm rows exist after SP re-run
SELECT ITR_TYPE, COUNT(*) AS CNT
FROM AGGNE.DEV.RISK_BUILDING_BG_TARGET
WHERE ITR_TYPE = 'BP_RISK_BUILDING_BG_UW'
GROUP BY ITR_TYPE;
-- Expected: > 0 rows (if OUTPUT_UWADJUST_BSP has BG records)

-- V5: LOCATION_* tables in correct schema
SELECT TABLE_NAME, TABLE_SCHEMA
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME ILIKE 'LOCATION_%COVERAGE'
  AND TABLE_SCHEMA = 'DEV'
ORDER BY TABLE_NAME;
-- Expected: BC, BB, BG, BI, EN, Money all in DEV schema
