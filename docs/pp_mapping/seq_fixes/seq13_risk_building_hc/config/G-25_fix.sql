-- ============================================================
-- G-25 — ClassCode HH/HBC hardcoded, wrong value (seq 7/13, P1)
-- CONFIRMED via manuscript's own lookup table — pure code fix, no decision needed. NOT YET APPLIED.
-- ============================================================

-- ---------- CONFIRMED — sourced directly from the manuscript, not guessed ----------
-- Carrier_CoverageLibrary_Data_1_0_0_0.xml, table id="BusinessAndAPRAClassCode" (line 58785-58824):
-- a lookup table keyed by CoverageType, positional rows (APRAClassCode, BusinessClassCode):
--   Building            -> FISR, BSP     (row 1)
--   ContentsAndStocks   -> FISR, BSP     (row 2)
--   PersonalMotor       -> DMV, DMV      (row 15)
-- Cross-validated: PersonalMotor's row (DMV,DMV) EXACTLY matches seq 18's already-correct Motor
-- ClassCode (<ClassCode><APRA>DMV</APRA><Business>DMV</Business></ClassCode>, marked OK in the
-- seq18 review) — confirms this table is the authoritative source, not a guess.
--
-- Current hardcode in both seq 7 (Building) and seq 13 (ContentsAndStocks) templates:
--   <ClassCode><APRA>HH</APRA><Business>HBC</Business></ClassCode>
-- Correct value (both blocks, per the manuscript table):
--   <ClassCode><APRA>FISR</APRA><Business>BSP</Business></ClassCode>

-- ---------- CODE FIX ----------
-- seq 7 template (RISK_Building_HB) and seq 13 template (RISK_Building_HC), PP_ConversionConfig:
--   Replace <ClassCode><APRA>HH</APRA><Business>HBC</Business></ClassCode>
--   with    <ClassCode><APRA>FISR</APRA><Business>BSP</Business></ClassCode>
-- (identical replacement in both templates — no view change needed, both are hardcoded literals.)

-- ---------- Scope ----------
-- 1,843 HB coverage blocks (PER_BUILDING_TARGET, ITR_TYPE='RISK_Building_HB') and 1,843 HC
-- coverage blocks (PER_HC_TARGET, ITR_TYPE='RISK_Building_HC') currently carry the wrong code —
-- 100% of both.

-- ---------- Verify after applying ----------
-- Re-run conversion, then check the generated payload text directly (this is a template literal,
-- not a queryable column):
--   SELECT COUNT(*) FROM AGGNE.DEV.PER_BUILDING_TARGET
--   WHERE ITR_TYPE='RISK_Building_HB' AND PAYLOAD LIKE '%<APRA>HH</APRA>%';
--   SELECT COUNT(*) FROM AGGNE.DEV.PER_HC_TARGET
--   WHERE ITR_TYPE='RISK_Building_HC' AND PAYLOAD LIKE '%<APRA>HH</APRA>%';
-- -- target: 0 for both (all replaced with FISR/BSP)
