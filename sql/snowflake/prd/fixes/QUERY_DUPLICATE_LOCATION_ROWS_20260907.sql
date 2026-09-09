-- ============================================================================
-- QUERY: Identify policies with duplicate location rows in LOCATION_01_POLICYATTACH
-- Date: 2026-09-07
-- Read-only. Safe to run anytime.
--
-- CONTEXT:
--   Found via P00029683 (request ID
--   'P00029683|CML00027813|2538198,2538201,2538201,2538867,2538200|485923,...')
--   -- 5 <risk type="Building"> blocks with LocationNumber 1-5, but only 4
--   <location> blocks (1-4). Root cause: AGGNE.PRD.LOCATION_01_POLICYATTACH
--   has a genuine duplicate row for one location (same PUREPOLICYNUMBER +
--   EXPIRINGID + ADDRESS1, appearing more than once). The location-list
--   builder correctly collapses this to one row; the risk-building view
--   (PA_RISK_BUILDING_FINAL) does NOT, because its RISKNUMBER is a
--   ROW_NUMBER() computed inside a SELECT DISTINCT -- ROW_NUMBER() assigns
--   each duplicate row its own unique value, so DISTINCT can never collapse
--   them (each row looks "different" because of its own row-number column).
--   The duplicate location ends up counted as an extra, orphaned risk with
--   no matching location definition.
-- ============================================================================


-- 1) SUMMARY -- overall scale of the issue
WITH dupes AS (
    SELECT PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1, COUNT(*) AS DUPE_COUNT
    FROM AGGNE.PRD.LOCATION_01_POLICYATTACH
    GROUP BY PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(DISTINCT PUREPOLICYNUMBER) AS IMPACTED_POLICIES,
    COUNT(*) AS DUPLICATE_LOCATION_GROUPINGS,
    SUM(DUPE_COUNT - 1) AS EXTRA_PHANTOM_ROWS
FROM dupes;
-- Result (2026-09-07): 3,206 impacted policies / 8,149 groupings / 17,155 extra rows


-- 2) FULL LIST -- every policy + location + how many times it's duplicated
WITH dupes AS (
    SELECT PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1, COUNT(*) AS DUPE_COUNT
    FROM AGGNE.PRD.LOCATION_01_POLICYATTACH
    GROUP BY PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
    HAVING COUNT(*) > 1
)
SELECT PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1, DUPE_COUNT
FROM dupes
ORDER BY DUPE_COUNT DESC, PUREPOLICYNUMBER;


-- 3) DISTINCT POLICY LIST ONLY -- for queueing/reprocessing purposes
WITH dupes AS (
    SELECT PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1, COUNT(*) AS DUPE_COUNT
    FROM AGGNE.PRD.LOCATION_01_POLICYATTACH
    GROUP BY PUREPOLICYNUMBER, EXPIRINGID, ADDRESS1
    HAVING COUNT(*) > 1
)
SELECT DISTINCT PUREPOLICYNUMBER
FROM dupes
ORDER BY PUREPOLICYNUMBER;
