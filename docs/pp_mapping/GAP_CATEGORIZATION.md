# PP Gap Categorization — by Layer/Decision and Field Type

Reclassifies all 39 gaps (+2 sub-splits where a gap has a fixable part and a needs-input part)
along two axes so we can work category-by-category:

- **Field Type**: `Dropdown` (fixed DCT option list), `Mandatory` (required field, blank/invalid
  with no dropdown angle), `Freetext` (free text content/formatting issue).
- **Layer + decision**: which artifact holds the bug, and whether it can be fixed outright or
  needs Aggne policy team / client input first. Added a 6th category (config-need-input) beyond
  the five requested, since several config-only hardcodes still need a business decision before
  the "fix" value is known.

**Layer definitions**: *SP* = `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql` (PM_01/PM_02/PM_03
build logic, or the equivalent `SP_PP_ADJ_EXP_PREM`). *View* = the `sql/snowflake/1_conversion/PP/views/*.sql`
files. *Config* = the SQL Server `PP_ConversionConfig` XML template text (hardcoded tags/tokens).

---

## 0. False Positive — no fix needed

| Gap | Field | Type | Note |
|---|---|---|---|
| G-04 | DriveDescription | Dropdown | View already maps captions to codes correctly |
| G-19 (original claim) | AdjustmentSelection/Recurring hardcode | Dropdown | Traced live SP — hardcodes are correct given upstream percent→dollar conversion + recurring-only filter |

---

## 1. Issues with Pure-to-Write SP — need client/Policy input

| Gap | Field | Type | Question |
|---|---|---|---|
| G-03 | BodyType | Dropdown | 'Other'/'Cab Chassis' mapping — does BP have existing precedent? |
| G-05 | NumberOfCylinders | Dropdown | Omit tag for cylinder-less VehicleTypes, or send something else? |
| G-07 | VoluntaryExcess | Dropdown | Re-banding rule above $1000 (current 2000/5000 bands are invalid) |
| G-11 | AgeOfYoungestRegularDriver | Mandatory | `<16` vs manuscript's `MinAge=17` — which threshold is correct? |
| G-19 (new finding) | UW Adjustments — non-recurring exclusion | Mandatory | Should non-recurring adjustments (60-64% of source) be included at all? |
| G-26 | Premium double-carry (HB+HC) | Mandatory | Does DCT sum coverage premiums? Is a real HB/HC split available? |
| G-38 (Part 2) | Clause codes — CM_*→PM_* mapping | Dropdown | Confirm the legacy-code equivalence table (2 of 6 pairs have no obvious match) |

## 2. Issues with Pure-to-Write SP — can be fixed (No client/Policy input)

| Gap | Field | Type | Fix |
|---|---|---|---|
| G-06 | InductionType | Dropdown | Restore SAS fallback block (PR-04) + correct CASE vocabulary |
| G-09 | ImportType | Freetext | Trim literal + restore SAS fallback block |
| G-10 | EngineSize/GrossVehicleMass | Mandatory | Restore SAS fallback block (PR-04), SAS-verified exact logic |
| G-38 (Part 1) | Clause codes — case | Dropdown | Stop `UPPER()`-ing `CAText`, carry raw case through |
| G-39 | Clause descriptions — caps | Freetext | Stop `UPPER()`-ing `CADescription` |

## 3. Issues with view — need Client/Policy input

| Gap | Field | Type | Question |
|---|---|---|---|
| G-18 (Landlords only) | LLB_SD Indicator | Dropdown | No Taken/NotTaken source column exists — is occupancy an acceptable proxy, or is there a real Pure flag? |
| G-20 | HB UW Adjustments | Mandatory | Is HB UW adjustment in scope at all? (repoint view to `Output_UWAdjust_PER` vs. retire) |

## 4. Issues with view — can be fixed (No client/Policy input)

| Gap | Field | Type | Fix |
|---|---|---|---|
| G-02 | Year/Make/Model | Mandatory | *(already applied 2026-07-09 — filter removed)* |
| G-08 | RegistrationNumber | Freetext | Uppercase + strip non-alphanumeric (covers 73%; residual is genuine bad data, needs a validation flag not a fix) |
| G-12 | VehicleType | Dropdown | Allow-list to the true 9-code Override=1 set, route unmatched to validation report |
| G-15 | DateOfClaim | Mandatory | No live defect; add validation-report rule for the silent-NULL pattern |
| G-16 | Cause | Dropdown | Caption→code CASE (defensive for untested Liability captions too) |
| G-17 | PriorCarrier | Dropdown | Copy the exact CASE the proven Attach view already uses |
| G-18 (Flood/ALD/structural) | BFL_SD/BAD_SD/BLD_* Indicator | Dropdown | Derive from existing `sValue`/limit columns already in the row |
| G-21 | Free text (5 views) | Freetext | One XML-escaping helper applied everywhere |
| G-27 | HC Specified Contents | Mandatory | Add the empty-item filter (same pattern as seq 8) |
| G-36 | Roof/Wall/Alarm/Deadlocks/Grills | Dropdown | Hardening only — 0% invalid today, low urgency |

## 5. Issues with config — can be fixed (No client/Policy input)

| Gap | Field | Type | Fix |
|---|---|---|---|
| G-13 | RedbookCode | Mandatory | Deploy the already-drafted, already-verified token fix to SQL Server (never actually pushed) |
| G-22 | HB Indicator | Dropdown | Template swap to `{HB_INDICATOR}` — view already computes it |
| G-25 | ClassCode (HB+HC) | Dropdown | `HH`/`HBC` → `FISR`/`BSP`, manuscript-confirmed via lookup table |
| G-28 | `{clauses}` token | Mandatory | Rename to `{HC_CLAUSE}` |
| G-29 | HC Indicator | Dropdown | Template swap to `{HC_INDICATOR}` — view already computes it |
| G-30 | FloodDamage | Dropdown | Template swap to `{FLOODDAMAGE}` — data already in the row |
| G-31 | HomeContentsLimits | Dropdown | Template swap to `{ANYITEMSEXCEEDVALUE}` |
| G-32 | HomeContentsTotal/SpecifiedContentsTotal | Mandatory | Blank the hardcoded test-residue numbers (readOnly DCT output fields) |

## 6. Issues with config — need Client/Policy input

| Gap | Field | Type | Question |
|---|---|---|---|
| G-01 | State | Freetext | What should State contain for NZ risks? |
| G-23 | HB Excess sub-tags (Standard/Imposed/EQ/Flood/Glass) | Freetext/Mandatory | Confirm inapplicable — no source data found anywhere, including client's original SAS |
| G-24 | GlassLimit | Mandatory | Blank it, or source a distinct glass limit? (100% of rows affected) |
| G-33 | SICCode | Freetext | Blank (let DCT default via `UWGroupForSICCode`) or send a specific PP value? |
| G-34 | Risk-level Excess (Standard/Imposed) | Freetext/Mandatory | Same as G-23, at risk level |
| G-35 | 6 fabricated risk-assessment answers | Mandatory | Blank them, or is there a real source for any? |
| G-37 | Motor sub-coverage Indicator (8 blocks) | Dropdown | Correct code-per-ProtectionType matrix |
| G-45 | "Legacy Start Date" field identity | Mandatory | Which DCT node is this — none of our date columns carry that literal name |

---

## New from client ticket cross-reference (2026-07-09) — G-40 through G-46

Added after mapping the client's ATP-10219 ticket folder against G-01...G-39 — see
`CLIENT_TICKET_MAPPING.md`. 2 are fully root-caused code fixes, 3 need more investigation before
they can be categorized as fixable-now vs. needs-input, 2 need client/policy input.

### 2b. Issues with view — can be fixed (No client/Policy input)

| Gap | Field | Type | Fix |
|---|---|---|---|
| G-42 | Motor Premium (PMEXPPREM) | Mandatory | **P1 — confirmed:** join in `PER_COM_PAYLOAD` compares a composite key to a plain key, so it never matches — 100% of rows show 0. Fix the join key — see `fixes/G-42_fix.sql` |

### 1b. Issues with SP — need investigation, then likely input

| Gap | Field | Type | Note |
|---|---|---|---|
| G-44 | Account Handler | Mandatory | **Confirmed symptom:** `PER_CONVERSION_FINAL_LOAD` defaults unmatched handlers to a real staff member's name ('Aaron Pang'), firing for 84% of policies — the join upstream is failing, root cause not yet found. Symptom fix + investigation queries in `fixes/G-44_fix.sql`; needs a policy decision on the correct fallback (blank vs. a different default) |

### 3b. Issues with view — need Client/Policy input

| Gap | Field | Type | Question |
|---|---|---|---|
| G-40 | HC Specified Items Away From Premises — itemized list | Freetext/Mandatory | The Taken/Not-Taken flag works; the itemized description/value list behind it (195 policies show "Taken") was never built. What's the target DCT node shape for a repeating item list here? |

### 7. Needs further investigation before categorizing

| Gap | Field | Type | Note |
|---|---|---|---|
| G-41 | YearLastReWired / YearLastRePlumbed | Mandatory | View + config token both correct; 558 of 584 buildings aged 41+ (95.5%) still blank — root cause is upstream, not yet located |
| G-43 | Location 1 (RISKNUMBER=1) missing | Mandatory | 235 of 4,239 policies (5.5%) have location rows but none numbered "1" — unclear if genuine bug or benign PURE-side renumbering |
| G-46 | Motor-Only protections migrating with Location sections | Logic-only | 260 of 4,076 policies (6.4%) show both Motor and HB/HC indicators set — suggestive, not proof; needs a PURE-side source comparison |

---

## Summary counts

| Category | Count |
|---|---|
| False Positive | 2 |
| SP — need input | 7 |
| SP — can fix | 5 |
| SP — need investigation, then likely input | 1 (G-44) |
| View — need input | 2 |
| View — can fix | 10 + 1 (G-42) |
| View — need input | +1 (G-40) |
| Config — can fix | 8 |
| Config — need input | 7 + 1 (G-45) |
| Needs further investigation | 3 (G-41, G-43, G-46) |

**Total gap-instances now tracked: 48** (41 original + G-40 through G-46 new).

---

## Deployment status (as of 2026-07-10, verified against true live hosts)

**Email sent (16)** — awaiting Aggne policy team / client response:
G-01, G-03, G-05, G-07, G-11, G-18 (Landlords), G-19 (new finding), G-20, G-23, G-24, G-26, G-33,
G-34, G-35, G-37, G-38 (Part 2). See `EMAIL_SP_NeedInput.md` / `EMAIL_CLIENT_FieldQuestions.md`.

**Bug fixed, need to validate XML (8)** — live in config/view; next step is a real conversion run
and checking the actual generated payload, not just the template/view:
G-02, G-13, G-22, G-25, G-28, G-29, G-31, G-32.
(G-13/G-22/G-28/G-29/G-31 were found already-deployed when re-verified against the true Azure
config host on 2026-07-10 — see `feedback_verify_live_not_repo.md`. G-25 and G-32 were deployed
today via `PP_ConversionConfig_FIXES_20260710.sql`.)

**Pending SP (5)** — drafted, no input needed, not yet applied (Snowflake write access is the
user's, not mine): G-06, G-09, G-10 (share the same PR-04 restore block — apply together),
G-38 (Part 1), G-39.

**Pending Config (1)**: G-30 — the prerequisite view fix
(`PER_HOME_BUILDING_PAYLOAD_ADD_FLOODDAMAGE.sql`) is live and confirmed returning
`FLOODDAMAGE` values (1,627 Not Taken / 216 Taken); only the config token swap
(`<FloodDamage>Taken</FloodDamage>` → `{FLOODDAMAGE}`, the commented-out block at the bottom of
`PP_ConversionConfig_FIXES_20260710.sql`) is still outstanding.

**Pending Views (9)** — drafted, no input needed, not yet applied:
G-08, G-12, G-15, G-16, G-17, G-18 (Flood/ALD/structural portion), G-21, G-27, G-36.

**Closed — False Positive, no action (2)**: G-04, G-19 (original claim).

**New from 2026-07-09 client ticket cross-reference (7):**
- Pending View fix, no input needed: G-42 (Motor Premium — P1, confirmed root cause)
- Pending SP investigation + policy decision: G-44 (Account Handler default)
- Need client/policy input: G-40 (away-items itemized list schema), G-45 (Legacy Start Date field identity)
- Needs further investigation before a fix/question can be drafted: G-41 (Rewired/Replumbed), G-43 (Location 1 missing), G-46 (Motor-only + Location sections)

---

## Implementation sequence

Ordered by blast radius (config = one template literal, lowest risk; view = one SELECT's logic,
moderate risk; SP = the shared stored procedure feeding every downstream table, highest risk/most
care needed) and by what's blocked on someone else vs. actionable right now.

**Step 1 — Close the false positives (no code change).** 2 gaps: G-04, G-19 (original claim).
Mark `Status: False Positive` in `VALIDATION_RULES.md` (already done) and drop from any client-facing
tracker — nothing to build or ask.

**Step 2 — Send the consolidated question set (already sent).** 16 gaps across all three layers —
`docs/pp_mapping/EMAIL_SP_NeedInput.md`. This runs in parallel with Steps 3-5; don't block
implementation on waiting for answers.

**Step 3 — Implement config fixes (no input needed).** 8 gaps: G-13, G-22, G-25, G-28, G-29, G-30,
G-31, G-32. All are template literal/token swaps in `PP_ConversionConfig` — lowest risk, fastest to
deploy and verify, and G-25 in particular (ClassCode) is manuscript-confirmed and currently wrong
on 100% of every HB/HC block, so it's the highest-value quick win in this batch.

**Step 4 — Implement view fixes (no input needed).** 10 gaps: G-02 *(already applied)*, G-08, G-12,
G-15, G-16, G-17, G-18 (Flood/ALD/structural portion), G-21, G-27, G-36. Each is scoped to one
view file's `CASE`/`WHERE` logic — moderate risk, test each view's output independently before
moving to the next.

**Step 5 — Implement SP fixes (no input needed).** 5 gaps: G-06, G-09, G-10, G-38 (Part 1), G-39.
Highest care — these all land in `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql`, which every
other downstream view/target depends on. G-06/G-09/G-10 share the same root cause (the missing
client-SAS `DO` block, PR-04) — implement as one combined change, not three separate edits, and
regression-check all three together since they touch the same PM_02 CTE.

**Step 6 — Implement the answered "need input" items, as responses arrive.** 16 gaps (7 SP / 2
view / 7 config — see Parts A/B/C of the email). Route each answer to whichever layer it lands in
and slot it into the same config→view→SP risk ordering as Steps 3-5, rather than implementing
in the order answers happen to arrive.

**Step 7 — Full regression pass.** Once Steps 3-6 are complete, re-run `PP_XML_VALIDATE_AND_REPORT`
end to end and re-check every "Verify after applying" query in each `fixes/G-NN_fix.sql` file
together, not just individually — several fixes touch the same source rows (e.g. G-06/G-09/G-10's
shared SP block, G-25's ClassCode affecting both G-23/G-34's excess-tag confirmation context) and
should be validated as a set.
| **Total gap-instances** | **41** *(39 gaps, G-18 and G-38 each split into two rows)* |
