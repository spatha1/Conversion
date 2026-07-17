-- ============================================================================
-- G-BP-99 (SP copy: SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD_SAI)
-- Fixes EngineSize / GrossVehicleMass hard-aliased to the near-empty manual-
-- override columns (CMRBEngineSizeOV / CMRBGrossVehMassOV) instead of
-- following the CASE WHEN CMCVOverride=1 THEN <OV> ELSE <base> END pattern
-- already used by every sibling field in the same CTAS.
--
-- Source of truth: full live GET_DDL of this procedure, pulled 2026-07-15,
-- with ONLY the 2 EngineSize/GrossVehicleMass lines changed via an exact,
-- verified (single-match) programmatic string replace -- not hand-retyped,
-- so the other ~450KB of this procedure is guaranteed byte-identical to
-- what is live today.
--
-- Live evidence: CMRBEngineSize (base) 88.2% filled vs CMRBEngineSizeOV
-- (override-only) 12.8% filled; CMRBGrossVehMass (base) 65.3% filled vs
-- CMRBGrossVehMassOV (override-only) 2.2% filled, on
-- PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL (1,216,397 rows).
-- Same bug already fixed once on the Personal Motor (PM_01) equivalent in
-- this same procedure -- confirm PM_03 still shows ~99.5%/57.5% fill after
-- deploying, as a regression check.
--
-- IMPORTANT: this table-build chain (Sample_CBP_CommercialVechicle -> CM_01
-- -> CM_02 -> CM_03) was found MISSING from the currently-deployed MAIN
-- procedure (SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD, redeployed
-- 2026-07-14 18:06) even though CM_01/02/03 were freshly rebuilt today
-- (2026-07-15 14:59) -- meaning some OTHER procedure actually ran that
-- batch. This SAI copy and the BKP_12072026 copy are the two live
-- candidates that still contain this logic; both get the identical fix
-- (see G-BP-99_fix_BKP.sql). Confirm with the team which one is the real
-- scheduled/production driver so its output is the one that counts --
-- deploying both is safe (harmless if one is unused) but only one matters
-- for the next actual batch run.
--
-- STATUS: DRAFTED, NOT APPLIED. SAFE_MODE -- user must run this.
-- ============================================================================

CREATE OR REPLACE PROCEDURE "SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD_SAI"()
RETURNS VARCHAR
LANGUAGE SQL
COMMENT='user-defined procedure'
EXECUTE AS CALLER
AS 'DECLARE
    v_result VARIANT;

BEGIN
--@keerthana : 25-05-- post call with lucas , jilna. for commercial vehicles the bodytype,cylinder and other details only come when override =1 , so when over ride =0 there will be no data . so for these cap team said to give the value coming from cbp_vehicle detial table, hence in case statement for these fields in have given the field from cbp_vehicle detail at last else statement
----------------------------------------------1@@Sample_CBP@@start@@------------------------------------------------------------
CREATE OR REPLACE TRANSIENT table AGGNE.DEV.Sample_CBP  AS
SELECT DISTINCT 
   t3.insurance_ref AS PUREPolicyNumber
    ,t14.shortname AS CMLNumber
	,t18.CBP_Policy_Binder_id AS ExpiringID_P
	,t3.insurance_file_cnt
	,t13.description AS Country
    ,CASE
        WHEN TRIM(COUNTRY) = ''New Zealand'' THEN ''NZ''
        ELSE t20.RLState
     END AS STATE
	,t16.insurance_file_status_id
	,t19.code AS Product
	,CAST(t3.expiry_date AS DATE) AS ExpiryDate 
	,t20.RLAnzsicCode AS AnzsicCode
	,
	/** Note MSCSLSIC will be an API to EPICOR, use MSCSLSIC for reference only*/
	t20.MSCSLSIC AS SICCode
	,CAST(t20.PolicyInceptionDate AS DATE) AS InceptionDate
	,CAST(t20.RLProtectionCommencementDate AS DATE) AS CommencementDate
	,t20.RLBusinessBuildings AS BusinessBuildings
	,t20.RLBusinessContents AS BusinessContents
	,t20.RLBurglary AS Burglary
	,t20.RLMoney AS MONEY
	,t20.RLEngineering AS Engineering
	,t20.RLBusinessInterruption AS BusinessInterruption
	,t20.RLGeneralProperty AS GeneralProperty
	,t20.RLGoodsInTransit AS GoodsInTransit
	,t20.RLPublicProducts AS PublicAndProductLiability
	,t20.RLProfessional AS ProfessionalProtection
	,t20.RLLegalExpenses AS LegalExpenses
	,t20.RLTaxAudit AS TaxAudit
	,t20.RLCommercialVehicles AS CommercialVehicles
	,t20.RLFleetVehicles AS Fleet
	,t20.RLCustomerVehicles AS CustomerVehicle
	,t20.RLStockVehicles AS StockVehicles
	,t21.PP1PropOwnersOnly AS IsPropOwnerOnly
	,t21.PP1PropOwnersLiab AS PropOwnerLiab
	,t21.PP1RunOffLiab AS IsRunOffLiab
	
	/** Note PP1TotAnnualTurnover will be indexed via renewal rules applied, use PP1TotAnnualTurnover for reference only*/
	,t21.PP1TotAnnualTurnover AS Turnover
	,t26.PIAnnualTurnover AS Turnover_Prof
	,t27.LEAnnualTurnover AS Turnover_LE
	,t28.TAAnnualTurnover AS Turnover_TA
	,t21.PP2SellFuel AS FuelSales
	,t21.PP2SellFuelPercent AS FuelSalesPercent
	,t21.PP3BusWebPage AS IsWebPage_Temp
	,t21.PP3Address AS WebsiteAddress_Temp
	,t21.PP3ComYear AS BusinessEstablishmentDate
	,t21.PP3Management AS ManagementProprietorsPartners_
	,t21.PP3SalesWorkshopActivities AS EngagedSalesWorkshopActivities_
	,t21.PP3ContractorStaff AS ContractorStaff_
	,t22.QU1HighPerformanceSales AS SalesHighPerformance
	,t22.QU1HighPerformanceService AS ServiceHighPerformance
	,t22.QU1HighPerformanceRestore AS RestoreHighPerformance
	,t22.QU1HPAnnualTurnover AS TurnoverHighPerformance
	,t22.QU1AntiqueClassicColSales AS SalesAntiqueClassicCollector
	,t22.QU1AntiqueClassicColService AS ServiceAntiqueClassicCollector
	,t22.QU1AntiqueClassicColRestore AS RestoreAntiqueClassicCollector
	,t22.QU1ACCAnnualTurnover AS TurnoverAntiqueClassicCollector
	,t21.PP2RepairWatercraft AS WatercraftRepair
	,t21.PP2RepairWatercraftPercent AS WatercraftTurnoverDetails
	,t21.PP2RepairHeavyVeh AS HeavyTransportVehicles
	,t21.PP2RepairHeavyVehPercent AS HeavyVehiclesTransportDetails
	,t21.PP2ImportProds AS ImportProducts
	,t21.PP2ImportProdsPercent AS ImportDetails
	,t21.PP2ManuProds AS ManuProducts
	,t21.PP2ManuProdsPercent AS ManuDetails
	,t21.PP2ReconEngines AS GearboxesRecondition
	,t21.PP2ReconEnginesPercent AS GearboxesDetails
	,t21.PP2ConstEquip AS ConstructionServices
	,t21.PP2ConstEquipPercent AS ConstructionDetails
	,t21.PP2RepairMiningEquip AS MiningEquipmentServices
	,t21.PP2RepairMiningEquipPercent AS MiningDetails
	,t23.PP2SMTEquipUse AS UndergroundMining
	,t21.PP2HaveSidelineBus AS SidelineBusinessEntity
	,t21.PP2HaveSidelineBusPercent AS TurnoverOfSidelineBusiness
	,t24.PP2SBDetails AS SidelineBusinessType_Temp
	,t21.PP2TyreRetailer AS RetailOrManufacturerTyres
	,t21.PP2TyreRetailerPercent AS TyreSalesPercentage
	,t25.PP2TRReTreading AS ReTreadingPercentage
	,t25.PP2TRImportTyres AS ImportingTyresPercentage
	,t25.PP2TRManufTyres AS ManufacturingTyresPercentage
	,t25.PP2TRSecondHandTyres AS SalesOfSecondHandTyresPercentage
	,t25.PP2TRHeavyTrans AS HeavyTransportTyresPercentage
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_policy_binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_membercsl t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts t10 ON t6.party_cnt = T10.CLIENTID
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_policy_binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.product t19 ON (t3.product_id = t19.product_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t20 ON (t18.CBP_Policy_Binder_id = t20.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_publicproducts t21 ON (t18.CBP_Policy_Binder_id = t21.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_question1 t22 ON (t18.CBP_Policy_Binder_id = t22.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_serviceminingequip t23 ON (t18.CBP_Policy_Binder_id = t23.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_sidebusiness t24 ON (t18.CBP_Policy_Binder_id = t24.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_tyreretailer t25 ON (t18.CBP_Policy_Binder_id = t25.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_professionalprotection t26 ON (t18.CBP_Policy_Binder_id = t26.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_legalexpenses t27 ON (t18.CBP_Policy_Binder_id = t27.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_taxaudit t28 ON (t18.CBP_Policy_Binder_id = t28.CBP_Policy_Binder_id)
WHERE  NOT (COALESCE(IsRunOffLiab,NULL,0) > 0 AND PublicAndProductLiability = 1) and
--CAST(t3.expiry_date AS DATE) >= CURRENT_DATE() 
	   SUBSTRING(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(T3.insurance_file_status_id,NULL,0) NOT IN (1, 2)
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
    AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		WHERE CAST(t13.expiry_date AS DATE) > CURRENT_DATE ()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				AND (status.insurance_file_status_id <> 1 OR status.insurance_file_status_id IS NULL)
			)
		)
ORDER BY ExpiryDate
	,PUREPolicyNumber;

---------------------------------------------1@@Sample_CBP@@end@@---------------------------------------------------------------------------------------

--------------------------------------2@@Sample_PER@@start@@---------------------------------------------------------------------------------------
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_PER AS
SELECT DISTINCT 
     t3.insurance_ref AS PUREPolicyNumber
     ,t9.MSCSLNo AS CSLNumber
	,t14.shortname AS CMLNumber
	,t18.PER_Policy_Binder_id AS ExpiringID_P
	,t3.insurance_file_cnt
	,t0.description AS LineOfBusiness
	,CAST(t3.expiry_date AS DATE) AS EffectiveDate
	,t13.description AS Country
	,t1.risk_number  AS RiskNumber
	,t19.RLStreet AS Address1
	,t19.RLSuburb AS Suburb
	,t19.RLPostCode AS Postcode
	,CASE
        WHEN TRIM(COUNTRY) = ''New Zealand'' THEN ''NZ''
        ELSE t19.RLState
     END AS STATE
	,t19.RLOverrideAddress AS Override
	,t19.description AS AddressDescription
	,t19.RLHomeBuildingsContents AS Home
	,t20.HCProtection AS ProtectionSelection
	,t20.HCIsBuildingOccupied AS HowOccup
	,t20.HCNoStories AS Storeys
	,t20.HCYearConstructed AS YearBuildingConstructed
	,t20.HCLastRewired AS YearLastReWired
	,t20.HCLastReplumb AS YearLastReplumbed
	,t20.HCWallConstruction AS WallConst
	,t20.HCRoofConstruction AS RoofConst
	,t20.HCfloorConstruction AS FloorConst
	,t20.HCAlarmInstalled AS AlarmSystem
	,t20.HCDeadLocks AS Deadlocks
	,t20.HCGrillKeyLocks AS GrillKeyLock
	,t20.HCSecurityDet AS SecurityDetails
	,t20.HCHBTPFinInterest AS BuildingTPInd
	,t20.HCHBTPFinInterestDet AS BuildingTPDetails
	,t20.HCHCTPFinInterest AS ContentsTPInd
	,t20.HCHCTPFinInterestDet AS ContentsTPDetails
    ,t21.code  AS Product
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_Policy_Binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_MEMBERCSL t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts t10 ON t6.party_cnt = T10.ClientID
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RiskSelection t19 ON (t18.PER_Policy_Binder_id = t19.PER_Policy_Binder_id) 
LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents  t20 ON (t18.PER_Policy_Binder_id = t20.PER_Policy_Binder_id) 
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Product   t21 ON (t3.product_id = t21.product_id)  
WHERE 
 --CAST(t3.expiry_date AS DATE) >= current_date()AND
   SUBSTRING(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(T3.insurance_file_status_id,NULL,0) NOT IN (1, 2) /* (1=Cancelled, 2=Lapsed) */
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
    AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.RISK t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		-- ============================================================
		-- FIX [H1]: Sample_PER — GETDATE() is SQL Server syntax, not valid in Snowflake
		-- SAS LOGIC: DATEPART(t13.expiry_date) > TODAY()  (SAS TODAY() = Snowflake CURRENT_DATE())
		-- ISSUE: GETDATE() is T-SQL (returns DATETIME). Snowflake uses CURRENT_DATE() for date-only.
		-- OLD CODE: WHERE CAST(t13.expiry_date as DATE) > CAST(GETDATE() AS DATE)
		-- ============================================================
		WHERE CAST(t13.expiry_date as DATE) > CURRENT_DATE()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				 AND (status.insurance_file_status_id <> 1 OR status.insurance_file_status_id IS NULL)
			)
		)
ORDER BY EffectiveDate, PUREPolicyNumber;

------------------------------------------------------1.1@@AdditionalInterest@@start@@-------------------------------------------------

CREATE OR REPLACE  TRANSIENT TABLE AGGNE.DEV.AI_01 AS
SELECT DISTINCT
    t2.PUREPolicyNumber,
    t2.ExpiringID_P,
    t2.CMLNumber,
    t2.ExpiryDate,
    t2.Country,
    t4.RLStreet,
    t4.RLSuburb,
    t4.RLPostCode,
    CASE 
        WHEN t2.Country = ''New Zealand'' THEN ''NZ''
        ELSE t4.RLState
    END AS State,
    t4.RLINTPARTIES,  -- PURE Field for testing only

    CASE 
        WHEN t4.RLINTPARTIES = 1 THEN t3.RLFullName
    END AS AdditionalIntDets, -- Additional Interest Type details

    CASE 
        WHEN (t3.RLBusinessBuildings = 1 OR t3.RLBusinessContents = 1 OR t3.RLBurglary = 1 
              OR t3.RLMoney = 1 OR t3.RLEngineering = 1 OR t3.RLBusinessInterruption = 1)
             AND t4.RLINTPARTIES = 1 THEN ''Yes''
        ELSE ''No''
    END AS AdditionalInterestLoc, -- Do you want to add this Additional Interest to the Property?

    CASE WHEN t3.RLBusinessBuildings = 1 AND t4.RLINTPARTIES = 1 THEN ''Business Buildings'' END AS AddIntLocCov1,
    CASE WHEN t3.RLBusinessContents = 1 AND t4.RLINTPARTIES = 1 THEN ''Business Contents'' END AS AddIntLocCov2,
    CASE WHEN t3.RLBurglary = 1 AND t4.RLINTPARTIES = 1 THEN ''Burglary'' END AS AddIntLocCov3,
    CASE WHEN t3.RLMoney = 1 AND t4.RLINTPARTIES = 1 THEN ''Money'' END AS AddIntLocCov4,
    CASE WHEN t3.RLEngineering = 1 AND t4.RLINTPARTIES = 1 THEN ''Engineering'' END AS AddIntLocCov5,
    CASE WHEN t3.RLBusinessInterruption = 1 AND t4.RLINTPARTIES = 1 THEN ''Business Interruption'' END AS AddIntLocCov6,

    CASE 
        WHEN (t3.RLGeneralProperty = 1 OR t3.RLGoodsInTransit = 1 OR t3.RLPublicProducts = 1 
              OR t3.RLProfessional = 1 OR t3.RLLegalExpenses = 1 OR t3.RLTaxAudit = 1
              OR t3.RLCustomerVehicles = 1 OR t3.RLStockVehicles = 1)
             AND t4.RLINTPARTIES = 1 THEN ''Yes''
        ELSE ''No''
    END AS AdditionalInterestLine, -- Do you want to add this Additional Interest to Line Protection Section?
    CASE WHEN t3.RLGeneralProperty = 1 AND t4.RLINTPARTIES = 1 THEN ''General Property'' END AS AddIntLocCov7,
    CASE WHEN t3.RLGoodsInTransit = 1 AND t4.RLINTPARTIES = 1 THEN ''Goods In Transit'' END AS AddIntLocCov8,
    CASE WHEN t3.RLPublicProducts = 1 AND t4.RLINTPARTIES = 1 THEN ''Products And Public Liability'' END AS AddIntLocCov9,
    CASE WHEN t3.RLProfessional = 1 AND t4.RLINTPARTIES = 1 THEN ''Professional Protection'' END AS AddIntLocCov10,
    CASE WHEN t3.RLLegalExpenses = 1 AND t4.RLINTPARTIES = 1 THEN ''Legal Expenses'' END AS AddIntLocCov11,
    CASE WHEN t3.RLTaxAudit = 1 AND t4.RLINTPARTIES = 1 THEN ''Tax Audit'' END AS AddIntLocCov12,
    CASE WHEN t3.RLCustomerVehicles = 1 AND t4.RLINTPARTIES = 1 THEN ''Customer Vehicles'' END AS AddIntLocCov13,
    CASE WHEN t3.RLStockVehicles = 1 AND t4.RLINTPARTIES = 1 THEN ''Stock Vehicles'' END AS AddIntLocCov14
FROM AGGNE.DEV.Sample_CBP AS t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION AS t4 
    ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_INTERESTEDPARTIES AS t3 
    ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
WHERE t4.RLINTPARTIES = 1
  AND COALESCE(t3.RLFullName, '''') <> '''';



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.AI_LOC AS
SELECT *
FROM AGGNE.DEV.AI_01
ORDER BY PUREPolicyNumber, ExpiringID_P, CMLNumber, ExpiryDate, Country, RLStreet, RLSuburb, RLPostCode, State, AdditionalIntDets, AdditionalInterestLoc;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.location_transposed AS
SELECT *
FROM (
    SELECT
        PUREPolicyNumber,
        ExpiringID_P,
        CMLNumber,
        ExpiryDate,
        Country,
        RLStreet,
        RLSuburb,
        RLPostCode,
        State,
        AdditionalIntDets,
        AdditionalInterestLoc,
        coverage_type,
        Location_value
    FROM AGGNE.DEV.AI_LOC
    UNPIVOT (
        Location_value
        FOR coverage_type IN (
            AddIntLocCov1,
            AddIntLocCov2,
            AddIntLocCov3,
            AddIntLocCov4,
            AddIntLocCov5,
            AddIntLocCov6
        )
    )
)
WHERE Location_value IS NOT NULL;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.AI_02 AS
SELECT 
    t1.PUREPolicyNumber,
    t1.ExpiringID_P,
    t1.CMLNumber,
    t1.ExpiryDate,
    t1.Country,
    t1.RLStreet,
    t1.RLSuburb,
    t1.RLPostCode,
    t1.State,
    t1.AdditionalIntDets,
    t1.AdditionalInterestLoc,
    T1.LOCATION_VALUE AS LOC_VALUE
FROM AGGNE.DEV.LOCATION_TRANSPOSED t1
WHERE t1.AdditionalInterestLoc = ''Yes'';



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.AI_LINE AS
SELECT *
FROM AGGNE.DEV.AI_01
ORDER BY 
    PUREPolicyNumber, ExpiringID_P, CMLNumber, ExpiryDate, 
    Country, RLStreet, RLSuburb, RLPostCode, State, 
    AdditionalIntDets, AdditionalInterestLine;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.LINE_TRANSPOSED AS
SELECT 
    PUREPolicyNumber,
    ExpiringID_P,
    CMLNumber,
    ExpiryDate,
    Country,
    RLStreet,
    RLSuburb,
    RLPostCode,
    State,
    AdditionalIntDets,
    AdditionalInterestLine,
    coverage_type,
    Line_value
FROM AGGNE.DEV.AI_LINE
UNPIVOT (
    Line_value FOR coverage_type IN (
        AddIntLocCov7,
        AddIntLocCov8,
        AddIntLocCov9,
        AddIntLocCov10,
        AddIntLocCov11,
        AddIntLocCov12,
        AddIntLocCov13,
        AddIntLocCov14
    )
) AS unpvt;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.AI_03 AS
SELECT 
    t1.PUREPolicyNumber,
    t1.ExpiringID_P,
    t1.CMLNumber,
    t1.ExpiryDate,
    t1.Country,
    t1.AdditionalIntDets,
    t1.AdditionalInterestLine,
    t1.Line_value
FROM AGGNE.DEV.line_transposed t1
WHERE t1.AdditionalInterestLine = ''Yes'';


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.NO_LOC_LINE AS
SELECT 
    t1.PUREPolicyNumber,
    t1.ExpiringID_P,
    t1.CMLNumber,
    t1.ExpiryDate,
    t1.Country,
    t1.AdditionalIntDets
FROM AGGNE.DEV.AI_01 t1
WHERE t1.AdditionalInterestLoc = ''No''
  AND t1.AdditionalInterestLine = ''No'';


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.AI_MERGED AS
SELECT *
FROM (
    -- From AI_02: remove blank Loc_value
    SELECT 
        PUREPolicyNumber,
        ExpiringID_P,
        CMLNumber,
        ExpiryDate,
        Country,
        RLStreet,
        RLSuburb,
        RLPostCode,
        State,
        AdditionalIntDets,
        AdditionalInterestLoc,
        --NULL AS Loc_value,
        Loc_value,
        '''' AS AdditionalInterestLine,
        NULL AS Line_value,
        ''A'' AS Source_Flag
    FROM AGGNE.DEV.AI_02
    WHERE COALESCE(TRIM(Loc_value), '''') <> ''''
    
    UNION ALL

    -- From AI_03: remove blank Line_value
    SELECT 
        PUREPolicyNumber,
        ExpiringID_P,
        CMLNumber,
        ExpiryDate,
        Country,
        NULL AS RLStreet,
        NULL AS RLSuburb,
        NULL AS RLPostCode,
        NULL AS State,
        AdditionalIntDets,
        NULL AS AdditionalInterestLoc,
        NULL as Loc_value,
        AdditionalInterestLine,
        Line_value,
        ''B'' AS Source_Flag
    FROM AGGNE.DEV.AI_03
    WHERE COALESCE(TRIM(Line_value), '''') <> ''''

    UNION ALL

    -- From NO_LOC_LINE: keep all
    SELECT 
        PUREPolicyNumber,
        ExpiringID_P,
        CMLNumber,
        ExpiryDate,
        Country,
        NULL AS RLStreet,
        NULL AS RLSuburb,
        NULL AS RLPostCode,
        NULL AS State,
        AdditionalIntDets,
        NULL AS AdditionalInterestLoc,
        NULL as Loc_value,
        '''' AS AdditionalInterestLine,
        NULL as Line_value,
        ''C'' AS Source_Flag
    FROM AGGNE.DEV.NO_LOC_LINE
);


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Additional_Interest AS
SELECT 
    t1.PUREPolicyNumber,
    t1.ExpiringID_P,
    t1.CMLNumber,
    t1.ExpiryDate,
    t1.Country,
    t1.RLStreet,
    t1.RLSuburb,
    t1.RLPostCode,
    CASE WHEN TRIM(t1.Country) = ''New Zealand'' THEN ''NZ'' ELSE t1.State END AS State,
    t1.AdditionalIntDets,
    t1.AdditionalInterestLoc,
    t1.Loc_value,
    t1.AdditionalInterestLine,
    t1.Line_value
FROM AGGNE.DEV.AI_MERGED t1
ORDER BY
    t1.PUREPolicyNumber,
    t1.ExpiringID_P,
    t1.CMLNumber,
    t1.ExpiryDate,
    t1.Country;

------------------------------------------1.1@@AdditionalInterest@@end@@----------------------------------------------------------------------------

--------------------------------------------------1.2@@ApplicantInfomration@@start@@---------------------------------------------------------------------


CREATE OR REPLACE  TRANSIENT TABLE AGGNE.DEV.Sample_CBP_Applicant AS
SELECT DISTINCT 
    t9.MSCSLNo AS CSLNumber
	,t3.insurance_ref AS PUREPolicyNumber
	,t18.CBP_Policy_Binder_id AS ExpiringID_P
	,t3.insurance_file_cnt
	,t0.description AS ProtectionType 
	,CAST(t3.expiry_date AS DATE) AS ExpiryDate
	,t14.shortname AS CMLNumber
	,t13.description AS Country
	,t19.code  AS Product
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_policy_binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_membercsl t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts t10 ON t6.party_cnt = T10.CLIENTID
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_policy_binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.product t19 ON (t3.product_id = t19.product_id)
WHERE 
--CAST(t3.expiry_date AS DATE) = CURRENT_DATE () + 45
	  SUBSTRING(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(T3.insurance_file_status_id,NULL,0) NOT IN (1, 2)
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
    AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		WHERE CAST(t13.expiry_date AS DATE) > CURRENT_DATE ()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				AND (status.insurance_file_status_id <> 1 OR status.insurance_file_status_id IS NULL)
			)
		)
ORDER BY ExpiryDate
	,PUREPolicyNumber;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_PER_Applicant AS
SELECT DISTINCT 
    t9.MSCSLNo AS CSLNumber
    ,t3.insurance_ref AS PUREPolicyNumber
	,t18.PER_Policy_Binder_id AS ExpiringID_P
	,t3.insurance_file_cnt
    ,t0.description AS ProtectionType
	,CAST(t3.expiry_date as DATE) AS ExpiryDate
	,t14.shortname AS CMLNumber
	,t13.description AS Country
	,t19.code  AS Product
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_Policy_Binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_MEMBERCSL t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts t10 ON t6.party_cnt = T10.clientid
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Product t19 ON (t3.product_id = t19.product_id)
WHERE 
--CAST(t3.expiry_date as DATE) = TODAY() + 45
	SUBSTRING(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(t3.insurance_file_status_id,NULL,0) NOT IN (1, 2) /* (1=Cancelled, 2=Lapsed) */
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
    AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		WHERE CAST(t13.expiry_date as DATE) > CURRENT_DATE()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				AND (STATUS.insurance_file_status_id <> 1 OR STATUS.insurance_file_status_id IS NULL) /* (1=Cancelled) */
			)
		)
ORDER BY ExpiryDate
	,PUREPolicyNumber;


CREATE  OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_1 AS
SELECT * FROM AGGNE.DEV.Sample_CBP_Applicant
UNION ALL
SELECT * FROM AGGNE.DEV.Sample_PER_Applicant;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CBP_CLAIMHISTORY_a AS
SELECT  
 t3.PUREPolicyNumber
	,t3.ExpiringID_P
	,t3.CMLNumber
	,t3.ExpiryDate
	,t3.Country
	,t3.Product
	,t1.CBP_CLAIMHISTORY_id AS CLAIMHISTORY_id
	,t1.QU3RiskType AS Line_temp
    ,CASE 
      WHEN t1.QU3DateofLoss IS NULL  THEN CAST(''1990-01-01'' AS DATE)
      ELSE CAST(t1.QU3DateofLoss AS DATE)
      END
	 AS DateOfClaim
     ,CASE 
      WHEN UPPER(t1.QU3Details)  LIKE ''%XXX%''  THEN ''Other''
      ELSE t1.QU3Details
      END
	 AS Cause 
    ,CASE 
      WHEN t1.QU3Cost IS NULL  THEN 0
      ELSE t1.QU3Cost
      END
	 AS AmountPaid
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_claimhistory t1
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_question3 t2 ON (t1.CBP_Policy_Binder_id = t2.CBP_Policy_Binder_id)
INNER JOIN AGGNE.DEV.Sample_1 t3 ON (t2.CBP_Policy_Binder_id = t3.ExpiringID_P)
WHERE t2.QU3RecentClaimsMade = 1
	AND trim(t3.Product) = ''BSP'';


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CBP_CLAIMHISTORY_b AS
SELECT
    CMLNumber,
    PUREPolicyNumber,
    ExpiringID_P,
    ExpiryDate,
    Country,
    Product,
    CLAIMHISTORY_id,
    Line,
    DateOfClaim,
    Cause,
    AmountPaid
FROM (
    -- FIX [C3-CBP]: CBP_CLAIMHISTORY_b — lateral alias risk
    -- Snowflake does not support referencing a column alias defined earlier in the same SELECT list.
    -- ''Line'' was computed and then referenced by the ''Cause'' CASE in the same SELECT clause.
    -- Fix: split into two subquery layers — inner derives Line from Line_temp, outer computes Cause using Line.
    SELECT
        CMLNumber,
        PUREPolicyNumber,
        ExpiringID_P,
        ExpiryDate,
        Country,
        Product,
        CLAIMHISTORY_id,
        Line,
        DateOfClaim,
        --Classify ''Cause'' based on ''Line'' and ''Cause''
        CASE
            -- Property specific causes
            WHEN Line = ''Property'' AND
                 (POSITION(''FIRE'' IN UPPER(Cause)) > 0 OR
                  POSITION(''FLAME'' IN UPPER(Cause)) > 0 OR
                  POSITION(''BLAZE'' IN UPPER(Cause)) > 0) THEN ''Fire''

            WHEN Line = ''Property'' AND
                 (POSITION(''FLOOD'' IN UPPER(Cause)) > 0 OR
                  POSITION(''WATER'' IN UPPER(Cause)) > 0 OR
                  POSITION(''OVERFLOW'' IN UPPER(Cause)) > 0 OR
                  POSITION(''RIVER'' IN UPPER(Cause)) > 0 OR
                  POSITION(''RAIN'' IN UPPER(Cause)) > 0 OR
                  POSITION(''TORRENT'' IN UPPER(Cause)) > 0) THEN ''Flood''

            WHEN Line = ''Property'' AND
                 (POSITION(''BURGLAR'' IN UPPER(Cause)) > 0 OR
                  POSITION(''THEFT'' IN UPPER(Cause)) > 0 OR
                  POSITION(''THIEF'' IN UPPER(Cause)) > 0 OR
                  POSITION(''THIEVE'' IN UPPER(Cause)) > 0 OR
                  POSITION(''STEAL'' IN UPPER(Cause)) > 0 OR
                  POSITION(''STOLE'' IN UPPER(Cause)) > 0) THEN ''Burglary''

            -- Liability specific causes
            WHEN Line = ''Liability'' AND
                 (POSITION(''PROPERT'' IN UPPER(Cause)) > 0 OR
                  POSITION(''BELONGING'' IN UPPER(Cause)) > 0 OR
                  POSITION(''GOODS'' IN UPPER(Cause)) > 0 OR
                  POSITION(''ASSET'' IN UPPER(Cause)) > 0 OR
                  POSITION(''VEHICLE'' IN UPPER(Cause)) > 0 OR
                  POSITION(''CAR'' IN UPPER(Cause)) > 0) THEN ''Customer Property Damage''

            WHEN Line = ''Liability'' AND
                 (POSITION(''INJUR'' IN UPPER(Cause)) > 0 OR
                  POSITION(''TRAUMA'' IN UPPER(Cause)) > 0 OR
                  POSITION(''HARM'' IN UPPER(Cause)) > 0 OR
                  POSITION(''HURT'' IN UPPER(Cause)) > 0) THEN ''Customer Injury''

            -- Motor specific causes
            -- ============================================================
            -- FIX [C2-CBP]: CBP_CLAIMHISTORY_b — AT FAULT / NOT AT FAULT evaluation order
            -- SAS LOGIC (CBP_CLAIMHISTORY_b DATA step, sequential IF statements):
            --   IF Line = "Motor" AND INDEX(UPCASE(Cause_Temp), "AT FAULT") THEN Cause = "At Fault";
            --   IF Line = "Motor" AND INDEX(UPCASE(Cause_Temp), "NOT AT FAULT") THEN Cause = "Not At Fault";
            -- ISSUE: In SAS, the last matching IF wins — "NOT AT FAULT" overrides "AT FAULT" correctly.
            --        In a CASE statement the FIRST matching WHEN wins. "NOT AT FAULT" contains "AT FAULT",
            --        so the old code misclassified "NOT AT FAULT" claims as "At Fault".
            -- FIX:   Put NOT AT FAULT check BEFORE AT FAULT so the more specific pattern fires first.
            -- ============================================================
            -- OLD CODE (incorrect — AT FAULT fired before NOT AT FAULT):
            -- WHEN Line = ''Motor'' AND POSITION(''AT FAULT'' IN UPPER(Cause)) > 0 THEN ''At Fault''
            -- WHEN Line = ''Motor'' AND POSITION(''NOT AT FAULT'' IN UPPER(Cause)) > 0 THEN ''Not At Fault''

            -- NEW CODE (NOT AT FAULT checked first — matches SAS sequential IF behaviour):
            WHEN Line = ''Motor'' AND POSITION(''NOT AT FAULT'' IN UPPER(Cause)) > 0 THEN ''Not At Fault''

            WHEN Line = ''Motor'' AND POSITION(''AT FAULT'' IN UPPER(Cause)) > 0 THEN ''At Fault''

            WHEN Line = ''Motor'' AND
                 (POSITION(''BURGLAR'' IN UPPER(Cause)) > 0 OR
                  POSITION(''THEFT'' IN UPPER(Cause)) > 0 OR
                  POSITION(''THIEF'' IN UPPER(Cause)) > 0 OR
                  POSITION(''THIEVE'' IN UPPER(Cause)) > 0 OR
                  POSITION(''STEAL'' IN UPPER(Cause)) > 0 OR
                  POSITION(''STOLE'' IN UPPER(Cause)) > 0) THEN ''Theft''

            ELSE ''Other''  -- Default cause if none of the conditions match
        END AS Cause,

        AmountPaid
    FROM (
        SELECT
            CMLNumber,
            PUREPolicyNumber,
            ExpiringID_P,
            ExpiryDate,
            Country,
            Product,
            CLAIMHISTORY_id,
            -- Classify the ''Line'' based on ''Line_Temp''
            CASE
                WHEN Line_temp IN (1, 2, 3) THEN ''Motor''
                WHEN Line_temp IN (4, 5) THEN ''Liability''
                WHEN Line_temp IN (6, 7, 8, 9, 10, 11, 12, 13) THEN ''Property''
                ELSE ''Other''
            END AS Line,
            DateOfClaim,
            Cause,
            AmountPaid
        FROM AGGNE.DEV.CBP_CLAIMHISTORY_a
    )
);


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CBP_CLAIMHISTORY_c AS
SELECT  t4.PUREPolicyNumber
	,t4.ExpiringID_P
	,t4.CMLNumber
	,t4.ExpiryDate
	,t4.Country
	,t4.Product
	,t1.CBP_DRIVERACCIDENT_id AS CLAIMHISTORY_id
    ,CASE 
      WHEN t1.CMDADOLoss IS NULL  THEN CAST(''1990-01-01'' AS DATE)
      ELSE CAST(t1.CMDADOLoss AS DATE)
      END
	 AS DateOfClaim
     ,CASE 
      WHEN UPPER(t1.CMDADetails)  LIKE ''%XXX%''  THEN ''Other''
      ELSE t1.CMDADetails
      END
	 AS Cause
    ,CASE 
      WHEN t1.CMDACost IS NULL  THEN 0
      ELSE t1.CMDACost
      END
	 AS AmountPaid
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_driveraccident t1
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t2 ON (t1.CBP_Policy_Binder_id = t2.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_vehicledetail t3 ON (t1.CBP_Policy_Binder_id = t3.CBP_Policy_Binder_id)
INNER JOIN AGGNE.DEV.Sample_1 t4 ON (t1.CBP_Policy_Binder_id = t4.ExpiringID_P)
WHERE t3.CMCVAcc5Yrs = 1
	AND t2.RLCommercialVehicles = 1
	AND trim(t4.Product) = ''BSP'';




;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CBP_CLAIMHISTORY_d AS
SELECT 
    CMLNumber,
    PUREPolicyNumber,
    ExpiringID_P,
    ExpiryDate,
    Country,
    Product,
    CLAIMHISTORY_id,
    ''Motor'' AS Line,  -- Default value for Line
    DateOfClaim,
    -- Case logic for determining Cause
    -- ============================================================
    -- FIX [C2-CBPd]: CBP_CLAIMHISTORY_d — NOT AT FAULT before AT FAULT
    -- SAS LOGIC (ApplicantInformation DATA step, sequential IF statements):
    --   IF Line="Motor" AND INDEX(...,"AT FAULT") THEN Cause="At Fault";
    --   IF Line="Motor" AND INDEX(...,"NOT AT FAULT") THEN Cause="Not At Fault";  /* overrides */
    -- ISSUE: First WHEN match wins in CASE; "NOT AT FAULT" contains "AT FAULT" substring
    --        so AT FAULT check must come AFTER NOT AT FAULT to prevent misclassification.
    -- ============================================================
    -- OLD CODE: WHEN ''%AT FAULT%'' THEN ''At Fault'' WHEN ''%NOT AT FAULT%'' THEN ''Not At Fault''
    CASE
        WHEN UPPER(Cause) LIKE ''%NOT AT FAULT%'' THEN ''Not At Fault''
        WHEN UPPER(Cause) LIKE ''%AT FAULT%'' THEN ''At Fault''
        WHEN UPPER(Cause) LIKE ''%BURGLAR%''
             OR UPPER(Cause) LIKE ''%THEFT%''
             OR UPPER(Cause) LIKE ''%THIEF%''
             OR UPPER(Cause) LIKE ''%THIEVE%''
             OR UPPER(Cause) LIKE ''%STEAL%''
             OR UPPER(Cause) LIKE ''%STOLE%'' THEN ''Theft''
        ELSE ''Other''
    END AS Cause,
    AmountPaid
FROM
    AGGNE.DEV.CBP_CLAIMHISTORY_c;


CREATE  OR REPLACE TRANSIENT TABLE AGGNE.DEV.PER_CLAIMHISTORY_a AS
SELECT  t3.PUREPolicyNumber
	,t3.ExpiringID_P
	,t3.CMLNumber
	,t3.ExpiryDate
	,t3.Country
	,t3.Product
	,t1.PER_CLMHISTORY_id AS CLAIMHISTORY_id
    ,CASE 
      WHEN t1.dol IS NULL  THEN CAST(''1990-01-01'' AS DATE)
      ELSE CAST(t1.dol AS DATE)
      END
	 AS DateOfClaim
	,t1.Details AS Cause
	,t1.Responsibility
    ,CASE 
      WHEN t1.Amount IS NULL  THEN 0
      ELSE t1.Amount
      END
	 AS AmountPaid
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.per_clmhistory t1
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.per_homecontents t2 ON (t1.PER_Policy_Binder_id = t2.PER_Policy_Binder_id)
INNER JOIN AGGNE.DEV.SAMPLE_1 t3 ON (t2.PER_Policy_Binder_id = t3.ExpiringID_P)
WHERE t2.HCCLMHistory = 1
	AND TRIM(t3.Product) = ''PER'';



-- ============================================================
-- FIX [C1]: PER_CLAIMHISTORY_b — Hardcoded ''Property'' AS Line makes Motor Cause branches dead code
-- FIX [C2b]: PER_CLAIMHISTORY_b — NOT AT FAULT must be evaluated before AT FAULT
-- SAS LOGIC (ApplicantInformation_conversionscriptCapricorn, DATA step PER_CLAIMHISTORY_b):
--   Line = "Property";   /* default */
--   IF (INDEX(UPCASE(Cause_Temp),"CAR") OR INDEX(UPCASE(Cause_Temp),"VEHICLE")) THEN Line = "Motor";
--   /* Then Cause IF-blocks reference derived Line — Motor wins over Property keywords */
--   IF Line="Motor" AND INDEX(UPCASE(Cause_Temp),"AT FAULT") ... THEN Cause = "At Fault";
--   IF Line="Motor" AND INDEX(UPCASE(Cause_Temp),"NOT AT FAULT") ... THEN Cause = "Not At Fault";
-- ISSUE C1: Snowflake had ''Property'' AS Line hardcoded. Cause CASE referenced Line=''Motor''
--   which could never be true, so At Fault / Not At Fault / Theft branches were dead code.
-- ISSUE C2b: AT FAULT was checked before NOT AT FAULT. In a CASE, first match wins.
--   "NOT AT FAULT" contains "AT FAULT" → previously misclassified as "At Fault".
-- FIX C1: Inner subquery derives Line from Cause keywords (Motor if CAR/VEHICLE, else Property).
--   Outer query evaluates Cause CASE using the derived Line — matches SAS DATA step order.
-- FIX C2b: NOT AT FAULT placed before AT FAULT in the Motor Cause WHEN list.
-- ============================================================
-- OLD CODE (incorrect — Line hardcoded Property; AT FAULT before NOT AT FAULT):
-- SELECT CMLNumber,...,''Property'' AS Line,...
--     CASE
--         WHEN UPPER(Cause) LIKE ''%CAR%'' OR ''%VEHICLE%'' THEN ''Motor''  -- set Cause not Line
--         WHEN Line = ''Motor'' AND CONTAINS(...,''AT FAULT'') THEN ''At Fault''     -- dead code
--         WHEN Line = ''Motor'' AND CONTAINS(...,''NOT AT FAULT'') THEN ''Not At Fault'' -- dead code
--         ...
--     END AS Cause
-- FROM AGGNE.DEV.PER_CLAIMHISTORY_a;
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PER_CLAIMHISTORY_b AS
-- NEW CODE (Line derived dynamically; NOT AT FAULT checked before AT FAULT):
SELECT
    CMLNumber
    ,PUREPolicyNumber
    ,ExpiringID_P
    ,ExpiryDate
    ,Country
    ,Product
    ,CLAIMHISTORY_id
    ,Line
    ,DateOfClaim
    ,AmountPaid
    ,CASE
        -- Property-specific causes (Line derived from inner subquery)
        WHEN Line = ''Property''
            AND (
                UPPER(Cause) LIKE ''%FIRE%''
                OR UPPER(Cause) LIKE ''%FLAME%''
                OR UPPER(Cause) LIKE ''%BLAZE%''
                )
            THEN ''Fire''
        WHEN Line = ''Property''
            AND (
                UPPER(Cause) LIKE ''%FLOOD%''
                OR UPPER(Cause) LIKE ''%WATER%''
                OR UPPER(Cause) LIKE ''%OVERFLOW%''
                OR UPPER(Cause) LIKE ''%RIVER%''
                OR UPPER(Cause) LIKE ''%RAIN%''
                OR UPPER(Cause) LIKE ''%TORRENT%''
                )
            THEN ''Flood''
        WHEN Line = ''Property''
            AND (
                UPPER(Cause) LIKE ''%BURGLAR%''
                OR UPPER(Cause) LIKE ''%THEFT%''
                OR UPPER(Cause) LIKE ''%THIEF%''
                OR UPPER(Cause) LIKE ''%THIEVE%''
                OR UPPER(Cause) LIKE ''%STEAL%''
                OR UPPER(Cause) LIKE ''%STOLE%''
                )
            THEN ''Burglary''
        -- Motor-specific causes: NOT AT FAULT before AT FAULT (C2b fix)
        WHEN Line = ''Motor''
            AND (
                CONTAINS(UPPER(Cause), ''NOT AT FAULT'')
                OR Responsibility IN (2, 3)
                )
            THEN ''Not At Fault''
        WHEN Line = ''Motor''
            AND (
                CONTAINS(UPPER(Cause), ''AT FAULT'')
                OR Responsibility = 1
                )
            THEN ''At Fault''
        WHEN Line = ''Motor''
            AND (
                CONTAINS(UPPER(Cause), ''BURGLAR'')
                OR CONTAINS(UPPER(Cause), ''THEFT'')
                OR CONTAINS(UPPER(Cause), ''THIEF'')
                OR CONTAINS(UPPER(Cause), ''THIEVE'')
                OR CONTAINS(UPPER(Cause), ''STEAL'')
                OR CONTAINS(UPPER(Cause), ''STOLE'')
                )
            THEN ''Theft''
        ELSE ''Other''
        END AS Cause
FROM (
    -- Inner subquery: derive Line from Cause keywords (mirrors SAS sequential assignment)
    SELECT
        CMLNumber
        ,PUREPolicyNumber
        ,ExpiringID_P
        ,ExpiryDate
        ,Country
        ,Product
        ,CLAIMHISTORY_id
        ,CASE
            WHEN UPPER(Cause) LIKE ''%CAR%'' OR UPPER(Cause) LIKE ''%VEHICLE%'' THEN ''Motor''
            ELSE ''Property''
            END AS Line
        ,DateOfClaim
        ,AmountPaid
        ,Cause
        ,Responsibility
    FROM AGGNE.DEV.PER_CLAIMHISTORY_a
) src;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PER_CLAIMHISTORY_c AS
SELECT  t4.PUREPolicyNumber
	,t4.ExpiringID_P
	,t4.CMLNumber
	,t4.ExpiryDate
	,t4.Country
	,t4.Product
	,t1.PER_DRIVERACCIDENT_id AS CLAIMHISTORY_id
    ,CASE 
      WHEN t1.MVDADOLoss IS NULL  THEN CAST(''1990-01-01'' AS DATE)
      ELSE CAST(t1.MVDADOLoss AS DATE)
      END
	 AS DateOfClaim
     ,CASE 
      WHEN UPPER(t1.MVDADetails)  LIKE ''%XXX%''  THEN ''Other''
      ELSE t1.MVDADetails
      END
	 AS Cause
    ,CASE 
      WHEN t1.MVDACost IS NULL  THEN 0
      ELSE t1.MVDACost
      END
	 AS AmountPaid
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.per_driveraccident t1
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.per_riskselection t2 ON (t1.PER_Policy_Binder_id = t2.PER_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.per_vehicledetail t3 ON (t1.PER_Policy_Binder_id = t3.PER_Policy_Binder_id)
INNER JOIN AGGNE.DEV.sample_1 t4 ON (t1.PER_Policy_Binder_id = t4.ExpiringID_P)
WHERE t3.MVCVAcc5Yrs = 1
	AND t2.RLMotorVehicles = 1
	AND TRIM(t4.Product) = ''PER'';


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PER_CLAIMHISTORY_d AS
SELECT 
  CMLNumber,
  PUREPolicyNumber,
  ExpiringID_P,
  ExpiryDate,
  Country,
  Product,
  CLAIMHISTORY_id,
  ''Motor'' AS Line,
  DateOfClaim,
  AmountPaid,
  -- ============================================================
  -- FIX [C2-PERd]: PER_CLAIMHISTORY_d — NOT AT FAULT before AT FAULT
  -- SAS LOGIC (ApplicantInformation DATA step, sequential IF statements):
  --   IF Line="Motor" AND INDEX(...,"AT FAULT") ... THEN Cause="At Fault";
  --   IF Line="Motor" AND INDEX(...,"NOT AT FAULT") ... THEN Cause="Not At Fault";  /* overrides */
  -- ISSUE: In CASE, first match wins. "NOT AT FAULT" contains "AT FAULT" as a substring,
  --        so the old order incorrectly classified "NOT AT FAULT" records as "At Fault".
  -- ============================================================
  -- OLD CODE: WHEN ''%AT FAULT%'' THEN ''At Fault'' (before NOT AT FAULT check)
  CASE
    WHEN UPPER(Cause) LIKE ''%NOT AT FAULT%'' THEN ''Not At Fault''
    WHEN UPPER(Cause) LIKE ''%AT FAULT%'' THEN ''At Fault''
    WHEN UPPER(Cause) LIKE ''%BURGLAR%''
         OR UPPER(Cause) LIKE ''%THEFT%''
         OR UPPER(Cause) LIKE ''%THIEF%''
         OR UPPER(Cause) LIKE ''%THIEVE%''
         OR UPPER(Cause) LIKE ''%STEAL%''
         OR UPPER(Cause) LIKE ''%STOLE%''
      THEN ''Theft''
    ELSE ''Other''
  END AS Cause
FROM AGGNE.DEV.PER_CLAIMHISTORY_c;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CLAIMHISTORY AS
SELECT CMLNumber, PUREPolicyNumber, ExpiringID_P, ExpiryDate,
       Country, Product, CLAIMHISTORY_id, Line, DateOfClaim, Cause, AmountPaid
FROM AGGNE.DEV.CBP_CLAIMHISTORY_b

UNION ALL
SELECT CMLNumber, PUREPolicyNumber, ExpiringID_P, ExpiryDate,
       Country, Product, CLAIMHISTORY_id, Line, DateOfClaim, Cause, AmountPaid
FROM AGGNE.DEV.CBP_CLAIMHISTORY_d

UNION ALL
SELECT CMLNumber, PUREPolicyNumber, ExpiringID_P, ExpiryDate,
       Country, Product, CLAIMHISTORY_id, Line, DateOfClaim, Cause, AmountPaid
FROM AGGNE.DEV.PER_CLAIMHISTORY_b

UNION ALL
SELECT CMLNumber, PUREPolicyNumber, ExpiringID_P, ExpiryDate,
       Country, Product, CLAIMHISTORY_id, Line, DateOfClaim, Cause, AmountPaid
FROM AGGNE.DEV.PER_CLAIMHISTORY_d;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CBP_Competitor_Information AS
SELECT  t3.PUREPolicyNumber
	,t3.ExpiringID_P
	,t3.CMLNumber
	,t3.ExpiryDate
	,t3.Country
	,t3.Product
	,t2.description AS PriorCarrier
    ,CASE 
      WHEN t1.SUCompetitorPrice IS NULL  THEN 0
      ELSE t1.SUCompetitorPrice
      END
	 AS Price
    ,t1.CBP_Policy_Binder_id
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_summary t1
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_suumr002 t2 ON TRIM(t1.SUCompetitorName) = TRIM(t2.UDL_SUUMR002_id)
INNER JOIN AGGNE.DEV.sample_1 t3 ON (t1.CBP_Policy_Binder_id = t3.ExpiringID_P)
WHERE t2.description NOT IN ('''')
ORDER BY t1.CBP_Policy_Binder_id;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PER_Competitor_Information AS
SELECT  t3.PUREPolicyNumber
	,t3.ExpiringID_P
	,t3.CMLNumber
	,t3.ExpiryDate
	,t3.Country
	,t3.Product
	,t2.description AS PriorCarrier
    ,CASE 
      WHEN t1.SUCompetitorPrice IS NULL  THEN 0
      ELSE t1.SUCompetitorPrice
      END
	  AS Price
    ,t1.PER_Policy_Binder_id
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.per_summary t1
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_suumr002 t2 ON (t1.SUCompetitorName = t2.UDL_SUUMR002_id)
INNER JOIN AGGNE.DEV.sample_1 t3 ON (t1.PER_Policy_Binder_id = t3.ExpiringID_P)
WHERE t2.description NOT IN ('''')
ORDER BY t1.PER_Policy_Binder_id;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Competitor_Information AS
SELECT 
       CMLNumber,
       PUREPolicyNumber,
       ExpiringID_P,
       ExpiryDate,
       Country,
       Product,
       PriorCarrier,
       Price
FROM AGGNE.DEV.CBP_Competitor_Information

UNION ALL

SELECT 
       CMLNumber,
       PUREPolicyNumber,
       ExpiringID_P,
       ExpiryDate,
       Country,
       Product,
       PriorCarrier,
       Price
FROM AGGNE.DEV.PER_Competitor_Information;

--select * from AGGNE.DEV.PER_Competitor_Information;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CBP_Duty_Disclosure AS
SELECT  t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,t2.Product
	,t1.QU3CriminalConviction
	,t1.QU3CriminalConvictionDetails AS CriminalConvictionDetails
	,t1.QU3InsuranceRefusedCancelled
	,t1.QU3InsuranceRefusedCancelledDetails  AS RefusedInsuranceDetails
    ,t1.CBP_Policy_Binder_id
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_question3 t1
INNER JOIN AGGNE.DEV.sample_1 t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
ORDER BY t1.CBP_Policy_Binder_id;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Duty_Disclosure AS
SELECT 
  PUREPolicyNumber,
  ExpiringID_P,
  CMLNumber,
  ExpiryDate,
  Country,
  Product,
  -- Create the new columns with default ''No''
  CASE WHEN QU3CriminalConviction = 1 THEN ''Yes'' ELSE ''No'' END AS CriminalConviction,
  CriminalConvictionDetails,
  CASE WHEN QU3InsuranceRefusedCancelled = 1 THEN ''Yes'' ELSE ''No'' END AS RefusedInsurance,
  RefusedInsuranceDetails
FROM
  AGGNE.DEV.CBP_Duty_Disclosure
  ORDER BY PUREPolicyNumber;
  
  --------------------------------------------------1.2@@ApplicantInfomration@@end@@---------------------------------------------------------------------


--------------------------------------------------1.3@@BusinessProtection@@start@@---------------------------------------------------------------------

;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.SAMPLE_BP_CBP AS
SELECT DISTINCT
    t9.MSCSLNo AS CSLNumber,
    t14.shortname AS CMLNUMBER,
    t19.RLState AS PRIMARYRATINGSTATE,
    t3.insurance_ref AS LEGACYPOLICYNUMBER,
    t18.CBP_Policy_Binder_id AS EXPIRINGID_P,
    t3.insurance_file_cnt,
    t0.description AS LINEOFBUSINESS,
    CAST(t3.expiry_date AS DATE) AS EFFECTIVEDATE,
    t13.description AS COUNTRY,
    t1.risk_number AS RISKNUMBER,
    CAST(t19.PolicyInceptionDate AS DATE) AS INCEPTIONDATE,
    CAST(t19.RLProtectionCommencementDate AS DATE) AS COMMENCEMENTDATE
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Folder t0               ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2  ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t3            ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t6           ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_Policy_Binder t7    ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_MEMBERCSL t9        ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Party t14                    ON t3.insured_cnt = t14.party_cnt
LEFT  JOIN aggne.dev.clientcontacts t10                                     ON t6.party_cnt = t10.clientid
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Source t13                   ON t3.source_id = t13.source_id
LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Status t15              ON t1.risk_status_id = t15.risk_status_id
LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16    ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t17          ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_Policy_Binder t18        ON t17.gis_policy_link_id = t18.gis_policy_link_id
LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RiskSelection t19        ON t18.CBP_Policy_Binder_id = t19.CBP_Policy_Binder_id
WHERE 
 --CAST(t3.expiry_date AS DATE) = CURRENT_DATE() + 45
    SUBSTR(t3.insurance_ref, 1, 1) = ''P''
  AND t3.insurance_file_type_id <> 3
  AND COALESCE(T3.insurance_file_status_id,NULL,0) NOT IN (1, 2)
  AND t15.risk_status_id IN (1, 3)
  AND t2.status_flag <> ''D''
  AND t3.insurance_ref NOT IN (
        SELECT DISTINCT t13.insurance_ref
        FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t11
        INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
        INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t13           ON t12.insurance_file_cnt = t13.insurance_file_cnt
        WHERE CAST(t13.expiry_date AS DATE) > CURRENT_DATE()
          AND t13.insurance_file_type_id = 8
  )
  AND (
        (
          SELECT COUNT(DISTINCT ins.insurance_file_cnt)
          FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
          WHERE ins.insurance_ref = t3.insurance_ref
        ) = 1
        OR
        t3.insurance_file_cnt = (
          SELECT MAX(ins.insurance_file_cnt)
          FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status status
            ON ins.insurance_file_status_id = status.insurance_file_status_id
          WHERE ins.insurance_ref = t3.insurance_ref
            AND (status.insurance_file_status_id <> 1 OR status.insurance_file_status_id IS NULL)
        )
  )
ORDER BY EFFECTIVEDATE, LEGACYPOLICYNUMBER;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.SAMPLE_BP_PER AS
SELECT DISTINCT 
        t9.MSCSLNo 									AS CSLNumber,
        t14.shortname 								AS CMLNumber,
        t19.RLState									AS PrimaryRatingState,
        t3.insurance_ref 							AS LegacyPolicyNumber,
        t18.PER_Policy_Binder_id 					AS ExpiringID_P,
        t3.insurance_file_cnt,
        t0.description 								AS LineOfBusiness,
        CAST(t3.expiry_date AS DATE) 					AS EffectiveDate,
        t13.description 							AS Country,
        t1.risk_number     					AS RiskNumber,
        CAST(t19.PolicyInceptionDate AS DATE)			AS InceptionDate ,
        CAST(t19.RLProtectionCommencementDate AS DATE)	AS CommencementDate 
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Folder              t0	ON t1.risk_folder_cnt = t0.risk_folder_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 	ON t1.risk_cnt = t2.risk_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File           t3 	ON t2.insurance_file_cnt = t3.insurance_file_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link          t6 	ON t3.insured_cnt = t6.party_cnt  
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_Policy_Binder   t7 	ON t6.gis_policy_link_id = t7.gis_policy_link_id   
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_MEMBERCSL       t9 	ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Party                    t14 ON t3.insured_cnt = t14.party_cnt
    LEFT JOIN  aggne.dev.clientcontacts           t10 ON t6.party_cnt = T10.ClientID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Source                   t13 ON t3.source_id = t13.source_id
    LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Status              t15 ON t1.risk_status_id = t15.risk_status_id
    LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status    t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
    LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link          t17 ON t1.risk_cnt = t17.risk_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder        t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
    LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RiskSelection        t19 ON (t18.PER_Policy_Binder_id = t19.PER_Policy_Binder_id)
    WHERE 
    --CAST(t3.expiry_date AS DATE) = CURRENT_DATE() + 45
          SUBSTRING(t3.insurance_ref,1,1) = ''P''
         AND t3.insurance_file_type_id <> 3				/* (3=Policy under Renewal) */
         AND COALESCE(T3.insurance_file_status_id,NULL,0) NOT IN (1, 2) 	/* (1=Cancelled, 2=Lapsed) */
         AND t15.risk_status_id IN (1, 3) 				/* (1=Referred, 3=Quoted) */
         AND t2.status_flag <> ''D''
         AND t3.insurance_ref NOT IN (
             SELECT DISTINCT t13.insurance_ref 
             FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t11
             INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
             INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
             WHERE CAST(t13.expiry_date AS DATE) > CURRENT_DATE()
               AND t13.insurance_file_type_id = 8 		/* (8 = MTA Cancelled) */
         )
         AND (
             /* Case 1: Only one insurance_file_cnt for the policy */
             (SELECT COUNT(DISTINCT ins.insurance_file_cnt)
              FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
              WHERE ins.insurance_ref = t3.insurance_ref) = 1
             OR
    
             /* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
             t3.insurance_file_cnt = (
                 SELECT MAX(ins.insurance_file_cnt)
                 FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
                 LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status status 
                   ON ins.insurance_file_status_id = status.insurance_file_status_id
                 WHERE ins.insurance_ref = t3.insurance_ref
                   AND (status.insurance_file_status_id <> 1 OR status.insurance_file_status_id IS NULL)
             )
         )
    ORDER BY EffectiveDate, legacypolicynumber;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.SAMPLE_FINAL AS
SELECT 
    LEGACYPOLICYNUMBER,
    CMLNUMBER,
    CSLNUMBER,
    ExpiringID_P,
    insurance_file_cnt,
    COUNTRY,
    CASE
        WHEN TRIM(COUNTRY) = ''New Zealand'' THEN ''NZ''
        ELSE PRIMARYRATINGSTATE
    END AS PRIMARYRATINGSTATE,
    LINEOFBUSINESS,
    EFFECTIVEDATE,
    DATEADD(YEAR, 1, EFFECTIVEDATE) AS EXPIRATIONDATE,
    COALESCE(COMMENCEMENTDATE, INCEPTIONDATE) AS MEMBERSHIPSYSTEMDATE,
    -- CASE
    --     WHEN TRIM(COUNTRY) = ''New Zealand'' THEN ''NZ''
    --     ELSE PRIMARYRATINGSTATE
    -- END AS PRIMARYRATINGSTATE_FINAL,
    CASE 
        WHEN LINEOFBUSINESS = ''Business Protections'' THEN ''Business Protection''
        WHEN LINEOFBUSINESS = ''Personal Protections'' THEN ''Personal Protection''
        ELSE LINEOFBUSINESS
    END AS LINEOFBUSINESS_STD,
    CASE
        WHEN LINEOFBUSINESS IN (''Business Protection'', ''Business Protections'') AND TRIM(COUNTRY) <> ''New Zealand'' THEN ''Business Protection (AUS)''
        WHEN LINEOFBUSINESS IN (''Business Protection'', ''Business Protections'') AND TRIM(COUNTRY) = ''New Zealand'' THEN ''Business Protection (NZ)''
        WHEN LINEOFBUSINESS IN (''Personal Protection'', ''Personal Protections'') AND TRIM(COUNTRY) <> ''New Zealand'' THEN ''Personal Protection (AUS)''
        WHEN LINEOFBUSINESS IN (''Personal Protection'', ''Personal Protections'') AND TRIM(COUNTRY) = ''New Zealand'' THEN ''Personal Protection (NZ)''
        ELSE NULL
    END AS CHOOSEPROTECTION,
    INCEPTIONDATE,
    COMMENCEMENTDATE
FROM (
    SELECT * FROM AGGNE.DEV.SAMPLE_BP_CBP
    UNION ALL
    SELECT * FROM AGGNE.DEV.SAMPLE_BP_PER
) AS combined
WHERE RISKNUMBER = 1;

--------------------------------------------------1.3@@BusinessProtection@@end@@---------------------------------------------------------------------

--------------------------------------------------1.4@@Businessdetails@@start@@---------------------------------------------------------------------
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_CBP_ as 
SELECT DISTINCT 
	 t3.insurance_ref AS PUREPolicyNumber
     ,t14.shortname AS CMLNumber
	,t18.CBP_Policy_Binder_id AS ExpiringID_P
	,t3.insurance_file_cnt
	,t13.description AS Country
	,t16.insurance_file_status_id
    ,t16.description as TransactionType
	,t19.code AS Product
    ,CAST(t3.cover_start_date AS DATE) AS CovEffectiveDate
	,CAST(t3.expiry_date AS DATE) AS ExpiryDate 
	,t20.RLAnzsicCode AS AnzsicCode
    ,t20.RLAnzsicDesc		AS AnzsicDescription
	,
	/** Note MSCSLSIC will be an API to EPICOR, use MSCSLSIC for reference only*/
	t20.MSCSLSIC AS SICCode
	,CAST(t20.PolicyInceptionDate AS DATE) AS InceptionDate
	,CAST(t20.RLProtectionCommencementDate AS DATE) AS CommencementDate
	,t20.RLBusinessBuildings AS BusinessBuildings
	,t20.RLBusinessContents AS BusinessContents
	,t20.RLBurglary AS Burglary
	,t20.RLMoney AS MONEY
	,t20.RLEngineering AS Engineering
	,t20.RLBusinessInterruption AS BusinessInterruption
	,t20.RLGeneralProperty AS GeneralProperty
	,t20.RLGoodsInTransit AS GoodsInTransit
	,t20.RLPublicProducts AS PublicAndProductLiability
	,t20.RLProfessional AS ProfessionalProtection
	,t20.RLLegalExpenses AS LegalExpenses
	,t20.RLTaxAudit AS TaxAudit
	,t20.RLCommercialVehicles AS CommercialVehicles
	,t20.RLFleetVehicles AS Fleet
	,t20.RLCustomerVehicles AS CustomerVehicle
	,t20.RLStockVehicles AS StockVehicles
	,t21.PP1PropOwnersOnly AS IsPropOwnerOnly
	,t21.PP1PropOwnersLiab AS PropOwnerLiab
	,t21.PP1RunOffLiab AS IsRunOffLiab
	,
	/** Note PP1TotAnnualTurnover will be indexed via renewal rules applied, use PP1TotAnnualTurnover for reference only*/
	t21.PP1TotAnnualTurnover AS Turnover
	,t26.PIAnnualTurnover AS Turnover_Prof
	,t27.LEAnnualTurnover AS Turnover_LE
	,t28.TAAnnualTurnover AS Turnover_TA
	,t21.PP2SellFuel AS FuelSales
	,t21.PP2SellFuelPercent AS FuelSalesPercent
	,t21.PP3BusWebPage AS IsWebPage_Temp
	,t21.PP3Address AS WebsiteAddress_Temp
	,t21.PP3ComYear AS BusinessEstablishmentDate
	,t21.PP3Management AS ManagementProprietorsPartners_
	,t21.PP3SalesWorkshopActivities AS EngagedSalesWorkshopActivities_
	,t21.PP3ContractorStaff AS ContractorStaff_
	,t22.QU1HighPerformanceSales AS SalesHighPerformance
	,t22.QU1HighPerformanceService AS ServiceHighPerformance
	,t22.QU1HighPerformanceRestore AS RestoreHighPerformance
	,t22.QU1HPAnnualTurnover AS TurnoverHighPerformance
	,t22.QU1AntiqueClassicColSales AS SalesAntiqueClassicCollector
	,t22.QU1AntiqueClassicColService AS ServiceAntiqueClassicCollector
	,t22.QU1AntiqueClassicColRestore AS RestoreAntiqueClassicCollector
	,t22.QU1ACCAnnualTurnover AS TurnoverAntiqueClassicCollector
	,t21.PP2RepairWatercraft AS WatercraftRepair
	,t21.PP2RepairWatercraftPercent AS WatercraftTurnoverDetails
	,t21.PP2RepairHeavyVeh AS HeavyTransportVehicles
	,t21.PP2RepairHeavyVehPercent AS HeavyVehiclesTransportDetails
	,t21.PP2ImportProds AS ImportProducts
	,t21.PP2ImportProdsPercent AS ImportDetails
	,t21.PP2ManuProds AS ManuProducts
	,t21.PP2ManuProdsPercent AS ManuDetails
	,t21.PP2ReconEngines AS GearboxesRecondition
	,t21.PP2ReconEnginesPercent AS GearboxesDetails
	,t21.PP2ConstEquip AS ConstructionServices
	,t21.PP2ConstEquipPercent AS ConstructionDetails
	,t21.PP2RepairMiningEquip AS MiningEquipmentServices
	,t21.PP2RepairMiningEquipPercent AS MiningDetails
	,t23.PP2SMTEquipUse AS UndergroundMining
	,t21.PP2HaveSidelineBus AS SidelineBusinessEntity
	,t21.PP2HaveSidelineBusPercent AS TurnoverOfSidelineBusiness
	,t24.PP2SBDetails AS SidelineBusinessType_Temp
	,t21.PP2TyreRetailer AS RetailOrManufacturerTyres
	,t21.PP2TyreRetailerPercent AS TyreSalesPercentage
	,t25.PP2TRReTreading AS ReTreadingPercentage
	,t25.PP2TRImportTyres AS ImportingTyresPercentage
	,t25.PP2TRManufTyres AS ManufacturingTyresPercentage
	,t25.PP2TRSecondHandTyres AS SalesOfSecondHandTyresPercentage
	,t25.PP2TRHeavyTrans AS HeavyTransportTyresPercentage
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_policy_binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_membercsl t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts  t10 ON t6.party_cnt = T10.CLIENTID
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_policy_binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.product t19 ON (t3.product_id = t19.product_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t20 ON (t18.CBP_Policy_Binder_id = t20.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_publicproducts t21 ON (t18.CBP_Policy_Binder_id = t21.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_question1 t22 ON (t18.CBP_Policy_Binder_id = t22.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_serviceminingequip t23 ON (t18.CBP_Policy_Binder_id = t23.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_sidebusiness t24 ON (t18.CBP_Policy_Binder_id = t24.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_tyreretailer t25 ON (t18.CBP_Policy_Binder_id = t25.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_professionalprotection t26 ON (t18.CBP_Policy_Binder_id = t26.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_legalexpenses t27 ON (t18.CBP_Policy_Binder_id = t27.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_taxaudit t28 ON (t18.CBP_Policy_Binder_id = t28.CBP_Policy_Binder_id)
WHERE 
   --CAST(t3.expiry_date AS DATE) = CURRENT_DATE () + 200
     SUBSTRING(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(T3.insurance_file_status_id,NULL,0) NOT IN (1, 2) /* (1=Cancelled, 2=Lapsed) */
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
    AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		WHERE CAST(t13.expiry_date AS DATE) > CURRENT_DATE ()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				AND (STATUS.insurance_file_status_id <> 1 OR status.insurance_file_status_id IS NULL) /* (1=Cancelled) */
			)
		)
    --AND  trim(purepolicynumber) = ''P00000005''
ORDER BY ExpiryDate
	,PUREPolicyNumber;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_CBP_Business AS
SELECT *
FROM Sample_CBP_
WHERE NOT (COALESCE(IsRunOffLiab,NULL,0) > 0 AND PublicAndProductLiability = 1);



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_CBP_BusinessDetail AS
SELECT *
FROM AGGNE.DEV.Sample_CBP_Business
ORDER BY PUREPolicyNumber, CommencementDate;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.BUSINESS_PROTECTIONS_01 AS
        SELECT DISTINCT
            PUREPolicyNumber,
            SUM(BusinessBuildings)            AS BusinessBuildings,
            SUM(BusinessContents)             AS BusinessContents,
            SUM(Burglary)                     AS Burglary,
            SUM(Money)                        AS Money,
            SUM(Engineering)                  AS Engineering,
            SUM(BusinessInterruption)         AS BusinessInterruption,
            SUM(GeneralProperty)              AS GeneralProperty,
            SUM(GoodsInTransit)               AS GoodsInTransit,
            SUM(PublicAndProductLiability)    AS PublicAndProductLiability,
            SUM(ProfessionalProtection)       AS ProfessionalProtection,
            SUM(LegalExpenses)                AS LegalExpenses,
            SUM(TaxAudit)                     AS TaxAudit,
            SUM(CommercialVehicles)           AS CommercialVehicles,
            SUM(Fleet)                        AS Fleet,
            SUM(CustomerVehicle)              AS CustomerVehicle,
            SUM(StockVehicles)                AS StockVehicles
        FROM AGGNE.DEV.Sample_CBP_BusinessDetail
        GROUP BY PUREPolicyNumber
        ORDER BY PUREPolicyNumber;


        ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.BUSINESS_PROTECTIONS_02 AS
        SELECT DISTINCT
            PUREPolicyNumber,
            CASE WHEN BusinessBuildings > 0 THEN 1 ELSE 0 END AS BusinessBuildings,
            CASE WHEN BusinessContents > 0 THEN 1 ELSE 0 END AS BusinessContents,
            CASE WHEN Burglary > 0 THEN 1 ELSE 0 END AS Burglary,
            CASE WHEN Money > 0 THEN 1 ELSE 0 END AS Money,
            CASE WHEN Engineering > 0 THEN 1 ELSE 0 END AS Engineering,
            CASE WHEN BusinessInterruption > 0 THEN 1 ELSE 0 END AS BusinessInterruption,
            CASE WHEN GeneralProperty > 0 THEN 1 ELSE 0 END AS GeneralProperty,
            CASE WHEN GoodsInTransit > 0 THEN 1 ELSE 0 END AS GoodsInTransit,
            CASE WHEN PublicAndProductLiability > 0 THEN 1 ELSE 0 END AS PublicAndProductLiability,
            CASE WHEN ProfessionalProtection > 0 THEN 1 ELSE 0 END AS ProfessionalProtection,
            CASE WHEN LegalExpenses > 0 THEN 1 ELSE 0 END AS LegalExpenses,
            CASE WHEN TaxAudit > 0 THEN 1 ELSE 0 END AS TaxAudit,
            CASE WHEN CommercialVehicles + Fleet > 0 THEN 1 ELSE 0 END AS CommercialVehicles,
            CASE WHEN Fleet > 0 THEN 1 ELSE 0 END AS Fleet,
            CASE WHEN CustomerVehicle > 0 THEN 1 ELSE 0 END AS CustomerVehicle,
            CASE WHEN StockVehicles > 0 THEN 1 ELSE 0 END AS StockVehicles
        FROM AGGNE.DEV.BUSINESS_PROTECTIONS_01
        ORDER BY PUREPolicyNumber;



        ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PROTECTION_TERM AS
        SELECT
            CMLNumber,
            PUREPolicyNumber,
            ExpiringID_P AS ExpiringID,
            insurance_file_cnt,
            Country,
            Product,
            DATEADD(year, 1, COVEFFECTIVEDATE) AS ExpirationDate,
            ''Australian Western Standard Time Zone'' AS TimeZone,
            ''4:00 PM'' AS EffectiveTime,
            COALESCE(CommencementDate, InceptionDate) AS PolicyInceptionDate
        FROM AGGNE.DEV.Sample_CBP_BusinessDetail
        QUALIFY ROW_NUMBER() OVER (PARTITION BY PUREPolicyNumber ORDER BY CommencementDate DESC) = 1;
        


-- ============================================================
-- FIX [C8]: ANZSIC_RANK_01 — Missing Rank=11 for Vehicles-Only code ''222222''
-- FIX [C9]: ANZSIC_RANK_01 — Rank CASE evaluated AnzsicCode (original) not AnzsicCode_final
-- SAS LOGIC (BusinessDetails_conversionscriptCapricorn, DATA step):
--   AnzsicCode_final derived first (recategorisation + vehicles-only = ''222222'')
--   Rank then assigned based on AnzsicCode_final, with ''222222'' → Rank 11
-- ISSUE C8: Rank CASE had no WHEN for ''222222'' → Vehicles-Only records got ELSE Rank=9
--           instead of the intended highest priority Rank=11.
-- ISSUE C9: Rank CASE referenced AnzsicCode (original) not AnzsicCode_final.
--           Snowflake does not allow alias references in the same SELECT clause,
--           so the Rank CASE silently used the pre-recategorization code.
--           Example: AnzsicCode=''281301'' → AnzsicCode_final=''532201'' (Rank 8), but
--           Rank CASE saw ''281301'' → ELSE → Rank 9. Wrong.
-- FIX: Wrap inner SELECT (computes AnzsicCode_final, AnzsicDescription_final) in a subquery.
--      Outer SELECT computes Rank referencing the derived AnzsicCode_final column.
-- OLD CODE (Rank evaluated on AnzsicCode, missing ''222222''):
-- CASE WHEN AnzsicCode = ''111111'' THEN 10 WHEN AnzsicCode IN (''532201'',''532504'') THEN 8 ... END AS Rank
-- ============================================================
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.ANZSIC_RANK_01 AS
SELECT
    *,
    -- NEW CODE: Rank evaluated on AnzsicCode_final; includes ''222222'' → 11 (C8+C9 fix)
    CASE
        WHEN AnzsicCode_final = ''222222'' THEN 11
        WHEN AnzsicCode_final = ''111111'' THEN 10
        WHEN AnzsicCode_final IN (''532201'',''532504'') THEN 8
        WHEN AnzsicCode_final IN (''532101'',''532103'',''532505'',''532903'',''532904'',''532912'',''540003'',''600001'',''600002'') THEN 7
        WHEN AnzsicCode_final IN (''532401'',''600003'') THEN 6
        WHEN AnzsicCode_final IN (''532301'',''532302'') THEN 5
        WHEN AnzsicCode_final = ''524502'' THEN 4
        WHEN AnzsicCode_final IN (''281901'',''532901'',''532902'',''540000'') THEN 3
        WHEN AnzsicCode_final IN (''531103'',''540001'') THEN 2
        WHEN AnzsicCode_final IN (''531116'',''540002'') THEN 1
        ELSE 9
    END AS Rank
FROM (
    -- Inner subquery: compute AnzsicCode_final and AnzsicDescription_final
    SELECT DISTINCT
       *,
        CASE
            /* VEHICLES ONLY */
            WHEN BusinessBuildings = 0 AND BusinessContents = 0 AND Burglary = 0
                 AND Money = 0 AND Engineering = 0 AND BusinessInterruption = 0
                 AND GeneralProperty = 0 AND GoodsInTransit = 0
                 AND PublicAndProductLiability = 0 AND ProfessionalProtection = 0
                 AND LegalExpenses = 0 AND TaxAudit = 0 AND CustomerVehicle = 0
                 AND StockVehicles = 0 AND CommercialVehicles = 1
                THEN ''222222''

            /* RECATEGORIZATION */
            WHEN AnzsicCode = ''281301'' THEN ''532201''
            WHEN AnzsicCode = ''292101'' THEN ''281901''
            WHEN AnzsicCode IN (''531104'',''286101'',''531118'') THEN ''531103''
            WHEN AnzsicCode = ''531201'' THEN ''531301''
            WHEN AnzsicCode IN (''462101'',''531119'') THEN ''531107''
            WHEN AnzsicCode = ''462401'' THEN ''531116''
            WHEN AnzsicCode IN (''531111'',''531112'',''531113'',''531114'') THEN ''462301''
            WHEN AnzsicCode = ''532102'' THEN ''532101''
            WHEN AnzsicCode = ''532104'' THEN ''532103''
            WHEN AnzsicCode IN (''255102'',''462302'') THEN ''532401''
            WHEN AnzsicCode IN (''532501'',''532502'',''532503'',''532906'',''532907'',''532910'',''532911'')
                THEN ''532505''

            /* OTHERWISE KEEP ORIGINAL */
            ELSE AnzsicCode
        END AS AnzsicCode_final,
        CASE
            /* VEHICLES ONLY */
            WHEN BusinessBuildings = 0 AND BusinessContents = 0 AND Burglary = 0
                 AND Money = 0 AND Engineering = 0 AND BusinessInterruption = 0
                 AND GeneralProperty = 0 AND GoodsInTransit = 0
                 AND PublicAndProductLiability = 0 AND ProfessionalProtection = 0
                 AND LegalExpenses = 0 AND TaxAudit = 0 AND CustomerVehicle = 0
                 AND StockVehicles = 0 AND CommercialVehicles = 1
                THEN ''Vehicles Only''

            /* RECATEGORIZED DESCRIPTIONS */
            WHEN AnzsicCode = ''281301'' THEN ''Automotive Electrical Services''
            WHEN AnzsicCode = ''292101'' THEN ''Automotive Component Manufacturing''
            WHEN AnzsicCode IN (''531104'',''286101'',''531118'')
                THEN ''Agricultural Machinery Dealers - Including Servicing''
            WHEN AnzsicCode = ''531201'' THEN ''Motorcycle Dealers - New and Used - including Servicing''
            WHEN AnzsicCode IN (''462101'',''531119'')
                THEN ''Motor Vehicle Dealers - New - excluding Servicing''
            WHEN AnzsicCode = ''462401'' THEN ''Motor Vehicle Wrecking - Used Parts Reseller''
            WHEN AnzsicCode IN (''531111'',''531112'',''531113'',''531114'')
                THEN ''Motor Vehicle New Part and Accessories Wholesaling''
            WHEN AnzsicCode = ''532102'' THEN ''Service Station - excluding Servicing''
            WHEN AnzsicCode = ''532104'' THEN ''Service Station - including Roadhouse - including Servicing''
            WHEN AnzsicCode IN (''255102'',''462302'')
                THEN ''Tyre Retailers and Repairers - excluding Retreading and Remoulding''
            WHEN AnzsicCode IN (''532501'',''532502'',''532503'',''532906'',''532907'',''532910'',''532911'')
                THEN ''Automotive Mechanical Repairs - Workshop - excluding Smash Repairs''

            /* HARDCODED DESCRIPTION OVERRIDES */
            WHEN AnzsicCode = ''111111'' THEN ''Property Owners Only''
            WHEN AnzsicCode = ''531301'' THEN ''Motorcycle Dealers - New and Used - including Servicing''
            WHEN AnzsicCode = ''600002'' THEN ''Ultra-Tune''
            WHEN AnzsicCode = ''524502'' THEN ''Boat Dealers - no Manufacturing - including Servicing''
            WHEN AnzsicCode = ''531109'' THEN ''Motor Vehicle Dealers - Used - excluding Servicing''
            WHEN AnzsicCode = ''531110'' THEN ''Motor Vehicle Dealers - Used - including Servicing''
            WHEN AnzsicCode = ''531116'' THEN ''Motor Vehicle Wrecking - Used Parts Reseller''
            WHEN AnzsicCode = ''532505'' THEN ''Automotive Mechanical Repairs - Workshop - excluding Smash Repairs''
            WHEN AnzsicCode = ''540002'' THEN ''Wrecker - Retailer Only''
            WHEN AnzsicCode = ''540003'' THEN ''Service Station - excluding Roadhouse''
            WHEN AnzsicCode = ''532504'' THEN ''Automotive Mechanical Repairs - Mobile Mechanic''

            ELSE AnzsicDescription
        END AS AnzsicDescription_final
    FROM AGGNE.DEV.Sample_CBP_BusinessDetail
) inner_q;
        --WHERE TRIM(PUREPOLICYNUMBER) = ''P00003184''


    ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.ANZSIC_RANK_02 AS
    SELECT  *
    FROM AGGNE.DEV.ANZSIC_RANK_01
    ORDER BY PUREPolicyNumber, Rank;


    ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.ANZSIC_RANK_03 AS
            WITH ranked AS (
                SELECT
                    CMLNumber,
                    PUREPolicyNumber,
                    Rank,
                    AnzsicCode_final as AnzsicCode,
                    AnzsicDescription_final as AnzsicDescription,
            
                    -- Equivalent to Count_ID (row number per PUREPolicyNumber)
                    ROW_NUMBER() OVER (
                        PARTITION BY PUREPolicyNumber
                        ORDER BY Rank
                    ) AS Count_ID,
            
                    -- Equivalent to LAG(AnzsicCode)
                    LAG(AnzsicCode) OVER (
                        PARTITION BY PUREPolicyNumber
                        ORDER BY Rank
                    ) AS Prev_AnzsicCode
            
                FROM AGGNE.DEV.ANZSIC_RANK_02
            )
            
            SELECT DISTINCT
                CMLNumber,
                PUREPolicyNumber,
                Rank,
                Count_ID,
                AnzsicCode,
                AnzsicDescription,
            
                -- SAS Logic:
                -- IF Count_ID = 1 THEN SelectANZSICLookup = AnzsicCode
                -- IF Count_ID = 2 THEN SelectANZSICLookup = LAG_AnzsicCode
                CASE
                    WHEN Count_ID = 1 THEN AnzsicCode
                    WHEN Count_ID = 2 THEN Prev_AnzsicCode
                END AS SelectANZSICLookup,
            
                -- SAS Logic:
                -- IF Count_ID = 2 THEN SecondaryANZSICLookup = AnzsicCode
                CASE
                    WHEN Count_ID = 2 THEN AnzsicCode
                    ELSE NULL
                END AS SecondaryANZSICLookup
            
            FROM ranked
            WHERE Count_ID IN (1, 2)
            ORDER BY PUREPolicyNumber, Rank;



        ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.ANZSIC_RANK_04 AS
            WITH src AS (
                SELECT
                    PUREPolicyNumber,
                    CMLNumber,
                    TRIM(SelectANZSICLookup)      AS SelectANZSICLookup,
                    TRIM(SecondaryANZSICLookup)   AS SecondaryANZSICLookup,
                    Count_ID,
            
                    /* Map descriptions for SelectANZSICLookup */
                    CASE TRIM(SelectANZSICLookup)
                        WHEN ''111111'' THEN ''Property Owners Only''
                        WHEN ''222222'' THEN ''Vehicles Only''
                        WHEN ''281901'' THEN ''Automotive Component Manufacturing''
                        WHEN ''462301'' THEN ''Motor Vehicle New Part and Accessories Wholesaling''
                        WHEN ''524502'' THEN ''Boat Dealers - no Manufacturing - including Servicing''
                        WHEN ''531103'' THEN ''Agricultural Machinery Dealers - Including Servicing''
                        WHEN ''531107'' THEN ''Motor Vehicle Dealers - New - excluding Servicing''
                        WHEN ''531108'' THEN ''Motor Vehicle Dealers - New - including Servicing''
                        WHEN ''531109'' THEN ''Motor Vehicle Dealers - Used - excluding Servicing''
                        WHEN ''531110'' THEN ''Motor Vehicle Dealers - Used - including Servicing''
                        WHEN ''531116'' THEN ''Motor Vehicle Wrecking - Used Parts Reseller''
                        WHEN ''531301'' THEN ''Motorcycle Dealers - New and Used - including Servicing''
                        WHEN ''531302'' THEN ''Trailer and Caravan Dealers''
                        WHEN ''532101'' THEN ''Service Station - excluding Servicing''
                        WHEN ''532103'' THEN ''Service Station - including Roadhouse - including Servicing''
                        WHEN ''532201'' THEN ''Automotive Electrical Services''
                        WHEN ''532301'' THEN ''Body/Smash Repair - Bus, Coach, Trucks and Heavy Machinery''
                        WHEN ''532302'' THEN ''Body/Smash Repair - Passenger - excluding Bus, Coach, Trucks and Heavy Machinery''
                        WHEN ''532401'' THEN ''Tyre Retailers and Repairers - excluding Retreading and Remolding''
                        WHEN ''532504'' THEN ''Automotive Mechanical Repairs - Mobile Mechanic''
                        WHEN ''532505'' THEN ''Automotive Mechanical Repairs - Workshop - excluding Smash Repairs''
                        WHEN ''532901'' THEN ''Automotive Engine Re-Conditioners''
                        WHEN ''532902'' THEN ''Automotive Exhaust and/or Suspension Specialists''
                        WHEN ''532903'' THEN ''Automotive Fuel Injection Services''
                        WHEN ''532904'' THEN ''Automotive LPG Fitters''
                        WHEN ''532905'' THEN ''Automotive Radiator Repairs''
                        WHEN ''532908'' THEN ''Automotive Windscreen Installation/Repair''
                        WHEN ''532909'' THEN ''Automotive Windscreen Tinting''
                        WHEN ''532912'' THEN ''Motor Vehicle Detailers''
                        WHEN ''532913'' THEN ''Tow Truck Operator''
                        WHEN ''540000'' THEN ''Automotive Fabrication and Engineering''
                        WHEN ''540001'' THEN ''Diesel Mechanic''
                        WHEN ''540002'' THEN ''Wrecker – Retailer Only''
                        WHEN ''540003'' THEN ''Service Station – excluding Roadhouse''
                        WHEN ''600001'' THEN ''Auto Masters''
                        WHEN ''600002'' THEN ''Ultra-Tune''
                        WHEN ''600003'' THEN ''Tyre Franchise''
                        WHEN ''774101'' THEN ''Motor Vehicle Hiring''
                        ELSE NULL
                    END AS SelectDesc,
            
                    /* Map descriptions for SecondaryANZSICLookup */
                    CASE TRIM(SecondaryANZSICLookup)
                        WHEN ''111111'' THEN ''Property Owners Only''
                        WHEN ''222222'' THEN ''Vehicles Only''
                        WHEN ''281901'' THEN ''Automotive Component Manufacturing''
                        WHEN ''462301'' THEN ''Motor Vehicle New Part and Accessories Wholesaling''
                        WHEN ''524502'' THEN ''Boat Dealers - no Manufacturing - including Servicing''
                        WHEN ''531103'' THEN ''Agricultural Machinery Dealers - Including Servicing''
                        WHEN ''531107'' THEN ''Motor Vehicle Dealers - New - excluding Servicing''
                        WHEN ''531108'' THEN ''Motor Vehicle Dealers - New - including Servicing''
                        WHEN ''531109'' THEN ''Motor Vehicle Dealers - Used - excluding Servicing''
                        WHEN ''531110'' THEN ''Motor Vehicle Dealers - Used - including Servicing''
                        WHEN ''531116'' THEN ''Motor Vehicle Wrecking - Used Parts Reseller''
                        WHEN ''531301'' THEN ''Motorcycle Dealers - New and Used - including Servicing''
                        WHEN ''531302'' THEN ''Trailer and Caravan Dealers''
                        WHEN ''532101'' THEN ''Service Station - excluding Servicing''
                        WHEN ''532103'' THEN ''Service Station - including Roadhouse - including Servicing''
                        WHEN ''532201'' THEN ''Automotive Electrical Services''
                        WHEN ''532301'' THEN ''Body/Smash Repair - Bus, Coach, Trucks and Heavy Machinery''
                        WHEN ''532302'' THEN ''Body/Smash Repair - Passenger - excluding Bus, Coach, Trucks and Heavy Machinery''
                        WHEN ''532401'' THEN ''Tyre Retailers and Repairers - excluding Retreading and Remolding''
                        WHEN ''532504'' THEN ''Automotive Mechanical Repairs - Mobile Mechanic''
                        WHEN ''532505'' THEN ''Automotive Mechanical Repairs - Workshop - excluding Smash Repairs''
                        WHEN ''532901'' THEN ''Automotive Engine Re-Conditioners''
                        WHEN ''532902'' THEN ''Automotive Exhaust and/or Suspension Specialists''
                        WHEN ''532903'' THEN ''Automotive Fuel Injection Services''
                        WHEN ''532904'' THEN ''Automotive LPG Fitters''
                        WHEN ''532905'' THEN ''Automotive Radiator Repairs''
                        WHEN ''532908'' THEN ''Automotive Windscreen Installation/Repair''
                        WHEN ''532909'' THEN ''Automotive Windscreen Tinting''
                        WHEN ''532912'' THEN ''Motor Vehicle Detailers''
                        WHEN ''532913'' THEN ''Tow Truck Operator''
                        WHEN ''540000'' THEN ''Automotive Fabrication and Engineering''
                        WHEN ''540001'' THEN ''Diesel Mechanic''
                        WHEN ''540002'' THEN ''Wrecker – Retailer Only''
                        WHEN ''540003'' THEN ''Service Station – excluding Roadhouse''
                        WHEN ''600001'' THEN ''Auto Masters''
                        WHEN ''600002'' THEN ''Ultra-Tune''
                        WHEN ''600003'' THEN ''Tyre Franchise''
                        WHEN ''774101'' THEN ''Motor Vehicle Hiring''
                        ELSE NULL
                    END AS SecondaryDesc,
            
                    /* emulate SAS LAST.PUREPolicyNumber -> keep last within group */
                    ROW_NUMBER() OVER (PARTITION BY PUREPolicyNumber ORDER BY Count_ID DESC) AS rn
                FROM AGGNE.DEV.ANZSIC_RANK_03
            )
            SELECT
                PUREPolicyNumber,
                CMLNumber,
                
                /* SelectANZSICLookup -> "code - description" */
                CASE
                    WHEN src.SelectANZSICLookup IS NULL OR src.SelectANZSICLookup = ''''
                        THEN src.SelectANZSICLookup
                    ELSE src.SelectANZSICLookup || '' - '' || COALESCE(src.SelectDesc, '''')
                END AS SelectANZSICLookup,
            
                /* SecondaryANZSICLookup: blank if equal to Select code, else "code - description" if not blank */
                CASE
                    WHEN src.SecondaryANZSICLookup IS NULL OR src.SecondaryANZSICLookup = ''''
                         OR src.SecondaryANZSICLookup = src.SelectANZSICLookup
                        THEN ''''
                    ELSE src.SecondaryANZSICLookup || '' - '' || COALESCE(src.SecondaryDesc, '''')
                END AS SecondaryANZSICLookup
            FROM src
            QUALIFY rn = 1;

            


        ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Business_Info_01 AS
           WITH BASE AS (
            SELECT DISTINCT
            a.*, b.SelectANZSICLookup, b.SecondaryANZSICLookup
            FROM AGGNE.DEV.Sample_CBP_BusinessDetail a
            LEFT JOIN AGGNE.DEV.ANZSIC_RANK_04 b USING (PUREPolicyNumber)
            
        )
        SELECT DISTINCT
            PUREPolicyNumber,
            CMLNumber,
            EXPIRINGID_P,
            SelectANZSICLookup,
            SecondaryANZSICLookup,

            -- Adjusted Turnover
             CASE WHEN IsPropOwnerOnly = 0 AND PublicAndProductLiability = 1 AND NVL(IsRunOffLiab,0) < 1
     THEN 
     CASE WHEN FuelSales = 1 THEN Turnover * (1 - FuelSalesPercent/100) WHEN FuelSales = 0 THEN Turnover ELSE 0 END 
     ELSE 0 END AS Turnover_Less_Fuel,

            -- Web Presence
            CASE WHEN IsWebPage_Temp = 1 THEN ''Yes'' ELSE ''No'' END AS IsWebPage,
            WebsiteAddress_Temp AS WebsiteAddress,

            -- Establishment and management details
            COALESCE(BusinessEstablishmentDate, YEAR(InceptionDate)) AS BusinessEstablishmentDate,
            ManagementProprietorsPartners_ AS ManagementProprietorsAndPartners,
            EngagedSalesWorkshopActivities_ + COALESCE(ContractorStaff_,0) AS EngagedSalesorWorkshopActivities,

            -- High Performance (Vehicle related)
            CASE WHEN (SalesHighPerformance=1 OR ServiceHighPerformance=1 OR RestoreHighPerformance=1) THEN 1 ELSE 0 END AS IsHighPerformance,
            ROUND(TurnoverHighPerformance / NULLIF(Turnover_Less_Fuel,0) * 100) AS VehicleTurnoverDetails_Perf,
            ROUND((TurnoverHighPerformance / NULLIF(Turnover_Less_Fuel,0)) * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_Perf,

            -- Antique/Classic Vehicles
            CASE WHEN (SalesAntiqueClassicCollector=1 OR ServiceAntiqueClassicCollector=1 OR RestoreAntiqueClassicCollector=1) THEN 1 ELSE 0 END AS IsAntiqueClassicCollector,
            ROUND(TurnoverAntiqueClassicCollector / NULLIF(Turnover_Less_Fuel,0) * 100) AS VehicleTurnoverDetails_ACC,
            ROUND((TurnoverAntiqueClassicCollector / NULLIF(Turnover_Less_Fuel,0)) * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_ACC,

            -- Watercraft
            CASE WHEN WatercraftRepair=1 THEN ''Yes'' ELSE ''No'' END AS IsWatercraftRepair,
            CASE WHEN WatercraftRepair=1 THEN ''No'' ELSE NULL END AS IsWaterWorkPerformed,
            WatercraftTurnoverDetails AS VehicleTurnoverDetails_Water,
            ROUND(WatercraftTurnoverDetails/100 * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_Water,

            -- Heavy Transport
            CASE WHEN HeavyTransportVehicles=1 THEN ''Yes'' ELSE ''No'' END AS IsHeavyTransportVehicles,
            HeavyVehiclesTransportDetails AS VehicleTurnoverDetails_Heavy,
            ROUND(HeavyVehiclesTransportDetails/100 * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_Heavy,

            -- Import & Manufacture
            CASE WHEN (ImportProducts=1 OR ManuProducts=1) THEN ''Yes'' ELSE ''No'' END AS IsProductsManufacturedorImported,
            (COALESCE(ImportDetails,0)+COALESCE(ManuDetails,0)) AS VehicleTurnoverDetails_ManIm,
            ROUND((COALESCE(ImportDetails,0)+COALESCE(ManuDetails,0))/100 * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_ManIm,

            -- Gearboxes
            CASE WHEN GearboxesRecondition=1 AND COALESCE(GearboxesDetails,0)>0 THEN ''Yes'' ELSE ''No'' END AS IsGearboxesRecondition,
            GearboxesDetails AS VehicleTurnoverDetails_Recon,
            ROUND(GearboxesDetails/100 * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_Recon,

            -- Construction
            CASE WHEN ConstructionServices=1 THEN ''Yes'' ELSE ''No'' END AS IsConstructionServices,
            ConstructionDetails AS VehicleTurnoverDetails_Const,
            ROUND(ConstructionDetails/100 * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_Const,

            -- Mining
            CASE WHEN MiningEquipmentServices=1 THEN ''Yes'' ELSE ''No'' END AS IsMiningEquipmentServices,
            CASE WHEN UndergroundMining=1 THEN ''Yes'' ELSE ''No'' END AS IsUndergroundMining,
            MiningDetails AS VehicleTurnoverDetails_Mine,
            ROUND(MiningDetails/100 * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_Mine,

            -- Sideline Business
            CASE WHEN SidelineBusinessEntity=1 THEN ''Yes'' ELSE ''No'' END AS IsSidelineBusinessEntity,
            CASE
                WHEN SidelineBusinessType_Temp IS NOT NULL AND SidelineBusinessType_Temp != '''' THEN SidelineBusinessType_Temp
                ELSE ''.''
            END AS SidelineBusinessType,
            TurnoverOfSidelineBusiness AS VehicleTurnoverDetails_Side,
            ROUND(TurnoverOfSidelineBusiness/100 * Turnover_Less_Fuel) AS VehicleTurnoverDisplay_Side,
            --Turnover_Less_Fuel

            -- Tyre Related
            CASE WHEN RetailOrManufacturerTyres=1 THEN ''Yes'' ELSE ''No'' END AS DoYouRetailOrManufacturerTyres,
            TyreSalesPercentage AS TyreSalesPercentageTurnover,
            ReTreadingPercentage AS ReTreadingPercentageTurnover,
            ImportingTyresPercentage AS ImportingTyresPercentageTurnover,
            ManufacturingTyresPercentage AS ManufacturingTyresPercTurnover,
            SalesOfSecondHandTyresPercentage AS SalesOfSecondHandPercTurnover,
            HeavyTransportTyresPercentage AS HeavyTransportTyresPercTurnover,
            ROUND(TyreSalesPercentage/100 * Turnover_Less_Fuel) AS TyreSalesTurnoverDisplay,
            ROUND(ReTreadingPercentage/100 * Turnover_Less_Fuel) AS ReTreadingTurnoverDisplay,
            ROUND(ImportingTyresPercentage/100 * Turnover_Less_Fuel) AS ImportingTyresTurnoverDisplay,
            ROUND(ManufacturingTyresPercentage/100 * Turnover_Less_Fuel) AS ManufacturingTyresTurnDisplay,
            ROUND(SalesOfSecondHandTyresPercentage/100 * Turnover_Less_Fuel) AS SalesOfSecondHandTurnDisplay,
            ROUND(HeavyTransportTyresPercentage/100 * Turnover_Less_Fuel) AS HeavyTransportTyresTurnDisplay,

            CASE
            WHEN SelectANZSICLookup = ''111111 - Property Owners Only''
             AND IsPropOwnerOnly = 0
             AND PublicAndProductLiability = 1
             AND COALESCE(IsRunOffLiab,NULL,0) < 1
             AND Turnover_Less_Fuel <> 0
            THEN ''532505 - Automotive Mechanical Repairs - Workshop - excluding Smash Repairs''
    
            WHEN SelectANZSICLookup = ''111111 - Property Owners Only''
             AND (
                    GeneralProperty = 1
                 OR GoodsInTransit = 1
                 OR ProfessionalProtection = 1
                 OR LegalExpenses = 1
                 OR TaxAudit = 1
                 OR (CommercialVehicles = 1 AND Fleet = 1)
             )
            THEN ''532505 - Automotive Mechanical Repairs - Workshop - excluding Smash Repairs''
    
            ELSE SelectANZSICLookup
        END AS SelectANZSICLookup_final,

            -- Derived vehicle flag (more than 30%)
            CASE WHEN ROUND(TurnoverHighPerformance / NULLIF(Turnover,0) * 100) > 30 THEN ''Yes'' ELSE ''No'' END AS IsVehicleTurnoverMorethan30

        FROM BASE;



    ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Business_Info_02 AS
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

        
 
   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Businessdetails_Final AS
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
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_HEAVYDUTYDIESEL hd USING (PUREPOLICYNUMBER)
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_TYREDEALER ty USING (PUREPOLICYNUMBER)
        QUALIFY
                ROW_NUMBER() OVER (
                    PARTITION BY p.PUREPolicyNumber
                    ORDER BY p.policyinceptiondate DESC
                ) = 1;
         --ORDER BY   PUREPOLICYNUMBER;

--------------------------------------------------1.4@@BusinessProtection@@end@@---------------------------------------------------------------------

--------------------------------------------------1.5@@CommercialVehicle@@start@@---------------------------------------------------------------------

	;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_CBP_CommercialVechicle AS
SELECT DISTINCT 
        t3.insurance_ref AS PUREPolicyNumber
	,t18.CBP_Policy_Binder_id AS ExpiringID_P
	,t3.insurance_file_cnt
	,CAST(t3.expiry_date AS DATE) AS ExpiryDate
	,t14.shortname AS CMLNumber
	,t13.description AS Country
	,t19.code AS Product
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_policy_binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_membercsl t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts t10 ON t6.party_cnt = T10.CLIENTID
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_policy_binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.product t19 ON (t3.product_id = t19.product_id)
WHERE 
--CAST(t3.expiry_date AS DATE) = CURRENT_DATE () + 45
	  SUBSTRING(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(t3.insurance_file_status_id,NULL,0) NOT IN (1, 2)
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
    AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		WHERE CAST(t13.expiry_date AS DATE) > CURRENT_DATE ()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				AND (status.insurance_file_status_id <> 1 OR status.insurance_file_status_id IS NULL)
			)
		)
ORDER BY ExpiryDate
	,PUREPolicyNumber;
	
	
	

;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CM_01 AS
SELECT 
 t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,t2.Product
	,CASE 
		WHEN TRIM(t2.Country) = ''New Zealand''
			THEN ''NZ''
		ELSE t4.RLState
		END AS STATE
	,t4.RLCommercialVehicles AS CommercialVehicles_Ind
	,
	/*Vehicle information*/
	t3.CBP_VEHICLEDETAIL_id AS VehicleID
	,t3.CMCVRegNo AS RegistrationNumber
	,t3.CMRBVehicleKey
	,t3.CMRBGrossVehMass /*PURE Field for testing only*/
	,t3.CMRBEngineSize /*PURE Field for testing only*/
	,CASE WHEN t3.CMCVOverride = 1 THEN t3.CMRBEngineSizeOV ELSE t3.CMRBEngineSize END AS EngineSize -- FIX G-BP-99
	,CASE WHEN t3.CMCVOverride = 1 THEN t3.CMRBGrossVehMassOV ELSE t3.CMRBGrossVehMass END AS GrossVehicleMass -- FIX G-BP-99
	,t3.CMCVTypeVeh
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVTypeVeh = 1
			THEN ''Passenger Vehicle''
		WHEN t3.CMCVTypeVeh = 2
			THEN ''Caravan''
		WHEN t3.CMCVTypeVeh = 3
			THEN ''Camper Van''
		WHEN t3.CMCVTypeVeh = 4
			THEN ''Motorcycle''
		WHEN t3.CMCVTypeVeh = 5
			THEN ''Trailer''
		WHEN t3.CMCVTypeVeh = 6
			THEN CASE 
					WHEN (
							t3.CMRBEngineSize >= 11000
							OR t3.CMRBEngineSizeOV >= 11000
							)
						THEN ''Heavy Commercial''
					WHEN (
							t3.CMRBEngineSize < 11000
							AND t3.CMRBGrossVehMass >= 11000
							)
						OR (
							t3.CMRBEngineSizeOV < 11000
							AND t3.CMRBGrossVehMassOV >= 11000
							)
						THEN ''Heavy Commercial''
					WHEN (
							t3.CMRBEngineSize < 11000
							AND t3.CMRBGrossVehMass < 11000
							)
						OR (
							t3.CMRBEngineSizeOV < 11000
							AND t3.CMRBGrossVehMassOV < 11000
							)
						THEN ''Light Commercial''
					ELSE ''''
					END
		WHEN t3.CMCVTypeVeh IN (
				7
				,8
				)
			THEN ''Heavy Commercial''
		WHEN t3.CMCVTypeVeh = 9
			THEN ''Forklift''
		WHEN t3.CMCVTypeVeh = 10
			THEN CASE 
					WHEN UPPER(t3.CMCVMake) = ''FORKLIFT''
						OR UPPER(t3.CMCVModel) = ''FORKLIFT''
						THEN ''Forklift''
					WHEN UPPER(t3.CMCVMake) = ''1930ES''
						AND UPPER(t3.CMCVModel) = ''SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''2.3 TON DIGGER''
						AND UPPER(t3.CMCVModel) = ''PLANT TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''A1''
						AND UPPER(t3.CMCVModel) = ''CAR TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''AMMANN''
						AND UPPER(t3.CMCVModel) = ''ARX16 ROLLER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''AUSTRAC''
						AND UPPER(t3.CMCVModel) = ''MINI DIGGER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''BARTCO''
						AND UPPER(t3.CMCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) IN (
							''BOA''
							,''BOAPOD''
							,''BOA POD''
							,''BOAPOD HYDRAULIC''
							,''BOA HUB''
							,''BOA POD HYDRAULIC HOSE''
							)
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''BOBCAT''
						AND UPPER(t3.CMCVModel) = ''753''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''BOBCAT''
						AND UPPER(t3.CMCVModel) = ''S185 SKIDSTEER LOADER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''BOX TRAILER WITH BUILDERS'''' RACKS AND GAS CYLINDER MOUNTS''
						AND UPPER(t3.CMCVModel) = ''TANDEM AXLE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''BRUNO CHARIOT''
						AND UPPER(t3.CMCVModel) = ''CHARIO DLT''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''BUGGY''
						AND UPPER(t3.CMCVModel) = ''OFF ROAD''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''BX23SLB-AU EXCAVATOR''
						AND UPPER(t3.CMCVModel) = ''BX23SLB-AU EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) IN (
							''CAN-AM''
							,''CANNEM''
							,''CAN AM''
							,''CAM AM''
							)
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''CASE''
						AND UPPER(t3.CMCVModel) = ''IH S88K BACKHOE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''CATERPILALR''
						AND UPPER(t3.CMCVModel) = ''SKID STEER LOADER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''CATERPILLAR''
						AND UPPER(t3.CMCVModel) = ''EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''CATERPILLER FRONT END LOADER''
						AND UPPER(t3.CMCVModel) = ''MODEL 906''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''CF''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''CF MOTO''
						AND UPPER(t3.CMCVModel) = ''CFORCE1000''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''COASTMAC''
						AND UPPER(t3.CMCVModel) = ''EXCAVATOR TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''CUSTOM''
						AND UPPER(t3.CMCVModel) = ''GO KART''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''CUSTOM''
						AND UPPER(t3.CMCVModel) = ''HYDRAULIC HOSE TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''CUSTOM ALUMINIUM TRAILER WITH COMPRESSOR''
						AND UPPER(t3.CMCVModel) = ''TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''CUSTOM ALUMINIUM TRAILER WITH MOUNTED COMPRESSOR TRAILER''
						AND UPPER(t3.CMCVModel) = ''COMPRESSOR TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''CUSTOM BUILT TRAILER''
						AND UPPER(t3.CMCVModel) = ''WITH AC TESTING UNIT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''CUSTOM GO KART''
						AND UPPER(t3.CMCVModel) = ''ARROW X6.2''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''DINGO''
						AND UPPER(t3.CMCVModel) = ''35DT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''DJ CUSTOM FAB''
						AND UPPER(t3.CMCVModel) = ''CRANE TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''EAGLE''
						AND UPPER(t3.CMCVModel) = ''GOLF CART''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''ESCAVATOR''
						AND UPPER(t3.CMCVModel) = ''KOBELCO SK17SR''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''E-TECH''
						AND UPPER(t3.CMCVModel) = ''PLUS, SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''EXCAVATOR''
						AND UPPER(t3.CMCVModel) = ''KUBOTA U17-3''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''FASSI M30A''
						AND UPPER(t3.CMCVModel) = ''CRANE''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''FFE TRAILER''
						AND UPPER(t3.CMCVModel) = ''DIG TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''GENIE''
						AND UPPER(t3.CMCVModel) = ''G-3246 SCISSOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''HANDYMAX''
						AND UPPER(t3.CMCVModel) = ''WHEEL LOADER HM22''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''HAULOTTE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''HAVLOTTE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''HBH LINMAC''
						AND UPPER(t3.CMCVModel) = ''CRANE''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''HIGHWAY''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''HIGHWAY1''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''HITACHI''
						AND UPPER(t3.CMCVModel) = ''EX22 DIGGER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''HOME MADE''
						AND UPPER(t3.CMCVModel) = ''BOX TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''HOMEBUILT TRAILER''
						AND UPPER(t3.CMCVModel) = ''VMS''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''HUSKI''
						AND UPPER(t3.CMCVModel) = ''M16U EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''HUSQVARNA''
						AND UPPER(t3.CMCVModel) = ''FC250''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''HYDRAULIC EXCAVATOR''
						AND UPPER(t3.CMCVModel) = ''CATERPILLAR 301.5-05''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''INDUSTRIAL''
						AND UPPER(t3.CMCVModel) = ''TOILET''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''INTER''
						AND UPPER(t3.CMCVModel) = ''MOBILE CRANE''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''ISUZU''
						AND UPPER(t3.CMCVModel) = ''N SERIES''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''IVECO''
						AND UPPER(t3.CMCVModel) = ''EURO CARGO 18T GVM TILT TRAY WITH WHEEL LIFT & HIAB''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''JCB''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''JOHN DEERE''
						AND UPPER(t3.CMCVModel) = ''BOBCAT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KANGA''
						AND UPPER(t3.CMCVModel) = ''MINI LOADER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KANGA''
						AND UPPER(t3.CMCVModel) = ''PW628''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KAWASAKI''
						AND UPPER(t3.CMCVModel) = ''KAF400''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''KITCHEN''
						AND UPPER(t3.CMCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''KOBELCO''
						AND UPPER(t3.CMCVModel) = ''45 COUPE EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KOBELCO''
						AND UPPER(t3.CMCVModel) = ''SK010SRD-7''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KOBELCO''
						AND UPPER(t3.CMCVModel) = ''SK140 SRD-7''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KOBELCO''
						AND UPPER(t3.CMCVModel) = ''SK140SRD-7''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KOBELCO''
						AND UPPER(t3.CMCVModel) = ''SK35SR-6''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KOBELCO''
						AND UPPER(t3.CMCVModel) = ''SK405R-5''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KOMATSU''
						AND UPPER(t3.CMCVModel) = ''DIGGER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KOMATSU''
						AND UPPER(t3.CMCVModel) = ''PC220-7 22T EXCAVATOR''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KRB''
						AND UPPER(t3.CMCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''KUBOTA''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KUBOTA SVL75-2''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KUBOTA U17''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''KUBOTA U27-4 DIGGER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''LAWNMASTER''
						AND UPPER(t3.CMCVModel) = ''37 TONNE LOG SPLITTER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''LOG  SPLITTER''
						AND UPPER(t3.CMCVModel) = ''LOG SPLITTER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''LUIGONG''
						AND UPPER(t3.CMCVModel) = ''9035E''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''MACK''
						AND UPPER(t3.CMCVModel) = ''METROLINER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''MAZDA''
						AND UPPER(t3.CMCVModel) = ''RX7''
						THEN ''Passenger Vehicle''
					WHEN UPPER(t3.CMCVMake) = ''NEW HOLLAND''
						AND UPPER(t3.CMCVModel) = ''C327''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''NEW HOLLAND''
						AND UPPER(t3.CMCVModel) = ''SKID STEER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''NUSSA AUSTRALIAN PORTABLE TOILET''
						AND UPPER(t3.CMCVModel) = ''TT1''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''OEM''
						AND UPPER(t3.CMCVModel) = ''HOTTIE IV PRESSURE CLEANER TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''POLARIS''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''RHINOCEROS MINI EXCAVATOR''
						AND UPPER(t3.CMCVModel) = ''XN12-8''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''RHINOSAUR''
						AND UPPER(t3.CMCVModel) = ''XN10-2B''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''RIZER''
						AND UPPER(t3.CMCVModel) = ''S03-E, SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''SHERMAC SERVICE TRAILER''
						AND UPPER(t3.CMCVModel) = ''SHERMAC SERVICE TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''SKID STEER LOADER''
						AND UPPER(t3.CMCVModel) = ''S630''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''SKYJACK''
						AND UPPER(t3.CMCVModel) = ''SCISSOR LIFT''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''SKYJACK''
						AND UPPER(t3.CMCVModel) = ''SJ1113219''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''SKYJACK 15FT''
						AND UPPER(t3.CMCVModel) = ''SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''SNORKEL''
						AND UPPER(t3.CMCVModel) = ''S2255RT ROUGH TERRAIN SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''SNORKEL SCISSOR LIFT''
						AND UPPER(t3.CMCVModel) = ''S3219E''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''SPIT''
						AND UPPER(t3.CMCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''TAKEUCHI''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TCM''
						AND UPPER(t3.CMCVModel) = ''800S''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TEREX TRAILER MOUNT LIGHTING TOWER''
						AND UPPER(t3.CMCVModel) = ''GENIE AL4000''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TORO''
						AND UPPER(t3.CMCVModel) = ''2500 TITAN MOWER''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''TORO''
						AND UPPER(t3.CMCVModel) = ''RIDE ON MOWER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TORO''
						AND UPPER(t3.CMCVModel) = ''TX1000 DINGO''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TOYOTA''
						AND UPPER(t3.CMCVModel) = ''30-5SKD8''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TOYOTA''
						AND UPPER(t3.CMCVModel) = ''FORKLIFT''
						THEN ''Forklift''
					WHEN UPPER(t3.CMCVMake) = ''TRAILER''
						AND UPPER(t3.CMCVModel) = ''HOME BUILT''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''TRAILER''
						AND UPPER(t3.CMCVModel) = ''MESSAGE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TRAILER''
						AND UPPER(t3.CMCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''TRAILERED ATLAS 65''
						AND UPPER(t3.CMCVModel) = ''COMPRESSOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TRUCK ROLLER BRAKE TESTER''
						AND UPPER(t3.CMCVModel) = ''TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''TS TRAILERS''
						AND UPPER(t3.CMCVModel) = ''FLATBED''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''UBCO''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''UHI''
						AND UPPER(t3.CMCVModel) = ''UME18 MINI EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''UNIVERSAL MAXTRAY''
						AND UPPER(t3.CMCVModel) = ''TRAILER HOSE BOA''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''VALLKREE''
						AND UPPER(t3.CMCVModel) = ''ELECTRIC PUSH BIKE''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''VAN DEMONS''
						AND UPPER(t3.CMCVModel) = ''PIG TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''VENTECH''
						AND UPPER(t3.CMCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''VERMAC''
						AND UPPER(t3.CMCVModel) = ''CUSTOM TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.CMCVMake) = ''WACKER NEUSON''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''XCMG''
						THEN ''Light Commercial''
					WHEN UPPER(t3.CMCVMake) = ''YAMAHA''
						THEN ''Motorcycle''
					WHEN UPPER(t3.CMCVMake) = ''YANMAR''
						AND UPPER(t3.CMCVModel) = ''DIGGER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''YANMAR''
						AND UPPER(t3.CMCVModel) = ''V4 LOADER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.CMCVMake) = ''YANMAR''
						AND UPPER(t3.CMCVModel) = ''VI020-3 MINI EXCAVATOR''
						THEN ''Light Commercial''
					ELSE ''''
					END
		ELSE ''''
		END AS VehicleType
	,t3.CMCVMake AS Make
	,t3.CMCVModel AS Model
	,t3.CMCVYear AS Year
	,t3.CMCVOverride
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVOverride = 1
			THEN ''Yes''
		WHEN t3.CMCVOverride IN (2)
			THEN ''''
		ELSE ''''
		END AS Override
	,
	/*redbook details only when override = yes else DC to do API call on redbook to populate those fields*/
	t3.CMCVDescription
	,/*PURE Field for testing only*/
	t3.CMCVDescriptionOV AS Description
	,t3.CMCVBodyType
	,/*PURE Field for testing only*/
	t3.CMCVBodyTypeOV
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVOverride = 1
			THEN CASE 
					WHEN t3.CMCVBodyTypeOV = 1
						THEN ''Sedan''
					WHEN t3.CMCVBodyTypeOV = 2
						THEN ''Coupe''
					WHEN t3.CMCVBodyTypeOV = 3
						THEN ''Wagon''
					WHEN t3.CMCVBodyTypeOV = 4
						THEN ''Hatchback''
					WHEN t3.CMCVBodyTypeOV = 5
						THEN ''Van''
					WHEN t3.CMCVBodyTypeOV = 6
						THEN ''Cab Chassis''
					WHEN t3.CMCVBodyTypeOV = 7
						THEN ''Utility''
					WHEN t3.CMCVBodyTypeOV = 8
						THEN ''Convertible''
					WHEN t3.CMCVBodyTypeOV = 9
						THEN ''Other''
					ELSE ''''
					END
		ELSE CMCVBodyType
		END AS BodyType
	,t3.CMRBCylinders
	,/*PURE Field for testing only*/
	t3.CMRBCylindersOV
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVOverride = 1
			THEN CASE 
					WHEN t3.CMRBCylindersOV = 1
						THEN 1
					WHEN t3.CMRBCylindersOV = 2
						THEN 2
					WHEN t3.CMRBCylindersOV = 3
						THEN 3
					WHEN t3.CMRBCylindersOV = 4
						THEN 4
					WHEN t3.CMRBCylindersOV = 5
						THEN 5
					WHEN t3.CMRBCylindersOV = 6
						THEN 6
					WHEN t3.CMRBCylindersOV = 7
						THEN 8
					WHEN t3.CMRBCylindersOV = 8
						THEN 10
					WHEN t3.CMRBCylindersOV = 9
						THEN 12
					WHEN t3.CMRBCylindersOV = 10
						THEN 16
					WHEN t3.CMRBCylindersOV = 11
						THEN 0
					ELSE NULL
					END
		ELSE CMRBCylinders
		END AS NumberOfCylinders
	,t3.CMRBDriveDescription
	,/*PURE Field for testing only*/
	t3.CMRBDriveDescriptionOV
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVOverride = 1
			THEN CASE 
					WHEN t3.CMRBDriveDescriptionOV = 1
						THEN ''Front wheel drive''
					WHEN t3.CMRBDriveDescriptionOV = 2
						THEN ''Rear wheel drive''
					WHEN t3.CMRBDriveDescriptionOV = 3
						THEN ''4 wheel drive''
					WHEN t3.CMRBDriveDescriptionOV = 4
						THEN ''N/A''
					ELSE ''''
					END
		ELSE CMRBDriveDescription
		END AS DriveDescription
	,t3.CMRBInduction
	,/*PURE Field for testing only*/
	t3.CMRBInductionOV
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVOverride = 1
			THEN CASE 
					WHEN t3.CMRBInductionOV = 1
						THEN ''Aspirated''
					WHEN t3.CMRBInductionOV = 2
						THEN ''Turbocharged''
					WHEN t3.CMRBInductionOV = 3
						THEN ''Supercharged''
					WHEN t3.CMRBInductionOV = 4
						THEN ''Turbo and supercharged''
					WHEN t3.CMRBInductionOV = 5
						THEN ''''
					ELSE ''''
					END
		ELSE CMRBInduction
		END AS InductionType
	,t3.CMRBImportFlag
	,/*PURE Field for testing only*/
	t3.CMRBImportFlagOV
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVOverride = 1
			THEN CASE 
					WHEN t3.CMRBImportFlagOV = 1
						THEN ''I''
					WHEN t3.CMRBImportFlagOV = 2
						THEN ''L''
					WHEN t3.CMRBImportFlagOV = 3
						THEN ''N/A ''
					ELSE ''''
					END
		ELSE CMRBImportFlag
		END AS ImportFlag
	,
	/*Standard protection*/
	t3.CMCVProtectionType
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVProtectionType = 1
			THEN ''Comprehensive - Market Value''
		WHEN t3.CMCVProtectionType = 2
			THEN ''Comprehensive - Agreed Value''
		WHEN t3.CMCVProtectionType = 3
			THEN ''Third Party, Fire and Theft''
		WHEN t3.CMCVProtectionType = 4
			THEN ''Third Party Only''
		WHEN t3.CMCVProtectionType = 5
			THEN ''Fire and Theft''
		ELSE ''''
		END AS ProtectionType
	,
	/*MARKET VALUE*/
	CASE 
		WHEN (
				t3.CMCVOverride = 1
				AND t3.CMCVProtectionType <> 2
				)
			THEN t3.CMCVMarketValue
		ELSE NULL
		END AS MVValueWithoutAccessories
	,/*market value w/O accesories*/
	CASE 
		WHEN (
				t3.CMCVProtectionType <> 2
				AND t3.CMCVVehModList = ''''
				AND t3.CMCVVehModValue IS NULL
				)
			THEN ''No''
		WHEN (
				t3.CMCVProtectionType <> 2
				AND t3.CMCVVehModList <> ''''
				AND t3.CMCVVehModValue > 0
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVProtectionType <> 2
				AND t3.CMCVVehModList <> ''''
				AND t3.CMCVVehModValue < 0
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVProtectionType <> 2
				AND t3.CMCVVehModList <> ''''
				AND t3.CMCVVehModValue = 0
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVProtectionType <> 2
				AND t3.CMCVVehModList = ''''
				AND t3.CMCVVehModValue > 0
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVProtectionType <> 2
				AND t3.CMCVVehModList = ''''
				AND t3.CMCVVehModValue < 0
				)
			THEN ''Yes''
		ELSE ''No''
		END AS MVAddAccOrMods
	,/*WouldYouLikeToAddAccessoriesOrModifications*/
	CASE 
		WHEN t3.CMCVProtectionType <> 2
			THEN t3.CMCVVehModList
		ELSE ''''
		END AS MarketValueDescription
	,CASE 
		WHEN t3.CMCVProtectionType <> 2
			THEN t3.CMCVVehModValue
		ELSE NULL
		END AS MarketValueDescriptionValue
	,
	/*MVValueWithoutAccessories + MarketValueDescriptionValue = MarketValueWithAccessoriesAmount*/
	t3.CMCVPrincipalUse
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVPrincipalUse IN (
				1
				,4
				,5
				,6
				,0
				)
			THEN ''General Business''
		WHEN t3.CMCVPrincipalUse = 2
			THEN ''Courtesy''
		WHEN t3.CMCVPrincipalUse = 3
			THEN ''Hire''
		WHEN t3.CMCVProtectionType = 5
			THEN ''General Business''
		ELSE ''''
		END AS HighestRiskUse
	,
	/*AGREED VALUE*/
	t3.CMCVAgreedValue
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVProtectionType = 2
			THEN (t3.CMCVAgreedValue - t3.CMCVVehModValue)
		ELSE NULL
		END AS AVValueWithoutAccessories
	,/*agreed value w/O accesories*/
	CASE 
		WHEN (
				t3.CMCVProtectionType = 2
				AND t3.CMCVVehModList = ''''
				AND t3.CMCVVehModValue IS NULL
				)
			THEN ''No''
		WHEN (
				t3.CMCVProtectionType = 2
				AND t3.CMCVVehModList <> ''''
				AND t3.CMCVVehModValue > 0
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVProtectionType = 2
				AND t3.CMCVVehModList <> ''''
				AND t3.CMCVVehModValue < 0
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVProtectionType = 2
				AND t3.CMCVVehModList <> ''''
				AND t3.CMCVVehModValue = 0
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVProtectionType = 2
				AND t3.CMCVVehModList = ''''
				AND t3.CMCVVehModValue > 0
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVProtectionType = 2
				AND t3.CMCVVehModList = ''''
				AND t3.CMCVVehModValue < 0
				)
			THEN ''Yes''
		ELSE ''No''
		END AS AVAddAccOrMods
	,/*WouldYouLikeToAddAccessoriesOrModifications*/
	CASE 
		WHEN t3.CMCVProtectionType = 2
			THEN t3.CMCVVehModList
		ELSE ''''
		END AS AgreedValueDescription
	,CASE 
		WHEN t3.CMCVProtectionType = 2
			THEN t3.CMCVVehModValue
		ELSE NULL
		END AS agreedValueDescriptionValue
	,
	/*AVValueWithoutAccessories + agreedValueDescriptionValue = agreedvalueamount*/
	t3.CMCVYoungestDriver AS AgeOfYoungestRegularDriver
	,t3.CMCVAgeRestriction
	,/*PURE Field for testing only*/
	t5.CAText
	,/*PURE Field for testing only*/
	t5.CADescription
	,/*PURE Field for testing only*/
	/*below code needs changes so when you see words like Protection is extended to drivers under the age of 21. This overrides any driver age restriction showing on this vehicle.
change this value to no restiction and not CM_C05_HVNOAR*/
	CASE 
		WHEN (
				UPPER(t5.CADescription) LIKE ''%THIS OVERRIDES ANY DRIVER AGE RESTRICTION SHOWING ON THIS VEHICLE%''
				AND UPPER(t5.CAText) <> ''CM_C05_HVNOAR''
				)
			THEN ''No Restriction''
		WHEN t3.CMCVAgeRestriction = 1
			THEN ''No Restriction''
		WHEN t3.CMCVAgeRestriction = 2
			THEN ''Min Age 21''
		WHEN t3.CMCVAgeRestriction = 3
			THEN ''Min Age 25''
		WHEN t3.CMCVAgeRestriction = 4
			THEN ''Min Age 30''
		WHEN t3.CMCVAgeRestriction = 5
			THEN ''Min Age 40''
		ELSE ''''
		END AS RestrictionOfDriverAge
	,t3.CMCVTPFinInterest
	,/*PURE Field for testing only*/
	CASE 
		WHEN (
				t3.CMCVTPFinInterest = 1
				AND t3.CMCVTPFinInterestDet <> ''''
				)
			THEN ''Yes''
		WHEN (
				t3.CMCVTPFinInterest = 1
				AND t3.CMCVTPFinInterestDet = ''''
				)
			THEN ''No''
		WHEN t3.CMCVTPFinInterest = 0
			THEN ''No''
		ELSE ''''
		END AS VehHaveAnInterestedParty /*DoesTheVehicleHaveAnInterestedParty*/
	,t3.CMCVTPFinInterestDet AS DetForTheParty
	,/*AddDetailsForTheInterestedParty*/
	/*optional protection*/
	/*on hook*/
	t3.CMCVCoverHookLiab
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVCoverHookLiab = 1
			THEN 0
		WHEN t3.CMCVCoverHookLiab = 2
			THEN 100000
		WHEN t3.CMCVCoverHookLiab = 3
			THEN 200000
		WHEN t3.CMCVCoverHookLiab = 4
			THEN 200000
		WHEN t3.CMCVCoverHookLiab = 5
			THEN 300000
		ELSE NULL
		END AS OnHookTowingProtection
	,t3.CMCVCarryingVehs
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVCarryingVehs = 1
			THEN 1
		WHEN t3.CMCVCarryingVehs = 2
			THEN 2
		WHEN t3.CMCVCarryingVehs = 3
			THEN 3
		WHEN t3.CMCVCarryingVehs = 4
			THEN 4
		WHEN t3.CMCVCarryingVehs = 5
			THEN 5
		WHEN t3.CMCVCarryingVehs = 6
			THEN 6
		WHEN t3.CMCVCarryingVehs > 6
			THEN 6
		ELSE NULL
		END AS HowManyVehicles /*HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime*/
	,t3.CMCVDeliverFreq
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVDeliverFreq = 1
			THEN ''''
		WHEN t3.CMCVDeliverFreq = 2
			THEN ''Daily''
		WHEN t3.CMCVDeliverFreq = 3
			THEN ''Weekly''
		WHEN t3.CMCVDeliverFreq = 4
			THEN ''Less Frequent''
		ELSE ''''
		END AS HowOften /*HowOftenDoYouPickUpOrDeliverVehicles*/
	,
	/*other optional covers*/
	t3.CMCVChoiceRepair
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVProtectionType <> 4
			THEN CASE 
					WHEN t3.CMCVChoiceRepair = 1
						THEN ''Taken''
					WHEN t3.CMCVChoiceRepair = 0
						THEN ''Not Taken''
					ELSE ''''
					END
		ELSE ''''
		END AS ChoiceOfRepair
	,t3.CMCVCarHire
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVProtectionType <> 4
			THEN CASE 
					WHEN t3.CMCVCarHire = 1
						THEN ''Taken''
					WHEN t3.CMCVCarHire = 0
						THEN ''Not Taken''
					ELSE ''''
					END
		ELSE ''''
		END AS HireCarHireAfterIncident
	,t3.CMCVUnlimGlass
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVProtectionType IN (
				1
				,2
				)
			THEN CASE 
					WHEN t3.CMCVUnlimGlass = 1
						THEN ''Yes''
					WHEN t3.CMCVUnlimGlass = 0
						THEN ''No''
					ELSE ''''
					END
		ELSE ''''
		END AS ExcessWaiverForGlass
	,
	/*Underwriting questions - heavy vehicles*/
	/*HowOftenIsTheVehicleUsed - refer to commercialmotor_Datamapping csv*/
	/*IsTheVehicleUsedForMembersBusinessNeedsOnly- refer to commercialmotor_Datamapping csv*/
	/*Details- refer to commercialmotor_Datamapping csv*/
	t3.CMCVTransHazGoods
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.CMCVTransHazGoods = 1
			THEN ''Yes''
		WHEN t3.CMCVTransHazGoods = 0
			THEN ''No''
		ELSE ''''
		END AS TransHazardGoods /*VehicleTransportHazardousDangerousGoods*/
	,t3.CMCVTransHazGoodsDetail AS Details
	,
	/*IsTheVehicleUsedToTransportAnyCustomerItemsReward- refer to commercialmotor_Datamapping csv*/
	/*Details- refer to commercialmotor_Datamapping csv*/
	t3.CMCVRadiusFromBase /*PURE Field for testing only*/
	,CASE 
		WHEN t3.CMCVRadiusFromBase = 1
			THEN ''''
		WHEN t3.CMCVRadiusFromBase = 2
			THEN ''<100kms''
		WHEN t3.CMCVRadiusFromBase IN (
				3
				,4
				)
			THEN ''100-500kms''
		WHEN t3.CMCVRadiusFromBase = 5
			THEN ''500kms+''
		ELSE ''''
		END AS MaximumRange /*MaximumRangeVehicleWillTravelBusinessUse*/
	,
	/*IsTheVehicleDrivenByDirectEmployeesOnly- refer to commercialmotor_Datamapping csv*/
	/*Details- refer to commercialmotor_Datamapping csv*/
	/*IfPrimeMoverWillItTowMoreThan1TrailerAtTime- refer to commercialmotor_Datamapping csv*/
	/*Details- refer to commercialmotor_Datamapping csv*/
	/*Underwriting questions - hire vehicles*/
	/*IsThisVehicleUsedForRideShareOperation- refer to commercialmotor_Datamapping csv*/
	/*AreHireContractsRestrictedToNamedDriversOnly- refer to commercialmotor_Datamapping csv*/
	/*AreAnyVehiclesDriverSupplied- refer to commercialmotor_Datamapping csv*/
	/*Underwriting questions - delivery vehicles*/
	/*WillAnyContractorsOperateThisVehicle- refer to commercialmotor_Datamapping csv*/
	/*WillThisVehicleBeUsedToDeliverDangerousGoods- refer to commercialmotor_Datamapping csv*/
	/*excesses*/
	t3.CMCVVoluntary /*PURE Field for testing only*/
	,CASE 
		WHEN t3.CMCVVoluntary IS NULL
			THEN NULL
		WHEN t3.CMCVVoluntary = 0
			THEN 0
		WHEN t3.CMCVVoluntary <= 250
			THEN 250
		WHEN t3.CMCVVoluntary <= 500
			THEN 500
		WHEN t3.CMCVVoluntary <= 750
			THEN 750
		WHEN t3.CMCVVoluntary <= 1000
			THEN 1000
		WHEN t3.CMCVVoluntary <= 1250
			THEN 1250
		WHEN t3.CMCVVoluntary > 1250
			THEN 1500
		END AS VoluntaryExcess
FROM AGGNE.DEV.Sample_CBP_CommercialVechicle t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL t3 ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
-- ============================================================
-- FIX [C5]: CM_01 — CBP_CLAUSEAMENDMENTCM JOIN missing vehicle-level key
-- SAS LOGIC (CommercialVehicles_conversionscriptCapricorn, PROC SQL):
--   LEFT JOIN P_NO_PII.CBP_CLAUSEAMENDMENTCM t5
--     ON (t2.CBP_Policy_Binder_id = t5.CBP_Policy_Binder_id
--         AND t3.CBP_VEHICLEDETAIL_id = t5.CBP_VEHICLEDETAIL_id)
-- ISSUE: Join was only on Policy_Binder_id (policy level). Clause amendments are vehicle-level
--        records (one per vehicle). Without the vehicle key, each vehicle row cross-joins with
--        all clause amendment records for the policy, producing cartesian multiplied output rows.
-- OLD CODE: LEFT JOIN CBP_CLAUSEAMENDMENTCM t5 ON t2.ExpiringID_P = t5.CBP_Policy_Binder_id
-- ============================================================
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_CLAUSEAMENDMENTCM t5
    ON t2.ExpiringID_P = t5.CBP_Policy_Binder_id
    AND t3.CBP_VEHICLEDETAIL_id = t5.CBP_VEHICLEDETAIL_id





;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CM_02 AS
WITH
-- 1) Base: bring in source and uppercase clause fields
base AS (
  SELECT
    *,
    UPPER(CAText)       AS Clause_Text,
    UPPER(CADescription) AS Clause_Desc
  FROM AGGNE.DEV.CM_01
),

--SELECT * FROM CM_01
-- 2) Accessories parsing: derive Result_String per delimiter precedence
accessory_parsed AS (
  SELECT
    *,
    CASE
      WHEN POSITION(''CM_C06_MODSACCS'' IN COALESCE(Clause_Text, '''')) > 0
        OR POSITION(''ACCESSORIES'' IN COALESCE(Clause_Text, '''')) > 0
        OR POSITION(''MODIFICATION'' IN COALESCE(Clause_Text, '''')) > 0
      THEN
        CASE
          WHEN POSITION(''INCLUDES'' IN COALESCE(Clause_Desc, '''')) > 0
            THEN LTRIM(SUBSTR(CADescription, POSITION(''INCLUDES'' IN COALESCE(Clause_Desc, '''')) + 8))
          WHEN POSITION(''INCLUDE '' IN COALESCE(Clause_Desc, '''')) > 0
            THEN LTRIM(SUBSTR(CADescription, POSITION(''INCLUDE '' IN COALESCE(Clause_Desc, '''')) + 8))
          WHEN POSITION(''INCLUDE:'' IN COALESCE(Clause_Desc, '''')) > 0
            THEN LTRIM(SUBSTR(CADescription, POSITION(''INCLUDE:'' IN COALESCE(Clause_Desc, '''')) + 8))
          WHEN POSITION(''MODIFICATIONS:'' IN COALESCE(Clause_Desc, '''')) > 0
            THEN LTRIM(SUBSTR(CADescription, POSITION(''MODIFICATIONS:'' IN COALESCE(Clause_Desc, '''')) + 14))
          ELSE CADescription
        END
      ELSE NULL
    END AS Result_String
  FROM base
),

-- 3) Set Market/Agreed descriptions and flags based on protection type
market_agreed AS (
  SELECT
    *,
    -- ============================================================
    -- FIX [C6a]: CM_02 market_agreed CTE — Accessories fields were commented out
    -- SAS LOGIC (CommercialVehicles_conversionscriptCapricorn, DATA step):
    --   IF CMCVProtectionType NE 2 AND Result_String NE '' THEN MVAddAccOrMods = "Yes";
    --   IF CMCVProtectionType = 2 THEN AgreedValueDescription = Result_String;
    --   IF CMCVProtectionType = 2 AND Result_String NE '' THEN AVAddAccOrMods = "Yes";
    -- ISSUE: MVAddAccOrMods, AgreedValueDescription, AVAddAccOrMods were commented out,
    --        producing NULL for all policies with accessories/modifications in agreed-value vehicles.
    -- OLD CODE (commented out — incorrect):
    -- --CASE WHEN CMCVProtectionType <> 2 THEN ''Yes'' END AS MVAddAccOrMods,
    -- --CASE WHEN CMCVProtectionType = 2 THEN Result_String END AS AgreedValueDescription,
    -- --CASE WHEN CMCVProtectionType = 2 THEN ''Yes'' END AS AVAddAccOrMods
    -- ============================================================
    CASE WHEN CMCVProtectionType <> 2 THEN Result_String END AS MarketValueDescription_temp,
    CASE WHEN CMCVProtectionType <> 2 AND Result_String IS NOT NULL THEN ''Yes'' END AS MVAddAccOrMods,
    CASE WHEN CMCVProtectionType = 2 THEN Result_String END AS AgreedValueDescription,
    CASE WHEN CMCVProtectionType = 2 AND Result_String IS NOT NULL THEN ''Yes'' END AS AVAddAccOrMods
  FROM accessory_parsed
)
-- select *  from market_agreed
,


-- 4) Override flag and VehicleType by explicit CMRBVehicleKey mapping
vehiclekey_map AS (
  SELECT
    *,
    -- ============================================================
    -- FIX [C6b]: CM_02 vehiclekey_map CTE — Override flag was commented out
    -- SAS LOGIC (CommercialVehicles_conversionscriptCapricorn, DATA step):
    --   IF CMRBVehicleKey = '' THEN Override = "Yes";
    -- ISSUE: Override was commented out → always NULL → override_fill CTE CASE expressions
    --        (WHEN OVERRIDE = ''Yes'') never triggered → CMRBEngineSize/BodyType/etc overrides
    --        never applied even when CMRBVehicleKey is blank.
    -- OLD CODE (commented out — incorrect):
    -- --CASE WHEN COALESCE(CMRBVehicleKey, '''') = '''' THEN ''Yes'' END AS Override,
    -- ============================================================
    CASE WHEN COALESCE(CMRBVehicleKey, '''') = '''' THEN ''Yes'' ELSE Override END AS Override,
    CASE
      WHEN CMRBVehicleKey = ''AUVTOYO1994AEGZ'' THEN ''Heavy Commercial''
      WHEN CMRBVehicleKey = ''AUVISUZ2009AEDN'' THEN ''Heavy Commercial''
      WHEN CMRBVehicleKey = ''AUVFORD2009AEIU'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVTOYO2001AEIZ'' THEN ''Heavy Commercial''
      WHEN CMRBVehicleKey = ''AUVISUZ2006AECF'' THEN ''Heavy Commercial''
      WHEN CMRBVehicleKey = ''AUVTOYO2001AEID'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''NZVMERC2002AEEX'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVFUSO2013AEDU'' THEN ''Heavy Commercial''
      WHEN CMRBVehicleKey = ''AUVVOLK2006AEIL'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVTOYO2005AEGO'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVVOLK2008AEHM'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVTOYO2011AECU'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVHOLD1991AECN'' THEN ''Passenger Vehicle''
      WHEN CMRBVehicleKey = ''AUVGWM_2021AEAC'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVFIAT2018AEAR'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVLDV_2020AEAM'' THEN ''Light Commercial''
      WHEN CMRBVehicleKey = ''AUVTOYO2021AEBK'' THEN ''Light Commercial''
      ELSE NULL
    END AS VehicleType_byKey
  FROM market_agreed
)
-- select MVADDACCORMODS,* from vehiclekey_map
,

-- 5) Apply override fallback copy of vehicle attributes when Override=''Yes'' AND CMCVOverride = 0
override_fill AS (
  SELECT
    *,
    COALESCE(VehicleType_byKey, VEHICLETYPE) AS VehicleType_mapped, -- Apply the key mapping
    -- Copy engine/body/grossmass/description fields from CMRB/CMCV sources when override conditions met
    CASE WHEN OVERRIDE = ''Yes'' AND COALESCE(CMCVOverride, 0) = 0 THEN CMRBEngineSize ELSE EngineSize END AS EngineSize_f,
    CASE WHEN OVERRIDE = ''Yes'' AND COALESCE(CMCVOverride, 0) = 0 THEN CMCVBodyType ELSE BodyType END AS BodyType_f,
    CASE WHEN OVERRIDE = ''Yes'' AND COALESCE(CMCVOverride, 0) = 0 THEN CMRBGrossVehMass ELSE GrossVehicleMass END AS GrossVehicleMass_f,
    CASE WHEN OVERRIDE = ''Yes'' AND COALESCE(CMCVOverride, 0) = 0 THEN CMCVDescription ELSE Description END AS Description_f,
    CASE WHEN OVERRIDE = ''Yes'' AND COALESCE(CMCVOverride, 0) = 0 THEN CMRBCylinders ELSE NumberOfCylinders END AS NumberOfCylinders_f,
    CASE WHEN OVERRIDE = ''Yes'' AND COALESCE(CMCVOverride, 0) = 0 THEN CMRBDriveDescription ELSE DriveDescription END AS DriveDescription_f,
    CASE WHEN OVERRIDE = ''Yes'' AND COALESCE(CMCVOverride, 0) = 0 THEN CMRBInduction ELSE InductionType END AS InductionType_f,
    CASE WHEN OVERRIDE = ''Yes'' AND COALESCE(CMCVOverride, 0) = 0 THEN CMRBImportFlag ELSE ImportFlag END AS ImportFlag_f
  FROM vehiclekey_map
)
-- select MarketValueDescription,* from override_fill 
,

-- 6) If BodyType blank after override copy, map BodyType by Make & Model per provided mappings
bodytype_from_make_model AS (
  SELECT
    *,
    -- Determine BodyType: prefer BodyType_f if exists, else map by Make/Model rules
    COALESCE(NULLIF(BodyType_f, ''''), 
      CASE
        WHEN UPPER(Make) = ''FORD''    AND UPPER(Model) = ''RANGER''           THEN ''Utility''
        WHEN UPPER(Make) = ''FORD''    AND UPPER(Model) = ''TERRIRTORY''       THEN ''Wagon''
        WHEN UPPER(Make) = ''LEXUS''   AND UPPER(Model) = ''NX300''            THEN ''Wagon''
        WHEN UPPER(Make) = ''TOYOTA''  AND UPPER(Model) = ''HIACE''            THEN ''Van''
        WHEN UPPER(Make) = ''TOYOTA''  AND UPPER(Model) = ''CAMRY''            THEN ''Sedan''
        WHEN UPPER(Make) = ''TOYOTA''  AND UPPER(Model) = ''LANDCRUISER PRADO'' THEN ''Wagon''
        WHEN UPPER(Make) = ''BMW''     AND UPPER(Model) = ''X5''               THEN ''Wagon''
        WHEN UPPER(Make) = ''MAZDA''   AND UPPER(Model) = ''BT-50''            THEN ''Utility''
        WHEN UPPER(Make) = ''MAZDA''   AND UPPER(Model) = ''T4000''            THEN ''Transporter''
        WHEN UPPER(Make) = ''MAZDA''   AND UPPER(Model) = ''3''                THEN ''Hatchback''
        WHEN UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''CANTER''        THEN ''Tow Truck''
        WHEN UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''PAJERO''        THEN ''Wagon''
        WHEN UPPER(Make) = ''SUBARU''   AND UPPER(Model) = ''LIBERTY''         THEN ''Wagon''
        WHEN UPPER(Make) = ''HYUNDAI''  AND UPPER(Model) = ''I30''             THEN ''Hatchback''
        WHEN UPPER(Make) = ''VOLKSWAGEN'' AND UPPER(Model) = ''CADDY''         THEN ''Van''
        WHEN UPPER(Make) = ''MERCEDES'' AND UPPER(Model) = ''AMG-C''           THEN ''Sedan''
        WHEN UPPER(Make) = ''MAZDA''    AND UPPER(Model) = ''RX7''             THEN ''Coupe''
        WHEN UPPER(Make) = ''FORD''     AND (UPPER(Model) = ''MUSTANG'' OR UPPER(Model) = ''GALAXIE COUPE'') THEN ''Coupe''
        WHEN UPPER(Make) = ''MCC''      AND UPPER(Model) = ''SMART COUPE''      THEN ''Coupe''
        WHEN UPPER(Make) = ''VOLKSWAGEN'' AND UPPER(Model) = ''GOLF''          THEN ''Hatchback''
        -- ... include other mappings that set BodyType from the long list
        ELSE BodyType_f
      END
    ) AS BodyType_mapped
  FROM override_fill
)
-- select MarketValueDescription,* from bodytype_from_make_model
,

-- 7) Additional Make/Model based VehicleType and BodyType mappings (applies when Override=''Yes'' or general rules)
make_model_rules AS (
  SELECT
    *,
    COALESCE(VEHICLETYPE_BYKEY,
      CASE
        WHEN Override = ''Yes'' AND UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''ROSA'' THEN ''Heavy Commercial''
        WHEN Override = ''Yes'' AND UPPER(Make) = ''LIFTSMART'' AND UPPER(Model) = ''LS-RT35'' THEN ''Forklift''
        WHEN UPPER(Make) IN (''CAN-AM'', ''CANNEM'', ''CAN AM'', ''CAM AM'') THEN ''Motorcycle''
        WHEN UPPER(Make) = ''HINO'' AND UPPER(Model) = ''RANGER'' THEN ''Heavy Commercial''
        WHEN UPPER(Make) = ''CUSTOM'' AND UPPER(Model) = ''BOXTOP TRAILER'' THEN ''Trailer''
        WHEN UPPER(Make) = ''CUSTOM BUILT'' AND (UPPER(Model) = ''TANDEM CAR TRAILER'' OR UPPER(Model) = ''TANDEM TRAILER'') THEN ''Trailer''
        WHEN UPPER(Make) = ''KINGS'' AND UPPER(Model) = ''TANDEM BOX TRAILER'' THEN ''Trailer''
        WHEN UPPER(Make) = ''JOHN PAPAS'' AND UPPER(Model) = ''FLAT TOP TRAILER'' THEN ''Trailer''
        WHEN UPPER(Make) = ''LOTUS'' AND UPPER(Model) = ''CARAVAN TROOPER'' THEN ''Caravan''
        WHEN UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''CANTA'' THEN ''Heavy Commercial''
        WHEN UPPER(Make) = ''POLARIS'' AND (UPPER(Model) = ''RZR XP 1000'' OR UPPER(Model) = ''RANGER'') THEN ''Motorcycle''
        WHEN UPPER(Make) = ''YAMAHA'' AND UPPER(Model) = ''ATV'' THEN ''Motorcycle''
        WHEN UPPER(Make) = ''DOMINO'' AND UPPER(Model) = ''BUS'' THEN ''Light Commercial''
        WHEN UPPER(Make) = ''MERCEDES BENZ'' AND UPPER(Model) = ''COACH'' THEN ''Light Commercial''
        WHEN UPPER(Make) = ''SUPREME'' AND UPPER(Model) = ''CARAVAN'' THEN ''Caravan''
        WHEN UPPER(Make) = ''TANDEM'' AND UPPER(Model) = ''CAR TRAILER'' THEN ''Trailer''
        WHEN UPPER(Make) = ''TCM FHG18T3'' AND UPPER(Model) = ''4 WHEEL BUGGY'' THEN ''Forklift''
        WHEN UPPER(Make) = ''KOMATSU'' AND UPPER(Model) = ''FG18'' THEN ''Forklift''
        WHEN UPPER(Make) = ''MOPED'' AND UPPER(Model) = ''KIWI 50'' THEN ''Motorcycle''
        WHEN UPPER(Make) = ''HECTON'' AND UPPER(Model) = ''DUAL AXEL TRAILER'' THEN ''Trailer''
        WHEN UPPER(Make) = ''HINO'' AND UPPER(Model) = ''DUTRO SERVICE TRUCK'' THEN ''Heavy Commercial''
        WHEN UPPER(Make) = ''KUBOTA'' AND UPPER(Model) = ''UME15'' THEN ''Light Commercial''
        WHEN UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''FM SERIES TRUCK'' THEN ''Heavy Commercial''
        WHEN UPPER(Make) = ''TRAILER CAR TRANSPORTER'' AND UPPER(Model) = ''COMMERCIAL TRAILER'' THEN ''Trailer''
        WHEN UPPER(Make) = ''HOMEBUILT'' AND (UPPER(Model) = ''BBQ TRAILER'' OR UPPER(Model) = ''BRENT SMITH TRAILER'') THEN ''Trailer''
        WHEN UPPER(Make) = ''BONAZA'' AND UPPER(Model) = ''TRAILER'' THEN ''Trailer''
        WHEN UPPER(Make) = ''CMADE CUSTOMER CARAVAN'' AND UPPER(Model) = ''TRAILER'' THEN ''Trailer''
        WHEN UPPER(Make) = ''FORD'' AND UPPER(Model) = ''N0915'' THEN ''Light Commercial''
        WHEN UPPER(Make) = ''TOYOTA'' AND UPPER(Model) = ''DYNA'' THEN ''Light Commercial''
        WHEN UPPER(Make) = ''NISSAN'' AND UPPER(Model) = ''ATLAS'' THEN ''Light Commercial''
        WHEN UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''FUSO SHOGUN'' THEN ''Heavy Commercial''
        WHEN UPPER(Make) = ''MITSUBISHI'' AND (UPPER(Model) = ''FUSO FV315HR'' OR UPPER(Model) = ''FUSO CANTER'' OR UPPER(Model) = ''FUSO'') THEN ''Light Commercial''
        WHEN UPPER(Make) = ''HINO'' AND UPPER(Model) = ''FS'' THEN ''Heavy Commercial''
        WHEN UPPER(Make) = ''ISUZU'' AND (UPPER(Model) = ''ELF'' OR UPPER(Model) = ''N SERIES'' OR UPPER(Model) = ''NPR SERIES TRUCK'') THEN ''Light Commercial''
        WHEN UPPER(Make) = ''TCM FORKLIFT'' AND UPPER(Model) = ''FG25T3'' THEN ''Forklift''
        -- default to existing vehicle type mapping if none of the above matched
        ELSE VEHICLETYPE_BYKEY
      END
    ) AS VEHICLETYPE_BYKEY,

    -- BodyType fallback: if vehicle type implies a body type or other rules
    CASE
      WHEN VEHICLETYPE_BYKEY = ''Trailer'' THEN ''Trailer''
      WHEN VEHICLETYPE_BYKEY = ''Motorcycle'' THEN ''Motorcycle''
      WHEN VEHICLETYPE_BYKEY = ''Forklift'' THEN ''Forklift''
      WHEN VEHICLETYPE_BYKEY = ''Caravan'' THEN ''Caravan''
      WHEN VEHICLETYPE_BYKEY = ''Camper Van'' THEN ''Camper Van''
      WHEN VEHICLETYPE_BYKEY = ''Heavy Commercial'' AND BodyType_mapped = ''Utility'' THEN ''Tow Truck'' -- as per SAS logic
      WHEN VEHICLETYPE_BYKEY = ''Light Commercial'' AND BodyType_mapped IN (''Cab Chassis'', ''Sedan'', ''Other'') THEN ''Tow Truck''
      WHEN VEHICLETYPE_BYKEY = ''Heavy Commercial'' AND BodyType_mapped IN (''Cab Chassis'',''Hatchback'',''Other'') THEN ''Transporter''
      ELSE BodyType_mapped
    END AS BodyType_mapped2
  FROM bodytype_from_make_model
)
-- select MarketValueDescription,* from make_model_rules
,

-- 8) Post-processing adjustments: default texts, numeric adjustments, restrictions etc.
post_adjustments AS (
  SELECT
    *,
    -- Market/Agreed default texts
    CASE WHEN (COALESCE(MarketValueDescription, '''') = '''') AND COALESCE(MVAddAccOrMods, '''') = ''Yes''
         THEN ''Not provided''
         ELSE MarketValueDescription END AS MarketValueDescription2,

    CASE WHEN (COALESCE(AgreedValueDescription, '''') = '''') AND COALESCE(AVAddAccOrMods, '''') = ''Yes''
         THEN ''Not provided''
         ELSE AgreedValueDescription END AS AgreedValueDescription2,

    -- AVValueWithoutAccessories logic: set to CMCVAgreedValue if null when protection type = 2
    CASE WHEN CMCVProtectionType = 2 AND AVValueWithoutAccessories IS NULL THEN CMCVAgreedValue
         ELSE AVValueWithoutAccessories END AS AVValueWithoutAccessories2,

    -- RestrictionOfDriverAge default
    CASE WHEN CMCVProtectionType IN (1,2,4) AND COALESCE(RestrictionOfDriverAge, '''') = '''' THEN ''No Restriction''
         ELSE RestrictionOfDriverAge END AS RestrictionOfDriverAge2,

    -- VehHaveAnInterestedParty flag
    CASE WHEN CMCVTPFinInterest = 2 THEN ''No'' ELSE VehHaveAnInterestedParty END AS VehHaveAnInterestedParty2,

    -- CMCVAgreedValue adjustments for minimum and agreedValueDescriptionValue ratio
    -- note: need to compute carefully: these derive new values from original CMCVAgreedValue and agreedValueDescriptionValue
    -- step A: handle minimum of 2000 when protection type = 2
    CASE
      WHEN CMCVProtectionType = 2 AND COALESCE(CMCVAgreedValue,0) < 2000 THEN 2000
      WHEN CMCVProtectionType = 2 THEN CMCVAgreedValue
      ELSE NULL
    END AS CMCVAgreedValue_step1,

    -- step B: handle ratio condition: if agreedValueDescriptionValue > (CMCVAgreedValue * 0.9) then increase CMCVAgreedValue by 10% and set agreedValueDescriptionValue to 80% of new value
    CASE
      WHEN CMCVProtectionType = 2
           AND COALESCE(agreedValueDescriptionValue,0) > COALESCE(CMCVAgreedValue,0) * 0.9
      THEN (COALESCE(CMCVAgreedValue,0) * 1.1)
      ELSE COALESCE(CMCVAgreedValue,0)
    END AS CMCVAgreedValue_step2,
    CASE
      WHEN CMCVProtectionType = 2
           AND COALESCE(agreedValueDescriptionValue,0) > COALESCE(CMCVAgreedValue,0) * 0.9
      THEN (COALESCE(CMCVAgreedValue,0) * 0.8)
      ELSE agreedValueDescriptionValue
    END AS agreedValueDescriptionValue_step2
  FROM make_model_rules
)
--select top 1 * from post_adjustments 
,

-- 9) Finalize numeric and flag fields, and apply SAS semantics for resetting fields when CMCVProtectionType != 2
final_calc AS (
  SELECT
	-- select original key columns
	PUREPolicyNumber,
    ExpiringID_P,
    CMLNumber,
    ExpiryDate,
    Country,
    Product,
    State,
    VehicleID,
    RegistrationNumber,
    EngineSize,
    GrossVehicleMass,
    CMCVChoiceRepair,
    Make,
    Model,
    Year,
    Override,
    Description,
    NumberOfCylinders,
    DriveDescription,
    InductionType,
    ImportFlag_f AS ImportFlag,
    ProtectionType,
    MVValueWithoutAccessories,
    MarketValueDescription,
    MarketValueDescriptionValue,
    HighestRiskUse,
    AgreedValueDescription,
    AgeOfYoungestRegularDriver,
    DetForTheParty,
    OnHookTowingProtection,
    HowManyVehicles,
    HowOften,
    ChoiceOfRepair,
    HireCarHireAfterIncident,
    ExcessWaiverForGlass,
    TransHazardGoods,
    Details,
    MaximumRange,
    VoluntaryExcess,
    CMCVVOLUNTARY,
    CMCVTPFinInterest
    -- AV value
    ,CASE WHEN CMCVProtectionType = 2 THEN COALESCE(AVValueWithoutAccessories2, CMCVAgreedValue) ELSE NULL END AS AVValueWithoutAccessories,

    -- CMCVAgreedValue rules - combine the step1 and step2 logic to produce final agreed value
    CASE
      WHEN CMCVProtectionType = 2
        THEN CASE
              WHEN COALESCE(agreedValueDescriptionValue,0) > COALESCE(CMCVAgreedValue,0) * 0.9
                THEN COALESCE(CMCVAgreedValue,0) * 1.1
              WHEN COALESCE(CMCVAgreedValue,0) < 2000
                THEN 2000
              ELSE CMCVAgreedValue
             END
      ELSE NULL
    END AS CMCVAgreedValue_final,

    -- Recompute agreedValueDescriptionValue if it was adjusted
    CASE
      WHEN CMCVProtectionType = 2 AND COALESCE(agreedValueDescriptionValue,0) > COALESCE(CMCVAgreedValue,0) * 0.9
        THEN COALESCE(CMCVAgreedValue,0) * 0.8
      ELSE agreedValueDescriptionValue
    END AS agreedValueDescriptionValue_final,

    -- Reset / blank fields depending on protection type
    CASE WHEN CMCVProtectionType = 2 THEN '''' ELSE NULL END AS MVAddAccOrMods,
    CASE WHEN CMCVProtectionType <> 2 THEN NULL ELSE AVAddAccOrMods END AS AVAddAccOrMods,

    -- Restriction Of Driver Age & interested party flags
    RestrictionOfDriverAge2 AS RestrictionOfDriverAge,
    VehHaveAnInterestedParty2 AS VehHaveAnInterestedParty,

    -- Other fields copied through
    CommercialVehicles_Ind,
    CMRBVehicleKey,
        COALESCE(CommercialVehicles_Ind,0) AS CommercialVehicles_Ind_f,
    -- Keep columns needed later or required in output (you can add/remove as needed)
    -- Also keep CMCVProtectionType for downstream logic if desired
    CMCVProtectionType,
    -- keep raw original values for auditing if desired
    CMCVAgreedValue_final AS CMCVAgreedValue, 
    agreedValueDescriptionValue_final AS AGREEDVALUEDESCRIPTIONVALUE,
    
    COALESCE(VehicleType_mapped, '''') AS VehicleType, 
    COALESCE(BodyType_mapped2, '''') AS BodyType,
    CMCVCARRYINGVEHS,
    CMCVRADIUSFROMBASE,
    CMCVTRANSHAZGOODS,
    CMCVCOVERHOOKLIAB,
    cmcvcarhire,
    cmcvunlimglass
  FROM post_adjustments
)
--select  top 1 * from final_calc
,

-- 10) Filter: remove records where CommercialVehicles_Ind = 0 (SAS DELETE)
filtered AS (
  SELECT *
  FROM final_calc
  WHERE COALESCE(CommercialVehicles_Ind_f, 0) <> 0
)
-- select * from filtered
-- Final projection: drop the fields you wanted to DROP in SAS and output cleaned rows
SELECT DISTINCT
     t2.PUREPolicyNumber,
    ExpiringID_P,
    CMLNumber,
    ExpiryDate,
    Country,
    Product,
    State,
    t2.VehicleID,
    RegistrationNumber,
    CMRBVehicleKey,
    CMCVChoiceRepair,
    CMCVVOLUNTARY,
    EngineSize,
    GrossVehicleMass,
    VehicleType,
    Make,
    Model,
    Year,
    Override,
    t2.Description,
    BodyType,
    NumberOfCylinders,
    DriveDescription,
    InductionType,
    ImportFlag,
    ProtectionType,
    MVValueWithoutAccessories,
    MVAddAccOrMods,
    MarketValueDescription,
    MarketValueDescriptionValue,
    HighestRiskUse,
    CMCVAgreedValue,
    AVValueWithoutAccessories,
    AVAddAccOrMods,
    AgreedValueDescription,
    agreedValueDescriptionValue,
    AgeOfYoungestRegularDriver,
    RestrictionOfDriverAge,
    VehHaveAnInterestedParty,
    DetForTheParty,
    OnHookTowingProtection,
    HowManyVehicles,
    HowOften,
    ChoiceOfRepair,
    HireCarHireAfterIncident,
    ExcessWaiverForGlass,
    TransHazardGoods,
    Details,
    MaximumRange,
    VoluntaryExcess,
    CMCVTPFinInterest,
    t9.dcclausetype,
    t9.dcinput,
    t6.FREQOFVEHUSE,
    t6.FORMEMBUS,
    t6.TRANSPORTCUSTITEM,
    t6.PRIMEMOVERTOWGT1TRAILER,
    t6.detailsmembus,
    t6.detailscustitem,
    t6.drivebydirectemp,
    t6.detailsdirectemp,
    t6.detailstowgt1,
    t7.RIDESHARE,
    t7.CONTRACTRESTRICTION,
    t7.HIREVEHDRIVERSUPPLIED,
    CMCVCARRYINGVEHS,
    CMCVRADIUSFROMBASE,
    CMCVTRANSHAZGOODS,
   ''CONTRACTOROPERATE'' AS CONTRACTOROPERATE , --t8.CONTRACTOROPERATE,
   ''DELIVERDANGEROUSGOOD'' AS DELIVERDANGEROUSGOOD,-- t8.DELIVERDANGEROUSGOOD,
    CMCVCOVERHOOKLIAB,
    cmcvcarhire,
    cmcvunlimglass
FROM filtered t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_CMHEAVY t6 ON t2.vehicleid = t6.vehicleid
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_CMHIRE t7 ON t2.vehicleid = t7.vehicleid
-- LEFT JOIN DEV_T5_EXTERNAL_AGGNE.RISK.REFERENCE_UW_QU_CMDELIVERY t8 ON t2.vehicleid = t8.vehicleid
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE t9 ON t2.vehicleid = t9.purevehicleid;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CM_03 AS 
WITH CM_02_DATA AS (
    SELECT * FROM CM_02
),

Deduplicate_Data AS (
    SELECT
        t1.*,
        ROW_NUMBER() OVER (
            PARTITION BY PUREPolicyNumber, EXPIRINGID_P,VEHICLEID
            ORDER BY RestrictionOfDriverAge DESC -- Last record based on full sort order
        ) AS RowRank
    FROM CM_02 t1
),

Filtered_Data AS (
    SELECT
        *
    FROM Deduplicate_Data
    WHERE RowRank = 1 -- Selects the single, final record for each vehicle group
)

-- Final SELECT statement to implement the DROP = list from the SAS Data Step
SELECT *
FROM Filtered_Data
ORDER BY PUREPolicyNumber;


 --------------------------------------------------1.5@@CommercialVehicle@@end@@---------------------------------------------------------------------

 --------------------------------------------------1.6@@FleetVehicle@@start@@---------------------------------------------------------------------
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_CBP_fleetvehicle AS
SELECT DISTINCT t3.insurance_ref AS PUREPolicyNumber
	,t18.CBP_Policy_Binder_id AS ExpiringID_P
	,t3.insurance_file_cnt
	,CAST(t3.expiry_date AS DATE) AS ExpiryDate
	,t14.shortname AS CMLNumber
	,t13.description AS Country
	,t19.code AS Product
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_policy_binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_membercsl t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts t10 ON t6.party_cnt = T10.clientid
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_policy_binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.product t19 ON (t3.product_id = t19.product_id)
WHERE
	--CAST(t3.expiry_date AS DATE) = CURRENT_DATE() + 45
	SUBSTRING(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(T3.insurance_file_status_id,NULL,0) NOT IN (1, 2) /* (1=Cancelled, 2=Lapsed) */
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
    AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		WHERE CAST(t13.expiry_date AS DATE) > CURRENT_DATE ()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				AND (STATUS.insurance_file_status_id <> 1 OR STATUS.insurance_file_status_id IS NULL) /* (1=Cancelled) */
			)
		)
ORDER BY ExpiryDate
	,PUREPolicyNumber;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.FL_01 AS

SELECT DISTINCT t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,t4.RLFleetVehicles AS FleetVehicles_Ind
	 ,CASE 
		WHEN t5.RLFleetVehicles = 1
			AND t4.RLINTPARTIES = 1
			THEN ''Yes''
		ELSE ''No''
		END AS HaveInterestedParty
	,CASE 
		WHEN t5.RLFleetVehicles = 1
			AND t4.RLINTPARTIES = 1
			THEN t5.RLFullName
		ELSE ''''
		END AS AdditonalParty

	/*standard protections*/
	,t3.FVProtectionType
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.FVProtectionType = 1
			THEN ''Comprehensive''
		WHEN t3.FVProtectionType = 3
			THEN ''Third Party, Fire and Theft''
		WHEN t3.FVProtectionType = 4
			THEN ''Third Party Only''
		WHEN t3.FVProtectionType = 5
			THEN ''Third Party, Fire and Theft''
		ELSE ''''
		END AS ProtectionType
	,t3.FVAgeRestriction
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.FVAgeRestriction = 1
			THEN ''No Restriction''
		WHEN t3.FVAgeRestriction = 2
			THEN ''Min Age 21''
		WHEN t3.FVAgeRestriction = 3
			THEN ''Min Age 25''
		WHEN t3.FVAgeRestriction = 4
			THEN ''Min Age 30''
		WHEN t3.FVAgeRestriction = 5
			THEN ''Min Age 40''
		ELSE ''''
		END AS RestrictionOfDriverAge
	,
	/*Optional Protection*/
	t3.FVChoiceRepair
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.FVProtectionType <> 4
			THEN CASE 
					WHEN t3.FVChoiceRepair = 1
						THEN ''Taken''
					WHEN t3.FVChoiceRepair = 0
						THEN ''Not Taken''
					ELSE ''''
					END
		ELSE ''''
		END AS ChoiceOfRepair
	,t3.FVCarHire
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.FVProtectionType <> 4
			THEN CASE 
					WHEN t3.FVCarHire = 1
						THEN ''Taken''
					WHEN t3.FVCarHire = 0
						THEN ''Not Taken''
					ELSE ''''
					END
		ELSE ''''
		END AS CarHire
	,t3.FVUnlimGlass
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.FVProtectionType = 1
			THEN CASE 
					WHEN t3.FVUnlimGlass = 1
						THEN ''Protected''
					WHEN t3.FVUnlimGlass = 0
						THEN ''Not Protected''
					ELSE ''''
					END
		ELSE ''''
		END AS UnlimitedGlass
	,t3.FVCoverHookLiab
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.FVCoverHookLiab = 1
			THEN 0
		WHEN t3.FVCoverHookLiab = 2
			THEN 100000
		WHEN t3.FVCoverHookLiab = 3
			THEN 150000
		WHEN t3.FVCoverHookLiab = 4
			THEN 200000
		WHEN t3.FVCoverHookLiab = 5
			THEN 250000
		ELSE NULL
		END AS OnHook
	,
	/*excesses*/
	t3.FVVoluntaryExcess
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.FVVoluntaryExcess IS NULL
			THEN NULL
		WHEN t3.FVVoluntaryExcess = 0
			THEN 0
		WHEN t3.FVVoluntaryExcess <= 250
			THEN 250
		WHEN t3.FVVoluntaryExcess <= 500
			THEN 500
		WHEN t3.FVVoluntaryExcess <= 750
			THEN 750
		WHEN t3.FVVoluntaryExcess <= 1000
			THEN 1000
		WHEN t3.FVVoluntaryExcess <= 1250
			THEN 1250
		WHEN t3.FVVoluntaryExcess > 1250
			THEN 1500
		END AS VoluntaryExcess
	,t6.REGISTRATIONSTATE
	,t6.REGISTRATIONNUMBER
	,t6.HIGHESTRISKUSE
	,t6.ACCESSORIESDESCRIPTION
	,t6.ACCESSORIESVALUE
	,t6.year
	,t6.MAKE
	,t6.MODEL
	,t6.DESCRIPTION
	,t6.BODYTYPE
	,t6.ENGINESIZE
	,t6.NUMBEROFCYLINDERS
	,t6.INDUCTIONTYPE
	,t6.GROSSVEHICLEMASS
	,t6.ADDACCESSORIES
	,t7.TAXIREGISTRATION
	,t7.OWNOTHERBUS
	,t7.IDLEVEHSTORED
	,t7.DETAILS_LOCRISKMIT
	,''AreContEmpDriver'' AS AreContEmpDriver  --t8.AreContEmpDriver
	,''DeliverDangerousGood'' AS DeliverDangerousGood  --t8.DeliverDangerousGood
	,''YearsExperienceDelivery'' AS YearsExperienceDelivery --t8.YearsExperienceDelivery
	,t9.Rideshare
	,t9.PercFLRideshare
	,t9.ContractRestriction
	,t9.HireVehDriverSupplied
	,t9.YearsExperiencehire
    ,t10.dcinput
    ,t10.dcclausetype
FROM AGGNE.DEV.Sample_CBP_fleetvehicle t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_fleetvehicles t3 ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id 
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_interestedparties t5 ON (t2.ExpiringID_P = t5.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.FLEET_TEMPLATE t6 ON TRIM(t2.ExpiringID_P) = TRIM(t6.purepolicybinderid)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_FLGENERAL t7 ON TRIM(t2.ExpiringID_P) = TRIM(t7.purepolicybinder)
-- LEFT JOIN dev_t5_external_aggne.risk.reference_uw_qu_fldelivery t8 ON TRIM(t2.ExpiringID_P) = TRIM(t8.purepolicybinder)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_FLHIRE t9 ON TRIM(t2.ExpiringID_P) = TRIM(t9.purepolicybinder)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE t10 ON TRIM(t2.ExpiringID_P) = TRIM(t10.purepolicybinderid)
WHERE FleetVehicles_Ind = 1;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.VehicleCoverages_FleetVehicle AS
SELECT  DISTINCT
PUREPOLICYNUMBER,
EXPIRINGID_P,
CMLNUMBER,
EXPIRYDATE,
COUNTRY,
HaveInterestedParty,
AdditonalParty,
PROTECTIONTYPE,
RESTRICTIONOFDRIVERAGE,
CHOICEOFREPAIR,
CARHIRE,
UNLIMITEDGLASS,
ONHOOK,
VOLUNTARYEXCESS,
REGISTRATIONSTATE,
REGISTRATIONNUMBER,
HIGHESTRISKUSE,
ACCESSORIESDESCRIPTION,
ACCESSORIESVALUE,
year,
MAKE,
MODEL,
DESCRIPTION,
BODYTYPE,
ENGINESIZE,
NUMBEROFCYLINDERS,
INDUCTIONTYPE,
GROSSVEHICLEMASS,
ADDACCESSORIES,
TAXIREGISTRATION,
OWNOTHERBUS,
IDLEVEHSTORED,
DETAILS_LOCRISKMIT,
AreContEmpDriver,
DeliverDangerousGood,
YearsExperienceDelivery,
Rideshare,
PercFLRideshare,
ContractRestriction,
HireVehDriverSupplied,
YearsExperiencehire,
dcinput,
dcclausetype
FROM FL_01
ORDER BY PUREPOLICYNUMBER;

 --------------------------------------------------1.5@@FleetVehicle@@end@@---------------------------------------------------------------------

 --------------------------------------------------1.6@@Locationdetails@@start@@---------------------------------------------------------------------
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_CBP_lOCATION AS
SELECT DISTINCT 
	t3.insurance_ref AS PUREPolicyNumber
	,t18.CBP_Policy_Binder_id AS ExpiringID_P
    ,t14.shortname AS CMLNumber
    ,t3.expiry_date AS ExpiryDate
	,t3.insurance_file_cnt
	,t13.description AS Country
	,t16.insurance_file_status_id
	,t19.code  AS Product
	,t1.risk_number  AS RiskNumber
	,t20.RLStreet AS Address1
	,t20.RLSuburb AS Suburb
    ,t20.RLGNAFPID AS GNAFPID
	,t20.RLPostCode AS Postcode
    ,CASE WHEN TRIM(t13.description) = ''New Zealand'' THEN ''NZ'' ELSE t20.RLState END AS State
	,t20.description AS AddressDescription
	,t20.rlanzsiccode AS AnzsicCode
	,t20.rlanzsicdesc AS AnzsicDescription
	,t22.QU2LeasedPremises AS LeasedPremises
	,t21.QU2Occupation AS HighestRiskTenant
	,t20.RLBusinessBuildings AS BusinessBuildings
	,t20.RLBusinessContents AS BusinessContents
	,t20.RLBurglary AS Burglary
	,t20.RLMoney AS MONEY
	,t20.RLEngineering AS Engineering
	,t20.RLBusinessInterruption AS BusinessInterruption
	,t20.RLGeneralProperty AS GeneralProperty
	,t20.RLGoodsInTransit AS GoodsInTransit
	,t20.RLPublicProducts AS PublicAndProductLiability
	,t20.RLProfessional AS ProfessionalProtection
	,t20.RLLegalExpenses AS LegalExpenses
	,t20.RLTaxAudit AS TaxAudit
	,t20.RLCommercialVehicles AS CommercialVehicles
	,t20.RLFleetVehicles AS Fleet
	,t20.RLCustomerVehicles AS CustomerVehicle
	,t20.RLStockVehicles AS StockVehicles
	,t22.QU2YearBuilt AS YearBuildingConstructed
	,t22.QU2YearLastElecticalInspection AS YearLastReWired
	,t22.QU2MainWallConstruction AS WallConst
	,t22.QU2RoofConstruction AS RoofConst
	,t22.QU2FloorConstruction AS FloorConst
	,t22.QU2AlarmSystem AS AlarmSystem
	,t22.QU2SecurityCameras AS Camera
	,t22.QU2TwoMeterFence AS TwoMeterFence
	,t22.QU2SecurityBollards AS Bollards
	,t22.QU2SecurityGuardPatrol AS SecurityGuard
	,t22.QU2DeadlocksOnDoors AS Deadlocks
	,t22.QU2ExteriorLighting AS SecurityLighting
	,t22.QU2BarsOnWindows AS Bars
	,t22.QU2AttendanceOnSite24Hrs AS TwentyFourHours
	,t22.QU2ConditionofPremises AS Condition
	,t23.PP1RunOffLiab AS IsRunOffLiab
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk  t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_policy_binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_membercsl t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts t10 ON t6.party_cnt = T10.clientid
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_policy_binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.product t19 ON (t3.product_id = t19.product_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t20 ON (t18.CBP_Policy_Binder_id = t20.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_leasedpremises t21 ON (t18.CBP_Policy_Binder_id = t21.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_question2 t22 ON (t18.CBP_Policy_Binder_id = t22.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_publicproducts t23 ON (t18.CBP_Policy_Binder_id = t23.CBP_Policy_Binder_id)
WHERE 
    --CAST(t3.expiry_date as DATE) = current_date() + 45
	 SUBSTRING(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(t3.insurance_file_status_id,NULL,0) NOT IN (1, 2) /* (1=Cancelled, 2=Lapsed) */
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
    AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		WHERE CAST(t13.expiry_date AS DATE) > current_date()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				AND (STATUS.insurance_file_status_id <> 1 OR STATUS.insurance_file_status_id IS NULL) /* (1=Cancelled) */
			)
		)
        --AND TRIM(PUREPOLICYNUMBER)=''P00028687'';
ORDER BY ExpiryDate,PUREPolicyNumber;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_CBP_locationDetail AS
SELECT
    t1.PUREPOLICYNUMBER
    ,EXPIRINGID_P
    ,CMLNUMBER
    ,EXPIRYDATE
    ,insurance_file_cnt
    ,COUNTRY
    ,insurance_file_status_id
    ,PRODUCT
    ,RISKNUMBER
    ,ADDRESS1
    ,Upper(trim(SUBURB)) as SUBURB
    ,GNAFPID
    ,POSTCODE
    ,STATE
    ,ADDRESSDESCRIPTION
    ,LEASEDPREMISES
    ,HIGHESTRISKTENANT
    ,BUSINESSBUILDINGS
    ,BUSINESSCONTENTS
    ,BURGLARY
    ,MONEY
    ,ENGINEERING
    ,BUSINESSINTERRUPTION
    ,YEARBUILDINGCONSTRUCTED
    ,YEARLASTREWIRED
    ,WALLCONST
    ,ROOFCONST
    ,FLOORCONST
    ,ALARMSYSTEM
    ,CAMERA
    ,TWOMETERFENCE
    ,BOLLARDS
    ,SECURITYGUARD
    ,DEADLOCKS
    ,SECURITYLIGHTING
    ,BARS
    ,TWENTYFOURHOURS
    ,t1.CONDITION
    -- AnzsicCode adjustments
   ,CASE 
        WHEN COMMERCIALVEHICLES + FLEET > 0 THEN 1
        ELSE COMMERCIALVEHICLES
    END AS COMMERCIALVEHICLES,

    /* ANZSIC transformations */
    CASE
        /* Special rule when only CommercialVehicles = 1 */
        WHEN BusinessBuildings = 0 AND BusinessContents = 0 AND Burglary = 0
             AND Money = 0 AND Engineering = 0 AND BusinessInterruption = 0
             AND GeneralProperty = 0 AND GoodsInTransit = 0
             AND PublicAndProductLiability = 0 AND ProfessionalProtection = 0
             AND LegalExpenses = 0 AND TaxAudit = 0 AND CustomerVehicle = 0
             AND StockVehicles = 0 AND (COMMERCIALVEHICLES + FLEET > 0)
            THEN ''222222''

        WHEN ANZSICCODE = ''281301'' THEN ''532201''
        WHEN ANZSICCODE = ''292101'' THEN ''281901''
        WHEN ANZSICCODE IN (''531104'',''286101'',''531118'') THEN ''531103''
        WHEN ANZSICCODE = ''531201'' THEN ''531301''
        WHEN ANZSICCODE IN (''462101'',''531119'') THEN ''531107''
        WHEN ANZSICCODE = ''462401'' THEN ''531116''
        WHEN ANZSICCODE IN (''531111'',''531112'',''531113'',''531114'') THEN ''462301''
        WHEN ANZSICCODE = ''532102'' THEN ''532101''
        WHEN ANZSICCODE = ''532104'' THEN ''532103''
        WHEN ANZSICCODE IN (''255102'',''462302'') THEN ''532401''
        WHEN ANZSICCODE IN (''532501'',''532502'',''532503'',''532906'',
                            ''532907'',''532910'',''532911'') THEN ''532505''
        ELSE ANZSICCODE
    END AS ANZSICCODE,

    /* ANZSIC Description logic */
    CASE
        WHEN ANZSICCODE = ''281301'' THEN ''Automotive Electrical Services''
        WHEN ANZSICCODE = ''292101'' THEN ''Automotive Component Manufacturing''
        WHEN ANZSICCODE IN (''531104'',''286101'',''531118'')
            THEN ''Agricultural Machinery Dealers - Including Servicing''
        WHEN ANZSICCODE = ''531201''
            THEN ''Motorcycle Dealers - New and Used - including Servicing''
        WHEN ANZSICCODE IN (''462101'',''531119'')
            THEN ''Motor Vehicle Dealers - New - excluding Servicing''
        WHEN ANZSICCODE = ''462401''
            THEN ''Motor Vehicle Wrecking - Used Parts Reseller''
        WHEN ANZSICCODE IN (''531111'',''531112'',''531113'',''531114'')
            THEN ''Motor Vehicle New Part and Accessories Wholesaling''
        WHEN ANZSICCODE = ''532102''
            THEN ''Service Station - excluding Servicing''
        WHEN ANZSICCODE = ''532104''
            THEN ''Service Station - including Roadhouse - including Servicing''
        WHEN ANZSICCODE IN (''255102'',''462302'')
            THEN ''Tyre Retailers and Repairers - excluding Retreading and Remoulding''
        WHEN ANZSICCODE IN (''532501'',''532502'',''532503'',''532906'',''532907'',
                            ''532910'',''532911'')
            THEN ''Automotive Mechanical Repairs - Workshop - excluding Smash Repairs''

        WHEN ANZSICCODE = ''531301''
            THEN ''Motorcycle Dealers - New and Used - including Servicing''
        WHEN ANZSICCODE = ''600002''
            THEN ''Ultra-Tune''
        WHEN ANZSICCODE = ''524502''
            THEN ''Boat Dealers - no Manufacturing - including Servicing''
        WHEN ANZSICCODE = ''531109''
            THEN ''Motor Vehicle Dealers - Used - excluding Servicing''
        WHEN ANZSICCODE = ''531110''
            THEN ''Motor Vehicle Dealers - Used - including Servicing''
        WHEN ANZSICCODE = ''531116''
            THEN ''Motor Vehicle Wrecking - Used Parts Reseller''
        WHEN ANZSICCODE = ''532505''
            THEN ''Automotive Mechanical Repairs - Workshop - excluding Smash Repairs''
        WHEN ANZSICCODE = ''540002''
            THEN ''Wrecker - Retailer Only''
        WHEN ANZSICCODE = ''540003''
            THEN ''Service Station - excluding Roadhouse''
        WHEN ANZSICCODE = ''532504''
            THEN ''Automotive Mechanical Repairs - Mobile Mechanic''
        WHEN ANZSICCODE = ''222222''
            THEN ''Vehicles Only''

        ELSE ANZSICDESCRIPTION
    END AS ANZSICDESCRIPTION

    ,t3.ADEQUATESECOVSTORAGE
    ,t3.HIGHRISKSPECIALISEDEQUIP
    ,t3.DETAILSHIGHRISKSPECEQUIP
    ,t3.INADEQUATEFUELSTORAGE
    ,t4.MORETHANFEWTYRESTACK
    ,t4.VOLTYRESTACK
    ,t4.VOLTYRESTACKIN
    ,t4.TYRESTOREDOUTORDERLY
    ,t4.EXCOILRESIDUEOUT
    ,t4.SATISFACTORYRISKMITIGATION
    ,t5.NOOFSPRAYBOOTHS
    ,t5.CONDITION AS SmashRepair_Condition
    ,t5.SURRAREAFREEOFHEATWORK
    ,t5.SURRAREAHOUSEKEEP
    ,t5.MIXINGRMHOUSEKEEP
    ,t5.AGEOFOLDESTBOOTH
    ,t5.REPLACECOST
    ,t5.REGULARSERVICELOG
    ,t5.INTERIORWALLPROTECTIONUSED
    ,t5.EXHAUSTFANREPLACED
    ,t6.FLOORCONDITION
    ,t6.DISMANTLEAREAHOUSEKEEP
    ,t6.DEFUELLOCATION
    ,t6.DISMANTLELOC
    ,t6.HOISTSUSED
    ,t6.FIREEQUIPNEAR
    ,t6.METALRECYCLEONSITE
    ,t6.METALRECYCLEINSIDE
    ,t6.STOCKHOUSEKEEPING
    ,t6.TYRESBATTERIESHOUSEKEEP
    ,t6.EVSTORAGE
    ,t6.VEHICLESSTACKED
    ,t6.FUELSTORE
    ,t6.AVGNOVEHSSTORED
    ,t6.YARDFLOORHOUSEKEEP
    ,t6.CLEARLANDSQM
FROM Sample_CBP_lOCATION t1
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_HEAVYDUTYDIESEL t3 ON (trim(t1.PUREPolicyNumber) = trim(t3.purepolicynumber)) AND (t1.expiringid_p = t3.purepolicybinder)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_TYREDEALER t4 ON (trim(t1.PUREPolicyNumber )= trim(t4.purepolicynumber)) AND (t1.expiringid_p = t4.purepolicybinder)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_SMASHREPAIRER t5 ON (trim(t1.PUREPolicyNumber) = trim(t5.purepolicynumber)) AND (t1.expiringid_p = t5.purepolicybinder)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.QU_DISMANTLER t6 ON ( trim(t1.PUREPolicyNumber) = trim(t6.purepolicynumber)) AND (t1.expiringid_p = t6.purepolicybinder)
WHERE 
    /* Equivalent of DELETE rules */
     COALESCE(ANZSICCODE, '''') <> ''222222''
     AND NOT (COALESCE(IsRunOffLiab, NULL,0)  > 0 AND PUBLICANDPRODUCTLIABILITY = 1)
     --AND MONEY = 1;
     --AND TRIM(t1.PUREPOLICYNUMBER)=''P00028687'';
    ORDER BY  t1.PUREPOLICYNUMBER, RiskNumber;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Location_01 AS
WITH base AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (
            PARTITION BY PUREPolicyNumber, RiskNumber, AddressDescription
            ORDER BY PUREPolicyNumber
        ) AS Count_ID,
         /* SAS: IF FIRST.AddressDescription; */
        ROW_NUMBER() OVER (
            PARTITION BY PUREPolicyNumber, RiskNumber, AddressDescription
            ORDER BY RiskNumber, AddressDescription
        ) AS rn_addr
    FROM Sample_CBP_locationDetail
),
mapped AS (
    SELECT
        -- Exclude dropped columns
        PUREPolicyNumber,
        RiskNumber,
        CMLNumber,
        ExpiringID_P AS ExpiringID,
        EXPIRYDATE,
        PRODUCT,
        Address1,
        Suburb,
        GNAFPID,
        Postcode,
        CASE WHEN TRIM(Country) = ''New Zealand'' THEN ''NZ'' ELSE State END AS State,
        Country,
        AddressDescription,
        CommercialVehicles,
        BusinessBuildings,
        BusinessContents,
        Burglary,
        Money,
        Engineering,
        BusinessInterruption,
        LeasedPremises,
        HighestRiskTenant,
        AnzsicCode,
        AnzsicDescription,
        -- YearBuildingConstructed,
        -- YearLastReWired,
        WallConst,
        RoofConst,
        FloorConst,
        AlarmSystem,
        Camera,
        TwoMeterFence,
        Bollards,
        SecurityGuard,
        Deadlocks,
        SecurityLighting,
        Bars,
        TwentyFourHours,
        ADEQUATESECOVSTORAGE,
        HIGHRISKSPECIALISEDEQUIP,
        DETAILSHIGHRISKSPECEQUIP,
        INADEQUATEFUELSTORAGE,
        MORETHANFEWTYRESTACK,
        VOLTYRESTACK,
        VOLTYRESTACKIN,
        TYRESTOREDOUTORDERLY,
        EXCOILRESIDUEOUT,
        SATISFACTORYRISKMITIGATION,
        NOOFSPRAYBOOTHS,
        SmashRepair_Condition,
        SURRAREAFREEOFHEATWORK,
        SURRAREAHOUSEKEEP,
        MIXINGRMHOUSEKEEP,
        AGEOFOLDESTBOOTH,
        REPLACECOST,
        REGULARSERVICELOG,
        INTERIORWALLPROTECTIONUSED,
        EXHAUSTFANREPLACED,
        FLOORCONDITION,
        DISMANTLEAREAHOUSEKEEP,
        DEFUELLOCATION,
        DISMANTLELOC,
        HOISTSUSED,
        FIREEQUIPNEAR,
        METALRECYCLEONSITE,
        METALRECYCLEINSIDE,
        STOCKHOUSEKEEPING,
        TYRESBATTERIESHOUSEKEEP,
        EVSTORAGE,
        VEHICLESSTACKED,
        FUELSTORE,
        AVGNOVEHSSTORED,
        YARDFLOORHOUSEKEEP,
        CLEARLANDSQM,
        Condition,
        -- Count_ID_String
        LPAD(Count_ID::STRING, 3, ''0'') AS Count_ID_String,
        -- Default Address2
        '''' AS Address2,
        -- Country mapping
        -- Business type mapping
        CONCAT(AnzsicCode, '' - '', AnzsicDescription) AS BusinessType,
        CONCAT(AnzsicCode, '' - '', AnzsicDescription) AS LocationANZSICCode,
        -- Section counts
        BusinessBuildings + BusinessContents + Burglary + Money + Engineering + BusinessInterruption AS TotalSectionCount,
        BusinessBuildings + BusinessContents + BusinessInterruption AS TotalSectionProperty,
        -- Year corrections
        CASE WHEN YearBuildingConstructed IS NULL OR YearBuildingConstructed = 0 THEN 1990
             WHEN YearBuildingConstructed < 1800 AND YearBuildingConstructed > 0 THEN 1800
             ELSE YearBuildingConstructed
        END AS YearBuildingConstructed,
        CASE WHEN YearLastReWired = 0 THEN 1800
             WHEN YearLastReWired < 1800 AND YearLastReWired > 0 THEN 1800
             ELSE YearLastReWired
        END AS YearLastReWired,
        NULL::INT AS YearLastReRoofed,
        NULL::INT AS YearLastRePlumbed,
        YEAR(CURRENT_DATE) AS CurrentYear,
        YEAR(CURRENT_DATE) - COALESCE(YearBuildingConstructed,1990) AS AgeOfBuilding,
        -- Default construction/security values
        ''Double Brick'' AS MainWallConstruction,
        ''Iron'' AS RoofConstruction,
        ''Concrete'' AS FloorConstruction,
        ''None'' AS AlarmSystemInstalled,
        ''No'' AS SecurityCameras,
        ''No'' AS TwoMeterHighPerimeterFence,
        ''No'' AS SecurityBollards,
        ''No'' AS PatrolledByASecurityGuard,
        ''No'' AS DeadlocksInstalled,
        ''No'' AS ExteriorSecurityLighting,
        ''No'' AS BarsOrGrillsInstalled,
        ''No'' AS TwentyFourHoursAttendance,
        -- Description
        CASE WHEN Count_ID = 1 THEN ''Primary Location''
             ELSE CONCAT(''Location #'', LPAD(Count_ID::STRING,3,''0''))
        END AS Description,
        -- OccupationOfHighestRiskTenant
        CASE 
            WHEN AnzsicCode = ''111111'' AND LeasedPremises = 1 THEN
                CASE HighestRiskTenant
                    WHEN 1 THEN ''Motor Trade Workshop''
                    WHEN 2 THEN ''Wood-worker''
                    WHEN 3 THEN ''Fibre-glass works''
                    WHEN 4 THEN ''Plastics or rubber manufacturing''
                    WHEN 5 THEN ''Hotel/Restaurant/Accomodation''
                    WHEN 6 THEN ''Battery Related''
                    WHEN 7 THEN ''Tyre Related''
                    WHEN 8 THEN ''Retail Premises''
                    WHEN 9 THEN ''Office''
                    WHEN 10 THEN ''Other - Low Fire/Injury risk''
                    WHEN 11 THEN ''Other - High Fire/Injury risk''
                END
        END AS OccupationOfHighestRiskTenant,
        -- Wall/roof/floor mappings
        CASE WallConst
            WHEN 1 THEN ''Asbestos''
            WHEN 2 THEN ''Double Brick''
            WHEN 3 THEN ''Concrete''
            WHEN 4 THEN ''Fibro (Non-Asbestos)''
            WHEN 5 THEN ''Iron''
            WHEN 6 THEN ''Other''
            WHEN 7 THEN ''Steel''
            WHEN 8 THEN ''Wood''
            WHEN 9 THEN ''Some Asbestos and Brick''
            WHEN 10 THEN ''Brick Veneer''
        END AS MainWallConstruction_final,
        CASE RoofConst
            WHEN 1 THEN ''Asbestos''
            WHEN 2 THEN ''Concrete''
            WHEN 3 THEN ''Fibro (Non-Asbestos)''
            WHEN 4 THEN ''Iron''
            WHEN 5 THEN ''Other''
            WHEN 6 THEN ''Tile''
            WHEN 7 THEN ''Tin''
            WHEN 8 THEN ''Wood''
            WHEN 9 THEN ''Some Asbestos and Brick''
        END AS RoofConstruction_final,
        CASE FloorConst
            WHEN 1 THEN ''Concrete''
            WHEN 2 THEN ''Other''
            WHEN 3 THEN ''Wood - Concrete footings''
            WHEN 4 THEN ''Wood''
        END AS FloorConstruction_final,
        -- Alarm/security mappings
        CASE AlarmSystem
            WHEN 1 THEN ''Local - Audible Only''
            WHEN 2 THEN ''Local - Monitored''
            WHEN 3 THEN ''Mobile Mechanic - No base location''
            WHEN 4 THEN ''Monitored - Back to base''
            WHEN 5 THEN ''Monitored - Security''
            WHEN 6 THEN ''None''
            WHEN 7 THEN ''Other''
        END AS AlarmSystemInstalled_final,
        CASE Camera WHEN 1 THEN ''Yes'' ELSE ''No'' END AS SecurityCameras_final,
        CASE TwoMeterFence WHEN 1 THEN ''Yes'' ELSE ''No'' END AS TwoMeterHighPerimeterFence_final,
        CASE Bollards WHEN 1 THEN ''Yes'' ELSE ''No'' END AS SecurityBollards_final,
        CASE SecurityGuard WHEN 1 THEN ''Yes'' ELSE ''No'' END AS PatrolledByASecurityGuard_final,
        CASE Deadlocks WHEN 1 THEN ''Yes'' ELSE ''No'' END AS DeadlocksInstalled_final,
        CASE SecurityLighting WHEN 1 THEN ''Yes'' ELSE ''No'' END AS ExteriorSecurityLighting_final,
        CASE Bars WHEN 1 THEN ''Yes'' ELSE ''No'' END AS BarsOrGrillsInstalled_final,
        CASE TwentyFourHours WHEN 1 THEN ''Yes'' ELSE ''No'' END AS TwentyFourHoursAttendance_final,
        -- ConditionOfBuilding
        CASE 
            WHEN Condition = 5 AND TotalSectionProperty > 0 AND YearBuildingConstructed < 1990 THEN ''< 1990 - poor condition''
            WHEN Condition IN (2,3) AND TotalSectionProperty > 0 AND YearBuildingConstructed < 1990 THEN ''< 1990 - good condition''
            WHEN Condition = 5 AND TotalSectionProperty > 0 AND YearBuildingConstructed > 1989 THEN ''> 1990 - poor condition''
            WHEN Condition IN (2,3) AND TotalSectionProperty > 0 AND YearBuildingConstructed > 1989 THEN ''> 1990 - good condition''
        END AS ConditionOfBuilding,
        '''' AS ConditionOfRoof,rn_addr
    FROM base
)
SELECT 
    PUREPolicyNumber,
    CMLNumber,
    ExpiringID,
    EXPIRYDATE,
    Product,
    Address1,
    GNAFPID,
    Country,
    AddressDescription,
    Suburb,
    Postcode,
    State,
    BusinessBuildings,
    BusinessContents,
    Burglary,
    Money,
    Engineering,
    BusinessInterruption,
    YearBuildingConstructed,
    YearLastReWired,
    Address2,
    OccupationOfHighestRiskTenant,
    BusinessType,
    LocationANZSICCode,
    YearLastReRoofed,
    YearLastRePlumbed,
    Description,
    MainWallConstruction_final AS MainWallConstruction,
    ROOFCONSTRUCTION_FINAL AS RoofConstruction,
    FLOORCONSTRUCTION_FINAL AS FloorConstruction,
    ALARMSYSTEMINSTALLED_FINAL AS AlarmSystemInstalled,
    SECURITYCAMERAS_FINAL AS SecurityCameras,
    TWOMETERHIGHPERIMETERFENCE_FINAL AS TwoMeterHighPerimeterFence,
    SecurityBollards_final as SecurityBollards,
    PATROLLEDBYASECURITYGUARD_FINAL AS PatrolledByASecurityGuard,
    DEADLOCKSINSTALLED_FINAL AS DeadlocksInstalled,
    EXTERIORSECURITYLIGHTING_FINAL AS ExteriorSecurityLighting,
    BARSORGRILLSINSTALLED_FINAL AS BarsOrGrillsInstalled,
    TWENTYFOURHOURSATTENDANCE_FINAL AS TwentyFourHoursAttendance,
    ConditionOfBuilding,
    ConditionOfRoof,
    ADEQUATESECOVSTORAGE,
    HIGHRISKSPECIALISEDEQUIP,
    DETAILSHIGHRISKSPECEQUIP,
    INADEQUATEFUELSTORAGE,
    MORETHANFEWTYRESTACK,
    VOLTYRESTACK,
    VOLTYRESTACKIN,
    TYRESTOREDOUTORDERLY,
    EXCOILRESIDUEOUT,
    SATISFACTORYRISKMITIGATION,
    NOOFSPRAYBOOTHS,
    SmashRepair_Condition,
    SURRAREAFREEOFHEATWORK,
    SURRAREAHOUSEKEEP,
    MIXINGRMHOUSEKEEP,
    AGEOFOLDESTBOOTH,
    REPLACECOST,
    REGULARSERVICELOG,
    INTERIORWALLPROTECTIONUSED,
    EXHAUSTFANREPLACED,
    FLOORCONDITION,
    DISMANTLEAREAHOUSEKEEP,
    DEFUELLOCATION,
    DISMANTLELOC,
    HOISTSUSED,
    FIREEQUIPNEAR,
    METALRECYCLEONSITE,
    METALRECYCLEINSIDE,
    STOCKHOUSEKEEPING,
    TYRESBATTERIESHOUSEKEEP,
    EVSTORAGE,
    VEHICLESSTACKED,
    FUELSTORE,
    AVGNOVEHSSTORED,
    YARDFLOORHOUSEKEEP,
    CLEARLANDSQM
    FROM mapped  QUALIFY rn_addr = 1 
    ORDER BY PUREPOLICYNUMBER;



 /* Locationdetails_PER added from merge*/
 CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Locationdetails_PER AS
WITH base AS (
    SELECT
        s.*,

        /* Count_ID equivalent */
        ROW_NUMBER() OVER (
            PARTITION BY PUREPolicyNumber
            ORDER BY RiskNumber, AddressDescription
        ) AS Count_ID,

        /* FIRST.AddressDescription equivalent */
        ROW_NUMBER() OVER (
            PARTITION BY PUREPolicyNumber, RiskNumber, AddressDescription
            ORDER BY RiskNumber
        ) AS addr_rn

    FROM AGGNE.DEV.Sample_PER s
),
--select * from base

derived AS (
    SELECT
        b.*,

        /* Count_ID_String */
        LPAD(Count_ID::VARCHAR, 3, '' '') AS Count_ID_String,

        '''' AS Address2,

        /* Country → State */
        CASE
            WHEN TRIM(Country) = ''New Zealand'' THEN ''NZ''
            ELSE State
        END AS State_new,

        /* Year corrections */
       CASE
            WHEN YearBuildingConstructed < 1900
                 AND YearBuildingConstructed > 0
            THEN 1900
            ELSE YearBuildingConstructed
        END AS YearBuildingConstructed_new,

        NVL(CAST(CASE WHEN LENGTH(YearLastReWired) = ''4'' THEN (CASE WHEN CAST(YearLastReWired AS int) BETWEEN 0 AND 1899 THEN 1900 ELSE NULL END)
        WHEN YearLastReWired = ''0'' THEN ''1900''
        ELSE NULL
        END AS varchar),'''') AS YearLastReWired_new,

        NVL(CAST(CASE WHEN LENGTH(YearLastRePlumbed) = ''4'' THEN (CASE WHEN CAST(YearLastRePlumbed AS int) BETWEEN 0 AND 1899 THEN 1900 ELSE NULL END)
        WHEN YearLastRePlumbed = ''0'' THEN ''1900''
        ELSE NULL
        END AS varchar),'''') AS YearLastRePlumbed_new,

        YEAR(CURRENT_DATE) AS CurrentYear

    FROM base b
),
 --select * from derived

final_calc AS (
    SELECT
        d.*,

        '''' AS YearLastReroofed,

        /* Age of building */
        CurrentYear - YearBuildingConstructed_new AS AgeOfBuilding,

        /* Description */
        CASE
            WHEN Count_ID = 1 THEN ''Primary Location''
            ELSE ''Location #'' || TRIM(Count_ID_String)
        END AS Description,

        /* Home Buildings / Contents */
        CASE
            WHEN Home = 1 AND ProtectionSelection IN (1, 3) THEN ''Yes''
            ELSE ''No''
        END AS HomeBuildings,

        CASE
            WHEN Home = 1 AND ProtectionSelection IN (2, 3) THEN ''Yes''
            ELSE ''No''
        END AS HomeContents,

        /* How Occupied */
        CASE HowOccup
            WHEN 1 THEN ''Owner Occupied''
            WHEN 2 THEN ''Tenanted by member''
            WHEN 3 THEN ''Owned leased to Others - Long Term Lease''
            WHEN 4 THEN ''Owned leased to Others - Short Term Rental''
            WHEN 5 THEN ''Holiday Home''
            ELSE ''''
        END AS HowOccuppied,

        /* Storeys */
        CASE WHEN Storeys = 0 THEN 1 ELSE Storeys END AS Storeys_new,

        /* Wall Construction */
        CASE WallConst
            WHEN 1 THEN ''Asbestos''
            WHEN 2 THEN ''Double Brick''
            WHEN 3 THEN ''Concrete''
            WHEN 4 THEN ''Fibro/Hardiplank''
            WHEN 5 THEN ''Iron/Steel''
            WHEN 6 THEN ''Brick Veneer''
            WHEN 7 THEN ''Iron/Steel''
            WHEN 8 THEN ''Wood''
            WHEN 9 THEN ''Brick Veneer''
            WHEN 10 THEN ''Fibro/Hardiplank''
            WHEN 11 THEN ''Brick Veneer''
            WHEN 12 THEN ''Brick Veneer''
            ELSE ''''
        END AS MainWallConstruction,

        /* Roof Construction */
        CASE RoofConst
            WHEN 1 THEN ''Asbestos''
            WHEN 2 THEN ''Concrete (Flat Roof)''
            WHEN 3 THEN ''Iron/Steel/Tin''
            WHEN 4 THEN ''Iron/Steel/Tin''
            WHEN 5 THEN ''Tile''
            WHEN 6 THEN ''Wood (Shingles)''
            WHEN 7 THEN ''Colorbond''
            ELSE ''''
        END AS RoofConstruction,

        /* Floor Construction */
        CASE FloorConst
            WHEN 1 THEN ''Concrete''
            WHEN 2 THEN ''Other''
            WHEN 3 THEN ''Wood - Concrete Footings''
            WHEN 4 THEN ''Wood - Stumps''
            WHEN 5 THEN ''Wood - Stilts''
            ELSE ''''
        END AS FloorConstruction,

        /* Alarm System */
        CASE
            WHEN Home = 1 THEN
                CASE AlarmSystem
                    WHEN 1 THEN ''Local - Audible Only''
                    WHEN 2 THEN ''Monitored - To Mobile Phone''
                    WHEN 3 THEN ''Monitored - Back to base''
                    WHEN 4 THEN ''Monitored - Security''
                    WHEN 5 THEN ''None''
                    ELSE ''None''
                END
            ELSE ''''
        END AS AlarmSystemInstalled,

        /* Deadlocks */
        CASE
            WHEN Home = 1 THEN
                CASE Deadlocks
                    WHEN 1 THEN ''All doors''
                    WHEN 2 THEN ''Some doors''
                    WHEN 3 THEN ''None''
                    ELSE ''None''
                END
            ELSE ''''
        END AS DeadlocksInstalled,

        /* Grill / Key Lock */
        CASE
            WHEN Home = 1 THEN
                CASE GrillKeyLock
                    WHEN 1 THEN ''All windows''
                    WHEN 2 THEN ''Some windows''
                    WHEN 3 THEN ''None''
                    ELSE ''None''
                END
            ELSE ''''
        END AS GrillKeyLockInstalled,

        /* Interested Party */
        CASE
            WHEN ContentsTPInd = 1 AND BuildingTPInd = 1
                 AND HomeBuildings = ''Yes'' AND HomeContents = ''Yes''
            THEN
                CASE
                    WHEN BuildingTPDetails = ContentsTPDetails
                    THEN BuildingTPDetails
                    ELSE CONCAT(BuildingTPDetails, ''. '', ContentsTPDetails)
                END
            WHEN BuildingTPInd = 1 AND HomeBuildings = ''Yes''
                THEN BuildingTPDetails
            WHEN ContentsTPInd = 1 AND HomeContents = ''Yes''
                THEN ContentsTPDetails
            ELSE ''''
        END AS InterestedParty

    FROM derived d
)

SELECT DISTINCT
PUREPOLICYNUMBER,
CSLNUMBER,
CMLNUMBER,
EXPIRINGID_P,
INSURANCE_FILE_CNT,
LINEOFBUSINESS,
EFFECTIVEDATE,
COUNTRY,
STATE_NEW AS STATE,
RISKNUMBER,
ADDRESS1,
SUBURB,
POSTCODE,
OVERRIDE,
ADDRESSDESCRIPTION,
HOME,
PROTECTIONSELECTION,
HOWOCCUP,
STOREYS_NEW AS STOREYS,
YEARBUILDINGCONSTRUCTED_NEW AS YEARBUILDINGCONSTRUCTED,
YEARLASTREWIRED_NEW AS YEARLASTREWIRED,
YEARLASTREPLUMBED_NEW AS YEARLASTREPLUMBED,
WALLCONST,
ROOFCONST,
FLOORCONST,
SECURITYDETAILS,
CONTENTSTPIND,
CONTENTSTPDETAILS,
PRODUCT,
ADDR_RN,
ADDRESS2,
YEARLASTREROOFED,
AGEOFBUILDING,
DESCRIPTION,
HOMEBUILDINGS,
HOMECONTENTS,
HOWOCCUPPIED,
MAINWALLCONSTRUCTION,
ROOFCONSTRUCTION,
FLOORCONSTRUCTION,
ALARMSYSTEMINSTALLED,
DEADLOCKSINSTALLED,
GRILLKEYLOCKINSTALLED,
INTERESTEDPARTY,
FROM final_calc
WHERE addr_rn = 1
ORDER BY PUREPOLICYNUMBER;

--------------------------------------------------1.6@@Locationdetails@@end@@------------------------------------------------------------------------------------------------------


--------------------------------------------------1.7@@LineCoverages@@start@@---------------------------------------------------------------------------------------------------

---------------------------------------------------Line_CV_Coverage-----------------------------------------

   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CV_01 AS
   SELECT 
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLCustomerVehicles AS CustomerVehicles_Ind,
          ''CV'' AS Coverage,

/*standard protections*/
          t3.CVSumProtected, /*PURE Field for testing only*/
		  CASE 
               WHEN t3.CVSumProtected IS NULL THEN NULL
			   WHEN t3.CVSumProtected = 0 THEN NULL
               WHEN t3.CVSumProtected <= 30000 THEN 30000
			   WHEN t3.CVSumProtected <= 50000 THEN 50000
               WHEN t3.CVSumProtected <= 75000 THEN 75000
			   WHEN t3.CVSumProtected <= 100000 THEN 100000
			   WHEN t3.CVSumProtected <= 150000 THEN 150000
			   WHEN t3.CVSumProtected <= 200000 THEN 200000
               WHEN t3.CVSumProtected <= 250000 THEN 250000
			   WHEN t3.CVSumProtected <= 300000 THEN 300000
			   ELSE 300000
          END AS 										LossDamageLimit,

		  
/*excesses*/
		  t3.CVVoluntaryExcess, /*PURE Field for testing only*/
          CASE 
               WHEN t3.CVVoluntaryExcess IS NULL THEN NULL
			   WHEN t3.CVVoluntaryExcess = 0 THEN 0
               WHEN t3.CVVoluntaryExcess <= 500 THEN 500
			   WHEN t3.CVVoluntaryExcess <= 1000 THEN 1000
               WHEN t3.CVVoluntaryExcess <= 2000 THEN 2000
			   WHEN t3.CVVoluntaryExcess <= 5000 THEN 5000
			   ELSE 5000
          END AS 										VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_customervehicle t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	 t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where  t4.RLCustomerVehicles = 1;



--    ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.CVAdj_01 AS
--    SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--              CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS                                                      RecurringIndicator,      
--          t5.UWADJUSTNOTE         AS 								  UnderwritingDescription,
-- 		  COALESCE(t5.UWADJUSTAMOUNT, NULL, 0)   AS AJAdjustmentValue,
--              t4.AJAdjustmentPercent,
--              CASE 
--                   WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
--                    ELSE ''''
--           END AS                                                                 AdjustmentSelection,
--              CASE 
--                WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS                                                                 AdjustmentDollarAndPercent
-- 	FROM CV_01 t2
-- 	LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentscv t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--     LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--     WHERE t4.AJRecurringIndicator = 1;


-- ;CREATE OR REPLACE TRANSIENT  TABLE CVAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- CUSTOMERVEHICLES_IND,
-- COVERAGE,
-- CVSumProtected,
-- LOSSDAMAGELIMIT,
-- CVVoluntaryExcess,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--     WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentPercent
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM CVAdj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- CUSTOMERVEHICLES_IND,
-- COVERAGE,
-- CVSumProtected,
-- LOSSDAMAGELIMIT,
-- CVVoluntaryExcess,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentValue
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM CVAdj_01


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Line_CV_Coverage AS
         SELECT DISTINCT * FROM CV_01;
         --          t1.*,
         --          t2.RecurringIndicator,
         --          t2.UnderwritingDescription,
         --          t2.AJAdjustmentValue,
         --          t2.AJAdjustmentPercent,
         --          t2.AdjustmentSelection,
         --          t2.AdjustmentDollarAndPercent
         -- FROM CV_01 t1
         -- LEFT JOIN
         -- (
         --   SELECT * FROM CVAdj_02
         --   WHERE AdjustmentSelection <> ''''
         --   UNION ALL
         --   SELECT * FROM CVAdj_01
         --   WHERE AdjustmentSelection <> ''''
         -- ) t2
         -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
         --   AND t1.ExpiringID_P = t2.ExpiringID_P
         --   AND t1.CMLNumber = t2.CMLNumber
         --   AND t1.ExpiryDate = t2.ExpiryDate
         --   AND t1.Country = t2.Country
         --   AND t1.Product = t2.Product
         --   AND t1.coverage = t2.coverage
         --   ORDER BY PUREPOLICYNUMBER;


-------------------------------------------Line_GP_Coverage-------------------------------------------------------------------------------------------------

CREATE OR REPLACE  TRANSIENT TABLE GP_SPTOOL AS
SELECT 
     t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,t2.Product
	,t7.RLGeneralProperty AS GeneralProperty_Ind
    , ''GP'' AS Coverage
	,
	/*standard protections*/
	t5.STDescription AS Description
	,t5.STLimit AS Value
FROM Sample_CBP t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_specifiedtools t5 ON (t2.ExpiringID_P = t5.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t7 ON t2.ExpiringID_P = t7.CBP_Policy_Binder_id
where t7.RLGeneralProperty = 1;




;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.GP_SPSTOCK AS
SELECT t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,t2.Product
	,t7.RLGeneralProperty AS GeneralProperty_Ind
    , ''GP'' AS Coverage
	,t4.SSDescription AS Description
	,t4.SSLimit AS Value
FROM Sample_CBP t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_specifiedstock t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t7 ON t2.ExpiringID_P = t7.CBP_Policy_Binder_id
where t7.RLGeneralProperty = 1;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.GP_OTHERPROP AS
SELECT t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,t2.Product
	,t7.RLGeneralProperty AS GeneralProperty_Ind
    , ''GP'' AS Coverage
	,
	/*standard protections*/
	t6.OPDescription AS Description
	,t6.OPLimit AS Value
FROM Sample_CBP t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_otherproperty t6 ON (t2.ExpiringID_P = t6.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t7 ON t2.ExpiringID_P = t7.CBP_Policy_Binder_id
where t7.RLGeneralProperty = 1;



CREATE OR REPLACE  transient TABLE AGGNE.DEV.GP_01 AS
SELECT * FROM GP_SPTOOL
WHERE NOT (Description = '''' AND Value IS NULL)

UNION ALL

SELECT * FROM GP_SPSTOCK
WHERE NOT (Description = '''' AND Value IS NULL)

UNION ALL

SELECT * FROM GP_OTHERPROP
WHERE NOT (Description = '''' AND Value IS NULL);



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.GP AS
SELECT t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,t2.Product
	,t7.RLGeneralProperty AS GeneralProperty_Ind
    ,''GP'' AS Coverage
	,
	/*standard protections*/
	t3.GPUnspecifiedTools
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.GPUnspecifiedTools IS NULL
			THEN 0
		ELSE t3.GPUnspecifiedTools
		END AS UnspecifiedToolsLimit
	,t3.GPUnspecifiedStock
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.GPUnspecifiedStock IS NULL
			THEN 0
		ELSE t3.GPUnspecifiedStock
		END AS UnspecifiedStockLimit
	,t3.GPSpecifiedTools
	,/*PURE Field for testing only*/
	t3.GPSpecifiedStock
	,/*PURE Field for testing only*/
	t3.GPOtherProperty
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.GPSpecifiedTools > 0
			THEN ''Taken''
		WHEN t3.GPSpecifiedStock > 0
			THEN ''Taken''
		WHEN t3.GPOtherProperty > 0
			THEN ''Taken''
		ELSE ''Not Taken''
		END AS SpecifiedTool
	,/*Specified Tools (Individual tools valued greater than $2,000)*/
	t4.Description
	,t4.Value
	,
	/*optional protections*/
	t3.GPFloodProtection
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.GPFloodProtection > 0
			THEN ''Taken''
		ELSE ''Not Taken''
		END AS FloodDamage
	,
	/*excesses*/
	t3.GPVoluntary
	,/*PURE Field for testing only*/
	CASE 
		WHEN t3.GPVoluntary IS NULL
			THEN NULL
		WHEN t3.GPVoluntary = 0
			THEN 0
		WHEN t3.GPVoluntary <= 500
			THEN 500
		WHEN t3.GPVoluntary <= 1000
			THEN 1000
		WHEN t3.GPVoluntary <= 2000
			THEN 2000
		WHEN t3.GPVoluntary <= 4500
			THEN 4500
		ELSE 4500
		END AS VoluntaryExcess
FROM Sample_CBP t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_generalproperty t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
LEFT JOIN GP_01 t4 ON (t2.ExpiringID_P = t4.ExpiringID_P)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t7 ON t2.ExpiringID_P = t7.CBP_Policy_Binder_id
where t7.RLGeneralProperty = 1;



-- ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.GPAdj_01 AS
-- SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--              CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS                                                      RecurringIndicator,      
--          t5.UWADJUSTNOTE         AS 								  UnderwritingDescription,
-- 		  COALESCE(t5.UWADJUSTAMOUNT, NULL, 0)   AS AJAdjustmentValue,
--              t4.AJAdjustmentPercent,
--              CASE 
--                   WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
--                    ELSE ''''
--           END AS                                                                 AdjustmentSelection,
--              CASE 
--                WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS                                                                 AdjustmentDollarAndPercent
-- FROM GP t2
-- LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsgp t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
-- LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t7 ON t2.ExpiringID_P = t7.CBP_Policy_Binder_id
-- LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--     WHERE t4.AJRecurringIndicator = 1;


-- CREATE OR REPLACE  transient TABLE GPAdj_02 AS
-- SELECT 
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- GENERALPROPERTY_IND,
-- Coverage,
-- GPUnspecifiedTools,
-- UNSPECIFIEDTOOLSLIMIT,
-- GPUnspecifiedStock,
-- UNSPECIFIEDSTOCKLIMIT,
-- GPSpecifiedTools,
-- GPSpecifiedStock,
-- GPOtherProperty,
-- SPECIFIEDTOOL,
-- DESCRIPTION,
-- VALUE,
-- GPFloodProtection,
-- FLOODDAMAGE,
-- GPVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentPercent
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM GPAdj_01


-- UNION 

-- SELECT 
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- GENERALPROPERTY_IND,
-- Coverage,
-- GPUnspecifiedTools,
-- UNSPECIFIEDTOOLSLIMIT,
-- GPUnspecifiedStock,
-- UNSPECIFIEDSTOCKLIMIT,
-- GPSpecifiedTools,
-- GPSpecifiedStock,
-- GPOtherProperty,
-- SPECIFIEDTOOL,
-- DESCRIPTION,
-- VALUE,
-- GPFloodProtection,
-- FLOODDAMAGE,
-- GPVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentValue
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM GPAdj_01


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Line_GP_Coverage AS
SELECT DISTINCT * FROM AGGNE.DEV.GP;

--------------------------------------------GT_Coverage-----------------------------------------------------------------

   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.GT_01 AS
   SELECT 
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLGoodsInTransit AS GoodsInTransit_Ind,
          ''GT'' AS Coverage,

/*standard protections*/
          t5.value AS GTInlandShipLimit, /*PURE Field for testing only*/
		  CASE 
               WHEN t3.GTInlandShipLimit IS NULL THEN NULL
			   WHEN t5.value = 0 THEN NULL
			   WHEN t5.value <= 10000 THEN 10000
               WHEN t5.value <= 20000 THEN 20000
			   WHEN t5.value <= 30000 THEN 30000
			   WHEN t5.value <= 50000 THEN 50000
			   WHEN t5.value <= 75000 THEN 75000
			   WHEN t5.value <= 100000 THEN 100000
			   WHEN t5.value <= 150000 THEN 150000
		  END AS										BusinessContentandStock,
		  t3.GTInland AS								EstimatedAnnualValue,
		  t3.GTHazardousGoods, /*PURE Field for testing only*/
		  CASE 
			   WHEN t3.GTHazardousGoods IS NULL OR t3.GTHazardousGoods = 2 THEN ''''
			   WHEN t3.GTHazardousGoods = 1 THEN ''Yes''
			   ELSE ''No''
          END AS 										HazardousGoods,
		  t3.GTHazardousGoodsDesc AS 					HazardousGoodstransported,
		  t3.GTContentsStockDesc AS 					ContentsandStocktransported,
		 		  
/*excesses*/
		  t3.GTVoluntary, /*PURE Field for testing only*/
          CASE 
               WHEN t3.GTVoluntary IS NULL THEN NULL
			   WHEN t3.GTVoluntary = 0 THEN 0
               WHEN t3.GTVoluntary <= 500 THEN 500
			   WHEN t3.GTVoluntary <= 1000 THEN 1000
               WHEN t3.GTVoluntary <= 2000 THEN 2000
			   WHEN t3.GTVoluntary <= 4500 THEN 4500
			   ELSE 4500
          END AS 										VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_goodstransit t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_gtumr001 AS t5 ON t5.UDL_GTUMR001_id = t3.GTInlandShipLimit
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where  t4.RLGoodsInTransit = 1;




--    ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.GTAdj_01 AS
--    SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--              CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS                                                      RecurringIndicator,      
--          t5.UWADJUSTNOTE         AS 								  UnderwritingDescription,
-- 		  COALESCE(t5.UWADJUSTAMOUNT, NULL, 0)   AS AJAdjustmentValue,
--              t4.AJAdjustmentPercent,
--              CASE 
--                   WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
--                    ELSE ''''
--           END AS                                                                 AdjustmentSelection,
--              CASE 
--                WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS                                                                 AdjustmentDollarAndPercent
--      FROM GT_01 t2
--      LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsgt t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--     LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--     WHERE t4.AJRecurringIndicator = 1;



-- ;CREATE OR REPLACE TRANSIENT  TABLE GTAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- GOODSINTRANSIT_IND,
-- COVERAGE,
-- GTINLANDSHIPLIMIT,
-- BUSINESSCONTENTANDSTOCK,
-- ESTIMATEDANNUALVALUE,
-- GTHazardousGoods,
-- HAZARDOUSGOODS,
-- HAZARDOUSGOODSTRANSPORTED,
-- CONTENTSANDSTOCKTRANSPORTED,
-- GTVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--   CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentPercent END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM GTAdj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- GOODSINTRANSIT_IND,
-- COVERAGE,
-- GTINLANDSHIPLIMIT,
-- BUSINESSCONTENTANDSTOCK,
-- ESTIMATEDANNUALVALUE,
-- GTHazardousGoods,
-- HAZARDOUSGOODS,
-- HAZARDOUSGOODSTRANSPORTED,
-- CONTENTSANDSTOCKTRANSPORTED,
-- GTVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--  CASE 
--     WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--     WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentValue END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM GTAdj_01


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Line_GT_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.GT_01;
         --          t1.*,
         --          t2.RecurringIndicator,
         --          t2.UnderwritingDescription,
         --          t2.AJAdjustmentValue,
         --          t2.AJAdjustmentPercent,
         --          t2.AdjustmentSelection,
         --          t2.AdjustmentDollarAndPercent
         -- FROM gt_01 t1
         -- LEFT JOIN
         -- (
         --   SELECT DISTINCT * FROM GTAdj_02
         --   WHERE AdjustmentSelection <> ''''
         --   UNION ALL
         --   SELECT DISTINCT * FROM GTAdj_01
         --   WHERE AdjustmentSelection <> ''''
         -- ) t2
         -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
         --   AND t1.ExpiringID_P = t2.ExpiringID_P
         --   AND t1.CMLNumber = t2.CMLNumber
         --   AND t1.ExpiryDate = t2.ExpiryDate
         --   AND t1.Country = t2.Country
         --   AND t1.Product = t2.Product
         --   AND t1.coverage = t2.coverage
         --   ORDER BY t1.PUREPolicyNumber ;


--------------------------------------------LE_Coverage-------------------------------------------------------------------------------------

  ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.LE_01 AS
   SELECT 
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLLegalExpenses AS LegalExpenses_Ind,
          ''LE'' AS Coverage,

/*standard protections*/
          t5.value AS LELimitofCover, /*PURE Field for testing only*/
		  CASE 
               WHEN t3.LELimitofCover IS NULL THEN NULL
			   WHEN t5.value = 0 THEN NULL
			   WHEN t5.value <= 10000 THEN 10000
               WHEN t5.value <= 25000 THEN 25000
			   WHEN t5.value <= 50000 THEN 50000
			   WHEN t5.value <= 75000 THEN 75000
			   WHEN t5.value <= 100000 THEN 100000
			   WHEN t5.value <= 150000 THEN 150000
			   WHEN t5.value <= 200000 THEN 200000
		  END AS										LegalExpensesLimit,
		  t3.LELegalDispute, /*PURE Field for testing only*/
		  CASE 
			   WHEN (t3.LELegalDispute IS NULL OR t3.LELegalDispute = 2) THEN ''''
			   WHEN t3.LELegalDispute = 1 THEN ''Yes''
			   ELSE ''No''
          END AS 										LegalDisputeActions,
		  t3.LELegalDisputeDetails AS					LegalDisputeActionsDetails,
		  t3.LERedundancies, /*PURE Field for testing only*/
		  CASE 
			   WHEN (t3.LERedundancies IS NULL OR t3.LERedundancies = 2) THEN ''''
			   WHEN t3.LERedundancies = 1 THEN ''Yes''
			   ELSE ''No''
          END AS 										Redundancies,
		  t3.LERedunDetails AS							RedundanciesDetails,
		 		  
/*excesses*/
		  t3.LEVoluntary, /*PURE Field for testing only*/
          CASE 
               WHEN t3.LEVoluntary IS NULL THEN NULL
			   WHEN t3.LEVoluntary = 0 THEN 0
               WHEN t3.LEVoluntary <= 500 THEN 500
			   WHEN t3.LEVoluntary <= 1000 THEN 1000
               WHEN t3.LEVoluntary <= 2000 THEN 2000
			   WHEN t3.LEVoluntary <= 4500 THEN 4500
			   ELSE 4500
          END AS 										VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_legalexpenses t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_leumr001 AS t5 ON t5.UDL_LEUMR001_id = t3.LELimitofCover
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	 t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where  t4.RLLegalExpenses = 1;
    


-- CREATE OR REPLACE  TRANSIENT TABLE LEAdj_01 AS
-- SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--              CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS                                                      RecurringIndicator,      
--          t5.UWADJUSTNOTE         AS 								  UnderwritingDescription,
-- 		  COALESCE(t5.UWADJUSTAMOUNT, NULL, 0)   AS AJAdjustmentValue,
--              t4.AJAdjustmentPercent,
--              CASE 
--                   WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
--                    ELSE ''''
--           END AS                                                                 AdjustmentSelection,
--              CASE 
--                WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS                                                                 AdjustmentDollarAndPercent
--      FROM LE_01 t2
--      LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsle t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--      LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--      WHERE t4.AJRecurringIndicator = 1;



-- ;CREATE OR REPLACE TRANSIENT  TABLE LEAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- LEGALEXPENSES_IND,
-- COVERAGE,
-- LELIMITOFCOVER,
-- LEGALEXPENSESLIMIT,
-- LELegalDispute,
-- LEGALDISPUTEACTIONS,
-- LEGALDISPUTEACTIONSDETAILS,
-- LERedundancies,
-- REDUNDANCIES,
-- REDUNDANCIESDETAILS,
-- LEVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentPercent
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM leadj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- LEGALEXPENSES_IND,
-- COVERAGE,
-- LELIMITOFCOVER,
-- LEGALEXPENSESLIMIT,
-- LELegalDispute,
-- LEGALDISPUTEACTIONS,
-- LEGALDISPUTEACTIONSDETAILS,
-- LERedundancies,
-- REDUNDANCIES,
-- REDUNDANCIESDETAILS,
-- LEVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentValue
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM leadj_01



   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Line_LE_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.LE_01;
         --          t1.*,
         --          t2.RecurringIndicator,
         --          t2.UnderwritingDescription,
         --          t2.AJAdjustmentValue,
         --          t2.AJAdjustmentPercent,
         --          t2.AdjustmentSelection,
         --          t2.AdjustmentDollarAndPercent
         -- FROM LE_01 t1
         -- LEFT JOIN
         -- (
         --   SELECT DISTINCT* FROM LEAdj_02
         --   WHERE AdjustmentSelection <> ''''
         --   UNION ALL
         --   SELECT DISTINCT * FROM LEAdj_01
         --   WHERE AdjustmentSelection <> ''''
         -- ) t2
         -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
         --   AND t1.ExpiringID_P = t2.ExpiringID_P
         --   AND t1.CMLNumber = t2.CMLNumber
         --   AND t1.ExpiryDate = t2.ExpiryDate
         --   AND t1.Country = t2.Country
         --   AND t1.Product = t2.Product
         --   AND t1.coverage = t2.coverage
         --   ORDER BY  t1.PUREPolicyNumber;
		   
-----------------------------------------Line_ProfessionalProtection_Coverage------------------------------------------------------

-- ============================================================
-- FIX [C4]: PF_01 — Inverted guard conditions (6 occurrences: IS NOT NULL AND <> 2 → IS NULL OR = 2)
-- SAS LOGIC (ProfessionalProtection_conversionscriptCapricorn, DATA step):
--   IF field = . THEN output = '';   /* missing / NULL → blank */
--   IF field = 2  THEN output = '';  /* value 2 means not applicable → blank */
--   IF field = 1  THEN output = ''Taken'';
--   ELSE               output = ''Not Taken'';
-- ISSUE: The Snowflake code had: WHEN (field IS NOT NULL AND field <> 2) THEN ''''
--        which is the exact INVERSE of the intended guard:
--        - For field = 1: IS NOT NULL AND <> 2 is TRUE → blank output (should be ''Taken'')
--        - For field = NULL: IS NOT NULL is FALSE → falls through to = 1 check → ELSE ''Not Taken'' (wrong)
--        - For field = 2: <> 2 is FALSE → falls through to = 1 check → ELSE ''Not Taken'' (wrong)
-- FIX: Changed to (field IS NULL OR field = 2) THEN '''' — matches SAS behaviour.
-- OLD CODE pattern: WHEN (field IS NOT NULL AND field <> 2) THEN ''''
-- NEW CODE pattern: WHEN (field IS NULL OR field = 2) THEN ''''
-- ============================================================
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PF_01 AS
SELECT
      t2.PUREPolicyNumber,
      t2.ExpiringID_P,
      t2.CMLNumber,
      t2.ExpiryDate,
      t2.Country,
      t2.Product,
      t4.RLProfessional AS Professional_Ind,
      ''PF'' AS Coverage,
      CASE 
           WHEN t3.PIIndemnity IS NULL THEN NULL
           WHEN CAST(value AS NUMBER(18,0))= 0 THEN NULL
           WHEN CAST(value AS NUMBER(18,0))<=2000000 THEN 2000000
           WHEN CAST(value AS NUMBER(18,0))<=5000000 THEN 5000000
           WHEN CAST(value AS NUMBER(18,0))<=10000000 THEN 10000000
      END AS PIIndemnity,

      /*Cap at $10m if standard + optional protections > $10m*/
      CASE
           WHEN GREATEST(CAST(t5.value AS NUMBER(18,0)),
                    GREATEST(
                        COALESCE(t3.PIAssessmentLimit, 0),
                        GREATEST(COALESCE(t3.PIBreakdownLimit, 0),
                            COALESCE(t3.PIActsOfOthersLimit, 0)
                        )
                    )
                ) > 10000000 THEN 10000000
        /*Professional limit adjusted to match dropdown options of 2m,5m,10m*/
           WHEN GREATEST(CAST(value AS NUMBER(18,0)),
                    GREATEST(
                        COALESCE(t3.PIAssessmentLimit, 0),
                        GREATEST(COALESCE(t3.PIBreakdownLimit, 0),
                            COALESCE(t3.PIActsOfOthersLimit, 0)
                        )
                    )
                ) <= 2000000 THEN 2000000
           WHEN GREATEST(CAST(value AS NUMBER(18,0)),
                    GREATEST(
                        COALESCE(t3.PIAssessmentLimit, 0),
                        GREATEST(COALESCE(t3.PIBreakdownLimit, 0),
                            COALESCE(t3.PIActsOfOthersLimit, 0)
                        )
                    )
                ) <= 5000000 THEN 5000000
           WHEN GREATEST(CAST(value AS NUMBER(18,0)),
                    GREATEST(
                        COALESCE(t3.PIAssessmentLimit, 0),
                        GREATEST(COALESCE(t3.PIBreakdownLimit, 0),
                            COALESCE(t3.PIActsOfOthersLimit, 0)
                        )
                    )
                ) <= 10000000 THEN 10000000
           ELSE GREATEST(CAST(value AS NUMBER(18,0)),
                    GREATEST(
                        COALESCE(t3.PIAssessmentLimit, 0),
                        GREATEST(COALESCE(t3.PIBreakdownLimit, 0),
                            COALESCE(t3.PIActsOfOthersLimit, 0)
                        )
                    )
                )
      END AS ProfessionalProtectionLimit,
      /*Dummy variable to indicate when Limit of Protection has been reduced to 10m*/
      CASE
           WHEN GREATEST(CAST(value AS NUMBER(18,0)),
                    GREATEST(
                        COALESCE(t3.PIAssessmentLimit, 0),
                        GREATEST(COALESCE(t3.PIBreakdownLimit, 0),
                            COALESCE(t3.PIActsOfOthersLimit, 0)
                        )
                    )
                ) > 10000000 THEN 1
           ELSE 0
      END AS Overridden,/*Requires referral creation if 1*/

      t3.PIAssessmentProtection,/*PURE Field for testing only*/
      CASE 
           WHEN (t3.PIAssessmentProtection IS NULL OR t3.PIAssessmentProtection = 2) THEN ''''
           WHEN t3.PIAssessmentProtection = 1 THEN ''Taken''
           ELSE ''Not Taken''
      END AS VehicleAssessmentProtection,
      t3.PIAssessmentTurnover AS VehicleAssessmentsAnnualTurnover,
      t3.PIAssessmentLimit,/*PURE Field for testing only*/

      t3.PIBreakdownProtection,/*PURE Field for testing only*/
      CASE 
           WHEN (t3.PIBreakdownProtection IS NULL OR t3.PIBreakdownProtection = 2) THEN ''''
           WHEN t3.PIBreakdownProtection = 1 THEN ''Taken''
           ELSE ''Not Taken''
      END AS VehicleBreakdownProtection,
      t3.PIAnnualTurnoverVehService AS VehicleBreakdownAnnualTurnover,
      t3.PIBreakdownLimit,/*PURE Field for testing only*/
      t3.PIActsOfOthers,/*PURE Field for testing only*/
      CASE 
           WHEN (t3.PIActsOfOthers IS NULL OR t3.PIActsOfOthers = 2) THEN ''''
           WHEN t3.PIActsOfOthers = 1 THEN ''Taken''
           ELSE ''Not Taken''
      END AS ContractorsandSubcontractors,
      t3.PIActsOfOthersDetail AS Details,
      t3.PIActsOfOthersLimit,/*PURE Field for testing only*/

      t3.PIRetroactiveCover,/*PURE Field for testing only*/
      CASE 
           WHEN (t3.PIRetroactiveCover IS NULL OR t3.PIRetroactiveCover = 2) THEN ''''
           WHEN t3.PIRetroactiveCover = 1 THEN ''Taken''
           ELSE ''Not Taken''
      END AS RetroactiveProtection,
      CASE
         WHEN  (t3.PIRetroactiveCover = 1 AND CAST(t3.PIDate AS DATE) IS NULL AND CAST(t4.RLProtectionCommencementDate AS DATE) IS NULL) THEN CAST(t4.PolicyInceptionDate AS DATE)
         WHEN t3.PIRetroactiveCover = 1 AND CAST(t3.PIDate AS DATE) IS NULL THEN CAST(t4.RLProtectionCommencementDate AS DATE)
         ELSE CAST(t3.PIDate AS DATE)
      END AS PIDate,
      t3.PIPrevProtection,/*PURE Field for testing only*/
      CASE 
           WHEN (t3.PIPrevProtection IS NULL OR t3.PIPrevProtection = 2) THEN ''''
           WHEN t3.PIPrevProtection = 1 THEN ''Yes''
           ELSE ''No''
      END AS PreviousProfessionalProtection,
      t3.PIPrevClaimEvents,/*PURE Field for testing only*/
      CASE 
           WHEN (t3.PIPrevClaimEvents IS NULL OR t3.PIPrevClaimEvents = 2) THEN ''''
           WHEN t3.PIPrevClaimEvents = 1 THEN ''Yes''
           ELSE ''No''
      END AS PreviousEvent,
      t3.PIVoluntary,/*PURE Field for testing only*/
      CASE 
           WHEN t3.PIVoluntary IS NULL THEN NULL
           WHEN t3.PIVoluntary = 0 THEN 0
           WHEN t3.PIVoluntary <= 500 THEN 500
           WHEN t3.PIVoluntary <= 1000 THEN 1000
           WHEN t3.PIVoluntary <= 2000 THEN 2000
           WHEN t3.PIVoluntary <= 5000 THEN 5000
           ELSE 5000
      END AS VoluntaryExcess
FROM Sample_CBP t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PROFESSIONALPROTECTION t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.UDL_PIUMR002 AS t5 ON t5.UDL_PIUMR002_id = t3.PIIndemnity
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
WHERE t4.RLProfessional = 1 ;



-- ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PFAdj_01 AS
-- SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--              CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS                                                      RecurringIndicator,      
--          t5.UWADJUSTNOTE         AS 								  UnderwritingDescription,
-- 		  COALESCE(t5.UWADJUSTAMOUNT, NULL, 0)   AS AJAdjustmentValue,
--              t4.AJAdjustmentPercent,
--              CASE 
--                   WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
--                    ELSE ''''
--           END AS                                                                 AdjustmentSelection,
--              CASE 
--                WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS                                                                 AdjustmentDollarAndPercent
-- FROM PF_01 t2
-- LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSPI t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
-- LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
-- WHERE t4.AJRecurringIndicator = 1;


-- CREATE OR REPLACE  TRANSIENT TABLE PFAdj_02 AS 
-- SELECT 
-- 	PUREPOLICYNUMBER ,
-- 	EXPIRINGID_P ,
-- 	CMLNUMBER ,
-- 	EXPIRYDATE ,
-- 	COUNTRY ,
-- 	PRODUCT ,
-- 	PROFESSIONAL_IND ,
--     COVERAGE,
-- 	PIINDEMNITY ,
-- 	PROFESSIONALPROTECTIONLIMIT ,
-- 	OVERRIDDEN ,
-- 	PIAssessmentProtection ,
-- 	VEHICLEASSESSMENTPROTECTION ,
-- 	VEHICLEASSESSMENTSANNUALTURNOVER ,
-- 	PIAssessmentLimit ,
-- 	PIBreakdownProtection ,
-- 	VEHICLEBREAKDOWNPROTECTION ,
-- 	VEHICLEBREAKDOWNANNUALTURNOVER ,
-- 	PIBreakdownLimit ,
-- 	PIActsOfOthers ,
-- 	CONTRACTORSANDSUBCONTRACTORS ,
-- 	DETAILS ,
-- 	PIActsOfOthersLimit ,
-- 	PIRetroactiveCover ,
-- 	RETROACTIVEPROTECTION ,
-- 	PIDate ,
-- 	PIPrevProtection,
-- 	PREVIOUSPROFESSIONALPROTECTION ,
-- 	PIPrevClaimEvents ,
-- 	PREVIOUSEVENT ,
-- 	PIVoluntary ,
-- 	VOLUNTARYEXCESS ,
-- 	RECURRINGINDICATOR ,
-- 	UNDERWRITINGDESCRIPTION ,
-- 	AJAdjustmentValue ,
-- 	AJAdjustmentPercent,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentPercent END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM PFAdj_01

-- UNION ALL 

-- SELECT 
-- 	PUREPOLICYNUMBER ,
-- 	EXPIRINGID_P ,
-- 	CMLNUMBER ,
-- 	EXPIRYDATE ,
-- 	COUNTRY ,
-- 	PRODUCT ,
-- 	PROFESSIONAL_IND ,
--     COVERAGE,
-- 	PIINDEMNITY ,
-- 	PROFESSIONALPROTECTIONLIMIT ,
-- 	OVERRIDDEN ,
-- 	PIAssessmentProtection ,
-- 	VEHICLEASSESSMENTPROTECTION ,
-- 	VEHICLEASSESSMENTSANNUALTURNOVER ,
-- 	PIAssessmentLimit ,
-- 	PIBreakdownProtection ,
-- 	VEHICLEBREAKDOWNPROTECTION ,
-- 	VEHICLEBREAKDOWNANNUALTURNOVER ,
-- 	PIBreakdownLimit ,
-- 	PIActsOfOthers ,
-- 	CONTRACTORSANDSUBCONTRACTORS ,
-- 	DETAILS ,
-- 	PIActsOfOthersLimit ,
-- 	PIRetroactiveCover ,
-- 	RETROACTIVEPROTECTION ,
-- 	PIDate ,
-- 	PIPrevProtection,
-- 	PREVIOUSPROFESSIONALPROTECTION ,
-- 	PIPrevClaimEvents ,
-- 	PREVIOUSEVENT ,
-- 	PIVoluntary ,
-- 	VOLUNTARYEXCESS ,
-- 	RECURRINGINDICATOR ,
-- 	UNDERWRITINGDESCRIPTION ,
-- 	AJAdjustmentValue ,
-- 	AJAdjustmentPercent,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentValue END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM PFAdj_01;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Line_ProfessionalProtection_Coverage AS
SELECT DISTINCT * FROM AGGNE.DEV.PF_01;
     --      t1.*,
     --      t2.RecurringIndicator,
     --      t2.UnderwritingDescription,
     --      t2.AJAdjustmentValue,
     --      t2.AJAdjustmentPercent,
     --      t2.AdjustmentSelection,
     --      t2.AdjustmentDollarAndPercent
     -- FROM PF_01 t1
     -- LEFT JOIN
     -- (
     --   SELECT * FROM PFAdj_02
     --   WHERE AdjustmentSelection <> ''''
     --   UNION ALL
     --   SELECT * FROM PFAdj_01
     --   WHERE AdjustmentSelection <> ''''
     -- ) t2
     -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
     --   AND t1.ExpiringID_P = t2.ExpiringID_P
     --   AND t1.CMLNumber = t2.CMLNumber
     --   AND t1.ExpiryDate = t2.ExpiryDate
     --   AND t1.Country = t2.Country
     --   AND t1.Product = t2.Product
     --   AND t1.coverage = t2.coverage
     --   ORDER BY t1.PUREPolicyNumber ;
	   
	   
---------------------------------Line_PublicLiability_Coverage-------------------------------------------------------

-- ============================================================
-- FIX [C3]: PP_01 — Impossible IS NULL AND field = 2 conditions (6 occurrences)
-- SAS LOGIC (ProductandPublicLiability_conversionscriptCapricorn, DATA step):
--   IF PP1PropOwnersOnly = . THEN PropertyOwner = ''; /* . is SAS missing value */
--   IF PP1PropOwnersOnly = 2  THEN PropertyOwner = '';
--   (Both conditions independently lead to blank output — equivalent to: IF . OR 2 THEN blank)
-- ISSUE: Each WHEN used (field IS NULL AND field = 2) which is always FALSE
--        (a column cannot be both NULL and equal to 2 simultaneously).
--        Result: the blank-output guard never triggered → fields that should be blank
--        for NULL or value=2 records were incorrectly classified as ''Taken''/''Not Taken''/etc.
-- FIX: Changed AND → OR in each guard condition (6 occurrences: PropOwnersOnly,
--      ActsOfOthers, AssumeLiabCover, ContractSubmitted, RectifyFaultyWork, HiredToOthers)
-- OLD CODE pattern: WHEN (field IS NULL AND field = 2) THEN ''''
-- NEW CODE pattern: WHEN (field IS NULL OR field = 2) THEN ''''
-- ============================================================
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PP_01 AS
SELECT
		  t2.PUREPolicyNumber,
          t2.ExpiringID_P,
          t2.CMLNumber,
          t2.ExpiryDate,
          t2.Country,
          t2.Product,
          t4.RLPublicProducts AS ProductANDPublic_Ind,
          ''PP'' AS Coverage,
		  t4.RLStreet AS Street,								
		  t4.RLSuburb AS Suburb,	
		  t4.RLPostCode	AS PostCode,
		  CASE WHEN t2.Country = ''New Zealand'' THEN ''NZ''
			   ELSE t4.RLState
		  END AS State, 
/*standard protections - STANDARD*/ 
		  CAST(t7.value AS NUMBER(18,0)) AS ProductLimit,/*PURE Field for testing only*/
		  CAST(t6.value AS NUMBER(18,0)) AS PublicLimit,/*PURE Field for testing only*/
		  CASE 
               WHEN (t3.PP1ProductLiab IS NULL OR t3.PP1PublicLiab IS NULL ) THEN ''''
               WHEN (t3.PP1ProductLiab IN (2,3,4,5) OR t3.PP1PublicLiab IN (2,3,4,5)) THEN ''Taken''
               ELSE ''Not Taken''
             END AS Standard,
	/*standard protections - standard*/
 		  CASE
            	WHEN (CAST(t7.value AS NUMBER(18,0)) = 0 AND CAST(t6.value AS NUMBER(18,0)) = 0) THEN NULL
				WHEN CAST(t7.value AS NUMBER(18,0)) > CAST(t6.value AS NUMBER(18,0)) THEN CAST(t7.value AS NUMBER(18,0))
				WHEN CAST(t6.value AS NUMBER(18,0)) > CAST(t7.value AS NUMBER(18,0)) THEN CAST(t6.value AS NUMBER(18,0))
				ELSE CAST(t6.value AS NUMBER(18,0))
          END AS ProductsandPublicLiabilityLimit,
/*standard protections - PROPERTYOWNER*/ 
		  t3.PP1PropOwnersOnly,/*PURE Field for testing only*/
		  CASE 
               WHEN (t3.PP1PropOwnersOnly IS NULL OR t3.PP1PropOwnersOnly = 2)  THEN ''''
               WHEN t3.PP1PropOwnersOnly = 1 AND PP1PropOwnersLiab <> 1 THEN ''Taken''
               ELSE ''Not Taken''
          END AS PropertyOwner,
		/*standard protections - property owners*/
		  CASE
            	WHEN t3.PP1PropOwnersLiab IS NULL  THEN NULL
            	WHEN CAST(t5.value AS NUMBER(18,0)) = 0 THEN NULL
            	WHEN CAST(t5.value AS NUMBER(18,0)) = 5000000 THEN 5000000
            	WHEN CAST(t5.value AS NUMBER(18,0)) = 10000000 THEN 10000000
            	WHEN CAST(t5.value AS NUMBER(18,0)) = 20000000 THEN 20000000
				WHEN CAST(t5.value AS NUMBER(18,0)) = 20000000 THEN 20000000
                ELSE NULL
          END AS PropertyOwnersLiabilityLimit,
		  
/*optional protections*/	   
		   t3.PP1ActsOfOthers,/*PURE Field for testing only*/
		   CASE
		       WHEN t3.PP1PropOwnersOnly = 1 AND PP1PropOwnersLiab <> 1 THEN ''''
			   ELSE
		        CASE 
		  	      WHEN (t3.PP1ActsOfOthers IS NULL OR t3.PP1ActsOfOthers = 2) THEN ''''
                  WHEN t3.PP1ActsOfOthers = 1 THEN ''Taken''
                  ELSE ''Not Taken''
			    END
          END AS ContractorsandSubcontractors,
		  t3.PP1AssumeLiabCover,/*PURE Field for testing only*/
 		  CASE 
		  	   WHEN (t3.PP1AssumeLiabCover IS NULL OR t3.PP1AssumeLiabCover = 2) THEN ''''
               WHEN t3.PP1AssumeLiabCover = 1 THEN ''Taken''
               ELSE ''Not Taken''
          END AS AssumedLiability,
		  t3.PP1ContractSubmitted, /*PURE Field for testing only*/
		  CASE 
		  	   WHEN (t3.PP1ContractSubmitted IS NULL OR t3.PP1ContractSubmitted = 2) THEN ''''
               WHEN t3.PP1ContractSubmitted = 1 THEN ''Yes''
               ELSE ''No''
          END AS ContractandAgreementUnderwriter,
		  CASE 
		  	   WHEN t3.PP1Details = '''' THEN ''.''
               ELSE t3.PP1Details
          END AS Details,
		  t3.PP1RectifyFaultyWork,/*PURE Field for testing only*/
		  CASE 
		  	   WHEN (t3.PP1RectifyFaultyWork IS NULL OR t3.PP1RectifyFaultyWork = 2) THEN ''''
               WHEN t3.PP1RectifyFaultyWork = 1 THEN ''Taken''
               ELSE ''Not Taken''
          END AS CostofRectifying/*CostofRectifyingFaultyWorkmanship*/,
		  t3.PP1AnnualTurnoverCalc,/*PURE Field for testing only*/
		  CASE
		   WHEN t3.PP1RectifyFaultyWork = 1 AND t3.PP1AnnualTurnoverCalc IS NOT NULL THEN
		     CASE
            	WHEN t3.PP1AnnualTurnoverCalc <= 25000 THEN 25000
            	WHEN t3.PP1AnnualTurnoverCalc <= 50000 THEN 50000
            	WHEN t3.PP1AnnualTurnoverCalc <= 75000 THEN 75000
            	WHEN t3.PP1AnnualTurnoverCalc <= 100000 THEN 100000
                ELSE 100000
			 END
		   ELSE NULL
          END AS CostofRectifyinglimit/*CostofRectifyingFaultyWorkmanship*/,
		  t3.PP2HiredToOthers,/*PURE Field for testing only*/
		  CASE 
		  	   WHEN (t3.PP2HiredToOthers IS NULL OR t3.PP2HiredToOthers = 2) THEN ''''
               WHEN t3.PP2HiredToOthers = 1 THEN ''Taken''
               ELSE ''Not Taken''
          END AS EquipmentGoods/*EquipmentGoodsorVehiclesHiredtoOthers*/,
		  CASE 
		  	   WHEN t9.PP2Details = '''' THEN ''.''
               ELSE t9.PP2Details
          END AS EquipmentGoodsDetails, 
/*excesses*/
		  t3.PP3Voluntary,/*PURE Field for testing only*/
          CASE 
               WHEN t3.PP3Voluntary IS NULL THEN NULL
			   WHEN t3.PP3Voluntary = 0 THEN 0
               WHEN t3.PP3Voluntary <= 500 THEN 500
			   WHEN t3.PP3Voluntary <= 1000 THEN 1000
               WHEN t3.PP3Voluntary <= 2000 THEN 2000
			   WHEN t3.PP3Voluntary <= 5000 THEN 5000
			   ELSE 5000
          END AS VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_PUBLICPRODUCTS t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.UDL_PPUMR001 AS t5 ON t5.UDL_PPUMR001_id = t3.PP1PropOwnersLiab
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.UDL_PPUMR002 AS t6 ON t6.UDL_PPUMR002_id = t3.PP1PublicLiab
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.UDL_PPUMR003 AS t7 ON t7.UDL_PPUMR003_id = t3.PP1ProductLiab
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.UDL_PPUMR004 AS t8 ON t8.UDL_PPUMR004_id = t3.PP1PropCareCustCon
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_EQUIPGOODSDETAIL AS t9 ON t2.ExpiringID_P = t9.CBP_Policy_Binder_id
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_RISKSELECTION t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
		WHERE NVL(t3.PP1RunOffLiab,0) < 1 
        AND t4.RLPublicProducts = 1;




-- CREATE OR REPLACE  TRANSIENT TABLE PPAdj_01 AS
-- SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--              CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS                                                      RecurringIndicator,      
--          t5.UWADJUSTNOTE         AS 								  UnderwritingDescription,
-- 		  COALESCE(t5.UWADJUSTAMOUNT, NULL, 0)   AS AJAdjustmentValue,
--              t4.AJAdjustmentPercent,
--              CASE 
--                   WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
--                    ELSE ''''
--           END AS                                                                 AdjustmentSelection,
--              CASE 
--                WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS                                                                 AdjustmentDollarAndPercent
-- FROM PP_01 t2
-- LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSPP t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
-- LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
-- WHERE t4.AJRecurringIndicator = 1;


-- ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PPAdj_02 AS
-- SELECT 
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- PRODUCTANDPUBLIC_IND,
-- COVERAGE,
-- STREET,
-- SUBURB,
-- POSTCODE,
-- STATE,
-- PRODUCTLIMIT,
-- PUBLICLIMIT,
-- STANDARD,
-- PRODUCTSANDPUBLICLIABILITYLIMIT,
-- PP1PropOwnersOnly,
-- PROPERTYOWNER,
-- PROPERTYOWNERSLIABILITYLIMIT,
-- PP1ActsOfOthers,
-- CONTRACTORSANDSUBCONTRACTORS,
-- PP1AssumeLiabCover,
-- ASSUMEDLIABILITY,
-- PP1ContractSubmitted,
-- CONTRACTANDAGREEMENTUNDERWRITER,
-- DETAILS,
-- PP1RectifyFaultyWork,
-- COSTOFRECTIFYING,
-- PP1AnnualTurnoverCalc,
-- COSTOFRECTIFYINGLIMIT,
-- PP2HiredToOthers,
-- EQUIPMENTGOODS,
-- EQUIPMENTGOODSDETAILS,
-- PP3Voluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentPercent
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM PPAdj_01


-- UNION ALL

-- SELECT 
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- PRODUCTANDPUBLIC_IND,
-- COVERAGE,
-- STREET,
-- SUBURB,
-- POSTCODE,
-- STATE,
-- PRODUCTLIMIT,
-- PUBLICLIMIT,
-- STANDARD,
-- PRODUCTSANDPUBLICLIABILITYLIMIT,
-- PP1PropOwnersOnly,
-- PROPERTYOWNER,
-- PROPERTYOWNERSLIABILITYLIMIT,
-- PP1ActsOfOthers,
-- CONTRACTORSANDSUBCONTRACTORS,
-- PP1AssumeLiabCover,
-- ASSUMEDLIABILITY,
-- PP1ContractSubmitted,
-- CONTRACTANDAGREEMENTUNDERWRITER,
-- DETAILS,
-- PP1RectifyFaultyWork,
-- COSTOFRECTIFYING,
-- PP1AnnualTurnoverCalc,
-- COSTOFRECTIFYINGLIMIT,
-- PP2HiredToOthers,
-- EQUIPMENTGOODS,
-- EQUIPMENTGOODSDETAILS,
-- PP3Voluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentValue
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM PPAdj_01



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Line_PublicLiability_Coverage AS
SELECT distinct * from AGGNE.DEV.PP_01;
--   t1.*,
--   t2.RecurringIndicator,
--   t2.UnderwritingDescription,
--   t2.AJAdjustmentValue,
--   t2.AJAdjustmentPercent,
--   t2.AdjustmentSelection,
--   t2.AdjustmentDollarAndPercent
-- FROM PP_01 t1
-- LEFT JOIN
-- (
--     SELECT * FROM PPAdj_02
--     WHERE AdjustmentSelection <> ''''
--     UNION ALL
--     SELECT * FROM PPAdj_01
--     WHERE AdjustmentSelection <> ''''
-- ) t2
-- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
-- AND t1.ExpiringID_P = t2.ExpiringID_P
-- AND t1.CMLNumber = t2.CMLNumber
-- AND t1.ExpiryDate = t2.ExpiryDate
-- AND t1.Country = t2.Country
-- AND t1.Product = t2.Product
-- AND t1.coverage = t2.coverage
-- ORDER BY t1.PUREPolicyNumber;


------------------------------Line_SV_Coverage---------------------------------------------------------------------------------------------------------

   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.SV_01 AS
   SELECT
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLStockVehicles AS StockVehicles_Ind,
          ''SV'' AS Coverage,
          

/*standard protections*/
          t5.description, /*PURE Field for testing only*/
		  CASE 
               WHEN t5.description = ''Comprehensive'' THEN ''Full Comprehensive''
			   WHEN t5.description = ''Third Party Only'' THEN ''Third Party Only''
               WHEN t5.description = '''' THEN ''''
          END AS 										ProtectionType,
		  t3.UVSumProtected, /*PURE Field for testing only*/
          CASE 
               WHEN t5.description = ''Comprehensive'' THEN
		      CASE 
               WHEN t3.UVSumProtected IS NULL THEN NULL
			   WHEN t3.UVSumProtected = 0 THEN NULL
               WHEN t3.UVSumProtected <= 30000 THEN 30000
			   WHEN t3.UVSumProtected <= 50000 THEN 50000
               WHEN t3.UVSumProtected <= 75000 THEN 75000
			   WHEN t3.UVSumProtected <= 100000 THEN 100000
			   WHEN t3.UVSumProtected <= 150000 THEN 150000
			   WHEN t3.UVSumProtected <= 200000 THEN 200000
               WHEN t3.UVSumProtected <= 250000 THEN 250000
			   WHEN t3.UVSumProtected <= 300000 THEN 300000
			   ELSE 300000
               END
                ELSE 0
          END AS 										LossDamageLimit,
		  t3.UVDealersLicence, /*PURE Field for testing only*/
		  CASE 
			   WHEN (t3.UVDealersLicence IS NULL OR t3.UVDealersLicence = 2) THEN ''''
			   WHEN t3.UVDealersLicence = 1 THEN ''Yes''
			   ELSE ''No''
          END AS 										DoYouHaveADealersLicense,
		  (t3.UVPassengerCommercialVehicle 
			+ t3.UVAgriculturalVehicles
			+ t3.UVGoodsCarryingTonnage
			+ t3.UVMotorcycles
		  	+ t3.UVWatercraft
			+ t3.UVConstructionEquipment
			+ t3.UVCaravanHomes
			+ t3.UVBoatTrailers) AS 					NOfVehWatercraftsHeld/*NumberOfVehiclesWatercraftsHeldAsStockByYou*/,
		  t3.UVAvgEstVehValue AS 						AverageValueOfTheVeh/*WhatIsTheAverageValueOfTheVehiclesHeldInStock*/,
		  t3.UVMaxEstVehValue AS 						MaximumEstimatedValue/*WhatIsTheMaximumEstimatedValueOfAnySingleVehicle*/, 

/*optional protection*/
		  t3.UVGlassExcessRemoval, /*PURE Field for testing only*/
		  CASE 
			   WHEN t3.UVGlassExcessRemoval = 1 THEN ''Taken''
			   WHEN t3.UVGlassExcessRemoval IS NULL OR t3.UVGlassExcessRemoval = 2 THEN ''''
			   ELSE ''Not Taken''
		  END AS 										ExcessWaiverForWindscreen, 
/*excesses*/
		  t3.UVVoluntary, /*PURE Field for testing only*/
          CASE 
               WHEN t3.UVVoluntary IS NULL THEN NULL
			   WHEN t3.UVVoluntary = 0 THEN 0
               WHEN t3.UVVoluntary <= 500 THEN 500
			   WHEN t3.UVVoluntary <= 1000 THEN 1000
               WHEN t3.UVVoluntary <= 2000 THEN 2000
			   WHEN t3.UVVoluntary <= 5000 THEN 5000
			   ELSE 5000
          END AS 										VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_stockvehicle t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_uvumr001 AS t5 ON t5.UDL_UVUMR001_id = t3.UVProtectionType
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	 t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where t4.RLStockVehicles = 1;
    

--    ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.SVAdj_01 AS
--    SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--              CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS                                                      RecurringIndicator,      
--          t5.UWADJUSTNOTE         AS 								  UnderwritingDescription,
-- 		  COALESCE(t5.UWADJUSTAMOUNT, NULL, 0)   AS AJAdjustmentValue,
--              t4.AJAdjustmentPercent,
--              CASE 
--                   WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
--                    ELSE ''''
--           END AS                                                                 AdjustmentSelection,
--              CASE 
--                WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS                                                                 AdjustmentDollarAndPercent
-- 	FROM SV_01 t2
-- 	LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsuv t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--     LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--      WHERE t4.AJRecurringIndicator = 1;


-- ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.SVAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- STOCKVEHICLES_IND,
-- COVERAGE,
-- description,
-- PROTECTIONTYPE,
-- UVSumProtected,
-- LOSSDAMAGELIMIT,
-- UVDealersLicence,
-- DOYOUHAVEADEALERSLICENSE,
-- NOFVEHWATERCRAFTSHELD,
-- AVERAGEVALUEOFTHEVEH,
-- MAXIMUMESTIMATEDVALUE,
-- UVGlassExcessRemoval,
-- EXCESSWAIVERFORWINDSCREEN,
-- UVVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentPercent
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
--   FROM SVAdj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- STOCKVEHICLES_IND,
-- COVERAGE,
-- description,
-- PROTECTIONTYPE,
-- UVSumProtected,
-- LOSSDAMAGELIMIT,
-- UVDealersLicence,
-- DOYOUHAVEADEALERSLICENSE,
-- NOFVEHWATERCRAFTSHELD,
-- AVERAGEVALUEOFTHEVEH,
-- MAXIMUMESTIMATEDVALUE,
-- UVGlassExcessRemoval,
-- EXCESSWAIVERFORWINDSCREEN,
-- UVVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentValue
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM SVAdj_01



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Line_SV_Coverage AS
SELECT * from AGGNE.DEV.SV_01;
-- t1.*
-- 	,t2.RecurringIndicator
-- 	,t2.UnderwritingDescription
-- 	,t2.AJAdjustmentValue
-- 	,t2.AJAdjustmentPercent
-- 	,t2.AdjustmentSelection
-- 	,t2.AdjustmentDollarAndPercent
-- FROM SV_01 t1
-- LEFT JOIN (
-- 	SELECT *
-- 	FROM SVAdj_02
-- 	WHERE AdjustmentSelection <> ''''
	
-- 	UNION ALL
	
-- 	SELECT *
-- 	FROM SVAdj_01
-- 	WHERE AdjustmentSelection <> ''''
-- 	) t2 ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
-- 	AND t1.ExpiringID_P = t2.ExpiringID_P
-- 	AND t1.CMLNumber = t2.CMLNumber
-- 	AND t1.ExpiryDate = t2.ExpiryDate
-- 	AND t1.Country = t2.Country
-- 	AND t1.Product = t2.Product
--     AND t1.coverage = t2.coverage
--     order by t1.PUREPolicyNumber;
	
	
-----------------------------------------------TA_Coverage-----------------------------------------------------------------

   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.TA_01 AS
   SELECT 
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLTaxAudit AS TaxAudit_Ind,
          ''TA'' AS Coverage,

/*standard protections*/
          t5.value AS TALimit, /*PURE Field for testing only*/
		  CASE 
               WHEN t3.TALimit IS NULL THEN NULL
			   WHEN t5.value = 0 THEN NULL
			   WHEN t5.value <= 10000 THEN 10000
               WHEN t5.value <= 25000 THEN 25000
			   WHEN t5.value <= 50000 THEN 50000
			   WHEN t5.value <= 75000 THEN 75000
			   WHEN t5.value <= 100000 THEN 100000
			   WHEN t5.value <= 150000 THEN 150000
			   WHEN t5.value <= 200000 THEN 200000
		  END AS										TaxauditLimit,
		  t3.TATaxNotification, /*PURE Field for testing only*/
		  CASE 
			   WHEN t3.TATaxNotification IS NULL OR  t3.TATaxNotification = 2 THEN ''''
			   WHEN t3.TATaxNotification = 1 THEN ''Yes''
			   ELSE ''No''
          END AS 										AustraliaTaxOfficeNotification,
		  CASE 
			   WHEN t3.TATaxNotification = 1 THEN ''.''
			   ELSE ''''
          END AS 						AusTaxOfficeNotificationDetails/*AustraliaTaxOfficeNotificationDetails*/,
		  t3.TATaxInvestigation, /*PURE Field for testing only*/
		  CASE 
			   WHEN t3.TATaxInvestigation IS NULL OR t3.TATaxInvestigation = 2 THEN ''''
			   WHEN t3.TATaxInvestigation = 1 THEN ''Yes''
			   ELSE ''No''
          END AS 										AusTaxOfficeHasBeenInvestigated/*AustraliaTaxOfficeHasBeenInvestigated*/,
		  t3.TATaxInvesDetails AS						Details,
		 		  
/*excesses*/
		  t3.TAVoluntary, /*PURE Field for testing only*/
          CASE 
               WHEN t3.TAVoluntary IS NULL THEN NULL
			   WHEN t3.TAVoluntary = 0 THEN 0
               WHEN t3.TAVoluntary <= 500 THEN 500
			   WHEN t3.TAVoluntary <= 1000 THEN 1000
               WHEN t3.TAVoluntary <= 2000 THEN 2000
			   WHEN t3.TAVoluntary <= 4500 THEN 4500
			   ELSE 4500
          END AS 										VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_taxaudit t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_taumr001 AS t5 ON t5.UDL_TAUMR001_id = t3.TALimit
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	 t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where t4.RLTaxAudit = 1;



 
-- ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.TAAdj_01 AS
--    SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--              CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS                                                      RecurringIndicator,      
--          t5.UWADJUSTNOTE         AS 								  UnderwritingDescription,
-- 		  COALESCE(t5.UWADJUSTAMOUNT, NULL, 0)   AS AJAdjustmentValue,
--              t4.AJAdjustmentPercent,
--              CASE 
--                   WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
--                    ELSE ''''
--           END AS                                                                 AdjustmentSelection,
--              CASE 
--                WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
--                    WHEN (t5.UWADJUSTAMOUNT IS NULL OR COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
--                    WHEN COALESCE(t5.UWADJUSTAMOUNT, NULL, 0) <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS                                                                 AdjustmentDollarAndPercent
-- 	FROM TA_01 t2
-- 	LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsta t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--     LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--     WHERE t4.AJRecurringIndicator = 1;
   


-- ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.TAAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- TAXAUDIT_IND,
-- COVERAGE,
-- TALIMIT,
-- TAXAUDITLIMIT,
-- TATaxNotification,
-- AUSTRALIATAXOFFICENOTIFICATION,
-- AUSTAXOFFICENOTIFICATIONDETAILS,
-- TATaxInvestigation,
-- AUSTAXOFFICEHASBEENINVESTIGATED,
-- DETAILS,
-- TAVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--   CASE 
--     WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentPercent
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM TAAdj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- TAXAUDIT_IND,
-- COVERAGE,
-- TALIMIT,
-- TAXAUDITLIMIT,
-- TATaxNotification,
-- AUSTRALIATAXOFFICENOTIFICATION,
-- AUSTAXOFFICENOTIFICATIONDETAILS,
-- TATaxInvestigation,
-- AUSTAXOFFICEHASBEENINVESTIGATED,
-- DETAILS,
-- TAVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--  CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
--     END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN AJAdjustmentValue
-- 	END AS ADJUSTMENTDOLLARANDPERCENT
--     FROM TAAdj_01;


   CREATE  OR REPLACE TRANSIENT TABLE Line_TA_Coverage AS
         SELECT distinct * from AGGNE.DEV.TA_01;
         --          t1.*,
         --          t2.RecurringIndicator,
         --          t2.UnderwritingDescription,
         --          t2.AJAdjustmentValue,
         --          t2.AJAdjustmentPercent,
         --          t2.AdjustmentSelection,
         --          t2.AdjustmentDollarAndPercent
         -- FROM TA_01 t1
         -- LEFT JOIN
         -- (
         --   SELECT  * FROM TAAdj_02
         --   WHERE AdjustmentSelection <> ''''
         --   UNION ALL
         --   SELECT  * FROM TAAdj_01
         --   WHERE AdjustmentSelection <> ''''
         -- ) t2
         -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
         --   AND t1.ExpiringID_P = t2.ExpiringID_P
         --   AND t1.CMLNumber = t2.CMLNumber
         --   AND t1.ExpiryDate = t2.ExpiryDate
         --   AND t1.Country = t2.Country
         --   AND t1.Product = t2.Product
         --   AND t1.coverage = t2.coverage
         --   ORDER BY PUREPOLICYNUMBER;
		   
		   
--------------------------------------------------1.7@@LineCoverages@@end@@---------------------------------------------------------------------------------------------------

--------------------------------------------------1.8@@LocationCoverages@@start@@------------------------------------------------------------------------------------------------

--------------------------------------------------Busines Building-------------------------------------------------------------------------


   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.BB_01 AS
   SELECT 
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.expirydate,
		  t2.Country,
          t2.Product,
          ''BB'' AS Coverage,
          t4.RLBusinessBuildings AS BusinessBuilding_Ind,

/*standard protections*/
          t3.BBSumProtected AS 											BusinessBuildingsLimit,

/*optional protections*/
          t3.BBAccidentalDamage AS 										AccidentalLossOrDamageLimit,
		  t3.BBFixedGlass, /*PURE Field for testing only*/
		  CASE 
			   WHEN t3.BBFixedGlass > 0 THEN ''Taken''
               ELSE ''Not Taken''
          END AS 														Glass,
		  CASE 
               WHEN t3.BBFixedGlass = 0 OR t3.BBFixedGlass IS NULL THEN ''''
               WHEN t3.BBFixedGlass BETWEEN 1 AND 10 THEN ''0-10''
			   WHEN t3.BBFixedGlass BETWEEN 11 AND 20 THEN ''11-20''
               WHEN t3.BBFixedGlass BETWEEN 21 AND 30 THEN ''21-30''
               WHEN t3.BBFixedGlass BETWEEN 31 AND 40 THEN ''31-40''
			   ELSE ''41+''
          END AS 														FixedGlass,
		  t3.BBLossRent AS 												LossOfRentLimit, 
		  t3.BBLandslideLimit AS 											LandslideLimit /*Applies to NZ only*/, 
		  t3.BBFloodProtection, /*PURE Field for testing only*/
		  CASE 
               WHEN t3.BBFloodProtection > 0 THEN ''Taken''
               ELSE ''Not Taken''
          END AS 														FloodDamage,
		  
/*excesses*/
		  t3.BBVoluntary, /*PURE Field for testing only*/
          CASE 
               WHEN t3.BBVoluntary IS NULL THEN NULL
			   WHEN t3.BBVoluntary = 0 THEN 0
               WHEN t3.BBVoluntary <= 500 THEN 500
			   WHEN t3.BBVoluntary <= 1000 THEN 1000
               WHEN t3.BBVoluntary <= 2000 THEN 2000
               WHEN t3.BBVoluntary <= 4500 THEN 4500
			   ELSE 4500
          END AS 											VoluntaryExcess
	FROM sample_cbp t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_businessbuildings t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	 t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    WHERE t4.RLBusinessBuildings = 1;
     


-- CREATE OR REPLACE  transient table BBAdj_01 AS
--    SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--    		  CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS  																RecurringIndicator,      
--           t5.UWADJUSTNOTE AS 												UnderwritingDescription,
-- 		  t5.UWADJUSTAMOUNT AS AJAdjustmentValue, /*PURE Field for testing only*/	
-- 		  t4.AJAdjustmentPercent, /*PURE Field for testing only*/	
-- 		  CASE 
-- 		       WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
-- 			   ELSE ''''
--           END AS                                                 				AdjustmentSelection,
-- 		  CASE 
--                WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS 																AdjustmentDollarAndPercent
-- 	FROM bb_01 t2
-- 	LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsbb t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--     INNER JOIN aggne.dev.Output_UWAdjust_BSP t5 ON (t2.ExpiringID_P = t5.expiringid_p) AND (t2.coverage = t5.coverage)
--     WHERE t4.AJRecurringIndicator = 1;



-- ;CREATE OR REPLACE TRANSIENT  TABLE BBAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- Coverage,
-- BUSINESSBUILDING_IND,
-- BUSINESSBUILDINGSLIMIT,
-- ACCIDENTALLOSSORDAMAGELIMIT,
-- BBFixedGlass,
-- GLASS,
-- FIXEDGLASS,
-- LOSSOFRENTLIMIT,
-- LANDSLIDELIMIT,
-- BBFloodProtection,
-- FLOODDAMAGE,
-- BBVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--  CASE 
--          WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentPercent END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM bbadj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- Coverage,
-- BUSINESSBUILDING_IND,
-- BUSINESSBUILDINGSLIMIT,
-- ACCIDENTALLOSSORDAMAGELIMIT,
-- BBFixedGlass,
-- GLASS,
-- FIXEDGLASS,
-- LOSSOFRENTLIMIT,
-- LANDSLIDELIMIT,
-- BBFloodProtection,
-- FLOODDAMAGE,
-- BBVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentValue END AS ADJUSTMENTDOLLARANDPERCENT
-- FROM bbadj_01;




;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Location_BB_Coverage AS
SELECT DISTINCT * FROM AGGNE.DEV.BB_01;
--   t1.*,
--   t2.RecurringIndicator,
--   t2.UnderwritingDescription,
--   t2.AJAdjustmentValue,
--   t2.AJAdjustmentPercent,
--   t2.AdjustmentSelection,
--   t2.AdjustmentDollarAndPercent
-- FROM
--   bb_01 t1
--   LEFT JOIN (SELECT * FROM bbadj_01
--     WHERE
--       AdjustmentSelection <> ''''
--     UNION ALL
--     SELECT * FROM bbadj_02
--     WHERE
--       AdjustmentSelection <> ''''
--   ) t2 ON t1.PUREPolicyNumber=t2.PUREPolicyNumber
--   AND t1.ExpiringID_P=t2.ExpiringID_P
--   AND t1.CMLNumber=t2.CMLNumber
--   AND t1.expirydate=t2.expirydate
--   AND t1.Country=t2.Country
--   AND t1.Product=t2.Product
--   AND t1.Coverage = T2.Coverage
--   ORDER BY PUREPOLICYNUMBER;
  
 
 

----------------------------------------Business Contents---------------------------------------------
 
   ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.BC_01 AS
   SELECT t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLBusinessContents AS BusinessContents_Ind,
          ''BC'' AS Coverage,
   
/*standard protections*/
          t3.BCContents AS                           ContentsLimit,
		  t3.BCStockWork AS                          StockLimitexvehicleswatercraft,/*StockLimitexcludingvehicleswatercraft*/
		  t3.BCPersonalEffects AS 				     PersonalEffectsLimit,
		  t3.BCMotorFuels AS 						 MotorFuelsLimit,
		  t3.BCVehiclesInStock AS 				     VehiclesinStockLimit,
          t3.BCCustomerVehicles AS					 CustomersVehiclesLimit,
		  t3.BCWatercraftUnder8m AS 				 WatercraftinStockunder8mLimit,
		  t3.BCCustWatercraftUnder8m AS 			 CustomersWatercraftunder8mLimit,
		  t3.BCEmployeeTools AS					     EmployeeToolsofTradeLimit,

/*optional protections*/
		  t3.BCAccidentalLossDamage AS               AccidentalLossorDamageLimit,
		  t3.BCFloodProtection, /*PURE Field for testing only*/	
		  CASE 
               WHEN t3.BCFloodProtection > 0 THEN ''Taken''
               ELSE ''Not Taken''
          END AS                                     FloodDamage,
		  t3.BCHailDamage AS 					     HailDamage, /*HailDamagetoVehiclesorWatercraftsinStockLimit*/
		  t3.BCHailNetting AS 						 ProportionofHailNetting,
		  t3.BCLandslideLimit AS                     LandslideLimit /*Applies to NZ only*/, 

/*excesses*/
		  t3.BCVoluntary, /*PURE Field for testing only*/	
          CASE 
			   WHEN t3.BCVoluntary IS NULL THEN NULL
			   WHEN t3.BCVoluntary = 0 THEN 0
               WHEN t3.BCVoluntary <= 500 THEN 500
			   WHEN t3.BCVoluntary <= 1000 THEN 1000
               WHEN t3.BCVoluntary <= 2000 THEN 2000
			   ELSE 2000
          END AS                                     VoluntaryExcess
    FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_businesscontents t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    WHERE t4.RLBusinessContents = 1 ;



--    ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.BCAdj_01 AS
--    SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--    		  CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS  																RecurringIndicator,      
--           t5.UWADJUSTNOTE AS 												UnderwritingDescription,
-- 		  t5.UWADJUSTAMOUNT AS AJAdjustmentValue, /*PURE Field for testing only*/	
-- 		  t4.AJAdjustmentPercent, /*PURE Field for testing only*/	
-- 		  CASE 
-- 		       WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
-- 			   ELSE ''''
--           END AS                                                 				AdjustmentSelection,
-- 		  CASE 
--                WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS 																AdjustmentDollarAndPercent
--       FROM BC_01 t2
--       LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsbc t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--       LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--       WHERE t4.AJRecurringIndicator = 1;
    



-- ;CREATE OR REPLACE TRANSIENT  TABLE BCAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- BUSINESSCONTENTS_IND,
-- COVERAGE,
-- CONTENTSLIMIT,
-- STOCKLIMITEXVEHICLESWATERCRAFT,
-- PERSONALEFFECTSLIMIT,
-- MOTORFUELSLIMIT,
-- VEHICLESINSTOCKLIMIT,
-- CUSTOMERSVEHICLESLIMIT,
-- WATERCRAFTINSTOCKUNDER8MLIMIT,
-- CUSTOMERSWATERCRAFTUNDER8MLIMIT,
-- EMPLOYEETOOLSOFTRADELIMIT,
-- ACCIDENTALLOSSORDAMAGELIMIT,
-- BCFloodProtection,
-- FLOODDAMAGE,
-- HAILDAMAGE,
-- PROPORTIONOFHAILNETTING,
-- LANDSLIDELIMIT,
-- BCVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--   CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentPercent END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM bcadj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- BUSINESSCONTENTS_IND,
-- COVERAGE,
-- CONTENTSLIMIT,
-- STOCKLIMITEXVEHICLESWATERCRAFT,
-- PERSONALEFFECTSLIMIT,
-- MOTORFUELSLIMIT,
-- VEHICLESINSTOCKLIMIT,
-- CUSTOMERSVEHICLESLIMIT,
-- WATERCRAFTINSTOCKUNDER8MLIMIT,
-- CUSTOMERSWATERCRAFTUNDER8MLIMIT,
-- EMPLOYEETOOLSOFTRADELIMIT,
-- ACCIDENTALLOSSORDAMAGELIMIT,
-- BCFloodProtection,
-- FLOODDAMAGE,
-- HAILDAMAGE,
-- PROPORTIONOFHAILNETTING,
-- LANDSLIDELIMIT,
-- BCVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentValue END AS ADJUSTMENTDOLLARANDPERCENT 
--     FROM bcadj_01;


CREATE OR REPLACE  TRANSIENT TABLE Location_BC_Coverage AS
SELECT    DISTINCT * FROM AGGNE.DEV.BC_01;
--           t1.*,
--           t2.recurringindicator,
--           t2.underwritingdescription,
--           t2.AJAdjustmentValue,
--           t2.AJAdjustmentPercent,
--           t2.adjustmentselection,
--           t2.adjustmentdollarandpercent
-- FROM      bc_01 t1
-- LEFT JOIN
--           (
--                  SELECT *
--                  FROM   bcadj_02
--                  WHERE  adjustmentselection <> ''''
--                  UNION ALL
--                  SELECT *
--                  FROM   bcadj_01
--                  WHERE  adjustmentselection <> '''' ) t2
-- ON        t1.purepolicynumber = t2.purepolicynumber
-- AND       t1.expiringid_p = t2.expiringid_p
-- AND       t1.cmlnumber = t2.cmlnumber
-- AND       t1.expirydate = t2.expirydate
-- AND       t1.country = t2.country
-- AND       t1.product = t2.product 
-- AND       t1.coverage = t2.coverage
-- ORDER BY purepolicynumber;


------------------------------------------------------------------Burglary-------------------------------------------------------------------------------------

;CREATE OR REPLACE TRANSIENT  TABLE AGGNE.DEV.BG_01 AS
   SELECT 
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
		  t4.RLBurglary AS Burglary_Ind,
          ''BG'' AS COVERAGE,

/*standard protections*/
          t3.BGContents + t3.BGEmployeeTools AS 						ContentsStockEmployeeToolsLimit,
		  t3.BGPersonalEffects AS 										PersonalEffectsLimit,
		  t3.BGMotorFuels AS 											MotorFuelsLimit,
		  t3.BGTobacco AS 												TobaccoLimit,
		  t3.BGAlcohol AS 												AlcoholLimit,
		  t3.BGVehiclesInStock + t3.BGWatercraftOver8m AS 				StockVehiclesWatercraftLimit,
  t3.BGCustomersVehicles AS 									CustomerVehiclesWatercraftLimit,
          
/*optional protections*/
          t3.BGTheftProtection AS 										TheftLimit, 							
		  t3.BGEmpTheft, /*PURE Field for testing only*/
		  CASE 
               WHEN t3.BGEmpTheft = 1 THEN 10000
               WHEN t3.BGEmpTheft = 2 THEN 25000
			   WHEN t3.BGEmpTheft = 3 THEN 50000
          END AS 														EmployeeTheftLimit,
		  
/*excesses*/
		  t3.BGVoluntary, /*PURE Field for testing only*/
          CASE 
               WHEN t3.BGVoluntary IS NULL THEN NULL
			   WHEN t3.BGVoluntary = 0 THEN 0
               WHEN t3.BGVoluntary <= 250 THEN 250
			   WHEN t3.BGVoluntary <= 500 THEN 500
               WHEN t3.BGVoluntary <= 1000 THEN 1000
			   ELSE 1000
          END AS 														VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_burglary t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where t4.RLBurglary = 1;

   


-- ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.BGAdj_01 AS
--    SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--    		  CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS  																RecurringIndicator,      
--           t5.UWADJUSTNOTE AS 												UnderwritingDescription,
-- 		  t5.UWADJUSTAMOUNT AS AJAdjustmentValue, /*PURE Field for testing only*/	
-- 		  t4.AJAdjustmentPercent, /*PURE Field for testing only*/	
-- 		  CASE 
-- 		       WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
-- 			   ELSE ''''
--           END AS                                                 				AdjustmentSelection,
-- 		  CASE 
--                WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS 																AdjustmentDollarAndPercent
--      FROM BG_01 t2
--      LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsbg t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--      LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--      WHERE t4.AJRecurringIndicator = 1;
    


-- ;CREATE OR REPLACE TRANSIENT  TABLE BGAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- BURGLARY_IND,
-- COVERAGE,
-- CONTENTSSTOCKEMPLOYEETOOLSLIMIT,
-- PERSONALEFFECTSLIMIT,
-- MOTORFUELSLIMIT,
-- TOBACCOLIMIT,
-- ALCOHOLLIMIT,
-- STOCKVEHICLESWATERCRAFTLIMIT,
-- CUSTOMERVEHICLESWATERCRAFTLIMIT,
-- THEFTLIMIT,
-- BGEmpTheft,
-- EMPLOYEETHEFTLIMIT,
-- BGVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--   CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentPercent END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM BGAdj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- BURGLARY_IND,
-- COVERAGE,
-- CONTENTSSTOCKEMPLOYEETOOLSLIMIT,
-- PERSONALEFFECTSLIMIT,
-- MOTORFUELSLIMIT,
-- TOBACCOLIMIT,
-- ALCOHOLLIMIT,
-- STOCKVEHICLESWATERCRAFTLIMIT,
-- CUSTOMERVEHICLESWATERCRAFTLIMIT,
-- THEFTLIMIT,
-- BGEmpTheft,
-- EMPLOYEETHEFTLIMIT,
-- BGVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentValue END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM BGAdj_01;


    ;CREATE OR REPLACE TRANSIENT  TABLE Location_BG_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.BG_01;
         --          t1.*,
         --         t2.RecurringIndicator,
         --          t2.UnderwritingDescription,
         --          t2.AJAdjustmentValue,
         --          t2.AJAdjustmentPercent,
         --          t2.AdjustmentSelection,
         --          t2.AdjustmentDollarAndPercent
         -- FROM BG_01 t1
         -- LEFT JOIN
         -- (
         --   SELECT * FROM BGAdj_02
         --   WHERE AdjustmentSelection <> ''''
         --   UNION ALL
         --   SELECT * FROM BGAdj_01
         --   WHERE AdjustmentSelection <> ''''
         -- ) t2
         -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
         --   AND t1.ExpiringID_P = t2.ExpiringID_P
         --   AND t1.CMLNumber = t2.CMLNumber
         --   AND t1.ExpiryDate = t2.ExpiryDate
         --   AND t1.Country = t2.Country
         --   AND t1.Product = t2.Product
         --   AND t1.coverage = t2.coverage
         --   ORDER BY PUREPOLICYNUMBER;
		   

------------------------Business Interuption-------------------------------------------------------------------------------------
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.BI_01 AS
   SELECT 
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLBusinessInterruption AS BusinessInterruption_Ind,
          ''BI'' AS Coverage,

/*standard protections*/
          t3.BIGrossProfit AS 											AnnualGrossProfit,
		  t8.description AS BIBenefitPeriod, /*PURE Field for testing only*/		 
          CASE 
               WHEN t8.description = 0 THEN ''''
			   WHEN t8.description = 9 THEN ''9 months''
               WHEN t8.description = 12 THEN ''12 months''
			   WHEN t8.description = 18 THEN ''18 months''
			   WHEN t8.description = 24 THEN ''24 months''
          END AS 														IndemnityPeriod,

/*optional protections*/
         t6.value AS BIClaimsPrepCost, /*PURE Field for testing only*/
		 CASE 
               WHEN t6.value IN (1000,2000,3000,4000,5000,
											6000,7000,8000,9000,10000,
											15000,20000,25000) THEN 25000
               WHEN t6.value IN (30000,50000) THEN 50000
			   WHEN t6.value = 75000 THEN 75000
			   WHEN t6.value = 100000 THEN 100000
			   WHEN t6.value IN (125000,150000) THEN 150000
			   WHEN t6.value = 200000 THEN 200000
			   WHEN t6.value = 250000 THEN 250000
			   WHEN t6.value = 0 THEN 0
          END AS 														ClaimsPreparationCostLimit,
		 t5.value AS BIReceivables, /*PURE Field for testing only*/
		 CASE 
               WHEN t5.value IN (1000,2000,3000,4000,5000,
											6000,7000,8000,9000,10000,
											15000,20000,25000) THEN 25000
               WHEN t5.value IN (30000,50000) THEN 50000
			   WHEN t5.value = 75000 THEN 75000
			   WHEN t5.value = 100000 THEN 100000
			   WHEN t5.value IN (125000,150000) THEN 150000
			   WHEN t5.value = 200000 THEN 200000
			   WHEN t5.value = 250000 THEN 250000
			   WHEN t5.value = 0 THEN 0
          END AS 														AccountsReceivableLimit,
		 t7.value AS BICostofWorking, /*PURE Field for testing only*/
		 CASE 
               WHEN t7.value IN (1000,2000,3000,4000,5000,
											6000,7000,8000,9000,10000,
											15000,20000,25000) THEN 25000
               WHEN t7.value IN (30000,50000) THEN 50000
			   WHEN t7.value = 75000 THEN 75000
			   WHEN t7.value = 100000 THEN 100000
			   WHEN t7.value IN (125000,150000) THEN 150000
			   WHEN t7.value = 200000 THEN 200000
			   WHEN t7.value = 250000 THEN 250000
			   WHEN t7.value = 0 THEN 0
          END AS 														AdditionalCostOfWorkingLimit/*AdditionalIncreasedCostOfWorkingLimit*/,

		  
/*excesses*/
		   COALESCE(t3.BIVoluntary , NULL, '''') AS BIVoluntary, /*PURE Field for testing only*/
          CASE
               WHEN (COALESCE(t3.BIVoluntary , NULL, '''') = '''' AND t3.BIGrossProfit > 0) THEN ''N/A''
			   WHEN COALESCE(t3.BIVoluntary , NULL, '''') = '''' THEN ''''
			   WHEN t3.BIVoluntary = 0 THEN ''N/A''
			   ELSE ''5 days''
          END AS 														VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_businessinterruption t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_biumr002 AS t5 ON t5.UDL_BIUMR002_id = t3.BIReceivables
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_biumr003 AS t6 ON t6.UDL_BIUMR003_id = t3.BIClaimsPrepCost
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_biumr004 AS t7 ON t7.UDL_BIUMR004_id = t3.BICostofWorking
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_biumr001 AS t8 ON t8.UDL_BIUMR001_id = t3.BIBenefitPeriod
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	 t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where t4.RLBusinessInterruption = 1;


-- ;CREATE OR REPLACE TRANSIENT  TABLE BIAdj_01  AS
--    SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--    		  CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS  																RecurringIndicator,      
--           t5.UWADJUSTNOTE AS 												UnderwritingDescription,
-- 		  t5.UWADJUSTAMOUNT AS AJAdjustmentValue, /*PURE Field for testing only*/	
-- 		  t4.AJAdjustmentPercent, /*PURE Field for testing only*/	
-- 		  CASE 
-- 		       WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
-- 			   ELSE ''''
--           END AS                                                 				AdjustmentSelection,
-- 		  CASE 
--                WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS 																AdjustmentDollarAndPercent
--      FROM bi_01 t2
--      LEFT JOIN  PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsbi t4 ON (t2.ExpiringID_P = t4.CBP_Policy_Binder_id)
--      LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
--      WHERE t4.AJRecurringIndicator = 1;
   


-- ;CREATE OR REPLACE TRANSIENT  TABLE BIAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- BUSINESSINTERRUPTION_IND,
-- Coverage,
-- ANNUALGROSSPROFIT,
-- BIBenefitPeriod,
-- INDEMNITYPERIOD,
-- BICLAIMSPREPCOST,
-- CLAIMSPREPARATIONCOSTLIMIT,
-- BIRECEIVABLES,
-- ACCOUNTSRECEIVABLELIMIT,
-- BICOSTOFWORKING,
-- ADDITIONALCOSTOFWORKINGLIMIT,
-- BIVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--  CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentPercent END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM biadj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- BUSINESSINTERRUPTION_IND,
-- Coverage,
-- ANNUALGROSSPROFIT,
-- BIBenefitPeriod,
-- INDEMNITYPERIOD,
-- BICLAIMSPREPCOST,
-- CLAIMSPREPARATIONCOSTLIMIT,
-- BIRECEIVABLES,
-- ACCOUNTSRECEIVABLELIMIT,
-- BICOSTOFWORKING,
-- ADDITIONALCOSTOFWORKINGLIMIT,
-- BIVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentValue END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM biadj_01;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Location_BI_Coverage AS
SELECT DISTINCT * FROM AGGNE.DEV.BI_01;
         --          t1.*,
         --          t2.RecurringIndicator,
         --          t2.UnderwritingDescription,
         --          t2.AJAdjustmentValue,
         --          t2.AJAdjustmentPercent,
         --          t2.AdjustmentSelection,
         --          t2.AdjustmentDollarAndPercent
         -- FROM bi_01 t1
         -- LEFT JOIN
         -- (
         --   SELECT * FROM biadj_02
         --   WHERE AdjustmentSelection <> ''''
         --   UNION ALL
         --   SELECT * FROM biadj_01
         --   WHERE AdjustmentSelection <> ''''
         -- ) t2
         -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
         --   AND t1.ExpiringID_P = t2.ExpiringID_P
         --   AND t1.CMLNumber = t2.CMLNumber
         --   AND t1.ExpiryDate = t2.ExpiryDate
         --   AND t1.Country = t2.Country
         --   AND t1.Product = t2.Product
         --   AND t1.coverage = t2.coverage
         --   ORDER BY PUREPOLICYNUMBER;
		   

------------------------------Engineering---------------------------------------------------------------------------------------------------------------
;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.EN_01 AS
   SELECT 
		  t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLEngineering AS Engineering_Ind,
          
          ''EN'' AS Coverage,

/*standard protections*/
          t3.ENMachineryValue + t3.ENElectronicEquipValue AS 			ENMachineryECEvalue, /*PURE Field for testing only*/
		  CASE 
               WHEN t3.ENMachineryValue + t3.ENElectronicEquipValue IS NULL THEN NULL
			   WHEN t3.ENMachineryValue + t3.ENElectronicEquipValue = 0 THEN NULL
               WHEN t3.ENMachineryValue + t3.ENElectronicEquipValue <= 10000 THEN 10000
			   WHEN t3.ENMachineryValue + t3.ENElectronicEquipValue <= 25000 THEN 25000
			   WHEN t3.ENMachineryValue + t3.ENElectronicEquipValue <= 50000 THEN 50000
			   WHEN t3.ENMachineryValue + t3.ENElectronicEquipValue <= 75000 THEN 75000
			   WHEN t3.ENMachineryValue + t3.ENElectronicEquipValue <= 100000 THEN 100000
			   WHEN t3.ENMachineryValue + t3.ENElectronicEquipValue <= 150000 THEN 150000
			   ELSE 150000
          END AS 														MachineryElectronicEquip/*MachineryElectronicEquipmentLimit*/,
		  t3.ENCarWashValue, /*PURE Field for testing only*/ 
		  CASE 
               WHEN t3.ENCarWashValue IS NULL THEN NULL
			   WHEN t3.ENCarWashValue = 0 THEN 0
               WHEN t3.ENCarWashValue <= 20000 THEN 20000
			   WHEN t3.ENCarWashValue <= 50000 THEN 50000
			   WHEN t3.ENCarWashValue <= 100000 THEN 100000
			   ELSE 100000
          END AS 														CarWashLimit,
		  t3.ENCWEquipmentMaintenance, /*PURE Field for testing only*/								
		  CASE 
               WHEN t3.ENCWEquipmentMaintenance IS NULL THEN ''''
			   WHEN t3.ENCWEquipmentMaintenance = 0 THEN ''No''
               WHEN t3.ENCWEquipmentMaintenance = 1  THEN ''Yes''
          END AS			EquipmentRegularlyMaintained/*EquipmentRegularlyMaintainedAndMaintenanceRecordskept*/,
          CASE 
               WHEN t3.ENEquipmentAge IS NULL THEN 0
			   ELSE t3.ENEquipmentAge
          END AS	AverageAgeOfEquipment,	
          CASE 
               WHEN t3.ENAgeOldestEquipment IS NULL THEN 0
			   ELSE t3.ENAgeOldestEquipment
          END AS	AgeOfTheOldest/*AgeOfTheOldestPieceOfEquipmentWorthMorethan5000*/,

/*optional protections*/
         t5.value AS ENStockDeterioration, /*PURE Field for testing only*/
		 CASE 
               WHEN t5.value IN (1000,2000,3000,4000,5000,
											6000,7000,8000,9000,10000) THEN 10000
               WHEN t5.value IN (15000, 20000, 25000) THEN 25000
			   WHEN t5.value IN (30000,50000,75000,
										    100000,125000,150000) THEN 50000
			   WHEN t5.value = 0 THEN 0
          END AS 														DeteriorationofStockLimit,
		 t6.value AS ENLossInfo, /*PURE Field for testing only*/
		 CASE 
               WHEN t6.value = 10000 THEN 10000
			   WHEN t6.value = 15000 THEN 25000
			   WHEN t6.value = 20000 THEN 25000
			   WHEN t6.value = 0 THEN 0
          END AS 														LossOfInformationLimit,
		 t7.value AS ENIncreaseCost, /*PURE Field for testing only*/
		 CASE 
               WHEN t7.value = 10000 THEN 10000
			   WHEN t7.value = 15000 THEN 25000
			   WHEN t7.value = 20000 THEN 25000
			   WHEN t7.value = 0 THEN 0
          END AS 														IncreasedCostofWorkingLimit,
		  
/*excesses*/
		  t3.ENVoluntary, /*PURE Field for testing only*/
          CASE 
               WHEN t3.ENVoluntary IS NULL THEN NULL
			   WHEN t3.ENVoluntary = 0 THEN 0
			   WHEN t3.ENVoluntary <= 250 THEN 250
			   WHEN t3.ENVoluntary <= 500 THEN 500
			   WHEN t3.ENVoluntary <= 1000 THEN 1000
			   ELSE 1000
          END AS 														VoluntaryExcess
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_engineering t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_enumr004 AS t5 ON t5.UDL_ENUMR004_id = t3.ENStockDeterioration
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_enumr005 AS t6 ON t6.UDL_ENUMR005_id = t3.ENLossInfo
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.udl_enumr006 AS t7 ON t7.UDL_ENUMR006_id = t3.ENIncreaseCost
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	 t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where t4.RLEngineering = 1;
    

-- ;CREATE OR REPLACE TRANSIENT  TABLE ENAdj_01 AS
-- SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--    		  CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS  																RecurringIndicator,      
--           t5.UWADJUSTNOTE AS 												UnderwritingDescription,
-- 		  t5.UWADJUSTAMOUNT AS AJAdjustmentValue, /*PURE Field for testing only*/	
-- 		  t4.AJAdjustmentPercent, /*PURE Field for testing only*/	
-- 		  CASE 
-- 		       WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
-- 			   ELSE ''''
--           END AS                                                 				AdjustmentSelection,
-- 		  CASE 
--                WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS 																AdjustmentDollarAndPercent
-- FROM      en_01 t2
-- LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsen t4
-- ON        (
--                     t2.expiringid_p = t4.CBP_Policy_Binder_id)
-- LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
-- WHERE t4.AJRecurringIndicator = 1;


-- ;CREATE OR REPLACE TRANSIENT  TABLE ENAdj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- ENGINEERING_IND,
-- COVERAGE,
-- ENMACHINERYECEVALUE,
-- MACHINERYELECTRONICEQUIP,
-- ENCarWashValue,
-- CARWASHLIMIT,
-- ENCWEquipmentMaintenance,
-- EQUIPMENTREGULARLYMAINTAINED,
-- AVERAGEAGEOFEQUIPMENT,
-- AGEOFTHEOLDEST,
-- ENStockDeterioration,
-- DETERIORATIONOFSTOCKLIMIT,
-- ENLOSSINFO,
-- LOSSOFINFORMATIONLIMIT,
-- ENINCREASECOST,
-- INCREASEDCOSTOFWORKINGLIMIT,
-- ENVoluntary,
-- VOLUNTARYEXCESS,
-- RecurringIndicator,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentPercent END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM enadj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- ENGINEERING_IND,
-- COVERAGE,
-- ENMACHINERYECEVALUE,
-- MACHINERYELECTRONICEQUIP,
-- ENCarWashValue,
-- CARWASHLIMIT,
-- ENCWEquipmentMaintenance,
-- EQUIPMENTREGULARLYMAINTAINED,
-- AVERAGEAGEOFEQUIPMENT,
-- AGEOFTHEOLDEST,
-- ENStockDeterioration,
-- DETERIORATIONOFSTOCKLIMIT,
-- ENLOSSINFO,
-- LOSSOFINFORMATIONLIMIT,
-- ENINCREASECOST,
-- INCREASEDCOSTOFWORKINGLIMIT,
-- ENVoluntary,
-- VOLUNTARYEXCESS,
-- RecurringIndicator,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentValue END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM enadj_01


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Location_EN_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.EN_01;
         --          t1.*,
         --          t2.RecurringIndicator,
         --          t2.UnderwritingDescription,
         --          t2.AJAdjustmentValue,
         --          t2.AJAdjustmentPercent,
         --          t2.AdjustmentSelection,
         --          t2.AdjustmentDollarAndPercent
         -- FROM EN_01 t1
         -- LEFT JOIN
         -- (
         --   SELECT * FROM ENAdj_02
         --   WHERE AdjustmentSelection <> ''''
         --   UNION ALL
         --   SELECT * FROM ENAdj_01
         --   WHERE AdjustmentSelection <> ''''
         -- ) t2
         -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
         --   AND t1.ExpiringID_P = t2.ExpiringID_P
         --   AND t1.CMLNumber = t2.CMLNumber
         --   AND t1.ExpiryDate = t2.ExpiryDate
         --   AND t1.Country = t2.Country
         --   AND t1.Product = t2.Product
         --   AND t1.coverage = t2.coverage
         --   ORDER BY PUREPOLICYNUMBER;
		   
		

-------------------------------Location_Money_Coverage--------------------------------------------------

;CREATE OR REPLACE TRANSIENT  TABLE AGGNE.DEV.MY_01 AS
   SELECT t2.PUREPolicyNumber,
		  t2.ExpiringID_P,
		  t2.CMLNumber,
		  t2.ExpiryDate,
		  t2.Country,
          t2.Product,
          t4.RLMoney AS Money_Ind,
          ''MY'' AS Coverage,

/*standard protections*/
		  t3.MYDuringBusHours, /*PURE Field for testing only*/	
		  CASE 
			   WHEN t3.MYDuringBusHours IS NULL OR t3.MYDuringBusHours = 0 THEN NULL
			   WHEN t3.MYDuringBusHours <= 2000 THEN 2000
               WHEN t3.MYDuringBusHours <= 5000 THEN 5000
			   WHEN t3.MYDuringBusHours <= 10000 THEN 10000
               WHEN t3.MYDuringBusHours <= 20000 THEN 20000
			   ELSE 20000
          END AS                                                   	MoneyDuringBusinessHours /*MoneyOnThePremisesDuringBusinessHoursLimit*/,
		  t3.MYOutsideBusHours, /*PURE Field for testing only*/	
		  CASE 
			   WHEN t3.MYOutsideBusHours IS NULL OR t3.MYOutsideBusHours = 0 THEN 0 
			   WHEN t3.MYOutsideBusHours <= 2000 THEN 2000
               WHEN t3.MYOutsideBusHours <= 5000 THEN 5000
			   ELSE 5000
          END AS                                                   	MoneyOutsideBusinessHours /*MoneyOnThePremisesOutsideBusinessHoursLimit*/,
          t3.MYOutsideBusLocation, /*PURE Field for testing only*/	
		  CASE 
               WHEN t3.MYOutsideBusLocation = '''' THEN ''''
               WHEN upper(t3.MYOutsideBusLocation) LIKE ''%TIL%'' THEN ''Locked Til''
			   WHEN upper(t3.MYOutsideBusLocation) LIKE ''%SAFE%'' 
    			OR upper(t3.MYOutsideBusLocation) LIKE ''%LOCKED DRAWER%'' 
    			OR upper(t3.MYOutsideBusLocation) LIKE ''%LOCKED%'' THEN ''Locked Safe'' 
			   ELSE ''Other''
          END AS                                                   	LocationOutsideBusinessHours /*LocationOMoneyOutsideBusinessHours*/,
		  t3.MYLockedSafe, /*PURE Field for testing only*/	
		  CASE 
			   WHEN t3.MYLockedSafe IS NULL OR t3.MYLockedSafe = 0 THEN 0 
			   WHEN t3.MYLockedSafe <= 2000 THEN 2000
               WHEN t3.MYLockedSafe <= 5000 THEN 5000
			   WHEN t3.MYLockedSafe <= 10000 THEN 10000
               WHEN t3.MYLockedSafe <= 20000 THEN 20000
			   ELSE 20000
          END AS                                                    MoneyInALockedSafe /*MoneyInALockedSafeOrStrongRoomLimit*/,
		  t3.MYOutsideBusHoursPrivate, /*PURE Field for testing only*/	
		    CASE 
			   WHEN t3.MYOutsideBusHoursPrivate IS NULL OR t3.MYOutsideBusHoursPrivate = 0 THEN 0 
			   WHEN t3.MYOutsideBusHoursPrivate <= 2000 THEN 2000
               WHEN t3.MYOutsideBusHoursPrivate <= 5000 THEN 5000
			   ELSE 5000
          END AS                                                    MoneyAtPrivateResidenceLimit , 
		  CASE 
               WHEN t3.MYLockedSafe > 0 THEN ''Yes''
               ELSE ''No''
          END AS                                                   	IsMoneyStoredInALockedSafe,	
 		  t3.MYInTransit, /*PURE Field for testing only*/	
		   CASE 
			   WHEN t3.MYInTransit IS NULL OR t3.MYInTransit = 0 THEN 0 
			   WHEN t3.MYInTransit <= 2000 THEN 2000
               WHEN t3.MYInTransit <= 5000 THEN 5000
			   WHEN t3.MYInTransit <= 10000 THEN 10000
               WHEN t3.MYInTransit <= 20000 THEN 20000
			   ELSE 20000
          END AS                                                    MoneyInTransitLimit , 

/*optional protections*/
		  t3.MYEmployeeDishonesty, /*PURE Field for testing only*/	
		  CASE 
			   WHEN t3.MYEmployeeDishonesty IS NULL OR t3.MYEmployeeDishonesty = 0 THEN 0
			   WHEN t3.MYEmployeeDishonesty = 1 THEN 2500
               WHEN t3.MYEmployeeDishonesty = 2 THEN 5000
			   WHEN t3.MYEmployeeDishonesty = 3 THEN 10000
          END AS                                                   EmployeeDishonestyLimit ,

/*excesses*/
		  t3.MYVoluntary, /*PURE Field for testing only*/	
          CASE 
			   WHEN t3.MYVoluntary IS NULL THEN NULL
			   WHEN t3.MYVoluntary = 0 THEN 0
               WHEN t3.MYVoluntary <= 250 THEN 250
			   WHEN t3.MYVoluntary <= 500 THEN 500
               WHEN t3.MYVoluntary <= 1000 THEN 1000
			   ELSE 1000
          END AS                                                VoluntaryExcess        
	FROM Sample_CBP t2
	LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_money t3 ON (t2.ExpiringID_P = t3.CBP_Policy_Binder_id)
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection 	t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
    where t4.RLMoney = 1;



-- ;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.MYAdj_01 AS
-- SELECT t2.*,
   
-- /*Underwriting Adjustments Details*/
--    		  CASE 
--                WHEN t4.AJRecurringIndicator = 1 THEN ''Yes''
--                ELSE ''No''
--           END AS  																RecurringIndicator,      
--           t5.UWADJUSTNOTE AS 												UnderwritingDescription,
-- 		  t5.UWADJUSTAMOUNT AS AJAdjustmentValue, /*PURE Field for testing only*/	
-- 		  t4.AJAdjustmentPercent, /*PURE Field for testing only*/	
-- 		  CASE 
-- 		       WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN ''%''
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN ''%''
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN ''$''
-- 			   ELSE ''''
--           END AS                                                 				AdjustmentSelection,
-- 		  CASE 
--                WHEN t5.UWADJUSTAMOUNT = 0  AND t4.AJAdjustmentPercent = 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN (t5.UWADJUSTAMOUNT IS NULL OR t5.UWADJUSTAMOUNT = 0) AND t4.AJAdjustmentPercent <> 0 THEN t4.AJAdjustmentPercent
-- 			   WHEN t5.UWADJUSTAMOUNT <> 0  AND (t4.AJAdjustmentPercent IS NULL OR t4.AJAdjustmentPercent = 0) THEN t5.UWADJUSTAMOUNT
--                ELSE NULL
--           END AS 																AdjustmentDollarAndPercent
-- FROM      my_01 t2
-- LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentsmy t4
-- ON        (
--                     t2.expiringid_p = t4.CBP_Policy_Binder_id)
-- LEFT JOIN aggne.dev.OUTPUT_UWADJUST_BSP_POLICYATTACH t5 ON  TRIM(t2.ExpiringID_P) = TRIM(t5.ExpiringID_P) AND TRIM(t2.coverage) = TRIM(t5.coverage)
-- WHERE t4.AJRecurringIndicator = 1;


-- ;CREATE OR REPLACE TRANSIENT  TABLE myadj_02 AS
-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- MONEY_IND,
-- COVERAGE,
-- MYDuringBusHours,
-- MONEYDURINGBUSINESSHOURS,
-- MYOutsideBusHours,
-- MONEYOUTSIDEBUSINESSHOURS,
-- MYOutsideBusLocation,
-- LOCATIONOUTSIDEBUSINESSHOURS,
-- MYLockedSafe,
-- MONEYINALOCKEDSAFE,
-- MYOutsideBusHoursPrivate,
-- MONEYATPRIVATERESIDENCELIMIT,
-- ISMONEYSTOREDINALOCKEDSAFE,
-- MYInTransit,
-- MONEYINTRANSITLIMIT,
-- MYEmployeeDishonesty,
-- EMPLOYEEDISHONESTYLIMIT,
-- MYVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
--  CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''%''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentPercent END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM myadj_01

-- UNION ALL

-- SELECT
-- PUREPOLICYNUMBER,
-- EXPIRINGID_P,
-- CMLNUMBER,
-- EXPIRYDATE,
-- COUNTRY,
-- PRODUCT,
-- MONEY_IND,
-- COVERAGE,
-- MYDuringBusHours,
-- MONEYDURINGBUSINESSHOURS,
-- MYOutsideBusHours,
-- MONEYOUTSIDEBUSINESSHOURS,
-- MYOutsideBusLocation,
-- LOCATIONOUTSIDEBUSINESSHOURS,
-- MYLockedSafe,
-- MONEYINALOCKEDSAFE,
-- MYOutsideBusHoursPrivate,
-- MONEYATPRIVATERESIDENCELIMIT,
-- ISMONEYSTOREDINALOCKEDSAFE,
-- MYInTransit,
-- MONEYINTRANSITLIMIT,
-- MYEmployeeDishonesty,
-- EMPLOYEEDISHONESTYLIMIT,
-- MYVoluntary,
-- VOLUNTARYEXCESS,
-- RECURRINGINDICATOR,
-- UNDERWRITINGDESCRIPTION,
-- AJAdjustmentValue,
-- AJAdjustmentPercent,
-- CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN ''$''
-- 	END AS ADJUSTMENTSELECTION ,
--     CASE 
--         WHEN ((AJAdjustmentValue IS NOT NULL AND AJAdjustmentValue <> 0)) AND ((AJAdjustmentPercent IS NOT NULL AND AJAdjustmentPercent <> 0)) THEN
--     AJAdjustmentValue END AS ADJUSTMENTDOLLARANDPERCENT 
-- FROM myadj_01


   ;CREATE OR REPLACE TRANSIENT  TABLE Location_Money_Coverage AS
         SELECT DISTINCT * FROM AGGNE.DEV.MY_01;
         --          t1.*,
         --          t2.RecurringIndicator,
         --          t2.UnderwritingDescription,
         --          t2.AJAdjustmentValue,
         --          t2.AJAdjustmentPercent,
         --          t2.AdjustmentSelection,
         --          t2.AdjustmentDollarAndPercent
         -- FROM my_01 t1
         -- LEFT JOIN
         -- (
         --   SELECT * FROM MYAdj_02
         --   WHERE AdjustmentSelection <> ''''
         --   UNION ALL
         --   SELECT * FROM MYAdj_01
         --   WHERE AdjustmentSelection <> ''''
         -- ) t2
         -- ON t1.PUREPolicyNumber = t2.PUREPolicyNumber
         --   AND t1.ExpiringID_P = t2.ExpiringID_P
         --   AND t1.CMLNumber = t2.CMLNumber
         --   AND t1.ExpiryDate = t2.ExpiryDate
         --   AND t1.Country = t2.Country
         --   AND t1.Product = t2.Product
         --   AND t1.coverage = t2.coverage
         --   ORDER BY PUREPOLICYNUMBER;
		   
	
	--------------------------------------------------1.7@@LineCoverages@@end@@---------------------------------------------------------------------------------------------------
	
	--------------------------------------------------1.8@@Privatevehicle@@start@@-------------------------------------------------------------------------------------------------
	;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.Sample_PrivateMotor_PER AS
SELECT DISTINCT 
     t3.insurance_ref AS PUREPolicyNumber
	,t18.PER_Policy_Binder_id AS ExpiringID_P
	,t3.insurance_file_cnt
	,CAST(t3.expiry_date AS DATE) AS ExpiryDate
	,t14.shortname AS CMLNumber
	,t13.description AS Country
	,t19.code  AS Product
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t1
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Folder t0 ON t1.risk_folder_cnt = t0.risk_folder_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t3 ON t2.insurance_file_cnt = t3.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t6 ON t3.insured_cnt = t6.party_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_Policy_Binder t7 ON t6.gis_policy_link_id = t7.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_MEMBERCSL t9 ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Party t14 ON t3.insured_cnt = t14.party_cnt
LEFT JOIN aggne.dev.clientcontacts     t10 ON t6.party_cnt = T10.ClientID
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Source t13 ON t3.source_id = t13.source_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Status t15 ON t1.risk_status_id = t15.risk_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t17 ON t1.risk_cnt = t17.risk_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Product t19 ON (t3.product_id = t19.product_id)
WHERE 
    --CAST(t3.expiry_date AS DATE) = current_date() + 45
	 SUBSTR(t3.insurance_ref, 1, 1) = ''P''
	AND t3.insurance_file_type_id <> 3 /* (3=Policy under Renewal) */
	AND COALESCE(t3.insurance_file_status_id,NULL,0) NOT IN (1, 2) /* (1=Cancelled, 2=Lapsed) */
	AND t15.risk_status_id IN (
		1
		,3
		) /* (1=Referred, 3=Quoted) */
   AND t2.status_flag <> ''D''
	AND t3.insurance_ref NOT IN (
		SELECT DISTINCT t13.insurance_ref
		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t11
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
		INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
		WHERE CAST(t13.expiry_date AS DATE) > current_date()
			AND t13.insurance_file_type_id = 8 /* (8 = MTA Cancelled) */
		)
	AND (
		/* Case 1: Only one insurance_file_cnt for the policy */
		(
			SELECT COUNT(DISTINCT ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
			WHERE ins.insurance_ref = t3.insurance_ref
			) = 1
		OR
		/* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
		t3.insurance_file_cnt = (
			SELECT MAX(ins.insurance_file_cnt)
			FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
			LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status STATUS ON ins.insurance_file_status_id = STATUS.insurance_file_status_id
			WHERE ins.insurance_ref = t3.insurance_ref
				AND (STATUS.insurance_file_status_id <> 1 OR STATUS.insurance_file_status_id IS NULL) /* (1=Cancelled) */
			)
		)
ORDER BY ExpiryDate ,PUREPolicyNumber;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PM_01 AS
SELECT 
    t2.PUREPolicyNumber
	,t2.ExpiringID_P
    ,t2.insurance_file_cnt
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,t2.Product
	,CASE 
		WHEN TRIM(t2.Country) = ''New Zealand''
			THEN ''NZ''
		ELSE t4.RLState
		END AS STATE
	,t4.RLMotorVehicles AS MotorVehicles_Ind
	-- Vehicle information
	,t3.PER_VEHICLEDETAIL_id AS VehicleID
	,t3.MVCVRegNo AS RegistrationNumber
	,t3.MVRBVehicleKey
	,t3.MVRBGrossVehMass
	,t3.MVRBEngineSize
	,t3.MVRBEngineSizeOV AS EngineSize
	,TO_NUMBER(REPLACE(t3.MVRBGrossVehMassOV, '','', '''')) AS GrossVehicleMass
	,t3.MVCVTypeVeh
	,CASE 
		WHEN t3.MVCVTypeVeh = 1
			THEN ''Passenger Vehicle''
		WHEN t3.MVCVTypeVeh = 2
			THEN ''Caravan''
		WHEN t3.MVCVTypeVeh = 3
			THEN ''Camper Van''
		WHEN t3.MVCVTypeVeh = 4
			THEN ''Motorcycle''
		WHEN t3.MVCVTypeVeh = 5
			THEN ''Trailer''
		WHEN t3.MVCVTypeVeh = 10
			THEN CASE 
					WHEN (
							t3.MVRBEngineSize >= 11000
							OR t3.MVRBEngineSizeOV >= 11000
							)
						THEN ''Heavy Commercial''
					WHEN (
							(
								t3.MVRBEngineSize < 11000
								AND t3.MVRBGrossVehMass >= 11000
								)
							OR (
								t3.MVRBEngineSizeOV < 11000
								AND TO_NUMBER(REPLACE(t3.MVRBGrossVehMassOV, '','', '''')) >= 11000
								)
							)
						THEN ''Heavy Commercial''
					WHEN (
							(
								t3.MVRBEngineSize < 11000
								AND t3.MVRBGrossVehMass < 11000
								)
							OR (
								t3.MVRBEngineSizeOV < 11000
								AND TO_NUMBER(REPLACE(t3.MVRBGrossVehMassOV, '','', '''')) < 11000
								)
							)
						THEN ''Light Commercial''
					ELSE ''''
					END
		WHEN t3.MVCVTypeVeh IN (
				6
				,7
				)
			THEN ''Heavy Commercial''
		WHEN t3.MVCVTypeVeh = 8
			THEN ''Forklift''
		WHEN t3.MVCVTypeVeh = 9
			THEN CASE 
					WHEN UPPER(t3.MVCVMake) = ''FORKLIFT''
						OR UPPER(t3.MVCVModel) = ''FORKLIFT''
						THEN ''Forklift''
					WHEN UPPER(t3.MVCVMake) = ''1930ES''
						AND UPPER(t3.MVCVModel) = ''SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''2.3 TON DIGGER''
						AND UPPER(t3.MVCVModel) = ''PLANT TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''A1''
						AND UPPER(t3.MVCVModel) = ''CAR TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''AMMANN''
						AND UPPER(t3.MVCVModel) = ''ARX16 ROLLER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''AUSTRAC''
						AND UPPER(t3.MVCVModel) = ''MINI DIGGER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''BARTCO''
						AND UPPER(t3.MVCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) IN (
							''BOA''
							,''BOAPOD''
							,''BOA POD''
							,''BOAPOD HYDRAULIC''
							,''BOA HUB''
							,''BOA POD HYDRAULIC HOSE''
							)
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''BOBCAT''
						AND UPPER(t3.MVCVModel) = ''753''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''BOBCAT''
						AND UPPER(t3.MVCVModel) = ''S185 SKIDSTEER LOADER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''BOX TRAILER WITH BUILDERS'''' RACKS AND GAS CYLINDER MOUNTS''
						AND UPPER(t3.MVCVModel) = ''TANDEM AXLE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''BRUNO CHARIOT''
						AND UPPER(t3.MVCVModel) = ''CHARIO DLT''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''BUGGY''
						AND UPPER(t3.MVCVModel) = ''OFF ROAD''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''BX23SLB-AU EXCAVATOR''
						AND UPPER(t3.MVCVModel) = ''BX23SLB-AU EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) IN (
							''CAN-AM''
							,''CANNEM''
							,''CAN AM''
							,''CAM AM''
							)
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''CASE''
						AND UPPER(t3.MVCVModel) = ''IH S88K BACKHOE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''CATERPILALR''
						AND UPPER(t3.MVCVModel) = ''SKID STEER LOADER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''CATERPILLAR''
						AND UPPER(t3.MVCVModel) = ''EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''CATERPILLER FRONT END LOADER''
						AND UPPER(t3.MVCVModel) = ''MODEL 906''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''CF''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''CF MOTO''
						AND UPPER(t3.MVCVModel) = ''CFORCE1000''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''COASTMAC''
						AND UPPER(t3.MVCVModel) = ''EXCAVATOR TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''CUSTOM''
						AND UPPER(t3.MVCVModel) = ''GO KART''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''CUSTOM''
						AND UPPER(t3.MVCVModel) = ''HYDRAULIC HOSE TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''CUSTOM ALUMINIUM TRAILER WITH COMPRESSOR''
						AND UPPER(t3.MVCVModel) = ''TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''CUSTOM ALUMINIUM TRAILER WITH MOUNTED COMPRESSOR TRAILER''
						AND UPPER(t3.MVCVModel) = ''COMPRESSOR TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''CUSTOM BUILT TRAILER''
						AND UPPER(t3.MVCVModel) = ''WITH AC TESTING UNIT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''CUSTOM GO KART''
						AND UPPER(t3.MVCVModel) = ''ARROW X6.2''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''DINGO''
						AND UPPER(t3.MVCVModel) = ''35DT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''DJ CUSTOM FAB''
						AND UPPER(t3.MVCVModel) = ''CRANE TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''EAGLE''
						AND UPPER(t3.MVCVModel) = ''GOLF CART''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''ESCAVATOR''
						AND UPPER(t3.MVCVModel) = ''KOBELCO SK17SR''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''E-TECH''
						AND UPPER(t3.MVCVModel) = ''PLUS, SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''EXCAVATOR''
						AND UPPER(t3.MVCVModel) = ''KUBOTA U17-3''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''FASSI M30A''
						AND UPPER(t3.MVCVModel) = ''CRANE''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''FFE TRAILER''
						AND UPPER(t3.MVCVModel) = ''DIG TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''GENIE''
						AND UPPER(t3.MVCVModel) = ''G-3246 SCISSOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''HANDYMAX''
						AND UPPER(t3.MVCVModel) = ''WHEEL LOADER HM22''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''HAULOTTE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''HAVLOTTE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''HBH LINMAC''
						AND UPPER(t3.MVCVModel) = ''CRANE''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''HIGHWAY''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''HIGHWAY1''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''HITACHI''
						AND UPPER(t3.MVCVModel) = ''EX22 DIGGER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''HOME MADE''
						AND UPPER(t3.MVCVModel) = ''BOX TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''HOMEBUILT TRAILER''
						AND UPPER(t3.MVCVModel) = ''VMS''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''HUSKI''
						AND UPPER(t3.MVCVModel) = ''M16U EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''HUSQVARNA''
						AND UPPER(t3.MVCVModel) = ''FC250''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''HYDRAULIC EXCAVATOR''
						AND UPPER(t3.MVCVModel) = ''CATERPILLAR 301.5-05''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''INDUSTRIAL''
						AND UPPER(t3.MVCVModel) = ''TOILET''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''INTER''
						AND UPPER(t3.MVCVModel) = ''MOBILE CRANE''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''ISUZU''
						AND UPPER(t3.MVCVModel) = ''N SERIES''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''IVECO''
						AND UPPER(t3.MVCVModel) = ''EURO CARGO 18T GVM TILT TRAY WITH WHEEL LIFT & HIAB''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''JCB''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''JOHN DEERE''
						AND UPPER(t3.MVCVModel) = ''BOBCAT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''KANGA''
						AND UPPER(t3.MVCVModel) = ''MINI LOADER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''KANGA''
						AND UPPER(t3.MVCVModel) = ''PW628''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''KAWASAKI''
						AND UPPER(t3.MVCVModel) = ''KAF400''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''KITCHEN''
						AND UPPER(t3.MVCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''KOBELCO''
						AND UPPER(t3.MVCVModel) = ''45 COUPE EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''KOBELCO''
						AND UPPER(t3.MVCVModel) = ''SK010SRD-7''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''KOBELCO''
						AND UPPER(t3.MVCVModel) = ''SK140 SRD-7''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''KOBELCO''
						AND UPPER(t3.MVCVModel) = ''SK140SRD-7''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''KOBELCO''
						AND UPPER(t3.MVCVModel) = ''SK35SR-6''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''MAZDA''
						AND UPPER(t3.MVCVModel) = ''RX7''
						THEN ''Passenger Vehicle''
					WHEN UPPER(t3.MVCVMake) = ''NEW HOLLAND''
						AND UPPER(t3.MVCVModel) = ''C327''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''NEW HOLLAND''
						AND UPPER(t3.MVCVModel) = ''SKID STEER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''NUSSA AUSTRALIAN PORTABLE TOILET''
						AND UPPER(t3.MVCVModel) = ''TT1''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''OEM''
						AND UPPER(t3.MVCVModel) = ''HOTTIE IV PRESSURE CLEANER TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''POLARIS''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''RHINOCEROS MINI EXCAVATOR''
						AND UPPER(t3.MVCVModel) = ''XN12-8''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''RHINOSAUR''
						AND UPPER(t3.MVCVModel) = ''XN10-2B''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''RIZER''
						AND UPPER(t3.MVCVModel) = ''S03-E, SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''SHERMAC SERVICE TRAILER''
						AND UPPER(t3.MVCVModel) = ''SHERMAC SERVICE TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''SKID STEER LOADER''
						AND UPPER(t3.MVCVModel) = ''S630''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''SKYJACK''
						AND UPPER(t3.MVCVModel) = ''SCISSOR LIFT''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''SKYJACK''
						AND UPPER(t3.MVCVModel) = ''SJ1113219''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''SKYJACK 15FT''
						AND UPPER(t3.MVCVModel) = ''SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''SNORKEL''
						AND UPPER(t3.MVCVModel) = ''S2255RT ROUGH TERRAIN SCISSOR LIFT''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''SNORKEL SCISSOR LIFT''
						AND UPPER(t3.MVCVModel) = ''S3219E''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''SPIT''
						AND UPPER(t3.MVCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''TAKEUCHI''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TCM''
						AND UPPER(t3.MVCVModel) = ''800S''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TEREX TRAILER MOUNT LIGHTING TOWER''
						AND UPPER(t3.MVCVModel) = ''GENIE AL4000''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TORO''
						AND UPPER(t3.MVCVModel) = ''2500 TITAN MOWER''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''TORO''
						AND UPPER(t3.MVCVModel) = ''RIDE ON MOWER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TORO''
						AND UPPER(t3.MVCVModel) = ''TX1000 DINGO''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TOYOTA''
						AND UPPER(t3.MVCVModel) = ''30-5SKD8''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TOYOTA''
						AND UPPER(t3.MVCVModel) = ''FORKLIFT''
						THEN ''Forklift''
					WHEN UPPER(t3.MVCVMake) = ''TRAILER''
						AND UPPER(t3.MVCVModel) = ''HOME BUILT''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''TRAILER''
						AND UPPER(t3.MVCVModel) = ''MESSAGE''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TRAILER''
						AND UPPER(t3.MVCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''TRAILERED ATLAS 65''
						AND UPPER(t3.MVCVModel) = ''COMPRESSOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TRUCK ROLLER BRAKE TESTER''
						AND UPPER(t3.MVCVModel) = ''TRAILER''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''TS TRAILERS''
						AND UPPER(t3.MVCVModel) = ''FLATBED''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''UBCO''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''UHI''
						AND UPPER(t3.MVCVModel) = ''UME18 MINI EXCAVATOR''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''UNIVERSAL MAXTRAY''
						AND UPPER(t3.MVCVModel) = ''TRAILER HOSE BOA''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''VALLKREE''
						AND UPPER(t3.MVCVModel) = ''ELECTRIC PUSH BIKE''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''VAN DEMONS''
						AND UPPER(t3.MVCVModel) = ''PIG TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''VENTECH''
						AND UPPER(t3.MVCVModel) = ''TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''VERMAC''
						AND UPPER(t3.MVCVModel) = ''CUSTOM TRAILER''
						THEN ''Trailer''
					WHEN UPPER(t3.MVCVMake) = ''WACKER NEUSON''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''XCMG''
						THEN ''Light Commercial''
					WHEN UPPER(t3.MVCVMake) = ''YAMAHA''
						THEN ''Motorcycle''
					WHEN UPPER(t3.MVCVMake) = ''YANMAR''
						AND UPPER(t3.MVCVModel) = ''DIGGER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''YANMAR''
						AND UPPER(t3.MVCVModel) = ''V4 LOADER''
						THEN ''Heavy Commercial''
					WHEN UPPER(t3.MVCVMake) = ''YANMAR''
						AND UPPER(t3.MVCVModel) = ''VI020-3 MINI EXCAVATOR''
						THEN ''Light Commercial''
					ELSE ''''
					END
		ELSE ''''
		END AS VehicleType
	,t3.MVCVMake AS Make
	,t3.MVCVModel AS Model
	,t3.MVCVYear AS Year
	,t3.MVCVOverride
	,CASE 
		WHEN t3.MVCVOverride = 1
			THEN ''Yes''
		WHEN t3.MVCVOverride IS NULL
			OR t3.MVCVOverride = 2
			THEN ''''
		ELSE ''''
		END AS Override
	,t3.MVCVDescription
	,t3.MVCVDescriptionOV AS Description
	,t3.MVCVBodyType
	,t3.MVCVBodyTypeOV
	,CASE 
		WHEN t3.MVCVOverride = 1
			THEN CASE 
					WHEN t3.MVCVBodyTypeOV = 1
						THEN ''Sedan''
					WHEN t3.MVCVBodyTypeOV = 2
						THEN ''Coupe''
					WHEN t3.MVCVBodyTypeOV = 3
						THEN ''Wagon''
					WHEN t3.MVCVBodyTypeOV = 4
						THEN ''Hatchback''
					WHEN t3.MVCVBodyTypeOV = 5
						THEN ''Van''
					WHEN t3.MVCVBodyTypeOV = 6
						THEN ''Cab Chassis''
					WHEN t3.MVCVBodyTypeOV = 7
						THEN ''Utility''
					WHEN t3.MVCVBodyTypeOV = 8
						THEN ''Convertible''
					WHEN t3.MVCVBodyTypeOV = 9
						THEN ''Other''
					ELSE ''''
					END
		ELSE ''''
		END AS BodyType
	,t3.MVRBCylinders
	,t3.MVRBCylindersOV
	,CASE 
		WHEN t3.MVCVOverride = 1
			THEN CASE 
					WHEN t3.MVRBCylindersOV = 1
						THEN 1
					WHEN t3.MVRBCylindersOV = 2
						THEN 2
					WHEN t3.MVRBCylindersOV = 3
						THEN 3
					WHEN t3.MVRBCylindersOV = 4
						THEN 4
					WHEN t3.MVRBCylindersOV = 5
						THEN 5
					WHEN t3.MVRBCylindersOV = 6
						THEN 6
					WHEN t3.MVRBCylindersOV = 7
						THEN 8
					WHEN t3.MVRBCylindersOV = 8
						THEN 10
					WHEN t3.MVRBCylindersOV = 9
						THEN 12
					WHEN t3.MVRBCylindersOV = 10
						THEN 16
					WHEN t3.MVRBCylindersOV = 11
						THEN 0
					ELSE NULL
					END
		ELSE NULL
		END AS NumberOfCylinders
	,t3.MVRBDriveDescription
	,t3.MVRBDriveDescriptionOV
	,CASE 
		WHEN t3.MVCVOverride = 1
			THEN CASE 
					WHEN t3.MVRBDriveDescriptionOV = 1
						THEN ''Front wheel drive''
					WHEN t3.MVRBDriveDescriptionOV = 2
						THEN ''Rear wheel drive''
					WHEN t3.MVRBDriveDescriptionOV = 3
						THEN ''4 wheel drive''
					WHEN t3.MVRBDriveDescriptionOV = 4
						THEN ''N/A''
					ELSE ''''
					END
		ELSE ''''
		END AS DriveDescription
	,t3.MVRBInduction
	,t3.MVRBInductionOV
	,CASE 
		WHEN t3.MVCVOverride = 1
			THEN CASE 
					WHEN t3.MVRBInductionOV = 1
						THEN ''Aspirated''
					WHEN t3.MVRBInductionOV = 2
						THEN ''Turbocharged''
					WHEN t3.MVRBInductionOV = 3
						THEN ''Supercharged''
					WHEN t3.MVRBInductionOV = 4
						THEN ''Turbo and supercharged''
					WHEN t3.MVRBInductionOV = 5
						THEN ''''
					ELSE ''''
					END
		ELSE ''''
		END AS InductionType
	,t3.MVRBImportFlag
	,t3.MVRBImportFlagOV
	,CASE 
		WHEN t3.MVCVOverride = 1
			THEN CASE 
					WHEN t3.MVRBImportFlagOV = 1
						THEN ''I''
					WHEN t3.MVRBImportFlagOV = 2
						THEN ''L''
					WHEN t3.MVRBImportFlagOV = 3
						THEN ''N/A ''
					ELSE ''''
					END
		ELSE ''''
		END AS ImportFlag
	,t3.MVCVProtectionType
	,CASE 
		WHEN t3.MVCVProtectionType = 1
			THEN ''Comprehensive - Market Value''
		WHEN t3.MVCVProtectionType = 2
			THEN ''Comprehensive - Agreed Value''
		WHEN t3.MVCVProtectionType = 3
			THEN ''Third Party, Fire and Theft''
		WHEN t3.MVCVProtectionType = 4
			THEN ''Third Party Only''
		WHEN t3.MVCVProtectionType = 5
			THEN ''Fire and Theft''
		ELSE ''''
		END AS ProtectionType
	/*MARKET VALUE*/
	,t3.MVCVMarketValue
	,CASE 
		WHEN (
				t3.MVCVOverride = 1
				AND t3.MVCVProtectionType <> 2
				)
			THEN t3.MVCVMarketValue
		ELSE NULL
		END AS MVValueWithoutAccessories /*market value w/O accesories*/
	,CASE 
		WHEN (
				t3.MVCVProtectionType <> 2
				AND t3.MVCVVehModList = ''''
				AND t3.MVCVVehModValue IS NULL
				)
			THEN ''No''
		WHEN (
				t3.MVCVProtectionType <> 2
				AND t3.MVCVVehModList <> ''''
				AND t3.MVCVVehModValue > 0
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVProtectionType <> 2
				AND t3.MVCVVehModList <> ''''
				AND t3.MVCVVehModValue < 0
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVProtectionType <> 2
				AND t3.MVCVVehModList <> ''''
				AND t3.MVCVVehModValue = 0
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVProtectionType <> 2
				AND t3.MVCVVehModList = ''''
				AND t3.MVCVVehModValue > 0
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVProtectionType <> 2
				AND t3.MVCVVehModList = ''''
				AND t3.MVCVVehModValue < 0
				)
			THEN ''Yes''
		ELSE ''No''
		END AS MVAddAccOrMods /*WouldYouLikeToAddAccessoriesOrModifications*/
	,CASE 
		WHEN t3.MVCVProtectionType <> 2
			THEN t3.MVCVVehModList
		ELSE ''''
		END AS MarketValueDescription
	,CASE 
		WHEN t3.MVCVProtectionType <> 2
			THEN t3.MVCVVehModValue
		ELSE NULL
		END AS MarketValueDescriptionValue /*MVValueWithoutAccessories + MarketValueDescriptionValue = MarketValueWithAccessoriesAmount*/
  ,  COALESCE(MVValueWithoutAccessories,NULL, 0) + COALESCE(MarketValueDescriptionValue, NULL, 0) AS MarketValueWithAccessoriesAmount
	,t3.MVCVAgreedValue /*AGREED VALUE*/
	,CASE 
		WHEN t3.MVCVProtectionType = 2
			THEN (t3.MVCVAgreedValue - t3.MVCVVehModValue)
		ELSE NULL
		END AS AVValueWithoutAccessories /*agreed value w/O accesories*/
	,CASE 
		WHEN (
				t3.MVCVProtectionType = 2
				AND t3.MVCVVehModList = ''''
				AND t3.MVCVVehModValue IS NULL
				)
			THEN ''No''
		WHEN (
				t3.MVCVProtectionType = 2
				AND t3.MVCVVehModList <> ''''
				AND t3.MVCVVehModValue > 0
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVProtectionType = 2
				AND t3.MVCVVehModList <> ''''
				AND t3.MVCVVehModValue < 0
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVProtectionType = 2
				AND t3.MVCVVehModList <> ''''
				AND t3.MVCVVehModValue = 0
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVProtectionType = 2
				AND t3.MVCVVehModList = ''''
				AND t3.MVCVVehModValue > 0
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVProtectionType = 2
				AND t3.MVCVVehModList = ''''
				AND t3.MVCVVehModValue < 0
				)
			THEN ''Yes''
		ELSE ''No''
		END AS AVAddAccOrMods /*WouldYouLikeToAddAccessoriesOrModifications*/
	,CASE 
		WHEN t3.MVCVProtectionType = 2
			THEN t3.MVCVVehModList
		ELSE ''''
		END AS AgreedValueDescription
	,CASE 
		WHEN t3.MVCVProtectionType = 2
			THEN t3.MVCVVehModValue
		ELSE NULL
		END AS agreedValueDescriptionValue
  ,COALESCE(AVValueWithoutAccessories, 0) + COALESCE(agreedValueDescriptionValue, 0) AS agreedvalueamount
	,t3.MVCVYoungestDriver AS AgeOfYoungestRegularDriver
	,t3.MVCVAgeRestriction
	,t5.CAText
	,t5.CADescription
	,CASE 
		WHEN (
				UPPER(t5.CADescription) LIKE ''%THIS OVERRIDES ANY DRIVER AGE RESTRICTION SHOWING ON THIS VEHICLE%''
				AND UPPER(t5.CAText) <> ''CM_C05_HVNOAR''
				)
			THEN ''No Restriction''
		WHEN t3.MVCVAgeRestriction = 1
			THEN ''No Restriction''
		WHEN t3.MVCVAgeRestriction = 2
			THEN ''Min Age 21''
		WHEN t3.MVCVAgeRestriction = 3
			THEN ''Min Age 25''
		WHEN t3.MVCVAgeRestriction = 4
			THEN ''Min Age 30''
		WHEN t3.MVCVAgeRestriction = 5
			THEN ''Min Age 40''
		ELSE ''''
		END AS RestrictionOfDriverAge
	,t3.MVCVTPFinInterest
	,CASE 
		WHEN (
				t3.MVCVTPFinInterest = 1
				AND t3.MVCVTPFinInterestDet <> ''''
				)
			THEN ''Yes''
		WHEN (
				t3.MVCVTPFinInterest = 1
				AND t3.MVCVTPFinInterestDet = ''''
				)
			THEN ''No''
		WHEN t3.MVCVTPFinInterest = 0
			THEN ''No''
		ELSE ''''
		END AS VehHaveAnInterestedParty /*DoesTheVehicleHaveAnInterestedParty*/
	,t3.MVCVTPFinInterestDet AS DetForTheParty /*AddDetailsForTheInterestedParty*/
	,t3.MVCVChoiceRepair
	,CASE 
		WHEN t3.MVCVProtectionType <> 4
			THEN CASE 
					WHEN t3.MVCVChoiceRepair = 1
						THEN ''Taken''
					WHEN t3.MVCVChoiceRepair = 0
						THEN ''Not Taken''
					ELSE ''''
					END
		ELSE ''''
		END AS ChoiceOfRepair
	,t3.MVCVCarHire
	,CASE 
		WHEN t3.MVCVProtectionType <> 4
			THEN CASE 
					WHEN t3.MVCVCarHire = 1
						THEN ''Taken''
					WHEN t3.MVCVCarHire = 0
						THEN ''Not Taken''
					ELSE ''''
					END
		ELSE ''''
		END AS HireCarHireAfterIncident
	,t3.MVCVUnlimGlass
	,CASE 
		WHEN t3.MVCVProtectionType IN (
				1
				,2
				)
			THEN CASE 
					WHEN t3.MVCVUnlimGlass = 1
						THEN ''Yes''
					WHEN t3.MVCVUnlimGlass = 0
						THEN ''No''
					ELSE ''''
					END
		ELSE ''''
		END AS ExcessWaiverForGlass
	,CASE 
		WHEN t3.MVCVVoluntary IS NULL
			THEN 0
		WHEN t3.MVCVVoluntary = 0
			THEN 0
		WHEN t3.MVCVVoluntary <= 500
			THEN 500
		WHEN t3.MVCVVoluntary <= 1000
			THEN 1000
		WHEN t3.MVCVVoluntary <= 2000
			THEN 2000
		WHEN t3.MVCVVoluntary > 2000
			THEN 5000
		END AS VoluntaryExcess,
    t6.dcclausetype AS ClausesSelection,
   t6.dcinput AS SelectClauseDescription
FROM Sample_PrivateMotor_PER t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL t3 ON (t2.ExpiringID_P = t3.PER_Policy_Binder_id)
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RISKSELECTION t4 ON t2.ExpiringID_P = t4.PER_Policy_Binder_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE t6 ON t2.expiringid_p = t6.purepolicybinderid
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_CLAUSEAMENDMENTMV t5 ON (
		t2.ExpiringID_P = t5.PER_Policy_Binder_id
		AND t3.PER_VEHICLEDETAIL_id = t5.PER_VEHICLEDETAIL_id
		);
        

;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PM_02 AS
SELECT 
    PUREPolicyNumber,
	ExpiringID_P,
    insurance_file_cnt,
	CMLNumber,
	ExpiryDate,
	Country,
	Product,
	STATE,
	MotorVehicles_Ind,
	-- Vehicle information
	VehicleID,
	RegistrationNumber,
    --RestrictionOfDriverAge,
	MVRBVehicleKey,
	MVRBGrossVehMass,
	MVRBEngineSize,
	MVCVTypeVeh,

    /* SAS: Clause_Text = UPCASE(CAText); */
    UPPER(CAText) AS Clause_Text,

    /* SAS: Clause_Desc = UPCASE(CADescription); */
    UPPER(CADescription) AS Clause_Desc,

    /* SAS Result_String logic */
    CASE
        WHEN
            POSITION(''CM_C06_MODSACCS'' IN UPPER(CAText)) > 0
         OR POSITION(''ACCESSORIES''     IN UPPER(CAText)) > 0
         OR POSITION(''MODIFICATION''    IN UPPER(CAText)) > 0
        THEN
            CASE
                WHEN POSITION(''INCLUDES'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(
                        CADescription,
                        POSITION(''INCLUDES'' IN UPPER(CADescription)) + 8
                    )

                WHEN POSITION(''INCLUDE '' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(
                        CADescription,
                        POSITION(''INCLUDE '' IN UPPER(CADescription)) + 8
                    )

                WHEN POSITION(''INCLUDE:'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(
                        CADescription,
                        POSITION(''INCLUDE:'' IN UPPER(CADescription)) + 8
                    )

                WHEN POSITION(''MODIFICATIONS:'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(
                        CADescription,
                        POSITION(''MODIFICATIONS:'' IN UPPER(CADescription)) + 14
                    )

                ELSE CADescription
            END
    END AS Result_String,

    /* SAS: IF MVCVProtectionType NE 2 */
    CASE
        WHEN
            (
                POSITION(''CM_C06_MODSACCS'' IN UPPER(CAText)) > 0
             OR POSITION(''ACCESSORIES''     IN UPPER(CAText)) > 0
             OR POSITION(''MODIFICATION''    IN UPPER(CAText)) > 0
            )
            AND MVCVProtectionType <> 2
        THEN
            CASE
                WHEN POSITION(''INCLUDES'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION(''INCLUDES'' IN UPPER(CADescription)) + 8)
                WHEN POSITION(''INCLUDE '' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION(''INCLUDE '' IN UPPER(CADescription)) + 8)
                WHEN POSITION(''INCLUDE:'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION(''INCLUDE:'' IN UPPER(CADescription)) + 8)
                WHEN POSITION(''MODIFICATIONS:'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION(''MODIFICATIONS:'' IN UPPER(CADescription)) + 14)
                ELSE CADescription
            END
    END AS MarketValueDescription,

    CASE
        WHEN
            (
                POSITION(''CM_C06_MODSACCS'' IN UPPER(CAText)) > 0
             OR POSITION(''ACCESSORIES''     IN UPPER(CAText)) > 0
             OR POSITION(''MODIFICATION''    IN UPPER(CAText)) > 0
            )
            AND MVCVProtectionType <> 2
        THEN ''Yes''
    END AS MVAddAccOrMods,

    /* SAS: IF MVCVProtectionType = 2 */
    CASE
        WHEN
            (
                POSITION(''CM_C06_MODSACCS'' IN UPPER(CAText)) > 0
             OR POSITION(''ACCESSORIES''     IN UPPER(CAText)) > 0
             OR POSITION(''MODIFICATION''    IN UPPER(CAText)) > 0
            )
            AND MVCVProtectionType = 2
        THEN
            CASE
                WHEN POSITION(''INCLUDES'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION(''INCLUDES'' IN UPPER(CADescription)) + 8)
                WHEN POSITION(''INCLUDE '' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION(''INCLUDE '' IN UPPER(CADescription)) + 8)
                WHEN POSITION(''INCLUDE:'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION(''INCLUDE:'' IN UPPER(CADescription)) + 8)
                WHEN POSITION(''MODIFICATIONS:'' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION(''MODIFICATIONS:'' IN UPPER(CADescription)) + 14)
                ELSE CADescription
            END
    END AS AgreedValueDescription,

    CASE
        WHEN
            (
                POSITION(''CM_C06_MODSACCS'' IN UPPER(CAText)) > 0
             OR POSITION(''ACCESSORIES''     IN UPPER(CAText)) > 0
             OR POSITION(''MODIFICATION''    IN UPPER(CAText)) > 0
            )
            AND MVCVProtectionType = 2
        THEN ''Yes''
    END AS AVAddAccOrMods,

    /* IF MVRBVehicleKey = '''' THEN Override = ''Yes''; */
    CASE
        WHEN MVRBVehicleKey = '''' THEN ''Yes''
        ELSE Override
    END AS Override,

    /* IF Override = ''Yes'' AND MVCVProtectionType NE 2
       AND MVValueWithoutAccessories = . */
    CASE
        WHEN
            (CASE
                WHEN MVRBVehicleKey = '''' THEN ''Yes''
                ELSE Override
             END) = ''Yes''
            AND MVCVProtectionType <> 2
            AND MVValueWithoutAccessories IS NULL
        THEN MVCVMarketValue
        ELSE MVValueWithoutAccessories
    END AS MVValueWithoutAccessories,
    CASE MVRBVehicleKey
        WHEN ''AUVTOYO1994AEGZ'' THEN ''Heavy Commercial''
        WHEN ''AUVISUZ2009AEDN'' THEN ''Heavy Commercial''
        WHEN ''AUVFORD2009AEIU'' THEN ''Light Commercial''
        WHEN ''AUVTOYO2001AEIZ'' THEN ''Heavy Commercial''
        WHEN ''AUVISUZ2006AECF'' THEN ''Heavy Commercial''
        WHEN ''AUVTOYO2001AEID'' THEN ''Light Commercial''
        WHEN ''NZVMERC2002AEEX'' THEN ''Light Commercial''
        WHEN ''AUVFUSO2013AEDU'' THEN ''Heavy Commercial''
        WHEN ''AUVVOLK2006AEIL'' THEN ''Light Commercial''
        WHEN ''AUVTOYO2005AEGO'' THEN ''Light Commercial''
        WHEN ''AUVVOLK2008AEHM'' THEN ''Light Commercial''
        WHEN ''AUVTOYO2011AECU'' THEN ''Light Commercial''
        WHEN ''AUVHOLD1991AECN'' THEN ''Passenger Vehicle''
        WHEN ''AUVMERC2017AEKY'' THEN ''Passenger Vehicle''
        WHEN ''AUVGWM_2021AEAC'' THEN ''Light Commercial''
        WHEN ''AUVFIAT2018AEAR'' THEN ''Light Commercial''
        WHEN ''AUVLDV_2020AEAM'' THEN ''Light Commercial''
        WHEN ''AUVTOYO2021AEBK'' THEN ''Light Commercial''
        WHEN ''AUVTOYO2010AELH'' THEN ''Light Commercial''
        WHEN ''AUVNISS2023AEAS'' THEN ''Light Commercial''

       

       
        --WHEN  UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''ROSA'' THEN ''Heavy Commercial'' END
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''ROSA'' THEN ''Heavy Commercial''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''LIFTSMART'' AND UPPER(Model) = ''LS-RT35'' THEN ''Forklift''
        -- WHEN Override = ''Yes'' AND UPPER(Make) IN (''CAN-AM'', ''CANNEM'', ''CAN AM'', ''CAM AM'') THEN ''Motorcycle''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''HINO'' AND UPPER(Model) = ''RANGER'' THEN ''Heavy Commercial''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''CUSTOM'' AND UPPER(Model) = ''BOXTOP TRAILER'' THEN ''Trailer''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''CUSTOM BUILT'' AND UPPER(Model) IN (''TANDEM CAR TRAILER'',''TANDEM TRAILER'') THEN ''Trailer''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''CUSTOM'' AND UPPER(Model) IN (''TANDEM CAR TRAILER'',''TANDEM TRAILER'') THEN ''Trailer''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''KINGS'' AND UPPER(Model) = ''TANDEM BOX TRAILER'' THEN ''Trailer''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''JOHN PAPAS'' AND UPPER(Model) = ''FLAT TOP TRAILER'' THEN ''Trailer''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''E-Z-GO'' AND UPPER(Model) = ''5161703'' THEN ''Trailer''
        -- WHEN Override = ''Yes'' AND UPPER(Make) = ''LOTUS'' AND UPPER(Model) = ''CARAVAN TROOPER'' THEN ''Caravan''
        ELSE VehicleType  -- preserve existing value if no match
    END AS VehicleType,

   

    -- Recalculate BodyType if blank after the above assignment
    CASE
        WHEN Override = ''Yes'' AND MVCVOverride = 0 AND (MVCVBodyType IS NULL OR MVCVBodyType = '''') THEN
            CASE
                WHEN UPPER(Make) = ''FORD''       AND UPPER(Model) = ''RANGER''              THEN ''Utility''
                WHEN UPPER(Make) = ''FORD''       AND UPPER(Model) = ''TERRIRTORY''          THEN ''Wagon''
                WHEN UPPER(Make) = ''LEXUS''      AND UPPER(Model) = ''NX300''               THEN ''Wagon''
                WHEN UPPER(Make) = ''TOYOTA''     AND UPPER(Model) = ''HIACE''               THEN ''Van''
                WHEN UPPER(Make) = ''TOYOTA''     AND UPPER(Model) = ''CAMRY''               THEN ''Sedan''
                WHEN UPPER(Make) = ''TOYOTA''     AND UPPER(Model) = ''LANDCRUISER PRADO''  THEN ''Wagon''
                WHEN UPPER(Make) = ''BMW''        AND UPPER(Model) = ''X5''                  THEN ''Wagon''
                WHEN UPPER(Make) = ''MAZDA''      AND UPPER(Model) = ''BT-50''               THEN ''Utility''
                WHEN UPPER(Make) = ''MAZDA''      AND UPPER(Model) = ''T4000''               THEN ''Transporter''
                WHEN UPPER(Make) = ''MAZDA''      AND UPPER(Model) = ''3''                   THEN ''Hatchback''
                WHEN UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''CANTER''              THEN ''Utility''
                WHEN UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''PAJERO''              THEN ''Wagon''
                WHEN UPPER(Make) = ''SUBARU''     AND UPPER(Model) = ''LIBERTY''             THEN ''Wagon''
                WHEN UPPER(Make) = ''HYUNDAI''    AND UPPER(Model) = ''I30''                 THEN ''Hatchback''
                WHEN UPPER(Make) = ''VOLKSWAGEN'' AND UPPER(Model) = ''CADDY''               THEN ''Van''
                WHEN UPPER(Make) = ''MERCEDES''   AND UPPER(Model) = ''AMG-C''               THEN ''Sedan''

                WHEN Override = ''Yes'' AND UPPER(Make) = ''MITSUBISHI'' AND UPPER(Model) = ''ROSA'' THEN ''Bus''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''LIFTSMART'' AND UPPER(Model) = ''LS-RT35'' THEN ''Forklift''
                WHEN Override = ''Yes'' AND UPPER(Make) IN (''CAN-AM'', ''CANNEM'', ''CAN AM'', ''CAM AM'') THEN ''Motorcycle''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''HINO'' AND UPPER(Model) = ''RANGER'' THEN ''Transporter''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''CUSTOM'' AND UPPER(Model) = ''BOXTOP TRAILER'' THEN ''Trailer''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''CUSTOM BUILT'' AND UPPER(Model) IN (''TANDEM CAR TRAILER'',''TANDEM TRAILER'') THEN ''Trailer''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''CUSTOM'' AND UPPER(Model) IN (''TANDEM CAR TRAILER'',''TANDEM TRAILER'') THEN ''Trailer''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''KINGS'' AND UPPER(Model) = ''TANDEM BOX TRAILER'' THEN ''Trailer''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''JOHN PAPAS'' AND UPPER(Model) = ''FLAT TOP TRAILER'' THEN ''Trailer''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''E-Z-GO'' AND UPPER(Model) = ''5161703'' THEN ''Trailer''
                WHEN Override = ''Yes'' AND UPPER(Make) = ''LOTUS'' AND UPPER(Model) = ''CARAVAN TROOPER'' THEN ''Caravan''

                WHEN UPPER(Make) = ''MERDEDES-BENZ'' AND UPPER(Model) = ''CLK320'' THEN ''Coupe''
                WHEN UPPER(Make) = ''MERCEDES-BENZ''
                     AND UPPER(Model) IN (''C-CLASS C250D'',''260SE'') THEN ''Sedan''
                WHEN UPPER(Make) = ''MERCEDES BENZ'' AND UPPER(Model) = ''300 GD WAGON'' THEN ''Wagon''
                WHEN UPPER(Make) = ''EMC'' AND UPPER(Model) = ''ELECTRIC CART'' THEN ''Utility''
                WHEN UPPER(Make) = ''FORD''
                     AND UPPER(Model) IN (''MUSTANG'',''GALAXIE COUPE'') THEN ''Coupe''
                WHEN UPPER(Make) = ''MAZDA'' AND UPPER(Model) = ''RX7'' THEN ''Coupe''
                WHEN UPPER(Make) = ''BMW'' AND UPPER(Model) = ''318I'' THEN ''Sedan''
                WHEN UPPER(Make) = ''DODGE''
                     AND UPPER(Model) IN (''RAM'',''RAM DUAL DIESEL XTRA CAB UTILITY'',''RAM 3500'')
                     THEN ''Utility''
                        
                ELSE MVCVBodyType
            END
        ELSE BodyType
        END AS BodyType,
        

    -- /* RestrictionOfDriverAge */
        CASE
            WHEN MVCVProtectionType IN (1,2,4)
                 AND RestrictionOfDriverAge = ''''
            THEN ''No Restriction''
            ELSE RestrictionOfDriverAge
        END
     AS RestrictionOfDriverAge,

    -- /* VehHaveAnInterestedParty */
        CASE
            WHEN MVCVTPFinInterest = 2 THEN ''No''
            ELSE VehHaveAnInterestedParty
        END
        AS VehHaveAnInterestedParty,

    -- /* MVCVAgreedValue – minimum 2000 */
        CASE
            WHEN MVCVProtectionType = 2
                 AND MVCVAgreedValue < 2000
            THEN 2000
            ELSE MVCVAgreedValue
        END
        AS  MVCVAgreedValue,

    -- /* agreedValueDescriptionValue & AVValueWithoutAccessories – 90% rule */
        CASE
            WHEN MVCVProtectionType = 2
                 AND agreedValueDescriptionValue > (MVCVAgreedValue * 0.9)
            THEN (MVCVAgreedValue * 1.1) * 0.8
            ELSE agreedValueDescriptionValue
        END
        AS agreedValueDescriptionValue,
    
        CASE
            WHEN MVCVProtectionType = 2
                 AND agreedValueDescriptionValue > (MVCVAgreedValue * 0.9)
            THEN (MVCVAgreedValue * 1.1) - ((MVCVAgreedValue * 1.1) * 0.8)
            WHEN MVCVProtectionType = 2
                 AND AVValueWithoutAccessories IS NULL
            THEN MVCVAgreedValue
            ELSE AVValueWithoutAccessories
        END
        AS AVValueWithoutAccessories,

    -- /* MarketValueDescriptionValue */
        CASE
            WHEN MVCVProtectionType <> 2
                 AND MVAddAccOrMods = ''Yes''
                 AND MarketValueDescriptionValue IS NULL
            THEN 0
            WHEN MVCVProtectionType <> 2
                 AND MVAddAccOrMods = ''No''
            THEN NULL
            ELSE MarketValueDescriptionValue
        END
        AS MarketValueDescriptionValue,

    

    -- /* AgeOfYoungestRegularDriver */
        CASE
            WHEN AgeOfYoungestRegularDriver < 16 THEN NULL
            ELSE AgeOfYoungestRegularDriver
        END
        AS AgeOfYoungestRegularDriver,

    -- /* Vehicle key present */
    
        CASE WHEN MVRBVehicleKey <> '''' THEN '''' ELSE Make END AS Make,
    
        CASE WHEN MVRBVehicleKey <> '''' THEN '''' ELSE Model END AS Model,

        CASE WHEN MVRBVehicleKey <> '''' THEN 0 ELSE Year END AS Year,
    
        CASE WHEN MVRBVehicleKey <> '''' THEN 0 ELSE EngineSize END AS EngineSize,
    
        CASE WHEN MVRBVehicleKey <> '''' THEN 0 ELSE GrossVehicleMass END AS GrossVehicleMass,
        MarketValueWithAccessoriesAmount,
        Description,
        NumberOfCylinders,
        DriveDescription,
        InductionType,
        ImportFlag,
        ProtectionType,
        MVAddAccOrMods  AS WouldYouLikeToAddAccessoriesOrModifications,
        DetForTheParty  AS AddDetailsForTheInterestedParty,
        ChoiceOfRepair,
        HireCarHireAfterIncident,
        agreedvalueamount,
        ExcessWaiverForGlass,
        VOLUNTARYEXCESS,
        ClausesSelection,
       SelectClauseDescription
FROM PM_01 
WHERE MotorVehicles_Ind <> 0
ORDER BY PUREPolicyNumber, RegistrationNumber, RestrictionOfDriverAge;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PM_03 AS
SELECT
    /* List all columns to KEEP (DROP columns excluded) */
   PUREPOLICYNUMBER,
    EXPIRINGID_P,
    insurance_file_cnt,
    CMLNUMBER,
    EXPIRYDATE,
    COUNTRY,
    PRODUCT,
    STATE,
    MOTORVEHICLES_IND,
    VEHICLEID,
    REGISTRATIONNUMBER,
    MVRBVEHICLEKEY,
    CLAUSE_TEXT,
    CLAUSE_DESC,
    RESULT_STRING,
    MARKETVALUEDESCRIPTION,
    MVADDACCORMODS,
    AGREEDVALUEDESCRIPTION,
    AVADDACCORMODS,
    OVERRIDE,
    MVVALUEWITHOUTACCESSORIES,
    VEHICLETYPE,
    BODYTYPE,
    RESTRICTIONOFDRIVERAGE,
    VEHHAVEANINTERESTEDPARTY,
    AGREEDVALUEDESCRIPTIONVALUE,
    AVVALUEWITHOUTACCESSORIES,
    MARKETVALUEDESCRIPTIONVALUE,
    AGEOFYOUNGESTREGULARDRIVER,
    MAKE,
    MODEL,
    YEAR,
    ENGINESIZE,
    GROSSVEHICLEMASS,
     Description,
    NumberOfCylinders,
    DriveDescription,
    InductionType,
    ImportFlag,
    ProtectionType,
    MarketValueWithAccessoriesAmount,
    agreedvalueamount,
    AddDetailsForTheInterestedParty,
     ChoiceOfRepair,
    HireCarHireAfterIncident,
    ExcessWaiverForGlass,
    VOLUNTARYEXCESS,
    ClausesSelection,
   SelectClauseDescription
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY PUREPolicyNumber, EXPIRINGID_P,VEHICLEID
            ORDER BY RestrictionOfDriverAge DESC -- Last record based on full sort order
        ) AS rn
    FROM PM_02
)
WHERE rn = 1
ORDER BY PUREPolicyNumber, RegistrationNumber, RestrictionOfDriverAge;


-----------------------------------------------1.8@@Privatevehicle@@end@@------------------------------------------------------------------------------------------------

-----------------------------------------------1.9@@ManualReferral_Notes@@start@@---------------------------------------------------------------------------------------------


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.ManualRef_01_BSP AS
SELECT DISTINCT t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.ExpiryDate
	,t2.Country
	,CASE 
		WHEN t3.SUAlwaysReferRenewal = 1
			THEN ''Yes''
		ELSE ''''
		END AS AlwaysReferAtRenewal
	,t3.SUAlwaysReferRenewalDet AS UnderwritingNotes
FROM sample_cbp t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_summary t3 ON t2.ExpiringID_P = t3.CBP_Policy_Binder_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentssu t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
WHERE t3.SUAlwaysReferRenewal = 1;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.AdjustmentNote_01_BSP AS
SELECT t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.ExpiryDate
	,t2.CMLNumber
	,t2.Country
	,t2.Product
	,t4.AJAdjustmentNote
FROM sample_cbp t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_adjustmentssu t4 ON t2.ExpiringID_P = t4.CBP_Policy_Binder_id
WHERE (
		UPPER(T4.AJAdjustmentNote) LIKE ''%MANUAL REFER%''
		OR UPPER(T4.AJAdjustmentNote) LIKE ''%MANUAL REVIEW%''
		OR UPPER(T4.AJAdjustmentNote) LIKE ''%MANUAL REF%''
		OR UPPER(T4.AJAdjustmentNote) LIKE ''%MAN REF%''
		)
ORDER BY t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.ExpiryDate
	,t2.CMLNumber
	,t2.Country
	,t2.Product;



CREATE  OR REPLACE TRANSIENT TABLE AdjustmentNote_BSP AS
SELECT
    PUREPolicyNumber,
    ExpiringID_P,
    ExpiryDate,
    CMLNumber,
    Country,
    Product,
    ARRAY_TO_STRING(ARRAY_AGG(AJAdjustmentNote), '','') AS AJAdjustment_Note_Combined
FROM AdjustmentNote_01_BSP
GROUP BY
    PUREPolicyNumber,
    ExpiringID_P,
    ExpiryDate,
    CMLNumber,
    Country,
    Product;
 


CREATE  OR REPLACE transient TABLE ManualRef_02_BSP AS
SELECT DISTINCT
     t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.expirydate
	,t2.Country
	,t2.AlwaysReferAtRenewal
	,CONCAT(
        TRIM(t2.UnderwritingNotes),
        '' '',
        TRIM(t3.AJAdjustment_Note_Combined)
    ) AS UWNote

FROM ManualRef_01_BSP t2
LEFT JOIN AdjustmentNote_BSP t3 ON t2.ExpiringID_P = t3.ExpiringID_P;



CREATE  OR REPLACE  TRANSIENT TABLE AGGNE.DEV.ManualRef_BSP AS
SELECT
 PUREPOLICYNUMBER
,EXPIRINGID_P
,CMLNUMBER
,EXPIRYDATE
,COUNTRY
,ALWAYSREFERATRENEWAL
  ,CASE 
    WHEN UWNote IS NULL OR TRIM(UWNote) = '''' THEN ''.''
    ELSE UWNote 
  END AS UnderwritingDetails
FROM ManualRef_02_BSP;


-----------------------------------------------1.9@@ManualReferral_Notes_BSP@@end@@---------------------------------------------------------------------------------------------

-----------------------------------------------1.10@@ManualReferral_Notes_PER@@start@@----------------------------------------------------------------------------------------


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.ManualRef_01_PER AS
SELECT DISTINCT t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.effectivedate
	,t2.Country
	,CASE 
		WHEN t3.SUReferRenewalUW = 1
			THEN ''Yes''
		ELSE ''''
		END AS AlwaysReferAtRenewal
	,t3.SUReferDetails AS UnderwritingNotes
FROM Sample_PER t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_SUMMARY t3 ON t2.ExpiringID_P = t3.PER_Policy_Binder_id
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSSU t4 ON t2.ExpiringID_P = t4.PER_Policy_Binder_id
WHERE t3.SUReferRenewalUW = 1;



;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.AdjustmentNote_01_PER AS
SELECT  t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.effectivedate
	,t2.CMLNumber
	,t2.Country
	,t2.Product
	,t4.AJAdjustmentNote
FROM Sample_PER t2
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSSU t4 ON t2.ExpiringID_P = t4.PER_Policy_Binder_id
WHERE (
		UPPER(T4.AJAdjustmentNote) LIKE ''%MANUAL REFER%''
		OR UPPER(T4.AJAdjustmentNote) LIKE ''%MANUAL REVIEW%''
		OR UPPER(T4.AJAdjustmentNote) LIKE ''%MANUAL REF%''
		OR UPPER(T4.AJAdjustmentNote) LIKE ''%MAN REF%''
		)
ORDER BY t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.effectivedate
	,t2.CMLNumber
	,t2.Country
	,t2.Product;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.AdjustmentNote_PER AS
SELECT 
    PUREPolicyNumber,
    ExpiringID_P,
    effectivedate,
    CMLNumber,
    Country,
    Product,
    ARRAY_TO_STRING(ARRAY_AGG(AJAdjustmentNote), '','') AS AJAdjustment_Note_Combined
FROM AdjustmentNote_01_PER
GROUP BY
    PUREPolicyNumber,
    ExpiringID_P,
    effectivedate,
    CMLNumber,
    Country,
    Product;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.ManualRef_02_PER AS
SELECT 
  t2.PUREPolicyNumber
	,t2.ExpiringID_P
	,t2.CMLNumber
	,t2.effectivedate
	,t2.Country
	,t2.AlwaysReferAtRenewal
	,CONCAT(
        TRIM(t2.UnderwritingNotes),
        '' '',
        TRIM(t3.AJAdjustment_Note_Combined)
    ) AS UWNote
FROM ManualRef_01_PER t2
LEFT JOIN AdjustmentNote_PER t3 ON t2.ExpiringID_P = t3.ExpiringID_P;


;CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.ManualRef_PER AS
SELECT
PUREPOLICYNUMBER
,EXPIRINGID_P
,CMLNUMBER
,effectivedate
,COUNTRY
,ALWAYSREFERATRENEWAL
    ,CASE 
        WHEN UWNote IS NULL OR TRIM(UWNote) = '''' THEN ''.''
        ELSE UWNote
    END AS UnderwritingDetails
FROM ManualRef_02_PER;

----Expirying Measure @start@---


--------------------Policy_Sample_BSP_01-----------------------------------------
 CREATE OR REPLACE TRANSIENT TABLE Policy_Sample_BSP_01 AS
         SELECT DISTINCT 
                   t3.INSURANCE_REF  AS PolicyNumber, 
                   t18.CBP_Policy_Binder_id  AS ExpiringID_P,
                   t14.shortname AS CMLNUMBER,
                   t1.risk_cnt  AS risk_cnt,
                   CAST(t3.expiry_date AS DATE)  AS ExpiryDate ,
                   t13.description  AS Country,
                   t19.code  AS Product,
                   t1.risk_number AS RiskNumber,
                        CAST(t20.SUBBTotalContrib AS NUMBER(11,0)) AS BBExpPrem,
                        CAST(t20.SUBCTotalContrib AS NUMBER(11,0)) AS BCExpPrem, 
                        CAST(t20.SUBGTotalContrib AS NUMBER(11,0)) AS BGExpPrem, 
                        CAST(t20.SUMYTotalContrib AS NUMBER(11,0)) AS MYExpPrem,  
                        CAST(t20.SUENTotalContrib AS NUMBER(11,0)) AS ENExpPrem, 
                        CAST(t20.SUBITotalContrib AS NUMBER(11,0)) AS BIExpPrem, 
                        CAST(t20.SUGPTotalContrib AS NUMBER(11,0)) AS GPExpPrem, 
                        CAST(t20.SUGTTotalContrib AS NUMBER(11,0)) AS GTExpPrem, 
                        CAST(t20.SUPPTotalContrib AS NUMBER(11,0)) AS PPExpPrem, 
                        CAST(t20.SUPITotalContrib AS NUMBER(11,0)) AS PIExpPrem, 
                        CAST(t20.SULETotalContrib AS NUMBER(11,0)) AS LEExpPrem, 
                        CAST(t20.SUTATotalContrib AS NUMBER(11,0)) AS TAExpPrem, 
                        CAST(t20.SUCMTotalContrib AS NUMBER(11,0)) AS CMExpPrem, 
                        CAST(t20.SUCVTotalContrib AS NUMBER(11,0)) AS CVExpPrem, 
                        CAST(t20.SUUVTotalContrib AS NUMBER(11,0)) AS SVExpPrem, 
                        CAST(t20.SUFVTotalContrib AS NUMBER(11,0)) AS FVExpPrem,
                        CAST(t20.SUTotStormBase AS NUMBER(11,0)) AS StormBase, 
                        CAST(t20.SUTotCycloneBase AS NUMBER(11,0)) AS CycloneBase,  
                        CAST(t20.SUTotBushFireBase AS NUMBER(11,0)) AS BushFireBase, 
                        CAST(t20.SUTotEarthquakeBase AS NUMBER(11,0)) AS EarthquakeBase,
                        CAST(t20.SUBBBaseContrib AS NUMBER(11,0)) AS TotalBase1, 
                        CAST(t20.SUBCBaseContrib AS NUMBER(11,0)) AS TotalBase2,  
                        CAST(t20.SUBIBaseContrib AS NUMBER(11,0)) AS TotalBase3, 
                        CAST(t20.SUUVBaseContrib AS NUMBER(11,0)) AS TotalBase4, 
                        t22.UVAgriculturalVehicles,
                      t22.UVBoatTrailers,
                      t22.UVCaravanHomes,
                     t22.UVConstructionEquipment,
                      t22.UVGoodsCarryingTonnage,
                      t22.UVMotorcycles,
                      t22.UVPassengerCommercialVehicle,
                      t22.UVWatercraft,
                      t21.RLStockVehicles,
                      t21.RLCommercialVehicles,
                      t21.RLFleetVehicles,
                   t25.FVNoVehicles,
                      t21.PersonalProtectionCount,
                        t21.RLPostCode,
                             (SELECT COUNT(*) 
                          FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_vehicledetail t23
                         WHERE t23.CBP_Policy_Binder_id = t18.CBP_Policy_Binder_id) AS VEH_CNT,
                      (SELECT COUNT(*) 
                         FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_vehicledetail t24
                        WHERE t24.CBP_Policy_Binder_id = t18.CBP_Policy_Binder_id
                          AND t24.CMCVTypeVeh = 6) AS TOW_CNT
          FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t1
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_folder              t0  ON t1.risk_folder_cnt = t0.risk_folder_cnt
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2  ON t1.risk_cnt = t2.risk_cnt
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file           t3  ON t2.insurance_file_cnt = t3.insurance_file_cnt
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link          t6  ON t3.insured_cnt = t6.party_cnt  
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_policy_binder   t7  ON t6.gis_policy_link_id = t7.gis_policy_link_id   
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.capparty_membercsl       t9  ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party                    t14 ON t3.insured_cnt = t14.party_cnt
          LEFT JOIN AGGNE.DEV.CLIENTCONTACTS          t10 ON t6.party_cnt = T10.clientid
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.source                   t13 ON t3.source_id    = t13.source_id
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk_status              t15 ON t1.risk_status_id = t15.risk_status_id
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status    t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link          t17 ON t1.risk_cnt = t17.risk_id
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_policy_binder        t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.product                  t19 ON (t3.product_id = t19.product_id) 
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_summary t20 ON (t20.CBP_Policy_Binder_id = t18.CBP_Policy_Binder_id)
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t21 ON (t21.CBP_Policy_Binder_id = t18.CBP_Policy_Binder_id)
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_stockvehicle t22 ON (t22.CBP_Policy_Binder_id = t18.CBP_Policy_Binder_id)
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_fleetvehicles t25 ON (t25.CBP_Policy_Binder_id = t18.CBP_Policy_Binder_id)
        WHERE 
        --CAST(t3.expiry_date) = TODAY() + 42
              SUBSTR(t3.insurance_ref,1,1) = ''P''
             AND t3.insurance_file_type_id <> 3                 /* (3=Policy under Renewal) */
             AND COALESCE(T3.insurance_file_status_id,NULL,0) NOT IN (1, 2)      
             AND t15.risk_status_id IN (1, 3)                   /* (1=Referred, 3=Quoted) */
             AND t2.status_flag <> ''D''                          /* (D=Deleted) */
             AND t3.insurance_ref NOT IN (
                 SELECT DISTINCT t13.insurance_ref 
                 FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t11
                 INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
                 INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
                 WHERE 
                 CAST(t13.expiry_date AS DATE) > current_date()
                   AND t13.insurance_file_type_id = 8        /* (8 = MTA Cancelled) */
             )
             AND (
                 /* Case 1: Only one insurance_file_cnt for the policy */
                 (SELECT COUNT(DISTINCT ins.insurance_file_cnt)
                  FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
                  WHERE ins.insurance_ref = t3.insurance_ref) = 1
                 OR

                 /* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
                 t3.insurance_file_cnt = (
                     SELECT MAX(ins.insurance_file_cnt)
                     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file ins
                     LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status status 
                       ON ins.insurance_file_status_id = status.insurance_file_status_id
                     WHERE ins.insurance_ref = t3.insurance_ref
                       AND (status.insurance_file_status_id <> 1 OR status.insurance_file_status_id IS NULL) /* (1=Cancelled) */
                 )
             )
       ORDER BY ExpiryDate, PolicyNumber;

--------------------------------------Policy_Sample_BSP--------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Policy_Sample_BSP AS
SELECT
POLICYNUMBER,
EXPIRINGID_P,
CMLNUMBER,
RISK_CNT,
EXPIRYDATE,
COUNTRY,
PRODUCT,
RISKNUMBER,
BBEXPPREM,
BCEXPPREM,
BGEXPPREM,
MYEXPPREM,
ENEXPPREM,
BIEXPPREM,
GPEXPPREM,
GTEXPPREM,
PPEXPPREM,
PIEXPPREM,
LEEXPPREM,
TAEXPPREM,
CMEXPPREM,
CVEXPPREM,
SVEXPPREM,
FVEXPPREM,
PersonalProtectionCount,
RLPostCode,

    -- Vehicle count calculations
    CASE WHEN RLCommercialVehicles = 1 THEN VEH_CNT ELSE 0 END AS CMNoVehs,
    CASE WHEN RLCommercialVehicles = 1 THEN TOW_CNT ELSE 0 END AS TowNoVehs,
    CASE WHEN RLFleetVehicles = 1 THEN FVNoVehicles ELSE 0 END AS FVNoVehs,
    CASE WHEN RLStockVehicles = 1 THEN
        COALESCE(UVAgriculturalVehicles, 0) +
        COALESCE(UVBoatTrailers, 0) +
        COALESCE(UVCaravanHomes, 0) +
        COALESCE(UVConstructionEquipment, 0) +
        COALESCE(UVGoodsCarryingTonnage, 0) +
        COALESCE(UVMotorcycles, 0) +
        COALESCE(UVPassengerCommercialVehicle, 0) +
        COALESCE(UVWatercraft, 0)
    ELSE 0 END AS SVNoVehs,

    -- PER campaign eligibility
    CASE 
        WHEN PersonalProtectionCount < 1 
             AND NOT (COUNTRY = ''Australia'' AND LEFT(RLPostCode,2) IN (''67'', ''47'', ''48'', ''08''))
             AND NOT (COUNTRY = ''New Zealand'' AND LEFT(RLPostCode,2) IN (''76'', ''80'', ''60'', ''69''))
        THEN 1
        ELSE 0
    END AS IsEligiblePER,

    -- Replace nulls with zero for base values
    COALESCE(TotalBase1, 0) AS TotalBase1,
    COALESCE(TotalBase2, 0) AS TotalBase2,
    COALESCE(TotalBase3, 0) AS TotalBase3,
    COALESCE(TotalBase4, 0) AS TotalBase4,

    -- Calculate total base
    (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) AS TotalBase,

    -- StandBase and peril proportions
    CASE
        WHEN (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) > 0 THEN
            (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) -
            (COALESCE(StormBase, 0) + COALESCE(CycloneBase, 0) + COALESCE(BushFireBase, 0) + COALESCE(EarthquakeBase, 0))
        ELSE 0
    END AS StandBase,

    CASE
        WHEN (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) > 0 THEN
            (
                (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) -
                (COALESCE(StormBase, 0) + COALESCE(CycloneBase, 0) + COALESCE(BushFireBase, 0) + COALESCE(EarthquakeBase, 0))
            ) /
            (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0))
        ELSE 0
    END AS Standard,

    CASE
        WHEN (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) > 0 THEN
            COALESCE(StormBase, 0) / 
            (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0))
        ELSE 0
    END AS Storm,

    CASE
        WHEN (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) > 0 THEN
            COALESCE(CycloneBase, 0) / 
            (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0))
        ELSE 0
    END AS Cyclone,

    CASE
        WHEN (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) > 0 THEN
            COALESCE(BushFireBase, 0) / 
            (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0))
        ELSE 0
    END AS BushFire,

    CASE
        WHEN (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0)) > 0 THEN
            COALESCE(EarthquakeBase, 0) / 
            (COALESCE(TotalBase1, 0) + COALESCE(TotalBase2, 0) + COALESCE(TotalBase3, 0) + COALESCE(TotalBase4, 0))
        ELSE 0
    END AS Earthquake

FROM Policy_Sample_BSP_01;

----------------------------------------CLAIM_SAMPLE_BSP-------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIM_SAMPLE_BSP AS
            SELECT DISTINCT
             clm.Claim_Number  AS ClaimNumber       
           , Sam.expiringid_p
           ,Sam.CMLNUMBER
        FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.claim AS clm
       INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file AS ins ON clm.Policy_id = ins.insurance_file_cnt            
       INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk AS Risk ON clm.Risk_type_id = Risk.risk_cnt
       INNER JOIN Policy_Sample_BSP AS Sam ON Sam.policynumber = TRIM(ins.insurance_ref)
                                             AND Risk.risk_number = Sam.risknumber
          AND CAST(clm.Reported_date AS DATE) > current_date() - 366
         AND clm.is_dirty = 0
        ORDER BY clm.Claim_Number;

-------------------------------------------CLAIM_COVER_BSP_01-------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIM_COVER_BSP_01 AS
SELECT DISTINCT 
    t0.claimnumber
	,t0.ExpiringID_P
    ,t0.cmlnumber
	,t3.RSBusinessBuildings
	,t3.RSBusinessContents
	,t3.RSBurglary
	,t3.RSMoney
	,t3.RSEngineering
	,t3.RSBusiness
	,t3.RSGeneralProperty
	,t3.RSGoodsInTransit
	,t3.RSPublicLiability
	,t3.RSProductsLiability
	,t3.RSProfessional
	,t3.RSLegalExpenses
	,t3.RSTaxAudit
	,t3.RSCommercial
	,t3.RSCustomer
	,t3.RSUnspecified
	,t3.RSFleet
	,MAX(t3.CBPCLMS_Policy_Binder_id) AS MAX_PB
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.claim AS t1
INNER JOIN CLAIM_SAMPLE_BSP AS t0 ON (t0.claimnumber = T1.Claim_Number)
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link AS T2 ON (T1.Claim_id = T2.claim_id)
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbpclms_riskselection AS T3 ON (T2.gis_policy_link_id = T3.CBPCLMS_Policy_Binder_id)
GROUP BY t0.claimnumber
     ,t0.ExpiringID_P
     ,t0.cmlnumber
	,t3.RSBusinessBuildings
	,t3.RSBusinessContents
	,t3.RSBurglary
	,t3.RSMoney
	,t3.RSEngineering
	,t3.RSBusiness
	,t3.RSGeneralProperty
	,t3.RSGoodsInTransit
	,t3.RSPublicLiability
	,t3.RSProductsLiability
	,t3.RSProfessional
	,t3.RSLegalExpenses
	,t3.RSTaxAudit
	,t3.RSCommercial
	,t3.RSCustomer
	,t3.RSUnspecified
	,t3.RSFleet;

-------------------------------CLAIM_COVER_BSP_02---------------------------------------


 CREATE OR REPLACE TABLE CLAIM_COVER_BSP_02 AS
SELECT DISTINCT
    CS.*,
    SUBSTR(t2.ReserveType, 1, 2) AS Coverage,
    ROUND(SUM(t2.InitialReserve) + SUM(t2.RevisedReserve)) AS COST
FROM Aggne.Dev.VW_PRD_T5_EXTERNAL_AGGNE_PURE_SNAPSHOT_claims t2
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.claim t1 
    ON t2.ID = t1.Claim_id
INNER JOIN CLAIM_COVER_BSP_01 CS
    ON CS.ClaimNumber = t1.Claim_Number
   AND t1.Claim_id = (
        SELECT MAX(t3.Claim_id)
        FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.claim t3
        WHERE t1.Claim_Number = t3.Claim_Number
    )
GROUP BY 
    cs.claimnumber
    ,cs.EXPIRINGID_P
    ,cs.cmlnumber
    ,cs.RSBusinessBuildings
    ,cs.RSBusinessContents
	,cs.RSBurglary
	,cs.RSMoney
	,cs.RSEngineering
	,cs.RSBusiness
	,cs.RSGeneralProperty
	,cs.RSGoodsInTransit
	,cs.RSPublicLiability
	,cs.RSProductsLiability
	,cs.RSProfessional
	,cs.RSLegalExpenses
	,cs.RSTaxAudit
	,cs.RSCommercial
	,cs.RSCustomer
	,cs.RSUnspecified
	,cs.RSFleet
    ,cs.max_pb
    ,Coverage
ORDER BY 
    cs.claimnumber, 
    COST;


-------------------------------------------CLAIM_COVER_BSP_03----------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIM_COVER_BSP_03 AS
SELECT
    -- Map Coverage codes according to SAS logic
    CASE
        WHEN Coverage = ''BU'' THEN ''BG''
        WHEN Coverage = ''PF'' THEN ''PI''
        WHEN Coverage = ''FL'' THEN ''FV''
        ELSE Coverage
    END AS Coverage,

    -- COST adjustments based on Coverage type
    COST
    + CASE WHEN Coverage = ''BB'' THEN RSBusinessBuildings ELSE 0 END
    + CASE WHEN Coverage = ''BC'' THEN RSBusinessContents ELSE 0 END
    + CASE WHEN Coverage = ''BG'' THEN RSBurglary ELSE 0 END
    + CASE WHEN Coverage = ''MY'' THEN RSMoney ELSE 0 END
    + CASE WHEN Coverage = ''EN'' THEN RSEngineering ELSE 0 END
    + CASE WHEN Coverage = ''BI'' THEN RSBusiness ELSE 0 END
    + CASE WHEN Coverage = ''GP'' THEN RSGeneralProperty ELSE 0 END
    + CASE WHEN Coverage = ''GT'' THEN RSGoodsInTransit ELSE 0 END
    + CASE WHEN Coverage = ''PP'' THEN RSPublicLiability + RSProductsLiability ELSE 0 END
    + CASE WHEN Coverage = ''PI'' THEN RSProfessional ELSE 0 END
    + CASE WHEN Coverage = ''LE'' THEN RSLegalExpenses ELSE 0 END
    + CASE WHEN Coverage = ''TA'' THEN RSTaxAudit ELSE 0 END
    + CASE WHEN Coverage = ''CM'' THEN RSCommercial ELSE 0 END
    + CASE WHEN Coverage = ''CV'' THEN RSCustomer ELSE 0 END
    + CASE WHEN Coverage = ''SV'' THEN RSUnspecified ELSE 0 END
    + CASE WHEN Coverage = ''FV'' THEN RSFleet ELSE 0 END
    AS COST,
    ClaimNumber,
    ExpiringID_P,
    cmlnumber
FROM CLAIM_COVER_BSP_02
ORDER BY ClaimNumber, COST;

-----------------------------------CLAIM_COVER_BSP--------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIM_COVER_BSP AS
SELECT ClaimNumber,
       Coverage,
       ExpiringID_P,
       cmlnumber
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ClaimNumber ORDER BY COST ASC) AS rn
    FROM CLAIM_COVER_BSP_03
)
WHERE rn = 1;

--------------------------------CLAIM_PAYMENT_BSP----------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIM_PAYMENT_BSP AS
    SELECT
        t1.Claim_Number AS ClaimNumber,
        ROUND(SUM(t2.initialreserve + t2.revisedreserve - t2.paidtodate)) AS Reserves,
        ROUND(SUM(t2.paidtodate)) AS PaidToDate
    FROM Aggne.Dev.VW_PRD_T5_EXTERNAL_AGGNE_PURE_SNAPSHOT_claims t2
    JOIN (
        SELECT
            Claim_id,
            Claim_Number,
            ROW_NUMBER() OVER (PARTITION BY Claim_Number ORDER BY Claim_id DESC) AS rn
        FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM
    ) t1
        ON t2.ID = t1.Claim_id
        AND t1.rn = 1
    JOIN AGGNE.DEV.CLAIM_SAMPLE_BSP CS 
        ON CS.ClaimNumber = t1.Claim_Number
    GROUP BY t1.Claim_Number;


-----------------------------------CLAIM_RECEIPT_BSP_01------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIM_RECEIPT_BSP_01 AS
    SELECT DISTINCT
           t2.Claim_Number AS ClaimNumber,
           COALESCE(t1.Amount, 0) - COALESCE(t1.tax_amount, 0) AS Recovered_TEMP
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Claim_Receipt t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM t2 
            ON t2.Claim_id = t1.claim_id
    INNER JOIN CLAIM_SAMPLE_BSP CS 
            ON CS.ClaimNumber = t2.Claim_Number
    ORDER BY t2.Claim_Number;

-------------------------------------------CLAIM_RECEIPT_BSP---------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIM_RECEIPT_BSP AS
    SELECT 
        t1.ClaimNumber,
        TO_DECIMAL(SUM(t1.Recovered_TEMP), 11, 0) AS Recovered
    FROM CLAIM_RECEIPT_BSP_01 t1
    GROUP BY t1.ClaimNumber;

-----------------------------------------CLAIMS_BSP_01-------------------------------------------------------

CREATE OR REPLACE TRANSIENT TABLE CLAIMS_BSP_01 AS
SELECT 
    COALESCE(S.claimNumber, C.claimNumber, P.claimNumber, R.claimNumber) AS ClaimNumber,
    -- Select columns from each source as needed
    S.EXPIRINGID_P,
    S.cmlnumber,
    C.COVERAGE,
    P.PAIDTODATE,
    P.RESERVES,
    COALESCE(R.Recovered, 0) AS Recovered
FROM CLAIM_SAMPLE_BSP S
FULL OUTER JOIN CLAIM_COVER_BSP C 
    ON S.ClaimNumber = C.ClaimNumber
FULL OUTER JOIN CLAIM_PAYMENT_BSP P 
    ON COALESCE(S.ClaimNumber, C.ClaimNumber) = P.ClaimNumber
FULL OUTER JOIN CLAIM_RECEIPT_BSP R 
    ON COALESCE(S.ClaimNumber, C.ClaimNumber, P.ClaimNumber) = R.ClaimNumber;

--------------------------------------CLAIMS_BSP_02--------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIMS_BSP_02 AS
SELECT
    ExpiringID_P,
    cmlnumber,
    Coverage,
    ROUND(SUM(Reserves) + SUM(PaidToDate) - SUM(Recovered), 0) AS Incurred,
    COUNT(*) AS Count
FROM CLAIMS_BSP_01
GROUP BY
    ExpiringID_P,
    cmlnumber,
    Coverage;

------------------------------------------CLAIMS_BSP_03A---------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIMS_BSP_03A AS
SELECT *
FROM CLAIMS_BSP_02
PIVOT (
    SUM(INCURRED)      -- corresponds to VAR Incurred
    FOR COVERAGE IN (   -- corresponds to ID Coverage
        ''BC'', ''FV'', ''TA'', ''EN'', ''BB'', ''CV'', ''BI'', ''PI'', ''MY'', ''GP'', ''CM'', ''PP'', ''LE'', ''BG'', ''GT'', ''SV'' -- <== replace with actual coverage values
    ) 
) AS P
(ExpiringID_P,cmlnumber,count,BC, FV, TA, EN, BB, CV, BI, PI, MY, GP, CM, PP, LE, BG, GT, SV);

----------------------------CLAIMS_BSP_03---------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIMS_BSP_03 AS
SELECT
    BB AS BBClmIncd,
    BC AS BCClmIncd,
    BG AS BGClmIncd,
    MY AS MYClmIncd,
    EN AS ENClmIncd,
    BI AS BIClmIncd,
    GP AS GPClmIncd,
    GT AS GTClmIncd,
    PP AS PPClmIncd,
    PI AS PIClmIncd,
    LE AS LEClmIncd,
    TA AS TAClmIncd,
    CM AS CMClmIncd,
    CV AS CVClmIncd,
    SV AS SVClmIncd,
    FV AS FVClmIncd,
    expiringid_p,
    cmlnumber
FROM CLAIMS_BSP_03a;

----------------------------------------------CLAIMS_BSP_04a-----------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIMS_BSP_04a AS
SELECT *
FROM (
    SELECT *
    FROM CLAIMS_BSP_02
) 
PIVOT (
    SUM(Count) FOR Coverage IN (''BC'', ''FV'', ''TA'', ''EN'', ''BB'', ''CV'', ''BI'', ''PI'', ''MY'', ''GP'', ''CM'', ''PP'', ''LE'', ''BG'', ''GT'', ''SV'' )
) AS P
(ExpiringID_P,cmlnumber,count,BC, FV, TA, EN, BB, CV, BI, PI, MY, GP, CM, PP, LE, BG, GT, SV);

--------------------------------------CLAIMS_BSP_04-----------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CLAIMS_BSP_04 AS
SELECT
    expiringid_p,
    cmlnumber,
    BB AS BBClmCnt,
    BC AS BCClmCnt,
    BG AS BGClmCnt,
    MY AS MYClmCnt,
    EN AS ENClmCnt,
    BI AS BIClmCnt,
    GP AS GPClmCnt,
    GT AS GTClmCnt,
    PP AS PPClmCnt,
    PI AS PIClmCnt,
    LE AS LEClmCnt,
    TA AS TAClmCnt,
    CM AS CMClmCnt,
    CV AS CVClmCnt,
    SV AS SVClmCnt,
    FV AS FVClmCnt
FROM CLAIMS_BSP_04a;

---------------------------Policy_Sample_BSP--Sorting----------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Policy_Sample_BSP AS
SELECT *
FROM Policy_Sample_BSP
ORDER BY ExpiringID_P;

------------------------------------COVERAGE_BSP---------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE COVERAGE_BSP AS
SELECT 
    P.*,
    COALESCE(c03.BBClmIncd, 0) AS BBClmIncd,
    COALESCE(c03.BCClmIncd, 0) AS BCClmIncd,
    COALESCE(c03.BGClmIncd, 0) AS BGClmIncd,
    COALESCE(c03.MYClmIncd, 0) AS MYClmIncd,
    COALESCE(c03.ENClmIncd, 0) AS ENClmIncd,
    COALESCE(c03.BIClmIncd, 0) AS BIClmIncd,
    COALESCE(c03.GPClmIncd, 0) AS GPClmIncd,
    COALESCE(c03.GTClmIncd, 0) AS GTClmIncd,
    COALESCE(c03.PPClmIncd, 0) AS PPClmIncd,
    COALESCE(c03.PIClmIncd, 0) AS PIClmIncd,
    COALESCE(c03.LEClmIncd, 0) AS LEClmIncd,
    COALESCE(c03.TAClmIncd, 0) AS TAClmIncd,
    COALESCE(c03.CMClmIncd, 0) AS CMClmIncd,
    COALESCE(c03.CVClmIncd, 0) AS CVClmIncd,
    COALESCE(c03.SVClmIncd, 0) AS SVClmIncd,
    COALESCE(c03.FVClmIncd, 0) AS FVClmIncd,
    COALESCE(c04.BBClmCnt, 0) AS BBClmCnt,
    COALESCE(c04.BCClmCnt, 0) AS BCClmCnt,
    COALESCE(c04.BGClmCnt, 0) AS BGClmCnt,
    COALESCE(c04.MYClmCnt, 0) AS MYClmCnt,
    COALESCE(c04.ENClmCnt, 0) AS ENClmCnt,
    COALESCE(c04.BIClmCnt, 0) AS BIClmCnt,
    COALESCE(c04.GPClmCnt, 0) AS GPClmCnt,
    COALESCE(c04.GTClmCnt, 0) AS GTClmCnt,
    COALESCE(c04.PPClmCnt, 0) AS PPClmCnt,
    COALESCE(c04.PIClmCnt, 0) AS PIClmCnt,
    COALESCE(c04.LEClmCnt, 0) AS LEClmCnt,
    COALESCE(c04.TAClmCnt, 0) AS TAClmCnt,
    COALESCE(c04.CMClmCnt, 0) AS CMClmCnt,
    COALESCE(c04.CVClmCnt, 0) AS CVClmCnt,
    COALESCE(c04.SVClmCnt, 0) AS SVClmCnt,
    COALESCE(c04.FVClmCnt, 0) AS FVClmCnt
FROM Policy_Sample_BSP p
LEFT JOIN claims_bsp_03 c03 ON p.ExpiringID_P = c03.ExpiringID_P
LEFT JOIN claims_bsp_04 c04 ON p.ExpiringID_P = c04.ExpiringID_P;

---------------------------------------------Output_Coverage_BSP------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Output_Coverage_BSP AS 
   SELECT t1.PolicyNumber, 
          t1.ExpiringID_P,
          t1.cmlnumber,
          t1.ExpiryDate, 
          t1.Country, 
          t1.Product, 
          t1.BBExpPrem, 
          t1.BBClmIncd, 
          t1.BBClmCnt, 
          t1.BCExpPrem, 
          t1.BCClmIncd, 
          t1.BCClmCnt, 
          t1.BGExpPrem, 
          t1.BGClmIncd, 
          t1.BGClmCnt, 
          t1.MYExpPrem, 
          t1.MYClmIncd, 
          t1.MYClmCnt, 
          t1.ENExpPrem, 
          t1.ENClmIncd, 
          t1.ENClmCnt, 
          t1.BIExpPrem, 
          t1.BIClmIncd, 
          t1.BIClmCnt, 
          t1.GPExpPrem, 
          t1.GPClmIncd, 
          t1.GPClmCnt, 
          t1.GTExpPrem, 
          t1.GTClmIncd, 
          t1.GTClmCnt, 
          t1.PPExpPrem, 
          t1.PPClmIncd, 
          t1.PPClmCnt, 
          t1.PIExpPrem, 
          t1.PIClmIncd, 
          t1.PIClmCnt, 
          t1.LEExpPrem, 
          t1.LEClmIncd, 
          t1.LEClmCnt, 
          t1.TAExpPrem, 
          t1.TAClmIncd, 
          t1.TAClmCnt, 
          t1.CMExpPrem, 
          t1.CMNoVehs,
          t1.TowNoVehs,
          t1.CMClmIncd, 
          t1.CMClmCnt, 
          t1.CVExpPrem, 
          t1.CVClmIncd, 
          t1.CVClmCnt, 
          t1.SVExpPrem, 
          t1.SVNoVehs,
          t1.SVClmIncd, 
          t1.SVClmCnt, 
          t1.FVExpPrem, 
          t1.FVNoVehs,
          t1.FVClmIncd, 
          t1.FVClmCnt,
          t1.IsEligiblePER
      FROM COVERAGE_BSP t1;

-------------------------------------Rego_BSP_01-----------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Rego_BSP_01  AS 
SELECT DISTINCT PB.PolicyNumber 
              , PB.ExpiringID_P 
              , PB.CMLNUMBER
              , PB.ExpiryDate  
              , t1.RegistrationNumber AS RegoNumber
              , CS.ClaimNumber
              , t1.ClaimOn
           FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBPCLMS_CMVS AS t1
             INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_POLICY_LINK AS t2 ON (t1.CBPCLMS_Policy_Binder_id = t2.gis_policy_link_id)
             INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM AS t3 ON (t2.claim_id = t3.Claim_id)
             INNER JOIN CLAIM_COVER_BSP AS CS ON (CS.ClaimNumber = t3.Claim_Number)
             INNER JOIN Policy_Sample_BSP AS PB ON (CS.ExpiringID_P = PB.ExpiringID_P)
          WHERE CS.Coverage = ''CM''
            AND t1.CBPCLMS_Policy_Binder_id = 
              (
             SELECT MAX(t4.CBPCLMS_Policy_Binder_id)
               FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBPCLMS_CMVS AS t4
                INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_POLICY_LINK AS t5 ON (t4.CBPCLMS_Policy_Binder_id = t5.gis_policy_link_id)
                INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM AS t6 ON (t5.claim_id = t6.Claim_id )
                 WHERE t3.Claim_Number = t6.Claim_Number
            );
------------------------------------------Rego_BSP_01---Sorting----------------------------------
CREATE OR REPLACE TRANSIENT TABLE Rego_BSP_01 AS
SELECT *
FROM Rego_BSP_01
ORDER BY ClaimNumber, ClaimOn;

--------------------------------------------------Rego_BSP_02--------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Rego_BSP_02 AS
SELECT *
FROM (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY ClaimNumber ORDER BY ClaimOn DESC) AS rn
    FROM Rego_BSP_01 r
) t
WHERE rn = 1;

----------------------------------------Output_Rego_BSP--------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Output_Rego_BSP  AS 
         SELECT  DISTINCT
                t1.PolicyNumber 
               , t1.ExpiringID_P
               , t1.cmlnumber
               , t1.ExpiryDate  
               , t1.RegoNumber
                , COUNT(t1.RegoNumber) AS ClaimCount
           FROM Rego_BSP_02 AS t1
         GROUP BY t1.PolicyNumber 
                , t1.ExpiringID_P 
                , t1.cmlnumber
                , t1.ExpiryDate
                , t1.RegoNumber;

-----------------------------------ExpiringPrem_BSP----------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE ExpiringPrem_BSP AS 
   SELECT DISTINCT t2.PolicyNumber,
             t2.ExpiringID_P,
             t2.cmlnumber,
             t2.Standard,
             t2.Storm,
             t2.Cyclone,
             t2.BushFire,
             t2.Earthquake,
             SUBSTR(t4.code,3,2) AS Section_01,
             SUBSTR(t4.code,5,4) AS Sub_Section_01, 
          TO_DECIMAL(t1.annual_premium, 11, 2) AS annual_premium_
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.rating_section t1
    INNER JOIN COVERAGE_BSP t2 ON (t1.risk_cnt = t2.risk_cnt)
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Rating_Section_Type t3 ON (t1.rating_section_type_id = t3.rating_section_type_id)
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Class_Of_Business t4 ON (t3.caption_id = t4.caption_id
                                            AND t4.is_deleted = 0)
    WHERE t1.original_flag = 0
      AND SUBSTR(t3.code,1,5) <> ''NZFSC'';

-----------------------------------------------Output_SubCover_BSP---------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Output_SubCover_BSP AS
SELECT 
    PolicyNumber,
    ExpiringID_P,
    cmlnumber,
    CASE
        WHEN Section_01 = ''BB'' AND Sub_Section_01 = ''ACNN'' THEN ''BBACC_SD''
        WHEN Section_01 = ''BB'' AND Sub_Section_01 = ''FLNN'' THEN ''BBFLD_SD''
        WHEN Section_01 = ''BB'' AND Sub_Section_01 = ''GLNN'' THEN ''BBGLS_SD''
        WHEN Section_01 = ''BB'' AND Sub_Section_01 = ''LNNN'' THEN ''BBLND_SD''
        WHEN Section_01 = ''BB'' AND Sub_Section_01 = ''LONN'' THEN ''BBLOR_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''ACNN'' THEN ''BCACC_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''CUNN'' THEN ''BCCUV_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''EMNN'' THEN ''BCEMP_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''FLNN'' THEN ''BCFLD_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''LNNN'' THEN ''BCLND_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''MFNN'' THEN ''BCMFL_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''PENN'' THEN ''BCPER_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''SWNN'' THEN ''BCSWP_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''VINN'' THEN ''BCVIS_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''WINN'' THEN ''BCWIS_SD''
        WHEN Section_01 = ''BC'' AND Sub_Section_01 = ''CWNN'' THEN ''BGCUV_SD''
        WHEN Section_01 = ''BI'' AND Sub_Section_01 = ''ACNN'' THEN ''BIACR_SD''
        WHEN Section_01 = ''BI'' AND Sub_Section_01 = ''CLNN'' THEN ''BICLP_SD''
        WHEN Section_01 = ''BI'' AND Sub_Section_01 = ''ICNN'' THEN ''BIICW_SD''
        WHEN Section_01 = ''CM'' AND Sub_Section_01 = ''CONN'' THEN ''CMCOR_SD''
        WHEN Section_01 = ''CM'' AND Sub_Section_01 = ''FTNN'' THEN ''CMFTL_SD''
        WHEN Section_01 = ''CM'' AND Sub_Section_01 = ''OHNN'' THEN ''CMOHL_SD''
        WHEN Section_01 = ''CM'' AND Sub_Section_01 = ''PCNN'' THEN ''CMPCH_SD''
        WHEN Section_01 = ''CM'' AND Sub_Section_01 = ''TFNN'' THEN ''CMTFT_SD''
        WHEN Section_01 = ''CM'' AND Sub_Section_01 = ''TPNN'' THEN ''CMTPO_SD''
        WHEN Section_01 = ''CM'' AND Sub_Section_01 = ''ULNN'' THEN ''CMULG_SD''
        WHEN Section_01 = ''CV'' AND Sub_Section_01 = ''STNN'' THEN ''CVSTD_SD''
        WHEN Section_01 = ''EN'' AND Sub_Section_01 = ''CENN'' THEN ''ENCEE_SD''
        WHEN Section_01 = ''EN'' AND Sub_Section_01 = ''CWNN'' THEN ''ENCWS_SD''
        WHEN Section_01 = ''EN'' AND Sub_Section_01 = ''DENN'' THEN ''ENDET_SD''
        WHEN Section_01 = ''EN'' AND Sub_Section_01 = ''ICNN'' THEN ''ENICW_SD''
        WHEN Section_01 = ''EN'' AND Sub_Section_01 = ''LONN'' THEN ''ENLOI_SD''
        WHEN Section_01 = ''EN'' AND Sub_Section_01 = ''MANN'' THEN ''ENMAC_SD''
        WHEN Section_01 = ''FL'' AND Sub_Section_01 = ''CONN'' THEN ''FLCOR_SD''
        WHEN Section_01 = ''FL'' AND Sub_Section_01 = ''FTNN'' THEN ''FLFTL_SD''
        WHEN Section_01 = ''FL'' AND Sub_Section_01 = ''OHNN'' THEN ''FLOHL_SD''
        WHEN Section_01 = ''FL'' AND Sub_Section_01 = ''TCNN'' THEN ''FLTCH_SD''
        WHEN Section_01 = ''FL'' AND Sub_Section_01 = ''TFNN'' THEN ''FLTFT_SD''
        WHEN Section_01 = ''FL'' AND Sub_Section_01 = ''TPNN'' THEN ''FLTPO_SD''
        WHEN Section_01 = ''FL'' AND Sub_Section_01 = ''ULNN'' THEN ''FLULG_SD''

        WHEN Section_01 = ''GP'' AND Sub_Section_01 = ''FLNN'' THEN ''GPFLD_SD''
        WHEN Section_01 = ''GP'' AND Sub_Section_01 = ''OTNN'' THEN ''GPOTH_SD''
        WHEN Section_01 = ''GP'' AND Sub_Section_01 = ''SPNN'' THEN ''GPSPS_SD''
        WHEN Section_01 = ''GP'' AND Sub_Section_01 = ''STNN'' THEN ''GPSPT_SD''
        WHEN Section_01 = ''GP'' AND Sub_Section_01 = ''UNNN'' THEN ''GPUNS_SD''
        WHEN Section_01 = ''GP'' AND Sub_Section_01 = ''UTNN'' THEN ''GPUNT_SD''
        WHEN Section_01 = ''GT'' AND Sub_Section_01 = ''STNN'' THEN ''GTSTD_SD''
        WHEN Section_01 = ''LE'' AND Sub_Section_01 = ''STNN'' THEN ''LESTD_SD''
    
        WHEN Section_01 = ''MY'' AND Sub_Section_01 = ''EMNN'' THEN ''MYEMP_SD''
        WHEN Section_01 = ''MY'' AND Sub_Section_01 = ''MBNN'' THEN ''MYMSB_SD''
        WHEN Section_01 = ''MY'' AND Sub_Section_01 = ''MINN'' THEN ''MYMIT_SD''
        WHEN Section_01 = ''MY'' AND Sub_Section_01 = ''MONN'' THEN ''MYMSO_SD''
        WHEN Section_01 = ''MY'' AND Sub_Section_01 = ''MPNN'' THEN ''MYMPC_SD''
        WHEN Section_01 = ''MY'' AND Sub_Section_01 = ''MSNN'' THEN ''MYMSS_SD''

        WHEN Section_01 = ''PF'' AND Sub_Section_01 IN (''CANN'',''CCNN'') THEN ''PFCCA_SD''
        WHEN Section_01 = ''PF'' AND Sub_Section_01 = ''CSNN'' THEN ''PFCSL_SD''
        WHEN Section_01 = ''PF'' AND Sub_Section_01 = ''RONN'' THEN ''PFROL_SD''
        WHEN Section_01 = ''PF'' AND Sub_Section_01 = ''STNN'' THEN ''PFSTD_SD''
        WHEN Section_01 = ''PF'' AND Sub_Section_01 = ''VHNN'' THEN ''PFVHB_SD''
    
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''CANN'' THEN ''PPCCA_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''CCNN'' THEN ''PPCCC_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''DFNN'' THEN ''PPDFW_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''GHNN'' THEN ''PPGHO_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''LHNN'' THEN ''PPLHA_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''PONN'' THEN ''PPPOO_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''RFNN'' THEN ''PPRFW_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''RUNN'' THEN ''PPRUF_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''SBNN'' THEN ''PPSTB_SD''
        WHEN Section_01 = ''PP'' AND Sub_Section_01 = ''STNN'' THEN ''PPSTD_SD''
    
        WHEN Section_01 = ''TA'' AND Sub_Section_01 = ''STNN'' THEN ''TASTD_SD''
    
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''ALNN'' THEN ''BGALC_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''CUNN'' THEN ''BGCUV_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''ETNN'' THEN ''BGEMP_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''FRNN'' THEN ''BGFRM_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''MFNN'' THEN ''BGMFL_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''MVNN'' THEN ''BGMVH_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''PENN'' THEN ''BGPER_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''STNN'' THEN ''BGSTD_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''TFNN'' THEN ''BGTFT_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''TONN'' THEN ''BGTOB_SD''
        WHEN Section_01 = ''TF'' AND Sub_Section_01 = ''WTNN'' THEN ''BGCUV_SD''
    
        WHEN Section_01 = ''UV'' AND Sub_Section_01 = ''GLNN'' THEN ''SVGLS_SD''
        WHEN Section_01 = ''UV'' AND Sub_Section_01 = ''TPNN'' THEN ''SVTPO_SD''
        
    END AS Sub_Coverage,
    annual_premium_ AS ExpPremium
FROM ExpiringPrem_BSP
WHERE Section_01 || Sub_Section_01 NOT IN (''BBSTNN'', ''BCSTNN'', ''BCHANN'', ''UVSTNN'', ''BIGRNN'', ''CMCMNN'', ''FLCMNN'')
AND  Sub_Coverage <> ''''

UNION ALL

-- BB-STNN multiple outputs
SELECT
    PolicyNumber, ExpiringID_P, cmlnumber,  ''BBSTD_BF'' AS Sub_Coverage,
    GREATEST(1, annual_premium_ * BushFire) AS ExpPremium
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BB'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT
    PolicyNumber, ExpiringID_P, cmlnumber,  ''BBSTD_CY'', GREATEST(1, annual_premium_ * Cyclone)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BB'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT
    PolicyNumber, ExpiringID_P, cmlnumber,  ''BBSTD_EQ'', GREATEST(1, annual_premium_ * Earthquake)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BB'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT
    PolicyNumber, ExpiringID_P, cmlnumber,  ''BBSTD_SD'', GREATEST(1, annual_premium_ * Standard)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BB'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT
    PolicyNumber, ExpiringID_P, cmlnumber,  ''BBSTD_ST'', GREATEST(1, annual_premium_ * Storm)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BB'' AND Sub_Section_01 = ''STNN''

-- BC-STNN multiple outputs
UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber,  ''BCSTD_BF'', GREATEST(1, annual_premium_ * BushFire)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BC'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BCSTD_CY'', GREATEST(1, annual_premium_ * Cyclone)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BC'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BCSTD_EQ'', GREATEST(1, annual_premium_ * Earthquake)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BC'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BCSTD_SD'', GREATEST(1, annual_premium_ * Standard)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BC'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BCSTD_ST'', GREATEST(1, annual_premium_ * Storm)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BC'' AND Sub_Section_01 = ''STNN''

-- BC-HANN
UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BCHAL_SD'', annual_premium_ * Standard
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BC'' AND Sub_Section_01 = ''HANN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BCHAL_ST'', annual_premium_ * (1 - Standard)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BC'' AND Sub_Section_01 = ''HANN''

-- UV-STNN
UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''SVCMP_SD'', (annual_premium_ * Standard) * 2/3
FROM ExpiringPrem_BSP
WHERE Section_01 = ''UV'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''SVLIA_SD'', (annual_premium_ * Standard) * 1/3
FROM ExpiringPrem_BSP
WHERE Section_01 = ''UV'' AND Sub_Section_01 = ''STNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''SVSTD_ST'', (annual_premium_ * (1 - Standard))
FROM ExpiringPrem_BSP
WHERE Section_01 = ''UV'' AND Sub_Section_01 = ''STNN''

--BI GRINN--
UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BIGRP_BF'', (annual_premium_ * BushFire)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BI'' AND Sub_Section_01 = ''GRNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BIGRP_CY'', (annual_premium_ * Cyclone)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BI'' AND Sub_Section_01 = ''GRNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BIGRP_EQ'', (annual_premium_ * Earthquake)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BI'' AND Sub_Section_01 = ''GRNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BIGRP_SD'', (annual_premium_ * Standard)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BI'' AND Sub_Section_01 = ''GRNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''BIGRP_ST'', (annual_premium_ * Storm)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''BI'' AND Sub_Section_01 = ''GRNN''
 

-- CM-CMNN
UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''CMCMP_SD'', (annual_premium_  * 2/3)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''CM'' AND Sub_Section_01 = ''CMNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''CMLIA_SD'', (annual_premium_ * 1/3)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''CM'' AND Sub_Section_01 = ''CMNN''


-- FL-CMNN
UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''FLCMP_SD'', (annual_premium_  * 2/3)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''FL'' AND Sub_Section_01 = ''CMNN''

UNION ALL
SELECT PolicyNumber, ExpiringID_P, cmlnumber, ''FLLIA_SD'', (annual_premium_ * 1/3)
FROM ExpiringPrem_BSP
WHERE Section_01 = ''FL'' AND Sub_Section_01 = ''CMNN'';

---------------------------------ExpPremium_BSP_A-------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE ExpPremium_BSP_A AS 
   SELECT t1.PolicyNumber,
          t1.ExpiringID_P, 
          t1.cmlnumber,
          NULL AS  Vehicle_ID,
          ''SU'' AS Coverage,
            (SUM(TO_DECIMAL(t1.ExpPremium, 11, 2)))  AS ExpPremium
     FROM Output_SubCover_BSP t1
    GROUP BY t1.PolicyNumber,
             t1.ExpiringID_P,
             t1.cmlnumber;
----------------------------------ExpPremium_BSP_B----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE ExpPremium_BSP_B AS 
   SELECT t1.PolicyNumber,
          t1.ExpiringID_P, 
          t1.cmlnumber,
           NULL AS  Vehicle_ID,
          SUBSTR(t1.Sub_Coverage,1,2) AS Coverage,
            (SUM(TO_DECIMAL(t1.ExpPremium, 11, 2))) AS ExpPremium
      FROM Output_SubCover_BSP t1
     WHERE SUBSTR(t1.Sub_Coverage,1,2) <> ''CM''
     GROUP BY t1.PolicyNumber,
              t1.ExpiringID_P,
              t1.cmlnumber,
           SUBSTR(t1.Sub_Coverage,1,2);
--------------------------------------------ExpPremium_BSP_C-----------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE ExpPremium_BSP_C AS 
   SELECT DISTINCT t2.PolicyNumber,
          t1.CBP_Policy_Binder_id AS ExpiringID_P, 
          t2.cmlnumber,
          RTRIM(t1.CBP_VEHICLEDETAIL_id) AS Vehicle_ID, 
             ''CM'' AS Coverage,
          TO_DECIMAL(t1.CMNetContribution, 11, 2) AS ExpPremium
      FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL t1
     INNER JOIN Output_SubCover_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.CMNetContribution > 0;

-------------------------------------ExpPremium_BSP-----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE ExpPremium_BSP AS
SELECT * FROM ExpPremium_BSP_A
UNION ALL
SELECT * FROM ExpPremium_BSP_B
UNION ALL
SELECT * FROM ExpPremium_BSP_C;

------------------------------------BB_ADJUST-----------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE BB_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P, 
         t2.cmlnumber,
          NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
          t1.AJAdjustmentNote,
             ''BB'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSBB t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
    WHERE t1.AJRecurringIndicator = 1
    ORDER BY t1.CBP_Policy_Binder_id;

----------------------------------------BC_ADJUST----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE BC_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P, 
         t2.cmlnumber,
         NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''BC'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSBC t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
    ORDER BY t1.CBP_Policy_Binder_id;

--------------------------------------BG_ADJUST-----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE BG_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P,
        t2.cmlnumber,
        NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''TF'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSBG t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
    ORDER BY t1.CBP_Policy_Binder_id;

--------------------------------------BI_ADJUST------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE BI_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P, 
          t2.cmlnumber,
          NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''BI'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSBI t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
    ORDER BY t1.CBP_Policy_Binder_id; 

-----------------------------------CM_ADJUST--------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CM_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P, 
          t2.cmlnumber,
          RTRIM(t1.CBP_VEHICLEDETAIL_id) AS Vehicle_ID, 
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''CM'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSCM t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
    ORDER BY t1.CBP_Policy_Binder_id;

-----------------------------------CV_ADJUST------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE CV_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P,  
        t2.cmlnumber,
        NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''CV'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSCV t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
    ORDER BY t1.CBP_Policy_Binder_id;

------------------------------------EN_ADJUST---------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE  EN_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P,
         t2.cmlnumber,
         NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''EN'' AS Coverage 
      FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSEN t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id; 

--------------------------------------GP_ADJUST-----------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE GP_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P, 
          t2.cmlnumber,
         NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''GP'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSGP t1
    INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

---------------------------------GT_ADJUST-----------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE GT_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P,  
        t2.cmlnumber,
         NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''GT'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSGT t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

--------------------------------------LE_ADJUST----------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE LE_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P, 
         t2.cmlnumber,
         NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''LE'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSLE t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

--------------------------------------MY_ADJUST------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE MY_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P,  
         t2.cmlnumber,
         NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''MY'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSMY t1
    INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

-------------------------------------PF_ADJUST---------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE PF_ADJUST AS                     
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P, 
          t2.cmlnumber,
          NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''PF'' AS Coverage         
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSPI t1
    INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

-------------------------------------PP_ADJUST---------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE PP_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P, 
        t2.cmlnumber,
        NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''PP'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSPP t1
    INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

----------------------------------SU_ADJUST_BSP---------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE SU_ADJUST_BSP AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P,
         t2.cmlnumber,
          NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''SU'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSSU t1
    INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

----------------------------------------TA_ADJUST--------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE TA_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P,
         t2.cmlnumber,
         NULL AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''TA'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSTA t1
    INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

------------------------------------------SV_ADJUST-----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE SV_ADJUST AS 
   SELECT DISTINCT t1.CBP_Policy_Binder_id AS ExpiringID_P,  
         NULL AS Vehicle_ID,
         t2.cmlnumber,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
             t1.AJAdjustmentNote,
             ''SV'' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_ADJUSTMENTSUV t1
     INNER JOIN ExpPremium_BSP t2 ON (t1.CBP_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
      ORDER BY t1.CBP_Policy_Binder_id;

--------------------------------------------Adjustments_BSP_A-----------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE Adjustments_BSP_A AS
SELECT *
FROM (
    SELECT * FROM BB_ADJUST
    UNION ALL
    SELECT * FROM BC_ADJUST
    UNION ALL
    SELECT * FROM BI_ADJUST
    UNION ALL
    SELECT * FROM CM_ADJUST
    UNION ALL
    SELECT * FROM CV_ADJUST
    UNION ALL
    SELECT * FROM EN_ADJUST
    UNION ALL
    SELECT * FROM GP_ADJUST
    UNION ALL
    SELECT * FROM GT_ADJUST
    UNION ALL
    SELECT * FROM LE_ADJUST
    UNION ALL
    SELECT * FROM MY_ADJUST
    UNION ALL
    SELECT * FROM PF_ADJUST
    UNION ALL
    SELECT * FROM PP_ADJUST
    UNION ALL
    SELECT * FROM TA_ADJUST
    UNION ALL
    SELECT * FROM SV_ADJUST
    UNION ALL
    SELECT * FROM BG_ADJUST
    UNION ALL
    SELECT * FROM SU_ADJUST_BSP
)
WHERE AJAdjustmentPercent <> 0;

----------------------------------------------Adjustments_BSP_B---------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Adjustments_BSP_B AS 
   SELECT DISTINCT t1.ExpiringID_P,
          t1.cmlnumber,
          t1.Vehicle_ID,
          t1.Coverage, 
            (SUM(TO_DECIMAL(t1.AJAdjustmentPercent, 11, 6)))  AS SUM_Adjustments
     FROM ADJUSTMENTS_BSP_A t1
    GROUP BY t1.ExpiringID_P,
             t1.Vehicle_ID,
             t1.cmlnumber,
             t1.Coverage;
             
--------------------------------------Adjustments_BSP_A-----Sorting---------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE Adjustments_BSP_A AS
SELECT *
FROM Adjustments_BSP_A
ORDER BY ExpiringID_P, cmlnumber,Vehicle_ID, Coverage;

---------------------------------------Adjustments_BSP_B------Sorting------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE Adjustments_BSP_B AS
SELECT *
FROM Adjustments_BSP_B
ORDER BY ExpiringID_P, cmlnumber, Vehicle_ID, Coverage;

------------------------------------------Adjustments_BSP-----------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE Adjustments_BSP AS
    SELECT DISTINCT
        COALESCE(a.ExpiringID_P, b.ExpiringID_P) AS ExpiringID_P,
        COALESCE(a.cmlnumber, b.cmlnumber) AS cmlnumber,
         COALESCE(a.VEHICLE_ID, b.VEHICLE_ID) AS VEHICLE_ID,
        COALESCE(a.Coverage, b.Coverage) AS Coverage,
        COALESCE(a.AJAdjustmentPercent, b.SUM_Adjustments) AS AJAdjustmentPercent,
        a.AJAdjustmentValue, a.AJType, a.AJAdjustmentNote, b.sum_adjustments
    FROM Adjustments_BSP_A a
    FULL OUTER JOIN Adjustments_BSP_B b
        ON a.ExpiringID_P = b.ExpiringID_P
       AND a.Coverage = b.Coverage
    WHERE COALESCE(a.AJAdjustmentPercent, b.SUM_Adjustments) <> 0
    AND b.SUM_Adjustments <> 0;

--------------------------------ExpPremium_BSP---Sorting----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE ExpPremium_BSP AS
SELECT DISTINCT *
FROM ExpPremium_BSP
ORDER BY ExpiringID_P, cmlnumber, VEHICLE_ID,Coverage;

--------------------------------Adjustments_BSP---Sorting-------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE Adjustments_BSP AS
SELECT DISTINCT *
FROM Adjustments_BSP
ORDER BY ExpiringID_P, cmlnumber, VEHICLE_ID, Coverage;

---------------------------------Adjustments_BSP_Out------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE ADJUSTMENTS_BSP_OUT AS
SELECT DISTINCT
    e.policynumber,
    e.ExpiringID_P,
    e.cmlnumber,
    e.Coverage,
    e.Vehicle_ID,
    e.ExpPremium,
    a.SUM_Adjustments,
    a.AJAdjustmentPercent,
    a.AJAdjustmentNote,

    /* UWAdjust calculation with divide-by-zero protection */
    CASE 
        WHEN (100 + a.SUM_Adjustments) <> 0 
            THEN TO_DECIMAL((e.ExpPremium / (100 + a.SUM_Adjustments)) * a.AJAdjustmentPercent,11,2)
        ELSE NULL
    END AS UWAdjust

FROM ExpPremium_BSP e
LEFT JOIN Adjustments_BSP a
    ON  trim(e.ExpiringID_P) = trim(a.ExpiringID_P)
      AND trim(e.Coverage)     = trim(a.Coverage)
     AND coalesce(e.Vehicle_ID,'''')    = coalesce(a.Vehicle_ID,'''')
    AND e.cmlnumber = a.cmlnumber;

--SELECT TOP 10 * FROM ADJUSTMENTS_BSP_OUT

---------------------------------------Output_UWAdjust_BSP-------------------------------------------------------------------
   CREATE OR REPLACE TRANSIENT TABLE Output_UWAdjust_BSP AS 
   SELECT DISTINCT
          t1.policynumber AS PolicyNumber,
          t1.ExpiringID_P  AS ExpiringID_P,
          t1.cmlnumber AS CMLNumber,
          t1.Vehicle_ID  AS Vehicle_ID, 
          t1.Coverage, 
          t1.AJAdjustmentNote  AS UWAdjustNote, 
          t1.UWAdjust AS UWAdjustAmount
     FROM Adjustments_BSP_Out t1;


-----Expirying Measure @end@----


CREATE OR REPLACE TRANSIENT TABLE  AGGNE.DEV.ACCOUNT_HANDLER AS 

SELECT * FROM PRD_T5_EXTERNAL_AGGNE.RISK.ACCOUNT_HANDLER;
 
 
CREATE OR REPLACE TRANSIENT TABLE  AGGNE.DEV.CLAUSES AS 

SELECT * FROM  PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE;
 

CREATE OR REPLACE TABLE AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD AS
WITH payment_method_per AS (
    SELECT DISTINCT
        t1.PER_POLICY_BINDER_ID AS POLICY_BINDER_ID,
        t7.SCHEMENAME           AS PAYMENT_METHOD
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RiskSelection t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder t2
        ON t1.RLEXPIRINGPOLICYBINDERID = t2.PER_POLICY_BINDER_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t3
        ON t2.GIS_POLICY_LINK_ID = t3.GIS_POLICY_LINK_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t4
        ON t4.RISK_CNT = t3.RISK_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t6
        ON t4.RISK_CNT = t6.RISK_CNT
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PFPREMIUMFINANCE t7
        ON t6.INSURANCE_FILE_CNT = t7.INSURANCE_FILE_CNT
),
payment_method_cbp AS (
    SELECT DISTINCT
        t1.CBP_POLICY_BINDER_ID AS POLICY_BINDER_ID,
        t7.SCHEMENAME           AS PAYMENT_METHOD
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.cbp_riskselection t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_Policy_Binder t2
        ON t1.RLEXPIRINGPOLICYBINDERID = t2.CBP_POLICY_BINDER_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.gis_policy_link t3
        ON t2.GIS_POLICY_LINK_ID = t3.GIS_POLICY_LINK_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk  t4
        ON t4.RISK_CNT = t3.RISK_ID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t6
        ON t4.RISK_CNT = t6.RISK_CNT
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PFPREMIUMFINANCE t7
        ON t6.INSURANCE_FILE_CNT = t7.INSURANCE_FILE_CNT
),
combined AS (
    SELECT * FROM payment_method_per
    UNION ALL
    SELECT * FROM payment_method_cbp
)
SELECT
    POLICY_BINDER_ID,
    CASE
        WHEN SUBSTR(PAYMENT_METHOD, 1, 1) = ''M'' THEN ''Monthly''
        WHEN SUBSTR(PAYMENT_METHOD, 1, 1) = ''A'' THEN ''Annually''
        ELSE PAYMENT_METHOD
    END AS PAYMENT_METHOD
FROM combined;





---------------------------------------------1.10@@ManualReferral_Notes_PER@@end@@----------------------------------------------------------------------------------------

--Personal protection adjustments and expiring premiums sp
  CALL AGGNE.DEV.SP_PP_ADJ_EXP_PREM();


  
v_result := OBJECT_CONSTRUCT(
    ''SPName'', ''SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD'',
    ''LoadStatus'', ''SUCCESS'',
    ''RowsInserted'', SQLROWCOUNT,
    ''ExecutedAt'', CURRENT_TIMESTAMP()
);

RETURN v_result;
END';