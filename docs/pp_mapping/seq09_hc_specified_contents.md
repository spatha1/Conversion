# Seq 9 — HC Specified Contents (`SpecifiedContents`)

| | |
|---|---|
| **Script name** | HC_Specified_Contents |
| **Source view** | `AGGNE.DEV.PER_HC_SPECIFIEDCONTENTS` |
| **Target** | `AGGNE.DEV.PER_HC_TARGET` (ITR_TYPE = HC_Specified_Contents) |
| **Consumed by** | `{HC_SPECIFIED_CONTENTS}` in seq 13 via `PER_HOME_BUILDING_PAYLOAD` LISTAGG |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents` → `HC_02` (step-2 staging) → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<SpecifiedContents>
  {VALUE}          <!-- column carries its own <Value> tags -->
  {DESCRIPTION}    <!-- column carries its own <Description> tags -->
</SpecifiedContents>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `SpecifiedContents/Value` | int | {VALUE} — no empty-item filter (unlike seq 8) | HC_02.VALUESPECIFIED | G-27 P2 |
| `SpecifiedContents/Description` | free text | {DESCRIPTION} — NULL→empty, NOT escaped | HC_02.DESCRIPTIONSPECIFIED | G-21 P2 |


## Gaps

- **G-27 (P2) — no row filter: every HC_02 row emits a `<SpecifiedContents>` node, including policies with no specified items** (NULL value/description → `<Value></Value><Description></Description>`). This is exactly the empty-node defect that was fixed in seq 8 (`ANYITEMSEXCEEDVALUE='Yes' AND VALUE > 0` filter); seq 9 needs the equivalent (`VALUESPECIFIED IS NOT NULL AND VALUESPECIFIED > 0`). DCT sees a non-empty `{HC_SPECIFIED_CONTENTS}` block with no real items, which can mark the "Specified Contents" section as selected. Validate: `seq09_vq.sql`.
- **G-21 (shared, P2)** — description free text not XML-escaped.

## Validation queries

See [`seq09_vq.sql`](vq/seq09_vq.sql).
