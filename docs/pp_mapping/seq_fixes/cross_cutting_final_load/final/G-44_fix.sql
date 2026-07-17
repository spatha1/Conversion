-- ============================================================
-- G-44 fix — Account Handler defaults to 'Aaron Pang' for 84% of policies
-- STORED PROCEDURE: AGGNE.DEV.PER_CONVERSION_FINAL_LOAD (~line 106-107)
--
-- RETRACTED 2026-07-10: the "symptom fix" below (blank instead of 'Aaron Pang') is NOT safe to
-- apply as originally claimed. HANDLERMAIL feeds the DCT session's Producer property
-- (Session.setPropertyRq name="Producer" value="{HANDLERMAIL}" in DEV_PER_CONVERSION_FINAL_XML.sql
-- line 20, and ExpressOutput.Producer in the Party manuscript) — not just a display field. Blanking
-- it for the 83% unmatched population risks DCT import/session failure or an unowned quote, which is
-- worse than the cosmetic wrong-name problem. Caught before deployment by the user reviewing the
-- ready batch — see READY_BATCH_20260710_SP_FINAL_LOAD.sql for the full risk note.
--
-- STATUS: back to "needs Aggne decision" — do NOT deploy either version (old or new) without first
-- confirming with Aggne/DCT whether Producer accepts blank, and if not, what a valid fallback should
-- be. Root cause (only 16.7% of PP policies match ACCOUNT_HANDLER at all) also still open.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-09): AGGNE.DEV.PER_FINAL — 4,076 total rows, 46 distinct handlers, 3,424
-- (84%) show 'Aaron Pang' (a real staff member, alphabetically first in
-- VW_ACCOUNT_HANDLER_POLICYTEAM — not a placeholder/test name; the COALESCE fallback was meant as a
-- rare last resort, not a mechanism firing 84% of the time).
--
-- INVESTIGATION (extended past the original draft, live-verified 2026-07-09):
--   T1 (PER_VW_SAMPLE_FINAL) -> T30 (ACCOUNT_HANDLER, _IS_CURRENT=TRUE) join: 3,342 of 4,004 (83.5%)
--   policies find no ACCOUNT_HANDLER row — closely matches the 84% Aaron Pang rate, confirming the
--   miss is upstream of the T30->T31 email match, not in it.
--   Removing the _IS_CURRENT filter barely changes the count (3,335 vs 3,342 missing) — ruling out
--   "filter too strict" as the cause.
--   Set-membership check (ignoring the join/date conditions entirely): of 4,004 distinct PP policy
--   numbers in PER_VW_SAMPLE_FINAL, only 669 (16.7%) exist ANYWHERE in ACCOUNT_HANDLER at all.
--   ACCOUNT_HANDLER has 6,766 rows / 5,113 distinct policies total — it's a real, populated table,
--   it just doesn't cover most PP policies specifically.
--
-- CONCLUSION: this is very likely a genuine data-coverage gap (ACCOUNT_HANDLER's source/population
-- may be scoped mostly to BP or a different policy set, not comprehensive for PP) rather than a
-- join-syntax bug — but that's an inference, not confirmed. NOT ruling out a wrong-source-table bug
-- (i.e. there may be a PP-specific account-handler source this SP should be reading instead).
-- ASK AGGNE: (1) is ACCOUNT_HANDLER expected to cover PP policies at all, or is there a separate
-- PP-specific handler source we should be joining to instead? (2) if blank coverage for 83% of PP
-- policies is expected/known, what should the payload show instead of a specific named person?
--
-- ┌─── HANDLERMAIL / HANDLERFULLNAME (~line 106-107) ──────────────────────────
-- │ OLD CODE (current, live):
-- │   COALESCE(TRIM(T31.ACCOUNTHANDLEREMAIL), 'Aaron.Pang@capricorn.coop') AS HANDLERMAIL,
-- │   COALESCE(TRIM(T31.FULLNAME), 'Aaron Pang') AS HANDLERFULLNAME,
-- │
-- │ NEW CODE (symptom fix — safe to apply now regardless of the open investigation above; stops
-- │ silently attributing unmatched policies to a specific real person):
-- │   COALESCE(TRIM(T31.ACCOUNTHANDLEREMAIL), '') AS HANDLERMAIL,
-- │   COALESCE(TRIM(T31.FULLNAME), '') AS HANDLERFULLNAME,
-- └─────────────────────────────────────────────────────────────────────────────
-- Apply in DEV_PER_CONVERSION_FINAL_LOAD.sql (live SP) and UAT_DEPLOY_FINAL_SPS_20260703.sql.
--
-- POLICY DECISION STILL NEEDED (unchanged from original draft): is a blank handler acceptable to
-- DCT, or does the client want a different placeholder (e.g. "Migration/Unassigned")? This
-- determines whether the symptom fix above is final or needs a different value — apply the symptom
-- fix now to stop the misleading named-person default, revisit the exact blank-vs-placeholder
-- choice once Aggne responds.


-- ============================================================
-- PRE-VALIDATION (2026-07-09 baseline)
-- ============================================================

SELECT COUNT(*) TOTAL, COUNT(DISTINCT HANDLERFULLNAME) DISTINCT_HANDLERS,
       SUM(CASE WHEN HANDLERFULLNAME='Aaron Pang' THEN 1 ELSE 0 END) AARON_PANG_ROWS
FROM AGGNE.DEV.PER_FINAL;
-- Baseline: TOTAL=4076, DISTINCT_HANDLERS=46, AARON_PANG_ROWS=3424 (84%)


-- ============================================================
-- POST-VALIDATION
-- ============================================================

SELECT HANDLERFULLNAME, COUNT(*) AS CNT FROM AGGNE.DEV.PER_FINAL GROUP BY 1 ORDER BY 2 DESC LIMIT 10;
-- Target: 'Aaron Pang' count drops to roughly his real matched share (~669 policies, 16.7%), with
-- the remaining ~83% now blank rather than misattributed — confirms the symptom fix without yet
-- resolving the underlying coverage gap
-- ============================================================
