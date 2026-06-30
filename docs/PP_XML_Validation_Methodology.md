# PP Conversion — XML Payload Validation Methodology

**Date:** 2026-06-27
**Author:** Conversion Team
**Scope:** Personal Protection (PP) — Building Risk (Seq 14) and Motor Risk (Seq 18)
**Reference Manuscript:** `Carrier_PersonalProtectionBase_1_0_0_0` v1.0.0.0

---

## 1. Overview

This document describes how the generated XML payloads for Personal Protection (PP) policies were validated against the authoritative DCT manuscript before deployment. Validation had three layers:

1. **Manuscript cross-reference** — parsing valid `<option value="...">` codes from the manuscript XML
2. **Source gap analysis** — comparing distinct source values in Snowflake against the valid code list
3. **Token completeness check** — confirming all `{COLUMN_NAME}` placeholders were resolved in the target payloads

---

## 2. Understanding the DCT Manuscript Inheritance Structure

### 2.1 Manuscript File

```
Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/
  CarrierPersonalPackage/CW-INH/
    Carrier_PersonalProtectionBase_1_0_0_0.xml
```

### 2.2 Inheritance Chain

DCT manuscripts use a two-tier inheritance model declared on the root element:

```xml
<ManuScript>
  <properties
    manuscriptID="Carrier_PersonalProtectionBase_1_0_0_0"
    inherited="Carrier_CoverageLibrary_Data_1_0_0_0"
    ...>
```

The `inherited` attribute points to a parent/base manuscript (`Carrier_CoverageLibrary_Data_1_0_0_0`) that defines the shared field catalogue for all carrier products. The child manuscript (`PersonalProtectionBase`) then **overrides** specific fields for the Personal Protection product line.

### 2.3 Object Hierarchy

Fields are nested inside a deep object tree. All field IDs fully qualify their path:

```
data
└── Policy (abstract)
    └── PolicyPrivate (abstract)
    └── Line (abstract)
        └── LocationAdditionalQuestions (abstract)
            └── SituationDetails
                └── SituationDetailsInput
                    └── SituationDetailsInput.HomeBuildingOccupied   ← enum field
        └── ConstructionOfBuildingInput (abstract)
            └── ConstructionOfBuildingInput.MainWallConstruction      ← enum field (override="1")
            └── ConstructionOfBuildingInput.RoofConstruction          ← enum field (override="1")
            └── ConstructionOfBuildingInput.FloorConstruction         ← enum field (override="1")
    └── Vehicle (abstract)
        └── VehicleInput
            └── VehicleInput.VehicleType                              ← enum field (override="1")
            └── VehicleInput.ProtectionType                           ← enum field (override="1")
```

### 2.4 What `override="1"` Means

A field marked `override="1"` replaces the definition inherited from the parent manuscript. **This is critical for validation:** the override field's `<options>` block is the final authoritative list — the parent's option list no longer applies. All valid `value` attributes must be sourced from the child's override, not assumed from any base.

```xml
<!-- Example: RoofConstruction overrides parent with PP-specific options -->
<public id="ConstructionOfBuildingInput.RoofConstruction"
        path="RoofConstruction"
        type="string"
        override="1">           <!-- ← replaces parent definition entirely -->
  <definition>
    <options>
      <option value="Asbestos"     caption="Asbestos" />
      <option value="Colourbond"   caption="Colourbond" />
      <option value="Concrete"     caption="Concrete (Flat Roof)" />
      <option value="IronSteelTin" caption="Iron/Steel/Tin" />
      <option value="Tile"         caption="Tile" />
      <option value="Wood"         caption="Wood (Shingles)" />
    </options>
    <formatMask idref="FormatMask.BlankOption" />  <!-- field renders blank if unmatched -->
    <required idref="True" />
  </definition>
</public>
```

### 2.5 `idref` Reusable References

Throughout the manuscript, `idref` attributes point to shared definitions rather than embedding values inline. Key refs used by PP enum fields:

| `idref` | Meaning |
|---|---|
| `FormatMask.BlankOption` | Dropdown renders blank/empty if the stored value doesn't match any option `value` — **this is why invalid codes cause UI blank fields** |
| `True` / `False` | Boolean constants |
| `Context.IsNotAccountHolder` | Read-only rule — field is locked if user is not account holder |
| `MaxLength.sValue` | String field max length constraint |
| `VehiclePrivate.RedBookDetailsRequiredCondition` | Required rule — conditional on whether RedBook lookup is active |

The `FormatMask.BlankOption` reference was the root cause of blank mandatory fields in DCT: when a payload contains a value like `ConcreteFlatRoof` or `OwnedleasedtoOthers-LongTermLease` that does not match any `option value=` in the override definition, DCT silently renders the field as blank rather than raising an error.

---

## 3. Step-by-Step Validation Process

### Step 1 — Read Valid Enum Codes from the Manuscript

For each enum field, the manuscript was opened and the relevant `<public id="...">` block was located. The `value` attribute of each `<option>` was recorded as the **only acceptable code** to send in the XML payload.

> **Rule:** The `caption` attribute is the human-readable label shown in the UI. The `value` attribute is what must be written into the XML. These are different and must not be confused.

Fields validated and their manuscript locations:

| Field | Object ID | Manuscript Line |
|---|---|---|
| MainWallConstruction | `ConstructionOfBuildingInput.MainWallConstruction` | 11548 |
| RoofConstruction | `ConstructionOfBuildingInput.RoofConstruction` | 11578 |
| FloorConstruction | `ConstructionOfBuildingInput.FloorConstruction` | 11607 |
| AlarmSystem | `SecurityFeaturesInput.AlarmSystem` | 11747 |
| Deadlocks | `SecurityFeaturesInput.Deadlocks` | 11763 |
| Grills | `SecurityFeaturesInput.GrillKeyLock` | 11777 |
| HomeBuildingOccupied | `SituationDetailsInput.HomeBuildingOccupied` | 11360 |
| VehicleType | `VehicleInput.VehicleType` | 2366 |
| ProtectionType | `VehicleInput.ProtectionType` | 2423 |

### Step 2 — Extract Distinct Source Values from Snowflake

For each field, a `SELECT DISTINCT` query was run against the source tables in `AGGNE.DEV`:

- **Building fields** — sourced from `AGGNE.DEV.LOCATIONDETAILS_PER`
- **Vehicle fields** — sourced from `AGGNE.DEV.PM_03`
- **Filter applied:** `EXPIRYDATE >= '2026-01-01'` (active policies only)

Example for VehicleType gap analysis (`sql/snowflake/diagnostics/vehicle_type_gap_analysis.sql`):

```sql
SELECT
    VEHICLETYPE AS SOURCE_VEHICLETYPE,
    CASE
        WHEN VEHICLETYPE = 'Passenger Vehicle'  THEN 'PassengerVehicle'
        WHEN VEHICLETYPE = 'Light Commercial'   THEN 'LightCommercial'
        -- ... all 13 mappings ...
        ELSE '*** UNMAPPED — hits ELSE passthrough ***'
    END AS DCT_VEHICLETYPE,
    COUNT(*) AS POLICY_ROWS
FROM AGGNE.DEV.PM_03
WHERE EXPIRYDATE >= '2026-01-01'
GROUP BY VEHICLETYPE
ORDER BY POLICY_ROWS DESC;
```

### Step 3 — Compare and Identify Gaps

The source values were mapped against the valid `value` codes extracted in Step 1. Any mismatch was flagged as a bug. Findings:

#### Building Risk (`PER_RISK_BUILDING_FINAL.sql`) — 5 Bugs Found and Fixed

| Field | Source Value | Bug in SQL | Correct DCT `value` |
|---|---|---|---|
| RoofConstruction | `'Concrete'` | Was mapped to `'ConcreteFlatRoof'` (does not exist in manuscript) | `'Concrete'` |
| RoofConstruction | `'Concrete (Flat Roof)'` | Missing branch — fell through to ELSE passthrough | `'Concrete'` |
| FloorConstruction | `'Wood - Concrete Footings'` | Was mapped to `'WoodConcreteFootings'` (wrong capitalisation) | `'WoodConcretefootings'` |
| HomeBuildingOccupied | `'Tenanted by member'` | Was `'Tenantedbymember'` (lowercase b) | `'TenantedbyMember'` |
| HomeBuildingOccupied | `'Owned leased to Others - Long Term Lease'` | Was `'OwnedleasedtoOthers-LongTermLease'` (hyphen in code) | `'OwnedleasedtoOthersLongTermLease'` |
| HomeBuildingOccupied | `'Owned leased to Others - Short Term Rental'` | Was `'OwnedleasedtoOthers-ShortTermRental'` (hyphen; wrong case) | `'OwnedLeasedtoOthersShortTermRental'` |

Additionally, `'Other'` appeared as a source value for Deadlocks and Grills — confirmed **not valid** in DCT (`AllDoors | SomeDoors | None` for Deadlocks; `AllWindows | SomeWindows | None` for Grills). Client decision required for these records.

#### Motor Risk (`PER_COM_PAYLOAD.sql`) — 3 Bugs Found and Fixed

| Field | Bug | Fix |
|---|---|---|
| `OVERRIDE` | Always `0` — DCT never used provided vehicle data | Set to `'1'` when `MVRBVEHICLEKEY IS NOT NULL AND TRIM(MVRBVEHICLEKEY) <> ''`, else `'0'` |
| `ProtectionType` | `'Comprehensive'` was mapped to `'FullComprehensive'` — this value does **not exist** in the manuscript (lines 2427–2433) | Corrected to `'Comprehensive'` |
| `VehicleType` | Raw passthrough — source values like `'Passenger Vehicle'` were not converted to DCT camelCase (`'PassengerVehicle'`) | Full 13-branch CASE added; 32 blank rows defaulted to `'PassengerVehicle'` (pending client confirmation) |

Also fixed in `run_all_seqs_pp.sql` Seq 18 template:

```xml
<!-- Before -->
<RedbookCode/>

<!-- After -->
<RedbookCode>{MVRBVEHICLEKEY}</RedbookCode>
```

### Step 4 — Token Completeness Check (Batch Validation)

After all fixes were deployed and the ETL was re-run by Aggne, a Python batch script (`scratchpad/batch_v2.py`) connected to Snowflake via the ConversionAgent SQL Server credentials (connection id=14) and checked `AGGNE.DEV.PER_RISK_BUILDING_TARGET` for any unresolved `{COLUMN_NAME}` placeholders using a regex:

```sql
SELECT ID, ITR_TYPE,
       REGEXP_COUNT(PAYLOAD, '\\{[A-Z_]+\\}') AS TOKEN_COUNT,
       REGEXP_SUBSTR(PAYLOAD, '\\{[A-Z_]+\\}') AS FIRST_TOKEN
FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
WHERE REGEXP_COUNT(PAYLOAD, '\\{[A-Z_]+\\}') > 0
ORDER BY CAST(LOAD_DATE AS DATE) DESC
LIMIT 5;
```

**Results (2026-06-27 run):**

| ITR_TYPE | Row Count | Unresolved Tokens |
|---|---|---|
| RISK_Building | 4,194 | **0** ✅ |
| RISK_Building_PM | 970 | **0** ✅ |

All payloads are clean.

---

## 4. VehicleType Dual Options Block (Special Case)

`VehicleInput.VehicleType` (line 2366) has **two `<options>` blocks** — this is unique in the manuscript:

```xml
<options validRef="VehicleInput.VehicleInfoOverride">
  <!-- 8 options shown when OVERRIDE=1 (RedBook override active) -->
  <option value="PassengerVehicle" ... />
  <option value="LightCommercial" ... />
  ...
</options>
<options>
  <!-- 13 options shown when OVERRIDE=0 or RedBook not active -->
  <option value="PassengerVehicle" ... />
  <option value="MobileEquipment" ... />
  <option value="TowTruck" ... />
  ...
</options>
```

The full 13-value set is the superset. The CASE mapping in `PER_COM_PAYLOAD.sql` covers all 13 to handle both scenarios correctly.

---

## 5. Test Policy Candidate — P00005611

To validate end-to-end in DCT via Aggne middleware, policy **P00005611** was selected as the best candidate because it exercises the maximum number of fixed fields:

| Attribute | Value |
|---|---|
| Policy Number | P00005611 |
| Roof Construction | Colorbond → maps to `Colourbond` |
| Floor Construction | Wood - Concrete Footings → maps to `WoodConcretefootings` (capitalisation bug was fixed) |
| Occupied | Owner Occupied → maps to `OwnerOccupied` |
| Vehicle data | Yes — 2 vehicles; exercises OVERRIDE, VehicleType, ProtectionType, RedbookCode |

**Validation steps in DCT:**
1. Trigger Seq 14 (RISK_Building) and Seq 18 (RISK_Building_PM) via Aggne middleware for P00005611
2. Send the generated payload to the PRD_XML import endpoint
3. Open DCT and navigate to the policy's building risk section
4. Confirm that mandatory fields (Roof, Floor, MainWall, HomeBuildingOccupied) display the correct captions, not blank
5. Navigate to the motor section and confirm VehicleType dropdown shows the correct caption and OVERRIDE is 1

---

## 6. Outstanding Items Requiring Client Decision

| Field | Issue | Record Count |
|---|---|---|
| VehicleType | 32 policies have blank/null VehicleType — defaulted to `'PassengerVehicle'` | 32 |
| Deadlocks / Grills | Source value `'Other'` is not a valid DCT code | TBC |
| FloorConstruction / MainWall / Roof | ~1,166 policies have empty construction fields | ~1,166 |
| RoofConstruction | `'Fibro (Non-Asbestos)'`, `'Some Asbestos and Brick'` have no DCT equivalent | TBC |
| MainWall | `'Steel'`, `'Some Asbestos and Brick'`, `'Other'` have no DCT equivalent | TBC |
| AlarmSystem | `'Local - Monitored'`, `'Mobile Mechanic - No base location'` not in manuscript | TBC |

---

## 7. Key Takeaway

The `FormatMask.BlankOption` idref in the manuscript means DCT silently renders a blank field — it does **not** raise an error — whenever the XML payload contains a `value` code that is absent from the field's `<options>` list. This makes it impossible to detect enum mismatches by looking at the DCT UI alone; they must be caught by cross-referencing the manuscript's `option value=` attributes directly against the CASE mapping logic in the source SQL views.
