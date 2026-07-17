# Party Delta — Internal Technical Annex

**Date:** 14 July 2026 (all counts as at this date, PRD)
**Companion to:** Party_Delta_Scenarios_ClientDiscussion.md
**Access note:** All evidence collected read-only from Snowflake PRD. No data was modified.
**Business driver:** delta was re-enabled for **CSL data, primarily STOP_CREDIT**. Membership fields = **EFFECTIVE_DATE + PAID2DATE** (confirmed); MEM_REF and AMOUNT sit in the same NULL-together block and ride the same `<membershipvalidity>` template tokens.

---

## 1. Pipeline components (verified live from Snowflake, not repo copies)

| Component | Object | Role |
|---|---|---|
| Main dim | `AGGNE.PRD.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2` | Yesterday's accepted state. 24,631 rows, 70 cols |
| Daily snapshot | `...SCD2_DELTA` | Today's Pure snapshot (rebuilt each run by `SP_PURE_SNAPSHOT_TO_WRITE_LOAD_DELTA` from `CML_DETAIL` + `CSL_DETAIL`). 24,629 rows |
| History | `...SCD2_HISTORY` | Pre-change images of impacted rows + `LOADDATE`. 36,353 rows |
| Field-level changes | `AGGNE.PRD.PARTY_CONVERSION_DELTA_CHANGES` | BK / COLUMN_NAME / OLD_VALUE / NEW_VALUE, rebuilt each run. 147 rows currently |
| DCT queue | `AGGNE.PRD_XML.CML_MIGRATION_DCT` | REQUEST_XML per party; RESULTS_JSON/RESPONSE_XML written back. 33,389 rows, 4 unprocessed |
| Push view | `AGGNE.PRD.VW_DIM_PARTY_SNAPSHOT_SEC_CONTACT` | **`WHERE IS_CURRENT = FALSE`** — selects exactly the rows steps 7–9 just replaced |
| XML builder | `AGGNE.PRD.INSERT_PARTY_SNAPSHOT_TO_DCTTABLE_SEC_CONTACT()` | 69-token REPLACE over full add/update XML template |
| Orchestrator | `AGGNE.PRD.PARTY_DAILY_RUN()` | 11-step wrapper with `PARTY_DAILY_RUN_LOG` + transaction/rollback. **Log is EMPTY — never executed; runs are done manually** via the operator script |

### Run mechanics (manual script ≈ PARTY_DAILY_RUN steps)
1. `UPDATE SCD2 SET IS_CURRENT = TRUE` (reset marker)
2. Truncate/DELETE `SCD2_DELTA`
3. `CALL SP_PURE_SNAPSHOT_TO_WRITE_LOAD_DELTA()` — rebuilds today's snapshot incl. `HASH_DIFF`
4. Rebuild `PARTY_CONVERSION_DELTA_CHANGES`: join SCD2↔DELTA on BK where `HASH_DIFF` differs, `OBJECT_CONSTRUCT` + `LATERAL FLATTEN`, keep only the **49-field compare list**
5. Copy impacted SCD2 rows → HISTORY with `LOADDATE`
6. DELETE impacted BKs from SCD2
7. `UPDATE SCD2_DELTA SET IS_CURRENT = FALSE`
8. INSERT changed BKs from DELTA → SCD2 (arrive with IS_CURRENT=FALSE)
9. INSERT brand-new BKs from DELTA → SCD2
10. `CALL INSERT_PARTY_SNAPSHOT_TO_DCTTABLE_SEC_CONTACT()` — builds full XML for every `IS_CURRENT=FALSE` row and queues to `CML_MIGRATION_DCT` (run manually/selectively — commented in the operator script)
11. Count `RESULTS_JSON IS NULL` (validation)
12. Response collection (operator script tail): loader writes results to `AGGNE.PRD_XML.CML_MIGRATION_DCT_PARTYID`; dedupe to latest `LOADDATE_DATE` per `PARTYDIM_ID` for today into a temp table, then backfill `CML_MIGRATION_DCT.RESULTS_JSON/RESPONSE_XML` where NULL (join on trimmed PARTY_DIM_ID)

Canonical operator script archived at [delta_operator_script_20260714.sql](delta_operator_script_20260714.sql).

**Key consequence:** the *decision* to push is field-level (compare list), but the *payload* is the whole record. Every pushed party carries all template fields; `IFNULL(col,'')` turns NULL into an **empty XML tag**, and the `else` branch (`PartyObj.updatePartyRq`) sends the full `PartyExtendedData` block — so an empty `<membervalidity>` / `<membershipvalidity>` clears membership in DCT.

## 2. Three field sets that don't agree

| Set | Contents | Mismatch effect |
|---|---|---|
| **HASH_DIFF** (~52 cols) | compare list **+ CSL_TENURE, CSL_MONTHLY_SPEND, CSL_CREDIT_USAGE** | These 3 are **deliberately excluded from monitoring** (business decision — they change every day). But they are still hashed: as of 2026-07-14, **19,981 of 24,631 parties (81%) have a hash mismatch producing zero change rows — 19,754 of them solely from these 3 fields** (SPEND 19,005 / USAGE 14,169 / TENURE 4,250). The daily run flattens and compares ~20k parties for nothing |
| **Compare list** (49 cols, hardcoded in step 4) | See SP; includes PAID2DATE, EFFECTIVE_DATE, MEM_REF, AMOUNT | This is the only gate to being pushed |
| **XML template tokens** (69) | Everything above **+ PROBABILITY_OF_DEFAULT, PRIMARY_PHONE_TYPE, PHONE_DETAILS, *_XMLDATA, LOAD_DATE…** | PROBABILITY_OF_DEFAULT / PRIMARY_PHONE_TYPE are pushed but **not hashed and not compared** → their changes alone are never detected (S-08); they only ride along when something else changes |

Fix R-2 (revised): **remove CSL_TENURE / CSL_MONTHLY_SPEND / CSL_CREDIT_USAGE from HASH_DIFF** so the hash matches the ignore decision (cuts the daily BASE set by ~99%); add PROBABILITY_OF_DEFAULT (and PRIMARY_PHONE_TYPE) to hash + compare list **if** Business confirms they should sync.

## 3. Evidence (read-only queries, 2026-07-14)

| Fact | Number | Query basis |
|---|---|---|
| Big-bang history load | 29,203 rows @ 2026-05-21 | HISTORY group by LOADDATE |
| Delta cadence | near-daily since 2026-06-22 (124–2,765 rows/day) | same |
| Parties with ALL membership fields NULL in Pure | **6,330 / 24,631 (25.7%)** | SCD2 |
| Latest run change mix | 147 rows: CONTACT_NAME 100, EFFECTIVE_DATE 23, PAID2DATE 23, TA_PAYMENT_METHOD 1 — all value→value | PARTY_CONVERSION_DELTA_CHANGES |
| **S-05 backlog: value→NULL pending right now** | **207 parties** (SCD2 PAID2DATE NOT NULL, DELTA NULL, hash differs) — **0 of them in the change table** → the manual `DELETE ... WHERE NEW_VALUE IS NULL` was run → all 207 are zombies re-appearing daily | SCD2 vs DELTA join |
| DCT-state basis for the 207 | **All 207: the LAST XML sent carried membership values and was confirmed processed** (`MAX_BY` over CML_MIGRATION_DCT). We have **no PRD Clarity/DCT read access**, so DCT state is always inferred from sent-and-processed history, never read directly | CML_MIGRATION_DCT last-push check |
| S-05 already executed historically (wiped) | **24 parties** had PAID2DATE in HISTORY, now NULL in SCD2 (e.g. CML00027849: 2025-07-01→NULL; CML00021885: 2025-05-31→NULL) | HISTORY vs SCD2 |
| S-03 (NULL→value, the good path) | 3 parties | HISTORY vs SCD2 |
| S-06 exposure today | 0 of the 207 currently have an additional non-membership change — but any ordinary edit (contact name is 100/147 of daily churn) flips one into the wipe path | change table vs 207 set |
| DELTA nulls today | 6,517 PAID2DATE/EFFECTIVE_DATE NULL vs 6,330 in SCD2 (net +187, consistent with 207 minus reversals) | DELTA |

Membership NULLs come as a block: PAID2DATE, EFFECTIVE_DATE, MEM_REF, AMOUNT are NULL together (6,330 each); MEMBER_TA_NUMBER and CSL_MEMBER_STATUS are never NULL.

## 4. Why the manual guard fails (S-05/S-06 mechanics)

The NULL-guard was only **added 2026-07-14** as an interim reaction to the wipes found that day — the 23 historical wipes all pre-date it, and it is not part of the standing design. The operator's `DELETE FROM Party_Conversion_Delta_Changes WHERE COLUMN_NAME IN ('PAID2DATE','EFFECTIVE_DATE') AND NEW_VALUE IS NULL`:

1. **Removes the party from steps 5–10 only if membership was its *only* change.** If any other compared field changed the same day, the BK survives in the change list → whole-record push with empty membership → DCT wiped despite the guard. (Also note the guard doesn't cover MEM_REF/AMOUNT going NULL.)
2. **Prevents SCD2 from ever accepting the new (NULL) state** → hash mismatch persists → the same parties reappear next run: 207 and growing. Each is one unrelated edit away from case 1.
3. It is manual and undocumented in the SP — `PARTY_DAILY_RUN` (the automation candidate) contains **no guard at all**, so switching it on today would push all 207 wipes in one run.

## 5. Recommended fixes (effort-ranked)

| # | Fix | Closes | Notes |
|---|---|---|---|
| R-1 | **Carry-forward instead of delete**: after step 3, patch DELTA rows — `SET PAID2DATE/EFFECTIVE_DATE/MEM_REF/AMOUNT = SCD2 values WHERE DELTA.col IS NULL AND SCD2.col IS NOT NULL` — then recompute those rows' HASH_DIFF (or accept one extra sync cycle). Party then syncs normally with last-known membership preserved | S-05 backlog, S-06 hole, zombie growth | Smallest change; keeps whole-record push. Needs business sign-off that Pure NULL ≠ deliberate cancellation (D-2/D-3) |
| R-2 | Align hash list = compare list = template business fields | S-07, S-08 | Adds CSL_TENURE/MONTHLY_SPEND/CREDIT_USAGE to compare; adds PROBABILITY_OF_DEFAULT, PRIMARY_PHONE_TYPE to hash+compare |
| R-3 | Pre-push exception report: any party whose outgoing XML would blank a field that was non-empty in the **last XML we sent** for that party (reference = `CML_MIGRATION_DCT` push history — our own data, no DCT access needed) | Makes wipe risk visible before pushing | **No PRD Clarity/DCT read access exists**, and CLARITY_BRONZE has no party-level objects — so last-sent state is the only available reference; it cannot see DCT-side manual edits (S-10/S-11 remain blind spots) |
| R-4 | Move manual script into `PARTY_DAILY_RUN` (it already has txn + logging) **after** R-1, then schedule | Operational risk, empty run log | Do not schedule before R-1 — the SP has no NULL guard today |
| R-5 | Longer term, D-1 dependent: field-level or DCT-aware merge. Note constraint: `PartyObj.updatePartyRq` takes the full `PartyExtendedData` blob — true field-level push likely means **reading DCT current values first and merging into the outgoing XML**, not a partial API call | S-10, S-11 fully | Significant build; only worth it if business rules DCT edits must survive |

## 6. Other observations

- **Conflict scenarios S-14/S-15 mechanics:** each push opens with `Search.queryIndexRq` on the party index keyed by CMLNumber with **`op="contains"`** (not exact match). PartyCount=0 → `addPartyRq`; PartyCount>0 → full `updatePartyRq`, which is what overwrites DCT edits. The `contains` operator is a latent wrong-party risk if CMLNumber values can be substrings of each other; current CML numbers are fixed-width (`CML########`) so exposure is theoretical today, but worth switching to an exact-match operator.
- There is no timestamp/version check anywhere in the update path — DCT locking timestamps (`~LocationLockingTS~` etc.) are fetched and echoed back within the same request, so they never detect a concurrent DCT-side edit; Pure wins unconditionally (S-15).

- `EFFECTIVE_DATE` is **TEXT** in SCD2 but cast `::DATE` in both HASH_DIFF and the push view — one malformed value fails the run (TRY_TO_DATE would be safer).
- S-13: `ACTIVE_FLAG` is hardcoded TRUE in the prepared source; there is no deactivation/delete path to DCT.
- The `else`/update XML branch also deletes non-primary emails/phones in DCT (`deletePartyEmailRq`/`deletePartyPhoneRq` for `PrimaryIndicator=0`) before re-adding from `{EMAIL_XMLDATA}`/`{PHONE_XMLDATA}` — DCT-side manually added contact points are also destroyed on every push (S-10 applies to contacts too).
- The manual operator script drifts from `PARTY_DAILY_RUN` (TRUNCATE vs DELETE, extra ad-hoc selects). Treat the **live SP + this annex** as the source of truth, per project convention.
- REQUEST_XML embeds a live DCT service credential in plain text in `CML_MIGRATION_DCT` (33k rows) — flag to whoever owns DCT access hygiene; not reproduced here.

## 7. Evidence collection scripts

Read-only collectors used for this annex (scratchpad, session 2026-07-14): `party_delta_collect.py` … `collect4.py` — row counts, SCD2/DELTA/HISTORY joins, GET_DDL of all 5 SPs + push view, change-table profiling. Re-run any time; they contain only SELECT/GET_DDL.
