-- ============================================================
-- RETRACTED 2026-07-10 — DO NOT DEPLOY THIS FILE AS WRITTEN
-- ============================================================
-- User caught a real risk in the original draft below before it was deployed: HANDLERMAIL is not
-- just a display field. It is used as the DCT session's Producer property —
--   Session.setPropertyRq name="Producer" value="{HANDLERMAIL}"
-- (sql/snowflake/1_conversion/PP/sps/DEV_PER_CONVERSION_FINAL_XML.sql line 20) — set BEFORE the
-- import even begins, and the same value feeds ExpressOutput.Producer in
-- Manuscripts/.../CarrierAdmin/Party/Carrier_Party_Base_Data_3_0_0_0.xml. This is the identity DCT
-- uses to create the quote, not free text.
--
-- VW_ACCOUNT_HANDLER_POLICYTEAM (the lookup this SP joins to) is a curated whitelist of exactly 129
-- real staff logins — strongly suggesting Producer must resolve to a valid DCT user account. Sending
-- '' for the 83% of policies that don't match risks either an outright import/session failure or an
-- unowned, unfindable quote — for potentially 3,400+ policies. That is a materially worse outcome
-- than the cosmetic "wrong name shown" problem this fix was meant to solve.
--
-- STATUS: G-44 moves OUT of the ready-no-client-question batch, back to "needs Aggne confirmation."
-- Two things must be answered before any change here:
--   1. Does DCT's Producer property accept blank, or does it require a real/valid producer login?
--      (Test in DEV against an actual DCT session before trusting either answer — this cannot be
--      confirmed from Snowflake data alone.)
--   2. If blank is unsafe, what should the 83%-unmatched policies use instead — the current
--      'Aaron Pang' default (misleading but known-safe), a different real "house" account if one
--      exists (none found in today's 129-row whitelist), or does Aggne want ACCOUNT_HANDLER's
--      coverage gap fixed at the source instead (still the deeper, unresolved root cause)?
--
-- UNTIL ANSWERED: leave PER_CONVERSION_FINAL_LOAD's HANDLERMAIL/HANDLERFULLNAME COALESCE exactly as
-- it is today (defaulting to 'Aaron.Pang@capricorn.coop' / 'Aaron Pang'). Do not apply the patch
-- below.
-- ============================================================


-- ============================================================
-- ORIGINAL DRAFT (retracted, kept for reference only — DO NOT APPLY)
-- ============================================================
-- STORED PROCEDURE: AGGNE.DEV.PER_CONVERSION_FINAL_LOAD() (~line 106-107)
--
-- ┌─── HANDLERMAIL / HANDLERFULLNAME (~line 106-107) ──────────────────────────
-- │ OLD CODE (current, live — UNCHANGED, do not touch until the questions above are answered):
-- │   COALESCE(TRIM(T31.ACCOUNTHANDLEREMAIL), 'Aaron.Pang@capricorn.coop') AS HANDLERMAIL,
-- │   COALESCE(TRIM(T31.FULLNAME), 'Aaron Pang') AS HANDLERFULLNAME,
-- │
-- │ RETRACTED NEW CODE (do not apply — see risk note above):
-- │   COALESCE(TRIM(T31.ACCOUNTHANDLEREMAIL), '') AS HANDLERMAIL,
-- │   COALESCE(TRIM(T31.FULLNAME), '') AS HANDLERFULLNAME,
-- └─────────────────────────────────────────────────────────────────────────────


-- ============================================================
-- PRE-VALIDATION (2026-07-10 baseline, reconfirm before deploying)
-- ============================================================
SELECT COUNT(*) TOTAL, COUNT(DISTINCT HANDLERFULLNAME) DISTINCT_HANDLERS,
       SUM(CASE WHEN HANDLERFULLNAME='Aaron Pang' THEN 1 ELSE 0 END) AARON_PANG_ROWS
FROM AGGNE.DEV.PER_FINAL;
-- Baseline (2026-07-09): TOTAL=4076, DISTINCT_HANDLERS=46, AARON_PANG_ROWS=3424 (84%)


-- ============================================================
-- POST-VALIDATION — run after the SP is redeployed and PER_CONVERSION_FINAL_LOAD() re-runs
-- ============================================================
SELECT HANDLERFULLNAME, COUNT(*) AS CNT FROM AGGNE.DEV.PER_FINAL GROUP BY 1 ORDER BY 2 DESC LIMIT 10;
-- Target: 'Aaron Pang' count drops to roughly his real matched share (~669 policies, 16.7%); the
-- remaining ~83% show blank rather than a misattributed named person
-- ============================================================
