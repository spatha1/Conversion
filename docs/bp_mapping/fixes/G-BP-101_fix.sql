-- ============================================================================
-- G-BP-101: FLEET_VEHICLE_MAIN_VIEW emits one row per vehicle instead of one
--           row per fleet (regression introduced by the G-BP-88 fix)
-- ============================================================================
--
-- REPORTED BY CLIENT: H & H AVENUES PTY LTD, DC Quote Q0115189
--                      (PURE policy P00034478), Commercial Fleet Vehicle
--                      Details Summary screen. "It's supposed to retrieve
--                      only 1 row for this policy. It was ok before but now
--                      broken." Tested 15-JUL-2026, 1st September batch
--                      (14-JUL-2026).
--
-- LIVE EVIDENCE:
--   select count(*) from AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW
--   where PUREPOLICYNUMBER LIKE 'P00034478%';
--   -> 42 rows, all sharing the identical composite key
--      P00034478|CML00031966|2178799 (this fleet has 42 vehicles).
--   Expected: 1 row.
--
-- ROOT CAUSE:
--   This is a direct side effect of G-BP-88 (SEQ 56/57 key widening, applied
--   earlier this engagement to fix cross-vehicle XML contamination).
--
--   G-BP-88 widened AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET's key (SEQ 57) from
--   fleet-level (PUREPOLICYNUMBER|cmlnumber|EXPIRINGID_P) to vehicle-level
--   (...|REGISTRATIONNUMBER). That was the correct fix for SEQ 57 itself.
--
--   FLEET_VEHICLE_MAIN_VIEW's own vehicle_xml CTE reads that same target
--   table and does `GROUP BY id`. Before G-BP-88, id was fleet-level, so
--   this GROUP BY collapsed every vehicle's coverage payload into ONE row
--   per fleet. After G-BP-88, id is vehicle-level, so this same GROUP BY
--   now produces one row PER VEHICLE (42 rows for this fleet) instead of
--   one row per fleet.
--
--   At the time, G-BP-88 compensated by changing the join from an exact
--   match to a prefix match:
--       LEFT JOIN vehicle_xml t2 ON t2.id LIKE t1.PUREPOLICYNUMBER || '|%'
--   The comment on that change states the intent was "to keep aggregating
--   every vehicle under the fleet" -- but a LIKE prefix-match LEFT JOIN
--   does not aggregate; it fans out. t1 (fleet_table, confirmed still
--   correctly 1 row per fleet -- see its own header comment, 30 rows total)
--   gets matched against all 42 of vehicle_xml's now vehicle-level rows,
--   producing 42 output rows instead of 1.
--
--   fleet_table (t1) itself was NOT the problem -- verified via GET_DDL and
--   a live row-count check, it remains correctly fleet-level. The fan-out
--   is isolated entirely to vehicle_xml's GROUP BY + the compensating join.
--
-- FIX:
--   Re-aggregate vehicle_xml back down to one row per FLEET (not per
--   vehicle) before joining, by grouping a second time on the fleet-level
--   prefix of id (the first 3 pipe-delimited segments), concatenating all
--   vehicles' payloads into a single combined XML blob per fleet -- exactly
--   as this view produced before G-BP-88. Then revert the join to an exact
--   match, since both sides are fleet-level keys again.
--
-- VERIFIED LIVE (read-only simulation, not yet applied):
--   Corrected vehicle_xml re-aggregated to fleet_id 'P00034478|CML00031966|2178799'
--   -> 1 row, vehicle_count 42, combined XML length 121,959 chars (identical
--      total length to the raw 42-row concatenation -- confirms no data is
--      lost, only re-combined).
--   Corrected fleet_table JOIN vehicle_xml (exact match on fleet_id)
--   -> 1 row returned for P00034478, xml_len 121,959. Matches expected.
--
-- SCOPE: Every fleet policy is affected, not just P00034478 -- this is a
--        structural regression in the view, not a per-policy data issue.
--
-- STATUS: DRAFTED, NOT APPLIED. SAFE_MODE -- user must run this.
-- ============================================================================

create or replace view AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW(
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
    CHOICEOFREPAIR
) as
WITH fleet_table as (
    select
        CAST(
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
        ) AS PUREPOLICYNUMBER,
        -- UNCHANGED (correct-by-design): this stays fleet-level. Confirmed
        -- live this view is intentionally one row per fleet/location (30
        -- rows total), aggregating every vehicle underneath it -- not a
        -- per-vehicle view like SEQ 56/57.
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
        -- FIXED (G-BP-55, this view's own separate copy of the same bug):
        -- removed "where YEAR<>0 and MAKE<>'' and MODEL<>''".
),
vehicle_xml_raw as (
    -- G-BP-88's rendered rows are vehicle-keyed
    -- (policy|cml|expiringid_p|registrationnumber). This GROUP BY id is
    -- intentionally left at vehicle grain here -- the second CTE below
    -- (vehicle_xml) re-aggregates it back down to fleet grain.
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
vehicle_xml as (
    -- FIX (G-BP-101): re-aggregate vehicle_xml_raw's vehicle-level rows back
    -- down to ONE row per fleet, by grouping on the fleet-level prefix of id
    -- (the first 3 pipe-delimited segments: policy|cml|expiringid_p) and
    -- concatenating every vehicle's payload into a single combined XML blob.
    -- This restores the pre-G-BP-88 one-row-per-fleet behaviour of this
    -- view while keeping SEQ 57's own vehicle-level correctness intact.
    select
        SPLIT_PART(id, '|', 1) || '|' || SPLIT_PART(id, '|', 2) || '|' || SPLIT_PART(id, '|', 3) AS fleet_id,
        LISTAGG(vehicle_cov_xml, '') WITHIN GROUP (
            ORDER BY
                id
        ) AS vehicle_cov_xml
    from
        vehicle_xml_raw
    group by
        fleet_id
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
select distinct
    t1.PUREPOLICYNUMBER,
    FleetType,
    PROTECTIONTYPE,
    restrictionofdriverage,
    voluntaryexcess,
    vehicle_cov_xml,
    ARECONTEMPDRIVER,
    DELIVERDANGEROUSGOOD,
    YEARSEXPERIENCEDELIVERY,
   case when trim(upper(coalesce(RIDESHARE,'NO')))='NO' then '0'else '1' end RIDESHARE ,
    replace(coalesce(PERCFLRIDESHARE,'0'),'%','') PERCFLRIDESHARE,
    case when trim(upper(coalesce(CONTRACTRESTRICTION,'NO')))='NO' then '0'else '1' end CONTRACTRESTRICTION,
    case when trim(upper(coalesce(HIREVEHDRIVERSUPPLIED,'NO')))='NO' then '0'else '1' end HIREVEHDRIVERSUPPLIED,
    coalesce(YEARSEXPERIENCEHIRE,'0') YEARSEXPERIENCEHIRE,
   case when trim(upper(coalesce(TAXIREGISTRATION,'NO')))='NO' then '0'else '1' end TAXIREGISTRATION,
    case when trim(upper(coalesce(OWNOTHERBUS,'NO')))='NO' then '0'else '1' end OWNOTHERBUS,
case when trim(upper(coalesce(IDLEVEHSTORED,'NO')))='NO' then '0'else '1' end IDLEVEHSTORED,
    DETAILS_LOCRISKMIT,
    b.FL_MOTOR_EXCESS,
    d.FL_MOTOR_UW,
    c.FL_MOTOR_CLAUSES,
    ONHOOK,
    UNLIMITEDGLASS,
    CARHIRE,
    CHOICEOFREPAIR
from
    fleet_table t1
    -- FIX (G-BP-101): reverted to an exact match. Both sides are fleet-level
    -- keys again now that vehicle_xml is re-aggregated above, so the prefix
    -- match (which caused the 1-to-42 fan-out) is no longer needed.
    left join vehicle_xml t2 on t1.PUREPOLICYNUMBER = t2.fleet_id
    LEFT JOIN FL_MOTOR_CLAUSES c ON t1.PUREPOLICYNUMBER = c.ID
    LEFT JOIN FL_MOTOR_EXCESS b ON t1.PUREPOLICYNUMBER = b.ID
    LEFT JOIN FL_MOTOR_UW d ON t1.PUREPOLICYNUMBER = d.ID
    -- These three stay exact-match -- FL_MOTOR_EXCESS/CLAUSE/UW are
    -- correctly fleet-level (unchanged, see header note).
    ;
