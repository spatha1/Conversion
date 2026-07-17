# Seq 5 — Home Buildings UW Adjustments (`UnderwritingAdjustment`)

| | |
|---|---|
| **Script name** | BUILDING_UW |
| **Source view** | `AGGNE.DEV.BUILDING_UW` *(fetched live from Snowflake — not in repo)* |
| **Target** | `AGGNE.DEV.PER_BUILDING_TARGET` (ITR_TYPE = BUILDING_UW) |
| **Consumed by** | **nothing** — the seq 7 template has no `{UW}` token (see gaps) |
| **Lineage** | `Output_UWAdjust_BSP` (**BSP table**) + `LOCATION_BB_COVERAGE` (**BP staging**) WHERE COVERAGE='BB' → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<UnderwritingAdjustment>
  <Type>{COVERAGE}</Type>
  <AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
  <AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
  <AdjustmentAmount></AdjustmentAmount>
  <Recurring><Indicator>{RECURRINGINDICATOR}</Indicator></Recurring>
  <UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `UnderwritingAdjustment/Type` | coverage key | {COVERAGE} — hardcoded 'Building' by view | — | OK |
| `UnderwritingAdjustment/AdjustmentSelection` | required — 0=%, 1=$ *(Package_Data 25240)* | {ADJUSTMENTSELECTION} — hardcoded '1' ($) by view | — | G-19 P2 |
| `UnderwritingAdjustment/AdjustmentDollarAndPercent` | required *(Package_Data 25197)* | {ADJUSTMENTDOLLARANDPERCENT} raw | Output_UWAdjust_BSP.UWADJUSTAMOUNT — wrong-LOB source | G-20 P1 |
| `UnderwritingAdjustment/AdjustmentAmount` | unused | empty — no source column | — | EMPTY |
| `UnderwritingAdjustment/Recurring/Indicator` | boolean | {RECURRINGINDICATOR} hardcoded '1' | — | G-19 P2 |
| `UnderwritingAdjustment/UnderwritingDescription` | max Description | {UNDERWRITINGDESCRIPTION} — &/quote escaped | Output_UWAdjust_BSP.UWADJUSTNOTE | OK |


## Gaps

- **G-20 (P1) — seq 5 output is never used AND sources the wrong LOB.** Two independent problems:
  1. The view reads `Output_UWAdjust_BSP` + `LOCATION_BB_COVERAGE` — both **Business Protection** staging objects. For PP policies these produce no (or wrong-population) rows.
  2. Even where rows land in `PER_BUILDING_TARGET`, the seq 7 template contains **no `{UW}` token** — HB underwriting adjustments never reach the final XML. (Seq 7 also hardcodes `<UWAdjustmentIndicator>0</UWAdjustmentIndicator>`.)
  Decision needed: is HB UW adjustment in scope for conversion? If yes — repoint the view at `Output_UWAdjust_PER` (COVERAGE='HB') and add `{UW}` + indicator to the seq 7 template; if no — retire seq 5 to avoid dead rows. Validate: `seq05_vq.sql`.
- **G-19 (P2) — AdjustmentSelection hardcoded `1` ($) and Recurring hardcoded `1`.** If any source adjustment is a percentage, it will be applied as dollars. Confirm the business rule that `UWADJUSTAMOUNT` is always a dollar amount and always recurring. (Same pattern in seqs 11 and 16.)

## Validation queries

See [`seq05_vq.sql`](vq/seq05_vq.sql).
