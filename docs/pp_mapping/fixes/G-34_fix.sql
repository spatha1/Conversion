-- ============================================================
-- G-34 — StandardExcess / ImposedExcess empty at risk level (seq 14, P2)
-- LIKELY FALSE POSITIVE — same root cause as G-23 (mirrors it at risk level). NOT A CODE FIX.
-- ============================================================

-- ---------- Same investigation as G-23 applies here ----------
-- No source column for Standard/Imposed excess exists anywhere in HB_02, PER_HomeContents, or
-- Locationdetails_PER, and the client's original SAS never computed these concepts either (see
-- fixes/G-23_fix.sql for the full investigation). This risk-level pair of empty tags is almost
-- certainly the same class of inherited/inapplicable template boilerplate, not dropped real data.

-- ---------- ASK — do not silently close this as resolved ----------
-- Confirm with Aggne policy team / client alongside G-23 — if StandardExcess/ImposedExcess are
-- confirmed inapplicable to PP (no PDS concept of a separately-tracked standard/imposed excess for
-- the property risk), both G-23 and G-34 close together as "by design, no source data exists,"
-- not as things to fix.

-- ---------- Verify (informational) ----------
-- SELECT * FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL LIMIT 0;  -- confirm no excess columns present
