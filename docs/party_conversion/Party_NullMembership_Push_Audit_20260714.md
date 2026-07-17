# Party Delta — NULL Membership Push Audit (Impact Analysis Input)

**Date:** 14 July 2026 · PRD · read-only audit of `AGGNE.PRD_XML.CML_MIGRATION_DCT.REQUEST_XML`
**Membership fields:** `EFFECTIVE_DATE` (→ `<membership EffectiveDate>`), `PAID2DATE` (→ `ExpirationDate`)
**Business context:** delta was (re-)enabled primarily for **CSL data — mostly STOP_CREDIT**. Membership dates are not the reason for delta; they ride along because the push is whole-record.

## Method

Every XML ever queued to DCT is retained in `CML_MIGRATION_DCT`. A party pushed with NULL membership renders as `<membership EffectiveDate="" ExpirationDate="" ...>`; with values it renders `EffectiveDate="2..."`. Each party's push history was classified across all 33,389 requests (24,631 distinct parties, 2026-05-19 → 2026-07-13). 68 early rows (~0.2%) contain no `<membership>` tag at all (older template) and are excluded from classification.

**Scope caveat:** we have no direct read access to DCT in PRD. All statements about DCT state describe **what was sent and confirmed processed** (`RESULTS_JSON` present). A manual edit made inside DCT after the last push is invisible to this audit.

## Results — direct answer

**Since delta day 1 (22 Jun 2026): 968 requests carrying empty membership dates were sent to DCT, covering 595 distinct parties.**

| Category (lifetime view, all 24,631 parties) | Parties | Meaning / impact |
|---|---:|---|
| **WIPED_HAD_VALUES_BEFORE** | **23** | DCT received real membership dates earlier (big bang), then a later delta push sent them **empty → membership cleared in DCT**. All 23 pushes were processed (`RESULTS_JSON` present). **Priority list for policy impact check.** |
| RECOVERED_NOW_HAS_VALUES | 3 | Went empty at some point but the latest push carries values again (Scenario 1 round-trip). Check for MTAs done during the empty window. |
| ALWAYS_SENT_EMPTY | 6,301 | Never had membership in Pure (big-bang included). 571 of these were **re-pushed empty during the delta era** (STOP_CREDIT / contact churn). No Pure-side loss — but any membership a user keyed **directly into DCT** for these parties was silently wiped on re-push. This DCT-side exposure is not visible from Snowflake and needs the DCT/policy check. |
| ALWAYS_VALUES | 18,304 | No exposure. |

Reconciliation: the 23 wiped parties here match the 24 found via SCD2-vs-HISTORY (the 24th changed in Pure but its empty push is still pending). The **207-party zombie backlog** (held back by the manual delete) is *not* yet in these numbers — it is the queue of *future* wipes.

## Deliverable for the DCT policy check

[Party_NullMembership_Pushed_DCT_20260714.csv](Party_NullMembership_Pushed_DCT_20260714.csv) — 6,332 parties (every party ever sent empty), sorted so the 23 WIPED parties are first. Columns: `CML_NUMBER, CATEGORY, FIRST_PUSH, LAST_PUSH, FIRST_EMPTY_PUSH, PUSHES_WITH_VALUE, PUSHES_EMPTY, LATEST_MEMB, LATEST_PROCESSED`.

Suggested check order in DCT:
1. **23 WIPED** — find policies attached to these parties; any policy issued/MTA'd relying on membership validity after `FIRST_EMPTY_PUSH` is impacted.
2. **3 RECOVERED** — policies touched between the empty window and recovery.
3. **595 delta-era empty** (CSV: `FIRST_EMPTY_PUSH >= 2026-06-22`) — spot-check whether any had membership keyed manually in DCT before the re-push.

## Note on STOP_CREDIT

Because STOP_CREDIT is the main business driver, note that **every STOP_CREDIT update on a party whose Pure membership is NULL wipes membership in DCT** (the whole record goes out with empty tags). The carry-forward fix (R-1 in the internal annex) lets STOP_CREDIT flow daily **without** this side effect — the two are not in conflict.

Also: `PARTY_CONVERSION_DELTA_CHANGES` is rebuilt every run, so *why* a party was pushed (which field triggered it) is not retained. Recommend persisting it per run (add RUN_DATE) so future impact analyses can tie each push to its trigger field.
