create or replace view FLEET_VEHICLE_MAIN_VIEW_POLICYATTACH(
	PUREPOLICYNUMBER,
	VEHICLE_ID_POLICYNUBER,
	ACTUALID,
	LEGACYPOLICYNUMBER,
	REGISTRATIONNUMBER,
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
	HIGHESTRISKUSE,
	AGEOFYOUNGESTREGULARDRIVER
) as 
WITH fleet_table as (
    select
        -- CAST(
        --     TRIM(PUREPOLICYNUMBER) || '|' || TRIM(CMLNUMBER) || '|' || TRIM(EXPIRINGID_P) || '|' || TRIM(insurance_file_cnt) || '|' || TRIM(VEHICLEID) AS VARCHAR
        -- ) AS PUREPOLICYNUMBER,
        CAST(
            TRIM(ID) || '|' || NVL(TRIM(registrationnumber),'Unknown') AS VARCHAR
        ) AS VEHICLE_ID_POLICYNUBER,
        ID AS WITHOUT_VEHID_PUREPOLICYNUMBER,
        ACTUALID,
        PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        INSURANCE_FILE_CNT,
        'FleetVehicle' as Type,
        'Fleet' as FleetType,
        CASE
            WHEN TRIM(PROTECTIONTYPE) = 'Third Party, Fire and Theft' THEN 'ThirdPartyFireandTheft'
            WHEN TRIM(PROTECTIONTYPE) = 'Comprehensive' THEN 'Comprehensive'
            WHEN TRIM(PROTECTIONTYPE) = 'Third Party Only' THEN 'ThirdPartyOnly'
            ELSE PROTECTIONTYPE
        end as PROTECTIONTYPE,
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
          CASE
            WHEN TRIM(RestrictionOfDriverAge) = 'No Restriction' THEN cast(0 as varchar)
            WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 21' THEN cast(20 as varchar)
            WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 25' THEN cast(24 as varchar)
            WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 30' THEN cast(29 as varchar)
            WHEN TRIM(RestrictionOfDriverAge) = 'Min Age 40' THEN cast(39 as varchar)
            ELSE NULL -- or a default code, e.g., -1
        END as RESTRICTIONOFDRIVERAGE,
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
        CAST ('0' AS VARCHAR) AS AGEOFYOUNGESTREGULARDRIVER,
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
        AGGNE.PRD.VEHICLECOVERAGES_FLEETVEHICLE_POLICYATTACH_IDENTIFIER 
),--782,509.00           
vehicle_xml as (
    select
        id,
        LISTAGG(payload, '') WITHIN GROUP (
            ORDER BY
                id
        ) AS vehicle_cov_xml
    from
        AGGNE.PRD.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH
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
        AGGNE.PRD.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH
    WHERE
        itr_type = 'BP_FL_MOTOR_EXCESS'
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
        AGGNE.PRD.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH
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
        AGGNE.PRD.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH
    WHERE
        itr_type = 'BP_FL_Motor_Clauses'
    GROUP BY
        id
)
select
 WITHOUT_VEHID_PUREPOLICYNUMBER as PUREPOLICYNUMBER,
    VEHICLE_ID_POLICYNUBER,
    ACTUALID,
    LEGACYPOLICYNUMBER,
    registrationnumber,
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
    T1.HIGHESTRISKUSE,
    AGEOFYOUNGESTREGULARDRIVER  --WE DNT AHVE THIS FIELD IN SOURCE HENCE GIVING VALUE WITH 0
from
    fleet_table t1
    left join vehicle_xml t2 on t1.VEHICLE_ID_POLICYNUBER = t2.id
    LEFT JOIN FL_MOTOR_CLAUSES c ON t1.VEHICLE_ID_POLICYNUBER = c.ID
    LEFT JOIN FL_MOTOR_EXCESS b ON t1.VEHICLE_ID_POLICYNUBER = b.ID
    LEFT JOIN FL_MOTOR_UW d ON t1.VEHICLE_ID_POLICYNUBER = d.ID;