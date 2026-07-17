-- ══════════════════════════════════════════════════════════════════════════
-- PP_FieldValidation_AllFields_SNOWFLAKE.sql
-- Target  : Snowflake — AGGNE.DEV (read-only)
-- Date    : 2026-07-01
--
-- Policy-level dropdown field validation — all 17 fields, UNION ALL.
--
-- Design:
--   • MOTOR_SRC / BLDG_SRC each join the DEV view ONCE to get mapped values.
--   • Raw source values come from PM_03 / Locationdetails_PER directly.
--   • Each UNION ALL branch is a thin SELECT — no CASE duplication.
--   • View updates are reflected automatically on next run.
--
-- Columns:
--   PUREPOLICYNUMBER  — composite key POLICY|CML|EXPIRINGID
--   XML_PATH          — element name from ConversionScript RHS
--   DCT_VALID_VALUES  — comma-separated valid DCT codes (from manuscript)
--   SOURCE_RAW_VALUE  — exact value in source table before mapping
--   MAPPED_DCT_CODE   — what the deployed DEV view produces
--   STATUS            — PASS | FAIL — <reason>
-- ══════════════════════════════════════════════════════════════════════════

WITH

-- ─── Motor scope ─────────────────────────────────────────────────────────
MOTOR_SCOPE AS (
    SELECT DISTINCT
        CAST(TRIM(PM.PUREPOLICYNUMBER) ||'|'|| TRIM(PM.CMLNUMBER) ||'|'|| TRIM(PM.EXPIRINGID_P) AS VARCHAR) AS POLICY_KEY
    FROM AGGNE.DEV.PM_03 PM
    JOIN AGGNE.DEV.SAMPLE_PER SP ON TRIM(PM.PUREPOLICYNUMBER) = TRIM(SP.PUREPOLICYNUMBER)
    WHERE PM.EXPIRYDATE >= '2026-01-01'
      AND PM.YEAR        <> 0
      AND TRIM(PM.MAKE)  <> ''
      AND TRIM(PM.MODEL) <> ''
),

-- ─── Building scope ───────────────────────────────────────────────────────
BLDG_SCOPE AS (
    SELECT DISTINCT
        CAST(TRIM(L.PUREPOLICYNUMBER) ||'|'|| TRIM(L.CMLNUMBER) ||'|'|| TRIM(L.EXPIRINGID_P) AS VARCHAR) AS POLICY_KEY
    FROM AGGNE.DEV.Locationdetails_PER L
    JOIN AGGNE.DEV.SAMPLE_PER SP ON TRIM(L.PUREPOLICYNUMBER) = TRIM(SP.PUREPOLICYNUMBER)
    WHERE L.EFFECTIVEDATE >= '2026-01-01'
),

-- ─── Motor: raw (PM_03) + mapped (PER_COM_PAYLOAD) ───────────────────────
-- View joined once; each UNION ALL branch just references columns here.
MOTOR_SRC AS (
    SELECT
        S.POLICY_KEY,
        -- raw source values from PM_03
        COALESCE(TRIM(PM.VEHICLETYPE),              '') AS RAW_VEHICLETYPE,
        COALESCE(TRIM(PM.PROTECTIONTYPE),           '') AS RAW_PROTECTIONTYPE,
        COALESCE(TRIM(PM.INDUCTIONTYPE),            '') AS RAW_INDUCTIONTYPE,
        CAST(COALESCE(PM.VOLUNTARYEXCESS, 0) AS VARCHAR)  AS RAW_VOLUNTARYEXCESS,
        COALESCE(TRIM(PM.RESTRICTIONOFDRIVERAGE),   '') AS RAW_RESTRICTIONOFDRIVERAGE,
        COALESCE(TRIM(PM.EXCESSWAIVERFORGLASS),     '') AS RAW_EXCESSWAIVERFORGLASS,
        COALESCE(TRIM(PM.CHOICEOFREPAIR),           '') AS RAW_CHOICEOFREPAIR,
        COALESCE(TRIM(PM.HIRECARHIREAFTERINCIDENT), '') AS RAW_HIRECARHIREAFTERINCIDENT,
        COALESCE(CAST(PM.MVADDACCORMODS AS VARCHAR), '') AS RAW_MVADDACCORMODS,
        COALESCE(TRIM(PM.VEHHAVEANINTERESTEDPARTY), '') AS RAW_VEHHAVEANINTERESTEDPARTY,
        -- mapped values from view (view owns all CASE logic)
        COALESCE(V.VEHICLETYPE,              '') AS MAP_VEHICLETYPE,
        COALESCE(V.PROTECTIONTYPE,           '') AS MAP_PROTECTIONTYPE,
        COALESCE(V.INDUCTIONTYPE,            '') AS MAP_INDUCTIONTYPE,
        COALESCE(V.VOLUNTARYEXCESS,          '') AS MAP_VOLUNTARYEXCESS,
        COALESCE(V.RESTRICTIONOFDRIVERAGE,   '') AS MAP_RESTRICTIONOFDRIVERAGE,
        COALESCE(V.EXCESSWAIVERFORGLASS,     '') AS MAP_EXCESSWAIVERFORGLASS,
        COALESCE(V.CHOICEOFREPAIR,           '') AS MAP_CHOICEOFREPAIR,
        COALESCE(V.HIRECARHIREAFTERINCIDENT, '') AS MAP_HIRECARHIREAFTERINCIDENT,
        COALESCE(V.MVADDACCORMODS,           '') AS MAP_MVADDACCORMODS,
        COALESCE(V.VEHHAVEANINTERESTEDPARTY, '') AS MAP_VEHHAVEANINTERESTEDPARTY
    FROM AGGNE.DEV.PM_03 PM
    JOIN MOTOR_SCOPE S
        ON CAST(TRIM(PM.PUREPOLICYNUMBER) ||'|'|| TRIM(PM.CMLNUMBER) ||'|'|| TRIM(PM.EXPIRINGID_P) AS VARCHAR) = S.POLICY_KEY
    JOIN AGGNE.DEV.PER_COM_PAYLOAD V
        ON S.POLICY_KEY = V.PUREPOLICYNUMBER
),

-- ─── Building: raw (Locationdetails_PER) + mapped (PER_RISK_BUILDING_FINAL)
BLDG_SRC AS (
    SELECT
        S.POLICY_KEY,
        -- raw source values from Locationdetails_PER
        COALESCE(TRIM(L.HOWOCCUPPIED),          '') AS RAW_HOWOCCUPPIED,
        COALESCE(TRIM(L.MAINWALLCONSTRUCTION),  '') AS RAW_MAINWALLCONSTRUCTION,
        COALESCE(TRIM(L.ROOFCONSTRUCTION),      '') AS RAW_ROOFCONSTRUCTION,
        COALESCE(TRIM(L.FLOORCONSTRUCTION),     '') AS RAW_FLOORCONSTRUCTION,
        COALESCE(TRIM(L.ALARMSYSTEMINSTALLED),  '') AS RAW_ALARMSYSTEMINSTALLED,
        COALESCE(TRIM(L.DEADLOCKSINSTALLED),    '') AS RAW_DEADLOCKSINSTALLED,
        COALESCE(TRIM(L.GRILLKEYLOCKINSTALLED), '') AS RAW_GRILLKEYLOCKINSTALLED,
        -- mapped values from view (_FINAL suffix columns)
        COALESCE(V.HOWOCCUPPIED,               '') AS MAP_HOWOCCUPPIED,
        COALESCE(V.MAINWALLCONSTRUCTION_FINAL, '') AS MAP_MAINWALLCONSTRUCTION,
        COALESCE(V.ROOFCONSTRUCTION_FINAL,     '') AS MAP_ROOFCONSTRUCTION,
        COALESCE(V.FLOORCONSTRUCTION_FINAL,    '') AS MAP_FLOORCONSTRUCTION,
        COALESCE(V.ALARMSYSTEMINSTALLED_FINAL, '') AS MAP_ALARMSYSTEMINSTALLED,
        COALESCE(V.DEADLOCKSINSTALLED_FINAL,   '') AS MAP_DEADLOCKSINSTALLED,
        COALESCE(V.GRILLKEYLOCKINSTALLED_FINAL,'') AS MAP_GRILLKEYLOCKINSTALLED
    FROM AGGNE.DEV.Locationdetails_PER L
    JOIN BLDG_SCOPE S
        ON CAST(TRIM(L.PUREPOLICYNUMBER) ||'|'|| TRIM(L.CMLNUMBER) ||'|'|| TRIM(L.EXPIRINGID_P) AS VARCHAR) = S.POLICY_KEY
    JOIN AGGNE.DEV.PER_RISK_BUILDING_FINAL V
        ON S.POLICY_KEY = V.PUREPOLICYNUMBER
)

-- ══════════════════════════════════════════════════════════════════════════
-- MOTOR FIELDS  (10 fields)
-- ══════════════════════════════════════════════════════════════════════════

-- 1. VehicleType
-- RHS: <VehicleType>{VEHICLETYPE}</VehicleType>  | manuscript line 2379-2393
SELECT
    POLICY_KEY AS PUREPOLICYNUMBER,
    'VehicleType' AS XML_PATH,
    'PassengerVehicle,CamperVan,Caravan,Forklift,Motorcycle,MobileEquipment,TowTruck,Tractor,Trailer,Transporter,HeavyVehicle,LightCommercial,HeavyCommercial' AS DCT_VALID_VALUES,
    RAW_VEHICLETYPE    AS SOURCE_RAW_VALUE,
    MAP_VEHICLETYPE    AS MAPPED_DCT_CODE,
    CASE
        WHEN MAP_VEHICLETYPE IN ('PassengerVehicle','CamperVan','Caravan','Forklift','Motorcycle',
            'MobileEquipment','TowTruck','Tractor','Trailer','Transporter',
            'HeavyVehicle','LightCommercial','HeavyCommercial') THEN 'PASS'
        WHEN MAP_VEHICLETYPE = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END AS STATUS
FROM MOTOR_SRC

UNION ALL

-- 2. ProtectionType
-- RHS: <ProtectionType>{PROTECTIONTYPE}</ProtectionType>  | manuscript line 2426-2436
SELECT
    POLICY_KEY,
    'ProtectionType',
    'ComprehensiveMarket,ComprehensiveAgreedValue,FireandTheft,Comprehensive,ThirdPartyFireandTheft,ThirdPartyOnly',
    RAW_PROTECTIONTYPE,
    MAP_PROTECTIONTYPE,
    CASE
        WHEN MAP_PROTECTIONTYPE IN ('ComprehensiveMarket','ComprehensiveAgreedValue','FireandTheft',
            'Comprehensive','ThirdPartyFireandTheft','ThirdPartyOnly') THEN 'PASS'
        WHEN MAP_PROTECTIONTYPE = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM MOTOR_SRC

UNION ALL

-- 3. InductionType
-- RHS: <InductionType>{INDUCTIONTYPE}</InductionType>  | manuscript line 2400-2415
SELECT
    POLICY_KEY,
    'InductionType',
    'Aspirated,Supercharged,Turbocharged,TurboandSupercharged',
    RAW_INDUCTIONTYPE,
    MAP_INDUCTIONTYPE,
    CASE
        WHEN MAP_INDUCTIONTYPE IN ('Aspirated','Supercharged','Turbocharged','TurboandSupercharged') THEN 'PASS'
        WHEN MAP_INDUCTIONTYPE = '' THEN 'PASS — blank (field omitted from payload)'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM MOTOR_SRC

UNION ALL

-- 4. VoluntaryExcess
-- RHS: <VoluntaryExcess>{VOLUNTARYEXCESS}</VoluntaryExcess>  | manuscript line 2244
SELECT
    POLICY_KEY,
    'VoluntaryExcess',
    '0,250,500,750,1000,1250,1500',
    RAW_VOLUNTARYEXCESS,
    MAP_VOLUNTARYEXCESS,
    CASE
        WHEN MAP_VOLUNTARYEXCESS IN ('0','250','500','750','1000','1250','1500') THEN 'PASS'
        WHEN MAP_VOLUNTARYEXCESS = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — value not in DCT list'
    END
FROM MOTOR_SRC

UNION ALL

-- 5. RestrictionOfDriverAge
-- RHS: <RestrictionOfDriverAge>{RESTRICTIONOFDRIVERAGE}</RestrictionOfDriverAge>  | manuscript line 2355
SELECT
    POLICY_KEY,
    'RestrictionOfDriverAge',
    '0,20,24,29,39',
    RAW_RESTRICTIONOFDRIVERAGE,
    MAP_RESTRICTIONOFDRIVERAGE,
    CASE
        WHEN MAP_RESTRICTIONOFDRIVERAGE IN ('0','20','24','29','39') THEN 'PASS'
        WHEN MAP_RESTRICTIONOFDRIVERAGE = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM MOTOR_SRC

UNION ALL

-- 6. ExcessWaiverForGlass
-- RHS: <ExcessWaiverForGlass>{EXCESSWAIVERFORGLASS}</ExcessWaiverForGlass>  | manuscript line 2221
SELECT
    POLICY_KEY,
    'ExcessWaiverForGlass',
    '1 (Protected),0 (Not Protected)',
    RAW_EXCESSWAIVERFORGLASS,
    MAP_EXCESSWAIVERFORGLASS,
    CASE
        WHEN MAP_EXCESSWAIVERFORGLASS IN ('0','1') THEN 'PASS'
        WHEN MAP_EXCESSWAIVERFORGLASS = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM MOTOR_SRC

UNION ALL

-- 7. ChoiceOfRepair
-- RHS: <ChoiceOfRepair>{CHOICEOFREPAIR}</ChoiceOfRepair>  | manuscript line 2268
SELECT
    POLICY_KEY,
    'ChoiceOfRepair',
    '1 (Taken),0 (Not Taken)',
    RAW_CHOICEOFREPAIR,
    MAP_CHOICEOFREPAIR,
    CASE
        WHEN MAP_CHOICEOFREPAIR IN ('0','1') THEN 'PASS'
        WHEN MAP_CHOICEOFREPAIR = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM MOTOR_SRC

UNION ALL

-- 8. HireCarHireAfterIncident
-- RHS: <HireCarHireAfterIncident>{HIRECARHIREAFTERINCIDENT}</HireCarHireAfterIncident>  | manuscript line 2295
SELECT
    POLICY_KEY,
    'HireCarHireAfterIncident',
    'Taken,NotTaken',
    RAW_HIRECARHIREAFTERINCIDENT,
    MAP_HIRECARHIREAFTERINCIDENT,
    CASE
        WHEN MAP_HIRECARHIREAFTERINCIDENT IN ('Taken','NotTaken') THEN 'PASS'
        WHEN MAP_HIRECARHIREAFTERINCIDENT = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM MOTOR_SRC

UNION ALL

-- 9. WouldYouLikeToAddAccessoriesOrModificationsMarket (MVADDACCORMODS)
-- RHS: <WouldYouLikeToAddAccessoriesOrModificationsMarket>{MVADDACCORMODS}</...>  | manuscript line 2452
SELECT
    POLICY_KEY,
    'WouldYouLikeToAddAccessoriesOrModificationsMarket',
    'Yes,No',
    RAW_MVADDACCORMODS,
    MAP_MVADDACCORMODS,
    CASE
        WHEN MAP_MVADDACCORMODS IN ('Yes','No') THEN 'PASS'
        WHEN MAP_MVADDACCORMODS = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM MOTOR_SRC

UNION ALL

-- 10. DoesTheVehicleHaveAnInterestedParty (VEHHAVEANINTERESTEDPARTY)
-- RHS: <DoesTheVehicleHaveAnInterestedParty>{VEHHAVEANINTERESTEDPARTY}</...>  | manuscript line 2484
SELECT
    POLICY_KEY,
    'DoesTheVehicleHaveAnInterestedParty',
    '1 (Yes),0 (No)',
    RAW_VEHHAVEANINTERESTEDPARTY,
    MAP_VEHHAVEANINTERESTEDPARTY,
    CASE
        WHEN MAP_VEHHAVEANINTERESTEDPARTY IN ('0','1') THEN 'PASS'
        WHEN MAP_VEHHAVEANINTERESTEDPARTY = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM MOTOR_SRC

-- ══════════════════════════════════════════════════════════════════════════
-- BUILDING FIELDS  (7 fields)
-- ══════════════════════════════════════════════════════════════════════════

UNION ALL

-- 11. HomeBuildingOccupied (HOWOCCUPPIED)
-- RHS: <HomeBuildingOccupied>{HOWOCCUPPIED}</HomeBuildingOccupied>  | manuscript line 11363
SELECT
    POLICY_KEY,
    'HomeBuildingOccupied',
    'OwnerOccupied,HolidayHome,OwnedleasedtoOthersLongTermLease,OwnedLeasedtoOthersShortTermRental,TenantedbyMember',
    RAW_HOWOCCUPPIED,
    MAP_HOWOCCUPPIED,
    CASE
        WHEN MAP_HOWOCCUPPIED IN ('OwnerOccupied','HolidayHome','OwnedleasedtoOthersLongTermLease',
            'OwnedLeasedtoOthersShortTermRental','TenantedbyMember') THEN 'PASS'
        WHEN MAP_HOWOCCUPPIED = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM BLDG_SRC

UNION ALL

-- 12. MainWallConstruction
-- RHS: <MainWallConstruction>{MAINWALLCONSTRUCTION}</...>  | manuscript line 11552
SELECT
    POLICY_KEY,
    'MainWallConstruction',
    'Asbestos,BrickVeneer,Concrete,DoubleBrick,FibroHardiplank,IronSteel,Wood',
    RAW_MAINWALLCONSTRUCTION,
    MAP_MAINWALLCONSTRUCTION,
    CASE
        WHEN MAP_MAINWALLCONSTRUCTION IN ('Asbestos','BrickVeneer','Concrete','DoubleBrick',
            'FibroHardiplank','IronSteel','Wood') THEN 'PASS'
        WHEN MAP_MAINWALLCONSTRUCTION = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code (client to confirm)'
    END
FROM BLDG_SRC

UNION ALL

-- 13. RoofConstruction
-- RHS: <RoofConstruction>{ROOFCONSTRUCTION}</...>  | manuscript line 11582
SELECT
    POLICY_KEY,
    'RoofConstruction',
    'Asbestos,Colourbond,Concrete,IronSteelTin,Tile,Wood',
    RAW_ROOFCONSTRUCTION,
    MAP_ROOFCONSTRUCTION,
    CASE
        WHEN MAP_ROOFCONSTRUCTION IN ('Asbestos','Colourbond','Concrete','IronSteelTin','Tile','Wood') THEN 'PASS'
        WHEN MAP_ROOFCONSTRUCTION = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM BLDG_SRC

UNION ALL

-- 14. FloorConstruction
-- RHS: <FloorConstruction>{FLOORCONSTRUCTION}</...>  | manuscript line 11611
SELECT
    POLICY_KEY,
    'FloorConstruction',
    'Concrete,Other,WoodConcretefootings,WoodStilts,WoodStumps',
    RAW_FLOORCONSTRUCTION,
    MAP_FLOORCONSTRUCTION,
    CASE
        WHEN MAP_FLOORCONSTRUCTION IN ('Concrete','Other','WoodConcretefootings',
            'WoodStilts','WoodStumps') THEN 'PASS'
        WHEN MAP_FLOORCONSTRUCTION = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code'
    END
FROM BLDG_SRC

UNION ALL

-- 15. WhatTypeOfAlarmSystemIsInstalled (ALARMSYSTEMINSTALLED)
-- RHS: <WhatTypeOfAlarmSystemIsInstalled>{ALARMSYSTEMINSTALLED}</...>  | manuscript line 11751
SELECT
    POLICY_KEY,
    'WhatTypeOfAlarmSystemIsInstalled',
    'LocalAudibleOnly,MonitoredBacktobase,MonitoredSecurity,MonitoredToMobilePhone,None',
    RAW_ALARMSYSTEMINSTALLED,
    MAP_ALARMSYSTEMINSTALLED,
    CASE
        WHEN MAP_ALARMSYSTEMINSTALLED IN ('LocalAudibleOnly','MonitoredBacktobase',
            'MonitoredSecurity','MonitoredToMobilePhone','None') THEN 'PASS'
        WHEN MAP_ALARMSYSTEMINSTALLED = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code (client to confirm)'
    END
FROM BLDG_SRC

UNION ALL

-- 16. AreDeadlocksInstalledOnAllExternalDoors (DEADLOCKSINSTALLED)
-- RHS: <AreDeadlocksInstalledOnAllExternalDoors>{DEADLOCKSINSTALLED}</...>  | manuscript line 11766
SELECT
    POLICY_KEY,
    'AreDeadlocksInstalledOnAllExternalDoors',
    'AllDoors,SomeDoors,None',
    RAW_DEADLOCKSINSTALLED,
    MAP_DEADLOCKSINSTALLED,
    CASE
        WHEN MAP_DEADLOCKSINSTALLED IN ('AllDoors','SomeDoors','None') THEN 'PASS'
        WHEN MAP_DEADLOCKSINSTALLED = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code (client to confirm)'
    END
FROM BLDG_SRC

UNION ALL

-- 17. BarsOrGrillsInstalledOnAllWindows (GRILLKEYLOCKINSTALLED)
-- RHS: <BarsOrGrillsInstalledOnAllWindows>{GRILLKEYLOCKINSTALLED}</...>  | manuscript line 11780
SELECT
    POLICY_KEY,
    'BarsOrGrillsInstalledOnAllWindows',
    'AllWindows,SomeWindows,None',
    RAW_GRILLKEYLOCKINSTALLED,
    MAP_GRILLKEYLOCKINSTALLED,
    CASE
        WHEN MAP_GRILLKEYLOCKINSTALLED IN ('AllWindows','SomeWindows','None') THEN 'PASS'
        WHEN MAP_GRILLKEYLOCKINSTALLED = '' THEN 'FAIL — blank after mapping'
        ELSE 'FAIL — not a valid DCT code (client to confirm)'
    END
FROM BLDG_SRC

ORDER BY PUREPOLICYNUMBER, XML_PATH
;
