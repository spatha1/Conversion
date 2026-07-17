-- ============================================================
-- G-21 — Free text not XML-escaped (seqs 6/8/9/12/14/17, P2)
-- Pure code fix, no decision needed. NOT YET APPLIED.
-- ============================================================

-- ---------- Confirmed live counts ----------
-- HB_CLAUSE (seq 6) description:                     0 unsafe rows
-- PER_HC_SPECIFIEDCONTENTS (seq 9) description:      15 unsafe rows
-- PER_HC_ITEMS_EXCEED_VALUE (seq 8) description:      186 unsafe rows
-- Locationdetails_PER.SECURITYDETAILS (seq 14):       39 unsafe rows
-- COM_CLAUSE (seq 17) description:                    4 unsafe rows
-- Total: 244 rows across 5 views currently carry an unescaped &, <, or > that will produce
-- malformed XML wherever they land (breaks the payload, not just that one field).

-- ---------- CODE FIX — one escaping function, applied everywhere free text reaches a template ----------
-- Snowflake pattern (apply to every {DESCRIPTION}/{DCINPUT}/{SECURITYDETAILS}-style column that
-- isn't already escaped — SUBCOV in PER_COM_PAYLOAD.sql already does the & replace, use as the
-- reference pattern):
--   REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col, '&', '&amp;'), '<', '&lt;'), '>', '&gt;'),
--           '"', '&quot;'), '''', '&apos;')
-- Apply at minimum to: HB_CLAUSE.DCINPUT, PER_HC_SPECIFIEDCONTENTS.DESCRIPTION,
-- PER_HC_ITEMS_EXCEED_VALUE.DESCRIPTION, Locationdetails_PER.SECURITYDETAILS (seq 14 view),
-- COM_CLAUSE.DCINPUT.

-- ---------- Verify after applying ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.HB_CLAUSE WHERE DCINPUT LIKE '%&%' AND DCINPUT NOT LIKE '%&amp;%';
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS WHERE DESCRIPTION LIKE '%&%' AND DESCRIPTION NOT LIKE '%&amp;%';
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE WHERE DESCRIPTION LIKE '%&%' AND DESCRIPTION NOT LIKE '%&amp;%';
-- -- target: 0 raw (unescaped) & / < / > remaining in any of these columns
