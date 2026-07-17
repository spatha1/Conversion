-- ============================================================
-- G-27 fix (combined with G-21 for this view) — HC Specified Contents: missing empty-item filter
-- + Description not XML-escaped (seq 9, P2)
-- VIEW: AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS
-- This file is the single owner of this view's CREATE OR REPLACE — it includes BOTH G-27 (filter)
-- and G-21 (escaping) fixes. Do not also deploy this folder's G-21_fix.sql standalone (it's a
-- cross-reference note only, not a separate script).
-- ============================================================
--
-- G-27 CONTEXT: every HC_02 row produces a <SpecifiedContents> node regardless of whether the
-- policy actually has any specified item — this can mark the "Specified Contents" section as
-- selected on a policy with nothing to specify. Same fix pattern already applied at seq 8
-- (PER_HC_ITEMS_EXCEED_VALUE: WHERE VALUE IS NOT NULL AND VALUE > 0).
--
-- LIVE-VERIFIED (2026-07-09, AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS): of policies where VALUE is
-- '<Value></Value>' or '<Value>0</Value>', 2,139 of 2,553 rows (83.8%) are empty/zero — every
-- HC_02 row currently emits a node.
--
-- G-21 CONTEXT: DESCRIPTIONSPECIFIED is not XML-escaped. 15 of 2,553 rows contain an unescaped `&`
-- — real, live-breaking impact (malformed XML for the whole policy, not just this field).
--
-- ┌─── WHERE clause (adds the empty-item filter) ──────────────────────────────
-- │ OLD: (no WHERE clause at all — every HC_02 row within date range is emitted)
-- │   FROM AGGNE.DEV.HC_02 WHERE EFFECTIVEDATE>='2026-01-01';
-- │ NEW:
-- │   FROM AGGNE.DEV.HC_02
-- │   WHERE EFFECTIVEDATE >= '2026-01-01'
-- │     AND VALUESPECIFIED IS NOT NULL AND VALUESPECIFIED > 0;
-- └─────────────────────────────────────────────────────────────────────────────
-- ┌─── DESCRIPTION (adds XML escaping) ────────────────────────────────────────
-- │ OLD:
-- │   CONCAT('<Description>',case when DESCRIPTIONSPECIFIED IS NOT NULL then  CAST(DESCRIPTIONSPECIFIED AS VARCHAR) ELSE '' end , '</Description>') AS DESCRIPTION
-- │ NEW:
-- │   CONCAT('<Description>',case when DESCRIPTIONSPECIFIED IS NOT NULL
-- │        then REPLACE(REPLACE(REPLACE(CAST(DESCRIPTIONSPECIFIED AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
-- │        ELSE '' end , '</Description>') AS DESCRIPTION
-- └─────────────────────────────────────────────────────────────────────────────

create or replace view PER_HC_SPECIFIEDCONTENTS(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	VALUE,
	DESCRIPTION
) as
SELECT
    CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    CONCAT('<Value>',case when VALUESPECIFIED IS NOT NULL then cast(CAST(COALESCE(VALUESPECIFIED ,0) AS NUMBER(10,0))as varchar) ELSE '' end , '</Value>') AS VALUE,
    -- FIX (G-21): escape XML-breaking characters
    CONCAT('<Description>',case when DESCRIPTIONSPECIFIED IS NOT NULL
        then REPLACE(REPLACE(REPLACE(CAST(DESCRIPTIONSPECIFIED AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
        ELSE '' end , '</Description>') AS DESCRIPTION
    FROM
    AGGNE.DEV.HC_02
    -- FIX (G-27): only emit a node when there's an actual specified item
    WHERE EFFECTIVEDATE >= '2026-01-01'
      AND VALUESPECIFIED IS NOT NULL AND VALUESPECIFIED > 0;


-- ============================================================
-- PRE-VALIDATION (2026-07-09 baseline)
-- ============================================================

SELECT CASE WHEN VALUE IN ('<Value></Value>','<Value>0</Value>') THEN 'EMPTY/ZERO' ELSE 'REAL ITEM' END AS KIND,
       COUNT(*) AS CNT, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES
FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS GROUP BY 1;
-- Baseline: REAL ITEM ~414 rows/policies; EMPTY/ZERO ~2,139 rows/policies

SELECT COUNT(*) AS UNESCAPED_ROWS FROM AGGNE.DEV.HC_02
WHERE (DESCRIPTIONSPECIFIED LIKE '%&%' AND DESCRIPTIONSPECIFIED NOT LIKE '%&amp;%')
   OR DESCRIPTIONSPECIFIED LIKE '%<%' OR DESCRIPTIONSPECIFIED LIKE '%>%';
-- Baseline: 15


-- ============================================================
-- POST-VALIDATION
-- ============================================================

-- 1) No more empty/zero nodes — every remaining row is a real specified item
SELECT CASE WHEN VALUE IN ('<Value></Value>','<Value>0</Value>') THEN 'EMPTY/ZERO' ELSE 'REAL ITEM' END AS KIND,
       COUNT(*) FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS GROUP BY 1;
-- Target: 0 EMPTY/ZERO rows remaining (only the ~414 real-item rows should remain)

-- 2) Escaping confirmed (check the wrapped output for a real unescaped ampersand, ignoring the
--    tag literals themselves)
SELECT COUNT(*) AS STILL_UNESCAPED FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS
WHERE DESCRIPTION LIKE '%&%' AND DESCRIPTION NOT LIKE '%&amp;%' AND DESCRIPTION NOT LIKE '%&lt;%' AND DESCRIPTION NOT LIKE '%&gt;%';
-- Target: 0
-- ============================================================
