-- ============================================================
-- G-21 fix — Clause/Description free text not XML-escaped (seq 12, HC Clauses, P2)
-- VIEW: AGGNE.DEV.PER_HC_CLAUSE
-- ============================================================
--
-- Same defect/fix as seq 6 (HB_CLAUSE) — see that file for full cross-view context.
--
-- LIVE-VERIFIED (2026-07-09): PER_HC_CLAUSE currently has 0 of 41 rows with an unescaped
-- XML-breaking character — no live incident today, this is hardening.
--
-- ┌─── DCINPUT (final SELECT) ─────────────────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   CAST(DCINPUT  AS VARCHAR) AS DCINPUT
-- │
-- │ NEW CODE:
-- │   REPLACE(REPLACE(REPLACE(CAST(DCINPUT AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
-- └─────────────────────────────────────────────────────────────────────────────

create or replace view PER_HC_CLAUSE(
	PUREPOLICYNUMBER,
	PUREPOLICYBINDERID,
	EXPIRINGID_P,
	DCCLAUSETYPE,
	DCINPUT
) as
SELECT DISTINCT
CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
CAST(T1.PUREPOLICYBINDERID AS VARCHAR) AS PUREPOLICYBINDERID,
CAST(T2.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
CAST(DCCLAUSETYPE AS VARCHAR) AS DCCLAUSETYPE,
-- FIX: escape XML-breaking characters (was: CAST(DCINPUT AS VARCHAR))
REPLACE(REPLACE(REPLACE(CAST(DCINPUT AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
FROM AGGNE.DEV.CLAUSES T1
INNER  JOIN AGGNE.DEV.HC_02 T2 ON trim(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND TRIM(T1.PUREPOLICYBINDERID)=TRIM(T2.EXPIRINGID_P)
WHERE T1.COVERAGE='HC' AND _IS_CURRENT='TRUE';


-- ============================================================
-- PRE/POST-VALIDATION
-- ============================================================

SELECT COUNT(*) AS UNESCAPED_ROWS FROM AGGNE.DEV.PER_HC_CLAUSE
WHERE DCINPUT LIKE '%&%' OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%';
-- PRE baseline (2026-07-09): 0

SELECT COUNT(*) AS STILL_UNESCAPED FROM AGGNE.DEV.PER_HC_CLAUSE
WHERE (DCINPUT LIKE '%&%' AND DCINPUT NOT LIKE '%&amp;%' AND DCINPUT NOT LIKE '%&lt;%' AND DCINPUT NOT LIKE '%&gt;%')
   OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%';
-- Target: 0
-- ============================================================
