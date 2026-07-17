-- ============================================================
-- BP Dropdown Field Validation Views
-- Module: BP (Business Protection)
--
-- Creates 4 views in deploy order (sub-views before ALL):
--   1. BP_DROPDOWN_BUILDING_VALIDATION  — Building risk (BB/BC/BG/BI/EN/MY)
--   2. BP_DROPDOWN_CM_VALIDATION        — CM Commercial Vehicle (vehicle-level)
--   3. BP_DROPDOWN_FL_VALIDATION        — FL Fleet Vehicle (policy-level)
--   4. BP_DROPDOWN_ALL_VALIDATION       — Combined union of the above
--
-- Design:
--   XML_VALUE is read directly from the existing DEV views (*_FINAL columns /
--   mapped output columns) — no CASE logic duplicated here. Fix the underlying
--   view; this validation automatically reflects the corrected output.
--   SOURCE_VALUE is the raw Pure value from the source table for side-by-side.
--
-- Usage after deploy:
--   -- Summary (grouped — for client sign-off):
--   SELECT COVERAGE_AREA, FIELD, SOURCE_VALUE, XML_VALUE, IS_IN_DCT_LIST,
--          COUNT(DISTINCT LEGACYPOLICYNUMBER) AS POLICY_COUNT, COMMENT
--   FROM   AGGNE.DEV.BP_DROPDOWN_ALL_VALIDATION
--   GROUP  BY COVERAGE_AREA, FIELD, SOURCE_VALUE, XML_VALUE, IS_IN_DCT_LIST, COMMENT
--   ORDER  BY COVERAGE_AREA, FIELD, IS_IN_DCT_LIST, POLICY_COUNT DESC;
--
--   -- Gaps only:
--   SELECT COVERAGE_AREA, FIELD, SOURCE_VALUE, XML_VALUE,
--          COUNT(DISTINCT LEGACYPOLICYNUMBER) AS POLICY_COUNT, COMMENT
--   FROM   AGGNE.DEV.BP_DROPDOWN_ALL_VALIDATION
--   WHERE  IS_IN_DCT_LIST = 'No'
--   GROUP  BY COVERAGE_AREA, FIELD, SOURCE_VALUE, XML_VALUE, COMMENT
--   ORDER  BY COVERAGE_AREA, FIELD, POLICY_COUNT DESC;
-- ============================================================


-- ============================================================
-- 1. BP_DROPDOWN_BUILDING_VALIDATION
--    Source views : AGGNE.DEV.RISK_BUILDING_FINAL  (VW — mapped *_FINAL cols)
--    Source table : AGGNE.DEV.LOCATION_01          (SRC — raw Pure values)
--    Fields: RoofConstruction, MainWallConstruction, FloorConstruction,
--            AlarmSystemInstalled, DeadlocksInstalled, BarsOrGrillsInstalled
-- ============================================================

CREATE OR REPLACE VIEW AGGNE.DEV.BP_DROPDOWN_BUILDING_VALIDATION (
    LEGACYPOLICYNUMBER,
    FIELD,
    SOURCE_VALUE,
    XML_VALUE,
    DCT_VALUES,
    IS_IN_DCT_LIST,
    COMMENT
) AS

WITH SRC AS (
    SELECT
        CAST(TRIM(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID) AS VARCHAR) AS COMPOSITE_KEY,
        TRIM(ADDRESSDESCRIPTION) AS ADDRESSDESCRIPTION,
        ROOFCONSTRUCTION,
        MAINWALLCONSTRUCTION,
        FLOORCONSTRUCTION,
        ALARMSYSTEMINSTALLED,
        DEADLOCKSINSTALLED,
        BARSORGRILLSINSTALLED
    FROM AGGNE.DEV.LOCATION_01
    WHERE LOCATIONANZSICCODE NOT LIKE '%222222%'
)

-- ── 1. RoofConstruction (REQUIRED) ──────────────────────────────────────────
SELECT
    VW.LEGACYPOLICYNUMBER,
    'RoofConstruction'                                                        AS FIELD,
    SRC.ROOFCONSTRUCTION                                                      AS SOURCE_VALUE,
    VW.ROOFCONSTRUCTION_FINAL                                                 AS XML_VALUE,
    '["Asbestos","Colourbond","Concrete","IronSteelTin","Tile","Wood"]'       AS DCT_VALUES,
    CASE WHEN VW.ROOFCONSTRUCTION_FINAL
              IN ('Asbestos','Colourbond','Concrete','IronSteelTin','Tile','Wood')
         THEN 'Yes' ELSE 'No' END                                             AS IS_IN_DCT_LIST,
    CASE
        WHEN TRIM(COALESCE(SRC.ROOFCONSTRUCTION,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.ROOFCONSTRUCTION_FINAL
             IN ('Asbestos','Colourbond','Concrete','IronSteelTin','Tile','Wood')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END                                                                       AS COMMENT
FROM AGGNE.DEV.RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 2. MainWallConstruction (REQUIRED) ──────────────────────────────────────
SELECT
    VW.LEGACYPOLICYNUMBER,
    'MainWallConstruction',
    SRC.MAINWALLCONSTRUCTION,
    VW.MAINWALLCONSTRUCTION_FINAL,
    '["Asbestos","BrickVeneer","Concrete","DoubleBrick","FibroHardiplank","IronSteel","Wood"]',
    CASE WHEN VW.MAINWALLCONSTRUCTION_FINAL
              IN ('Asbestos','BrickVeneer','Concrete','DoubleBrick','FibroHardiplank','IronSteel','Wood')
         THEN 'Yes' ELSE 'No' END,
    CASE
        WHEN TRIM(COALESCE(SRC.MAINWALLCONSTRUCTION,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.MAINWALLCONSTRUCTION_FINAL
             IN ('Asbestos','BrickVeneer','Concrete','DoubleBrick','FibroHardiplank','IronSteel','Wood')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 3. FloorConstruction (REQUIRED) ─────────────────────────────────────────
SELECT
    VW.LEGACYPOLICYNUMBER,
    'FloorConstruction',
    SRC.FLOORCONSTRUCTION,
    VW.FLOORCONSTRUCTION_FINAL,
    '["Concrete","Other","WoodConcretefootings","WoodStilts","WoodStumps"]',
    CASE
        WHEN TRIM(COALESCE(SRC.FLOORCONSTRUCTION,'')) = '' THEN 'N/A'
        WHEN VW.FLOORCONSTRUCTION_FINAL
             IN ('Concrete','Other','WoodConcretefootings','WoodStilts','WoodStumps')
             THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.FLOORCONSTRUCTION,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.FLOORCONSTRUCTION_FINAL
             IN ('Concrete','Other','WoodConcretefootings','WoodStilts','WoodStumps')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 4. AlarmSystemInstalled (OPTIONAL) ──────────────────────────────────────
SELECT
    VW.LEGACYPOLICYNUMBER,
    'AlarmSystemInstalled',
    SRC.ALARMSYSTEMINSTALLED,
    VW.ALARMSYSTEMINSTALLED_FINAL,
    '["LocalAudibleOnly","MonitoredBacktobase","MonitoredSecurity","MonitoredToMobilePhone","None"]',
    CASE
        WHEN TRIM(COALESCE(SRC.ALARMSYSTEMINSTALLED,'')) = '' THEN 'N/A'
        WHEN VW.ALARMSYSTEMINSTALLED_FINAL
             IN ('LocalAudibleOnly','MonitoredBacktobase','MonitoredSecurity','MonitoredToMobilePhone','None')
             THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.ALARMSYSTEMINSTALLED,'')) = ''
             THEN 'Blank — optional field, omitted from XML (OK)'
        WHEN VW.ALARMSYSTEMINSTALLED_FINAL
             IN ('LocalAudibleOnly','MonitoredBacktobase','MonitoredSecurity','MonitoredToMobilePhone','None')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 5. DeadlocksInstalled (OPTIONAL) ────────────────────────────────────────
-- Bug: view outputs 0/1 Boolean; DCT expects AllDoors|SomeDoors|None
SELECT
    VW.LEGACYPOLICYNUMBER,
    'DeadlocksInstalled',
    SRC.DEADLOCKSINSTALLED,
    VW.DEADLOCKSINSTALLED_FINAL,
    '["AllDoors","SomeDoors","None"]',
    CASE
        WHEN TRIM(COALESCE(SRC.DEADLOCKSINSTALLED,'')) = '' THEN 'N/A'
        WHEN VW.DEADLOCKSINSTALLED_FINAL IN ('AllDoors','SomeDoors','None') THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.DEADLOCKSINSTALLED,'')) = ''
             THEN 'Blank — optional field, omitted from XML (OK)'
        WHEN VW.DEADLOCKSINSTALLED_FINAL IN ('AllDoors','SomeDoors','None')
             THEN 'OK'
        ELSE 'Type mismatch — view outputs 0/1; DCT expects AllDoors|SomeDoors|None (Business to confirm rule for SomeDoors)'
    END
FROM AGGNE.DEV.RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 6. BarsOrGrillsInstalled (OPTIONAL) ─────────────────────────────────────
-- Bug: view outputs 0/1 Boolean; DCT expects AllWindows|SomeWindows|None
SELECT
    VW.LEGACYPOLICYNUMBER,
    'BarsOrGrillsInstalled',
    SRC.BARSORGRILLSINSTALLED,
    VW.BARSORGRILLSINSTALLED_FINAL,
    '["AllWindows","SomeWindows","None"]',
    CASE
        WHEN TRIM(COALESCE(SRC.BARSORGRILLSINSTALLED,'')) = '' THEN 'N/A'
        WHEN VW.BARSORGRILLSINSTALLED_FINAL IN ('AllWindows','SomeWindows','None') THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.BARSORGRILLSINSTALLED,'')) = ''
             THEN 'Blank — optional field, omitted from XML (OK)'
        WHEN VW.BARSORGRILLSINSTALLED_FINAL IN ('AllWindows','SomeWindows','None')
             THEN 'OK'
        ELSE 'Type mismatch — view outputs 0/1; DCT expects AllWindows|SomeWindows|None (Business to confirm rule for SomeWindows)'
    END
FROM AGGNE.DEV.RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION);


-- ============================================================
-- 2. BP_DROPDOWN_CM_VALIDATION
--    Source view  : AGGNE.DEV.CV_RISK_COV_FINAL_VIEW  (VW — mapped cols)
--    Source table : AGGNE.DEV.CM_03                   (SRC — raw Pure values)
--    Fields: ProtectionType, VehicleType, HighestRiskUse,
--            InductionType, HowOften
-- ============================================================

CREATE OR REPLACE VIEW AGGNE.DEV.BP_DROPDOWN_CM_VALIDATION (
    LEGACYPOLICYNUMBER,
    REGISTRATIONNUMBER,
    FIELD,
    SOURCE_VALUE,
    XML_VALUE,
    DCT_VALUES,
    IS_IN_DCT_LIST,
    COMMENT
) AS

WITH SRC AS (
    SELECT
        CAST(TRIM(PUREPOLICYNUMBER) || '|' || TRIM(CMLNUMBER) || '|' || TRIM(EXPIRINGID_P) || '|' || TRIM(VEHICLEID) AS VARCHAR) AS COMPOSITE_KEY,
        TRIM(PUREPOLICYNUMBER)   AS LEGACYPOLICYNUMBER,
        TRIM(REGISTRATIONNUMBER) AS REGISTRATIONNUMBER,
        PROTECTIONTYPE,
        HighestRiskUse,
        VEHICLETYPE,
        INDUCTIONTYPE,
        HOWOFTEN
    FROM AGGNE.DEV.CM_03
    WHERE EXPIRYDATE > '2026-01-01'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRIM(PUREPOLICYNUMBER), TRIM(VEHICLEID)
        ORDER BY EXPIRYDATE DESC
    ) = 1
)

-- ── 1. ProtectionType (REQUIRED) ────────────────────────────────────────────
SELECT
    SRC.LEGACYPOLICYNUMBER,
    SRC.REGISTRATIONNUMBER,
    'ProtectionType'                                                                                                             AS FIELD,
    SRC.PROTECTIONTYPE                                                                                                           AS SOURCE_VALUE,
    VW.PROTECTIONTYPE                                                                                                            AS XML_VALUE,
    '["ThirdPartyFireandTheft","ComprehensiveMarket","ComprehensiveAgreedValue","FireandTheft","ThirdPartyOnly"]'                AS DCT_VALUES,
    CASE
        WHEN TRIM(COALESCE(SRC.PROTECTIONTYPE,'')) = '' THEN 'N/A'
        WHEN VW.PROTECTIONTYPE IN ('ThirdPartyFireandTheft','ComprehensiveMarket',
                                   'ComprehensiveAgreedValue','FireandTheft','ThirdPartyOnly')
             THEN 'Yes'
        ELSE 'No'
    END                                                                                                                          AS IS_IN_DCT_LIST,
    CASE
        WHEN TRIM(COALESCE(SRC.PROTECTIONTYPE,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.PROTECTIONTYPE IN ('ThirdPartyFireandTheft','ComprehensiveMarket',
                                   'ComprehensiveAgreedValue','FireandTheft','ThirdPartyOnly')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END                                                                                                                          AS COMMENT
FROM AGGNE.DEV.CV_RISK_COV_FINAL_VIEW VW
JOIN SRC ON SRC.COMPOSITE_KEY = TRIM(VW.PUREPOLICYNUMBER)

UNION ALL

-- ── 2. VehicleType (REQUIRED) ───────────────────────────────────────────────
-- Bug: view has no ELSE clause → unknown types produce NULL (silent data loss)
SELECT
    SRC.LEGACYPOLICYNUMBER,
    SRC.REGISTRATIONNUMBER,
    'VehicleType',
    SRC.VEHICLETYPE,
    COALESCE(VW.VEHICLETYPE, ''),
    '["PassengerVehicle","CamperVan","Caravan","Forklift","Motorcycle","Trailer","LightCommercial","HeavyCommercial","MobileEquipment","TowTruck","Transporter","HeavyVehicle","Tractor"]',
    CASE
        WHEN TRIM(COALESCE(SRC.VEHICLETYPE,'')) = '' THEN 'N/A'
        WHEN COALESCE(VW.VEHICLETYPE,'') IN ('PassengerVehicle','CamperVan','Caravan','Forklift',
             'Motorcycle','Trailer','LightCommercial','HeavyCommercial','MobileEquipment',
             'TowTruck','Transporter','HeavyVehicle','Tractor')
             THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.VEHICLETYPE,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN COALESCE(VW.VEHICLETYPE,'') IN ('PassengerVehicle','CamperVan','Caravan','Forklift',
             'Motorcycle','Trailer','LightCommercial','HeavyCommercial','MobileEquipment',
             'TowTruck','Transporter','HeavyVehicle','Tractor')
             THEN 'OK'
        WHEN VW.VEHICLETYPE IS NULL AND TRIM(COALESCE(SRC.VEHICLETYPE,'')) <> ''
             THEN 'View ELSE clause missing — unknown source produces NULL (silent data loss); add ELSE '''' to view'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.CV_RISK_COV_FINAL_VIEW VW
JOIN SRC ON SRC.COMPOSITE_KEY = TRIM(VW.PUREPOLICYNUMBER)

UNION ALL

-- ── 3. HighestRiskUse (REQUIRED) ────────────────────────────────────────────
SELECT
    SRC.LEGACYPOLICYNUMBER,
    SRC.REGISTRATIONNUMBER,
    'HighestRiskUse',
    SRC.HighestRiskUse,
    VW.HIGHESTRISKUSE,
    '["Business","Delivery","Courtesy","Hire"]',
    CASE
        WHEN TRIM(COALESCE(SRC.HighestRiskUse,'')) = '' THEN 'N/A'
        WHEN VW.HIGHESTRISKUSE IN ('Business','Delivery','Courtesy','Hire') THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.HighestRiskUse,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.HIGHESTRISKUSE IN ('Business','Delivery','Courtesy','Hire')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value (verify full enum list in PL101)'
    END
FROM AGGNE.DEV.CV_RISK_COV_FINAL_VIEW VW
JOIN SRC ON SRC.COMPOSITE_KEY = TRIM(VW.PUREPOLICYNUMBER)

UNION ALL

-- ── 4. InductionType (OPTIONAL) ─────────────────────────────────────────────
SELECT
    SRC.LEGACYPOLICYNUMBER,
    SRC.REGISTRATIONNUMBER,
    'InductionType',
    SRC.INDUCTIONTYPE,
    VW.INDUCTIONTYPE,
    '["Aspirated","Supercharged","Turbocharged","TurboandSupercharged"]',
    CASE
        WHEN TRIM(COALESCE(SRC.INDUCTIONTYPE,'')) = '' THEN 'N/A'
        WHEN VW.INDUCTIONTYPE IN ('Aspirated','Supercharged','Turbocharged','TurboandSupercharged') THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.INDUCTIONTYPE,'')) = ''
             THEN 'Blank — optional field, omitted from XML (OK)'
        WHEN VW.INDUCTIONTYPE IN ('Aspirated','Supercharged','Turbocharged','TurboandSupercharged')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.CV_RISK_COV_FINAL_VIEW VW
JOIN SRC ON SRC.COMPOSITE_KEY = TRIM(VW.PUREPOLICYNUMBER)

UNION ALL

-- ── 5. HowOften (OPTIONAL) ──────────────────────────────────────────────────
SELECT
    SRC.LEGACYPOLICYNUMBER,
    SRC.REGISTRATIONNUMBER,
    'HowOften',
    SRC.HOWOFTEN,
    VW.HOWOFTEN,
    '["Daily","Weekly","LessFrequent"]',
    CASE
        WHEN TRIM(COALESCE(SRC.HOWOFTEN,'')) = '' THEN 'N/A'
        WHEN VW.HOWOFTEN IN ('Daily','Weekly','LessFrequent') THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.HOWOFTEN,'')) = ''
             THEN 'Blank — optional field, omitted from XML (OK)'
        WHEN VW.HOWOFTEN IN ('Daily','Weekly','LessFrequent')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.CV_RISK_COV_FINAL_VIEW VW
JOIN SRC ON SRC.COMPOSITE_KEY = TRIM(VW.PUREPOLICYNUMBER);


-- ============================================================
-- 3. BP_DROPDOWN_FL_VALIDATION
--    Source view  : AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW       (VW — mapped cols)
--    Source table : AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE  (SRC — raw Pure)
--    Fields: ProtectionType, HighestRiskUse
-- ============================================================

CREATE OR REPLACE VIEW AGGNE.DEV.BP_DROPDOWN_FL_VALIDATION (
    LEGACYPOLICYNUMBER,
    FIELD,
    SOURCE_VALUE,
    XML_VALUE,
    DCT_VALUES,
    IS_IN_DCT_LIST,
    COMMENT
) AS

WITH SRC AS (
    SELECT
        CAST(TRIM(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS COMPOSITE_KEY,
        TRIM(PUREPOLICYNUMBER) AS LEGACYPOLICYNUMBER,
        PROTECTIONTYPE,
        highestriskuse
    FROM AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY TRIM(PUREPOLICYNUMBER), TRIM(cmlnumber), TRIM(EXPIRINGID_P)
        ORDER BY 1
    ) = 1
)

-- ── 1. ProtectionType (REQUIRED) ────────────────────────────────────────────
-- Note: FLEET_VEHICLE_MAIN_VIEW ELSE passes raw source value for unknown types
SELECT
    SRC.LEGACYPOLICYNUMBER,
    'ProtectionType'                                                                      AS FIELD,
    SRC.PROTECTIONTYPE                                                                    AS SOURCE_VALUE,
    VW.PROTECTIONTYPE                                                                     AS XML_VALUE,
    '["ThirdPartyFireandTheft","Comprehensive","ThirdPartyOnly"]'                         AS DCT_VALUES,
    CASE
        WHEN TRIM(COALESCE(SRC.PROTECTIONTYPE,'')) = '' THEN 'N/A'
        WHEN VW.PROTECTIONTYPE IN ('ThirdPartyFireandTheft','Comprehensive','ThirdPartyOnly') THEN 'Yes'
        ELSE 'No'
    END                                                                                   AS IS_IN_DCT_LIST,
    CASE
        WHEN TRIM(COALESCE(SRC.PROTECTIONTYPE,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.PROTECTIONTYPE IN ('ThirdPartyFireandTheft','Comprehensive','ThirdPartyOnly')
             THEN 'OK'
        ELSE 'Unmapped — view ELSE passes raw value to DCT; add explicit mapping or ELSE '''' to view'
    END                                                                                   AS COMMENT
FROM AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW VW
JOIN SRC ON SRC.COMPOSITE_KEY = TRIM(VW.PUREPOLICYNUMBER)

UNION ALL

-- ── 2. HighestRiskUse (REQUIRED) ────────────────────────────────────────────
-- Bug: FLEET_VEHICLE_MAIN_VIEW has no CASE mapping — raw source value passes through
SELECT
    SRC.LEGACYPOLICYNUMBER,
    'HighestRiskUse',
    SRC.highestriskuse,
    VW.HIGHESTRISKUSE,
    '["Business","Delivery","Courtesy","Hire"]',
    CASE
        WHEN TRIM(COALESCE(SRC.highestriskuse,'')) = '' THEN 'N/A'
        WHEN VW.HIGHESTRISKUSE IN ('Business','Delivery','Courtesy','Hire') THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.highestriskuse,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.HIGHESTRISKUSE IN ('Business','Delivery','Courtesy','Hire')
             THEN 'OK'
        ELSE 'Not mapped — FLEET_VEHICLE_MAIN_VIEW passes raw source value; apply same CASE as CV_RISK_COV_FINAL_VIEW (General Business→Business etc.)'
    END
FROM AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW VW
JOIN SRC ON SRC.COMPOSITE_KEY = TRIM(VW.PUREPOLICYNUMBER);


-- ============================================================
-- 4. BP_DROPDOWN_ALL_VALIDATION  (deploy last — depends on views 1–3)
--    Combined union of Building + CM + FL validation views.
--    COVERAGE_AREA: 'Building' / 'CM' / 'FL'
--    VEHICLE_REF  : NULL for Building/FL; REGISTRATIONNUMBER for CM
-- ============================================================

CREATE OR REPLACE VIEW AGGNE.DEV.BP_DROPDOWN_ALL_VALIDATION (
    COVERAGE_AREA,
    LEGACYPOLICYNUMBER,
    VEHICLE_REF,
    FIELD,
    SOURCE_VALUE,
    XML_VALUE,
    DCT_VALUES,
    IS_IN_DCT_LIST,
    COMMENT
) AS

SELECT
    'Building'         AS COVERAGE_AREA,
    LEGACYPOLICYNUMBER,
    NULL               AS VEHICLE_REF,
    FIELD, SOURCE_VALUE, XML_VALUE, DCT_VALUES, IS_IN_DCT_LIST, COMMENT
FROM AGGNE.DEV.BP_DROPDOWN_BUILDING_VALIDATION

UNION ALL

SELECT
    'CM'               AS COVERAGE_AREA,
    LEGACYPOLICYNUMBER,
    REGISTRATIONNUMBER AS VEHICLE_REF,
    FIELD, SOURCE_VALUE, XML_VALUE, DCT_VALUES, IS_IN_DCT_LIST, COMMENT
FROM AGGNE.DEV.BP_DROPDOWN_CM_VALIDATION

UNION ALL

SELECT
    'FL'               AS COVERAGE_AREA,
    LEGACYPOLICYNUMBER,
    NULL               AS VEHICLE_REF,
    FIELD, SOURCE_VALUE, XML_VALUE, DCT_VALUES, IS_IN_DCT_LIST, COMMENT
FROM AGGNE.DEV.BP_DROPDOWN_FL_VALIDATION;
