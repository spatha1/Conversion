-- ============================================================
-- Seq 7 (RISK_Building_HB) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-22 Indicator=1 hardcoded (P1), G-23 excess fields dropped (P2),
--       G-24 GlassLimit mapping (P2), G-26 premium double-carry (P2)
-- ============================================================

-- G-22: HC-only policies that would receive an HB block with Indicator=1
SELECT COUNT(*) AS HC_ONLY_POLICIES_GETTING_HB_BLOCK
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
WHERE HB_INDICATOR = '0';

-- Indicator column distribution (what the template SHOULD be emitting)
SELECT HB_INDICATOR, HC_INDICATOR, COUNT(*) AS CNT
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
GROUP BY HB_INDICATOR, HC_INDICATOR;

-- G-23: excess data present in HB_02 but dropped (not exposed/tokenized)
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN STANDARDEXCESS   IS NOT NULL THEN 1 ELSE 0 END) AS HAS_STANDARD,
  SUM(CASE WHEN IMPOSEDEXCESS    IS NOT NULL THEN 1 ELSE 0 END) AS HAS_IMPOSED,
  SUM(CASE WHEN EARTHQUAKEEXCESS IS NOT NULL THEN 1 ELSE 0 END) AS HAS_EARTHQUAKE,
  SUM(CASE WHEN FLOODEXCESS      IS NOT NULL THEN 1 ELSE 0 END) AS HAS_FLOOD
FROM AGGNE.DEV.HB_02;

-- VoluntaryExcess distinct values (confirm vs HB option list)
SELECT VOLUNTARYEXCESS, COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
GROUP BY VOLUNTARYEXCESS ORDER BY 2 DESC;

-- G-26: same HMEXPPREM on both blocks — sample
SELECT PUREPOLICYNUMBER, EXPPREM AS HB_PREMIUM, HBEXPPREM AS HC_PREMIUM
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
WHERE HB_INDICATOR='1' AND HC_INDICATOR='1' LIMIT 20;

-- G-25: ClassCode HH/HBC hardcoded — every HB block carries it (scope check)
SELECT COUNT(*) AS HB_BLOCKS_WITH_HARDCODED_CLASSCODE
FROM AGGNE.DEV.PER_BUILDING_TARGET
WHERE ITR_TYPE = 'RISK_Building_HB';
