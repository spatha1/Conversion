-- ============================================================
-- G-39 fix — Clause descriptions forced ALL CAPS + not XML-escaped (seq 17, P3)
-- STORED PROCEDURE: AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD() (~line 8902, PM_02 build)
-- Code-only patch — cosmetic + hygiene, no decision needed.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-09, AGGNE.DEV.COM_CLAUSE, 1,861 rows): 178 rows are forced ALL CAPS
-- (source text like 'No Age Restriction', 'Extended Protection', 'Caravan wording' becomes
-- 'NO AGE RESTRICTION', 'EXTENDED PROTECTION', 'CARAVAN WORDING') — cosmetic, but client-visible
-- on the quote. This is purely PM_02's own UPPER() call — the raw Pure source
-- (PER_CLAUSEAMENDMENTMV.CADescription) already carries normal mixed-case free text.
--
-- ┌─── Clause_Desc (PM_02 build, ~line 8902) ──────────────────────────────────
-- │ OLD CODE (current, live):
-- │   /* SAS: Clause_Desc = UPCASE(CADescription); */
-- │   UPPER(CADescription) AS Clause_Desc,
-- │
-- │ NEW CODE:
-- │   /* Case preserved — forcing ALL CAPS is cosmetic-only and not required by DCT */
-- │   CADescription AS Clause_Desc,
-- └─────────────────────────────────────────────────────────────────────────────
-- NOTE: the internal keyword-matching logic below this (POSITION(...IN UPPER(CADescription))...)
-- is a separate, correct use of UPPER() purely for case-insensitive text search — do not touch that.


-- ============================================================
-- G-39 also shares the XML-escaping defect with G-21 — COM_CLAUSE.DCINPUT is not escaped.
-- VIEW: AGGNE.DEV.COM_CLAUSE
-- LIVE-VERIFIED (2026-07-09): 4 of 1,861 rows contain an unescaped `&`, `<`, or `>`.
-- ============================================================
--
-- ┌─── DCINPUT (COM_CLAUSE final SELECT) ──────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   CAST(CLAUSE_DESC  AS VARCHAR) AS DCINPUT
-- │
-- │ NEW CODE:
-- │   REPLACE(REPLACE(REPLACE(CAST(CLAUSE_DESC AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
-- └─────────────────────────────────────────────────────────────────────────────

create or replace view COM_CLAUSE(
	PUREPOLICYNUMBER,
	EXPIRINGID_P,
	DCCLAUSETYPE,
	DCINPUT
) as
SELECT DISTINCT
CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
CAST(EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
CAST(CLAUSE_TEXT AS VARCHAR) AS DCCLAUSETYPE,
-- FIX: escape XML-breaking characters (was: CAST(CLAUSE_DESC AS VARCHAR))
REPLACE(REPLACE(REPLACE(CAST(CLAUSE_DESC AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
FROM AGGNE.DEV.PM_03 where EXPIRYDATE>='2026-01-01' ;


-- ============================================================
-- PRE-VALIDATION (2026-07-09 baseline)
-- ============================================================

SELECT COUNT(*) AS TOTAL,
    SUM(CASE WHEN DCINPUT = UPPER(DCINPUT) AND DCINPUT <> LOWER(DCINPUT) THEN 1 ELSE 0 END) AS FORCED_CAPS,
    SUM(CASE WHEN (DCINPUT LIKE '%&%' AND DCINPUT NOT LIKE '%&amp;%') OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%' THEN 1 ELSE 0 END) AS UNESCAPED
FROM AGGNE.DEV.COM_CLAUSE;
-- Baseline: TOTAL=1861, FORCED_CAPS~178, UNESCAPED=4


-- ============================================================
-- POST-VALIDATION (after both the SP change and this view are deployed)
-- ============================================================

SELECT COUNT(*) AS TOTAL,
    SUM(CASE WHEN DCINPUT = UPPER(DCINPUT) AND DCINPUT <> LOWER(DCINPUT) THEN 1 ELSE 0 END) AS STILL_FORCED_CAPS,
    SUM(CASE WHEN (DCINPUT LIKE '%&%' AND DCINPUT NOT LIKE '%&amp;%') OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%' THEN 1 ELSE 0 END) AS STILL_UNESCAPED
FROM AGGNE.DEV.COM_CLAUSE;
-- Target: STILL_FORCED_CAPS drops to ~0 (excluding any genuinely all-caps source text);
-- STILL_UNESCAPED = 0
-- ============================================================
