create or replace view ACCOUNT_LOC_AGG(
	PUREPOLICYNUMBER,
	AOI,
	LOAD_DATE
) as 

WITH cte1 AS (
    SELECT
        DISTINCT SPLIT_PART(TRIM(ID), '|', 1) AS PUREPOLICYNUMBER,
        SPLIT_PART(TRIM(ID), '|', 3) AS EXPIRYID,
        *
        --,PARSE_XML(REGEXP_REPLACE(PAYLOAD, '(&)', '&amp;'))
        ,GET(
            XMLGET(
                PARSE_XML(REGEXP_REPLACE(PAYLOAD, '(&)', '&amp;')),
                'Number'
            ),
            '$'
        )::string AS RiskNumber
    FROM
        AGGNE.DEV.ACCOUNT_LOC_TARGET
    WHERE
        ITR_TYPE = 'BP_ACC_LOC'
        
)
SELECT
    t1.PUREPOLICYNUMBER,
    LISTAGG(t1.payload, '\n') WITHIN GROUP (
        ORDER BY
            t1.RISKNUMBER
    ) AS AOI,
    t1.LOAD_DATE
FROM
    cte1 t1
    
GROUP BY
    t1.PUREPOLICYNUMBER,
    t1.LOAD_DATE 
    /*removed old code by Raju */
-- WITH cte1 AS (
--   SELECT DISTINCT
--          SPLIT_PART(TRIM(ID), '|', 1) AS PUREPOLICYNUMBER,SPLIT_PART(TRIM(ID), '|', 3) AS EXPIRYID,
--          *
--   FROM AGGNE.DEV.ACCOUNT_LOC_TARGET
--   WHERE  ITR_TYPE = 'BP_ACC_LOC'
-- ),
-- acc AS (
--   SELECT DISTINCT
--          SPLIT_PART(TRIM(PUREPOLICYNUMBER), '|', 3) AS EXPIRYID,
--          *
--   FROM AGGNE.DEV.ACCOUNT_LOC
-- )
-- SELECT
--   t1.PUREPOLICYNUMBER,
--   LISTAGG(t1.payload, '\n') WITHIN GROUP (ORDER BY a.RISKNUMBER) AS AOI,
--   t1.LOAD_DATE
-- FROM cte1 t1
-- JOIN acc a
--   ON TRIM(a.LEGACYPOLICYNUMBER) = TRIM(t1.PUREPOLICYNUMBER) and a.EXPIRYID=T1.EXPIRYID
-- GROUP BY t1.PUREPOLICYNUMBER, t1.LOAD_DATE
-- ORDER BY t1.PUREPOLICYNUMBER, t1.LOAD_DATE;
/*removed old code by Raju */
;