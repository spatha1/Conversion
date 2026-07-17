-- ============================================================
-- G-21 fix — Clause/Description free text not XML-escaped (seq 6, HB Clauses, P2)
-- VIEW: AGGNE.DEV.HB_CLAUSE
-- ============================================================
--
-- Same defect pattern applies across 5 views total (seq 6 HB_CLAUSE, seq 8
-- PER_HC_ITEMS_EXCEED_VALUE, seq 9 PER_HC_SPECIFIEDCONTENTS, seq 12 PER_HC_CLAUSE, seq 14
-- PER_RISK_BUILDING_FINAL.SECURITYDETAILS) — a clause/item/security description containing `&`,
-- `<`, or `>` produces malformed XML for the WHOLE policy payload, not just that one field. The UW
-- views already escape `&`; these don't. Seq 17 (Motor, COM_CLAUSE) is handled together with
-- G-38/G-39 (which also touches clause text in that same view) rather than duplicated here.
--
-- LIVE-VERIFIED (2026-07-09): HB_CLAUSE currently has 0 of 16 rows with an unescaped XML-breaking
-- character — no live incident today, this is hardening against future clause text containing one.
--
-- ┌─── DCINPUT (final SELECT) ─────────────────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   CAST(DCINPUT  AS VARCHAR) AS DCINPUT
-- │
-- │ NEW CODE:
-- │   REPLACE(REPLACE(REPLACE(CAST(DCINPUT AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
-- └─────────────────────────────────────────────────────────────────────────────

create or replace view HB_CLAUSE(
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
INNER  JOIN AGGNE.DEV.HB_02 T2 ON trim(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND TRIM(T1.PUREPOLICYBINDERID)=TRIM(T2.EXPIRINGID_P)
WHERE T1.COVERAGE='HB' AND _IS_CURRENT='TRUE';


-- ============================================================
-- PRE/POST-VALIDATION
-- ============================================================

-- PRE (2026-07-09 baseline: 0 rows — no current live incident)
SELECT COUNT(*) AS UNESCAPED_ROWS FROM AGGNE.DEV.HB_CLAUSE
WHERE DCINPUT LIKE '%&%' OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%';

-- POST — same query; target 0, and confirm already-escaped entities aren't double-escaped
SELECT COUNT(*) AS STILL_UNESCAPED FROM AGGNE.DEV.HB_CLAUSE
WHERE (DCINPUT LIKE '%&%' AND DCINPUT NOT LIKE '%&amp;%' AND DCINPUT NOT LIKE '%&lt;%' AND DCINPUT NOT LIKE '%&gt;%')
   OR DCINPUT LIKE '%<%' OR DCINPUT LIKE '%>%';
-- Target: 0
-- ============================================================
