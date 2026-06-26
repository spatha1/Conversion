-- ============================================================
-- SQL Server Fixes: Seq 13 (RISK_Building_HC) ConversionScript corrections
-- DB  : PolicyConversion
-- Table: PP_ConversionConfig
--
-- FIX A — {clauses} → {HC_CLAUSE} token rename
--   Root cause (ATP-9638 / ATP-9652, found 2026-06-25):
--   The seq 13 ConversionScript ends with {clauses} but the source view
--   PER_HOME_BUILDING_PAYLOAD exposes column HC_CLAUSE.  DYNAMIC_XML_V1
--   substitutes by column name, so {clauses} is never replaced and HC
--   clause rows are silently dropped from every HC payload.
--
-- FIX B — <HomeContentsLimits>1</HomeContentsLimits> → dynamic token
--   Root cause (PL101 cross-check, 2026-06-25):
--   The template hardcodes the value as 1.  Reference payload (SAI_CONFIGURATION
--   ID=1) shows DCT expects 'Yes'/'No'.  The source view PER_HOME_BUILDING_PAYLOAD
--   now exposes column ANYITEMSEXCEEDVALUE ('Yes' / 'No' from HC_02).
--   Replacing the literal with {ANYITEMSEXCEEDVALUE} lets policies correctly
--   show 'No' when no items exceed value, instead of always showing 'Yes'.
--
-- SAFE_MODE: run each Step 1 (SELECT preview) before the Step 2 UPDATE.
-- ============================================================

-- ── FIX A ─────────────────────────────────────────────────────────────────
-- Step A1 — Preview: confirm the {clauses} token is still present
SELECT
    SequenceID,
    ScriptName,
    CHARINDEX('{clauses}', ConversionScript)        AS clauses_pos,
    CHARINDEX('{HC_CLAUSE}', ConversionScript)      AS hc_clause_pos,
    LEFT(ConversionScript, 300)                      AS script_preview
FROM PP_ConversionConfig
WHERE SequenceID = 13;

-- Expected: clauses_pos > 0, hc_clause_pos = 0
-- If already fixed (clauses_pos = 0), do NOT run Step A2.

-- Step A2 — Apply: replace {clauses} with {HC_CLAUSE}
-- Uncomment and run only after confirming Step A1 shows clauses_pos > 0

/*
UPDATE PP_ConversionConfig
   SET ConversionScript = REPLACE(ConversionScript, '{clauses}', '{HC_CLAUSE}'),
       ModifiedBy       = 'ATP-9638-fix-A',
       ModifiedOn       = GETDATE()
WHERE  SequenceID = 13;
*/

-- ── FIX B ─────────────────────────────────────────────────────────────────
-- Step B1 — Preview: confirm the hardcoded <HomeContentsLimits>1</HomeContentsLimits> is present
SELECT
    SequenceID,
    ScriptName,
    CHARINDEX('<HomeContentsLimits>1</HomeContentsLimits>', ConversionScript) AS hardcoded_pos,
    CHARINDEX('{ANYITEMSEXCEEDVALUE}', ConversionScript)                      AS token_pos,
    -- Show 200 chars around the HomeContentsLimits element to verify context
    SUBSTRING(
        ConversionScript,
        CASE WHEN CHARINDEX('<HomeContentsLimits>', ConversionScript) > 20
             THEN CHARINDEX('<HomeContentsLimits>', ConversionScript) - 20
             ELSE 1
        END,
        120
    ) AS context_preview
FROM PP_ConversionConfig
WHERE SequenceID = 13;

-- Expected: hardcoded_pos > 0, token_pos = 0
-- If already fixed (hardcoded_pos = 0), do NOT run Step B2.

-- Step B2 — Apply: replace hardcoded '1' with {ANYITEMSEXCEEDVALUE} token
-- Uncomment and run only after confirming Step B1 shows hardcoded_pos > 0

/*
UPDATE PP_ConversionConfig
   SET ConversionScript = REPLACE(
           ConversionScript,
           '<HomeContentsLimits>1</HomeContentsLimits>',
           '<HomeContentsLimits>{ANYITEMSEXCEEDVALUE}</HomeContentsLimits>'
       ),
       ModifiedBy       = 'ATP-9638-fix-B',
       ModifiedOn       = GETDATE()
WHERE  SequenceID = 13;
*/

-- ── Post-fix verification ─────────────────────────────────────────────────
-- Run after both fixes to confirm all tokens are correct:
/*
SELECT
    SequenceID, ScriptName,
    CHARINDEX('{clauses}',              ConversionScript) AS clauses_pos,          -- must be 0
    CHARINDEX('{HC_CLAUSE}',            ConversionScript) AS hc_clause_pos,        -- must be > 0
    CHARINDEX('HomeContentsLimits>1<',  ConversionScript) AS hardcoded_limit_pos,  -- must be 0
    CHARINDEX('{ANYITEMSEXCEEDVALUE}',  ConversionScript) AS anyitems_token_pos    -- must be > 0
FROM PP_ConversionConfig
WHERE SequenceID = 13;
*/
