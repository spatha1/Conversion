-- ============================================================================
-- G-BP-65 partial fix — SEQ 26 (BP_LINE_CV), Customer Vehicles: casing bug on
-- HailAndMaliciousDamage node (ATP-10904)
-- ============================================================================
-- Found while re-checking the manuscript: SEQ 26 sends the node as
-- <HailandMaliciousDamage/> (lowercase "and"), but the manuscript's actual
-- XML path is Excess/HailAndMaliciousDamage (capital "And"):
--
--   <public id="CustomerVehiclesInput.HailandMaliciousDamage"
--           path="Excess/HailAndMaliciousDamage" type="int" ...>
--
-- XML element names are case-sensitive. Even though this tag is currently
-- empty either way (see seq24-26_customervehicles.md — no Pure source exists
-- for this field, separate open question with the client), sending the wrong
-- casing means DC's parser would never map this node to the manuscript field
-- at all, regardless of whether a value is ever added later. Fixing the
-- casing now is a prerequisite for any future fix, independent of the
-- Pure-source question.
--
-- Scope: CONFIG-ONLY, single tag rename, still empty/self-closing.
-- Status: DRAFTED. Whitespace confirmed byte-exact via live pull immediately
-- before drafting.
-- ============================================================================

-- PRE-CHECK
SELECT SequenceID, ScriptName,
       CASE WHEN CHARINDEX('<HailandMaliciousDamage/>', ConversionScript) > 0 THEN 'PRESENT (wrong casing)' ELSE 'MISSING' END AS WRONG_CASING,
       CASE WHEN CHARINDEX('<HailAndMaliciousDamage/>', ConversionScript) > 0 THEN 'PRESENT (correct casing)' ELSE 'MISSING' END AS CORRECT_CASING
FROM dbo.ConversionConfig
WHERE SequenceID = 26 AND ScriptName = 'BP_LINE_CV';
-- Expect WRONG_CASING = 'PRESENT (wrong casing)', CORRECT_CASING = 'MISSING'

-- UPDATE
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(ConversionScript,
        '<HailandMaliciousDamage/>',
        '<HailAndMaliciousDamage/>')
WHERE SequenceID = 26 AND ScriptName = 'BP_LINE_CV'
  AND CHARINDEX('<HailandMaliciousDamage/>', ConversionScript) > 0;

-- POST-CHECK
SELECT SequenceID, ScriptName, ConversionScript
FROM dbo.ConversionConfig
WHERE SequenceID = 26 AND ScriptName = 'BP_LINE_CV';
-- Expect: <HailAndMaliciousDamage/> (capital A), still empty — the
-- Pure-source question (G-BP-65) remains open separately.
