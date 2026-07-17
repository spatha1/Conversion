create or replace view AOI_FINAL_AGG(
	PUREPOLICYNUMBER,
	AOI,
	LOAD_DATE
) as 
with cte1 as(
SELECT distinct SPLIT_PART(TRIM(ID), '|', 1)  AS PUREPOLICYNUMBER, * 
,GET(
            XMLGET(
                PARSE_XML( REGEXP_REPLACE(PAYLOAD, '(&)', '&amp;')),
                'LocationNumber'
            ),
            '$'
        )::string AS LocationNumber

FROM AGGNE.DEV.AOI_Target  
)
SELECT
  PUREPOLICYNUMBER,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_Policy_AOI' THEN payload END, '\n') WITHIN GROUP (
        ORDER BY
            LocationNumber
    )  AS AOI,
  CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM cte1
WHERE ITR_TYPE IN ('BP_Policy_AOI')
GROUP BY PUREPOLICYNUMBER,CAST(LOAD_DATE AS DATE);