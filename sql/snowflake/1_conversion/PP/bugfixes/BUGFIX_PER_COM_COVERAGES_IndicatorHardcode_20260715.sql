-- STANDALONE: PER_COM_COVERAGES, run this whole file as one statement.
-- Pulled fresh via GET_DDL('VIEW','AGGNE.DEV.PER_COM_COVERAGES') on 2026-07-15 immediately before
-- this edit -- only the change below, nothing else touched.
--
-- FIX: INDICATOR was hardcoded to 1 for every one of 7 sub-coverage branches (CMP_SD
-- Comprehensive Property, COR_SD Choice of Repairer, FTL_SD Fire&Theft excl Liability, LIA_SD
-- Comprehensive Liability, PCH_SD Car Hire, TFT_SD Third Party Fire&Theft, TPO_SD Third Party
-- Only) -- meaning every vehicle sent DCT 7+ mutually-exclusive protection-tier "selections"
-- simultaneously marked active (a vehicle cannot genuinely be Comprehensive AND Third-Party-Only
-- AND Fire&Theft-only at once). Only EXP_PREM (and the already-separately-fixed ULG_SD branch,
-- ATP-10842) correctly checked which sub-coverage actually applies via
-- Output_SubCover_PER.SUB_COVERAGE -- INDICATOR never did the same check on the other 7.
--
-- Confirmed live: real Motor XML shows <Indicator>1</Indicator> on 5+ sub-coverage blocks
-- simultaneously for the same vehicle, with <iValue></iValue> empty on every one -- exactly the
-- "selected coverage missing required data" pattern flagged as a rating-failure cause. This is
-- the most systemic Motor-rating-blocking candidate found so far (Motor premium confirmed $0 on
-- every DEV test quote this session regardless of Market Value / State / GaragingPostcode fixes,
-- all three now ruled out on a fully clean control policy -- P00019280, still $0 after all three).
--
-- Fix: same conditional pattern already proven correct for EXP_PREM and ULG_SD --
-- CASE WHEN T2.SUB_COVERAGE = 'PMxxx_SD' THEN '1' ELSE '0' END AS INDICATOR, so only the
-- sub-coverage that genuinely matches (LEFT JOIN found a real Output_SubCover_PER row) is marked
-- selected; the rest correctly show 0. Not yet confirmed as resolving Motor premium -- verify
-- after deploying + regenerating.

create or replace view PER_COM_COVERAGES(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	CMLNUMBER,
	COVERAGE,
	COVERAGETYPE,
	DESCRIPTION,
	TYPE,
	CODE,
	IVALUE,
	SVALUE,
	INDICATOR,
	EXP_PREM
) as
SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'CommercialVehicle' AS CoverageType,
    'Comprehensive Property' AS Description,
    'CMP_SD' AS Type,
    'PMCMP_SD' AS CODE,
     ''  AS IVALUE,
    '' AS SVALUE,
    CASE WHEN T2.SUB_COVERAGE = 'PMCMP_SD' THEN '1' ELSE '0' END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='PMCMP_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.PM_03 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='PMCMP_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'CommercialVehicle' AS CoverageType,
    'Choice of Repairer' AS Description,
    'COR_SD' AS Type,
    'PMCOR_SD' AS CODE,
     ''  AS IVALUE,
     '' AS SVALUE,
    CASE WHEN T2.SUB_COVERAGE = 'PMCOR_SD' THEN '1' ELSE '0' END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='PMCOR_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.PM_03 T1 LEFT JOIN AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='PMCOR_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'CommercialVehicle' AS CoverageType,
    'Fire & Theft excluding Liability' AS Description,
    'FTL_SD' AS Type,
    'PMFTL_SD' AS CODE,
      ''  AS IVALUE,
     '' AS SVALUE,
    CASE WHEN T2.SUB_COVERAGE = 'PMFTL_SD' THEN '1' ELSE '0' END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='PMFTL_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.PM_03 T1 LEFT JOIN AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='PMFTL_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'CommercialVehicle' AS CoverageType,
    'Comprehensive Liability' AS Description,
    'LIA_SD' AS Type,
    'PMLIA_SD' AS CODE,
      '' AS IVALUE,
     ''AS SVALUE,
    CASE WHEN T2.SUB_COVERAGE = 'PMLIA_SD' THEN '1' ELSE '0' END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='PMLIA_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.PM_03 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='PMLIA_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'CommercialVehicle' AS CoverageType,
    'Car Hire' AS Description,
    'PCH_SD' AS Type,
    'PMPCH_SD' AS CODE,
      ''  AS IVALUE,
     ''AS SVALUE,
    CASE WHEN T2.SUB_COVERAGE = 'PMPCH_SD' THEN '1' ELSE '0' END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='PMPCH_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.PM_03 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='PMPCH_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'CommercialVehicle' AS CoverageType,
    'Third Party Fire & Theft' AS Description,
    'TFT_SD' AS Type,
    'PMTFT_SD' AS CODE,
     ''  AS IVALUE,
     ''AS SVALUE,
    CASE WHEN T2.SUB_COVERAGE = 'PMTFT_SD' THEN '1' ELSE '0' END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='PMTFT_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.PM_03 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND  SUB_COVERAGE='PMTFT_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'CommercialVehicle' AS CoverageType,
    'Third Party Only' AS Description,
    'TPO_SD' AS Type,
    'PMTPO_SD' AS CODE,
    ''  AS IVALUE,
     ''AS SVALUE,
    CASE WHEN T2.SUB_COVERAGE = 'PMTPO_SD' THEN '1' ELSE '0' END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='PMTPO_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.PM_03 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND  SUB_COVERAGE='PMTPO_SD'

UNION ALL

-- ============================================================
-- FIX v2 (ATP-10842) — CORRECTED 2026-07-10 after live regression found in v1.
-- v1 drove INDICATOR straight off T1.EXCESSWAIVERFORGLASS (a per-VEHICLE field) inside a
-- SELECT DISTINCT that is otherwise policy/location-level (one row per PUREPOLICYNUMBER). 210
-- policies have multiple vehicles with DIFFERENT EXCESSWAIVERFORGLASS values, so v1 produced two
-- conflicting PMULG_SD rows for 208 policies instead of one — worse than the original hardcoded-1
-- bug. Corrected by aggregating to one value per policy: MAX (if ANY vehicle on the policy has
-- glass excess waived, treat the whole policy as waived). This is an ASSUMPTION, not a confirmed
-- business rule — MIN (only if ALL vehicles are waived) is an equally plausible alternative; flagging
-- for Aggne to confirm which is correct, but MAX is the safer default (doesn't silently drop a
-- waiver a customer paid for on at least one vehicle).
-- OLD (original hardcode): CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
-- ============================================================
SELECT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'CommercialVehicle' AS CoverageType,
    'Unlimited Glass' AS Description,
    'ULG_SD' AS Type,
    'PMULG_SD' AS CODE,
     ''  AS IVALUE,
     ''AS SVALUE,
    CAST(CAST(MAX(CASE WHEN T1.EXCESSWAIVERFORGLASS IN ('Yes','Taken') THEN 1 ELSE 0 END) AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
    MAX(CASE WHEN T2.SUB_COVERAGE='PMULG_SD' THEN CAST(CAST(COALESCE(T2.EXPPREMIUM,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END) AS EXP_PREM
FROM AGGNE.DEV.PM_03 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND  T2.SUB_COVERAGE='PMULG_SD'
GROUP BY T1.PUREPOLICYNUMBER, T1.cmlnumber, T1.EXPIRINGID_P
;