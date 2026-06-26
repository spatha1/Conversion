create or replace view FLEET_VEHICLE_MAIN_VIEW(
	PUREPOLICYNUMBER,
	FLEETTYPE,
	PROTECTIONTYPE,
	RESTRICTIONOFDRIVERAGE,
	VOLUNTARYEXCESS,
	VEHICLE_COV_XML,
	ARECONTEMPDRIVER,
	DELIVERDANGEROUSGOOD,
	YEARSEXPERIENCEDELIVERY,
	RIDESHARE,
	PERCFLRIDESHARE,
	CONTRACTRESTRICTION,
	HIREVEHDRIVERSUPPLIED,
	YEARSEXPERIENCEHIRE,
	TAXIREGISTRATION,
	OWNOTHERBUS,
	IDLEVEHSTORED,
	DETAILS_LOCRISKMIT,
	FL_MOTOR_EXCESS,
	FL_MOTOR_UW,
	FL_MOTOR_CLAUSES,
	ONHOOK,
	UNLIMITEDGLASS,
	CARHIRE,
	CHOICEOFREPAIR,
	HIGHESTRISKUSE
) as WITH fleet_table as (
    select
        CAST(
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
        ) AS PUREPOLICYNUMBER,
        cmlnumber,
        purepolicynumber AS legacypolicynumber,
        expiringid_p,
        'FleetVehicle' as Type,
        'Fleet' as FleetType,
        CASE
            WHEN TRIM(PROTECTIONTYPE) = 'Third Party, Fire and Theft' THEN 'ThirdPartyFireandTheft'
            WHEN TRIM(PROTECTIONTYPE) = 'Comprehensive' THEN 'Comprehensive'
            WHEN TRIM(PROTECTIONTYPE) = 'Third Party Only' THEN 'ThirdPartyOnly'
            ELSE PROTECTIONTYPE
        end as PROTECTIONTYPE,
        NVL(CAST(registrationstate AS VARCHAR), '') AS registrationstate,
        NVL(CAST(year AS VARCHAR), '') AS year,
        NVL(CAST(make AS VARCHAR), '') AS make,
        NVL(CAST(model AS VARCHAR), '') AS model,
        NVL(CAST(registrationnumber AS VARCHAR), '') AS registrationnumber,
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
          CASE
            WHEN TRIM(RestrictionOfDriverAge) = 'No Restriction' THEN 0
            WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 21' THEN 20
            WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 25' THEN 24
            WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 30' THEN 29
            WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 40' THEN 39
            ELSE NULL -- or a default code, e.g., -1
        END ::varchar as RESTRICTIONOFDRIVERAGE,
        CAST(ARECONTEMPDRIVER AS VARCHAR) AS ARECONTEMPDRIVER,
        CAST(DELIVERDANGEROUSGOOD AS VARCHAR) AS DELIVERDANGEROUSGOOD,
        CAST(YEARSEXPERIENCEDELIVERY AS VARCHAR) AS YEARSEXPERIENCEDELIVERY,
        CAST(RIDESHARE AS VARCHAR) AS RIDESHARE,
        CAST(PERCFLRIDESHARE AS VARCHAR) AS PERCFLRIDESHARE,
        CAST(CONTRACTRESTRICTION AS VARCHAR) AS CONTRACTRESTRICTION,
        CAST(HIREVEHDRIVERSUPPLIED AS VARCHAR) AS HIREVEHDRIVERSUPPLIED,
        CAST(YEARSEXPERIENCEHIRE AS VARCHAR) AS YEARSEXPERIENCEHIRE,
        CAST(TAXIREGISTRATION AS VARCHAR) AS TAXIREGISTRATION,
        CAST(OWNOTHERBUS AS VARCHAR) AS OWNOTHERBUS,
        CAST(IDLEVEHSTORED AS VARCHAR) AS IDLEVEHSTORED,
        CAST(DETAILS_LOCRISKMIT AS VARCHAR) AS DETAILS_LOCRISKMIT,
        CAST(ONHOOK AS VARCHAR) AS ONHOOK,
        CAST(
            CASE
                WHEN UNLIMITEDGLASS = 'Protected' THEN '1'
                ELSE '0'
            END AS VARCHAR
        ) AS UNLIMITEDGLASS,
        CAST(
            CASE
                WHEN CARHIRE = 'Taken' THEN '1'
                ELSE '0'
            END AS VARCHAR
        ) AS CARHIRE,
        CAST(
            CASE
                WHEN CHOICEOFREPAIR = 'Taken' THEN '1'
                ELSE '0'
            END AS VARCHAR
        ) AS CHOICEOFREPAIR
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
),
vehicle_xml as (
    select
        id,
        LISTAGG(payload, '') WITHIN GROUP (
            ORDER BY
                id
        ) AS vehicle_cov_xml
    from
        AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET
    where
        itr_type = 'BP_Fleet_Vehicle_coverage'
    group by
        id
),
FL_MOTOR_CLAUSES AS (
    SELECT
        id,
        LISTAGG(payload, '') WITHIN GROUP (
            ORDER BY
                id
        ) AS FL_MOTOR_CLAUSES
    FROM
        AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET
    WHERE
        itr_type = 'BP_FL_Motor_Clauses'
    GROUP BY
        id
),
FL_MOTOR_UW AS (
    SELECT
        id,
        LISTAGG(payload, '') WITHIN GROUP (
            ORDER BY
                id
        ) AS FL_MOTOR_UW
    FROM
        AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET
    WHERE
        itr_type = 'BP_FL_Motor_UW'
    GROUP BY
        id
),
FL_MOTOR_EXCESS AS (
    SELECT
        id,
        LISTAGG(payload, '') WITHIN GROUP (
            ORDER BY
                id
        ) AS FL_MOTOR_EXCESS
    FROM
        AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET
    WHERE
        itr_type = 'BP_FL_Motor_Excess'
    GROUP BY
        id
)
select
    t1.PUREPOLICYNUMBER,
    FleetType,
    PROTECTIONTYPE,
    restrictionofdriverage,
    voluntaryexcess,
    vehicle_cov_xml,
    ARECONTEMPDRIVER,
    DELIVERDANGEROUSGOOD,
    YEARSEXPERIENCEDELIVERY,
    RIDESHARE,
    PERCFLRIDESHARE,
    CONTRACTRESTRICTION,
    HIREVEHDRIVERSUPPLIED,
    YEARSEXPERIENCEHIRE,
    TAXIREGISTRATION,
    OWNOTHERBUS,
    IDLEVEHSTORED,
    DETAILS_LOCRISKMIT,
    b.FL_MOTOR_EXCESS,
    d.FL_MOTOR_UW,
    c.FL_MOTOR_CLAUSES,
    ONHOOK,
    UNLIMITEDGLASS,
    CARHIRE,
    CHOICEOFREPAIR,
    T1.HIGHESTRISKUSE
from
    fleet_table t1
    left join vehicle_xml t2 on t1.PUREPOLICYNUMBER = t2.id
    LEFT JOIN FL_MOTOR_CLAUSES c ON t1.PUREPOLICYNUMBER = c.ID
    LEFT JOIN FL_MOTOR_EXCESS b ON t1.PUREPOLICYNUMBER = b.ID
    LEFT JOIN FL_MOTOR_UW d ON t1.PUREPOLICYNUMBER = d.ID;