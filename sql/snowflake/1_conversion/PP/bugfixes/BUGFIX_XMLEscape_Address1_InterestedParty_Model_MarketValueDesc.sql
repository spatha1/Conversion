-- BUG: 4 more free-text fields not XML-escaped -- same defect class as G-21 (which already fixed
-- HB_CLAUSE, PER_HC_CLAUSE, PER_HC_ITEMS_EXCEED_VALUE, PER_HC_SPECIFIEDCONTENTS, and
-- PER_RISK_BUILDING_FINAL.SECURITYDETAILS) -- but these 4 columns were missed by that batch.
--
-- Found 2026-07-15 verifying the Session.closeRq fix: after that fix, real XML parse failures
-- dropped from 3,934/3,934 (100%, all caused by Session.closeRq) to 38/3,934. Diagnosed all 38
-- remaining failures -- every one is a raw unescaped '&' in one of these 4 fields:
--   PER_ACCOUNT_LOC.ADDRESS1                    (seq 3)  -- 10 policies, e.g. "36A & 36B Wakefield Road"
--   PER_RISK_BUILDING_FINAL.INTERESTEDPARTY     (seq 14) -- 26 policies, e.g. "GIUSEPPE, NADINE & DANIEL CALLO"
--   PER_COM_PAYLOAD.MODEL                       (seq 18) -- 1 policy, "714 Tractor & Fel"
--   PER_COM_PAYLOAD.MARKETVALUEDESCRIPTION      (seq 18) -- 1 policy (long accessories list)
-- 10 + 26 + 1 + 1 = 38, exact match to the live failure count.
--
-- FIX: same REPLACE(REPLACE(REPLACE(col,'&','&amp;'),'<','&lt;'),'>','&gt;') pattern already used
-- for every other G-21 field. No other logic touched in any of these 3 views.

-- ============================================================
-- PER_ACCOUNT_LOC (seq 3) -- ADDRESS1
-- ============================================================
CREATE OR REPLACE VIEW PER_ACCOUNT_LOC(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	RISKNUMBER,
	STATE,
	ADDRESS1,
	SUBURB,
	POSTCODE,
	LOC_COUNTRY,
	ADDRESSOVERRIDE
) as
WITH cte1 as
(
SELECT  CAST(trim(T1.PUREPOLICYNUMBER) ||'|' || TRIM(T1.cmlnumber) ||'|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS ID,
T1.* FROM AGGNE.DEV.Locationdetails_PER T1 inner join AGGNE.DEV.SAMPLE_PER T2 on t1.PUREPOLICYNUMBER=T2.PUREPOLICYNUMBER AND T1.EXPIRINGID_P=T2.EXPIRINGID_P
WHERE   T1.EFFECTIVEDATE >= '2026-01-01'
),
cte2  AS (
SELECT CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
TRIM(PUREPOLICYNUMBER) as LEGACYPOLICYNUMBER,
STATE,
ADDRESS1,
SUBURB,
CAST(POSTCODE AS VARCHAR) AS POSTCODE,
-- CAST(COALESCE(GNAFPID ,'0')AS VARCHAR) AS GNAFPID,
COUNTRY,
-- LOCATIONANZSICCODE,
EXPIRINGID_P,
-- Fix ATP-9746 Issue 3: use source RISKNUMBER instead of ROW_NUMBER() to preserve the
-- original location ordering (EXPIRINGID_P order != RISKNUMBER order for multi-period policies)
CAST(COALESCE(CAST(RISKNUMBER AS NUMBER(10,0)), 0) AS VARCHAR) AS RISKNUMBER,
-- PP-CF-25 (2026-07-02, supersedes ATP-9746 Issue 2): AddressOverride must be 1 for ALL
-- converted locations, per Aggne QA. Converted addresses never pass Duck Creek address
-- validation, so OVERRIDE=0 (83% of in-scope source rows) triggers the blocking alert
-- "One or more locations are neither validated nor overridden" and prevents navigation
-- past the Locations screen. Source OVERRIDE column intentionally ignored:
-- CAST(COALESCE(OVERRIDE, 0) AS VARCHAR)  -- ATP-9746 Issue 2 mapping, kept for reference
CAST('1' AS VARCHAR) AS ADDRESSOVERRIDE
FROM AGGNE.DEV.Locationdetails_PER
)
SELECT
T1.PUREPOLICYNUMBER,
-- T1.LOCATIONANZSICCODE,
LEGACYPOLICYNUMBER,
T1.RISKNUMBER,
CASE
    WHEN TRIM(T1.COUNTRY) = 'New Zealand' THEN T1.STATE
    WHEN TRIM(T1.COUNTRY) = 'Australia' AND T1.STATE IS NOT NULL THEN CONCAT(T1.STATE, 'AU')
    ELSE T1.STATE end as STATE,
-- FIX: escape XML-breaking characters (was: T1.ADDRESS1)
REPLACE(REPLACE(REPLACE(CAST(T1.ADDRESS1 AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS ADDRESS1,
UPPER(T1.SUBURB) AS SUBURB,   -- CR 2026-07-13: policy team expects uppercase; 13.5% of Pure source values are mixed-case
-- CAST(COALESCE(T1.GNAFPID ,'0')AS VARCHAR) AS GNAFPID,
CAST(T1.POSTCODE AS VARCHAR) AS POSTCODE,
CASE
    WHEN TRIM(T1.COUNTRY) = 'New Zealand' THEN 'NZ'
    WHEN TRIM(T1.COUNTRY) = 'Australia' THEN 'AU'
    ELSE TRIM(T1.COUNTRY) END AS LOC_COUNTRY,
T1.ADDRESSOVERRIDE
FROM ctE2 T1 INNER JOIN  CTE1 T2  ON T1.PUREPOLICYNUMBER=T2.ID ;

-- Verify:
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_ACCOUNT_LOC WHERE ADDRESS1 LIKE '%&%' AND ADDRESS1 NOT LIKE '%&amp;%';
-- Expected: 0


-- ============================================================
-- PER_RISK_BUILDING_FINAL (seq 14) -- INTERESTEDPARTY
-- ============================================================
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

-- Verify:
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL WHERE INTERESTEDPARTY LIKE ''%&%'' AND INTERESTEDPARTY NOT LIKE ''%&amp;%'';
-- Expected: 0


-- ============================================================
-- PER_COM_PAYLOAD (seq 18) -- MODEL, MARKETVALUEDESCRIPTION
-- ============================================================
create or replace view PER_COM_PAYLOAD(
	PUREPOLICYNUMBER,
	COVERAGE,
	SUBCOV,
	COM_CLAUSE,
	UW,
	MVVALUEWITHOUTACCESSORIES,
	VEHHAVEANINTERESTEDPARTY,
	YEAR,
	MAKE,
	MODEL,
	BODYTYPE,
	MVRBVEHICLEKEY,
	OVERRIDE,
	REGISTRATIONNUMBER,
	ENGINESIZE,
	MARKETVALUEDESCRIPTIONVALUE,
	GROSSVEHICLEMASS,
	MARKETVALUEDESCRIPTION,
	MVADDACCORMODS,
	AGEOFYOUNGESTREGULARDRIVER,
	RESTRICTIONOFDRIVERAGE,
	VOLUNTARYEXCESS,
	PROTECTIONTYPE,
	VEHICLETYPE,
	DESCRIPTION,
	NUMBEROFCYLINDERS,
	DRIVEDESCRIPTION,
	INDUCTIONTYPE,
	IMPORTFLAG,
	MARKETVALUEWITHACCESSORIESAMOUNT,
	AGREEDVALUEAMOUNT,
	ADDDETAILSFORTHEINTERESTEDPARTY,
	HIRECARHIREAFTERINCIDENT,
	CHOICEOFREPAIR,
	EXCESSWAIVERFORGLASS,
	AVVALUEWITHOUTACCESSORIES,
	PMCLMINCD,
	PMCLMCNT,
	PMEXPPREM,
	FUELTYPE,
	POWERKW,
	TRACKREAR,
	LOAD_DATE
) as


-- ============================================================
-- MERGED — G-02 + G-08 + G-12 + G-42, all on AGGNE.DEV.PER_COM_PAYLOAD
-- Single CREATE OR REPLACE VIEW combining the 4 "ready to deploy, no blocker" fixes that all
-- patch this same view. Deploying each one separately as its own CREATE OR REPLACE would have
-- silently undone the others — this file is the safe way to apply all 4 at once.
--
-- Pulled fresh via GET_DDL('VIEW','AGGNE.DEV.PER_COM_PAYLOAD') on 2026-07-10 immediately before
-- merging — confirmed identical length/content to the last live pull, so no other change has
-- landed on this view since G-02/G-08/G-12/G-42 were each investigated.
--
-- NOT INCLUDED: G-05 part 1b (NumberOfCylinders COALESCE-to-0 removal) — also patches this view
-- and is individually ready, but wasn't in the specific "ready, no blocker" list this merge covers.
-- Deploy separately (seq18_risk_building_pm/sp/G-05_fix.sql) if wanted — safe to layer on top of
-- this file's changes with one more edit to the NUMBEROFCYLINDERS line.
--
-- CR 2026-07-14: added FUELTYPE / POWERKW / TRACKREAR (MVRBFUELTYPEDESCRIPTION / MVRBPOWER /
-- MVRBTRACKREAR on PM_03) -- previously not selected anywhere in this view at all.
--
-- FIX 2026-07-15: G-42's Output_Coverage_PER join corrected with TRIM()/TRY_TO_NUMBER() -- see
-- header note above.
-- ============================================================

with cte_SAMPLE_CBP_LOCATION as
(
select distinct trim(T1.PUREPOLICYNUMBER)AS PUREPOLICYNUMBER ,trim(t1.CMLNUMBER) AS CMLNUMBER,T1.EXPIRINGID_P
from AGGNE.DEV.PM_03 T1
INNER JOIN AGGNE.DEV.SAMPLE_PER
T2 ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
--and
--T1.EXPIRINGID=T2.EXPIRINGID_P
WHERE t1.EXPIRYDATE>='2026-01-01'
),cte_COVERAGES as
(
select distinct trim(PUREPOLICYNUMBER) PUREPOLICYNUMBER,cmlnumber, trim(EXPIRINGID_P) EXPIRINGID_P,'BB' AS CLAUSE,'Motor' AS  COVERAGE,
MVVALUEWITHOUTACCESSORIES,
VEHHAVEANINTERESTEDPARTY,-- yes=1,no=0,
-- MVRBVEHICLEKEY,--redbookcode
YEAR,
INITCAP(make) as make,
INITCAP(MODEL) as MODEL,
BODYTYPE,
OVERRIDE,
REGISTRATIONNUMBER,
ENGINESIZE,
MARKETVALUEDESCRIPTIONVALUE,
GROSSVEHICLEMASS,
MARKETVALUEDESCRIPTION,
MVADDACCORMODS,
AGEOFYOUNGESTREGULARDRIVER,
RESTRICTIONOFDRIVERAGE,
VOLUNTARYEXCESS,
PROTECTIONTYPE,
VEHICLETYPE,
DESCRIPTION,
NUMBEROFCYLINDERS,
DRIVEDESCRIPTION,
INDUCTIONTYPE,
IMPORTFLAG,
MARKETVALUEWITHACCESSORIESAMOUNT,
AGREEDVALUEAMOUNT,
ADDDETAILSFORTHEINTERESTEDPARTY,
HIRECARHIREAFTERINCIDENT,
CHOICEOFREPAIR,
EXCESSWAIVERFORGLASS,
AVVALUEWITHOUTACCESSORIES,
MVRBFUELTYPEDESCRIPTION,
MVRBPOWER,
MVRBTRACKREAR
-- FIX (G-02): removed "where YEAR<>0 and make<>'' and MODEL<>''" — was silently dropping vehicles
-- missing Year/Make/Model instead of converting them with those fields blank (PR-01: never
-- silently drop a record for one bad field). 0 vehicles affected in today's data, but the filter
-- was still live and would drop any future one.
from AGGNE.DEV.PM_03 T1
) ,

RedBookCode as (select PUREPOLICYNUMBER,MVRBVEHICLEKEY,EXPIRINGID_P from AGGNE.DEV.PM_03 where (PUREPOLICYNUMBER ,EXPIRINGID_P)in (select distinct  PUREPOLICYNUMBER ,  EXPIRINGID_P from cte_COVERAGES)   )
 , CTE_EXCESS AS(
SELECT
    CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,T2.cmlnumber,T2.EXPIRINGID_P,t2.COVERAGE,t2.MVVALUEWITHOUTACCESSORIES,
t2.VEHHAVEANINTERESTEDPARTY,-- yes=1,no=0,
t2.YEAR,
t2.MAKE,
t2.MODEL,
t2.BODYTYPE,
t2.OVERRIDE,
t2.REGISTRATIONNUMBER,
t2.ENGINESIZE,
t2.MARKETVALUEDESCRIPTIONVALUE,
t2.GROSSVEHICLEMASS,
t2.MARKETVALUEDESCRIPTION,
t2.MVADDACCORMODS,
t2.AGEOFYOUNGESTREGULARDRIVER,
CASE
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'No Restriction' THEN 0
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'Min Age 21'     THEN 20
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'Min Age 25'     THEN 24
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'Min Age 30'     THEN 29
  WHEN TRIM(t2.RestrictionOfDriverAge) = 'Min Age 40'     THEN 39
  ELSE 0  -- or a default code, e.g., -1
END ::varchar as  RESTRICTIONOFDRIVERAGE,
t2.VOLUNTARYEXCESS,
t2.PROTECTIONTYPE,
t2.VEHICLETYPE,
t2.DESCRIPTION,--&,
t2.NUMBEROFCYLINDERS,
t2.DRIVEDESCRIPTION,
t2.INDUCTIONTYPE,
t2.IMPORTFLAG,
t2.MARKETVALUEWITHACCESSORIESAMOUNT,
t2.AGREEDVALUEAMOUNT,
t2.ADDDETAILSFORTHEINTERESTEDPARTY,
t2.HIRECARHIREAFTERINCIDENT,
t2.CHOICEOFREPAIR,
t2.EXCESSWAIVERFORGLASS,
t2.AVVALUEWITHOUTACCESSORIES,
t2.MVRBFUELTYPEDESCRIPTION,
t2.MVRBPOWER,
t2.MVRBTRACKREAR,
t3.MVRBVEHICLEKEY
FROM
cte_SAMPLE_CBP_LOCATION T1
INNER JOIN cte_COVERAGES T2 ON T1.EXPIRINGID_P=T2.EXPIRINGID_P AND TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
LEFT  JOIN RedBookCode T3 ON T3.EXPIRINGID_P=T2.EXPIRINGID_P AND TRIM(T3.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)
--and T3.MVRBVEHICLEKEY is not null


)
-- select * from CTE_EXCESS  where PUREPOLICYNUMBER like '%P00012077%'

,CTE_LISTAGG AS(
SELECT
  ID,
  LISTAGG(CASE WHEN ITR_TYPE = 'Risk_CM'            THEN payload END, '\n') AS SUBCOV,
  LISTAGG(CASE WHEN ITR_TYPE = 'PER_PM_BUILDING_UW' THEN payload END, '\n') AS UW,
  LISTAGG(CASE WHEN ITR_TYPE = 'COM_CLAUSE'          THEN payload END, '\n') AS COM_CLAUSE,
  CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE ITR_TYPE IN ('Risk_CM', 'PER_PM_BUILDING_UW', 'COM_CLAUSE')   --AND CAST(LOAD_DATE AS DATE)= CAST(GETDATE() AS DATE)
GROUP BY ID, CAST(LOAD_DATE AS DATE)
)
SELECT distinct
T1.PUREPOLICYNUMBER,
COVERAGE,
CAST(REPLACE(SUBCOV ,'&','&amp;') AS VARCHAR) AS SUBCOV,
CASE WHEN COM_CLAUSE IS NOT NULL AND COM_CLAUSE <> '' THEN CAST(COM_CLAUSE AS VARCHAR) ELSE '' END AS COM_CLAUSE,
CASE WHEN UW IS NOT NULL AND UW <> '' THEN CAST(UW AS VARCHAR) ELSE '' END AS UW,
CAST(MVVALUEWITHOUTACCESSORIES AS VARCHAR) AS MVVALUEWITHOUTACCESSORIES,
case when VEHHAVEANINTERESTEDPARTY ='Yes' THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS VEHHAVEANINTERESTEDPARTY,-- yes=1,no=0,
CAST(YEAR AS VARCHAR) AS YEAR,
CAST(make AS VARCHAR) AS make,
-- FIX: escape XML-breaking characters (was: CAST(MODEL AS VARCHAR))
REPLACE(REPLACE(REPLACE(CAST(MODEL AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS MODEL,
-- BodyType: RedBook free-text field — map source values to camelCase for DCT consistency.
CASE
  WHEN TRIM(BodyType) = 'B-double'         THEN 'B-double'
  WHEN TRIM(BodyType) = 'Bus'              THEN 'Bus'
  WHEN TRIM(BodyType) = 'Bus Chassis'      THEN 'BusChassis'
  WHEN TRIM(BodyType) = 'Cab Chassis'      THEN 'CabChassis'
  WHEN TRIM(BodyType) = 'Cabriolet'        THEN 'Cabriolet'
  WHEN TRIM(BodyType) = 'Compactor'        THEN 'Compactor'
  WHEN TRIM(BodyType) = 'Convertible'      THEN 'Convertible'
  WHEN TRIM(BodyType) = 'Coupe'            THEN 'Coupe'
  WHEN TRIM(BodyType) = 'Distributor'      THEN 'Distributor'
  WHEN TRIM(BodyType) = 'Dump'             THEN 'Dump'
  WHEN TRIM(BodyType) = 'Extra Heavy Duty' THEN 'ExtraHeavyDuty'
  WHEN TRIM(BodyType) = 'Fastback'         THEN 'Fastback'
  WHEN TRIM(BodyType) = 'Hardtop'          THEN 'Hardtop'
  WHEN TRIM(BodyType) = 'Hatchback'        THEN 'Hatchback'
  WHEN TRIM(BodyType) = 'Heavy Duty'       THEN 'HeavyDuty'
  WHEN TRIM(BodyType) = 'Highway'          THEN 'Highway'
  WHEN TRIM(BodyType) = 'Liftback'         THEN 'Liftback'
  WHEN TRIM(BodyType) = 'Limousine'        THEN 'Limousine'
  WHEN TRIM(BodyType) = 'Mixer'            THEN 'Mixer'
  WHEN TRIM(BodyType) = 'Prime Mover'      THEN 'PrimeMover'
  WHEN TRIM(BodyType) = 'Rigid'            THEN 'Rigid'
  WHEN TRIM(BodyType) = 'Road Train'       THEN 'RoadTrain'
  WHEN TRIM(BodyType) = 'Roadster'         THEN 'Roadster'
  WHEN TRIM(BodyType) = 'Sedan'            THEN 'Sedan'
  WHEN TRIM(BodyType) = 'Softtop'          THEN 'Softtop'
  WHEN TRIM(BodyType) = 'Street Sweeper'   THEN 'StreetSweeper'
  WHEN TRIM(BodyType) = 'Targa'            THEN 'Targa'
  WHEN TRIM(BodyType) = 'Tipper'           THEN 'Tipper'
  WHEN TRIM(BodyType) = 'Trailer'          THEN 'Trailer'
  WHEN TRIM(BodyType) = 'Traytop'          THEN 'Traytop'
  WHEN TRIM(BodyType) = 'Utility'          THEN 'Utility'
  WHEN TRIM(BodyType) = 'Van'              THEN 'Van'
  WHEN TRIM(BodyType) = 'Van Wagon'        THEN 'VanWagon'
  WHEN TRIM(BodyType) = 'Wagon'            THEN 'Wagon'
  ELSE ''
END AS BODYTYPE,

MVRBVEHICLEKEY,
-- PP-CF-26 (2026-07-02, follows PP-CF-25 pattern): VehicleInfoOverride must be 1 for ALL
-- converted vehicles, per Aggne QA. 100% of in-scope vehicles (607 vehicles / 441 policies)
-- have no MVRBVEHICLEKEY, so the previous key-driven CASE set 0 everywhere and DCT cannot
-- do a RedBook lookup without a key — vehicle screen blocks like the Locations screen did.
-- Previous logic, kept for reference:
-- CASE WHEN T1.MVRBVEHICLEKEY IS NOT NULL AND TRIM(T1.MVRBVEHICLEKEY) <> '' THEN '1' ELSE '0' END
CAST('1' AS VARCHAR) AS OVERRIDE,
-- FIX (G-08): uppercase + strip every non-alphanumeric character. 63 of 3,304 rows were pure
-- formatting issues (case/stray punctuation around a real rego); the remaining ~273 are genuine
-- bad-data rows (a VIN/serial/"Unregistered" typed into this field) that this cannot fix — those
-- need the separate keyword-based validation-report rule described in G-08_fix.sql.
UPPER(REGEXP_REPLACE(CAST(REGISTRATIONNUMBER AS VARCHAR), '[^A-Za-z0-9]', '')) AS REGISTRATIONNUMBER,
CAST(ENGINESIZE AS VARCHAR) AS ENGINESIZE,
CAST(MARKETVALUEDESCRIPTIONVALUE AS VARCHAR) AS MARKETVALUEDESCRIPTIONVALUE,
CAST(GROSSVEHICLEMASS AS VARCHAR) AS GROSSVEHICLEMASS,
-- FIX: escape XML-breaking characters (was: CAST(MARKETVALUEDESCRIPTION AS VARCHAR))
REPLACE(REPLACE(REPLACE(CAST(MARKETVALUEDESCRIPTION AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS MARKETVALUEDESCRIPTION,
case when CAST(MVADDACCORMODS AS VARCHAR) ='Yes' then 'Yes' else 'No' end AS MVADDACCORMODS,
CAST(AGEOFYOUNGESTREGULARDRIVER AS VARCHAR) AS AGEOFYOUNGESTREGULARDRIVER,
CAST(RESTRICTIONOFDRIVERAGE AS VARCHAR) AS RESTRICTIONOFDRIVERAGE,
CAST(CAST(COALESCE(VOLUNTARYEXCESS,0)AS NUMBER(20,0)) AS VARCHAR) AS VOLUNTARYEXCESS,
-- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml PL101, line 2427-2433):
-- ComprehensiveMarket | ComprehensiveAgreedValue | FireandTheft | Comprehensive | ThirdPartyFireandTheft | ThirdPartyOnly
-- NOTE: 'FullComprehensive' does NOT exist in DCT — 'Comprehensive' is the correct code.
CASE
    WHEN PROTECTIONTYPE = 'Comprehensive - Market Value'    THEN 'ComprehensiveMarket'
    WHEN PROTECTIONTYPE = 'Comprehensive - Agreed Value'    THEN 'ComprehensiveAgreedValue'
    WHEN PROTECTIONTYPE = 'Fire and Theft'                  THEN 'FireandTheft'
    WHEN PROTECTIONTYPE = 'Comprehensive'                   THEN 'Comprehensive'
    WHEN PROTECTIONTYPE = 'Third Party Only'                THEN 'ThirdPartyOnly'
    WHEN PROTECTIONTYPE = 'Third Party, Fire and Theft'     THEN 'ThirdPartyFireandTheft'
    ELSE ''
END AS PROTECTIONTYPE,

-- FIX (G-12): allow-list to the 9-code Override=1 set (Override is force-set to '1' for every
-- vehicle above, so the Override=0-only codes — MobileEquipment/Tractor/Transporter/HeavyVehicle —
-- are structurally never valid here). ELSE changed from raw passthrough to NULL so the validation
-- report catches anything unmapped instead of forwarding an invalid code silently (PR-01).
-- 0 live impact today (hardening only) — no current rows use the removed codes or hit the old ELSE.
CASE
    WHEN TRIM(VEHICLETYPE) = 'Passenger Vehicle'  THEN 'PassengerVehicle'
    WHEN TRIM(VEHICLETYPE) = 'Caravan'            THEN 'Caravan'
    WHEN TRIM(VEHICLETYPE) = 'Camper Van'         THEN 'CamperVan'
    WHEN TRIM(VEHICLETYPE) = 'Trailer'            THEN 'Trailer'
    WHEN TRIM(VEHICLETYPE) = 'Motorcycle'         THEN 'Motorcycle'
    WHEN TRIM(VEHICLETYPE) = 'Light Commercial'   THEN 'LightCommercial'
    WHEN TRIM(VEHICLETYPE) = 'Heavy Commercial'   THEN 'HeavyCommercial'
    WHEN TRIM(VEHICLETYPE) = 'Forklift'           THEN 'Forklift'
    WHEN TRIM(VEHICLETYPE) = 'Tow Truck'          THEN 'TowTruck'
    WHEN VEHICLETYPE IS NULL OR TRIM(VEHICLETYPE) = '' THEN 'PassengerVehicle'  -- still pending explicit client sign-off, unrelated to this gap
    ELSE NULL
END AS VEHICLETYPE,
REPLACE(DESCRIPTION ,'&','&amp;') as DESCRIPTION,
-- CAST(CAST(COALESCE(NUMBEROFCYLINDERS,0)AS NUMBER(20,0)) AS VARCHAR)
 CAST(NUMBEROFCYLINDERS AS VARCHAR)  -- NULL stays NULL/blank, not the invalid '0'
AS  NUMBEROFCYLINDERS,
REPLACE(DRIVEDESCRIPTION ,'&','&amp;') as  DRIVEDESCRIPTION,
-- DCT options (Carrier_PersonalProtectionBase_1_0_0_0.xml line 2400-2415):
--   Aspirated | Supercharged | Turbocharged | TurboandSupercharged
-- Fix applied 2026-07-01: added 'Turbocharged' as explicit source value (6 policies)
--   — source data already contains the DCT code value; was falling to ELSE '' silently.
CASE
  WHEN TRIM(INDUCTIONTYPE) = 'Aspirated'                      THEN 'Aspirated'
  WHEN TRIM(INDUCTIONTYPE) = 'Supercharged Intercooled'       THEN 'Supercharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Twin Supercharged Intercooled'  THEN 'Supercharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Supercharged'                   THEN 'Supercharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Turbo'                          THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Turbo Intercooled'              THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Twin Turbo Intercooled'         THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Triple Turbo Intercooled'       THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Quad Turbo Intercooled'         THEN 'Turbocharged'
  WHEN TRIM(INDUCTIONTYPE) = 'Turbocharged'                   THEN 'Turbocharged'  -- fixed: source already has DCT code value
  WHEN TRIM(INDUCTIONTYPE) = 'Turbo Supercharged Intercooled' THEN 'TurboandSupercharged'
  ELSE ''
END AS INDUCTIONTYPE,
IMPORTFLAG,
CAST(CAST(COALESCE(MARKETVALUEWITHACCESSORIESAMOUNT,0)AS NUMBER(20,0)) AS VARCHAR) AS MARKETVALUEWITHACCESSORIESAMOUNT,
CAST(CAST(COALESCE(AGREEDVALUEAMOUNT,0)AS NUMBER(20,0)) AS VARCHAR) AS  AGREEDVALUEAMOUNT,
REPLACE(ADDDETAILSFORTHEINTERESTEDPARTY ,'&','&amp;') as ADDDETAILSFORTHEINTERESTEDPARTY,
case when HIRECARHIREAFTERINCIDENT ='Taken' THEN CAST('Taken' AS VARCHAR) ELSE CAST('NotTaken' AS VARCHAR) END AS  HIRECARHIREAFTERINCIDENT,
case when CHOICEOFREPAIR ='Taken' THEN CAST('1' AS VARCHAR) ELSE CAST('0' AS VARCHAR) END AS  CHOICEOFREPAIR,
-- ATP-11003 (2026-07-03): Pure stores 'Taken' (not 'Yes') for some policies — map both values to 1.
-- Pattern matches HIRECARHIREAFTERINCIDENT and CHOICEOFREPAIR which already accept 'Taken'.
case when EXCESSWAIVERFORGLASS IN ('Yes', 'Taken') THEN CAST(1 AS VARCHAR) ELSE CAST(0 AS VARCHAR) END AS  EXCESSWAIVERFORGLASS,
CAST(CAST(COALESCE(AVVALUEWITHOUTACCESSORIES,0)AS NUMBER(20,0)) AS VARCHAR) AS  AVVALUEWITHOUTACCESSORIES,
CAST(COALESCE(T4.PMCLMINCD,0) AS VARCHAR) AS PMCLMINCD,
CAST(COALESCE(T4.PMCLMCNT,0) AS VARCHAR) AS PMCLMCNT,
CAST(COALESCE(T4.PMEXPPREM,0) AS VARCHAR) AS PMEXPPREM,
CAST(MVRBFUELTYPEDESCRIPTION AS VARCHAR) AS FUELTYPE,
CAST(MVRBPOWER AS VARCHAR) AS POWERKW,
CAST(MVRBTRACKREAR AS VARCHAR) AS TRACKREAR,
CAST(GETDATE() AS DATE) as LOAD_DATE
FROM CTE_EXCESS T1
LEFT JOIN  AGGNE.DEV.PER_COM_COVERAGES_TARGET T2 ON T1.PUREPOLICYNUMBER=T2.ID
LEFT JOIN CTE_LISTAGG T3 ON T1.PUREPOLICYNUMBER = T3.ID
-- FIX (G-42, corrected 2026-07-15): T1.PUREPOLICYNUMBER here is the COMPOSITE key
-- (LEGACYPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P) but T4.POLICYNUMBER is the PLAIN pure policy
-- number, with padding spaces -- needs TRIM(). SPLIT_PART's string result also needs
-- TRY_TO_NUMBER() to compare correctly against the NUMBER EXPIRINGID_P column. Without both,
-- this join never matches, so PMEXPPREM/PMCLMINCD/PMCLMCNT are always 0 (confirmed live: 100%
-- of 3,288 rows). With both added: 0% NULL.
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4
    ON SPLIT_PART(T1.PUREPOLICYNUMBER, '|', 1) = TRIM(T4.POLICYNUMBER)
   AND TRY_TO_NUMBER(SPLIT_PART(T1.PUREPOLICYNUMBER, '|', 3)) = T4.EXPIRINGID_P
WHERE   COVERAGE='Motor'  ;

-- Verify:
-- SELECT COUNT(*) FROM AGGNE.DEV.PER_COM_PAYLOAD WHERE (MODEL LIKE ''%&%'' AND MODEL NOT LIKE ''%&amp;%'') OR (MARKETVALUEDESCRIPTION LIKE ''%&%'' AND MARKETVALUEDESCRIPTION NOT LIKE ''%&amp;%'');
-- Expected: 0
