-- ============================================================
-- G-21 fix — Item Description free text not XML-escaped (seq 8, HC Items Exceeding Value, P2)
-- VIEW: AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE
-- ============================================================
--
-- Same defect/fix pattern as seq 6/9/12 — a description containing `&`, `<`, or `>` produces
-- malformed XML for the WHOLE policy payload. This view already wraps the value in
-- <Description>...</Description> tags manually (rather than relying on the template), so the fix
-- applies to the inner CAST(T1.DESCRIPTION AS VARCHAR) expression, not the wrapper tags themselves.
--
-- LIVE-VERIFIED (2026-07-09): 25 of 186 rows in the source (HC_02.DESCRIPTION, filtered to
-- ANYITEMSEXCEEDVALUE='Yes' AND VALUE>0) contain an unescaped `&` — real, live-breaking impact,
-- not just hardening.
--
-- ┌─── DESCRIPTION (final SELECT) ─────────────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   CONCAT(
-- │       '<Description>',
-- │       CASE WHEN T1.DESCRIPTION IS NOT NULL
-- │            THEN CAST(T1.DESCRIPTION AS VARCHAR)
-- │            ELSE ''
-- │       END,
-- │       '</Description>'
-- │   ) AS DESCRIPTION
-- │
-- │ NEW CODE:
-- │   CONCAT(
-- │       '<Description>',
-- │       CASE WHEN T1.DESCRIPTION IS NOT NULL
-- │            THEN REPLACE(REPLACE(REPLACE(CAST(T1.DESCRIPTION AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
-- │            ELSE ''
-- │       END,
-- │       '</Description>'
-- │   ) AS DESCRIPTION
-- └─────────────────────────────────────────────────────────────────────────────

create or replace view PER_HC_ITEMS_EXCEED_VALUE(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	VALUE,
	DESCRIPTION
) as
SELECT
    CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,

    CONCAT(
        '<Value>',
        CAST(CAST(T1.VALUE AS NUMBER(10, 0)) AS VARCHAR),
        '</Value>'
    ) AS VALUE,

    -- FIX: escape XML-breaking characters in the description before wrapping it in tags
    CONCAT(
        '<Description>',
        CASE WHEN T1.DESCRIPTION IS NOT NULL
             THEN REPLACE(REPLACE(REPLACE(CAST(T1.DESCRIPTION AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
             ELSE ''
        END,
        '</Description>'
    ) AS DESCRIPTION

FROM AGGNE.DEV.HC_02 T1
WHERE T1.EFFECTIVEDATE >= '2026-01-01'
  AND T1.ANYITEMSEXCEEDVALUE = 'Yes'
  AND T1.VALUE IS NOT NULL
  AND T1.VALUE > 0;


-- ============================================================
-- PRE-VALIDATION (2026-07-09 baseline)
-- ============================================================

SELECT COUNT(*) AS UNESCAPED_ROWS FROM AGGNE.DEV.HC_02
WHERE ANYITEMSEXCEEDVALUE = 'Yes' AND VALUE IS NOT NULL AND VALUE > 0
  AND ((DESCRIPTION LIKE '%&%' AND DESCRIPTION NOT LIKE '%&amp;%') OR DESCRIPTION LIKE '%<%' OR DESCRIPTION LIKE '%>%');
-- Baseline: 25


-- ============================================================
-- POST-VALIDATION
-- ============================================================

SELECT COUNT(*) AS STILL_UNESCAPED FROM AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE
WHERE (DESCRIPTION LIKE '%&%' AND DESCRIPTION NOT LIKE '%&amp;%' AND DESCRIPTION NOT LIKE '%&lt;%' AND DESCRIPTION NOT LIKE '%&gt;%');
-- Note: DESCRIPTION here is already tag-wrapped, so a plain '<'/'>' check would always match the
-- wrapper tags themselves — check only for unescaped '&' post-fix. Target: 0
-- ============================================================
