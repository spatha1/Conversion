-- ============================================================
-- PP Conversion — policy-level detail queries, one per client question
-- Companion to CLIENT_QUESTIONS_QUERIES.sql, which only gives aggregate counts. Use these to pull
-- the actual failing policy numbers, to check specific cases with the client one at a time.
--
-- Each block is INDEPENDENT — run one at a time, not as a single UNION ALL (the grain differs:
-- some are per-vehicle, some per-policy, some per-risk-node). Every block returns
-- LEGACYPOLICYNUMBER (the plain PURE policy number) plus the specific field value(s) in question,
-- LIMIT 50 by default — remove the LIMIT to pull the full list once you've picked a block to use.
--
-- Read-only against AGGNE.DEV.
-- ============================================================

-- ============================================================
-- 1. Body Type
-- ============================================================
SELECT SPLIT_PART(PUREPOLICYNUMBER,'|',1) AS LEGACYPOLICYNUMBER, BODYTYPE
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE BODYTYPE NOT IN ('Bus','Convertible','Coupe','Hatchback','PrimeMover','Sedan','Utility','Van','Wagon',
                        'TowTruck','Transporter','MobilePlant','Motorcycle','Trailer','CamperVan','Caravan','Forklift')
LIMIT 50;

-- ============================================================
-- 2. Number of Cylinders
-- ============================================================
SELECT SPLIT_PART(PUREPOLICYNUMBER,'|',1) AS LEGACYPOLICYNUMBER, NUMBEROFCYLINDERS, VEHICLETYPE
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE TRY_TO_NUMBER(NUMBEROFCYLINDERS) NOT BETWEEN 1 AND 16 OR NUMBEROFCYLINDERS IS NULL
LIMIT 50;

-- ============================================================
-- 3. Voluntary Excess (Motor)
-- ============================================================
SELECT SPLIT_PART(PUREPOLICYNUMBER,'|',1) AS LEGACYPOLICYNUMBER, VOLUNTARYEXCESS
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE VOLUNTARYEXCESS NOT IN ('0','250','500','750','1000','1250','1500')
LIMIT 50;

-- ============================================================
-- 4. Age of Youngest Regular Driver
-- ============================================================
SELECT SPLIT_PART(PUREPOLICYNUMBER,'|',1) AS LEGACYPOLICYNUMBER, AGEOFYOUNGESTREGULARDRIVER
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE COALESCE(TRIM(AGEOFYOUNGESTREGULARDRIVER),'')='' OR TRY_TO_NUMBER(AGEOFYOUNGESTREGULARDRIVER) < 17
LIMIT 50;

-- ============================================================
-- 5. Underwriting Adjustments (one-off) — Motor + Home Contents
-- Source-side rows that exist but don't have a matching converted row (LEFT JOIN ... IS NULL).
-- ============================================================
SELECT TRIM(SRC.POLICYNUMBER) AS LEGACYPOLICYNUMBER, SRC.COVERAGE, SRC.UWADJUSTAMOUNT, SRC.UWADJUSTNOTE
FROM AGGNE.DEV.Output_UWAdjust_PER SRC
WHERE SRC.COVERAGE IN ('PM','HC')
  AND NOT EXISTS (
    SELECT 1 FROM AGGNE.DEV.PER_PM_BUILDING_UW T WHERE TRIM(T.PUREPOLICYNUMBER) = TRIM(SRC.POLICYNUMBER)
    UNION ALL
    SELECT 1 FROM AGGNE.DEV.PER_HC_BUILDING_UW T WHERE TRIM(T.PUREPOLICYNUMBER) = TRIM(SRC.POLICYNUMBER)
  )
LIMIT 50;

-- ============================================================
-- 6. Premium (Home) — policies where both HB and HC show 0.00
-- ============================================================
SELECT SPLIT_PART(PUREPOLICYNUMBER,'|',1) AS LEGACYPOLICYNUMBER, EXPPREM, HBEXPPREM
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
WHERE HC_INDICATOR = 1 AND HB_INDICATOR = 1
LIMIT 50;

-- ============================================================
-- 7. Motor Clause Codes — legacy CM_*/FV* codes
-- ============================================================
SELECT SPLIT_PART(TRIM(PUREPOLICYNUMBER),'|',1) AS LEGACYPOLICYNUMBER, DCCLAUSETYPE
FROM AGGNE.DEV.COM_CLAUSE
WHERE DCCLAUSETYPE LIKE 'CM_%' OR DCCLAUSETYPE LIKE 'FV%'
LIMIT 50;

-- ============================================================
-- 8. Landlords Protections Indicator (Building_SubCov HBLLB_SD block) — owner-occupied policies
-- where the redundant sub-coverage block still shows Indicator=1
-- ============================================================
SELECT SPLIT_PART(T1.ID,'|',1) AS LEGACYPOLICYNUMBER, T2.HOWOCCUPPIED,
       REGEXP_SUBSTR(T1.PAYLOAD, '<Indicator>(.*?)</Indicator>', 1, 1, 'e') AS HBLLB_SD_INDICATOR
FROM AGGNE.DEV.PER_BUILDING_TARGET T1
JOIN AGGNE.DEV.PER_RISK_BUILDING_FINAL T2 ON T1.ID = T2.PUREPOLICYNUMBER
WHERE T1.ITR_TYPE = 'Building_SubCov' AND T1.PAYLOAD ILIKE '%HBLLB_SD%' AND T2.HOWOCCUPPIED ILIKE '%owner%'
LIMIT 50;

-- ============================================================
-- 9. Home Buildings Underwriting Adjustments — policies with a real UW adjustment in source but
-- the payload's UWAdjustmentIndicator hardcoded to 0
-- ============================================================
SELECT SPLIT_PART(T1.ID,'|',1) AS LEGACYPOLICYNUMBER,
       REGEXP_SUBSTR(T1.PAYLOAD, '<UWAdjustmentIndicator>(.*?)</UWAdjustmentIndicator>', 1, 1, 'e') AS UWADJUSTMENTINDICATOR_SENT,
       SRC.UWADJUSTAMOUNT AS SOURCE_ADJUSTMENT_AMOUNT
FROM AGGNE.DEV.PER_BUILDING_TARGET T1
JOIN AGGNE.DEV.Output_UWAdjust_PER SRC ON TRIM(SPLIT_PART(T1.ID,'|',1)) = TRIM(SRC.POLICYNUMBER) AND SRC.COVERAGE = 'HB'
WHERE T1.ITR_TYPE = 'RISK_Building_HB'
LIMIT 50;

-- ============================================================
-- 10. State — NZ risks
-- ============================================================
SELECT PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER, STATE, REGISTRATIONNUMBER
FROM AGGNE.DEV.PM_03
WHERE STATE = 'NZ'
LIMIT 50;

-- ============================================================
-- 11. Home Buildings Excess Breakdown — every RISK_Building_HB policy (scope question, all affected)
-- ============================================================
SELECT SPLIT_PART(ID,'|',1) AS LEGACYPOLICYNUMBER,
       REGEXP_SUBSTR(PAYLOAD, '<Voluntary>(.*?)</Voluntary>', 1, 1, 'e') AS VOLUNTARY_EXCESS_ONLY_FIELD_POPULATED
FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE ITR_TYPE = 'RISK_Building_HB'
LIMIT 50;

-- ============================================================
-- 12. Glass Limit — sample across the value range, not just the low end
-- ============================================================
SELECT SPLIT_PART(ID,'|',1) AS LEGACYPOLICYNUMBER,
       REGEXP_SUBSTR(PAYLOAD, '<GlassLimit>(.*?)</GlassLimit>', 1, 1, 'e') AS GLASSLIMIT
FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE ITR_TYPE = 'RISK_Building_HB' AND PAYLOAD LIKE '%<GlassLimit>%'
ORDER BY TRY_TO_NUMBER(REGEXP_SUBSTR(PAYLOAD, '<GlassLimit>(.*?)</GlassLimit>', 1, 1, 'e')) DESC
LIMIT 50;

-- ============================================================
-- 13. Risk-Level Excess Breakdown — every risk node (scope question, all affected)
-- ============================================================
SELECT SPLIT_PART(ID,'|',1) AS LEGACYPOLICYNUMBER
FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
LIMIT 50;

-- ============================================================
-- 14. SIC Code — every risk node (100% affected, same hardcoded value everywhere)
-- ============================================================
SELECT SPLIT_PART(ID,'|',1) AS LEGACYPOLICYNUMBER,
       REGEXP_SUBSTR(PAYLOAD, '<SICCode>(.*?)</SICCode>', 1, 1, 'e') AS SICCODE
FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
LIMIT 50;

-- ============================================================
-- 15. Risk-Assessment Answers — all 6 fields per policy in one row
-- ============================================================
SELECT SPLIT_PART(ID,'|',1) AS LEGACYPOLICYNUMBER,
       REGEXP_SUBSTR(PAYLOAD, '<ExternalDoors>(.*?)</ExternalDoors>', 1, 1, 'e') AS EXTERNALDOORS,
       REGEXP_SUBSTR(PAYLOAD, '<SecurityAccessibleWindows>(.*?)</SecurityAccessibleWindows>', 1, 1, 'e') AS SECURITYACCESSIBLEWINDOWS,
       REGEXP_SUBSTR(PAYLOAD, '<SecurityAlarm>(.*?)</SecurityAlarm>', 1, 1, 'e') AS SECURITYALARM,
       REGEXP_SUBSTR(PAYLOAD, '<LocationConnectedToTownWaterMain>(.*?)</LocationConnectedToTownWaterMain>', 1, 1, 'e') AS LOCATIONCONNECTEDTOTOWNWATERMAIN,
       REGEXP_SUBSTR(PAYLOAD, '<StoreFlammableGoods>(.*?)</StoreFlammableGoods>', 1, 1, 'e') AS STOREFLAMMABLEGOODS,
       REGEXP_SUBSTR(PAYLOAD, '<IsAusStandardFollowed>(.*?)</IsAusStandardFollowed>', 1, 1, 'e') AS ISAUSSTANDARDFOLLOWED
FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
LIMIT 50;

-- ============================================================
-- 16. Motor Coverage Selections — spurious cross-protection-type coverage blocks, per policy
-- ============================================================
SELECT SPLIT_PART(T1.ID,'|',1) AS LEGACYPOLICYNUMBER, T2.PROTECTIONTYPE,
       REGEXP_SUBSTR(T1.PAYLOAD, '<Type>(.*?)</Type>', 1, 1, 'e') AS COVERAGE_CODE,
       REGEXP_SUBSTR(T1.PAYLOAD, '<Indicator>(.*?)</Indicator>', 1, 1, 'e') AS INDICATOR
FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET T1
JOIN AGGNE.DEV.PER_COM_PAYLOAD T2 ON T1.ID = T2.PUREPOLICYNUMBER
WHERE T1.ITR_TYPE = 'Risk_CM'
  AND (
    (T2.PROTECTIONTYPE = 'ThirdPartyOnly' AND REGEXP_SUBSTR(T1.PAYLOAD, '<Type>(.*?)</Type>', 1, 1, 'e') IN ('CMP_SD','PCH_SD','COR_SD','ULG_SD'))
    OR (T2.PROTECTIONTYPE LIKE 'Comprehensive%' AND REGEXP_SUBSTR(T1.PAYLOAD, '<Type>(.*?)</Type>', 1, 1, 'e') = 'TPO_SD')
  )
LIMIT 50;

-- ============================================================
-- 17. HC Specified Items Away From the Premises — actual item list from HC_AWAY (source),
-- for policies whose flag shows "Taken"
-- ============================================================
SELECT TRIM(HA.PUREPOLICYNUMBER) AS LEGACYPOLICYNUMBER, HA.DESCRIPTION, HA.VALUE
FROM AGGNE.DEV.HC_AWAY HA
WHERE TRIM(HA.PUREPOLICYNUMBER) IN (
    SELECT SPLIT_PART(PUREPOLICYNUMBER,'|',1) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD WHERE SPECIFIEDITEMSAWAY = 'Taken'
)
LIMIT 50;

-- ============================================================
-- 18. Legacy Start Date — sample policies with their Inception/Effective/Membership dates
-- ============================================================
SELECT LEGACYPOLICYNUMBER, INCEPTIONDATE, EFFECTIVEDATE, MEMBERSHIPSYSTEMDATE
FROM AGGNE.DEV.PER_FINAL
WHERE MEMBERSHIPSYSTEMDATE IS NOT NULL
LIMIT 50;
