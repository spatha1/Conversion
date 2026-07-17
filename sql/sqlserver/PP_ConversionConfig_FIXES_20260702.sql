-- ============================================================
-- PP_ConversionConfig_FIXES_20260702.sql
--
-- Database : Capricorn-Dev-SwiftConversion
-- Table    : [dbo].[PP_ConversionConfig]
-- Date     : 2026-07-02
--
-- FIX 1 — BUG-NEW-01 (SeqID 7, ConversionConfigId 7)
--   Root cause : {SUBCOV} token in RISK_Building_HB template causes
--                HC sub-coverages (CNT_SD, CAD_SD, SPE_SD) to be
--                injected inside the HB Building coverage block.
--   Fix        : Remove {SUBCOV} from the template entirely.
--
-- FIX 2 — PP-CF-22 (SeqID 18, ConversionConfigId 17)
--   Root cause : <WouldYouLikeToAddAccessoriesOrModifications/> is
--                a self-closing empty tag. DCT treats it as a required
--                field. The view (PER_COM_PAYLOAD) returns the correct
--                value in column MVADDACCORMODS but the token was missing.
--   Fix        : Replace the self-closing empty tag with
--                <WouldYouLikeToAddAccessoriesOrModifications>{MVADDACCORMODS}
--                </WouldYouLikeToAddAccessoriesOrModifications>
--
-- APPLY ORDER:
--   Step 1 — Run the BEFORE selects to confirm current state
--   Step 2 — Run Fix 1 UPDATE
--   Step 3 — Run Fix 2 UPDATE
--   Step 4 — Run the AFTER selects to verify
--   Step 5 — Re-run seqs 7 and 18 via the orchestrator or Aggne ETL
-- ============================================================

USE [Capricorn-Dev-SwiftConversion];
GO


-- ════════════════════════════════════════════════════════════
-- BEFORE: Verify current state (run first, expect BUG markers)
-- ════════════════════════════════════════════════════════════

SELECT
    ConversionConfigId,
    SequenceID,
    ScriptName,
    LEN(ConversionScript) AS TemplateLenBefore,
    CASE WHEN ConversionScript LIKE '%{SUBCOV}%'
         THEN 'HAS {SUBCOV} — BUG PRESENT'
         ELSE 'No {SUBCOV} — already clean'
    END AS SeqID7_BugStatus
FROM [dbo].[PP_ConversionConfig]
WHERE ConversionConfigId = 7;

SELECT
    ConversionConfigId,
    SequenceID,
    ScriptName,
    LEN(ConversionScript) AS TemplateLenBefore,
    CASE WHEN ConversionScript LIKE '%<WouldYouLikeToAddAccessoriesOrModifications/>%'
         THEN 'EMPTY self-close tag — BUG PRESENT'
         ELSE 'Not empty — already clean'
    END AS SeqID18_BugStatus,
    CASE WHEN ConversionScript LIKE '%{MVADDACCORMODS}%'
         THEN 'Token already present'
         ELSE 'Token MISSING'
    END AS TokenStatus
FROM [dbo].[PP_ConversionConfig]
WHERE ConversionConfigId = 17;
GO


-- ════════════════════════════════════════════════════════════
-- FIX 1: Remove {SUBCOV} from seq 7 (RISK_Building_HB)
-- ConversionConfigId=7, SequenceID=7, ScriptName=RISK_Building_HB
--
-- The WHERE clause guards are intentional — if any condition
-- fails (wrong row / already fixed), the UPDATE is a no-op.
-- ════════════════════════════════════════════════════════════

UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(ConversionScript, '{SUBCOV}', '')
WHERE  ConversionConfigId = 7
  AND  SequenceID         = 7
  AND  ScriptName         = 'RISK_Building_HB'
  AND  ConversionScript LIKE '%{SUBCOV}%';   -- no-op if already fixed

-- Expected: 1 row affected
GO


-- ════════════════════════════════════════════════════════════
-- FIX 2: Restore {MVADDACCORMODS} token in seq 18 (RISK_Building_PM)
-- ConversionConfigId=17, SequenceID=18, ScriptName=RISK_Building_PM
--
-- Only the plain (non-Market) WouldYouLikeToAdd... tag is empty.
-- The Market variant already has {MVADDACCORMODS} — do NOT touch it.
-- ════════════════════════════════════════════════════════════

UPDATE [dbo].[PP_ConversionConfig]
SET    ConversionScript = REPLACE(
           ConversionScript,
           '<WouldYouLikeToAddAccessoriesOrModifications/>',
           '<WouldYouLikeToAddAccessoriesOrModifications>{MVADDACCORMODS}</WouldYouLikeToAddAccessoriesOrModifications>'
       )
WHERE  ConversionConfigId = 17
  AND  SequenceID         = 18
  AND  ScriptName         = 'RISK_Building_PM'
  AND  ConversionScript LIKE '%<WouldYouLikeToAddAccessoriesOrModifications/>%';   -- no-op if already fixed

-- Expected: 1 row affected
GO


-- ════════════════════════════════════════════════════════════
-- AFTER: Verify fixes applied correctly
-- ════════════════════════════════════════════════════════════

SELECT
    ConversionConfigId,
    SequenceID,
    ScriptName,
    LEN(ConversionScript) AS TemplateLenAfter,
    CASE WHEN ConversionScript LIKE '%{SUBCOV}%'
         THEN 'FAIL — {SUBCOV} still present'
         ELSE 'PASS — {SUBCOV} removed'
    END AS Fix1_Result
FROM [dbo].[PP_ConversionConfig]
WHERE ConversionConfigId = 7;

SELECT
    ConversionConfigId,
    SequenceID,
    ScriptName,
    LEN(ConversionScript) AS TemplateLenAfter,
    CASE WHEN ConversionScript LIKE '%<WouldYouLikeToAddAccessoriesOrModifications/>%'
         THEN 'FAIL — empty tag still present'
         ELSE 'PASS — empty tag replaced'
    END AS Fix2_EmptyTag,
    CASE WHEN ConversionScript LIKE '%<WouldYouLikeToAddAccessoriesOrModifications>{MVADDACCORMODS}%'
         THEN 'PASS — token present'
         ELSE 'FAIL — token missing'
    END AS Fix2_TokenPresent
FROM [dbo].[PP_ConversionConfig]
WHERE ConversionConfigId = 17;
GO


-- ════════════════════════════════════════════════════════════
-- AFTER APPLYING FIXES:
-- Re-run seqs 7 and 18 to regenerate target table rows with
-- corrected templates.
--
-- Option A — full orchestrator SP (re-runs all 18 seqs):
--   In Snowflake: CALL AGGNE.DEV.PP_CONVERSION_RUN(TRUE);
--
-- Option B — targeted re-run (seq 7 and 18 only):
--   Delete latest batch rows for RISK_Building_HB and RISK_Building_PM
--   then re-call DYNAMIC_XML_V1 for each.
--   Finish with: CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();
-- ════════════════════════════════════════════════════════════
