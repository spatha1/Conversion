-- ============================================================================
-- G-BP-88 fix — Fleet per-vehicle sub-coverage cross-contamination
-- (combines G-BP-30 indicator fix + G-BP-55 filter fix + the key widening,
-- across all 3 views involved: FLEET_VEHICLE_SUBCOVERAGES, FLEET_VEHICLE_VIEW,
-- FLEET_VEHICLE_MAIN_VIEW)
-- ============================================================================
-- ROOT CAUSE: FLEET_VEHICLE_SUBCOVERAGES (SEQ 56) and FLEET_VEHICLE_VIEW
-- (SEQ 57) both key on PUREPOLICYNUMBER|cmlnumber|EXPIRINGID_P — a
-- location/term key, not a vehicle key. Confirmed live (2026-07-12):
-- 1,222 Fleet vehicles collapse to 52 distinct keys; one fleet has 54
-- vehicles sharing a single key. DYNAMIC_XML_V1 (the Snowflake procedure
-- that populates every *_TARGET table) does a literal
-- `SELECT DISTINCT PUREPOLICYNUMBER ... AS ID` from the source view — no
-- independent key logic, a straight passthrough — so RISK_FLEET_VEHICLE_TARGET.ID
-- inherits this same non-unique key, and FLEET_VEHICLE_VIEW's LISTAGG/JOIN
-- back onto that ID attaches the SAME sub-coverage payload to every vehicle
-- sharing the key. Verified: 5 different vehicles under one key (Honda
-- Accord, Toyota Caldina, Toyota Vitz, Honda Civic, Toyota Hiace) all
-- returned byte-identical SUBCOV_XML.
--
-- SCOPE IS NARROWER than first thought. FLEET_VEHICLE_MAIN_VIEW (SEQ 61,
-- the top-level <risk><Type>Motor</Type> node) was checked directly and
-- confirmed to be intentionally fleet-level (30 rows total, not 1,222 or
-- even 52) — it aggregates every vehicle under one risk node, which is the
-- correct design for a risk-level XML node. FL_MOTOR_EXCESS/CLAUSE/UW
-- (SEQ 58/59/60) feed SEQ 61 directly as fleet-wide attributes, and
-- VOLUNTARYEXCESS never varies within any of the 30 multi-vehicle fleets in
-- live data (0/30) — consistent with real Fleet policies using uniform
-- terms across the whole fleet. These are correct-by-design, NOT touched
-- here.
--
-- FIX: widen the composite key in SEQ 56/57 only, by appending
-- TRIM(COALESCE(REGISTRATIONNUMBER,'')) — confirmed live: this takes 52
-- distinct keys to 1,194 (vs. 1,222 total vehicles; 22 have blank
-- registration, same shape as G-BP-55's blank Make/Model, and 2 residual
-- duplicate-registration keys remain — both small, acceptable edge cases,
-- same class as the already-accepted G-BP-55 gap).
--
-- SEQ 61 (FLEET_VEHICLE_MAIN_VIEW) needs ONE change to stay compatible: its
-- own PUREPOLICYNUMBER stays fleet-level (unchanged, correct), but its
-- `vehicle_xml` CTE currently joins to SEQ 57's rendered target rows with an
-- EXACT match on the old fleet-level key — once SEQ 57's own key becomes
-- vehicle-specific, that exact match would silently return nothing for
-- every fleet. Changed to a prefix match
-- (`t2.id LIKE t1.PUREPOLICYNUMBER || '|%'`) so it still aggregates every
-- vehicle under the right fleet. FL_MOTOR_CLAUSES/EXCESS/UW joins are
-- untouched (still exact-match on the fleet-level key, correct-by-design).
--
-- ALSO FOUND while reviewing FLEET_VEHICLE_MAIN_VIEW: it has its OWN
-- separate copy of G-BP-55's silent-drop filter
-- (`WHERE YEAR<>0 and MAKE<>'' and MODEL<>''`) — fixed here too, same as
-- FLEET_VEHICLE_VIEW.
--
-- Combines and supersedes: fixes/G-BP-30_fix.sql (Indicator fix, folded
-- into STEP 1) and fixes/G-BP-55_fix.sql (filter removal, folded into
-- STEP 2). Run this file instead of those two.
--
-- Scope: 3 views + 1 config change (SEQ 56's Indicator token, same as
-- G-BP-30). No other config changes — SEQ 57/61 don't reference
-- PUREPOLICYNUMBER by name in their templates (it's the join key, not a
-- rendered field).
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- Re-pull GET_DDL / live config immediately before applying and diff.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 (Snowflake) — FLEET_VEHICLE_SUBCOVERAGES (SEQ 56):
-- widen PUREPOLICYNUMBER + dynamic INDICATOR (G-BP-30).
-- ---------------------------------------------------------------------------

create or replace view FLEET_VEHICLE_SUBCOVERAGES(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	EXPIRINGID_P,
	PROTECTIONTYPE,
	FLTYPE,
	FLCODE,
	ACCESSORIESVALUE,
	INDICATOR,
	EXPPREMIUM
) as with base as (
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        registrationnumber,
        protectiontype,
        accessoriesvalue,
        '1' as row_indicator  -- primary/selected protection type: always taken
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        registrationnumber,
        'onhook' as protectiontype,
        onhook as accessoriesvalue,
        CASE WHEN COALESCE(onhook,0)::int > 0 THEN '1' ELSE '0' END as row_indicator
        -- FIXED (G-BP-30): was hardcoded '1' in config regardless of ONHOOK.
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        registrationnumber,
        'unlimitedglass' as protectiontype,
        case
            when unlimitedglass = 'Not Protected' then 0
            else 1
        end as accessoriesvalue,
        CASE WHEN unlimitedglass = 'Not Protected' THEN '0' ELSE '1' END as row_indicator
        -- FIXED (G-BP-30): was hardcoded '1' in config regardless of UNLIMITEDGLASS.
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        registrationnumber,
        'carhire' as protectiontype,
        case
            when carhire = 'Not Taken' then 0
            else 1
        end as accessoriesvalue,
        CASE WHEN COALESCE(carhire,'Not Taken') = 'Not Taken' OR TRIM(carhire) = '' THEN '0' ELSE '1' END as row_indicator
        -- FIXED (G-BP-30): was hardcoded '1' in config regardless of CARHIRE.
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        registrationnumber,
        'choiceofrepair' as protectiontype,
        case
            when choiceofrepair = 'Not Taken' then 0
            else 1
        end as accessoriesvalue,
        CASE WHEN COALESCE(choiceofrepair,'Not Taken') = 'Not Taken' OR TRIM(choiceofrepair) = '' THEN '0' ELSE '1' END as row_indicator
        -- FIXED (G-BP-30): was hardcoded '1' in config regardless of CHOICEOFREPAIR.
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
),
SUB_COV AS (
    select
        CAST(
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) || '|' || TRIM(COALESCE(registrationnumber,'')) AS VARCHAR
        ) AS purepolicynumber,
        -- FIXED (G-BP-88): appended registrationnumber -- the key was
        -- policy|cml|expiringid_p only, which is NOT unique per vehicle
        -- (1,222 vehicles collapsed to 52 keys). This is the disambiguator
        -- that makes each vehicle's sub-coverage rows independently keyed.
        cmlnumber,
        expiringid_p,CASE
            WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE' THEN 'Comprehensive Property'
            WHEN UPPER(TRIM(protectiontype)) = 'ONHOOK' THEN 'On Hook Liability'
            WHEN UPPER(TRIM(protectiontype)) = 'UNLIMITEDGLASS' THEN 'Unlimited Glass'
            WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'Third Party Only'
            WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'Third Party Fire &amp; Theft'
            WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'Choice of Repairer'
            WHEN UPPER(TRIM(protectiontype)) = 'CARHIRE' THEN 'Car Hire'
            WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'Fire &amp; Theft'
            WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'Comprehensive Liability'
            ELSE ''
        END as PROTECTIONTYPE,
       CASE
            WHEN TRIM(protectiontype) = 'Comprehensive' THEN 'CMP_SD'
            WHEN TRIM(protectiontype) = 'onhook' THEN 'OHL_SD'
            WHEN TRIM(protectiontype) = 'unlimitedglass' THEN 'ULG_SD'
            WHEN TRIM(protectiontype) = 'Third Party Only' THEN 'TPO_SD'
            WHEN TRIM(protectiontype) = 'Third Party, Fire and Theft' THEN 'TFT_SD'
            WHEN TRIM(protectiontype) = 'choiceofrepair' THEN 'COR_SD'
            WHEN TRIM(protectiontype) = 'carhire' THEN 'TCH_SD'
            WHEN TRIM(protectiontype) = 'Fire & Theft' THEN 'FTL_SD'
            WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'LIA_SD'
            ELSE ''
        END AS FLTYPE,
        CASE
            WHEN TRIM(protectiontype) = 'Comprehensive' THEN 'FLCMP_SD'
            WHEN TRIM(protectiontype) = 'onhook' THEN 'FLOHL_SD'
            WHEN TRIM(protectiontype) = 'unlimitedglass' THEN 'FLULG_SD'
            WHEN TRIM(protectiontype) = 'Third Party Only' THEN 'FLTPO_SD'
            WHEN TRIM(protectiontype) = 'Third Party, Fire and Theft' THEN 'FLTFT_SD'
            WHEN TRIM(protectiontype) = 'choiceofrepair' THEN 'FLCOR_SD'
            WHEN TRIM(protectiontype) = 'carhire' THEN 'FLTCH_SD'
            WHEN TRIM(protectiontype)='Fire & Theft' THEN 'FLFTL_SD'
            WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'FLLIA_SD'
            ELSE ''
        END AS FLCODE,
        NVL(CAST(accessoriesvalue AS VARCHAR), 0) AS accessoriesvalue,
        row_indicator
    from
        base
),
EXP_PRE AS (
    SELECT
        PUREPOLICYNUMBER,
        SUB_COVERAGE,
        EXPPREMIUM
    FROM
        AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP
    WHERE
        SUB_COVERAGE LIKE 'FL%'
)
SELECT
    A.PUREPOLICYNUMBER,
    CMLNUMBER,
    EXPIRINGID_P,
    PROTECTIONTYPE,
    FLTYPE,
    A.FLCODE,
    ACCESSORIESVALUE,
    row_indicator AS INDICATOR,
    cast(EXPPREMIUM as varchar) as EXPPREMIUM
FROM
    SUB_COV A
    LEFT JOIN EXP_PRE B ON TRIM(A.PUREPOLICYNUMBER) = TRIM(B.PUREPOLICYNUMBER)
    AND TRIM(A.FLCODE) = TRIM(B.SUB_COVERAGE);

-- POST-CHECK (Snowflake)
-- SELECT COUNT(DISTINCT PUREPOLICYNUMBER) FROM AGGNE.DEV.FLEET_VEHICLE_SUBCOVERAGES;
-- Expect close to 1,194 (was 52 before this fix).
-- SELECT FLTYPE, INDICATOR, COUNT(*) FROM AGGNE.DEV.FLEET_VEHICLE_SUBCOVERAGES GROUP BY 1,2 ORDER BY 1,2;
-- Expect CMP_SD/TPO_SD/TFT_SD/FTL_SD/LIA_SD all Indicator='1'; OHL_SD/ULG_SD/
-- TCH_SD/COR_SD now a mix of '0'/'1'.


-- ---------------------------------------------------------------------------
-- STEP 2 (Snowflake) — FLEET_VEHICLE_VIEW (SEQ 57):
-- widen PUREPOLICYNUMBER + remove the silent-drop filter (G-BP-55).
-- ---------------------------------------------------------------------------

create or replace view FLEET_VEHICLE_VIEW(
	PUREPOLICYNUMBER,
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
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) || '|' || TRIM(COALESCE(registrationnumber,'')) AS VARCHAR
        ) AS PUREPOLICYNUMBER,
        -- FIXED (G-BP-88): appended registrationnumber, matching SEQ 56's
        -- new key shape -- this is what makes the LEFT JOIN to coverage_xml
        -- below return each vehicle's OWN sub-coverage payload instead of
        -- the whole fleet's combined payload.
        cmlnumber,
        purepolicynumber AS legacypolicynumber,
        expiringid_p,
        'FleetVehicle' as Type,
        'Fleet' as FleetType,
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
        NVL(CAST(restrictionofdriverage AS VARCHAR), '') AS restrictionofdriverage,
        NVL(CAST(haveinterestedparty AS VARCHAR), '') AS haveinterestedparty,
        NVL(CAST(additonalparty AS VARCHAR), '') AS additonalparty
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
        -- FIXED (G-BP-55): removed "where YEAR<>0 and MAKE<>'' and MODEL<>''"
        -- which silently dropped 22 of 1,222 vehicles (1.8%) that had a
        -- blank Make or Model.
),
coverage_xml as (
    select
        id,
        LISTAGG(payload, '') WITHIN GROUP (
            ORDER BY
                id
        ) AS subcov_xml
    from
        AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET
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
        AGGNE.DEV.VW_OUTPUT_COVERAGE_BSP
)
select
    t1.PUREPOLICYNUMBER,
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
        when trim(addaccessories) = 'Yes' then '1'
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
    left join coverage_xml t2 on t1.PUREPOLICYNUMBER = t2.id
    left join exp_prem t3 on TRIM(t1.PUREPOLICYNUMBER) LIKE TRIM(t3.PUREPOLICYNUMBER) || '|%'
    -- CHANGED (G-BP-88): exp_prem's own key stays policy|cml|expiringid_p
    -- (fleet-level -- VW_OUTPUT_COVERAGE_BSP has no vehicle-level detail),
    -- so this join is now a prefix match instead of exact-equality, matching
    -- fleet_table's newly-widened vehicle-specific key against it.
;

-- POST-CHECK (Snowflake)
-- SELECT COUNT(*) FROM AGGNE.DEV.FLEET_VEHICLE_VIEW;
-- Expect 1,222 (matches VEHICLECOVERAGES_FLEETVEHICLE source count exactly, 0 vehicles dropped).
-- SELECT PUREPOLICYNUMBER, MAKE, MODEL, LEN(SUBCOV_XML) FROM AGGNE.DEV.FLEET_VEHICLE_VIEW
-- WHERE PUREPOLICYNUMBER LIKE 'P00026745%';
-- Expect DIFFERENT SUBCOV_XML lengths/content per vehicle now (was identical 1,115 for all 54
-- vehicles in this fleet before the fix).


-- ---------------------------------------------------------------------------
-- STEP 3 (Snowflake) — FLEET_VEHICLE_MAIN_VIEW (SEQ 61):
-- keep its own key fleet-level (correct-by-design), but fix the vehicle_xml
-- join to a prefix match (so it still aggregates every vehicle under the
-- fleet, now that SEQ 57's rendered rows are individually vehicle-keyed),
-- plus remove its own separate copy of the G-BP-55 silent-drop filter.
-- ---------------------------------------------------------------------------

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
    left join vehicle_xml t2 on t2.id LIKE t1.PUREPOLICYNUMBER || '|%'
    -- CHANGED (G-BP-88): was exact `t1.PUREPOLICYNUMBER = t2.id`. SEQ 57's
    -- rendered rows are now individually vehicle-keyed
    -- (policy|cml|expiringid_p|registrationnumber), so this must be a
    -- prefix match against fleet_table's still-fleet-level key to keep
    -- aggregating every vehicle under the fleet.
    LEFT JOIN FL_MOTOR_CLAUSES c ON t1.PUREPOLICYNUMBER = c.ID
    LEFT JOIN FL_MOTOR_EXCESS b ON t1.PUREPOLICYNUMBER = b.ID
    LEFT JOIN FL_MOTOR_UW d ON t1.PUREPOLICYNUMBER = d.ID
    -- These three stay exact-match -- FL_MOTOR_EXCESS/CLAUSE/UW are
    -- correctly fleet-level (unchanged, see header note).
    ;

-- POST-CHECK (Snowflake)
-- SELECT COUNT(*) FROM AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW;
-- Expect >= 30 (may increase slightly now that the Make/Model filter no
-- longer excludes any fleet where every vehicle previously had a blank field).
-- SELECT PUREPOLICYNUMBER, LEN(VEHICLE_COV_XML) FROM AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW
-- WHERE PUREPOLICYNUMBER LIKE 'P00026745%';
-- Expect VEHICLE_COV_XML length to reflect all 54 vehicles' individual
-- <Vehicle> blocks concatenated (should be non-null and non-trivially long,
-- not blank -- confirms the prefix-match join still works).


-- ---------------------------------------------------------------------------
-- STEP 4 (Azure ConversionConfig) — SEQ 56 (BP_fleet_coverage_Vehicle_SubCov):
-- wire the Indicator token (G-BP-30). PRE-CHECK, then UPDATE, then POST-CHECK.
-- ---------------------------------------------------------------------------

-- PRE-CHECK
-- SELECT SequenceID, ConversionScript FROM ConversionConfig WHERE SequenceID = 56;
-- Confirm it still reads exactly:
--   <coverage>
--   <Indicator>1</Indicator>
--   ...

-- UPDATE
UPDATE ConversionConfig
SET ConversionScript = REPLACE(
    ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{INDICATOR}</Indicator>'
)
WHERE SequenceID = 56;

-- POST-CHECK
-- SELECT SequenceID, ConversionScript FROM ConversionConfig WHERE SequenceID = 56;
-- Confirm it now reads:
--   <Indicator>{INDICATOR}</Indicator>
