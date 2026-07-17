-- Add 3 manuscript-derived rules to the existing PP_XML_VALIDATION_RULES engine (2026-07-14).
--
-- Cross-checked all 18 fields parsed from docs/PP_XML_Validation_Building.xsd and
-- PP_XML_Validation_Motor.xsd against the live table -- 14 of 18 already exist with matching
-- valid-value lists (RoofConstruction, MainWallConstruction, FloorConstruction, ProtectionType,
-- VehicleType, BodyType, HomeBuildingOccupied, Make, Model, Year, YearBuilt, NumberOfStoreys,
-- RedbookCode, VehicleInfoOverride) -- these XSDs were evidently generated from this same table
-- originally. Only 3 enum-bearing fields were genuinely missing (EngineCapacity has no enum/
-- constraint worth a rule, skipped).
--
-- No new table needed -- these slot directly into the existing engine (SP_PP_XML_VALIDATE already
-- picks up any ACTIVE row here automatically on its next run).

INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
  (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES, ACTIVE, CREATED_BY, CREATED_AT)
SELECT '1.0', 'WhatTypeOfAlarmSystemIsInstalled', 'WhatTypeOfAlarmSystemIsInstalled', 'RISK_Building', FALSE,
    PARSE_JSON('["LocalAudibleOnly", "MonitoredBacktobase", "MonitoredSecurity", "MonitoredToMobilePhone", "None"]'),
    'Source: LOCATIONDETAILS_PER.ALARMSYSTEMINSTALLED. ''Local - Monitored'' and ''Mobile Mechanic - No base location'' have no PL101 equivalent -- client decision needed.',
    TRUE, '', CURRENT_TIMESTAMP()
UNION ALL
SELECT '1.0', 'AreDeadlocksInstalledOnAllExternalDoors', 'AreDeadlocksInstalledOnAllExternalDoors', 'RISK_Building', FALSE,
    PARSE_JSON('["AllDoors", "None", "SomeDoors"]'),
    'Source: LOCATIONDETAILS_PER.DEADLOCKSINSTALLED. ''Other'' in source has no PL101 equivalent.',
    TRUE, '', CURRENT_TIMESTAMP()
UNION ALL
SELECT '1.0', 'BarsOrGrillsInstalledOnAllWindows', 'BarsOrGrillsInstalledOnAllWindows', 'RISK_Building', FALSE,
    PARSE_JSON('["AllWindows", "None", "SomeWindows"]'),
    'Source: LOCATIONDETAILS_PER.GRILLKEYLOCKINSTALLED. ''Other'' in source has no PL101 equivalent.',
    TRUE, '', CURRENT_TIMESTAMP();

-- Verify:
SELECT RULE_ID, FIELD_NAME, PAYLOAD_TYPE, VALID_VALUES
FROM AGGNE.DEV.PP_XML_VALIDATION_RULES
WHERE FIELD_NAME IN ('WhatTypeOfAlarmSystemIsInstalled','AreDeadlocksInstalledOnAllExternalDoors','BarsOrGrillsInstalledOnAllWindows');

-- Re-run the engine to pick these up:
-- CALL AGGNE.DEV.SP_PP_XML_VALIDATE('1.0');
