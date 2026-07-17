# PP Conversion — Mandatory Fields Client Discussion
**Date:** 2026-06-27  
**Reference:** PL101 = `Carrier_PersonalProtectionBase_1_0_0_0.xml`  
**Total policies in scope:** 4,967 (SAMPLE_PER)  
**Building payloads generated:** 4,194  |  **Motor payloads generated:** 605

---

## 1. Building Risk — Mandatory & Key Fields

| # | DCT Field | PL101 Required | Pure Table | Pure Column | Pure Value / Distribution | Blank in Pure | Code Behaviour | Is Issue? | Comment / Client Action |
|---|---|:---:|---|---|---|---|---|:---:|---|
| 1 | **RoofConstruction** | **YES** | LOCATIONDETAILS_PER | ROOFCONSTRUCTION | Tile (most common), Colorbond, Concrete, Iron/Steel/Tin, Asbestos, Wood, Fibro (Non-Asbestos)¹ | **991 (23.6%)** | CASE maps source values to DCT codes. Blank source → blank XML tag | ⚠ | **Client decision needed:** 991 policies have no Roof data in Pure. Should these be excluded from conversion, or is there a default? |
| 2 | **MainWallConstruction** | **YES** | LOCATIONDETAILS_PER | MAINWALLCONSTRUCTION | Brick Veneer, Double Brick, Wood, Concrete, Fibro/Hardiplank, Iron/Steel, Asbestos, Steel², Some Asbestos and Brick² | **991 (23.6%)** | CASE maps to DCT codes. Blank → blank XML. 'Steel' / 'Some Asbestos and Brick' not in PL101 — passes through as-is | ⚠ | Same 991 policies as Roof (same records with no building data). Also need mapping for 'Steel' and 'Some Asbestos and Brick' |
| 3 | **FloorConstruction** | **YES** | LOCATIONDETAILS_PER | FLOORCONSTRUCTION | Concrete, Wood - Concrete Footings, Wood - Stilts, Wood - Stumps, Other | **991 (23.6%)** | CASE maps to DCT codes including correct 'WoodConcretefootings'. Blank → blank XML | ⚠ | Same 991 policies as above. No issue with mapped values — only blank source is the problem |
| 4 | HomeBuildingOccupied | No | LOCATIONDETAILS_PER | HOWOCCUPPIED | Owner Occupied (majority), Holiday Home, Tenanted by member, Owned leased - Long Term, Owned leased - Short Term | **991 (23.6%)** | CASE maps all 5 PL101 values. Blank → blank XML | ⚠ | Same 991 policies. Not mandatory in PL101 but important for landlord protection rules |
| 5 | AlarmSystem | No | LOCATIONDETAILS_PER | ALARMSYSTEMINSTALLED | None (2,390), Local - Audible Only (498), Monitored - Back to base (458), Monitored - To Mobile Phone (323), Monitored - Security (42), **Local - Monitored**³, **Mobile Mechanic - No base location**³ | **1,072 (25.6%)** | CASE maps 5 valid values. 'Local - Monitored' and 'Mobile Mechanic - No base location' are NOT in PL101 — pass through as-is | ⚠ | Blank: 1,072 policies (no security data). Need PL101 mapping for 'Local - Monitored' and 'Mobile Mechanic - No base location' |
| 6 | Deadlocks | No | LOCATIONDETAILS_PER | DEADLOCKSINSTALLED | All doors (2,264), None (1,020), Some doors (427), **Other**³ | **1,072 (25.6%)** | Maps: All doors→AllDoors, Some doors→SomeDoors, None→None. 'Other' is NOT in PL101 — passes through | ⚠ | 1,072 blank. 'Other' in source has no DCT equivalent — needs client decision on target value |
| 7 | Grills | No | LOCATIONDETAILS_PER | GRILLKEYLOCKINSTALLED | None (1,647), All windows (1,647), Some windows (417), **Other**³ | **1,072 (25.6%)** | Maps: All windows→AllWindows, Some windows→SomeWindows, None→None. 'Other' is NOT in PL101 | ⚠ | Same as Deadlocks — 'Other' needs a client-approved PL101 mapping |

---

## 2. Motor Risk — Key Fields

| # | DCT Field | PL101 Required | Pure Table | Pure Column | Pure Value / Distribution | Blank in Pure | Code Behaviour | Is Issue? | Comment / Client Action |
|---|---|:---:|---|---|---|---|---|:---:|---|
| 8 | **ProtectionType** | No | PM_03 | PROTECTIONTYPE | Comprehensive - Market Value, Comprehensive - Agreed Value, Fire and Theft, Comprehensive, Third Party Only, Third Party Fire and Theft | 0 | CASE maps all. **BUG in deployed view:** 'Comprehensive' → `FullComprehensive` (not in PL101). **Fixed in our local file** → `Comprehensive` | ❌ CODE BUG | Deploy fixed `PER_COM_PAYLOAD.sql`. Re-run Seq 17+18. No client action needed |
| 9 | VehicleType | No | PM_03 | VEHICLETYPE | Passenger Vehicle (2,648), Caravan (193), Motorcycle (178), Trailer (130), Heavy Commercial (85), Camper Van (12), Forklift (3), Light Commercial (2), + 5 others | **32 (5.3%)** | CASE maps all 13 PL101 codes. Blank source: **deployed view → empty XML**. **Fixed in our local file → defaults to `PassengerVehicle`** | ⚠ | **Client to confirm:** 32 policies have no Vehicle Type in Pure — is `PassengerVehicle` the right default? |
| 10 | VehicleInfoOverride | No | PM_03 | MVRBVEHICLEKEY (derived) | Has RedBook key → 1, No key → 0 | 0 | **BUG in deployed view:** reads source `OVERRIDE` column (always blank) → produces `0.00000` / `1.00000` (decimal, not valid). **Fixed in our local file:** checks MVRBVEHICLEKEY IS NOT NULL → `'1'` or `'0'` (string) | ❌ CODE BUG | Deploy fixed `PER_COM_PAYLOAD.sql`. Re-run Seq 17+18. No client action needed |
| 11 | BodyType | No | PM_03 | BODYTYPE | Sedan, Hatchback, Utility, Wagon, Van, etc. (free text from RedBook) | Some blank | CASE now maps 34 body types to camelCase (added by Dev). Unmapped → blank | ✅ | No PL101 enum constraint — RedBook free-text field. Code handles known values |
| 12 | RedbookCode (MVRBVEHICLEKEY) | No | PM_03 | MVRBVEHICLEKEY | RedBook key string where available | Some blank | `{MVRBVEHICLEKEY}` token in template, fixed from empty `<RedbookCode/>` | ✅ | Fixed in Seq 18 XML template. No client action needed |

---

## 3. Root Cause Summary

| Root Cause | Affected Fields | Policy Count | Who Resolves |
|---|---|---|---|
| **Source blank in Pure** — no building data was captured for these policies | Roof, MainWall, Floor, Occupied | **991 policies (23.6%)** | **Client** — decide: exclude, default, or enrich |
| **Source blank in Pure** — no security/lock data captured | AlarmSystem, Deadlocks, Grills | **1,072 policies (25.6%)** | **Client** — decide: exclude or default to 'None'? |
| **Source value not in PL101** — Pure has a value but no DCT equivalent | 'Other' (Deadlocks/Grills), 'Local - Monitored' (Alarm), 'Steel' (MainWall) | Small count | **Client** — provide correct PL101 mapping |
| **Code bug in deployed view** — wrong DCT code generated | ProtectionType (`FullComprehensive`), VehicleInfoOverride (decimal) | 605 motor policies | **Dev** — deploy fixed `PER_COM_PAYLOAD.sql` (ready) |
| **Code no-default for blank** — 32 blank VehicleType pass through empty | VehicleType | 32 policies | **Client to confirm** default = `PassengerVehicle` |

---

## 4. Client Decisions Required

| # | Question | Impact |
|---|---|---|
| Q1 | 991 policies have NO building data in Pure (Roof, Floor, MainWall all blank). Should these policies be **excluded** from conversion, or should defaults be applied? | Mandatory fields will be blank in DCT — policy may fail DCT validation |
| Q2 | 1,072 policies have no security data (AlarmSystem, Deadlocks, Grills). Should these default to **`None`** (meaning no security measures)? | DCT will show blank for these fields |
| Q3 | Source `ALARMSYSTEMINSTALLED` has values **'Local - Monitored'** and **'Mobile Mechanic - No base location'** which are not in PL101. What is the closest PL101 option? (`LocalAudibleOnly` / `MonitoredBacktobase` / `None`?) | Small count — but will pass through as invalid code |
| Q4 | Source `DEADLOCKSINSTALLED` and `GRILLKEYLOCKINSTALLED` have value **'Other'** which is not in PL101. What should this map to? (`None`?) | Small count — will pass through as invalid |
| Q5 | 32 motor policies have blank `VEHICLETYPE` in Pure. Is defaulting to **`PassengerVehicle`** acceptable? | 32 policies affected |
| Q6 | `MAINWALLCONSTRUCTION` has values **'Steel'** and **'Some Asbestos and Brick'** not in PL101. Closest mapping? (`IronSteel`? `Asbestos`?) | Small count — will pass through as invalid |

---

> ¹ `Fibro (Non-Asbestos)` → mapped to `FibroHardiplank` (handled in code — no client action)  
> ² `Steel`, `Some Asbestos and Brick` → NOT in PL101 — client decision needed (Q6)  
> ³ Source values with no PL101 equivalent — passthrough produces invalid code in DCT
