-- ============================================================
-- PP XML Validation — Full Run & Report
-- Run this file end-to-end after each ETL batch.
--
-- Steps:
--   0. Check available batch dates in PREVDATA (historical XMLs)
--   1. Refresh rules v1.0 + v1.2
--   2. Deactivate ambiguous Type-tag rules
--   3. Recreate SP (CREATE OR REPLACE)
--   4. Call SP — current batch OR historical batch by date
--   5. Analysis queries — paste RUN_ID from Step 4 output below
--   6. Standalone fix-verification queries
--
-- Table sources:
--   Current batch  → AGGNE.DEV.PER_POLICY_MIGRATION_DCT
--   Historical      → AGGNE.DEV.PER_POLICY_MIGRATION_DCT_PREVDATA (filtered by LOADDATE)
-- ============================================================

-- ============================================================
-- STEP 0 — Check which batch dates exist in PREVDATA
-- Run this first to find the date(s) you want to validate.
-- ============================================================

SELECT
    CAST(LOADDATE AS DATE)  AS BATCH_DATE,
    COUNT(*)                AS XML_COUNT,
    MIN(LEGACYPOLICYNUMBER) AS FIRST_POLICY,
    MAX(LEGACYPOLICYNUMBER) AS LAST_POLICY
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT_PREVDATA
GROUP BY 1
ORDER BY 1 DESC;

-- ============================================================
-- STEP 1 — Refresh rules v1.0
-- ============================================================

DELETE FROM AGGNE.DEV.PP_XML_VALIDATION_RULES
WHERE RULE_VERSION = '1.0';

INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT ver, field_name, xml_tag, payload_type, is_required, PARSE_JSON(valid_json), notes
FROM (
    SELECT '1.0' AS ver, 'RoofConstruction' AS field_name, 'RoofConstruction' AS xml_tag,
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

INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT '1.0', field_name, xml_tag, 'RISK_Building', FALSE, NULL, notes
FROM (
    SELECT 'YearBuilt'     AS field_name, 'YearBuilt'     AS xml_tag, '4-digit year. Source: LOCATIONDETAILS_PER.YEARBUILT.' AS notes
    UNION ALL
    SELECT 'NumberOfStoreys',              'NumberOfStoreys',           'Numeric. Source: LOCATIONDETAILS_PER.'
);

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

INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT '1.0', field_name, xml_tag, 'RISK_Building_PM', FALSE, NULL, notes
FROM (
    SELECT 'Make'      AS field_name, 'Make'      AS xml_tag, 'Free text. Source: PM_03.MAKE (INITCAP).'  AS notes
    UNION ALL SELECT 'Model',                  'Model',                  'Free text. Source: PM_03.MODEL (INITCAP).'
    UNION ALL SELECT 'Year',                   'Year',                   '4-digit year. Source: PM_03.YEAR.'
    UNION ALL SELECT 'BodyType',               'BodyType',               'Free text. Dev added 34-type CASE mapping.'
    UNION ALL SELECT 'RedbookCode',            'RedbookCode',            'Source: PM_03.MVRBVEHICLEKEY.'
);

-- ============================================================
-- STEP 1b — Rules v1.2 (July 2026 fix batch)
-- Covers: InceptionDate, Coverage Indicators, ExcessWaiverForGlass
-- ============================================================

DELETE FROM AGGNE.DEV.PP_XML_VALIDATION_RULES WHERE RULE_VERSION = '1.2';

INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
    (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES)
SELECT ver, field_name, xml_tag, payload_type, is_required, PARSE_JSON(valid_json), notes
FROM (
    -- ATP-10962: InceptionDate must be present and non-blank for all policies
    SELECT '1.2' AS ver, 'InceptionDate' AS field_name, 'InceptionDate' AS xml_tag,
           'Policy' AS payload_type, TRUE AS is_required,
           NULL AS valid_json,
           'ATP-10962: FINAL_LOAD uses MIN(INCEPTIONDATE) from POLICYATTACH_PER with EFFECTIVEDATE fallback. Blank = renewal inception date missing.' AS notes

    UNION ALL
    -- ATP-10965: HomeBuildingsContents must be 0 or 1 (data-driven, not hardcoded)
    SELECT '1.2', 'HomeBuildingsContents', 'HomeBuildingsContents', 'Policy', FALSE,
           '["0","1"]',
           'ATP-10965: Driven by HB_HC_INDICATOR in FINAL_LOAD. Motor-only policies must be 0.'

    UNION ALL
    -- ATP-10965: PrivateMotorVehicles must be 0 or 1 (data-driven, not hardcoded)
    SELECT '1.2', 'PrivateMotorVehicles', 'PrivateMotorVehicles', 'Policy', FALSE,
           '["0","1"]',
           'ATP-10965: Driven by MOTOR_INDICATOR in FINAL_LOAD. HB/HC-only policies must be 0.'

    UNION ALL
    -- ATP-11003: ExcessWaiverForGlass must be 0 or 1 — never blank or other value
    SELECT '1.2', 'ExcessWaiverForGlass', 'ExcessWaiverForGlass', 'RISK_Building_PM', FALSE,
           '["0","1"]',
           'ATP-11003: Pure stores Taken (not Yes) for some policies. Fix: IN (Yes, Taken) -> 1 in PER_COM_PAYLOAD line 283. Any value outside 0/1 = mapping bug.'
);

-- ============================================================
-- STEP 2 — Deactivate ambiguous Type-tag rules
-- (XML_TAG = 'Type' matches the first <Type> in the whole XML
--  which is the product-line code PPAU/PPNZ, not the clause code)
-- ============================================================

UPDATE AGGNE.DEV.PP_XML_VALIDATION_RULES
SET    ACTIVE = FALSE
WHERE  FIELD_NAME IN (
           'BuildingRiskClausesType',
           'HomeContentsClausesType',
           'CommercialVehicleClausesType'
       )
  AND  RULE_VERSION = '1.1';

-- ============================================================
-- STEP 3 — Recreate stored procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE AGGNE.DEV.SP_PP_XML_VALIDATE(
    P_RULE_VERSION  VARCHAR,
    P_PAYLOAD_TYPE  VARCHAR,
    P_BATCH_DATE    DATE DEFAULT NULL
    -- NULL  → reads PER_POLICY_MIGRATION_DCT        (current / latest batch)
    -- date  → reads PER_POLICY_MIGRATION_DCT_PREVDATA filtered by that LOADDATE
    --         e.g. '2026-07-01'::DATE
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
    FROM (
        SELECT LEGACYPOLICYNUMBER, NULL::DATE AS BATCH_DATE
        FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
        UNION ALL
        SELECT LEGACYPOLICYNUMBER, CAST(LOADDATE AS DATE)
        FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT_PREVDATA
    ) SRC
    WHERE (:P_BATCH_DATE IS NULL     AND BATCH_DATE IS NULL)
       OR (:P_BATCH_DATE IS NOT NULL AND BATCH_DATE = :P_BATCH_DATE);

    IF (v_pol_count = 0) THEN
        RETURN 'ERROR: No XMLs found. For current batch check PER_POLICY_MIGRATION_DCT; for a previous batch pass the LoadDate as P_BATCH_DATE.';
    END IF;

    INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_REPORT
        (RUN_ID, RUN_TS, POLICY_ID, LEGACY_POLICY_NO, PAYLOAD_TYPE,
         FIELD_NAME, XML_TAG, EXTRACTED_VALUE, ISSUE_TYPE,
         VALID_VALUES_REF, RULE_VERSION, NOTES)

    WITH policies AS (
        SELECT LEGACYPOLICYNUMBER                      AS LEGACY_POLICY_NO,
               LEGACYPOLICYNUMBER || '|' || CML_NUMBER AS POLICY_ID,
               REQUEST_XML
        FROM (
            SELECT LEGACYPOLICYNUMBER, CML_NUMBER, REQUEST_XML, NULL::DATE AS BATCH_DATE
            FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
            UNION ALL
            SELECT LEGACYPOLICYNUMBER, CML_NUMBER, REQUEST_XML, CAST(LOADDATE AS DATE)
            FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT_PREVDATA
        ) SRC
        WHERE (:P_BATCH_DATE IS NULL     AND BATCH_DATE IS NULL)
           OR (:P_BATCH_DATE IS NOT NULL AND BATCH_DATE = :P_BATCH_DATE)
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
            -- XPath-style tags (contain / or [) cannot be matched by simple
            -- regex — mark XPATH_SKIP to suppress all checks for these rules.
            CASE
                WHEN r.XML_TAG LIKE '%/%' OR r.XML_TAG LIKE '%[%'
                THEN 'XPATH_SKIP'
                WHEN REGEXP_INSTR(p.REQUEST_XML, '<' || r.XML_TAG || '[^>]*>') > 0
                THEN 'PRESENT'
                ELSE 'ABSENT'
            END AS TAG_PRESENCE,
            CASE
                WHEN r.XML_TAG LIKE '%/%' OR r.XML_TAG LIKE '%[%'
                THEN NULL
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
           OR (TAG_PRESENCE = 'PRESENT' AND EXTRACTED_VALUE IS NULL   AND IS_REQUIRED = TRUE)
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
        'Run: '                || :v_run_id
        || ' | Policies: '     || :v_pol_count::VARCHAR
        || ' | Issues found: ' || :v_issue_cnt::VARCHAR
        || ' | RUN_ID for queries below: ' || :v_run_id;

END;
$$;

-- ============================================================
-- STEP 4 — Run the SP
-- Copy the RUN_ID from the result and paste it into STEP 5.
--
-- Option A — Current batch (PER_POLICY_MIGRATION_DCT):
CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, NULL);

-- Option B — Historical batch from PREVDATA (replace the date):
-- CALL AGGNE.DEV.SP_PP_XML_VALIDATE(NULL, NULL, '2026-07-01'::DATE);
-- ============================================================

-- ============================================================
-- STEP 5 — Analysis queries
-- Replace <<RUN_ID>> with the RUN_ID returned above.
-- e.g. '20260630_2044_PP'
-- ============================================================

-- 5a. Issue type summary
SELECT ISSUE_TYPE,
       COUNT(*)                     AS ISSUE_COUNT,
       COUNT(DISTINCT POLICY_ID)    AS POLICIES_AFFECTED
FROM   AGGNE.DEV.PP_XML_VALIDATION_REPORT
WHERE  RUN_ID = '<<RUN_ID>>'
GROUP  BY ISSUE_TYPE
ORDER  BY ISSUE_COUNT DESC;

-- 5b. INVALID_CODE — wrong dropdown values (fix in source view)
SELECT FIELD_NAME,
       XML_TAG,
       PAYLOAD_TYPE,
       EXTRACTED_VALUE              AS BAD_VALUE,
       VALID_VALUES_REF,
       COUNT(DISTINCT POLICY_ID)    AS POLICY_COUNT
FROM   AGGNE.DEV.PP_XML_VALIDATION_REPORT
WHERE  RUN_ID     = '<<RUN_ID>>'
  AND  ISSUE_TYPE = 'INVALID_CODE'
GROUP  BY FIELD_NAME, XML_TAG, PAYLOAD_TYPE, EXTRACTED_VALUE, VALID_VALUES_REF
ORDER  BY POLICY_COUNT DESC;

-- 5c. MISSING_TAG — required tag absent from XML
SELECT FIELD_NAME,
       XML_TAG,
       PAYLOAD_TYPE,
       COUNT(DISTINCT POLICY_ID)    AS POLICY_COUNT
FROM   AGGNE.DEV.PP_XML_VALIDATION_REPORT
WHERE  RUN_ID     = '<<RUN_ID>>'
  AND  ISSUE_TYPE = 'MISSING_TAG'
GROUP  BY FIELD_NAME, XML_TAG, PAYLOAD_TYPE
ORDER  BY POLICY_COUNT DESC;

-- 5d. BLANK_REQUIRED — tag present but value is empty
SELECT FIELD_NAME,
       XML_TAG,
       PAYLOAD_TYPE,
       COUNT(DISTINCT POLICY_ID)    AS POLICY_COUNT
FROM   AGGNE.DEV.PP_XML_VALIDATION_REPORT
WHERE  RUN_ID     = '<<RUN_ID>>'
  AND  ISSUE_TYPE = 'BLANK_REQUIRED'
GROUP  BY FIELD_NAME, XML_TAG, PAYLOAD_TYPE
ORDER  BY POLICY_COUNT DESC;

-- 5e. Per-policy breakdown (worst offenders first)
SELECT LEGACY_POLICY_NO,
       COUNT(*)                                                AS TOTAL_ISSUES,
       SUM(CASE WHEN ISSUE_TYPE = 'INVALID_CODE'   THEN 1 END) AS INVALID_CODE,
       SUM(CASE WHEN ISSUE_TYPE = 'MISSING_TAG'    THEN 1 END) AS MISSING_TAG,
       SUM(CASE WHEN ISSUE_TYPE = 'BLANK_REQUIRED' THEN 1 END) AS BLANK_REQUIRED
FROM   AGGNE.DEV.PP_XML_VALIDATION_REPORT
WHERE  RUN_ID = '<<RUN_ID>>'
GROUP  BY LEGACY_POLICY_NO
ORDER  BY TOTAL_ISSUES DESC;

-- 5f. Full detail for a specific policy (replace <<POLICY_NO>>)
-- SELECT * FROM AGGNE.DEV.PP_XML_VALIDATION_REPORT
-- WHERE RUN_ID = '<<RUN_ID>>' AND LEGACY_POLICY_NO = '<<POLICY_NO>>'
-- ORDER BY ISSUE_TYPE, FIELD_NAME;

-- ============================================================
-- STEP 6 — Standalone fix-verification queries (July 2026 batch)
-- These checks need source cross-references or logic the SP
-- cannot express. Run independently — no RUN_ID needed.
-- ============================================================

-- ── 6a. Summary row count ─────────────────────────────────────
SELECT
    COUNT(*)                           AS TOTAL_XML_ROWS,
    COUNT(DISTINCT LEGACYPOLICYNUMBER) AS UNIQUE_POLICIES,
    CAST(GETDATE() AS DATE)            AS AS_OF_DATE
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;


-- ── 6b. Coverage Indicators distribution (ATP-10965) ──────────
-- Verify: motor-only policies have HBC=0, HBHC-only have PMV=0.
-- A row where both=1 is OK only for policies with both coverages.
SELECT
    REGEXP_SUBSTR(REQUEST_XML,'<HomeBuildingsContents>(.*?)</HomeBuildingsContents>',1,1,'e',1) AS HBC,
    REGEXP_SUBSTR(REQUEST_XML,'<PrivateMotorVehicles>(.*?)</PrivateMotorVehicles>',1,1,'e',1)   AS PMV,
    COUNT(*) AS POLICIES
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
GROUP BY 1, 2
ORDER BY 3 DESC;
-- Expected: distribution across (0,1) / (1,0) / (1,1) — no rows with both=NULL


-- ── 6c. Motor-only policies leaking a building section (ATP-10965) ──
-- Policies where PMV=1, HBC=0 but the XML still contains a <RoofConstruction> tag.
SELECT LEGACYPOLICYNUMBER
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE REGEXP_SUBSTR(REQUEST_XML,'<PrivateMotorVehicles>(.*?)</PrivateMotorVehicles>',1,1,'e',1) = '1'
  AND REGEXP_SUBSTR(REQUEST_XML,'<HomeBuildingsContents>(.*?)</HomeBuildingsContents>',1,1,'e',1) = '0'
  AND REQUEST_XML LIKE '%<RoofConstruction>%'
ORDER BY 1;
-- Expected: 0 rows


-- ── 6d. Override = 1 on all motor vehicles (PP-CF-26) ─────────
-- Any motor policy with Override not equal to 1 = blocking bug.
SELECT LEGACYPOLICYNUMBER
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE REQUEST_XML LIKE '%<VehicleType>%'           -- has motor section
  AND (   REQUEST_XML LIKE '%<Override>0</Override>%'
       OR REQUEST_XML LIKE '%<Override></Override>%')
ORDER BY 1;
-- Expected: 0 rows


-- ── 6e. ExcessWaiverForGlass source cross-reference (ATP-11003) ──
-- Policies where Pure source = 'Taken' must have ExcessWaiverForGlass=1 in XML.
SELECT
    F.LEGACYPOLICYNUMBER,
    C.EXCESSWAIVERFORGLASS                                                 AS SOURCE_VALUE,
    CASE
        WHEN F.REQUEST_XML LIKE '%<ExcessWaiverForGlass>1</ExcessWaiverForGlass>%' THEN '1 — OK'
        WHEN F.REQUEST_XML LIKE '%<ExcessWaiverForGlass>0</ExcessWaiverForGlass>%' THEN '0 — FAIL'
        ELSE 'Tag absent'
    END                                                                    AS XML_VALUE
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT F
JOIN AGGNE.DEV.COMMERCIALMOTOR_PER C
    ON TRIM(C.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
WHERE UPPER(TRIM(C.EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
ORDER BY 1;
-- Expected: all rows XML_VALUE = '1 — OK'


-- ── 6f. Unreplaced tokens catch-all ───────────────────────────
-- Any {TOKEN} still in the XML means a REPLACE() call is missing.
SELECT
    LEGACYPOLICYNUMBER,
    REGEXP_SUBSTR(REQUEST_XML,'\\{[A-Z_0-9]+\\}',1,1,'e',0) AS FIRST_UNREPLACED_TOKEN
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE REQUEST_XML REGEXP '\\{[A-Z_0-9]+\\}'
ORDER BY 1;
-- Expected: 0 rows


-- ── 6g. BP sideline turnover — ATP-10928 (run after BP batch) ─
-- Policy P00010114: TurnoverOfSidelineBusiness must be 25 (%) not 77500 ($).
-- Run against AGGNE.DEV.POLICY_MIGRATION_DCT (BP table, not PP).
SELECT
    LEGACYPOLICYNUMBER,
    REGEXP_SUBSTR(REQUEST_XML,
        '<TurnoverOfSidelineBusiness>(.*?)</TurnoverOfSidelineBusiness>',
        1, 1, 'e', 1) AS SIDELINE_TURNOVER
FROM AGGNE.DEV.POLICY_MIGRATION_DCT
WHERE LEGACYPOLICYNUMBER = 'P00010114';
-- Expected: 25   (not 77500 and not blank)
