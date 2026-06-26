CREATE OR REPLACE PROCEDURE "DYNAMIC_XML_GENERATOR"("SOURCETABLE" VARCHAR, "PAYLOAD" VARCHAR, "TARGETTABLE" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE
    v_template STRING;
    v_sql STRING;
    v_replacement_expr STRING;
BEGIN
    -- Truncate the target table
    EXECUTE IMMEDIATE ''TRUNCATE TABLE '' || :TargetTable;

    

    -- Build nested REPLACE() calls using LISTAGG
    SELECT 
        LISTAGG(
            ''REPLACE('',
            ''''
        ) || '''''''' || :Payload || '''''''' || 
        LISTAGG(
            '', ''''{'' || column_name || ''}'''', IFNULL('' || column_name || '', ''''''''))'',
            ''''
        )
    INTO v_replacement_expr
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_name = SPLIT_PART(:SourceTable, ''.'', 3)
      AND table_schema = SPLIT_PART(:SourceTable, ''.'', 2)
      AND table_catalog = SPLIT_PART(:SourceTable, ''.'', 1)
    ORDER BY ordinal_position;

    -- Construct the final SQL statement
    v_sql := ''INSERT INTO '' || :TargetTable || 
             '' (ID, PAYLOAD,LOAD_DATE) '' ||
             ''SELECT DISTINCT PUREPOLICYNUMBER, '' || v_replacement_expr || 
             '',GETDATE() FROM '' || :SourceTable;

    -- Execute the dynamic SQL
    EXECUTE IMMEDIATE v_sql;

    RETURN ''XML script generation and insertion completed.'';
END;
';