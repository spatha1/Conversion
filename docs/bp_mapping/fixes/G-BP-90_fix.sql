-- G-BP-90 — Commercial Vehicle (CV) per-vehicle sub-coverage cross-contamination
-- SEQ 62 (CV_COVERAGE_VEHICLE_SUBCOV) -> SEQ 63 (CV_COVERAGE_VEHICLE_COV) -> SEQ 67 (CV_RISK_COV_FINAL_VIEW)
--
-- HOTFIX 2026-07-12 (after first live reload): the original STEP 1 below built SEQ62's key using
-- NVL(CAST(VEHICLEID AS VARCHAR),0), which renders this NUMBER column as '1060225.00000' (decimal
-- scale preserved). SEQ63/64/65/66/67 all key off plain TRIM(VEHICLEID) on the raw numeric column,
-- which renders '1060225' (no decimals) -- confirmed different text byte-for-byte. This meant
-- SEQ63's join to SEQ62's rendered rows never matched ANYTHING: confirmed live, 0 of 45,142
-- CV_COVERAGE_VEHICLE_COV rows had a non-null SUBCOV_XML after the first reload -- sub-coverage
-- data was no longer cross-contaminated, but was now silently missing for every vehicle instead.
-- STEP 1 below is corrected to NVL(TRIM(VEHICLEID),'0'), matching the clean format used everywhere
-- else in this chain. If you already applied the original STEP 1 and re-ran the backfill script,
-- re-apply this corrected STEP 1 and re-run docs/bp_mapping/fixes/G-BP-90_rerun_seq62_63.py again.
--
-- Same bug SHAPE as G-BP-88 (Fleet), but more severe:
--   - Fleet was a single-hop LEFT JOIN overwrite (every vehicle got a copy of the SAME payload).
--   - CV is a TWO-HOP LISTAGG chain: SEQ62 rows get LISTAGG'd by SEQ63 on the wrong key, then
--     SEQ63's own (already-per-vehicle) rows get LISTAGG'd AGAIN by SEQ67 on the wrong key.
--     Net effect: every vehicle's final <VehicleCoverage> XML block contains every OTHER
--     vehicle's sub-coverage AND coverage entries concatenated together -- confirmed live via
--     policy P00009911|CML00000309|575099 (3 vehicles), whose rendered BP_CV_vehicle_Cov payload
--     contains 3 different <CMP_SD> "Comprehensive Property" blocks with 3 different <iValue>
--     amounts (121500 / 309200 / 0) and 2 different <OHL_SD> blocks -- all inside ONE vehicle's XML.
--
-- Root cause: CV_COVERAGE_VEHICLE_SUBCOV (SEQ62) and CV_COVERAGE_VEHICLE_COV (SEQ63) both build
-- their key as policy|cml|expiringid_p -- WITHOUT vehicleid -- even though vehicleid is available
-- and is already correctly used by CV_MOTOR_EXCESS/CV_MOTOR_CLAUSE/CV_MOTOR_UW (SEQ64-66) and by
-- CV_RISK_COV_FINAL_VIEW's own PUREPOLICYNUMBER (SEQ67, line 72). SEQ67 also computes a second,
-- deliberately policy-level key (WITHOUT_VEHID_PUREPOLICYNUMBER) for a different purpose, and
-- mistakenly joins CV_VEHICLE_COV against that policy-level key instead of the vehicle-level one.
--
-- Live impact (cm_03, 2026-07-12):
--   44,836 total CV vehicle rows / 11,438 distinct policy|cml|expiringid_p keys.
--   8,256 of those keys (72.2%) hold more than one distinct VEHICLEID.
--   5,017 of those keys (43.9% of all keys) have vehicles with GENUINELY DIFFERENT ProtectionType
--     values sharing one key -- i.e. not just theoretically at risk like Fleet, but actively
--     producing contradictory data today.
--   29,327 of 44,836 vehicle rows (65.4%) sit inside a contaminated key group.
--   This is the largest-scale, highest-severity issue found in the BP gap-analysis pass to date.
--
-- Fix: widen SEQ62 and SEQ63's key to include VEHICLEID (matching SEQ64-67's existing pattern),
-- and repoint SEQ67's CV_VEHICLE_COV join at the vehicle-level key instead of the policy-level one.
-- SEQ63's join to VW_OUTPUT_COVERAGE_BSP (CMEXPPREM/CMNOVEHS/CMCLMCNT/CMCLMINCD) stays on the
-- policy-level key -- confirmed live that source table is genuinely one row per policy|cml|
-- expiringid_p (fleet-wide totals), not per vehicle, so it must NOT be widened.
--
-- After applying: RISK_FLEET_VEHICLE_TARGET-equivalent table for CV is AGGNE.DEV.CV_FLEET_VEHICLE_TARGET.
-- Same DYNAMIC_XML_V1 caveat as G-BP-88 -- it never truncates and never auto-refreshes -- so the
-- stale policy-level rows for ITR_TYPE IN ('BP_CV_Vehicle_SubCov','BP_CV_vehicle_Cov') must be
-- deleted and re-rendered after these view changes. See G-BP-90_rerun_seq62_63.py.

-- ============================================================
-- STEP 1: CV_COVERAGE_VEHICLE_SUBCOV (SEQ 62) -- widen key to include VEHICLEID
-- ============================================================
create or replace view CV_COVERAGE_VEHICLE_SUBCOV(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	POLICYNUMBER,
	EXPIRINGID_P,
	VEHICLEID,
	PROTECTIONTYPE,
	CMTYPE,
	CMCODE,
	EXPPREMIUM,
	ACCESSORIESVALUE
) as
with base as (SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, protectiontype, NVL(CAST(cmcvagreedvalue AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
UNION ALL
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, 'choiceofrepair' AS protectiontype, NVL(CAST(cmcvchoicerepair AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
UNION ALL
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, 'OnHookTowingProtection' AS protectiontype, NVL(CAST(cmcvcoverhookliab AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
union all
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, 'HireCarHireAfterIncident' AS protectiontype, NVL(CAST(cmcvcarhire AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
union all
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(TRIM(VEHICLEID),'0') AS VEHICLEID, 'ExcessWaiverForGlass' AS protectiontype, NVL(CAST(cmcvunlimglass AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03),
SUB_COV_EXP_PRM AS (select POLICYNUMBER, sub_coverage,EXPIRINGID_P, CMLNUMBER as CLAIMNUMBER,CMLNUMBER,EXPPREMIUM from AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP where sub_coverage like 'CM%'),
-- FIX (G-BP-90): appended VEHICLEID so this key is unique per vehicle, matching SEQ64-67.
CM_BASE AS (select  CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) ||'|' || TRIM(vehicleid) AS VARCHAR) AS purepolicynumber,cmlnumber,PUREPOLICYNUMBER AS POLICYNUMBER,expiringid_p,vehicleid,CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'Comprehensive Property'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'Comprehensive Property'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'Fire &amp; Theft excluding Liability'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'On Hook Liability'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'Unlimited Glass'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'Third Party Only'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'Third Party Fire &amp; Theft'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'Choice of Repairer'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'Car Hire'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'Comprehensive Liability'
            end as PROTECTIONTYPE ,
CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'CMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'CMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'FTL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'OHL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'ULG_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'TPO_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'TFT_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'COR_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'PCH_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'LIA_SD'
                ELSE ''
            END AS CMTYPE,CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'CMCMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'CMCMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'CMFTL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'CMOHL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'CMULG_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'CMTPO_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'CMTFT_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'CMCOR_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'CMPCH_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'CMLIA_SD'
                ELSE ''
            END AS CMCODE,NVL(CAST(marketvaluewithoutaccessories AS VARCHAR),0) AS accessoriesvalue from base)
SELECT purepolicynumber,A.cmlnumber,A.POLICYNUMBER,A.expiringid_p,vehicleid,PROTECTIONTYPE,CMTYPE,CMCODE,CAST(EXPPREMIUM AS VARCHAR) AS EXPPREMIUM,accessoriesvalue FROM CM_BASE A
left join SUB_COV_EXP_PRM B ON TRIM(A.POLICYNUMBER) = TRIM(B.POLICYNUMBER)
AND TRIM(A.cmlnumber) = TRIM(B.cmlnumber)
AND TRIM(A.CMCODE) = TRIM(B.sub_coverage);

-- ============================================================
-- STEP 2: CV_COVERAGE_VEHICLE_COV (SEQ 63) -- widen output key to include VEHICLEID,
-- keep the VW_OUTPUT_COVERAGE_BSP join on the policy-level key (that source is genuinely
-- fleet-wide, confirmed one row per policy|cml|expiringid_p live).
-- ============================================================
create or replace view CV_COVERAGE_VEHICLE_COV(
	PUREPOLICYNUMBER,
	TYPE,
	MARKETVALUEWITHACCESSORIESAMOUNT,
	SUBCOV_XML,
	CLAIMNUMBER,
	EXPIRYDATE,
	CMEXPPREM,
	CMNOVEHS,
	CMCLMCNT,
	CMCLMINCD
) as
with cv_table as (select distinct
CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) ||'|' || TRIM(vehicleid) AS VARCHAR) AS PUREPOLICYNUMBER,
-- FIX (G-BP-90): separate policy-level key retained ONLY for the VW_OUTPUT_COVERAGE_BSP join below.
CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS POLICY_LEVEL_KEY,
cmlnumber, purepolicynumber AS legacypolicynumber, expiringid_p, vehicleid,'CommercialVehicle' as Type, 'Default' as FleetType,CAST(CMCVAGREEDVALUE AS VARCHAR) as marketvaluewithaccessoriesamount from AGGNE.DEV.cm_03),
cv_coverage_xml as (select id, LISTAGG(payload,'') WITHIN GROUP (ORDER BY id) AS subcov_xml from AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
where itr_type = 'BP_CV_Vehicle_SubCov'
group by id)
select distinct t1.PUREPOLICYNUMBER,Type,
marketvaluewithaccessoriesamount,
subcov_xml,TRIM(t1.CMLNUMBER) as claimnumber,CAST(expirydate AS VARCHAR) AS expirydate,
CAST(cmexpprem AS VARCHAR) AS cmexpprem,
CAST(cmnovehs AS VARCHAR) AS cmnovehs,
CAST(cmclmcnt AS VARCHAR) AS cmclmcnt,
CAST(cmclmincd AS VARCHAR)  AS cmclmincd
from
cv_table t1 left join cv_coverage_xml t2
on trim(t1.PUREPOLICYNUMBER) = trim(t2.id)
left join AGGNE.DEV.VW_OUTPUT_COVERAGE_BSP t3
on trim(t1.POLICY_LEVEL_KEY) = trim(t3.purepolicynumber);

-- ============================================================
-- STEP 3: CV_RISK_COV_FINAL_VIEW (SEQ 67) -- repoint the CV_VEHICLE_COV join at the
-- vehicle-level key (PUREPOLICYNUMBER), matching how CV_MOTOR_EXCESS/CLAUSES/UW already join.
-- Only the final join line changes; everything else is unchanged from live GET_DDL.
-- ============================================================
create or replace view CV_RISK_COV_FINAL_VIEW(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	TYPE,
	FLEETTYPE,
	CMLNUMBER,
	EXPIRINGID_P,
	VEHICLEID,
	REGISTRATIONNUMBER,
	CMRBVEHICLEKEY,
	STATE,
	VEHICLETYPE,
	MAKE,
	MODEL,
	YEAR,
	DESCRIPTION,
	BODYTYPE,
	ENGINESIZE,
	NUMBEROFCYLINDERS,
	DRIVEDESCRIPTION,
	INDUCTIONTYPE,
	GROSSVEHICLEMASS,
	MARKETVALUEWITHACCESSORIESAMOUNT,
	MARKETVALUEWITHOUTACCESSORIESAMOUNT,
	VALUEWITHOUTACCESSORIES,
	MARKETVALUEDESCRIPTION,
	MARKETVALUEDESCRIPTIONVALUE,
	AGREEDVALUEDESCRIPTION,
	AGREEDVALUEDESCRIPTIONVALUE,
	AGREEDVALUEAMOUNT,
	PROTECTIONTYPE,
	HIGHESTRISKUSE,
	ONHOOKTOWINGPROTECTION,
	CHOICEOFREPAIR,
	EXCESSWAIVERFORGLASS,
	HIRECARHIREAFTERINCIDENT,
	AGEOFYOUNGESTREGULARDRIVER,
	RESTRICTIONOFDRIVERAGE,
	HOWOFTEN,
	HOWOFTENISTHEVEHICLEUSED,
	ISTHEVEHICLEUSEDFORMEMBERSBUSINESSNEEDSONLY,
	WOULDYOULIKETOADDACCESSORIESORMODIFICATIONS,
	DOESTHEVEHICLEHAVEANINTERESTEDPARTY,
	ADDDETAILSFORTHEINTERESTEDPARTY,
	HOWMANYVEHICLESISYOURVEHICLEEQUIPPEDTOCARRYATANYONETIME,
	VEHICLETRANSPORTHAZARDOUSDANGEROUSGOODS,
	ISTHEVEHICLEUSEDTOTRANSPORTANYCUSTOMERITEMSREWARD,
	MAXIMUMRANGEVEHICLEWILLTRAVELBUSINESSUSE,
	IFPRIMEMOVERWILLITTOWMORETHAN1TRAILERATTIME,
	ISTHISVEHICLEUSEDFORRIDESHAREOPERATION,
	AREHIRECONTRACTSRESTRICTEDTONAMEDDRIVERSONLY,
	AREANYVEHICLESDRIVERSUPPLIED,
	WILLANYCONTRACTORSOPERATETHISVEHICLE,
	WILLTHISVEHICLEBEUSEDTODELIVERDANGEROUSGOODS,
	DETAILS,
	OVERRIDE,
	DETAILSMEMBUS,
	DETAILSCUSTITEM,
	DRIVEBYDIRECTEMP,
	DETAILSDIRECTEMP,
	CONTRACTRESTRICTION,
	DETAILSTOWGT1,
	CV_MOTOR_EXCESS,
	CV_MOTOR_CLAUSES,
	CV_MOTOR_UW,
	CV_VEHICLE_COV,
	VEHICLEINFOOVERRIDE,
	IMPORTFLAG
) as
WITH CV_MOTOR_MAIN AS (
   SELECT
        CAST(TRIM(PUREPOLICYNUMBER) || '|' || TRIM(CMLNUMBER) || '|' || TRIM(EXPIRINGID_P)|| '|' || TRIM(VEHICLEID) AS VARCHAR) AS PUREPOLICYNUMBER,
        CAST(TRIM(PUREPOLICYNUMBER) || '|' || TRIM(CMLNUMBER) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS WITHOUT_VEHID_PUREPOLICYNUMBER,
        CMLNUMBER,
        PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        EXPIRINGID_P,
        VEHICLEID,

        'CommercialVehicle' AS TYPE,
        'Default' AS FLEETTYPE,
        TO_VARCHAR(CMCVAgreedValue) AS VALUEWITHOUTACCESSORIES,
        REGISTRATIONNUMBER,
        CMRBVEHICLEKEY,
        (
            COALESCE(MVVALUEWITHOUTACCESSORIES, 0)
            + COALESCE(MARKETVALUEDESCRIPTIONVALUE, 0)
        ) AS MARKETVALUEWITHACCESSORIESAMOUNT,

CASE
  WHEN TRIM(PROTECTIONTYPE) = 'Third Party, Fire and Theft'  THEN 'ThirdPartyFireandTheft'
  WHEN TRIM(PROTECTIONTYPE) = 'Comprehensive - Market Value' THEN 'ComprehensiveMarket'
  WHEN TRIM(PROTECTIONTYPE) = 'Comprehensive - Agreed Value' THEN 'ComprehensiveAgreedValue'
  WHEN TRIM(PROTECTIONTYPE) = 'Fire and Theft'               THEN 'FireandTheft'
  WHEN TRIM(PROTECTIONTYPE) = 'Third Party Only'             THEN 'ThirdPartyOnly'
  ELSE ''  -- or a default like 'Unknown'
END as PROTECTIONTYPE,

CASE
  WHEN TRIM(HighestRiskUse) ILIKE 'General Business' THEN 'Business'
  WHEN TRIM(HighestRiskUse) ILIKE 'Delivery'         THEN 'Delivery'
  WHEN TRIM(HighestRiskUse) ILIKE 'Courtesy'         THEN 'Courtesy'
  WHEN TRIM(HighestRiskUse) ILIKE 'Hire'             THEN 'Hire'
  ELSE ''
END AS HIGHESTRISKUSE,
        ONHOOKTOWINGPROTECTION,
        case when trim(CHOICEOFREPAIR) = 'Taken' then 1 else 0 end as CHOICEOFREPAIR,
        case when hirecarhireafterincident = '' then 'NotTaken'
		when hirecarhireafterincident = 'Not Taken' then 'NotTaken'
		else hirecarhireafterincident end AS HIRECARHIREAFTERINCIDENT,
        CASE WHEN TRIM(EXCESSWAIVERFORGLASS) = 'Yes' then 1 else 0 end as EXCESSWAIVERFORGLASS,
        STATE,

CASE
    WHEN TRIM(VEHICLETYPE) = 'Passenger Vehicle' THEN 'PassengerVehicle'
    WHEN TRIM(VEHICLETYPE) = 'Camper Van' THEN 'CamperVan'
    WHEN TRIM(VEHICLETYPE) = 'Caravan' THEN 'Caravan'
    WHEN TRIM(VEHICLETYPE) = 'Forklift' THEN 'Forklift'
    WHEN TRIM(VEHICLETYPE) = 'Motorcycle' THEN 'Motorcycle'
    WHEN TRIM(VEHICLETYPE) = 'Trailer' THEN 'Trailer'
    WHEN TRIM(VEHICLETYPE) = 'Light Commercial' THEN 'LightCommercial'
    WHEN TRIM(VEHICLETYPE) = 'Heavy Commercial' THEN 'HeavyCommercial'
WHEN TRIM(VEHICLETYPE) = 'Mobile Equipment' THEN 'MobileEquipment'
WHEN TRIM(VEHICLETYPE) = 'Tow Truck' THEN 'TowTruck'
WHEN TRIM(VEHICLETYPE) = 'Transporter' THEN 'Transporter'
WHEN TRIM(VEHICLETYPE) = 'Heavy Vehicle' THEN 'HeavyVehicle'
WHEN TRIM(VEHICLETYPE) = 'Tractor' THEN 'Tractor'  END AS VEHICLETYPE,
        MAKE,
        MODEL,
        YEAR,
        DESCRIPTION,

CASE
  WHEN TRIM(BodyType) = 'B-double'         THEN 'B-double'
  WHEN TRIM(BodyType) = 'Bus'              THEN 'Bus'
  WHEN TRIM(BodyType) = 'Bus Chassis'      THEN 'BusChassis'
  WHEN TRIM(BodyType) = 'Cab Chassis'      THEN 'CabChassis'
  WHEN TRIM(BodyType) = 'Cabriolet'        THEN 'Cabriolet'
  WHEN TRIM(BodyType) = 'Compactor'        THEN 'Compactor'
  WHEN TRIM(BodyType) = 'Convertible'      THEN 'Convertible'
  WHEN TRIM(BodyType) = 'Coupe'            THEN 'Coupe'
  WHEN TRIM(BodyType) = 'Distributor'      THEN 'Distributor'
  WHEN TRIM(BodyType) = 'Dump'             THEN 'Dump'
  WHEN TRIM(BodyType) = 'Extra Heavy Duty' THEN 'ExtraHeavyDuty'
  WHEN TRIM(BodyType) = 'Fastback'         THEN 'Fastback'
  WHEN TRIM(BodyType) = 'Hardtop'          THEN 'Hardtop'
  WHEN TRIM(BodyType) = 'Hatchback'        THEN 'Hatchback'
  WHEN TRIM(BodyType) = 'Heavy Duty'       THEN 'HeavyDuty'
  WHEN TRIM(BodyType) = 'Highway'          THEN 'Highway'
  WHEN TRIM(BodyType) = 'Liftback'         THEN 'Liftback'
  WHEN TRIM(BodyType) = 'Limousine'        THEN 'Limousine'
  WHEN TRIM(BodyType) = 'Mixer'            THEN 'Mixer'
  WHEN TRIM(BodyType) = 'Prime Mover'      THEN 'PrimeMover'
  WHEN TRIM(BodyType) = 'Rigid'            THEN 'Rigid'
  WHEN TRIM(BodyType) = 'Road Train'       THEN 'RoadTrain'
  WHEN TRIM(BodyType) = 'Roadster'         THEN 'Roadster'
  WHEN TRIM(BodyType) = 'Sedan'            THEN 'Sedan'
  WHEN TRIM(BodyType) = 'Softtop'          THEN 'Softtop'
  WHEN TRIM(BodyType) = 'Street Sweeper'   THEN 'StreetSweeper'
  WHEN TRIM(BodyType) = 'Targa'            THEN 'Targa'
  WHEN TRIM(BodyType) = 'Tipper'           THEN 'Tipper'
  WHEN TRIM(BodyType) = 'Traytop'          THEN 'Traytop'
  WHEN TRIM(BodyType) = 'Utility'          THEN 'Utility'
  WHEN TRIM(BodyType) = 'Van'              THEN 'Van'
  WHEN TRIM(BodyType) = 'Van Wagon'        THEN 'VanWagon'
  WHEN TRIM(BodyType) = 'Wagon'            THEN 'Wagon'
  ELSE  TRIM(BodyType)  -- or a default like 'Unknown'
END as BODYTYPE
,
        ENGINESIZE,
        CAST(NUMBEROFCYLINDERS AS INT) AS NUMBEROFCYLINDERS,


        case
when trim(upper(DRIVEDESCRIPTION))=upper('4 wheel drive') then '4wheeldrive'
when trim(upper(DRIVEDESCRIPTION))=upper('Four Wheel Drive') then '4wheeldrive'
when trim(upper(DRIVEDESCRIPTION))=upper('Rear wheel drive') then 'Rearwheeldrive'
when trim(upper(DRIVEDESCRIPTION))=upper('Front Wheel Drive') then 'Frontwheeldrive' else 'N/A' end as DRIVEDESCRIPTION,

CASE
  WHEN TRIM(INDUCTIONTYPE) = 'Aspirated'                      THEN 'Aspirated'
  WHEN TRIM(INDUCTIONTYPE) = 'Supercharged Intercooled'       THEN 'Supercharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Twin Supercharged Intercooled'  THEN 'Supercharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Supercharged'                   THEN 'Supercharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Turbo'                          THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Turbo Intercooled'              THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Twin Turbo Intercooled'         THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Triple Turbo Intercooled'       THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Quad Turbo Intercooled'         THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Turbo Supercharged Intercooled' THEN 'TurboandSupercharged'
  ELSE TRIM(INDUCTIONTYPE)  -- or a default like 'Unknown'
END AS INDUCTIONTYPE,
        GROSSVEHICLEMASS,

        -- FIXED ALIAS
        CAST(CMCVAgreedValue AS VARCHAR) AS MARKETVALUEWITHOUTACCESSORIESAMOUNT,

        case when trim(protectiontype) = 'Comprehensive - Market Value' and mvaddaccormods='Yes' then 'Yes'
when trim(protectiontype) = 'Comprehensive - Agreed Value' and avaddaccormods='Yes' then 'Yes' else 'No' end
 AS WOULDYOULIKETOADDACCESSORIESORMODIFICATIONS,
        AGREEDVALUEDESCRIPTION as AGREEDVALUEDESCRIPTION,
        cast(AGREEDVALUEDESCRIPTIONVALUE as int) as AGREEDVALUEDESCRIPTIONVALUE,

        TO_VARCHAR(
            COALESCE(TO_DECIMAL(CMCVAgreedValue, 38, 4), 0)
            + COALESCE(TO_DECIMAL(AGREEDVALUEDESCRIPTIONVALUE, 38, 4), 0)
        ) AS AGREEDVALUEAMOUNT,

        MARKETVALUEDESCRIPTION,
        cast(MARKETVALUEDESCRIPTIONVALUE as int) as MARKETVALUEDESCRIPTIONVALUE,
        AGEOFYOUNGESTREGULARDRIVER as AGEOFYOUNGESTREGULARDRIVER,

CASE
  WHEN TRIM(RestrictionOfDriverAge) = 'No Restriction' THEN 0
  WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 21'     THEN 20
  WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 25'     THEN 24
  WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 30'     THEN 29
  WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 40'     THEN 39
  ELSE 0  -- or a default code, e.g., -1
END ::varchar as RESTRICTIONOFDRIVERAGE
,
         case when CMCVTPFinInterest = 1 then 1 else 0 end AS DOESTHEVEHICLEHAVEANINTERESTEDPARTY,
        detfortheparty AS ADDDETAILSFORTHEINTERESTEDPARTY,
        CMCVCarryingVehs AS HOWMANYVEHICLESISYOURVEHICLEEQUIPPEDTOCARRYATANYONETIME,

CASE
  WHEN TRIM(HOWOFTEN) = 'Daily'         THEN 'Daily'
  WHEN TRIM(HOWOFTEN) = 'Weekly'        THEN 'Weekly'
  WHEN TRIM(HOWOFTEN) = 'Less Frequent' THEN 'LessFrequent'
  ELSE ''  -- or a default like 'Unknown'
END AS HOWOFTEN
,
        FREQOFVEHUSE AS HOWOFTENISTHEVEHICLEUSED,
        FORMEMBUS AS ISTHEVEHICLEUSEDFORMEMBERSBUSINESSNEEDSONLY,
        CMCVTransHazGoods AS VEHICLETRANSPORTHAZARDOUSDANGEROUSGOODS,
        TRANSPORTCUSTITEM AS ISTHEVEHICLEUSEDTOTRANSPORTANYCUSTOMERITEMSREWARD,
        CMCVRadiusFromBase AS MAXIMUMRANGEVEHICLEWILLTRAVELBUSINESSUSE,
        PRIMEMOVERTOWGT1TRAILER AS IFPRIMEMOVERWILLITTOWMORETHAN1TRAILERATTIME,
        RIDESHARE AS ISTHISVEHICLEUSEDFORRIDESHAREOPERATION,
        CONTRACTRESTRICTION AS AREHIRECONTRACTSRESTRICTEDTONAMEDDRIVERSONLY,
        HIREVEHDRIVERSUPPLIED AS AREANYVEHICLESDRIVERSUPPLIED,
        CONTRACTOROPERATE AS WILLANYCONTRACTORSOPERATETHISVEHICLE,
        DELIVERDANGEROUSGOOD AS WILLTHISVEHICLEBEUSEDTODELIVERDANGEROUSGOODS,
        -- CASE WHEN TRIM(OVERRIDE) = 'Yes' THEN 1 ELSE 0 END AS OVERRIDE, -- as per capricron&vihari request  defaulting to 1
       '1' as OVERRIDE,
        CASE WHEN UPPER(TRIM(detailsmembus))       = 'TRUE' THEN '1' ELSE '0' END AS detailsmembus,
  CASE WHEN UPPER(TRIM(DetailsCustItem))     = 'TRUE' THEN '1' ELSE '0' END AS DetailsCustItem,
  CASE WHEN UPPER(TRIM(DriveByDirectEmp))    = 'TRUE' THEN '1' ELSE '0' END AS DriveByDirectEmp,
  CASE WHEN UPPER(TRIM(DetailsDirectEmp))    = 'TRUE' THEN '1' ELSE '0' END AS DetailsDirectEmp,
  CASE WHEN UPPER(TRIM(ContractRestriction)) = 'TRUE' THEN '1' ELSE '0' END AS ContractRestriction,
  CASE WHEN UPPER(TRIM(DetailsTowGT1))       = 'TRUE' THEN '1' ELSE '0' END AS DetailsTowGT1,
  details,
   -- CASE WHEN UPPER(TRIM(OVERRIDE))       = 'YES' THEN '1' ELSE '0' END AS VEHICLEINFOOVERRIDE,
   '1' as  VEHICLEINFOOVERRIDE,  -- as per capricron&vihari request  defaulting to 1
   case when coalesce(IMPORTFLAG,'')='' then 'N/A' else IMPORTFLAG end  IMPORTFLAG
  FROM AGGNE.DEV.CM_03 WHERE EXPIRYDATE>='2026-01-01' and YEAR<>0 and MAKE<>'' and MODEL<>''

),

CV_MOTOR_EXCESS AS (
    SELECT id, LISTAGG(payload, '') WITHIN GROUP (ORDER BY id) AS CV_MOTOR_EXCESS
    FROM AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
    WHERE itr_type = 'BP_CV_Motor_Excess'
    GROUP BY id
),

CV_MOTOR_CLAUSES AS (
    SELECT id, LISTAGG(payload, '') WITHIN GROUP (ORDER BY id) AS CV_MOTOR_CLAUSES
    FROM AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
    WHERE itr_type = 'BP_CV_Motor_Clauses'
    GROUP BY id
),

CV_MOTOR_UW AS (
    SELECT id, LISTAGG(payload, '') WITHIN GROUP (ORDER BY id) AS CV_MOTOR_UW
    FROM AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
    WHERE itr_type = 'BP_CV_Motor_UW'
    GROUP BY id
),

CV_VEHICLE_COV AS (
    SELECT id, LISTAGG(payload, '') WITHIN GROUP (ORDER BY id) AS CV_VEHICLE_COV
    FROM AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
    WHERE itr_type = 'BP_CV_vehicle_Cov'
    GROUP BY id
)

SELECT
    a.PUREPOLICYNUMBER,
    TRIM(a.LEGACYPOLICYNUMBER) AS LEGACYPOLICYNUMBER,
    a.TYPE,
    a.FLEETTYPE,
    -- CAST everything else from a.*
    CAST(a.CMLNUMBER AS VARCHAR) AS CMLNUMBER,
    CAST(a.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
    CAST(a.VEHICLEID AS VARCHAR) AS VEHICLEID,
    CAST(a.REGISTRATIONNUMBER AS VARCHAR) AS REGISTRATIONNUMBER,
     CAST(a.CMRBVEHICLEKEY AS VARCHAR) AS CMRBVEHICLEKEY,

    CAST(a.STATE AS VARCHAR) AS STATE,
    CAST(a.VEHICLETYPE AS VARCHAR) AS VEHICLETYPE,
    CAST(a.MAKE AS VARCHAR) AS MAKE,
    CAST(a.MODEL AS VARCHAR) AS MODEL,
    CAST(a.YEAR AS VARCHAR) AS YEAR,
    CAST(a.DESCRIPTION AS VARCHAR) AS DESCRIPTION,
    CAST(a.BODYTYPE AS VARCHAR) AS BODYTYPE,
    CAST(a.ENGINESIZE AS VARCHAR) AS ENGINESIZE,
    CAST(a.NUMBEROFCYLINDERS AS VARCHAR) AS NUMBEROFCYLINDERS,
    CAST(a.DRIVEDESCRIPTION AS VARCHAR) AS DRIVEDESCRIPTION,
    CAST(a.INDUCTIONTYPE AS VARCHAR) AS INDUCTIONTYPE,
    CAST(a.GROSSVEHICLEMASS AS VARCHAR) AS GROSSVEHICLEMASS,
    CAST(a.MARKETVALUEWITHACCESSORIESAMOUNT AS VARCHAR) AS MARKETVALUEWITHACCESSORIESAMOUNT,
    CAST(a.MARKETVALUEWITHOUTACCESSORIESAMOUNT AS VARCHAR) AS MARKETVALUEWITHOUTACCESSORIESAMOUNT,
    VALUEWITHOUTACCESSORIES,
    CAST(a.MARKETVALUEDESCRIPTION AS VARCHAR) AS MARKETVALUEDESCRIPTION,
    CAST(a.MARKETVALUEDESCRIPTIONVALUE AS VARCHAR) AS MARKETVALUEDESCRIPTIONVALUE,
    CAST(a.AGREEDVALUEDESCRIPTION AS VARCHAR) AS AGREEDVALUEDESCRIPTION,
    CAST(a.AGREEDVALUEDESCRIPTIONVALUE AS VARCHAR) AS AGREEDVALUEDESCRIPTIONVALUE,
    CAST(a.AGREEDVALUEAMOUNT AS VARCHAR) AS AGREEDVALUEAMOUNT,
    CAST(a.PROTECTIONTYPE AS VARCHAR) AS PROTECTIONTYPE,
    CAST(a.HIGHESTRISKUSE AS VARCHAR) AS HIGHESTRISKUSE,
    CAST(a.ONHOOKTOWINGPROTECTION AS VARCHAR) AS ONHOOKTOWINGPROTECTION,
    CAST(a.CHOICEOFREPAIR AS VARCHAR) AS CHOICEOFREPAIR,
    CAST(a.EXCESSWAIVERFORGLASS AS VARCHAR) AS EXCESSWAIVERFORGLASS,
    CAST(a.HIRECARHIREAFTERINCIDENT AS VARCHAR) AS HIRECARHIREAFTERINCIDENT,
    CAST(a.AGEOFYOUNGESTREGULARDRIVER AS VARCHAR) AS AGEOFYOUNGESTREGULARDRIVER,
    CAST(a.RESTRICTIONOFDRIVERAGE AS VARCHAR) AS RESTRICTIONOFDRIVERAGE,
    CAST(a.HOWOFTEN AS VARCHAR) AS HOWOFTEN,
    CAST(a.HOWOFTENISTHEVEHICLEUSED AS VARCHAR) AS HOWOFTENISTHEVEHICLEUSED,
    CAST(a.ISTHEVEHICLEUSEDFORMEMBERSBUSINESSNEEDSONLY AS VARCHAR) AS ISTHEVEHICLEUSEDFORMEMBERSBUSINESSNEEDSONLY,
   case when CAST(a.WOULDYOULIKETOADDACCESSORIESORMODIFICATIONS AS VARCHAR) ='Yes' then '1' else '0' end AS WOULDYOULIKETOADDACCESSORIESORMODIFICATIONS,
    CAST(a.DOESTHEVEHICLEHAVEANINTERESTEDPARTY AS VARCHAR) AS DOESTHEVEHICLEHAVEANINTERESTEDPARTY,
    CAST(a.ADDDETAILSFORTHEINTERESTEDPARTY AS VARCHAR) AS ADDDETAILSFORTHEINTERESTEDPARTY,
    CAST(a.HOWMANYVEHICLESISYOURVEHICLEEQUIPPEDTOCARRYATANYONETIME AS VARCHAR) AS HOWMANYVEHICLESISYOURVEHICLEEQUIPPEDTOCARRYATANYONETIME,
    CAST(a.VEHICLETRANSPORTHAZARDOUSDANGEROUSGOODS AS VARCHAR) AS VEHICLETRANSPORTHAZARDOUSDANGEROUSGOODS,
    CAST(a.ISTHEVEHICLEUSEDTOTRANSPORTANYCUSTOMERITEMSREWARD AS VARCHAR) AS ISTHEVEHICLEUSEDTOTRANSPORTANYCUSTOMERITEMSREWARD,
    CAST(a.MAXIMUMRANGEVEHICLEWILLTRAVELBUSINESSUSE AS VARCHAR) AS MAXIMUMRANGEVEHICLEWILLTRAVELBUSINESSUSE,
    CAST(a.IFPRIMEMOVERWILLITTOWMORETHAN1TRAILERATTIME AS VARCHAR) AS IFPRIMEMOVERWILLITTOWMORETHAN1TRAILERATTIME,
    CAST(a.ISTHISVEHICLEUSEDFORRIDESHAREOPERATION AS VARCHAR) AS ISTHISVEHICLEUSEDFORRIDESHAREOPERATION,
    CAST(a.AREHIRECONTRACTSRESTRICTEDTONAMEDDRIVERSONLY AS VARCHAR) AS AREHIRECONTRACTSRESTRICTEDTONAMEDDRIVERSONLY,
    CAST(a.AREANYVEHICLESDRIVERSUPPLIED AS VARCHAR) AS AREANYVEHICLESDRIVERSUPPLIED,
    CAST(a.WILLANYCONTRACTORSOPERATETHISVEHICLE AS VARCHAR) AS WILLANYCONTRACTORSOPERATETHISVEHICLE,
    CAST(a.WILLTHISVEHICLEBEUSEDTODELIVERDANGEROUSGOODS AS VARCHAR) AS WILLTHISVEHICLEBEUSEDTODELIVERDANGEROUSGOODS,
    cast(a.details AS VARCHAR) as DETAILS,
	CAST(a.OVERRIDE as VARCHAR) AS OVERRIDE,
    detailsmembus,
  DetailsCustItem,
  DriveByDirectEmp,
  DetailsDirectEmp,
  ContractRestriction,
  DetailsTowGT1,
    b.CV_MOTOR_EXCESS,
    c.CV_MOTOR_CLAUSES,
    d.CV_MOTOR_UW,
    e.CV_VEHICLE_COV,
    a.VEHICLEINFOOVERRIDE,
    a.IMPORTFLAG

FROM CV_MOTOR_MAIN a
LEFT JOIN CV_MOTOR_EXCESS b ON a.PUREPOLICYNUMBER = b.ID
left JOIN CV_MOTOR_CLAUSES c ON a.PUREPOLICYNUMBER = c.ID
LEFT JOIN CV_MOTOR_UW d ON a.PUREPOLICYNUMBER = d.ID
-- FIX (G-BP-90): was a.WITHOUT_VEHID_PUREPOLICYNUMBER = e.ID (policy-level, wrong).
-- Now matches the vehicle-level key, same as the three joins above.
LEFT JOIN CV_VEHICLE_COV e ON a.PUREPOLICYNUMBER = e.ID;

-- ============================================================
-- POST-CHECK 1: SEQ62/63's own key granularity -- expect near-1 vehicles per key now
-- (run only after G-BP-90_rerun_seq62_63.py has re-populated CV_FLEET_VEHICLE_TARGET)
-- ============================================================
-- SELECT COUNT(*) AS keys, SUM(CASE WHEN vc>1 THEN 1 ELSE 0 END) AS still_shared
-- FROM (SELECT PUREPOLICYNUMBER, COUNT(*) vc FROM AGGNE.DEV.CV_COVERAGE_VEHICLE_SUBCOV GROUP BY 1);

-- ============================================================
-- POST-CHECK 2: spot check -- the P00009911 policy should now show 3 DIFFERENT SUBCOV_XML
-- lengths/content (one per vehicle) instead of 1 shared blob.
-- ============================================================
-- SELECT PUREPOLICYNUMBER, LEN(SUBCOV_XML) FROM AGGNE.DEV.CV_COVERAGE_VEHICLE_COV
-- WHERE PUREPOLICYNUMBER LIKE 'P00009911|CML00000309|575099%';

-- ============================================================
-- POST-CHECK 3: no more duplicate <coverage> Type blocks inside one vehicle's final payload
-- ============================================================
-- SELECT ID, PAYLOAD FROM AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
-- WHERE ITR_TYPE='BP_CV_vehicle_Cov' AND ID LIKE 'P00009911|CML00000309|575099%';
