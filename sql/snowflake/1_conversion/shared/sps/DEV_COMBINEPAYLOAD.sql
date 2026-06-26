CREATE OR REPLACE PROCEDURE "COMBINEPAYLOAD"("SOURCETABLE" VARCHAR, "HEADER" VARCHAR, "FOOTER" VARCHAR, "TARGETTABLE" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
DECLARE
    v_sql STRING;
BEGIN
    -- Truncate the target table
    EXECUTE IMMEDIATE ''TRUNCATE TABLE '' || :TARGETTABLE;

    -- Build dynamic SQL to insert combined payloads
    v_sql := ''
        INSERT INTO '' || :TARGETTABLE || '' (ID, COMBINED_PAYLOAD)
        SELECT 
            ID,
            '''''' || :HEADER || '''''' || LISTAGG(PAYLOAD, '''' '''') WITHIN GROUP (ORDER BY PAYLOAD) || '''''' || :FOOTER || '''''' AS COMBINED_PAYLOAD
        FROM '' || :SOURCETABLE || ''
        GROUP BY ID;
    '';

    -- Execute the dynamic SQL
    EXECUTE IMMEDIATE v_sql;

    RETURN ''Combined payload inserted successfully.'';
END;
';