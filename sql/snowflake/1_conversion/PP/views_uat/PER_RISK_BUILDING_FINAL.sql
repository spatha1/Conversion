-- ============================================================
-- View  : PER_RISK_BUILDING_FINAL
-- Module: PP (Personal Package) — Seq 14 (RISK_Building)
-- Source: AGGNE.UAT.Locationdetails_PER  (T2)
--         AGGNE.UAT.PER_ACCOUNT_LOC      (T3, for composite key + RISKNUMBER)
-- Target: AGGNE.UAT.PER_RISK_BUILDING_TARGET  (via ETL seq 14)
--
-- Purpose:
--   Translates raw legacy construction/security/occupancy codes from
--   Locationdetails_PER into the exact DCT dropdown codes expected by the
--   target system.  Also attaches the resolved HB and HC coverage payloads
--   (RISK_BUILDING, RISK_BC) from today's PER_BUILDING_TARGET / PER_HC_TARGET.
--
-- IMPORTANT: The CTE SELECT column order MUST match the view column declaration
--   order exactly. Snowflake assigns the declared names by position, not by alias.
--
-- Mappings validated against DCT manuscript Carrier_PersonalProtectionBase_1_0_0_0.xml (2026-06-27):
--   ROOFCONSTRUCTION    : DCT code 'Concrete' (caption "Concrete (Flat Roof)") — NOT 'ConcreteFlatRoof'
--                         'Iron','Tin','Iron/Steel/Tin' → 'IronSteelTin'
--                         'Tile' and 'Wood' are valid DCT options; 'Wood (Shingles)' source → 'Wood'
--   MAINWALLCONSTRUCTION: 'Fibro/Hardiplank','Fibro (Non-Asbestos)' → 'FibroHardiplank'
--                         'Iron','Iron/Steel' → 'IronSteel'
--   FLOORCONSTRUCTION   : DCT code 'WoodConcretefootings' — lowercase 'f' (not capital F)
--   HOWOCCUPPIED        : 'TenantedbyMember' (capital M); no hyphens in Owned/leased codes
--   DEADLOCKSINSTALLED  : DCT has no 'Other' option — source 'Other' falls to ELSE passthrough
--   GRILLKEYLOCKINSTALLED: DCT has no 'Other' option — source 'Other' falls to ELSE passthrough
--   ALARMSYSTEMINSTALLED: All 5 DCT codes confirmed correct
--
-- TODO (client mapping decision required — no DCT PP equivalent found in manuscript):
--   ROOFCONSTRUCTION   : 'Fibro (Non- Asbestos)', 'Some Asbestos and Brick'
--   MAINWALLCONSTRUCTION: 'Steel', 'Some Asbestos and Brick', 'Other'
--   ALARMSYSTEMINSTALLED: 'Local - Monitored', 'Mobile Mechanic - No base location'
--   DEADLOCKSINSTALLED  : 'Other'
--   GRILLKEYLOCKINSTALLED: 'Other'
-- ============================================================
create or replace view AGGNE.UAT.PER_RISK_BUILDING_FINAL(
    PUREPOLICYNUMBER,
    LEGACYPOLICYNUMBER,
    ADDRESSDESCRIPTION,
    RISKNUMBER,
    STOREYS,
    ROOFCONSTRUCTION_FINAL,         -- pos 6
    YEARBUILDINGCONSTRUCTED,        -- pos 7
    YEARLASTREWIRED,                -- pos 8
    YEARLASTREPLUMBED,              -- pos 9
    FLOORCONSTRUCTION_FINAL,        -- pos 10
    MAINWALLCONSTRUCTION_FINAL,     -- pos 11
    ALARMSYSTEMINSTALLED_FINAL,     -- pos 12
    DEADLOCKSINSTALLED_FINAL,       -- pos 13
    GRILLKEYLOCKINSTALLED_FINAL,    -- pos 14
    SECURITYDETAILS,                -- pos 15
    HOWOCCUPPIED,                   -- pos 16
    INTERESTEDPARTY,                -- pos 17
    RISK_BUILDING,
    RISK_BC,
    LOAD_DATE
) as
WITH CTE1 AS (
    SELECT
        -- pos 1: Composite key: LEGACYPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P
        CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.cmlnumber) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
        -- pos 2
        T2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        -- pos 3
        ADDRESSDESCRIPTION,
        -- pos 4
        CAST(T3.RISKNUMBER AS VARCHAR) AS RISKNUMBER,
        -- pos 5
        CAST(STOREYS AS VARCHAR) AS STOREYS,

        -- pos 6: ROOFCONSTRUCTION → DCT dropdown code
        -- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml, line 11582-11589):
        --   Asbestos | Colourbond | Concrete (display: "Concrete (Flat Roof)") | IronSteelTin | Tile | Wood (display: "Wood (Shingles)")
        -- Source 'Concrete' and 'Concrete (Flat Roof)' both map to DCT code 'Concrete'.
        -- Source 'Wood (Shingles)' maps to DCT code 'Wood'.
        -- ILIKE for 'Colorbond' handles US/AU spelling variants in source data.
        -- Fibro / Some Asbestos and Brick: NOT in DCT — passthrough; client to confirm.
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
            ELSE ROOFCONSTRUCTION  -- Fibro/SomeAsbestosAndBrick: no DCT PP option, client to confirm
        END AS ROOFCONSTRUCTION_FINAL,

        -- pos 7-9: Year fields (no code translation needed)
        CAST(YEARBUILDINGCONSTRUCTED AS VARCHAR) AS YEARBUILDINGCONSTRUCTED,
        CAST(YEARLASTREWIRED         AS VARCHAR) AS YEARLASTREWIRED,
        CAST(YEARLASTREPLUMBED       AS VARCHAR) AS YEARLASTREPLUMBED,

        -- pos 10: FLOORCONSTRUCTION → DCT dropdown code
        -- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml, line 11611-11617):
        --   Concrete | Other | WoodConcretefootings | WoodStilts | WoodStumps
        -- Note: DCT code is 'WoodConcretefootings' — lowercase 'f' (not 'WoodConcreteFootings').
        -- ILIKE used to guard against source case variation.
        CASE
            WHEN FLOORCONSTRUCTION = 'Concrete'                            THEN 'Concrete'
            WHEN FLOORCONSTRUCTION = 'Other'                               THEN 'Other'
            WHEN FLOORCONSTRUCTION ILIKE 'Wood - Concrete Footings'        THEN 'WoodConcretefootings'
            WHEN FLOORCONSTRUCTION ILIKE 'Wood - Stilts'                   THEN 'WoodStilts'
            WHEN FLOORCONSTRUCTION ILIKE 'Wood - Stumps'                   THEN 'WoodStumps'
            ELSE FLOORCONSTRUCTION  -- unknowns: no direct DCT PP equivalent
        END AS FLOORCONSTRUCTION_FINAL,

        -- pos 11: MAINWALLCONSTRUCTION → DCT dropdown code
        -- PP PL101 options: Asbestos | Brick Veneer | Concrete | Double Brick |
        --                   Fibro / Hardiplank | Iron / Steel | Wood
        -- 'Fibro (Non-Asbestos)' and 'Fibro/Hardiplank' both map to PP's 'Fibro / Hardiplank' option.
        -- 'Iron' and 'Iron/Steel' both map to PP's 'Iron / Steel' option.
        -- 'Steel' alone and 'Some Asbestos and Brick': not in PP PL101 — passthrough, client to confirm.
        CASE
            WHEN MAINWALLCONSTRUCTION = 'Asbestos'                THEN 'Asbestos'
            WHEN MAINWALLCONSTRUCTION = 'Brick Veneer'            THEN 'BrickVeneer'
            WHEN MAINWALLCONSTRUCTION = 'Concrete'                THEN 'Concrete'
            WHEN MAINWALLCONSTRUCTION = 'Double Brick'            THEN 'DoubleBrick'
            WHEN MAINWALLCONSTRUCTION = 'Fibro (Non-Asbestos)'    THEN 'FibroHardiplank'
            WHEN MAINWALLCONSTRUCTION = 'Fibro/Hardiplank'        THEN 'FibroHardiplank'
            WHEN MAINWALLCONSTRUCTION = 'Iron'                    THEN 'IronSteel'
            WHEN MAINWALLCONSTRUCTION = 'Iron/Steel'              THEN 'IronSteel'
            WHEN MAINWALLCONSTRUCTION = 'Wood'                    THEN 'Wood'
            ELSE MAINWALLCONSTRUCTION  -- Steel/SomeAsbestosAndBrick/Other: no PP equivalent, needs client mapping
        END AS MAINWALLCONSTRUCTION_FINAL,

        -- pos 12: ALARMSYSTEMINSTALLED → DCT dropdown code
        -- PP PL101 options: Local - Audible Only | Monitored - Back to base |
        --                   Monitored - Security | Monitored - To Mobile Phone | None
        -- 'Local - Monitored' and 'Mobile Mechanic - No base location' are NOT in PP PL101.
        --   They pass through as-is; client must confirm the correct PP DCT mapping.
        CASE
            WHEN ALARMSYSTEMINSTALLED = 'Local - Audible Only'               THEN 'LocalAudibleOnly'
            WHEN ALARMSYSTEMINSTALLED = 'Monitored - Back to base'           THEN 'MonitoredBacktobase'
            WHEN ALARMSYSTEMINSTALLED = 'Monitored - Security'               THEN 'MonitoredSecurity'
            WHEN ALARMSYSTEMINSTALLED = 'Monitored - To Mobile Phone'        THEN 'MonitoredToMobilePhone'
            WHEN ALARMSYSTEMINSTALLED = 'None'                               THEN 'None'
            ELSE ALARMSYSTEMINSTALLED  -- Local - Monitored / Mobile Mechanic: no PP PL101 equivalent
        END AS ALARMSYSTEMINSTALLED_FINAL,

        -- pos 13: DEADLOCKSINSTALLED → DCT dropdown code
        -- DCT options (line 11766-11770): AllDoors | SomeDoors | None
        -- 'Other' is NOT a valid DCT option — source 'Other' falls to ELSE; client to confirm target.
        CASE
            WHEN DEADLOCKSINSTALLED = 'All doors'  THEN 'AllDoors'
            WHEN DEADLOCKSINSTALLED = 'Some doors' THEN 'SomeDoors'
            WHEN DEADLOCKSINSTALLED = 'None'       THEN 'None'
            ELSE DEADLOCKSINSTALLED  -- 'Other' and unknowns: no DCT PP equivalent, client to confirm
        END AS DEADLOCKSINSTALLED_FINAL,

        -- pos 14: GRILLKEYLOCKINSTALLED → DCT dropdown code
        -- DCT options (line 11780-11784): AllWindows | SomeWindows | None
        -- 'Other' is NOT a valid DCT option — source 'Other' falls to ELSE; client to confirm target.
        CASE
            WHEN GRILLKEYLOCKINSTALLED = 'All windows'  THEN 'AllWindows'
            WHEN GRILLKEYLOCKINSTALLED = 'Some windows' THEN 'SomeWindows'
            WHEN GRILLKEYLOCKINSTALLED = 'None'         THEN 'None'
            ELSE GRILLKEYLOCKINSTALLED  -- 'Other' and unknowns: no DCT PP equivalent, client to confirm
        END AS GRILLKEYLOCKINSTALLED_FINAL,

        -- pos 15: free-text, no code translation
        SECURITYDETAILS,

        -- pos 16: HOWOCCUPPIED → DCT dropdown code
        -- DCT options (line 11363-11369): OwnerOccupied | HolidayHome | OwnedleasedtoOthersLongTermLease
        --   | OwnedLeasedtoOthersShortTermRental | TenantedbyMember
        -- Case and hyphen are significant — DCT rejects wrong case or hyphens in the code value.
        CASE
            WHEN HOWOCCUPPIED = 'Owner Occupied'                             THEN 'OwnerOccupied'
            WHEN HOWOCCUPPIED = 'Tenanted by member'                         THEN 'TenantedbyMember'
            WHEN HOWOCCUPPIED = 'Owned leased to Others - Long Term Lease'   THEN 'OwnedleasedtoOthersLongTermLease'
            WHEN HOWOCCUPPIED = 'Holiday Home'                               THEN 'HolidayHome'
            WHEN HOWOCCUPPIED = 'Owned leased to Others - Short Term Rental' THEN 'OwnedLeasedtoOthersShortTermRental'
            ELSE HOWOCCUPPIED
        END AS HOWOCCUPPIED,

        -- pos 17
        CAST(INTERESTEDPARTY AS VARCHAR) AS INTERESTEDPARTY

    FROM AGGNE.UAT.Locationdetails_PER T2
    -- INNER JOIN: only policies that have completed seq 3 (PER_ACCOUNT_LOC) are included.
    INNER JOIN AGGNE.UAT.PER_ACCOUNT_LOC T3
        ON CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.cmlnumber) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) = TRIM(T3.PUREPOLICYNUMBER)
)

-- Final SELECT: attach today's resolved HB and HC coverage payloads.
-- RISK_BUILDING: HB XML block from PER_BUILDING_TARGET (seq 7 output).
--                Falls back to Indicator=0 stub if seq 7 has not run today.
-- RISK_BC      : HC XML block from PER_HC_TARGET (seq 13 output).
--                Falls back to Indicator=0 stub if seq 13 has not run today.
-- LOAD_DATE filter ensures only today's target rows are joined (avoids stale data).
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
LEFT JOIN AGGNE.UAT.PER_HC_TARGET       T2
    ON T1.PUREPOLICYNUMBER = T2.ID
    AND T2.ITR_TYPE = 'RISK_Building_HC'
    AND CAST(T2.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
LEFT JOIN AGGNE.UAT.PER_BUILDING_TARGET T3
    ON T1.PUREPOLICYNUMBER = T3.ID
    AND T3.ITR_TYPE = 'RISK_Building_HB'
    AND CAST(T3.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
;
