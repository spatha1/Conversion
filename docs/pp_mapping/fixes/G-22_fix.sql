-- ============================================================
-- G-22 — HB Indicator hardcoded 1 (seq 7, P1)
-- Pure code fix, no decision needed. 0 live impact today, real structural risk. NOT YET APPLIED.
-- ============================================================

-- ---------- Data ----------
-- PER_HOME_BUILDING_PAYLOAD.HB_INDICATOR is NEVER '0' in the current dataset (0 rows) —
-- HC_INDICATOR varies (734 rows = '0', i.e. HB-only policies exist and are correctly flagged that
-- direction). This means today's data has HB-only and HB+HC policies, but no true HC-only policy
-- — so the specific bug (HC-only policy getting a bogus HB block) doesn't currently fire. It is
-- still a live defect waiting for the first genuine HC-only policy to appear on a future run.

-- ---------- CODE FIX ----------
-- seq 7 template (PP_ConversionConfig, RISK_Building_HB): <Indicator>1</Indicator>
-- Replace with: <Indicator>{HB_INDICATOR}</Indicator>
-- The view (PER_HOME_BUILDING_PAYLOAD) already computes HB_INDICATOR correctly from the
-- HB_01/HC_02 union — no view change needed, config-only template fix.

-- ---------- Verify after applying ----------
-- SELECT HB_INDICATOR, COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD GROUP BY 1;
-- -- confirms distribution matches what should now appear in the emitted Indicator tag
