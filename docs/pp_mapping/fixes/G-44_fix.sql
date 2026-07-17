-- ============================================================
-- G-44 — Account Handler defaults to 'Aaron Pang' for 84% of policies
-- Symptom fix only (stop the silent hardcoded default) + open investigation into the join miss.
-- NOT YET APPLIED. Needs a policy decision (see bottom) before the COALESCE default is removed.
-- ============================================================

-- ---------- Data ----------
-- SELECT COUNT(*) TOTAL, COUNT(DISTINCT HANDLERFULLNAME) DISTINCT_HANDLERS,
--        SUM(CASE WHEN HANDLERFULLNAME='Aaron Pang' THEN 1 ELSE 0 END) AARON_PANG_ROWS
-- FROM AGGNE.DEV.PER_FINAL;
-- Result: 4,076 total, 46 distinct handlers, 3,424 (84%) show 'Aaron Pang'.

-- ---------- Root cause (immediate) ----------
-- PER_CONVERSION_FINAL_LOAD (sql/snowflake/1_conversion/PP/sps/DEV_PER_CONVERSION_FINAL_LOAD.sql,
-- line ~106-107; same in UAT_DEPLOY_FINAL_SPS_20260703.sql and the BUG-NEW-04 fix file):
--
--   COALESCE(TRIM(T31.ACCOUNTHANDLEREMAIL), 'Aaron.Pang@capricorn.coop') AS HANDLERMAIL,
--   COALESCE(TRIM(T31.FULLNAME), 'Aaron Pang') AS HANDLERFULLNAME,
--
-- T31 = AGGNE.DEV.VW_ACCOUNT_HANDLER_POLICYTEAM, a legitimate ~180-row lookup of real Capricorn
-- staff (Aaron Pang is real personnel, alphabetically first in the view — not a placeholder/test
-- name). The join chain feeding T31 is:
--   T1 (PER_VW_SAMPLE_FINAL) --[LEGACYPOLICYNUMBER]--> T30 (ACCOUNT_HANDLER, _IS_CURRENT=TRUE)
--     --[LOWER(EMAIL)]--> T31 (VW_ACCOUNT_HANDLER_POLICYTEAM, LOWER(ACCOUNTHANDLEREMAIL))
-- The COALESCE was presumably meant as a rare last-resort fallback, but it's firing 84% of the
-- time — meaning the T1->T30 or T30->T31 join is failing for most policies, not that most policies
-- genuinely have no handler.

-- ---------- Investigation needed before the real fix ----------
-- SELECT COUNT(*) AS TOTAL, SUM(CASE WHEN T30.PUREPOLICYNUMBER IS NULL THEN 1 ELSE 0 END) AS NO_ACCOUNT_HANDLER_ROW
-- FROM AGGNE.DEV.PER_VW_SAMPLE_FINAL T1
-- LEFT JOIN AGGNE.DEV.ACCOUNT_HANDLER T30
--   ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T30.PUREPOLICYNUMBER) AND T30._IS_CURRENT = TRUE;
-- -- If NO_ACCOUNT_HANDLER_ROW is ~84%, the miss is in ACCOUNT_HANDLER itself (stale/incomplete
-- -- table, or _IS_CURRENT filter too strict). If it's low, the miss is in the T30->T31 email match
-- -- (case/whitespace/domain mismatch) instead — check that join specifically next.

-- ---------- Symptom fix (apply only after the policy decision below) ----------
-- Replace the named-person fallback with a blank, so unmatched policies surface as a validation
-- finding instead of silently reporting a specific person as the handler for policies they don't
-- own:
--
--   COALESCE(TRIM(T31.ACCOUNTHANDLEREMAIL), '') AS HANDLERMAIL,
--   COALESCE(TRIM(T31.FULLNAME), '') AS HANDLERFULLNAME,
--
-- Apply in DEV_PER_CONVERSION_FINAL_LOAD.sql (live SP) and UAT_DEPLOY_FINAL_SPS_20260703.sql.

-- ---------- Policy decision needed ----------
-- Is a blank handler acceptable to DCT (does the UI/downstream handle a blank Account Handler
-- gracefully), or does the client want a different genuine default (e.g. a "Migration/Unassigned"
-- queue) instead of leaving it blank? This determines whether the symptom fix above is final or
-- needs a different placeholder value.

-- ---------- Verify after applying ----------
-- SELECT HANDLERFULLNAME, COUNT(*) AS CNT FROM AGGNE.DEV.PER_FINAL GROUP BY 1 ORDER BY 2 DESC LIMIT 10;
-- -- target: 'Aaron Pang' count should drop to roughly his real share of policies, not 84%.
