-- ============================================================================
-- G-BP-55 fix — Fleet Make/Model: silent vehicle drop (SEQ 57, ATP-11134)
--
-- *** SUPERSEDED by fixes/G-BP-88_fix.sql *** — that file's STEP 2 includes
-- this exact filter-removal fix PLUS the composite-key widening (G-BP-88),
-- since both touch the same view. It also fixes the SAME filter's separate
-- copy in FLEET_VEHICLE_MAIN_VIEW (STEP 3), which this file didn't cover.
-- Run G-BP-88_fix.sql instead. Kept only as the standalone record.
-- ============================================================================
-- FLEET_VEHICLE_VIEW's fleet_table CTE has `WHERE YEAR<>0 and MAKE<>'' and
-- MODEL<>''` — silently drops the ENTIRE vehicle record (registration,
-- coverages, excess, everything) when any one of Year/Make/Model is blank.
-- Same shape as PP's retired PR-01 pattern.
--
-- Live check (2026-07-12): 1,222 total Fleet vehicle rows in
-- VEHICLECOVERAGES_FLEETVEHICLE; 22 have blank MAKE, 22 have blank MODEL
-- (largely the same 22 vehicles), 0 have YEAR=0 — 22 of 1,222 (1.8%)
-- vehicles are currently silently dropped from the conversion entirely.
--
-- FIX: remove the WHERE filter, let every vehicle flow through. Blank
-- Make/Model becomes a validation-report concern, not a silent drop.
--
-- Scope: view-only, one view, one WHERE clause removed. No config change —
-- SEQ 57 already reads {MAKE}/{MODEL} tokens directly.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- Re-pull GET_DDL immediately before applying and diff against this.
-- ============================================================================

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
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
        ) AS PUREPOLICYNUMBER,
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
    left join exp_prem t3 on TRIM(t1.PUREPOLICYNUMBER) = TRIM(t3.PUREPOLICYNUMBER)
;

-- POST-CHECK (Snowflake)
-- SELECT COUNT(*) FROM AGGNE.DEV.FLEET_VEHICLE_VIEW;
-- Expect 1,222 (matches VEHICLECOVERAGES_FLEETVEHICLE source count exactly, 0 vehicles dropped).
