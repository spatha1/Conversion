-- ══════════════════════════════════════════════════════════════════════════
-- PP_FieldVal_Template_VehicleType.sql
-- TEMPLATE — one field, replicate + UNION ALL for all fields
--
-- Approach:
--   SOURCE_RAW_VALUE  = from raw source table (PM_03 / Locationdetails_PER)
--   MAPPED_DCT_CODE   = from the deployed DEV view (already has CASE logic)
--   STATUS            = check mapped value against DCT valid list
--
-- No CASE duplication — view is the single source of truth for mapping.
-- If the view is updated, validation picks up the change automatically.
--
-- ConversionScript RHS: <VehicleType>{VEHICLETYPE}</VehicleType>  (~line 608)
-- DCT manuscript      : line 2379-2393
-- ══════════════════════════════════════════════════════════════════════════

WITH

SCOPE AS (
    SELECT DISTINCT
        CAST(TRIM(PM.PUREPOLICYNUMBER) ||'|'|| TRIM(PM.CMLNUMBER) ||'|'|| TRIM(PM.EXPIRINGID_P) AS VARCHAR) AS POLICY_KEY
    FROM AGGNE.DEV.PM_03 PM
    JOIN AGGNE.DEV.SAMPLE_PER SP ON TRIM(PM.PUREPOLICYNUMBER) = TRIM(SP.PUREPOLICYNUMBER)
    WHERE PM.EXPIRYDATE >= '2026-01-01'
      AND PM.YEAR        <> 0
      AND TRIM(PM.MAKE)  <> ''
      AND TRIM(PM.MODEL) <> ''
),

SRC AS (
    SELECT
        S.POLICY_KEY,
        COALESCE(TRIM(PM.VEHICLETYPE), '') AS SOURCE_RAW_VALUE,  -- raw, from PM_03
        COALESCE(V.VEHICLETYPE,         '') AS MAPPED_DCT_CODE   -- mapped, from view
    FROM AGGNE.DEV.PM_03 PM
    JOIN SCOPE S
        ON CAST(TRIM(PM.PUREPOLICYNUMBER) ||'|'|| TRIM(PM.CMLNUMBER) ||'|'|| TRIM(PM.EXPIRINGID_P) AS VARCHAR) = S.POLICY_KEY
    JOIN AGGNE.DEV.PER_COM_PAYLOAD V
        ON S.POLICY_KEY = V.PUREPOLICYNUMBER
)

SELECT
    POLICY_KEY    AS PUREPOLICYNUMBER,
    'VehicleType' AS XML_PATH,
    'PassengerVehicle,CamperVan,Caravan,Forklift,Motorcycle,MobileEquipment,TowTruck,Tractor,Trailer,Transporter,HeavyVehicle,LightCommercial,HeavyCommercial'
                  AS DCT_VALID_VALUES,
    SOURCE_RAW_VALUE,
    MAPPED_DCT_CODE,
    CASE
        WHEN MAPPED_DCT_CODE IN (
            'PassengerVehicle','CamperVan','Caravan','Forklift','Motorcycle',
            'MobileEquipment','TowTruck','Tractor','Trailer','Transporter',
            'HeavyVehicle','LightCommercial','HeavyCommercial'
        ) THEN 'PASS'
        WHEN MAPPED_DCT_CODE = '' THEN 'FAIL — blank after mapping'
        ELSE                           'FAIL — not a valid DCT code'
    END           AS STATUS

FROM SRC
ORDER BY STATUS, SOURCE_RAW_VALUE
;
