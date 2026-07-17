-- ============================================================
-- Seq 13 (RISK_Building_HC) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gaps: G-28 {clauses} unresolved (P1), G-29 Indicator=1 (P1),
--       G-31 HomeContentsLimits=1 (P1), G-30 FloodDamage=Taken (P2)
-- ============================================================

-- G-28: literal '{clauses}' leaking into generated payloads
SELECT COUNT(*) AS PAYLOADS_WITH_UNRESOLVED_CLAUSES_TOKEN
FROM AGGNE.DEV.PER_HC_TARGET
WHERE ITR_TYPE = 'RISK_Building_HC' AND PAYLOAD LIKE '%{clauses}%';

-- G-28: policies with HC clauses loaded (seq 12) that never made it into the HC block
SELECT COUNT(DISTINCT C.ID) AS POLICIES_WITH_LOST_HC_CLAUSES
FROM AGGNE.DEV.PER_HC_TARGET C
WHERE C.ITR_TYPE = 'LOC_HC_CLAUSE';

-- G-29: HB-only policies that would receive an HC block with Indicator=1
SELECT COUNT(*) AS HB_ONLY_POLICIES_GETTING_HC_BLOCK
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
WHERE HC_INDICATOR = '0';

-- G-31: what ANYITEMSEXCEEDVALUE actually is (the value HomeContentsLimits should carry)
SELECT ANYITEMSEXCEEDVALUE, COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
GROUP BY ANYITEMSEXCEEDVALUE;

-- G-30: FloodDamage reality vs the hardcoded 'Taken'
SELECT FLOODDAMAGE, COUNT(*) FROM AGGNE.DEV.HC_02 GROUP BY FLOODDAMAGE ORDER BY 2 DESC;

-- UnspecifiedItemsAwayLimit mapping coverage (ELSE '' catches off-list source values)
SELECT UNSPECIFIEDITEMSAWAYLIMIT, COUNT(*) FROM AGGNE.DEV.HC_02
GROUP BY UNSPECIFIEDITEMSAWAYLIMIT ORDER BY 2 DESC;

-- G-25: ClassCode HH/HBC hardcoded — every HC block carries it (scope check)
SELECT COUNT(*) AS HC_BLOCKS_WITH_HARDCODED_CLASSCODE
FROM AGGNE.DEV.PER_HC_TARGET
WHERE ITR_TYPE = 'RISK_Building_HC';

-- G-32: HomeContentsTotal / SpecifiedContentsTotal test-residue values — scope check
SELECT COUNT(*) AS HC_BLOCKS_WITH_HARDCODED_TOTALS
FROM AGGNE.DEV.PER_HC_TARGET
WHERE ITR_TYPE = 'RISK_Building_HC';
