# Client Ticket ↔ Gap Register Mapping — Batch 2 (2026-07-10)

Second cross-reference pass, covering the new export `files/Issues/Conversion/ATP-10219_Bugs_Sai_Raju.csv`
— 89 tickets total (rows 2-90), superset that also re-lists earlier-seen tickets. Same scope filter
as Batch 1 (`CLIENT_TICKET_MAPPING.md`): tickets labeled "CM details", "Fleet Details", "Business
details screen", "Location coverages BG/BC/BB/MY/EN", "Business Protection screen", or containing
explicit Commercial/Business signals ("commercial motor", "BI " = Business Interruption, Smash
Repairer/Tyre Dealer UW templates) are BP scope, not this register.

- **BP-scope tickets excluded: ~55**
- **PP-scope tickets found: 15** (including 9 already known from Batch 1)
- **Ambiguous, no clear LOB signal in title — needs your judgment: 12** (listed at the bottom)

---

## 1. Headline finding — P00010162 (the client's own primary test policy, referenced by 6 tickets)

Investigated live. This is bigger than any single ticket — it looks like a real, structural bug in
how `HB_02`/`HC_02` (and possibly `PM_01`) get populated for policies with multiple locations
and/or a renewed term:

- `Locationdetails_PER` confirms **both** current-term locations (2026-09-01) have
  `HOMEBUILDINGS='Yes'` and `HOMECONTENTS='Yes'`:
  - Location 1 (`EXPIRINGID_P=2530787`): 1437 Lower Hotham Rd
  - Location 2 (`EXPIRINGID_P=2178093`): 1c Hill St
- `HB_02` and `HC_02` — **zero rows for either current-term location.** Nothing.
- `PM_01` (Motor) has 7 vehicle rows, but tagged against `EXPIRINGID_P=585251` — the **old 2021
  term**, not either current 2026 location.
- `SAMPLE_PER` (the master in-scope join key) correctly has all 3 EXPIRINGID_P values including
  both current ones, so that's not the blocker.

This directly explains:
- **ATP-11117** (Home Buildings/Contents not selected)
- **ATP-11115** (Private Motor Vehicle details did not populate) — likely explained by PM_01 reading
  the wrong (old) term, on top of the already-known G-06/G-09/G-10 Override-gating issue
- Likely contributes to **ATP-11110** (Location 1 sections missing)

**This also means G-43 ("closed — false positive, only 2 of 4,006 policies genuinely affected")
needs re-opening.** My original re-measurement was correct for the specific "is Location 1 present
at all" question, but this new evidence shows a different, real problem: HB_02/HC_02 failing to
populate for a policy's current term under certain conditions (multi-location and/or renewal).
Root cause not yet found — needs SP-level tracing (why does HB_02/HC_02's build logic skip a
location/term that `Locationdetails_PER` says should qualify?). **Not yet investigated further —
next concrete step, not done today.**

---

## 2. New PP gaps from this batch

| Ticket | Summary | Finding | Gap |
|---|---|---|---|
| **ATP-11116** | Private Motor imposed excess failed to migrate | Live-confirmed: `<ImposedExcess/>` is a hardcoded empty tag in the seq 18 template — no token, no source column exists anywhere on `PM_03` either. Same "no such concept in PP's data model" pattern as G-23 (HB) / G-34 (HB risk-level) — third instance. | **G-48 (NEW)** — bundle with G-23/G-34 for one client answer, not three separate asks |
| **ATP-11117** / **ATP-11110** / **ATP-11115** | Home Buildings/Contents not selected; Location 1 sections missing; Vehicle details did not populate | All three trace to the P00010162 finding above — HB_02/HC_02 failing to populate for a valid current-term location | **G-49 (NEW, investigating)** — supersedes/reopens G-43's scope; root cause not yet found |

## 3. Already-known gaps, reconfirmed by this batch

| Ticket | Gap | Note |
|---|---|---|
| ATP-11123 | (was going to be G-40-adjacent) | **Checked live against P00026900 — already correct** ("Model car collection", $10,000). Filed 2026-07-09, before today's G-27 deployment. Very likely already resolved — no action needed, but worth confirming with the client on the next batch. |
| ATP-11113 | G-07-adjacent | Checked live against P00010162 — VoluntaryExcess is **not** blank (one vehicle shows 500, rest show 0). Doesn't match "failed to migrate" as described. Needs clarification from the client on which specific vehicle they expected a value for — don't assume this is G-07's re-banding issue without more detail. |
| ATP-11112 | Related to G-11, not merged (per Batch 1) | Still the same conclusion — describes age *increasing*, a renewal recompute symptom, not G-11's blank/16-vs-17 initial-conversion issue. No new info this batch. |
| ATP-11111 | **G-42** | Direct match — Motor Premium always 0. Fix already drafted, ready to deploy (not yet deployed). |
| ATP-11107 | **G-40** | Direct match — Specified Items Away from Premises. Still awaiting client on DCT node shape. |
| ATP-11106 | Checked, not a bug (per Batch 1) | No new info this batch — same conclusion stands. |
| ATP-11105 | **G-41** | Direct match — Rewired/Replumbed dates. Still investigating (see G-41 file — narrowed to raw-source-vs-downstream gap, not fully closed). |
| ATP-10965 | **G-46** | Direct match — Motor Only protections with Location selected. Still investigating. |
| ATP-10963 | **G-02/G-03/G-05/G-06/G-09/G-10** | Direct match — Personal motor vehicles failing to transfer. Mixed status (some ready to deploy, some awaiting client) — see `SEQ_GAP_ATP_MASTER.md`. |
| ATP-10962 | **G-45** | Direct match, and this batch's description gives a clearer expected-value rule: *"Legacy start date should match the inception date of the migrated protection or the migrated renewal field already in PURE."* This may be answerable now without waiting on the client — **worth re-investigating G-45 with this rule in mind rather than leaving it as a blind question.** Not yet done. |
| ATP-10961 | **G-44** | Direct match — Account handler default. Symptom fix ready; root cause (only 16.7% of PP policies match `ACCOUNT_HANDLER` at all) still open. |

---

## 4. Ambiguous — no clear BP/PP signal in the title, needs your call

These don't contain the BP-exclusion keywords, but also aren't explicitly labeled PP. Listed here
rather than guessed at:

| Ticket | Summary |
|---|---|
| ATP-11151 | Endorsement Screen: Incorrect Clauses Type and Description |
| ATP-11145 | Location details screen: GNAF not showing on UI |
| ATP-11089 | Renewal - Adjustment migration incorrect |
| ATP-11088 | Renewal - Clause migration incorrect |
| ATP-11086 | Renewal - Manual referral text not populating |
| ATP-11042 | Renewal - reoccurring adjustment incorrectly migrated from % to $ |
| ATP-11041 | Renewal - Protection Number issue - Dash "-" after protection number |
| ATP-10980 | Additional Interest screen: data missing/incorrect |
| ATP-10979 | Schedule clause reference template data missing |
| ATP-10906 | Renewal - Contribution summary/payment frequency tabs missing |
| ATP-10904 | Renewal - S.14 Customer vehicles - Hail/Malicious Damage Excess |
| ATP-10903 | Renewal - Locations validated in PURE not validating in DC |

---

## Summary

- **1 headline structural finding** (P00010162 / HB_02-HC_02 population bug) explaining 3 tickets
  at once and reopening G-43's scope.
- **2 new gaps filed**: G-48 (Motor ImposedExcess, bundle with G-23/G-34), G-49 (HB_02/HC_02
  population bug, investigating).
- **9 tickets reconfirm gaps already in the register** — 2 of them (ATP-11123, ATP-11113) turned
  out NOT to match their expected symptom on live re-check, so don't assume the ticket = the gap
  without verifying.
- **1 ticket** (ATP-10962/G-45) now has enough detail in its description to possibly answer without
  waiting on the client — flagged for re-investigation.
- **12 tickets** need your call on PP vs BP scope before I analyze them further.
