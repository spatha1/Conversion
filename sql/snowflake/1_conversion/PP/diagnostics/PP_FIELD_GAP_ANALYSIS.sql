-- ============================================================
-- PP FIELD-LEVEL GAP ANALYSIS — All Policies
-- Date    : 2026-07-01
-- Version : 1.0
--
-- Purpose : For EVERY policy in AGGNE.DEV.SAMPLE_PER:
--             1. Source view row coverage  — which ETL sections have data
--             2. Mandatory field blanks    — PL101 required fields are NULL/empty
--             3. Dropdown mismatches       — source value has no valid DCT mapping
--             4. Length violations         — value exceeds PL101 maxLength
--             5. Policy-level detail       — per-policy flag matrix
--
-- Source reference : PP_ConversionConfig (SQL Server · PolicyConversion DB)
-- PL101 reference  : Carrier_PersonalProtectionBase_1_0_0_0.xml (2025-02-24)
--                    145 public fields · 25 always required · 6 conditionally required · 43 dropdowns
--
-- Run each section independently or scroll to the section needed.
-- Run with: USE DATABASE AGGNE; USE SCHEMA DEV;
-- ============================================================


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 0  ·  SCOPE — total policies in scope for PP conversion
-- ─────────────────────────────────────────────────────────────────────────────
-- Source : AGGNE.DEV.SAMPLE_PER (the full PP conversion population)
-- Config : Applied to all PP ConversionConfig sequences (seq 1–18)
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT
    'SAMPLE_PER (PP base population)'      AS SOURCE,
    COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)) AS TOTAL_POLICIES,
    NULL                                   AS NOTE
FROM AGGNE.DEV.SAMPLE_PER;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 1  ·  SOURCE VIEW COVERAGE — which sections have data per policy
-- ─────────────────────────────────────────────────────────────────────────────
-- Shows how many policies from SAMPLE_PER appear in each source pure table.
-- A policy with 0 rows in a source table will produce nothing in that ETL section.
-- Config seqs listed next to each source.
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT SOURCE, POLICY_COUNT, CONFIG_SEQS, NOTES FROM (

    SELECT 1 AS SORT_KEY,
        'SAMPLE_PER (base scope)'                        AS SOURCE,
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER))           AS POLICY_COUNT,
        'All seqs'                                       AS CONFIG_SEQS,
        'Full PP conversion population'                  AS NOTES
    FROM AGGNE.DEV.SAMPLE_PER

    UNION ALL

    -- Seq 3 : Address / location
    -- Source view: PER_ACCOUNT_LOC  ←  Locationdetails_PER (EFFECTIVEDATE >= 2026-01-01)
    SELECT 2,
        'Locationdetails_PER  →  PER_ACCOUNT_LOC (address)',
        COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER)),
        'Seq 3',
        'Policies with at least one active location record'
    FROM AGGNE.DEV.Locationdetails_PER L
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE L.EFFECTIVEDATE >= '2026-01-01'

    UNION ALL

    -- Seq 14 : Building risk (construction + security + occupancy)
    -- Source view: PER_RISK_BUILDING_FINAL  ←  Locationdetails_PER  (same filter)
    -- NOTE: Locationdetails_PER feeds both Seq 3 (address) AND Seq 14 (building risk)
    SELECT 3,
        'Locationdetails_PER  →  PER_RISK_BUILDING_FINAL (building risk)',
        COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER)),
        'Seq 14',
        'Same source as Seq 3 — additional construction/security fields'
    FROM AGGNE.DEV.Locationdetails_PER L
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE L.EFFECTIVEDATE >= '2026-01-01'

    UNION ALL

    -- Seq 7 + 13 : Home Building (HB) and Home Contents (HC) payloads
    -- Source view: PER_HOME_BUILDING_PAYLOAD  ←  HC_02  ∪  HB_01 (HB-only)
    SELECT 4,
        'HC_02  →  HB+HC payloads (Home Contents policies)',
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)),
        'Seq 7, 13',
        'Policies with Home Contents coverage (HC_02 present)'
    FROM AGGNE.DEV.HC_02

    UNION ALL

    SELECT 5,
        'HB_01  →  HB payload (HB-only, no HC_02)',
        COUNT(DISTINCT TRIM(H.PUREPOLICYNUMBER)),
        'Seq 7',
        'HB-only policies added by ATP-9638 fix (not in HC_02)'
    FROM AGGNE.DEV.HB_01 H
    WHERE NOT EXISTS (
        SELECT 1 FROM AGGNE.DEV.HC_02 HC
        WHERE TRIM(H.PUREPOLICYNUMBER) = TRIM(HC.PUREPOLICYNUMBER)
    )

    UNION ALL

    -- Seq 7 (HB-specific fields): HB_02 (home building limits, landlord, rental period)
    SELECT 6,
        'HB_02  →  PER_HOME_BUILDING_PAYLOAD (HB limits/landlord)',
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)),
        'Seq 7',
        'HOMEBUILDINGSLIMIT, LANDLORDPROTECTIONS, MINIMUMRENTALPERIOD, WEEKLYRENT'
    FROM AGGNE.DEV.HB_02

    UNION ALL

    -- Seq 17 + 18 : Motor / Commercial vehicle payloads
    -- Source view: PER_COM_PAYLOAD  ←  PM_03 (active vehicles: YEAR<>0, MAKE<>'', MODEL<>'')
    SELECT 7,
        'PM_03  →  PER_COM_PAYLOAD (motor vehicle)',
        COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER)),
        'Seq 17, 18',
        'Policies with at least one active vehicle record'
    FROM AGGNE.DEV.PM_03 P
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE P.EXPIRYDATE >= '2026-01-01'
      AND P.YEAR   <> 0
      AND TRIM(P.MAKE)  <> ''
      AND TRIM(P.MODEL) <> ''

    UNION ALL

    -- Seq 1 : Claim history
    -- Source view: PER_VW_CLAIM_HISTORY  (inner source table not shown; query the view directly)
    SELECT 8,
        'PER_VW_CLAIM_HISTORY (claim history)',
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)),
        'Seq 1',
        'Policies with at least one claim history row'
    FROM AGGNE.DEV.PER_VW_CLAIM_HISTORY

    UNION ALL

    -- Seq 2 : Prior/competitor information
    SELECT 9,
        'PER_VW_CBP_COMPETITOR_INFORMATION (prior info)',
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)),
        'Seq 2',
        'Policies with prior carrier / price information'
    FROM AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION

    UNION ALL

    -- Seq 4 : BB sub-coverages (HB building sub-coverage line items)
    -- Source view: PER_BB_SUBCOVERAGES  ←  HC_02 (coverage type, limits, premiums)
    SELECT 10,
        'HC_02  →  PER_BB_SUBCOVERAGES (HB sub-coverage lines)',
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)),
        'Seq 4',
        'HC sub-coverage rows: TYPE, CODE, IVALUE, INDICATOR, EXP_PREM (all hardcoded or source-derived)'
    FROM AGGNE.DEV.HC_02

    UNION ALL

    -- Seq 8 : HC exceed-value items
    -- Source view: PER_HC_ITEMS_EXCEED_VALUE  ←  HC_02 + ITEMS_EXCEED_VALUE_PER
    SELECT 11,
        'ITEMS_EXCEED_VALUE_PER  →  PER_HC_ITEMS_EXCEED_VALUE (HC item values)',
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)),
        'Seq 8',
        'HomeContents items exceeding value — VALUE + DESCRIPTION per item'
    FROM AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE

    UNION ALL

    -- Seq 9 : HC specified contents
    -- Source view: PER_HC_SPECIFIEDCONTENTS  ←  HC specified items
    SELECT 12,
        'HC specified items  →  PER_HC_SPECIFIEDCONTENTS (Seq 9)',
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)),
        'Seq 9',
        'SpecifiedContents rows — VALUE + DESCRIPTION per item'
    FROM AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS

    UNION ALL

    -- Seq 10 : HC building sub-coverages
    -- Source view: PER_HC_SUBCOVERAGES  ←  HC_02
    SELECT 13,
        'HC_02  →  PER_HC_SUBCOVERAGES (HC sub-coverage lines)',
        COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)),
        'Seq 10',
        'HC sub-coverage rows: TYPE, CODE, IVALUE, INDICATOR, EXP_PREM'
    FROM AGGNE.DEV.PER_HC_SUBCOVERAGES

    UNION ALL

    -- Seq 16 : Motor sub-coverages
    -- Source view: PER_COM_COVERAGES  ←  PM_03 + Output_SubCover_PER
    -- 8 hardcoded coverage types (CMP_SD, COR_SD, FTL_SD, LIA_SD, PCH_SD, TFT_SD, TPO_SD, ULG_SD)
    SELECT 14,
        'PM_03 + Output_SubCover_PER  →  PER_COM_COVERAGES (motor sub-coverage lines)',
        COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER)),
        'Seq 16',
        '8 hardcoded CommercialVehicle sub-coverages; EXP_PREM from Output_SubCover_PER'
    FROM AGGNE.DEV.PM_03 P
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE P.EXPIRYDATE >= '2026-01-01'

) t
ORDER BY SORT_KEY;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 2  ·  MANDATORY FIELD BLANK COUNTS
-- ─────────────────────────────────────────────────────────────────────────────
-- PL101 fields marked "always required" or "conditionally required" that
-- are blank/NULL in the source data produce incomplete XML in DCT and may
-- fail policy attach validation.
-- ═══════════════════════════════════════════════════════════════════════════════


-- ── 2A  ·  Location / Address  (Seq 3 template tokens) ──────────────────────
-- Source  : AGGNE.DEV.Locationdetails_PER  (via PER_ACCOUNT_LOC)
-- Template: <State>{STATE}  <Address1>{ADDRESS1}  <City>{SUBURB}  <ZipCode>{POSTCODE}  <Country>{LOC_COUNTRY}
-- PL101   : All five address fields are mandatory for a location element
SELECT
    '2A · Location/Address  [Seq 3]'                                            AS SECTION,
    'Locationdetails_PER → PER_ACCOUNT_LOC'                                    AS SOURCE_VIEW,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS TOTAL_POLICIES,
    SUM(CASE WHEN NULLIF(TRIM(L.STATE),    '') IS NULL THEN 1 ELSE 0 END)       AS STATE_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(L.ADDRESS1), '') IS NULL THEN 1 ELSE 0 END)       AS ADDRESS1_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(L.SUBURB),   '') IS NULL THEN 1 ELSE 0 END)       AS SUBURB_BLANK,
    SUM(CASE WHEN L.POSTCODE IS NULL
              OR CAST(L.POSTCODE AS VARCHAR) = '' THEN 1 ELSE 0 END)            AS POSTCODE_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(L.COUNTRY),  '') IS NULL THEN 1 ELSE 0 END)       AS COUNTRY_BLANK,
    SUM(CASE WHEN TRIM(L.COUNTRY) NOT IN ('Australia','New Zealand')
             AND NULLIF(TRIM(L.COUNTRY),'') IS NOT NULL THEN 1 ELSE 0 END)      AS COUNTRY_UNEXPECTED_VALUE
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01';


-- ── 2B  ·  Building Construction + Security + Occupancy  (Seq 14) ────────────
-- Source  : AGGNE.DEV.Locationdetails_PER  (via PER_RISK_BUILDING_FINAL)
-- PL101   : RoofConstruction, MainWallConstruction, FloorConstruction → REQUIRED
--           HomeBuildingOccupied, AlarmSystem, Deadlocks, Grills → NOT required
--           but important for DCT landlord/security rules
-- 991 of ~4,194 building policies have ALL construction fields blank (no building data in Pure)
SELECT
    '2B · Building Construction + Security  [Seq 14]'                           AS SECTION,
    'Locationdetails_PER → PER_RISK_BUILDING_FINAL'                            AS SOURCE_VIEW,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS TOTAL_BUILDING_POLICIES,

    -- PL101 REQUIRED construction fields
    SUM(CASE WHEN NULLIF(TRIM(L.ROOFCONSTRUCTION),    '') IS NULL THEN 1 ELSE 0 END) AS ROOF_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(L.MAINWALLCONSTRUCTION),'') IS NULL THEN 1 ELSE 0 END) AS MAINWALL_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(L.FLOORCONSTRUCTION),   '') IS NULL THEN 1 ELSE 0 END) AS FLOOR_BLANK,

    -- Non-required but flagged as important
    SUM(CASE WHEN NULLIF(TRIM(L.HOWOCCUPPIED),         '') IS NULL THEN 1 ELSE 0 END) AS OCCUPIED_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(L.ALARMSYSTEMINSTALLED), '') IS NULL THEN 1 ELSE 0 END) AS ALARM_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(L.DEADLOCKSINSTALLED),   '') IS NULL THEN 1 ELSE 0 END) AS DEADLOCKS_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(L.GRILLKEYLOCKINSTALLED),'') IS NULL THEN 1 ELSE 0 END) AS GRILLS_BLANK,

    -- Year / structural fields
    SUM(CASE WHEN L.YEARBUILDINGCONSTRUCTED IS NULL
              OR CAST(L.YEARBUILDINGCONSTRUCTED AS VARCHAR) = ''
              OR L.YEARBUILDINGCONSTRUCTED = 0 THEN 1 ELSE 0 END)               AS YEAR_BUILT_BLANK,
    SUM(CASE WHEN L.STOREYS IS NULL
              OR CAST(L.STOREYS AS VARCHAR) = '' THEN 1 ELSE 0 END)             AS STOREYS_BLANK,

    -- Policies with NO building data at all (all 3 mandatory construction fields blank)
    SUM(CASE WHEN NULLIF(TRIM(L.ROOFCONSTRUCTION),    '') IS NULL
             AND NULLIF(TRIM(L.MAINWALLCONSTRUCTION), '') IS NULL
             AND NULLIF(TRIM(L.FLOORCONSTRUCTION),    '') IS NULL
             THEN 1 ELSE 0 END)                                                  AS ALL_CONSTRUCTION_BLANK
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01';


-- ── 2C  ·  Motor Vehicle Fields  (Seq 17–18) ─────────────────────────────────
-- Source  : AGGNE.DEV.PM_03  (via PER_COM_PAYLOAD)
-- PL101   : Make, Model, Year are required; ProtectionType required for pricing
--           VehicleType NOT required but defaults to PassengerVehicle when blank
--           VehicleInfoOverride is DERIVED from MVRBVEHICLEKEY (not a source column)
SELECT
    '2C · Motor Vehicle Fields  [Seq 17-18]'                                    AS SECTION,
    'PM_03 → PER_COM_PAYLOAD'                                                  AS SOURCE_VIEW,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS TOTAL_MOTOR_POLICIES,
    SUM(CASE WHEN NULLIF(TRIM(P.MAKE),  '') IS NULL THEN 1 ELSE 0 END)          AS MAKE_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(P.MODEL), '') IS NULL THEN 1 ELSE 0 END)          AS MODEL_BLANK,
    SUM(CASE WHEN P.YEAR IS NULL OR P.YEAR = 0 THEN 1 ELSE 0 END)               AS YEAR_BLANK,
    SUM(CASE WHEN NULLIF(TRIM(P.PROTECTIONTYPE),'') IS NULL THEN 1 ELSE 0 END)  AS PROTECTIONTYPE_BLANK,
    SUM(CASE WHEN P.VEHICLETYPE IS NULL
              OR TRIM(P.VEHICLETYPE) = '' THEN 1 ELSE 0 END)                    AS VEHICLETYPE_BLANK_defaults_to_PassengerVehicle,
    SUM(CASE WHEN P.MVRBVEHICLEKEY IS NULL
              OR TRIM(P.MVRBVEHICLEKEY) = '' THEN 1 ELSE 0 END)                 AS REDBOOK_KEY_BLANK_drives_VehicleInfoOverride_0
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01';


-- ── 2D  ·  Home Building Coverage Fields  (Seq 7) ────────────────────────────
-- Source  : AGGNE.DEV.HB_02  (via PER_HOME_BUILDING_PAYLOAD)
-- PL101   : HOMEBUILDINGSLIMIT → GlassLimit (not required but must be numeric)
--           MINIMUMRENTALPERIOD → conditional (only for landlord/tenanted policies)
SELECT
    '2D · HB Coverage Limits  [Seq 7]'                                          AS SECTION,
    'HB_02 → PER_HOME_BUILDING_PAYLOAD'                                        AS SOURCE_VIEW,
    COUNT(DISTINCT TRIM(PUREPOLICYNUMBER))                                      AS TOTAL_HB_POLICIES,
    SUM(CASE WHEN HOMEBUILDINGSLIMIT IS NULL OR HOMEBUILDINGSLIMIT = 0
             THEN 1 ELSE 0 END)                                                  AS HOMEBUILDINGSLIMIT_ZERO_OR_NULL,
    SUM(CASE WHEN NULLIF(TRIM(MINIMUMRENTALPERIOD),'') IS NULL THEN 1 ELSE 0 END) AS RENTALPERIOD_BLANK,
    SUM(CASE WHEN WEEKLYRENT IS NULL OR WEEKLYRENT = 0 THEN 1 ELSE 0 END)       AS WEEKLYRENT_ZERO_OR_NULL,
    SUM(CASE WHEN NULLIF(TRIM(LANDLORDPROTECTIONS),'') IS NULL THEN 1 ELSE 0 END) AS LANDLORD_PROTECTION_BLANK
FROM AGGNE.DEV.HB_02;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 3  ·  DROPDOWN VALIDATION
-- ─────────────────────────────────────────────────────────────────────────────
-- For each dropdown field: show every distinct source value, policy count,
-- and whether the value has a valid DCT mapping.
-- STATUS key:
--   MAPPED_OK              → source value has a CASE branch in the view (valid DCT code produced)
--   BLANK                  → null or empty string (becomes empty XML tag / blank DCT field)
--   INVALID — needs mapping → falls to ELSE; passthrough value is NOT a valid PL101 DCT code
-- ═══════════════════════════════════════════════════════════════════════════════


-- ── 3A  ·  ROOFCONSTRUCTION ──────────────────────────────────────────────────
-- Source  : Locationdetails_PER.ROOFCONSTRUCTION  (via PER_RISK_BUILDING_FINAL, Seq 14)
-- PL101   : REQUIRED  |  DCT codes: Asbestos | Colourbond | Concrete | IronSteelTin | Tile | Wood
-- View mapping: Iron/Steel/Tin → IronSteelTin; Colorbond(US) → Colourbond; Wood(Shingles) → Wood
SELECT
    '3A · ROOFCONSTRUCTION  [Seq 14, mandatory]'                                AS SECTION,
    'Locationdetails_PER → ROOFCONSTRUCTION_FINAL'                             AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(ROOFCONSTRUCTION), ''), '(blank)')                     AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(ROOFCONSTRUCTION), '') IS NULL                         THEN 'BLANK'
        WHEN TRIM(ROOFCONSTRUCTION) IN ('Asbestos','Concrete','Concrete (Flat Roof)',
             'Iron','Iron/Steel/Tin','Tin','Tile','Wood','Wood (Shingles)')      THEN 'MAPPED_OK'
        WHEN TRIM(ROOFCONSTRUCTION) ILIKE '%colorbond%'
          OR TRIM(ROOFCONSTRUCTION) ILIKE '%colourbond%'                        THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(ROOFCONSTRUCTION), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3B  ·  MAINWALLCONSTRUCTION ──────────────────────────────────────────────
-- Source  : Locationdetails_PER.MAINWALLCONSTRUCTION  (via PER_RISK_BUILDING_FINAL, Seq 14)
-- PL101   : REQUIRED  |  DCT codes: Asbestos | BrickVeneer | Concrete | DoubleBrick |
--                                   FibroHardiplank | IronSteel | Wood
-- Known issues: 'Steel' and 'Some Asbestos and Brick' are NOT in PL101 (client decision Q6)
SELECT
    '3B · MAINWALLCONSTRUCTION  [Seq 14, mandatory]'                            AS SECTION,
    'Locationdetails_PER → MAINWALLCONSTRUCTION_FINAL'                         AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(MAINWALLCONSTRUCTION), ''), '(blank)')                 AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(MAINWALLCONSTRUCTION), '') IS NULL                     THEN 'BLANK'
        WHEN TRIM(MAINWALLCONSTRUCTION) IN ('Asbestos','Brick Veneer','Concrete',
             'Double Brick','Fibro (Non-Asbestos)','Fibro/Hardiplank',
             'Iron','Iron/Steel','Wood')                                         THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(MAINWALLCONSTRUCTION), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3C  ·  FLOORCONSTRUCTION ─────────────────────────────────────────────────
-- Source  : Locationdetails_PER.FLOORCONSTRUCTION  (via PER_RISK_BUILDING_FINAL, Seq 14)
-- PL101   : REQUIRED  |  DCT codes: Concrete | Other | WoodConcretefootings | WoodStilts | WoodStumps
-- Note    : DCT code is 'WoodConcretefootings' — lowercase 'f' (not 'WoodConcreteFootings')
SELECT
    '3C · FLOORCONSTRUCTION  [Seq 14, mandatory]'                               AS SECTION,
    'Locationdetails_PER → FLOORCONSTRUCTION_FINAL'                            AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(FLOORCONSTRUCTION), ''), '(blank)')                    AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(FLOORCONSTRUCTION), '') IS NULL                        THEN 'BLANK'
        WHEN TRIM(FLOORCONSTRUCTION) IN ('Concrete', 'Other')                  THEN 'MAPPED_OK'
        WHEN UPPER(TRIM(FLOORCONSTRUCTION)) LIKE 'WOOD - CONCRETE%'            THEN 'MAPPED_OK'
        WHEN UPPER(TRIM(FLOORCONSTRUCTION)) LIKE 'WOOD - STILTS%'              THEN 'MAPPED_OK'
        WHEN UPPER(TRIM(FLOORCONSTRUCTION)) LIKE 'WOOD - STUMPS%'              THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(FLOORCONSTRUCTION), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3D  ·  HOWOCCUPPIED  (HomeBuildingOccupied) ──────────────────────────────
-- Source  : Locationdetails_PER.HOWOCCUPPIED  (via PER_RISK_BUILDING_FINAL, Seq 14)
-- PL101   : NOT required  |  DCT codes: OwnerOccupied | HolidayHome |
--            OwnedleasedtoOthersLongTermLease | OwnedLeasedtoOthersShortTermRental | TenantedbyMember
-- Note    : Case and hyphens are significant — DCT rejects wrong case
SELECT
    '3D · HOWOCCUPPIED  [Seq 14, not mandatory]'                                AS SECTION,
    'Locationdetails_PER → HOWOCCUPPIED'                                       AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(HOWOCCUPPIED), ''), '(blank)')                         AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(HOWOCCUPPIED), '') IS NULL                             THEN 'BLANK'
        WHEN TRIM(HOWOCCUPPIED) IN (
             'Owner Occupied','Tenanted by member','Holiday Home',
             'Owned leased to Others - Long Term Lease',
             'Owned leased to Others - Short Term Rental')                       THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(HOWOCCUPPIED), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3E  ·  ALARMSYSTEMINSTALLED ──────────────────────────────────────────────
-- Source  : Locationdetails_PER.ALARMSYSTEMINSTALLED  (via PER_RISK_BUILDING_FINAL, Seq 14)
-- PL101   : NOT required  |  DCT codes: LocalAudibleOnly | MonitoredBacktobase |
--            MonitoredSecurity | MonitoredToMobilePhone | None
-- Known issues: 'Local - Monitored' and 'Mobile Mechanic - No base location' NOT in PL101
--               → pass through as-is; client decision needed (Q3 in PP discussion doc)
SELECT
    '3E · ALARMSYSTEMINSTALLED  [Seq 14, not mandatory]'                        AS SECTION,
    'Locationdetails_PER → ALARMSYSTEMINSTALLED_FINAL'                         AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(ALARMSYSTEMINSTALLED), ''), '(blank)')                 AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(ALARMSYSTEMINSTALLED), '') IS NULL                     THEN 'BLANK'
        WHEN TRIM(ALARMSYSTEMINSTALLED) IN (
             'Local - Audible Only','Monitored - Back to base',
             'Monitored - Security','Monitored - To Mobile Phone','None')        THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(ALARMSYSTEMINSTALLED), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3F  ·  DEADLOCKSINSTALLED ────────────────────────────────────────────────
-- Source  : Locationdetails_PER.DEADLOCKSINSTALLED  (via PER_RISK_BUILDING_FINAL, Seq 14)
-- PL101   : NOT required  |  DCT codes: AllDoors | SomeDoors | None
-- Known issue: 'Other' is NOT in PL101 → client decision needed (Q4 in PP discussion doc)
SELECT
    '3F · DEADLOCKSINSTALLED  [Seq 14, not mandatory]'                          AS SECTION,
    'Locationdetails_PER → DEADLOCKSINSTALLED_FINAL'                           AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(DEADLOCKSINSTALLED), ''), '(blank)')                   AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(DEADLOCKSINSTALLED), '') IS NULL                       THEN 'BLANK'
        WHEN TRIM(DEADLOCKSINSTALLED) IN ('All doors','Some doors','None')      THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(DEADLOCKSINSTALLED), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3G  ·  GRILLKEYLOCKINSTALLED ─────────────────────────────────────────────
-- Source  : Locationdetails_PER.GRILLKEYLOCKINSTALLED  (via PER_RISK_BUILDING_FINAL, Seq 14)
-- PL101   : NOT required  |  DCT codes: AllWindows | SomeWindows | None
-- Known issue: 'Other' is NOT in PL101 → client decision needed (Q4 in PP discussion doc)
SELECT
    '3G · GRILLKEYLOCKINSTALLED  [Seq 14, not mandatory]'                       AS SECTION,
    'Locationdetails_PER → GRILLKEYLOCKINSTALLED_FINAL'                        AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(GRILLKEYLOCKINSTALLED), ''), '(blank)')                AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(L.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(GRILLKEYLOCKINSTALLED), '') IS NULL                    THEN 'BLANK'
        WHEN TRIM(GRILLKEYLOCKINSTALLED) IN ('All windows','Some windows','None') THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.Locationdetails_PER L
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE L.EFFECTIVEDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(GRILLKEYLOCKINSTALLED), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3H  ·  PROTECTIONTYPE  (motor) ───────────────────────────────────────────
-- Source  : PM_03.PROTECTIONTYPE  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : NOT required but essential for pricing  |
--   DCT codes: ComprehensiveMarket | ComprehensiveAgreedValue | FireandTheft |
--              Comprehensive | ThirdPartyFireandTheft | ThirdPartyOnly
-- Fixed bug: 'Comprehensive' was mapped to 'FullComprehensive' in old deployed view
--            (FullComprehensive does NOT exist in PL101). Fixed in current repo code.
SELECT
    '3H · PROTECTIONTYPE  [Seq 18, motor]'                                      AS SECTION,
    'PM_03 → PROTECTIONTYPE (via PER_COM_PAYLOAD)'                             AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(PROTECTIONTYPE), ''), '(blank)')                       AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(PROTECTIONTYPE), '') IS NULL                           THEN 'BLANK'
        WHEN TRIM(PROTECTIONTYPE) IN (
             'Comprehensive - Market Value','Comprehensive - Agreed Value',
             'Fire and Theft','Comprehensive',
             'Third Party Only','Third Party, Fire and Theft')                   THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(PROTECTIONTYPE), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3I  ·  VEHICLETYPE  (motor) ──────────────────────────────────────────────
-- Source  : PM_03.VEHICLETYPE  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : NOT required  |
--   DCT codes (13): PassengerVehicle | CamperVan | Caravan | Forklift | Motorcycle |
--     Trailer | LightCommercial | HeavyCommercial | MobileEquipment | TowTruck |
--     Transporter | HeavyVehicle | Tractor
-- Blank handling: 32 policies have no VehicleType → view defaults to 'PassengerVehicle' (client to confirm)
SELECT
    '3I · VEHICLETYPE  [Seq 18, motor]'                                         AS SECTION,
    'PM_03 → VEHICLETYPE (via PER_COM_PAYLOAD)'                                AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(VEHICLETYPE), ''), '(blank → defaults to PassengerVehicle)') AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN P.VEHICLETYPE IS NULL OR TRIM(P.VEHICLETYPE) = ''                 THEN 'BLANK → PassengerVehicle (client to confirm)'
        WHEN TRIM(P.VEHICLETYPE) IN (
             'Passenger Vehicle','Camper Van','Caravan','Forklift','Motorcycle',
             'Trailer','Light Commercial','Heavy Commercial','Mobile Equipment',
             'Tow Truck','Transporter','Heavy Vehicle','Tractor')                THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY
    COALESCE(NULLIF(TRIM(VEHICLETYPE), ''), '(blank → defaults to PassengerVehicle)'),
    STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3J  ·  INDUCTIONTYPE  (motor) ────────────────────────────────────────────
-- Source  : PM_03.INDUCTIONTYPE  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : NOT required  |  DCT codes: Aspirated | Supercharged | Turbocharged | TurboandSupercharged
-- Note    : Multiple source variants map to the same DCT code (e.g. Turbo/Turbo Intercooled → Turbocharged)
SELECT
    '3J · INDUCTIONTYPE  [Seq 18, motor]'                                       AS SECTION,
    'PM_03 → INDUCTIONTYPE (via PER_COM_PAYLOAD)'                              AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(INDUCTIONTYPE), ''), '(blank)')                        AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(INDUCTIONTYPE), '') IS NULL                            THEN 'BLANK'
        WHEN TRIM(INDUCTIONTYPE) IN (
             'Aspirated',
             'Supercharged Intercooled','Twin Supercharged Intercooled','Supercharged',
             'Turbo','Turbo Intercooled','Twin Turbo Intercooled',
             'Triple Turbo Intercooled','Quad Turbo Intercooled',
             'Turbo Supercharged Intercooled')                                   THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S
    ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(INDUCTIONTYPE), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3K  ·  MINIMUMRENTALPERIOD  (HB coverage) ────────────────────────────────
-- Source  : HB_02.MINIMUMRENTALPERIOD  (via PER_HOME_BUILDING_PAYLOAD, Seq 7)
-- PL101   : Conditional (only relevant for landlord / tenanted occupancy)
--   DCT codes: Morethan90Days | Lessthan90Days
SELECT
    '3K · MINIMUMRENTALPERIOD  [Seq 7, HB conditional]'                         AS SECTION,
    'HB_02 → MINIMUMRENTALPERIOD (via PER_HOME_BUILDING_PAYLOAD)'              AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(MINIMUMRENTALPERIOD), ''), '(blank)')                  AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(PUREPOLICYNUMBER))                                      AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(MINIMUMRENTALPERIOD), '') IS NULL                      THEN 'BLANK'
        WHEN TRIM(MINIMUMRENTALPERIOD) IN ('More than 90 Days','Less than 90 Days') THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.HB_02
GROUP BY COALESCE(NULLIF(TRIM(MINIMUMRENTALPERIOD), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3L  ·  UNSPECIFIEDITEMSAWAYLIMIT  (HC coverage) ──────────────────────────
-- Source  : HC_02.UNSPECIFIEDITEMSAWAYLIMIT  (via PER_HOME_BUILDING_PAYLOAD, Seq 13)
-- PL101   : Conditional  |  DCT codes: 2000peritemupto10000perevent | 1250peritemupto5000perevent
SELECT
    '3L · UNSPECIFIEDITEMSAWAYLIMIT  [Seq 13, HC conditional]'                  AS SECTION,
    'HC_02 → UNSPECIFIEDITEMSAWAYLIMIT (via PER_HOME_BUILDING_PAYLOAD)'        AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(UNSPECIFIEDITEMSAWAYLIMIT), ''), '(blank)')             AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(PUREPOLICYNUMBER))                                      AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(UNSPECIFIEDITEMSAWAYLIMIT), '') IS NULL                THEN 'BLANK'
        WHEN TRIM(UNSPECIFIEDITEMSAWAYLIMIT) IN (
             '$2,000 per item up to $10,000 per event',
             '$1,250 per item up to $5,000 per event')                           THEN 'MAPPED_OK'
        ELSE 'INVALID — needs client mapping'
    END AS STATUS
FROM AGGNE.DEV.HC_02
GROUP BY COALESCE(NULLIF(TRIM(UNSPECIFIEDITEMSAWAYLIMIT), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3M  ·  SPECIFIEDITEMSAWAY / UNSPECIFIEDITEMSAWAY  (HC coverage) ──────────
-- Source  : HC_02  (via PER_HOME_BUILDING_PAYLOAD, Seq 7/13)
-- PL101   : DCT codes: Taken | Not Taken
-- View logic: CASE WHEN x='Taken' THEN 'Taken' ELSE 'Not Taken' — any non-'Taken' → 'Not Taken'
SELECT
    '3M · SPECIFIEDITEMSAWAY + UNSPECIFIEDITEMSAWAY  [Seq 7/13, HC]'            AS SECTION,
    'HC_02 → SPECIFIEDITEMSAWAY / UNSPECIFIEDITEMSAWAY'                        AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(SPECIFIEDITEMSAWAY), ''), '(blank)')                   AS SPECIFIEDITEMSAWAY_SRC,
    COALESCE(NULLIF(TRIM(UNSPECIFIEDITEMSAWAY), ''), '(blank)')                 AS UNSPECIFIEDITEMSAWAY_SRC,
    COUNT(DISTINCT TRIM(PUREPOLICYNUMBER))                                      AS POLICY_COUNT
FROM AGGNE.DEV.HC_02
GROUP BY
    COALESCE(NULLIF(TRIM(SPECIFIEDITEMSAWAY), ''), '(blank)'),
    COALESCE(NULLIF(TRIM(UNSPECIFIEDITEMSAWAY), ''), '(blank)')
ORDER BY POLICY_COUNT DESC;


-- ── 3N  ·  HIRECARHIREAFTERINCIDENT  (motor) ─────────────────────────────────
-- Source  : PM_03.HIRECARHIREAFTERINCIDENT  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : DCT codes: Taken | NotTaken
-- View logic: 'Taken' → 'Taken'; anything else (incl. blank) → 'NotTaken'
SELECT
    '3N · HIRECARHIREAFTERINCIDENT  [Seq 18, motor]'                            AS SECTION,
    'PM_03 → HIRECARHIREAFTERINCIDENT (via PER_COM_PAYLOAD)'                   AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(HIRECARHIREAFTERINCIDENT), ''), '(blank)')             AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(HIRECARHIREAFTERINCIDENT), '') IS NULL                 THEN 'BLANK → NotTaken'
        WHEN TRIM(HIRECARHIREAFTERINCIDENT) = 'Taken'                          THEN 'MAPPED_OK'
        ELSE 'OTHER → NotTaken (acceptable; review if unexpected value)'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(HIRECARHIREAFTERINCIDENT), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3O  ·  BODYTYPE  (motor) ─────────────────────────────────────────────────
-- Source  : PM_03.BODYTYPE  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : Free-text / RedBook field — no strict DCT enum constraint
-- View logic: 34 CASE branches map to camelCase; ELSE → '' (blank, not invalid)
-- This check surfaces any values falling to ELSE (which will be blank in XML)
SELECT
    '3O · BODYTYPE  [Seq 18, motor — free text]'                                AS SECTION,
    'PM_03 → BODYTYPE (via PER_COM_PAYLOAD)'                                   AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(BODYTYPE), ''), '(blank)')                             AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(BODYTYPE), '') IS NULL                                 THEN 'BLANK'
        WHEN TRIM(BODYTYPE) IN (
             'B-double','Bus','Bus Chassis','Cab Chassis','Cabriolet','Compactor',
             'Convertible','Coupe','Distributor','Dump','Extra Heavy Duty','Fastback',
             'Hardtop','Hatchback','Heavy Duty','Highway','Liftback','Limousine',
             'Mixer','Prime Mover','Rigid','Road Train','Roadster','Sedan','Softtop',
             'Street Sweeper','Targa','Tipper','Trailer','Traytop','Utility',
             'Van','Van Wagon','Wagon')                                          THEN 'MAPPED_OK'
        ELSE 'UNMAPPED → blank in XML (no PL101 enum; note for reference only)'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(BODYTYPE), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3P  ·  RESTRICTIONOFDRIVERAGE  (motor) ───────────────────────────────────
-- Source  : PM_03.RESTRICTIONOFDRIVERAGE  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : Numeric value (minimum driver age); not a string dropdown
-- View logic: 'No Restriction'→0, 'Min Age 21'→20, 'Min Age 25'→24,
--             'Min Age 30'→29, 'Min Age 40'→39; ELSE → 0 (default)
SELECT
    '3P · RESTRICTIONOFDRIVERAGE  [Seq 18, motor]'                              AS SECTION,
    'PM_03 → RESTRICTIONOFDRIVERAGE (via PER_COM_PAYLOAD)'                     AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(RESTRICTIONOFDRIVERAGE), ''), '(blank)')               AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(RESTRICTIONOFDRIVERAGE), '') IS NULL                   THEN 'BLANK → 0 (No Restriction)'
        WHEN TRIM(RESTRICTIONOFDRIVERAGE) IN (
             'No Restriction','Min Age 21','Min Age 25','Min Age 30','Min Age 40') THEN 'MAPPED_OK'
        ELSE 'UNMAPPED → defaults to 0 (review)'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(RESTRICTIONOFDRIVERAGE), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3Q  ·  MVADDACCORMODS  (motor — accessories/modifications flag) ───────────
-- Source  : PM_03.MVADDACCORMODS  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : Boolean / flag  |  DCT values: Yes | No
-- View logic: 'Yes' → 'Yes'; anything else → 'No'
SELECT
    '3Q · MVADDACCORMODS  [Seq 18, motor]'                                      AS SECTION,
    'PM_03 → MVADDACCORMODS (via PER_COM_PAYLOAD)'                             AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(CAST(MVADDACCORMODS AS VARCHAR)), ''), '(blank)')      AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(CAST(MVADDACCORMODS AS VARCHAR)), '') IS NULL          THEN 'BLANK → No'
        WHEN TRIM(CAST(MVADDACCORMODS AS VARCHAR)) = 'Yes'                      THEN 'MAPPED_OK'
        ELSE 'OTHER → No (acceptable default)'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(CAST(MVADDACCORMODS AS VARCHAR)), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3R  ·  VEHHAVEANINTERESTEDPARTY  (motor) ─────────────────────────────────
-- Source  : PM_03.VEHHAVEANINTERESTEDPARTY  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : Boolean  |  DCT value: 1 (Yes) or 0 (No)
-- View logic: 'Yes' → '1'; anything else → '0'
SELECT
    '3R · VEHHAVEANINTERESTEDPARTY  [Seq 18, motor]'                            AS SECTION,
    'PM_03 → VEHHAVEANINTERESTEDPARTY (via PER_COM_PAYLOAD)'                   AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(CAST(VEHHAVEANINTERESTEDPARTY AS VARCHAR)), ''), '(blank)') AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(CAST(VEHHAVEANINTERESTEDPARTY AS VARCHAR)), '') IS NULL THEN 'BLANK → 0'
        WHEN TRIM(CAST(VEHHAVEANINTERESTEDPARTY AS VARCHAR)) IN ('Yes','No')    THEN 'MAPPED_OK'
        ELSE 'UNEXPECTED — review'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(CAST(VEHHAVEANINTERESTEDPARTY AS VARCHAR)), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3S  ·  ACCIDENTALLOSSORDAMAGE  (HB/HC building coverage) ──────────────────
-- Source  : HC_02.ACCIDENTALLOSSORDAMAGE  (via PER_HOME_BUILDING_PAYLOAD, Seq 7/13)
--           Also HB_01.ACCIDENTALLOSSORDAMAGE for HB-only policies
-- PL101   : Boolean  |  View converts raw 'Taken'/'Not Taken' → '1'/'0'
-- Check   : Flag any values that are neither 'Taken' nor 'Not Taken'
SELECT
    '3S · ACCIDENTALLOSSORDAMAGE  [Seq 7/13, HB/HC]'                            AS SECTION,
    'HC_02 / HB_01 → ACCIDENTALLOSSORDAMAGE (via PER_HOME_BUILDING_PAYLOAD)'   AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(ACCIDENTALLOSSORDAMAGE), ''), '(blank)')               AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(PUREPOLICYNUMBER))                                      AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(ACCIDENTALLOSSORDAMAGE), '') IS NULL                   THEN 'BLANK → 0'
        WHEN TRIM(ACCIDENTALLOSSORDAMAGE) = 'Taken'                            THEN 'MAPPED_OK → 1'
        WHEN TRIM(ACCIDENTALLOSSORDAMAGE) = 'Not Taken'                        THEN 'MAPPED_OK → 0'
        ELSE 'UNEXPECTED — review'
    END AS STATUS
FROM AGGNE.DEV.HC_02
GROUP BY COALESCE(NULLIF(TRIM(ACCIDENTALLOSSORDAMAGE), ''), '(blank)'), STATUS

UNION ALL

SELECT
    '3S · ACCIDENTALLOSSORDAMAGE  [Seq 7, HB-only]'                             AS SECTION,
    'HB_01 → ACCIDENTALLOSSORDAMAGE (HB-only branch)'                         AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(ACCIDENTALLOSSORDAMAGE), ''), '(blank)')               AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(PUREPOLICYNUMBER))                                      AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(ACCIDENTALLOSSORDAMAGE), '') IS NULL                   THEN 'BLANK → 0'
        WHEN TRIM(ACCIDENTALLOSSORDAMAGE) = 'Taken'                            THEN 'MAPPED_OK → 1'
        WHEN TRIM(ACCIDENTALLOSSORDAMAGE) = 'Not Taken'                        THEN 'MAPPED_OK → 0'
        ELSE 'UNEXPECTED — review'
    END AS STATUS
FROM AGGNE.DEV.HB_01
GROUP BY COALESCE(NULLIF(TRIM(ACCIDENTALLOSSORDAMAGE), ''), '(blank)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3T  ·  ANYITEMSEXCEEDVALUE  (HC contents) ────────────────────────────────
-- Source  : HC_02.ANYITEMSEXCEEDVALUE  (via PER_HOME_BUILDING_PAYLOAD, Seq 13)
-- PL101   : Conditional  |  DCT values: Yes | No
-- View logic: COALESCE(ANYITEMSEXCEEDVALUE, 'No') — blank defaults to 'No'
SELECT
    '3T · ANYITEMSEXCEEDVALUE  [Seq 13, HC]'                                    AS SECTION,
    'HC_02 → ANYITEMSEXCEEDVALUE (via PER_HOME_BUILDING_PAYLOAD)'              AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(ANYITEMSEXCEEDVALUE), ''), '(blank → No)')            AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(PUREPOLICYNUMBER))                                      AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(ANYITEMSEXCEEDVALUE), '') IS NULL                      THEN 'BLANK → No (default)'
        WHEN TRIM(ANYITEMSEXCEEDVALUE) IN ('Yes','No')                         THEN 'MAPPED_OK'
        ELSE 'UNEXPECTED — review'
    END AS STATUS
FROM AGGNE.DEV.HC_02
GROUP BY COALESCE(NULLIF(TRIM(ANYITEMSEXCEEDVALUE), ''), '(blank → No)'), STATUS
ORDER BY STATUS, POLICY_COUNT DESC;


-- ── 3U  ·  CHOICEOFREPAIR + EXCESSWAIVERFORGLASS  (motor flags) ──────────────
-- Source  : PM_03  (via PER_COM_PAYLOAD, Seq 18)
-- PL101   : CHOICEOFREPAIR → '1'/'0';  EXCESSWAIVERFORGLASS → 1/0
-- View logic: 'Taken'→'1'; else→'0' for CHOICEOFREPAIR
--             'Yes'→1; else→0 for EXCESSWAIVERFORGLASS
SELECT
    '3U · CHOICEOFREPAIR  [Seq 18, motor]'                                      AS SECTION,
    'PM_03 → CHOICEOFREPAIR'                                                   AS SOURCE_COLUMN,
    COALESCE(NULLIF(TRIM(CHOICEOFREPAIR), ''), '(blank)')                       AS SOURCE_VALUE,
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER))                                    AS POLICY_COUNT,
    CASE
        WHEN NULLIF(TRIM(CHOICEOFREPAIR), '') IS NULL                           THEN 'BLANK → 0'
        WHEN TRIM(CHOICEOFREPAIR) IN ('Taken','Not Taken')                     THEN 'MAPPED_OK'
        ELSE 'UNEXPECTED — review'
    END AS STATUS
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY COALESCE(NULLIF(TRIM(CHOICEOFREPAIR), ''), '(blank)'), STATUS

UNION ALL

SELECT
    '3U · EXCESSWAIVERFORGLASS  [Seq 18, motor]',
    'PM_03 → EXCESSWAIVERFORGLASS',
    COALESCE(NULLIF(TRIM(CAST(EXCESSWAIVERFORGLASS AS VARCHAR)), ''), '(blank)'),
    COUNT(DISTINCT TRIM(P.PUREPOLICYNUMBER)),
    CASE
        WHEN NULLIF(TRIM(CAST(EXCESSWAIVERFORGLASS AS VARCHAR)), '') IS NULL    THEN 'BLANK → 0'
        WHEN TRIM(CAST(EXCESSWAIVERFORGLASS AS VARCHAR)) IN ('Yes','No')       THEN 'MAPPED_OK'
        ELSE 'UNEXPECTED — review'
    END
FROM AGGNE.DEV.PM_03 P
INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
WHERE P.EXPIRYDATE >= '2026-01-01'
GROUP BY
    COALESCE(NULLIF(TRIM(CAST(EXCESSWAIVERFORGLASS AS VARCHAR)), ''), '(blank)'),
    CASE
        WHEN NULLIF(TRIM(CAST(EXCESSWAIVERFORGLASS AS VARCHAR)), '') IS NULL    THEN 'BLANK → 0'
        WHEN TRIM(CAST(EXCESSWAIVERFORGLASS AS VARCHAR)) IN ('Yes','No')       THEN 'MAPPED_OK'
        ELSE 'UNEXPECTED — review'
    END
ORDER BY STATUS, POLICY_COUNT DESC;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 4  ·  LENGTH VIOLATIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Check whether source text values exceed the PL101 maxLength constraint.
-- PL101 maxLength values sourced from Carrier_PersonalProtectionBase_1_0_0_0.xml.
-- FIX: all column references qualified with table alias to avoid ambiguous column
--      error when SAMPLE_PER shares a column name with the source table.
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT FIELD, SOURCE_TABLE, PL101_MAX_LEN, MAX_OBSERVED_LEN,
    CASE WHEN MAX_OBSERVED_LEN > PL101_MAX_LEN THEN 'VIOLATION' ELSE 'OK' END AS LENGTH_STATUS,
    POLICIES_EXCEEDING
FROM (

    -- Address1 (PL101 maxLength: 100)
    -- Source: Locationdetails_PER.ADDRESS1  [Seq 3]
    SELECT 'ADDRESS1' AS FIELD, 'Locationdetails_PER' AS SOURCE_TABLE, 100 AS PL101_MAX_LEN,
        MAX(LEN(TRIM(L.ADDRESS1))) AS MAX_OBSERVED_LEN,
        SUM(CASE WHEN LEN(TRIM(L.ADDRESS1)) > 100 THEN 1 ELSE 0 END) AS POLICIES_EXCEEDING
    FROM AGGNE.DEV.Locationdetails_PER L
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE L.EFFECTIVEDATE >= '2026-01-01'

    UNION ALL

    -- Suburb / City (PL101 maxLength: 100)
    -- Source: Locationdetails_PER.SUBURB  [Seq 3]
    SELECT 'SUBURB (City)', 'Locationdetails_PER', 100,
        MAX(LEN(TRIM(L.SUBURB))),
        SUM(CASE WHEN LEN(TRIM(L.SUBURB)) > 100 THEN 1 ELSE 0 END)
    FROM AGGNE.DEV.Locationdetails_PER L
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE L.EFFECTIVEDATE >= '2026-01-01'

    UNION ALL

    -- POSTCODE (PL101 maxLength: 10)
    -- Source: Locationdetails_PER.POSTCODE  [Seq 3]
    SELECT 'POSTCODE', 'Locationdetails_PER', 10,
        MAX(LEN(TRIM(CAST(L.POSTCODE AS VARCHAR)))),
        SUM(CASE WHEN LEN(TRIM(CAST(L.POSTCODE AS VARCHAR))) > 10 THEN 1 ELSE 0 END)
    FROM AGGNE.DEV.Locationdetails_PER L
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE L.EFFECTIVEDATE >= '2026-01-01'

    UNION ALL

    -- SecurityDetails free-text (PL101 maxLength: 500)
    -- Source: Locationdetails_PER.SECURITYDETAILS  [Seq 14]
    SELECT 'SECURITYDETAILS', 'Locationdetails_PER', 500,
        MAX(LEN(TRIM(L.SECURITYDETAILS))),
        SUM(CASE WHEN LEN(TRIM(L.SECURITYDETAILS)) > 500 THEN 1 ELSE 0 END)
    FROM AGGNE.DEV.Locationdetails_PER L
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(L.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE L.EFFECTIVEDATE >= '2026-01-01'

    UNION ALL

    -- Motor: REGISTRATIONNUMBER (PL101 maxLength: 20)
    -- Source: PM_03.REGISTRATIONNUMBER  [Seq 18]
    SELECT 'REGISTRATIONNUMBER', 'PM_03', 20,
        MAX(LEN(TRIM(P.REGISTRATIONNUMBER))),
        SUM(CASE WHEN LEN(TRIM(P.REGISTRATIONNUMBER)) > 20 THEN 1 ELSE 0 END)
    FROM AGGNE.DEV.PM_03 P
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE P.EXPIRYDATE >= '2026-01-01'

    UNION ALL

    -- Motor: MAKE (PL101 maxLength: 50)
    -- Source: PM_03.MAKE  [Seq 18]
    SELECT 'MAKE', 'PM_03', 50,
        MAX(LEN(TRIM(P.MAKE))),
        SUM(CASE WHEN LEN(TRIM(P.MAKE)) > 50 THEN 1 ELSE 0 END)
    FROM AGGNE.DEV.PM_03 P
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE P.EXPIRYDATE >= '2026-01-01'

    UNION ALL

    -- Motor: MODEL (PL101 maxLength: 100)
    -- Source: PM_03.MODEL  [Seq 18]
    SELECT 'MODEL', 'PM_03', 100,
        MAX(LEN(TRIM(P.MODEL))),
        SUM(CASE WHEN LEN(TRIM(P.MODEL)) > 100 THEN 1 ELSE 0 END)
    FROM AGGNE.DEV.PM_03 P
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE P.EXPIRYDATE >= '2026-01-01'

    UNION ALL

    -- Motor: vehicle DESCRIPTION (PL101 maxLength: 200)
    -- Source: PM_03.DESCRIPTION  [Seq 18]
    SELECT 'VEHICLE DESCRIPTION', 'PM_03', 200,
        MAX(LEN(TRIM(P.DESCRIPTION))),
        SUM(CASE WHEN LEN(TRIM(P.DESCRIPTION)) > 200 THEN 1 ELSE 0 END)
    FROM AGGNE.DEV.PM_03 P
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE P.EXPIRYDATE >= '2026-01-01'

    UNION ALL

    -- Motor: ADDDETAILSFORTHEINTERESTEDPARTY (free text — PL101 maxLength: 500)
    -- Source: PM_03.ADDDETAILSFORTHEINTERESTEDPARTY  [Seq 18]
    SELECT 'INTERESTED_PARTY_DETAILS', 'PM_03', 500,
        MAX(LEN(TRIM(P.ADDDETAILSFORTHEINTERESTEDPARTY))),
        SUM(CASE WHEN LEN(TRIM(P.ADDDETAILSFORTHEINTERESTEDPARTY)) > 500 THEN 1 ELSE 0 END)
    FROM AGGNE.DEV.PM_03 P
    INNER JOIN AGGNE.DEV.SAMPLE_PER S ON TRIM(P.PUREPOLICYNUMBER) = TRIM(S.PUREPOLICYNUMBER)
    WHERE P.EXPIRYDATE >= '2026-01-01'

) t
ORDER BY LENGTH_STATUS DESC, FIELD;


-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 5  ·  POLICY-LEVEL GAP MATRIX
-- ─────────────────────────────────────────────────────────────────────────────
-- One row per policy showing OK / BLANK / INVALID for each key field.
-- Mirrors the pattern of BP_GAP_ANALYSIS.sql but at field level (not section level).
-- Useful for: identifying specific policies to fix or exclude before final attach.
-- ═══════════════════════════════════════════════════════════════════════════════

WITH

-- Scope: all policies
all_policies AS (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY
    FROM AGGNE.DEV.SAMPLE_PER
),

-- Building source (latest effective)
building AS (
    SELECT DISTINCT
        TRIM(PUREPOLICYNUMBER)       AS POLICY,
        TRIM(ROOFCONSTRUCTION)       AS ROOF,
        TRIM(MAINWALLCONSTRUCTION)   AS MAINWALL,
        TRIM(FLOORCONSTRUCTION)      AS FLOOR,
        TRIM(HOWOCCUPPIED)           AS OCCUPIED,
        TRIM(ALARMSYSTEMINSTALLED)   AS ALARM,
        TRIM(DEADLOCKSINSTALLED)     AS DEADLOCKS,
        TRIM(GRILLKEYLOCKINSTALLED)  AS GRILLS,
        TRIM(ADDRESS1)               AS ADDR1,
        TRIM(STATE)                  AS STATE
    FROM AGGNE.DEV.Locationdetails_PER
    WHERE EFFECTIVEDATE >= '2026-01-01'
),

-- Motor source (active vehicles only)
motor AS (
    SELECT DISTINCT
        TRIM(PUREPOLICYNUMBER)   AS POLICY,
        TRIM(PROTECTIONTYPE)     AS PROT_TYPE,
        TRIM(VEHICLETYPE)        AS VEH_TYPE,
        TRIM(MVRBVEHICLEKEY)     AS REDBOOK
    FROM AGGNE.DEV.PM_03
    WHERE EXPIRYDATE >= '2026-01-01'
      AND YEAR <> 0
      AND TRIM(MAKE) <> ''
      AND TRIM(MODEL) <> ''
)

SELECT
    p.POLICY,

    -- ── Section presence ────────────────────────────────────────────────────
    CASE WHEN b.POLICY IS NOT NULL THEN 'Y' ELSE 'N' END        AS HAS_BUILDING,
    CASE WHEN m.POLICY IS NOT NULL THEN 'Y' ELSE 'N' END        AS HAS_MOTOR,

    -- ── Address (Seq 3) ─────────────────────────────────────────────────────
    -- Source: Locationdetails_PER.ADDRESS1 → template {ADDRESS1}
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.ADDR1, '') IS NULL            THEN 'BLANK'
        ELSE 'OK'
    END AS ADDRESS1,

    -- Source: Locationdetails_PER.STATE → template {STATE} (with AU suffix for Australia)
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.STATE, '') IS NULL            THEN 'BLANK'
        ELSE 'OK'
    END AS STATE,

    -- ── Building construction (Seq 14, mandatory) ───────────────────────────
    -- Source: Locationdetails_PER.ROOFCONSTRUCTION → PER_RISK_BUILDING_FINAL.ROOFCONSTRUCTION_FINAL
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.ROOF, '') IS NULL             THEN 'BLANK'
        WHEN b.ROOF IN ('Asbestos','Concrete','Concrete (Flat Roof)','Iron',
                        'Iron/Steel/Tin','Tin','Tile','Wood','Wood (Shingles)')  THEN 'OK'
        WHEN b.ROOF ILIKE '%colorbond%'
          OR b.ROOF ILIKE '%colourbond%'                                        THEN 'OK'
        ELSE 'INVALID'
    END AS ROOFCONSTRUCTION,

    -- Source: Locationdetails_PER.MAINWALLCONSTRUCTION → MAINWALLCONSTRUCTION_FINAL
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.MAINWALL, '') IS NULL         THEN 'BLANK'
        WHEN b.MAINWALL IN ('Asbestos','Brick Veneer','Concrete','Double Brick',
                            'Fibro (Non-Asbestos)','Fibro/Hardiplank',
                            'Iron','Iron/Steel','Wood')                          THEN 'OK'
        ELSE 'INVALID'
    END AS MAINWALLCONSTRUCTION,

    -- Source: Locationdetails_PER.FLOORCONSTRUCTION → FLOORCONSTRUCTION_FINAL
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.FLOOR, '') IS NULL            THEN 'BLANK'
        WHEN b.FLOOR IN ('Concrete','Other')
          OR UPPER(b.FLOOR) LIKE 'WOOD - %'                                     THEN 'OK'
        ELSE 'INVALID'
    END AS FLOORCONSTRUCTION,

    -- ── Building security/occupancy (Seq 14, not mandatory) ─────────────────
    -- Source: Locationdetails_PER.ALARMSYSTEMINSTALLED → ALARMSYSTEMINSTALLED_FINAL
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.ALARM, '') IS NULL            THEN 'BLANK'
        WHEN b.ALARM IN ('Local - Audible Only','Monitored - Back to base',
                         'Monitored - Security','Monitored - To Mobile Phone','None') THEN 'OK'
        ELSE 'INVALID'
    END AS ALARMSYSTEM,

    -- Source: Locationdetails_PER.DEADLOCKSINSTALLED → DEADLOCKSINSTALLED_FINAL
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.DEADLOCKS, '') IS NULL        THEN 'BLANK'
        WHEN b.DEADLOCKS IN ('All doors','Some doors','None')                   THEN 'OK'
        ELSE 'INVALID'
    END AS DEADLOCKS,

    -- Source: Locationdetails_PER.GRILLKEYLOCKINSTALLED → GRILLKEYLOCKINSTALLED_FINAL
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.GRILLS, '') IS NULL           THEN 'BLANK'
        WHEN b.GRILLS IN ('All windows','Some windows','None')                  THEN 'OK'
        ELSE 'INVALID'
    END AS GRILLS,

    -- Source: Locationdetails_PER.HOWOCCUPPIED → HOWOCCUPPIED
    CASE
        WHEN b.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(b.OCCUPIED, '') IS NULL         THEN 'BLANK'
        WHEN b.OCCUPIED IN ('Owner Occupied','Tenanted by member','Holiday Home',
             'Owned leased to Others - Long Term Lease',
             'Owned leased to Others - Short Term Rental')                       THEN 'OK'
        ELSE 'INVALID'
    END AS OCCUPIED,

    -- ── Motor fields (Seq 18) ───────────────────────────────────────────────
    -- Source: PM_03.PROTECTIONTYPE → PROTECTIONTYPE (DCT code)
    CASE
        WHEN m.POLICY IS NULL                       THEN 'N/A'
        WHEN NULLIF(m.PROT_TYPE, '') IS NULL        THEN 'BLANK'
        WHEN m.PROT_TYPE IN ('Comprehensive - Market Value','Comprehensive - Agreed Value',
             'Fire and Theft','Comprehensive',
             'Third Party Only','Third Party, Fire and Theft')                   THEN 'OK'
        ELSE 'INVALID'
    END AS PROTECTIONTYPE,

    -- Source: PM_03.VEHICLETYPE → VEHICLETYPE (blank → PassengerVehicle default)
    CASE
        WHEN m.POLICY IS NULL                       THEN 'N/A'
        WHEN m.VEH_TYPE IS NULL OR m.VEH_TYPE = '' THEN 'BLANK→PassengerVehicle'
        WHEN m.VEH_TYPE IN ('Passenger Vehicle','Camper Van','Caravan','Forklift',
             'Motorcycle','Trailer','Light Commercial','Heavy Commercial',
             'Mobile Equipment','Tow Truck','Transporter','Heavy Vehicle','Tractor') THEN 'OK'
        ELSE 'INVALID'
    END AS VEHICLETYPE,

    -- Source: PM_03.MVRBVEHICLEKEY → OVERRIDE (VehicleInfoOverride): 1 if key exists, 0 if not
    CASE
        WHEN m.POLICY IS NULL                       THEN 'N/A'
        WHEN m.REDBOOK IS NOT NULL AND m.REDBOOK <> '' THEN 'HAS_REDBOOK (OVERRIDE=1)'
        ELSE 'NO_REDBOOK (OVERRIDE=0 → DCT lookup)'
    END AS VEHICLEINFO_OVERRIDE,

    -- ── Summary gap count ────────────────────────────────────────────────────
    (
        CASE WHEN b.POLICY IS NOT NULL AND NULLIF(b.ROOF, '') IS NULL THEN 1 ELSE 0 END
      + CASE WHEN b.POLICY IS NOT NULL AND NULLIF(b.ROOF, '') IS NOT NULL
               AND b.ROOF NOT IN ('Asbestos','Concrete','Concrete (Flat Roof)','Iron',
                   'Iron/Steel/Tin','Tin','Tile','Wood','Wood (Shingles)')
               AND NOT (b.ROOF ILIKE '%colorbond%' OR b.ROOF ILIKE '%colourbond%') THEN 1 ELSE 0 END
      + CASE WHEN b.POLICY IS NOT NULL AND NULLIF(b.MAINWALL, '') IS NULL THEN 1 ELSE 0 END
      + CASE WHEN b.POLICY IS NOT NULL AND NULLIF(b.MAINWALL, '') IS NOT NULL
               AND b.MAINWALL NOT IN ('Asbestos','Brick Veneer','Concrete','Double Brick',
                   'Fibro (Non-Asbestos)','Fibro/Hardiplank','Iron','Iron/Steel','Wood') THEN 1 ELSE 0 END
      + CASE WHEN b.POLICY IS NOT NULL AND NULLIF(b.FLOOR, '') IS NULL THEN 1 ELSE 0 END
      + CASE WHEN m.POLICY IS NOT NULL AND NULLIF(m.PROT_TYPE, '') IS NULL THEN 1 ELSE 0 END
    ) AS TOTAL_GAPS

FROM all_policies p
LEFT JOIN building b ON p.POLICY = b.POLICY
LEFT JOIN motor    m ON p.POLICY = m.POLICY
ORDER BY TOTAL_GAPS DESC, p.POLICY;
