# BP Gaps by Verification Source

All BP conversion gaps that were confirmed or root-caused using at least one of the 4 sources
below, with a concrete example and current status for each — regardless of whether it's fixed,
awaiting client confirmation, or awaiting policy team input.

**Legend — Status:**
`FIXED LIVE` verified in Snowflake · `FIXED (drafted)` fix written, not yet applied · `OPEN` not yet traced/fixed · `AWAITING CLIENT` needs client confirmation · `AWAITING POLICY TEAM` needs Aggne policy team / data input · `BLOCKED` blocked on a specific confirmation before a fix can be written

**"Closed · no defect" items are excluded from this document** — those were investigated and
found to be false positives (correct-by-design, or the original claim didn't reproduce against
live data), not real gaps. They're tracked separately in `README.md` for the audit trail, but
don't belong in a gap list.

**Totals:** SAS 7 · Pure-to-Write SP 55 · PL101 7 · Manuscript 6 (real gaps only — "closed, no
defect" items excluded as false positives)
(14 further items on the full register have no source-backed investigation yet and are excluded
here — see `README.md` for the complete list.)

---

## 1. SAS reference scripts (7)

Gaps found or confirmed by comparing the live Snowflake implementation directly against the
client's original pre-conversion SAS logic (`SAS/txt/*.txt`).

### G-BP-70 — UW Adjustment `AdjustmentSelection` always `'1'` ($), never `'%'`
**Status: OPEN — needs a business decision**
All 14 BP UW-adjustment views reverse-calculate every adjustment to a dollar figure regardless of
whether Pure recorded it as % or $. Client's original SAS (e.g.
`Generalproperty_conversionscriptCapricorn.txt`) dynamically derives `AdjustmentSelection` from
which of `AJAdjustmentPercent`/`AJAdjustmentValue` is populated. Example: every one of the ~2,000+
live adjustment rows checked shows `'$'` even where the source was clearly a % entry. Not a
data-loss bug (only 1 row dropped globally) — a labeling/type divergence. Needs a decision: keep
the dollar-normalization, or restore original type/value per SAS.

### G-BP-16a — Additional Interest, parties with no Location/Line tie dropped
**Status: FIXED LIVE**
`AOI_FINAL`'s `WHERE LOC_VALUE IS NOT NULL OR LINE_VALUE IS NOT NULL` silently dropped every
interested party with no Location/Line coverage tie (e.g. a Finance-only party). Client's
original SAS (`Additional interested conversionscriptCapricorn.txt`) had an explicit "Step 3"
(`NO_LOC_LINE` table) for exactly this case that never got ported. Example: policy P00010027
(ATP-10980) — row count went from 4,897 → 5,167 policies after the fix; this exact policy now
shows all 3 interested parties including "Australia and New Zealand Banking Group Ltd : Finance".

### G-BP-95 — Turnover Details/Display fields not gated by their own Yes/No flag (8 field-groups)
**Status: FIXED LIVE**
Business Details' "IsX/Details_X/Display_X" field triplets (Mining, Heavy Transport, Watercraft,
etc.) had the flag correctly derived but the detail/display amount leaking through even when the
flag said "No." Re-reading `SAS/txt/BusinessDetails_conversionscriptCapricorn Corrected V2.txt`
line-by-line surfaced 6 more real deviations beyond the original gating fix: an outer eligibility
gate wrapping almost the whole section (5,968 of 20,949 rows, 28.5%, fail it and should be
blank), `Turnover_Less_Fuel` used instead of plain `Turnover` in all 14 display formulas, a
Prof/LE/TA substitution fallback that was entirely missing, a Tyre eligibility gate, ordered
Import/Manufacture gating, and the SAS ">30%" blanking rule. Example: ATP-11050's policy
P00034499 now returns `'No', 0, 0, NULL` exactly as expected — was showing `MiningDetails=1`,
`MiningDisplayValue=4200` despite the flag correctly saying "No." Also directly confirmed 9
tickets fixed by a full-batch sweep of the 14 Jul UAT batch (0/152 records show the leak on any
of the 8 field-groups).

### G-BP-97 — Run-Off + Public&Product-Liability policies excluded from the entire conversion
**Status: FIXED (drafted), not yet applied — large blast radius**
`Sample_CBP` — the foundational staging table 17 other tables join to directly — excludes any
policy that's both Run-Off and has PL from the *entire* conversion (Location, CM, Fleet,
Business Details), not one field. SAS has a matching filter, but its own comment scopes it
narrowly: *"Fetch public liability coverage data - which is not Run-Off"* — meant to exclude
Run-Off only from the PPL coverage line (`PP_01`), which already has its own independent, correct
version of this filter. Example: 848 policies currently match the exclusion condition and are
missing from `Sample_CBP` today — this directly explains ATP-11068's "broken"/empty Business
Information screen (P00034480, P00034537 both still show every field blank as of the 14 Jul UAT
batch, matching this exact root cause). Fix drafted at `fixes/G-BP-97_fix.sql`, held for a
deliberate re-run decision given the scope.

### G-BP-14 — Underwriting Adjustments not populating (BG/BI/EN/Money)
**Status: OPEN — true root cause still unresolved**
Reported independently across 4 test-execution docs for Burglary, Business Interruption,
Engineering, and Money. Checked whether G-BP-70's percent-only filter explains it (it doesn't —
only 1 row dropped globally); checked `RISK_LOCATION_UW_COMBINE`'s active-term filter (drops 104
of 573 rows, but all are genuinely expired terms — correct, not a bug). Next candidate: the
`ExpPremium_BSP`/`Adjustments_BSP` join in `ADJUSTMENTS_BSP_OUT`, or `RECURRINGINDICATOR`'s
hardcode against SAS's `WHERE AJRecurringIndicator=1` filter (the view checks
`UWADJUSTNOTE IS NOT NULL` instead — a different condition).

### G-BP-56 — CM Overridden Vehicles incorrect
**Status: OPEN — SAS check not yet run**
"Incorrect for Overridden Vehicles in UI + Clarity" — possibly the same override-fallback bug
class PP found (its PR-04) on the BP/CM side. Flagged as needing a check against
`SAS/txt/CommercialVehicles_conversionscriptCapricorn.txt` before scoping a fix.

### G-BP-72 — TA required fields (SumInsured/ListOfDirectors/PreviousTaxAudit), zero Pure source
**Status: OPEN — no client ticket yet, self-identified**
3 manuscript-required fields sent as bare empty tags on 100% of 2,162 TA records. Checked Pure's
entire Tax Audit table (`cbp_taxaudit`) — it only has 5 columns, none matching these 3 fields.
Matches the client's own original SAS exactly, so this was never captured by the original design
either — not a Snowflake-port regression. Example: `SumInsured`'s dropdown ($10k/$20k/$50k/0)
doesn't even overlap with `TaxAuditLimit`'s banding, ruling out reuse as an approximation. Worth
raising proactively since it's a `required`-field gap on every TA policy.

---

## 2. Pure-to-Write SP / live Snowflake (55)

The primary investigation tool throughout — gaps found or confirmed by reading the live
conversion SP/views directly in Snowflake, or by querying live staging/target tables and DCT
payloads. A representative sample of the largest and most illustrative findings follows (full
list of all 68 IDs at the bottom of this section).

### G-BP-90 — Commercial Vehicle per-vehicle sub-coverage cross-contamination
**Status: FIXED (drafted) — largest-scale, highest-severity finding this session**
`CV_COVERAGE_VEHICLE_SUBCOV`/`CV_COVERAGE_VEHICLE_COV` key on policy+cml+term — no `VEHICLEID` —
even though it's available and used correctly by sibling views. A two-hop `LISTAGG` aggregation
then concatenates every vehicle's sub-coverage data onto every other vehicle sharing that key.
Example: policy `P00009911|CML00000309|575099` (3 vehicles) renders a payload with 3 conflicting
`<CMP_SD>` blocks (iValue 121500/309200/0) inside every one of its 3 vehicles' XML. Live impact:
44,836 CV vehicle rows, 8,256 keys (72.2%) hold more than one vehicle, 5,017 keys (43.9%) have
genuinely different `ProtectionType`s sharing one key — actively wrong today, not latent risk.

### G-BP-88 — Fleet composite key has no per-vehicle identifier
**Status: FIXED (drafted)**
`FLEET_VEHICLE_SUBCOVERAGES`/`FLEET_VEHICLE_VIEW` key on policy/cml/term only — 1,222 Fleet
vehicles collapse to 52 distinct keys, every vehicle sharing a key gets byte-identical
sub-coverage XML (verified directly: 5 vehicles under one key returned identical `SUBCOV_XML`).
Fixed by widening the key to include `REGISTRATIONNUMBER` — 52 → 1,194 distinct keys.

### G-BP-93 — Additional Interest, LINE-tied parties dropped by stale flags
**Status: FIXED LIVE**
`AOI_FINAL` gates each of 8 line ties on a `BUSINESSDETAILS_FINAL` flag; when the flag disagrees
with reality the party is silently dropped. Example: checked against the real `LINE_xx_Target`
tables directly — 213 of 258 dropped LINE-tied parties (82.6%) actually had real coverage.
Confirmed live: `AOI_FINAL` row count went from 5,168 → exactly 5,381 after the fix, matching the
simulation precisely.

### G-BP-94 — Tyre Dealer / Heavy Duty Diesel Mechanic UW joins unkeyed
**Status: FIXED LIVE**
`Businessdetails_Final` joins two raw Pure SCD reference tables via `USING (PUREPOLICYNUMBER)`
only — no term disambiguation, plus untrimmed padding could silently break the join. Example:
ATP-11137's exact reported policy P00009659 now correctly shows `PERTOVEHSERVICE='90'`,
`FRANCHISE='1'` in the final master output view — was blank before despite Pure genuinely having
90%/Yes. Traced precisely: the join was attaching current-term identity to an unrelated expired
term's (blank) UW answers.

### G-BP-98 — CM Yes/No UW fields sent as raw text instead of numeric 0/1
**Status: FIXED (drafted) — client-reported**
Client reported `<IsThisVehicleUsedForRideShareOperation>NO</IsThisVehicleUsedForRideShareOperation>`
where `0` was expected. Root cause: `CV_RISK_COV_FINAL_VIEW` passes `RIDESHARE` straight through
as text with no numeric conversion, unlike the sibling `FLEET_VEHICLE_MAIN_VIEW` which correctly
converts the same field to `'0'`/`'1'`. Example: confirmed for policy P00009817 directly in the 14
Jul UAT batch; live impact 1,293 answered rows across 4,667 policies for this and 2 sibling fields
(`ContractRestriction`, `HireVehDriverSupplied`).

### G-BP-99 — EngineSize/GrossVehicleMass hard-aliased to the near-empty override column
**Status: FIXED (drafted) — client email (Raju)**
`Sample_CBP_CommercialVechicle` aliases `EngineSize`/`GrossVehicleMass` straight from the
manual-override-only Pure columns (12.8%/2.2% filled) instead of the base columns (88.2%/65.3%
filled) — every sibling field in the same query correctly checks the override flag first, these
two skip it. Example: proven by finding the *exact same bug already fixed once* on the Personal
Motor side (`PM_01`) — the old buggy line sits there commented out, replaced with the correct
`CASE WHEN Override=1 THEN OV ELSE base END` pattern, confirmed live at 99.5%/57.5% fill on
`PM_03`. The CM fix is a direct copy of the already-proven PP pattern.

### G-BP-76/77/79/80/81/82 — Building coverage views missing active-term filter (client-confirmed)
**Status: FIXED LIVE (all 6)**
Client comment on ATP-10947 (policy P00010139): *"We are seeing a duplicate coverage entry for
BCLND_SD... please review the coverage mapping."* Root cause: `RISK_BUILDING_BC_COVERAGES` had no
active-term filter, so an expired term's coverage row and the current term's both got emitted.
Same missing-filter shape found and fixed across all 5 Building coverage lines (BC/BI/BG/EN/
Money). Example: BC alone had 2,749 of 11,055 policies (24.9%) exposed; BG was the largest at
25,442 duplicate (policy, Type) combinations. G-BP-81 additionally found a premium-join fan-out
specific to BG (5 policies with 2 conflicting premium rows for the same sub-coverage key).

### G-BP-01 — BG Theft Limit (NZ)
**Status: FIXED LIVE**
PL101 requires NZ to force Theft Limit = Contents/Stock/Employee Tools Limit; live view sent raw
`THEFTLIMIT` unconditionally. Example: 1,265 of 1,978 NZ Burglary policies (63.9%) were
mismatched; confirmed 0 mismatches remain post-fix (Australia untouched, 0 before and after).

### G-BP-92 — Total Annual Turnover partial minimum-value floor
**Status: FIXED LIVE**
Closes the ATP-10775 minimum-value initiative (client "Highest" priority — sending below-minimum
fails migration for the whole policy). The existing floor only caught exact $0/NULL, not the
$1–$49,999 range. Example: 109 of 18,925 records (0.58%) genuinely below-floor nonzero — e.g.
P00007337 at $42,000 — now floored to $50,000; 4,072 already-correct $0/NULL cases unaffected.

### G-BP-30 — Fleet Subcov indicator (largest single-field mismatch this session)
**Status: FIXED (drafted) — corrects a stale "already fixed" claim**
The register previously claimed this was fixed; live check found the config still hardcoded and
the view had no `INDICATOR` column at all. Example: On Hook Liability (`OHL_SD`) showed
`Indicator=1` for **1,222 of 1,222 vehicles (100.0%)** — every single Fleet vehicle in the
portfolio, despite the real value being 0 for all of them.

### G-BP-82 — RISK_BUILDING_EN_COVERAGES hardcoded Indicator (all 5 branches)
**Status: FIXED LIVE — corrects an earlier mistake in this same pass**
An earlier "checked clean" note had wrongly closed this as by-design without checking limit data.
User flagged it directly; live data confirmed: `CWS_SD` showed `Indicator='1'` on 99.7% (5,985 of
6,003) of rows that actually had a $0/NULL limit — the largest single-field mismatch found this
session.

### G-BP-11 — CM VehicleType, no ELSE clause
**Status: OPEN — re-confirmed still live 2026-07-14**
`CV_RISK_COV_FINAL_VIEW`'s VehicleType `CASE` has no fallback branch — unmapped source values
silently produce `NULL`. Example: this was marked "Fixed via new batch load" by the client, but a
direct check of the 14 Jul UAT batch found policy P00020200 with a fully-populated CM vehicle
(real RegistrationNumber, RedbookCode, Make/Model/Year) still showing `<VehicleType></VehicleType>`
completely blank — the exact reported symptom, still reproducing.

### G-BP-53 / G-BP-54 — Fleet RB Vehicle Key / Market Value without Accessories
**Status: AWAITING POLICY TEAM (both)**
Not wiring gaps — `VEHICLECOVERAGES_FLEETVEHICLE` (checked live, 41 columns) has no RedBook-key
column and no without-accessories column anywhere in scope. Genuine data-availability questions:
does Fleet even have RedBook integration in Pure? Needs Aggne policy team / client input before
any fix can be scripted.

*(Full list of the 55 real Pure-to-Write-sourced gap IDs (excludes closed/no-defect): G-BP-01, 06,
11, 13, 14, 16b, 17, 18, 21, 24, 27, 30, 31, 33, 35, 37, 38, 39, 48, 50, 53, 54, 55, 57, 58, 61,
65, 67, 70, 73, 74, 75, 76, 77, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
96, 97, 98, 99 — see `README.md` for the full text of every one, or ask for the remainder expanded
with examples the same way.)*

---

## 3. PL101 mapping spec (7)

Gaps found by cross-checking a live view's dropdown/banding/default logic against the BP PL101
field-rule spec (`Conversion_Mapping_BP_PL101_V2.xlsx`).

### G-BP-01 — BG Theft Limit (NZ) — see above (also Pure-to-Write)

### G-BP-02 — BC Landslide (LND_SD)
**Status: FIXED LIVE**
Two bugs: raw `LANDSLIDELIMIT` sourced instead of PL101's
`LEAST(Contents+Stock+EmployeeTools, 250000)` formula, and the NZ-only gate sitting in a JOIN's
`ON` clause instead of filtering rows. Example: 935 of 1,389 NZ records (67.3%) mismatched on the
formula alone.

### G-BP-05 — Money outside business hours dropdown
**Status: FIXED LIVE**
Was rendering `'Other'` even at a $0 limit; PL101 says the field shouldn't display at all unless
limit > $0. Example: 438 of 1,339 rows (32.7%) were affected; confirmed live post-fix split
exactly 438/832/64/5 across blank/Other/LockedSafe/LockedTil.

### G-BP-07 — CM BodyType unmapped values
**Status: OPEN**
View's ~40-value `CASE` doesn't cover all live Pure values; PL101 (Commercial Vehicle v1.1) shows
DCT only accepts 9 Body Type codes — unmapped values pass through raw text instead of one of the 9.

### G-BP-08 — CM ImportType, no translation
**Status: AWAITING CLIENT — resolved 2026-07-13 per client, not traced to a conversion-side fix**
Raw `'I'`/`'L'` codes pass through with no translation; PL101 doesn't document target values.

### G-BP-10 — CM FuelType / CMRBPower / CMRBTrackRear bare tags
**Status: OPEN — superseded by G-BP-99's findings**
Originally recorded as bare `<FuelType/>` etc. with no source column and PL101 not documenting
one. The 2026-07-14 investigation (G-BP-99) found these are in fact wired for non-overridden CM
vehicles (92%/88%/99.8% filled) — this entry needs reconciling against that newer finding rather
than treated as fully open.

### G-BP-33 — Building RoofConstruction / MainWallConstruction / FloorConstruction dropdowns
**Status: FIXED LIVE (RoofConstruction); others checked clean**
Checked all 3 dropdown `CASE` blocks against live distinct Pure text. RoofConstruction had a real
typo (see G-BP-83); FloorConstruction/MainWallConstruction checked clean, no unmapped values
found.

### G-BP-84 — RISK_BUILDING_FINAL ClearLandSqm "<600sqm" unreachable branch
**Status: FIXED (drafted) — latent, 0 current impact**
The 4th `WHEN` branch duplicates the 3rd's condition instead of the PL101-documented 4th tier — a
copy-paste error. 0 rows currently hit it (only `<150sqm`/NULL exist today), fixed anyway since
the branch is genuinely unreachable.

---

## 4. DC Manuscript XML (6)

Gaps found or resolved by reading the actual DC target-schema manuscript XML
(`Carrier_Package_Data`, `Carrier_CoverageLibrary_Data`, `Carrier_BusinessProtectionBase`) to
confirm the correct node path, enum values, or default-rule behavior.

### G-BP-48 — Fleet Vehicle main `<risk>` block, ~100 empty fields
**Status: FIXED LIVE — corrected after manuscript check, not actually a gap**
Original claim: `FLEET_VEHICLE_MAIN_VIEW` only has 25 columns against ~130 template tags. Fresh
read of `Carrier_CoverageLibrary_Data_1_0_0_0.xml` showed Fleet's vehicle-identity fields live at
the nested `<Vehicle>` node (SEQ 57), not the `<risk>` node (SEQ 61) — the empty tags at SEQ 61
are correct per the manuscript. Downgraded from a structural gap to a non-issue; the real bugs
were in SEQ 57 instead (G-BP-53/54/55).

### G-BP-16c — Additional Interest LineProtectionSection value mismatch
**Status: FIXED LIVE**
Was outputting `PublicProductLiability`/`StockVehicles`/`CustomerVehicles` against DC's canonical
enum (`Carrier_Package_Data_CW_1_0_0_0.xml`, `AdditionalInterestSMEInput.LineProtectionSection`),
which expects `PublicandProductLiability`/`StockVehicle`/`CustomerVehicle` — mismatched strings
fell back to "NA" in DC's UI. Example: P00010027's "National Retail Group" party now shows
`LINE_VALUE='PublicandProductLiability'`, matching the enum exactly.

### G-BP-62 — SV "Is Windscreen Glass Excess Taken"
**Status: BLOCKED — holding for client's dollar-figure confirmation**
Manuscript defines this as a derived value (`WindscreenAndWindowGlassExcessConditional`: 0 if not
taken, else $1,000 if `LossOrDamageLimit>=100001` else $500) since Pure has no native numeric
source. Fix is drafted and ready (`fixes/G-BP-62_fix.sql`), but the $1,000/$500 constants are
inferred from naming convention, not confirmed against DC's actual values — held pending
client/DC confirmation of the correct figures before deploying to this client-visible field.

### G-BP-65 — Renewal, CV Hail/Malicious Damage Excess
**Status: BLOCKED (value) / FIXED LIVE (casing bug)**
Manuscript's real path is `Excess/HailAndMaliciousDamage` (capital A) but SEQ 26 sent the
lowercase `<HailandMaliciousDamage/>` — XML is case-sensitive, so DC never recognized the node at
all. That casing bug is fixed and confirmed live. Separately, the manuscript shows this value is
actually synced from the Building BC Theft screen via a DC-internal `onChange` rule, not a
standalone Pure-sourced field — needs client clarification before a value-level fix can be
written.

### G-BP-69 — SEQ 1 AddressVerified missing entirely
**Status: FIXED LIVE**
Field was absent from the template — not even an empty tag. Manuscript documents
`<rules><default value="0"/></rules>` (same ATP-9994 mechanism as G-BP-68). Config-only fix
applied: `<AddressVerified>0</AddressVerified>` now sits correctly in the SEQ 1 output.

### G-BP-71 — SV Storm (STD_ST), no Pure source
**Status: OPEN — needs a client/business decision**
Manuscript ties `STD_ST/Indicator` to `LegalLiabilityStorm > 0`, but no such field exists anywhere
in the SP or SAS for Stock Vehicles — "Storm" only exists for Building coverage in this codebase.
Not a wiring gap; needs a decision on whether this field genuinely applies to SV at all.

### G-BP-72 — TA required fields — see Section 1 (also SAS)

---

## Follow-up notes

- **G-BP-98/99** are new findings from today (14 Jul) not yet added to the main `README.md`
  register table — recommend registering them formally alongside the rest before the next
  handoff.
- **G-BP-11 / G-BP-93 (via ATP-11093/ATP-11072)**: two "Closed" statuses on the ticket-status
  side currently contradict live 14 Jul UAT batch evidence — flagged in both this document and
  the earlier batch validation report; recommend re-verifying before treating as closed.
- The 68-gap Pure-to-Write list above shows the 12 largest/most illustrative findings in full;
  say the word and I'll expand the remaining ~56 with the same example-and-status format.
