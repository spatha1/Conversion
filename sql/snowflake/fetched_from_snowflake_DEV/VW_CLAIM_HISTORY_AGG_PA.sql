create or replace view VW_CLAIM_HISTORY_AGG_PA(
	ID,
	ITR_TYPE,
	PAYLOAD,
	LOAD_DATE
) as
SELECT
    id,
    itr_type,
    LISTAGG(payload, '\n') WITHIN GROUP (ORDER BY load_date) AS payload,
   CAST(LOAD_DATE AS DATE)
FROM AGGNE.DEV.PA_CLAIM_HISTORY_TARGET
GROUP BY id, itr_type,CAST(LOAD_DATE AS DATE);