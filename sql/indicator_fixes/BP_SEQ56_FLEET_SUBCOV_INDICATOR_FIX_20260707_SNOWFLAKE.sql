-- ============================================================
-- SEQ 56 BP_fleet_coverage_Vehicle_SubCov Indicator Fix -- Snowflake VIEW
-- Date   : 2026-07-07
-- Target : AGGNE.DEV.FLEET_VEHICLE_SUBCOVERAGES
-- Fix    : Add INDICATOR column (new). Per-branch logic
--          (verified against live AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE data):
--            protectiontype row : 1 (vehicle's actual protection = taken)
--            onhook             : 1 when onhook > 0            (data: numeric)
--            unlimitedglass     : 1 when = 'Protected'         (data: ''/Not Protected/Protected)
--            carhire            : 1 when = 'Taken'             (data: ''/Taken/Not Taken)
--            choiceofrepair     : 1 when = 'Taken'             (data: ''/Taken/Not Taken)
--          Note: current iValue treats '' as taken for the flag rows;
--          INDICATOR uses strict matching so '' => 0.
-- Companion: BP_SEQ56_FLEET_SUBCOV_INDICATOR_FIX_20260707_CONFIG.sql
-- ============================================================

create or replace view AGGNE.DEV.FLEET_VEHICLE_SUBCOVERAGES(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	EXPIRINGID_P,
	PROTECTIONTYPE,
	FLTYPE,
	FLCODE,
	ACCESSORIESVALUE,
	EXPPREMIUM,
	INDICATOR
) as with base as (
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        protectiontype,
        accessoriesvalue,
        1 as indicator
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        'onhook' as protectiontype,
        onhook as accessoriesvalue,
        case when COALESCE(onhook, 0) > 0 then 1 else 0 end as indicator
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        'unlimitedglass' as protectiontype,
        case
            when unlimitedglass = 'Not Protected' then 0
            else 1
        end as accessoriesvalue,
        case when unlimitedglass = 'Protected' then 1 else 0 end as indicator
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        'carhire' as protectiontype,
        case
            when carhire = 'Not Taken' then 0
            else 1
        end as accessoriesvalue,
        case when carhire = 'Taken' then 1 else 0 end as indicator
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        'choiceofrepair' as protectiontype,
        case
            when choiceofrepair = 'Not Taken' then 0
            else 1
        end as accessoriesvalue,
        case when choiceofrepair = 'Taken' then 1 else 0 end as indicator
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
),
SUB_COV AS (
    select
        CAST(
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
        ) AS purepolicynumber,
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
        CAST(indicator AS VARCHAR) AS indicator,
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
    cast(EXPPREMIUM as varchar) as EXPPREMIUM,
    INDICATOR
FROM
    SUB_COV A
    LEFT JOIN EXP_PRE B ON TRIM(A.PUREPOLICYNUMBER) = TRIM(B.PUREPOLICYNUMBER)
    AND TRIM(A.FLCODE) = TRIM(B.SUB_COVERAGE);
