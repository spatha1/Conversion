-- ============================================================
-- G-28 — {clauses} unresolved token in seq 13 (P1)
-- Pure code fix (config-only), no decision needed. NOT YET APPLIED.
-- ============================================================

-- ---------- Data ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_TARGET WHERE ITR_TYPE='RISK_Building_HC' AND PAYLOAD LIKE '%{clauses}%';
-- Result: 0 — the literal '{clauses}' text is NOT currently leaking into generated payloads
-- (likely because the token substitution engine drops unresolved tokens silently rather than
-- printing them literally). That's not good news though — it means the token resolves to nothing,
-- so HC clauses are silently ABSENT rather than visibly broken.
--
-- SELECT COUNT(DISTINCT ID) FROM AGGNE.DEV.PER_HC_TARGET WHERE ITR_TYPE='LOC_HC_CLAUSE';
-- Result: 41 — 41 policies have HC clause rows loaded (seq 12 output exists) that never reach the
-- HC coverage block because the token name doesn't match the view's column.

-- ---------- CODE FIX ----------
-- seq 13 template (RISK_Building_HC, PP_ConversionConfig): the token substitution engine resolves
-- tokens by matching the view's column names. The view's column is HC_CLAUSE, not "clauses".
--   Replace {clauses} with {HC_CLAUSE} in the seq 13 template.
-- No view change needed — HC_CLAUSE already exists and is correctly populated.

-- ---------- Verify after applying ----------
-- Re-run conversion, then:
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_TARGET
-- WHERE ITR_TYPE='RISK_Building_HC' AND (PAYLOAD LIKE '%{clauses}%' OR PAYLOAD LIKE '%{HC_CLAUSE}%');
-- -- target: 0 unresolved tokens of either form; the 41 orphaned-clause policies should now show
-- -- their clauses inside the HC block
