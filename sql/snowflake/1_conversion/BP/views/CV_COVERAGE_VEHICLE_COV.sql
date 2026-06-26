create or replace view CV_COVERAGE_VEHICLE_COV(
	PUREPOLICYNUMBER,
	TYPE,
	MARKETVALUEWITHACCESSORIESAMOUNT,
	SUBCOV_XML,
	CLAIMNUMBER,
	EXPIRYDATE,
	CMEXPPREM,
	CMNOVEHS,
	CMCLMCNT,
	CMCLMINCD
) as 
with cv_table as (select distinct CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER
,cmlnumber, purepolicynumber AS legacypolicynumber, expiringid_p, vehicleid,'CommercialVehicle' as Type, 'Default' as FleetType,CAST(CMCVAGREEDVALUE AS VARCHAR) as marketvaluewithaccessoriesamount from AGGNE.DEV.cm_03),
cv_coverage_xml as (select id, LISTAGG(payload,'') WITHIN GROUP (ORDER BY id) AS subcov_xml from AGGNE.DEV.CV_FLEET_VEHICLE_TARGET
where itr_type = 'BP_CV_Vehicle_SubCov'
group by id)
select distinct t1.PUREPOLICYNUMBER,Type,
marketvaluewithaccessoriesamount,
subcov_xml,TRIM(t1.CMLNUMBER) as claimnumber,CAST(expirydate AS VARCHAR) AS expirydate,
CAST(cmexpprem AS VARCHAR) AS cmexpprem,
CAST(cmnovehs AS VARCHAR) AS cmnovehs,
CAST(cmclmcnt AS VARCHAR) AS cmclmcnt,
CAST(cmclmincd AS VARCHAR)  AS cmclmincd
from 
cv_table t1 left join cv_coverage_xml t2
on trim(t1.PUREPOLICYNUMBER) = trim(t2.id)
left join AGGNE.DEV.VW_OUTPUT_COVERAGE_BSP t3
on trim(t1.PUREPOLICYNUMBER) = trim(t3.purepolicynumber);