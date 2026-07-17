-- ============================================================
-- G-47 (NEW, found 2026-07-10) — Sub-coverage Indicator hardcoded in the TEMPLATE, not just the view
-- Seq 4 (HB) and Seq 10 (HC) both affected — same root cause, same fix pattern, two config rows.
-- Discovered during post-deployment validation of G-18: the view fix (PER_BB_SUBCOVERAGES /
-- PER_HC_SUBCOVERAGES, deployed and verified correct) turned out to have ZERO effect on the real
-- generated XML, because the seq 4 / seq 10 config templates never read the view's INDICATOR
-- column at all — they hardcode the literal text <Indicator>1</Indicator> instead of using an
-- {INDICATOR} token.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-10, after CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE)): checked the real
-- generated payload in AGGNE.DEV.PER_BUILDING_TARGET / PER_HC_TARGET (ITR_TYPE='Building_SubCov')
-- — every single sub-coverage block, including Flood and Accidental Damage ones with
-- <sValue>NotTaken</sValue> sitting right next to it, still shows <Indicator>1</Indicator>. G-18's
-- fix to the view (correctly computing 0/1 from sValue/limit) never reaches DCT, because the
-- config template ignores that column entirely.
--
-- Confirmed directly against [dbo].[PP_ConversionConfig] (Azure host):
--   SequenceID 4  (Building_SubCov, HB): ConversionScript contains literal '<Indicator>1</Indicator>',
--                                        does NOT contain '{INDICATOR}'
--   SequenceID 10 (Building_SubCov, HC): same — literal hardcode, no token
--
-- Both PER_BB_SUBCOVERAGES and PER_HC_SUBCOVERAGES already expose a column literally named
-- INDICATOR (confirmed via the CREATE VIEW column list in each — see G-18_fix.sql in seq04/seq10),
-- so DYNAMIC_XML_V1's INFORMATION_SCHEMA.COLUMNS-driven substitution will pick up a {INDICATOR}
-- token correctly once added — same mechanism already proven working for every other token in
-- these templates (e.g. {SVALUE}, {CODE}, {DESCRIPTION}).
--
-- ┌─── Seq 4 (Building_SubCov, HB) template ────────────────────────────────────
-- │ OLD:
-- │   <Indicator>1</Indicator>
-- │ NEW:
-- │   <Indicator>{INDICATOR}</Indicator>
-- └─────────────────────────────────────────────────────────────────────────────
-- ┌─── Seq 10 (Building_SubCov, HC) template ───────────────────────────────────
-- │ OLD:
-- │   <Indicator>1</Indicator>
-- │ NEW:
-- │   <Indicator>{INDICATOR}</Indicator>
-- └─────────────────────────────────────────────────────────────────────────────
--
-- NOTE: seq 15 (Risk_CM, Motor sub-coverages) uses the exact same template shape
-- ('<coverage>...<Indicator>1</Indicator>...{SVALUE}...') — confirm whether that one has a real
-- Taken/NotTaken-driven Indicator concept at all before assuming it needs the same fix; G-37
-- already covers seq 15's Indicator question from a different angle (ProtectionType matrix), so
-- don't duplicate/conflict with that gap — flag for review, not an auto-apply.


-- ============================================================
-- PRE-VALIDATION (2026-07-10, run against Azure host)
-- ============================================================
-- USE [Capricorn-Dev-SwiftConversion];
SELECT SequenceID, ScriptName,
    CASE WHEN ConversionScript LIKE '%<Indicator>1</Indicator>%' THEN 'G-47 BUG PRESENT (hardcoded)' ELSE 'clean/tokenized' END AS Status
FROM [dbo].[PP_ConversionConfig] WHERE SequenceID IN (4, 10);
-- Baseline: both rows show 'G-47 BUG PRESENT'


-- ============================================================
-- FIX
-- ============================================================
UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(ConversionScript, '<Indicator>1</Indicator>', '<Indicator>{INDICATOR}</Indicator>')
WHERE  SequenceID = 4
  AND  ScriptName = 'Building_SubCov'
  AND  ConversionScript LIKE '%<Indicator>1</Indicator>%';
-- Expected: 1 row affected

UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(ConversionScript, '<Indicator>1</Indicator>', '<Indicator>{INDICATOR}</Indicator>')
WHERE  SequenceID = 10
  AND  ScriptName = 'Building_SubCov'
  AND  ConversionScript LIKE '%<Indicator>1</Indicator>%';
-- Expected: 1 row affected


-- ============================================================
-- POST-VALIDATION
-- ============================================================
SELECT SequenceID, ScriptName,
    CASE WHEN ConversionScript LIKE '%{INDICATOR}%' THEN 'PASS — tokenized' ELSE 'FAIL — still hardcoded/missing' END AS Result
FROM [dbo].[PP_ConversionConfig] WHERE SequenceID IN (4, 10);

-- IMPORTANT: same two-source-drift risk as every other config change in this project —
-- PP_CONVERSION_RUN must be regenerated from config after this, or the fix won't reach real
-- output even though the config table itself is correct (see feedback_verify_live_not_repo.md).
-- After regenerating + redeploying, re-run against real Snowflake output:
--   SELECT PAYLOAD FROM AGGNE.DEV.PER_BUILDING_TARGET
--   WHERE ITR_TYPE='Building_SubCov' AND PAYLOAD LIKE '%HBBFL_SD%' LIMIT 5;
--   -- target: Indicator now varies (0 for NotTaken, 1 for Taken), not hardcoded 1 for every row
-- ============================================================
