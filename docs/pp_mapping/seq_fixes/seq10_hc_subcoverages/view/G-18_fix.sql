-- ============================================================
-- G-18 fix (HC side) — Home Contents sub-coverage Indicator hardcoded 1, should be per-block computed
-- VIEW: AGGNE.DEV.PER_HC_SUBCOVERAGES (seq 10, HC Sub-Coverages, P2)
-- Live-verified 2026-07-09 — same defect pattern as the HB side (seq04 G-18, PER_BB_SUBCOVERAGES,
-- already fixed) but on the Home Contents equivalent view, sourced from AGGNE.DEV.HC_02.
-- ============================================================
--
-- CONTEXT: Carrier_PersonalProtectionBase_1_0_0_0.xml gives each sub-coverage block its own
-- computed Indicator rule (limit>0 for structural blocks; the block's own Taken/NotTaken sValue for
-- Flood/Accidental Damage) — none of them are meant to be a flat hardcoded 1. Two of the 8 HC
-- blocks (HCCFL_SD Flood, HCCAD_SD Accidental Damage) ALREADY carry the correct sValue in this view
-- — the Indicator column next to it is hardcoded 1 regardless, ignoring the sValue that's sitting
-- right there. The remaining structural blocks (HCCNT_SD, HCCNT_BF/CY/EQ/ST, HCCLI_SD) have no
-- live defect today (HomeContentsLimit_new is never 0 in current data) but hardening prevents a
-- future zero-limit policy from silently getting Indicator=1. HCSPE_SD (Specified Items) has no
-- limit or sValue exposed in this view at all — left unchanged, same as HB's LLB_SD situation.
--
-- LIVE IMPACT (2026-07-09, AGGNE.DEV.HC_02, 2,553 policies):
--   FLOODDAMAGE:            'Not Taken' 2,008 (78.7%) / 'Taken' 545 (21.3%)
--   ACCIDENTALLOSSORDAMAGE: 'Taken' 1,357 (53.2%) / 'Not Taken' 1,196 (46.8%)
--   -> 2,008 policies currently show Flood Indicator=1 despite sValue=NotTaken (should be 0)
--   -> 1,196 policies currently show Accidental Damage Indicator=1 despite sValue=NotTaken (should be 0)
--   HOMECONTENTSLIMIT_NEW = 0: 0 rows today (structural-block fix is hardening only, no current impact)
--
-- ┌─── HCCFL_SD (Flood) block ─────────────────────────────────────────────────
-- │ OLD: CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR   -- always 1, ignores the sValue
-- │ NEW: CAST(CASE WHEN COALESCE(FLOODDAMAGE,'')='Taken' THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR
-- └─────────────────────────────────────────────────────────────────────────────
-- ┌─── HCCAD_SD (Accidental Damage) block ─────────────────────────────────────
-- │ OLD: CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR   -- always 1, ignores the sValue
-- │ NEW: CAST(CASE WHEN COALESCE(ACCIDENTALLOSSORDAMAGE,'')='Taken' THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR
-- └─────────────────────────────────────────────────────────────────────────────
-- ┌─── HCCNT_SD / HCCNT_BF / HCCNT_CY / HCCNT_EQ / HCCNT_ST / HCCLI_SD (structural) ───
-- │ OLD: CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR   -- always 1
-- │ NEW: CAST(CASE WHEN COALESCE(HOMECONTENTSLIMIT_NEW,0) > 0 THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR
-- └─────────────────────────────────────────────────────────────────────────────
-- ┌─── HCSPE_SD (Specified Items) block ───────────────────────────────────────
-- │ UNCHANGED — no limit or sValue column exposed for this block in HC_02; left hardcoded pending
-- │ a source signal (same open status as HB's LLB_SD)
-- └─────────────────────────────────────────────────────────────────────────────

create or replace view PER_HC_SUBCOVERAGES(
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
    'Building' AS CoverageType,
    'Standard' AS Description,
    'CNT_SD' AS Type,
    'HCCNT_SD' AS CODE,
    CAST(CAST(COALESCE(HOMECONTENTSLIMIT_NEW,0) AS NUMBER(10,0)) AS VARCHAR)   AS IVALUE,
     '' AS SVALUE,
    -- FIX: structural block, Indicator derived from limit>0 (was hardcoded 1)
    CAST(CASE WHEN COALESCE(HOMECONTENTSLIMIT_NEW,0) > 0 THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCCNT_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCCNT_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Accidental Damage' AS Description,
    'CAD_SD' AS Type,
    'HCCAD_SD' AS CODE,
    CAST(CAST(COALESCE(ACCIDENTALLOSSORDAMAGELIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
     CONCAT('<sValue>',case when COALESCE(ACCIDENTALLOSSORDAMAGE, '')='Taken' then 'Taken' ELSE 'NotTaken' end , '</sValue>') AS SVALUE,
    -- FIX: sValue already exists on this row — drive Indicator from it instead of hardcoding 1
    CAST(CASE WHEN COALESCE(ACCIDENTALLOSSORDAMAGE,'')='Taken' THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCCAD_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCCAD_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Specified Items' AS Description,
    'SPE_SD' AS Type,
    'HCSPE_SD' AS CODE,
    ''  AS IVALUE,
    '' AS SVALUE,
    -- UNCHANGED: no limit/sValue signal exposed for this block — same open status as HB's LLB_SD
    CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCSPE_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCSPE_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Bushfire' AS Description,
    'CNT_BF' AS Type,
    'HCCNT_BF' AS CODE,
    CAST(CAST(COALESCE(HOMECONTENTSLIMIT_NEW,0) AS NUMBER(10,0)) AS VARCHAR)   AS IVALUE,
    '' AS SVALUE,
    CAST(CASE WHEN COALESCE(HOMECONTENTSLIMIT_NEW,0) > 0 THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCCNT_BF' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCCNT_BF'
UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Cyclone' AS Description,
    'CNT_CY' AS Type,
    'HCCNT_CY' AS CODE,
    CAST(CAST(COALESCE(HOMECONTENTSLIMIT_NEW,0) AS NUMBER(10,0)) AS VARCHAR)   AS IVALUE,
    '' AS SVALUE,
    CAST(CASE WHEN COALESCE(HOMECONTENTSLIMIT_NEW,0) > 0 THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCCNT_CY' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCCNT_CY'
UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Earthquake' AS Description,
    'CNT_EQ' AS Type,
    'HCCNT_EQ' AS CODE,
    CAST(CAST(COALESCE(HOMECONTENTSLIMIT_NEW,0) AS NUMBER(10,0)) AS VARCHAR)   AS IVALUE,
    '' AS SVALUE,
    CAST(CASE WHEN COALESCE(HOMECONTENTSLIMIT_NEW,0) > 0 THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCCNT_EQ' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCCNT_EQ'
UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Storm' AS Description,
    'CNT_ST' AS Type,
    'HCCNT_ST' AS CODE,
    CAST(CAST(COALESCE(HOMECONTENTSLIMIT_NEW,0) AS NUMBER(10,0)) AS VARCHAR)   AS IVALUE,
    '' AS SVALUE,
    CAST(CASE WHEN COALESCE(HOMECONTENTSLIMIT_NEW,0) > 0 THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCCNT_ST' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCCNT_ST'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Flood' AS Description,
    'CFL_SD' AS Type,
    'HCCFL_SD' AS CODE,
    CAST(CAST(COALESCE(HCHOMEHOBBYFARMFLOODPROTECTION,0) AS NUMBER(10,0)) AS VARCHAR)   AS IVALUE,
    CONCAT('<sValue>',case when COALESCE(FLOODDAMAGE, '')='Taken' then 'Taken' ELSE 'NotTaken' end , '</sValue>') AS SVALUE,
    -- FIX: sValue already exists on this row (and drives G-30's coverage-level FloodDamage tag) —
    -- drive Indicator from the same signal instead of hardcoding 1
    CAST(CASE WHEN COALESCE(FLOODDAMAGE,'')='Taken' THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCCFL_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCCFL_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Contents Liability' AS Description,
    'CLI_SD' AS Type,
    'HCCLI_SD' AS CODE,
    CAST(CAST(COALESCE(HOMECONTENTSLIMIT_NEW,0) AS NUMBER(10,0)) AS VARCHAR)   AS IVALUE,
    '' AS SVALUE,
    CAST(CASE WHEN COALESCE(HOMECONTENTSLIMIT_NEW,0) > 0 THEN 1 ELSE 0 END AS VARCHAR) AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HCCLI_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HC_02 T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2
ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HCCLI_SD'
;


-- ============================================================
-- PRE-VALIDATION — run BEFORE applying (2026-07-09 baseline; re-run for current counts)
-- ============================================================

SELECT CODE, INDICATOR, COUNT(*) FROM AGGNE.DEV.PER_HC_SUBCOVERAGES
WHERE CODE IN ('HCCFL_SD','HCCAD_SD') GROUP BY 1,2 ORDER BY 1,2;
-- 2026-07-09 baseline: HCCAD_SD/1 = 2,553 (100%, always 1 today); HCCFL_SD/1 = 2,553 (100%, always 1 today)


-- ============================================================
-- POST-VALIDATION — run AFTER deploying
-- ============================================================

-- 1) Flood/Accidental Damage Indicator now matches sValue
SELECT CODE, SVALUE, INDICATOR, COUNT(*)
FROM AGGNE.DEV.PER_HC_SUBCOVERAGES
WHERE CODE IN ('HCCFL_SD','HCCAD_SD')
GROUP BY 1,2,3 ORDER BY 1,2;
-- Target: HCCFL_SD rows with sValue NotTaken -> Indicator 0 (~2,008); Taken -> Indicator 1 (~545)
--         HCCAD_SD rows with sValue NotTaken -> Indicator 0 (~1,196); Taken -> Indicator 1 (~1,357)

-- 2) Structural blocks — confirm no regression (should still all be Indicator=1 today, since limit
--    is never 0 in current data; this just confirms the hardening didn't break anything live)
SELECT CODE, INDICATOR, COUNT(*)
FROM AGGNE.DEV.PER_HC_SUBCOVERAGES
WHERE CODE IN ('HCCNT_SD','HCCNT_BF','HCCNT_CY','HCCNT_EQ','HCCNT_ST','HCCLI_SD')
GROUP BY 1,2 ORDER BY 1,2;
-- Target: all still Indicator=1 today (0 rows with a zero limit) — confirms hardening is a no-op
-- on current data, not a behavior change

-- 3) HCSPE_SD unchanged
SELECT CODE, INDICATOR, COUNT(*) FROM AGGNE.DEV.PER_HC_SUBCOVERAGES
WHERE CODE = 'HCSPE_SD' GROUP BY 1,2;
-- Target: still Indicator=1 for all rows (unchanged, as documented above)
-- ============================================================
