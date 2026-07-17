# Seq 17 — Motor Clauses (`Clauses`)

| | |
|---|---|
| **Script name** | COM_CLAUSE |
| **Source view** | `AGGNE.DEV.COM_CLAUSE` *(fetched live from Snowflake — not in repo)* |
| **Target** | `AGGNE.DEV.PER_COM_COVERAGES_TARGET` (ITR_TYPE = COM_CLAUSE) |
| **Consumed by** | `{COM_CLAUSE}` in seq 18 via `PER_COM_PAYLOAD` LISTAGG |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE` + `PER_CLAUSEAMENDMENTMV` → `PM_02.CLAUSE_TEXT` = **`UPPER(CAText)`** / `CLAUSE_DESC` = `UPPER(CADescription)` → `PM_03` → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<Clauses>
  <Type>Motor</Type>
  <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
  <SelectClauseDescription>{DCINPUT} </SelectClauseDescription>
  <IsClauseReadOnly>0</IsClauseReadOnly>
  <IsEditable>1</IsEditable>
  <Value>{DCINPUT}</Value>
  <DescriptionValue>{DCINPUT}</DescriptionValue>
</Clauses>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `Clauses/Type` | — | hardcoded "Motor" | — | BY DESIGN |
| `Clauses/ClausesSelection` | optional — PM* codes only *(PP base 2558)* | {DCCLAUSETYPE} — PM_02 built as UPPER(CAText) | PM_03.CLAUSE_TEXT ← SCHEDULE_CLAUSES_TEMPLATE + PER_CLAUSEAMENDMENTMV | G-38 P1 |
| `Clauses/SelectClauseDescription` | free text | {DCINPUT} = UPPER(CADescription), ALL CAPS | PM_03.CLAUSE_DESC | G-39 P3 |
| `Clauses/IsClauseReadOnly` | — | hardcoded "0" | — | BY DESIGN |
| `Clauses/IsEditable` | — | hardcoded "1" | — | BY DESIGN |
| `Clauses/Value` | free text | {DCINPUT} same ALL-CAPS value | PM_03.CLAUSE_DESC | → G-39 G-21 P2 |
| `Clauses/DescriptionValue` | free text | {DCINPUT} same ALL-CAPS value | PM_03.CLAUSE_DESC | → G-39 |


## Gaps

- **G-38 (P1) — `UPPER()` breaks mixed-case clause codes and CM_*/FV_* codes are disabled in PP.** Two compounding problems:
  1. PM_02 stores `UPPER(CAText)` — any source clause matching a PP `PM*` code (e.g. `PMLearnerextension`) becomes `PMLEARNEREXTENSION`, which is not a valid option value.
  2. Legacy `CM_C*` clause codes (which survive UPPER unchanged) are validRef=False — disabled options — in the PP product.
  Net effect: it is structurally impossible for seq 17 to emit a valid PP clause selection. Fix: carry the raw `CAText` case through (or map legacy CM_* codes → their PM* equivalents per a client-agreed table). Validate: `seq17_vq.sql`.
- **G-39 (P3)** — descriptions forced to ALL CAPS (`UPPER(CADescription)`) — cosmetic but client-visible on the quote; and not XML-escaped (shares G-21).

## Validation queries

See [`seq17_vq.sql`](vq/seq17_vq.sql).
