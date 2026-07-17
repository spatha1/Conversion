# G-BP-53 / G-BP-54 / G-BP-55 — Fleet Vehicle Details cluster (seq 57, P1/P2)

**Field:** Make, Model, RB Vehicle Key, Market Value without Accessories, ImportType, FuelType,
PowerKW, TrackRear, VehicleType, DriveDescription (`<Vehicle Type="FleetVehicle">` node)
**Type:** Free text / read-only display fields, all `required` per manuscript row context
**DCT Values:** N/A (not dropdowns except VehicleType/ImportType, not yet re-checked)
**Wrong value sent:** varies by field — see table below; this cluster corrects an earlier wrong
hypothesis (originally filed as part of G-BP-48 against the `<risk>` node, SEQ 61)

### Manuscript block (exact, re-read 2026-07-09)

| Field | Manuscript id | DC xpath |
|---|---|---|
| BodyType | `FleetVehicleInput.BodyType` | `risk[Type="Motor"]/Vehicle[Type="FleetVehicle"]/BodyType` |
| ImportType | `FleetVehicleInput.ImportType` | `.../Vehicle[Type="FleetVehicle"]/ImportType` |
| CMRBPower | `FleetVehicleOutput.CMRBPower` | `.../Vehicle[Type="FleetVehicle"]/PowerKW` |
| CMRBTrackRear | `FleetVehicleOutput.CMRBTrackRear` | `.../Vehicle[Type="FleetVehicle"]/TrackRear` |
| AddAccessoriesOrModification | `FleetVehicleInput.AddAccessoriesOrModification` | `.../Vehicle[Type="FleetVehicle"]/AddAccessoriesOrModification` |

Source: `Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/CarrierCoverageLibrary/Carrier_CoverageLibrary_Data_1_0_0_0.xml`.
Every one of these fields sits on the **`Vehicle[Type="FleetVehicle"]`** node — i.e. SEQ 57
(`BP_Fleet_Vehicle_coverage`, template's `<Vehicle>...</Vehicle>` block), not SEQ 61's `<risk>`
node. This directly resolves G-BP-48's open question from the previous pass: SEQ 61's ~100 empty
tags are very likely correct-as-is (those fields aren't supposed to exist there for Fleet), and
G-BP-48 is downgraded accordingly. No RedbookCode / MarketValueWithoutAccessories entry found
anywhere in this manuscript file for FleetVehicle — see G-BP-53/54 below.

### Data

| Sub-gap | Ticket | Root cause | Status |
|---|---|---|---|
| Make/Model | ATP-11134 | `FLEET_VEHICLE_VIEW` WHERE filter (`YEAR<>0 AND MAKE<>'' AND MODEL<>''`) silently drops the whole vehicle — PP's PR-01 pattern | **Fixed, code-only** — `fixes/G-BP-55_fix.sql` |
| RB Vehicle Key | ATP-11130 | No RedBook-key column anywhere in `VEHICLECOVERAGES_FLEETVEHICLE` (41 cols checked) | **Open — data source unconfirmed**, `fixes/G-BP-53_G-BP-54_fix.sql` |
| Market Value w/o Accessories | ATP-11129 | No without-accessories column in source; only `ACCESSORIESVALUE` (with-accessories) exists | **Open — data source unconfirmed**, `fixes/G-BP-53_G-BP-54_fix.sql` |
| FuelType / PowerKW / TrackRear / VehicleType / DriveDescription / ModelOther / MakeOther | ATP-11127 | Bare empty tags in SEQ 57's template, no token — confirmed in full-67-config sweep | Open — not yet drafted this pass |
| ImportType | ATP-11127 (same ticket) | Hardcoded literal `"N/A"` in SEQ 57's template — not even a token | Open — not yet drafted this pass |

**Vehicle drop counts (`AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE`, live 2026-07-09):**

| Metric | Count | % |
|---|---|---|
| Total Fleet vehicle rows | 1,302 | — |
| Rows surviving into `FLEET_VEHICLE_VIEW` | 1,280 | 98.3% |
| Vehicles silently dropped | 22 | 1.7% |
| — of which blank MAKE | 21 | — |
| — of which blank MODEL | 21 | — |
| — of which YEAR = 0 | 0 | — |

### Query
```sql
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN YEAR = 0 THEN 1 ELSE 0 END) AS YEAR_ZERO,
  SUM(CASE WHEN COALESCE(TRIM(MAKE),'') = '' THEN 1 ELSE 0 END) AS MAKE_BLANK,
  SUM(CASE WHEN COALESCE(TRIM(MODEL),'') = '' THEN 1 ELSE 0 END) AS MODEL_BLANK
FROM AGGNE.DEV.VEHICLECOVERAGES_FLEETVEHICLE;

SELECT COUNT(*) FROM AGGNE.DEV.FLEET_VEHICLE_VIEW;  -- post-filter row count
```

### Honest scope

**Proven:** the Make/Model drop mechanism and its exact blast radius (22 vehicles, 1.7%) — this is a
straight code fix, no business decision needed, same shape PP already resolved and got client
sign-off on (PR-01).

**Not proven / needs the client or Aggne policy team:**
- Whether Fleet has a RedBook key or a without-accessories value anywhere in Pure at all (G-BP-53/
  G-BP-54) — cannot script a fix without knowing the source column, and PP's PR-05 already
  established the client won't accept "Fleet doesn't need RedBook" as an answer, so this has to be
  chased down rather than closed as N/A.
- FuelType/PowerKW/TrackRear/VehicleType/DriveDescription/ImportType (ATP-11127) haven't had their
  own data-source check yet this pass — flagged as the next piece of this cluster to pick up.
- Whether SAS/txt has an original client rule for any of these fields (PR-04-style check) — not yet
  run for Fleet specifically.

**Status:** G-BP-55 Fixed (code drafted, not deployed). G-BP-53/G-BP-54 Open, blocked on client
input. G-BP-48 downgraded (see README). Remainder of ATP-11127's fields still open, not drafted
this pass.
