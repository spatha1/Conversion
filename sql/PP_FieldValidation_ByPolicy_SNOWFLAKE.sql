-- ══════════════════════════════════════════════════════════════════════════
-- PP_FieldValidation_ByPolicy_SNOWFLAKE.sql
-- Target  : Snowflake — AGGNE.DEV schema (read-only)
-- Date    : 2026-07-01
--
-- One row per policy per DCT dropdown field, UNION ALL across all 17 fields.
-- Reads directly from raw source tables (PM_03, Locationdetails_PER) —
-- no dependency on DEV views or staging tables.
--
-- Columns:
--   PUREPOLICYNUMBER  — composite key (POLICY|CML|EXPIRINGID)
--   SECTION           — Motor | Building
--   DCT_FIELD         — DCT field name
--   DCT_VALID_VALUES  — comma-separated valid DCT codes
--   SOURCE_RAW_VALUE  — value exactly as it sits in the source table
--   MAPPED_DCT_CODE   — what our mapping produces (mirrors view CASE logic)
--   STATUS            — PASS | FAIL — <reason>
--
-- Filter: SAMPLE_PER scope, EFFECTIVEDATE/EXPIRYDATE >= 2026-01-01
-- ══════════════════════════════════════════════════════════════════════════

WITH

-- ────────────────────────────────────────────────────────────────
-- Motor scope: PM_03 policies that are in scope + have vehicle data
-- ────────────────────────────────────────────────────────────────
MOTOR_SCOPE AS (
    SELECT DISTINCT
        CAST(TRIM(PM.PUREPOLICYNUMBER) ||'|'|| TRIM(PM.CMLNUMBER) ||'|'|| TRIM(PM.EXPIRINGID_P) AS VARCHAR) AS POLICY_KEY
    FROM AGGNE.DEV.PM_03 PM
    JOIN AGGNE.DEV.SAMPLE_PER SP ON TRIM(PM.PUREPOLICYNUMBER) = TRIM(SP.PUREPOLICYNUMBER)
    WHERE PM.EXPIRYDATE     >= '2026-01-01'
      AND PM.YEAR            <> 0
      AND TRIM(PM.MAKE)      <> ''
      AND TRIM(PM.MODEL)     <> ''
),

-- ────────────────────────────────────────────────────────────────
-- Building scope: Locationdetails_PER in scope
-- ────────────────────────────────────────────────────────────────
BLDG_SCOPE AS (
    SELECT DISTINCT
        CAST(TRIM(L.PUREPOLICYNUMBER) ||'|'|| TRIM(L.CMLNUMBER) ||'|'|| TRIM(L.EXPIRINGID_P) AS VARCHAR) AS POLICY_KEY
    FROM AGGNE.DEV.Locationdetails_PER L
    JOIN AGGNE.DEV.SAMPLE_PER SP ON TRIM(L.PUREPOLICYNUMBER) = TRIM(SP.PUREPOLICYNUMBER)
    WHERE L.EFFECTIVEDATE >= '2026-01-01'
),

-- ────────────────────────────────────────────────────────────────
-- Motor raw source fields (one row per vehicle record)
-- ────────────────────────────────────────────────────────────────
MOTOR_RAW AS (
    SELECT
        CAST(TRIM(PM.PUREPOLICYNUMBER) ||'|'|| TRIM(PM.CMLNUMBER) ||'|'|| TRIM(PM.EXPIRINGID_P) AS VARCHAR) AS POLICY_KEY,
        COALESCE(TRIM(PM.VEHICLETYPE),              '')  AS VEHICLETYPE,
        COALESCE(TRIM(PM.PROTECTIONTYPE),           '')  AS PROTECTIONTYPE,
        COALESCE(TRIM(PM.INDUCTIONTYPE),            '')  AS INDUCTIONTYPE,
        CAST(COALESCE(PM.VOLUNTARYEXCESS, 0) AS NUMBER(20,0))  AS VOLUNTARYEXCESS,
        COALESCE(TRIM(PM.RESTRICTIONOFDRIVERAGE),   '')  AS RESTRICTIONOFDRIVERAGE,
        COALESCE(TRIM(PM.EXCESSWAIVERFORGLASS),     '')  AS EXCESSWAIVERFORGLASS,
        COALESCE(TRIM(PM.CHOICEOFREPAIR),           '')  AS CHOICEOFREPAIR,
        COALESCE(TRIM(PM.HIRECARHIREAFTERINCIDENT), '')  AS HIRECARHIREAFTERINCIDENT,
        COALESCE(CAST(PM.MVADDACCORMODS AS VARCHAR), '') AS MVADDACCORMODS,
        COALESCE(TRIM(PM.VEHHAVEANINTERESTEDPARTY), '')  AS VEHHAVEANINTERESTEDPARTY
    FROM AGGNE.DEV.PM_03 PM
    JOIN MOTOR_SCOPE MS
        ON CAST(TRIM(PM.PUREPOLICYNUMBER) ||'|'|| TRIM(PM.CMLNUMBER) ||'|'|| TRIM(PM.EXPIRINGID_P) AS VARCHAR) = MS.POLICY_KEY
),

-- ────────────────────────────────────────────────────────────────
-- Building raw source fields (one row per location record)
-- ────────────────────────────────────────────────────────────────
BLDG_RAW AS (
    SELECT
        CAST(TRIM(L.PUREPOLICYNUMBER) ||'|'|| TRIM(L.CMLNUMBER) ||'|'|| TRIM(L.EXPIRINGID_P) AS VARCHAR) AS POLICY_KEY,
        COALESCE(TRIM(L.HOWOCCUPPIED),          '') AS HOWOCCUPPIED,
        COALESCE(TRIM(L.MAINWALLCONSTRUCTION),  '') AS MAINWALLCONSTRUCTION,
        COALESCE(TRIM(L.ROOFCONSTRUCTION),      '') AS ROOFCONSTRUCTION,
        COALESCE(TRIM(L.FLOORCONSTRUCTION),     '') AS FLOORCONSTRUCTION,
        COALESCE(TRIM(L.ALARMSYSTEMINSTALLED),  '') AS ALARMSYSTEMINSTALLED,
        COALESCE(TRIM(L.DEADLOCKSINSTALLED),    '') AS DEADLOCKSINSTALLED,
        COALESCE(TRIM(L.GRILLKEYLOCKINSTALLED), '') AS GRILLKEYLOCKINSTALLED
    FROM AGGNE.DEV.Locationdetails_PER L
    JOIN BLDG_SCOPE BS
        ON CAST(TRIM(L.PUREPOLICYNUMBER) ||'|'|| TRIM(L.CMLNUMBER) ||'|'|| TRIM(L.EXPIRINGID_P) AS VARCHAR) = BS.POLICY_KEY
)

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 1: VehicleType
-- DCT manuscript line 2379-2393; default options list
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY                        AS PUREPOLICYNUMBER,
    'Motor'                           AS SECTION,
    'VehicleType'                     AS DCT_FIELD,
    'PassengerVehicle,CamperVan,Caravan,Forklift,Motorcycle,MobileEquipment,TowTruck,Tractor,Trailer,Transporter,HeavyVehicle,LightCommercial,HeavyCommercial'
                                      AS DCT_VALID_VALUES,
    VEHICLETYPE                       AS SOURCE_RAW_VALUE,
    CASE
        WHEN VEHICLETYPE = 'Passenger Vehicle' THEN 'PassengerVehicle'
        WHEN VEHICLETYPE = 'Caravan'           THEN 'Caravan'
        WHEN VEHICLETYPE = 'Camper Van'        THEN 'CamperVan'
        WHEN VEHICLETYPE = 'Trailer'           THEN 'Trailer'
        WHEN VEHICLETYPE = 'Motorcycle'        THEN 'Motorcycle'
        WHEN VEHICLETYPE = 'Light Commercial'  THEN 'LightCommercial'
        WHEN VEHICLETYPE = 'Heavy Commercial'  THEN 'HeavyCommercial'
        WHEN VEHICLETYPE = 'Heavy Vehicle'     THEN 'HeavyVehicle'
        WHEN VEHICLETYPE = 'Mobile Equipment'  THEN 'MobileEquipment'
        WHEN VEHICLETYPE = 'Forklift'          THEN 'Forklift'
        WHEN VEHICLETYPE = 'Tow Truck'         THEN 'TowTruck'
        WHEN VEHICLETYPE = 'Transporter'       THEN 'Transporter'
        WHEN VEHICLETYPE = 'Tractor'           THEN 'Tractor'
        WHEN VEHICLETYPE = ''                  THEN 'PassengerVehicle'
        ELSE VEHICLETYPE
    END                               AS MAPPED_DCT_CODE,
    CASE
        WHEN VEHICLETYPE IN ('Passenger Vehicle','Caravan','Camper Van','Trailer','Motorcycle',
                             'Light Commercial','Heavy Commercial','Heavy Vehicle',
                             'Mobile Equipment','Forklift','Tow Truck','Transporter','Tractor')
          OR VEHICLETYPE = ''
        THEN 'PASS'
        ELSE 'FAIL — no DCT mapping'
    END                               AS STATUS
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 2: ProtectionType
-- DCT manuscript line 2426-2436
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'ProtectionType',
    'ComprehensiveMarket,ComprehensiveAgreedValue,FireandTheft,Comprehensive,ThirdPartyFireandTheft,ThirdPartyOnly',
    PROTECTIONTYPE,
    CASE
        WHEN PROTECTIONTYPE = 'Comprehensive - Market Value'   THEN 'ComprehensiveMarket'
        WHEN PROTECTIONTYPE = 'Comprehensive - Agreed Value'   THEN 'ComprehensiveAgreedValue'
        WHEN PROTECTIONTYPE = 'Fire and Theft'                 THEN 'FireandTheft'
        WHEN PROTECTIONTYPE = 'Comprehensive'                  THEN 'Comprehensive'
        WHEN PROTECTIONTYPE = 'Third Party Only'               THEN 'ThirdPartyOnly'
        WHEN PROTECTIONTYPE = 'Third Party, Fire and Theft'    THEN 'ThirdPartyFireandTheft'
        ELSE ''
    END,
    CASE
        WHEN PROTECTIONTYPE IN ('Comprehensive - Market Value','Comprehensive - Agreed Value',
                                'Fire and Theft','Comprehensive',
                                'Third Party Only','Third Party, Fire and Theft') THEN 'PASS'
        WHEN PROTECTIONTYPE = '' THEN 'FAIL — blank'
        ELSE 'FAIL — no DCT mapping'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 3: InductionType
-- DCT manuscript line 2400-2415
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'InductionType',
    'Aspirated,Supercharged,Turbocharged,TurboandSupercharged',
    INDUCTIONTYPE,
    CASE
        WHEN INDUCTIONTYPE = 'Aspirated'                        THEN 'Aspirated'
        WHEN INDUCTIONTYPE IN ('Supercharged Intercooled',
                               'Twin Supercharged Intercooled',
                               'Supercharged')                  THEN 'Supercharged'
        WHEN INDUCTIONTYPE IN ('Turbo','Turbo Intercooled',
                               'Twin Turbo Intercooled',
                               'Triple Turbo Intercooled',
                               'Quad Turbo Intercooled',
                               'Turbocharged')                  THEN 'Turbocharged'
        WHEN INDUCTIONTYPE = 'Turbo Supercharged Intercooled'   THEN 'TurboandSupercharged'
        ELSE ''
    END,
    CASE
        WHEN INDUCTIONTYPE IN ('Aspirated','Supercharged Intercooled','Twin Supercharged Intercooled',
                               'Supercharged','Turbo','Turbo Intercooled','Twin Turbo Intercooled',
                               'Triple Turbo Intercooled','Quad Turbo Intercooled','Turbocharged',
                               'Turbo Supercharged Intercooled') THEN 'PASS'
        WHEN INDUCTIONTYPE = '' THEN 'PASS — blank (field omitted from payload)'
        ELSE 'FAIL — no DCT mapping'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 4: VoluntaryExcess
-- DCT manuscript line 2244; valid: 0,250,500,750,1000,1250,1500
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'VoluntaryExcess',
    '0,250,500,750,1000,1250,1500',
    CAST(VOLUNTARYEXCESS AS VARCHAR),
    CAST(VOLUNTARYEXCESS AS VARCHAR),
    CASE
        WHEN VOLUNTARYEXCESS IN (0,250,500,750,1000,1250,1500) THEN 'PASS'
        ELSE 'FAIL — value not in DCT list'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 5: RestrictionOfDriverAge
-- DCT manuscript line 2355; source values are text labels
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'RestrictionOfDriverAge',
    '0,20,24,29,39',
    RESTRICTIONOFDRIVERAGE,
    CASE
        WHEN RESTRICTIONOFDRIVERAGE = 'No Restriction' THEN '0'
        WHEN RESTRICTIONOFDRIVERAGE = 'Min Age 21'     THEN '20'
        WHEN RESTRICTIONOFDRIVERAGE = 'Min Age 25'     THEN '24'
        WHEN RESTRICTIONOFDRIVERAGE = 'Min Age 30'     THEN '29'
        WHEN RESTRICTIONOFDRIVERAGE = 'Min Age 40'     THEN '39'
        WHEN RESTRICTIONOFDRIVERAGE = ''               THEN '0'
        ELSE '0'
    END,
    CASE
        WHEN RESTRICTIONOFDRIVERAGE IN ('No Restriction','Min Age 21','Min Age 25',
                                        'Min Age 30','Min Age 40')
          OR RESTRICTIONOFDRIVERAGE = '' THEN 'PASS'
        ELSE 'FAIL — unexpected source value'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 6: ExcessWaiverForGlass
-- DCT manuscript line 2221; DCT: 1=Protected, 0=Not Protected
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'ExcessWaiverForGlass',
    '1 (Protected),0 (Not Protected)',
    EXCESSWAIVERFORGLASS,
    CASE WHEN EXCESSWAIVERFORGLASS = 'Yes' THEN '1' ELSE '0' END,
    CASE
        WHEN EXCESSWAIVERFORGLASS IN ('Yes','No') OR EXCESSWAIVERFORGLASS = '' THEN 'PASS'
        ELSE 'FAIL — unexpected source value'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 7: ChoiceOfRepair
-- DCT manuscript line 2268; DCT: 1=Taken, 0=Not Taken
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'ChoiceOfRepair',
    '1 (Taken),0 (Not Taken)',
    CHOICEOFREPAIR,
    CASE WHEN CHOICEOFREPAIR = 'Taken' THEN '1' ELSE '0' END,
    CASE
        WHEN CHOICEOFREPAIR IN ('Taken','Not Taken') OR CHOICEOFREPAIR = '' THEN 'PASS'
        ELSE 'FAIL — unexpected source value'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 8: HireCarHireAfterIncident
-- DCT manuscript line 2295; DCT: Taken | NotTaken
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'HireCarHireAfterIncident',
    'Taken,NotTaken',
    HIRECARHIREAFTERINCIDENT,
    CASE WHEN HIRECARHIREAFTERINCIDENT = 'Taken' THEN 'Taken' ELSE 'NotTaken' END,
    CASE
        WHEN HIRECARHIREAFTERINCIDENT IN ('Taken','Not Taken') OR HIRECARHIREAFTERINCIDENT = '' THEN 'PASS'
        ELSE 'FAIL — unexpected source value'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 9: AddAccessoriesOrModifications (MVADDACCORMODS)
-- DCT manuscript line 2452; DCT: Yes | No
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'AddAccessoriesOrModifications',
    'Yes,No',
    MVADDACCORMODS,
    CASE WHEN MVADDACCORMODS = 'Yes' THEN 'Yes' ELSE 'No' END,
    CASE
        WHEN MVADDACCORMODS IN ('Yes','No') OR MVADDACCORMODS = '' THEN 'PASS'
        ELSE 'FAIL — unexpected source value'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR — Field 10: DoesVehicleHaveInterestedParty (VEHHAVEANINTERESTEDPARTY)
-- DCT manuscript line 2484; DCT: 1=Yes, 0=No
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Motor',
    'DoesVehicleHaveInterestedParty',
    '1 (Yes),0 (No)',
    VEHHAVEANINTERESTEDPARTY,
    CASE WHEN VEHHAVEANINTERESTEDPARTY = 'Yes' THEN '1' ELSE '0' END,
    CASE
        WHEN VEHHAVEANINTERESTEDPARTY IN ('Yes','No') OR VEHHAVEANINTERESTEDPARTY = '' THEN 'PASS'
        ELSE 'FAIL — unexpected source value'
    END
FROM MOTOR_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- BUILDING — Field 11: HomeBuildingOccupied (HOWOCCUPPIED)
-- DCT manuscript line 11363
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Building',
    'HomeBuildingOccupied',
    'OwnerOccupied,HolidayHome,OwnedleasedtoOthersLongTermLease,OwnedLeasedtoOthersShortTermRental,TenantedbyMember',
    HOWOCCUPPIED,
    CASE
        WHEN HOWOCCUPPIED = 'Owner Occupied'                              THEN 'OwnerOccupied'
        WHEN HOWOCCUPPIED ILIKE 'Tenanted by member'                      THEN 'TenantedbyMember'
        WHEN HOWOCCUPPIED = 'Owned leased to Others - Long Term Lease'    THEN 'OwnedleasedtoOthersLongTermLease'
        WHEN HOWOCCUPPIED = 'Holiday Home'                                THEN 'HolidayHome'
        WHEN HOWOCCUPPIED = 'Owned leased to Others - Short Term Rental'  THEN 'OwnedLeasedtoOthersShortTermRental'
        ELSE HOWOCCUPPIED
    END,
    CASE
        WHEN HOWOCCUPPIED IN ('Owner Occupied','Holiday Home',
                              'Owned leased to Others - Long Term Lease',
                              'Owned leased to Others - Short Term Rental')
          OR HOWOCCUPPIED ILIKE 'Tenanted by member'
        THEN 'PASS'
        WHEN HOWOCCUPPIED = '' THEN 'FAIL — blank'
        ELSE 'FAIL — no DCT mapping'
    END
FROM BLDG_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- BUILDING — Field 12: MainWallConstruction
-- DCT manuscript line 11552
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Building',
    'MainWallConstruction',
    'Asbestos,BrickVeneer,Concrete,DoubleBrick,FibroHardiplank,IronSteel,Wood',
    MAINWALLCONSTRUCTION,
    CASE
        WHEN MAINWALLCONSTRUCTION = 'Asbestos'             THEN 'Asbestos'
        WHEN MAINWALLCONSTRUCTION = 'Brick Veneer'         THEN 'BrickVeneer'
        WHEN MAINWALLCONSTRUCTION = 'Concrete'             THEN 'Concrete'
        WHEN MAINWALLCONSTRUCTION = 'Double Brick'         THEN 'DoubleBrick'
        WHEN MAINWALLCONSTRUCTION = 'Fibro (Non-Asbestos)' THEN 'FibroHardiplank'
        WHEN MAINWALLCONSTRUCTION = 'Fibro/Hardiplank'     THEN 'FibroHardiplank'
        WHEN MAINWALLCONSTRUCTION = 'Iron'                 THEN 'IronSteel'
        WHEN MAINWALLCONSTRUCTION = 'Iron/Steel'           THEN 'IronSteel'
        WHEN MAINWALLCONSTRUCTION = 'Steel'                THEN 'IronSteel'
        WHEN MAINWALLCONSTRUCTION = 'Wood'                 THEN 'Wood'
        ELSE MAINWALLCONSTRUCTION
    END,
    CASE
        WHEN MAINWALLCONSTRUCTION IN ('Asbestos','Brick Veneer','Concrete','Double Brick',
                                      'Fibro (Non-Asbestos)','Fibro/Hardiplank',
                                      'Iron','Iron/Steel','Steel','Wood') THEN 'PASS'
        WHEN MAINWALLCONSTRUCTION = '' THEN 'FAIL — blank'
        ELSE 'FAIL — no DCT mapping (client to confirm)'
    END
FROM BLDG_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- BUILDING — Field 13: RoofConstruction
-- DCT manuscript line 11582
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Building',
    'RoofConstruction',
    'Asbestos,Colourbond,Concrete,IronSteelTin,Tile,Wood',
    ROOFCONSTRUCTION,
    CASE
        WHEN ROOFCONSTRUCTION = 'Asbestos'              THEN 'Asbestos'
        WHEN ROOFCONSTRUCTION = 'Concrete'              THEN 'Concrete'
        WHEN ROOFCONSTRUCTION = 'Concrete (Flat Roof)'  THEN 'Concrete'
        WHEN ROOFCONSTRUCTION = 'Iron'                  THEN 'IronSteelTin'
        WHEN ROOFCONSTRUCTION = 'Iron/Steel/Tin'        THEN 'IronSteelTin'
        WHEN ROOFCONSTRUCTION = 'Tin'                   THEN 'IronSteelTin'
        WHEN ROOFCONSTRUCTION ILIKE 'Colorbond'         THEN 'Colourbond'
        WHEN ROOFCONSTRUCTION = 'Tile'                  THEN 'Tile'
        WHEN ROOFCONSTRUCTION = 'Wood'                  THEN 'Wood'
        WHEN ROOFCONSTRUCTION = 'Wood (Shingles)'       THEN 'Wood'
        ELSE ROOFCONSTRUCTION
    END,
    CASE
        WHEN ROOFCONSTRUCTION IN ('Asbestos','Concrete','Concrete (Flat Roof)',
                                  'Iron','Iron/Steel/Tin','Tin','Tile',
                                  'Wood','Wood (Shingles)')
          OR ROOFCONSTRUCTION ILIKE 'Colorbond'
        THEN 'PASS'
        WHEN ROOFCONSTRUCTION = '' THEN 'FAIL — blank'
        ELSE 'FAIL — no DCT mapping'
    END
FROM BLDG_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- BUILDING — Field 14: FloorConstruction
-- DCT manuscript line 11611
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Building',
    'FloorConstruction',
    'Concrete,Other,WoodConcretefootings,WoodStilts,WoodStumps',
    FLOORCONSTRUCTION,
    CASE
        WHEN FLOORCONSTRUCTION = 'Concrete'                         THEN 'Concrete'
        WHEN FLOORCONSTRUCTION = 'Other'                            THEN 'Other'
        WHEN FLOORCONSTRUCTION ILIKE 'Wood - Concrete Footings'     THEN 'WoodConcretefootings'
        WHEN FLOORCONSTRUCTION ILIKE 'Wood - Stilts'                THEN 'WoodStilts'
        WHEN FLOORCONSTRUCTION ILIKE 'Wood - Stumps'                THEN 'WoodStumps'
        ELSE FLOORCONSTRUCTION
    END,
    CASE
        WHEN FLOORCONSTRUCTION IN ('Concrete','Other')
          OR FLOORCONSTRUCTION ILIKE 'Wood - Concrete Footings'
          OR FLOORCONSTRUCTION ILIKE 'Wood - Stilts'
          OR FLOORCONSTRUCTION ILIKE 'Wood - Stumps'
        THEN 'PASS'
        WHEN FLOORCONSTRUCTION = '' THEN 'FAIL — blank'
        ELSE 'FAIL — no DCT mapping'
    END
FROM BLDG_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- BUILDING — Field 15: AlarmSystemInstalled
-- DCT manuscript line 11751
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Building',
    'AlarmSystemInstalled',
    'LocalAudibleOnly,MonitoredBacktobase,MonitoredSecurity,MonitoredToMobilePhone,None',
    ALARMSYSTEMINSTALLED,
    CASE
        WHEN ALARMSYSTEMINSTALLED = 'Local - Audible Only'         THEN 'LocalAudibleOnly'
        WHEN ALARMSYSTEMINSTALLED = 'Monitored - Back to base'     THEN 'MonitoredBacktobase'
        WHEN ALARMSYSTEMINSTALLED = 'Monitored - Security'         THEN 'MonitoredSecurity'
        WHEN ALARMSYSTEMINSTALLED = 'Monitored - To Mobile Phone'  THEN 'MonitoredToMobilePhone'
        WHEN ALARMSYSTEMINSTALLED = 'None'                         THEN 'None'
        ELSE ALARMSYSTEMINSTALLED
    END,
    CASE
        WHEN ALARMSYSTEMINSTALLED IN ('Local - Audible Only','Monitored - Back to base',
                                      'Monitored - Security','Monitored - To Mobile Phone','None')
        THEN 'PASS'
        WHEN ALARMSYSTEMINSTALLED = '' THEN 'FAIL — blank'
        ELSE 'FAIL — no DCT mapping (client to confirm)'
    END
FROM BLDG_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- BUILDING — Field 16: DeadlocksInstalledOnAllExternalDoors
-- DCT manuscript line 11766
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Building',
    'DeadlocksInstalledOnAllExternalDoors',
    'AllDoors,SomeDoors,None',
    DEADLOCKSINSTALLED,
    CASE
        WHEN DEADLOCKSINSTALLED = 'All doors'  THEN 'AllDoors'
        WHEN DEADLOCKSINSTALLED = 'Some doors' THEN 'SomeDoors'
        WHEN DEADLOCKSINSTALLED = 'None'       THEN 'None'
        ELSE DEADLOCKSINSTALLED
    END,
    CASE
        WHEN DEADLOCKSINSTALLED IN ('All doors','Some doors','None') THEN 'PASS'
        WHEN DEADLOCKSINSTALLED = '' THEN 'FAIL — blank'
        ELSE 'FAIL — no DCT mapping (client to confirm)'
    END
FROM BLDG_RAW

UNION ALL

-- ══════════════════════════════════════════════════════════════════════════
-- BUILDING — Field 17: BarsOrGrillsInstalledOnAllWindows (GRILLKEYLOCKINSTALLED)
-- DCT manuscript line 11780
-- ══════════════════════════════════════════════════════════════════════════
SELECT
    POLICY_KEY,
    'Building',
    'BarsOrGrillsInstalledOnAllWindows',
    'AllWindows,SomeWindows,None',
    GRILLKEYLOCKINSTALLED,
    CASE
        WHEN GRILLKEYLOCKINSTALLED = 'All windows'  THEN 'AllWindows'
        WHEN GRILLKEYLOCKINSTALLED = 'Some windows' THEN 'SomeWindows'
        WHEN GRILLKEYLOCKINSTALLED = 'None'         THEN 'None'
        ELSE GRILLKEYLOCKINSTALLED
    END,
    CASE
        WHEN GRILLKEYLOCKINSTALLED IN ('All windows','Some windows','None') THEN 'PASS'
        WHEN GRILLKEYLOCKINSTALLED = '' THEN 'FAIL — blank'
        ELSE 'FAIL — no DCT mapping (client to confirm)'
    END
FROM BLDG_RAW

ORDER BY PUREPOLICYNUMBER, SECTION DESC, DCT_FIELD
;
