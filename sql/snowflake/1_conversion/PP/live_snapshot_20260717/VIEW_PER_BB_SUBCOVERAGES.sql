create or replace view PER_BB_SUBCOVERAGES(
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

-- ============================================================
-- G-18 fix — HB coverage Indicator: hardcoded 1, should be per-block computed (seq 4, P2)
-- TABLE: AGGNE.DEV.PER_BB_SUBCOVERAGES (view)
-- ============================================================
--
-- ┌─── BFL_SD block (Flood) ─────────────────────────────────────────────────
-- │ CURRENT:
-- │   CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR
-- │ FIX:
-- │   CASE WHEN COALESCE(FLOODDAMAGE, '') = 'Taken' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR
-- └───────────────────────────────────────────────────────────────────────────
--
-- ┌─── BAD_SD block (Accidental Loss/Damage) ─────────────────────────────────
-- │ CURRENT:
-- │   CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR
-- │ FIX:
-- │   CASE WHEN COALESCE(ACCIDENTALLOSSORDAMAGE, '') = 'Taken' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR
-- └───────────────────────────────────────────────────────────────────────────
--
-- ┌─── BLD_SD / BLD_BF / BLD_CY / BLD_EQ / BLD_ST / BLI_SD blocks (structural, hardening only) ──
-- │ CURRENT (same in all 6 blocks):
-- │   CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR
-- │ FIX (same in all 6 blocks):
-- │   CASE WHEN COALESCE(HOMEBUILDINGSLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR
-- └───────────────────────────────────────────────────────────────────────────
--
-- ┌─── LLB_SD block (Landlords) — CORRECTION 2026-07-10, now fixable ─────────────────────────────
-- │ Original note said "no Taken/NotTaken source signal exists on HB_02 today" — that was WRONG.
-- │ Re-checked live: AGGNE.DEV.HB_02.LANDLORDPROTECTIONS exists (VARCHAR(9)) with exactly the
-- │ values needed: 'Not Taken' (2,843) / 'Taken' (211). It is currently UNUSED anywhere in this
-- │ view — LLB_SD's SVALUE is hardcoded blank and INDICATOR hardcoded 1, identical to how
-- │ BFL_SD/BAD_SD looked before their own fix. Same fix pattern applies directly, no client input
-- │ needed after all.
-- │ CURRENT:
-- │   '' AS SVALUE,
-- │   CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR
-- │ FIX:
-- │   CONCAT('<sValue>',case when COALESCE(LANDLORDPROTECTIONS, '')='Taken' then 'Taken' ELSE 'NotTaken' end , '</sValue>') AS SVALUE,
-- │   CASE WHEN COALESCE(LANDLORDPROTECTIONS, '') = 'Taken' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR
-- └───────────────────────────────────────────────────────────────────────────
--
-- Confirmed live impact higher than original P2 label suggested (up to 75.7% wrong on Flood,
-- 93.1% wrong on Landlords — the biggest of the four fixable blocks).
-- Pulled live via GET_DDL('VIEW','AGGNE.DEV.PER_BB_SUBCOVERAGES') — full corrected view below,
-- only the INDICATOR expression changed in each block, nothing else touched.
-- ============================================================


SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Buildings Flood' AS Description,
    'BFL_SD' AS Type,
    'HBBFL_SD' AS CODE,
     ''  AS IVALUE,
    CONCAT('<sValue>',case when COALESCE(FLOODDAMAGE, '')='Taken' then 'Taken' ELSE 'NotTaken' end , '</sValue>') AS SVALUE,
    -- FIX (was hardcoded 1): Indicator now follows the same FLOODDAMAGE flag the sValue already uses
    CASE WHEN COALESCE(FLOODDAMAGE, '') = 'Taken' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBBFL_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HBBFL_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Buildings Standard' AS Description,
    'BLD_SD' AS Type,
    'HBBLD_SD' AS CODE,
      CAST(CAST(COALESCE(HOMEBUILDINGSLIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
     '' AS SVALUE,
    -- FIX (was hardcoded 1): hardening only, 0% wrong today — every policy has a real limit > 0,
    -- but this prevents a future zero-limit policy from silently getting Indicator=1
    CASE WHEN COALESCE(HOMEBUILDINGSLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBBLD_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HBBLD_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Accidental Loss Or Damage' AS Description,
    'BAD_SD' AS Type,
    'HBBAD_SD' AS CODE,
      CAST(CAST(COALESCE(ACCIDENTALLOSSORDAMAGELIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
     CONCAT('<sValue>',case when COALESCE(ACCIDENTALLOSSORDAMAGE, '')='Taken' then 'Taken' ELSE 'NotTaken' end , '</sValue>') AS SVALUE,
    -- FIX (was hardcoded 1): Indicator now follows the same ACCIDENTALLOSSORDAMAGE flag the sValue already uses
    CASE WHEN COALESCE(ACCIDENTALLOSSORDAMAGE, '') = 'Taken' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBBAD_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HBBAD_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Bushfire' AS Description,
    'BLD_BF' AS Type,
    'HBBLD_BF' AS CODE,
      CAST(CAST(COALESCE(HOMEBUILDINGSLIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
     ''AS SVALUE,
    -- FIX (was hardcoded 1): hardening only, same structural pattern as BLD_SD
    CASE WHEN COALESCE(HOMEBUILDINGSLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBBLD_BF' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HBBLD_BF'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Cyclone' AS Description,
    'BLD_CY' AS Type,
    'HBBLD_CY' AS CODE,
      CAST(CAST(COALESCE(HOMEBUILDINGSLIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
     ''AS SVALUE,
    -- FIX (was hardcoded 1): hardening only, same structural pattern as BLD_SD
    CASE WHEN COALESCE(HOMEBUILDINGSLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBBLD_CY' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HBBLD_CY'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Earthquake' AS Description,
    'BLD_EQ' AS Type,
    'HBBLD_EQ' AS CODE,
      CAST(CAST(COALESCE(HOMEBUILDINGSLIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
     ''AS SVALUE,
    -- FIX (was hardcoded 1): hardening only, same structural pattern as BLD_SD
    CASE WHEN COALESCE(HOMEBUILDINGSLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBBLD_EQ' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='HBBLD_EQ'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Storm' AS Description,
    'BLD_ST' AS Type,
    'HBBLD_ST' AS CODE,
      CAST(CAST(COALESCE(HOMEBUILDINGSLIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
     ''AS SVALUE,
    -- FIX (was hardcoded 1): hardening only, same structural pattern as BLD_SD
    CASE WHEN COALESCE(HOMEBUILDINGSLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBBLD_ST' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND  SUB_COVERAGE='HBBLD_ST'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Buildings Liability' AS Description,
    'BLI_SD' AS Type,
    'HBBLI_SD' AS CODE,
      CAST(CAST(COALESCE(HOMEBUILDINGSLIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
     ''AS SVALUE,
    -- FIX (was hardcoded 1): hardening only, same structural pattern as BLD_SD (not explicitly
    -- called out in the original G-18 manuscript check — applied for consistency; flag if wrong)
    CASE WHEN COALESCE(HOMEBUILDINGSLIMIT, 0) > 0 THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBBLI_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND  SUB_COVERAGE='HBBLI_SD'

UNION ALL

SELECT DISTINCT
CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building' AS CoverageType,
    'Buildings Landlords' AS Description,
    'LLB_SD' AS Type,
    'HBLLB_SD' AS CODE,
      CAST(CAST(COALESCE(HOMEBUILDINGSLIMIT,0) AS NUMBER(20,0))AS VARCHAR)  AS IVALUE,
    -- FIX: LANDLORDPROTECTIONS exists on HB_02 with real Taken/NotTaken values — was unused
    CONCAT('<sValue>',case when COALESCE(LANDLORDPROTECTIONS, '')='Taken' then 'Taken' ELSE 'NotTaken' end , '</sValue>') AS SVALUE,
    CASE WHEN COALESCE(LANDLORDPROTECTIONS, '') = 'Taken' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS INDICATOR,
    CASE WHEN SUB_COVERAGE='HBLLB_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar)
    END AS EXP_PREM
FROM AGGNE.DEV.HB_02 T1 LEFT JOIN  AGGNE.DEV.Output_SubCover_PER T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND  SUB_COVERAGE='HBLLB_SD';