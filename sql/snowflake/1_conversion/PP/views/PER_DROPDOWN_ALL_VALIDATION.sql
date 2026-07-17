-- ============================================================
-- View  : PER_DROPDOWN_ALL_VALIDATION
-- Module: PP (Personal Protection) — Full dropdown QA (all coverage areas)
--
-- Purpose:
--   Single combined view unioning all 3 PP dropdown validation views.
--   Use this for the complete client QA sign-off report.
--
--   HB    (7 fields): Home Buildings policies — Roof, Wall, Floor, Occupation,
--                     Alarm, Deadlocks, Grills
--   HC    (7 fields): Home Contents policies  — same 7 fields (HOMECONTENTS=Yes)
--   Motor (4 fields): Vehicle Type, Protection Type, Body Type, Induction Type
--
-- Note: Policies with both HB and HC appear in BOTH the HB and HC sections.
-- REGISTRATIONNUMBER is NULL for HB/HC rows (policy-level),
-- populated for Motor rows (vehicle-level).
--
-- Summary query for client sign-off:
--   SELECT COVERAGE_AREA, FIELD, SOURCE_VALUE, XML_VALUE, IS_IN_DCT_LIST,
--          COUNT(DISTINCT LEGACYPOLICYNUMBER) AS POLICY_COUNT, COMMENT
--   FROM   AGGNE.DEV.PER_DROPDOWN_ALL_VALIDATION
--   GROUP  BY COVERAGE_AREA, FIELD, SOURCE_VALUE, XML_VALUE, IS_IN_DCT_LIST, COMMENT
--   ORDER  BY COVERAGE_AREA, FIELD, IS_IN_DCT_LIST, POLICY_COUNT DESC;
--
-- Gaps only:
--   SELECT COVERAGE_AREA, FIELD, SOURCE_VALUE, XML_VALUE,
--          COUNT(DISTINCT LEGACYPOLICYNUMBER) AS POLICY_COUNT, COMMENT
--   FROM   AGGNE.DEV.PER_DROPDOWN_ALL_VALIDATION
--   WHERE  IS_IN_DCT_LIST = 'No'
--   GROUP  BY COVERAGE_AREA, FIELD, SOURCE_VALUE, XML_VALUE, COMMENT
--   ORDER  BY COVERAGE_AREA, FIELD, POLICY_COUNT DESC;
-- ============================================================

CREATE OR REPLACE VIEW AGGNE.DEV.PER_DROPDOWN_ALL_VALIDATION (
    COVERAGE_AREA,
    LEGACYPOLICYNUMBER,
    REGISTRATIONNUMBER,
    FIELD,
    SOURCE_VALUE,
    XML_VALUE,
    DCT_VALUES,
    IS_IN_DCT_LIST,
    COMMENT
) AS

-- Home Buildings (policy-level, HOMEBUILDINGS = 'Yes')
SELECT
    'HB'   AS COVERAGE_AREA,
    LEGACYPOLICYNUMBER,
    NULL   AS REGISTRATIONNUMBER,
    FIELD, SOURCE_VALUE, XML_VALUE, DCT_VALUES, IS_IN_DCT_LIST, COMMENT
FROM AGGNE.DEV.PER_DROPDOWN_HB_VALIDATION

UNION ALL

-- Home Contents (policy-level, HOMECONTENTS = 'Yes')
SELECT
    'HC'   AS COVERAGE_AREA,
    LEGACYPOLICYNUMBER,
    NULL   AS REGISTRATIONNUMBER,
    FIELD, SOURCE_VALUE, XML_VALUE, DCT_VALUES, IS_IN_DCT_LIST, COMMENT
FROM AGGNE.DEV.PER_DROPDOWN_HC_VALIDATION

UNION ALL

-- Motor Vehicle (vehicle-level, one row per policy × vehicle × field)
SELECT
    'Motor' AS COVERAGE_AREA,
    LEGACYPOLICYNUMBER,
    REGISTRATIONNUMBER,
    FIELD, SOURCE_VALUE, XML_VALUE, DCT_VALUES, IS_IN_DCT_LIST, COMMENT
FROM AGGNE.DEV.PER_DROPDOWN_MOTOR_VALIDATION;
