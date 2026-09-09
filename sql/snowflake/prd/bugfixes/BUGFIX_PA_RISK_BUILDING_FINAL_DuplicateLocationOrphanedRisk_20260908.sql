-- ============================================================================
-- BUGFIX: PA_RISK_BUILDING_FINAL sends an orphaned "phantom" risk when a
-- location is duplicated upstream
-- Date: 2026-09-08
-- SAFE_MODE -- NOT APPLIED. Review and confirm before running.
--
-- Live DDL pulled today (2026-09-08) via GET_DDL -- see
-- docs/bp_mapping/Duplicate_Location_Rows_OrphanedRisk_Investigation_20260907.md
-- for the full investigation this fix is based on.
-- ============================================================================
--
-- CONTEXT
-- Found via P00029683: request had 5 <risk type="Building"> blocks
-- (LocationNumber 1-5) but only 4 <location> blocks (1-4) -- risk #5
-- referenced a location that was never defined.
--
-- CONFIRMED NOT a PURE data issue -- checked the raw PURE snapshot directly
-- (PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT, via risk -> cbp_policy_binder for
-- CBP_Policy_Binder_id=2538201): exactly 1 row. PURE is clean.
--
-- The duplicate is introduced in the external load that populates
-- AGGNE.PRD.policyattach_bp (no Snowflake SP writes to that table -- checked
-- all 33 PRD + 94 DEV procedures) -- that's a separate issue for whoever
-- owns that load process, out of scope for this fix.
--
-- THIS fix addresses a *different*, Snowflake-side problem: even granting
-- that a duplicate location row reaches this view, it should never have
-- produced an orphaned risk. The bug is local to this one view.
--
-- ROOT CAUSE (confirmed via live GET_DDL, this exact view)
-- CTE1's RISKNUMBER is computed as:
--   ROW_NUMBER() OVER (PARTITION BY T2.ACTUALID ORDER BY t2.ID ASC)
-- wrapped inside a `SELECT DISTINCT`. ROW_NUMBER() assigns every row --
-- including a true duplicate with otherwise identical data -- its own
-- unique value. That means the wrapping SELECT DISTINCT can never collapse
-- a real duplicate: the two copies only differ by their own RISKNUMBER
-- output, which is exactly what ROW_NUMBER() is designed to make different.
-- The duplicate location gets counted as an extra risk with no matching
-- location definition.
--
-- FIX
-- Replace ROW_NUMBER() with DENSE_RANK() ordered on ADDRESSDESCRIPTION
-- (the location's own identity) instead of the row's own id:
--   DENSE_RANK() OVER (PARTITION BY T2.ACTUALID ORDER BY ADDRESSDESCRIPTION ASC)
-- DENSE_RANK() assigns the SAME rank to rows that tie on the ORDER BY
-- expression -- so two rows for the same location (same ADDRESSDESCRIPTION)
-- now get the same RISKNUMBER. Once RISKNUMBER stops being artificially
-- unique for true duplicates, the whole CTE1 row becomes byte-for-byte
-- identical between the two copies (confirmed: all their other source
-- columns already match) -- and the SELECT DISTINCT that was ALREADY
-- wrapping this CTE finally does what it was presumably meant to do,
-- collapsing the duplicate down to one row on its own. No new
-- deduplication step was added -- this just stops ROW_NUMBER() from
-- defeating the DISTINCT that already exists.
--
-- Confirmed RISKNUMBER is not used as a join key anywhere else in this
-- view (the T2-T7 target joins key on T1.PUREPOLICYNUMBER, i.e. T2.ID --
-- untouched by this change), so this is an isolated, safe change.
--
-- Only ONE line changes (marked -- FIXED below); everything else in this
-- view is byte-for-byte the live DDL pulled today. Re-pull GET_DDL and
-- diff before applying if any time has passed.
-- ============================================================================

create or replace view AGGNE.PRD.PA_RISK_BUILDING_FINAL(
	PUREPOLICYNUMBER,
	ACTUALID,
	LEGACYPOLICYNUMBER,
	ADDRESSDESCRIPTION,
	RISKNUMBER,
	LOCATIONANZSICCODE,
	ROOFCONSTRUCTION_FINAL,
	YEARBUILDINGCONSTRUCTED,
	FLOORCONSTRUCTION_FINAL,
	MAINWALLCONSTRUCTION_FINAL,
	ALARMSYSTEMINSTALLED_FINAL,
	SECURITYCAMERAS_FINAL,
	TWOMETERHIGHPERIMETERFENCE_FINAL,
	SECURITYBOLLARDS_FINAL,
	PATROLLEDBYASECURITYGUARD_FINAL,
	DEADLOCKSINSTALLED_FINAL,
	EXTERIORSECURITYLIGHTING_FINAL,
	BARSORGRILLSINSTALLED_FINAL,
	TWENTYFOURHOURSATTENDANCE_FINAL,
	CONDITIONOFROOF,
	CONDITIONOFBUILDING,
	YEARLASTREWIRED,
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
	SMASHREPAIR_CONDITION,
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
	RISK_BUILDING,
	RISK_BI,
	RISK_BG,
	RISK_MONEY,
	RISK_EN,
	RISK_BC,
	UW_COMBINE,
	LOAD_DATE
) as
WITH CTE1 AS (
    SELECT distinct
       T2.ID  AS PUREPOLICYNUMBER,
       T2.actualid,
        T2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        ADDRESSDESCRIPTION,
        -- t1.RISKNUMBER,
            -- FIXED (2026-09-08, duplicate-location orphaned-risk bug):
            -- was ROW_NUMBER() OVER (PARTITION BY T2.ACTUALID ORDER BY t2.ID ASC)
            -- -- gave every row (including true duplicates) a unique value,
            -- so the SELECT DISTINCT below could never collapse a real
            -- duplicate location. DENSE_RANK() ordered on the location's
            -- own identity (ADDRESSDESCRIPTION) gives true duplicates the
            -- SAME RISKNUMBER, letting the existing DISTINCT collapse them
            -- as intended.
            CAST(CAST(DENSE_RANK() OVER (PARTITION BY T2.ACTUALID ORDER BY ADDRESSDESCRIPTION ASC)AS NUMBER(10,0)) AS VARCHAR) AS RISKNUMBER,
        T2.LOCATIONANZSICCODE,
        CASE  WHEN ROOFCONSTRUCTION='Asbestos' THEN 'Asbestos'
         WHEN ROOFCONSTRUCTION ='Concrete' THEN 'Concrete'
         WHEN ROOFCONSTRUCTION ='Fibro (Non- Asbestos)' THEN 'FibroNonAsbestos'
         WHEN ROOFCONSTRUCTION ='Iron' THEN 'Iron'
         WHEN ROOFCONSTRUCTION ='Other' THEN 'Other'
         WHEN ROOFCONSTRUCTION ='Some Asbestos and Brick' THEN 'SomeAsbestosAndBrick'
         WHEN ROOFCONSTRUCTION ='Tile' THEN 'Tile'
         WHEN ROOFCONSTRUCTION ='Tin' THEN 'Tin'
         WHEN ROOFCONSTRUCTION ='Wood' THEN 'Wood' ELSE ROOFCONSTRUCTION END  AS ROOFCONSTRUCTION_FINAL,
        CAST(YEARBUILDINGCONSTRUCTED  AS VARCHAR) AS YEARBUILDINGCONSTRUCTED,
        CASE  WHEN FLOORCONSTRUCTION ='Concrete' THEN 'Concrete'
              WHEN FLOORCONSTRUCTION ='Other' THEN 'Other'
              WHEN FLOORCONSTRUCTION ='Wood' THEN 'Wood'
              WHEN FLOORCONSTRUCTION ='Wood - Concrete footings' THEN 'WoodConcretefootings' ELSE FLOORCONSTRUCTION END AS FLOORCONSTRUCTION_FINAL,
        CASE  WHEN MAINWALLCONSTRUCTION ='Asbestos' THEN 'Asbestos'
              WHEN MAINWALLCONSTRUCTION ='Brick Veneer' THEN 'BrickVeneer'
              WHEN MAINWALLCONSTRUCTION ='Concrete' THEN 'Concrete'
              WHEN MAINWALLCONSTRUCTION ='Double Brick' THEN 'DoubleBrick'
              WHEN MAINWALLCONSTRUCTION ='Fibro (Non-Asbestos)' THEN 'FibroNonAsbestos'
              WHEN MAINWALLCONSTRUCTION ='Iron' THEN 'Iron'
              WHEN MAINWALLCONSTRUCTION ='Other' THEN 'Other'
              WHEN MAINWALLCONSTRUCTION ='Some Asbestos and Brick' THEN 'SomeAsbestosAndBrick'
              WHEN MAINWALLCONSTRUCTION ='Steel' THEN 'Steel'
              WHEN MAINWALLCONSTRUCTION ='Wood' THEN 'Wood' ELSE  MAINWALLCONSTRUCTION END AS MAINWALLCONSTRUCTION_FINAL ,
        CASE WHEN ALARMSYSTEMINSTALLED='Local - Audible Only'  THEN  'LocalAudibleOnly'
             WHEN ALARMSYSTEMINSTALLED='Local - Monitored'  THEN  'LocalMonitored'
             WHEN ALARMSYSTEMINSTALLED='Mobile Mechanic - No base location'  THEN  'MobileMechanicNobaseLocation'
             WHEN ALARMSYSTEMINSTALLED='Monitored - Back to base'  THEN  'MonitoredBacktobase'
             WHEN ALARMSYSTEMINSTALLED='Monitored - Security'  THEN  'MonitoredSecurity'
             WHEN ALARMSYSTEMINSTALLED='None'  THEN  'None'
             WHEN ALARMSYSTEMINSTALLED='Other'  THEN  'Other' ELSE ALARMSYSTEMINSTALLED END AS ALARMSYSTEMINSTALLED_FINAL,
         CASE WHEN  CAST(COALESCE(SECURITYCAMERAS,'0') AS VARCHAR) = 'Yes' THEN CAST(CAST(1 AS NUMBER(5,0))AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(5,0))AS VARCHAR) END AS SECURITYCAMERAS_FINAL,
         CASE WHEN  CAST(COALESCE(TWOMETERHIGHPERIMETERFENCE,'0') AS VARCHAR) = 'Yes' THEN CAST(CAST(1 AS NUMBER(5,0))AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(5,0))AS VARCHAR) END AS TWOMETERHIGHPERIMETERFENCE_FINAL,
        CASE WHEN  CAST(COALESCE(SECURITYBOLLARDS,'0') AS VARCHAR) = 'Yes' THEN CAST(CAST(1 AS NUMBER(5,0))AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(5,0))AS VARCHAR) END AS SECURITYBOLLARDS_FINAL,
        CASE WHEN  CAST(COALESCE(PATROLLEDBYASECURITYGUARD,'0') AS VARCHAR) = 'Yes' THEN CAST(CAST(1 AS NUMBER(5,0))AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(5,0))AS VARCHAR) END AS PATROLLEDBYASECURITYGUARD_FINAL,
        CASE WHEN  CAST(COALESCE(DEADLOCKSINSTALLED,'0') AS VARCHAR) = 'Yes' THEN CAST(CAST(1 AS NUMBER(5,0))AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(5,0))AS VARCHAR) END AS DEADLOCKSINSTALLED_FINAL,
        CASE WHEN  CAST(COALESCE(EXTERIORSECURITYLIGHTING,'0') AS VARCHAR) = 'Yes' THEN CAST(CAST(1 AS NUMBER(5,0))AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(5,0))AS VARCHAR) END AS EXTERIORSECURITYLIGHTING_FINAL,
        CASE WHEN  CAST(COALESCE(BARSORGRILLSINSTALLED,'0') AS VARCHAR) = 'Yes' THEN CAST(CAST(1 AS NUMBER(5,0))AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(5,0))AS VARCHAR) END AS BARSORGRILLSINSTALLED_FINAL,
        CASE WHEN  CAST(COALESCE(TWENTYFOURHOURSATTENDANCE,'0') AS VARCHAR) = 'Yes' THEN CAST(CAST(1 AS NUMBER(5,0))AS VARCHAR) ELSE CAST(CAST(0 AS NUMBER(5,0))AS VARCHAR) END AS TWENTYFOURHOURSATTENDANCE_FINAL,
        CASE WHEN CONDITIONOFROOF ='Asbestos and poor condition' THEN 'Asbestosandpoorcondition'
             WHEN CONDITIONOFROOF ='Tin and poor condition' THEN 'Tinandpoorcondition'
             WHEN CONDITIONOFROOF ='Asbestos and good condition' THEN 'Asbestosandgoodcondition'
             WHEN CONDITIONOFROOF ='Tin and good condition' THEN 'Tinandgoodcondition' ELSE CONDITIONOFROOF END AS CONDITIONOFROOF,
         CASE WHEN CONDITIONOFBUILDING ='> 1990 - good condition' THEN 'Greaterthan1990-goodcondition'
              WHEN CONDITIONOFBUILDING ='< 1990 - good condition' THEN 'Lessthan1990-goodcondition'
              WHEN CONDITIONOFBUILDING ='> 1990 - poor condition' THEN 'Greaterthan1990-poorcondition'
              WHEN CONDITIONOFBUILDING ='< 1990 - poor condition' THEN 'Lessthan1990-goodcondition' ELSE CONDITIONOFBUILDING END AS CONDITIONOFBUILDING,
         CAST(YEARLASTREWIRED AS VARCHAR) AS YEARLASTREWIRED,
         CASE WHEN ADEQUATESECOVSTORAGE='TRUE' THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS ADEQUATESECOVSTORAGE,
         CASE WHEN HIGHRISKSPECIALISEDEQUIP='TRUE' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS HIGHRISKSPECIALISEDEQUIP,
         CAST(DETAILSHIGHRISKSPECEQUIP AS VARCHAR) AS DETAILSHIGHRISKSPECEQUIP,
         CASE WHEN INADEQUATEFUELSTORAGE ='TRUE' THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS INADEQUATEFUELSTORAGE,
         CASE WHEN MORETHANFEWTYRESTACK ='TRUE' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS MORETHANFEWTYRESTACK,
         CASE WHEN VOLTYRESTACK ='LESS THAN 100' THEN 'Lessthan100'
              WHEN VOLTYRESTACK ='100-250' THEN '100-250'
              WHEN VOLTYRESTACK ='250-500' THEN '250-500'
              WHEN VOLTYRESTACK ='More than 500' THEN 'MoreThan500' ELSE VOLTYRESTACK END AS VOLTYRESTACK
         ,CASE WHEN VOLTYRESTACKIN ='LESS THAN 100' THEN 'Lessthan100'
               WHEN VOLTYRESTACKIN ='100-250' THEN '100-250'
               WHEN VOLTYRESTACKIN ='250-500' THEN '250-500'
               WHEN VOLTYRESTACKIN ='More than 500' THEN 'MoreThan500' ELSE VOLTYRESTACKIN END AS VOLTYRESTACKIN,
         CASE WHEN TYRESTOREDOUTORDERLY='TRUE' THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS TYRESTOREDOUTORDERLY
         ,CASE WHEN EXCOILRESIDUEOUT='TRUE' THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS EXCOILRESIDUEOUT
         ,CASE WHEN SATISFACTORYRISKMITIGATION='TRUE' THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS SATISFACTORYRISKMITIGATION
         ,CAST(CAST(NOOFSPRAYBOOTHS AS NUMBER(3,0))AS VARCHAR) AS NOOFSPRAYBOOTHS
         ,LOWER(SMASHREPAIR_CONDITION) AS SMASHREPAIR_CONDITION
         ,CASE WHEN SURRAREAFREEOFHEATWORK='TRUE' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS SURRAREAFREEOFHEATWORK
         ,LOWER(SURRAREAHOUSEKEEP) AS SURRAREAHOUSEKEEP
         ,LOWER(MIXINGRMHOUSEKEEP) AS MIXINGRMHOUSEKEEP
         ,CAST(CAST(AGEOFOLDESTBOOTH AS NUMBER(3,0))AS VARCHAR) AS AGEOFOLDESTBOOTH
         ,CAST(CAST(REPLACE(REPLACECOST,',','') AS NUMBER(15,0))AS VARCHAR) AS REPLACECOST
         , CASE WHEN REGULARSERVICELOG='TRUE' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS REGULARSERVICELOG
         ,CASE WHEN INTERIORWALLPROTECTIONUSED='TRUE'  THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS INTERIORWALLPROTECTIONUSED
         ,CASE WHEN EXHAUSTFANREPLACED='TRUE' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS EXHAUSTFANREPLACED
        ,CASE WHEN FLOORCONDITION ='Excessive oil residues' THEN 'ExcessiveOilResidues'
               WHEN FLOORCONDITION ='Average' THEN 'Average'
               WHEN FLOORCONDITION ='Good' THEN 'Good'
               WHEN FLOORCONDITION ='Excellent' THEN 'Excellent' ELSE FLOORCONDITION END AS FLOORCONDITION
         ,CASE WHEN DISMANTLEAREAHOUSEKEEP ='Excessive clutter present' THEN 'ExcessiveClutterPresent'
               WHEN DISMANTLEAREAHOUSEKEEP ='Small amounts of clutter present' THEN 'SmallAmountsOfClutterPresent'
               WHEN DISMANTLEAREAHOUSEKEEP ='No clutter present' THEN 'NoClutterPresent'
               WHEN DISMANTLEAREAHOUSEKEEP ='Immaculate housekeeping' THEN 'ImmaculateHousekeeping'  ELSE DISMANTLEAREAHOUSEKEEP END  AS DISMANTLEAREAHOUSEKEEP
         ,CASE WHEN DEFUELLOCATION ='Occurs inside main building' THEN 'OccursInsideMainBuilding'
               WHEN DEFUELLOCATION ='Defueling occurs outside before dismantling' THEN 'DefuelingOccursOutsideBeforeDismantling'
               WHEN DEFUELLOCATION ='Designated dismantling only building' THEN 'DesignatedDismantlingOnlyBuilding' ELSE DEFUELLOCATION END AS DEFUELLOCATION
         ,CASE WHEN DISMANTLELOC ='In main building & near stock storage area' THEN 'Inainbuildingandnearstockstoragearea'
              WHEN DISMANTLELOC ='In main building with large clearance' THEN 'Inmainbuildingwithlargeclearence'
              WHEN DISMANTLELOC ='Outside main building' THEN 'Outsidemainbuilding'
              WHEN DISMANTLELOC ='Designated dismantling only building' THEN 'Designateddismantleingonlybuilding'
              WHEN DISMANTLELOC ='No dismantling on site' THEN 'Nodismantlingonsite' ELSE DISMANTLELOC END AS DISMANTLELOC
         ,CASE WHEN HOISTSUSED='Yes' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS HOISTSUSED
         ,CASE WHEN FIREEQUIPNEAR ='No items present' THEN 'Noitemspresent'
               WHEN FIREEQUIPNEAR ='Extinguishers on floor' THEN 'Extinguishersonfloor'
               WHEN FIREEQUIPNEAR ='Extinguishers hung in open spaces' THEN 'Extinguishershunginopenspaces'
               WHEN FIREEQUIPNEAR ='Fire detection/suppression items' THEN 'Firedetectionorsuppressionitems' ELSE FIREEQUIPNEAR END AS FIREEQUIPNEAR
         ,CASE WHEN METALRECYCLEONSITE='TRUE' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS METALRECYCLEONSITE
         ,CASE WHEN METALRECYCLEINSIDE='TRUE' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS METALRECYCLEINSIDE
         ,CASE WHEN STOCKHOUSEKEEPING ='Overstocked & untidy' THEN 'Overstockanduntidy'
          WHEN STOCKHOUSEKEEPING ='Neatly on pallets/floor' THEN 'Neatlyonpalletsorfloor'
          WHEN STOCKHOUSEKEEPING ='Neat/mostly stacked on racks' THEN 'Neatormostlystackedonracks'
          WHEN STOCKHOUSEKEEPING ='Very neat/all stacked on racks' THEN 'Veryneatorallstackedonracks'  ELSE STOCKHOUSEKEEPING END AS STOCKHOUSEKEEPING
         ,CASE WHEN TYRESBATTERIESHOUSEKEEP ='Throughout the yard' THEN 'Throughttheyard'
               WHEN TYRESBATTERIESHOUSEKEEP ='Designated area near main building' THEN 'Designatedareanearmainbuilding'
               WHEN TYRESBATTERIESHOUSEKEEP ='Designated area +10m from main building' THEN 'Designatedareaplus10mfrommainbuilding' ELSE TYRESBATTERIESHOUSEKEEP END AS TYRESBATTERIESHOUSEKEEP
         ,CASE WHEN EVSTORAGE ='Inside the main building' THEN 'Insidethemainbuilding'
               WHEN EVSTORAGE ='Outside & near the main building' THEN 'Outsideandnearthemainbuilding'
               WHEN EVSTORAGE ='Designated area +10m from main building' THEN 'Designatedareaplus10mfrommainbuilding'
               WHEN EVSTORAGE ='EV''s never stocked' THEN 'Evsneverstocked'  ELSE EVSTORAGE end AS EVSTORAGE
         ,CASE WHEN VEHICLESSTACKED ='Stacked precariously' THEN 'Stackedprecariously'
               WHEN VEHICLESSTACKED ='Some stacked with some racked' THEN 'Somestackedwithsomeracked'
               WHEN VEHICLESSTACKED ='Most stacked with some racked' THEN 'Moststackedwithsomeracked'
               WHEN VEHICLESSTACKED ='All racked' THEN 'Allracked' ELSE VEHICLESSTACKED END AS VEHICLESSTACKED
         ,CASE WHEN FUELSTORE ='Not removed prior to storage. Inside the main building' THEN 'NotRemovedPriorToStorageInsideTheMainBuilding'
               WHEN FUELSTORE ='Outside & near the main building' THEN 'OutsideAndNearTheMainBuilding'
               WHEN FUELSTORE ='Outside & +10m from main building' THEN 'Outside10mFromMainBuilding'  ELSE FUELSTORE END AS FUELSTORE
         ,TO_VARCHAR(CAST(AVGNOVEHSSTORED AS NUMBER(4,0))) AS  AVGNOVEHSSTORED
         ,CASE WHEN YARDFLOORHOUSEKEEP ='Caked oil all over' THEN 'Cakedoilallover'
               WHEN YARDFLOORHOUSEKEEP ='Caked oil in places' THEN 'Cakedoilinplaces'
               WHEN YARDFLOORHOUSEKEEP ='Some oil' THEN 'Someoil'
               WHEN YARDFLOORHOUSEKEEP ='Immaculate yard' THEN 'Immaculateyard' ELSE YARDFLOORHOUSEKEEP END AS YARDFLOORHOUSEKEEP
         ,CASE WHEN CLEARLANDSQM ='<150sqm' THEN 'Lessthan150sqm'
               WHEN CLEARLANDSQM ='<300sqm' THEN 'Lessthan300sqm'
               WHEN CLEARLANDSQM ='<450sqm' THEN 'Lessthan450sqm'
               WHEN CLEARLANDSQM ='<450sqm' THEN 'Lessthan600sqm' ELSE CLEARLANDSQM END AS CLEARLANDSQM
    FROM  AGGNE.PRD.LOCATION_01_POLICYATTACH_IDENTIFIER T2
    -- inner join AGGNE.PRD.ACCOUNT_LOC_POLICYATTACH t1 on t1.actualid=t2.actualid
    -- AND T1.PUREPOLICYNUMBER=T2.ID
),CTE_LISTAGG AS(
SELECT
  ID,
  LISTAGG(CASE WHEN ITR_TYPE = 'PA_Risk_Building_Combine_UW' THEN payload END, '\n') AS UW,
  CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM AGGNE.PRD.PA_RISK_BUILDING_FINAL_TARGET
WHERE ITR_TYPE IN ('PA_Risk_Building_Combine_UW')
GROUP BY ID,CAST(LOAD_DATE AS DATE)
)
SELECT DISTINCT  T1.*
,
CASE WHEN T2.PAYLOAD IS NULL THEN '<coverage>
	<Type>Building</Type>
    <Description>Business Buildings</Description>
    <Indicator>0</Indicator>
    </coverage>' ELSE T2.PAYLOAD END AS RISK_BUILDING,
CASE WHEN T3.PAYLOAD IS NULL THEN '<coverage>
	<Type>BusinessInterruption</Type>
    <Description>Business Interruption</Description>
    <Indicator>0</Indicator>
    </coverage>' ELSE T3.PAYLOAD END AS RISK_BI,
CASE WHEN T4.PAYLOAD IS NULL THEN '<coverage>
	<Type>Burglary</Type>
    <Description>Burglary</Description>
    <Indicator>0</Indicator>
    </coverage>' ELSE T4.PAYLOAD END AS RISK_BG,
CASE WHEN T5.PAYLOAD IS NULL THEN '<coverage>
	<Type>Money</Type>
    <Description>Money</Description>
    <Indicator>0</Indicator>
    </coverage>' ELSE T5.PAYLOAD  END AS RISK_Money,
CASE WHEN T6.PAYLOAD IS NULL THEN '<coverage>
	<Type>Engineering</Type>
    <Description>Engineering</Description>
    <Indicator>0</Indicator>
    </coverage>' ELSE T6.PAYLOAD END AS RISK_EN,
CASE WHEN T7.PAYLOAD IS NULL THEN '<coverage>
	<Type>ContentsAndStocks</Type>
    <Description>Business Contents</Description>
    <Indicator>0</Indicator>
    </coverage>' ELSE T7.PAYLOAD END  AS RISK_BC,
T8.UW AS UW_COMBINE,
CAST(GETDATE() AS DATE) AS LOAD_DATE
FROM CTE1 T1
LEFT JOIN CTE_LISTAGG T8  ON  T1.PUREPOLICYNUMBER=T8.ID
LEFT JOIN AGGNE.PRD.PA_RISK_BUILDING_TARGET             T2 ON T1.PUREPOLICYNUMBER = T2.ID AND T2.ITR_TYPE = 'BP_RISK_Building_Cov_Building'
LEFT JOIN AGGNE.PRD.PA_RISK_BUILDING_BI_TARGET     T3 ON T1.PUREPOLICYNUMBER = T3.ID AND T3.ITR_TYPE = 'BP_RISK_Building_BI'
LEFT JOIN AGGNE.PRD.PA_RISK_BUILDING_BG_TARGET     T4 ON T1.PUREPOLICYNUMBER = T4.ID AND T4.ITR_TYPE = 'BP_RISK_Building_BG'
LEFT JOIN AGGNE.PRD.PA_RISK_BUILDING_MONEY_TARGET  T5 ON T1.PUREPOLICYNUMBER = T5.ID AND T5.ITR_TYPE = 'BP_RISK_Building_Money'
LEFT JOIN AGGNE.PRD.PA_RISK_BUILDING_EN_TARGET     T6 ON T1.PUREPOLICYNUMBER = T6.ID AND T6.ITR_TYPE = 'BP_RISK_Building_EN'
LEFT JOIN AGGNE.PRD.PA_RISK_BUILDING_BC_TARGET     T7 ON T1.PUREPOLICYNUMBER = T7.ID AND T7.ITR_TYPE = 'BP_RISK_Building_BC'
;


-- ============================================================================
-- VALIDATION (read-only, run before AND after applying)
-- ============================================================================
-- Before: how many distinct policies currently have more risk numbers than
-- distinct addresses (the orphaned-risk symptom), across the whole view --
-- SELECT COUNT(*) FROM (
--     SELECT ACTUALID, COUNT(DISTINCT RISKNUMBER) AS RISK_COUNT, COUNT(DISTINCT ADDRESSDESCRIPTION) AS ADDR_COUNT
--     FROM AGGNE.PRD.PA_RISK_BUILDING_FINAL
--     GROUP BY ACTUALID
--     HAVING RISK_COUNT > ADDR_COUNT
-- );
--
-- After applying, re-run the same query -- expect 0 (RISK_COUNT should never
-- exceed ADDR_COUNT once dedup is working).
--
-- Spot-check P00029683 directly:
-- SELECT PUREPOLICYNUMBER, RISKNUMBER, ADDRESSDESCRIPTION
-- FROM AGGNE.PRD.PA_RISK_BUILDING_FINAL
-- WHERE LEGACYPOLICYNUMBER = 'P00029683';
-- Expected after fix: RISKNUMBER 1-4 only, no 5, and 604 Lower North East Rd
-- appears with only one distinct RISKNUMBER even if the source still has it twice.
-- ============================================================================
