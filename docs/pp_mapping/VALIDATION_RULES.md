# PP Validation Rules Catalog

Living record of every field-level validation rule discovered during the gap-by-gap review of
`docs/pp_mapping/PP_FieldMapping_AllSeqs.html`. Grows one entry per gap as we work through the
39-gap register. Each field entry follows the same shape so it can go straight to the client or
the Aggne policy team without reformatting.

**Entry format:**
```
Field: <name> (<XML path>)
Type: Dropdown | Free text | Hardcoded | Logic-only
DCT Values: <the accepted list, if a dropdown>
Missing mapping for / Wrong value sent: <what's broken>
Count by value (client-ready, comma-separated): <value: count, value: count...>
Query: <the exact SQL used>
Status: Open | Fixed | False Positive
```

---

## Process rules (not field-specific)

### PR-01 — Never silently drop a vehicle/record for one bad field (2026-07-09, client-approved)

**Decision:** Filters that exclude an entire record because one field fails validation (e.g. the
old `YEAR<>0 AND MAKE<>'' AND MODEL<>''` filter in `PER_COM_PAYLOAD`) are retired project-wide
going forward. Renewal runs **daily**, and Pure data completeness varies day to day — a vehicle
present today with good data may have been incomplete yesterday, or vice versa. Silently dropping
the whole vehicle hides the problem instead of surfacing it, and there's no guarantee the gap
self-heals on a later run.

**Rule:** Every record always flows through to the XML, even with blank/invalid mandatory fields.
Data-quality problems must be caught by the **validation report** (`SP_PP_XML_VALIDATE` /
`PP_XML_VALIDATION_RULES`) as a `BLANK_REQUIRED` or `INVALID_CODE` finding, not by exclusion.

**Applied to:** G-02 (seq 18 YMM filter) — see `sql/snowflake/1_conversion/PP/views/PER_COM_PAYLOAD.sql`.

**Follow-up needed:** confirm `PP_XML_VALIDATION_RULES` has (or gets) an explicit rule row for
Year/Make/Model blank-on-required, so removing the filter doesn't just trade a silent drop for a
silent blank — the report has to actually catch it.

---

### PR-02 — Manually-loaded reference tables are scoped to ~3 months, not the full book (2026-07-10)

**Context (client-provided):** a subset of reference tables were manually loaded by the client
covering only **~3 months of data**, not the full historical book. Any field sourced from one of
these tables will show blanks/gaps outside that window — this is **expected data scope, not a
conversion bug**, and should not be chased as a gap the way G-01–G-04 were.

**Rule:** when a gap's root cause traces back to one of these manually-loaded, scope-limited
reference tables, do not treat it as a code/mapping defect. Instead:
1. Note it in this catalog as **"Known limitation — scoped reference data"**, not Open/Fixed.
2. Still add a validation-report rule for it (per PR-01's pattern) so missing data is visible and
   trackable, distinguishing "outside the loaded window" from a genuine new data-quality issue.

**Candidate tables identified (2026-07-10, from SP scan):** a separate Snowflake schema,
`PRD_T5_EXTERNAL_AGGNE.RISK` (distinct from `PURE_SNAPSHOT`, which G-02's investigation already
confirmed is fully populated), holds a small set of tables with a different naming/data profile —
"template" and questionnaire-lookup tables rather than the live Pure policy feed:

- `RISK.SCHEDULE_CLAUSES_TEMPLATE` — feeds **every clause field**: HB clauses (seq 6), HC clauses
  (seq 12), Motor clauses (seq 17). **Directly relevant to G-38/G-39 and the seq 6/12 clause gaps
  — confirm this table's load scope before concluding those gaps are code bugs vs. known data
  limitations.**
- `RISK.QU_HEAVYDUTYDIESEL`, `QU_TYREDEALER`, `QU_CMHEAVY`, `QU_CMHIRE`, `QU_FLGENERAL`, `QU_FLHIRE`
  — business/fleet questionnaire lookups (BP-side, not PP, but noted for completeness).
- `RISK.FLEET_TEMPLATE` — fleet vehicle template (BP-side).

**Not yet confirmed (need client input):** whether `SCHEDULE_CLAUSES_TEMPLATE` specifically is one
of the ~3-month manually-loaded tables. If so, sparse/missing clause data should be read as
"outside the loaded window," not a mapping defect — re-evaluate G-38/G-39 through that lens when
we reach them.

---

### PR-03 — "Required when Override=1" may actually mean "required when Override=1 AND an underwriter is editing in the DCT UI" (2026-07-10, open question)

**Discovery (G-10):** the manuscript's shared required-condition for every RedBook-override field
(BodyType, NumberOfCylinders, DriveDescription, InductionType, GrossVehicleMass, EngineSize, plus
others) is `VehiclePrivate.RedBookDetailsRequiredCondition`, defined in
`Carrier_Package_Data_CW_1_0_0_0.xml` (~line 13563) as:

```
(VehicleInput.VehicleInfoOverride = True) AND (Context.IsUnderwriters = True)
```

`Context.IsUnderwriters` (`Carrier_Package_Workflow_1_0_0_0.xml` ~line 8545) checks the logged-in
user's `Role.Name` against `UnderwriterAssistant,Underwriter,UnderwriterManager`. Every gap so far
(G-03, G-05, G-06, G-09, G-10) has cited only the `Override=1` half of this condition and treated
the field as unconditionally required, because Override is force-set to `1` for every vehicle
(PP-CF-26).

**Open question — not yet resolved:** `Context.IsUnderwriters` is a role check tied to an
interactive UI session. Conversion delivers policies via XML/API import, which has no logged-in
"Role" in the same sense. It is unconfirmed whether DCT's import/validation engine evaluates
`required` idrefs at all during batch XML load, evaluates them and resolves `IsUnderwriters` to
`false` for a service/import account (meaning these fields are NOT actually enforced at
conversion time), or enforces them identically to the UI. This does not change any fix already
drafted (sending the real Pure value instead of a blank is correct regardless), but it may affect
how urgently these are pursued as P1 vs P2, and whether the payload needs to satisfy this rule at
all before DCT will accept it.

**Rule:** flag this explicitly to the Aggne policy team before final severity sign-off on any gap
that cites `RedBookDetailsRequiredCondition` (currently G-03, G-05, G-06, G-09, G-10). Do not
downgrade severity unilaterally — ask first.

---

### PR-04 — CONFIRMED: G-03/G-05/G-06/G-09/G-10 are one missing block, not five separate guesses (2026-07-10)

**Source of truth:** `SAS/txt/PrivateMotor_conversionscriptCapricorn.txt` (client-delivered SAS,
pre-Snowflake-port). Contains one `DO` block:

```sas
IF Override = 'Yes' AND MVCVOverride = 0 THEN DO ;
    EngineSize = MVRBEngineSize ;
    BodyType = MVCVBodyType ;
    GrossVehicleMass = MVRBGrossVehMass ;
    Description = MVCVDescription ;
    NumberOfCylinders = MVRBCylinders ;
    DriveDescription = MVRBDriveDescription ;
    InductionType = MVRBInduction ;
    ImportFlag = MVRBImportFlag ;
    IF BodyType = '' THEN DO ; <make/model lookup table> END ;
END ;
```

One rule: when the *output* Override flag is forced to `'Yes'` (PP-CF-26, applies to every
vehicle) but the *raw Pure* flag `MVCVOverride` says no real override happened, fall back to the
plain (non-OV) RedBook-matched column instead of the empty OV-only value.

**Checked against the Snowflake port** (`DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql`,
PM_02 build, ~line 8456-8505): only the **BodyType** half survived (make/model lookup table +
`ELSE MVCVBodyType`). The plain reassignments for **EngineSize, GrossVehicleMass,
NumberOfCylinders, DriveDescription, InductionType, ImportFlag** were dropped during the
SAS-to-Snowflake port — confirmed absent anywhere else in the SP.

**Effect:** this is the verified, single root cause behind G-03 (partially — BodyType's fallback
exists but the 'Other'/'Cab Chassis' handling is still separately missing), G-05, G-06, G-09, and
G-10. Not five independent "Override-gating" patterns as originally described — one missing
client-authored block, restorable in one PM_02 change (six `CASE WHEN Override='Yes' AND
MVCVOverride=0 THEN <raw column> ELSE <current column> END` expressions added alongside the
existing BodyType CASE).

**Rule:** for any future gap involving a RedBook-override field (`MV*OV` sourcing) that looks
Override-gated, check `SAS/txt/PrivateMotor_conversionscriptCapricorn.txt` (or the matching
commercial-line script) FIRST before drafting a fix — the client's original SAS may already
specify the exact correction, removing the need to ask for one.

**Follow-up needed:** `Description` is also in this SAS block. `VehicleFullDescription` was
marked OK in the seq18 write-up (`{DESCRIPTION}` reused) — recheck briefly when reached, though not
expected to be broken since PM_01 already sources it from `MVCVDescriptionOV`.

**Applied to fix drafts:** `fixes/G-10_fix.sql` rewritten to use this exact SAS logic instead of a
generic `COALESCE` guess. `fixes/G-05_fix.sql`, `fixes/G-06_fix.sql`, `fixes/G-09_fix.sql` still
describe the symptom correctly but should be updated to reference this same block before final
compile.

---

### PR-05 — RedbookCode is a needed field on every vehicle type, including Fleet (Aggne policy team, corrected 2026-07-10)

**Context (client-provided, corrected):** an earlier note in this catalog said "no RedBook data
for Fleet" and implied Fleet RedBook gaps could be waved off. The client corrected this: RedbookCode
is a **needed field for all vehicle types** — PM (Personal Motor), Fleet, everything. Do not treat
a blank/unwired RedbookCode on a Fleet vehicle as "expected, ignore it." The field should still be
populated/wired wherever the source data supports it.

**Rule:** RedbookCode gaps are real gaps regardless of vehicle type. G-13 (this catalog, PM/
Personal Motor) is the PP-scope instance — deploy that fix per `fixes/G-13_fix.sql`. If/when BP
work covers Fleet vehicles, check the equivalent RedbookCode wiring there too (Fleet uses its own
`FLEET_VEHICLE_*` source views, `FleetVehicleInput.RedbookCode` in the manuscript, and likely its
own config-table row) rather than assuming it's out of scope by this rule.

**Still open, unchanged:** whether `MVRBVEHICLEKEY` (PM's source column) is expected to ever
populate for Personal Motor specifically remains a separate question for Aggne policy team — this
correction is about not dismissing the *class* of gap for Fleet, not an answer to PM's 100% blank
rate.

---

## Field validation catalog

### Seq 18 — Motor

**Field:** State (`risk/State`)
**Type:** Free text (confirmed via manuscript — `VehicleInput.State` has no `<options>` block)
**DCT Values:** No formal dropdown. De facto convention used elsewhere in the manuscript (Fleet
excess-calc comparisons): `ACT, NSW, QLD, VIC, NT, SA, TAS, WA` (8 AU state/territory codes). NZ
has no case anywhere in that logic.
**Wrong value sent:** Hardcoded `"NSW"` for every vehicle regardless of actual state.
**Count by actual state (from PM_03, 4,377 vehicles):**
`VIC: 1342, WA: 891, NSW: 747, NZ: 629, QLD: 392, SA: 290, TAS: 63, NT: 16, ACT: 7`
**Query:**
```sql
SELECT STATE, COUNT(*) AS VEHICLES, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES,
       CASE WHEN STATE IN ('ACT','NSW','QLD','VIC','NT','SA','TAS','WA') THEN 'VALID AU CODE'
            WHEN STATE = 'NZ' THEN 'NZ — NO CASE IN MANUSCRIPT, CONFIRM WITH CLIENT'
            WHEN COALESCE(TRIM(STATE),'') = '' THEN 'BLANK'
            ELSE 'UNEXPECTED VALUE' END AS VALUE_CHECK
FROM AGGNE.DEV.PM_03 GROUP BY STATE ORDER BY 2 DESC;
```
**Status:** Open. **Ask Aggne policy team first:** what should `State` contain for NZ risks —
DCT's own logic has no NZ case.

---

**Field:** Year / Make / Model (`risk/Year`, `risk/Make`, `risk/Model`)
**Type:** Free text, all three `required` per manuscript (Package_Data 11793 / 11334 / 11342)
**DCT Values:** N/A (not dropdowns)
**Issue:** View's `WHERE YEAR<>0 AND MAKE<>'' AND MODEL<>''` filter dropped the entire vehicle
when any one was blank. **Retired 2026-07-09 — see Process Rule PR-01.**
**Count:** 3,589 vehicles (1,918 policies) were being dropped — but this figure is stale: `PM_01/
02/03` predate the ATP-10963 fix (retired the SAS rule that force-blanked these fields). Diagnosed
at the PM_01 level: **0** vehicles fail to join to `PER_VEHICLEDETAIL`, **0** have blank Year when
the join succeeds — the raw Pure source is fully populated; the blanking was self-inflicted by our
own PM_01→PM_02 transform, not an upstream data gap.
**Query:**
```sql
SELECT COUNT(*) AS DROPPED_VEHICLES, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES_AFFECTED
FROM AGGNE.DEV.PM_03 WHERE NOT (YEAR<>0 AND MAKE<>'' AND MODEL<>'');
```
**Status:** Fixed (filter removed 2026-07-09). Follow-up: confirm `PP_XML_VALIDATION_RULES` has a
BLANK_REQUIRED rule for these three fields so the validation report catches any genuine future gaps.

---

**Field:** BodyType (`risk/BodyType`)
**Type:** Dropdown, constrained further by VehicleType, required when `VehicleInfoOverride=1`
(effectively always, per PP-CF-26)
**DCT Values:** `Bus, Convertible, Coupe, Hatchback, PrimeMover, Sedan, Utility, Van, Wagon,
TowTruck, Transporter, MobilePlant, Motorcycle, Trailer, CamperVan, Caravan, Forklift` (17 codes)
**Missing mapping for:** blank at source, `Other`, `Cab Chassis` (maps to `CabChassis`, not a
valid DCT code)
**Count by missing value (client-ready):** `(blank): 3600, Other: 661, Cab Chassis: 10`
**Query:** see `vq/seq18_vq.sql` (G-03 block) for the full classification query.
**Root cause (two-part, not just a missing mapping table):**
1. `Other` was never given a branch in the view's 34-way CASE.
2. `PM_01`'s BodyType CASE only computes a value `WHEN t3.MVCVOverride = 1` (the *raw* Pure flag)
   — but the pipeline separately force-sets the output `Override` to `1` for every vehicle
   (PP-CF-26), so vehicles never actually overridden in Pure get a forced-mandatory field that
   was computed as blank. PM_02's fallback only fires when the raw value is null/blank, so a real
   value like `Other` doesn't qualify for the fallback either.
**Status:** Open. **Ask Aggne policy team first:** has BP already solved this same BodyType
mapping? Reuse its precedent instead of asking the client to invent one from scratch.

---

**Field:** DriveDescription (`risk/DriveDescription`)
**Type:** Dropdown, 4 codes, `required` per `RedBookDetailsRequiredCondition` (see PR-03)
**DCT Values:** `4wheeldrive, Frontwheeldrive, Rearwheeldrive, N-A` (CoverageLibrary 30449)
**Wrong value sent:** none — PM_01 emits plain-English captions ("4 Wheel Drive", "Front Wheel
Drive", "Rear Wheel Drive", "N/A") for RedBook codes 1-4; the view's CASE maps all four correctly
to the DCT codes with no gap.
**Count:** clean 1:1 mapping, no unmapped values found.
**Query:**
```sql
SELECT DRIVEDESCRIPTION, COUNT(*) FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
```
**Status:** False Positive — originally flagged as "captions sent, not codes" but the view already
converts captions to the correct DCT code values. No fix needed.

---

**Field:** NumberOfCylinders (`risk/NumberOfCylinders`)
**Type:** Dropdown, 1-16, `required` per `RedBookDetailsRequiredCondition` (see PR-03)
**DCT Values:** integers `1` through `16` (CoverageLibrary 30424) — no `0` or blank option.
**Wrong value sent:** `0` — the view wraps the source in `COALESCE(NUMBEROFCYLINDERS,0)`, turning
every NULL into the literal `'0'`, which is not a valid dropdown value.
**Root cause (two-part):** (1) same Override-gating pattern as BodyType — PM_01 only computes the
value `WHEN t3.MVCVOverride = 1`; (2) RedBook code `11` ("none") is deliberately mapped to `0` in
PM_01 for genuinely cylinder-less vehicles (trailers, EVs) — 512 vehicles carry this by design, not
by accident.
**Query:**
```sql
SELECT NUMBEROFCYLINDERS, COUNT(*),
       CASE WHEN NUMBEROFCYLINDERS BETWEEN 1 AND 16 THEN 'VALID' ELSE 'STILL INVALID' END
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
```
**Status:** Open. **Ask Aggne policy team first:** should the `NumberOfCylinders` tag be omitted
entirely for cylinder-less VehicleTypes rather than sent as `0`?

---

**Field:** InductionType (`risk/InductionType`)
**Type:** Dropdown, 4 codes, `required` per `RedBookDetailsRequiredCondition` (see PR-03)
**DCT Values:** `Aspirated, Supercharged, Turbocharged, TurboandSupercharged` (CoverageLibrary
30462)
**Missing mapping for:** `'Turbo and supercharged'` — PM_01's actual case-4 wording has no matching
branch in the view's 11-branch CASE (which instead matches RedBook-style phrasings PM_01 never
produces, e.g. `'Turbo Intercooled'`) and falls to `ELSE ''`.
**Count:** 4,279 of 4,362 vehicles (98%) blank — dominated by the Override-gating issue, not the
CASE mismatch (0 vehicles currently hit the unmapped-phrasing branch in the live snapshot, but it's
a live defect waiting for the right RedBook code to appear on a future renewal).
**Query:**
```sql
SELECT INDUCTIONTYPE, COUNT(*),
       CASE WHEN INDUCTIONTYPE IN ('Aspirated','Supercharged','Turbocharged','TurboandSupercharged')
            THEN 'VALID' WHEN COALESCE(TRIM(INDUCTIONTYPE),'')='' THEN 'BLANK' ELSE 'STILL INVALID' END
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
```
**Status:** Open. Pure code fix, no decision needed — see `fixes/G-06_fix.sql`.

---

**Field:** VoluntaryExcess (`risk/VoluntaryExcess`)
**Type:** Dropdown
**DCT Values:** `0, 250, 500, 750, 1000, 1250, 1500` (7 PP options)
**Wrong value sent:** `2000`, `5000` — PM_01's banding logic produces values above the PP option
ceiling (looks copied from BP, which allows higher excess bands).
**Count:** 9 vehicles currently affected; structurally, the banding also never produces `250`,
`750`, or `1250` at all — those three are unreachable regardless of the 2000/5000 problem.
**Query:**
```sql
SELECT VOLUNTARYEXCESS, COUNT(*),
       CASE WHEN VOLUNTARYEXCESS IN (0,250,500,750,1000,1250,1500) THEN 'VALID' ELSE 'STILL INVALID' END
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
```
**Status:** Open. **Ask Aggne policy team / client first:** what should raw excess amounts above
1000 map to — cap at 1500, re-band across all 7 options, or a different pricing-driven rule? Do not
guess a rounding rule for a customer-facing dollar amount.

---

**Field:** RegistrationNumber (`risk/RegistrationNumber`)
**Type:** Free text, `FormatMask.Rego` (capitals + numbers only, no spaces/specials)
**DCT Values:** N/A (format mask, not a dropdown)
**Wrong value sent:** lowercase, spaces, and special characters pass through uncleaned; a smaller
population contains VIN/engine/chassis/serial numbers typed into the registration field instead of
an actual rego.
**Count:** 484 total format violations — 352 (73%) fixable by uppercase+strip-non-alphanumeric;
~105-132 are genuine bad source data (no formatting rule can fix a VIN in the rego field).
**Query:**
```sql
SELECT COUNT(*) AS BAD_REGO FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE NOT REGEXP_LIKE(COALESCE(REGISTRATIONNUMBER,''), '^[A-Z0-9]*$');
```
**Status:** Open. Code fix covers 73%; remainder needs a validation-report flag
(`WRONG_DATA_TYPE`), not a formatting fix — see `fixes/G-08_fix.sql`.

---

**Field:** ImportType (`risk/ImportType`)
**Type:** Free text (confirmed — CoverageLibrary line 33000, no `<options>` block)
**DCT Values:** N/A (default `"N/A"`, no trailing space in the manuscript)
**Wrong value sent:** `'N/A '` (trailing space) from a PM_01 literal; blank when source
`MVCVOverride <> 1`.
**Count by value:** blank=3,584; `[N/A ]` (trailing space)=623; `[L]`=124; `[I]`=31 (total 4,362).
I/L are fine as free text — the real issues are the trailing space and the Override-gating blanks.
**Query:**
```sql
SELECT '['||IMPORTFLAG||']' AS VALUE_BRACKETED, COUNT(*) AS CNT
FROM AGGNE.DEV.PM_03 GROUP BY 1 ORDER BY 2 DESC;
```
**Status:** Open. Pure code fix, no decision needed — see `fixes/G-09_fix.sql`.

---

**Field:** EngineSize / GrossVehicleMass (`risk/EngineSize`, `risk/GrossVehicleMass`)
**Type:** Free text/int (no dropdown), both `required` per `RedBookDetailsRequiredCondition` (see
PR-03 — the required-condition also depends on `Context.IsUnderwriters`, not confirmed to apply to
batch XML import)
**DCT Values:** N/A (numeric, no format mask beyond `int`)
**Wrong value sent:** blank/`0` — PM_01 sources both fields **exclusively** from the RedBook
Override columns (`MVRBEngineSizeOV`, `MVRBGrossVehMassOV`); the raw non-override columns
(`MVRBEngineSize`, `MVRBGrossVehMass`) are pulled into PM_01 but never used as a fallback (unlike
Year/Make/Model, which got an explicit unconditional-passthrough fix under ATP-10963). PM_02/PM_03
pass both fields through unchanged.
**Count (3,306 vehicles in current live `PER_COM_PAYLOAD` snapshot — pre-G-02-fix filter still
live in Snowflake):** EngineSize blank/0 = 3,139 (95%); GrossVehicleMass blank/0 = 3,294 (99.6%).
Engine-less VehicleTypes (Trailer/Caravan/CamperVan/Forklift) = 348 of those, a legitimate subset.
**Query:**
```sql
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN COALESCE(TRIM(ENGINESIZE),'')='' OR ENGINESIZE='0' THEN 1 ELSE 0 END) AS ENGINESIZE_ZERO_BLANK,
  SUM(CASE WHEN COALESCE(TRIM(GROSSVEHICLEMASS),'')='' OR GROSSVEHICLEMASS='0' THEN 1 ELSE 0 END) AS GVM_ZERO_BLANK,
  SUM(CASE WHEN VEHICLETYPE IN ('Trailer','Caravan','CamperVan','MobileEquipment','Forklift') THEN 1 ELSE 0 END) AS ENGINELESS_TYPES
FROM AGGNE.DEV.PER_COM_PAYLOAD;
```
**Status:** Open. Pure code fix (`COALESCE(OV column, raw column)`), no decision needed — see
`fixes/G-10_fix.sql`. Severity pending PR-03 answer from Aggne policy team.

---

**Field:** AgeOfYoungestRegularDriver (`risk/AgeOfYoungestRegularDriver`)
**Type:** Numeric free text, `minimum`/`maximum` rules, `required` per `Context.IsAccountHolderWithSystemAdmin` (a different, UI-role-based condition than `RedBookDetailsRequiredCondition` — same open question as PR-03)
**DCT Values:** N/A (not a dropdown) — `VehiclePrivate.MinAge = 17`, `VehiclePrivate.MaxAge = 99`
(Package_Data 12343-12348)
**Wrong value sent:** blank (no default); **newly found** — PM_02 nulls values `<16`, but the
manuscript's actual floor is `17`, so an age of `16` passes through as "valid" when it's below
DCT's real minimum.
**Count:** 218 of 3,306 vehicles (6.6%) blank; 2 vehicles carry age `16` (below the real min of 17
but above PM_02's 16 cutoff); observed range 16-97.
**Query:**
```sql
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN COALESCE(TRIM(AGEOFYOUNGESTREGULARDRIVER),'')='' THEN 1 ELSE 0 END) AS AGE_BLANK
FROM AGGNE.DEV.PER_COM_PAYLOAD;
```
**Status:** Open. Threshold fix is **not** a pure code change — the existing `<16` cutoff was
previously documented as "matches DCT MinAge rule," but the manuscript says `MinAge=17`; two
sources disagree, so this needs confirmation from **both** the Aggne policy team (was 16 a
deliberate business choice?) and the client (which value should gate DCT acceptance) before
changing it. Blank population separately needs a validation-report rule, not an invented default —
see `fixes/G-11_fix.sql`.

---

**Field:** VehicleType (`risk/VehicleType`)
**Type:** Dropdown, split across two Override-gated `<options>` blocks
**DCT Values:** when `Override=1` (forced true for every vehicle, PP-CF-26): `PassengerVehicle,
LightCommercial, HeavyCommercial, Motorcycle, Trailer, CamperVan, Caravan, Forklift, TowTruck` (9
codes — TowTruck further gated by `VehiclePrivate.ShowOnHookExcess`). The `Override=0` set (never
applies here) additionally has `MobileEquipment, Tractor, Transporter, HeavyVehicle`.
**Wrong value sent:** none currently live — but the view's CASE treats all 13 captions (both
option sets combined) as valid, and falls back to `ELSE VEHICLETYPE` (raw, unvalidated) for
anything unmatched.
**Count:** 0 rows hit the 4 structurally-invalid captions or the ELSE branch today — Pure only
ever produces `Passenger Vehicle, Motorcycle, Caravan, Trailer, Heavy Commercial, Camper Van,
Forklift, Light Commercial`, plus blank (48 rows, defaults to PassengerVehicle, still pending
client sign-off per prior project notes).
**Query:**
```sql
SELECT VEHICLETYPE, COUNT(*) AS CNT FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
SELECT VEHICLETYPE, COUNT(*) AS CNT FROM AGGNE.DEV.PM_03 GROUP BY 1 ORDER BY 2 DESC;
```
**Status:** Open — latent defect, no current data impact. Pure code fix (allow-list + route
unmatched to validation report per PR-01) — see `fixes/G-12_fix.sql`.

---

**Field:** RedbookCode (`risk/RedbookCode`)
**Type:** Free text — triggers DCT's own market-value integration when non-blank, during
import-renewal transactions specifically (Package_Data ~11811, 12388-12394, 13783-13793)
**Wrong value sent:** empty tag — but the fix already exists in the repo, it just was never
deployed to the live SQL Server config.
**Finding:** `run_all_seqs_pp.sql` and `sps/DEV_PP_CONVERSION_RUN.sql` already have
`<RedbookCode>{MVRBVEHICLEKEY}</RedbookCode>` (documented in
`docs/PP_XML_Validation_Methodology.md`), but the **live** template — stored in the SQL Server
`PP_ConversionConfig` table, not these repo files — is still `<RedbookCode/>` per the most recent
snapshot (`reference/PP_ConversionConfig_snapshot_20260703.json`, captured *after* the repo fix).
The deployment script that pushed other PP config fixes to SQL Server
(`sql/sqlserver/PP_ConversionConfig_FIXES_20260702.sql`) does not include RedbookCode — missed
from that batch. Two stale repo copies (`run_seq18_now.sql`, `run_seqs17_18_final.sql`) still show
the old empty tag and could mislead anyone treating them as current.
**Count:** `MVRBVEHICLEKEY` is 100% blank (3,306/3,306) in current Pure data regardless — deploying
the config fix won't populate any value today, only stops discarding the column if/when Pure ever
carries a key.
**Query:**
```sql
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN MVRBVEHICLEKEY IS NULL OR TRIM(MVRBVEHICLEKEY)='' THEN 1 ELSE 0 END) AS KEY_BLANK
FROM AGGNE.DEV.PER_COM_PAYLOAD;
```
**Status:** Open — fix drafted and verified, not yet deployed to SQL Server. See
`fixes/G-13_fix.sql`. Separately: ask Aggne policy team whether a RedBook key is even expected to
populate for PP/personal motor.

---

### Seq 1 — Claim History

**Field:** DateOfClaim (`losshistory/DateOfClaim`)
**Type:** Date, `required=True` (unconditional), `maximum=DateTime.CurrentDate` (Package_Data
51029-51036)
**Wrong value sent:** none currently — 0 blanks, 0 unparseable, 0 future dates.
**Finding:** the view's `TRY_TO_DATE(REGEXP_REPLACE(TRIM(...), '[A-Za-z]', ''), 'YYYY-MM-DD')`
letters-stripping transform is defensive code for a problem the current source doesn't have —
`CLAIMHISTORY.DATEOFCLAIM` is already a native `DATE`-typed column, not free text. The pattern
(silent NULL on parse failure) is a live risk only if the source ever becomes free text again.
**Count:** 0 of 572 claim rows blank/unparseable/future-dated.
**Query:**
```sql
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN DATEOFCLAIM IS NULL OR TRIM(DATEOFCLAIM) = '' THEN 1 ELSE 0 END) AS DATE_BLANK
FROM AGGNE.DEV.PER_VW_CLAIM_HISTORY;
```
**Status:** Open (latent, not live) — add a validation-report rule per PR-01 rather than an
invented fallback, since there's currently nothing to fall back for. See `fixes/G-15_fix.sql`.

---

**Field:** Cause (`losshistory/Cause`)
**Type:** Dropdown, `required=True`, split across 3 `Line`-gated option sets (Package_Data
50994-51014 + `IsLineMotor/Liability/Property` 51106-51129) — not one flat list:
`Motor`→`AtFault,NotAtFault,Theft,Other`; `Liability`→`CustomerPropertyDamage,CustomerInjury,Other`;
`Property`→`Fire,Flood,Burglary,Other`
**Wrong value sent:** `'At Fault'` (caption, space) instead of `'AtFault'` on Motor-line claims.
**Count:** 30 of 572 claims (5.2%) — all Motor-line `'At Fault'`. `Fire/Flood/Burglary/Other`
already match DCT codes exactly (single-word values, no divergence). 0 Liability-line claims exist
in current data — that option set is untested.
**Query:**
```sql
SELECT LINE, CAUSE, COUNT(*) AS CNT,
  CASE
    WHEN LINE='Motor' AND CAUSE IN ('AtFault','NotAtFault','Theft','Other') THEN 'VALID FOR LINE'
    WHEN LINE='Liability' AND CAUSE IN ('CustomerPropertyDamage','CustomerInjury','Other') THEN 'VALID FOR LINE'
    WHEN LINE='Property' AND CAUSE IN ('Fire','Flood','Burglary','Other') THEN 'VALID FOR LINE'
    ELSE 'INVALID FOR THIS LINE'
  END AS DCT_CHECK
FROM AGGNE.DEV.PER_VW_CLAIM_HISTORY GROUP BY 1,2 ORDER BY 3 DESC;
```
**Status:** Open. Pure code fix (caption→code CASE, defensive for untested Liability captions too)
— see `fixes/G-16_fix.sql`.

---

### Seq 4/10 — HB/HC Sub-Coverages

**Field:** `coverage/Indicator` (all HB sub-coverage blocks: BFL_SD, BLD_SD, BAD_SD, BLD_BF/CY/EQ/ST, LLB_SD; seq 10/HC shares the pattern)
**Type:** Boolean — **not flat**, each block has its own computed rule in
`Carrier_PersonalProtectionBase_1_0_0_0.xml`: `BLD_SD`→`limit>0` (6333-6345); `BFL_SD`→`FloodDamage='Taken'`
(5880-5892); `LLB_SD`→`LandlordProtections='Taken'` (5894-5909, 5449-5456).
**Wrong value sent:** `1` hardcoded for every block regardless of the actual rule.
**Count:** BFL_SD (Flood) wrong on 2,313/3,054 (75.7%); BAD_SD (ALD) wrong on 1,439/3,054 (47.1%);
LLB_SD (Landlords) wrong on ≥2,097/3,054 (68.7%, owner-occupied signal). Structural blocks
(BLD_SD/BF/CY/EQ/ST) — 0% wrong today, every policy has a real non-zero limit, but still hardcoded
rather than rule-driven (future risk).
**Query:**
```sql
SELECT CODE, SVALUE, COUNT(*) FROM AGGNE.DEV.PER_BB_SUBCOVERAGES
WHERE CODE IN ('HBBFL_SD','HBBAD_SD') GROUP BY CODE, SVALUE ORDER BY CODE;
```
**Status:** Open. Flood/ALD/structural blocks are pure code fixes (data already present in the
row) — see `fixes/G-18_fix.sql`. Landlords needs Aggne policy team input: no Taken/NotTaken source
column exists for it today; occupancy type is a signal, not the manuscript's actual condition.

---

### Seq 2 — Prior Insurance

**Field:** PriorCarrier (`priorinsuranceinfo/PriorCarrier`)
**Type:** Dropdown, `required=True` (Package_Data 50946-50966)
**DCT Values:** `Allianz, CGU, Elders, GIO, MotorTradeDirect, NRMA, Other, QBE, SGIC, SGIO, Unknown,
VERO, Wesfarmers` (13 codes) — caption for `MotorTradeDirect` is `"Motor Trade Direct"`.
**Wrong value sent:** `'Motor Trade Direct'` (caption) instead of `'MotorTradeDirect'`.
**Resolved "conflicting evidence":** the live production Attach view
(`sql/snowflake/2_attach/PP/views/PA_PER_VW_CBP_COMPETITOR_INFORMATION.sql` line 11) already does
`CASE WHEN PRIORCARRIER='Motor Trade Direct' THEN 'MotorTradeDirect' ELSE PRIORCARRIER END` —
manuscript and proven production reference agree; the conversion view is just missing this line.
**Count:** 1 of 300 rows wrong; 0 off-list values (every other insurer name already matches a DCT
code exactly).
**Query:**
```sql
SELECT PRIORCARRIER, COUNT(*) AS CNT FROM AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION
GROUP BY PRIORCARRIER ORDER BY CNT DESC;
```
**Status:** Open. Pure code fix, no decision needed — see `fixes/G-17_fix.sql`.

---

### Seq 5/11/16 — UW Adjustments

**Field:** `UnderwritingAdjustment/AdjustmentSelection`, `UnderwritingAdjustment/Recurring/Indicator`
**Type:** Boolean dropdowns — `AdjustmentSelection` 0=%/1=$ (Package_Data 30027-30036);
`Recurring/Indicator` 1=Yes/0=No
**Verdict:** **False Positive** for seq 11 (HC) / seq 16 (Motor). Traced the live
`AGGNE.DEV.SP_PP_ADJ_EXP_PREM` procedure DDL: source selection filters `AJRecurringIndicator=1`
upstream (every row reaching the table is recurring by construction), and `UWAdjustAmount` is
computed as `(ExpPremium/(100+SUM_Adjustments))*AJAdjustmentPercent` — every adjustment is
percent-based in Pure but converted to a dollar figure before this table. Both hardcodes are
correct for the rows that appear. Confirmed against the identical logic in the live production
Attach path (`SP_PP_ADJ_EXP_PREM_POLICYATTACH.sql`). Seq 5 (HB) is separately moot per G-20.
**New finding (not in original register):** the `AJRecurringIndicator=1` filter silently excludes
non-recurring adjustments entirely — 59.9% of Motor adjustments (11,450/19,136) and 63.6% of
HC/HB adjustments (8,365/13,144) never reach DCT at all.
**Query:**
```sql
SELECT AJRecurringIndicator, COUNT(*) FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSMV GROUP BY 1;
SELECT AJRecurringIndicator, COUNT(*) FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSHC GROUP BY 1;
```
**Status:** False Positive (original claim) / new finding logged, needs Aggne policy team
confirmation on whether excluding non-recurring adjustments is intentional — see `fixes/G-19_fix.sql`.

---

### Seq 5 — HB UW Adjustments

**Field:** entire `UnderwritingAdjustment` block (seq 5)
**Wrong value sent:** N/A — output is wrong-sourced (reads BP/Business `Output_UWAdjust_BSP` +
`LOCATION_BB_COVERAGE`, not PER-side tables) AND never consumed (seq 7 has no `{UW}` token, hardcodes `UWAdjustmentIndicator=0`).
**Status:** Open — decision needed (in scope? repoint to `Output_UWAdjust_PER WHERE COVERAGE='HB'`
+ wire `{UW}`, or retire seq 5 entirely). See `fixes/G-20_fix.sql`.

---

### Cross-cutting — Seq 6/8/9/12/14/17 (Free text XML escaping)

**Field:** various description/free-text columns
**Wrong value sent:** unescaped `&`/`<`/`>` breaks XML.
**Count:** HB_CLAUSE 0, HC Specified Contents 15, HC exceed-values 186, seq14 SecurityMeasures 39,
seq17 clause descriptions 4 — 244 rows total across 5 views.
**Status:** Open. Pure code fix (one escaping helper, applied everywhere) — see `fixes/G-21_fix.sql`.

---

### Seq 7 — HB Coverage Block

**Field:** `coverage/Indicator` — **Status:** Open, 0 live impact today (no true HC-only policies
in current data) but real structural risk — see `fixes/G-22_fix.sql`.
**Field:** `coverage/Excess/{Standard,Imposed,Earthquake,Flood,Glass}` — **Status:** Likely False
Positive. Re-investigated: no source column exists anywhere (HB_02, PER_HomeContents,
Locationdetails_PER all checked) and the client's original SAS never computed these either. Ask
policy team to confirm inapplicable rather than treating as dropped data — see `fixes/G-23_fix.sql`.
**Field:** `coverage/GlassLimit` — **Status:** Open, decision needed. 100% of 3,054 HB rows carry
`HOMEBUILDINGSLIMIT` reused here; confirm whether that's intended or a distinct glass limit should
be sourced — see `fixes/G-24_fix.sql`.
**Field:** `coverage/ClassCode` (shared with seq 13) — **CONFIRMED via manuscript's own
`BusinessAndAPRAClassCode` lookup table** (CoverageLibrary line 58785-58824): `Building` and
`ContentsAndStocks` both map to APRA=`FISR`, Business=`BSP` — not the hardcoded `HH`/`HBC`.
Cross-validated against Motor's already-correct `DMV,DMV` entry in the same table. Affects 1,843 HB
+ 1,843 HC blocks (100%). **Status:** Open, pure code fix, no decision needed — see `fixes/G-25_fix.sql`.
**Field:** `coverage/Premium` (shared with seq 13) — **Status:** Open, decision needed. 1,109
HB+HC policies (60.2%) carry the identical `HMEXPPREM` total on both blocks; need to know if DCT
sums coverage premiums (double-count risk) — see `fixes/G-26_fix.sql`.

---

### Seq 9 — HC Specified Contents

**Field:** `SpecifiedContents` node emission — **Status:** Open, pure code fix (same pattern
already used for seq 8). 2,139 of 2,553 rows (83.8%) are empty/zero nodes that shouldn't emit at
all vs. 414 real items — see `fixes/G-27_fix.sql`.

---

### Seq 13 — HC Coverage Block

**Field:** `coverage/{clauses}` token — **Status:** Open, pure code fix (rename to `{HC_CLAUSE}`).
0 literal leaks but 41 policies have HC clauses loaded that never reach the block — see `fixes/G-28_fix.sql`.
**Field:** `coverage/Indicator` — **Status:** Open, pure code fix, confirmed live (734 HB-only
policies get a bogus HC block, unlike seq 7's mirror which shows 0 today) — see `fixes/G-29_fix.sql`.
**Field:** `coverage/FloodDamage` — **Status:** Open, pure code fix. 2,008 of 2,553 (78.7%) HC
policies are actually 'Not Taken' but told 'Taken'; `HC_02.FLOODDAMAGE` already has the real value
— see `fixes/G-30_fix.sql`.
**Field:** `coverage/HomeContentsLimits` — **CONFIRMED via manuscript** (PersonalProtectionBase
line 6602-6611): options are `Yes`/`No` only, `1` isn't valid at all. View already exposes
`{ANYITEMSEXCEEDVALUE}` (167 Yes / 1,676 No). **Status:** Open, pure code fix — see `fixes/G-31_fix.sql`.
**Field:** `coverage/HomeContentsTotal`, `SpecifiedContentsTotal` — **Status:** Open, pure code fix,
low urgency (both are DCT readOnly/recalculated output fields, but test-residue values 9100/622221
shouldn't ship regardless) — see `fixes/G-32_fix.sql`.

---

### Seq 14 — Outer Building Risk

**Field:** `risk/SICCode` — **CONFIRMED wrong via manuscript** (CoverageLibrary line 49513-49519:
`default idref="AccountPrivate.UWGroupForSICCode"` — DCT's own design defaults this from account
UW group, not a fixed literal). 100% of 1,399 risk nodes carry the wrong commercial classification
("General Mechanical Workshop"). **Status:** Open — recommend blanking to let DCT default; confirm
with policy team — see `fixes/G-33_fix.sql`.
**Field:** `risk/StandardExcess`, `ImposedExcess` — **Status:** Likely False Positive, mirrors G-23
at risk level, same investigation applies — see `fixes/G-34_fix.sql`.
**Field:** `risk/ExternalDoors`, `SecurityAccessibleWindows`, `SecurityAlarm`,
`LocationConnectedToTownWaterMain`, `StoreFlammableGoods`, `IsAusStandardFollowed` — fabricated
factual property assertions, no source column for any of them, 100% of 1,399 risk nodes. **Status:**
Open, decision needed — cannot determine correct values from code/data; may need blanking or may
need a real source confirmed — see `fixes/G-35_fix.sql`.
**Field:** ROOF/MAINWALL/ALARM/DEADLOCKS/GRILLS construction & security dropdowns — **re-checked
with fresh data: every current value is VALID**, 0% invalid today. The specific problem values in
the original gap description don't appear in current data. **Status:** Open (latent hardening only,
not urgent) — see `fixes/G-36_fix.sql`.

---

### Seq 15 — Motor Sub-Coverages

**Field:** `coverage/Indicator` (8 blocks) — **Status:** Open, decision needed, large confirmed
impact. Every ThirdPartyOnly policy (230) gets Comprehensive/CarHire/Glass/ChoiceOfRepair blocks;
every Comprehensive policy (2,701 combined) gets a Third-Party-Only block. Need the correct
code-per-ProtectionType matrix from the client — see `fixes/G-37_fix.sql`.

---

### Seq 17 — Motor Clauses

**Field:** `Clauses/ClausesSelection` — **CONFIRMED structural failure: 0% of clause codes
currently valid.** `UPPER(CAText)` breaks the ~96 mixed-case PM* codes; 71 legacy CM_* codes are
disabled (validRef=False) in PP with no mapping to their PM* equivalent. **Status:** Open — Part 1
(stop uppercasing) is pure code, no decision needed; Part 2 (CM_*→PM_* mapping table) needs
Aggne policy team/client confirmation — 4 pairs have an obvious naming-pattern match but 2 (CM_C02_YNGDRIVER,
CM_C10_FTLIAB) have no obvious equivalent — see `fixes/G-38_fix.sql`.
**Field:** `Clauses/SelectClauseDescription`, `Value`, `DescriptionValue` — **Status:** Open, pure
code fix, cosmetic. 178 of 1,862 rows forced ALL CAPS via `UPPER(CADescription)` — see `fixes/G-39_fix.sql`.

---

*(All 39 gaps now have a first-pass validation entry. G-03's per-VehicleType BodyType recheck and
a final consolidated compile are the two items still open from earlier in the review.)*

---

## G-40 through G-46 — new gaps from client ticket cross-reference (2026-07-09)

Source: `docs/pp_mapping/CLIENT_TICKET_MAPPING.md` — 13 client-reported tickets (epic ATP-10219)
that didn't match any of G-01...G-39. Of those 13, 6 were within PP scope with a findable PURE
field/DCT path (validated below); the other 7 (Contractors & Subcontractors limit, "Is Type
Standard", PF Vehicle Assessment/Breakdown Protection, PF Previous PF in place, SV Windscreen
Glass Excess, Tyre question) trace back to Product & Public Liability / Professional Protection /
unclear Motor add-ons that don't appear in any PP-scope manuscript searched (`LocationDetailsPER`,
`HomeContents`, `PrivateMotor`) — flagged as **scope-uncertain**, not validated, pending
confirmation these sections are even in the 18-seq PP register at all.

### G-40 — HC Specified Items Away From Premises: itemized list never migrated (ATP-11107)

**Field:** `coverage/SpecifiedItemsPremises` (Taken/Not Taken flag) **+ the itemized item list
behind it** — Type: Flag (works) + missing repeating item block.

Manuscript (`HomeContents_coversionscriptCapricorn.txt`): PURE builds a **separate** output,
`HC_AWAY`, sourced from `P_NO_PII.PER_ITEMSAWAYFROMPREM` (`ItemDescription`, `ItemValue`), filtered
`RLHomeBuildingsContents=1 AND (HCProtection=2 OR HCProtection=3) AND ItemDescription<>'' AND
ItemValue<>.` — this is a per-item Description/Value list, distinct from the in-home "Specified
Contents" list (`PER_HC_SPECIFIEDCONTENTS`, DESCRIPTIONSPECIFIED/VALUESPECIFIED — G-27's subject).

**Live check:** `SPECIFIEDITEMSAWAY` flag on `PER_HOME_BUILDING_PAYLOAD` is populated correctly
(1,636 Not Taken / 195 Taken) and the seq 13 template token `<SpecifiedItemsPremises>
{SPECIFIEDITEMSAWAY}</SpecifiedItemsPremises>` is wired correctly — the flag itself is fine.
But there is **no view, no ITR_TYPE, and no template node anywhere in the 18-seq pipeline** that
carries the actual item descriptions/values for the 195 "Taken" policies — `HC_02` has no
away-from-premises item columns (checked full 30-column list), and no `PER_ITEMSAWAYFROMPREM`-
sourced table exists in `AGGNE.DEV`.

**Impacted Count:** 195 of 1,831 HC policies show "Taken" but carry zero itemized detail (100% of
the Taken cases — the response survives, the items behind it don't).

**Status:** Open, needs input — before building a fix we need the DCT payload's expected node
shape for a repeating away-from-premises item list (is there even a node for this, and does the
target CW_Data manuscript define one?). Not yet in `fixes/` since the target shape is unconfirmed.

---

### G-41 — YearLastReWired / YearLastRePlumbed blank for old buildings (ATP-11105)

**Field:** `risk/YearTheBuildingWasLastReWired`, `YearTheBuildingWasLastRePlumbed` — Type: Year
(free text, DCT has no dropdown here).

Manuscript (`LocationDetailsPER_coversionscriptCapricorn V2.txt`): `HCLastRewired`/`HCLastReplumb`
→ `YearLastReWired`/`YearLastRePlumbed`, with a sentinel/blank rule: 0 → 1900 (unknown), non-4-digit
→ blank, and **`IF AgeOfBuilding < 41 THEN YearLastReWired = ''; YearLastRePlumbed = '';`** — i.e.
these fields should ONLY be blank for buildings under 41 years old.

**Live check:** the view (`PER_RISK_BUILDING_FINAL`) and the seq 14 template token
(`<YearTheBuildingWasLastReWired>{YEARLASTREWIRED}</YearTheBuildingWasLastReWired>`) are both wired
correctly — this isn't a view or config bug. The problem is upstream: of 584 buildings aged 41+
(`YEARBUILDINGCONSTRUCTED` between 1900–1985), **558 (95.5%) still show blank**, including
buildings built in 1900–1928 (98–126 years old) where the age-gate should never apply.

**Impacted Count:** 558 of 584 buildings aged 41+ (95.5%); 1,363 of 1,392 total risk-building rows
blank overall.

**Status:** Open, pure code fix (no client input needed) — root cause is upstream of
`PER_RISK_BUILDING_FINAL`, in whatever populates `LocationDetails_PER`'s source columns; the
age-gate condition needs to be found and corrected there. Not yet drafted — needs the upstream
source view identified first.

---

### G-42 — Private Motor Premium (contribution amount) always zero (ATP-11111) — **P1, confirmed root cause**

**Field:** `coverage/Premium` (Motor) — `{PMEXPPREM}` token, seq 18 template
(`<Premium>{PMEXPPREM}</Premium>`).

**Live check — smoking gun:** `AGGNE.DEV.Output_Coverage_PER` (the actual premium source table)
has real, non-zero `PMEXPPREM` values for 2,181 of 5,018 rows (43%) — the source data is fine. But
`PER_COM_PAYLOAD` (the view that feeds the seq 18 template) joins it wrong:

```sql
-- PER_COM_PAYLOAD.sql line 313 (current, broken):
LEFT JOIN AGGNE.DEV.Output_Coverage_PER T4 ON T1.PUREPOLICYNUMBER=T4.POLICYNUMBER
```

`T1.PUREPOLICYNUMBER` in this view is the **composite** key (`PURE|CML|EXPIRINGID_P`, built at line
104), but `T4.POLICYNUMBER` is the **plain** PURE policy number — they can never match. Every row
falls through to `COALESCE(T4.PMEXPPREM,0)` → `'0'`.

**Impacted Count: 3,304 of 3,304 rows (100%)** — Private Motor contribution amount is zero for
every single policy in the current payload.

**Status:** Open, pure code fix, no client input needed, **highest-severity item found this
session** — see `fixes/G-42_fix.sql`.

---

### G-43 — Location 1 property section missing for some policies (ATP-11110)

**Field:** `risk` node for `RISKNUMBER=1` (the first/primary property location).

**Live check:** `PER_ACCOUNT_LOC` has 4,239 distinct policies total, but only 4,004 have a row with
`RISKNUMBER=1` — **235 policies (5.5%) have location rows, just none numbered "1"** (their location
rows start at 2, 3, etc.).

**Impacted Count:** 235 of 4,239 policies (5.5%).

**Status:** Open, needs more investigation before it's clear this is a bug rather than a benign
gap in the risk-numbering sequence (e.g. Location 1 was deleted/renumbered in PURE itself). Not yet
root-caused — recommend pulling 3-5 sample `PUREPOLICYNUMBER`s from the 235 and checking their
Pure-side location history before drafting a fix.

---

### G-44 — Account Handler defaults to a developer's name (ATP-10961) — **confirmed root cause**

**Field:** `Account/Handler` — `HANDLERMAIL`/`HANDLERFULLNAME`.

**Live check — smoking gun:** `PER_CONVERSION_FINAL_LOAD` (line ~133-134, all 3 live copies —
`DEV_PER_CONVERSION_FINAL_LOAD.sql`, `UAT_DEPLOY_FINAL_SPS_20260703.sql`, and the
`BUG-NEW-04` fix file) has:

```sql
COALESCE(TRIM(T31.ACCOUNTHANDLEREMAIL), 'Aaron.Pang@capricorn.coop') AS HANDLERMAIL,
COALESCE(TRIM(T31.FULLNAME), 'Aaron Pang') AS HANDLERFULLNAME,
```

`VW_ACCOUNT_HANDLER_POLICYTEAM` is a legitimate lookup of ~180 real Capricorn staff (confirmed —
Aaron Pang is real personnel, first alphabetically in the view, not a fake/test name). The
`COALESCE` default was presumably meant as a rare last-resort fallback, but the
`T1→ACCOUNT_HANDLER(T30)→VW_ACCOUNT_HANDLER_POLICYTEAM(T31)` join chain is failing for the large
majority of policies, so the "fallback" is actually the common case.

**Impacted Count: 3,424 of 4,076 policies (84%)** show "Aaron Pang" as account handler.

**Status:** Open, needs investigation into why the T30/T31 join misses 84% of policies (likely a
key-format or `_IS_CURRENT` filter issue on `ACCOUNT_HANDLER`), plus a policy decision on what
should happen when no handler is found (blank vs. a real default) — see `fixes/G-44_fix.sql` for
the immediate symptom fix (stop defaulting to a named person) pending that decision.

---

### G-45 — "Legacy Start Date" — DCT field identity unclear (ATP-10962)

**Field:** unclear which DCT node "Legacy Start Date" refers to.

**Live check:** `PER_FINAL` has `INCEPTIONDATE`, `EFFECTIVEDATE`, `MEMBERSHIPSYSTEMDATE`,
`EXPIRATIONDATE` — no column literally named "legacy start date". In current data,
`MEMBERSHIPSYSTEMDATE` always equals `INCEPTIONDATE` (sampled), and `EFFECTIVEDATE` differs (looks
like a term/expiry-adjacent date, not the term start) — `INCEPTIONDATE <> EFFECTIVEDATE` on 4,019
of 4,076 rows (98.6%), which was previously logged as expected ("real inception history") in
`verify_full_run.py`, not re-examined against this specific ticket.

**Status:** Open, needs input — cannot confirm or deny a bug without the client naming the exact
DCT field/path "Legacy Start Date" maps to, since none of our columns carry that literal name.

---

### G-46 — PURE Motor-Only protections migrating with Location sections selected (ATP-10965)

**Field:** protection-type/section selection logic (not a single field — a structural
include/exclude decision).

**Live check:** `PER_FINAL.MOTOR_INDICATOR=1 AND HB_HC_INDICATOR=1` simultaneously for 260 of 4,076
policies (6.4%) — i.e. 260 policies carry both a Motor section and a Home Building/Contents section
indicator set. This is *consistent* with the complaint but not proof: `MOTOR_INDICATOR=1` doesn't by
itself mean "Motor-only in PURE" (a policy can legitimately have both Motor and Home cover). Confirming
this gap needs a source-side comparison — PURE's own `RLMotorVehicles`/`RLHomeBuildingsContents`
risk-selection flags (per the SAS manuscript) against the converted `HB_HC_INDICATOR`, which hasn't
been done yet.

**Impacted Count (partial evidence only):** 260 of 4,076 policies (6.4%) show both indicators.

**Status:** Open, needs more investigation before a root cause or fix can be drafted — flagging the
260-policy figure as a starting point, not a confirmed defect count.

---

*(G-40...G-46: 2 fully root-caused code fixes (G-42, G-44), 2 needing more investigation before a
fix can be drafted (G-41, G-43, G-46), 2 needing client/policy input on the target field/schema
(G-40, G-45). 7 further client tickets are scope-uncertain — see `CLIENT_TICKET_MAPPING.md` — and
have not been validated at all pending confirmation they belong in the PP register.)*
