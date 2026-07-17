create or replace view CV_COVERAGE_VEHICLE_SUBCOV(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	POLICYNUMBER,
	EXPIRINGID_P,
	VEHICLEID,
	PROTECTIONTYPE,
	CMTYPE,
	CMCODE,
	EXPPREMIUM,
	ACCESSORIESVALUE
) as 
with base as (SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(CAST(VEHICLEID AS VARCHAR),0) AS VEHICLEID, protectiontype, NVL(CAST(cmcvagreedvalue AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
UNION ALL
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(CAST(VEHICLEID AS VARCHAR),0) AS VEHICLEID, 'choiceofrepair' AS protectiontype, NVL(CAST(cmcvchoicerepair AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
UNION ALL
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(CAST(VEHICLEID AS VARCHAR),0) AS VEHICLEID, 'OnHookTowingProtection' AS protectiontype, NVL(CAST(cmcvcoverhookliab AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
union all
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(CAST(VEHICLEID AS VARCHAR),0) AS VEHICLEID, 'HireCarHireAfterIncident' AS protectiontype, NVL(CAST(cmcvcarhire AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03
union all
SELECT DISTINCT purepolicynumber, cmlnumber, expiringid_p, NVL(CAST(VEHICLEID AS VARCHAR),0) AS VEHICLEID, 'ExcessWaiverForGlass' AS protectiontype, NVL(CAST(cmcvunlimglass AS VARCHAR),0) AS marketvaluewithoutaccessories FROM AGGNE.DEV.cm_03),
SUB_COV_EXP_PRM AS (select POLICYNUMBER, sub_coverage,EXPIRINGID_P, CMLNUMBER as CLAIMNUMBER,CMLNUMBER,EXPPREMIUM from AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP where sub_coverage like 'CM%'),
CM_BASE AS (select  CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS purepolicynumber,cmlnumber,PUREPOLICYNUMBER AS POLICYNUMBER,expiringid_p,vehicleid,CASE
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
            end as PROTECTIONTYPE ,
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
            END AS CMCODE,NVL(CAST(marketvaluewithoutaccessories AS VARCHAR),0) AS accessoriesvalue from base)
SELECT purepolicynumber,A.cmlnumber,A.POLICYNUMBER,A.expiringid_p,vehicleid,PROTECTIONTYPE,CMTYPE,CMCODE,CAST(EXPPREMIUM AS VARCHAR) AS EXPPREMIUM,accessoriesvalue FROM CM_BASE A
left join SUB_COV_EXP_PRM B ON TRIM(A.POLICYNUMBER) = TRIM(B.POLICYNUMBER)
AND TRIM(A.cmlnumber) = TRIM(B.cmlnumber)
AND TRIM(A.CMCODE) = TRIM(B.sub_coverage);