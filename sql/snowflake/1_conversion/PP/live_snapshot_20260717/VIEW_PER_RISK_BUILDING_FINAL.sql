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
        -- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml, line 11548-11560):
        --   Asbestos | BrickVeneer | Concrete | DoubleBrick | FibroHardiplank | IronSteel | Wood
        -- 'Fibro (Non-Asbestos)' and 'Fibro/Hardiplank' both map to DCT 'FibroHardiplank'.
        -- 'Iron' and 'Iron/Steel' both map to DCT 'IronSteel'.
        -- 'Steel' alone: source legacy code for steel-framed walls — closest DCT match is 'IronSteel' (fixed 2026-07-01).
        -- 'Some Asbestos and Brick', 'Other': no DCT PP equivalent — passthrough, client to confirm.
        CASE
            WHEN MAINWALLCONSTRUCTION = 'Asbestos'                THEN 'Asbestos'
            WHEN MAINWALLCONSTRUCTION = 'Brick Veneer'            THEN 'BrickVeneer'
            WHEN MAINWALLCONSTRUCTION = 'Concrete'                THEN 'Concrete'
            WHEN MAINWALLCONSTRUCTION = 'Double Brick'            THEN 'DoubleBrick'
            WHEN MAINWALLCONSTRUCTION = 'Fibro (Non-Asbestos)'    THEN 'FibroHardiplank'
            WHEN MAINWALLCONSTRUCTION = 'Fibro/Hardiplank'        THEN 'FibroHardiplank'
            WHEN MAINWALLCONSTRUCTION = 'Iron'                    THEN 'IronSteel'
            WHEN MAINWALLCONSTRUCTION = 'Iron/Steel'              THEN 'IronSteel'
            WHEN MAINWALLCONSTRUCTION = 'Steel'                   THEN 'IronSteel'  -- steel-framed = IronSteel in DCT
            WHEN MAINWALLCONSTRUCTION = 'Wood'                    THEN 'Wood'
            ELSE MAINWALLCONSTRUCTION  -- SomeAsbestosAndBrick/Other: no PP DCT equivalent, client to confirm
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
        -- SECURITYDETAILS,
        -- pos 15: free-text — escape XML-breaking characters
  REPLACE(REPLACE(REPLACE(CAST(SECURITYDETAILS AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS     SECURITYDETAILS,

        -- pos 16: HOWOCCUPPIED → DCT dropdown code
        -- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml, line 11363-11369):
        --   OwnerOccupied | HolidayHome | OwnedleasedtoOthersLongTermLease
        --   | OwnedLeasedtoOthersShortTermRental | TenantedbyMember
        -- Case and hyphen are significant — DCT rejects wrong case or hyphens in the code value.
        -- ILIKE on 'Tenanted by member': source data has inconsistent capitalisation ('member' vs 'Member')
        --   — exact-match would silently fall to ELSE passthrough for the uppercase-M variant (fixed 2026-07-01).
        CASE
            WHEN HOWOCCUPPIED = 'Owner Occupied'                             THEN 'OwnerOccupied'
            WHEN HOWOCCUPPIED ILIKE 'Tenanted by member'                     THEN 'TenantedbyMember'  -- ILIKE: source has 'member'/'Member' variants
            WHEN HOWOCCUPPIED = 'Owned leased to Others - Long Term Lease'   THEN 'OwnedleasedtoOthersLongTermLease'
            WHEN HOWOCCUPPIED = 'Holiday Home'                               THEN 'HolidayHome'
            WHEN HOWOCCUPPIED = 'Owned leased to Others - Short Term Rental' THEN 'OwnedLeasedtoOthersShortTermRental'
            ELSE HOWOCCUPPIED
        END AS HOWOCCUPPIED,

        -- pos 17
        -- FIX: escape XML-breaking characters (was: CAST(INTERESTEDPARTY AS VARCHAR))
REPLACE(REPLACE(REPLACE(CAST(INTERESTEDPARTY AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS INTERESTEDPARTY

    FROM AGGNE.DEV.Locationdetails_PER T2
    -- INNER JOIN: only policies that have completed seq 3 (PER_ACCOUNT_LOC) are included.
    INNER JOIN AGGNE.DEV.PER_ACCOUNT_LOC T3
        ON CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.cmlnumber) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) = TRIM(T3.PUREPOLICYNUMBER)
    -- Motor-only filter: only include policies that have HB (Home Building) OR HC (Home Contents)
    -- coverage in source. Motor-only policies appear in Locationdetails_PER (they have an address)
    -- but must NOT get a Location risk node in the XML — DCT treats any Location node as
    -- "Location section selected" even if all coverage Indicators are 0.
    WHERE (
        -- Direct coverage flags from source: most reliable filter for motor-only exclusion.
        -- HB_01/HC_02 EXISTS checks retained as belt-and-suspenders but HOMEBUILDINGS/HOMECONTENTS
        -- are the authoritative flags (some motor-only policies have stale HB_01 rows).
        TRIM(COALESCE(T2.HOMEBUILDINGS, '')) = 'Yes'
        OR TRIM(COALESCE(T2.HOMECONTENTS, '')) = 'Yes'
    )
    AND (
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
LEFT JOIN AGGNE.DEV.PER_HC_TARGET       T2
    ON T1.PUREPOLICYNUMBER = T2.ID
    AND T2.ITR_TYPE = 'RISK_Building_HC'
    AND CAST(T2.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
LEFT JOIN AGGNE.DEV.PER_BUILDING_TARGET T3
    ON T1.PUREPOLICYNUMBER = T3.ID
    AND T3.ITR_TYPE = 'RISK_Building_HB'
    AND CAST(T3.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
;