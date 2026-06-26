create or replace view CV_COVERAGE_VEHICLE_COV_POLICYATTACH(
	PUREPOLICYNUMBER,
	ID,
	TYPE,
	MARKETVALUEWITHACCESSORIESAMOUNT,
	SUBCOV_XML,
	VEHICLEID,
	EXPIRYDATE,
	CMEXPPREM,
	CMNOVEHS,
	CMCLMCNT,
	CMCLMINCD
) as
with cv_table as (
    select
        CAST(
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
        ) AS PUREPOLICYNUMBER_CONV,
        CAST(TRIM(ID) || '|' || TRIM(vehicleid) AS VARCHAR ) AS PUREPOLICYNUMBER_Vehicle,
        ID AS PUREPOLICYNUMBER,
        cmlnumber,
        purepolicynumber AS legacypolicynumber,
        expiringid_p,
        vehicleid,
        'CommercialVehicle' as Type,
        'Default' as FleetType,
        CAST(CMCVAGREEDVALUE AS VARCHAR) as marketvaluewithaccessoriesamount
    from
        AGGNE.PRD.CM_03_Policyattach_IDENTIFIER
),
cv_coverage_xml as (
       SELECT
        ID,
        LISTAGG(PAYLOAD, '') WITHIN GROUP (ORDER BY ID) AS SUBCOV_XML
    FROM AGGNE.PRD.CV_FLEET_VEHICLE_TARGET_POLICYATTACH
    WHERE ITR_TYPE = 'BP_CV_Vehicle_SubCov'
    GROUP BY ID
),
Coverage_vehicle_xml as (
SELECT distinct 
    T1.ID,
    T2.PUREPOLICYNUMBER_ACTUAL,
    T1.SUBCOV_XML
FROM cv_coverage_xml t1 
INNER JOIN AGGNE.PRD.CV_COVERAGE_VEHICLE_SUBCOV_POLICYATTACH T2
    ON T1.ID = T2.PUREPOLICYNUMBER
)
select distinct 
    t1.PUREPOLICYNUMBER_Vehicle as PUREPOLICYNUMBER,
    t2.ID,
    Type,
    CAST(CAST(COALESCE(marketvaluewithaccessoriesamount ,0) AS NUMBER(36,3))AS VARCHAR) AS marketvaluewithaccessoriesamount,
    CAST(subcov_xml AS VARCHAR) AS subcov_xml,
    CAST(vehicleid AS VARCHAR) AS vehicleid,
    CAST(expirydate AS VARCHAR) AS expirydate,
    CAST(cmexpprem AS VARCHAR) AS cmexpprem,
    CAST(cmnovehs AS VARCHAR) AS cmnovehs,
    CAST(cmclmcnt AS VARCHAR) AS cmclmcnt,
    CAST(cmclmincd AS VARCHAR) AS cmclmincd
from
    cv_table t1
    left join Coverage_vehicle_xml t2 on  t1.PUREPOLICYNUMBER_Vehicle=t2.id
    left join AGGNE.PRD.VW_OUTPUT_COVERAGE_BSP_policyattach t3 on trim(t1.PUREPOLICYNUMBER_CONV) = trim(t3.PUREPOLICYNUMBER)
    where subcov_xml is not null;