-- ============================================================
-- G-07 fix — VoluntaryExcess (Motor) banded to wrong tiers, some above DCT's max
-- STORED PROCEDURE: AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()
-- (PM_01 build, ~line 8876-8889)
-- ============================================================
--
-- CLIENT ANSWER (13 July 2026 MoM): "The maximum available value in the Duck Creek (DC) Voluntary
-- Excess dropdown is $1,500. Therefore, during conversion renewals, if the value in Pure exceeds
-- $1,500, the field should default to $1,500 in DC." — resolves option (a) from this file's
-- original question below.
--
-- ROOT CAUSE: the current banding doesn't just fail to cap at $1,500 — it bands to completely the
-- WRONG set of tiers. DCT's real dropdown (confirmed against the manuscript) only accepts 7 values:
-- $0/$250/$500/$750/$1,000/$1,250/$1,500 — but the live code bands to $0/$500/$1,000/$2,000/$5,000,
-- and never uses the $250/$750/$1,250 tiers at all. Live-confirmed PM_01 distribution (2026-07-13):
-- 9 vehicles show $2,000 (always invalid), 214 band to $500 and 25 to $1,000 (both technically valid
-- DCT values, but imprecise — raw source values are genuinely varied: $50/$100/$150/$200/$300/$400/
-- $450/$600/$700/$800/$900/$1,100/$1,300/$1,700..., not pre-aligned to any tier).
--
-- ┌─── VoluntaryExcess (PM_01 build) ────────────────────────────────────────────
-- │ OLD CODE (current, live):
-- │   CASE
-- │       WHEN t3.MVCVVoluntary IS NULL THEN 0
-- │       WHEN t3.MVCVVoluntary = 0 THEN 0
-- │       WHEN t3.MVCVVoluntary <= 500 THEN 500
-- │       WHEN t3.MVCVVoluntary <= 1000 THEN 1000
-- │       WHEN t3.MVCVVoluntary <= 2000 THEN 2000
-- │       WHEN t3.MVCVVoluntary > 2000 THEN 5000
-- │       END AS VoluntaryExcess,
-- │
-- │ NEW CODE (same ceiling-banding style as the original, corrected to DCT's real 7-tier ladder,
-- │ capped at $1,500 per the client's answer):
    CASE
        WHEN t3.MVCVVoluntary IS NULL THEN 0
        WHEN t3.MVCVVoluntary = 0 THEN 0
        WHEN t3.MVCVVoluntary <= 250 THEN 250
        WHEN t3.MVCVVoluntary <= 500 THEN 500
        WHEN t3.MVCVVoluntary <= 750 THEN 750
        WHEN t3.MVCVVoluntary <= 1000 THEN 1000
        WHEN t3.MVCVVoluntary <= 1250 THEN 1250
        WHEN t3.MVCVVoluntary <= 1500 THEN 1500
        WHEN t3.MVCVVoluntary > 1500 THEN 1500
        END AS VoluntaryExcess,
-- └─────────────────────────────────────────────────────────────────────────────


-- ============================================================
-- PRE-VALIDATION (2026-07-13 baseline)
-- ============================================================
SELECT VOLUNTARYEXCESS, COUNT(*) FROM AGGNE.DEV.PM_01 GROUP BY 1 ORDER BY 1;
-- Baseline: 0 (7,046) / 500 (214) / 1000 (25) / 2000 (9)

SELECT MVCVVoluntary, COUNT(*) FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL t3
JOIN AGGNE.DEV.Sample_PrivateMotor_PER t2 ON t2.ExpiringID_P = t3.PER_Policy_Binder_id
WHERE t3.MVCVVoluntary IS NOT NULL GROUP BY 1 ORDER BY 2 DESC;
-- Baseline raw distribution: 0 (4,263), 200 (57), 500 (43), 300 (32), 150 (27), 100 (26), 50 (12),
-- 400 (10), 800 (7), 1000 (6), 600 (6), 1100 (4), 450 (3), 1300 (3), 250 (3), 900 (2), 700 (2),
-- 210 (1), 550 (1), 1700 (1)


-- ============================================================
-- POST-VALIDATION — run after the SP is redeployed and PM_01 is rebuilt
-- ============================================================

-- 1) No more values outside DCT's valid 7-tier list
SELECT VOLUNTARYEXCESS, COUNT(*) FROM AGGNE.DEV.PM_01
WHERE VOLUNTARYEXCESS NOT IN (0,250,500,750,1000,1250,1500)
GROUP BY 1;
-- Target: 0 rows

-- 2) The 9 previously-$2,000 vehicles now cap at $1,500
SELECT VOLUNTARYEXCESS, COUNT(*) FROM AGGNE.DEV.PM_01 GROUP BY 1 ORDER BY 1;
-- Target: no more 2000/5000 bucket; new 250/750/1250 buckets now populated; 1500 bucket present

-- 3) Real payload check
SELECT COUNT(*) AS STILL_INVALID FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE VOLUNTARYEXCESS NOT IN ('0','250','500','750','1000','1250','1500');
-- Target: 0
-- ============================================================
