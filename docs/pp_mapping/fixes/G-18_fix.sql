-- ============================================================
-- G-18 fix — HB/HC coverage Indicator: hardcoded 1, should be per-block computed (seq 4/10, P2)
-- Confirmed live impact higher than original P2 label suggested (up to 75.7% wrong on Flood).
-- NOT YET APPLIED.
-- ============================================================

-- ---------- CONTEXT — re-verified against the actual product manuscript, not just the shared library ----------
-- Carrier_PersonalProtectionBase_1_0_0_0.xml — every block's Indicator has its own computed rule:
--   BLD_SD (line 6333-6345): Indicator = (BusinessBuildingsLimit > 0), default False
--   BFL_SD (line 5880-5892): Indicator = (FloodDamage = 'Taken'), default 0
--   LLB_SD (line 5894-5909, 5449-5456): Indicator = (LandlordProtections = 'Taken')
--   BLD_ST and presumably BLD_BF/CY/EQ (pattern continues past line 6347): same limit>0 pattern
-- None of these are meant to be a flat hardcoded 1.

-- ---------- CODE FIX 1 — Flood (BFL_SD) — no decision needed ----------
-- sql/snowflake/1_conversion/PP/views/PER_BB_SUBCOVERAGES.sql (or wherever the seq4 template's
-- {SVALUE}/Indicator are assembled — confirm exact file)
-- The FLOODDAMAGE sValue ('Taken'/'NotTaken') already exists on this row. Replace hardcoded
-- <Indicator>1</Indicator> for the BFL_SD block with:
--   CASE WHEN FLOODDAMAGE = 'Taken' THEN 1 ELSE 0 END AS INDICATOR   -- BFL_SD block only

-- ---------- CODE FIX 2 — Accidental Loss/Damage (BAD_SD) — no decision needed ----------
-- Same pattern, using the existing ACCIDENTALLOSSORDAMAGE sValue:
--   CASE WHEN ACCIDENTALLOSSORDAMAGE = 'Taken' THEN 1 ELSE 0 END AS INDICATOR   -- BAD_SD block only

-- ---------- CODE FIX 3 — Structural blocks (BLD_SD, BLD_BF, BLD_CY, BLD_EQ, BLD_ST) ----------
-- No live defect today (0 zero-limit rows in current data), but hardening to match the manuscript
-- rule prevents a future zero-limit policy from silently getting a wrong Indicator=1:
--   CASE WHEN COALESCE(TRY_TO_NUMBER(HOMEBUILDINGSLIMIT), 0) > 0 THEN 1 ELSE 0 END AS INDICATOR

-- ---------- DECISION NEEDED — Landlords (LLB_SD) ----------
-- Cannot be code-fixed from currently-exposed columns: the view has no Taken/NotTaken sValue for
-- Landlords Protections at all today (manuscript's condition is
-- BuildingRiskSMEInput.LandlordProtections = 'Taken', sourced from coverage[Type="LLB_SD"]/sValue
-- — i.e. Pure needs its own "was Landlord Protections elected" signal, not just occupancy type).
-- 2,097 of 3,054 policies (68.7%) currently show Landlords Indicator=1 on Owner Occupied
-- properties — a strong signal something's wrong, but occupancy alone is NOT the manuscript's
-- actual condition and should not be used as a stand-in without confirmation.
-- ASK AGGNE POLICY TEAM: does Pure carry an explicit Landlord-Protections-elected flag we can
-- source? If not, is HowOccupied (Owner Occupied -> NotTaken, else -> Taken) an acceptable proxy,
-- or does that break for other occupancy types (e.g. vacant, rented-by-owner-in-part)?

-- ---------- Verify after applying ----------
-- SELECT CODE, SVALUE, COUNT(*),
--   SUM(CASE WHEN CODE IN ('HBBFL_SD') AND SVALUE LIKE '%NotTaken%' THEN 1 ELSE 0 END) AS SHOULD_BE_ZERO
-- FROM AGGNE.DEV.PER_BB_SUBCOVERAGES GROUP BY CODE, SVALUE ORDER BY CODE;
-- -- target: Indicator in the actual payload output matches SVALUE-derived expectation for
-- -- BFL_SD/BAD_SD; Landlords stays flagged pending the policy-team decision above
