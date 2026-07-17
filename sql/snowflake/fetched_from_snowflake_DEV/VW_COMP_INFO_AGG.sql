create or replace view VW_COMP_INFO_AGG(
	ID,
	ITR_TYPE,
	PAYLOAD,
	LOAD_DATE
) as
SELECT DISTINCT 
    id,
    itr_type,
    LISTAGG(payload, '\n') WITHIN GROUP (ORDER BY load_date) AS payload,
    load_date
FROM AGGNE.DEV.COMPETITOR_INFORMATION_TARGET
GROUP BY id, itr_type,load_date;