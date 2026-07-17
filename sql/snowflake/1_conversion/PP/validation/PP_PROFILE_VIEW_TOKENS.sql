-- PP_PROFILE_VIEW_TOKENS: token-level anomaly profiler, runs entirely in Snowflake.
--
-- Takes any fully-qualified view/table name, profiles every column across ALL rows (NON_NULL,
-- DISTINCT count, NULL count, blank count, zero count), and flags columns that look suspicious:
--   SINGLE-VALUE   — every row has the same value (dead field, or an intentionally hardcoded tag)
--   MOSTLY-MISSING — >=90% NULL+blank
--   MOSTLY-ZERO    — >=90% of rows are '0'/'0.00'
--
-- A flag is a starting point for investigation, not proof of a bug — always check the source
-- table before concluding a fix is needed. Confirmed on PER_COM_PAYLOAD 2026-07-15: some flagged
-- columns turned out to be genuine sparse source data (MARKETVALUEDESCRIPTION, PMCLMINCD/PMCLMCNT
-- — claims exist but for a different policy term than the one in scope), not conversion defects.
--
-- Usage:
--   CALL AGGNE.DEV.PP_PROFILE_VIEW_TOKENS('AGGNE.DEV.PER_COM_PAYLOAD');
--   SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE FLAG <> '' ORDER BY TOKEN;

CREATE OR REPLACE PROCEDURE AGGNE.DEV.PP_PROFILE_VIEW_TOKENS(P_VIEW VARCHAR)
RETURNS TABLE (
    TOKEN         VARCHAR,
    TOTAL_ROWS    NUMBER,
    NON_NULL      NUMBER,
    DISTINCT_VALS NUMBER,
    NULL_CNT      NUMBER,
    BLANK_CNT     NUMBER,
    ZERO_CNT      NUMBER,
    MISSING_PCT   NUMBER(5,1),
    FLAG          VARCHAR
)
LANGUAGE SQL
AS
$$
DECLARE
    v_db      VARCHAR DEFAULT UPPER(SPLIT_PART(:P_VIEW, '.', 1));
    v_schema  VARCHAR DEFAULT UPPER(SPLIT_PART(:P_VIEW, '.', 2));
    v_table   VARCHAR DEFAULT UPPER(SPLIT_PART(:P_VIEW, '.', 3));
    v_total   NUMBER;
    v_sql     VARCHAR DEFAULT '';
    v_first   BOOLEAN DEFAULT TRUE;
    col_cursor CURSOR FOR
        SELECT column_name
        FROM information_schema.columns
        WHERE table_catalog = :v_db AND table_schema = :v_schema AND table_name = :v_table
        ORDER BY ordinal_position;
    res RESULTSET;
BEGIN
    SELECT COUNT(*) INTO :v_total FROM IDENTIFIER(:P_VIEW);

    FOR rec IN col_cursor DO
        IF (NOT v_first) THEN
            v_sql := v_sql || ' UNION ALL ';
        END IF;
        v_first := FALSE;
        v_sql := v_sql ||
            'SELECT ''' || rec.column_name || ''' AS TOKEN, ' ||
            'COUNT(' || rec.column_name || ') AS NON_NULL, ' ||
            'COUNT(DISTINCT ' || rec.column_name || ') AS DISTINCT_VALS, ' ||
            'SUM(CASE WHEN ' || rec.column_name || ' IS NULL THEN 1 ELSE 0 END) AS NULL_CNT, ' ||
            'SUM(CASE WHEN ' || rec.column_name || ' IS NOT NULL AND TRIM(CAST(' || rec.column_name || ' AS VARCHAR)) = '''' THEN 1 ELSE 0 END) AS BLANK_CNT, ' ||
            'SUM(CASE WHEN CAST(' || rec.column_name || ' AS VARCHAR) IN (''0'',''0.00'') THEN 1 ELSE 0 END) AS ZERO_CNT ' ||
            'FROM ' || :P_VIEW;
    END FOR;

    v_sql :=
        'WITH PROFILE AS (' || v_sql || ') ' ||
        'SELECT TOKEN, ' || :v_total || ' AS TOTAL_ROWS, NON_NULL, DISTINCT_VALS, NULL_CNT, BLANK_CNT, ZERO_CNT, ' ||
        'ROUND((NULL_CNT + BLANK_CNT) / NULLIF(' || :v_total || ',0) * 100, 1) AS MISSING_PCT, ' ||
        'ARRAY_TO_STRING(ARRAY_CONSTRUCT_COMPACT(' ||
            'CASE WHEN DISTINCT_VALS <= 1 THEN ''SINGLE-VALUE'' END, ' ||
            'CASE WHEN (NULL_CNT + BLANK_CNT) / NULLIF(' || :v_total || ',0) * 100 >= 90 THEN ''MOSTLY-MISSING'' END, ' ||
            'CASE WHEN ZERO_CNT / NULLIF(' || :v_total || ',0) >= 0.90 THEN ''MOSTLY-ZERO'' END' ||
        '), '','') AS FLAG ' ||
        'FROM PROFILE ORDER BY TOKEN';

    res := (EXECUTE IMMEDIATE :v_sql);
    RETURN TABLE(res);
END;
$$;
