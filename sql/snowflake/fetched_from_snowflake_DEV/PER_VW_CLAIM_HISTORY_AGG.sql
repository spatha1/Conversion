create or replace view PER_VW_CLAIM_HISTORY_AGG(
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
FROM AGGNE.DEV.PER_CLAIM_HISTORY_TARGET
GROUP BY id, itr_type,CAST(LOAD_DATE AS DATE);