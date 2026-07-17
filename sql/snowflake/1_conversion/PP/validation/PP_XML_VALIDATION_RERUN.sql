-- ============================================================
-- PP XML Validation — RERUN Script
-- Safe to execute repeatedly at any time.
-- Assumes tables already exist (run SETUP.sql once first).
--
-- What this does:
--   1. Refreshes all v1.0 rules (delete + re-insert)
--   2. Re-creates the stored procedure (CREATE OR REPLACE)
--
-- After running this, call the SP:
--   CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, NULL);
-- ============================================================

-- ── Step 1: Refresh rules (v1.0) ─────────────────────────────────────────────

DELETE FROM AGGNE.DEV.PP_XML_VALIDATION_RULES
WHERE RULE_VERSION = '1.0';

-- Building — enum fields
INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT ver, field_name, xml_tag, payload_type, is_required, PARSE_JSON(valid_json), notes
FROM (
    SELECT '1.0' AS ver, 'RoofConstruction'     AS field_name, 'RoofConstruction'     AS xml_tag,
           'RISK_Building' AS payload_type, TRUE AS is_required,
           '["Asbestos","Colourbond","Concrete","IronSteelTin","Tile","Wood"]' AS valid_json,
           'PL101 required. Source: LOCATIONDETAILS_PER.ROOFCONSTRUCTION. 991 policies (23.6%) blank source.' AS notes
    UNION ALL
    SELECT '1.0', 'MainWallConstruction', 'MainWallConstruction', 'RISK_Building', TRUE,
           '["Asbestos","BrickVeneer","Concrete","DoubleBrick","FibroHardiplank","IronSteel","Wood"]',
           'PL101 required. Source: LOCATIONDETAILS_PER.MAINWALLCONSTRUCTION. Steel and Some Asbestos and Brick not in PL101.'
    UNION ALL
    SELECT '1.0', 'FloorConstruction', 'FloorConstruction', 'RISK_Building', TRUE,
           '["Concrete","Other","WoodConcretefootings","WoodStilts","WoodStumps"]',
           'PL101 required. Source: LOCATIONDETAILS_PER.FLOORCONSTRUCTION.'
    UNION ALL
    SELECT '1.0', 'HomeBuildingOccupied', 'HomeBuildingOccupied', 'RISK_Building', FALSE,
           '["HolidayHome","OwnedLeasedtoOthersShortTermRental","OwnedleasedtoOthersLongTermLease","OwnerOccupied","TenantedbyMember"]',
           'Optional in PL101. Source: LOCATIONDETAILS_PER.HOWOCCUPPIED.'
    UNION ALL
    SELECT '1.0', 'AlarmSystem', 'WhatTypeOfAlarmSystemIsInstalled', 'RISK_Building', FALSE,
           '["LocalAudibleOnly","MonitoredBacktobase","MonitoredSecurity","MonitoredToMobilePhone","None"]',
           'Source: LOCATIONDETAILS_PER.ALARMSYSTEMINSTALLED. Local-Monitored and Mobile Mechanic not in PL101.'
    UNION ALL
    SELECT '1.0', 'Deadlocks', 'AreDeadlocksInstalledOnAllExternalDoors', 'RISK_Building', FALSE,
           '["AllDoors","None","SomeDoors"]',
           'Source: LOCATIONDETAILS_PER.DEADLOCKSINSTALLED. Other has no PL101 equivalent.'
    UNION ALL
    SELECT '1.0', 'Grills', 'BarsOrGrillsInstalledOnAllWindows', 'RISK_Building', FALSE,
           '["AllWindows","None","SomeWindows"]',
           'Source: LOCATIONDETAILS_PER.GRILLKEYLOCKINSTALLED. Other has no PL101 equivalent.'
);

-- Building — free-text / numeric (NULL = no enum restriction)
INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT '1.0', field_name, xml_tag, 'RISK_Building', FALSE, NULL, notes
FROM (
    SELECT 'YearBuilt'       AS field_name, 'YearBuilt'       AS xml_tag, '4-digit year. Source: LOCATIONDETAILS_PER.YEARBUILT.'  AS notes
    UNION ALL
    SELECT 'NumberOfStoreys',               'NumberOfStoreys',             'Numeric. Source: LOCATIONDETAILS_PER.'
);

-- Motor — enum fields
INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT ver, field_name, xml_tag, payload_type, is_required, PARSE_JSON(valid_json), notes
FROM (
    SELECT '1.0' AS ver, 'ProtectionType' AS field_name, 'ProtectionType' AS xml_tag,
           'RISK_Building_PM' AS payload_type, FALSE AS is_required,
           '["Comprehensive","ComprehensiveAgreedValue","ComprehensiveMarket","FireandTheft","ThirdPartyFireandTheft","ThirdPartyOnly"]' AS valid_json,
           'Source: PM_03.PROTECTIONTYPE. BUG FIXED: FullComprehensive -> Comprehensive.' AS notes
    UNION ALL
    SELECT '1.0', 'VehicleType', 'VehicleType', 'RISK_Building_PM', FALSE,
           '["CamperVan","Caravan","Forklift","HeavyCommercial","HeavyVehicle","LightCommercial","MobileEquipment","Motorcycle","PassengerVehicle","Tractor","Trailer","Transporter","TowTruck"]',
           'Source: PM_03.VEHICLETYPE. 32 blank -> defaulted to PassengerVehicle (client to confirm).'
    UNION ALL
    SELECT '1.0', 'VehicleInfoOverride', 'VehicleInfoOverride', 'RISK_Building_PM', FALSE,
           '["0","1"]',
           'BUG FIXED: decimal 0.00000/1.00000 -> string 0/1 via MVRBVEHICLEKEY check.'
);

-- Motor — free-text fields (NULL = no enum restriction)
INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT '1.0', field_name, xml_tag, 'RISK_Building_PM', FALSE, NULL, notes
FROM (
    SELECT 'Make'        AS field_name, 'Make'        AS xml_tag, 'Free text. Source: PM_03.MAKE (INITCAP).'           AS notes
    UNION ALL
    SELECT 'Model',                     'Model',                  'Free text. Source: PM_03.MODEL (INITCAP).'
    UNION ALL
    SELECT 'Year',                      'Year',                   '4-digit year. Source: PM_03.YEAR.'
    UNION ALL
    SELECT 'BodyType',                  'BodyType',               'Free text. Dev added 34-type CASE mapping.'
    UNION ALL
    SELECT 'RedbookCode',               'RedbookCode',            'Source: PM_03.MVRBVEHICLEKEY.'
);

-- ── Step 1b: Deactivate rules whose XML_TAG is too generic for regex ─────────
-- The 'Type' tag appears many times in the payload XML (product line, clause line,
-- coverage type, etc.). REGEXP_SUBSTR always picks the first match — PPAU/PPNZ —
-- not the clause-level value. Deactivate until section-scoped extraction is added.
UPDATE AGGNE.DEV.PP_XML_VALIDATION_RULES
SET    ACTIVE = FALSE
WHERE  FIELD_NAME IN (
           'BuildingRiskClausesType',
           'HomeContentsClausesType',
           'CommercialVehicleClausesType'
       )
  AND  RULE_VERSION = '1.1';

-- ── Step 2: Recreate stored procedure ────────────────────────────────────────

CREATE OR REPLACE PROCEDURE AGGNE.DEV.SP_PP_XML_VALIDATE(
    P_RULE_VERSION  VARCHAR,
    P_PAYLOAD_TYPE  VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_run_id     VARCHAR;
    v_run_ts     TIMESTAMP_NTZ;
    v_pol_count  INT DEFAULT 0;
    v_issue_cnt  INT DEFAULT 0;

BEGIN
    v_run_ts := CURRENT_TIMESTAMP();
    v_run_id  := TO_CHAR(v_run_ts, 'YYYYMMDD_HH24MI') || '_PP';

    SELECT COUNT(*) INTO v_pol_count
    FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT;

    IF (v_pol_count = 0) THEN
        RETURN 'ERROR: PER_POLICY_MIGRATION_DCT is empty — run the full ETL pipeline first.';
    END IF;

    INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_REPORT
        (RUN_ID, RUN_TS, POLICY_ID, LEGACY_POLICY_NO, PAYLOAD_TYPE,
         FIELD_NAME, XML_TAG, EXTRACTED_VALUE, ISSUE_TYPE,
         VALID_VALUES_REF, RULE_VERSION, NOTES)

    WITH policies AS (
        SELECT LEGACYPOLICYNUMBER                       AS LEGACY_POLICY_NO,
               LEGACYPOLICYNUMBER || '|' || CML_NUMBER  AS POLICY_ID,
               REQUEST_XML
        FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
    ),
    active_rules AS (
        SELECT RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE,
               IS_REQUIRED, VALID_VALUES::VARCHAR AS VALID_VALUES_STR, NOTES
        FROM   AGGNE.DEV.PP_XML_VALIDATION_RULES
        WHERE  ACTIVE = TRUE
          AND  (:P_RULE_VERSION IS NULL OR RULE_VERSION = :P_RULE_VERSION)
          AND  (:P_PAYLOAD_TYPE IS NULL OR PAYLOAD_TYPE = :P_PAYLOAD_TYPE)
    ),
    extracted AS (
        SELECT
            p.POLICY_ID,
            p.LEGACY_POLICY_NO,
            r.PAYLOAD_TYPE,
            r.FIELD_NAME,
            r.XML_TAG,
            r.IS_REQUIRED,
            r.VALID_VALUES_STR,
            r.RULE_VERSION,
            r.NOTES AS RULE_NOTES,
            CASE
                -- XPath-style tags (contain / or [) cannot be matched by simple
                -- regex — mark as XPATH_SKIP to suppress all checks for these rules.
                WHEN r.XML_TAG LIKE '%/%' OR r.XML_TAG LIKE '%[%'
                THEN 'XPATH_SKIP'
                WHEN REGEXP_INSTR(p.REQUEST_XML, '<' || r.XML_TAG || '[^>]*>') > 0
                THEN 'PRESENT'
                ELSE 'ABSENT'
            END AS TAG_PRESENCE,
            CASE
                WHEN r.XML_TAG LIKE '%/%' OR r.XML_TAG LIKE '%[%'
                THEN NULL   -- XPath-style: cannot extract with simple regex
                ELSE NULLIF(
                        REGEXP_SUBSTR(p.REQUEST_XML,
                            '<' || r.XML_TAG || '>([^<]*)</' || r.XML_TAG || '>',
                            1, 1, 'e', 1),
                        '')
            END AS EXTRACTED_VALUE
        FROM policies p
        CROSS JOIN active_rules r
    ),
    issues AS (
        SELECT
            POLICY_ID, LEGACY_POLICY_NO, PAYLOAD_TYPE,
            FIELD_NAME, XML_TAG, EXTRACTED_VALUE,
            CASE
                WHEN TAG_PRESENCE = 'ABSENT'  AND IS_REQUIRED = TRUE
                    THEN 'MISSING_TAG'
                WHEN TAG_PRESENCE = 'PRESENT' AND EXTRACTED_VALUE IS NULL AND IS_REQUIRED = TRUE
                    THEN 'BLANK_REQUIRED'
                WHEN TAG_PRESENCE = 'PRESENT' AND EXTRACTED_VALUE IS NOT NULL
                     AND VALID_VALUES_STR IS NOT NULL
                     AND NOT ARRAY_CONTAINS(
                             EXTRACTED_VALUE::VARIANT,
                             PARSE_JSON(VALID_VALUES_STR))
                    THEN 'INVALID_CODE'
                ELSE NULL
            END AS ISSUE_TYPE,
            VALID_VALUES_STR AS VALID_VALUES_REF,
            RULE_VERSION, RULE_NOTES
        FROM extracted
        WHERE (TAG_PRESENCE = 'ABSENT'  AND IS_REQUIRED = TRUE)
           OR (TAG_PRESENCE = 'PRESENT' AND EXTRACTED_VALUE IS NULL AND IS_REQUIRED = TRUE)
           OR (TAG_PRESENCE = 'PRESENT' AND EXTRACTED_VALUE IS NOT NULL
               AND VALID_VALUES_STR IS NOT NULL
               AND NOT ARRAY_CONTAINS(
                       EXTRACTED_VALUE::VARIANT,
                       PARSE_JSON(VALID_VALUES_STR)))
    )
    SELECT :v_run_id, :v_run_ts,
           POLICY_ID, LEGACY_POLICY_NO, PAYLOAD_TYPE,
           FIELD_NAME, XML_TAG, EXTRACTED_VALUE, ISSUE_TYPE,
           VALID_VALUES_REF, RULE_VERSION, RULE_NOTES
    FROM issues
    WHERE ISSUE_TYPE IS NOT NULL;

    v_issue_cnt := SQLROWCOUNT;

    RETURN
        'Run: '                  || :v_run_id
        || ' | Policies: '       || :v_pol_count::VARCHAR
        || ' | Issues found: '   || :v_issue_cnt::VARCHAR
        || ' | View: SELECT * FROM AGGNE.DEV.PP_XML_VALIDATION_SUMMARY WHERE RUN_ID = ''' || :v_run_id || ''';';

END;
$$;

-- ── Step 3: After ETL run, call the SP ───────────────────────────────────────
-- CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, NULL);

-- ── Check rules loaded ────────────────────────────────────────────────────────
SELECT PAYLOAD_TYPE, FIELD_NAME, IS_REQUIRED,
       ARRAY_SIZE(VALID_VALUES) AS OPTION_COUNT
FROM   AGGNE.DEV.PP_XML_VALIDATION_RULES
WHERE  ACTIVE = TRUE
ORDER  BY PAYLOAD_TYPE, FIELD_NAME;
