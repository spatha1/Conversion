create or replace view FLEET_VEHICLE_SUBCOVERAGES(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	EXPIRINGID_P,
	PROTECTIONTYPE,
	FLTYPE,
	FLCODE,
	ACCESSORIESVALUE,
	EXPPREMIUM
) as with base as (
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        protectiontype,
        accessoriesvalue
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        'onhook' as protectiontype,
        onhook as accessoriesvalue
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
        end as accessoriesvalue
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
        end as accessoriesvalue
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
        end as accessoriesvalue
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
    cast(EXPPREMIUM as varchar) as EXPPREMIUM
FROM
    SUB_COV A
    LEFT JOIN EXP_PRE B ON TRIM(A.PUREPOLICYNUMBER) = TRIM(B.PUREPOLICYNUMBER)
    AND TRIM(A.FLCODE) = TRIM(B.SUB_COVERAGE);