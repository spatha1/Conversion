-- ============================================================
-- View  : PER_DROPDOWN_FIELD_VALIDATION
-- Module: PP (Personal Package) — Dropdown field QA
--
-- Source:
--   AGGNE.DEV.PER_RISK_BUILDING_FINAL   (VW)  — already mapped _FINAL values
--   AGGNE.DEV.LOCATIONDETAILS_PER       (SRC) — raw Pure source values
--
-- Purpose:
--   One row per policy per dropdown field. XML_VALUE is taken directly
--   from PER_RISK_BUILDING_FINAL (_FINAL columns) so it reflects exactly
--   what gets sent to DCT — no duplicated CASE logic.
--   SOURCE_VALUE is the original raw Pure value from LOCATIONDETAILS_PER.
--
--   Reusable for:
--     - Business QA / sign-off report  (GROUP BY FIELD, SOURCE_VALUE)
--     - Automated validation rules   (filter IS_IN_DCT_LIST = 'No')
--     - Per-policy drill-down
--
-- Fields covered:
--   RoofConstruction, MainWallConstruction  (REQUIRED in DCT — blank = failure)
--   FloorConstruction, HowOccuppied         (REQUIRED in DCT — blank = failure)
--   AlarmSystemInstalled, DeadlocksInstalled, GrillKeyLockInstalled (OPTIONAL)
--
-- Client summary query:
--   SELECT FIELD, SOURCE_VALUE, XML_VALUE, DCT_VALUES, IS_IN_DCT_LIST,
--          COUNT(DISTINCT LEGACYPOLICYNUMBER) AS POLICY_COUNT, COMMENT
--   FROM   AGGNE.DEV.PER_DROPDOWN_FIELD_VALIDATION
--   GROUP  BY FIELD, SOURCE_VALUE, XML_VALUE, DCT_VALUES, IS_IN_DCT_LIST, COMMENT
--   ORDER  BY FIELD, IS_IN_DCT_LIST, POLICY_COUNT DESC;
--
-- Validation query (gaps only):
--   SELECT * FROM AGGNE.DEV.PER_DROPDOWN_FIELD_VALIDATION
--   WHERE IS_IN_DCT_LIST = 'No'
--   ORDER BY FIELD, SOURCE_VALUE;
-- ============================================================

CREATE OR REPLACE VIEW AGGNE.DEV.PER_DROPDOWN_FIELD_VALIDATION (
    LEGACYPOLICYNUMBER,
    FIELD,
    SOURCE_VALUE,
    XML_VALUE,
    DCT_VALUES,
    IS_IN_DCT_LIST,
    COMMENT
) AS

-- SRC mirrors the exact join PER_RISK_BUILDING_FINAL uses internally:
--   LOCATIONDETAILS_PER (T2) INNER JOIN PER_ACCOUNT_LOC (T3)
--   ON composite key LEGACYPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P
-- This guarantees SRC picks the same underlying row as VW, so SOURCE_VALUE
-- and XML_VALUE are always from the same LOCATIONDETAILS_PER record.
WITH SRC AS (
    SELECT
        CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.CMLNUMBER) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS COMPOSITE_KEY,
        TRIM(T2.ADDRESSDESCRIPTION) AS ADDRESSDESCRIPTION,
        T2.ROOFCONSTRUCTION,
        T2.MAINWALLCONSTRUCTION,
        T2.FLOORCONSTRUCTION,
        T2.HOWOCCUPPIED,
        T2.ALARMSYSTEMINSTALLED,
        T2.DEADLOCKSINSTALLED,
        T2.GRILLKEYLOCKINSTALLED
    FROM AGGNE.DEV.LOCATIONDETAILS_PER T2
    INNER JOIN AGGNE.DEV.PER_ACCOUNT_LOC T3
        ON CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.CMLNUMBER) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) = TRIM(T3.PUREPOLICYNUMBER)
)

-- ── 1. RoofConstruction (REQUIRED in DCT) ───────────────────────────────────
SELECT
    VW.LEGACYPOLICYNUMBER,
    'RoofConstruction'                                                          AS FIELD,
    SRC.ROOFCONSTRUCTION                                                        AS SOURCE_VALUE,
    VW.ROOFCONSTRUCTION_FINAL                                                   AS XML_VALUE,
    '["Asbestos","Colourbond","Concrete","IronSteelTin","Tile","Wood"]'         AS DCT_VALUES,
    CASE WHEN VW.ROOFCONSTRUCTION_FINAL
              IN ('Asbestos','Colourbond','Concrete','IronSteelTin','Tile','Wood')
         THEN 'Yes' ELSE 'No' END                                               AS IS_IN_DCT_LIST,
    CASE
        WHEN TRIM(COALESCE(SRC.ROOFCONSTRUCTION,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.ROOFCONSTRUCTION_FINAL
             IN ('Asbestos','Colourbond','Concrete','IronSteelTin','Tile','Wood')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END                                                                         AS COMMENT
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 2. MainWallConstruction (REQUIRED in DCT) ───────────────────────────────
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
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 3. AlarmSystemInstalled (OPTIONAL in DCT) ───────────────────────────────
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
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 4. DeadlocksInstalled (OPTIONAL in DCT) ─────────────────────────────────
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
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 5. GrillKeyLockInstalled (OPTIONAL in DCT) ──────────────────────────────
SELECT
    VW.LEGACYPOLICYNUMBER,
    'GrillKeyLockInstalled',
    SRC.GRILLKEYLOCKINSTALLED,
    VW.GRILLKEYLOCKINSTALLED_FINAL,
    '["AllWindows","SomeWindows","None"]',
    CASE
        WHEN TRIM(COALESCE(SRC.GRILLKEYLOCKINSTALLED,'')) = '' THEN 'N/A'
        WHEN VW.GRILLKEYLOCKINSTALLED_FINAL IN ('AllWindows','SomeWindows','None') THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.GRILLKEYLOCKINSTALLED,'')) = ''
             THEN 'Blank — optional field, omitted from XML (OK)'
        WHEN VW.GRILLKEYLOCKINSTALLED_FINAL IN ('AllWindows','SomeWindows','None')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 6. FloorConstruction (REQUIRED in DCT) ──────────────────────────────────
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
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION)

UNION ALL

-- ── 7. HowOccuppied (REQUIRED in DCT) ───────────────────────────────────────
SELECT
    VW.LEGACYPOLICYNUMBER,
    'HowOccuppied',
    SRC.HOWOCCUPPIED,
    VW.HOWOCCUPPIED,
    '["OwnerOccupied","HolidayHome","OwnedleasedtoOthersLongTermLease","OwnedLeasedtoOthersShortTermRental","TenantedbyMember"]',
    CASE
        WHEN TRIM(COALESCE(SRC.HOWOCCUPPIED,'')) = '' THEN 'N/A'
        WHEN VW.HOWOCCUPPIED
             IN ('OwnerOccupied','HolidayHome','OwnedleasedtoOthersLongTermLease','OwnedLeasedtoOthersShortTermRental','TenantedbyMember')
             THEN 'Yes'
        ELSE 'No'
    END,
    CASE
        WHEN TRIM(COALESCE(SRC.HOWOCCUPPIED,'')) = ''
             THEN 'Blank in source — REQUIRED field, default needed from Business'
        WHEN VW.HOWOCCUPPIED
             IN ('OwnerOccupied','HolidayHome','OwnedleasedtoOthersLongTermLease','OwnedLeasedtoOthersShortTermRental','TenantedbyMember')
             THEN 'OK'
        ELSE 'Unmapped — Business to confirm DCT value'
    END
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL VW
JOIN SRC
  ON  SRC.COMPOSITE_KEY      = TRIM(VW.PUREPOLICYNUMBER)
  AND SRC.ADDRESSDESCRIPTION = TRIM(VW.ADDRESSDESCRIPTION);
