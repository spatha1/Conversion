-- G-BP-95 REVISED (ATP-11050 + the whole Business Details "turnover/UW" ticket cluster) —
-- Business_Info_01 rewritten to match the client's original SAS reference exactly
-- (SAS/txt/BusinessDetails_conversionscriptCapricorn Corrected V2.txt)
--
-- This SUPERSEDES the first draft of G-BP-95_fix.sql. That draft only fixed the per-field
-- flag-gating (IsX / Details_X / Display_X). Reading the full SAS reference line-by-line
-- (previously only skimmed) surfaced four more real, confirmed deviations. One candidate
-- ("Business_Info_02/Businessdetails_Final join is policy-level, not term-level") was
-- INVESTIGATED AND RETRACTED -- it is a deliberate, faithful match to SAS's own
-- `MERGE ... BY PUREPolicyNumber` design, not a bug. Do not "fix" that.
--
-- ============================================================
-- CONFIRMED DEVIATIONS FROM SAS (this fix addresses all of them):
-- ============================================================
--
-- 1. OUTER GATE MISSING on almost everything. In SAS, Turnover_Less_Fuel's FuelSales-based
--    calc AND every single downstream field (IsWebPage, WebsiteAddress, Management/Engaged,
--    all 8 IsX/Details_X/Display_X groups, the entire Tyre section) live INSIDE one outer
--    `IF IsPropOwnerOnly=0 AND PublicAndProductLiability=1 AND IsRunOffLiab<1 THEN DO ... END`
--    block. The live SP only gates Turnover_Less_Fuel by this condition -- every other field
--    is computed unconditionally (gated only by its own IsX flag, if at all). Live impact:
--    5,968 of 20,949 rows (28.5%) fail this outer gate and should have the WHOLE Business
--    Details section blank, not just the fields with their own flag off.
--
-- 2. Turnover_Less_Fuel vs Turnover in all 14 Display formulas (8 field groups + 6 Tyre) --
--    already flagged by the user, confirmed real. SAS uses Turnover_Less_Fuel everywhere;
--    the live SP uses plain Turnover.
--
-- 3. Prof/LE/TA substitution fallback missing. When the outer gate is FALSE and
--    SelectANZSICLookup <> '111111 - Property Owners Only', SAS substitutes
--    Turnover_Prof/Turnover_LE/Turnover_TA (whichever of Professional Protection/Legal
--    Expenses/Tax Audit apply, GREATEST() when more than one) into Turnover_Less_Fuel instead
--    of leaving it 0. Confirmed the 3 source columns (TURNOVER_PROF/TURNOVER_LE/TURNOVER_TA)
--    exist in AGGNE.DEV.Sample_CBP_BusinessDetail but were never used anywhere in the live SP.
--
-- 4. Tyre section has no eligibility gate at all. SAS only populates the 6 Tyre %/Display
--    fields when (a) SICCode is one of 23 tyre-related codes OR SelectANZSICLookup is
--    Tyre Retailer/Tyre Franchise, AND (b) RetailOrManufacturerTyres=1.
--    DoYouRetailOrManufacturerTyres itself is blank (not "No") unless condition (a) holds --
--    this is ATP-11133's exact symptom ("always blank on UI but clarity has values" -- the
--    live SP has it backwards: always populated, should be conditionally blank).
--
-- 5. ManIm per-source gating: SAS's 3-block overwrite (Import alone / Manu alone / both)
--    collapses to a clean CASE; the live SP's OR-gated sum could leak a stale ManuDetails
--    value even when only ImportProducts=1 (or vice versa).
--
-- 6. IsUndergroundMining / SidelineBusinessType: SAS leaves these BLANK (not "No"/".") when
--    their parent condition doesn't fire. The live SP defaults IsUndergroundMining to
--    unconditional Yes/No and SidelineBusinessType to unconditional value/'.'.
--
-- 7. High Performance ">30%" rule: SAS blanks VehicleTurnoverDetails_Perf/Display_Perf
--    entirely whenever the computed percentage is <= 30 (`IF ... < 31 THEN ... = .`) -- only
--    ever shows a value when genuinely > 30%. Matches ATP-11066's ticket topic. Not applied
--    to _ACC since SAS's original single merged field only maps cleanly onto the live SP's
--    separate _Perf field -- _ACC's schema-split from SAS is a pre-existing, undocumented
--    engineering decision (DC's target XML very likely needs both as separate fields) that
--    predates this session; not second-guessed here, only the flag-gating/outer-gate/
--    Turnover_Less_Fuel fixes are applied to _ACC, using its own natural source
--    (TurnoverAntiqueClassicCollector), not SAS's literal merge-into-_Perf mechanic.
--
-- ============================================================
-- NOT changed (confirmed correct-by-design, matches SAS or is deliberately safe to diverge):
-- ============================================================
--   - Business_Info_02's policy-level (not term-level) dedup and its join into
--     Businessdetails_Final -- retracted false alarm, see above.
--   - IsWaterWorkPerformed's existing NULL-when-not-applicable logic -- already correct,
--     unchanged.
--   - Gearboxes' `GearboxesDetails>0` condition -- already matches SAS exactly.
--   - SelectANZSICLookup_final's two override branches -- out of scope, unrelated to turnover.
--
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead. Performs
-- CREATE OR REPLACE TABLE against 3 tables other objects depend on downstream
-- (VW_BUSINESS_FINAL, VW_CBP_OUTPUT_CONVERSION) -- read carefully before running. This is a
-- LARGE, HIGH-BLAST-RADIUS change (28.5% of rows go from "some fields populated" to "whole
-- section blank") -- strongly recommend spot-checking several real policies against DC/Clarity
-- before treating this as final, not just trusting the SAS-fidelity argument alone.

-- ============================================================
-- STEP 1: Business_Info_01
-- ============================================================
CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Business_Info_01 AS
WITH BASE AS (
    SELECT DISTINCT
    a.*, b.SelectANZSICLookup, b.SecondaryANZSICLookup
    FROM AGGNE.DEV.Sample_CBP_BusinessDetail a
    LEFT JOIN AGGNE.DEV.ANZSIC_RANK_04 b USING (PUREPolicyNumber)
),
STAGE1 AS (
    SELECT
        BASE.*,
        -- The single outer condition that gates almost the entire section in SAS.
        (IsPropOwnerOnly = 0 AND PublicAndProductLiability = 1 AND COALESCE(IsRunOffLiab,0) < 1) AS OUTER_GATE,
        -- Turnover_Less_Fuel: FuelSales-based when the outer gate holds; otherwise the
        -- Prof/LE/TA substitution fallback (only for non-Property-Owners-Only policies);
        -- otherwise 0. Matches SAS's two sequential IF blocks exactly (the second overwrites
        -- the first's result whenever the outer gate is true).
        CASE
            WHEN IsPropOwnerOnly = 0 AND PublicAndProductLiability = 1 AND COALESCE(IsRunOffLiab,0) < 1 THEN
                CASE WHEN FuelSales = 1 THEN Turnover - (Turnover * FuelSalesPercent / 100)
                     WHEN FuelSales = 0 THEN Turnover
                     ELSE 0 END
            WHEN SelectANZSICLookup <> '111111 - Property Owners Only' THEN
                CASE
                    WHEN ProfessionalProtection=1 AND LegalExpenses=0 AND TaxAudit=0 THEN Turnover_Prof
                    WHEN ProfessionalProtection=0 AND LegalExpenses=1 AND TaxAudit=0 THEN Turnover_LE
                    WHEN ProfessionalProtection=0 AND LegalExpenses=0 AND TaxAudit=1 THEN Turnover_TA
                    WHEN ProfessionalProtection=1 AND LegalExpenses=1 AND TaxAudit=0 THEN GREATEST(COALESCE(Turnover_Prof,0), COALESCE(Turnover_LE,0))
                    WHEN ProfessionalProtection=1 AND LegalExpenses=0 AND TaxAudit=1 THEN GREATEST(COALESCE(Turnover_Prof,0), COALESCE(Turnover_TA,0))
                    WHEN ProfessionalProtection=0 AND LegalExpenses=1 AND TaxAudit=1 THEN GREATEST(COALESCE(Turnover_LE,0), COALESCE(Turnover_TA,0))
                    WHEN ProfessionalProtection=1 AND LegalExpenses=1 AND TaxAudit=1 THEN GREATEST(COALESCE(Turnover_Prof,0), COALESCE(Turnover_LE,0), COALESCE(Turnover_TA,0))
                    ELSE 0
                END
            ELSE 0
        END AS Turnover_Less_Fuel,
        -- Tyre section eligibility (SIC code list is the client's own, from their SAS --
        -- reproduced exactly, including treating "TYR-O"/"DIF-I" as two distinct codes: the
        -- original SAS text has them adjacent with no comma, which is almost certainly a typo
        -- for 23 distinct codes rather than one operator running two codes together).
        (
            SICCode IN ('WCU-O','TAM-O','TRT-C','TRT-O','TYR-P','TYP-O','TYR-F','OZY-O','NAT-T',
                        'KUM-O','JQF-O','TYR-O','DIF-I','HAN-O','HPP-L','GAC-O','DSD-O','CON-C',
                        'CON-T','BRS-O','BRN-O','BJT-O','BEA-O')
            OR SelectANZSICLookup = '532401 - Tyre Retailers and Repairers - excluding Retreading and Remolding'
            OR SelectANZSICLookup = '600003 - Tyre Franchise'
        ) AS TYRE_ELIGIBLE
    FROM BASE
),
STAGE2 AS (
    SELECT
        STAGE1.*,
        -- Raw (pre 30%-cutoff) High Performance detail -- only High Performance's own sources,
        -- unlike SAS's field which also absorbs Antique/Classic when both apply (see header
        -- note on why _ACC stays separate here).
        CASE WHEN OUTER_GATE AND (SalesHighPerformance=1 OR ServiceHighPerformance=1 OR RestoreHighPerformance=1)
             THEN ROUND(TurnoverHighPerformance / NULLIF(Turnover_Less_Fuel,0) * 100) END AS PERF_PCT_RAW
    FROM STAGE1
)
SELECT DISTINCT
    PUREPolicyNumber,
    CMLNumber,
    EXPIRINGID_P,
    SelectANZSICLookup,
    SecondaryANZSICLookup,

    Turnover_Less_Fuel,

    CASE WHEN OUTER_GATE AND IsWebPage_Temp = 1 THEN 'Yes' ELSE 'No' END AS IsWebPage,
    CASE WHEN OUTER_GATE AND IsWebPage_Temp = 1 THEN WebsiteAddress_Temp ELSE '' END AS WebsiteAddress,

    COALESCE(BusinessEstablishmentDate, YEAR(InceptionDate)) AS BusinessEstablishmentDate,
    CASE WHEN OUTER_GATE THEN ManagementProprietorsPartners_ ELSE 0 END AS ManagementProprietorsAndPartners,
    CASE WHEN OUTER_GATE THEN EngagedSalesWorkshopActivities_ + COALESCE(ContractorStaff_,0) ELSE 0 END AS EngagedSalesorWorkshopActivities,

    -- High Performance -- >30% cutoff: SAS blanks Details/Display_Perf whenever the computed
    -- percentage is <= 30 (only ever shown when genuinely more than 30%).
    CASE WHEN PERF_PCT_RAW >= 31 THEN PERF_PCT_RAW END AS VehicleTurnoverDetails_Perf,
    CASE WHEN PERF_PCT_RAW >= 31 THEN ROUND(PERF_PCT_RAW / 100 * Turnover_Less_Fuel) END AS VehicleTurnoverDisplay_Perf,

    -- Antique/Classic Vehicles -- own separate field (see header note), same gating/base-value
    -- fixes applied, no >30% cutoff (SAS never had a distinct field to apply one to).
    CASE WHEN (SalesAntiqueClassicCollector=1 OR ServiceAntiqueClassicCollector=1 OR RestoreAntiqueClassicCollector=1) THEN 1 ELSE 0 END AS IsAntiqueClassicCollector,
    CASE WHEN OUTER_GATE AND (SalesAntiqueClassicCollector=1 OR ServiceAntiqueClassicCollector=1 OR RestoreAntiqueClassicCollector=1)
        THEN ROUND(TurnoverAntiqueClassicCollector / NULLIF(Turnover_Less_Fuel,0) * 100) ELSE 0 END AS VehicleTurnoverDetails_ACC,
    CASE WHEN OUTER_GATE AND (SalesAntiqueClassicCollector=1 OR ServiceAntiqueClassicCollector=1 OR RestoreAntiqueClassicCollector=1)
        THEN ROUND((TurnoverAntiqueClassicCollector / NULLIF(Turnover_Less_Fuel,0)) * Turnover_Less_Fuel) ELSE 0 END AS VehicleTurnoverDisplay_ACC,

    -- Watercraft
    CASE WHEN OUTER_GATE AND WatercraftRepair=1 THEN 'Yes' ELSE 'No' END AS IsWatercraftRepair,
    CASE WHEN OUTER_GATE AND WatercraftRepair=1 THEN 'No' ELSE NULL END AS IsWaterWorkPerformed,
    CASE WHEN OUTER_GATE AND WatercraftRepair=1 THEN WatercraftTurnoverDetails ELSE 0 END AS VehicleTurnoverDetails_Water,
    CASE WHEN OUTER_GATE AND WatercraftRepair=1 THEN ROUND(WatercraftTurnoverDetails/100 * Turnover_Less_Fuel) ELSE 0 END AS VehicleTurnoverDisplay_Water,

    -- Heavy Transport
    CASE WHEN OUTER_GATE AND HeavyTransportVehicles=1 THEN 'Yes' ELSE 'No' END AS IsHeavyTransportVehicles,
    CASE WHEN OUTER_GATE AND HeavyTransportVehicles=1 THEN HeavyVehiclesTransportDetails ELSE 0 END AS VehicleTurnoverDetails_Heavy,
    CASE WHEN OUTER_GATE AND HeavyTransportVehicles=1 THEN ROUND(HeavyVehiclesTransportDetails/100 * Turnover_Less_Fuel) ELSE 0 END AS VehicleTurnoverDisplay_Heavy,

    -- Import & Manufacture -- per-source gating (SAS's Import-alone/Manu-alone/both 3-block
    -- overwrite pattern), not a blanket OR over the summed value.
    CASE WHEN OUTER_GATE AND (ImportProducts=1 OR ManuProducts=1) THEN 'Yes' ELSE 'No' END AS IsProductsManufacturedorImported,
    CASE
        WHEN OUTER_GATE AND ImportProducts=1 AND ManuProducts=1 THEN COALESCE(ImportDetails,0)+COALESCE(ManuDetails,0)
        WHEN OUTER_GATE AND ManuProducts=1 THEN ManuDetails
        WHEN OUTER_GATE AND ImportProducts=1 THEN ImportDetails
        ELSE 0
    END AS VehicleTurnoverDetails_ManIm,
    CASE
        WHEN OUTER_GATE AND ImportProducts=1 AND ManuProducts=1 THEN ROUND((COALESCE(ImportDetails,0)+COALESCE(ManuDetails,0))/100 * Turnover_Less_Fuel)
        WHEN OUTER_GATE AND ManuProducts=1 THEN ROUND(ManuDetails/100 * Turnover_Less_Fuel)
        WHEN OUTER_GATE AND ImportProducts=1 THEN ROUND(ImportDetails/100 * Turnover_Less_Fuel)
        ELSE 0
    END AS VehicleTurnoverDisplay_ManIm,

    -- Gearboxes (GearboxesDetails>0 condition already matched SAS -- unchanged)
    CASE WHEN OUTER_GATE AND GearboxesRecondition=1 AND COALESCE(GearboxesDetails,0)>0 THEN 'Yes' ELSE 'No' END AS IsGearboxesRecondition,
    CASE WHEN OUTER_GATE AND GearboxesRecondition=1 AND COALESCE(GearboxesDetails,0)>0 THEN GearboxesDetails ELSE 0 END AS VehicleTurnoverDetails_Recon,
    CASE WHEN OUTER_GATE AND GearboxesRecondition=1 AND COALESCE(GearboxesDetails,0)>0 THEN ROUND(GearboxesDetails/100 * Turnover_Less_Fuel) ELSE 0 END AS VehicleTurnoverDisplay_Recon,

    -- Construction
    CASE WHEN OUTER_GATE AND ConstructionServices=1 THEN 'Yes' ELSE 'No' END AS IsConstructionServices,
    CASE WHEN OUTER_GATE AND ConstructionServices=1 THEN ConstructionDetails ELSE 0 END AS VehicleTurnoverDetails_Const,
    CASE WHEN OUTER_GATE AND ConstructionServices=1 THEN ROUND(ConstructionDetails/100 * Turnover_Less_Fuel) ELSE 0 END AS VehicleTurnoverDisplay_Const,

    -- Mining -- IsUndergroundMining stays NULL (not "No") unless MiningEquipmentServices=1 AND
    -- the outer gate holds, matching SAS's uninitialized-missing semantics.
    CASE WHEN OUTER_GATE AND MiningEquipmentServices=1 THEN 'Yes' ELSE 'No' END AS IsMiningEquipmentServices,
    CASE WHEN OUTER_GATE AND MiningEquipmentServices=1 THEN (CASE WHEN UndergroundMining=1 THEN 'Yes' ELSE 'No' END) ELSE NULL END AS IsUndergroundMining,
    CASE WHEN OUTER_GATE AND MiningEquipmentServices=1 THEN MiningDetails ELSE 0 END AS VehicleTurnoverDetails_Mine,
    CASE WHEN OUTER_GATE AND MiningEquipmentServices=1 THEN ROUND(MiningDetails/100 * Turnover_Less_Fuel) ELSE 0 END AS VehicleTurnoverDisplay_Mine,

    -- Sideline Business -- SidelineBusinessType stays NULL (not '.') unless
    -- SidelineBusinessEntity=1 AND the outer gate holds.
    CASE WHEN OUTER_GATE AND SidelineBusinessEntity=1 THEN 'Yes' ELSE 'No' END AS IsSidelineBusinessEntity,
    CASE WHEN OUTER_GATE AND SidelineBusinessEntity=1
        THEN (CASE WHEN COALESCE(SidelineBusinessType_Temp,'') <> '' THEN SidelineBusinessType_Temp ELSE '.' END)
        ELSE NULL END AS SidelineBusinessType,
    CASE WHEN OUTER_GATE AND SidelineBusinessEntity=1 THEN TurnoverOfSidelineBusiness ELSE 0 END AS VehicleTurnoverDetails_Side,
    CASE WHEN OUTER_GATE AND SidelineBusinessEntity=1 THEN ROUND(TurnoverOfSidelineBusiness/100 * Turnover_Less_Fuel) ELSE 0 END AS VehicleTurnoverDisplay_Side,

    -- Tyre Related -- two-level gate: TYRE_ELIGIBLE (SIC/ANZSIC-based) AND
    -- RetailOrManufacturerTyres=1. DoYouRetailOrManufacturerTyres is NULL (not "No") unless
    -- TYRE_ELIGIBLE, matching ATP-11133 exactly.
    CASE WHEN TYRE_ELIGIBLE THEN (CASE WHEN RetailOrManufacturerTyres=1 THEN 'Yes' ELSE 'No' END) ELSE NULL END AS DoYouRetailOrManufacturerTyres,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN TyreSalesPercentage END AS TyreSalesPercentageTurnover,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ReTreadingPercentage END AS ReTreadingPercentageTurnover,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ImportingTyresPercentage END AS ImportingTyresPercentageTurnover,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ManufacturingTyresPercentage END AS ManufacturingTyresPercTurnover,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN SalesOfSecondHandTyresPercentage END AS SalesOfSecondHandPercTurnover,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN HeavyTransportTyresPercentage END AS HeavyTransportTyresPercTurnover,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ROUND(TyreSalesPercentage/100 * Turnover_Less_Fuel) END AS TyreSalesTurnoverDisplay,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ROUND(ReTreadingPercentage/100 * Turnover_Less_Fuel) END AS ReTreadingTurnoverDisplay,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ROUND(ImportingTyresPercentage/100 * Turnover_Less_Fuel) END AS ImportingTyresTurnoverDisplay,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ROUND(ManufacturingTyresPercentage/100 * Turnover_Less_Fuel) END AS ManufacturingTyresTurnDisplay,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ROUND(SalesOfSecondHandTyresPercentage/100 * Turnover_Less_Fuel) END AS SalesOfSecondHandTurnDisplay,
    CASE WHEN TYRE_ELIGIBLE AND RetailOrManufacturerTyres=1 THEN ROUND(HeavyTransportTyresPercentage/100 * Turnover_Less_Fuel) END AS HeavyTransportTyresTurnDisplay,

    -- SelectANZSICLookup_final -- unchanged, out of scope for this fix
    CASE
        WHEN SelectANZSICLookup = '111111 - Property Owners Only'
         AND IsPropOwnerOnly = 0
         AND PublicAndProductLiability = 1
         AND COALESCE(IsRunOffLiab,NULL,0) < 1
         AND Turnover_Less_Fuel <> 0
        THEN '532505 - Automotive Mechanical Repairs - Workshop - excluding Smash Repairs'

        WHEN SelectANZSICLookup = '111111 - Property Owners Only'
         AND (
                GeneralProperty = 1
             OR GoodsInTransit = 1
             OR ProfessionalProtection = 1
             OR LegalExpenses = 1
             OR TaxAudit = 1
             OR (CommercialVehicles = 1 AND Fleet = 1)
         )
        THEN '532505 - Automotive Mechanical Repairs - Workshop - excluding Smash Repairs'

        ELSE SelectANZSICLookup
    END AS SelectANZSICLookup_final,

    -- Derived vehicle flag (more than 30%) -- now correctly reflects the same >30% cutoff as
    -- Details_Perf itself (was previously computed independently and could disagree).
    CASE WHEN PERF_PCT_RAW > 30 THEN 'Yes' ELSE 'No' END AS IsVehicleTurnoverMorethan30

FROM STAGE2;

-- ============================================================
-- STEP 2: Business_Info_02 (unchanged logic -- just re-dedups the corrected Business_Info_01)
-- ============================================================
CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Business_Info_02 AS
    SELECT *
        FROM (
            SELECT DISTINCT *,
                   ROW_NUMBER() OVER (
                       PARTITION BY PUREPolicyNumber
                       ORDER BY Turnover_Less_Fuel DESC,
                                BusinessEstablishmentDate DESC
                   ) AS rn
            FROM AGGNE.DEV.Business_Info_01
        )
        WHERE rn = 1;

-- ============================================================
-- STEP 3: Businessdetails_Final -- rebuild again since it reads FROM Business_Info_02, reusing
-- G-BP-94's already-fixed QU_HEAVYDUTYDIESEL/QU_TYREDEALER join (unchanged from that fix).
-- ============================================================
CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Businessdetails_Final AS
    SELECT  DISTINCT
        p.PUREPolicyNumber,
        p.expiringid,
        p.insurance_file_cnt,
        p.CMLNumber,
        p.Country,
        p.Product,
        p.ExpirationDate,
        p.PolicyInceptionDate,
        p.EffectiveTime,
        p.TimeZone,
        COALESCE(i.BusinessEstablishmentDate, YEAR(p.PolicyInceptionDate)) AS BusinessEstablishmentDate,
        i.SelectANZSICLookup_final AS SelectANZSICLookup,
        b.SecondaryANZSICLookup,
        i.Turnover_Less_Fuel,
        i.IsWebPage,
        i.IsVehicleTurnoverMorethan30,
        i.IsWatercraftRepair,
        i.IsHeavyTransportVehicles,
        i.IsProductsManufacturedorImported,
        i.IsGearboxesRecondition,
        i.IsConstructionServices,
        i.IsMiningEquipmentServices,
        i.IsUndergroundMining,
        i.IsSidelineBusinessEntity,
        i.DoYouRetailOrManufacturerTyres,
        i.ManagementProprietorsAndPartners,
        i.EngagedSalesorWorkshopActivities,
        i.WebsiteAddress,
        i.VehicleTurnoverDetails_Perf,
        i.VehicleTurnoverDisplay_Perf,
        i.IsWaterWorkPerformed,
        i.VehicleTurnoverDetails_Water,
        i.VehicleTurnoverDisplay_Water,
        i.VehicleTurnoverDetails_Heavy,
        i.VehicleTurnoverDisplay_Heavy,
        i.VehicleTurnoverDetails_ManIm,
        i.VehicleTurnoverDisplay_ManIm,
        i.VehicleTurnoverDetails_Recon,
        i.VehicleTurnoverDisplay_Recon,
        i.VehicleTurnoverDetails_Const,
        i.VehicleTurnoverDisplay_Const,
        i.VehicleTurnoverDetails_Mine,
        i.VehicleTurnoverDisplay_Mine,
        i.SidelineBusinessType,
        i.VehicleTurnoverDisplay_Side,
        i.TyreSalesPercentageTurnover,
        i.ReTreadingPercentageTurnover,
        i.ImportingTyresPercentageTurnover,
        i.ManufacturingTyresPercTurnover,
        i.SalesOfSecondHandPercTurnover,
        i.HeavyTransportTyresPercTurnover,
        i.TyreSalesTurnoverDisplay,
        i.ReTreadingTurnoverDisplay,
        i.ImportingTyresTurnoverDisplay,
        i.ManufacturingTyresTurnDisplay,
        i.SalesOfSecondHandTurnDisplay,
        i.HeavyTransportTyresTurnDisplay,
        pr.GeneralProperty,
        pr.GoodsInTransit,
        pr.PublicAndProductLiability,
        pr.ProfessionalProtection,
        pr.LegalExpenses,
        pr.TaxAudit,
        pr.CommercialVehicles,
        pr.CustomerVehicle,
        pr.StockVehicles,
        hd.roadtestprime,
        hd.testdriveroutes,
        hd.custprimestov,
        hd.courtesytrailerssupply,
        hd.detailscourtesyveh,
        hd.perctoconsormining,
        ty.pertovehservice,
        ty.franchise,
        ty.retreadingmanufacturing,
        ty.salesechandtyres,
        ty.detailsnonpassveh,
        ty.detailssechand,
        ty.tyrefittednonpassveh

    FROM AGGNE.DEV.PROTECTION_TERM p
    LEFT JOIN AGGNE.DEV.ANZSIC_RANK_04 b USING (PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.Business_Info_02 i USING (PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.BUSINESS_PROTECTIONS_02 pr USING (PUREPOLICYNUMBER)
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_HEAVYDUTYDIESEL hd
        ON TRIM(hd.PUREPOLICYNUMBER) = TRIM(p.PUREPolicyNumber)
        AND hd.PUREPOLICYBINDER = p.expiringid
        AND hd._IS_CURRENT = TRUE
        AND COALESCE(hd._IS_DELETED, FALSE) = FALSE
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_TYREDEALER ty
        ON TRIM(ty.PUREPOLICYNUMBER) = TRIM(p.PUREPolicyNumber)
        AND TRY_CAST(ty.PUREPOLICYBINDER AS NUMBER) = p.expiringid
        AND ty._IS_CURRENT = TRUE
        AND COALESCE(ty._IS_DELETED, FALSE) = FALSE
    QUALIFY
            ROW_NUMBER() OVER (
                PARTITION BY p.PUREPolicyNumber
                ORDER BY p.policyinceptiondate DESC
            ) = 1;

-- ============================================================
-- POST-CHECK 1: ATP-11050's exact example still resolves correctly
-- ============================================================
-- SELECT ISMININGEQUIPMENTSERVICES, VEHICLETURNOVERDETAILS_MINE, VEHICLETURNOVERDISPLAY_MINE
-- FROM AGGNE.DEV.Businessdetails_Final WHERE TRIM(PUREPOLICYNUMBER)='P00034499';
-- Expect 'No', 0, 0 (unchanged from the first draft's result).

-- POST-CHECK 2: ATP-11133's field is now genuinely conditional, not unconditionally populated
-- SELECT COUNT(*) FROM AGGNE.DEV.Business_Info_02 WHERE DoYouRetailOrManufacturerTyres IS NOT NULL;
-- Expect a small fraction of the 18,925 total (only genuinely tyre-eligible policies).

-- POST-CHECK 3: no more Turnover-vs-Turnover_Less_Fuel base-value mismatches in any Display field
-- (spot check a fuel-sales-excluded policy directly).

-- ============================================================
-- FOLLOW-UP: apply the same corrected logic inside both copies of the SP
-- (sql/snowflake/1_conversion/BP/sps/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql and
-- sql/snowflake/stored_procedures/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql,
-- Business_Info_01's CTAS) once this script is confirmed correct against real policies --
-- NOT yet applied to the SP files this time, given the size/risk of this revision; recommend
-- validating against several real Clarity/DC examples first.
-- ============================================================
