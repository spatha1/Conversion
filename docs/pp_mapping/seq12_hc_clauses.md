# Seq 12 — Home Contents Clauses (`Clause`)

| | |
|---|---|
| **Script name** | LOC_HC_CLAUSE |
| **Source view** | `AGGNE.DEV.PER_HC_CLAUSE` |
| **Target** | `AGGNE.DEV.PER_HC_TARGET` (ITR_TYPE = LOC_HC_CLAUSE) |
| **Consumed by** | intended: `{HC_CLAUSE}` — **but the live seq 13 template carries `{clauses}` (see seq 13, G-28)** |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE` → `CLAUSES` (staging) WHERE COVERAGE='HC' AND `_IS_CURRENT='TRUE'`, joined to `HC_02` → view → template → target |

## Template — identical shape to seq 6 (`<Clause>` with hardcoded `Indicator=1`, `DisableFlag=1`).

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `Clause/Type` | optional, clause code list | {DCCLAUSETYPE} pass-through | CLAUSES (COVERAGE='HC') ⋈ HC_02 | CONFIRM codes |
| `Clause/Indicator` | boolean | hardcoded "1" | — | BY DESIGN |
| `Clause/Description` | free text | {DCINPUT} NOT escaped; rows never reach XML (seq 13 template still says {clauses}) | — | → G-28 G-21 P2 |
| `Clause/DisableFlag` | boolean | hardcoded "1" | — | BY DESIGN |


## Gaps

- Rows load correctly into `PER_HC_TARGET` and the source view aggregates them into its `HC_CLAUSE` column — but they **never reach the final XML** because the live seq 13 template still says `{clauses}` (lowercase, no matching column). Logged as **G-28 (P1)** under seq 13, where the fix belongs.
- **Shares G-21 (P2)** — `{DCINPUT}` not XML-escaped.

## Validation queries

See [`seq12_vq.sql`](vq/seq12_vq.sql).
