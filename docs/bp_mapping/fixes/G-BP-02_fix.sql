-- ============================================================================
-- G-BP-02 fix — BC Landslide (LND_SD): wrong source column + missing NZ gate
-- (also includes G-BP-75 — BC Hail Storm (HAL_ST) hardcoded Indicator, same
-- view — and G-BP-74's Contents Limit floor in STEP 1/2, same two views)
--
-- *** SUPERSEDED for STEP 1 by fixes/G-BP-76_fix.sql (2026-07-11) *** — see
-- the note further down. STEP 2 (BUILDING_BC_PAYLOAD) is still current.
-- ============================================================================
-- PL101 (Location v1.1, ContentsAndStocksInput.LandSlideLimit): "Hard coded,
-- equals Contents+Stock+Employee Tools of Trade Limits) Note: Cannot exceed
-- Contents+Stock+Employee Tools of Trade Limits. (Max=$250k)" and field is
-- labelled "Landslide Limit NZ ONLY".
--
-- Required value:
--   iValue = LEAST(CONTENTSLIMIT + STOCKLIMITEXVEHICLESWATERCRAFT +
--                   EMPLOYEETOOLSOFTRADELIMIT, 250000)   -- NZ only, else 0
--
-- Two live bugs found (2026-07-11):
-- 1. RISK_BUILDING_BC_COVERAGES's LND_SD branch sources the raw
--    LANDSLIDELIMIT column instead of computing the required formula. Live
--    check: 935 of 1,389 NZ Building Contents records (67.3%) have a raw
--    LANDSLIDELIMIT that does not match LEAST(sum, 250000).
-- 2. The "NZ ONLY" gate that should restrict this coverage is written as
--    `AND TRIM(COUNTRY)='New Zealand'` inside the LEFT JOIN's ON clause
--    (targeting VW_OUTPUT_SUBCOVERAGE_BSP for the premium lookup), not a
--    WHERE/CASE condition — so it has ZERO effect on which policies get an
--    LND_SD row; a LEFT JOIN returns every T1 row regardless of whether the
--    ON condition matches. Confirmed live: 12,495 non-NZ policies currently
--    get an LND_SD row (should be 0 per PL101). Currently harmless in
--    practice only because LANDSLIDELIMIT happens to always be $0/NULL for
--    non-NZ Pure records (0 non-NZ policies show Indicator=1) — but this is
--    a data coincidence, not a structural guarantee, so it's fixed properly
--    here rather than left as a latent risk.
--
-- BUILDING_BC_PAYLOAD (SEQ 53) has a SEPARATE, hardcoded LND_SD coverage
-- block in its own config template that also reads a raw LANDSLIDELIMIT
-- column (same bug) and a country-only LND_SD_INDICATOR (NZ ? 1 : 0, not
-- gated on the computed value > 0) — fixed here too so both places emit the
-- same correct number if they render into the same payload.
--
-- *** UPDATE 2026-07-11, client confirmed the client-visible duplicate (ATP-10947,
-- policy P00010139): "We are seeing a duplicate coverage entry for BCLND_SD
-- ... please review the coverage mapping and ensure there are no duplicate
-- coverages being sent going forward." Root-caused: it is NOT the SEQ50-vs-
-- SEQ53 dual-node issue noted below — it's a missing active-term filter on
-- RISK_BUILDING_BC_COVERAGES itself, which returns BOTH an expired-term row
-- AND the current-term row as separate LND_SD entries whenever a policy has
-- more than one Location_BC_Coverage record. See the dedicated fix:
-- fixes/G-BP-76_fix.sql — RUN THAT FILE'S STEP (which supersedes this
-- file's STEP 1 below) to resolve the actual client-reported duplicate.
-- This file's STEP 1 is kept only for the value-correctness fixes
-- (LND_SD formula, HAL_ST indicator, STD_SD floor); G-BP-76_fix.sql
-- includes all of those PLUS the active-term filter.
--
-- NOTE (flagged, still unresolved, separate question): SEQ 50's LND_SD
-- sub-coverage (rendered via the {SUBCOV} token) and SEQ 53's hardcoded
-- LND_SD block are TWO SEPARATE `<coverage><Type>LND_SD</Type>` nodes in
-- the same final payload — a config-level duplication, not something a
-- view-only fix can resolve (removing one requires a config/template
-- decision). This is a real, separate design question (does DC's schema
-- tolerate two sibling LND_SD nodes) but is NOT what caused the client's
-- ATP-10947 report — that was the active-term issue above, now fixed by
-- G-BP-76. Recommend still confirming with the dev team whether one of the
-- two config occurrences should be dropped, for cleanliness/future-proofing.
--
-- G-BP-75 (new, same view): SEQ 50's HAL_ST branch also hardcoded
-- Indicator='1' regardless of HAILDAMAGE. Live check: 14,216 of 14,533 rows
-- (97.8%) show "Taken" with a $0 limit — the largest single-field impact
-- found this session. Fixed to the same dynamic `limit>0` pattern already
-- used by every other correctly-wired branch in this view.
--
-- FLAGGED, not fixed (needs confirmation): SEQ 53's template also has a
-- SEPARATE hardcoded coverage block, Type="HAL_SD"/Code="BCHAL_SD"/
-- Description="Hail Standard", sourced from the same HAILDAMAGE column via
-- BUILDING_BC_PAYLOAD, with its own hardcoded <Indicator>1</Indicator>
-- baked directly into the SEQ 53 config template (not a view token at all).
-- PL101 only documents "HAL_ST" as a valid BC Hail coverage type — "HAL_SD"
-- does not appear anywhere in PL101. This may be an extra/incorrectly-typed
-- coverage node that either needs its own config-level indicator fix or
-- should be removed entirely — needs a dev-team decision before scripting,
-- same as the LND_SD duplication noted below.
--
-- Scope: view-only, two views. No config change.
--
-- *** RUN THIS FILE'S STEP 2 (BUILDING_BC_PAYLOAD) — BUT FOR STEP 1
-- (RISK_BUILDING_BC_COVERAGES), RUN fixes/G-BP-76_fix.sql INSTEAD ***
-- G-BP-76_fix.sql's single CREATE OR REPLACE already includes every fix in
-- this file's STEP 1 (STD_SD floor / G-BP-74, LND_SD formula / G-BP-02,
-- HAL_ST indicator / G-BP-75) PLUS the active-term filter that resolves the
-- client's actual ATP-10947 duplicate-BCLND_SD report. Running this file's
-- STEP 1 alone would fix the value-correctness issues but NOT the
-- duplication the client asked about.
-- G-BP-74_fix.sql is kept only as a standalone reference for that gap's own
-- register entry — do not run it separately either.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 (Snowflake) — RISK_BUILDING_BC_COVERAGES: fix LND_SD branch only.
-- Every other branch (STD_SD/FLD_SD/SWP_SD/PER_SD/MFL_SD/EMP_SD/VIS_SD/
-- CUV_SD/WIS_SD/CUW_SD/ACC_SD/HAL_ST) is untouched from the G-BP-74 fix
-- above — apply both fixes together as one CREATE OR REPLACE.
-- Re-pull GET_DDL immediately before applying and diff against this.
-- ---------------------------------------------------------------------------

create or replace view RISK_BUILDING_BC_COVERAGES(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	CMLNUMBER,
	COVERAGE,
	COVERAGETYPE,
	DESCRIPTION,
	TYPE,
	CODE,
	IVALUE,
	INDICATOR,
	SVALUE,
	EXP_PREM
) as
SELECT DISTINCT
    CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Contents And Stocks' AS Description,
    'STD_SD' AS Type,
    'BCSTD_SD' AS Code,
    CAST(GREATEST(COALESCE(CONTENTSLIMIT, 0), 30000) AS VARCHAR) AS iValue,
    CAST(1 AS VARCHAR) AS Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCSTD_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCSTD_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Flood' AS Description,
    'FLD_SD' AS Type,
    'BCFLD_SD' AS Code,
    cast(CAST(COALESCE("BCFLOODPROTECTION" ,0) AS NUMBER(20,0)) as varchar) AS iValue,
   case   WHEN  COALESCE("BCFLOODPROTECTION" ,0)::int>0 then '1' else '0' end as Indicator,
CASE WHEN  FLOODDAMAGE='Not Taken' THEN '<sValue>NotTaken</sValue>'
     WHEN  FLOODDAMAGE='Taken' THEN  '<sValue>Taken</sValue>'
     WHEN TRIM(COUNTRY)='New Zealand' THEN '<sValue>Taken</sValue>' -- PL101 NZ default (checked live 2026-07-11: 0/1,389 NZ rows currently hit this branch, kept for robustness)
     else cast('' as varchar) END  AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCFLD_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCFLD_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Stock & Works in Progress' AS Description,
    'SWP_SD' AS Type,
    'BCSWP_SD' AS Code,
    cast(CAST(COALESCE(STOCKLIMITEXVEHICLESWATERCRAFT,0) AS NUMBER(20,0)) as varchar) AS iValue,
       case   WHEN  COALESCE(STOCKLIMITEXVEHICLESWATERCRAFT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCSWP_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCSWP_SD'
UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Handtools' AS Description,
    'PER_SD' AS Type,
    'BCPER_SD' AS Code,
    cast(CAST(COALESCE( PERSONALEFFECTSLIMIT,0) AS NUMBER(20,0)) as varchar) AS iValue,
    case   WHEN  COALESCE(PERSONALEFFECTSLIMIT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCPER_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCPER_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Motor Fuels' AS Description,
    'MFL_SD' AS Type,
    'BCMFL_SD' AS Code,
    cast(CAST(COALESCE(MOTORFUELSLIMIT,0) AS NUMBER(20,0)) as varchar) AS iValue,
    case   WHEN  COALESCE(MOTORFUELSLIMIT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCMFL_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCMFL_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Employees Effects' AS Description,
    'EMP_SD' AS Type,
    'BCEMP_SD' AS Code,
    cast(CAST(COALESCE(EMPLOYEETOOLSOFTRADELIMIT,0) AS NUMBER(20,0)) as varchar) AS iValue,
     case   WHEN  COALESCE(EMPLOYEETOOLSOFTRADELIMIT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCEMP_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCEMP_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Vehicles in Stock' AS Description,
    'VIS_SD' AS Type,
    'BCVIS_SD' AS Code,
    cast(cast(COALESCE(VEHICLESINSTOCKLIMIT,0) AS NUMBER(20,0)) as varchar) AS iValue,
     case   WHEN  COALESCE(VEHICLESINSTOCKLIMIT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCVIS_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCVIS_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Customer Vehicles' AS Description,
    'CUV_SD' AS Type,
    'BCCUV_SD' AS Code,
    cast(cast(COALESCE(CUSTOMERSVEHICLESLIMIT,0) AS NUMBER(20,0)) as varchar) AS iValue,
     case   WHEN  COALESCE(CUSTOMERSVEHICLESLIMIT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCCUV_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCCUV_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Watercraft in Stock' AS Description,
    'WIS_SD' AS Type,
    'BCWIS_SD' AS Code,
    cast(cast(COALESCE(WATERCRAFTINSTOCKUNDER8MLIMIT,0) AS NUMBER(20,0)) as varchar) AS iValue,
     case   WHEN  COALESCE(WATERCRAFTINSTOCKUNDER8MLIMIT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCWIS_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCWIS_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Customers Watercraft' AS Description,
    'CUW_SD' AS Type,
    'BCCUW_SD' AS Code,
    cast(cast(COALESCE(CUSTOMERSWATERCRAFTUNDER8MLIMIT,0) AS NUMBER(20,0)) as varchar) AS iValue,
    case   WHEN  COALESCE(CUSTOMERSWATERCRAFTUNDER8MLIMIT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCCUW_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCCUW_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Accidental Damage' AS Description,
    'ACC_SD' AS Type,
    'BCACC_SD' AS Code,
    cast(cast(COALESCE(ACCIDENTALLOSSORDAMAGELIMIT,0) AS NUMBER(20,0)) as varchar) AS iValue,
    case   WHEN  COALESCE(ACCIDENTALLOSSORDAMAGELIMIT ,0)::int>0 then '1' else '0' end as Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCACC_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCACC_SD'

UNION ALL
SELECT DISTINCT
 CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Hail Storm' AS Description,
    'HAL_ST' AS Type,
    'BCHAL_ST' AS Code,
    cast(cast(COALESCE(HAILDAMAGE,0) AS NUMBER(20,0)) as varchar) AS iValue,
    -- FIXED (G-BP-75): was hardcoded '1' regardless of HAILDAMAGE — 14,216 of
    -- 14,533 rows (97.8%) showed "Taken" with a $0 limit. PL101
    -- (ContentsAndStocksInput.HailDamagetoVehiclesorWatercraftsInStockLimit)
    -- confirms HAL_ST is the only documented Hail coverage type for BC.
    case WHEN COALESCE(HAILDAMAGE,0)::int>0 then '1' else '0' end AS Indicator,
    '' AS SVALUE,
    CASE WHEN SUB_COVERAGE='BCHAL_ST' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='BCHAL_ST'
UNION ALL
    -- ── LND_SD : Landslide (FIXED, G-BP-02) ──────────────────────
    -- iValue = LEAST(Contents+Stock+EmployeeTools, 250000), NZ only.
    -- Country gate moved from the (ineffective) LEFT JOIN ON-clause into
    -- the SELECT itself — a LEFT JOIN's ON-clause never filters the left
    -- table's rows, only whether the right table matches.
SELECT
    CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    T1.cmlnumber,
    T1.EXPIRINGID_P AS Coverage,
    'Building_BC' AS CoverageType,
    'Landslide' AS Description,
    'LND_SD' AS Type,
    'BCLND_SD' AS Code,
    CASE WHEN TRIM(COUNTRY)='New Zealand'
         THEN CAST(LEAST(COALESCE(CONTENTSLIMIT,0)+COALESCE(STOCKLIMITEXVEHICLESWATERCRAFT,0)+COALESCE(EMPLOYEETOOLSOFTRADELIMIT,0), 250000) AS VARCHAR)
         ELSE '0' END AS iValue,
    CASE WHEN TRIM(COUNTRY)='New Zealand'
              AND LEAST(COALESCE(CONTENTSLIMIT,0)+COALESCE(STOCKLIMITEXVEHICLESWATERCRAFT,0)+COALESCE(EMPLOYEETOOLSOFTRADELIMIT,0), 250000) > 0
         THEN '1' ELSE '0' END AS Indicator,
    '' AS sValue,
    CASE WHEN SUB_COVERAGE='BCLND_SD' THEN CAST(CAST(COALESCE(EXPPREMIUM ,0) AS NUMBER(36,3)) AS VARCHAR) ELSE cast(0 as varchar) END AS EXP_PREM
FROM AGGNE.DEV.Location_BC_Coverage T1 LEFT JOIN  AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP T2 ON CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR)=T2.PUREPOLICYNUMBER AND SUB_COVERAGE='BCLND_SD'
;

-- POST-CHECK (Snowflake)
-- SELECT COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_BC_COVERAGES WHERE TYPE='HAL_ST' AND INDICATOR='1' AND CAST(IVALUE AS INT)=0;
-- Expect 0 (was 14,216 of 14,533 before this fix, G-BP-75).
-- SELECT COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_BC_COVERAGES r
-- JOIN AGGNE.DEV.Location_BC_Coverage l ON r.PUREPOLICYNUMBER=CAST(TRIM(l.PUREPOLICYNUMBER)||'|'||TRIM(l.cmlnumber)||'|'||TRIM(l.EXPIRINGID_P) AS VARCHAR)
-- WHERE r.TYPE='LND_SD' AND TRIM(l.COUNTRY)='New Zealand'
--   AND CAST(r.IVALUE AS INT) <> LEAST(COALESCE(l.CONTENTSLIMIT,0)+COALESCE(l.STOCKLIMITEXVEHICLESWATERCRAFT,0)+COALESCE(l.EMPLOYEETOOLSOFTRADELIMIT,0), 250000);
-- Expect 0 (was 935 before this fix, G-BP-02).
-- SELECT COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_BC_COVERAGES r
-- JOIN AGGNE.DEV.Location_BC_Coverage l ON r.PUREPOLICYNUMBER=CAST(TRIM(l.PUREPOLICYNUMBER)||'|'||TRIM(l.cmlnumber)||'|'||TRIM(l.EXPIRINGID_P) AS VARCHAR)
-- WHERE r.TYPE='LND_SD' AND TRIM(l.COUNTRY)<>'New Zealand' AND r.INDICATOR='1';
-- Expect 0.


-- ============================================================================
-- STEP 2 (Snowflake) — BUILDING_BC_PAYLOAD: apply the same LEAST() formula
-- to LANDSLIDELIMIT (feeds SEQ 53's separate hardcoded LND_SD block) and
-- make LND_SD_INDICATOR consistent with the computed value, not just country.
-- Combine with the G-BP-74 CONTENTSLIMIT floor fix — apply as one
-- CREATE OR REPLACE (both edits shown together below).
-- Re-pull GET_DDL immediately before applying and diff against this.
-- ============================================================================

create or replace view BUILDING_BC_PAYLOAD(
	PUREPOLICYNUMBER,
	COVERAGE,
	SUBCOV,
	UW,
	LOC_BC_CLAUSE,
	VOLUNTARYEXCESS,
	BUSINESSCONTENTS_IND,
	PROPORTIONOFHAILNETTING,
	BCCLMCNT,
	BCCLMINCD,
	BCEXPPREM,
	CONTENTSLIMIT,
	LANDSLIDELIMIT,
	EXP_PREM_BCHAL_SD,
	EXP_PREM_BCLND_SD,
	EXP_PREM_BCSTD_BF,
	EXP_PREM_BCSTD_CY,
	EXP_PREM_BCSTD_EQ,
	EXP_PREM_BCSTD_ST,
	HAILDAMAGE,
	LND_SD_INDICATOR,
	LOAD_DATE
) as
 with cte_SAMPLE_CBP_LOCATION as
(
select distinct T1.PUREPOLICYNUMBER,T1.cmlnumber,T1.EXPIRINGID from AGGNE.DEV.Location_01 T1 INNER JOIN AGGNE.DEV.SAMPLE_CBP T2 ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
-- and
-- T1.EXPIRINGID=T2.EXPIRINGID_P
WHERE t1.EXPIRYDATE>='2026-01-01'
),cte_COVERAGES as
(
select distinct PUREPOLICYNUMBER,cmlnumber,EXPIRINGID_P,'BC' AS CLAUSE,'ContentsAndStocks' AS  COVERAGE, CAST(VOLUNTARYEXCESS AS VARCHAR) AS VOLUNTARYEXCESS,
 CAST(GREATEST(COALESCE(CONTENTSLIMIT,0), 30000) AS VARCHAR) AS CONTENTSLIMIT,
CAST(BUSINESSCONTENTS_IND AS VARCHAR) AS BUSINESSCONTENTS_IND ,
cast(cast(COALESCE(HAILDAMAGE,0) AS NUMBER(20,0)) as varchar) AS HAILDAMAGE,
-- FIXED (G-BP-02): LEAST(Contents+Stock+EmployeeTools, 250000), NZ only.
CASE WHEN TRIM(COUNTRY)='New Zealand'
     THEN LEAST(COALESCE(CONTENTSLIMIT,0)+COALESCE(STOCKLIMITEXVEHICLESWATERCRAFT,0)+COALESCE(EMPLOYEETOOLSOFTRADELIMIT,0), 250000)
     ELSE 0 END AS LANDSLIDELIMIT,
CAST(PROPORTIONOFHAILNETTING AS VARCHAR) AS PROPORTIONOFHAILNETTING,COUNTRY
FROM AGGNE.DEV.Location_BC_Coverage T1  WHERE EXPIRYDATE>='2026-01-01' --10767
)
, CTE_EXCESS AS(
SELECT
CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,T2.cmlnumber,T2.EXPIRINGID_P,COVERAGE,CAST(VOLUNTARYEXCESS AS VARCHAR) AS VOLUNTARYEXCESS,
CAST(BUSINESSCONTENTS_IND AS VARCHAR) AS BUSINESSCONTENTS_IND ,
cast(cast(COALESCE(HAILDAMAGE,0) AS NUMBER(20,0)) as varchar) AS HAILDAMAGE,
 CAST(CONTENTSLIMIT AS VARCHAR) AS CONTENTSLIMIT,LANDSLIDELIMIT,
CAST(PROPORTIONOFHAILNETTING AS VARCHAR) AS PROPORTIONOFHAILNETTING,COUNTRY
FROM
cte_SAMPLE_CBP_LOCATION T1
INNER JOIN cte_COVERAGES T2 ON T1.EXPIRINGID =T2.EXPIRINGID_P
AND TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) --1185
)
,CTE_LISTAGG AS(
SELECT
  ID,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_Risk_Building_BC_Subcov' THEN payload END, '\n') AS SUBCOV,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_RISK_BUILDING_BC_UW'     THEN payload END, '\n') AS UW,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_LOC_BC_CLAUSE'     THEN payload END, '\n') AS LOC_BC_CLAUSE,
  CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM AGGNE.DEV.RISK_BUILDING_BC_TARGET
WHERE ITR_TYPE IN ('BP_Risk_Building_BC_Subcov', 'BP_RISK_BUILDING_BC_UW','BP_LOC_BC_CLAUSE')
GROUP BY ID,CAST(LOAD_DATE AS DATE)
),
SUB_COV_PREM AS (
SELECT
  PUREPOLICYNUMBER,
BCHAL_SD,
BCLND_SD,
BCSTD_BF,
BCSTD_CY,
BCSTD_EQ,
BCSTD_ST
FROM (
  SELECT PUREPOLICYNUMBER, SUB_COVERAGE, EXPPREMIUM
  FROM AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP
) src
PIVOT (
  SUM(EXPPREMIUM) FOR SUB_COVERAGE IN (
    ('BCHAL_SD') AS BCHAL_SD,
    ('BCLND_SD') AS BCLND_SD,
    ('BCSTD_BF') AS BCSTD_BF,
    ('BCSTD_CY') AS BCSTD_CY,
    ('BCSTD_EQ') AS BCSTD_EQ,
    ('BCSTD_ST') AS BCSTD_ST
    )
) p
)
SELECT distinct
T1.PUREPOLICYNUMBER,
COVERAGE,CAST(SUBCOV AS VARCHAR) AS SUBCOV,
CAST(UW AS VARCHAR) AS UW,
CASE WHEN LOC_BC_CLAUSE IS NOT NULL AND LOC_BC_CLAUSE<> '' THEN '<Clauses><Type>ContentsAndStocks</Type>'||CAST(LOC_BC_CLAUSE AS VARCHAR)||'</Clauses>' ELSE '' END AS LOC_BC_CLAUSE,
-- CAST(LOC_BC_CLAUSE AS VARCHAR) AS LOC_BC_CLAUSE,
 CAST(CAST(COALESCE(VOLUNTARYEXCESS,0) AS NUMBER(20,0)) AS VARCHAR) AS VOLUNTARYEXCESS,
CAST(CAST(COALESCE(BUSINESSCONTENTS_IND,0) AS NUMBER(20,0)) AS VARCHAR) AS BUSINESSCONTENTS_IND ,
CAST(CAST(PROPORTIONOFHAILNETTING AS NUMBER(20,0)) AS VARCHAR) AS PROPORTIONOFHAILNETTING,
 CAST(CAST(COALESCE(T4.BCCLMCNT,0) AS NUMBER(20,0)) AS VARCHAR) AS BCCLMCNT,
 CAST(CAST(COALESCE(T4.BCCLMINCD,0) AS NUMBER(20,0)) AS VARCHAR) AS  BCCLMINCD,
 CAST(COALESCE(T4.BCEXPPREM,0) AS VARCHAR) AS  BCEXPPREM,
 CAST(CAST(COALESCE(CONTENTSLIMIT,0) AS NUMBER(20,0))AS VARCHAR) AS CONTENTSLIMIT,
  CAST(CAST(COALESCE(LANDSLIDELIMIT,0) AS NUMBER(20,0))AS VARCHAR) AS  LANDSLIDELIMIT,
 CAST(COALESCE(CAST(BCHAL_SD AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BCHAL_SD,
 CAST(COALESCE(CAST(BCLND_SD AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BCLND_SD,
 CAST(COALESCE(CAST(BCSTD_BF AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BCSTD_BF,
 CAST(COALESCE(CAST(BCSTD_CY AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BCSTD_CY,
 CAST(COALESCE(CAST(BCSTD_EQ AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BCSTD_EQ,
 CAST(COALESCE(CAST(BCSTD_ST AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_BCSTD_ST,
cast(cast(COALESCE(HAILDAMAGE,0) AS NUMBER(20,0)) as varchar) AS HAILDAMAGE,
-- FIXED (G-BP-02): Indicator now matches the computed LANDSLIDELIMIT value,
-- not just country membership.
CASE WHEN TRIM(T1.COUNTRY)='New Zealand' AND COALESCE(LANDSLIDELIMIT,0)>0
     THEN CAST(CAST(1 AS NUMBER(3,0)) AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(1,0)) AS VARCHAR) END AS LND_SD_INDICATOR ,
 CAST(GETDATE() AS DATE) AS LOAD_DATE
 FROM CTE_EXCESS T1
--  INNER JOIN  AGGNE.DEV.RISK_BUILDING_BC_TARGET T2
-- ON T1.PUREPOLICYNUMBER=T2.ID
LEFT JOIN CTE_LISTAGG T3 ON T1.PUREPOLICYNUMBER = T3.ID
LEFT JOIN AGGNE.DEV.VW_OUTPUT_COVERAGE_BSP T4 ON T1.PUREPOLICYNUMBER=T4.PUREPOLICYNUMBER
LEFT JOIN SUB_COV_PREM T5 ON T1.PUREPOLICYNUMBER=T5.PUREPOLICYNUMBER
WHERE   COVERAGE='ContentsAndStocks';

-- POST-CHECK (Snowflake)
-- SELECT MIN(CAST(CONTENTSLIMIT AS INT)) FROM AGGNE.DEV.BUILDING_BC_PAYLOAD;
-- Expect >= 30000.
-- SELECT COUNT(*) FROM AGGNE.DEV.BUILDING_BC_PAYLOAD WHERE LND_SD_INDICATOR='1' AND CAST(LANDSLIDELIMIT AS INT)=0;
-- Expect 0 (Indicator/value now always consistent).
