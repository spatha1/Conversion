-- ============================================================
-- PP_DEPLOY_MOTOR_ONLY_FIX_20260702_SNOWFLAKE.sql
--
-- Target  : Snowflake — AGGNE.DEV (run in Snowflake worksheet)
-- Date    : 2026-07-02
-- Bug     : Motor-only PP policies migrating with Location section selected in DCT
-- Client ref policies: P00009965, P00010132, P00026339, P00026440,
--                      P00034501, P00034510, P00034535, P00034583
--
-- Root cause:
--   PER_RISK_BUILDING_FINAL (seq 14 source view) was querying ALL policies
--   from Locationdetails_PER, including motor-only policies that have no
--   Home Building (HB_01) or Home Contents (HC_02) coverage.
--   Seq 14 then inserted a Location risk node with Indicator=0 Building/Contents
--   blocks into the XML. DCT treats ANY Location node as "Location section selected"
--   regardless of Indicator value — causing motor-only policies to show Location
--   section as selected.
--
-- Fix:
--   Added WHERE clause to CTE1 in PER_RISK_BUILDING_FINAL to restrict output
--   to policies that exist in HB_01 OR HC_02.
--   Motor-only policies produce zero rows → seq 14 skips them → no Location
--   risk node in their XML → Location section not selected in DCT.
--
-- After deploying this view, Aggne must re-run seq 14 for affected policies.
-- ============================================================

USE DATABASE AGGNE;
USE SCHEMA DEV;

-- ── VIEW: PER_RISK_BUILDING_FINAL (with motor-only filter) ────────────────

create or replace view PER_RISK_BUILDING_FINAL(
    PUREPOLICYNUMBER,
    LEGACYPOLICYNUMBER,
    ADDRESSDESCRIPTION,
    RISKNUMBER,
    STOREYS,
    ROOFCONSTRUCTION_FINAL,
    YEARBUILDINGCONSTRUCTED,
    YEARLASTREWIRED,
    YEARLASTREPLUMBED,
    FLOORCONSTRUCTION_FINAL,
    MAINWALLCONSTRUCTION_FINAL,
    ALARMSYSTEMINSTALLED_FINAL,
    DEADLOCKSINSTALLED_FINAL,
    GRILLKEYLOCKINSTALLED_FINAL,
    SECURITYDETAILS,
    HOWOCCUPPIED,
    INTERESTEDPARTY,
    RISK_BUILDING,
    RISK_BC,
    LOAD_DATE
) as
WITH CTE1 AS (
    SELECT
        CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.cmlnumber) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
        T2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        ADDRESSDESCRIPTION,
        CAST(T3.RISKNUMBER AS VARCHAR) AS RISKNUMBER,
        CAST(STOREYS AS VARCHAR) AS STOREYS,
        CASE
            WHEN ROOFCONSTRUCTION = 'Asbestos'                THEN 'Asbestos'
            WHEN ROOFCONSTRUCTION = 'Concrete'                THEN 'Concrete'
            WHEN ROOFCONSTRUCTION = 'Concrete (Flat Roof)'    THEN 'Concrete'
            WHEN ROOFCONSTRUCTION = 'Iron'                    THEN 'IronSteelTin'
            WHEN ROOFCONSTRUCTION = 'Iron/Steel/Tin'          THEN 'IronSteelTin'
            WHEN ROOFCONSTRUCTION = 'Tin'                     THEN 'IronSteelTin'
            WHEN ROOFCONSTRUCTION ILIKE 'Colorbond'           THEN 'Colourbond'
            WHEN ROOFCONSTRUCTION = 'Tile'                    THEN 'Tile'
            WHEN ROOFCONSTRUCTION = 'Wood'                    THEN 'Wood'
            WHEN ROOFCONSTRUCTION = 'Wood (Shingles)'         THEN 'Wood'
            ELSE ROOFCONSTRUCTION
        END AS ROOFCONSTRUCTION_FINAL,
        CAST(YEARBUILDINGCONSTRUCTED AS VARCHAR) AS YEARBUILDINGCONSTRUCTED,
        CAST(YEARLASTREWIRED         AS VARCHAR) AS YEARLASTREWIRED,
        CAST(YEARLASTREPLUMBED       AS VARCHAR) AS YEARLASTREPLUMBED,
        CASE
            WHEN FLOORCONSTRUCTION = 'Concrete'                            THEN 'Concrete'
            WHEN FLOORCONSTRUCTION = 'Other'                               THEN 'Other'
            WHEN FLOORCONSTRUCTION ILIKE 'Wood - Concrete Footings'        THEN 'WoodConcretefootings'
            WHEN FLOORCONSTRUCTION ILIKE 'Wood - Stilts'                   THEN 'WoodStilts'
            WHEN FLOORCONSTRUCTION ILIKE 'Wood - Stumps'                   THEN 'WoodStumps'
            ELSE FLOORCONSTRUCTION
        END AS FLOORCONSTRUCTION_FINAL,
        CASE
            WHEN MAINWALLCONSTRUCTION = 'Asbestos'                THEN 'Asbestos'
            WHEN MAINWALLCONSTRUCTION = 'Brick Veneer'            THEN 'BrickVeneer'
            WHEN MAINWALLCONSTRUCTION = 'Concrete'                THEN 'Concrete'
            WHEN MAINWALLCONSTRUCTION = 'Double Brick'            THEN 'DoubleBrick'
            WHEN MAINWALLCONSTRUCTION = 'Fibro (Non-Asbestos)'    THEN 'FibroHardiplank'
            WHEN MAINWALLCONSTRUCTION = 'Fibro/Hardiplank'        THEN 'FibroHardiplank'
            WHEN MAINWALLCONSTRUCTION = 'Iron'                    THEN 'IronSteel'
            WHEN MAINWALLCONSTRUCTION = 'Iron/Steel'              THEN 'IronSteel'
            WHEN MAINWALLCONSTRUCTION = 'Steel'                   THEN 'IronSteel'
            WHEN MAINWALLCONSTRUCTION = 'Wood'                    THEN 'Wood'
            ELSE MAINWALLCONSTRUCTION
        END AS MAINWALLCONSTRUCTION_FINAL,
        CASE
            WHEN ALARMSYSTEMINSTALLED = 'Local - Audible Only'               THEN 'LocalAudibleOnly'
            WHEN ALARMSYSTEMINSTALLED = 'Monitored - Back to base'           THEN 'MonitoredBacktobase'
            WHEN ALARMSYSTEMINSTALLED = 'Monitored - Security'               THEN 'MonitoredSecurity'
            WHEN ALARMSYSTEMINSTALLED = 'Monitored - To Mobile Phone'        THEN 'MonitoredToMobilePhone'
            WHEN ALARMSYSTEMINSTALLED = 'None'                               THEN 'None'
            ELSE ALARMSYSTEMINSTALLED
        END AS ALARMSYSTEMINSTALLED_FINAL,
        CASE
            WHEN DEADLOCKSINSTALLED = 'All doors'  THEN 'AllDoors'
            WHEN DEADLOCKSINSTALLED = 'Some doors' THEN 'SomeDoors'
            WHEN DEADLOCKSINSTALLED = 'None'       THEN 'None'
            ELSE DEADLOCKSINSTALLED
        END AS DEADLOCKSINSTALLED_FINAL,
        CASE
            WHEN GRILLKEYLOCKINSTALLED = 'All windows'  THEN 'AllWindows'
            WHEN GRILLKEYLOCKINSTALLED = 'Some windows' THEN 'SomeWindows'
            WHEN GRILLKEYLOCKINSTALLED = 'None'         THEN 'None'
            ELSE GRILLKEYLOCKINSTALLED
        END AS GRILLKEYLOCKINSTALLED_FINAL,
        SECURITYDETAILS,
        CASE
            WHEN HOWOCCUPPIED = 'Owner Occupied'                             THEN 'OwnerOccupied'
            WHEN HOWOCCUPPIED ILIKE 'Tenanted by member'                     THEN 'TenantedbyMember'
            WHEN HOWOCCUPPIED = 'Owned leased to Others - Long Term Lease'   THEN 'OwnedleasedtoOthersLongTermLease'
            WHEN HOWOCCUPPIED = 'Holiday Home'                               THEN 'HolidayHome'
            WHEN HOWOCCUPPIED = 'Owned leased to Others - Short Term Rental' THEN 'OwnedLeasedtoOthersShortTermRental'
            ELSE HOWOCCUPPIED
        END AS HOWOCCUPPIED,
        CAST(INTERESTEDPARTY AS VARCHAR) AS INTERESTEDPARTY

    FROM AGGNE.DEV.Locationdetails_PER T2
    INNER JOIN AGGNE.DEV.PER_ACCOUNT_LOC T3
        ON CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.cmlnumber) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) = TRIM(T3.PUREPOLICYNUMBER)
    -- FIX 2026-07-02: exclude motor-only policies from this view.
    -- PER_RISK_BUILDING_FINAL feeds seq 14 (Location risk node). Including a motor-only
    -- policy here causes DCT to show the Location section as selected even with
    -- all coverage Indicators = 0. Only policies with HB_01 or HC_02 data should
    -- produce a Location risk node.
    WHERE (
        EXISTS (
            SELECT 1 FROM AGGNE.DEV.HB_01 H
            WHERE TRIM(H.PUREPOLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
              AND H.EXPIRINGID_P           = T2.EXPIRINGID_P
        )
        OR EXISTS (
            SELECT 1 FROM AGGNE.DEV.HC_02 HC
            WHERE TRIM(HC.PUREPOLICYNUMBER) = TRIM(T2.PUREPOLICYNUMBER)
              AND HC.EXPIRINGID_P           = T2.EXPIRINGID_P
        )
    )
)

SELECT DISTINCT T1.*,
    CASE
        WHEN T3.PAYLOAD IS NULL THEN
            '<coverage>
    <Type>Building</Type>
    <Description>Home Buildings</Description>
    <Indicator>0</Indicator>
    </coverage>'
        ELSE T3.PAYLOAD
    END AS RISK_BUILDING,
    CASE
        WHEN T2.PAYLOAD IS NULL THEN
            '<coverage>
    <Type>ContentsAndStocks</Type>
    <Description>Home Contents</Description>
    <Indicator>0</Indicator>
    </coverage>'
        ELSE T2.PAYLOAD
    END AS RISK_BC,
    CAST(GETDATE() AS DATE) AS LOAD_DATE
FROM CTE1 T1
LEFT JOIN AGGNE.DEV.PER_HC_TARGET       T2
    ON T1.PUREPOLICYNUMBER = T2.ID
    AND T2.ITR_TYPE = 'RISK_Building_HC'
    AND CAST(T2.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
LEFT JOIN AGGNE.DEV.PER_BUILDING_TARGET T3
    ON T1.PUREPOLICYNUMBER = T3.ID
    AND T3.ITR_TYPE = 'RISK_Building_HB'
    AND CAST(T3.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
;


-- ── POST-DEPLOY VALIDATION ────────────────────────────────────────────────
-- Run these after deploying the view to confirm the fix.

-- 1. Row count before/after: motor-only policies should be gone
--    Expected: only HB/HC policies remain
SELECT COUNT(DISTINCT LEGACYPOLICYNUMBER) AS TOTAL_HOME_POLICIES
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL;

-- 2. Confirm none of the 8 client reference policies appear (they are motor-only)
--    Expected: 0 rows
SELECT LEGACYPOLICYNUMBER
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL
WHERE LEGACYPOLICYNUMBER IN (
    'P00009965','P00010132','P00026339','P00026440',
    'P00034501','P00034510','P00034535','P00034583'
);

-- 3. Spot-check: all remaining policies have HB or HC in source
--    Expected: 0 rows (no motor-only policy should remain)
SELECT DISTINCT F.LEGACYPOLICYNUMBER
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL F
WHERE NOT EXISTS (
    SELECT 1 FROM AGGNE.DEV.HB_01 H
    WHERE TRIM(H.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
)
AND NOT EXISTS (
    SELECT 1 FROM AGGNE.DEV.HC_02 HC
    WHERE TRIM(HC.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
)
LIMIT 20;
