-- ============================================================
-- G-42 fix — Motor Premium (PMEXPPREM) always zero (seq 18, P1)
-- VIEW: AGGNE.DEV.PER_COM_PAYLOAD (~line 294, CTE_EXCESS join to Output_Coverage_PER)
-- Code-only patch — this view is shared by G-01/G-02/G-04/G-08/G-12/G-42, do not paste a full
-- CREATE OR REPLACE from this file alone or you will drop the other gaps' fixes.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-09):
--   Source has real values: AGGNE.DEV.OUTPUT_COVERAGE_PER has 5,018 rows, 2,181 (43%) with a real
--   non-zero PMEXPPREM.
--   Payload always shows zero: AGGNE.DEV.PER_COM_PAYLOAD — 3,304 of 3,304 (100%) rows zero/blank.
--
-- ROOT CAUSE: T1.PUREPOLICYNUMBER in this view is the COMPOSITE key
-- (LEGACYPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P). T4.POLICYNUMBER (Output_Coverage_PER) is the PLAIN
-- pure policy number — composite never equals plain, so the join never matches and
-- COALESCE(T4.PMEXPPREM,0) always falls to 0. Output_Coverage_PER also carries EXPIRINGID_P for a
-- precise per-term match (a plain policy number alone can span multiple terms/renewals);
-- T1.EXPIRINGID_P is already available in CTE_EXCESS (used elsewhere in this same view for the
-- RedbookCode join), so no new column needs to be added upstream.
--
-- ┌─── Output_Coverage_PER join (final SELECT FROM clause) ────────────────────
-- │ OLD CODE (current, live):
-- │   LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4 ON T1.PUREPOLICYNUMBER=T4.POLICYNUMBER
-- │
-- │ NEW CODE:
-- │   LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4
-- │       ON SPLIT_PART(T1.PUREPOLICYNUMBER, '|', 1) = T4.POLICYNUMBER
-- │      AND T1.EXPIRINGID_P = T4.EXPIRINGID_P
-- └─────────────────────────────────────────────────────────────────────────────
--
-- Apply the same change to PER_COM_PAYLOAD in both views/ and views_uat/. This view isn't
-- config-driven (called directly by DYNAMIC_XML_V1), so PP_CONVERSION_RUN does not need a matching
-- change for this specific gap.


-- ============================================================
-- PRE-VALIDATION (2026-07-09 baseline)
-- ============================================================

SELECT COUNT(*) AS TOTAL, COUNT(DISTINCT POLICYNUMBER) AS DISTINCT_POL,
       SUM(CASE WHEN PMEXPPREM IS NOT NULL AND PMEXPPREM<>0 THEN 1 ELSE 0 END) AS NONZERO
FROM AGGNE.DEV.OUTPUT_COVERAGE_PER;
-- Baseline: TOTAL=5018, NONZERO=2181 (43%)

SELECT SUM(CASE WHEN COALESCE(TRIM(PMEXPPREM),'')='' OR TRY_TO_NUMBER(PMEXPPREM)=0 THEN 1 ELSE 0 END) AS ZERO_OR_BLANK,
       COUNT(*) AS TOTAL
FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- Baseline: ZERO_OR_BLANK=3304, TOTAL=3304 (100%)


-- ============================================================
-- POST-VALIDATION
-- ============================================================

SELECT SUM(CASE WHEN TRY_TO_NUMBER(PMEXPPREM) > 0 THEN 1 ELSE 0 END) AS NONZERO,
       COUNT(*) AS TOTAL
FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- Target: NONZERO lands near the source's ~43% rate, not 0

-- Spot-check a sample of previously-zero rows now show a real premium
SELECT p.PUREPOLICYNUMBER, p.PMEXPPREM, o.PMEXPPREM AS SRC_PMEXPPREM
FROM AGGNE.DEV.PER_COM_PAYLOAD p
JOIN AGGNE.DEV.OUTPUT_COVERAGE_PER o
    ON SPLIT_PART(p.PUREPOLICYNUMBER, '|', 1) = o.POLICYNUMBER
WHERE o.PMEXPPREM IS NOT NULL AND o.PMEXPPREM <> 0
LIMIT 20;
-- Target: p.PMEXPPREM matches o.PMEXPPREM for every row (cast/rounding aside)
-- ============================================================
