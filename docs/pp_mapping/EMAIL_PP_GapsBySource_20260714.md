# PP Conversion — Gaps Found, By Source

For management review. **Snapshot as of 2026-07-14 — analysis is still ongoing; this is not a
final or complete list.** More gaps are expected to surface as the remaining source material is
worked through.

**Sources considered in this analysis:**
1. **Pure-to-Write** — the raw source insurance data, before conversion
2. **PL101** (`Carrier_PersonalProtectionBase_1_0_0_0.xml`) — the official field specification
3. **Manuscript** — the other DCT configuration files (workflow rules, coverage/clause code
   libraries, node structure)
4. **SAS** — the legacy conversion scripts, checked as a reference where the other three don't
   have an answer

Every finding below was discovered by comparing the converted output against one of these four —
not guessed or inferred. Each section explains what the source is, how we use it, and gives real
examples of what it caught so far.

---

## 1. Pure-to-Write (the source insurance data itself)

**What it is:** The raw policy data as it exists in the old system (Pure), before any conversion
happens — vehicle details, building details, coverage selections, everything the customer actually
has on file today.

**How we use it:** For every field that ends up in the converted policy, we check: does the value
in the new system actually match what's sitting in Pure? If Pure has real data and the converted
policy shows it blank (or wrong), that's a conversion bug. If Pure genuinely has no data, that's
not our bug to fix — it's a data quality question for the business.

**Examples found this way:**

- **Home location coverage disappearing.** For policy **P00010162**, Pure clearly shows $906,000 of
  Home Building cover and $202,000 of Home Contents cover for the customer's current address. But
  the converted policy showed nothing — the system was still looking at the address from an old,
  expired policy term instead of the current one. Root cause: a snapshot table wasn't being
  refreshed when a customer moved or renewed. **Fixed and confirmed** — this specific policy, and
  every other policy in the same situation, now shows the correct location and coverage.

- **Underwriting discounts vanishing.** 596 policies had a real dollar-value loading or discount
  recorded in Pure (e.g. a no-claims discount) that should carry through to the new policy — instead
  the amount showed as blank. Root cause: a technical join comparing two blank values ("nothing"
  compared to "nothing") was silently treated as "no match" instead of "no vehicle involved, that's
  expected." **Fixed and confirmed.**

- **Rewiring/replumbing dates lost.** 787 buildings had a real, correctly recorded year in Pure for
  when the building was last rewired or replumbed — but the conversion logic had a backwards rule
  that was supposed to only clean up garbage years (like "0" or "1850") and accidentally wiped out
  every normal year in the process. **Fixed and confirmed.**

- **Duplicate policies.** 72 policies were being submitted twice to Duck Creek, because when a
  customer's payment plan changed (e.g. from Monthly to Annually), Pure kept both the old and new
  plan on file and the conversion picked up both instead of just the current one. **Fixed** — down
  to 1 remaining case, which traces to a timing issue in an upstream table refresh, not our logic.

- **New vehicle fields added by client request.** Three new fields were added on the Pure side for
  vehicles — fuel type, engine power, and rear track width — but nothing on the conversion side had
  been built to carry them through; the tags existed in the output but were always empty. **Fixed
  and confirmed** — 1,696 of the eligible policies now show real values (e.g. "Petrol - Unleaded
  ULP", 158.0 kW).

- **Still open:** several fields (Motor vehicle details, cylinder counts, drive type, engine size)
  are blank for a large share of vehicles because the conversion only ever filled them in when one
  specific optional flag was set — the other 89% of vehicles were skipped even though Pure has the
  data. Fix is drafted and ready, not yet deployed.

---

## 2. PL101 (`Carrier_PersonalProtectionBase_1_0_0_0.xml`)

**What it is:** The official specification document for the Personal Package product — it defines,
field by field, which values Duck Creek will actually accept (e.g. Roof Construction can only be
"Tile", "Concrete", "Wood", etc. — nothing else), and which fields are mandatory.

**How we use it:** We check every value the conversion produces against this list. If Pure has a
value that isn't on PL101's approved list, or if a mandatory field comes through blank, that's a
gap this document catches that a simple "is it blank" check would miss.

**Examples found this way:**

- **An invalid code that would have been silently rejected.** The conversion was producing
  `FullComprehensive` for a vehicle's protection type — that value does not exist anywhere in
  PL101's approved list; the correct code is simply `Comprehensive`. Every policy with that
  protection type would have failed or shown wrong data on the Duck Creek side. **Fixed.**

- **Mandatory building fields blank for 991 policies (23.6%).** Roof Construction, Main Wall
  Construction, and Floor Construction are all marked mandatory in PL101 — but for 991 policies,
  Pure itself has no value recorded for these buildings at all. This isn't a code bug (the mapping
  logic is correct) — it's a genuine data gap in Pure. Flagged to the business, not something code
  can fix.

- **Source values with no PL101 equivalent.** A handful of real Pure values simply don't have a
  matching option in PL101 at all — e.g. Main Wall Construction of "Steel" or "Some Asbestos and
  Brick", Alarm System of "Local - Monitored", Deadlocks/Window Grilles of "Other". These pass
  through as invalid codes today. Small counts, but each one needs the business to say what the
  closest correct PL101 value is — **awaiting client confirmation.**

- **32 vehicles with no Vehicle Type recorded in Pure at all.** PL101 requires one of 13 specific
  vehicle type codes. We've defaulted these to "PassengerVehicle" as a reasonable guess, but that's
  pending explicit sign-off from the business rather than something we should decide unilaterally.

---

## 3. Manuscript (other DCT configuration files, beyond PL101)

**What it is:** Beyond the PL101 field spec, Duck Creek's conversion process is driven by several
other configuration files — the "workflow" manuscript (controls session/import mechanics), the
coverage and clause "code libraries" (define which numeric/text codes are valid for a given type of
cover), and structural node definitions (what shape a repeating list of items needs to be in).

**How we use it:** For questions that aren't about a single field's valid values, but about
*structure* — what codes are allowed for a coverage, how a list of items should be formatted, what
a session-level setting controls — we go to these files directly rather than guess.

**Examples found this way:**

- **A coverage indicator that was always "on."** For 2,175 policies, the "Unlimited Glass" coverage
  code was hardcoded to always show as selected, regardless of whether the customer actually had it.
  The manuscript's code library confirmed this is a real, independently-controllable coverage code —
  so we wired it to the real driving field. **Fixed and confirmed.** The same "always-on" pattern
  exists on 7 other coverage codes for the same policies — those need a business-defined rule for
  which codes can/can't coexist before they can be fixed the same way — **awaiting client input.**

- **A hardcoded session field with no real mapping.** Every generated policy currently sends a fixed
  value of "10" for the transaction/modification number — confirmed via the workflow manuscript that
  this is a real, meaningful field Duck Creek uses, not decorative. Checked the legacy SAS scripts
  and the Pure-to-Write source for anything that could supply a real value — neither has one.
  **Still open** — needs further investigation into what should actually populate this.

- **Itemized list structure not yet built.** A client ticket asked why "Specified Items Away from
  the Premises" only shows a Yes/No flag instead of the full itemized list. The source data has the
  full list ready (1,278 items across 495 policies) — what's missing is confirmation of the exact
  repeating-node shape Duck Creek expects for a list like this. **Awaiting client confirmation** on
  the node structure before this can be built.

---

## 4. SAS (legacy conversion scripts)

**What it is:** The original SAS-based scripts used for a prior, separate conversion effort —
kept as a reference in case they show a mapping or business rule that isn't obvious from Pure or
the manuscripts alone.

**How we use it:** When a gap doesn't have an obvious source elsewhere, we check whether the legacy
SAS logic already solved the same problem.

**Example:**

- **Checked, but no answer found there either.** For the hardcoded transaction/modification number
  described above, we specifically searched the extracted legacy SAS scripts (including the section
  that covers this same policy-header data) for any existing mapping — found none. This source has
  been checked and ruled out for this particular gap; it remains open pending further investigation
  elsewhere.

---

## 5. Changes Received From the Client

Not bugs — these are new requirements the client has actively asked for since conversion started,
layered on top of the original scope. Listed here separately so it's clear these are additions to
the work, not defects we introduced.

- **New RedBook vehicle fields.** The client added three new attributes on the Pure side for
  vehicles — fuel type, engine power, and rear track width (all sourced from RedBook, the vehicle
  data provider) — and asked for them to be carried through to the converted policy. These didn't
  exist in the original scope at all. **Built and confirmed** — 1,696 eligible policies now show
  real values (e.g. "Petrol - Unleaded ULP", 158.0 kW). Currently DEV only; the client's UAT
  environment needs the same 3 fields added on the Pure side before this can go there too.

- **New tag requested on the location block.** The client asked for an `AddressVerified` field to
  be added to every location, with a default value, after noticing it was missing from a real
  example payload they reviewed. Not something originally scoped — a genuinely new field.
  **Built and confirmed** in the underlying system that generates policies; not yet included in a
  regenerated batch of already-issued policies.

- **Consistent formatting for Suburb/City.** The client's policy team asked that Suburb/City always
  display in uppercase, for consistency, after noticing some policies showed mixed case (e.g.
  "Cannington" instead of "CANNINGTON"). Traced to the source data itself having inconsistent
  casing in about 13.5% of records — not a conversion bug, but a reasonable, low-risk formatting
  rule to apply. **Built and confirmed** — 100% of locations now show uppercase.

---

## Summary

| Source | Gaps/changes found | Fixed & confirmed | Awaiting client/business | Still investigating |
|---|---|---|---|---|
| Pure-to-Write | 6 highlighted above (of a larger set) | 5 | — | 1 |
| PL101 | 4 | 1 | 3 | — |
| Manuscript | 3 | 1 | 1 | 1 |
| SAS | 1 | — | — | 1 (checked, not the answer) |
| Client change requests (not bugs) | 3 | 3 | — | — |

This is a curated set of the clearest, most concrete examples per source, as analysis stands
**today, 2026-07-14** — not the full gap register and not a final count. Analysis is ongoing and
these numbers will grow. The complete list (55 items across all statuses, current cut) is
available separately if needed.
