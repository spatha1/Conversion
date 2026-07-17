-- ============================================================
-- PP Source Validation Engine — Pure + View layers (2026-07-13)
-- Extends the existing XML-layer validator (PP_XML_VALIDATION_RULES /
-- PP_XML_VALIDATION_REPORT / SP_PP_XML_VALIDATE, see PP_XML_VALIDATE_AND_REPORT.sql)
-- with two new layers, using the SAME rule shape, WITHOUT touching the existing XML system at all.
--
-- Per direction: rules never block the conversion. A failing rule just produces a report row —
-- the pipeline runs exactly as it does today; this is a reporting layer only.
--
-- IMPORTANT — the runner SP (Part 4) is FULLY SET-BASED: no CURSOR, no FOR/LOOP over rows, no
-- row-variable dot notation anywhere. One query builds a single UNION ALL statement (one SELECT
-- branch per active rule, via LISTAGG) and one EXECUTE IMMEDIATE runs it. This shape was reached
-- after 3 earlier attempts each failed differently in this environment — worth knowing before
-- touching this procedure again:
--   1. DECLAREd CURSOR referencing a procedure parameter via :P_LAYER in its WHERE clause ->
--      "Bind variable :P_LAYER not set" at CALL time. Cursors declared this way don't reliably
--      resolve named bind variables when opened.
--   2. Inline `FOR row IN (SELECT ...) DO` with `row.FIELD` dot-notation access ->
--      "invalid identifier 'ROW.FIELD'". Dot-notation field access on the loop's row variable
--      didn't compile here, even inside plain string concatenation.
--   3. CURSOR + explicit `OPEN ... USING (...)` + `FETCH ... INTO` + `%NOTFOUND` ->
--      "Invalid use of cursor". %NOTFOUND is Oracle PL/SQL syntax; Snowflake Scripting doesn't
--      support it.
-- The final version below avoids all three by never using a cursor, loop, or row variable at all.
-- Every quote-sensitive piece is built with CHR(39) rather than hand-typed '''' sequences — that
-- switch matters: an earlier hand-escaped attempt *compiled and ran with no error* but silently
-- produced wrong results (a blank-value comparison matched a literal quote character instead of
-- an empty string) — a worse failure mode than a compile error, since nothing flags it. If you're
-- adding new logic to this SP, test the exact query it builds as a plain read-only SELECT against
-- live data first (see the test scripts referenced in the project chat history) before wiring it
-- into the procedure.
--
-- I cannot execute CREATE PROCEDURE / CALL myself (read-only Snowflake access this session) — every
-- piece of SQL logic below was tested in isolation against live data before being written here.
--
-- THIS IS A LONG-LIVED ENGINE, NOT A ONE-OFF SCRIPT — designed so a junior team member can add a new
-- rule a year from now without touching the SP or understanding Snowflake Scripting at all. Adding a
-- rule is ALWAYS just one INSERT into PP_SOURCE_VALIDATION_RULES, following the same pattern as the
-- 5 seed rules in Part 3 below:
--
--   INSERT INTO AGGNE.DEV.PP_SOURCE_VALIDATION_RULES
--       (RULE_VERSION, LAYER, FIELD_NAME, SOURCE_OBJECT, SOURCE_COLUMN, POLICY_KEY_COLUMN,
--        IS_REQUIRED, VALID_VALUES, NOTES, CREATED_BY)
--   SELECT '1.0', 'PURE' or 'VIEW', '<human-readable field name>',
--       '<fully-qualified table/view, e.g. AGGNE.DEV.SomeTable>', '<column to check>',
--       '<column that identifies the policy in that table, e.g. PUREPOLICYNUMBER>',
--       TRUE or FALSE,                                    -- must this field never be blank?
--       PARSE_JSON('["Value1","Value2"]') or NULL,        -- allowed values, or NULL for free text
--       '<why this rule exists / what it catches>', '<your name>';
--
-- Two things to get right before adding a rule (both caught the hard way while building the seed
-- rules — see NOTES on the RoofConstruction/MainWallConstruction rules below):
--   1. LAYER='PURE' rules must use PURE'S OWN raw vocabulary for VALID_VALUES (the free text as it
--      exists before any conversion mapping), NOT the XML layer's target enum codes — they are
--      genuinely different strings for the same field (e.g. 'Iron/Steel/Tin' in Pure vs
--      'IronSteelTin' in the final XML). Check a few real values first:
--        SELECT DISTINCT <column> FROM <table> LIMIT 20;
--   2. POLICY_KEY_COLUMN must be a column that actually exists in SOURCE_OBJECT and identifies the
--      policy at that table's own grain (policy-level, location-level, vehicle-level, etc. all use
--      different column names across this project's tables).
--
-- No rule can ever block the conversion — every rule here only ever produces a report row (never a
-- hard failure), so it's always safe for a junior team member to add one.
-- ============================================================


-- ============================================================
-- PART 1 — Rules table
-- ============================================================

CREATE TABLE IF NOT EXISTS AGGNE.DEV.PP_SOURCE_VALIDATION_RULES (
    RULE_ID            NUMBER AUTOINCREMENT,
    RULE_VERSION       VARCHAR,
    LAYER              VARCHAR,   -- 'PURE' or 'VIEW'
    FIELD_NAME         VARCHAR,
    SOURCE_OBJECT      VARCHAR,   -- fully-qualified table/view, e.g. AGGNE.DEV.Locationdetails_PER
    SOURCE_COLUMN      VARCHAR,   -- column to check
    POLICY_KEY_COLUMN  VARCHAR,   -- which column identifies the policy in SOURCE_OBJECT
    IS_REQUIRED        BOOLEAN,
    VALID_VALUES       VARIANT,   -- JSON array, NULL if free text / no enum constraint
    NOTES              VARCHAR,
    ACTIVE             BOOLEAN DEFAULT TRUE,
    CREATED_BY         VARCHAR,
    CREATED_AT         TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


-- ============================================================
-- PART 2 — Report table
-- ============================================================

CREATE TABLE IF NOT EXISTS AGGNE.DEV.PP_SOURCE_VALIDATION_REPORT (
    REPORT_ID          NUMBER AUTOINCREMENT,
    RUN_ID             VARCHAR,
    RUN_TS             TIMESTAMP_NTZ,
    POLICY_ID          VARCHAR,
    LEGACY_POLICY_NO   VARCHAR,
    LAYER              VARCHAR,
    FIELD_NAME         VARCHAR,
    SOURCE_OBJECT      VARCHAR,
    EXTRACTED_VALUE    VARCHAR,
    ISSUE_TYPE         VARCHAR,   -- BLANK_REQUIRED / INVALID_CODE
    VALID_VALUES_REF   VARCHAR,
    RULE_VERSION       VARCHAR,
    NOTES              VARCHAR
);


-- ============================================================
-- PART 3 — Seed rules (proof of concept — grows one row at a time from here,
-- same philosophy as the existing XML rules table)
-- ============================================================

-- Pure layer: RoofConstruction — confirmed live 2026-07-13: 980 of 4,225 policies (23.2%) blank.
-- VALID_VALUES is Pure's OWN raw vocabulary (pre-mapping free text), NOT the XML layer's target
-- enum codes — confirmed live these are genuinely different ('Iron/Steel/Tin' raw vs 'IronSteelTin'
-- mapped). Using the XML-side codes here would have falsely flagged ~2,044 valid rows as INVALID_CODE.
INSERT INTO AGGNE.DEV.PP_SOURCE_VALIDATION_RULES
    (RULE_VERSION, LAYER, FIELD_NAME, SOURCE_OBJECT, SOURCE_COLUMN, POLICY_KEY_COLUMN,
     IS_REQUIRED, VALID_VALUES, NOTES, CREATED_BY)
SELECT '1.0', 'PURE', 'RoofConstruction', 'AGGNE.DEV.Locationdetails_PER', 'ROOFCONSTRUCTION', 'PUREPOLICYNUMBER',
    TRUE, PARSE_JSON('["Iron/Steel/Tin","Tile","Colorbond","Concrete (Flat Roof)","Asbestos","Wood (Shingles)"]'),
    'Confirmed live 2026-07-13: 980/4225 (23.2%) blank in Pure. PL101 requires this field for RISK_Building — client to backfill in Pure.',
    'claude_session_20260713';

-- Pure layer: MainWallConstruction — confirmed live 2026-07-13: 980 of 4,225 policies blank
-- (same population as RoofConstruction, both typically blank/filled together per location).
INSERT INTO AGGNE.DEV.PP_SOURCE_VALIDATION_RULES
    (RULE_VERSION, LAYER, FIELD_NAME, SOURCE_OBJECT, SOURCE_COLUMN, POLICY_KEY_COLUMN,
     IS_REQUIRED, VALID_VALUES, NOTES, CREATED_BY)
SELECT '1.0', 'PURE', 'MainWallConstruction', 'AGGNE.DEV.Locationdetails_PER', 'MAINWALLCONSTRUCTION', 'PUREPOLICYNUMBER',
    TRUE, PARSE_JSON('["Brick Veneer","Double Brick","Fibro/Hardiplank","Wood","Concrete","Iron/Steel","Asbestos"]'),
    'Confirmed live 2026-07-13: 980/4225 (23.2%) blank in Pure. PL101 requires this field for RISK_Building — client to backfill in Pure.',
    'claude_session_20260713';

-- Pure layer: YearLastReWired — no VALID_VALUES (free-text year, not an enum). Flags blanks for
-- client awareness; G-41's fix (2026-07-13) already corrected the conversion-side bug that was
-- discarding real years — remaining blanks after that fix are confirmed genuine Pure gaps.
INSERT INTO AGGNE.DEV.PP_SOURCE_VALIDATION_RULES
    (RULE_VERSION, LAYER, FIELD_NAME, SOURCE_OBJECT, SOURCE_COLUMN, POLICY_KEY_COLUMN,
     IS_REQUIRED, VALID_VALUES, NOTES, CREATED_BY)
SELECT '1.0', 'PURE', 'YearLastReWired', 'AGGNE.DEV.Locationdetails_PER', 'YEARLASTREWIRED', 'PUREPOLICYNUMBER',
    TRUE, NULL,
    'Post G-41 fix (2026-07-13): remaining blanks confirmed genuine Pure gaps, not a conversion defect.',
    'claude_session_20260713';

INSERT INTO AGGNE.DEV.PP_SOURCE_VALIDATION_RULES
    (RULE_VERSION, LAYER, FIELD_NAME, SOURCE_OBJECT, SOURCE_COLUMN, POLICY_KEY_COLUMN,
     IS_REQUIRED, VALID_VALUES, NOTES, CREATED_BY)
SELECT '1.0', 'PURE', 'YearLastRePlumbed', 'AGGNE.DEV.Locationdetails_PER', 'YEARLASTREPLUMBED', 'PUREPOLICYNUMBER',
    TRUE, NULL,
    'Post G-41 fix (2026-07-13): remaining blanks confirmed genuine Pure gaps, not a conversion defect.',
    'claude_session_20260713';

-- View layer: NumberOfCylinders — confirmed live 2026-07-13: 407 rows show '0' in PER_COM_PAYLOAD,
-- which is outside the valid 1-16 DCT range. This is the known G-05 part 2 case (RedBook code 11 =
-- "no cylinders", e.g. trailers/EVs) — flags for the still-open client decision: omit the tag for
-- these vehicle types, or is 0 an acceptable value?
INSERT INTO AGGNE.DEV.PP_SOURCE_VALIDATION_RULES
    (RULE_VERSION, LAYER, FIELD_NAME, SOURCE_OBJECT, SOURCE_COLUMN, POLICY_KEY_COLUMN,
     IS_REQUIRED, VALID_VALUES, NOTES, CREATED_BY)
SELECT '1.0', 'VIEW', 'NumberOfCylinders', 'AGGNE.DEV.PER_COM_PAYLOAD', 'NUMBEROFCYLINDERS', 'PUREPOLICYNUMBER',
    FALSE, PARSE_JSON('["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16"]'),
    'G-05 part 2 (still awaiting client decision): 407 vehicles show 0 (RedBook code 11, "no cylinders" — trailers/EVs). Omit tag or accept 0?',
    'claude_session_20260713';


-- ============================================================
-- PART 4 — Runner procedure
-- ============================================================

CREATE OR REPLACE PROCEDURE AGGNE.DEV.SP_PP_SOURCE_VALIDATE(
    P_LAYER        VARCHAR,
    P_RULE_VERSION VARCHAR DEFAULT NULL
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    v_run_id     VARCHAR;
    v_run_ts     TIMESTAMP_NTZ;
    v_rule_cnt   INT;
    v_issue_cnt  INT DEFAULT 0;
    v_union_sql  VARCHAR;
    v_full_sql   VARCHAR;
BEGIN
    -- No cursor, no FOR/LOOP over rows, no row-variable dot notation anywhere in this procedure —
    -- three different Snowflake Scripting control-flow constructs each hit a different compile/
    -- runtime error in this environment (bind variables not resolving in a DECLAREd CURSOR,
    -- row-variable dot notation not compiling, %NOTFOUND not supported). This version is fully
    -- set-based instead: one query builds a single UNION ALL statement (one branch per active
    -- rule, via LISTAGG) and one EXECUTE IMMEDIATE runs it. Every literal is built with CHR(39)
    -- rather than hand-typed '''' sequences — tested directly against live data before writing
    -- this procedure (see chat) specifically because hand-counted quote escaping caused a silent
    -- wrong-result bug (blank comparison matched a literal quote character instead of empty
    -- string) that produced no error and would have been easy to miss.
    v_run_ts   := CURRENT_TIMESTAMP();
    v_run_id   := TO_CHAR(v_run_ts, 'YYYYMMDD_HH24MI') || '_' || :P_LAYER;

    SELECT COUNT(*) INTO :v_rule_cnt
    FROM AGGNE.DEV.PP_SOURCE_VALIDATION_RULES
    WHERE ACTIVE = TRUE
      AND LAYER = :P_LAYER
      AND (:P_RULE_VERSION IS NULL OR RULE_VERSION = :P_RULE_VERSION);

    IF (v_rule_cnt = 0) THEN
        RETURN 'No active rules found for LAYER=' || :P_LAYER;
    END IF;

    SELECT LISTAGG(
        'SELECT '
            || CHR(39) || RULE_ID || CHR(39) || ' AS RULE_ID_TXT, '
            || 'TRIM(' || POLICY_KEY_COLUMN || '::VARCHAR) AS LEGACY_POLICY_NO, '
            || CHR(39) || LAYER || CHR(39) || ' AS LAYER, '
            || CHR(39) || REPLACE(FIELD_NAME, CHR(39), CHR(39)||CHR(39)) || CHR(39) || ' AS FIELD_NAME, '
            || CHR(39) || REPLACE(SOURCE_OBJECT, CHR(39), CHR(39)||CHR(39)) || CHR(39) || ' AS SOURCE_OBJECT, '
            || 'TRIM(' || SOURCE_COLUMN || '::VARCHAR) AS EXTRACTED_VALUE, '
            || CHR(39) || REPLACE(COALESCE(VALID_VALUES::VARCHAR, ''), CHR(39), CHR(39)||CHR(39)) || CHR(39) || ' AS VALID_VALUES_REF, '
            || CHR(39) || REPLACE(RULE_VERSION, CHR(39), CHR(39)||CHR(39)) || CHR(39) || ' AS RULE_VERSION, '
            || CHR(39) || REPLACE(COALESCE(NOTES, ''), CHR(39), CHR(39)||CHR(39)) || CHR(39) || ' AS NOTES, '
            || 'CASE'
            || ' WHEN (' || SOURCE_COLUMN || ' IS NULL OR TRIM(' || SOURCE_COLUMN || '::VARCHAR) = ' || CHR(39) || CHR(39) || ')'
                || ' AND ' || (CASE WHEN IS_REQUIRED THEN 'TRUE' ELSE 'FALSE' END)
                || ' THEN ' || CHR(39) || 'BLANK_REQUIRED' || CHR(39)
            || ' WHEN ' || SOURCE_COLUMN || ' IS NOT NULL AND TRIM(' || SOURCE_COLUMN || '::VARCHAR) <> ' || CHR(39) || CHR(39)
                || ' AND ' || (CASE WHEN VALID_VALUES IS NULL THEN 'FALSE'
                       ELSE 'NOT ARRAY_CONTAINS(TRIM(' || SOURCE_COLUMN || '::VARCHAR)::VARIANT, PARSE_JSON('
                            || CHR(39) || REPLACE(VALID_VALUES::VARCHAR, CHR(39), CHR(39)||CHR(39)) || CHR(39) || '))'
                  END)
                || ' THEN ' || CHR(39) || 'INVALID_CODE' || CHR(39)
            || ' ELSE NULL END AS ISSUE_TYPE '
            || 'FROM ' || SOURCE_OBJECT,
        ' UNION ALL '
    ) INTO :v_union_sql
    FROM AGGNE.DEV.PP_SOURCE_VALIDATION_RULES
    WHERE ACTIVE = TRUE
      AND LAYER = :P_LAYER
      AND (:P_RULE_VERSION IS NULL OR RULE_VERSION = :P_RULE_VERSION);

    v_full_sql := 'INSERT INTO AGGNE.DEV.PP_SOURCE_VALIDATION_REPORT'
        || ' (RUN_ID, RUN_TS, POLICY_ID, LEGACY_POLICY_NO, LAYER, FIELD_NAME, SOURCE_OBJECT,'
        || '  EXTRACTED_VALUE, ISSUE_TYPE, VALID_VALUES_REF, RULE_VERSION, NOTES)'
        || ' SELECT '
        || CHR(39) || v_run_id || CHR(39) || ', '
        || CHR(39) || v_run_ts || CHR(39) || '::TIMESTAMP_NTZ,'
        || ' TRIM(LEGACY_POLICY_NO) || ' || CHR(39) || '|' || CHR(39) || ' || FIELD_NAME,'
        || ' TRIM(LEGACY_POLICY_NO), LAYER, FIELD_NAME, SOURCE_OBJECT, EXTRACTED_VALUE, ISSUE_TYPE,'
        || ' VALID_VALUES_REF, RULE_VERSION, NOTES'
        || ' FROM (' || v_union_sql || ')'
        || ' WHERE ISSUE_TYPE IS NOT NULL';

    EXECUTE IMMEDIATE :v_full_sql;
    v_issue_cnt := SQLROWCOUNT;

    RETURN 'Run: ' || v_run_id || ' | Layer: ' || :P_LAYER
        || ' | Rules evaluated: ' || v_rule_cnt::VARCHAR
        || ' | Issues found: ' || v_issue_cnt::VARCHAR;
END;
$$;


-- ============================================================
-- PART 5 — Convenience combined view (all 3 layers, one query for client reporting)
-- ============================================================

CREATE OR REPLACE VIEW AGGNE.DEV.VW_PP_VALIDATION_REPORT_ALL AS
SELECT
    RUN_ID, RUN_TS, POLICY_ID, LEGACY_POLICY_NO,
    'XML' AS LAYER,
    FIELD_NAME,
    PAYLOAD_TYPE || ' / ' || XML_TAG AS SOURCE_REF,
    EXTRACTED_VALUE, ISSUE_TYPE, VALID_VALUES_REF, RULE_VERSION, NOTES
FROM AGGNE.DEV.PP_XML_VALIDATION_REPORT
UNION ALL
SELECT
    RUN_ID, RUN_TS, POLICY_ID, LEGACY_POLICY_NO,
    LAYER,
    FIELD_NAME,
    SOURCE_OBJECT AS SOURCE_REF,
    EXTRACTED_VALUE, ISSUE_TYPE, VALID_VALUES_REF, RULE_VERSION, NOTES
FROM AGGNE.DEV.PP_SOURCE_VALIDATION_REPORT;


-- ============================================================
-- PART 6 — Run it
-- ============================================================

CALL AGGNE.DEV.SP_PP_SOURCE_VALIDATE('PURE', NULL);
CALL AGGNE.DEV.SP_PP_SOURCE_VALIDATE('VIEW', NULL);


-- ============================================================
-- PART 7 — Post-validation
-- ============================================================

-- 7a. Confirm baselines match what was tested live (before deploying)
SELECT FIELD_NAME, ISSUE_TYPE, COUNT(*) AS POLICY_COUNT
FROM AGGNE.DEV.PP_SOURCE_VALIDATION_REPORT
GROUP BY 1, 2 ORDER BY 1, 2;
-- Target: RoofConstruction/BLANK_REQUIRED ~980, MainWallConstruction/BLANK_REQUIRED ~980,
-- NumberOfCylinders/INVALID_CODE ~407, YearLastReWired/YearLastRePlumbed some BLANK_REQUIRED count

-- 7b. Confirm the combined view returns a superset of the existing XML-only report
SELECT LAYER, COUNT(*) FROM AGGNE.DEV.VW_PP_VALIDATION_REPORT_ALL GROUP BY 1 ORDER BY 1;

-- 7c. Confirm the existing XML system is completely untouched
SELECT COUNT(*) FROM AGGNE.DEV.PP_XML_VALIDATION_REPORT;
-- Target: unchanged from before this deploy (still reflects only past SP_PP_XML_VALIDATE runs)
-- ============================================================
