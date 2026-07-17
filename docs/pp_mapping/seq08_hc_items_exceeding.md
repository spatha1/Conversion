# Seq 8 — HC Items Exceeding Value (`HomeContents`)

| | |
|---|---|
| **Script name** | HC_exceed_values |
| **Source view** | `AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE` |
| **Target** | `AGGNE.DEV.PER_HC_TARGET` (ITR_TYPE = HC_exceed_values) |
| **Consumed by** | `{HC_EXCEED_VALUES}` in seq 13 via `PER_HOME_BUILDING_PAYLOAD` LISTAGG |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents` → `HC_02` (step-2 staging) → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<HomeContents>
  {VALUE}          <!-- column carries its own <Value> tags -->
  {DESCRIPTION}    <!-- column carries its own <Description> tags -->
</HomeContents>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `HomeContents/Value` | optional, int (only sent when item qualifies) | {VALUE} — NUMBER(10,0) cast; filtered ANYITEMSEXCEEDVALUE='Yes' AND VALUE>0 | HC_02.VALUE ← PER_HomeContents | OK |
| `HomeContents/Description` | free text | {DESCRIPTION} — NULL→empty, NOT escaped | HC_02.DESCRIPTION | G-21 P2 |


## Gaps

- The empty-node class of bug is handled here (Yes + non-null + >0 filter) — **seq 9 lacks the equivalent filter** (see seq 9, G-27).
- **G-21 (shared, P2)** — `{DESCRIPTION}` free text is not XML-escaped.

## Validation queries

See [`seq08_vq.sql`](vq/seq08_vq.sql).
