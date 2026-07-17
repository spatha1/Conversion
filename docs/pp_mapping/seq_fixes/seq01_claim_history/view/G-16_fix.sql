-- ============================================================
-- G-16 fix — Cause: caption sent instead of code for Motor-line claims (seq 1, P1)
-- TABLE: AGGNE.DEV.PER_VW_CLAIM_HISTORY (view)
-- ============================================================
--
-- ┌─── CAUSE expression (final SELECT) ──────────────────────────────────────
-- │ CURRENT (already has a partial, unrelated fix for CAUSE='Motor'):
-- │   CASE WHEN T1.CAUSE = 'Motor' THEN 'Other' ELSE T1.CAUSE END AS CAUSE
-- │
-- │ FIX (adds the real G-16 case — caption 'At Fault' -> code 'AtFault' — on top of what's
-- │ already there, line-gated per the manuscript's 3 separate option sets so a caption never gets
-- │ mapped under the wrong Line):
-- │   CASE
-- │     WHEN T1.CAUSE = 'Motor' THEN 'Other'                                    -- existing, unchanged
-- │     WHEN T1.LINE = 'Motor'     AND TRIM(T1.CAUSE) = 'At Fault'     THEN 'AtFault'
-- │     WHEN T1.LINE = 'Motor'     AND TRIM(T1.CAUSE) = 'Not At Fault' THEN 'NotAtFault'
-- │     WHEN T1.LINE = 'Liability' AND TRIM(T1.CAUSE) = 'Customer Property Damage' THEN 'CustomerPropertyDamage'
-- │     WHEN T1.LINE = 'Liability' AND TRIM(T1.CAUSE) = 'Customer Injury' THEN 'CustomerInjury'
-- │     ELSE T1.CAUSE
-- │   END AS CAUSE
-- │   -- Property line (Fire/Flood/Burglary/Other) already matches DCT codes exactly, no case needed
-- └────────────────────────────────────────────────────────────────────────────
--
-- Live-confirmed distribution (2026-07-1x): Motor/At Fault = 30, Motor/Other = 51,
-- Property/Other = 408, Property/Burglary = 34, Property/Flood = 33, Property/Fire = 17.
-- 0 Liability-line claims exist in current data — that option set is untested, included
-- defensively per PR-01 (don't wait for a bug report to cover a documented manuscript rule).
-- Unmapped values still pass through unchanged (not dropped) — a genuinely new/untested caption
-- would need a validation-report flag, not a silent drop, per PR-01.
-- ============================================================

create or replace view PER_VW_CLAIM_HISTORY(
	PUREPOLICYNUMBER,
	CMLNUMBER,
	DATEOFCLAIM,
	AMOUNTPAID,
	LINE,
	CAUSE
) as
WITH CTE1 AS(
SELECT DISTINCT
    TRIM(T1.PUREPOLICYNUMBER) AS PUREPOLICYNUMBER,
    TRIM(T1.CMLNUMBER) AS CMLNUMBER,
    TRY_TO_DATE(REGEXP_REPLACE(TRIM(T1.DATEOFCLAIM), '[A-Za-z]', ''), 'YYYY-MM-DD')AS DATEOFCLAIM,
    TO_VARCHAR(T1.AMOUNTPAID) AS AMOUNTPAID,
    TO_VARCHAR(T1.LINE) AS LINE,
    TO_VARCHAR(T1.CAUSE) AS CAUSE
FROM AGGNE.DEV.CLAIMHISTORY AS T1
INNER JOIN AGGNE.DEV.SAMPLE_PER AS T2
ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND T1.EXPIRINGID_P=T2.EXPIRINGID_P
WHERE  T2.EFFECTIVEDATE>='2026-01-01'
) SELECT DISTINCT
    TRIM(T1.PUREPOLICYNUMBER)AS PUREPOLICYNUMBER,
    TRIM(T1.CMLNUMBER)AS CMLNUMBER,
    TO_CHAR(DATEOFCLAIM::DATE, 'YYYY-MM-DD') AS DATEOFCLAIM ,
    TO_VARCHAR(T1.AMOUNTPAID) AS AMOUNTPAID,
    TO_VARCHAR(T1.LINE) AS LINE,
    -- FIX: caption -> code mapping, per-line-gated (manuscript Package_Data 50994-51014, 51106-51129)
    CASE
        WHEN T1.CAUSE = 'Motor' THEN 'Other'
        WHEN T1.LINE = 'Motor'     AND TRIM(T1.CAUSE) = 'At Fault'     THEN 'AtFault'
        WHEN T1.LINE = 'Motor'     AND TRIM(T1.CAUSE) = 'Not At Fault' THEN 'NotAtFault'
        WHEN T1.LINE = 'Liability' AND TRIM(T1.CAUSE) = 'Customer Property Damage' THEN 'CustomerPropertyDamage'
        WHEN T1.LINE = 'Liability' AND TRIM(T1.CAUSE) = 'Customer Injury' THEN 'CustomerInjury'
        ELSE T1.CAUSE
    END AS CAUSE
    FROM CTE1 T1 ;

-- ---------- Verify after applying ----------
-- SELECT LINE, CAUSE, COUNT(*),
--   CASE
--     WHEN LINE='Motor' AND CAUSE IN ('AtFault','NotAtFault','Theft','Other') THEN 'VALID FOR LINE'
--     WHEN LINE='Liability' AND CAUSE IN ('CustomerPropertyDamage','CustomerInjury','Other') THEN 'VALID FOR LINE'
--     WHEN LINE='Property' AND CAUSE IN ('Fire','Flood','Burglary','Other') THEN 'VALID FOR LINE'
--     ELSE 'INVALID FOR THIS LINE'
--   END AS DCT_CHECK
-- FROM AGGNE.DEV.PER_VW_CLAIM_HISTORY GROUP BY 1,2 ORDER BY 3 DESC;
-- -- target: 0 'INVALID FOR THIS LINE'
