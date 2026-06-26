-- ============================================================
-- Seq 13 (RISK_Building_HC) — Fix A + Fix B combined
-- DB   : PolicyConversion
-- Table: dbo.PP_ConversionConfig
-- ============================================================
--
-- Fix A: {clauses} → {HC_CLAUSE}
--   Token {clauses} is never substituted by DYNAMIC_XML_V1 because the source
--   view PER_HOME_BUILDING_PAYLOAD exposes the column as HC_CLAUSE (uppercase).
--   Result without fix: HC clause rows silently dropped from every HC payload.
--
-- Fix B: <HomeContentsLimits>1</HomeContentsLimits> → dynamic token
--   Hardcoded "1" means all policies show "Yes" regardless of source.
--   PER_HOME_BUILDING_PAYLOAD.ANYITEMSEXCEEDVALUE returns 'Yes'/'No' per policy.
--
-- ── PREVIEW (run first, verify both conditions are true) ─────────────────────
SELECT
    SequenceID, ScriptName,
    CHARINDEX('{clauses}',                             ConversionScript) AS clauses_pos,           -- must be > 0
    CHARINDEX('<HomeContentsLimits>1</HomeContentsLimits>', ConversionScript) AS hardcoded_hcl_pos, -- must be > 0
    CHARINDEX('{HC_CLAUSE}',                           ConversionScript) AS hc_clause_pos,         -- must be 0
    CHARINDEX('{ANYITEMSEXCEEDVALUE}',                 ConversionScript) AS anyitems_pos            -- must be 0
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 13;

-- ── FIX A — uncomment and run after confirming clauses_pos > 0 ───────────────
/*
UPDATE dbo.PP_ConversionConfig
   SET ConversionScript = REPLACE(ConversionScript, '{clauses}', '{HC_CLAUSE}'),
       ModifiedBy       = 'fix-seq13-A',
       ModifiedOn       = GETDATE()
WHERE SequenceID = 13
  AND ConversionScript LIKE '%{clauses}%';
*/

-- ── FIX B — uncomment and run after confirming hardcoded_hcl_pos > 0 ─────────
/*
UPDATE dbo.PP_ConversionConfig
   SET ConversionScript = REPLACE(
           ConversionScript,
           '<HomeContentsLimits>1</HomeContentsLimits>',
           '<HomeContentsLimits>{ANYITEMSEXCEEDVALUE}</HomeContentsLimits>'
       ),
       ModifiedBy       = 'fix-seq13-B',
       ModifiedOn       = GETDATE()
WHERE SequenceID = 13
  AND ConversionScript LIKE '%<HomeContentsLimits>1</HomeContentsLimits>%';
*/

-- ── POST-FIX VERIFY — run after both fixes ───────────────────────────────────
/*
SELECT
    SequenceID, ScriptName,
    CHARINDEX('{clauses}',                             ConversionScript) AS clauses_pos,           -- must be 0
    CHARINDEX('<HomeContentsLimits>1</HomeContentsLimits>', ConversionScript) AS hardcoded_hcl_pos, -- must be 0
    CHARINDEX('{HC_CLAUSE}',                           ConversionScript) AS hc_clause_pos,         -- must be > 0
    CHARINDEX('{ANYITEMSEXCEEDVALUE}',                 ConversionScript) AS anyitems_pos            -- must be > 0
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 13;
*/
