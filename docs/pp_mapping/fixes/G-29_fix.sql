-- ============================================================
-- G-29 — HC Indicator hardcoded 1 (seq 13, P1)
-- Pure code fix, no decision needed. Real, confirmed live impact. NOT YET APPLIED.
-- ============================================================

-- ---------- Data ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD WHERE HC_INDICATOR = '0';
-- Result: 734 — 734 policies are HB-only (no HC cover at all) but currently receive a full HC
-- coverage block with Indicator=1 and (per G-30/G-31/G-32) fabricated FloodDamage/HomeContentsLimits/
-- totals on top. Confirmed real, not a latent risk like the seq 7 mirror (G-22) — this direction
-- of the bug is actively firing in the current dataset.

-- ---------- CODE FIX ----------
-- seq 13 template (PP_ConversionConfig, RISK_Building_HC): <Indicator>1</Indicator>
-- Replace with: <Indicator>{HC_INDICATOR}</Indicator>
-- The view (PER_HOME_BUILDING_PAYLOAD) already computes HC_INDICATOR correctly — config-only fix.

-- ---------- Verify after applying ----------
-- SELECT HC_INDICATOR, COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD GROUP BY 1;
-- -- 734 policies should now emit Indicator=0 on their HC block
