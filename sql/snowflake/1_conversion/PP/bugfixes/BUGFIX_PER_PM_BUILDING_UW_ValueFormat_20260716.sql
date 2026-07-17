-- ============================================================================
-- Fixes AGGNE.DEV.PER_PM_BUILDING_UW: RECURRINGINDICATOR and ADJUSTMENTSELECTION
-- were hardcoded to numeric '1', but the DCT manuscript defines both as string
-- enums, not booleans/numbers -- DCT silently failed to bind them, contributing
-- (together with the Type='PM' vs required 'Vehicle' bug, see companion fix
-- BUGFIX_PP_CONVERSION_RUN_VehicleUWAdjustment_20260716.sql) to Underwriting
-- Adjustments not materializing in Express (Detail grid showed "NoResultsFound",
-- UW Adjustment stayed $0.00).
--
-- Root cause confirmed against the live DCT manuscript
-- (Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/CarrierCoverageLibrary/
-- Carrier_CoverageLibrary_Data_1_0_0_0.xml, VehicleUWAdjustmentInput object):
--   RecurringIndicator  (path Recurring/sValue,   type string) -- options: "Yes" / "No"
--   AdjustmentSelection (path AdjustmentSelection, type string) -- options: "Percent" / "Dollar"
-- Our source (Output_UWAdjust_PER) only ever produces dollar-amount adjustments,
-- never percent, so AdjustmentSelection is safely hardcoded to 'Dollar' (matching
-- the existing $-only assumption already baked into this view). Recurring is
-- hardcoded to 'Yes' -- same as the prior '1' was intended to mean recurring=true;
-- this view has never distinguished recurring vs non-recurring adjustments
-- (that distinction is the separate, already-tracked G-19 scope question).
--
-- Client-reported (2026-07-16): "Underwriting adjustments also not working."
-- Confirmed live on P00009639/CML00005281 (quote Q0132756/Q0132757 in DEV).
--
-- Source of truth: full live GET_DDL of this view, pulled 2026-07-16 -- only the
-- two hardcoded '1' values changed, rest is byte-identical to what is live today.
--
-- STATUS: DRAFTED, NOT APPLIED. SAFE_MODE -- user must run this.
-- ============================================================================

create or replace view PER_PM_BUILDING_UW(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	EXPIRINGID_P,
	CMLNUMBER,
	RECURRINGINDICATOR,
	UNDERWRITINGDESCRIPTION,
	ADJUSTMENTDOLLARANDPERCENT,
	ADJUSTMENTSELECTION,
	COVERAGE
) as
SELECT DISTINCT
    CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    CAST(T1.POLICYNUMBER AS VARCHAR) AS LEGACYPOLICYNUMBER,
    CAST(T1.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
    CAST(T2.cmlnumber AS VARCHAR) AS CMLNUMBER,
    CAST('Yes'  AS VARCHAR)AS RECURRINGINDICATOR,
    CAST(REPLACE(REPLACE(T1.UWADJUSTNOTE,  '&', '&amp;'),'''', '''''') AS VARCHAR) AS UnderwritingDescription,
    CAST(T1.UWADJUSTAMOUNT AS VARCHAR) AS AdjustmentDollarAndPercent,
    CAST('Dollar'  AS VARCHAR)AS AdjustmentSelection,
    CAST(T1.COVERAGE AS VARCHAR) AS COVERAGE
FROM AGGNE.DEV.Output_UWAdjust_PER T1
INNER JOIN AGGNE.DEV.PM_03 T2
    ON T1.POLICYNUMBER = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    WHERE COVERAGE='PM' AND UWADJUSTAMOUNT IS NOT NULL AND UWADJUSTAMOUNT != 0;
