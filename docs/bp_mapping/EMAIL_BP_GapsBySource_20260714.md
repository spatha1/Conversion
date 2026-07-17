# BP Conversion — Gaps Found, By Source

For management review. **Snapshot as of 2026-07-14 — analysis is still ongoing; this is not a
final or complete list.** More gaps are expected to surface as the remaining source material is
worked through.

**Sources considered in this analysis:**
1. **Pure-to-Write** — the raw source insurance data, before conversion
2. **PL101** (`Conversion_Mapping_BP_PL101_V2.xlsx`) — the official field specification for the
   Business Protection product
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
happens — vehicle details, business turnover, coverage selections, everything the customer
actually has on file today.

**How we use it:** For every field that ends up in the converted policy, we check: does the value
in the new system actually match what's sitting in Pure? If Pure has real data and the converted
policy shows it blank (or wrong), that's a conversion bug. If Pure genuinely has no data, that's
not our bug to fix — it's a data quality question for the business.

**Examples found this way:**

- **Business details answers leaking through when they shouldn't.** Across 8 different
  Business Details questions (mining equipment, heavy transport, watercraft repair, sideline
  business, and more), the system was correctly recording "No" for the question but then still
  sending a leftover dollar amount from an earlier, unrelated answer sitting behind the scenes.
  One customer's policy showed "No, we don't service mining equipment" alongside a $4,200 mining
  turnover figure. **Fixed and confirmed** — checked against a full batch of 152 fresh policies,
  zero remaining mismatches on any of the 8 questions.

- **Tyre Dealer and Heavy Duty Diesel Mechanic answers going missing.** For one customer's policy,
  Pure clearly showed "90% of turnover is vehicle servicing" and "Yes, this is a franchise" — but
  the converted policy sent blank for both. Root cause: a technical join between two reference
  tables wasn't accounting for extra spaces in the policy number field, so it silently attached
  the wrong policy's (blank) answers instead. **Fixed and confirmed** for this and every other
  affected policy.

- **Interested parties (banks, finance companies) dropped from the policy.** 213 policies had a
  bank or finance company with a genuine financial interest in a piece of business coverage, but
  the system's internal "does this coverage exist" signal was wrong, so the party was silently
  left off the policy. **Fixed and confirmed.**

- **Vehicles on the same policy showing each other's coverage.** For multi-vehicle commercial
  policies, the system was combining coverage details across all vehicles instead of keeping each
  vehicle separate — one customer's policy showed 3 different, conflicting coverage amounts
  stacked onto every one of their 3 vehicles. Affects 65% of all commercial vehicle rows.
  **Fixed, ready to deploy.**

- **Run-off policies missing almost everything.** 848 policies that are both "run-off" and have
  Public & Product Liability were being left out of the conversion entirely — not just one field,
  the whole policy's business details, location, and vehicle data. This directly explains a
  client-reported case where a policy's Business Information screen looked completely broken.
  **Fixed, ready to deploy** — larger change, being sequenced carefully given how many other
  screens it touches.

- **Engine Size and Gross Vehicle Mass blank for almost all commercial vehicles.** The system was
  reading these two fields from the wrong place in Pure — a field that's only filled in when a
  staff member manually overrides the vehicle record (which is rare), instead of the main field
  that's populated automatically for every vehicle. Confirmed by finding the exact same mistake
  already fixed once on the Personal Motor side of the system — it just never got carried over to
  Commercial. **Fixed, ready to deploy.**

### Recent client-requested changes — Redbook vehicle fields & new tag formatting

Two items this week came directly from a client request rather than our own sweep, so they're
called out separately.

- **Redbook vehicle attributes — client asked for a full status check.** The client asked how we
  were going with sending Power, Track Rear, Body Type, Engine Size, Gross Vehicle Mass,
  Induction Type, Fuel Type, and Import Type for vehicles that haven't been manually overridden —
  across both Personal and Commercial. We checked every one of the 8 fields live, for both
  products:
  - **5 of 8 already working correctly on Commercial** (Body Type, Induction Type, Import Type,
    Power, Track Rear — all 88–99.8% filled, sourced straight from Pure, no Redbook lookup
    involved beyond what's meant to be used for Market Value only, exactly as the client expected).
  - **2 fields (Engine Size, Gross Vehicle Mass) were the bug described above** — now fixed,
    ready to deploy.
  - **Fuel Type, Power, and Track Rear were never built for Personal Motor at all** — the tags
    exist in the output but are always empty. Pure does have this data available; this is real,
    outstanding work, not yet started. **Needs to be built.**

- **A newly-reported formatting mismatch on Yes/No answers.** The client flagged that
  "Is this vehicle used for ride-share?" was coming through as the word "NO" instead of the number
  `0` that Duck Creek expects for this type of field. Traced it to the Commercial vehicle view
  sending the raw Pure answer as text with no conversion — found the same field (and 2 close
  neighbors, "hire contract restrictions" and "driver supplied") is affected the same way, on
  4,667 policies. **Fixed, ready to deploy.**

---

## 2. PL101 (`Conversion_Mapping_BP_PL101_V2.xlsx`)

**What it is:** The official specification document for the Business Protection product — it
defines, field by field, which values Duck Creek will actually accept, and which fields have a
required minimum value.

**How we use it:** We check every value the conversion produces against this list. If a required
minimum isn't being enforced, or a dropdown value doesn't match what's approved, that's a gap this
document catches that a simple "is it blank" check would miss.

**Examples found this way:**

- **A required minimum limit not being enforced.** Several business coverage limits (Burglary
  contents, Business Interruption profit, minimum turnover) have a hard minimum dollar value that
  Duck Creek requires — sending anything below it fails the whole policy's migration. 109 policies
  were sending a real but below-minimum turnover figure (e.g. $42,000 against a $50,000 minimum)
  that would have failed. **Fixed and confirmed** across every coverage this rule applies to.

- **New Zealand Theft and Landslide limits using the wrong formula.** For New Zealand policies,
  these two limits are supposed to be capped using a specific combined-coverage formula from the
  spec — instead the raw, uncapped Pure value was being sent. Affected 64–67% of the relevant NZ
  policies. **Fixed and confirmed**, zero mismatches remain.

- **Import Type sent as a raw, untranslated code.** Commercial vehicles were sending Pure's raw
  internal code instead of a value Duck Creek recognizes, and the spec doesn't document what the
  correct target value should be. **Resolved per client confirmation** — not something code alone
  could fix.

---

## 3. Manuscript (other DCT configuration files, beyond PL101)

**What it is:** Beyond the PL101 field spec, Duck Creek's conversion process is driven by several
other configuration files — structural node definitions, and workflow rules for how and when
certain values are meant to reset or auto-populate.

**How we use it:** For questions that aren't about a single field's valid values, but about
*structure or behavior* — what a field's real target name is, or when Duck Creek expects a value
to be blank on purpose — we go to these files directly rather than guess.

**Examples found this way:**

- **Additional Interest party type not matching Duck Creek's exact wording.** The system was
  sending "PublicProductLiability"/"StockVehicles"/"CustomerVehicles" as the coverage tie for an
  interested party, but Duck Creek's manuscript shows it expects slightly different wording
  ("PublicandProductLiability", etc.) — the mismatch meant the party's coverage tie showed as "NA"
  in the UI despite the underlying data being correct. **Fixed and confirmed.**

- **Windscreen glass excess amount needs a client-confirmed dollar figure.** The manuscript
  confirms this is meant to be a calculated value ($1,000 or $500 depending on the coverage
  limit), not something Pure stores directly — Pure has no source for it at all. A fix is written
  and ready, but the exact dollar thresholds are inferred from field naming, not confirmed.
  **Awaiting client confirmation** on the correct figures before this goes live, since it's a
  client-visible number.

- **Hail & Malicious Damage Excess node name had the wrong capitalization.** The manuscript's
  exact field name uses a capital letter partway through that our output didn't match — since
  these names are case-sensitive, Duck Creek never recognized the field at all, even though the
  data behind it was fine. **Fixed and confirmed.** Separately, the manuscript shows this value
  is actually meant to sync from a different screen automatically, not come from Pure directly —
  **awaiting client clarification** on whether Pure has an equivalent field under another name.

- **Storm coverage field with no source anywhere.** The manuscript documents a "Storm" indicator
  for Stock Vehicles coverage, but no matching field exists anywhere in Pure or in the legacy
  scripts for this coverage — "Storm" only exists for Building coverage in the whole system.
  **Awaiting a client/business decision** on whether this field genuinely applies here at all.

---

## 4. SAS (legacy conversion scripts)

**What it is:** The client's original SAS-based scripts from the prior conversion effort — kept
as a reference for business logic that isn't obvious from Pure or the manuscripts alone.

**How we use it:** When a gap doesn't have an obvious source elsewhere, or when a fix needs to
match an existing, client-approved business rule exactly, we check whether the legacy SAS logic
already solved the same problem.

**Examples found this way:**

- **The Business Details leak (above) needed the original formula, not just a flag fix.** The
  first attempt at the Business Details fix only stopped the leftover dollar amount from leaking
  through — a client review of the fix caught that the underlying calculation itself was also
  using the wrong base figure. Going back to the original SAS line-by-line surfaced 6 further real
  differences (an entire eligibility condition that was missing, a fallback calculation that
  never got carried over, a "more than 30%" rule that blanks the figure back out below that
  threshold) — all now corrected together. **Fixed and confirmed.**

- **Run-off policy exclusion was scoped too broadly.** The legacy SAS only ever excluded run-off
  policies from one specific coverage line — our system was excluding them from the *entire*
  conversion instead, which is the 848-policy issue described above. Checked the SAS's own code
  comment directly to confirm the intended, narrower scope. **Fixed, ready to deploy.**

- **Interested parties with no coverage tie at all.** The legacy SAS had a specific extra step for
  interested parties that aren't tied to any location or coverage line (e.g. a finance-only
  party) — that step never got carried over to the current system, so those parties were silently
  dropped. **Fixed and confirmed.**

- **Adjustment amounts always shown as a dollar figure, never a percentage.** Every business
  underwriting adjustment currently converts to a dollar-equivalent regardless of how the original
  discount/loading was recorded in Pure. The legacy SAS preserves the original percentage/dollar
  type. **Still open** — needs a business decision on whether the current dollar-normalization is
  intentional or should be reverted to match the original type.

---

## Summary

| Source | Gaps found | Fixed & confirmed | Awaiting client/business | Still investigating |
|---|---|---|---|---|
| Pure-to-Write | 9 highlighted above (of a larger set) | 3 | — | 6 (4 fixed &amp; ready to deploy, not yet live; 1 not yet started) |
| PL101 | 3 | 2 | — | 1 (resolved per client) |
| Manuscript | 4 | 2 | 2 | — |
| SAS | 4 | 3 | — | 1 |

This is a curated set of the clearest, most concrete examples per source, as analysis stands
**today, 2026-07-14** — not the full gap register and not a final count. Analysis is ongoing and
these numbers will grow. The complete list (67 items across all statuses, current cut) is
available separately if needed.
