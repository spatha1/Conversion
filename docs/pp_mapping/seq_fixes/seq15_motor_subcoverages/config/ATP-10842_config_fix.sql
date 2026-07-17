-- ============================================================
-- ATP-10842 config fix — Seq 15 template hardcodes <Indicator>1</Indicator>, same pattern as G-47
-- (seq 4/10). The view fix (PER_COM_COVERAGES.PMULG_SD, deployed and confirmed correct at the
-- staging layer) has ZERO effect on real output until this is also deployed, because the template
-- never reads the view's INDICATOR column at all.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-10): seq 15's ConversionScript in PP_ConversionConfig (and the live
-- PP_CONVERSION_RUN orchestrator's embedded copy) contains the literal text
-- '<Indicator>1</Indicator>' — no {INDICATOR} token. Confirmed against real payloads: policies where
-- PER_COM_COVERAGES.INDICATOR='0' still show <Indicator>1</Indicator> in PER_COM_COVERAGES_TARGET.
--
-- NOTE: this template is shared by ALL 8 sub-coverage codes in seq 15 (PMCMP_SD, PMCOR_SD, PMFTL_SD,
-- PMLIA_SD, PMPCH_SD, PMTFT_SD, PMTPO_SD, PMULG_SD) — tokenizing it affects all 8, not just
-- PMULG_SD/glass. The other 7 still have INDICATOR hardcoded to 1 at the VIEW layer (PER_COM_COVERAGES,
-- unchanged, still G-37's open client question) — so for those 7, {INDICATOR} will resolve to '1'
-- either way (same visible behavior as today) until G-37's matrix is answered. Only PMULG_SD changes
-- behavior from this deploy, because it's the only one of the 8 with a real, varying view-level value
-- right now. Safe to tokenize the shared template regardless of G-37's status.
--
-- ============================================================
-- PRE-VALIDATION (run against Azure host)
-- ============================================================
-- USE [Capricorn-Dev-SwiftConversion];
SELECT SequenceID, ScriptName,
    CASE WHEN ConversionScript LIKE '%<Indicator>1</Indicator>%' THEN 'BUG PRESENT (hardcoded)' ELSE 'clean/tokenized' END AS Status
FROM [dbo].[PP_ConversionConfig] WHERE SequenceID = 15;
-- Baseline: 'BUG PRESENT'


-- ============================================================
-- FIX
-- ============================================================
UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(ConversionScript, '<Indicator>1</Indicator>', '<Indicator>{INDICATOR}</Indicator>')
WHERE  SequenceID = 15
  AND  ConversionScript LIKE '%<Indicator>1</Indicator>%';
-- Expected: 1 row affected


-- ============================================================
-- POST-VALIDATION
-- ============================================================
SELECT SequenceID, ScriptName,
    CASE WHEN ConversionScript LIKE '%{INDICATOR}%' THEN 'PASS — tokenized' ELSE 'FAIL — still hardcoded/missing' END AS Result
FROM [dbo].[PP_ConversionConfig] WHERE SequenceID = 15;

-- IMPORTANT — same two-source-drift risk as G-47: PP_CONVERSION_RUN must be regenerated from config
-- after this (re-run the regen script / re-pull all 18 templates), or the fix won't reach real
-- output even though the config table itself is correct.
--
-- After regenerating + redeploying + re-running PP_CONVERSION_RUN(TRUE), re-check against real
-- Snowflake output:
SELECT COUNT(*) FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET t
JOIN AGGNE.DEV.PER_COM_COVERAGES v ON t.ID = v.PUREPOLICYNUMBER
WHERE t.ITR_TYPE='Risk_CM' AND v.CODE='PMULG_SD' AND v.INDICATOR='0'
  AND t.PAYLOAD LIKE '%PMULG_SD%' AND t.PAYLOAD NOT LIKE '%<Indicator>0</Indicator>%<Code>PMULG_SD%';
-- Target: 0 (every policy where the view says '0' should now show '0' in the real payload too)
-- ============================================================
