-- ============================================================
-- View   : AGGNE.DEV.PER_BUILDING_FINAL_AGG
-- Schema : DEV (PP Conversion)
-- Purpose: Aggregates the per-policy building risk XML block
--          used as the {LOC} token in PER_FINAL / PER_CONVERSION_FINAL_XML.
--
-- Token substitution layers (outermost → innermost):
--
--   Layer 1 — PER_CONVERSION_FINAL_XML SP:
--     {LOC} → this view's AOI column
--
--   Layer 2 — This view:
--     Seq 14 (DYNAMIC_XML_V1 on PER_RISK_BUILDING_FINAL) embeds the full
--     HB block (RISK_BUILDING column = seq 7 payload) and HC block
--     (RISK_BC column = seq 13 payload) into PER_RISK_BUILDING_TARGET.PAYLOAD
--     via {RISK_BUILDING} and {RISK_BC} token substitution.
--
--     After seq 14, PER_RISK_BUILDING_TARGET.PAYLOAD contains the full
--     <risk> block with embedded HB and HC coverage content — but with
--     three tokens still unresolved:
--       {HB_CLAUSE} — inside the Building <coverage> block (from seq 7 template)
--       {clauses}   — inside the ContentsAndStocks <coverage> block (from seq 13)
--       {UW}        — inside the ContentsAndStocks <coverage> block (from seq 13)
--
--     These tokens cannot be resolved by DYNAMIC_XML_V1 because:
--       • HB_CLAUSE is not a column in PER_HOME_BUILDING_PAYLOAD (the seq 7
--         source view) — adding it would create a circular dependency since
--         PER_BUILDING_TARGET (where HB_CLAUSE rows live) is the TARGET of seq 7.
--       • Same circular-dependency reason for {clauses} and {UW}.
--
--   Layer 3 — This view also injects BB sub-coverages (Building_SubCov rows
--     from PER_BUILDING_TARGET, seqs 4) inside the Building </coverage> block.
--     The first </coverage> in the payload closes the Building block.
--     REGEXP_REPLACE with occurrence=1 targets only that closing tag.
--
-- Fix history:
--   2026-06-24 v1: Added hb_agg + hc_agg CTEs; resolved {HB} and {HC}.
--   2026-06-24 v2: Split into hb_parts/hb_agg and hc_parts/hc_agg;
--                  resolved {HB_CLAUSE}, {clauses}, {UW}.
--   2026-06-24 v3: Fixed BB sub-coverage placement inside </coverage>.
--   2026-06-24 v4: Corrected substitution targets. Seq 14 embeds HB/HC
--                  content directly — no {HB}/{HC} tokens exist in the
--                  risk payload. Now replaces {HB_CLAUSE}, {clauses}, {UW}
--                  directly in cte1.PAYLOAD, and injects BB sub-coverages
--                  before the first </coverage> (Building block closing tag).
-- ============================================================

CREATE OR REPLACE VIEW AGGNE.DEV.PER_BUILDING_FINAL_AGG (
    PUREPOLICYNUMBER,
    AOI,
    LOAD_DATE
) AS

WITH cte1 AS (
    -- Outer <risk> block from PER_RISK_BUILDING_TARGET (seq 14 output).
    -- PAYLOAD has HB and HC coverage blocks already embedded by DYNAMIC_XML_V1
    -- via {RISK_BUILDING} and {RISK_BC} substitution.
    -- Still contains: {HB_CLAUSE}, {clauses}, {UW} — resolved in final SELECT.
    SELECT DISTINCT
           SPLIT_PART(TRIM(ID), '|', 1) AS PUREPOLICYNUMBER,
           SPLIT_PART(TRIM(ID), '|', 3) AS EXPIRYID,
           *
    FROM   AGGNE.DEV.PER_RISK_BUILDING_TARGET
    WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    AND    ITR_TYPE = 'RISK_Building'
),

acc AS (
    -- Provides RISKNUMBER for ordering multiple buildings per policy.
    SELECT DISTINCT
           SPLIT_PART(TRIM(PUREPOLICYNUMBER), '|', 3) AS EXPIRYID,
           *
    FROM   AGGNE.DEV.PER_RISK_BUILDING_FINAL
),

-- ════════════════════════════════════════════════════════════════════════
-- HOME BUILDING (HB) — data to substitute into PER_RISK_BUILDING_TARGET
-- ════════════════════════════════════════════════════════════════════════
--
-- PER_BUILDING_TARGET contains rows of these ITR_TYPEs (PP_ConversionConfig):
--   Seq 4  Building_SubCov  ← PER_BB_SUBCOVERAGES   (BB sub-coverage rows)
--   Seq 5  BUILDING_UW      ← BUILDING_UW            (UW adjustment rows)
--   Seq 6  HB_CLAUSE        ← HB_CLAUSE              (clause rows)
--   Seq 7  RISK_Building_HB ← PER_HOME_BUILDING_PAYLOAD (main HB template)
--
-- We need:
--   CLAUSE_PAYLOAD  → replaces {HB_CLAUSE} in cte1.PAYLOAD
--   APPEND_PAYLOAD  → injected INSIDE Building </coverage> (first occurrence)
--
hb_parts AS (
    SELECT
        ID,
        LISTAGG(CASE WHEN ITR_TYPE = 'HB_CLAUSE' THEN PAYLOAD END, '\n')
            WITHIN GROUP (ORDER BY LOAD_DATE) AS CLAUSE_PAYLOAD,
        LISTAGG(CASE WHEN ITR_TYPE IN ('Building_SubCov', 'BUILDING_UW') THEN PAYLOAD END, '\n')
            WITHIN GROUP (ORDER BY LOAD_DATE) AS APPEND_PAYLOAD
    FROM   AGGNE.DEV.PER_BUILDING_TARGET
    WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP  BY ID
),

-- ════════════════════════════════════════════════════════════════════════
-- HOME CONTENTS (HC) — data to substitute into PER_RISK_BUILDING_TARGET
-- ════════════════════════════════════════════════════════════════════════
--
-- PER_HC_TARGET contains rows of these ITR_TYPEs (PP_ConversionConfig):
--   Seq 8  HC_exceed_values      ← PER_HC_ITEMS_EXCEED_VALUE
--   Seq 9  HC_Specified_Contents ← PER_HC_SPECIFIEDCONTENTS
--   Seq 10 Building_SubCov       ← PER_HC_SUBCOVERAGES  (already inlined by seq 13)
--   Seq 11 BUILDING_UW           ← PER_HC_BUILDING_UW
--   Seq 12 LOC_HC_CLAUSE         ← PER_HC_CLAUSE
--   Seq 13 RISK_Building_HC      ← PER_HOME_BUILDING_PAYLOAD
--
-- We need:
--   CLAUSE_PAYLOAD → replaces {clauses} in cte1.PAYLOAD
--   UW_PAYLOAD     → replaces {UW} in cte1.PAYLOAD
--
hc_parts AS (
    SELECT
        ID,
        LISTAGG(CASE WHEN ITR_TYPE = 'LOC_HC_CLAUSE' THEN PAYLOAD END, '\n')
            WITHIN GROUP (ORDER BY LOAD_DATE) AS CLAUSE_PAYLOAD,
        LISTAGG(CASE WHEN ITR_TYPE = 'BUILDING_UW'   THEN PAYLOAD END, '\n')
            WITHIN GROUP (ORDER BY LOAD_DATE) AS UW_PAYLOAD
    FROM   AGGNE.DEV.PER_HC_TARGET
    WHERE  CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP  BY ID
)

-- ════════════════════════════════════════════════════════════════════════
-- Final assembly: resolve remaining tokens and inject BB sub-coverages.
-- All substitutions operate directly on cte1.PAYLOAD.
--
-- Order of operations (must be innermost-first in nested REPLACE):
--   1. REPLACE {HB_CLAUSE} with HB clause rows from hb_parts
--   2. REPLACE {clauses}   with HC clause rows from hc_parts
--   3. REPLACE {UW}        with HC UW adjustment rows from hc_parts
--   4. REGEXP_REPLACE: inject BB sub-coverages (Building_SubCov + BUILDING_UW)
--      INSIDE the FIRST </coverage> tag — which closes the Building block.
--      occurrence=1 targets only the Building </coverage>, not HC or others.
-- ════════════════════════════════════════════════════════════════════════
SELECT
    t1.PUREPOLICYNUMBER,
    LISTAGG(
        REGEXP_REPLACE(
            -- Steps 1–3: replace the three surviving token placeholders
            REPLACE(
                REPLACE(
                    REPLACE(t1.PAYLOAD,
                        '{HB_CLAUSE}', COALESCE(hb.CLAUSE_PAYLOAD, '')
                    ),
                    '{clauses}', COALESCE(hc.CLAUSE_PAYLOAD, '')
                ),
                '{UW}', COALESCE(hc.UW_PAYLOAD, '')
            ),
            -- Step 4: inject BB sub-coverages inside Building </coverage>
            -- Pattern: first </coverage> in the payload
            -- Replacement: sub-coverage payloads + </coverage>
            '</coverage>',
            COALESCE(TRIM(hb.APPEND_PAYLOAD), '') || '\n</coverage>',
            1,   -- start position
            1    -- occurrence = 1 (only the first </coverage> — Building block)
        ),
        '\n'
    ) WITHIN GROUP (ORDER BY a.RISKNUMBER) AS AOI,
    t1.LOAD_DATE

FROM   cte1 t1
JOIN   acc    a   ON  TRIM(a.LEGACYPOLICYNUMBER) = TRIM(t1.PUREPOLICYNUMBER)
                  AND a.EXPIRYID                 = t1.EXPIRYID
LEFT JOIN hb_parts hb ON hb.ID = t1.ID
LEFT JOIN hc_parts hc ON hc.ID = t1.ID

GROUP  BY t1.PUREPOLICYNUMBER, t1.LOAD_DATE
ORDER  BY t1.PUREPOLICYNUMBER, t1.LOAD_DATE;
