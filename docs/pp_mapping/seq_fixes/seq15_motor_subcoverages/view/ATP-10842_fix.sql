-- ============================================================
-- ATP-10842 fix — Windscreen/Glass Excess (Unlimited Glass, PMULG_SD) always shows Indicator=1
-- VIEW: AGGNE.DEV.PER_COM_COVERAGES (Unlimited Glass UNION ALL branch, ~line 155-171)
-- Related to G-37 (Motor sub-coverage matrix, all 8 codes always on) but SCOPED and deployable now —
-- unlike the other 7 codes (which need a client-defined ProtectionType exclusivity matrix), this one
-- code already has an unambiguous, correctly-computed driver: EXCESSWAIVERFORGLASS.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-10):
--   PER_COM_COVERAGES WHERE CODE='PMULG_SD': INDICATOR = '1' for all 2,175 rows (100%, hardcoded).
--   PM_03.EXCESSWAIVERFORGLASS (raw): 'Yes' 2,658 / '' 1,660 / 'No' 45 — real, varying signal exists.
--   PER_COM_PAYLOAD.EXCESSWAIVERFORGLASS (already correctly mapped under ATP-11003): '1' 2,658 /
--   '0' 649 — confirms the Yes/Taken->1, else->0 mapping pattern is already proven correct elsewhere
--   in this same pipeline; reusing it here for consistency.
--
-- ┌─── PMULG_SD INDICATOR (PER_COM_COVERAGES, ~line 166) ──────────────────────
-- │ OLD CODE (current, live):
-- │   CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR) AS INDICATOR,
-- │   ...
-- │   FROM AGGNE.DEV.PM_03 T1 LEFT JOIN AGGNE.DEV.Output_SubCover_PER T2
-- │   ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.POLICYNUMBER)
-- │   AND T1.EXPIRINGID_P=T2.EXPIRINGID_P AND SUB_COVERAGE='PMULG_SD'
-- │
-- │ NEW CODE:
-- │   CASE WHEN T1.EXCESSWAIVERFORGLASS IN ('Yes','Taken') THEN CAST(CAST(1 AS NUMBER(1,0)) AS VARCHAR)
-- │        ELSE CAST(CAST(0 AS NUMBER(1,0)) AS VARCHAR) END AS INDICATOR,
-- │   ... (FROM/JOIN unchanged)
-- └─────────────────────────────────────────────────────────────────────────────
--
-- Code-only patch — PER_COM_COVERAGES has 8 UNION ALL branches for the other sub-coverage codes;
-- only touch the PMULG_SD (Unlimited Glass) branch, leave the other 7 (PMCMP_SD/PMCOR_SD/PMFTL_SD/
-- PMLIA_SD/PMPCH_SD/PMTFT_SD/PMTPO_SD) untouched — those remain G-37's open client question.


-- ============================================================
-- PRE-VALIDATION (2026-07-10 baseline)
-- ============================================================
SELECT INDICATOR, COUNT(*) FROM AGGNE.DEV.PER_COM_COVERAGES WHERE CODE='PMULG_SD' GROUP BY 1;
-- Baseline: only '1', 2,175 rows (100% hardcoded)


-- ============================================================
-- POST-VALIDATION
-- ============================================================
SELECT INDICATOR, COUNT(*) FROM AGGNE.DEV.PER_COM_COVERAGES WHERE CODE='PMULG_SD' GROUP BY 1;
-- Target: two buckets now, roughly matching PM_03's real EXCESSWAIVERFORGLASS split
-- (~2,658 'Yes'-driven '1' vs ~1,705 blank/'No'-driven '0')

-- Spot-check: vehicles where glass excess is NOT waived should no longer claim Unlimited Glass
SELECT p.PUREPOLICYNUMBER, p.EXCESSWAIVERFORGLASS, c.INDICATOR
FROM AGGNE.DEV.PER_COM_PAYLOAD p
JOIN AGGNE.DEV.PER_COM_COVERAGES c
  ON c.PUREPOLICYNUMBER = p.PUREPOLICYNUMBER AND c.CODE = 'PMULG_SD'
WHERE p.EXCESSWAIVERFORGLASS = '0'
LIMIT 20;
-- Target: c.INDICATOR = '0' for all rows here (was '1' for all before this fix)
-- ============================================================
