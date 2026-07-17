-- ============================================================
-- G-17 fix — PriorCarrier: caption vs code, resolved via Attach reference (seq 2, P2)
-- Only 1/300 rows wrong. NOT YET APPLIED.
-- ============================================================

-- ---------- Resolved — no longer "conflicting evidence" ----------
-- The live production Attach view already does this exact fix:
--   sql/snowflake/2_attach/PP/views/PA_PER_VW_CBP_COMPETITOR_INFORMATION.sql, line 11:
--     case when PRIORCARRIER='Motor Trade Direct' then 'MotorTradeDirect' else PRIORCARRIER END
-- Manuscript (Package_Data line 50946-50964) agrees: value='MotorTradeDirect', caption='Motor
-- Trade Direct' (display-only). Both sources point the same direction — the conversion view is
-- just missing the one-line CASE Attach already has, most likely dropped during the SAS/view port,
-- not a deliberate change.

-- ---------- CODE FIX ----------
-- sql/snowflake/1_conversion/PP/views/PER_VW_CBP_COMPETITOR_INFORMATION.sql (line 12)
-- Current: TO_VARCHAR(T1.PRIORCARRIER) AS PRIORCARRIER   -- raw pass-through
-- Replace with the same CASE Attach uses:
--   CASE WHEN TO_VARCHAR(T1.PRIORCARRIER) = 'Motor Trade Direct' THEN 'MotorTradeDirect'
--        ELSE TO_VARCHAR(T1.PRIORCARRIER) END AS PRIORCARRIER

-- ---------- Off-list values — not currently an issue ----------
-- 0 off-list values in current data (every value besides the 1 spaced row already matches a DCT
-- code exactly). No validation-report rule needed today; if a genuinely new/legacy insurer name
-- appears on a future run, PR-01 applies (flow through, flag via validation report, don't drop).

-- ---------- Verify after applying ----------
-- SELECT PRIORCARRIER, COUNT(*),
--        CASE WHEN PRIORCARRIER IN ('Allianz','CGU','Elders','GIO','MotorTradeDirect','NRMA',
--                                   'Other','QBE','SGIC','SGIO','Unknown','VERO','Wesfarmers')
--             THEN 'VALID CODE' ELSE 'STILL INVALID' END AS DCT_CHECK
-- FROM AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION GROUP BY 1 ORDER BY 2 DESC;
-- -- target: 0 'STILL INVALID'
