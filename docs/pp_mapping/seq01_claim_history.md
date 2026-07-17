# Seq 1 — Account Claim History (`losshistory`)

| | |
|---|---|
| **Script name** | account_info_claim_history |
| **Source view** | `AGGNE.DEV.PER_VW_CLAIM_HISTORY` |
| **Target** | `AGGNE.DEV.PER_CLAIM_HISTORY_TARGET` |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.per_clmhistory` / `per_driveraccident` → `CLAIMHISTORY` (staging, Pure-to-Write SP line 1050) → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<losshistory>
  <DateOfClaim>{DATEOFCLAIM}</DateOfClaim>
  <AmmountPaid>{AMOUNTPAID}</AmmountPaid>
  <Line>{LINE}</Line>
  <Cause>{CAUSE}</Cause>
  <Source>Perf</Source>            <!-- hardcoded -->
</losshistory>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `losshistory/DateOfClaim` | date, required | {DATEOFCLAIM} — letters stripped, TRY_TO_DATE | CLAIMHISTORY ← per_clmhistory.DATEOFCLAIM | G-15 P2 |
| `losshistory/AmmountPaid` | required, max CreditsAndDebits | {AMOUNTPAID} pass-through | CLAIMHISTORY ← per_clmhistory amount | OK |
| `losshistory/Line` | optional, free-form line code | {LINE} pass-through | CLAIMHISTORY ← claim line code | OK |
| `losshistory/Cause` | required — AtFault, NotAtFault, Theft, Fire, Flood, Burglary, Other | {CAUSE} — only 'Motor'→'Other' mapped, else raw | CLAIMHISTORY ← per_clmhistory cause text | G-16 P1 |
| `losshistory/Source` | free text | hardcoded "Perf" | — | BY DESIGN |


## Gaps

- **G-16 (P1) — Cause caption-vs-code.** The view passes raw source text; DCT option *values* are camelCase (`AtFault`, `NotAtFault`…). Any source value with spaces ("At Fault", "Not At Fault") is an invalid dropdown value on a required field. Same bug class as VehicleType/DriveDescription in seq 18. Fix: add caption→code CASE. Validate: `seq01_vq.sql`.
- **G-15 (P2) — Unparseable claim dates emit empty `<DateOfClaim>`** on a required field (letters-stripping regex + `TRY_TO_DATE` → NULL is silent). Decide a fallback (policy effective date? exclusion?). Validate: `seq01_vq.sql`.

## Validation queries

See [`seq01_vq.sql`](vq/seq01_vq.sql).
