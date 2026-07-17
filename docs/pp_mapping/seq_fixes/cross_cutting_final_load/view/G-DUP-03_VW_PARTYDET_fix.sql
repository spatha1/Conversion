-- ============================================================
-- G-DUP-03 (CORRECTED 2026-07-13) — AGGNE.DEV.VW_PARTYDET missing array de-dup (P2)
-- ============================================================
--
-- ORIGINAL (WRONG) DIAGNOSIS: first suspected a timing/race condition against
-- AGGNE.UAT.VW_PARTYDET while investigating the single P00027855 residual duplicate left after
-- G-DUP-01. That was the wrong table — AGGNE.DEV.PER_CONVERSION_FINAL_LOAD actually joins
-- AGGNE.DEV.VW_PARTYDET (a DIFFERENT view, same name, DEV schema), confirmed via a DEV-vs-UAT
-- procedure diff. Re-checked against the correct view — this is a real, deterministic bug, not
-- volatility.
--
-- ROOT CAUSE: AGGNE.DEV.VW_PARTYDET picks the MAX(PARTY_DIM_ID) per CML_NUMBER (via CTE `e`), then
-- LATERAL FLATTENs that one row's RESULTS_JSON array with NO limit on array elements. When that
-- JSON array holds more than one entry with a real PartyId (confirmed for CML00001889: 2 entries,
-- '08DE22BCE81F3499'/'20309' and '08DE22BCE9D9D4D4'/'20310', both under the same PARTY_DIM_ID
-- 807751), both survive as separate output rows -- feeding a 1:many fan-out into every downstream
-- join (PER_CONVERSION_FINAL_LOAD -> PER_FINAL -> PER_POLICY_MIGRATION_DCT).
--
-- CONFIRMED live 2026-07-13: 4 CML_NUMBERs affected globally (CML00019910, CML00001889,
-- CML00026663, CML00014715) -- matches AGGNE.UAT.VW_PARTYDET's OWN definition, which already has
-- the fix for this exact scenario: `QUALIFY ROW_NUMBER() OVER (PARTITION BY d.CML_NUMBER
-- ORDER BY f.index) = 1`. DEV's copy is simply missing that QUALIFY clause -- otherwise identical
-- intent (pick one PartyId per CML). Mirroring UAT's own established tie-break (first array
-- element, f.index ascending) for consistency between the two schemas' logic.
--
-- ┌─── OLD CODE (current, live) ────────────────────────────────────────────────
-- │ create or replace view VW_PARTYDET(
-- │ 	CML_NUMBER,
-- │ 	PARTY_DIM_ID,
-- │ 	PARTYID,
-- │ 	PARTYNUMBER
-- │ ) as
-- │
-- │ WITH cte AS (
-- │     SELECT
-- │         CML_NUMBER,
-- │         MAX(PARTY_DIM_ID) AS PARTY_DIM_ID
-- │     FROM AGGNE.DEV.CML_MIGRATION_DCT_PREVDATA   where RESULTS_JSON is not null
-- │     GROUP BY CML_NUMBER
-- │ )
-- │ select * from (
-- │ SELECT DISTINCT
-- │     d.CML_NUMBER,
-- │     d.PARTY_DIM_ID,
-- │     f.value:PartyId::STRING   AS PARTYID,
-- │     f.value:PartyNumber::STRING AS PARTYNUMBER
-- │ FROM AGGNE.DEV.CML_MIGRATION_DCT_PREVDATA d
-- │ JOIN cte e
-- │     ON e.CML_NUMBER = d.CML_NUMBER
-- │    AND d.PARTY_DIM_ID = e.PARTY_DIM_ID
-- │ , LATERAL FLATTEN(input => d.RESULTS_JSON) f
-- │ WHERE d.CML_NUMBER IS NOT NULL
-- │   AND f.value:PartyId IS NOT NULL
-- │   AND d.RESPONSE_XML NOT LIKE '%error%') where PARTYID is not null;
-- └─────────────────────────────────────────────────────────────────────────────

create or replace view VW_PARTYDET(
	CML_NUMBER,
	PARTY_DIM_ID,
	PARTYID,
	PARTYNUMBER
) as

WITH cte AS (
    SELECT
        CML_NUMBER,
        MAX(PARTY_DIM_ID) AS PARTY_DIM_ID
    FROM AGGNE.DEV.CML_MIGRATION_DCT_PREVDATA   where RESULTS_JSON is not null
    GROUP BY CML_NUMBER
)
select * from (
SELECT DISTINCT
    d.CML_NUMBER,
    d.PARTY_DIM_ID,
    f.value:PartyId::STRING   AS PARTYID,
    f.value:PartyNumber::STRING AS PARTYNUMBER
FROM AGGNE.DEV.CML_MIGRATION_DCT_PREVDATA d
JOIN cte e
    ON e.CML_NUMBER = d.CML_NUMBER
   AND d.PARTY_DIM_ID = e.PARTY_DIM_ID
, LATERAL FLATTEN(input => d.RESULTS_JSON) f
WHERE d.CML_NUMBER IS NOT NULL
  AND f.value:PartyId IS NOT NULL
  AND d.RESPONSE_XML NOT LIKE '%error%'
-- FIX (G-DUP-03): keep only the first PartyId per CML when the JSON array holds more than one --
-- mirrors AGGNE.UAT.VW_PARTYDET's own already-deployed fix for this exact scenario.
QUALIFY ROW_NUMBER() OVER (PARTITION BY d.CML_NUMBER ORDER BY f.index) = 1
) where PARTYID is not null;


-- ============================================================
-- PRE-VALIDATION (2026-07-13 baseline, confirmed live)
-- ============================================================
SELECT CML_NUMBER, COUNT(*) FROM AGGNE.DEV.VW_PARTYDET
GROUP BY CML_NUMBER HAVING COUNT(*) > 1;
-- Baseline: 4 rows (CML00019910, CML00001889, CML00026663, CML00014715)

SELECT COUNT(*), COUNT(DISTINCT LEGACYPOLICYNUMBER) FROM AGGNE.DEV.PER_FINAL;
-- Baseline: 3988 / 3987 (1 duplicate — P00027855)


-- ============================================================
-- POST-VALIDATION — run after deploying + CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD() +
-- CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML() (or PP_CONVERSION_RUN(FALSE) for final-only)
-- ============================================================

-- 1) No more duplicate CML_NUMBERs in VW_PARTYDET
SELECT CML_NUMBER, COUNT(*) FROM AGGNE.DEV.VW_PARTYDET
GROUP BY CML_NUMBER HAVING COUNT(*) > 1;
-- Target: 0 rows

-- 2) PER_FINAL fully deduped
SELECT COUNT(*), COUNT(DISTINCT LEGACYPOLICYNUMBER) FROM AGGNE.DEV.PER_FINAL;
-- Target: equal counts

-- 3) Real DCT-facing table fully deduped
SELECT COUNT(*), COUNT(DISTINCT LEGACYPOLICYNUMBER) FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;
-- Target: equal counts
-- ============================================================
