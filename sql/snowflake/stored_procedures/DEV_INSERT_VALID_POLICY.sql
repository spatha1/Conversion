CREATE OR REPLACE PROCEDURE "INSERT_VALID_POLICY"("POLICYNUMBERS" VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '

DECLARE
  v_sql STRING;
BEGIN

TRUNCATE  TABLE AGGNE.DEV.POLICYATTACH_TO_PROCESS;

  WITH parts AS (
    SELECT TRIM(value) AS p
    FROM TABLE(SPLIT_TO_TABLE(:Policynumbers, '',''))
    WHERE NULLIF(TRIM(value), '''') IS NOT NULL
  ),
  vals AS (
    SELECT ''('''''' || p || '''''')'' AS piece
    FROM parts
  )
  SELECT ''INSERT INTO AGGNE.DEV.POLICYATTACH_TO_PROCESS  '' ||
         ''SELECT v.col FROM VALUES '' ||
         LISTAGG(piece, '','') || '' AS v(col)''
  INTO :v_sql
  FROM vals;

  EXECUTE IMMEDIATE :v_sql;

  RETURN ''Insert completed'';
END;
';