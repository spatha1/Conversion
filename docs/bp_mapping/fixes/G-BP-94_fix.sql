-- G-BP-94 (ATP-11137 / ATP-11075) — Business Details: Tyre Dealer / Heavy Duty Diesel Mechanic
-- UW questions dropped/wrong due to unkeyed reference-table joins
-- Businessdetails_Final (base table, feeds VW_BUSINESS_FINAL -> VW_CBP_OUTPUT_CONVERSION)
--
-- ROOT CAUSE: the SP's CTAS for Businessdetails_Final
-- (sql/snowflake/1_conversion/BP/sps/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql, lines
-- 1991-2084) joins two raw Pure reference tables --
--   PRD_T5_EXTERNAL_AGGNE.RISK.QU_HEAVYDUTYDIESEL (Heavy Duty Diesel Mechanic UW questions:
--     roadtestprime, testdriveroutes, custprimestov, courtesytrailerssupply, detailscourtesyveh,
--     perctoconsormining)
--   PRD_T5_EXTERNAL_AGGNE.RISK.QU_TYREDEALER (Tyre Dealer UW questions: pertovehservice,
--     franchise, retreadingmanufacturing, salesechandtyres, detailsnonpassveh, detailssechand,
--     tyrefittednonpassveh)
-- via `USING (PUREPOLICYNUMBER)` only. Both tables are SCD-style snapshot tables with genuine
-- historical duplicate rows per policy -- confirmed live: QU_HEAVYDUTYDIESEL has 904 rows for
-- only 690 distinct policies, QU_TYREDEALER has 614 rows for only 361 distinct policies. Both
-- already carry the standard disambiguators used correctly elsewhere in this codebase
-- (`_IS_CURRENT`/`_IS_DELETED` flags, same pattern as `ACCOUNT_HANDLER._IS_CURRENT=TRUE` in
-- VW_CBP_OUTPUT_CONVERSION) plus `PUREPOLICYBINDER`, confirmed live to be the exact same value
-- domain as PROTECTION_TERM.EXPIRINGID (e.g. P00000018: PUREPOLICYBINDER=2175428 ==
-- EXPIRINGID=2175428) -- but the SP's join uses neither. The final QUALIFY
-- (ROW_NUMBER() ... PARTITION BY p.PUREPolicyNumber ORDER BY p.policyinceptiondate DESC = 1) can
-- therefore land on an arbitrary hd/ty snapshot row for the winning term, unrelated to which term
-- actually won on the p/i/b/pr side.
--
-- Checked and RULED OUT a second hypothesis: whether the same QUALIFY could pick an EXPIRED term
-- over a CURRENT one for the base p/i/b/pr columns (which would explain the wider ~20-ticket
-- turnover/ANZSIC/run-off cluster too). Verified empirically -- 0 of 16,036 policies have this
-- happen; `ORDER BY policyinceptiondate DESC` reliably picks the current term for those columns.
-- NOT a bug, not touched. This fix is scoped ONLY to the QU_HEAVYDUTYDIESEL/QU_TYREDEALER joins.
--
-- Live impact: after applying `_IS_CURRENT=TRUE AND _IS_DELETED IS NOT TRUE`, 410 policies have a
-- genuinely current QU_HEAVYDUTYDIESEL row (down from 690 raw), 231 for QU_TYREDEALER (down from
-- 361) -- confirming a meaningful fraction of today's live joins are matching against a stale
-- snapshot instead of the current one. (policy, binder) is a clean key for both tables after this
-- filter (0 residual duplicates for QU_HEAVYDUTYDIESEL, 1 negligible residual for QU_TYREDEALER).
--
-- FIX: rebuild Businessdetails_Final with the exact same logic as the SP's live CTAS, changing
-- only the two `USING (PUREPOLICYNUMBER)` joins to explicit `ON` conditions that also match
-- PUREPOLICYBINDER = EXPIRINGID and require _IS_CURRENT = TRUE / not deleted. Every other column,
-- join, and the QUALIFY dedup are reproduced byte-for-byte from the live SP.
--
-- DEPLOYMENT NOTE -- this is different from every other fix this session: Businessdetails_Final is
-- a physical TRANSIENT TABLE (CREATE ... AS SELECT), not a view, so this script must be RE-RUN
-- (not just applied once) any time the SP's normal daily/scheduled run would otherwise regenerate
-- it -- otherwise the next full SP run will silently revert this fix by rebuilding the table with
-- the original unkeyed joins. The permanent fix is to apply the same ON-condition change directly
-- inside the SP file (lines 2077-2078) so every future run is correct automatically -- recommend
-- doing that once this script is confirmed to produce the right result, rather than relying on
-- this standalone script long-term.
--
-- Status: APPLIED 2026-07-13, VERIFIED LIVE end-to-end against the client's exact reported
-- example (ATP-11137, policy P00009659) -- confirmed correct at every layer:
--   Businessdetails_Final: current term (EXPIRINGID=2175270, expires 2026-09-01) now shows
--     PERTOVEHSERVICE='90%', FRANCHISE='YES'; expired term (176982, expired 2019) correctly NULL.
--   VW_BUSINESS_FINAL (active-term filtered): PERTOVEHSERVICE='90%', FRANCHISE='YES'.
--   VW_CBP_OUTPUT_CONVERSION (final master output view): PERTOVEHSERVICE='90', FRANCHISE='1'.
-- Follow-up DONE 2026-07-13: applied the same ON-condition change directly inside both copies of
-- the SP (sql/snowflake/1_conversion/BP/sps/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql and
-- sql/snowflake/stored_procedures/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql, lines
-- 2073-2078 in each) so a future scheduled SP run won't rebuild this table with the original
-- unkeyed joins. Validated the fix pattern against an EXISTING correct usage found elsewhere in
-- the same SP file (~line 4118-4121, the QU_HEAVYDUTYDIESEL/QU_TYREDEALER/QU_SMASHREPAIRER/
-- QU_DISMANTLER joins feeding a different staging table) -- that block already uses
-- trim(...)=trim(...) AND expiringid_p=purepolicybinder, confirming this is the established
-- correct pattern in this codebase, not a new invention.

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
    -- FIX (G-BP-94): was `LEFT JOIN ... hd USING (PUREPOLICYNUMBER)` -- matched every historical
    -- snapshot row for the policy, not just the current term's. Now matches on policy + the
    -- specific term (PUREPOLICYBINDER = EXPIRINGID) and requires the row to be the current,
    -- non-deleted snapshot.
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_HEAVYDUTYDIESEL hd
        ON TRIM(hd.PUREPOLICYNUMBER) = TRIM(p.PUREPolicyNumber)
        AND hd.PUREPOLICYBINDER = p.expiringid
        AND hd._IS_CURRENT = TRUE
        AND COALESCE(hd._IS_DELETED, FALSE) = FALSE
    -- FIX (G-BP-94): same change as hd above -- PUREPOLICYBINDER is TEXT here, cast to NUMBER to
    -- compare against p.expiringid.
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
-- POST-CHECK 1: row count should be unchanged (this fix corrects WHICH hd/ty row is attached,
-- not how many Businessdetails_Final rows exist)
-- ============================================================
-- SELECT COUNT(*) FROM AGGNE.DEV.Businessdetails_Final;
-- Baseline: 16,036 (matches TRIM-deduplicated distinct PROTECTION_TERM policy count).

-- POST-CHECK 2: spot check -- pick a policy that was in the duplicate set for either reference
-- table and confirm ROADTESTPRIME/PERTOVEHSERVICE etc. now reflect the _IS_CURRENT=TRUE row
-- SELECT PUREPOLICYNUMBER, ROADTESTPRIME, PERCTOCONSORMINING, PERTOVEHSERVICE, FRANCHISE
-- FROM AGGNE.DEV.Businessdetails_Final
-- WHERE TRIM(PUREPOLICYNUMBER) = 'P00007576';  -- one of the QU_HEAVYDUTYDIESEL dup examples found live

-- ============================================================
-- FOLLOW-UP: after confirming this standalone rebuild produces the right result, apply the same
-- ON-condition change to the SP itself
-- (sql/snowflake/1_conversion/BP/sps/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql, lines
-- 2077-2078) so future scheduled SP runs don't silently revert this fix by rebuilding the table
-- with the original unkeyed joins.
-- ============================================================
