-- ============================================================================
-- Fixes PER_PM_BUILDING_UW: Vehicle Underwriting Adjustment field values did
-- not match DCT's actual Private Motor UW Adjustments spec.
--
-- Confirmed 2026-07-16 by Sadhanala Teja (Duck Creek/policy team) via Teams
-- (Capricorn - Quick Policy Conversion Quick connect, 10:51): for Personal
-- Protection Private Motor, the UW Adjustments group should be:
--   Type = Motor (separate fix, see BUGFIX_PP_CONVERSION_RUN_MotorUWAdjustmentGroup)
--   AdjustmentSelection: 0=%, 1=$  (numeric, NOT the string 'Percent'/'Dollar'
--     the manuscript's VehicleUWAdjustment object implied)
--   AdjustmentAmount: float, should be populated (NOT left blank as DCT-computed
--     -- that assumption was based on the wrong manuscript object, VehicleUWAdjustment;
--     the correct object, CommercialVehicleUWAdjustment [Type="Motor"], has no
--     readOnly flag on AdjustmentAmount)
--   Recurring/Indicator: 1=Yes, 0=No (numeric, path Indicator -- separate fix in
--     PP_CONVERSION_RUN changes the template path from Recurring/sValue)
--
-- This view currently hardcodes RECURRINGINDICATOR='Yes' and
-- AdjustmentSelection='Dollar' for every row (not derived from real per-row
-- source data -- Output_UWAdjust_PER has no such columns). Translating the same
-- hardcoded assumption into the new numeric spec: 'Yes'->'1', 'Dollar'->'1'.
-- AdjustmentAmount is new -- reuses UWADJUSTAMOUNT (same source as
-- AdjustmentDollarAndPercent), since no separate pre-computed-amount column
-- exists in Output_UWAdjust_PER.
--
-- Source of truth: full live GET_DDL of this view, pulled 2026-07-16, with ONLY
-- the 3 verified single-match string replaces below applied.
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
	ADJUSTMENTAMOUNT,
	COVERAGE
) as
SELECT DISTINCT
    CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    CAST(T1.POLICYNUMBER AS VARCHAR) AS LEGACYPOLICYNUMBER,
    CAST(T1.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
    CAST(T2.cmlnumber AS VARCHAR) AS CMLNUMBER,
    CAST('1'  AS VARCHAR)AS RECURRINGINDICATOR,
    CAST(REPLACE(REPLACE(T1.UWADJUSTNOTE,  '&', '&amp;'),'''', '''''') AS VARCHAR) AS UnderwritingDescription,
    CAST(T1.UWADJUSTAMOUNT AS VARCHAR) AS AdjustmentDollarAndPercent,
    CAST('1'  AS VARCHAR)AS AdjustmentSelection,
    CAST(T1.UWADJUSTAMOUNT AS VARCHAR) AS AdjustmentAmount,
    CAST(T1.COVERAGE AS VARCHAR) AS COVERAGE
FROM AGGNE.DEV.Output_UWAdjust_PER T1
INNER JOIN AGGNE.DEV.PM_03 T2
    ON T1.POLICYNUMBER = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    WHERE COVERAGE='PM' AND UWADJUSTAMOUNT IS NOT NULL AND UWADJUSTAMOUNT != 0;