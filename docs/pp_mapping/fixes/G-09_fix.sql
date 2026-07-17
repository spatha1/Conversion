-- ============================================================
-- G-09 fix — ImportType: trailing space + Override-gated blanks (seq 18, Motor, P2)
-- Free text, not a dropdown (confirmed: CoverageLibrary line 33000, no <options> block).
-- NOT YET APPLIED.
-- ============================================================

-- ---------- 1. CODE FIX — trailing space ----------
-- sql/snowflake/stored_procedures/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql, PM_01 build
-- Current: WHEN t3.MVRBImportFlagOV = 3 THEN 'N/A ' (trailing space in the literal)
-- Fix: WHEN t3.MVRBImportFlagOV = 3 THEN 'N/A'   (matches manuscript default exactly, no space)

-- ---------- 2. CODE FIX — Override-gating (same pattern as G-03/G-05/G-06) ----------
-- ImportType is only computed `WHEN t3.MVCVOverride = 1` (raw Pure flag), while Override is
-- force-set to 1 downstream for everyone. Fix together with the other Override-gating corrections.

-- ---------- Verify after applying ----------
-- SELECT '['||IMPORTFLAG||']', COUNT(*) FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
-- -- target: no more '[N/A ]' (trailing space), blank rate drops with the Override-gating fix
