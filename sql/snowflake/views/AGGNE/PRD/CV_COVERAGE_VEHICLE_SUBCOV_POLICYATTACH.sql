create or replace view CV_COVERAGE_VEHICLE_SUBCOV_POLICYATTACH(
	PUREPOLICYNUMBER,
	PUREPOLICYNUMBER_ACTUAL,
	CMLNUMBER,
	POLICYNUMBER,
	EXPIRINGID_P,
	INSURANCE_FILE_CNT,
	VEHICLEID,
	PROTECTIONTYPE,
	CMTYPE,
	CMCODE,
	VALUE,
	EXPPREMIUM,
	ACCESSORIESVALUE
) as


    with base as (
        SELECT
            DISTINCT ID,
            purepolicynumber,
            cmlnumber,
            expiringid_p,
            INSURANCE_FILE_CNT,
            cAST(VEHICLEID AS VARCHAR) AS VEHICLEID,
            protectiontype,
            NVL(CAST(MVVALUEWITHOUTACCESSORIES AS VARCHAR), 0) AS marketvaluewithoutaccessories
        FROM
            AGGNE.PRD.CM_03_POLICYATTACH_IDENTIFIER  where protectiontype not in ('Comprehensive - Agreed Value')
        UNION ALL
          SELECT
            DISTINCT ID,
            purepolicynumber,
            cmlnumber,
            expiringid_p,
            INSURANCE_FILE_CNT,
            cAST(VEHICLEID AS VARCHAR) AS VEHICLEID,
            protectiontype,
            NVL(CAST(AVVALUEWITHOUTACCESSORIES AS VARCHAR), 0) AS marketvaluewithoutaccessories
        FROM
            AGGNE.PRD.CM_03_POLICYATTACH_IDENTIFIER where  protectiontype in ('Comprehensive - Agreed Value')
        UNION ALL
        SELECT
            DISTINCT ID,
            purepolicynumber,
            cmlnumber,
            expiringid_p,
            INSURANCE_FILE_CNT,
            cAST(VEHICLEID AS VARCHAR) AS VEHICLEID,
            'Comprehensive Liability' AS protectiontype,
           case when  protectiontype in ('Comprehensive - Agreed Value') then NVL(CAST(AVVALUEWITHOUTACCESSORIES AS VARCHAR), 0) 
           when  protectiontype in ('Comprehensive - Market Value') then NVL(CAST(MVVALUEWITHOUTACCESSORIES AS VARCHAR), 0)  end
           AS marketvaluewithoutaccessories
        FROM
            AGGNE.PRD.CM_03_POLICYATTACH_IDENTIFIER 
        where
            protectiontype in ('Comprehensive - Market Value','Comprehensive - Agreed Value')
        UNION ALL
        SELECT
            DISTINCT ID,
            purepolicynumber,
            cmlnumber,
            expiringid_p,
            INSURANCE_FILE_CNT,
            cAST(VEHICLEID AS VARCHAR) AS VEHICLEID,
            'choiceofrepair' AS protectiontype,
            NVL(CAST(cmcvchoicerepair AS VARCHAR), 0) AS marketvaluewithoutaccessories
        FROM
            AGGNE.PRD.CM_03_POLICYATTACH_IDENTIFIER
        where
            cmcvchoicerepair::int != 0
        UNION ALL
        SELECT
            DISTINCT ID,
            purepolicynumber,
            cmlnumber,
            expiringid_p,
            INSURANCE_FILE_CNT,
            cAST(VEHICLEID AS VARCHAR) AS VEHICLEID,
            'OnHookTowingProtection' AS protectiontype,
            NVL(CAST(ONHOOKTOWINGPROTECTION AS VARCHAR), 0) AS marketvaluewithoutaccessories
        FROM
            AGGNE.PRD.CM_03_POLICYATTACH_IDENTIFIER
        where
            COALESCE(CMCVCOVERHOOKLIAB::int, 0) != 0
        union all
        SELECT
            DISTINCT ID,
            purepolicynumber,
            cmlnumber,
            expiringid_p,
            INSURANCE_FILE_CNT,
            cAST(VEHICLEID AS VARCHAR) AS VEHICLEID,
            'HireCarHireAfterIncident' AS protectiontype,
            NVL(CAST(cmcvcarhire AS VARCHAR), 0) AS marketvaluewithoutaccessories
        FROM
            AGGNE.PRD.CM_03_POLICYATTACH_IDENTIFIER
        where
            cmcvcarhire::int != 0
        union all
        SELECT
            DISTINCT ID,
            purepolicynumber,
            cmlnumber,
            expiringid_p,
            INSURANCE_FILE_CNT,
            cAST(VEHICLEID AS VARCHAR) AS VEHICLEID,
            'ExcessWaiverForGlass' AS protectiontype,
            NVL(CAST(cmcvunlimglass AS VARCHAR), 0) AS marketvaluewithoutaccessories
        FROM
            AGGNE.PRD.CM_03_POLICYATTACH_IDENTIFIER
        where
            cmcvunlimglass::int != 0
    ),
    SUB_COV_EXP_PRM AS (
        select
            POLICYNUMBER,
            sub_coverage,
            EXPIRINGID_P,
            CMLNUMBER,
            EXPPREMIUM
        from
            AGGNE.PRD.VW_OUTPUT_SUBCOVERAGE_BSP_POLICYATTACH
        where
            sub_coverage like 'CM%'
    ),
    CM_BASE AS (
        select distinct 
            ID AS purepolicynumber,
            CAST(
                trim(PUREPOLICYNUMBER) || '|' || TRIM(cmlnumber) || '|' || TRIM(EXPIRINGID_P) AS VARCHAR
            ) AS purepolicynumber_conv,
            cmlnumber,
            PUREPOLICYNUMBER AS POLICYNUMBER,
            expiringid_p,
            INSURANCE_FILE_CNT,
            vehicleid,CASE
                WHEN TRIM(PROTECTIONTYPE) = 'Third Party, Fire and Theft' THEN 'ThirdPartyFireandTheft'
                WHEN TRIM(PROTECTIONTYPE) = 'Comprehensive - Market Value' THEN 'ComprehensiveMarket'
                WHEN TRIM(PROTECTIONTYPE) = 'Comprehensive - Agreed Value' THEN 'ComprehensiveAgreedValue'
                WHEN TRIM(PROTECTIONTYPE) = 'Fire and Theft' THEN 'FireandTheft'
                WHEN TRIM(PROTECTIONTYPE) = 'Third Party Only' THEN 'ThirdPartyOnly'
                ELSE PROTECTIONTYPE
            END as PROTECTIONTYPE,
            CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'CMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'CMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'FTL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'OHL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'ULG_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'TPO_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'TFT_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'COR_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'PCH_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'LIA_SD'
                ELSE ''
            END AS CMTYPE,CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'CMCMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'CMCMP_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'CMFTL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'CMOHL_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'CMULG_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'CMTPO_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'CMTFT_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'CMCOR_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'CMPCH_SD'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'CMLIA_SD'
                ELSE ''
            END AS CMCODE,
            CASE
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - MARKET VALUE' THEN 'Comprehensive Property'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE - AGREED VALUE' THEN 'Comprehensive Property'
                WHEN UPPER(TRIM(protectiontype)) = 'FIRE AND THEFT' THEN 'Fire &amp; Theft excluding Liability'
                WHEN UPPER(TRIM(protectiontype)) = 'ONHOOKTOWINGPROTECTION' THEN 'On Hook Liability'
                WHEN UPPER(TRIM(protectiontype)) = 'EXCESSWAIVERFORGLASS' THEN 'Unlimited Glass'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY ONLY' THEN 'Third Party Only'
                WHEN UPPER(TRIM(protectiontype)) = 'THIRD PARTY, FIRE AND THEFT' THEN 'Third Party Fire &amp; Theft'
                WHEN UPPER(TRIM(protectiontype)) = 'CHOICEOFREPAIR' THEN 'Choice of Repairer'
                WHEN UPPER(TRIM(protectiontype)) = 'HIRECARHIREAFTERINCIDENT' THEN 'Car Hire'
                WHEN UPPER(TRIM(protectiontype)) = 'COMPREHENSIVE LIABILITY' THEN 'Comprehensive Liability'
            end as VALUE,
            NVL(CAST(marketvaluewithoutaccessories AS VARCHAR), 0) AS accessoriesvalue
        from
            base
    )
SELECT distinct 
    CAST(
        trim(purepolicynumber) || '|' || TRIM(VEHICLEID) AS VARCHAR
    ) AS PUREPOLICYNUMBER,
    purepolicynumber AS PUREPOLICYNUMBER_ACTUAL,
    A.cmlnumber,
    A.POLICYNUMBER,
    A.expiringid_p,
    INSURANCE_FILE_CNT,
    vehicleid,
    PROTECTIONTYPE,
    CMTYPE,
    CMCODE,
    VALUE,
    CAST(EXPPREMIUM AS VARCHAR) AS EXPPREMIUM,
    accessoriesvalue
FROM
    CM_BASE A
    left join SUB_COV_EXP_PRM B ON TRIM(A.purepolicynumber_conv) = TRIM(B.POLICYNUMBER)
    AND TRIM(A.cmlnumber) = TRIM(B.cmlnumber)
    AND TRIM(A.CMCODE) = TRIM(B.sub_coverage);