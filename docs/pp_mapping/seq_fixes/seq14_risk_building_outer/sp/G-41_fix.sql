-- ============================================================
-- G-41 fix — YearLastReWired / YearLastRePlumbed blanked for every genuinely real year
-- STORED PROCEDURE: AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()
-- (Locationdetails_PER build, "derived" CTE)
-- Line numbers shift as the SP is edited (BP team also actively edits this same SP) — do NOT rely
-- on a cached line number. Search for the exact OLD CODE text below instead. Re-confirmed live
-- 2026-07-13 after BP's weekend changes (SP grew 440,461->456,533 chars): this logic is
-- byte-for-byte unchanged, just shifted from ~line 4471 to ~line 4745.
-- ============================================================
--
-- ROOT CAUSE CONFIRMED 2026-07-13 (supersedes the earlier "stale table" hypothesis from
-- 2026-07-10's quick recon — that recon was on the right track re: blank rate, wrong about the
-- cause). The intent of this CASE was clearly "garbage years (0-1899, PURE data-entry junk) get
-- corrected to 1900; genuine years pass through unchanged" — but the inner ELSE branch (for any
-- normal 4-digit year NOT in the 0-1899 garbage range, i.e. every real rewire/replumb year) returns
-- NULL instead of the actual value. The only non-blank outputs this logic can ever produce are
-- '1900' — every genuine year like 1985, 2001, 2010 gets silently discarded.
--
-- Confirmed against AGGNE.DEV.Sample_PER (the true raw source, before this CASE runs): 787 rows
-- have a real 4-digit YearLastReWired value outside the 0-1899 garbage range, all of which are
-- currently nulled out. This is not a staleness or wrong-source-table issue — Locationdetails_PER
-- and its own upstream (Sample_PER) are both rebuilt fresh every SP run; this is a straightforward
-- logic bug in the CASE statement itself.
--
-- (An earlier "PERSONAL_RISK_01/02/03 might be a better source, same pattern as G-49" idea was
-- investigated and retracted: those 3 tables are genuinely stale — created 2026-03-05, never
-- rebuilt since, not referenced by any of the 3 main orchestrator SPs — but they turned out to be
-- a red herring; the real bug was always inside Locationdetails_PER's own logic, not a wrong source.)
--
-- ┌─── YearLastReWired_new / YearLastRePlumbed_new ("derived" CTE, ~line 4471-4479) ─────────────
-- │ OLD CODE (current, live):
-- │   NVL(CAST(CASE WHEN LENGTH(YearLastReWired) = '4' THEN (CASE WHEN CAST(YearLastReWired AS int) BETWEEN 0 AND 1899 THEN 1900 ELSE NULL END)
-- │   WHEN YearLastReWired = '0' THEN '1900'
-- │   ELSE NULL
-- │   END AS varchar),'') AS YearLastReWired_new,
-- │
-- │   NVL(CAST(CASE WHEN LENGTH(YearLastRePlumbed) = '4' THEN (CASE WHEN CAST(YearLastRePlumbed AS int) BETWEEN 0 AND 1899 THEN 1900 ELSE NULL END)
-- │   WHEN YearLastRePlumbed = '0' THEN '1900'
-- │   ELSE NULL
-- │   END AS varchar),'') AS YearLastRePlumbed_new,
-- │
-- │ NEW CODE (paste in place of the block above — only change: the inner ELSE now passes the
-- │ real year through instead of discarding it):
    NVL(CAST(CASE WHEN LENGTH(YearLastReWired) = '4' THEN (CASE WHEN CAST(YearLastReWired AS int) BETWEEN 0 AND 1899 THEN 1900 ELSE CAST(YearLastReWired AS int) END)
    WHEN YearLastReWired = '0' THEN '1900'
    ELSE NULL
    END AS varchar),'') AS YearLastReWired_new,

    NVL(CAST(CASE WHEN LENGTH(YearLastRePlumbed) = '4' THEN (CASE WHEN CAST(YearLastRePlumbed AS int) BETWEEN 0 AND 1899 THEN 1900 ELSE CAST(YearLastRePlumbed AS int) END)
    WHEN YearLastRePlumbed = '0' THEN '1900'
    ELSE NULL
    END AS varchar),'') AS YearLastRePlumbed_new,
-- └─────────────────────────────────────────────────────────────────────────────
--
-- NOTE: ELSE NULL for the outer CASE (LENGTH <> 4, e.g. blank or malformed source values) is
-- correct and unchanged — that's a genuine "no usable value" case, not part of this bug.


-- ============================================================
-- PRE-VALIDATION (2026-07-13 baseline)
-- ============================================================
SELECT COUNT(*) TOTAL, SUM(CASE WHEN YEARLASTREWIRED IS NULL OR TRIM(YEARLASTREWIRED)='' THEN 1 ELSE 0 END) BLANK_REWIRED
FROM AGGNE.DEV.Locationdetails_PER;
-- Baseline: TOTAL=4996, BLANK_REWIRED=4944 (99.0%)

SELECT COUNT(*) AS TOTAL_RECOVERABLE
FROM AGGNE.DEV.Sample_PER
WHERE LENGTH(YearLastReWired) = 4 AND TRY_CAST(YearLastReWired AS INT) > 1899;
-- Baseline: 787 rows have a real year that should stop being nulled out


-- ============================================================
-- POST-VALIDATION — run after the SP is redeployed and Locationdetails_PER is rebuilt
-- (CALL AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD(); then re-run PP_CONVERSION_RUN(TRUE))
-- ============================================================

-- 1) Blank rate should drop by roughly the 787-row recoverable population
SELECT COUNT(*) TOTAL, SUM(CASE WHEN YEARLASTREWIRED IS NULL OR TRIM(YEARLASTREWIRED)='' THEN 1 ELSE 0 END) STILL_BLANK
FROM AGGNE.DEV.Locationdetails_PER;
-- Target: STILL_BLANK drops from 4,944 toward ~4,157 (4,944 - 787)

-- 2) Spot-check: real years now flow through unchanged (not converted to 1900)
SELECT YEARLASTREWIRED, COUNT(*) FROM AGGNE.DEV.Locationdetails_PER
WHERE YEARLASTREWIRED IS NOT NULL AND TRIM(YEARLASTREWIRED) <> ''
GROUP BY 1 ORDER BY 2 DESC LIMIT 20;
-- Target: a real spread of years (2000, 2010, 1970, 2008...) not just '1900'

-- 3) Regression check — garbage years (0-1899) still correctly become 1900, not something else
SELECT COUNT(*) AS GARBAGE_YEAR_MISHANDLED
FROM AGGNE.DEV.Sample_PER
WHERE LENGTH(YearLastReWired) = 4 AND TRY_CAST(YearLastReWired AS INT) BETWEEN 0 AND 1899
  AND TRIM(YearLastReWired) <> '';
-- Informational count only — cross-check these specific rows show YEARLASTREWIRED='1900' in
-- Locationdetails_PER after the fix, same as before (unaffected by this change)

-- 4) Age-41+ population specifically (the original ticket's framing) — re-run the same query used
--    in the 2026-07-10 recon to see the improvement in that specific slice
SELECT COUNT(*) TOTAL,
    SUM(CASE WHEN YEARLASTREWIRED IS NULL OR TRIM(YEARLASTREWIRED)='' THEN 1 ELSE 0 END) BLANK_REWIRED
FROM AGGNE.DEV.Locationdetails_PER
WHERE TRY_TO_NUMBER(CAST(YEARBUILDINGCONSTRUCTED AS VARCHAR)) <= 1985
  AND TRY_TO_NUMBER(CAST(YEARBUILDINGCONSTRUCTED AS VARCHAR)) > 1800;
-- Baseline (2026-07-13, before fix): TOTAL=1582, BLANK_REWIRED=1530 (96.7%)
-- ============================================================
