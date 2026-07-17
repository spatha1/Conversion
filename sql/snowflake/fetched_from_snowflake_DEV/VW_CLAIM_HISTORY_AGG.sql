create or replace view VW_CLAIM_HISTORY_AGG(
	ID,
	ITR_TYPE,
	PAYLOAD,
	LOAD_DATE
) as
SELECT
    id,
    itr_type,
    LISTAGG(payload, '\n') WITHIN GROUP (ORDER BY load_date) AS payload,
    load_date
FROM AGGNE.DEV.CLAIM_HISTORY_TARGET
GROUP BY id, itr_type,load_date;