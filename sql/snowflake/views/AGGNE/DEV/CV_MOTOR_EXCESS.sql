create or replace view CV_MOTOR_EXCESS(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	LEGACYPOLICYNUMBER,
	EXPIRINGID_P,
	VEHICLEID,
	TYPE,
	FLEETTYPE,
	VOLUNTARYEXCESS
) as
select CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P)||'|' || TRIM(VEHICLEID) AS VARCHAR) AS PUREPOLICYNUMBER,cmlnumber, purepolicynumber AS legacypolicynumber, expiringid_p, CAST(vehicleid AS VARCHAR) AS vehicleid,'CommercialVehicle' as Type, 'Default' as FleetType,CAST(CAST(CMCVVOLUNTARY AS INT) AS VARCHAR) AS VOLUNTARYEXCESS from AGGNE.DEV.cm_03;