-- ============================================================
-- BP GAP ANALYSIS — Mandatory sections + Line coverages
-- Date    : 2026-06-30
-- Purpose : For each UAT test policy identify:
--   SOURCE (Code expectation)  — source view has rows
--   TARGET (Available)         — DEV target table has rows (latest LOAD_DATE)
--   STATUS:
--     OK               — source AND target have data
--     GAP              — source has rows, target is empty (ETL4 conversion gap)
--     MANDATORY_MISSING— source is also empty (mandatory step, no data at all)
--     N/A              — conditional section, policy has no this coverage
-- PRD column: is the policy in AGGNE.PRD.POLICY_ATTACH_TABLE?
--
-- Run with: USE DATABASE AGGNE; USE SCHEMA DEV;
-- ============================================================

WITH

test_policies AS (
    SELECT TRIM(LEGACYPOLICYNUMBER) AS POLICY
    FROM AGGNE.UAT.VW_TEST_POLICYCONVERSION_LIST
),

-- ── Latest LOAD_DATE per target / ITR_TYPE ────────────────────────────────────
max_acc   AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.ACCOUNT_LOC_AGG),
max_aoi   AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.AOI_FINAL_AGG),
max_claim AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.VW_CLAIM_HISTORY_AGG),
max_comp  AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.VW_COMP_INFO_AGG
              WHERE ITR_TYPE = 'BP_Prior_INFO'),
max_gp    AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.LINE_GP_Target
              WHERE ITR_TYPE = 'BP_LINE_GP'),
max_ppl   AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.LINE_PPL_Target
              WHERE ITR_TYPE = 'BP_LINE_PPL'),
max_pf    AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.LINE_PF_Target
              WHERE ITR_TYPE = 'BP_LINE_PF'),
max_gt    AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.LINE_GT_Target
              WHERE ITR_TYPE = 'BP_LINE_GT'),
max_le    AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.LINE_LE_Target
              WHERE ITR_TYPE = 'BP_LINE_LE'),
max_sv    AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.LINE_SV_Target
              WHERE ITR_TYPE = 'BP_LINE_SV'),
max_cv    AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.LINE_CV_Target
              WHERE ITR_TYPE = 'BP_LINE_CV'),
max_ta    AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.LINE_TA_Target
              WHERE ITR_TYPE = 'BP_LINE_TA'),
max_bld   AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.BUILDING_Target
              WHERE ITR_TYPE = 'BP_RISK_Building_Cov_Building'),

-- ── SOURCE: code expectation (source conversion views) ───────────────────────
-- MANDATORY: expected for ALL policies
-- Note: ACCOUNT_LOC.PUREPOLICYNUMBER is composite (policy|cml|expiring);
--       LEGACYPOLICYNUMBER is the plain policy number.
src_acc   AS (SELECT DISTINCT TRIM(LEGACYPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.ACCOUNT_LOC),
src_aoi   AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER)   AS POLICY FROM AGGNE.DEV.AOI_FINAL),
src_claim AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER)   AS POLICY FROM AGGNE.DEV.VW_CLAIM_HISTORY),
src_comp  AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER)   AS POLICY FROM AGGNE.DEV.VW_CBP_COMPETITOR_INFORMATION),

-- CONDITIONAL: LINE coverage sections (only policies with that coverage)
src_gp    AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.LINE_GP_PAYLOAD),
src_ppl   AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.LINE_PPL_PAYLOAD),
src_pf    AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.LINE_PF_PAYLOAD),
src_gt    AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.LINE_GT_PAYLOAD),
src_le    AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.LINE_LE_PAYLOAD),
src_sv    AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.LINE_SV_PAYLOAD),
src_cv    AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.LINE_CV_PAYLOAD),
src_ta    AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.LINE_TA_PAYLOAD),

-- CONDITIONAL: Building and Vehicle sections
src_bld   AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY FROM AGGNE.DEV.BUILDING_PAYLOAD),

-- ── TARGET: what was actually loaded (latest LOAD_DATE) ──────────────────────
-- AGG views: PUREPOLICYNUMBER = plain policy number
-- *_Target tables: ID = composite; SPLIT_PART('|',1) = plain policy
tgt_acc   AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY
              FROM AGGNE.DEV.ACCOUNT_LOC_AGG
              WHERE CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_acc)),

tgt_aoi   AS (SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY
              FROM AGGNE.DEV.AOI_FINAL_AGG
              WHERE CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_aoi)),

tgt_claim AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.VW_CLAIM_HISTORY_AGG
              WHERE CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_claim)),

tgt_comp  AS (SELECT DISTINCT TRIM(ID) AS POLICY
              FROM AGGNE.DEV.VW_COMP_INFO_AGG
              WHERE ITR_TYPE = 'BP_Prior_INFO'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_comp)),

tgt_gp    AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.LINE_GP_Target
              WHERE ITR_TYPE = 'BP_LINE_GP'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_gp)),

tgt_ppl   AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.LINE_PPL_Target
              WHERE ITR_TYPE = 'BP_LINE_PPL'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_ppl)),

tgt_pf    AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.LINE_PF_Target
              WHERE ITR_TYPE = 'BP_LINE_PF'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_pf)),

tgt_gt    AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.LINE_GT_Target
              WHERE ITR_TYPE = 'BP_LINE_GT'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_gt)),

tgt_le    AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.LINE_LE_Target
              WHERE ITR_TYPE = 'BP_LINE_LE'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_le)),

tgt_sv    AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.LINE_SV_Target
              WHERE ITR_TYPE = 'BP_LINE_SV'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_sv)),

tgt_cv    AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.LINE_CV_Target
              WHERE ITR_TYPE = 'BP_LINE_CV'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_cv)),

tgt_ta    AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.LINE_TA_Target
              WHERE ITR_TYPE = 'BP_LINE_TA'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_ta)),

tgt_bld   AS (SELECT DISTINCT SPLIT_PART(TRIM(ID),'|',1) AS POLICY
              FROM AGGNE.DEV.BUILDING_Target
              WHERE ITR_TYPE = 'BP_RISK_Building_Cov_Building'
                AND CAST(LOAD_DATE AS DATE) = (SELECT D FROM max_bld)),

-- ── PRD: placeholder — PRD identifier table column TBD ──────────────────────
-- To add PRD comparison, replace the SELECT below with actual PRD query
prd_attached AS (SELECT NULL::VARCHAR AS POLICY WHERE 1=0)

-- ── FINAL OUTPUT ─────────────────────────────────────────────────────────────
SELECT
    p.POLICY,

    -- ── MANDATORY sections (Seq 1-4 in ConversionConfig) ────────────────────
    CASE
        WHEN tgt_acc.POLICY  IS NOT NULL THEN 'OK'
        WHEN src_acc.POLICY  IS NOT NULL THEN 'GAP'
        ELSE 'MANDATORY_MISSING'
    END AS "ACC_LOC [Seq1]",

    CASE
        WHEN tgt_aoi.POLICY  IS NOT NULL THEN 'OK'
        WHEN src_aoi.POLICY  IS NOT NULL THEN 'GAP'
        ELSE 'MANDATORY_MISSING'
    END AS "AOI [Seq2]",

    CASE
        WHEN tgt_claim.POLICY IS NOT NULL THEN 'OK'
        WHEN src_claim.POLICY IS NOT NULL THEN 'GAP'
        ELSE 'MANDATORY_MISSING'
    END AS "CLAIM_HIST [Seq3]",

    CASE
        WHEN tgt_comp.POLICY IS NOT NULL THEN 'OK'
        WHEN src_comp.POLICY IS NOT NULL THEN 'GAP'
        ELSE 'MANDATORY_MISSING'
    END AS "COMP_INFO [Seq4]",

    -- ── LINE coverage sections (Seq 5-29) ────────────────────────────────────
    CASE
        WHEN src_gp.POLICY IS NULL THEN 'N/A'
        WHEN tgt_gp.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "LINE_GP",

    CASE
        WHEN src_ppl.POLICY IS NULL THEN 'N/A'
        WHEN tgt_ppl.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "LINE_PPL",

    CASE
        WHEN src_pf.POLICY IS NULL THEN 'N/A'
        WHEN tgt_pf.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "LINE_PF",

    CASE
        WHEN src_gt.POLICY IS NULL THEN 'N/A'
        WHEN tgt_gt.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "LINE_GT",

    CASE
        WHEN src_le.POLICY IS NULL THEN 'N/A'
        WHEN tgt_le.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "LINE_LE",

    CASE
        WHEN src_sv.POLICY IS NULL THEN 'N/A'
        WHEN tgt_sv.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "LINE_SV",

    CASE
        WHEN src_cv.POLICY IS NULL THEN 'N/A'
        WHEN tgt_cv.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "LINE_CV",

    CASE
        WHEN src_ta.POLICY IS NULL THEN 'N/A'
        WHEN tgt_ta.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "LINE_TA",

    -- ── Building section ────────────────────────────────────────────────────
    CASE
        WHEN src_bld.POLICY IS NULL THEN 'N/A'
        WHEN tgt_bld.POLICY IS NOT NULL THEN 'OK'
        ELSE 'GAP'
    END AS "BUILDING",

    -- ── PRD attach status ────────────────────────────────────────────────────
    CASE
        WHEN prd_attached.POLICY IS NOT NULL THEN 'PRD_ATTACHED'
        ELSE 'NOT_IN_PRD'
    END AS PRD_STATUS,

    -- Summary counts
    (CASE WHEN tgt_acc.POLICY   IS NULL AND src_acc.POLICY   IS NOT NULL THEN 1 ELSE 0 END
   + CASE WHEN tgt_aoi.POLICY   IS NULL AND src_aoi.POLICY   IS NOT NULL THEN 1 ELSE 0 END
   + CASE WHEN tgt_claim.POLICY IS NULL AND src_claim.POLICY IS NOT NULL THEN 1 ELSE 0 END
   + CASE WHEN tgt_comp.POLICY  IS NULL AND src_comp.POLICY  IS NOT NULL THEN 1 ELSE 0 END
   + CASE WHEN src_gp.POLICY  IS NOT NULL AND tgt_gp.POLICY  IS NULL THEN 1 ELSE 0 END
   + CASE WHEN src_ppl.POLICY IS NOT NULL AND tgt_ppl.POLICY IS NULL THEN 1 ELSE 0 END
   + CASE WHEN src_pf.POLICY  IS NOT NULL AND tgt_pf.POLICY  IS NULL THEN 1 ELSE 0 END
   + CASE WHEN src_gt.POLICY  IS NOT NULL AND tgt_gt.POLICY  IS NULL THEN 1 ELSE 0 END
   + CASE WHEN src_le.POLICY  IS NOT NULL AND tgt_le.POLICY  IS NULL THEN 1 ELSE 0 END
   + CASE WHEN src_sv.POLICY  IS NOT NULL AND tgt_sv.POLICY  IS NULL THEN 1 ELSE 0 END
   + CASE WHEN src_cv.POLICY  IS NOT NULL AND tgt_cv.POLICY  IS NULL THEN 1 ELSE 0 END
   + CASE WHEN src_ta.POLICY  IS NOT NULL AND tgt_ta.POLICY  IS NULL THEN 1 ELSE 0 END
   + CASE WHEN src_bld.POLICY IS NOT NULL AND tgt_bld.POLICY IS NULL THEN 1 ELSE 0 END
    ) AS GAP_COUNT,

    (CASE WHEN tgt_acc.POLICY   IS NULL AND src_acc.POLICY   IS NULL THEN 1 ELSE 0 END
   + CASE WHEN tgt_aoi.POLICY   IS NULL AND src_aoi.POLICY   IS NULL THEN 1 ELSE 0 END
   + CASE WHEN tgt_claim.POLICY IS NULL AND src_claim.POLICY IS NULL THEN 1 ELSE 0 END
   + CASE WHEN tgt_comp.POLICY  IS NULL AND src_comp.POLICY  IS NULL THEN 1 ELSE 0 END
    ) AS MANDATORY_MISSING_COUNT

FROM test_policies p
LEFT JOIN src_acc   ON p.POLICY = src_acc.POLICY
LEFT JOIN tgt_acc   ON p.POLICY = tgt_acc.POLICY
LEFT JOIN src_aoi   ON p.POLICY = src_aoi.POLICY
LEFT JOIN tgt_aoi   ON p.POLICY = tgt_aoi.POLICY
LEFT JOIN src_claim ON p.POLICY = src_claim.POLICY
LEFT JOIN tgt_claim ON p.POLICY = tgt_claim.POLICY
LEFT JOIN src_comp  ON p.POLICY = src_comp.POLICY
LEFT JOIN tgt_comp  ON p.POLICY = tgt_comp.POLICY
LEFT JOIN src_gp    ON p.POLICY = src_gp.POLICY
LEFT JOIN tgt_gp    ON p.POLICY = tgt_gp.POLICY
LEFT JOIN src_ppl   ON p.POLICY = src_ppl.POLICY
LEFT JOIN tgt_ppl   ON p.POLICY = tgt_ppl.POLICY
LEFT JOIN src_pf    ON p.POLICY = src_pf.POLICY
LEFT JOIN tgt_pf    ON p.POLICY = tgt_pf.POLICY
LEFT JOIN src_gt    ON p.POLICY = src_gt.POLICY
LEFT JOIN tgt_gt    ON p.POLICY = tgt_gt.POLICY
LEFT JOIN src_le    ON p.POLICY = src_le.POLICY
LEFT JOIN tgt_le    ON p.POLICY = tgt_le.POLICY
LEFT JOIN src_sv    ON p.POLICY = src_sv.POLICY
LEFT JOIN tgt_sv    ON p.POLICY = tgt_sv.POLICY
LEFT JOIN src_cv    ON p.POLICY = src_cv.POLICY
LEFT JOIN tgt_cv    ON p.POLICY = tgt_cv.POLICY
LEFT JOIN src_ta    ON p.POLICY = src_ta.POLICY
LEFT JOIN tgt_ta    ON p.POLICY = tgt_ta.POLICY
LEFT JOIN src_bld   ON p.POLICY = src_bld.POLICY
LEFT JOIN tgt_bld   ON p.POLICY = tgt_bld.POLICY
LEFT JOIN prd_attached ON p.POLICY = prd_attached.POLICY
ORDER BY (GAP_COUNT + MANDATORY_MISSING_COUNT) DESC, p.POLICY;
