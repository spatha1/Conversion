create or replace view FLEET_VEHICLE_VIEW_POLICYATTACH(
	PUREPOLICYNUMBER,
	ID,
	REGISTRATIONSTATE,
	YEAR,
	MAKE,
	MODEL,
	REGISTRATIONNUMBER,
	VEHICLEDESCRIPTION,
	HIGHESTRISKUSE,
	ACCESSORIESDESCRIPTION,
	ACCESSORIESVALUE_FLEET,
	DESCRIPTION,
	BODYTYPE,
	ENGINESIZE,
	NUMBEROFCYLINDERS,
	INDUCTIONTYPE,
	GROSSVEHICLEMASS,
	ADDACCESSORIES,
	FVEXPPREM,
	FVCLMCNT,
	FVCLMINCD,
	SUBCOV_XML,
	HAVEINTERESTEDPARTY,
	ADDITONALPARTY
) as
WITH fleet_table as (
    select
        CAST(
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
        ) AS PUREPOLICYNUMBER_COV,
        ID AS PUREPOLICYNUMBER,
        CAST(TRIM(ID) || '|' || NVL(TRIM(registrationnumber),'Unknown') AS VARCHAR ) AS PUREPOLICYNUMBER_Vehicle,
        cmlnumber,
        purepolicynumber AS legacypolicynumber,
        expiringid_p,
        'FleetVehicle' as Type,
        'Fleet' as FleetType,
        NVL(CAST(registrationstate AS VARCHAR), '') AS registrationstate,
        NVL(CAST(year AS VARCHAR), '1800') AS year,
        NVL(CAST(make AS VARCHAR), 'Unknown') AS make,
        NVL(CAST(model AS VARCHAR), 'Unknown') AS model,
        NVL(CAST(registrationnumber AS VARCHAR), 'Unknown') AS registrationnumber,
        NVL(
            CAST(
                CONCAT(description, ' ', make, ' ', year) AS VARCHAR
            ),
            ''
        ) AS VehicleDescription,
        NVL(CAST(highestriskuse AS VARCHAR), '') AS highestriskuse,
        NVL(CAST(accessoriesdescription AS VARCHAR), '') AS accessoriesdescription,
        NVL(CAST(accessoriesvalue AS VARCHAR), '') AS accessoriesvalue_fleet,
        NVL(CAST(description AS VARCHAR), '') AS description,
        NVL(CAST(bodytype AS VARCHAR), '') AS bodytype,
        NVL(CAST(enginesize AS VARCHAR), '') AS enginesize,
        NVL(CAST(numberofcylinders AS VARCHAR), '') AS numberofcylinders,
        NVL(CAST(inductiontype AS VARCHAR), '') AS inductiontype,
        NVL(CAST(grossvehiclemass AS VARCHAR), '') AS grossvehiclemass,
        NVL(CAST(addaccessories AS VARCHAR), '') AS addaccessories,
        NVL(CAST(accessoriesvalue AS VARCHAR), '') AS accessoriesvalue,
        NVL(CAST(voluntaryexcess AS VARCHAR), '') AS voluntaryexcess,
        NVL(CAST(restrictionofdriverage AS VARCHAR), '') AS restrictionofdriverage,
        NVL(CAST(haveinterestedparty AS VARCHAR), '') AS haveinterestedparty,
        NVL(CAST(additonalparty AS VARCHAR), '') AS additonalparty
    from
        AGGNE.PRD.VEHICLECOVERAGES_FLEETVEHICLE_POLICYATTACH_IDENTIFIER
),
coverage_xml as (
    select
        id,
        LISTAGG(payload, '') WITHIN GROUP (
            ORDER BY
                id
        ) AS subcov_xml
    from
        AGGNE.PRD.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH
    where
        itr_type = 'BP_fleet_coverage_Vehicle_SubCov'
    group by
        id
),
exp_prem as (
    select
        CAST(
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
        ) AS PUREPOLICYNUMBER,
        NVL(CAST(fvexpprem AS VARCHAR), '') AS FVEXPPREM,
        NVL(CAST(fvclmcnt AS VARCHAR), '') AS FVCLMCNT,
        NVL(CAST(fvclmincd AS VARCHAR), '') AS FVCLMINCD
    from
        AGGNE.PRD.VW_OUTPUT_COVERAGE_BSP_policyattach
)
select
     t1.PUREPOLICYNUMBER_Vehicle as PUREPOLICYNUMBER,
    t2.ID,
    registrationstate,
    year,
    make,
    model,
    registrationnumber,
    VehicleDescription,case
        when trim(highestriskuse) = 'General Business' then 'Business'
        when trim(highestriskuse) = 'Hire' then 'Hire'
        when trim(highestriskuse) = 'Courtesy' then 'Courtesy'
        when trim(highestriskuse) = 'Delivery' then 'Delivery'
        else ''
    end as highestriskuse,
    accessoriesdescription,
    accessoriesvalue_fleet,
    description,
    bodytype,
    enginesize,
    numberofcylinders,
    inductiontype,
    grossvehiclemass,case
        when trim(addaccessories) = 'true' then '1'
        else '0'
    end as addaccessories,
    fvexpprem,
    fvclmcnt,
    fvclmincd,
    subcov_xml,case
        when haveinterestedparty = 'Yes' then '1'
        else '0'
    end as haveinterestedparty,
    additonalparty
from
    fleet_table t1
    left join coverage_xml t2 on t1.PUREPOLICYNUMBER_VEHICLE = t2.id
    left join exp_prem t3 on TRIM(t1.PUREPOLICYNUMBER_COV) = TRIM(t3.PUREPOLICYNUMBER);