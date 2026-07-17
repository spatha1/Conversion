# Seq 2 — Prior Insurance Info (`priorinsuranceinfo`)

| | |
|---|---|
| **Script name** | Prior_INFO |
| **Source view** | `AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION` |
| **Target** | `AGGNE.DEV.PER_COMPETITOR_INFORMATION_TARGET` |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.per_summary` + `udl_suumr002` (insurer lookup) → `PER_Competitor_Information` (staging, Pure-to-Write SP line 1093) → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<priorinsuranceinfo>
  <PriorCarrier>{PRIORCARRIER}</PriorCarrier>
  <Price>{PRICE}</Price>
</priorinsuranceinfo>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `priorinsuranceinfo/PriorCarrier` | conditional required — Allianz, CGU, Elders, GIO, MotorTradeDirect, NRMA, Other, QBE, SGIC, SGIO, Unknown, VERO, Wesfarmers | {PRIORCARRIER} pass-through (space-stripping removed per PolicyAttach reference) | PER_Competitor_Information ← per_summary.SUCompetitorName ⋈ udl_suumr002 lookup | G-17 P2 |
| `priorinsuranceinfo/Price` | max Premium | {PRICE} COALESCE 0, NUMBER(10,2) | PER_Competitor_Information ← per_summary premium | OK |


## Gaps

- **G-17 (P2) — PriorCarrier value form needs one authoritative answer.** The manuscript says option value = `MotorTradeDirect` (no spaces); the current view passes "Motor Trade Direct" with spaces, based on the PolicyAttach reference view. Both can't be right — confirm against a working DCT quote and align. Also: any source insurer outside the 13-option list passes through unvalidated (e.g. legacy insurer names). Validate: `seq02_vq.sql`.

## Validation queries

See [`seq02_vq.sql`](vq/seq02_vq.sql).
