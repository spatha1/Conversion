create or replace view VW_FLEET_VEHICLE_AGG(
	ID,
	ITR_TYPE,
	LOAD_DATE,
	AGGREGATED_PAYLOAD
) as
SELECT
    id,
    itr_type,
    load_date,
    LISTAGG(payload, ', ') WITHIN GROUP (ORDER BY load_date) AS aggregated_payload
FROM AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
WHERE itr_type = 'CV_Vehicle_main'
GROUP BY id, itr_type, load_date;