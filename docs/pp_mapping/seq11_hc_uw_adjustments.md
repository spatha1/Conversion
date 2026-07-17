# Seq 11 — Home Contents UW Adjustments (`UnderwritingAdjustment`)

| | |
|---|---|
| **Script name** | BUILDING_UW (HC) |
| **Source view** | `AGGNE.DEV.PER_HC_BUILDING_UW` |
| **Target** | `AGGNE.DEV.PER_HC_TARGET` (ITR_TYPE = BUILDING_UW) |
| **Consumed by** | `{UW}` in seq 13 via `PER_HOME_BUILDING_PAYLOAD` LISTAGG |
| **Lineage** | `Output_UWAdjust_PER` (built by `SP_PP_ADJ_EXP_PREM` ← `per_summary` UW fields) WHERE COVERAGE='HC' AND amount not null, joined to `HC_02` → view → template → target |

## Template — identical shape to seq 5.

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `UnderwritingAdjustment/Type` | coverage key | {COVERAGE}='HC' | — | CONFIRM key |
| `UnderwritingAdjustment/AdjustmentSelection` | required — 0=%, 1=$ *(Package_Data 30027)* | hardcoded '1' ($) | — | G-19 P2 |
| `UnderwritingAdjustment/AdjustmentDollarAndPercent` | required *(Package_Data 29984)* | {ADJUSTMENTDOLLARANDPERCENT} raw | Output_UWAdjust_PER.UWADJUSTAMOUNT (COVERAGE='HC') | OK |
| `UnderwritingAdjustment/AdjustmentAmount` | unused | empty — no source column | — | EMPTY |
| `UnderwritingAdjustment/Recurring/Indicator` | boolean | hardcoded '1' | — | G-19 P2 |
| `UnderwritingAdjustment/UnderwritingDescription` | max Description | {UNDERWRITINGDESCRIPTION} escaped | Output_UWAdjust_PER.UWADJUSTNOTE | OK |


## Gaps

- **Shares G-19 (P2)** — AdjustmentSelection hardcoded `1` ($), Recurring hardcoded `1`. Confirm all HC UW adjustments in Pure are dollar amounts and recurring.
- Filter inconsistency (minor): seq 11 filters `UWADJUSTAMOUNT IS NOT NULL` only; seq 16 (motor) additionally filters `!= 0`. Zero-dollar HC adjustments produce visible no-op adjustment rows. Align to `!= 0`. Validate: `seq11_vq.sql`.
- Unlike seq 5, this one is **correctly wired end to end** (PER source table, and seq 13 template consumes `{UW}`).

## Validation queries

See [`seq11_vq.sql`](vq/seq11_vq.sql).
