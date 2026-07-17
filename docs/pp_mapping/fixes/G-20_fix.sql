-- ============================================================
-- G-20 — HB UW Adjustments: wrong-LOB source + output never consumed (seq 5, P1)
-- DECISION NEEDED before any code change. NOT YET APPLIED.
-- ============================================================

-- ---------- Confirmed facts ----------
-- 1. sql/snowflake/1_conversion/PP/views/BUILDING_UW.sql (fetched live, not in repo) reads
--    Output_UWAdjust_BSP + LOCATION_BB_COVERAGE — both Business Protection (BP) staging objects,
--    not Personal (PER). For PP policies this produces no rows, or wrong-population rows.
-- 2. Even where rows land in PER_BUILDING_TARGET (ITR_TYPE=BUILDING_UW), the seq 7 template has
--    NO {UW} token anywhere — HB underwriting adjustments never reach the final XML regardless.
--    Seq 7 also hardcodes <UWAdjustmentIndicator>0</UWAdjustmentIndicator>.
-- Net effect: seq 5's entire output is dead — wrong-sourced AND unconsumed.

-- ---------- DECISION NEEDED — Aggne policy team / client ----------
-- Is HB UW adjustment in scope for conversion at all?
--   IF YES: repoint BUILDING_UW's source to Output_UWAdjust_PER (COVERAGE='HB' — the correct
--   PER-side table, already proven working for seq 11/HC and seq 16/Motor per G-19's
--   investigation), and add {UW} + a real UWAdjustmentIndicator to the seq 7 template.
--   IF NO: retire seq 5 entirely (stop running it) to avoid producing dead rows that cost
--   compute/storage for nothing.
-- Do not guess which — this is a scope question, not a code defect with one obvious answer.

-- ---------- If "yes, in scope" — the fix (once confirmed) ----------
-- Mirror seq 11's already-working view exactly:
--   FROM AGGNE.DEV.Output_UWAdjust_PER WHERE COVERAGE = 'HB'
-- (matches the HB_ADJUST table build already present in SP_PP_ADJ_EXP_PREM — see G-19_fix.sql —
-- Output_UWAdjust_PER already carries HB rows, this table is not missing, just not read by seq 5)
-- Then in the seq 7 template, add {UW} where UnderwritingAdjustment blocks belong, and replace
-- the hardcoded <UWAdjustmentIndicator>0</UWAdjustmentIndicator> with a real derived value.

-- ---------- Verify after a decision is made ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.Output_UWAdjust_PER WHERE COVERAGE='HB';
-- -- shows how many real HB adjustment rows exist and would start flowing if repointed
