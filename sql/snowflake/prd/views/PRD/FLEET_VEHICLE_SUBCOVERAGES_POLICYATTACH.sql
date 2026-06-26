create or replace view FLEET_VEHICLE_SUBCOVERAGES_POLICYATTACH(
	PUREPOLICYNUMBER_ACTUAL,
	PUREPOLICYNUMBER,
	REGISTRATIONNUMBER,
	CMLNUMBER,
	EXPIRINGID_P,
	PROTECTIONTYPE,
	FLTYPE,
	FLCODE,
	VALUE,
	ACCESSORIESVALUE,
	EXPPREMIUM
) as
with base as (
    select
        distinct ID,
        cmlnumber,
        purepolicynumber,
        expiringid_p,
        INSURANCE_FILE_CNT,
        protectiontype,
        accessoriesvalue,
        NVL(cAST(REGISTRATIONNUMBER AS VARCHAR),'Unknown') AS REGISTRATIONNUMBER
    from
        AGGNE.PRD.VEHICLECOVERAGES_FLEETVEHICLE_POLICYATTACH_IDENTIFIER
    UNION ALL
    SELECT
        DISTINCT ID,
        cmlnumber,
        purepolicynumber,
        expiringid_p,
        INSURANCE_FILE_CNT,
        'Comprehensive Liability' AS protectiontype,
        NVL(CAST(accessoriesvalue AS VARCHAR), 0) AS accessoriesvalue,
        NVL(cAST(REGISTRATIONNUMBER AS VARCHAR),'Unknown') AS REGISTRATIONNUMBER
        
    FROM
        AGGNE.PRD.VEHICLECOVERAGES_FLEETVEHICLE_POLICYATTACH_IDENTIFIER
    where
        protectiontype in (
            'Comprehensive'
        )
    union all
    select
        distinct ID,
        cmlnumber,
        purepolicynumber,
        expiringid_p,
        INSURANCE_FILE_CNT,
        'onhook' as protectiontype,
        onhook as accessoriesvalue,
        NVL(cAST(REGISTRATIONNUMBER AS VARCHAR),'Unknown') AS REGISTRATIONNUMBER
    from
        AGGNE.PRD.VEHICLECOVERAGES_FLEETVEHICLE_POLICYATTACH_IDENTIFIER
        WHERE onhook<>0
    union all
    select
        distinct ID,
        cmlnumber,
        purepolicynumber,
        expiringid_p,
        INSURANCE_FILE_CNT,
        'unlimitedglass' as protectiontype,
        case
            when unlimitedglass = 'Not Protected' then 0
            else 1
        end as accessoriesvalue,
        NVL(cAST(REGISTRATIONNUMBER AS VARCHAR),'Unknown') AS REGISTRATIONNUMBER
    from
        AGGNE.PRD.VEHICLECOVERAGES_FLEETVEHICLE_POLICYATTACH_IDENTIFIER
    WHERE
        unlimitedglass != 'Not Protected'
    union all
    select
        distinct ID,
        cmlnumber,
        purepolicynumber,
        expiringid_p,
        INSURANCE_FILE_CNT,
        'carhire' as protectiontype,
        case
            when carhire = 'Not Taken' then 0
            else 1
        end as accessoriesvalue,
        NVL(cAST(REGISTRATIONNUMBER AS VARCHAR),'Unknown') AS REGISTRATIONNUMBER
    from
        AGGNE.PRD.VEHICLECOVERAGES_FLEETVEHICLE_POLICYATTACH_IDENTIFIER
    WHERE
        carhire != 'Not Taken'
    union all
    select
        distinct ID,
        cmlnumber,
        purepolicynumber,
        expiringid_p,
        INSURANCE_FILE_CNT,
        'choiceofrepair' as protectiontype,
        case
            when choiceofrepair = 'Not Taken' then 0
            else 1
        end as accessoriesvalue,
        NVL(cAST(REGISTRATIONNUMBER AS VARCHAR),'Unknown') AS REGISTRATIONNUMBER
    from
        AGGNE.PRD.VEHICLECOVERAGES_FLEETVEHICLE_POLICYATTACH_IDENTIFIER
    WHERE
        choiceofrepair != 'Not Taken'
),
SUB_COV AS (
    select
        ID AS purepolicynumber,
        CAST(
            trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
        ) AS purepolicynumber_conv,
        cmlnumber,
        expiringid_p,CASE
            WHEN TRIM(PROTECTIONTYPE) = 'Third Party, Fire and Theft' THEN 'ThirdPartyFireandTheft'
            WHEN TRIM(PROTECTIONTYPE) = 'Comprehensive' THEN 'Comprehensive Property'
            WHEN TRIM(PROTECTIONTYPE) = 'Third Party Only' THEN 'ThirdPartyOnly'
            ELSE PROTECTIONTYPE
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
            WHEN TRIM(protectiontype) ='Fire & Theft' THEN 'FLFTL_SD'
            WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'FLLIA_SD'
            ELSE ''
        END AS FLCODE,
        CASE
            WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE' THEN 'Comprehensive Property'
            WHEN UPPER(TRIM(protectiontype)) = 'ONHOOK' THEN 'On Hook Liability'
            WHEN UPPER(TRIM(protectiontype)) = 'UNLIMITEDGLASS' THEN 'Unlimited Glass'
            WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'Third Party Only'
            WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'Third Party Fire & Theft'
            WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'Choice of Repairer'
            WHEN UPPER(TRIM(protectiontype)) = 'CARHIRE' THEN 'Car Hire'
            WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'Fire & Theft'
            WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'Comprehensive Liability'
            ELSE ''
        END AS VALUE,
        NVL(CAST(accessoriesvalue AS VARCHAR), 0) AS accessoriesvalue,
        NVL(cAST(REGISTRATIONNUMBER AS VARCHAR),'Unknown') AS REGISTRATIONNUMBER
    from
        base
),
EXP_PRE AS (
    SELECT
        PUREPOLICYNUMBER,
        SUB_COVERAGE,
        EXPPREMIUM
    FROM
        AGGNE.PRD.VW_OUTPUT_SUBCOVERAGE_BSP_POLICYATTACH
    WHERE
        SUB_COVERAGE LIKE 'FL%'
)
SELECT
    A.PUREPOLICYNUMBER AS PUREPOLICYNUMBER_ACTUAL,
    CAST(
        trim(A.purepolicynumber) || '|' || NVL(TRIM(registrationnumber),'Unknown') AS VARCHAR
    ) AS PUREPOLICYNUMBER,
    NVL(cAST(REGISTRATIONNUMBER AS VARCHAR),'Unknown'),
    CMLNUMBER,
    EXPIRINGID_P,
    PROTECTIONTYPE,
    FLTYPE,
    A.FLCODE,
    A.VALUE,
    ACCESSORIESVALUE,
    cast(EXPPREMIUM as varchar) as EXPPREMIUM
FROM
    SUB_COV A
    LEFT JOIN EXP_PRE B ON TRIM(A.purepolicynumber_conv) = TRIM(B.PUREPOLICYNUMBER)
    AND TRIM(A.FLCODE) = TRIM(B.SUB_COVERAGE);