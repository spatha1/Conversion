# Seq 18 — Motor Risk (`RISK_Building_PM`)

> Full interactive version with expandable per-field trace: [`PP_FieldMapping_Seq18_Motor.html`](PP_FieldMapping_Seq18_Motor.html) (this MD is the summary of the same analysis; gap IDs G-01…G-14 match).

| | |
|---|---|
| **Script name** | RISK_Building_PM |
| **Source view** | `AGGNE.DEV.PER_COM_PAYLOAD` |
| **Target** | `AGGNE.DEV.PER_COM_COVERAGES_TARGET` (ITR_TYPE = RISK_Building_PM) |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL` (+`PER_RISKSELECTION`, `PER_CLAUSEAMENDMENTMV`, `RISK.SCHEDULE_CLAUSES_TEMPLATE`) → `PM_01` (SP line 7499) → `PM_02` (SAS business rules, 8257) → `PM_03` (dedupe, 8609) → view → template → target |

**The rule that makes everything mandatory:** conversion hardcodes `VehicleInfoOverride=1` for every vehicle (no RedBook keys in scope); the manuscript's `RedBookDetailsRequiredCondition` (`Override=1 AND IsUnderwriters`) then makes VehicleType, BodyType, EngineSize, GrossVehicleMass, NumberOfCylinders, DriveDescription and InductionType **required on the UW screen** for every converted vehicle.

## Gap register (details + full field matrix in the HTML)

| ID | Field | Gap (from code) | Severity |
|---|---|---|---|
| G-01 | State | Template hardcodes `NSW` for every vehicle; real state already derived in `PM_01.STATE` (`PER_RISKSELECTION.RLState`) but never tokenized | P1 |
| G-02 | Year/Make/Model | View filter `YEAR<>0 AND MAKE<>'' AND MODEL<>''` silently drops vehicles — no error, no report | P1 |
| G-03 | BodyType | View emits 34 RedBook names; DCT accepts 17 codes constrained by VehicleType; PM_01 'Other' + PM_02 backfill values have no view branch → ELSE '' blanks a required field | P1 |
| G-04 | DriveDescription | Captions sent ("Front wheel drive"); DCT values are code-form (`Frontwheeldrive`, `Rearwheeldrive`, `4wheeldrive`) | P1 |
| G-05 | NumberOfCylinders | `COALESCE(x,0)` + OV-code 11 → `0`; DCT dropdown is 1–16, no 0 | P1 |
| G-06 | InductionType | PM_01's "Turbo and supercharged" unmapped → ELSE '' blanks it | P1 |
| G-07 | VoluntaryExcess | PM_01 bands to 0/500/1000/**2000/5000**; PP options stop at 1500 | P1 |
| G-08 | RegistrationNumber | No cleanup vs DCT format mask (A–Z, 0–9 only) | P2 |
| G-09 | ImportType | SP literal `'N/A '` carries a trailing space; blank when source Override≠1 | P2 |
| G-10 | EngineSize / GVM | Sourced from RedBook *override* columns — structurally sparse; both required because Override=1 | P2 |
| G-11 | AgeOfYoungestRegularDriver | <16 nulled (correct) but no default for a required field | P2 |
| G-12 | VehicleType | ELSE passes raw value unvalidated; blank → PassengerVehicle default pending client sign-off | P2 |
| G-13 | RedbookCode | View joins/carries `MVRBVEHICLEKEY` but template hardcodes empty `<RedbookCode/>` | P2 |
| G-14 | Clauses | CM_*/FV_* codes disabled in PP (superseded by seq 17 **G-38**, which is broader) | P2 |

Verified-correct notables (documented to prevent re-"fixing"): RestrictionOfDriverAge's 20/24/29/39 int values (DCT stores age thresholds, captions show marketing age); HireCarHireAfterIncident `NotTaken` code form; ChoiceOfRepair TPO→0; the market/agreed value formulas matching DCT's own recalculation.

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `risk/Type` | — | hardcoded "Motor" | — | BY DESIGN |
| `risk/ExcessWaiverForGlass` | boolean, default 1 *(PP base 2218)* | {EXCESSWAIVERFORGLASS} — IN ('Yes','Taken')→1 | PM_01 ← PER_VEHICLEDETAIL.MVCVUnlimGlass | OK |
| `risk/OnHookTowingProtection` | — | hardcoded "0" | — | BY DESIGN |
| `risk/VoluntaryExcess` | optional, default 0 — 0–1500 *(PP base 2241)* | {VOLUNTARYEXCESS} — PM_01 bands to 0/500/1000/2000/5000 | PM_01 ← PER_VEHICLEDETAIL.MVCVVoluntary | G-07 P1 |
| `risk/ProtectionType` | required (FleetType=Default) — 6 codes *(PP base 2423)* | {PROTECTIONTYPE} — 5 captions mapped, ELSE '' | PM_01 ← PER_VEHICLEDETAIL.MVCVProtectionType | OK |
| `risk/HireVehicleExcess` | — | hardcoded "0" | — | BY DESIGN |
| `risk/CourtesyVehicleExcess` | — | hardcoded "0" | — | BY DESIGN |
| `risk/ValueAccessoriesOption` | — | hardcoded "2" | — | BY DESIGN |
| `risk/MarketValueWithoutAccessories` | float | {MVVALUEWITHOUTACCESSORIES} — Override backfill of missing market value | PM_01/PM_02 ← MVCVMarketValue | OK |
| `risk/ValueWithoutAccessories` | required=True *(Package_Data 11416)* | {AVVALUEWITHOUTACCESSORIES} — agreed value floored at 2000, 90% accessories rebase | PM_02 business rules ← MVCVAgreedValue, MVCVVehModValue | OK — verify rules |
| `risk/HireCourtesyDeliveryUse` | optional | empty | — | EMPTY |
| `risk/UnlimitedGlass` | — | hardcoded "1" | — | BY DESIGN |
| `risk/OnHook` | — | hardcoded "0" | — | BY DESIGN |
| `risk/DeliveryVehicleExcess` | — | hardcoded "0" | — | BY DESIGN |
| `risk/InterestedParties` | boolean, required, default 0 *(PP base 2481)* | {VEHHAVEANINTERESTEDPARTY} — 'Yes'→1 ELSE 0 | PM_01 ← PER_VEHICLEDETAIL.MVCVTPFinInterest | OK |
| `risk/InterestedPartiesAddress` | optional | empty — details go in free-text field instead | — | EMPTY |
| `risk/InterestedPartiesName` | optional | empty | — | EMPTY |
| `risk/IsVehicleImportedorNot` | — | hardcoded "0" | — | BY DESIGN |
| `risk/NonClaimDiscount` | — | hardcoded "0" | — | BY DESIGN |
| `risk/LocationID` | optional | empty | — | EMPTY |
| `risk/FleetType` | switches required-ness of ProtectionType/RestrictionOfDriverAge/ChoiceOfRepair | hardcoded "Default" | — | BY DESIGN |
| `risk/VehicleDetails` | — | hardcoded "Vehicle 0" | — | BY DESIGN |
| `risk/GaragingPostcode` | optional | empty | — | EMPTY |
| `risk/Usage` | optional | empty | — | EMPTY |
| `risk/Performance` | optional | empty | — | EMPTY |
| `risk/PrincipalOperator` | — | hardcoded "Yes" | — | BY DESIGN |
| `risk/Included` | — | hardcoded "1" | — | BY DESIGN |
| `risk/HighestValueVehicleinFleet` | — | hardcoded "0" | — | BY DESIGN |
| `risk/MaximumOneVehiclePay` | — | hardcoded "0" | — | BY DESIGN |
| `risk/State` | required *(Package_Data 11466)* | hardcoded "NSW" for every vehicle | PM_01.STATE already derived from PER_RISKSELECTION.RLState — not tokenized | G-01 P1 |
| `risk/Segment` | optional | empty | — | EMPTY |
| `risk/PerformanceSafetyModifications` | — | hardcoded "0" | — | BY DESIGN |
| `risk/IsNonStandardAccessoriesIncludedinCover` | — | hardcoded "0" | — | BY DESIGN |
| `risk/CarHaveAnyModifications` | — | hardcoded "0" | — | BY DESIGN |
| `risk/WindscreenExtFlag` | — | hardcoded "0" | — | BY DESIGN |
| `risk/Code` | — | hardcoded "CM" | — | BY DESIGN |
| `risk/ImportType` | free text, default "N/A" | {IMPORTFLAG} — PM_01 literal 'N/A ' has a trailing space | PM_01 ← PER_VEHICLEDETAIL.MVRBImportFlagOV | G-09 P2 |
| `risk/AddedHistoryID` | — | hardcoded "2069" | — | BY DESIGN |
| `risk/CommercialVehicleNumber` | — | hardcoded "1" | — | BY DESIGN |
| `risk/coverage/Type` | — | hardcoded "CommercialVehicle" | — | BY DESIGN |
| `risk/coverage/limit/Type` | — | hardcoded "CommercialVehicle" | — | BY DESIGN |
| `risk/coverage/limit/iValue` | int | {MARKETVALUEWITHACCESSORIESAMOUNT} | PM_01/PM_02 market+accessories sum | OK |
| `risk/coverage/Indicator` | — | hardcoded "1" | — | BY DESIGN |
| `risk/coverage/ClassCode/APRA` | — | hardcoded "DMV" | — | BY DESIGN |
| `risk/coverage/ClassCode/Business` | — | hardcoded "DMV" | — | BY DESIGN |
| `risk/coverage/Code` | — | hardcoded "CM" | — | BY DESIGN |
| `risk/coverage/{SUBCOV}` | — | LISTAGG of seq 15 rows | PER_COM_COVERAGES_TARGET (Risk_CM) | see seq 15 |
| `risk/coverage/Description` | — | hardcoded "Commercial Motor" | — | BY DESIGN |
| `risk/coverage/ExpiringPurePremium` | — | hardcoded "0" | — | BY DESIGN |
| `risk/coverage/ExpiringPremium` | — | hardcoded "0" | — | BY DESIGN |
| `risk/coverage/ClaimsIncurred` | numeric | {PMCLMINCD} COALESCE 0 | Output_Coverage_PER.PMCLMINCD | OK |
| `risk/coverage/NumberOfClaims` | numeric | {PMCLMCNT} COALESCE 0 | Output_Coverage_PER.PMCLMCNT | OK |
| `risk/coverage/Premium` | numeric | {PMEXPPREM} COALESCE 0 | Output_Coverage_PER.PMEXPPREM | OK |
| `risk/HireCarHireAfterIncident` | Taken/NotTaken, required *(PP base 2292)* | {HIRECARHIREAFTERINCIDENT} — 'Taken'→'Taken' ELSE 'NotTaken' | PM_01 ← PER_VEHICLEDETAIL.MVCVCarHire | OK |
| `risk/CoverType` | optional | empty | — | EMPTY |
| `risk/VehicleType` | 13 codes, required when Override=1 | {VEHICLETYPE} — 13-branch CASE; ELSE raw passthrough; blank→PassengerVehicle | PM_01 ← MVCVTypeVeh code map + ~150 make/model plant lookups; PM_02 patches 20 RedBook keys | G-12 P2 |
| `risk/VehicleInfoOverride` | optional — 0/1 | {OVERRIDE} = '1' fixed for all vehicles | PM_01/PM_02 ← MVCVOverride / MVRBVehicleKey blank check | DECISION MADE |
| `risk/RegistrationNumber` | required, FormatMask.Rego (A–Z, 0–9) *(PP base 2150)* | {REGISTRATIONNUMBER} pass-through, no cleanup | PM_01 ← PER_VEHICLEDETAIL.MVCVRegNo | G-08 P2 |
| `risk/VinNumber` | optional | empty | — | EMPTY |
| `risk/Year` | required *(Package_Data 11793)* | {YEAR} — view filter YEAR<>0 AND MAKE<>'' AND MODEL<>'' silently drops vehicles | PM_01/PM_02 ← PER_VEHICLEDETAIL.MVCVYear, pass-through unconditional | G-02 P1 |
| `risk/RegoStatus` | — | hardcoded "500" | — | BY DESIGN |
| `risk/Make` | required, readOnly *(Package_Data 11334)* | {MAKE} INITCAP | PM_01 ← PER_VEHICLEDETAIL.MVCVMake | OK |
| `risk/Model` | required, readOnly *(Package_Data 11342)* | {MODEL} INITCAP | PM_01 ← PER_VEHICLEDETAIL.MVCVModel | OK |
| `risk/Description` | free text *(CoverageLibrary 31142)* | {DESCRIPTION} &-escaped | PM_01 ← PER_VEHICLEDETAIL.MVCVDescriptionOV | OK |
| `risk/NightParkingLocation` | optional | empty | — | EMPTY |
| `risk/NightParkingPostcode` | optional | empty | — | EMPTY |
| `risk/DayParkingLocation` | optional | empty | — | EMPTY |
| `risk/DayParkingPostcode` | optional | empty | — | EMPTY |
| `risk/SecurityType` | optional | empty | — | EMPTY |
| `risk/FinanceType` | optional | empty | — | EMPTY |
| `risk/DateOfPurchase` | optional | empty | — | EMPTY |
| `risk/AnnualMileage` | optional | empty | — | EMPTY |
| `risk/CoverValue` | optional | empty | — | EMPTY |
| `risk/Excess/LessThanAge20` | optional | empty | — | EMPTY |
| `risk/Excess/Age20To21` | optional | empty | — | EMPTY |
| `risk/Excess/Age22To25` | optional | empty | — | EMPTY |
| `risk/NonStandardAccessories` | optional | empty | — | EMPTY |
| `risk/NonStandardAccessoriesSumInsured` | optional | empty | — | EMPTY |
| `risk/ModificationType` | optional | empty | — | EMPTY |
| `risk/ModificationSumInsured` | optional | empty | — | EMPTY |
| `risk/TotalSumInsured` | — | hardcoded "0" | — | BY DESIGN |
| `risk/LocationDescription` | — | hardcoded "Primary Location" | — | BY DESIGN |
| `risk/VehicleFullDescription` | free text | {DESCRIPTION} reused | PM_01.MVCVDescriptionOV | OK |
| `risk/BodyType` | 17 codes, per VehicleType, required when Override=1 | {BODYTYPE} — 34-branch CASE vs 17 valid codes; unmapped → blank | PM_01 ← MVCVBodyTypeOV (Override=1 only) / MVCVBodyType fallback; PM_02 make/model backfill | G-03 P1 |
| `risk/EngineSize` | required when Override=1 *(CoverageLibrary 31093)* | {ENGINESIZE} pass-through | PM_01 ← PER_VEHICLEDETAIL.MVRBEngineSizeOV (RedBook Override value) | G-10 P2 |
| `risk/NumberOfCylinders` | 1–16, required when Override=1 *(CoverageLibrary 30424)* | {NUMBEROFCYLINDERS} — COALESCE(x,0) | PM_01 ← MVRBCylindersOV coded 1–11 (code 11="none"→0) | G-05 P1 |
| `risk/DriveDescription` | 4 codes, required when Override=1 *(CoverageLibrary 30449)* | {DRIVEDESCRIPTION} — captions sent, not codes | PM_01 ← MVRBDriveDescriptionOV 1–4 → captions | G-04 P1 |
| `risk/InductionType` | 4 codes, required when Override=1 *(CoverageLibrary 30462)* | {INDUCTIONTYPE} — "Turbo and supercharged" unmapped | PM_01 ← MVRBInductionOV 1–5 | G-06 P1 |
| `risk/GrossVehicleMass` | required when Override=1 *(CoverageLibrary 30475)* | {GROSSVEHICLEMASS} comma-stripped cast | PM_01 ← MVRBGrossVehMassOV | G-10 P2 |
| `risk/WouldYouLikeToAddAccessoriesOrModifications` | optional | empty | — | EMPTY |
| `risk/AgreedValueAmount` | float | {AGREEDVALUEAMOUNT} | PM_01 = MVCVAgreedValue − MVCVVehModValue | OK |
| `risk/AgreedValueDescription` | optional | empty | — | EMPTY |
| `risk/AgreedValueDescriptionValue` | optional | empty | — | EMPTY |
| `risk/MarketValueDescription` | free text | {MARKETVALUEDESCRIPTION} | PM_02 clause-parsed accessory text (CM_C06_MODSACCS "INCLUDES…") | OK |
| `risk/WouldYouLikeToAddAccessoriesOrModificationsMarket` | Yes/No, required=True | {MVADDACCORMODS} — 'Yes'→Yes ELSE No | PM_01/PM_02 | OK |
| `risk/MarketValueDescriptionValue` | float | {MARKETVALUEDESCRIPTIONVALUE} | PM_01/PM_02 | OK |
| `risk/MarketValueWithAccessories` | not applicable — DCT-calculated readOnly output field *(Package_Data 11519)* | {MARKETVALUEWITHACCESSORIESAMOUNT} = Without + DescriptionValue | PM_01/PM_02 sum | OK |
| `risk/HighestRiskUse` | optional dropdown *(PP base 2497)* | empty — no view column | — | CONFIRM |
| `risk/AgeOfYoungestRegularDriver` | required *(Package_Data 11361)* | {AGEOFYOUNGESTREGULARDRIVER} | PM_02 nulls <16 (matches DCT MinAge rule) | G-11 P2 |
| `risk/RestrictionOfDriverAge` | 0/20/24/29/39 *(PP base 2351)* | {RESTRICTIONOFDRIVERAGE} — captions→int values (verified correct) | PM_01 clause override + MVCVAgeRestriction 1–5; PM_02 default "No Restriction" | OK — verified |
| `risk/DoesTheVehicleHaveAnInterestedParty` | boolean, required, default 0 *(PP base 2481)* | {VEHHAVEANINTERESTEDPARTY} reused | PM_01 MVCVTPFinInterest=1+details; PM_02 =2→No | OK |
| `risk/AddDetailsForTheInterestedParty` | free text | {ADDDETAILSFORTHEINTERESTEDPARTY} | PM_01.MVCVTPFinInterestDet | OK |
| `risk/HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime, /HowOftenDoYouPickUpOrDeliverVehicles *(2 tags)*` | optional | all empty | — | EMPTY |
| `risk/ChoiceOfRepair` | 1/0, required, forced 0 for TPO *(PP base 2265)* | {CHOICEOFREPAIR} — 'Taken'→1 ELSE 0 | PM_01 ProtType≠4 ← MVCVChoiceRepair | OK |
| `risk/WhatIsTheTypicalRadiusOfTravelFromTheBaseLocation, /WillTheVehicleTransportMotorVehiclesOrTheMembersGeneralProperty, /AreAnyVehiclesDriverSuppliedPM, /Details, /IsThisVehicleUsedForRideShareOperation, /AreHireContractsRestrictedToNamedDriversOnly, /AreAnyVehiclesDriverSupplied, /WillAnyContractorsOperateThisVehicle, /WillThisVehicleBeUsedToDeliverDangerousGoods, /StandardExcess, /ImposedExcess, /OnHookExcess, /UWAdjustmentTotal, /MarketValue, /NumberofVehicles, /TotalValueofNonStandard, /GeneralBusinessUse, /CarHire *(18 tags)*` | optional / DCT-calculated | all empty | — | EMPTY |
| `risk/HowManyOfYourVehiclesMayRequireOnHook, /DoAnyOfYourVehiclesHaveATaxiRegistration, /DoesTheMemberOwnAnyOtherBusinesses, /WhereAreIdleVehiclesStored, /DetailsOfVehicleLocationRiskMitigation, /AreAnyVehiclesHiredOutForRideShareOperations, /WhatPercentOfTheFleetIsHiredOutToRideShareOperators, /HowManyYearsExperienceDoesThisMemberHaveOperatingAHireFleet, /AreContractorsEmployedAsDrivers, /AreAnyVehiclesUsedToDeliverDangerousGoods, /HowManyYearsExperienceDoesThisMemberHaveOperatingADeliveryFleet, /HowOftenIsTheVehicleUsed, /IsTheVehicleUsedForMembersBusinessNeedsOnly(+Details), /VehicleTransportHazardousDangerousGoods(+Details), /IsTheVehicleUsedToTransportAnyCustomerItemsReward(+Details), /MaximumRangeVehicleWillTravelBusinessUse, /IsTheVehicleDrivenByDirectEmployeesOnly(+Details), /IfPrimeMoverWillItTowMoreThan1TrailerAtTime(+Details) *(~23 tags: hire/rideshare/dangerous-goods fleet screening)*` | optional | all empty — fleet/commercial-use screening questions, boilerplate for a personal motor vehicle | — | NEW — confirm boilerplate |
| `risk/MakeOther, /ModelOther, /MakeID, /FamilyID *(4 tags)*` | optional | all empty | — | EMPTY |
| `risk/RedbookCode` | optional, market value only *(Package_Data 11811)* | hardcoded empty — view joins/carries MVRBVEHICLEKEY but never emits it | PM_03.MVRBVEHICLEKEY ← PER_VEHICLEDETAIL.MVRBVehicleKey | G-13 P2 |
| `risk/RedBookStatus` | optional | empty | — | EMPTY |
| `risk/FuelType` | optional free text *(CoverageLibrary 31400)* | empty — no view column; PM_01 does not derive it | — | CONFIRM |
| `risk/TrackRear` | optional | empty | — | EMPTY |
| `risk/PowerKW` | — | hardcoded "0" | — | BY DESIGN |
| `risk/BuildingID, /OccupancyID *(2 tags)*` | optional | empty | — | EMPTY |
| `risk/{COM_CLAUSE}` | — | LISTAGG of seq 17 rows | PER_COM_COVERAGES_TARGET (COM_CLAUSE) | see seq 17 |
| `risk/{UW}` | — | LISTAGG of seq 16 rows | PER_COM_COVERAGES_TARGET (PER_PM_BUILDING_UW) | see seq 16 |

## Validation queries

See [`seq18_vq.sql`](vq/seq18_vq.sql) (same pack as the HTML's VQ-01…VQ-14).

