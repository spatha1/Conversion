# Seq 14 — Outer Building Risk (`risk` / Building)

| | |
|---|---|
| **Script name** | RISK_Building |
| **Source view** | `AGGNE.DEV.PER_RISK_BUILDING_FINAL` |
| **Target** | `AGGNE.DEV.PER_RISK_BUILDING_TARGET` |
| **Consumed by** | `{LOC}` assembly in the final XML SP |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RiskSelection` / `PER_HomeContents` → `Locationdetails_PER` (staging) + `PER_ACCOUNT_LOC` (risk numbers) + `PER_BUILDING_TARGET`/`PER_HC_TARGET` (seq 7/13 blocks) → view → template → target |

## Template (live PP_ConversionConfig) — key lines

```xml
<risk>
  <Type>Building</Type>
  <SICCode>General Mechanical Workshop</SICCode>   <!-- hardcoded — see G-33 -->
  <LocationNumber>{RISKNUMBER}</LocationNumber>
  <!-- ~40 commercial screening tags (spray booths, dismantlers, tyres, EV storage…) hardcoded empty -->
  <StandardExcess></StandardExcess>                <!-- hardcoded empty — see G-34 -->
  <ImposedExcess></ImposedExcess>                  <!-- hardcoded empty — see G-34 -->
  <Details>Building 1</Details>
  <IsBuildingHeritage>0</IsBuildingHeritage>
  <ExternalDoors>1</ExternalDoors>                 <!-- hardcoded answer — see G-35 -->
  <SecurityAccessibleWindows>1</SecurityAccessibleWindows>
  <SecurityAlarm>0</SecurityAlarm>
  <LocationConnectedToTownWaterMain>0</LocationConnectedToTownWaterMain>
  <StoreFlammableGoods>0</StoreFlammableGoods>
  <IsAusStandardFollowed>1</IsAusStandardFollowed>
  {RISK_BUILDING}
  {RISK_BC}
  <RoofConstruction>{ROOFCONSTRUCTION_FINAL}</RoofConstruction>
  <NumberOfStories>{STOREYS}</NumberOfStories>
  <WhatYearWasTheBuildingConstructed>{YEARBUILDINGCONSTRUCTED}</WhatYearWasTheBuildingConstructed>
  <YearTheBuildingWasLastReWired>{YEARLASTREWIRED}</YearTheBuildingWasLastReWired>
  <YearTheBuildingWasLastRePlumbed>{YEARLASTREPLUMBED}</YearTheBuildingWasLastRePlumbed>
  <MainWallConstruction>{MAINWALLCONSTRUCTION_FINAL}</MainWallConstruction>
  <FloorConstruction>{FLOORCONSTRUCTION_FINAL}</FloorConstruction>
  <WhatTypeOfAlarmSystemIsInstalled>{ALARMSYSTEMINSTALLED_FINAL}</WhatTypeOfAlarmSystemIsInstalled>
  <AreDeadlocksInstalledOnAllExternalDoors>{DEADLOCKSINSTALLED_FINAL}</AreDeadlocksInstalledOnAllExternalDoors>
  <BarsOrGrillsInstalledOnAllWindows>{GRILLKEYLOCKINSTALLED_FINAL}</BarsOrGrillsInstalledOnAllWindows>
  <SecurityMeasures>{SECURITYDETAILS}</SecurityMeasures>
  <HomeBuildingOccupied>{HOWOCCUPPIED}</HomeBuildingOccupied>
  <InterestedPartyDescription>{INTERESTEDPARTY}</InterestedPartyDescription>
</risk>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `risk/Type` | — | hardcoded "Building" | — | BY DESIGN |
| `risk/SICCode` | — | hardcoded "General Mechanical Workshop" | — | G-33 P1 |
| `risk/LocationNumber` | required | {RISKNUMBER} pass-through | PER_ACCOUNT_LOC.RISKNUMBER | OK |
| `risk/NumberOfSprayBoothsAtThisLocation … risk/SatisfactoryRiskMitigationProcessesEvident *(~37 tags: spray booth, dismantler, metal recycling, tyre storage, fuel storage screening)*` | optional | all empty — no source column for any of them | commercial/industrial risk-assessment questions inherited from a shared template | NEW — confirm boilerplate |
| `risk/Embargoes/MatchingRestrictions` | optional | empty | — | EMPTY |
| `risk/StandardExcess` | excess amount | empty — not tokenized (mirrors seq 7 G-23) | — | G-34 P2 |
| `risk/ImposedExcess` | excess amount | empty — not tokenized | — | G-34 P2 |
| `risk/Details` | — | hardcoded "Building 1" | — | BY DESIGN |
| `risk/IsBuildingHeritage` | — | hardcoded "0" | — | BY DESIGN |
| `risk/AmoutOfEPS` | — | hardcoded "0" | — | BY DESIGN |
| `risk/ExternalDoors` | assessment answer | hardcoded "1" — fabricated | — | G-35 P2 |
| `risk/SecurityAccessibleWindows` | assessment answer | hardcoded "1" — fabricated | — | G-35 P2 |
| `risk/SecurityAlarm` | assessment answer | hardcoded "0" — fabricated | — | G-35 P2 |
| `risk/VehicleDetails` | — | hardcoded "Vehicle 1" | — | BY DESIGN |
| `risk/VehicleYardShowingAnySecurity` | — | hardcoded "0" | — | BY DESIGN |
| `risk/VehicleKeyStorage` | — | hardcoded "0" | — | BY DESIGN |
| `risk/HireVehicleContractSupplied` | — | hardcoded "0" | — | BY DESIGN |
| `risk/LocationANZSICCode` | optional | empty | — | EMPTY |
| `risk/LocationConnectedToTownWaterMain` | assessment answer | hardcoded "0" — fabricated | — | G-35 P2 |
| `risk/StoreFlammableGoods` | assessment answer | hardcoded "0" — fabricated | — | G-35 P2 |
| `risk/WhatQuantity` | optional | empty | — | EMPTY |
| `risk/IsAusStandardFollowed` | assessment answer | hardcoded "1" — fabricated | — | G-35 P2 |
| `risk/{RISK_BUILDING}` | — | seq 7 payload (Indicator=0 stub fallback) | PER_BUILDING_TARGET | see seq 7 |
| `risk/{RISK_BC}` | — | seq 13 payload (Indicator=0 stub fallback) | PER_HC_TARGET | see seq 13 |
| `risk/RoofConstruction` | required (conditional) — 6 codes *(PP base 11578)* | {ROOFCONSTRUCTION_FINAL} 10-branch CASE | Locationdetails_PER.ROOFCONSTRUCTION | G-36 P2 |
| `risk/NumberOfStories` | int | {STOREYS} pass-through | Locationdetails_PER.STOREYS | OK |
| `risk/WhatYearWasTheBuildingConstructed` | required *(CoverageLibrary 52245)* | {YEARBUILDINGCONSTRUCTED} pass-through | Locationdetails_PER.YEARBUILDINGCONSTRUCTED | VQ blanks |
| `risk/OccupationOfHighestRiskTenant` | optional | empty | — | EMPTY |
| `risk/YearTheBuildingWasLastReWired` | optional | {YEARLASTREWIRED} pass-through | Locationdetails_PER.YEARLASTREWIRED | OK |
| `risk/YearTheBuildingWasLastRePlumbed` | optional | {YEARLASTREPLUMBED} pass-through | Locationdetails_PER.YEARLASTREPLUMBED | OK |
| `risk/YearTheBuildingWasLastReRoofed` | optional | empty | — | EMPTY |
| `risk/MainWallConstruction` | required (conditional) — 7 codes *(PP base 11548)* | {MAINWALLCONSTRUCTION_FINAL} 10-branch CASE | Locationdetails_PER.MAINWALLCONSTRUCTION | G-36 P2 |
| `risk/FloorConstruction` | required (conditional) — 5 codes *(PP base 11607)* | {FLOORCONSTRUCTION_FINAL} mapped incl. lowercase-f code | Locationdetails_PER.FLOORCONSTRUCTION | mostly OK |
| `risk/YearLastReWiredCalculation` | optional | empty | — | EMPTY |
| `risk/WhatTypeOfAlarmSystemIsInstalled` | required (conditional) — 5 codes *(PP base 11747)* | {ALARMSYSTEMINSTALLED_FINAL} 5-branch CASE | Locationdetails_PER.ALARMSYSTEMINSTALLED | G-36 P2 |
| `risk/DoYouHaveSecurityCamerasOrCCTVInstalled` | optional | empty | — | EMPTY |
| `risk/IsThereATwoMeterHighPerimeterFenceEnclosingThePremises` | optional | empty | — | EMPTY |
| `risk/AreSecurityBollardsInPlace` | optional | empty | — | EMPTY |
| `risk/AreYourPremisesPatrolledByASecurityGuard` | optional | empty | — | EMPTY |
| `risk/AreDeadlocksInstalledOnAllExternalDoors` | required (conditional) — 3 codes | {DEADLOCKSINSTALLED_FINAL} mapped, 'Other' ELSE passthrough | Locationdetails_PER.DEADLOCKSINSTALLED | G-36 P2 |
| `risk/IsThereExteriorSecurityLighting` | optional | empty | — | EMPTY |
| `risk/BarsOrGrillsInstalledOnAllWindows` | required (conditional) — 3 codes | {GRILLKEYLOCKINSTALLED_FINAL} mapped, 'Other' ELSE passthrough | Locationdetails_PER.GRILLKEYLOCKINSTALLED | G-36 P2 |
| `risk/TwentyFourHoursAttendanceOnSite` | — | hardcoded "0" | — | BY DESIGN |
| `risk/SecurityMeasures` | free text | {SECURITYDETAILS} pass-through, NOT escaped | Locationdetails_PER.SECURITYDETAILS | G-21 P2 |
| `risk/WhatYearWasARiskAssessmentReviewLastUndertaken` | optional | empty | — | EMPTY |
| `risk/ConditionOfBuilding` | optional | empty | — | EMPTY |
| `risk/ConditionOfRoof` | optional | empty | — | EMPTY |
| `risk/RoofConstructionAon` | optional | empty | — | EMPTY |
| `risk/RoofSqmAon` | — | hardcoded "0" | — | BY DESIGN |
| `risk/LandSqm` | optional | empty | — | EMPTY |
| `risk/PropertyInputGeocodeURL` | optional | empty | — | EMPTY |
| `risk/HomeBuildingOccupied` | optional — 5 codes *(PP base 11360)* | {HOWOCCUPPIED} mapped incl. ILIKE for member/Member variants | Locationdetails_PER.HOWOCCUPPIED | OK |
| `risk/InterestedPartyDescription` | free text *(PP base 11876)* | {INTERESTEDPARTY} pass-through | Locationdetails_PER.INTERESTEDPARTY | OK |


## Gaps

- **G-33 (P1) — `<SICCode>General Mechanical Workshop</SICCode>` hardcoded on every personal home risk.** A commercial occupancy code on PP policies. Confirm what PP expects (blank, or a PP occupancy value) and tokenize if needed.
- **G-36 (P2) — unmapped construction/security source values pass through raw** (Fibro (Non-Asbestos) roof, Some Asbestos and Brick, wall Other, alarm Local - Monitored / Mobile Mechanic, deadlocks/grills Other). All are invalid PP dropdown values; the required client mapping decision list is already drafted in the view header. Validate counts per value: `seq14_vq.sql`.
- **G-34 (P2) — StandardExcess / ImposedExcess hardcoded empty** at risk level (mirrors seq 7 G-23 at coverage level).
- **G-35 (P2) — fabricated underwriting answers hardcoded**: `ExternalDoors=1`, `SecurityAccessibleWindows=1`, `SecurityAlarm=0`, `LocationConnectedToTownWaterMain=0`, `StoreFlammableGoods=0`, `IsAusStandardFollowed=1`. These are risk-assessment answers being asserted for every policy without source data. Client to confirm each default (or blank them).
- Note (by design, verify once): motor-only policies are correctly excluded from location risk nodes via the `HOMEBUILDINGS/HOMECONTENTS='Yes'` + HB_01/HC_02 EXISTS filter.

## Validation queries

See [`seq14_vq.sql`](vq/seq14_vq.sql).
