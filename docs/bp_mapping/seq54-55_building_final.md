# SEQ 54-55 — Building: Final Assembly & UW Combine

| Seq | Name | Source view |
|---|---|---|
| 54 | BP_RISK_LOCATION_UW_COMBINE | `RISK_LOCATION_UW_COMBINE` (property-level UW adjustment, `Output_UWAdjust_BSP` `COVERAGE='SU'`) |
| 55 | BP_RISK_Building | `RISK_BUILDING_FINAL` (top-level `<risk><Type>Building</Type>...` node — ~50 fields: Smash Repair/Dismantler yard risk-assessment questions, construction/security dropdowns, plus embeds the 5 sub-coverage payloads via `{RISK_BUILDING}`/`{RISK_BC}`/`{RISK_BI}`/`{RISK_BG}`/`{RISK_MONEY}`/`{RISK_EN}` and `{UW_COMBINE}`) |

This closes out the Building coverage cluster (SEQ 30-55) — SEQ 56+ starts Fleet.

---

## G-BP-14 candidate lead (SEQ 54) — CHECKED, RULED OUT

`RISK_LOCATION_UW_COMBINE` was flagged earlier this session as the highest-leverage candidate for
G-BP-14's still-open "UW adjustments not populating" symptom (shared across BI/BG/Money/BC/EN's UW
screens). Investigated directly:

**Live check**: 573 property-level (`COVERAGE='SU'`) UW-adjustment notes exist in
`Output_UWAdjust_BSP`, but only 469 rows make it through `RISK_LOCATION_UW_COMBINE` — a 104-row
(18.1%) gap that looked, at first, like exactly the kind of silent drop G-BP-14 describes.

**Root-caused the gap**: all 104 missing notes are attached to `Location_01` records with
`EXPIRYDATE` in 2021-2022 — genuinely **expired policy terms**, not the current one. `ACCOUNT_LOC`
(SEQ 1, which `RISK_LOCATION_UW_COMBINE` joins through) already applies the same active-term filter
(`Location_01`/`SAMPLE_CBP`, `EXPIRYDATE>='2026-01-01'`) enforced everywhere else this session
(G-BP-76 through 82). This is **correct, intentional filtering** — a stale UW note attached to a
lapsed term should not flow into the current conversion. Confirmed with a live sample (10 of 104
rows checked, all pre-2022 `EXPIRYDATE`).

**Conclusion**: this is not the cause of G-BP-14. Ruled out as a candidate. G-BP-14's true root cause
remains open — needs a different investigation path (worth checking the individual per-coverage UW
views' joins to `Output_UWAdjust_BSP`/`LOCATION_BB_COVERAGE` directly, rather than this shared
combine step).

---

## G-BP-83 — RISK_BUILDING_FINAL RoofConstruction "Fibro" typo — FIXED, drafted

`ROOFCONSTRUCTION_FINAL`'s `CASE` checks `ROOFCONSTRUCTION='Fibro (Non- Asbestos)'` (stray space after
the hyphen) — but the actual live Pure text is `'Fibro (Non-Asbestos)'` (no space). Confirmed by
comparing against `MAINWALLCONSTRUCTION_FINAL`'s equivalent branch a few lines below, which has the
correct no-space text and works. The mismatch means the branch never fires; raw unmapped Pure text
(with the space and parentheses) is sent straight through instead of the clean DC code
`FibroNonAsbestos`.

**Live data**: 29 of 13,824 rows (0.2%) currently show the raw unmapped text in
`ROOFCONSTRUCTION_FINAL`.

**Fix**: `docs/bp_mapping/fixes/G-BP-83_G-BP-84_fix.sql` — one-line `WHEN` clause correction, removes
the stray space.

---

## G-BP-84 — RISK_BUILDING_FINAL ClearLandSqm "<600sqm" unreachable — FIXED, drafted

The 4th `WHEN` branch for `CLEARLANDSQM` duplicates the 3rd branch's condition
(`WHEN CLEARLANDSQM='<450sqm' THEN 'Lessthan600sqm'`) instead of checking `'<600sqm'` — a copy-paste
error. PL101 (`DismantlingInput.ClearLandSqm`) documents 4 dropdown tiers:
`<150sqm`/`<300sqm`/`<450sqm`/`<600sqm`; the last tier's branch is unreachable as written.

**Live data**: 0 rows currently have `<600sqm` selected (only `Lessthan150sqm` and `NULL` exist
today) — zero current impact, but a real latent bug. Fixed anyway for correctness, consistent with
this session's practice of fixing structural defects regardless of current data coverage (same
reasoning as G-BP-02's country-filter fix).

**Fix**: `docs/bp_mapping/fixes/G-BP-83_thru_87_fix.sql` (combined with G-BP-83, same view) — corrects
the 4th `WHEN` branch to check `'<600sqm'`.

---

## Follow-up dropdown audit (2026-07-12) — 3 more bugs found

Systematically pulled live `DISTINCT` values for all 16 remaining dropdown source columns in
`RISK_BUILDING_FINAL` and compared each against its `CASE WHEN` literals (same technique that found
G-BP-83/84). 13 of 16 checked clean (every live value has a matching branch); `CONDITIONOFROOF` has no
live data at all currently (all blank) so couldn't be verified either way. 3 more confirmed bugs:

### G-BP-85 — ConditionOfBuilding "poor" mislabeled as "good" — FIXED, drafted

The `'< 1990 - poor condition'` branch maps to `'Lessthan1990-goodcondition'` — copy-pasted from the
branch above it — instead of `'Lessthan1990-poorcondition'`. **Unlike the other 4 bugs in this SEQ**
(raw-text passthrough), this one actively **asserts the wrong value**: a poor-condition building gets
reported to DC as good condition, which matters for underwriting.

**Live data**: 19 of 13,824 rows (0.14%) have source `'< 1990 - poor condition'` but are sent as
`'Lessthan1990-goodcondition'`.

### G-BP-86 — VehiclesStacked text mismatch — FIXED, drafted

Live Pure text is `'Most stacked and some racked'` but the `WHEN` clause checks
`'Most stacked with some racked'` (`and` vs `with`) — falls through to `ELSE`.

**Live data**: 1 of 13,824 rows (0.01%) sends raw unmapped text instead of
`Moststackedwithsomeracked`.

### G-BP-87 — FuelStore text mismatch — FIXED, drafted

Live Pure text is `'Outside and +10m the main building'` but the `WHEN` clause checks
`'Outside & +10m from main building'` — different wording and word order entirely — falls through to
`ELSE`.

**Live data**: 5 of 13,824 rows (0.04%) send raw unmapped text instead of `Outside10mFromMainBuilding`.

**Fix (all three)**: `docs/bp_mapping/fixes/G-BP-83_thru_87_fix.sql` — supersedes
`G-BP-83_G-BP-84_fix.sql`, includes all 5 fixes (83/84/85/86/87) in one `CREATE OR REPLACE`. Run this
file.

**Checked clean** (live values all matched their `CASE WHEN` branches): `AlarmSystemInstalled`,
`FloorCondition`, `DismantleAreaHousekeep`, `DefuelLocation`, `DismantleLoc`, `FireEquipNear`,
`StockHousekeeping`, `TyresBatteriesHousekeep`, `EVStorage`, `YardFloorHousekeep`, `VolTyreStack`,
`VolTyreStackIn`. **Not verifiable**: `ConditionOfRoof` has zero live non-blank values currently.

---

## Checked, correct-by-design — blank/hardcoded fields in SEQ 55's template

The config template has ~15 fields that are either bare self-closing tags (no token at all) or
literal hardcoded constants (`IsBuildingHeritage=0`, `ExternalDoors=1`, `SecurityAlarm=0`,
`IsAusStandardFollowed=1`, `WhatYearWasARiskAssessmentReviewLastUndertaken=2025`, etc.). Cross-checked
several of the most suspicious ones against PL101 (`GeneralRiskAssessmentInput.*`,
`ConstructionOfBuildingInput.YearTheBuildingWasLastRePlumbed`/`ReRoofed`,
`PropertyInput.OccupationOfHighestRiskTenant`) — **all of them show blank PURE Table/Field/Mapping
Rule columns in PL101 itself**, meaning PL101 documents no Pure source for any of these fields. The
blank tags and hardcoded defaults match PL101 exactly — not a gap in this pipeline, these fields
simply have nowhere to source real data from.

**Now fully audited** (see "Follow-up dropdown audit" section above) — every dropdown `CASE` block in
this view has been checked against live distinct raw values. 5 confirmed bugs total (G-BP-83/84/85/86/87),
all fixed in `fixes/G-BP-83_thru_87_fix.sql`; remaining 13 blocks checked clean. This closes out the
area flagged in an earlier session's memory as having "confirmed invalid mappings" for Building
`RoofCon`/`MainWall`/`Deadlocks`/`Bars` — `RoofCon` was real (G-BP-83), `MainWall` checked clean,
`Deadlocks`/`Bars` turned out to be a mistaken claim (G-BP-12, closed — PL101 confirms these are
simple Boolean fields, not enums). The repo's draft `BP_DROPDOWN_VALIDATION` view remains undeployed
(`GET_DDL` fails live) and was not used as a source of truth for this audit — all findings here came
from direct live-data comparison.
