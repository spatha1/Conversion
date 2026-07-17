# PP Conversion — Session Summary, 16 Jul 2026

**Scope:** Motor risk labeling, Comprehensive Market premium calculation, missing account PartyID
(Express UI crash), and Vehicle Underwriting Adjustments. Two client-reported issues (Teams,
16 Jul 2026, batch_20260709 / P00026345 &amp; P00026339), two found during our own re-testing.

**Companion artifacts:**
- [PP Conversion — Plain-English Guide to All 18 Sequences](https://claude.ai/code/artifact/d607fba8-9908-468e-919e-c3ac421ac765) — Sequences 16 and 18 updated with today's changes
- `sql/snowflake/1_conversion/PP/bugfixes/` — all four deploy scripts referenced below

---

## 1. What was validated today

| # | Item | Source | Status |
|---|---|---|---|
| 1 | Motor risk coverage `Type`/`Description` reading "CommercialVehicle" | Client-reported | Fixed, confirmed live |
| 2 | Comprehensive Market vehicles pricing at $0 (two further causes beyond the Sequence 15 join-key fix) | Client-reported | Fixed, confirmed live on 4 policies |
| 3 | Missing account PartyID crashing the Express quote screen (`culture=en-NZ` 500 error) | Found during re-testing | Root cause identified and confirmed; source-level fix still open |
| 4 | Vehicle Underwriting Adjustments not appearing in Express | Client-reported | Our side confirmed correct against the manuscript; escalated to Duck Creek/policy team |

Validation method for all four: pulled the live view/procedure definitions directly from Snowflake
(not the repo copies, which can drift), reproduced each issue against real Pure data, checked the
actual DCT manuscript field definitions where relevant (not assumptions), applied a full
`CREATE OR REPLACE` deploy, then regenerated real quotes in DCT DEV and confirmed the result in both
the raw XML/API response and the Express UI screens.

---

## 2. Item 1 — Motor risk coverage mislabeled

**What we found:** the Personal Motor risk block's `<coverage>` node — inside `<Code>PM</Code>`, i.e.
already scoped to Personal Motor — had its own `Type`, `limit.Type`, and `Description` fields
hardcoded to `CommercialVehicle` / `CommercialVehicle` / `Commercial Motor`. This is copy-paste
residue from the Commercial Vehicle (BP) version of the same template.

**Fix:** hardcoded to `PersonalMotor` / `PersonalMotor` / `Personal Motor`.

**File:** `BUGFIX_PP_CONVERSION_RUN_CommercialVehicleMislabel_20260716.sql` (procedure
`PP_CONVERSION_RUN`, Sequence 18 template only)

**Confirmed live:**
- P00026339 → Quote `Q0132752`
- P00026345 → Quote `Q0132755`

---

## 3. Item 2 — Comprehensive Market premium still $0

Yesterday's fix (Sequence 15's join-key mismatch, and separately the Agreed-Value market-value
fallback) did not cover Comprehensive Market vehicles specifically. Two further, independent causes
were found on this population:

### 3a. `MVValueWithoutAccessories` gated on a stale raw flag

**View:** `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD`, PM_01 CTE.

**Before:**
```sql
,CASE
    WHEN (t3.MVCVOverride = 1 AND t3.MVCVProtectionType <> 2)
        THEN t3.MVCVMarketValue
    ELSE NULL
    END AS MVValueWithoutAccessories
```
**Live impact confirmed:** 2,127 of 2,324 rows (91.5%) had `MVCVOverride <> 1` and were therefore
always `NULL`, discarding a real `MVCVMarketValue` Pure had on file.

**After:**
```sql
,CASE
    WHEN t3.MVCVProtectionType <> 2
        THEN t3.MVCVMarketValue
    ELSE NULL
    END AS MVValueWithoutAccessories
```

**Why this is correct, not just a workaround:** checked the original legacy SAS conversion script
(`SAS/txt/PrivateMotor_conversionscriptCapricorn.txt`) directly. It performs the same backfill in two
stages — a DATA STEP that re-derives an internal "Override" flag from whether the vehicle has a
RedBook key (`IF MVRBVehicleKey = '' THEN Override = 'Yes'`), then backfills
`MVValueWithoutAccessories` from `MVCVMarketValue` whenever that derived flag is Yes. Since 100% of
in-scope vehicles have no RedBook key (confirmed separately under ATP-10963), the derived flag is
effectively always Yes — meaning the original design's intent already matches this simplified fix in
practice. A second-stage backfill implementing the SAS logic exactly already existed further down in
the same SP (using the RedBook-key-derived Override) but was not producing the same result live —
that discrepancy is still an open question (see Section 6), though moot now that the earlier gate is
removed.

### 3b. Accessories flag defaults to No even with real accessory data

**View:** same procedure, PM_02 CTE — `MarketValueDescription` / `MVAddAccOrMods` are recomputed from
a clause-text lookup (`PER_CLAUSEAMENDMENTMV.CAText`/`CADescription`) with no fallback branch.

**Before:** a bare `CASE WHEN <clause text matches> THEN ... END` with no `ELSE` — any vehicle with no
matching clause record got `NULL` for both fields, discarding the correctly-computed PM_01 value
(driven by the vehicle's real `MVCVVehModList`/`MVCVVehModValue`).

**Why this is a genuine translation bug:** the original SAS is a DATA STEP —
`SET PM_01; IF <clause match> THEN DO; MVAddAccOrMods = 'Yes'; END;`. In SAS, that conditional
assignment only *overwrites* the field when the condition is true; otherwise the field keeps
whatever PM_01 already computed. The SQL port used a bare `CASE...END`, which evaluates to `NULL`
instead of "leave unchanged" — a real semantic mismatch between SAS and SQL, not a data-quality issue.

**After:** added an `ELSE` that falls back to PM_01's `MarketValueDescription`/`MarketValueDescriptionValue`-driven
value.

**File:** `BUGFIX_SP_PM01_PM02_MarketValueZero_20260716.sql`

**Confirmed live** — `RiskTotalPremiumsVehicle`, before → after:

| Policy | Quote | Before | After |
|---|---|---|---|
| P00026339 | Q0132752 | $0.00 | $3,234.54 |
| P00019280 (10-vehicle control policy from the original investigation) | Q0132753 | $0.00 | $190,668.58 |
| P00004700 | Q0132754 | $0.00 | $487.08 |
| P00026345 (Agreed Value — was already computing) | Q0132755 | n/a | $6,103.14 |

**Population-level check** (`AGGNE.DEV.PER_COM_PAYLOAD`, `PROTECTIONTYPE = 'ComprehensiveMarket'`):
`MVVALUEWITHOUTACCESSORIES` blank count went from 1,619/1,796 (90.2%) to 0/1,800.

---

## 4. Item 3 — Missing PartyID crashing Express (`culture=en-NZ`)

**Symptom:** `Http failure response for .../defaultViewModel?culture=en-NZ: 500 Internal Server
Error` when opening certain quotes in Express — a long-unresolved issue from earlier in this project,
previously seen but never pinned down (confirmed NOT a browser/cache/session issue in earlier testing).

**What we found:** `AGGNE.DEV.PER_FINAL.PARTYID` is `NULL` for some policies (confirmed: P00009639 /
CML00005281). The `Session.setPropertyRq name="InputClientID"` value in the request XML was
therefore an empty string.

**Test:** took P00009639's real request XML, substituted a known-good PartyID from a working policy
(P00026339's), resubmitted to DCT DEV. The resulting quote (`Q0132757`) navigated the entire flow
cleanly — Applicant Information → Personal Protection → Private Motor Vehicles → Protection Summary
→ Contribution → Detail — with zero errors, versus the crash on the original blank-PartyID
submission.

**Status:** this confirms the mechanism (blank PartyID → Express crash on this specific API call), but
the substitution was done manually on one test policy as a diagnostic step, not applied as a
data-level fix. **Still open:** why `PARTYID` comes back `NULL` for some policies in the first place —
this connects to the previously-tracked "Party Conversion PartyID broken for CML00001418
(P00010162)" item, not yet investigated at the source (see Section 6).

---

## 5. Item 4 — Vehicle Underwriting Adjustments not displaying

**What we found (and fixed on our side):** checked the actual live DCT manuscript directly
(`Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/CarrierCoverageLibrary/Carrier_CoverageLibrary_Data_1_0_0_0.xml`,
`VehicleUWAdjustmentInput` object) rather than guessing at field names. Found three mismatches:

| Field | Manuscript requirement | What we were sending |
|---|---|---|
| `Type` | Literal `Vehicle` (schema path is `UnderwritingAdjustment[Type="Vehicle"]`) | The coverage code `PM` |
| `AdjustmentSelection` | String enum `Dollar` / `Percent` | Numeric `1` |
| `Recurring/sValue` | String enum `Yes` / `No` | Numeric `1` |

**Fixed:**
- `BUGFIX_PP_CONVERSION_RUN_VehicleUWAdjustment_20260716.sql` — `<Type>{COVERAGE}</Type>` → hardcoded
  `<Type>Vehicle</Type>` (Sequence 16 template only)
- `BUGFIX_PER_PM_BUILDING_UW_ValueFormat_20260716.sql` — view `PER_PM_BUILDING_UW`:
  `AdjustmentSelection` `'1'`→`'Dollar'`, `RECURRINGINDICATOR` `'1'`→`'Yes'`

**Confirmed live (P00009639, quotes Q0132756 → Q0132760):**
- Request XML: `<Type>Vehicle</Type><AdjustmentSelection>Dollar</AdjustmentSelection><Recurring><sValue>Yes</sValue></Recurring>` — matches the manuscript exactly.
- DCT's raw response now assigns the submitted `UnderwritingAdjustment` object a real internal `id`
  (e.g. `UB60C1AE8496740CCBA482436D6836882`) — it did not before, when the values did not match the
  schema.

**Still not resolved:** the Underwriting Adjustment Details grid on the Private Motor Vehicles →
Detail screen still shows **"NoResultsFound"** and **UW Adjustment Total: $0.00**, despite the
document-level object now being valid and ID-assigned. This has been raised with the Duck
Creek/policy team directly — our data matches every field definition the manuscript exposes for this
object, so the remaining gap (if any) is either an additional undocumented linkage requirement, or a
display-layer issue on DCT's side. See the Teams snippet already sent for the exact request/response
pair.

---

## 6. Open items carried forward

1. **Why the pre-existing PM_02 backfill CASE (SAS-faithful, derived-Override-from-missing-RedBook-key)
   was not already catching the blank `MVValueWithoutAccessories` cases before today's simpler fix.**
   Not blocking — the simpler fix (Section 3a) produces the correct result regardless — but worth
   understanding for the sake of the eventual PP-only SP rewrite.
2. **Root cause of `PARTYID` being `NULL`** for some policies (the actual data-level fix, not the
   diagnostic workaround used to prove the culture=en-NZ mechanism).
3. **Vehicle Underwriting Adjustment display** — awaiting Duck Creek/policy team response.
4. **Clauses — data confirmed reaching DCT, display not yet independently confirmed.** Given the UW
   Adjustment lesson (present in the XML ≠ visible in the UI), the Motor Clauses section should be
   specifically screenshotted in Express to confirm it renders, not just inferred from the raw
   response.

---

## 7. UI/UX observations from live testing

These are observations from directly operating DCT Express during today's testing, not conclusions —
flagging them for the policy team / Duck Creek to weigh in on, since some may be intentional platform
behavior we're not aware of the reasoning for.

- **Generic failure messaging.** The `culture=en-NZ` crash surfaces to the end user as a raw
  `500 Internal Server Error` with only an opaque "issue reference number" — no indication of what
  went wrong or what to check (e.g. "this account is missing required party information"). For an
  underwriter working through a batch of converted quotes, a more specific error would make it much
  faster to tell "this quote has a real data problem" apart from "this quote just needs a retry."
- **Grid empty-state wording is technical, not user-facing.** The Underwriting Adjustment Details grid
  shows the literal string `NoResultsFound` (unstyled, looks like a debug/placeholder string rather
  than a designed empty state) rather than something like "No underwriting adjustments recorded for
  this vehicle." Worth checking whether this is a genuine UI bug or an untranslated resource key.
- **Truncated grid columns hide relevant detail.** On the Private Motor Vehicles summary screen,
  columns like "Vehicle Descr..." and "Protection Ty..." truncate without a tooltip or expand affordance,
  so a user has to open Edit on each row to see the full value — slower for anyone scanning a
  multi-vehicle policy for a specific detail.
- **`Recurring Indicator` presented as a free dropdown with no default.** The manual "Add" form for an
  Underwriting Adjustment shows `Recurring Indicator` as `(Select)` with no default and `Adjustment
  Type` defaulting to `%` — worth confirming with underwriting whether `%` is genuinely the more common
  case for Motor adjustments (our own source data is 100% dollar-amount adjustments), since a
  mismatched default increases the chance of a wrong manual entry.
- **Steps Recorder shows a persistent "this tool is being phased out" banner** across every recording
  this session — unrelated to Express itself, but worth switching to a supported recording tool
  (e.g. the Windows 11 Snipping Tool's screen recorder, or Clipchamp) before this becomes unavailable
  and interrupts evidence-collection for future sessions.

---

## 8. Files changed today

| File | Purpose |
|---|---|
| `sql/snowflake/1_conversion/PP/bugfixes/BUGFIX_PP_CONVERSION_RUN_CommercialVehicleMislabel_20260716.sql` | Item 1 |
| `sql/snowflake/1_conversion/PP/bugfixes/BUGFIX_SP_PM01_PM02_MarketValueZero_20260716.sql` | Item 2 |
| `sql/snowflake/1_conversion/PP/bugfixes/BUGFIX_PP_CONVERSION_RUN_VehicleUWAdjustment_20260716.sql` | Item 4 |
| `sql/snowflake/1_conversion/PP/bugfixes/BUGFIX_PER_PM_BUILDING_UW_ValueFormat_20260716.sql` | Item 4 |
| `.env`, `middleware/config.py`, `middleware/dct_client.py` | Added `DCT_DEV_URL`/`DCT_UAT_URL`, corrected the submission client to match how DCT actually accepts requests (raw XML POST with a browser User-Agent, not a Bearer-token JSON API) |

All four SQL fixes deployed and confirmed live against real quotes in DEV, per Sections 2–5 above.
UAT validation is the next step before any of this becomes client-facing evidence.
