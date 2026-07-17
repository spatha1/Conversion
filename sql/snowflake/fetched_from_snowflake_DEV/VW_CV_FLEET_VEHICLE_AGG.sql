create or replace view VW_CV_FLEET_VEHICLE_AGG(
	ID,
	ITR_TYPE,
	LOAD_DATE,
	AGGREGATED_PAYLOAD
) as
SELECT
    id,
    itr_type,
    MAX(load_date) AS load_date,
    LISTAGG(payload) WITHIN GROUP (ORDER BY payload) AS aggregated_payload
FROM (
    SELECT *
    FROM AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
    WHERE itr_type = 'CV_Vehicle_main'
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY id, itr_type
        ORDER BY load_date DESC
    ) = 1
)
GROUP BY id, itr_type;