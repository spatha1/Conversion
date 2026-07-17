-- ══════════════════════════════════════════════════════════════════════════
-- PP_FieldValidation_Report_SNOWFLAKE.sql
--
-- Purpose : Client-facing field validation report.
--           For every dropdown / enumerated field in the PP conversion,
--           shows: Source Table · Source Field · Source Value · Count · %
--                  DCT Field · DCT Valid Values · Mapped DCT Code · Status
--
-- DCT ref : Carrier_PersonalProtectionBase_1_0_0_0.xml
--           (Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/
--            CarrierPersonalPackage/CW-INH/)
--
-- Run in  : Snowflake worksheet — AGGNE.DEV schema
-- Scope   : SAMPLE_PER policies with EFFECTIVEDATE >= 2026-01-01
--           (PM_03 uses EXPIRYDATE >= 2026-01-01)
-- ══════════════════════════════════════════════════════════════════════════

WITH

-- ── scope filters ─────────────────────────────────────────────────────────
LOC_IN_SCOPE AS (
    SELECT DISTINCT T.PUREPOLICYNUMBER, T.EXPIRINGID_P
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T
    INNER JOIN AGGNE.DEV.SAMPLE_PER S
        ON TRIM(T.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
       AND T.EXPIRINGID_P = S.EXPIRINGID_P
    WHERE T.EFFECTIVEDATE >= '2026-01-01'
),
HB01_IN_SCOPE AS (
    SELECT DISTINCT T.PUREPOLICYNUMBER, T.EXPIRINGID_P
    FROM AGGNE.DEV.HB_01 T
    INNER JOIN AGGNE.DEV.SAMPLE_PER S
        ON TRIM(T.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
       AND T.EXPIRINGID_P = S.EXPIRINGID_P
    WHERE T.EFFECTIVEDATE >= '2026-01-01'
),
HB02_IN_SCOPE AS (
    SELECT DISTINCT T.PUREPOLICYNUMBER, T.EXPIRINGID_P
    FROM AGGNE.DEV.HB_02 T
    INNER JOIN AGGNE.DEV.SAMPLE_PER S
        ON TRIM(T.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
       AND T.EXPIRINGID_P = S.EXPIRINGID_P
    WHERE T.EFFECTIVEDATE >= '2026-01-01'
),
HC02_IN_SCOPE AS (
    SELECT DISTINCT T.PUREPOLICYNUMBER, T.EXPIRINGID_P
    FROM AGGNE.DEV.HC_02 T
    INNER JOIN AGGNE.DEV.SAMPLE_PER S
        ON TRIM(T.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
       AND T.EXPIRINGID_P = S.EXPIRINGID_P
    WHERE T.EFFECTIVEDATE >= '2026-01-01'
),
PM03_IN_SCOPE AS (
    SELECT DISTINCT T.PUREPOLICYNUMBER, T.EXPIRINGID_P
    FROM AGGNE.DEV.PM_03 T
    INNER JOIN AGGNE.DEV.SAMPLE_PER S
        ON TRIM(T.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE T.EXPIRYDATE >= '2026-01-01'
),

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 1: HOME BUILDING — LOCATIONDETAILS_PER
-- ══════════════════════════════════════════════════════════════════════════

-- ── 1A: RoofConstruction ─────────────────────────────────────────────────
ROOF_RAW AS (
    SELECT COALESCE(TRIM(T.ROOFCONSTRUCTION), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T
    INNER JOIN LOC_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
ROOF_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'Asbestos'             THEN 'Asbestos'
            WHEN SRC_VAL = 'Concrete'             THEN 'Concrete'
            WHEN SRC_VAL = 'Concrete (Flat Roof)' THEN 'Concrete'
            WHEN SRC_VAL = 'Iron'                 THEN 'IronSteelTin'
            WHEN SRC_VAL = 'Iron/Steel/Tin'       THEN 'IronSteelTin'
            WHEN SRC_VAL = 'Tin'                  THEN 'IronSteelTin'
            WHEN SRC_VAL ILIKE 'Colou%rbond'      THEN 'Colourbond'
            WHEN SRC_VAL ILIKE 'Color%bond'       THEN 'Colourbond'
            WHEN SRC_VAL = 'Tile'                 THEN 'Tile'
            WHEN SRC_VAL = 'Wood'                 THEN 'Wood'
            WHEN SRC_VAL = 'Wood (Shingles)'      THEN 'Wood'
            WHEN SRC_VAL = ''                     THEN ''
            ELSE SRC_VAL  -- raw passthrough
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = ''  THEN 'NULL/BLANK'
            WHEN SRC_VAL IN ('Asbestos','Concrete','Concrete (Flat Roof)','Iron','Iron/Steel/Tin',
                             'Tin','Tile','Wood','Wood (Shingles)') THEN 'PASS'
            WHEN SRC_VAL ILIKE 'Colou%rbond' OR SRC_VAL ILIKE 'Color%bond' THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM ROOF_RAW
),

-- ── 1B: MainWallConstruction ──────────────────────────────────────────────
WALL_RAW AS (
    SELECT COALESCE(TRIM(T.MAINWALLCONSTRUCTION), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T
    INNER JOIN LOC_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
WALL_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'Asbestos'             THEN 'Asbestos'
            WHEN SRC_VAL = 'Brick Veneer'         THEN 'BrickVeneer'
            WHEN SRC_VAL = 'Concrete'             THEN 'Concrete'
            WHEN SRC_VAL = 'Double Brick'         THEN 'DoubleBrick'
            WHEN SRC_VAL = 'Fibro (Non-Asbestos)' THEN 'FibroHardiplank'
            WHEN SRC_VAL = 'Fibro/Hardiplank'     THEN 'FibroHardiplank'
            WHEN SRC_VAL = 'Iron'                 THEN 'IronSteel'
            WHEN SRC_VAL = 'Iron/Steel'           THEN 'IronSteel'
            WHEN SRC_VAL = 'Steel'                THEN 'IronSteel'
            WHEN SRC_VAL = 'Wood'                 THEN 'Wood'
            WHEN SRC_VAL = ''                     THEN ''
            ELSE SRC_VAL
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK'
            WHEN SRC_VAL IN ('Asbestos','Brick Veneer','Concrete','Double Brick',
                             'Fibro (Non-Asbestos)','Fibro/Hardiplank','Iron',
                             'Iron/Steel','Steel','Wood') THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM WALL_RAW
),

-- ── 1C: FloorConstruction ────────────────────────────────────────────────
FLOOR_RAW AS (
    SELECT COALESCE(TRIM(T.FLOORCONSTRUCTION), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T
    INNER JOIN LOC_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
FLOOR_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'Concrete' THEN 'Concrete'
            WHEN SRC_VAL = 'Other'    THEN 'Other'
            WHEN SRC_VAL ILIKE 'Wood - Concrete Footings' THEN 'WoodConcretefootings'
            WHEN SRC_VAL ILIKE 'Wood - Stilts'            THEN 'WoodStilts'
            WHEN SRC_VAL ILIKE 'Wood - Stumps'            THEN 'WoodStumps'
            WHEN SRC_VAL = ''                             THEN ''
            ELSE SRC_VAL
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK'
            WHEN SRC_VAL IN ('Concrete','Other') THEN 'PASS'
            WHEN SRC_VAL ILIKE 'Wood - Concrete Footings'
              OR SRC_VAL ILIKE 'Wood - Stilts'
              OR SRC_VAL ILIKE 'Wood - Stumps' THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM FLOOR_RAW
),

-- ── 1D: WhatTypeOfAlarmSystemIsInstalled ─────────────────────────────────
ALARM_RAW AS (
    SELECT COALESCE(TRIM(T.ALARMSYSTEMINSTALLED), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T
    INNER JOIN LOC_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
ALARM_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'Local - Audible Only'        THEN 'LocalAudibleOnly'
            WHEN SRC_VAL = 'Monitored - Back to base'    THEN 'MonitoredBacktobase'
            WHEN SRC_VAL = 'Monitored - Security'        THEN 'MonitoredSecurity'
            WHEN SRC_VAL = 'Monitored - To Mobile Phone' THEN 'MonitoredToMobilePhone'
            WHEN SRC_VAL = 'None'                        THEN 'None'
            WHEN SRC_VAL = ''                            THEN ''
            ELSE SRC_VAL
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK'
            WHEN SRC_VAL IN ('Local - Audible Only','Monitored - Back to base',
                             'Monitored - Security','Monitored - To Mobile Phone','None') THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM ALARM_RAW
),

-- ── 1E: AreDeadlocksInstalledOnAllExternalDoors ──────────────────────────
DEAD_RAW AS (
    SELECT COALESCE(TRIM(T.DEADLOCKSINSTALLED), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T
    INNER JOIN LOC_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
DEAD_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'All doors'  THEN 'AllDoors'
            WHEN SRC_VAL = 'Some doors' THEN 'SomeDoors'
            WHEN SRC_VAL = 'None'       THEN 'None'
            WHEN SRC_VAL = ''           THEN ''
            ELSE SRC_VAL
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK'
            WHEN SRC_VAL IN ('All doors','Some doors','None') THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM DEAD_RAW
),

-- ── 1F: BarsOrGrillsInstalledOnAllWindows ────────────────────────────────
GRILL_RAW AS (
    SELECT COALESCE(TRIM(T.GRILLKEYLOCKINSTALLED), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T
    INNER JOIN LOC_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
GRILL_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'All windows'  THEN 'AllWindows'
            WHEN SRC_VAL = 'Some windows' THEN 'SomeWindows'
            WHEN SRC_VAL = 'None'         THEN 'None'
            WHEN SRC_VAL = ''             THEN ''
            ELSE SRC_VAL
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK'
            WHEN SRC_VAL IN ('All windows','Some windows','None') THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM GRILL_RAW
),

-- ── 1G: HowIsTheBuildingOccupied ─────────────────────────────────────────
HOW_RAW AS (
    SELECT COALESCE(TRIM(T.HOWOCCUPPIED), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T
    INNER JOIN LOC_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
HOW_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'Owner Occupied'                             THEN 'OwnerOccupied'
            WHEN SRC_VAL ILIKE 'Tenanted by member'                     THEN 'TenantedbyMember'
            WHEN SRC_VAL = 'Owned leased to Others - Long Term Lease'   THEN 'OwnedleasedtoOthersLongTermLease'
            WHEN SRC_VAL = 'Holiday Home'                               THEN 'HolidayHome'
            WHEN SRC_VAL = 'Owned leased to Others - Short Term Rental' THEN 'OwnedLeasedtoOthersShortTermRental'
            WHEN SRC_VAL = ''                                           THEN ''
            ELSE SRC_VAL
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK'
            WHEN SRC_VAL IN ('Owner Occupied','Holiday Home',
                             'Owned leased to Others - Long Term Lease',
                             'Owned leased to Others - Short Term Rental')
                 OR SRC_VAL ILIKE 'Tenanted by member' THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM HOW_RAW
),

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 2: HOME BUILDING — HB_01 / HB_02
-- ══════════════════════════════════════════════════════════════════════════

-- ── 2A: AccidentalLossOrDamage (HB_01) ───────────────────────────────────
ALOD_RAW AS (
    SELECT COALESCE(TRIM(T.ACCIDENTALLOSSORDAMAGE), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.HB_01 T
    INNER JOIN HB01_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
ALOD_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE WHEN SRC_VAL = 'Taken' THEN '1' WHEN SRC_VAL = 'Not Taken' THEN '0' ELSE '' END AS DCT_CODE,
        CASE WHEN SRC_VAL = '' THEN 'NULL/BLANK'
             WHEN SRC_VAL IN ('Taken','Not Taken') THEN 'PASS'
             ELSE 'FAIL' END AS STATUS
    FROM ALOD_RAW
),

-- ── 2B: MinimumRentalPeriod (HB_02) ──────────────────────────────────────
RENTAL_RAW AS (
    SELECT COALESCE(TRIM(T.MINIMUMRENTALPERIOD), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.HB_02 T
    INNER JOIN HB02_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
RENTAL_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE WHEN SRC_VAL = 'More than 90 Days' THEN 'Morethan90Days'
             WHEN SRC_VAL = 'Less than 90 Days' THEN 'Lessthan90Days'
             WHEN SRC_VAL = '' THEN ''
             ELSE SRC_VAL END AS DCT_CODE,
        CASE WHEN SRC_VAL = '' THEN 'NULL/BLANK'
             WHEN SRC_VAL IN ('More than 90 Days','Less than 90 Days') THEN 'PASS'
             ELSE 'FAIL - no DCT mapping' END AS STATUS
    FROM RENTAL_RAW
),

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 3: HOME CONTENTS — HC_02
-- ══════════════════════════════════════════════════════════════════════════

-- ── 3A: HomeContentsLimits (ANYITEMSEXCEEDVALUE) ─────────────────────────
HCITEMS_RAW AS (
    SELECT COALESCE(TRIM(T.ANYITEMSEXCEEDVALUE), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.HC_02 T
    INNER JOIN HC02_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
HCITEMS_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE WHEN SRC_VAL = '' THEN 'No' ELSE SRC_VAL END AS DCT_CODE,
        CASE WHEN SRC_VAL = '' THEN 'PASS (default No)'
             WHEN SRC_VAL IN ('Yes','No') THEN 'PASS'
             ELSE 'FAIL' END AS STATUS
    FROM HCITEMS_RAW
),

-- ── 3B: SpecifiedItemsAway ───────────────────────────────────────────────
SPECD_RAW AS (
    SELECT COALESCE(TRIM(T.SPECIFIEDITEMSAWAY), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.HC_02 T
    INNER JOIN HC02_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
SPECD_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE WHEN SRC_VAL = '' THEN 'Not Taken' ELSE SRC_VAL END AS DCT_CODE,
        CASE WHEN SRC_VAL = '' THEN 'PASS (default Not Taken)'
             WHEN SRC_VAL IN ('Taken','Not Taken') THEN 'PASS'
             ELSE 'FAIL' END AS STATUS
    FROM SPECD_RAW
),

-- ── 3C: UnspecifiedItemsAway ─────────────────────────────────────────────
UNSP_RAW AS (
    SELECT COALESCE(TRIM(T.UNSPECIFIEDITEMSAWAY), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.HC_02 T
    INNER JOIN HC02_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
UNSP_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE WHEN SRC_VAL = '' THEN 'Not Taken' ELSE SRC_VAL END AS DCT_CODE,
        CASE WHEN SRC_VAL = '' THEN 'PASS (default Not Taken)'
             WHEN SRC_VAL IN ('Taken','Not Taken') THEN 'PASS'
             ELSE 'FAIL' END AS STATUS
    FROM UNSP_RAW
),

-- ── 3D: UnspecifiedItemsAwayLimit ────────────────────────────────────────
UNSPLMT_RAW AS (
    SELECT COALESCE(TRIM(T.UNSPECIFIEDITEMSAWAYLIMIT), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.HC_02 T
    INNER JOIN HC02_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
UNSPLMT_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = '$2,000 per item up to $10,000 per event' THEN '2000peritemupto10000perevent'
            WHEN SRC_VAL = '$1,250 per item up to $5,000 per event'  THEN '1250peritemupto5000perevent'
            WHEN SRC_VAL = '' THEN ''
            ELSE SRC_VAL
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK (only applies when UnspecifiedItemsAway=Taken)'
            WHEN SRC_VAL IN ('$2,000 per item up to $10,000 per event',
                             '$1,250 per item up to $5,000 per event') THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM UNSPLMT_RAW
),

-- ── 3E: FloodDamage ──────────────────────────────────────────────────────
FLOOD_RAW AS (
    SELECT COALESCE(TRIM(T.FLOODDAMAGE), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.HC_02 T
    INNER JOIN HC02_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
FLOOD_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE WHEN SRC_VAL = '' THEN '' ELSE SRC_VAL END AS DCT_CODE,
        CASE WHEN SRC_VAL = '' THEN 'NULL/BLANK'
             WHEN SRC_VAL IN ('Taken','Not Taken') THEN 'PASS'
             ELSE 'FAIL' END AS STATUS
    FROM FLOOD_RAW
),

-- ══════════════════════════════════════════════════════════════════════════
-- SECTION 4: MOTOR — PM_03
-- ══════════════════════════════════════════════════════════════════════════

-- ── 4A: ProtectionType ───────────────────────────────────────────────────
PROT_RAW AS (
    SELECT COALESCE(TRIM(T.PROTECTIONTYPE), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.PM_03 T
    INNER JOIN PM03_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
PROT_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'Comprehensive - Market Value'    THEN 'ComprehensiveMarket'
            WHEN SRC_VAL = 'Comprehensive - Agreed Value'    THEN 'ComprehensiveAgreedValue'
            WHEN SRC_VAL = 'Fire and Theft'                  THEN 'FireandTheft'
            WHEN SRC_VAL = 'Comprehensive'                   THEN 'Comprehensive'
            WHEN SRC_VAL = 'Third Party Only'                THEN 'ThirdPartyOnly'
            WHEN SRC_VAL = 'Third Party, Fire and Theft'     THEN 'ThirdPartyFireandTheft'
            WHEN SRC_VAL = ''                                THEN ''
            ELSE ''
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK'
            WHEN SRC_VAL IN ('Comprehensive - Market Value','Comprehensive - Agreed Value',
                             'Fire and Theft','Comprehensive','Third Party Only',
                             'Third Party, Fire and Theft') THEN 'PASS'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM PROT_RAW
),

-- ── 4B: VehicleType ──────────────────────────────────────────────────────
VEH_RAW AS (
    SELECT COALESCE(TRIM(T.VEHICLETYPE), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.PM_03 T
    INNER JOIN PM03_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
VEH_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'Passenger Vehicle'  THEN 'PassengerVehicle'
            WHEN SRC_VAL = 'Caravan'            THEN 'Caravan'
            WHEN SRC_VAL = 'Camper Van'         THEN 'CamperVan'
            WHEN SRC_VAL = 'Trailer'            THEN 'Trailer'
            WHEN SRC_VAL = 'Motorcycle'         THEN 'Motorcycle'
            WHEN SRC_VAL = 'Light Commercial'   THEN 'LightCommercial'
            WHEN SRC_VAL = 'Heavy Commercial'   THEN 'HeavyCommercial'
            WHEN SRC_VAL = 'Heavy Vehicle'      THEN 'HeavyVehicle'
            WHEN SRC_VAL = 'Mobile Equipment'   THEN 'MobileEquipment'
            WHEN SRC_VAL = 'Forklift'           THEN 'Forklift'
            WHEN SRC_VAL = 'Tow Truck'          THEN 'TowTruck'
            WHEN SRC_VAL = 'Transporter'        THEN 'Transporter'
            WHEN SRC_VAL = 'Tractor'            THEN 'Tractor'
            WHEN SRC_VAL = ''                   THEN 'PassengerVehicle'
            ELSE SRC_VAL
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL IN ('Passenger Vehicle','Caravan','Camper Van','Trailer',
                             'Motorcycle','Light Commercial','Heavy Commercial',
                             'Heavy Vehicle','Mobile Equipment','Forklift',
                             'Tow Truck','Transporter','Tractor') THEN 'PASS'
            WHEN SRC_VAL = ''                   THEN 'PASS (default PassengerVehicle)'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM VEH_RAW
),

-- ── 4C: InductionType ────────────────────────────────────────────────────
IND_RAW AS (
    SELECT COALESCE(TRIM(T.INDUCTIONTYPE), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.PM_03 T
    INNER JOIN PM03_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
IND_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'Aspirated'                      THEN 'Aspirated'
            WHEN SRC_VAL IN ('Supercharged','Supercharged Intercooled',
                             'Twin Supercharged Intercooled')           THEN 'Supercharged'
            WHEN SRC_VAL IN ('Turbo','Turbo Intercooled','Turbocharged',
                             'Twin Turbo Intercooled','Triple Turbo Intercooled',
                             'Quad Turbo Intercooled')                  THEN 'Turbocharged'
            WHEN SRC_VAL = 'Turbo Supercharged Intercooled' THEN 'TurboandSupercharged'
            WHEN SRC_VAL = ''                               THEN ''
            ELSE ''
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'NULL/BLANK (most motor policies have no induction specified)'
            WHEN SRC_VAL IN ('Aspirated','Supercharged','Supercharged Intercooled',
                             'Twin Supercharged Intercooled','Turbo','Turbo Intercooled',
                             'Twin Turbo Intercooled','Triple Turbo Intercooled',
                             'Quad Turbo Intercooled','Turbo Supercharged Intercooled') THEN 'PASS'
            WHEN SRC_VAL = 'Turbocharged' THEN 'PASS (fixed 2026-07-01: source value = DCT code)'
            ELSE 'FAIL - no DCT mapping'
        END AS STATUS
    FROM IND_RAW
),

-- ── 4D: RestrictionOfDriverAge ───────────────────────────────────────────
REST_RAW AS (
    SELECT COALESCE(TRIM(T.RESTRICTIONOFDRIVERAGE), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.PM_03 T
    INNER JOIN PM03_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
REST_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE
            WHEN SRC_VAL = 'No Restriction' THEN '0'
            WHEN SRC_VAL = 'Min Age 21'     THEN '20'
            WHEN SRC_VAL = 'Min Age 25'     THEN '24'
            WHEN SRC_VAL = 'Min Age 30'     THEN '29'
            WHEN SRC_VAL = 'Min Age 40'     THEN '39'
            WHEN SRC_VAL = ''               THEN '0'
            ELSE '0'
        END AS DCT_CODE,
        CASE
            WHEN SRC_VAL = '' THEN 'PASS (default 0 = No Restriction)'
            WHEN SRC_VAL IN ('No Restriction','Min Age 21','Min Age 25',
                             'Min Age 30','Min Age 40') THEN 'PASS'
            ELSE 'FAIL - unexpected value, defaults to 0'
        END AS STATUS
    FROM REST_RAW
),

-- ── 4E: WouldYouLikeToAddAccessoriesOrModifications ──────────────────────
MVACC_RAW AS (
    SELECT COALESCE(TRIM(T.MVADDACCORMODS), '') AS SRC_VAL, COUNT(*) AS CNT
    FROM AGGNE.DEV.PM_03 T
    INNER JOIN PM03_IN_SCOPE S USING (PUREPOLICYNUMBER, EXPIRINGID_P)
    GROUP BY 1
),
MVACC_MAPPED AS (
    SELECT SRC_VAL, CNT,
        CASE WHEN SRC_VAL = 'Yes' THEN 'Yes' ELSE 'No' END AS DCT_CODE,
        CASE WHEN SRC_VAL IN ('Yes','No','') THEN 'PASS'
             ELSE 'PASS (defaults to No)' END AS STATUS
    FROM MVACC_RAW
)

-- ══════════════════════════════════════════════════════════════════════════
-- FINAL UNION — all fields
-- ══════════════════════════════════════════════════════════════════════════

SELECT
    'Home Building'              AS "Line of Business",
    'LOCATIONDETAILS_PER'        AS "Source Table (Pure)",
    'ROOFCONSTRUCTION'           AS "Source Field",
    SRC_VAL                      AS "Source Value (Actual)",
    CNT                          AS "Count",
    ROUND(CNT * 100.0 / SUM(CNT) OVER (), 1) AS "% of Field Total",
    'RoofConstruction'           AS "DCT Field Name",
    'Asbestos | Colourbond | Concrete | IronSteelTin | Tile | Wood'
                                 AS "DCT Valid Values",
    DCT_CODE                     AS "Mapped To (DCT Code)",
    STATUS                       AS "Status",
    'Manuscript line 11578-11589 (REQUIRED)'
                                 AS "DCT Manuscript Reference"
FROM ROOF_MAPPED

UNION ALL

SELECT 'Home Building','LOCATIONDETAILS_PER','MAINWALLCONSTRUCTION',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'MainWallConstruction',
    'Asbestos | BrickVeneer | Concrete | DoubleBrick | FibroHardiplank | IronSteel | Wood',
    DCT_CODE, STATUS, 'Manuscript line 11548-11560 (REQUIRED)'
FROM WALL_MAPPED

UNION ALL

SELECT 'Home Building','LOCATIONDETAILS_PER','FLOORCONSTRUCTION',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'FloorConstruction',
    'Concrete | Other | WoodConcretefootings | WoodStilts | WoodStumps',
    DCT_CODE, STATUS, 'Manuscript line 11607-11617 (REQUIRED)'
FROM FLOOR_MAPPED

UNION ALL

SELECT 'Home Building','LOCATIONDETAILS_PER','ALARMSYSTEMINSTALLED',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'WhatTypeOfAlarmSystemIsInstalled',
    'LocalAudibleOnly | MonitoredBacktobase | MonitoredSecurity | MonitoredToMobilePhone | None',
    DCT_CODE, STATUS, 'Manuscript line 11747-11761 (REQUIRED)'
FROM ALARM_MAPPED

UNION ALL

SELECT 'Home Building','LOCATIONDETAILS_PER','DEADLOCKSINSTALLED',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'AreDeadlocksInstalledOnAllExternalDoors',
    'AllDoors | SomeDoors | None',
    DCT_CODE, STATUS, 'Manuscript line 11763-11775 (REQUIRED)'
FROM DEAD_MAPPED

UNION ALL

SELECT 'Home Building','LOCATIONDETAILS_PER','GRILLKEYLOCKINSTALLED',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'BarsOrGrillsInstalledOnAllWindows',
    'AllWindows | SomeWindows | None',
    DCT_CODE, STATUS, 'Manuscript line 11777-11789 (REQUIRED)'
FROM GRILL_MAPPED

UNION ALL

SELECT 'Home Building','LOCATIONDETAILS_PER','HOWOCCUPPIED',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'HowIsTheBuildingOccupied',
    'OwnerOccupied | HolidayHome | OwnedleasedtoOthersLongTermLease | OwnedLeasedtoOthersShortTermRental | TenantedbyMember',
    DCT_CODE, STATUS, 'Manuscript line 11363-11369 (REQUIRED)'
FROM HOW_MAPPED

UNION ALL

SELECT 'Home Building','HB_01','ACCIDENTALLOSSORDAMAGE',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'AccidentalLossOrDamage (Indicator)',
    '1 = Taken | 0 = Not Taken',
    DCT_CODE, STATUS, 'Manuscript line 11200-11210'
FROM ALOD_MAPPED

UNION ALL

SELECT 'Home Building','HB_02','MINIMUMRENTALPERIOD',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'MinimumRentalPeriod',
    'Morethan90Days | Lessthan90Days',
    DCT_CODE, STATUS, 'Manuscript line 11400-11410 (LandlordProtections)'
FROM RENTAL_MAPPED

UNION ALL

SELECT 'Home Contents','HC_02','ANYITEMSEXCEEDVALUE',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'HomeContentsLimits',
    'Yes | No',
    DCT_CODE, STATUS, 'Manuscript line 11450-11460'
FROM HCITEMS_MAPPED

UNION ALL

SELECT 'Home Contents','HC_02','SPECIFIEDITEMSAWAY',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'SpecifiedItemsAway',
    'Taken | Not Taken',
    DCT_CODE, STATUS, 'Manuscript line 11470-11480'
FROM SPECD_MAPPED

UNION ALL

SELECT 'Home Contents','HC_02','UNSPECIFIEDITEMSAWAY',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'UnspecifiedItemsAway',
    'Taken | Not Taken',
    DCT_CODE, STATUS, 'Manuscript line 11480-11490'
FROM UNSP_MAPPED

UNION ALL

SELECT 'Home Contents','HC_02','UNSPECIFIEDITEMSAWAYLIMIT',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'UnspecifiedItemsAwayLimit',
    '$2000/item up to $10000/event | $1250/item up to $5000/event',
    DCT_CODE, STATUS, 'Manuscript line 11490-11510'
FROM UNSPLMT_MAPPED

UNION ALL

SELECT 'Home Contents','HC_02','FLOODDAMAGE',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'FloodDamage',
    'Taken | Not Taken',
    DCT_CODE, STATUS,
    'Manuscript line 11530-11540 — NOTE: currently hardcoded Taken in seq 13 template (PP-CF-04)'
FROM FLOOD_MAPPED

UNION ALL

SELECT 'Motor','PM_03','PROTECTIONTYPE',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'ProtectionType',
    'ComprehensiveMarket | ComprehensiveAgreedValue | FireandTheft | Comprehensive | ThirdPartyFireandTheft | ThirdPartyOnly',
    DCT_CODE, STATUS, 'Manuscript line 2423-2436'
FROM PROT_MAPPED

UNION ALL

SELECT 'Motor','PM_03','VEHICLETYPE',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'VehicleType',
    'PassengerVehicle | CamperVan | Caravan | Forklift | Motorcycle | MobileEquipment | TowTruck | Tractor | Trailer | Transporter | HeavyVehicle | LightCommercial | HeavyCommercial',
    DCT_CODE, STATUS, 'Manuscript line 2379-2393 (default options block)'
FROM VEH_MAPPED

UNION ALL

SELECT 'Motor','PM_03','INDUCTIONTYPE',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'InductionType',
    'Aspirated | Supercharged | Turbocharged | TurboandSupercharged',
    DCT_CODE, STATUS, 'Manuscript line 2400-2415'
FROM IND_MAPPED

UNION ALL

SELECT 'Motor','PM_03','RESTRICTIONOFDRIVERAGE',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'RestrictionOfDriverAge',
    '0 (No Restriction) | 20 (Min Age 21) | 24 (Min Age 25) | 29 (Min Age 30) | 39 (Min Age 40)',
    DCT_CODE, STATUS, 'Manuscript line 2356-2360'
FROM REST_MAPPED

UNION ALL

SELECT 'Motor','PM_03','MVADDACCORMODS',
    SRC_VAL, CNT, ROUND(CNT*100.0/SUM(CNT) OVER(), 1),
    'WouldYouLikeToAddAccessoriesOrModifications',
    'Yes | No',
    DCT_CODE, STATUS,
    'Manuscript line 2449-2464 (REQUIRED) — NOTE: live seq 18 template has empty element (PP-CF-22)'
FROM MVACC_MAPPED

ORDER BY "Line of Business", "Source Table (Pure)", "Source Field", "Count" DESC;
