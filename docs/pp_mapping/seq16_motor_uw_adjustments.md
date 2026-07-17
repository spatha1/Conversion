# Seq 16 — Motor UW Adjustments (`UnderwritingAdjustment`)

| | |
|---|---|
| **Script name** | PER_PM_BUILDING_UW |
| **Source view** | `AGGNE.DEV.PER_PM_BUILDING_UW` |
| **Target** | `AGGNE.DEV.PER_COM_COVERAGES_TARGET` (ITR_TYPE = PER_PM_BUILDING_UW) |
| **Consumed by** | `{UW}` in seq 18 via `PER_COM_PAYLOAD` LISTAGG |
| **Lineage** | `Output_UWAdjust_PER` (`SP_PP_ADJ_EXP_PREM` ← `per_summary`) WHERE COVERAGE='PM' AND amount not null AND != 0, joined to `PM_03` → view → template → target |

## Template — identical shape to seq 5/11.

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `UnderwritingAdjustment/Type` | coverage key | {COVERAGE}='PM' | — | OK |
| `UnderwritingAdjustment/AdjustmentSelection` | required — 0=%, 1=$ *(CoverageLibrary 37936)* | hardcoded '1' ($) | — | G-19 P2 |
| `UnderwritingAdjustment/AdjustmentDollarAndPercent` | required *(CoverageLibrary 37893)* | {ADJUSTMENTDOLLARANDPERCENT} raw | Output_UWAdjust_PER.UWADJUSTAMOUNT (COVERAGE='PM', ≠ 0) | OK |
| `UnderwritingAdjustment/AdjustmentAmount` | unused | empty — no source column | — | EMPTY |
| `UnderwritingAdjustment/Recurring/Indicator` | boolean | hardcoded '1' | — | G-19 P2 |
| `UnderwritingAdjustment/UnderwritingDescription` | max Description | {UNDERWRITINGDESCRIPTION} escaped | Output_UWAdjust_PER.UWADJUSTNOTE | OK |


## Gaps

- **Shares G-19 (P2)** — hardcoded `$` adjustment type and always-recurring. Confirm business rule.
- This seq has the `!= 0` amount filter that seq 11 lacks — keep as the reference implementation when aligning seq 11.

## Validation queries

See [`seq16_vq.sql`](vq/seq16_vq.sql).
