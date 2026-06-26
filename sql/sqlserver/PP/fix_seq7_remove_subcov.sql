-- ============================================================
-- SQL Server: Fix seq 7 HB template — remove {SUBCOV} token
--
-- Problem:
--   The RISK_Building_HB template (seq 7) contains {SUBCOV}
--   between </Excess> and <SetExcessAmount>.
--   DYNAMIC_XML_V1 resolves {SUBCOV} from PER_HOME_BUILDING_PAYLOAD
--   column SUBCOV, which reads Building_SubCov rows from
--   PER_HC_TARGET (i.e., HC sub-coverages from PER_HC_SUBCOVERAGES).
--   This incorrectly places HC sub-coverages inside the HB
--   Building coverage block.
--
-- Fix:
--   Remove {SUBCOV} from seq 7 template.
--   BB sub-coverages (Building_SubCov rows from PER_BUILDING_TARGET)
--   are now injected INSIDE </coverage> by the updated
--   PER_BUILDING_FINAL_AGG.hb_agg CTE.
--
-- SAFE_MODE: Run this manually against PolicyConversion DB.
-- After applying, re-run seq 7 (DYNAMIC_XML_V1) and then
-- PER_CONVERSION_FINAL_LOAD + PER_CONVERSION_FINAL_XML.
-- ============================================================


-- Step 1: Preview the change before applying
SELECT
    SequenceID,
    ScriptName,
    CHARINDEX('{SUBCOV}', ConversionScript) AS SUBCOV_POSITION,
    ConversionScript
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 7
  AND IsActive   = 1;


-- Step 2: Remove {SUBCOV} from seq 7 template
-- (leaves surrounding whitespace — harmless in XML)
UPDATE dbo.PP_ConversionConfig
SET    ConversionScript = REPLACE(ConversionScript, '{SUBCOV}', '')
WHERE  SequenceID = 7
  AND  IsActive   = 1;


-- Step 3: Verify {SUBCOV} is gone and template looks correct
SELECT
    SequenceID,
    ScriptName,
    CASE WHEN CHARINDEX('{SUBCOV}', ConversionScript) > 0
         THEN 'SUBCOV STILL PRESENT — check failed'
         ELSE 'OK — SUBCOV removed'
    END AS CHECK_STATUS,
    ConversionScript
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 7
  AND IsActive   = 1;
