-- ============================================================
-- PP XML Validation Framework — Setup Script
-- Schema  : AGGNE.DEV
-- Purpose : Creates the validation rules table, report table,
--           initial PL101 rules (v1.0), and the validation SP.
--
-- DEPLOY ORDER (run manually in Snowflake):
--   Step 1  SECTION 1 — create tables
--   Step 2  SECTION 2 — insert initial PL101 rules (v1.0)
--   Step 3  SECTION 3 — create/replace stored procedure
--   Step 4  After ETL batch completes, call the SP:
--             CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, NULL);
--           Or a specific rule version / payload type:
--             CALL AGGNE.DEV.SP_PP_XML_VALIDATE('1.0', 'RISK_Building');
--
-- Extending rules: add rows to PP_XML_VALIDATION_RULES
--   with a new RULE_VERSION (e.g. '1.1') and call the SP
--   with that version to run only the new rules.
--   Or set ACTIVE = FALSE on outdated rules without deleting them.
--
-- Source   : Carrier_PersonalProtectionBase_1_0_0_0.xml (PL101)
-- Created  : 2026-06-30
-- ============================================================

USE DATABASE CONVERSION;   -- adjust if your Snowflake DB differs
USE SCHEMA DEV;             -- adjust as needed

-- ============================================================
-- SECTION 1: TABLE DEFINITIONS
-- ============================================================

-- ── Validation rules table ─────────────────────────────────
--    Stores one row per (payload_type, field) rule.
--    VALID_VALUES is a JSON array e.g. '["Tile","Concrete"]'
--    If NULL → no enum restriction (field accepts any value).
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS AGGNE.DEV.PP_XML_VALIDATION_RULES (
    RULE_ID          INT                    AUTOINCREMENT PRIMARY KEY,
    RULE_VERSION     VARCHAR(20)            NOT NULL,          -- e.g. '1.0', '1.1'
    FIELD_NAME       VARCHAR(100)           NOT NULL,          -- logical name for reports
    XML_TAG          VARCHAR(200)           NOT NULL,          -- exact tag name in payload XML
    PAYLOAD_TYPE     VARCHAR(50)            NOT NULL,          -- 'RISK_Building' | 'RISK_Building_PM'
    IS_REQUIRED      BOOLEAN                NOT NULL DEFAULT FALSE,
    VALID_VALUES     VARIANT,                                  -- PARSE_JSON array or NULL
    NOTES            VARCHAR(1000),
    ACTIVE           BOOLEAN                NOT NULL DEFAULT TRUE,
    CREATED_BY       VARCHAR(100)           DEFAULT CURRENT_USER(),
    CREATED_AT       TIMESTAMP_NTZ          DEFAULT CURRENT_TIMESTAMP()
);

COMMENT ON TABLE  AGGNE.DEV.PP_XML_VALIDATION_RULES IS
    'PP XML payload validation rules — one row per field. Derived from PL101 (Carrier_PersonalProtectionBase_1_0_0_0.xml). Add new versions without deleting old rows.';
COMMENT ON COLUMN AGGNE.DEV.PP_XML_VALIDATION_RULES.VALID_VALUES IS
    'JSON array of valid DCT codes e.g. [\"Tile\",\"Concrete\"]. NULL = any value allowed (free-text field).';
COMMENT ON COLUMN AGGNE.DEV.PP_XML_VALIDATION_RULES.XML_TAG IS
    'Exact tag name used in REGEXP_SUBSTR extraction e.g. RoofConstruction or WhatTypeOfAlarmSystemIsInstalled.';

-- ── Validation report table ────────────────────────────────
--    Populated by SP_PP_XML_VALIDATE on each run.
--    Keeps full history — each run has a unique RUN_ID.
-- ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS AGGNE.DEV.PP_XML_VALIDATION_REPORT (
    REPORT_ID        INT                    AUTOINCREMENT PRIMARY KEY,
    RUN_ID           VARCHAR(50)            NOT NULL,          -- YYYYMMDD_HHMI or UUID
    RUN_TS           TIMESTAMP_NTZ          NOT NULL DEFAULT CURRENT_TIMESTAMP(),
    POLICY_ID        VARCHAR(500),                             -- composite ID from target table
    LEGACY_POLICY_NO VARCHAR(100),                            -- SPLIT_PART(ID,'|',1)
    PAYLOAD_TYPE     VARCHAR(50),                             -- 'RISK_Building' | 'RISK_Building_PM'
    FIELD_NAME       VARCHAR(100),
    XML_TAG          VARCHAR(200),
    EXTRACTED_VALUE  VARCHAR(500),                            -- actual value found in XML (or NULL)
    ISSUE_TYPE       VARCHAR(50),           -- 'BLANK_REQUIRED' | 'INVALID_CODE' | 'MISSING_TAG'
    VALID_VALUES_REF VARCHAR(2000),                          -- snapshot of valid values for reference
    RULE_VERSION     VARCHAR(20),
    NOTES            VARCHAR(1000)
);

COMMENT ON TABLE  AGGNE.DEV.PP_XML_VALIDATION_REPORT IS
    'PP XML validation results — populated by SP_PP_XML_VALIDATE. One row per policy+field issue. Full history retained by RUN_ID.';
COMMENT ON COLUMN AGGNE.DEV.PP_XML_VALIDATION_REPORT.ISSUE_TYPE IS
    'BLANK_REQUIRED = field is required in PL101 but blank/missing in payload | INVALID_CODE = value not in PL101 enum | MISSING_TAG = tag not found in XML';

-- ── Report summary view ────────────────────────────────────
CREATE OR REPLACE VIEW AGGNE.DEV.PP_XML_VALIDATION_SUMMARY AS
SELECT
    RUN_ID,
    RUN_TS,
    PAYLOAD_TYPE,
    FIELD_NAME,
    ISSUE_TYPE,
    RULE_VERSION,
    COUNT(DISTINCT POLICY_ID)  AS POLICIES_AFFECTED,
    COUNT(*)                   AS ISSUE_COUNT,
    LISTAGG(DISTINCT EXTRACTED_VALUE, ', ')
        WITHIN GROUP (ORDER BY EXTRACTED_VALUE)
                               AS DISTINCT_BAD_VALUES
FROM AGGNE.DEV.PP_XML_VALIDATION_REPORT
GROUP BY RUN_ID, RUN_TS, PAYLOAD_TYPE, FIELD_NAME, ISSUE_TYPE, RULE_VERSION
ORDER BY RUN_TS DESC, PAYLOAD_TYPE, ISSUE_TYPE, POLICIES_AFFECTED DESC;

COMMENT ON VIEW AGGNE.DEV.PP_XML_VALIDATION_SUMMARY IS
    'Aggregated view of PP XML validation results by run/field/issue type.';


-- ============================================================
-- SECTION 2: INITIAL RULES — PL101 v1.0
--            (derived from Carrier_PersonalProtectionBase_1_0_0_0.xml)
-- ============================================================

-- Clear existing v1.0 rules before re-inserting (safe to re-run)
DELETE FROM AGGNE.DEV.PP_XML_VALIDATION_RULES
WHERE RULE_VERSION = '1.0';

-- ── Building payload rules (ITR_TYPE = 'RISK_Building') ───────────────────────
-- Note: INSERT...SELECT syntax required — PARSE_JSON() is not allowed in VALUES clauses.
INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT ver, field_name, xml_tag, payload_type, is_required, PARSE_JSON(valid_json), notes
FROM (
    -- Required enum fields
    SELECT '1.0' AS ver, 'RoofConstruction'     AS field_name, 'RoofConstruction'     AS xml_tag,
           'RISK_Building' AS payload_type, TRUE AS is_required,
           '["Asbestos","Colourbond","Concrete","IronSteelTin","Tile","Wood"]' AS valid_json,
           'PL101 required. Source: LOCATIONDETAILS_PER.ROOFCONSTRUCTION. 991 policies (23.6%) have blank source — client decision needed.' AS notes
    UNION ALL
    SELECT '1.0', 'MainWallConstruction', 'MainWallConstruction', 'RISK_Building', TRUE,
           '["Asbestos","BrickVeneer","Concrete","DoubleBrick","FibroHardiplank","IronSteel","Wood"]',
           'PL101 required. Source: LOCATIONDETAILS_PER.MAINWALLCONSTRUCTION. Values Steel and Some Asbestos and Brick not in PL101 — client to map.'
    UNION ALL
    SELECT '1.0', 'FloorConstruction', 'FloorConstruction', 'RISK_Building', TRUE,
           '["Concrete","Other","WoodConcretefootings","WoodStilts","WoodStumps"]',
           'PL101 required. Source: LOCATIONDETAILS_PER.FLOORCONSTRUCTION.'
    -- Optional enum fields
    UNION ALL
    SELECT '1.0', 'HomeBuildingOccupied', 'HomeBuildingOccupied', 'RISK_Building', FALSE,
           '["HolidayHome","OwnedLeasedtoOthersShortTermRental","OwnedleasedtoOthersLongTermLease","OwnerOccupied","TenantedbyMember"]',
           'Optional in PL101 but important for landlord protection rules. Source: LOCATIONDETAILS_PER.HOWOCCUPPIED.'
    UNION ALL
    SELECT '1.0', 'AlarmSystem', 'WhatTypeOfAlarmSystemIsInstalled', 'RISK_Building', FALSE,
           '["LocalAudibleOnly","MonitoredBacktobase","MonitoredSecurity","MonitoredToMobilePhone","None"]',
           'Source: LOCATIONDETAILS_PER.ALARMSYSTEMINSTALLED. Local - Monitored and Mobile Mechanic - No base location not in PL101.'
    UNION ALL
    SELECT '1.0', 'Deadlocks', 'AreDeadlocksInstalledOnAllExternalDoors', 'RISK_Building', FALSE,
           '["AllDoors","None","SomeDoors"]',
           'Source: LOCATIONDETAILS_PER.DEADLOCKSINSTALLED. Other in source has no PL101 equivalent.'
    UNION ALL
    SELECT '1.0', 'Grills', 'BarsOrGrillsInstalledOnAllWindows', 'RISK_Building', FALSE,
           '["AllWindows","None","SomeWindows"]',
           'Source: LOCATIONDETAILS_PER.GRILLKEYLOCKINSTALLED. Other in source has no PL101 equivalent.'
);

-- Free-text / numeric fields — VALID_VALUES is NULL (no enum restriction).
-- Inserted separately because PARSE_JSON(NULL) must be handled as a literal NULL.
INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT '1.0', field_name, xml_tag, 'RISK_Building', FALSE, NULL, notes
FROM (
    SELECT 'YearBuilt'       AS field_name, 'YearBuilt'       AS xml_tag, '4-digit year. Source: LOCATIONDETAILS_PER.YEARBUILT. NULL = no enum check.'  AS notes
    UNION ALL
    SELECT 'NumberOfStoreys',               'NumberOfStoreys',             'Numeric. Source: LOCATIONDETAILS_PER. NULL = no enum check.'
);

-- ── Motor payload rules (ITR_TYPE = 'RISK_Building_PM') ──────────────────────
INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT ver, field_name, xml_tag, payload_type, is_required, PARSE_JSON(valid_json), notes
FROM (
    SELECT '1.0' AS ver, 'ProtectionType' AS field_name, 'ProtectionType' AS xml_tag,
           'RISK_Building_PM' AS payload_type, FALSE AS is_required,
           '["Comprehensive","ComprehensiveAgreedValue","ComprehensiveMarket","FireandTheft","ThirdPartyFireandTheft","ThirdPartyOnly"]' AS valid_json,
           'Source: PM_03.PROTECTIONTYPE. BUG FIXED in PER_COM_PAYLOAD: FullComprehensive -> Comprehensive.' AS notes
    UNION ALL
    SELECT '1.0', 'VehicleType', 'VehicleType', 'RISK_Building_PM', FALSE,
           '["CamperVan","Caravan","Forklift","HeavyCommercial","HeavyVehicle","LightCommercial","MobileEquipment","Motorcycle","PassengerVehicle","Tractor","Trailer","Transporter","TowTruck"]',
           'Source: PM_03.VEHICLETYPE. 32 blank -> defaulted to PassengerVehicle (client to confirm).'
    UNION ALL
    SELECT '1.0', 'VehicleInfoOverride', 'VehicleInfoOverride', 'RISK_Building_PM', FALSE,
           '["0","1"]',
           'BUG FIXED: Dev view returned 0.00000 / 1.00000 (decimal). Fixed to string 0 or 1 via MVRBVEHICLEKEY check.'
);

-- Motor free-text fields (NULL valid_values)
INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT '1.0', field_name, xml_tag, 'RISK_Building_PM', FALSE, NULL, notes
FROM (
    SELECT 'Make'        AS field_name, 'Make'        AS xml_tag, 'Free text. Source: PM_03.MAKE (INITCAP applied). NULL = no enum check.'                             AS notes
    UNION ALL
    SELECT 'Model',                     'Model',                  'Free text. Source: PM_03.MODEL (INITCAP applied). NULL = no enum check.'
    UNION ALL
    SELECT 'Year',                      'Year',                   '4-digit year. Source: PM_03.YEAR. NULL = no enum check.'
    UNION ALL
    SELECT 'BodyType',                  'BodyType',               'Free text from RedBook. Dev added 34-type CASE mapping. Unmapped -> blank. NULL = no enum check.'
    UNION ALL
    SELECT 'RedbookCode',               'RedbookCode',            'Source: PM_03.MVRBVEHICLEKEY. NULL = no enum check.'
);


-- ============================================================
-- SECTION 3: VALIDATION STORED PROCEDURE
-- ============================================================
--
-- SP_PP_XML_VALIDATE
--   Validates the final assembled XMLs in PER_POLICY_MIGRATION_DCT
--   against the active rules in PP_XML_VALIDATION_RULES.
--
--   Source table: AGGNE.DEV.PER_POLICY_MIGRATION_DCT
--     Columns: LEGACYPOLICYNUMBER, CML_NUMBER, REQUEST_XML
--     This table is always truncated + refilled each batch run,
--     so it always reflects the latest generation — no date filter needed.
--
--   Building fields (RoofConstruction, MainWall, Floor, etc.) and
--   Motor fields (VehicleType, ProtectionType, etc.) all live inside
--   the same REQUEST_XML for each policy.  One single CROSS JOIN pass
--   covers all rules regardless of PAYLOAD_TYPE.
--
-- Parameters:
--   P_RULE_VERSION  VARCHAR — rule version to apply e.g. '1.0'
--                             NULL = all active versions
--   P_PAYLOAD_TYPE  VARCHAR — 'RISK_Building' | 'RISK_Building_PM'
--                             NULL = all rules (building + motor)
--
-- Algorithm (set-based, single pass):
--   1. CROSS JOIN all active rules with all rows in PER_POLICY_MIGRATION_DCT
--   2. REGEXP_INSTR  → detect if tag is present in REQUEST_XML
--   3. REGEXP_SUBSTR → extract tag value from REQUEST_XML
--   4. Classify each (policy, rule) pair:
--        MISSING_TAG    — tag not found anywhere in the XML
--        BLANK_REQUIRED — tag present but empty, rule IS_REQUIRED = TRUE
--        INVALID_CODE   — value not in VALID_VALUES enum list
--   5. INSERT only issue rows into PP_XML_VALIDATION_REPORT
--   6. RETURN summary
--
-- Note: Optional fields that are blank are NOT flagged — only required
--       blank fields produce a BLANK_REQUIRED issue.
-- ──────────────────────────────────────────────────────────
CREATE OR REPLACE PROCEDURE AGGNE.DEV.SP_PP_XML_VALIDATE(
    P_RULE_VERSION  VARCHAR,   -- NULL = all active versions; '1.0' = specific version
    P_PAYLOAD_TYPE  VARCHAR    -- NULL = all; 'RISK_Building' or 'RISK_Building_PM'
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
    -- Unique run ID derived from timestamp
    v_run_ts := CURRENT_TIMESTAMP();
    v_run_id  := TO_CHAR(v_run_ts, 'YYYYMMDD_HH24MI') || '_PP';

    -- Abort early if the final XML table is empty
    SELECT COUNT(*) INTO v_pol_count
    FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT;

    IF (v_pol_count = 0) THEN
        RETURN 'ERROR: PER_POLICY_MIGRATION_DCT is empty — run the full ETL pipeline first (SP_PP_XML_VALIDATE requires the final XML assembly step to have completed).';
    END IF;

    -- ── Single-pass validation against PER_POLICY_MIGRATION_DCT ──────────
    INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_REPORT
        (RUN_ID, RUN_TS, POLICY_ID, LEGACY_POLICY_NO, PAYLOAD_TYPE,
         FIELD_NAME, XML_TAG, EXTRACTED_VALUE, ISSUE_TYPE,
         VALID_VALUES_REF, RULE_VERSION, NOTES)

    WITH policies AS (
        -- One row per policy — full DCT request XML
        SELECT LEGACYPOLICYNUMBER                           AS LEGACY_POLICY_NO,
               LEGACYPOLICYNUMBER || '|' || CML_NUMBER     AS POLICY_ID,
               REQUEST_XML
        FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
    ),
    active_rules AS (
        -- All active rules filtered by parameter
        SELECT RULE_VERSION,
               FIELD_NAME,
               XML_TAG,
               PAYLOAD_TYPE,
               IS_REQUIRED,
               VALID_VALUES::VARCHAR AS VALID_VALUES_STR,
               NOTES
        FROM   AGGNE.DEV.PP_XML_VALIDATION_RULES
        WHERE  ACTIVE = TRUE
          AND  (:P_RULE_VERSION IS NULL OR RULE_VERSION = :P_RULE_VERSION)
          AND  (:P_PAYLOAD_TYPE IS NULL OR PAYLOAD_TYPE = :P_PAYLOAD_TYPE)
    ),
    extracted AS (
        -- CROSS JOIN: every policy × every rule  (e.g. 4967 × 17 = ~84K rows)
        SELECT
            p.POLICY_ID,
            p.LEGACY_POLICY_NO,
            r.PAYLOAD_TYPE,
            r.FIELD_NAME,
            r.XML_TAG,
            r.IS_REQUIRED,
            r.VALID_VALUES_STR,
            r.RULE_VERSION,
            r.NOTES                  AS RULE_NOTES,
            -- XPath-style tags (contain / or [) cannot be matched by simple regex.
            -- Mark as XPATH_SKIP to suppress all checks — stored for documentation only.
            CASE
                WHEN r.XML_TAG LIKE '%/%' OR r.XML_TAG LIKE '%[%'
                THEN 'XPATH_SKIP'
                WHEN REGEXP_INSTR(p.REQUEST_XML, '<' || r.XML_TAG || '[^>]*>') > 0
                THEN 'PRESENT'
                ELSE 'ABSENT'
            END                      AS TAG_PRESENCE,
            CASE
                WHEN r.XML_TAG LIKE '%/%' OR r.XML_TAG LIKE '%[%'
                THEN NULL   -- XPath-style: cannot extract with simple regex
                ELSE NULLIF(
                        REGEXP_SUBSTR(p.REQUEST_XML,
                            '<' || r.XML_TAG || '>([^<]*)</' || r.XML_TAG || '>',
                            1, 1, 'e', 1),
                        '')
            END                      AS EXTRACTED_VALUE
        FROM policies p
        CROSS JOIN active_rules r
    ),
    issues AS (
        -- Classify only the rows that have a problem.
        -- TAG_PRESENCE = 'XPATH_SKIP' intentionally excluded from all three conditions.
        SELECT
            POLICY_ID,
            LEGACY_POLICY_NO,
            PAYLOAD_TYPE,
            FIELD_NAME,
            XML_TAG,
            EXTRACTED_VALUE,
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
                ELSE NULL   -- no issue — excluded by WHERE below
            END              AS ISSUE_TYPE,
            VALID_VALUES_STR AS VALID_VALUES_REF,
            RULE_VERSION,
            RULE_NOTES
        FROM extracted
        WHERE
            (TAG_PRESENCE = 'ABSENT'  AND IS_REQUIRED = TRUE)
            OR (TAG_PRESENCE = 'PRESENT' AND EXTRACTED_VALUE IS NULL AND IS_REQUIRED = TRUE)
            OR (TAG_PRESENCE = 'PRESENT' AND EXTRACTED_VALUE IS NOT NULL
                AND VALID_VALUES_STR IS NOT NULL
                AND NOT ARRAY_CONTAINS(
                        EXTRACTED_VALUE::VARIANT,
                        PARSE_JSON(VALID_VALUES_STR)))
    )
    SELECT
        :v_run_id,
        :v_run_ts,
        POLICY_ID,
        LEGACY_POLICY_NO,
        PAYLOAD_TYPE,
        FIELD_NAME,
        XML_TAG,
        EXTRACTED_VALUE,
        ISSUE_TYPE,
        VALID_VALUES_REF,
        RULE_VERSION,
        RULE_NOTES
    FROM issues
    WHERE ISSUE_TYPE IS NOT NULL;   -- safety net: exclude null-classified rows

    v_issue_cnt := SQLROWCOUNT;

    RETURN
        'Run: '           || :v_run_id
        || ' | Policies validated: ' || :v_pol_count::VARCHAR
        || ' | Rules applied: '      || (SELECT COUNT(*) FROM AGGNE.DEV.PP_XML_VALIDATION_RULES
                                          WHERE ACTIVE = TRUE
                                            AND (:P_RULE_VERSION IS NULL OR RULE_VERSION = :P_RULE_VERSION)
                                            AND (:P_PAYLOAD_TYPE IS NULL OR PAYLOAD_TYPE = :P_PAYLOAD_TYPE))::VARCHAR
        || ' | Total issues found: ' || :v_issue_cnt::VARCHAR
        || ' | View results: SELECT * FROM AGGNE.DEV.PP_XML_VALIDATION_SUMMARY WHERE RUN_ID = ''' || :v_run_id || ''';';

END;
$$;

COMMENT ON PROCEDURE AGGNE.DEV.SP_PP_XML_VALIDATE(VARCHAR, VARCHAR) IS
    'Validates the final assembled PP XMLs in PER_POLICY_MIGRATION_DCT against PL101 rules in PP_XML_VALIDATION_RULES. One pass — both building and motor fields validated from the same REQUEST_XML. Args: P_RULE_VERSION (NULL=all), P_PAYLOAD_TYPE (NULL=all). Results written to PP_XML_VALIDATION_REPORT.';


-- ============================================================
-- USAGE EXAMPLES
-- ============================================================

-- Run full validation after ETL pipeline completes:
--   CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, NULL);

-- Run only building rules:
--   CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, 'RISK_Building');

-- View summary of latest run (issues by field, sorted by impact):
--   SELECT * FROM AGGNE.DEV.PP_XML_VALIDATION_SUMMARY
--   ORDER BY POLICIES_AFFECTED DESC;

-- Drill into INVALID_CODE issues for a specific run:
--   SELECT LEGACY_POLICY_NO, PAYLOAD_TYPE, FIELD_NAME, EXTRACTED_VALUE
--   FROM   AGGNE.DEV.PP_XML_VALIDATION_REPORT
--   WHERE  RUN_ID = (SELECT MAX(RUN_ID) FROM AGGNE.DEV.PP_XML_VALIDATION_REPORT)
--     AND  ISSUE_TYPE = 'INVALID_CODE'
--   ORDER BY FIELD_NAME, EXTRACTED_VALUE;

-- Drill into BLANK_REQUIRED issues (mandatory field missing):
--   SELECT LEGACY_POLICY_NO, FIELD_NAME, XML_TAG
--   FROM   AGGNE.DEV.PP_XML_VALIDATION_REPORT
--   WHERE  RUN_ID = (SELECT MAX(RUN_ID) FROM AGGNE.DEV.PP_XML_VALIDATION_REPORT)
--     AND  ISSUE_TYPE = 'BLANK_REQUIRED'
--   ORDER BY FIELD_NAME;

-- View all active rules:
--   SELECT PAYLOAD_TYPE, FIELD_NAME, XML_TAG, IS_REQUIRED,
--          ARRAY_SIZE(VALID_VALUES) AS OPTION_COUNT, NOTES
--   FROM AGGNE.DEV.PP_XML_VALIDATION_RULES
--   WHERE ACTIVE = TRUE
--   ORDER BY PAYLOAD_TYPE, FIELD_NAME;

-- Add a new rule in v1.1 (no SP change needed — just insert):
--   INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
--       (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
--   SELECT '1.1', 'InductionType', 'InductionType', 'RISK_Building_PM', FALSE,
--          PARSE_JSON('["Aspirated","Turbocharged","Supercharged","TwinTurbo"]'),
--          'PL101 source: PM_03.INDUCTIONTYPE. Added v1.1.'
--   FROM (SELECT 1) dummy;   -- use SELECT to allow PARSE_JSON
