-- ============================================================
-- PP Conversion — Fix Deployment (2026-06-30)
--
-- Fixes bundled:
--   F1  PER_COM_PAYLOAD         MVADDACCORMODS maps 'Yes'→'1','*'→'0';
--                                DCT expects 'Yes'/'No' → corrected to 'Yes'/'No'
--   F2  PER_HOME_BUILDING_PAYLOAD MINIMUMRENTALPERIOD passes raw source text;
--                                DCT expects 'Morethan90Days'/'Lessthan90Days'
--   F3  PER_HOME_BUILDING_PAYLOAD UNSPECIFIEDITEMSAWAYLIMIT typo '20000' vs '10000'
--                                in the $2,000 per item / $10,000 per event bucket
--   F4  seq 18 ConversionConfig  <WouldYouLikeToAddAccessoriesOrModifications/>
--                                was hardcoded self-closing (no value);
--                                must be token-driven using {MVADDACCORMODS}
--
-- How to run:
--   SECTION 1 → Snowflake  (AGGNE.DEV context)
--   SECTION 2 → SQL Server (PolicyConversion DB)
--   After both sections complete, re-run the PP ETL pipeline from seq 18 onward,
--   then call CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD(); and
--        CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();
--   then re-run the validation SP to confirm 0 INVALID_CODE issues.
-- ============================================================


-- ============================================================
-- SECTION 1 — SNOWFLAKE
-- Run in: AGGNE.DEV
-- ============================================================

USE DATABASE AGGNE;
USE SCHEMA DEV;


-- ── 1A: PER_COM_PAYLOAD  (fixes F1: MVADDACCORMODS 'Yes'/'No') ───────────────

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
AVVALUEWITHOUTACCESSORIES
from AGGNE.DEV.PM_03 T1  where YEAR<>0 and make<>'' and MODEL<>''
) ,

RedBookCode as (select PUREPOLICYNUMBER,MVRBVEHICLEKEY,EXPIRINGID_P from AGGNE.DEV.PM_03 where (PUREPOLICYNUMBER ,EXPIRINGID_P)in (select distinct  PUREPOLICYNUMBER ,  EXPIRINGID_P from cte_COVERAGES)   )
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
t3.MVRBVEHICLEKEY
FROM
cte_SAMPLE_CBP_LOCATION T1
INNER JOIN cte_COVERAGES T2 ON T1.EXPIRINGID_P=T2.EXPIRINGID_P AND TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
LEFT  JOIN RedBookCode T3 ON T3.EXPIRINGID_P=T2.EXPIRINGID_P AND TRIM(T3.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
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
CAST(MVVALUEWITHOUTACCESSORIES AS VARCHAR) AS MVVALUEWITHOUTACCESSORIES,
case when VEHHAVEANINTERESTEDPARTY ='Yes' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS VEHHAVEANINTERESTEDPARTY,-- yes=1,no=0,
CAST(YEAR AS VARCHAR) AS YEAR,
CAST(make AS VARCHAR) AS make,
CAST(MODEL AS VARCHAR) AS MODEL,
-- BodyType: RedBook free-text field — map source values to camelCase for DCT consistency.
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
  WHEN TRIM(BodyType) = 'Trailer'          THEN 'Trailer'
  WHEN TRIM(BodyType) = 'Traytop'          THEN 'Traytop'
  WHEN TRIM(BodyType) = 'Utility'          THEN 'Utility'
  WHEN TRIM(BodyType) = 'Van'              THEN 'Van'
  WHEN TRIM(BodyType) = 'Van Wagon'        THEN 'VanWagon'
  WHEN TRIM(BodyType) = 'Wagon'            THEN 'Wagon'
  ELSE ''
END AS BODYTYPE,

MVRBVEHICLEKEY,
-- OVERRIDE: 1 = DCT uses provided vehicle data (VehicleInfoOverride); 0 = DCT does RedBook lookup.
-- Must be driven by whether a RedBook key exists, NOT by the source OVERRIDE column (always blank).
CASE
    WHEN T1.MVRBVEHICLEKEY IS NOT NULL AND TRIM(T1.MVRBVEHICLEKEY) <> ''
    THEN '1'
    ELSE '0'
END AS OVERRIDE,
CAST(REGISTRATIONNUMBER AS VARCHAR) AS REGISTRATIONNUMBER,
CAST(ENGINESIZE AS VARCHAR) AS ENGINESIZE,
CAST(MARKETVALUEDESCRIPTIONVALUE AS VARCHAR) AS MARKETVALUEDESCRIPTIONVALUE,
CAST(GROSSVEHICLEMASS AS VARCHAR) AS GROSSVEHICLEMASS,
CAST(MARKETVALUEDESCRIPTION AS VARCHAR) AS MARKETVALUEDESCRIPTION,
-- F1 FIX: was CASE WHEN ... THEN '1' ELSE '0' END — DCT expects 'Yes'/'No' not '1'/'0'
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

-- DCT options (PL101 line 2370-2393): 13 camelCase codes.
-- NULL/blank source → default 'PassengerVehicle' (32 policies; client to confirm).
CASE
    WHEN TRIM(VEHICLETYPE) = 'Passenger Vehicle'  THEN 'PassengerVehicle'
    WHEN TRIM(VEHICLETYPE) = 'Camper Van'         THEN 'CamperVan'
    WHEN TRIM(VEHICLETYPE) = 'Caravan'            THEN 'Caravan'
    WHEN TRIM(VEHICLETYPE) = 'Forklift'           THEN 'Forklift'
    WHEN TRIM(VEHICLETYPE) = 'Motorcycle'         THEN 'Motorcycle'
    WHEN TRIM(VEHICLETYPE) = 'Trailer'            THEN 'Trailer'
    WHEN TRIM(VEHICLETYPE) = 'Light Commercial'   THEN 'LightCommercial'
    WHEN TRIM(VEHICLETYPE) = 'Heavy Commercial'   THEN 'HeavyCommercial'
    WHEN TRIM(VEHICLETYPE) = 'Mobile Equipment'   THEN 'MobileEquipment'
    WHEN TRIM(VEHICLETYPE) = 'Tow Truck'          THEN 'TowTruck'
    WHEN TRIM(VEHICLETYPE) = 'Transporter'        THEN 'Transporter'
    WHEN TRIM(VEHICLETYPE) = 'Heavy Vehicle'      THEN 'HeavyVehicle'
    WHEN TRIM(VEHICLETYPE) = 'Tractor'            THEN 'Tractor'
    WHEN VEHICLETYPE IS NULL OR TRIM(VEHICLETYPE) = '' THEN 'PassengerVehicle'
    ELSE VEHICLETYPE
END AS VEHICLETYPE,
REPLACE(DESCRIPTION ,'&','&amp;') as DESCRIPTION,
CAST(CAST(COALESCE(NUMBEROFCYLINDERS,0)AS NUMBER(20,0)) AS VARCHAR) AS  NUMBEROFCYLINDERS,
REPLACE(DRIVEDESCRIPTION ,'&','&amp;') as  DRIVEDESCRIPTION,
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
  ELSE ''
END AS INDUCTIONTYPE,
IMPORTFLAG,
CAST(CAST(COALESCE(MARKETVALUEWITHACCESSORIESAMOUNT,0)AS NUMBER(20,0)) AS VARCHAR) AS MARKETVALUEWITHACCESSORIESAMOUNT,
CAST(CAST(COALESCE(AGREEDVALUEAMOUNT,0)AS NUMBER(20,0)) AS VARCHAR) AS  AGREEDVALUEAMOUNT,
REPLACE(ADDDETAILSFORTHEINTERESTEDPARTY ,'&','&amp;') as ADDDETAILSFORTHEINTERESTEDPARTY,
case when HIRECARHIREAFTERINCIDENT ='Taken' THEN CAST('Taken' AS VARCHAR) ELSE CAST('NotTaken' AS VARCHAR) END AS  HIRECARHIREAFTERINCIDENT,
case when CHOICEOFREPAIR ='Taken' THEN CAST('1' AS VARCHAR) ELSE CAST('0' AS VARCHAR) END AS  CHOICEOFREPAIR,
case when EXCESSWAIVERFORGLASS ='Yes' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS  EXCESSWAIVERFORGLASS,
CAST(CAST(COALESCE(AVVALUEWITHOUTACCESSORIES,0)AS NUMBER(20,0)) AS VARCHAR) AS  AVVALUEWITHOUTACCESSORIES,
CAST(COALESCE(T4.PMCLMINCD,0) AS VARCHAR) AS PMCLMINCD,
CAST(COALESCE(T4.PMCLMCNT,0) AS VARCHAR) AS PMCLMCNT,
CAST(COALESCE(T4.PMEXPPREM,0) AS VARCHAR) AS PMEXPPREM,
CAST(GETDATE() AS DATE) as LOAD_DATE
FROM CTE_EXCESS T1
LEFT JOIN  AGGNE.DEV.PER_COM_COVERAGES_TARGET T2 ON T1.PUREPOLICYNUMBER=T2.ID
LEFT JOIN CTE_LISTAGG T3 ON T1.PUREPOLICYNUMBER = T3.ID
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4 ON T1.PUREPOLICYNUMBER=T4.POLICYNUMBER
WHERE   COVERAGE='Motor'  ;


-- ── 1B: PER_HOME_BUILDING_PAYLOAD  (fixes F2: MINIMUMRENTALPERIOD, F3: UNSPECIFIEDITEMSAWAYLIMIT) ──

create or replace view PER_HOME_BUILDING_PAYLOAD(
    PUREPOLICYNUMBER,
    COVERAGE,
    -- ── HC sub-payload columns (seq 13 RISK_Building_HC) ──────────────────
    SUBCOV,               -- {SUBCOV}              : Building sub-coverage rows
    HC_EXCEED_VALUES,     -- {HC_EXCEED_VALUES}     : Items exceeding value rows
    HC_SPECIFIED_CONTENTS,-- {HC_SPECIFIED_CONTENTS}: Specified contents rows
    -- ── Shared HC / HB columns ────────────────────────────────────────────
    VOLUNTARYEXCESS,      -- {VOLUNTARYEXCESS}
    ACCIDENTALLOSSORDAMAGE,-- {ACCIDENTALLOSSORDAMAGE}
    SPECIFIEDITEMSAWAY,   -- {SPECIFIEDITEMSAWAY}   : 'Taken' / 'Not Taken' (PL101 #104)
    UNSPECIFIEDITEMSAWAY, -- {UNSPECIFIEDITEMSAWAY} : 'Taken' / 'Not Taken' (PL101 #113)
    UNSPECIFIEDITEMSAWAYLIMIT, -- {UNSPECIFIEDITEMSAWAYLIMIT}
    ANYITEMSEXCEEDVALUE,  -- {ANYITEMSEXCEEDVALUE}  : 'Yes' / 'No' → seq 13 <HomeContentsLimits>
    -- ── HC claims/premium (seq 13) ────────────────────────────────────────
    HCCLMCNT,             -- {HCCLMCNT}
    HCCLMINCD,            -- {HCCLMINCD}
    HBEXPPREM,            -- {HBEXPPREM}  (HC premium — sourced from HMEXPPREM)
    -- ── HB-specific columns added 2026-06-24 (seq 7 RISK_Building_HB) ─────
    HOMEBUILDINGSLIMIT,   -- {HOMEBUILDINGSLIMIT}  : from HB_02
    LANDLORDPROTECTIONS,  -- {LANDLORDPROTECTIONS} : from HB_02
    MINIMUMRENTALPERIOD,  -- {MINIMUMRENTALPERIOD} : from HB_02
    WEEKLYRENT,           -- {WEEKLYRENT}          : from HB_02
    HBCLMCNT,             -- {HBCLMCNT}            : from Output_Coverage_PER
    HBCLMINCD,            -- {HBCLMINCD}           : from Output_Coverage_PER
    EXPPREM,              -- {EXPPREM}             : HB premium (HMEXPPREM alias)
    -- ── Clause / UW columns ───────────────────────────────────────────────
    HB_CLAUSE,            -- {HB_CLAUSE}           : aggregated from PER_BUILDING_TARGET
    HC_CLAUSE,            -- {HC_CLAUSE}           : aggregated from PER_HC_TARGET (seq 13 fix: {clauses} renamed to {HC_CLAUSE})
    UW,                   -- {UW}                  : '' default TODO source from UW adjustment data
    LOAD_DATE
) as

-- ── CTE 1: Active PP locations in scope ──────────────────────────────────
with cte_SAMPLE_CBP_LOCATION as
(
    select distinct
        trim(T1.PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
        trim(t1.CMLNUMBER)        AS CMLNUMBER,
        T1.EXPIRINGID_P
    from AGGNE.DEV.Locationdetails_PER T1
    INNER JOIN AGGNE.DEV.SAMPLE_PER T2
        ON TRIM(T1.PUREPOLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
    WHERE t1.EFFECTIVEDATE >= '2026-01-01'
),

cte_COVERAGES as
(
    -- HC_02 branch: preserves HC-specific fields for policies with Home Contents
    select distinct
        PUREPOLICYNUMBER, cmlnumber, EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        VOLUNTARYEXCESS,
        ACCIDENTALLOSSORDAMAGE,          -- raw 'Taken'/'Not Taken'; CTE_EXCESS converts
        SPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAYLIMIT,
        ANYITEMSEXCEEDVALUE
    from AGGNE.DEV.HC_02

    UNION

    -- HB_01 branch: adds HB-only policies absent from HC_02 (ATP-9638 fix)
    select distinct
        PUREPOLICYNUMBER, cmlnumber, EXPIRINGID_P,
        'BB'       AS CLAUSE,
        'Building' AS COVERAGE,
        COALESCE(VOLUNTARYEXCESS, 0)     AS VOLUNTARYEXCESS,
        ACCIDENTALLOSSORDAMAGE,          -- raw 'Taken'/'Not Taken'; CTE_EXCESS converts
        NULL AS SPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAY,
        NULL AS UNSPECIFIEDITEMSAWAYLIMIT,
        NULL AS ANYITEMSEXCEEDVALUE
    from AGGNE.DEV.HB_01 H
    WHERE NOT EXISTS (
        SELECT 1 FROM AGGNE.DEV.HC_02 HC2
        WHERE TRIM(H.PUREPOLICYNUMBER) = TRIM(HC2.PUREPOLICYNUMBER)
          AND H.EXPIRINGID_P           = HC2.EXPIRINGID_P
    )
),

CTE_EXCESS AS (
    SELECT
        CAST(
            TRIM(T2.PUREPOLICYNUMBER) || '|' ||
            TRIM(T2.cmlnumber)        || '|' ||
            TRIM(T2.EXPIRINGID_P)
        AS VARCHAR) AS PUREPOLICYNUMBER,
        t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        T2.cmlnumber,
        T2.EXPIRINGID_P,
        COVERAGE,
        T2.VOLUNTARYEXCESS,
        CASE WHEN T2.ACCIDENTALLOSSORDAMAGE = 'Taken'
             THEN CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR)
             ELSE CAST(CAST(0 AS NUMBER(1,0)) AS VARCHAR)
        END AS ACCIDENTALLOSSORDAMAGE,
        SPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAYLIMIT,
        ANYITEMSEXCEEDVALUE
    FROM cte_SAMPLE_CBP_LOCATION T1
    INNER JOIN cte_COVERAGES T2
        ON  T1.EXPIRINGID_P             = T2.EXPIRINGID_P
        AND TRIM(T1.PUREPOLICYNUMBER)   = TRIM(T2.PUREPOLICYNUMBER)
),

CTE_LISTAGG AS (
    SELECT
        ID,
        LISTAGG(CASE WHEN ITR_TYPE = 'Building_SubCov'        THEN payload END, '\n') AS SUBCOV,
        LISTAGG(CASE WHEN ITR_TYPE = 'HC_exceed_values'       THEN payload END, '\n') AS HC_exceed_values,
        LISTAGG(CASE WHEN ITR_TYPE = 'HC_Specified_Contents'  THEN payload END, '\n') AS HC_Specified_Contents,
        CAST(LOAD_DATE AS DATE) AS LOAD_DATE
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE IN ('Building_SubCov', 'HC_exceed_values', 'HC_Specified_Contents')
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID, CAST(LOAD_DATE AS DATE)
)

, CTE_BUILDING_CLAUSES AS (
    SELECT
        ID,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS HB_CLAUSE_PAYLOAD
    FROM AGGNE.DEV.PER_BUILDING_TARGET
    WHERE ITR_TYPE = 'HB_CLAUSE'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
)

, CTE_HC_CLAUSES AS (
    SELECT
        ID,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS HC_CLAUSE_PAYLOAD
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE = 'HC_CLAUSE'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
)

SELECT distinct
    T1.PUREPOLICYNUMBER,
    T1.COVERAGE,

    CAST(T3.SUBCOV               AS VARCHAR) AS SUBCOV,
    CAST(T3.HC_exceed_values     AS VARCHAR) AS HC_EXCEED_VALUES,
    CAST(T3.HC_Specified_Contents AS VARCHAR) AS HC_SPECIFIED_CONTENTS,

    CAST(CAST(COALESCE(T1.VOLUNTARYEXCESS, 0) AS NUMBER(20,0)) AS VARCHAR) AS VOLUNTARYEXCESS,
    T1.ACCIDENTALLOSSORDAMAGE AS ACCIDENTALLOSSORDAMAGE,
    CASE WHEN T1.SPECIFIEDITEMSAWAY = 'Taken' THEN 'Taken' ELSE 'Not Taken' END AS SPECIFIEDITEMSAWAY,
    CASE WHEN T1.UNSPECIFIEDITEMSAWAY = 'Taken' THEN 'Taken' ELSE 'Not Taken' END AS UNSPECIFIEDITEMSAWAY,
    -- F3 FIX: was '2000peritemupto20000perevent' — typo, source says $10,000 not $20,000
    CASE WHEN T1.UNSPECIFIEDITEMSAWAYLIMIT = '$2,000 per item up to $10,000 per event'
              THEN '2000peritemupto10000perevent'
         WHEN T1.UNSPECIFIEDITEMSAWAYLIMIT = '$1,250 per item up to $5,000 per event'
              THEN '1250peritemupto5000perevent'
         ELSE ''
    END AS UNSPECIFIEDITEMSAWAYLIMIT,
    CAST(COALESCE(T1.ANYITEMSEXCEEDVALUE, 'No') AS VARCHAR) AS ANYITEMSEXCEEDVALUE,

    CAST(COALESCE(T4.HCCLMCNT,  0) AS VARCHAR) AS HCCLMCNT,
    CAST(COALESCE(T4.HCCLMINCD, 0) AS VARCHAR) AS HCCLMINCD,
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS HBEXPPREM,

    CAST(CAST(COALESCE(T5.HOMEBUILDINGSLIMIT, 0) AS NUMBER(10, 0)) AS VARCHAR) AS HOMEBUILDINGSLIMIT,
    CAST(COALESCE(T5.LANDLORDPROTECTIONS, '')                       AS VARCHAR) AS LANDLORDPROTECTIONS,
    -- F2 FIX: was raw CAST(COALESCE(...)) — passes 'More than 90 Days' which DCT rejects
    CASE TRIM(T5.MINIMUMRENTALPERIOD)
        WHEN 'More than 90 Days' THEN 'Morethan90Days'
        WHEN 'Less than 90 Days' THEN 'Lessthan90Days'
        ELSE CAST(COALESCE(T5.MINIMUMRENTALPERIOD, '') AS VARCHAR)
    END AS MINIMUMRENTALPERIOD,
    CAST(CAST(COALESCE(T5.WEEKLYRENT, 0) AS NUMBER(10, 0))          AS VARCHAR) AS WEEKLYRENT,
    CAST(COALESCE(T4.HBCLMCNT,  0) AS VARCHAR) AS HBCLMCNT,
    CAST(COALESCE(T4.HBCLMINCD, 0) AS VARCHAR) AS HBCLMINCD,
    CAST(COALESCE(T4.HMEXPPREM, 0) AS VARCHAR) AS EXPPREM,

    CAST(COALESCE(T6.HB_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HB_CLAUSE,
    CAST(COALESCE(T7.HC_CLAUSE_PAYLOAD, '') AS VARCHAR) AS HC_CLAUSE,
    CAST('' AS VARCHAR) AS UW,

    CAST(GETDATE() AS DATE) AS LOAD_DATE

FROM CTE_EXCESS T1
LEFT JOIN AGGNE.DEV.PER_HC_TARGET T2
    ON T1.PUREPOLICYNUMBER = T2.ID
LEFT JOIN CTE_LISTAGG T3
    ON T1.PUREPOLICYNUMBER = T3.ID
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4
    ON T1.PUREPOLICYNUMBER = T4.POLICYNUMBER
LEFT JOIN AGGNE.DEV.HB_02 T5
    ON  TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.PUREPOLICYNUMBER)
    AND T1.EXPIRINGID_P             = T5.EXPIRINGID_P
LEFT JOIN CTE_BUILDING_CLAUSES T6
    ON T1.PUREPOLICYNUMBER = T6.ID
LEFT JOIN CTE_HC_CLAUSES T7
    ON T1.PUREPOLICYNUMBER = T7.ID

WHERE COVERAGE = 'Building';


-- ── 1C: Verify views (optional spot check) ───────────────────────────────────
-- SELECT MVADDACCORMODS, COUNT(*) AS CNT
-- FROM AGGNE.DEV.PER_COM_PAYLOAD
-- GROUP BY MVADDACCORMODS;
-- Expected: rows with 'Yes' and 'No' only — no '0' or '1'.

-- SELECT MINIMUMRENTALPERIOD, COUNT(*) AS CNT
-- FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
-- GROUP BY MINIMUMRENTALPERIOD;
-- Expected: 'Morethan90Days', 'Lessthan90Days', '' — no raw text.

-- SELECT UNSPECIFIEDITEMSAWAYLIMIT, COUNT(*) AS CNT
-- FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
-- GROUP BY UNSPECIFIEDITEMSAWAYLIMIT;
-- Expected: '2000peritemupto10000perevent', '1250peritemupto5000perevent', '' only.


-- ============================================================
-- SECTION 2 — SQL SERVER
-- Run in: PolicyConversion DB (ConversionAgent)
-- ============================================================

-- F4 FIX: seq 18 template — replace self-closing tag with token-driven element
--
-- Before: <WouldYouLikeToAddAccessoriesOrModifications/>
-- After:  <WouldYouLikeToAddAccessoriesOrModifications>{MVADDACCORMODS}</WouldYouLikeToAddAccessoriesOrModifications>
--
-- {MVADDACCORMODS} is resolved by DYNAMIC_XML_V1 from PER_COM_PAYLOAD.MVADDACCORMODS
-- which now outputs 'Yes'/'No' (fix F1 above).


-- Step 1: Preview — confirm the old self-closing tag is present
SELECT
    SequenceID,
    ScriptName,
    CHARINDEX(
        '<WouldYouLikeToAddAccessoriesOrModifications/>',
        ConversionScript
    ) AS OLD_SELFCLOSE_POS,
    CHARINDEX(
        '{MVADDACCORMODS}',
        ConversionScript
    ) AS MVADDACCORMODS_TOKEN_POS
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 18
  AND IsActive   = 1;
-- Expected: OLD_SELFCLOSE_POS > 0, MVADDACCORMODS_TOKEN_POS > 0
--           (token already present on the Market line)


-- Step 2: Apply fix
UPDATE dbo.PP_ConversionConfig
SET    ConversionScript = REPLACE(
           ConversionScript,
           '<WouldYouLikeToAddAccessoriesOrModifications/>',
           '<WouldYouLikeToAddAccessoriesOrModifications>{MVADDACCORMODS}</WouldYouLikeToAddAccessoriesOrModifications>'
       )
WHERE  SequenceID = 18
  AND  IsActive   = 1;


-- Step 3: Verify fix
SELECT
    SequenceID,
    ScriptName,
    CASE
        WHEN CHARINDEX('<WouldYouLikeToAddAccessoriesOrModifications/>', ConversionScript) > 0
            THEN 'FAIL — self-closing tag still present'
        WHEN CHARINDEX('{MVADDACCORMODS}</WouldYouLikeToAddAccessoriesOrModifications>', ConversionScript) > 0
            THEN 'OK — token-driven element in place'
        ELSE 'CHECK — neither pattern found'
    END AS CHECK_STATUS
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 18
  AND IsActive   = 1;
-- Expected: CHECK_STATUS = 'OK — token-driven element in place'
