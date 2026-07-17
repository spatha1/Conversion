-- STANDALONE: PER_COM_PAYLOAD, run this whole file as one statement.
-- SUPERSEDES BUGFIX_PER_COM_PAYLOAD_MarketValueFallback_20260715.sql (includes everything from it
-- plus the STATE column below -- do not deploy both, deploy this one).
--
-- Adds: STATE column, sourced from PM_03.STATE (real per-vehicle garaging/rating state, well-
-- populated: VIC/WA/NSW/NZ/QLD/SA/TAS/NT/ACT). Companion fix to
-- BUGFIX_PP_CONVERSION_RUN_MotorState_20260715.sql, which changes the SP's hardcoded
-- <State>NSW</State> to <State>{STATE}</State>. DEPLOY THIS VIEW FIRST, then the SP fix, then
-- regenerate -- the SP's {STATE} token has nothing to substitute until this column exists.

create or replace view PER_COM_PAYLOAD(
	PUREPOLICYNUMBER,
	COVERAGE,
	SUBCOV,
	COM_CLAUSE,
	UW,
	MVVALUEWITHOUTACCESSORIES,
	VEHHAVEANINTERESTEDPARTY,
	YEAR,
	MAKE,
	MODEL,
	BODYTYPE,
	MVRBVEHICLEKEY,
	OVERRIDE,
	REGISTRATIONNUMBER,
	ENGINESIZE,
	MARKETVALUEDESCRIPTIONVALUE,
	GROSSVEHICLEMASS,
	MARKETVALUEDESCRIPTION,
	MVADDACCORMODS,
	AGEOFYOUNGESTREGULARDRIVER,
	RESTRICTIONOFDRIVERAGE,
	VOLUNTARYEXCESS,
	PROTECTIONTYPE,
	VEHICLETYPE,
	DESCRIPTION,
	NUMBEROFCYLINDERS,
	DRIVEDESCRIPTION,
	INDUCTIONTYPE,
	IMPORTFLAG,
	MARKETVALUEWITHACCESSORIESAMOUNT,
	AGREEDVALUEAMOUNT,
	ADDDETAILSFORTHEINTERESTEDPARTY,
	HIRECARHIREAFTERINCIDENT,
	CHOICEOFREPAIR,
	EXCESSWAIVERFORGLASS,
	AVVALUEWITHOUTACCESSORIES,
	PMCLMINCD,
	PMCLMCNT,
	PMEXPPREM,
	FUELTYPE,
	POWERKW,
	TRACKREAR,
	STATE,
	LOAD_DATE
) as
with cte_SAMPLE_CBP_LOCATION as
(
select distinct trim(T1.PUREPOLICYNUMBER)AS PUREPOLICYNUMBER ,trim(t1.CMLNUMBER) AS CMLNUMBER,T1.EXPIRINGID_P
from AGGNE.DEV.PM_03 T1
INNER JOIN AGGNE.DEV.SAMPLE_PER
T2 ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
--and
--T1.EXPIRINGID=T2.EXPIRINGID_P
WHERE t1.EXPIRYDATE>='2026-01-01'
),cte_COVERAGES as
(
select distinct trim(PUREPOLICYNUMBER) PUREPOLICYNUMBER,cmlnumber, trim(EXPIRINGID_P) EXPIRINGID_P,'BB' AS CLAUSE,'Motor' AS  COVERAGE,
MVVALUEWITHOUTACCESSORIES,
VEHHAVEANINTERESTEDPARTY,-- yes=1,no=0,
-- MVRBVEHICLEKEY,--redbookcode
YEAR,
INITCAP(make) as make,
INITCAP(MODEL) as MODEL,
BODYTYPE,
OVERRIDE,
REGISTRATIONNUMBER,
ENGINESIZE,
MARKETVALUEDESCRIPTIONVALUE,
GROSSVEHICLEMASS,
MARKETVALUEDESCRIPTION,
MVADDACCORMODS,
AGEOFYOUNGESTREGULARDRIVER,
RESTRICTIONOFDRIVERAGE,
VOLUNTARYEXCESS,
PROTECTIONTYPE,
VEHICLETYPE,
DESCRIPTION,
NUMBEROFCYLINDERS,
DRIVEDESCRIPTION,
INDUCTIONTYPE,
IMPORTFLAG,
MARKETVALUEWITHACCESSORIESAMOUNT,
AGREEDVALUEAMOUNT,
ADDDETAILSFORTHEINTERESTEDPARTY,
HIRECARHIREAFTERINCIDENT,
CHOICEOFREPAIR,
EXCESSWAIVERFORGLASS,
AVVALUEWITHOUTACCESSORIES,
-- CR 2026-07-14: FuelType/Power/TrackRear -- previously not selected anywhere in this view,
-- leaving <FuelType/>, <PowerKW>0</PowerKW>, <TrackRear/> permanently hardcoded blank/zero.
MVRBFUELTYPEDESCRIPTION,
MVRBPOWER,
MVRBTRACKREAR,
-- FIX 2026-07-15: vehicle's real garaging/rating STATE from Pure -- the SP template previously
-- hardcoded <State>NSW</State> for every single vehicle regardless of actual location, confirmed
-- live via a hardcoded literal (not a {TOKEN}) in PP_CONVERSION_RUN. Only ~17% of vehicles are
-- actually NSW (748/4,344) -- this is a likely contributor to Motor rating failing to compute a
-- premium, since State is a core Motor rating input.
STATE
-- G-02 (2026-07-09, client-approved): the YEAR<>0/MAKE<>''/MODEL<>'' filter previously
-- dropped the entire vehicle from the payload when any one of the three was blank. Since
-- renewal runs daily and Pure data completeness varies day to day, a silent full-vehicle
-- drop is worse than sending an incomplete vehicle through: the vehicle (and the rest of
-- its valid fields) now always reaches the XML. Blank Year/Make/Model must instead be
-- caught by the validation report (SP_PP_XML_VALIDATE / PP_XML_VALIDATION_RULES) as a
-- BLANK_REQUIRED finding — see docs/pp_mapping/VALIDATION_RULES.md for the rule catalog.
-- Retired filter, kept for reference: WHERE YEAR<>0 and make<>'' and MODEL<>''
from AGGNE.DEV.PM_03 T1
) ,

-- ATP-10963 companion (2026-07-06): REGISTRATIONNUMBER added for a vehicle-level join.
-- With the SAS blanking retired, Redbook-keyed vehicles now pass the YMM filter — the old
-- policy+term-only join would cross-match every vehicle with every key on multi-vehicle
-- policies, duplicating vehicle payloads with wrong RedbookCodes.
RedBookCode as (select distinct PUREPOLICYNUMBER,MVRBVEHICLEKEY,EXPIRINGID_P,REGISTRATIONNUMBER from AGGNE.DEV.PM_03 where (PUREPOLICYNUMBER ,EXPIRINGID_P)in (select distinct  PUREPOLICYNUMBER ,  EXPIRINGID_P from cte_COVERAGES)   )
 , CTE_EXCESS AS(
SELECT
    CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,T2.cmlnumber,T2.EXPIRINGID_P,t2.COVERAGE,t2.MVVALUEWITHOUTACCESSORIES,
t2.VEHHAVEANINTERESTEDPARTY,-- yes=1,no=0,
t2.YEAR,
t2.MAKE,
t2.MODEL,
t2.BODYTYPE,
t2.OVERRIDE,
t2.REGISTRATIONNUMBER,
t2.ENGINESIZE,
t2.MARKETVALUEDESCRIPTIONVALUE,
t2.GROSSVEHICLEMASS,
t2.MARKETVALUEDESCRIPTION,
t2.MVADDACCORMODS,
t2.AGEOFYOUNGESTREGULARDRIVER,
CASE
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'No Restriction' THEN 0
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'Min Age 21'     THEN 20
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'Min Age 25'     THEN 24
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'Min Age 30'     THEN 29
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'Min Age 40'     THEN 39
  ELSE 0  -- or a default code, e.g., -1
END ::varchar as  RESTRICTIONOFDRIVERAGE,
t2.VOLUNTARYEXCESS,
t2.PROTECTIONTYPE,
t2.VEHICLETYPE,
t2.DESCRIPTION,--&,
t2.NUMBEROFCYLINDERS,
t2.DRIVEDESCRIPTION,
t2.INDUCTIONTYPE,
t2.IMPORTFLAG,
t2.MARKETVALUEWITHACCESSORIESAMOUNT,
t2.AGREEDVALUEAMOUNT,
t2.ADDDETAILSFORTHEINTERESTEDPARTY,
t2.HIRECARHIREAFTERINCIDENT,
t2.CHOICEOFREPAIR,
t2.EXCESSWAIVERFORGLASS,
t2.AVVALUEWITHOUTACCESSORIES,
t2.MVRBFUELTYPEDESCRIPTION,
t2.MVRBPOWER,
t2.MVRBTRACKREAR,
t2.STATE,
t3.MVRBVEHICLEKEY
FROM
cte_SAMPLE_CBP_LOCATION T1
INNER JOIN cte_COVERAGES T2 ON T1.EXPIRINGID_P=T2.EXPIRINGID_P AND TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
LEFT  JOIN RedBookCode T3 ON T3.EXPIRINGID_P=T2.EXPIRINGID_P AND TRIM(T3.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
-- ATP-10963 companion: vehicle-level match — see RedBookCode CTE comment above
AND TRIM(COALESCE(T3.REGISTRATIONNUMBER,'')) = TRIM(COALESCE(T2.REGISTRATIONNUMBER,''))
--and T3.MVRBVEHICLEKEY is not null


)
-- select * from CTE_EXCESS  where PUREPOLICYNUMBER like '%P00012077%'

,CTE_LISTAGG AS(
SELECT
  ID,
  LISTAGG(CASE WHEN ITR_TYPE = 'Risk_CM'            THEN payload END, '\n') AS SUBCOV,
  LISTAGG(CASE WHEN ITR_TYPE = 'PER_PM_BUILDING_UW' THEN payload END, '\n') AS UW,
  LISTAGG(CASE WHEN ITR_TYPE = 'COM_CLAUSE'          THEN payload END, '\n') AS COM_CLAUSE,
  CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE ITR_TYPE IN ('Risk_CM', 'PER_PM_BUILDING_UW', 'COM_CLAUSE')   --AND CAST(LOAD_DATE AS DATE)= CAST(GETDATE() AS DATE)
GROUP BY ID, CAST(LOAD_DATE AS DATE)
)
SELECT distinct
T1.PUREPOLICYNUMBER,
COVERAGE,
CAST(REPLACE(SUBCOV ,'&','&amp;') AS VARCHAR) AS SUBCOV,
CASE WHEN COM_CLAUSE IS NOT NULL AND COM_CLAUSE <> '' THEN CAST(COM_CLAUSE AS VARCHAR) ELSE '' END AS COM_CLAUSE,
CASE WHEN UW IS NOT NULL AND UW <> '' THEN CAST(UW AS VARCHAR) ELSE '' END AS UW,
-- FIX 2026-07-15 (Market Value fallback): MVVALUEWITHOUTACCESSORIES is genuinely blank in Pure
-- for 796/889 (89.5%) Agreed-Value-protection vehicles, even though a real value exists in
-- AVVALUEWITHOUTACCESSORIES (the same figure as AgreedValueAmount). Confirmed live in DCT Express:
-- the vehicle grid's Market Value column showed $0 for these despite real Agreed Value data.
-- Falling back to the Agreed-Value-derived figure when the true Market Value field is blank, since
-- that's the only real value Pure has for these vehicles. Judgment call, not client-confirmed.
CAST(COALESCE(MVVALUEWITHOUTACCESSORIES, AVVALUEWITHOUTACCESSORIES) AS VARCHAR) AS MVVALUEWITHOUTACCESSORIES,
case when VEHHAVEANINTERESTEDPARTY ='Yes' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS VEHHAVEANINTERESTEDPARTY,-- yes=1,no=0,
CAST(YEAR AS VARCHAR) AS YEAR,
CAST(make AS VARCHAR) AS make,
-- FIX 2026-07-15 (re-applied: prior XML-escape fix on MODEL did not survive a later redeploy of
-- this view, confirmed live -- caused a P00018897 parse failure, "714 Tractor & Fel").
REPLACE(REPLACE(REPLACE(CAST(MODEL AS VARCHAR),'&','&amp;'),'<','&lt;'),'>','&gt;') AS MODEL,
-- BodyType: RedBook free-text field — map source values to camelCase for DCT consistency.
-- FIX 2026-07-15 (BUGFIX_BodyType_InvalidCodes): manuscript (Carrier_PersonalProtectionBase_1_0_0_0,
-- VehicleTypeInput.BodyType) only accepts 13 codes: Bus, Convertible, Coupe, Hatchback, PrimeMover,
-- Sedan, Utility, Van, Wagon, TowTruck, Transporter, MobilePlant, Motorcycle. The prior mapping
-- passed RedBook's ~30 free-text categories through as literal camelCase, sending 12 invalid codes
-- to DCT (270/3,288 vehicles = 8.2% live). Remapped to nearest semantic equivalent below — these
-- 12 are a judgment call (esp. CabChassis->Utility, Tipper/Dump->MobilePlant), not client-confirmed;
-- flag for policy team review. Codes with 0 live occurrences (B-double, BusChassis, Compactor,
-- Distributor, ExtraHeavyDuty, HeavyDuty, Highway, Limousine, Mixer, RoadTrain, StreetSweeper,
-- Trailer, Rigid) are left passing through unchanged since they've never actually appeared in
-- source data — revisit if/when they do.
CASE
  WHEN TRIM(BodyType) = 'B-double'         THEN 'B-double'
  WHEN TRIM(BodyType) = 'Bus'              THEN 'Bus'
  WHEN TRIM(BodyType) = 'Bus Chassis'      THEN 'BusChassis'
  WHEN TRIM(BodyType) = 'Cab Chassis'      THEN 'Utility'        -- was CabChassis (invalid, 199 live)
  WHEN TRIM(BodyType) = 'Cabriolet'        THEN 'Convertible'    -- was Cabriolet (invalid, 11 live)
  WHEN TRIM(BodyType) = 'Compactor'        THEN 'Compactor'
  WHEN TRIM(BodyType) = 'Convertible'      THEN 'Convertible'
  WHEN TRIM(BodyType) = 'Coupe'            THEN 'Coupe'
  WHEN TRIM(BodyType) = 'Distributor'      THEN 'Distributor'
  WHEN TRIM(BodyType) = 'Dump'             THEN 'MobilePlant'    -- was Dump (invalid, 1 live)
  WHEN TRIM(BodyType) = 'Extra Heavy Duty' THEN 'ExtraHeavyDuty'
  WHEN TRIM(BodyType) = 'Fastback'         THEN 'Coupe'          -- was Fastback (invalid, 4 live)
  WHEN TRIM(BodyType) = 'Hardtop'          THEN 'Coupe'          -- was Hardtop (invalid, 16 live)
  WHEN TRIM(BodyType) = 'Hatchback'        THEN 'Hatchback'
  WHEN TRIM(BodyType) = 'Heavy Duty'       THEN 'HeavyDuty'
  WHEN TRIM(BodyType) = 'Highway'          THEN 'Highway'
  WHEN TRIM(BodyType) = 'Liftback'         THEN 'Hatchback'      -- was Liftback (invalid, 10 live)
  WHEN TRIM(BodyType) = 'Limousine'        THEN 'Limousine'
  WHEN TRIM(BodyType) = 'Mixer'            THEN 'Mixer'
  WHEN TRIM(BodyType) = 'Prime Mover'      THEN 'PrimeMover'
  WHEN TRIM(BodyType) = 'Rigid'            THEN 'Rigid'
  WHEN TRIM(BodyType) = 'Road Train'       THEN 'RoadTrain'
  WHEN TRIM(BodyType) = 'Roadster'         THEN 'Convertible'    -- was Roadster (invalid, 10 live)
  WHEN TRIM(BodyType) = 'Sedan'            THEN 'Sedan'
  WHEN TRIM(BodyType) = 'Softtop'          THEN 'Convertible'    -- was Softtop (invalid, 10 live)
  WHEN TRIM(BodyType) = 'Street Sweeper'   THEN 'StreetSweeper'
  WHEN TRIM(BodyType) = 'Targa'            THEN 'Convertible'    -- was Targa (invalid, 2 live)
  WHEN TRIM(BodyType) = 'Tipper'           THEN 'MobilePlant'    -- was Tipper (invalid, 2 live)
  WHEN TRIM(BodyType) = 'Trailer'          THEN 'Trailer'
  WHEN TRIM(BodyType) = 'Traytop'          THEN 'Utility'        -- was Traytop (invalid, 3 live)
  WHEN TRIM(BodyType) = 'Utility'          THEN 'Utility'
  WHEN TRIM(BodyType) = 'Van'              THEN 'Van'
  WHEN TRIM(BodyType) = 'Van Wagon'        THEN 'Wagon'          -- was VanWagon (invalid, 2 live)
  WHEN TRIM(BodyType) = 'Wagon'            THEN 'Wagon'
  ELSE ''
END AS BODYTYPE,

MVRBVEHICLEKEY,
-- PP-CF-26 (2026-07-02, follows PP-CF-25 pattern): VehicleInfoOverride must be 1 for ALL
-- converted vehicles, per Aggne QA. 100% of in-scope vehicles (607 vehicles / 441 policies)
-- have no MVRBVEHICLEKEY, so the previous key-driven CASE set 0 everywhere and DCT cannot
-- do a RedBook lookup without a key — vehicle screen blocks like the Locations screen did.
-- Previous logic, kept for reference:
-- CASE WHEN T1.MVRBVEHICLEKEY IS NOT NULL AND TRIM(T1.MVRBVEHICLEKEY) <> '' THEN '1' ELSE '0' END
-- ATP-10963 (2026-07-06, client-approved): Year/Make/Model are unaffected by Override — DCT
-- uses RedbookCode for market value only, never resolves vehicle details from it. The actual
-- fix was retiring the SAS blanking rule in DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql
-- (Pure had the data all along); RedBookCode CTE below updated for vehicle-level join.
-- Override itself stays 1 for all vehicles — unchanged by this fix.
CAST('1' AS VARCHAR) AS OVERRIDE,
-- FIX (G-08, 2026-07-14 CR, applying now): uppercase + strip every non-alphanumeric character.
-- 63 of 3,304 rows were pure formatting issues (case/stray punctuation around a real rego); the
-- remaining ~273 are genuine bad-data rows (a VIN/serial/"Unregistered" typed into this field)
-- that this cannot fix -- those need a separate validation-report rule.
UPPER(REGEXP_REPLACE(CAST(REGISTRATIONNUMBER AS VARCHAR), '[^A-Za-z0-9]', '')) AS REGISTRATIONNUMBER,
CAST(ENGINESIZE AS VARCHAR) AS ENGINESIZE,
CAST(MARKETVALUEDESCRIPTIONVALUE AS VARCHAR) AS MARKETVALUEDESCRIPTIONVALUE,
CAST(GROSSVEHICLEMASS AS VARCHAR) AS GROSSVEHICLEMASS,
-- FIX 2026-07-15 (re-applied: prior XML-escape fix on MARKETVALUEDESCRIPTION did not survive a
-- later redeploy of this view, confirmed live -- caused a P00029380 parse failure, free-text
-- accessories list containing '&' and other raw special characters).
REPLACE(REPLACE(REPLACE(CAST(MARKETVALUEDESCRIPTION AS VARCHAR),'&','&amp;'),'<','&lt;'),'>','&gt;') AS MARKETVALUEDESCRIPTION,
case when CAST(MVADDACCORMODS AS VARCHAR) ='Yes' then 'Yes' else 'No' end AS MVADDACCORMODS,
CAST(AGEOFYOUNGESTREGULARDRIVER AS VARCHAR) AS AGEOFYOUNGESTREGULARDRIVER,
CAST(RESTRICTIONOFDRIVERAGE AS VARCHAR) AS RESTRICTIONOFDRIVERAGE,
CAST(CAST(COALESCE(VOLUNTARYEXCESS,0)AS NUMBER(20,0)) AS VARCHAR) AS VOLUNTARYEXCESS,
-- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml PL101, line 2427-2433):
-- ComprehensiveMarket | ComprehensiveAgreedValue | FireandTheft | Comprehensive | ThirdPartyFireandTheft | ThirdPartyOnly
-- NOTE: 'FullComprehensive' does NOT exist in DCT — 'Comprehensive' is the correct code.
CASE
    WHEN PROTECTIONTYPE = 'Comprehensive - Market Value'    THEN 'ComprehensiveMarket'
    WHEN PROTECTIONTYPE = 'Comprehensive - Agreed Value'    THEN 'ComprehensiveAgreedValue'
    WHEN PROTECTIONTYPE = 'Fire and Theft'                  THEN 'FireandTheft'
    WHEN PROTECTIONTYPE = 'Comprehensive'                   THEN 'Comprehensive'
    WHEN PROTECTIONTYPE = 'Third Party Only'                THEN 'ThirdPartyOnly'
    WHEN PROTECTIONTYPE = 'Third Party, Fire and Theft'     THEN 'ThirdPartyFireandTheft'
    ELSE ''
END AS PROTECTIONTYPE,

-- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml line 2379-2393, default options block):
--   PassengerVehicle | CamperVan | Caravan | Forklift | Motorcycle
--   | MobileEquipment | TowTruck | Tractor | Trailer | Transporter
--   | HeavyVehicle | LightCommercial | HeavyCommercial
-- Source PM_03 values have spaces; DCT codes are camelCase without spaces.
-- Note: LightCommercial, HeavyCommercial, CamperVan, Forklift, Motorcycle are all valid DCT codes
--       confirmed from manuscript line 2379-2393 (2026-07-01).
CASE
    WHEN TRIM(VEHICLETYPE) = 'Passenger Vehicle'  THEN 'PassengerVehicle'
    WHEN TRIM(VEHICLETYPE) = 'Caravan'            THEN 'Caravan'
    WHEN TRIM(VEHICLETYPE) = 'Camper Van'         THEN 'CamperVan'
    WHEN TRIM(VEHICLETYPE) = 'Trailer'            THEN 'Trailer'
    WHEN TRIM(VEHICLETYPE) = 'Motorcycle'         THEN 'Motorcycle'
    WHEN TRIM(VEHICLETYPE) = 'Light Commercial'   THEN 'LightCommercial'
    WHEN TRIM(VEHICLETYPE) = 'Heavy Commercial'   THEN 'HeavyCommercial'
    WHEN TRIM(VEHICLETYPE) = 'Forklift'           THEN 'Forklift'
    WHEN TRIM(VEHICLETYPE) = 'Tow Truck'          THEN 'TowTruck'
    -- FIX (G-12, 2026-07-14 CR, applying now): allow-list to the 9-code Override=1 set. Override
    -- is force-set to '1' for every vehicle above, so the Override=0-only codes (MobileEquipment/
    -- Tractor/Transporter/HeavyVehicle) are structurally never valid here. ELSE changed from raw
    -- passthrough to NULL so the validation report catches anything unmapped instead of forwarding
    -- an invalid code silently. 0 live impact at time of drafting (hardening only).
    WHEN VEHICLETYPE IS NULL OR TRIM(VEHICLETYPE) = '' THEN 'PassengerVehicle'  -- 32 blank policies default to PassengerVehicle
    ELSE NULL
END AS VEHICLETYPE,
REPLACE(DESCRIPTION ,'&','&amp;') as DESCRIPTION,
CAST(CAST(COALESCE(NUMBEROFCYLINDERS,0)AS NUMBER(20,0)) AS VARCHAR) AS  NUMBEROFCYLINDERS,
REPLACE(DRIVEDESCRIPTION ,'&','&amp;') as  DRIVEDESCRIPTION,
-- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml line 2400-2415):
--   Aspirated | Supercharged | Turbocharged | TurboandSupercharged
-- Fix applied 2026-07-01: added 'Turbocharged' as explicit source value (6 policies)
--   — source data already contains the DCT code value; was falling to ELSE '' silently.
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
  WHEN TRIM(INDUCTIONTYPE) = 'Turbocharged'                   THEN 'Turbocharged'  -- fixed: source already has DCT code value
  WHEN TRIM(INDUCTIONTYPE) = 'Turbo Supercharged Intercooled' THEN 'TurboandSupercharged'
  ELSE ''
END AS INDUCTIONTYPE,
IMPORTFLAG,
-- FIX 2026-07-15 (same Market Value fallback as MVVALUEWITHOUTACCESSORIES above): source
-- MARKETVALUEWITHACCESSORIESAMOUNT is 0 (not NULL) for the same 796/889 Agreed-Value vehicles --
-- NULLIF treats that 0 as "no value" so it falls back to AGREEDVALUEAMOUNT instead.
CAST(CAST(COALESCE(NULLIF(MARKETVALUEWITHACCESSORIESAMOUNT,0), AGREEDVALUEAMOUNT, 0) AS NUMBER(20,0)) AS VARCHAR) AS MARKETVALUEWITHACCESSORIESAMOUNT,
CAST(CAST(COALESCE(AGREEDVALUEAMOUNT,0)AS NUMBER(20,0)) AS VARCHAR) AS  AGREEDVALUEAMOUNT,
REPLACE(ADDDETAILSFORTHEINTERESTEDPARTY ,'&','&amp;') as ADDDETAILSFORTHEINTERESTEDPARTY,
case when HIRECARHIREAFTERINCIDENT ='Taken' THEN CAST('Taken' AS VARCHAR) ELSE CAST('NotTaken' AS VARCHAR) END AS  HIRECARHIREAFTERINCIDENT,
case when CHOICEOFREPAIR ='Taken' THEN CAST('1' AS VARCHAR) ELSE CAST('0' AS VARCHAR) END AS  CHOICEOFREPAIR,
-- ATP-11003 (2026-07-03): Pure stores 'Taken' (not 'Yes') for some policies — map both values to 1.
-- Pattern matches HIRECARHIREAFTERINCIDENT and CHOICEOFREPAIR which already accept 'Taken'.
case when EXCESSWAIVERFORGLASS IN ('Yes', 'Taken') THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS  EXCESSWAIVERFORGLASS,
CAST(CAST(COALESCE(AVVALUEWITHOUTACCESSORIES,0)AS NUMBER(20,0)) AS VARCHAR) AS  AVVALUEWITHOUTACCESSORIES,
CAST(COALESCE(T4.PMCLMINCD,0) AS VARCHAR) AS PMCLMINCD,
CAST(COALESCE(T4.PMCLMCNT,0) AS VARCHAR) AS PMCLMCNT,
CAST(COALESCE(T4.PMEXPPREM,0) AS VARCHAR) AS PMEXPPREM,
CAST(MVRBFUELTYPEDESCRIPTION AS VARCHAR) AS FUELTYPE,
CAST(MVRBPOWER AS VARCHAR) AS POWERKW,
CAST(MVRBTRACKREAR AS VARCHAR) AS TRACKREAR,
-- FIX 2026-07-15: real per-vehicle garaging/rating STATE from Pure -- see cte_COVERAGES comment.
CAST(TRIM(STATE) AS VARCHAR) AS STATE,
CAST(GETDATE() AS DATE) as LOAD_DATE
FROM CTE_EXCESS T1
LEFT JOIN  AGGNE.DEV.PER_COM_COVERAGES_TARGET T2 ON T1.PUREPOLICYNUMBER=T2.ID
LEFT JOIN CTE_LISTAGG T3 ON T1.PUREPOLICYNUMBER = T3.ID
-- FIX (G-42, 2026-07-14 CR, applying now): T1.PUREPOLICYNUMBER here is the COMPOSITE key
-- (LEGACYPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P) but T4.POLICYNUMBER is the PLAIN pure policy
-- number (with inconsistent trailing-space padding observed live) -- the old join never matched,
-- so PMEXPPREM/PMCLMINCD/PMCLMCNT were always 0 for 100% of rows (confirmed live 2026-07-15,
-- visible in DCT Express as $0.00 Contribution across the board). Extract the plain number and
-- match on EXPIRINGID_P too for a precise per-term match (Output_Coverage_PER carries multiple
-- terms per policy, e.g. an expired term alongside the current one, with different premiums).
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4
    ON SPLIT_PART(T1.PUREPOLICYNUMBER, '|', 1) = TRIM(T4.POLICYNUMBER)
   AND T1.EXPIRINGID_P = T4.EXPIRINGID_P
WHERE   COVERAGE='Motor'  ;

-- Verify (after deploying this view, before deploying the SP fix):
-- SELECT STATE, COUNT(*) FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY STATE ORDER BY COUNT(*) DESC;
-- Expected: real distribution across VIC/WA/NSW/NZ/QLD/SA/TAS/NT/ACT, not blank
--
-- After deploying BOTH this view AND BUGFIX_PP_CONVERSION_RUN_MotorState_20260715.sql, then
-- CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE); to regenerate, verify the SP no longer hardcodes NSW:
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT WHERE REQUEST_XML LIKE '%<State>NSW</State>%';
-- (some real NSW policies will still show this legitimately -- compare against the ~17% NSW baseline,
-- don't expect exactly 0)
