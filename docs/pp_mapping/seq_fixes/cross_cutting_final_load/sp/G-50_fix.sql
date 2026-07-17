-- ============================================================
-- G-50 (NEW, found 2026-07-13 investigating ATP-11089/ATP-11042) — UWAdjustAmount NULL for
-- effectively all HB/HC/SU underwriting adjustments — NULL=NULL join failure
-- STORED PROCEDURE: AGGNE.DEV.SP_PP_ADJ_EXP_PREM() (Adjustments_PER_Out build)
-- ============================================================
--
-- CONTEXT: investigating whether ATP-11089 ("Recurring adjustments not migrating") and ATP-11042
-- ("recurring adjustment incorrectly migrated % to $") are duplicates of the already-known G-19
-- finding. They are NOT — G-19 only found that non-recurring adjustments are excluded upstream
-- (a filter issue); this is a SEPARATE, more severe bug: even RECURRING adjustments that DO make
-- it through the filter almost always carry a blank dollar amount, because of a NULL=NULL join
-- failure — a different bug, same symptom family ("the adjustment isn't showing up").
--
-- ROOT CAUSE CONFIRMED (2026-07-13): `Adjustments_PER_Out` computes UWAdjust via
--   LEFT JOIN AGGNE.DEV.Adjustments_PER a
--     ON e.ExpiringID_P = a.ExpiringID_P AND e.Coverage = a.Coverage AND e.Vehicle_ID = a.Vehicle_ID
-- For HB/HC/SU coverages (non-vehicle-level), Vehicle_ID is NULL on BOTH sides — and in standard
-- SQL, `NULL = NULL` evaluates to unknown, not true, so the join silently fails to match for every
-- HB/HC/SU row. Confirmed live:
--   ExpPremium_PER  : HB/HC/SU all 100% NULL Vehicle_ID (HB 3,521/3,521, HC 2,989/2,989, SU 4,996/4,996)
--   Adjustments_PER : HB/HC 100% NULL Vehicle_ID too (HB 693/693, HC 547/547); SU mostly (78/135)
-- Net effect on Output_UWAdjust_PER.UWAdjustAmount: NULL for 15,476 of 15,913 rows (97.3%) overall —
-- HB, HC, SU are 100% NULL; PM (Motor, which mostly has real matching Vehicle_IDs on both sides) is
-- the only coverage with any real values, and even that is 90.1% NULL.
--
-- Simulated fix (read-only test, not yet applied) using IS NOT DISTINCT FROM instead of a plain =
-- comparison recovers real matches and real computed dollar values:
--   HC: 243 of 547 rows would get a real UWAdjust value (was 0)
--   HB: 314 of 693 rows would get a real UWAdjust value (was 0)
--   SU: 39 of 78 (null-Vehicle_ID) rows would get a real UWAdjust value (was 0)
--
-- This is very likely the actual mechanism behind both ATP-11089 (adjustment silently blank/absent
-- from the schedule even though a row technically exists) and possibly ATP-11042 — worth
-- re-checking ATP-11042's "% vs $" symptom against this fix once deployed, since a NULL
-- UWAdjustAmount may be causing whatever downstream logic picks AdjustmentSelection (%/$) to fall
-- back incorrectly (not yet traced to a specific payload view — PER_HOME_BUILDING_PAYLOAD/
-- PER_COM_PAYLOAD would need checking for how they read Output_UWAdjust_PER's blank amounts).
--
-- ┌─── Adjustments_PER_Out join fix ────────────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   FROM AGGNE.DEV.ExpPremium_PER e
-- │   LEFT JOIN AGGNE.DEV.Adjustments_PER a ON e.ExpiringID_P = a.ExpiringID_P
-- │       AND e.Coverage = a.Coverage
-- │       AND e.Vehicle_ID = a.Vehicle_ID;
-- │
-- │ NEW CODE:
    FROM AGGNE.DEV.ExpPremium_PER e
    LEFT JOIN AGGNE.DEV.Adjustments_PER a ON e.ExpiringID_P = a.ExpiringID_P
        AND e.Coverage = a.Coverage
        AND e.Vehicle_ID IS NOT DISTINCT FROM a.Vehicle_ID;
-- └─────────────────────────────────────────────────────────────────────────────
-- Code-only patch — only this join's comparison operator changes; the UWAdjust CASE formula itself
-- (ExpPremium / (100 + SUM_Adjustments) * AJAdjustmentPercent) is unchanged and confirmed correct.


-- ============================================================
-- PRE-VALIDATION (2026-07-13 baseline)
-- ============================================================
SELECT COUNT(*) TOTAL, SUM(CASE WHEN UWADJUSTAMOUNT IS NULL THEN 1 ELSE 0 END) NULL_AMOUNT
FROM AGGNE.DEV.Output_UWAdjust_PER;
-- Baseline: TOTAL=15913, NULL_AMOUNT=15476 (97.3%)

SELECT COVERAGE, COUNT(*) TOTAL, SUM(CASE WHEN UWADJUSTAMOUNT IS NULL THEN 1 ELSE 0 END) NULL_AMOUNT
FROM AGGNE.DEV.Output_UWAdjust_PER GROUP BY 1;
-- Baseline: HB 3521/3521, HC 2989/2989, SU 4996/4996, PM 3970/4407


-- ============================================================
-- POST-VALIDATION — run after SP_PP_ADJ_EXP_PREM is redeployed and re-run
-- ============================================================
SELECT COUNT(*) TOTAL, SUM(CASE WHEN UWADJUSTAMOUNT IS NULL THEN 1 ELSE 0 END) STILL_NULL
FROM AGGNE.DEV.Output_UWAdjust_PER;
-- Target: STILL_NULL drops sharply, especially for HB/HC/SU

SELECT COVERAGE, COUNT(*) TOTAL, SUM(CASE WHEN UWADJUSTAMOUNT IS NULL THEN 1 ELSE 0 END) STILL_NULL
FROM AGGNE.DEV.Output_UWAdjust_PER GROUP BY 1;
-- Target: HB/HC/SU no longer 100% null

-- Regression check — PM (Motor) rows that already worked must be unaffected
SELECT COUNT(*) AS PM_ROWS_CHANGED
FROM AGGNE.DEV.Output_UWAdjust_PER
WHERE COVERAGE = 'PM' AND UWADJUSTAMOUNT IS NULL;
-- Compare against baseline 3,970 -- should be similar or slightly better (a few PM rows may also
-- have had NULL Vehicle_ID on one side), not worse
-- ============================================================
