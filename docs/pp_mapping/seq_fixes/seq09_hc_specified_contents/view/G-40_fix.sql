-- ============================================================
-- G-40 fix — Specified Items Away From the Premises: itemized list never built
-- VIEW: AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS (seq 9, feeds {HC_SPECIFIED_CONTENTS} in seq 13's template)
-- ============================================================
--
-- CORRECTION 2026-07-13: the first draft of this file was built against the REPO copy of this view
-- (sql/snowflake/1_conversion/PP/views/PER_HC_SPECIFIEDCONTENTS.sql), which is stale. Pulled fresh
-- from live Snowflake before rewriting this — the live view already has G-27's empty-item filter
-- (WHERE VALUESPECIFIED IS NOT NULL AND VALUESPECIFIED > 0) and G-21's XML escaping on DESCRIPTION,
-- neither of which were in the repo file. The first draft would have silently regressed both of
-- those already-deployed fixes. Corrected below to build on top of the real live definition.
--
-- CLIENT ANSWER (13 July 2026, path provided by Vihari):
--   data/policy/line[Type="PPAU"]/risk[Type="Building"]/coverage[Type="ContentsAndStocks"]/SpecifiedContents/Description
--   data/policy/line[Type="PPAU"]/risk[Type="Building"]/coverage[Type="ContentsAndStocks"]/SpecifiedContents/Value
--
-- INTERPRETATION (flagging as inference, not an explicit instruction — worth a quick confirm):
-- This is the EXACT SAME node shape (<Value>/<Description> under SpecifiedContents) that
-- PER_HC_SPECIFIEDCONTENTS (seq 9) already emits — but only from HC_02.DESCRIPTIONSPECIFIED/
-- VALUESPECIFIED (the "specifically scheduled at home" items). G-40 is about a DIFFERENT pair of
-- columns on the same table, HC_02.DESCRIPTION/VALUE ("away from premises" items, sourced from
-- HC_AWAY, confirmed live: 1,278 items across 495 policies). Since the client pointed us at the
-- same target node rather than a distinct one, the most direct reading is that "away from premises"
-- items should be UNIONed into the same SpecifiedContents list alongside the specifically-scheduled
-- ones, not sent to a separate node. If that's wrong (DCT actually wants a distinct node for "away"
-- items), this fix is trivially reversible — just split the UNION back into two views.
--
-- ┌─── PER_HC_SPECIFIEDCONTENTS ─────────────────────────────────────────────────
-- │ OLD CODE (current, live — confirmed via fresh GET_DDL pull 2026-07-13, includes G-27+G-21):
-- │   create or replace view PER_HC_SPECIFIEDCONTENTS(
-- │       PUREPOLICYNUMBER, LEGACYPOLICYNUMBER, VALUE, DESCRIPTION
-- │   ) as
-- │   SELECT
-- │       CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
-- │       PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
-- │       CONCAT('<Value>',case when VALUESPECIFIED IS NOT NULL then cast(CAST(COALESCE(VALUESPECIFIED ,0) AS NUMBER(10,0))as varchar) ELSE '' end , '</Value>') AS VALUE,
-- │       -- FIX (G-21): escape XML-breaking characters
-- │       CONCAT('<Description>',case when DESCRIPTIONSPECIFIED IS NOT NULL
-- │           then REPLACE(REPLACE(REPLACE(CAST(DESCRIPTIONSPECIFIED AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
-- │           ELSE '' end , '</Description>') AS DESCRIPTION
-- │       FROM AGGNE.DEV.HC_02
-- │       -- FIX (G-27): only emit a node when there's an actual specified item
-- │       WHERE EFFECTIVEDATE >= '2026-01-01'
-- │         AND VALUESPECIFIED IS NOT NULL AND VALUESPECIFIED > 0;
-- │
-- │ NEW CODE (adds a second SELECT, UNION ALL, sourcing the "away from premises" pair — same
-- │ empty-item-filter and XML-escaping treatment applied to the new branch for consistency):
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
    CONCAT('<Description>',case when DESCRIPTIONSPECIFIED IS NOT NULL
        then REPLACE(REPLACE(REPLACE(CAST(DESCRIPTIONSPECIFIED AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
        ELSE '' end , '</Description>') AS DESCRIPTION
    FROM AGGNE.DEV.HC_02
    WHERE EFFECTIVEDATE >= '2026-01-01'
      AND VALUESPECIFIED IS NOT NULL AND VALUESPECIFIED > 0

UNION ALL

SELECT
    CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
    CONCAT('<Value>',case when VALUE IS NOT NULL then cast(CAST(COALESCE(VALUE ,0) AS NUMBER(10,0))as varchar) ELSE '' end , '</Value>') AS VALUE,
    CONCAT('<Description>',case when DESCRIPTION IS NOT NULL
        then REPLACE(REPLACE(REPLACE(CAST(DESCRIPTION AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
        ELSE '' end , '</Description>') AS DESCRIPTION
    FROM AGGNE.DEV.HC_02
    WHERE EFFECTIVEDATE >= '2026-01-01'
      AND VALUE IS NOT NULL AND VALUE > 0;
-- └─────────────────────────────────────────────────────────────────────────────
-- NOTE: the "away from premises" branch's empty-item filter uses VALUE > 0 (matching G-27's pattern
-- exactly: numeric-value-present, not just non-null-text) rather than the DESCRIPTION <> '' check
-- the first draft used — kept consistent with the already-proven G-27 filter style.


-- ============================================================
-- PRE-VALIDATION (2026-07-13 baseline)
-- ============================================================
SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS;
-- Baseline: whatever the current specifically-scheduled-only count is

SELECT COUNT(DISTINCT PUREPOLICYNUMBER), COUNT(*) FROM AGGNE.DEV.HC_AWAY;
-- Baseline: confirms the away-from-premises source data ready to flow in (1,278 items / 495 policies,
-- as confirmed earlier this project)


-- ============================================================
-- POST-VALIDATION — run after deploying and re-running PP_CONVERSION_RUN(TRUE)
-- ============================================================

-- 1) Row count should grow by roughly the away-from-premises item count
SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS;
-- Target: baseline + up to 1,278 (some may be filtered by EFFECTIVEDATE>='2026-01-01' or blank check)

-- 2) Real payload check — itemized list now present, not just the Taken/NotTaken flag
SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_TARGET
WHERE ITR_TYPE='HC_Specified_Contents' AND PAYLOAD LIKE '%<Description>%</Description>%'
  AND PAYLOAD NOT LIKE '%<Description></Description>%';
-- Target: > 0, and grows compared to before this fix
-- ============================================================
