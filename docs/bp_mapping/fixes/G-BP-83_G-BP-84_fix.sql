-- ============================================================================
-- G-BP-83 + G-BP-84 fix — RISK_BUILDING_FINAL (SEQ 55): two dropdown-mapping
-- typos, both copy-paste errors in CASE WHEN branches
--
-- *** SUPERSEDED by fixes/G-BP-83_thru_87_fix.sql *** — a follow-up audit of
-- the view's other dropdown CASE blocks found 3 more bugs (G-BP-85/86/87).
-- Run that file instead; it includes these two fixes plus the new ones.
-- ============================================================================
-- Found during the SEQ 54-55 pass (Building: Final Assembly / UW Combine).
--
-- G-BP-83 — ROOFCONSTRUCTION_FINAL: the WHEN clause checks
-- 'Fibro (Non- Asbestos)' (extra space after the hyphen), but the actual
-- live Pure text is 'Fibro (Non-Asbestos)' (no space) — confirmed by
-- comparing against MAINWALLCONSTRUCTION_FINAL's WHEN clause a few lines
-- below, which has the correct no-space text and works fine. The mismatch
-- means the branch never fires; the raw, unmapped Pure text (with space and
-- parentheses) is sent straight through instead of the clean DC code
-- 'FibroNonAsbestos'. Live check: 29 of 13,824 rows (0.2%) currently show
-- the raw unmapped text in ROOFCONSTRUCTION_FINAL.
--
-- G-BP-84 — CLEARLANDSQM: the 4th WHEN branch duplicates the 3rd branch's
-- condition ('<450sqm') instead of the intended '<600sqm' (matching PL101's
-- DismantlingInput.ClearLandSqm dropdown: <150sqm/<300sqm/<450sqm/<600sqm).
-- A copy-paste error — the '<600sqm' value branch is unreachable, so it
-- would fall through to ELSE and send raw '<600sqm' text instead of
-- 'Lessthan600sqm'. Live check: 0 current rows have '<600sqm' selected (only
-- 'Lessthan150sqm' and NULL exist today) — zero current impact, but a real
-- latent bug fixed here for correctness, consistent with this session's
-- practice of fixing structural defects even at zero current impact.
--
-- Scope: view-only, one view, two CASE branches changed. No config change —
-- SEQ 55 already reads {ROOFCONSTRUCTION_FINAL} and {CLEARLANDSQM} tokens.
-- Everything else in this large view (40+ other fields) is untouched.
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead.
-- Re-pull GET_DDL immediately before applying and diff against this.
-- ============================================================================

create or replace view RISK_BUILDING_FINAL(
	PUREPOLICYNUMBER,
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
	SICCODE,
	LASTSERVICEYEAR,
	RISK_BUILDING,
	RISK_BI,
	RISK_BG,
	RISK_MONEY,
	RISK_EN,
	RISK_BC,
	UW_COMBINE,
	BUILDINGVOLUNTARYEXCESS,
	LOAD_DATE
) as
WITH CTE1 AS (
    SELECT
        CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.cmlnumber) || '|' || TRIM(T2.EXPIRINGID) AS VARCHAR) AS PUREPOLICYNUMBER,
        T2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,
        ADDRESSDESCRIPTION,
        CAST(T3.RISKNUMBER AS VARCHAR) AS RISKNUMBER,
CASE WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%111111%' THEN '111111 - Property Owners Only'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%222222%' THEN '222222 - Vehicles Only'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%281901%' THEN '281901 - Automotive Component Manufacturing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%462301%' THEN '462301 - Motor Vehicle New Part and Accessories Wholesaling'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%524502%' THEN '524502 - Boat Dealers - no Manufacturing - including Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%531103%' THEN '531103 - Agricultural Machinery Dealers - Including Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%531107%' THEN '531107 - Motor Vehicle Dealers - New - excluding Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%531108%' THEN '531108 - Motor Vehicle Dealers - New - including Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%531109%' THEN '531109 - Motor Vehicle Dealers - Used - excluding Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%531110%' THEN '531110 - Motor Vehicle Dealers - Used - including Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%531116%' THEN '531116 - Motor Vehicle Wrecking - Used Parts Reseller'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%531301%' THEN '531301 - Motorcycle Dealers - New and Used - including Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%531302%' THEN '531302 - Trailer and Caravan Dealers'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532101%' THEN '532101 - Service Station - excluding Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532103%' THEN '532103 - Service Station - including Roadhouse - including Servicing'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532201%' THEN '532201 - Automotive Electrical Services'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532301%' THEN '532301 - Body/Smash Repair - Bus, Coach, Trucks and Heavy Machinery'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532302%' THEN '532302 - Body/Smash Repair - Passenger - excluding Bus, Coach, Trucks and Heavy Machinery'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532401%' THEN '532401 - Tyre Retailers and Repairers - excluding Retreading and Remoulding'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532504%' THEN '532504 - Automotive Mechanical Repairs - Mobile Mechanic'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532505%' THEN '532505 - Automotive Mechanical Repairs - Workshop - excluding Smash Repairs'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532901%' THEN '532901 - Automotive Engine Re-Conditioners'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532902%' THEN '532902 - Automotive Exhaust and/or Suspension Specialists'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532903%' THEN '532903 - Automotive Fuel Injection Services'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532904%' THEN '532904 - Automotive LPG Fitters'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532905%' THEN '532905 - Automotive Radiator Repairs'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532908%' THEN '532908 - Automotive Windscreen Installation/Repair'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532909%' THEN '532909 - Automotive Windscreen Tinting'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532912%' THEN '532912 - Motor Vehicle Detailers'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%532913%' THEN '532913 - Tow Truck Operator'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%540000%' THEN '540000 - Automotive Fabrication and Engineering'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%540001%' THEN '540001 - Diesel Mechanic'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%540002%' THEN '540002 - Wrecker – Retailer Only'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%540003%' THEN '540003 - Service Station – excluding Roadhouse'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%600001%' THEN '600001 - Auto Masters'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%600002%' THEN '600002 - Ultra-Tune'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%600003%' THEN '600003 - Tyre Franchise'
WHEN CAST(T2.LOCATIONANZSICCODE AS VARCHAR) like '%774101%' THEN '774101 - Motor Vehicle Hiring'
ELSE NULL
END AS  LOCATIONANZSICCODE,
        CASE  WHEN ROOFCONSTRUCTION='Asbestos' THEN 'Asbestos'
         WHEN ROOFCONSTRUCTION ='Concrete' THEN 'Concrete'
         WHEN ROOFCONSTRUCTION ='Fibro (Non-Asbestos)' THEN 'FibroNonAsbestos'  -- FIXED (G-BP-83): removed stray space, was 'Fibro (Non- Asbestos)'
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
             WHEN ALARMSYSTEMINSTALLED='Other'  THEN  'Other' ELSE 'None' END AS ALARMSYSTEMINSTALLED_FINAL,
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
         CASE WHEN INADEQUATEFUELSTORAGE ='TRUE' THEN cast('Yes' as varchar) ELSE cast('No' as varchar) END AS INADEQUATEFUELSTORAGE,
         CASE WHEN Upper(trim(MORETHANFEWTYRESTACK))='YES'  THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS MORETHANFEWTYRESTACK,
         CASE WHEN VOLTYRESTACK ='LESS THAN 100' THEN 'Lessthan100'
              WHEN VOLTYRESTACK ='100-250' THEN '100-250'
              WHEN VOLTYRESTACK ='250-500' THEN '250-500'
              WHEN VOLTYRESTACK ='More than 500' THEN 'MoreThan500' ELSE VOLTYRESTACK END AS VOLTYRESTACK
         ,CASE WHEN VOLTYRESTACKIN ='LESS THAN 100' THEN 'Lessthan100'
               WHEN VOLTYRESTACKIN ='100-250' THEN '100-250'
               WHEN VOLTYRESTACKIN ='250-500' THEN '250-500'
               WHEN VOLTYRESTACKIN ='More than 500' THEN 'MoreThan500' ELSE VOLTYRESTACKIN END AS VOLTYRESTACKIN,
         CASE WHEN Upper(trim(TYRESTOREDOUTORDERLY))='YES' THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS TYRESTOREDOUTORDERLY
         ,CASE WHEN  Upper(trim(EXCOILRESIDUEOUT))='YES'   THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS EXCOILRESIDUEOUT
         ,CASE WHEN  Upper(trim(SATISFACTORYRISKMITIGATION))='YES' THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS SATISFACTORYRISKMITIGATION
         ,CAST(CAST(NOOFSPRAYBOOTHS AS NUMBER(3,0))AS VARCHAR) AS NOOFSPRAYBOOTHS
         ,LOWER(SMASHREPAIR_CONDITION) AS SMASHREPAIR_CONDITION
         ,CASE WHEN Upper(trim(SURRAREAFREEOFHEATWORK))='YES' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS SURRAREAFREEOFHEATWORK
         ,LOWER(SURRAREAHOUSEKEEP) AS SURRAREAHOUSEKEEP
         ,LOWER(MIXINGRMHOUSEKEEP) AS MIXINGRMHOUSEKEEP
         ,CAST(CAST(AGEOFOLDESTBOOTH AS NUMBER(3,0))AS VARCHAR) AS AGEOFOLDESTBOOTH
         ,CAST(CAST( REPLACE(REPLACECOST,',','') AS NUMBER(15,0))AS VARCHAR) AS REPLACECOST
         , CASE WHEN  Upper(trim(REGULARSERVICELOG))='YES'  THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS REGULARSERVICELOG
         ,CASE WHEN INTERIORWALLPROTECTIONUSED='TRUE' OR  Upper(trim(INTERIORWALLPROTECTIONUSED))='YES' THEN cast('1' as varchar) ELSE cast('0' as varchar) END AS INTERIORWALLPROTECTIONUSED
         ,CASE WHEN  Upper(trim(EXHAUSTFANREPLACED))='YES' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS EXHAUSTFANREPLACED
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
         ,CASE WHEN METALRECYCLEONSITE='TRUE' OR Upper(trim(METALRECYCLEONSITE))='YES' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS METALRECYCLEONSITE
         ,CASE WHEN METALRECYCLEINSIDE='TRUE' OR Upper(trim(METALRECYCLEINSIDE))='YES' THEN  cast('1' as varchar) ELSE cast('0' as varchar) END AS METALRECYCLEINSIDE
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
         ,CAST(CAST(AVGNOVEHSSTORED AS NUMBER(3,0))AS VARCHAR) AS  AVGNOVEHSSTORED
         ,CASE WHEN YARDFLOORHOUSEKEEP ='Caked oil all over' THEN 'Cakedoilallover'
               WHEN YARDFLOORHOUSEKEEP ='Caked oil in places' THEN 'Cakedoilinplaces'
               WHEN YARDFLOORHOUSEKEEP ='Some oil' THEN 'Someoil'
               WHEN YARDFLOORHOUSEKEEP ='Immaculate yard' THEN 'Immaculateyard' ELSE YARDFLOORHOUSEKEEP END AS YARDFLOORHOUSEKEEP
         ,CASE WHEN CLEARLANDSQM ='<150sqm' THEN 'Lessthan150sqm'
               WHEN CLEARLANDSQM ='<300sqm' THEN 'Lessthan300sqm'
               WHEN CLEARLANDSQM ='<450sqm' THEN 'Lessthan450sqm'
               WHEN CLEARLANDSQM ='<600sqm' THEN 'Lessthan600sqm' ELSE CLEARLANDSQM END AS CLEARLANDSQM,
               -- FIXED (G-BP-84): was 'WHEN CLEARLANDSQM =''<450sqm'' THEN ''Lessthan600sqm''' —
               -- duplicated the <450sqm condition instead of checking <600sqm, so the
               -- <600sqm branch was unreachable.
                coalesce(T28.SICCode_Value,'Other')  SICCODE, coalesce(LASTSERVICEYEAR::varchar,'') LASTSERVICEYEAR
    FROM  AGGNE.DEV.LOCATION_01 T2
    INNER JOIN AGGNE.DEV.ACCOUNT_LOC T3 ON CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.cmlnumber) || '|' || TRIM(T2.EXPIRINGID) AS VARCHAR)=TRIM(T3.PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 T24 ON TRIM(T24.CMLNUMBER) = TRIM(T2.CMLNUMBER)
    LEFT JOIN AGGNE.DEV.SICCode_Lookup T28 ON TRIM(T24.STANDARD_INDUSTRY_CODE) = TRIM(T28.SICCode)
    WHERE T2.LOCATIONANZSICCODE NOT LIKE '%222222%'

),CTE_LISTAGG AS(
SELECT
  ID,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_RISK_LOCATION_UW_COMBINE' THEN payload END, '\n') AS UW,
  CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM AGGNE.DEV.RISK_BUILDING_FINAL_TARGET
WHERE ITR_TYPE IN ('BP_RISK_LOCATION_UW_COMBINE')
GROUP BY ID,CAST(LOAD_DATE AS DATE)
)
,BUILDINGVOLUNTARYEXCESS_DATA as (
 select distinct
 CAST(TRIM(T2.PUREPOLICYNUMBER) || '|' || TRIM(T2.cmlnumber) || '|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS ID
 ,VOLUNTARYEXCESS
 FROM AGGNE.DEV.LOCATION_BG_COVERAGE T2  WHERE T2.EXPIRYDATE>='2026-01-01' )

SELECT DISTINCT  T1.*,
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


coalesce(t10.VOLUNTARYEXCESS,0)::varchar as  BUILDINGVOLUNTARYEXCESS
,
CAST(GETDATE() AS DATE) AS LOAD_DATE
FROM CTE1 T1
LEFT JOIN CTE_LISTAGG T8  ON  T1.PUREPOLICYNUMBER=T8.ID --AND CAST(T8.LOAD_DATE AS DATE)= CAST(GETDATE() AS DATE)
LEFT JOIN AGGNE.DEV.BUILDING_Target             T2 ON T1.PUREPOLICYNUMBER = T2.ID AND T2.ITR_TYPE = 'BP_RISK_Building_Cov_Building'
LEFT JOIN AGGNE.DEV.RISK_BUILDING_BI_TARGET     T3 ON T1.PUREPOLICYNUMBER = T3.ID AND T3.ITR_TYPE = 'BP_RISK_Building_BI'
LEFT JOIN AGGNE.DEV.RISK_BUILDING_BG_TARGET     T4 ON T1.PUREPOLICYNUMBER = T4.ID AND T4.ITR_TYPE = 'BP_RISK_Building_BG'
LEFT JOIN AGGNE.DEV.RISK_BUILDING_MONEY_TARGET  T5 ON T1.PUREPOLICYNUMBER = T5.ID AND T5.ITR_TYPE = 'BP_RISK_Building_Money'
LEFT JOIN AGGNE.DEV.RISK_BUILDING_EN_TARGET     T6 ON T1.PUREPOLICYNUMBER = T6.ID AND T6.ITR_TYPE = 'BP_RISK_Building_EN'
LEFT JOIN AGGNE.DEV.RISK_BUILDING_BC_TARGET     T7 ON T1.PUREPOLICYNUMBER = T7.ID AND T7.ITR_TYPE = 'BP_RISK_Building_BC'
LEFT JOIN BUILDINGVOLUNTARYEXCESS_DATA     T10 ON T1.PUREPOLICYNUMBER = T10.ID
 ;

-- POST-CHECK (Snowflake)
-- SELECT COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_FINAL WHERE ROOFCONSTRUCTION_FINAL='Fibro (Non-Asbestos)';
-- Expect 0 (was 29 before this fix, G-BP-83) — should now show 'FibroNonAsbestos'.
-- SELECT COUNT(*) FROM AGGNE.DEV.RISK_BUILDING_FINAL WHERE CLEARLANDSQM='<600sqm';
-- Expect 0 (was already 0 before this fix — confirms no regression, G-BP-84 fixes the latent risk).
