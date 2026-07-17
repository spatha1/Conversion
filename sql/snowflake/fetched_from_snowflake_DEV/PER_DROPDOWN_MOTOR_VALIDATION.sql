create or replace view PER_DROPDOWN_MOTOR_VALIDATION(
	LEGACYPOLICYNUMBER,
	REGISTRATIONNUMBER,
	FIELD,
	SOURCE_VALUE,
	XML_VALUE,
	DCT_VALUES,
	IS_IN_DCT_LIST,
	COMMENT
) as

-- One row per vehicle: latest EXPIRYDATE wins when PM_03 has multiple records
-- for the same (policy, registration). Mapping CASE logic mirrors PER_COM_PAYLOAD.
WITH VEHICLE AS (
    SELECT
        TRIM(T1.PUREPOLICYNUMBER)   AS LEGACYPOLICYNUMBER,
        TRIM(T1.REGISTRATIONNUMBER) AS REGISTRATIONNUMBER,

        -- Source values (raw from PM_03)
        T1.VEHICLETYPE    AS SRC_VEHICLETYPE,
        T1.PROTECTIONTYPE AS SRC_PROTECTIONTYPE,
        T1.BODYTYPE       AS SRC_BODYTYPE,
        T1.INDUCTIONTYPE  AS SRC_INDUCTIONTYPE,

        -- Mapped: VehicleType
        CASE
            WHEN TRIM(T1.VEHICLETYPE) = 'Passenger Vehicle' THEN 'PassengerVehicle'
            WHEN TRIM(T1.VEHICLETYPE) = 'Caravan'           THEN 'Caravan'
            WHEN TRIM(T1.VEHICLETYPE) = 'Camper Van'        THEN 'CamperVan'
            WHEN TRIM(T1.VEHICLETYPE) = 'Trailer'           THEN 'Trailer'
            WHEN TRIM(T1.VEHICLETYPE) = 'Motorcycle'        THEN 'Motorcycle'
            WHEN TRIM(T1.VEHICLETYPE) = 'Light Commercial'  THEN 'LightCommercial'
            WHEN TRIM(T1.VEHICLETYPE) = 'Heavy Commercial'  THEN 'HeavyCommercial'
            WHEN TRIM(T1.VEHICLETYPE) = 'Heavy Vehicle'     THEN 'HeavyVehicle'
            WHEN TRIM(T1.VEHICLETYPE) = 'Mobile Equipment'  THEN 'MobileEquipment'
            WHEN TRIM(T1.VEHICLETYPE) = 'Forklift'          THEN 'Forklift'
            WHEN TRIM(T1.VEHICLETYPE) = 'Tow Truck'         THEN 'TowTruck'
            WHEN TRIM(T1.VEHICLETYPE) = 'Transporter'       THEN 'Transporter'
            WHEN TRIM(T1.VEHICLETYPE) = 'Tractor'           THEN 'Tractor'
            WHEN T1.VEHICLETYPE IS NULL OR TRIM(T1.VEHICLETYPE) = '' THEN 'PassengerVehicle'
            ELSE T1.VEHICLETYPE
        END AS DCT_VEHICLETYPE,

        -- Mapped: ProtectionType
        CASE
            WHEN T1.PROTECTIONTYPE = 'Comprehensive - Market Value'   THEN 'ComprehensiveMarket'
            WHEN T1.PROTECTIONTYPE = 'Comprehensive - Agreed Value'   THEN 'ComprehensiveAgreedValue'
            WHEN T1.PROTECTIONTYPE = 'Fire and Theft'                 THEN 'FireandTheft'
            WHEN T1.PROTECTIONTYPE = 'Comprehensive'                  THEN 'Comprehensive'
            WHEN T1.PROTECTIONTYPE = 'Third Party Only'               THEN 'ThirdPartyOnly'
            WHEN T1.PROTECTIONTYPE = 'Third Party, Fire and Theft'    THEN 'ThirdPartyFireandTheft'
            ELSE ''
        END AS DCT_PROTECTIONTYPE,

        -- Mapped: BodyType
        CASE
            WHEN TRIM(T1.BODYTYPE) = 'B-double'         THEN 'B-double'
            WHEN TRIM(T1.BODYTYPE) = 'Bus'              THEN 'Bus'
            WHEN TRIM(T1.BODYTYPE) = 'Bus Chassis'      THEN 'BusChassis'
            WHEN TRIM(T1.BODYTYPE) = 'Cab Chassis'      THEN 'CabChassis'
            WHEN TRIM(T1.BODYTYPE) = 'Cabriolet'        THEN 'Cabriolet'
            WHEN TRIM(T1.BODYTYPE) = 'Compactor'        THEN 'Compactor'
            WHEN TRIM(T1.BODYTYPE) = 'Convertible'      THEN 'Convertible'
            WHEN TRIM(T1.BODYTYPE) = 'Coupe'            THEN 'Coupe'
            WHEN TRIM(T1.BODYTYPE) = 'Distributor'      THEN 'Distributor'
            WHEN TRIM(T1.BODYTYPE) = 'Dump'             THEN 'Dump'
            WHEN TRIM(T1.BODYTYPE) = 'Extra Heavy Duty' THEN 'ExtraHeavyDuty'
            WHEN TRIM(T1.BODYTYPE) = 'Fastback'         THEN 'Fastback'
            WHEN TRIM(T1.BODYTYPE) = 'Hardtop'          THEN 'Hardtop'
            WHEN TRIM(T1.BODYTYPE) = 'Hatchback'        THEN 'Hatchback'
            WHEN TRIM(T1.BODYTYPE) = 'Heavy Duty'       THEN 'HeavyDuty'
            WHEN TRIM(T1.BODYTYPE) = 'Highway'          THEN 'Highway'
            WHEN TRIM(T1.BODYTYPE) = 'Liftback'         THEN 'Liftback'
            WHEN TRIM(T1.BODYTYPE) = 'Limousine'        THEN 'Limousine'
            WHEN TRIM(T1.BODYTYPE) = 'Mixer'            THEN 'Mixer'
            WHEN TRIM(T1.BODYTYPE) = 'Prime Mover'      THEN 'PrimeMover'
            WHEN TRIM(T1.BODYTYPE) = 'Rigid'            THEN 'Rigid'
            WHEN TRIM(T1.BODYTYPE) = 'Road Train'       THEN 'RoadTrain'
            WHEN TRIM(T1.BODYTYPE) = 'Roadster'         THEN 'Roadster'
            WHEN TRIM(T1.BODYTYPE) = 'Sedan'            THEN 'Sedan'
            WHEN TRIM(T1.BODYTYPE) = 'Softtop'          THEN 'Softtop'
            WHEN TRIM(T1.BODYTYPE) = 'Street Sweeper'   THEN 'StreetSweeper'
            WHEN TRIM(T1.BODYTYPE) = 'Targa'            THEN 'Targa'
            WHEN TRIM(T1.BODYTYPE) = 'Tipper'           THEN 'Tipper'
            WHEN TRIM(T1.BODYTYPE) = 'Trailer'          THEN 'Trailer'
            WHEN TRIM(T1.BODYTYPE) = 'Traytop'          THEN 'Traytop'
            WHEN TRIM(T1.BODYTYPE) = 'Utility'          THEN 'Utility'
            WHEN TRIM(T1.BODYTYPE) = 'Van'              THEN 'Van'
            WHEN TRIM(T1.BODYTYPE) = 'Van Wagon'        THEN 'VanWagon'
            WHEN TRIM(T1.BODYTYPE) = 'Wagon'            THEN 'Wagon'
            ELSE ''
        END AS DCT_BODYTYPE,

        -- Mapped: InductionType
        CASE
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Aspirated'                      THEN 'Aspirated'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Supercharged Intercooled'       THEN 'Supercharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Twin Supercharged Intercooled'  THEN 'Supercharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Supercharged'                   THEN 'Supercharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Turbo'                          THEN 'Turbocharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Turbo Intercooled'              THEN 'Turbocharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Twin Turbo Intercooled'         THEN 'Turbocharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Triple Turbo Intercooled'       THEN 'Turbocharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Quad Turbo Intercooled'         THEN 'Turbocharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Turbocharged'                   THEN 'Turbocharged'
            WHEN TRIM(T1.INDUCTIONTYPE) = 'Turbo Supercharged Intercooled' THEN 'TurboandSupercharged'
            ELSE ''
        END AS DCT_INDUCTIONTYPE

    FROM AGGNE.DEV.PM_03 T1
    INNER JOIN AGGNE.DEV.SAMPLE_PER S
        ON TRIM(T1.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE T1.EXPIRYDATE >= '2026-01-01'
      AND T1.YEAR        <> 0
      AND TRIM(T1.MAKE)  <> ''
      AND TRIM(T1.MODEL) <> ''
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRIM(T1.PUREPOLICYNUMBER), TRIM(T1.REGISTRATIONNUMBER)
        ORDER BY T1.EXPIRYDATE DESC
    ) = 1
)

-- ── 1. VehicleType (REQUIRED in DCT) ────────────────────────────────────────
SELECT
    LEGACYPOLICYNUMBER,
    REGISTRATIONNUMBER,
    'VehicleType'                                                                                                                                                                          AS FIELD,
    SRC_VEHICLETYPE                                                                                                                                                                        AS SOURCE_VALUE,
    DCT_VEHICLETYPE                                                                                                                                                                        AS XML_VALUE,
    '["PassengerVehicle","CamperVan","Caravan","Forklift","Motorcycle","MobileEquipment","TowTruck","Tractor","Trailer","Transporter","HeavyVehicle","LightCommercial","HeavyCommercial"]' AS DCT_VALUES,
    CASE
        WHEN DCT_VEHICLETYPE IN ('PassengerVehicle','CamperVan','Caravan','Forklift','Motorcycle',
                                 'MobileEquipment','TowTruck','Tractor','Trailer','Transporter',
                                 'HeavyVehicle','LightCommercial','HeavyCommercial')
             THEN 'Yes' ELSE 'No'
    END                                                                                                                                                                                    AS IS_IN_DCT_LIST,
    CASE
        WHEN TRIM(COALESCE(SRC_VEHICLETYPE,'')) = ''
             THEN 'Blank in source — defaulted to PassengerVehicle (client to confirm)'
        WHEN DCT_VEHICLETYPE IN ('PassengerVehicle','CamperVan','Caravan','Forklift','Motorcycle',
                                 'MobileEquipment','TowTruck','Tractor','Trailer','Transporter',
                                 'HeavyVehicle','LightCommercial','HeavyCommercial')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END                                                                                                                                                                                    AS COMMENT
FROM VEHICLE

UNION ALL

-- ── 2. ProtectionType (REQUIRED in DCT) ─────────────────────────────────────
SELECT
    LEGACYPOLICYNUMBER, REGISTRATIONNUMBER,
    'ProtectionType',
    SRC_PROTECTIONTYPE,
    DCT_PROTECTIONTYPE,
    '["ComprehensiveMarket","ComprehensiveAgreedValue","FireandTheft","Comprehensive","ThirdPartyOnly","ThirdPartyFireandTheft"]',
    CASE
        WHEN TRIM(COALESCE(SRC_PROTECTIONTYPE,'')) = '' THEN 'N/A'
        WHEN DCT_PROTECTIONTYPE IN ('ComprehensiveMarket','ComprehensiveAgreedValue','FireandTheft',
                                    'Comprehensive','ThirdPartyOnly','ThirdPartyFireandTheft')
             THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC_PROTECTIONTYPE,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN DCT_PROTECTIONTYPE IN ('ComprehensiveMarket','ComprehensiveAgreedValue','FireandTheft',
                                    'Comprehensive','ThirdPartyOnly','ThirdPartyFireandTheft')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM VEHICLE

UNION ALL

-- ── 3. BodyType (OPTIONAL — from RedBook) ───────────────────────────────────
SELECT
    LEGACYPOLICYNUMBER, REGISTRATIONNUMBER,
    'BodyType',
    SRC_BODYTYPE,
    DCT_BODYTYPE,
    '["B-double","Bus","BusChassis","CabChassis","Cabriolet","Compactor","Convertible","Coupe","Distributor","Dump","ExtraHeavyDuty","Fastback","Hardtop","Hatchback","HeavyDuty","Highway","Liftback","Limousine","Mixer","PrimeMover","Rigid","RoadTrain","Roadster","Sedan","Softtop","StreetSweeper","Targa","Tipper","Trailer","Traytop","Utility","Van","VanWagon","Wagon"]',
    CASE
        WHEN TRIM(COALESCE(SRC_BODYTYPE,'')) = '' THEN 'N/A'
        WHEN DCT_BODYTYPE IN ('B-double','Bus','BusChassis','CabChassis','Cabriolet','Compactor',
                              'Convertible','Coupe','Distributor','Dump','ExtraHeavyDuty','Fastback',
                              'Hardtop','Hatchback','HeavyDuty','Highway','Liftback','Limousine',
                              'Mixer','PrimeMover','Rigid','RoadTrain','Roadster','Sedan','Softtop',
                              'StreetSweeper','Targa','Tipper','Trailer','Traytop','Utility',
                              'Van','VanWagon','Wagon')
             THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC_BODYTYPE,'')) = ''
             THEN 'Blank — optional field, omitted from XML (OK)'
        WHEN DCT_BODYTYPE IN ('B-double','Bus','BusChassis','CabChassis','Cabriolet','Compactor',
                              'Convertible','Coupe','Distributor','Dump','ExtraHeavyDuty','Fastback',
                              'Hardtop','Hatchback','HeavyDuty','Highway','Liftback','Limousine',
                              'Mixer','PrimeMover','Rigid','RoadTrain','Roadster','Sedan','Softtop',
                              'StreetSweeper','Targa','Tipper','Trailer','Traytop','Utility',
                              'Van','VanWagon','Wagon')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM VEHICLE

UNION ALL

-- ── 4. InductionType (OPTIONAL — from RedBook) ──────────────────────────────
SELECT
    LEGACYPOLICYNUMBER, REGISTRATIONNUMBER,
    'InductionType',
    SRC_INDUCTIONTYPE,
    DCT_INDUCTIONTYPE,
    '["Aspirated","Supercharged","Turbocharged","TurboandSupercharged"]',
    CASE
        WHEN TRIM(COALESCE(SRC_INDUCTIONTYPE,'')) = '' THEN 'N/A'
        WHEN DCT_INDUCTIONTYPE IN ('Aspirated','Supercharged','Turbocharged','TurboandSupercharged')
             THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC_INDUCTIONTYPE,'')) = ''
             THEN 'Blank — optional field, omitted from XML (OK)'
        WHEN DCT_INDUCTIONTYPE IN ('Aspirated','Supercharged','Turbocharged','TurboandSupercharged')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM VEHICLE;