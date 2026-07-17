# Seq 6 — Home Buildings Clauses (`Clause`)

| | |
|---|---|
| **Script name** | HB_CLAUSE |
| **Source view** | `AGGNE.DEV.HB_CLAUSE` *(fetched live from Snowflake — not in repo)* |
| **Target** | `AGGNE.DEV.PER_BUILDING_TARGET` (ITR_TYPE = HB_CLAUSE) |
| **Consumed by** | `{HB_CLAUSE}` in seq 7 via `PER_HOME_BUILDING_PAYLOAD` CTE_BUILDING_CLAUSES |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE` → `CLAUSES` (staging, Pure-to-Write SP line 10256) WHERE COVERAGE='HB' AND `_IS_CURRENT='TRUE'`, joined to `HB_02` → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<Clause>
  <Type>{DCCLAUSETYPE}</Type>
  <Indicator>1</Indicator>       <!-- hardcoded -->
  <Description>{DCINPUT}</Description>
  <DisableFlag>1</DisableFlag>   <!-- hardcoded -->
</Clause>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `Clause/Type` | optional, building clause code list | {DCCLAUSETYPE} pass-through | CLAUSES (COVERAGE='HB', _IS_CURRENT) ⋈ HB_02 ← SCHEDULE_CLAUSES_TEMPLATE | CONFIRM codes |
| `Clause/Indicator` | boolean | hardcoded "1" | — | BY DESIGN |
| `Clause/Description` | free text | {DCINPUT} pass-through, NOT escaped | — | G-21 P2 |
| `Clause/DisableFlag` | boolean | hardcoded "1" | — | BY DESIGN |


## Gaps

- **G-21 (P2) — no XML escaping on `{DCINPUT}`** (unlike the UW views, which escape `&`). A clause description containing `&`, `<` or `>` produces malformed XML for the whole policy. Same applies to seq 12 (HC) — seq 17 (motor) inherits an UPPER-cased description instead (see seq 17). One-line fix per view. Validate: `seq06_vq.sql`.
- Clause-code validity: list the distinct `DCCLAUSETYPE` values and check against the DCT clause options (some legacy HB clause codes may not exist in PP DCT). VQ provided.
- Hardcoded `DisableFlag=1` / `Indicator=1` — confirm intended (clauses shown but locked).

## Validation queries

See [`seq06_vq.sql`](vq/seq06_vq.sql).
