create or replace view PER_BUILDING_FINAL_AGG(
	PUREPOLICYNUMBER,
	AOI,
	LOAD_DATE
) as

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