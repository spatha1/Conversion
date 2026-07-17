-- ============================================================================
-- G-BP-24 fix — SEQ 23 (BP_LINE_SV), Stock Vehicles: LIA_SD / STD_SD / TPO_SD
-- hardcoded Indicator=1 (ATP-10842 investigation led here, not the ticket
-- itself — see notes on G-BP-62 in seq21-23_stockvehicles.md)
-- ============================================================================
-- Root cause (confirmed against manuscript + live data, 2026-07-11):
--   LIA_SD ("Comprehensive Liability"), STD_SD ("Comprehensive Property") and
--   TPO_SD ("Third Party Only") are mutually-exclusive protection-type
--   sub-coverages, but SEQ 23 hardcodes all three <Indicator> to 1
--   unconditionally. Manuscript (Carrier_CoverageLibrary_Data_1_0_0_0.xml):
--     StockVehiclesInput.ComprehensiveLiabilityIndicator (LIA_SD)  = (LossOrDamageLimit > 0)
--     StockVehiclesInput.StandardPerilIndicator (STD_SD)           = (ComprehensiveProperty > 0), where ComprehensiveProperty = LossOrDamageLimit
--     StockVehiclesInput.ThirdPartyOnlyIndicator (TPO_SD, ATP-9792) = (ProtectionType == 'ThirdPartyOnly')
--   LINE_SV_PAYLOAD already computes COM_INDICATOR and TPO_INDICATOR from
--   PROTECTIONTYPE but SEQ 23 never references either token — confirmed
--   equivalent to the manuscript's LossOrDamageLimit-based rule in 100% of
--   live data (every FullComprehensive row has LOSSDAMAGELIMIT>0, every
--   ThirdPartyOnly row has LOSSDAMAGELIMIT=0):
--     PROTECTIONTYPE='FullComprehensive', LOSSDAMAGELIMIT>0 -> 676 rows
--     PROTECTIONTYPE='ThirdPartyOnly',    LOSSDAMAGELIMIT=0 -> 19 rows
--   Confirmed bug: 19 of 695 SV records (2.7%) — every "Third Party Only"
--   policy — incorrectly show Comprehensive Liability AND Comprehensive
--   Property as "Taken" (should be 0), and 0 of 695 records ever show Third
--   Party Only as Taken even though 19 of them should.
--
--   STD_ST ("Storm") is NOT part of this fix. Manuscript ties it to
--   StockVehiclesInput.LegalLiabilityStorm > 0, but there is no Pure source
--   for a Stock-Vehicles-specific storm limit anywhere in the SP or SAS
--   ("Storm" only exists for Building coverage in this codebase) — a genuine
--   gap, not a wiring fix, needs a client/business conversation about whether
--   this field even applies to Stock Vehicles before scripting anything.
--
-- Scope: CONFIG-ONLY. LINE_SV_PAYLOAD already exposes COM_INDICATOR/TPO_INDICATOR
--   — no view change needed. Whitespace confirmed byte-exact via live pull
--   immediately before drafting (CRLF + double-tab between tags).
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead before running.
-- ============================================================================

-- PRE-CHECK: confirm the 4 hardcodes are still present exactly as expected
-- (LIA_SD, STD_SD, TPO_SD to be fixed; STD_ST left alone)
SELECT SequenceID, ScriptName,
       LEN(ConversionScript) - LEN(REPLACE(ConversionScript, '<Indicator>1</Indicator>', '')) AS HARDCODED_IND1_CHARS
FROM dbo.ConversionConfig
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV';
-- Expect HARDCODED_IND1_CHARS = 100 (4 * LEN('<Indicator>1</Indicator>') = 4*25)

-- UPDATE
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(
        REPLACE(
            REPLACE(ConversionScript,
                '<Indicator>1</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Code>SVLIA_SD</Code>',
                '<Indicator>{COM_INDICATOR}</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Code>SVLIA_SD</Code>'),
            '<Indicator>1</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Type>STD_SD</Type>',
            '<Indicator>{COM_INDICATOR}</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Type>STD_SD</Type>'),
        '<Indicator>1</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Type>TPO_SD</Type>',
        '<Indicator>{TPO_INDICATOR}</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Type>TPO_SD</Type>')
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV'
  AND CHARINDEX('<Indicator>1</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Code>SVLIA_SD</Code>', ConversionScript) > 0
  AND CHARINDEX('<Indicator>1</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Type>STD_SD</Type>', ConversionScript) > 0
  AND CHARINDEX('<Indicator>1</Indicator>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + '<Type>TPO_SD</Type>', ConversionScript) > 0;

-- POST-CHECK
SELECT SequenceID, ScriptName, ConversionScript
FROM dbo.ConversionConfig
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV';
-- Expect: LIA_SD and STD_SD both reference {COM_INDICATOR}, TPO_SD references
-- {TPO_INDICATOR}, STD_ST's <Indicator>1</Indicator> untouched (its anchor
-- string, '<Type>STD_ST</Type>', was never targeted).

-- POST-CHECK (Snowflake, after config change takes effect on next run)
-- SELECT PROTECTIONTYPE, COUNT(*) FROM AGGNE.DEV.LINE_SV_PAYLOAD GROUP BY 1;
-- Cross-reference against LINE_SV_Target's rendered XML for LIA_SD/STD_SD/TPO_SD
-- <Indicator> values once the next conversion run has picked up the new config.
