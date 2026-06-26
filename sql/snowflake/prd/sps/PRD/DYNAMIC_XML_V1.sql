-- SP: AGGNE.PRD.DYNAMIC_XML_V1
-- Signature: (SOURCETABLE VARCHAR, PAYLOAD VARCHAR, TARGETTABLE VARCHAR, ITR_TYPE VARCHAR)
-- Language:  SQL
-- Collected: 2026-06-25


DECLARE
    v_template STRING;
    v_sql STRING;
    v_audit_sql STRING;
    v_replacement_expr STRING;
    v_process STRING;
BEGIN
    -- Truncate the target table
    --EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || :TargetTable;

    

    -- Build nested REPLACE() calls using LISTAGG
    SELECT 
        LISTAGG(
            'REPLACE(',
            ''
        ) || '''' || :Payload || '''' || 
        LISTAGG(
            ', ''{' || column_name || '}'', IFNULL(' || column_name || ', ''''))',
            ''
        )
    INTO v_replacement_expr
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_name = SPLIT_PART(:SourceTable, '.', 3)
      AND table_schema = SPLIT_PART(:SourceTable, '.', 2)
      AND table_catalog = SPLIT_PART(:SourceTable, '.', 1)
    ORDER BY ordinal_position;

    -- Construct the final SQL statement
    v_sql := 'INSERT INTO ' || :TargetTable || 
             ' (ID,ITR_TYPE, PAYLOAD,LOAD_DATE) ' ||
             'SELECT DISTINCT PUREPOLICYNUMBER,  ''' || :ITR_TYPE || ''',' || v_replacement_expr || 
             ',GETDATE() FROM ' || :SourceTable;

    -- Execute the dynamic SQL
    EXECUTE IMMEDIATE  v_sql;

      -- Construct the final SQL statement

   v_process := 'DYNAMIC_XML_V1';

    -- Write audit row
  v_audit_sql := 'INSERT INTO AGGNE.PRD.LOAD_AUDIT_LOG
                  (PROCESS_NAME, SOUREC_TABLE_NAME, TARGET_TABLE_NAME, TARGET_RECORD_COUNT, LOAD_DATE)
                  SELECT '
                  || CHR(39) || ITR_TYPE || CHR(39) || ', '
                  || CHR(39) || SOURCETABLE || CHR(39) || ', '
                  || CHR(39) || TARGETTABLE || CHR(39) || ', COUNT(*), CURRENT_TIMESTAMP()
                  FROM ' || TARGETTABLE;

  EXECUTE IMMEDIATE v_audit_sql;



    RETURN 'XML script generation and insertion completed.';
END;
