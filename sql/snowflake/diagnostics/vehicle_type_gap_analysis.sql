-- ============================================================
-- Vehicle Field Gap Analysis — PM_03 source vs DCT camelCase
-- Run in Snowflake (READ-ONLY) to confirm VEHICLETYPE source values
-- and identify any unmapped values hitting the ELSE passthrough.
-- ============================================================

-- STEP 1: All distinct VEHICLETYPE values in source + what we map them to
SELECT
    VEHICLETYPE                                         AS SOURCE_VEHICLETYPE,
    CASE
        WHEN VEHICLETYPE = 'Passenger Vehicle'  THEN 'PassengerVehicle'
        WHEN VEHICLETYPE = 'Light Commercial'   THEN 'LightCommercial'
        WHEN VEHICLETYPE = 'Heavy Commercial'   THEN 'HeavyCommercial'
        WHEN VEHICLETYPE = 'Motorcycle'         THEN 'Motorcycle'
        WHEN VEHICLETYPE = 'Trailer'            THEN 'Trailer'
        WHEN VEHICLETYPE = 'Camper Van'         THEN 'CamperVan'
        WHEN VEHICLETYPE = 'Caravan'            THEN 'Caravan'
        WHEN VEHICLETYPE = 'Forklift'           THEN 'Forklift'
        WHEN VEHICLETYPE = 'Mobile Equipment'   THEN 'MobileEquipment'
        WHEN VEHICLETYPE = 'Tow Truck'          THEN 'TowTruck'
        WHEN VEHICLETYPE = 'Tractor'            THEN 'Tractor'
        WHEN VEHICLETYPE = 'Transporter'        THEN 'Transporter'
        WHEN VEHICLETYPE = 'Heavy Vehicle'      THEN 'HeavyVehicle'
        ELSE '*** UNMAPPED — hits ELSE passthrough ***'
    END                                                 AS DCT_VEHICLETYPE,
    COUNT(*)                                            AS POLICY_ROWS
FROM AGGNE.DEV.PM_03
WHERE EXPIRYDATE >= '2026-01-01'
GROUP BY VEHICLETYPE
ORDER BY POLICY_ROWS DESC;

-- STEP 2: PROTECTIONTYPE gap check
SELECT
    PROTECTIONTYPE                                      AS SOURCE_PROTECTIONTYPE,
    CASE
        WHEN PROTECTIONTYPE = 'Comprehensive - Market Value'    THEN 'ComprehensiveMarket'
        WHEN PROTECTIONTYPE = 'Comprehensive - Agreed Value'    THEN 'ComprehensiveAgreedValue'
        WHEN PROTECTIONTYPE = 'Fire and Theft'                  THEN 'FireandTheft'
        WHEN PROTECTIONTYPE = 'Comprehensive'                   THEN 'Comprehensive'
        WHEN PROTECTIONTYPE = 'Third Party Only'                THEN 'ThirdPartyOnly'
        WHEN PROTECTIONTYPE = 'Third Party, Fire and Theft'     THEN 'ThirdPartyFireandTheft'
        ELSE '*** UNMAPPED ***'
    END                                                 AS DCT_PROTECTIONTYPE,
    COUNT(*)                                            AS POLICY_ROWS
FROM AGGNE.DEV.PM_03
WHERE EXPIRYDATE >= '2026-01-01'
GROUP BY PROTECTIONTYPE
ORDER BY POLICY_ROWS DESC;

-- STEP 3: BODYTYPE values (free-text / RedBook — no enum mapping, just check for blanks)
SELECT
    COALESCE(NULLIF(TRIM(BODYTYPE), ''), '(blank)') AS BODYTYPE,
    COUNT(*)                                          AS POLICY_ROWS
FROM AGGNE.DEV.PM_03
WHERE EXPIRYDATE >= '2026-01-01'
GROUP BY BODYTYPE
ORDER BY POLICY_ROWS DESC;

-- STEP 4: OVERRIDE current source value distribution
SELECT
    OVERRIDE,
    COUNT(*) AS POLICY_ROWS
FROM AGGNE.DEV.PM_03
WHERE EXPIRYDATE >= '2026-01-01'
GROUP BY OVERRIDE
ORDER BY POLICY_ROWS DESC;
