-- ============================================================================
-- G-BP-89 fix — FL_MOTOR_UW (SEQ 60): AdjustmentSelection never wired
-- ============================================================================
-- SEQ 60's config template (BP_FL_Motor_UW) has:
--   <AdjustmentSelection></AdjustmentSelection>
-- a bare, permanently-empty tag with no token at all — unlike every one of
-- the other 14 shared UW-adjustment views in this codebase (BC/BI/BG/Money/
-- EN/Property), which all hardcode AdjustmentSelection='1' in the view and
-- wire it via {ADJUSTMENTSELECTION}. FL_MOTOR_UW's view doesn't even output
-- an ADJUSTMENTSELECTION column to wire.
--
-- Live impact (2026-07-12): 0 — there are currently 0 live Fleet UW-
-- adjustment notes (Output_UWAdjust_BSP, COVERAGE='FL') at all, so this has
-- no current effect on any policy. Fixed anyway per this session's standard
-- of correcting structural defects regardless of current data coverage —
-- if a Fleet UW adjustment note is ever entered in Pure, it would otherwise
-- render with every field populated except a permanently blank
-- AdjustmentSelection.
--
-- Scope: view (adds ADJUSTMENTSELECTION column, matching the same hardcoded
-- '1' pattern used by every sibling UW view) + config (wires the new token).
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- Re-pull GET_DDL / live config immediately before applying and diff.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 (Snowflake) — FL_MOTOR_UW: add ADJUSTMENTSELECTION column.
-- ---------------------------------------------------------------------------

create or replace view FL_MOTOR_UW(
	PUREPOLICYNUMBER,
	POLICYNUMBER,
	EXPIRINGID_P,
	CMLNUMBER,
	RECURRINGIND,
	ADJUSTMENTTYPE,
	COVERAGE,
	UWADJUSTNOTE,
	UWADJUSTAMOUNT,
	ADJUSTMENTSELECTION
) as
    SELECT distinct
    CAST(trim(A.PUREPOLICYNUMBER) ||'|' || TRIM(A.cmlnumber) ||'|' || TRIM(A.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    POLICYNUMBER,
    A.EXPIRINGID_P,
    A.CMLNUMBER,
    '1' AS RECURRINGIND,
    '1' AS ADJUSTMENTTYPE,
       COVERAGE,
    UWADJUSTNOTE,
    CAST(UWADJUSTAMOUNT AS VARCHAR) AS UWADJUSTAMOUNT,
    '1' AS ADJUSTMENTSELECTION
    -- FIXED (G-BP-89): new column, matches the hardcoded '1' pattern used by
    -- every sibling UW-adjustment view (BC/BI/BG/Money/EN/Property).
FROM
AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE A INNER JOIN
AGGNE.DEV.OUTPUT_UWADJUST_BSP B ON TRIM(A.PUREPOLICYNUMBER) = TRIM(B.POLICYNUMBER)
AND TRIM(A.EXPIRINGID_P) = TRIM(B.EXPIRINGID_P)
AND TRIM(A.CMLNUMBER) = TRIM(B.CMLNUMBER)
WHERE B.COVERAGE = 'FL' AND UWADJUSTNOTE IS NOT NULL ;

-- POST-CHECK (Snowflake)
-- SELECT COUNT(*) FROM AGGNE.DEV.FL_MOTOR_UW WHERE ADJUSTMENTSELECTION IS NULL;
-- Expect 0.

-- ---------------------------------------------------------------------------
-- STEP 2 (Azure ConversionConfig) — SEQ 60 (BP_FL_Motor_UW): wire the token.
-- PRE-CHECK, then UPDATE, then POST-CHECK.
-- ---------------------------------------------------------------------------

-- PRE-CHECK
-- SELECT SequenceID, ConversionScript FROM ConversionConfig WHERE SequenceID = 60;
-- Confirm it still reads exactly:
--   <AdjustmentSelection></AdjustmentSelection>

-- UPDATE
UPDATE ConversionConfig
SET ConversionScript = REPLACE(
    ConversionScript,
    '<AdjustmentSelection></AdjustmentSelection>',
    '<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>'
)
WHERE SequenceID = 60;

-- POST-CHECK
-- SELECT SequenceID, ConversionScript FROM ConversionConfig WHERE SequenceID = 60;
-- Confirm it now reads:
--   <AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
