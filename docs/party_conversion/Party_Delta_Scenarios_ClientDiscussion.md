# Party Conversion — Daily Delta Sync: Scenarios & Decisions Required

**Audience:** Business / Client stakeholders
**Date:** 14 July 2026
**Status:** For discussion — decisions required before delta is fully enabled as an automated daily process
**Scope:** Party (CML/CSL member) data synchronisation from Pure to DCT

---

## 1. Background

- Party conversion was executed as a **big-bang load in PRD on 21 May 2026** (~24,600 parties, 59 fields collected from Pure and loaded into DCT).
- Since **22 June 2026** a **daily delta** has been running: each day the current Pure party data is compared against the previous day's snapshot, and parties with changes are re-sent to DCT.
- **Business purpose of the delta: keeping CSL data current in DCT — primarily STOP_CREDIT** (and related credit-control fields such as stop-credit reason, credit limit and credit risk). Membership dates were never the driver for delta; they are carried along only because the process re-sends the whole party record.

This document lays out **every scenario the delta can produce**, which of them are safe, which ones **silently lose data**, and the **decisions we need from Business** before the delta runs unattended.

## 2. Two design facts that drive every scenario

These two facts are the root of all the risk scenarios below:

1. **The delta re-sends the whole party record, not just the changed field.**
   If *any one* monitored field changes in Pure (e.g. contact name), the *entire* party record — all fields, including membership dates — is re-sent to DCT and overwrites what DCT currently holds.

2. **The delta compares Pure against Pure — it cannot see DCT.**
   The comparison is "Pure today vs Pure yesterday". Any change a user makes **directly in DCT** is invisible to the delta. That DCT edit survives only until the *next time anything changes on that party in Pure* — at which point the whole-record push overwrites it without warning.

A third fact specific to the membership fields:

3. **Membership fields (Effective Date, Paid-to Date / Expiration) are frequently NULL in Pure.** Roughly **1 in 4 parties** currently has no membership dates in Pure. When the record is pushed, a NULL is sent as an **empty value**, which clears the field in DCT.

Put together: **every STOP_CREDIT update on a party whose membership dates are NULL in Pure re-sends that party with empty membership values** — the business-critical CSL update and the membership wipe travel in the same request.

### Fields in scope

**Monitored daily (change in any of these re-sends the whole record):**

| Group | Fields |
|---|---|
| **CSL credit-control** (the delta's purpose) | STOP_CREDIT, STOP_CREDIT_REASON, CSL_CREDIT_LIMIT, CSL_CREDIT_RISK, CSL_MEMBER_STATUS, TA_PAYMENT_METHOD |
| **Membership** (the wipe-risk fields) | **EFFECTIVE_DATE, PAID2DATE** (plus MEM_REF, AMOUNT in the same block) |
| Identity / registration | CMLNUMBER, CSL_NUMBER, CSLNUMBER, MEMBER_TA_NUMBER, CMLLEGALENTITY, CML_LEGAL_ENTITY, CSL_LEGAL_ENTITY, CMLTRADINGNAME, ABN_NZBN, STANDARD_INDUSTRY_CODE, STANDARD_INDUSTRY_CODE_DESCRIPTION |
| Contacts | MAINCONTACT, CONTACT_NAME, SCONDARYCONTACT, PHONE, EMAIL, PRIMARY_PHONE, PRIMARY_EMAIL, OTHERPHONE, OTHEREMAIL |
| Addresses | CORRESPONDENCELINE1–4, CORRESPONDENCEPOSTCODE, SITE_STREET, SITE_SUBURB, SITE_STATE, SITE_POSTCODE, STREET, SUBURB, STATE, POSTCODE, COUNTRY, SITE_COUNTRY |
| Management / other | CML_RISK_ACCOUNT_MANAGER, CSL_AREA_MANAGER, CSL_ZONE, CSL_REGION, MESSAGE |

**Deliberately not monitored (they change every day, by design):** CSL_TENURE, CSL_MONTHLY_SPEND, CSL_CREDIT_USAGE — a change in these alone does not trigger a push; their *current* values are still included whenever a party is pushed for another reason.

**Not monitored (see S-08):** PROBABILITY_OF_DEFAULT, PRIMARY_PHONE_TYPE — sent to DCT whenever the record is pushed, but a change in only these fields is never detected. Notable because probability of default is credit-control data, the very category delta was enabled for — Business to confirm whether this exclusion is intentional.

## 3. Scenario catalogue

### Group A — Changes made in Pure (no DCT edits involved)

| # | Scenario | What happens today | Outcome |
|---|----------|--------------------|---------|
| S-01 | New party created in Pure | Detected as new; party is created in DCT | ✅ Works as intended |
| S-02 | A monitored field changes value → value (e.g. **STOP_CREDIT flag flips**, credit limit updated, contact name changed) — party's membership dates populated in Pure **and no one has edited this party in DCT** | Whole record re-pushed; DCT updated | ✅ Works as intended — this is the case delta was enabled for. If the party *was* edited in DCT, the outcome changes: same push, but the DCT edit is reverted — see S-14 (different field), S-15 (same field), S-02a (membership) and the conflict matrix |
| S-02a | Same CSL change (e.g. **STOP_CREDIT**) — but the party's membership dates are **NULL in Pure** while **DCT holds membership values** | The STOP_CREDIT update goes out carrying **empty membership values → membership wiped in DCT as a side effect** of a legitimate credit-control update | 🔴 The delta's main use case and the wipe risk are the **same push** — this is why a field-level safeguard is needed rather than holding parties back |
| S-03 | **Membership fields go NULL → value in Pure** (policy issued; Pure populates membership afterwards — Scenario 1) | Change detected; whole record pushed; DCT party membership set to Pure's new dates (3 parties have taken this path in PRD). **But** the policy was issued *before* Pure had these dates — if the user keyed membership into DCT to issue the policy, the push **replaces the keyed dates with Pure's**, and nothing verifies that Pure's dates match what the policy was issued with | ⚠️ Mechanically works, but only safe if Pure is the sole author of membership dates and its values are guaranteed to match the issue-day data — neither is confirmed today |
| S-04 | Membership dates move value → value (e.g. renewal extends paid-to date) | Detected and pushed | ✅ Works as intended |
| S-05 | **Membership fields go value → NULL in Pure** | Whole record would be pushed with **empty membership values, wiping them in DCT**. Currently prevented only by a **manual step** where the operator deletes these changes before pushing — but the party is then never synced and **re-appears in the change list every single day** | ⚠️ **HIGH RISK** — manual, fragile, and grows daily |
| S-06 | **Membership goes value → NULL *and* another field changes on the same day** (e.g. **STOP_CREDIT is set** while membership lapses in Pure) | The manual protection in S-05 removes only the membership rows from the change list — the party **still gets pushed because of the other change**, and the push carries the **empty membership values, wiping DCT anyway** | 🔴 **CRITICAL GAP** — the current safeguard does not cover this case, and STOP_CREDIT churn is exactly what triggers it. The 207 held-back parties (S-05) convert to this scenario one by one as their CSL data changes |
| S-08 | PROBABILITY_OF_DEFAULT or PRIMARY_PHONE_TYPE change (sent to DCT but not monitored) | Change is never detected; DCT stays stale until some *other* field changes | ⚠️ Stale credit-control data with no signal — Business to confirm the exclusion is intentional |

### Group B — Changes made directly in DCT

| # | Scenario | What happens today | Outcome |
|---|----------|--------------------|---------|
| S-09 | User edits a party field in DCT; Pure unchanged | Delta cannot see it; the DCT value survives — for now. Pure and DCT silently diverge with no report | ⚠️ Unmonitored divergence |
| S-10 | User edits a party in DCT; **later, any monitored field changes in Pure** (even an unrelated one) | Whole-record push **overwrites every DCT edit on that party**, not just the field that changed in Pure. No warning, no audit | 🔴 **Silent loss of DCT user edits** |
| S-11 | Membership is NULL in Pure; user enters correct membership data **in DCT** (e.g. to complete an MTA); later anything changes on that party in Pure | Push sends empty membership values → **the user's DCT fix is wiped**; user must re-enter it, and it can be wiped again | 🔴 **Repeating data loss loop** — this is the exact situation raised as Scenario 2 |
| S-14 | **Different-field conflict:** Pure updates field A (e.g. STOP_CREDIT) while a DCT user has changed field B (e.g. phone number) on the same party | No real conflict exists — the two edits touch different fields — but the whole-record push **reverts field B to the Pure value** while applying field A | 🔴 Data loss without an actual conflict; a field-level merge would have handled this cleanly |
| S-15 | **Same-field conflict:** Pure and a DCT user change the **same field** to different values | Pure wins on the next push — regardless of which change was made later. There is no conflict detection, no warning to the DCT user, and no record that a conflict ever occurred | 🔴 Silent "Pure wins" with no audit trail; business may believe DCT corrections stick when they don't |

### Conflict matrix — who wins today?

Every combination of "Pure changed / DCT changed" and its current outcome. "Pure wins" always means *the entire record*, not just the changed field:

| | **DCT: no edit** | **DCT: edited field B** | **DCT: edited same field A** | **DCT: entered membership (Pure NULL)** |
|---|---|---|---|---|
| **Pure: no change** | In sync | DCT value survives — *until any future Pure change* (S-09) | DCT value survives — *until any future Pure change* (S-09) | DCT value survives — *until any future Pure change* (S-11) |
| **Pure: changed field A** | DCT updated ✅ (S-02) | **Field A applied, field B reverted** (S-14) | **Pure wins silently, even if the DCT edit was later** (S-15) | **Field A applied, membership wiped** (S-02a / S-11) |
| **Pure: membership → NULL** | Wipe held back only by manual step (S-05); wipes anyway if anything else changed (S-06) | Same, plus field B reverted | Same | **Both losses combine: membership wiped and edits reverted** |

The pattern: **DCT edits only ever survive by luck of timing** — nothing protects them; they persist exactly until the next Pure-side change on that party.

### Group C — Policy lifecycle & timing

| # | Scenario | What happens today | Outcome |
|---|----------|--------------------|---------|
| S-12 | **Policy issued while membership dates exist in Pure; membership then changes in Pure** (renewal, correction, or lapse to NULL) | The policy keeps the membership as at issue day; the delta updates only the *party* record. Nothing checks or records whether the policy's dates and the party's current dates still agree — after any later change **we cannot be sure they match**. An MTA reads the latest party data, which may differ from what the policy was issued on (and is empty if membership lapsed to NULL — Scenario 2) | ❓ Business to define which membership dates an MTA should use: issue-day (policy snapshot) or current (party record). A policy-vs-party membership reconciliation report is needed either way |
| S-13 | Party is deactivated / removed in Pure | Delta has add & update paths only — there is **no removal/deactivation push** to DCT | ❓ Open question — confirm expected behaviour |

## 4. Worked examples — membership dates day by day

All examples use one party and the two membership fields: **EffectiveDate** and **Paid-to Date** (sent to DCT as ExpirationDate).

**S-03 — Pure fills the dates after policy issue (NULL → value):**
| Date | Pure | DCT party record | Event |
|---|---|---|---|
| 05-Jul | EffectiveDate NULL · Paid-to NULL | empty | Policy issued in DCT; user keys **EffectiveDate 2026-07-05 · Paid-to 2027-07-05** into DCT to complete issuance |
| 06-Jul | Pure populates **2026-07-01 · 2027-07-01** | still 2026-07-05 · 2027-07-05 | Note: Pure's dates ≠ the keyed dates |
| 07-Jul | — | **2026-07-01 · 2027-07-01** | Delta pushes; keyed dates silently replaced; policy was issued on 05-Jul dates, party now shows 01-Jul dates — no check catches this |

**S-04 — normal renewal (value → value):** Pure Paid-to **2026-06-30 → 2027-06-30**; next delta run pushes; DCT shows 2027-06-30. ✅ (23 changes like this in the latest run.)

**S-05 — lapse to NULL (value → NULL):** Pure EffectiveDate 2024-07-01 · Paid-to 2025-07-01 → **both NULL**. Without the interim manual step, the next push sends empty dates and DCT is cleared — exactly what happened to the 23 wiped parties (e.g. one party went Paid-to 2025-07-01 → blank).

**S-06 — lapse + STOP_CREDIT on the same day:**
| Date | Pure | What the run does |
|---|---|---|
| 10-Jul | EffectiveDate 2024-07-01 · Paid-to 2025-07-01, STOP_CREDIT = No | in sync |
| 11-Jul | membership → **NULL · NULL**, STOP_CREDIT → **Yes** | Operator deletes the two membership change rows (interim guard) — but the party stays in the run because STOP_CREDIT changed |
| 11-Jul push | — | Whole record goes out: STOP_CREDIT = Yes **and empty membership** → DCT membership wiped despite the guard |

**S-11 — DCT fix keeps getting wiped:** Pure membership NULL; user keys **2026-07-01 · 2027-07-01** into DCT to complete an MTA. A week later the party's phone number changes in Pure → push sends empty membership → DCT blank again. User re-keys; any future Pure change blanks it again.

**S-15 — same field, both sides:** Pure Paid-to **2026-06-30**; DCT user corrects it to **2026-09-30** (say, after a payment dispute). Pure later updates the party's address → push reverts Paid-to to **2026-06-30**. The correction is gone, no warning, and it looks like it was never made.

**S-12 — policy and party drift apart:** Policy issued 05-Jul with Paid-to **2027-07-05**. In August, Pure corrects the party's Paid-to to **2027-01-05**; delta updates the DCT party. The policy still carries 2027-07-05, the party says 2027-01-05 — which one should an MTA in September use? Undefined today.

## 5. What we have already observed in PRD (as at 14 Jul 2026)

- **24 parties** have already had their membership dates go from a value to NULL in Pure since go-live (e.g. a party that held Paid-to 2025-07-01 / Effective 2024-07-01 now holds nothing).
- **207 parties** are *currently* sitting in the pending state of S-05: Pure now shows NULL membership dates, while **the last record sent to DCT for every one of these 207 parties contained membership values and was confirmed processed**. They are being held back **only** by the manual delete step, and they reappear in every run.
- *Note on DCT state:* we have no direct read access to DCT in PRD, so statements about what DCT holds are based on the full history of what was **sent and confirmed processed** — a subsequent manual edit inside DCT would not be visible to us.
- **3 parties** have gone the good direction (NULL → value, S-03) — confirming the business's Scenario 1 does occur and delta handles it.
- The most recent delta run contained 147 field changes: 100 contact-name, 23 effective-date, 23 paid-to-date, 1 payment-method — all normal value→value updates.

## 6. Decisions required from Business

| # | Decision | Options |
|---|----------|---------|
| D-1 | **Who is the source of truth for membership fields once a policy exists?** | (a) Pure always wins — DCT edits are temporary and may be overwritten (current behaviour); (b) DCT wins after policy issuance — membership fields excluded from delta once a policy exists; (c) most-recent change wins (requires change-tracking on both sides — significant build) |
| D-2 | **Should a NULL in Pure ever erase a populated value in DCT?** | Recommended: **No** — a blank source value should never overwrite real data ("carry-forward" rule). Business to confirm whether a genuine membership *cancellation* must be an exception, and how it is signalled |
| D-3 | **Is membership value → NULL in Pure a legitimate business event or a data error?** | If Pure re-populates it later automatically (Scenario 1 behaviour), the safe answer is to hold the last known value until it does. Business/Pure team to confirm why values revert to NULL |
| D-4 | **Are DCT-side party edits an approved practice?** | If yes, whole-record overwrite (S-10) needs a protection rule and users need guidance on which fields are safe to edit in DCT. If no, users must be told party data may be overwritten at any time |
| D-5 | Expected behaviour for parties deactivated in Pure (S-13) | Keep in DCT / flag inactive / other |

---
*Prepared by the conversion team. Technical detail, evidence queries and the underlying pipeline analysis are in the internal annex (Party_Delta_Internal_Annex.md).*
