-- ============================================================================
-- G-BP-30 fix — FLEET_VEHICLE_SUBCOVERAGES (SEQ 56) hardcoded Indicator
--
-- *** SUPERSEDED by fixes/G-BP-88_fix.sql *** — that file's STEP 1 includes
-- this exact Indicator fix PLUS the composite-key widening (G-BP-88), since
-- both touch the same view. Run G-BP-88_fix.sql instead (all 3 views + the
-- SEQ 56 config change). Kept only as the standalone record for this gap.
-- ============================================================================
-- CORRECTION OF A STALE REGISTER CLAIM: this gap was marked "view+config fix
-- scripted, verified against live protection-type data" from an earlier
-- session. Verified live 2026-07-12 — the config still hardcodes
-- <Indicator>1</Indicator> unconditionally, and the view has no INDICATOR
-- column at all. The claimed fix was never actually applied.
--
-- ROOT CAUSE: `base` CTE unions 5 sources per vehicle — the vehicle's own
-- selected protection type (Comprehensive/Third Party Only/etc, "primary"),
-- plus 4 fixed "optional extra" rows (On Hook, Unlimited Glass, Car Hire,
-- Choice of Repairer) regardless of whether Pure actually shows them taken.
-- The primary branch's Indicator=1 is correct-by-design (it's literally the
-- vehicle's own selected type, always "taken"). The 4 optional-extra
-- branches should be dynamic — CASE WHEN <field>='Not Taken'/'Not
-- Protected' THEN 0 ELSE 1 — but the config hardcodes all 5 branches to 1.
--
-- Live impact (2026-07-12), VEHICLECOVERAGES_FLEETVEHICLE, 1,222 vehicles:
--   OHL_SD (On Hook)         : 1,222 / 1,222 (100.0%) show Indicator=1 with
--                              ONHOOK=0 for every single vehicle in the
--                              entire Fleet portfolio — the largest-scope
--                              mismatch found in this entire BP pass.
--   TCH_SD (Car Hire)        : 1,192 / 1,222 (97.5%) — CARHIRE 'Not Taken'/blank.
--   COR_SD (Choice of Repair): 464 / 1,222 (38.0%) — CHOICEOFREPAIR 'Not Taken'/blank.
--   ULG_SD (Unlimited Glass) : 128 / 1,222 (10.5%) — UNLIMITEDGLASS 'Not Protected'.
--
-- NOTE: this fix is independent of G-BP-88 (the composite-key/per-vehicle
-- identity issue, same view family) — it only changes the Indicator
-- computation within the existing key shape, it does not touch the key
-- itself, so it's safe to apply without resolving G-BP-88 first.
--
-- Scope: view + config. No key/join changes.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- Re-pull GET_DDL / live config immediately before applying and diff.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 (Snowflake) — FLEET_VEHICLE_SUBCOVERAGES: add dynamic INDICATOR.
-- ---------------------------------------------------------------------------

create or replace view FLEET_VEHICLE_SUBCOVERAGES(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	EXPIRINGID_P,
	PROTECTIONTYPE,
	FLTYPE,
	FLCODE,
	ACCESSORIESVALUE,
	INDICATOR,
	EXPPREMIUM
) as with base as (
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        protectiontype,
        accessoriesvalue,
        '1' as row_indicator  -- primary/selected protection type: always taken
    from
        AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE
    union all
    select
        distinct cmlnumber,
        purepolicynumber,
        expiringid_p,
        'onhook' as protectiontype,
        onhook as accessoriesvalue,
        CASE WHEN COALESCE(onhook,0)::int > 0 THEN '1' ELSE '0' END as row_indicator
        -- FIXED (G-BP-30): was hardcoded '1' in config regardless of ONHOOK.
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
        end as accessoriesvalue,
        CASE WHEN unlimitedglass = 'Not Protected' THEN '0' ELSE '1' END as row_indicator
        -- FIXED (G-BP-30): was hardcoded '1' in config regardless of UNLIMITEDGLASS.
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
        end as accessoriesvalue,
        CASE WHEN COALESCE(carhire,'Not Taken') = 'Not Taken' OR TRIM(carhire) = '' THEN '0' ELSE '1' END as row_indicator
        -- FIXED (G-BP-30): was hardcoded '1' in config regardless of CARHIRE.
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
        end as accessoriesvalue,
        CASE WHEN COALESCE(choiceofrepair,'Not Taken') = 'Not Taken' OR TRIM(choiceofrepair) = '' THEN '0' ELSE '1' END as row_indicator
        -- FIXED (G-BP-30): was hardcoded '1' in config regardless of CHOICEOFREPAIR.
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
        row_indicator
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
    row_indicator AS INDICATOR,
    cast(EXPPREMIUM as varchar) as EXPPREMIUM
FROM
    SUB_COV A
    LEFT JOIN EXP_PRE B ON TRIM(A.PUREPOLICYNUMBER) = TRIM(B.PUREPOLICYNUMBER)
    AND TRIM(A.FLCODE) = TRIM(B.SUB_COVERAGE);

-- POST-CHECK (Snowflake)
-- SELECT FLTYPE, INDICATOR, COUNT(*) FROM AGGNE.DEV.FLEET_VEHICLE_SUBCOVERAGES GROUP BY 1,2 ORDER BY 1,2;
-- Expect: CMP_SD/TPO_SD/TFT_SD/FTL_SD/LIA_SD all Indicator='1' (unchanged, correct-by-design).
-- OHL_SD/ULG_SD/TCH_SD/COR_SD now show a mix of '0'/'1' matching the ONHOOK/
-- UNLIMITEDGLASS/CARHIRE/CHOICEOFREPAIR distributions above.

-- ---------------------------------------------------------------------------
-- STEP 2 (Azure ConversionConfig) — SEQ 56 (BP_fleet_coverage_Vehicle_SubCov):
-- wire the token. PRE-CHECK, then UPDATE, then POST-CHECK.
-- ---------------------------------------------------------------------------

-- PRE-CHECK
-- SELECT SequenceID, ConversionScript FROM ConversionConfig WHERE SequenceID = 56;
-- Confirm it still reads exactly:
--   <coverage>
--   <Indicator>1</Indicator>
--   ...

-- UPDATE
UPDATE ConversionConfig
SET ConversionScript = REPLACE(
    ConversionScript,
    '<Indicator>1</Indicator>',
    '<Indicator>{INDICATOR}</Indicator>'
)
WHERE SequenceID = 56;

-- POST-CHECK
-- SELECT SequenceID, ConversionScript FROM ConversionConfig WHERE SequenceID = 56;
-- Confirm it now reads:
--   <Indicator>{INDICATOR}</Indicator>
