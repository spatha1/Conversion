-- ============================================================
-- G-33 — SICCode hardcoded "General Mechanical Workshop" (seq 14, P1)
-- Confirmed wrong via manuscript; final value needs policy team confirmation. NOT YET APPLIED.
-- ============================================================

-- ---------- Confirmed via manuscript ----------
-- Carrier_CoverageLibrary_Data_1_0_0_0.xml line 49513-49519: PropertyOutput.SICCode is free text,
-- with <default idref="AccountPrivate.UWGroupForSICCode" /> — i.e. DCT's own design is to DEFAULT
-- this field from the account's underwriting group, not to receive a fixed literal from the
-- conversion payload. "General Mechanical Workshop" is a commercial/business occupancy
-- classification — it has no logical connection to a personal home policy, and hardcoding it
-- overrides DCT's own intended default mechanism.

-- ---------- Data ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET;
-- Result: 1,399 — every single PP home risk node carries this wrong commercial classification.

-- ---------- RECOMMENDED FIX (pending policy team confirmation) ----------
-- seq 14 template (PP_ConversionConfig, RISK_Building): remove the hardcoded value entirely —
--   <SICCode></SICCode>   (or omit the tag)
-- so DCT's own AccountPrivate.UWGroupForSICCode default takes over, rather than sending our own
-- best-guess text. This is the recommended default per the manuscript's own design.

-- ---------- CONFIRM WITH AGGNE POLICY TEAM ----------
-- Is blanking the tag (letting DCT default it) the right approach, or does PP conversion need to
-- send a specific SIC code value of its own? If the latter, what value — do not guess a
-- replacement classification string.

-- ---------- Verify after applying ----------
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
-- WHERE PAYLOAD LIKE '%General Mechanical Workshop%';
-- -- target: 0
