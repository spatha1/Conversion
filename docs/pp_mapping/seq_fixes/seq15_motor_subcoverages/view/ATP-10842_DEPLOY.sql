-- ============================================================
-- ATP-10842 — DEPLOY — full CREATE OR REPLACE VIEW, pulled fresh from live 2026-07-10 before editing
-- (confirmed identical to the version inspected during investigation, no drift).
-- Only change: PMULG_SD (Unlimited Glass) branch's INDICATOR, now driven by EXCESSWAIVERFORGLASS
-- instead of hardcoded 1. All 7 other branches byte-for-byte unchanged.
-- See ATP-10842_fix.sql in this same folder for the full RCA/before-after detail.
-- ============================================================

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
    CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
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
    CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
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
    CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
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
    CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
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
    CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
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
    CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
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
    CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
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


-- ============================================================
-- POST-VALIDATION — run after deploying v2
-- ============================================================

-- 1) No more duplicate/conflicting PMULG_SD rows per policy (the v1 regression)
SELECT COUNT(*) AS POLICIES_WITH_DUPLICATE_PMULG_SD FROM (
    SELECT PUREPOLICYNUMBER FROM AGGNE.DEV.PER_COM_COVERAGES
    WHERE CODE='PMULG_SD' GROUP BY 1 HAVING COUNT(*) > 1
);
-- Target: 0 (was 208 under v1)

-- 2) Indicator distribution now varies (not 100% hardcoded 1)
SELECT INDICATOR, COUNT(*) FROM AGGNE.DEV.PER_COM_COVERAGES WHERE CODE='PMULG_SD' GROUP BY 1;

-- 3) For single-vehicle policies (unambiguous case), Indicator should exactly match EXCESSWAIVERFORGLASS
SELECT COUNT(*) AS TOTAL,
    SUM(CASE WHEN (p.EXCESSWAIVERFORGLASS='1' AND c.INDICATOR='1') OR (p.EXCESSWAIVERFORGLASS='0' AND c.INDICATOR='0') THEN 1 ELSE 0 END) AS MATCHES
FROM AGGNE.DEV.PER_COM_PAYLOAD p
JOIN AGGNE.DEV.PER_COM_COVERAGES c
  ON c.PUREPOLICYNUMBER = p.PUREPOLICYNUMBER AND c.CODE = 'PMULG_SD'
WHERE p.PUREPOLICYNUMBER IN (
    SELECT PUREPOLICYNUMBER FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 HAVING COUNT(*) = 1
);
-- Target: MATCHES = TOTAL (100% agreement for the unambiguous single-vehicle-per-policy case)
