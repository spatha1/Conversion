# Seq 15 — Motor Sub-Coverages (`coverage` blocks, Risk_CM)

| | |
|---|---|
| **Script name** | Risk_CM |
| **Source view** | `AGGNE.DEV.PER_COM_COVERAGES` |
| **Target** | `AGGNE.DEV.PER_COM_COVERAGES_TARGET` (ITR_TYPE = Risk_CM) |
| **Consumed by** | `{SUBCOV}` in seq 18 via `PER_COM_PAYLOAD` LISTAGG |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL` → `PM_03` (staging) + `Output_SubCover_PER` (premiums) → view → template → target |

## Template — same `<coverage>` shape as seq 4/10 (hardcoded `Indicator=1`).

## Sub-coverage blocks emitted (fixed list, one per vehicle-policy)

| Code | Type | Description |
|---|---|---|
| PMCMP_SD | CMP_SD | Comprehensive Property |
| PMCOR_SD | COR_SD | Choice of Repairer |
| PMFTL_SD | FTL_SD | Fire & Theft excluding Liability |
| PMLIA_SD | LIA_SD | Comprehensive Liability |
| PMPCH_SD | PCH_SD | Car Hire |
| PMTFT_SD | TFT_SD | Third Party Fire & Theft |
| PMTPO_SD | TPO_SD | Third Party Only |
| PMULG_SD | ULG_SD | Unlimited Glass |

All 8 blocks: `iValue` empty, `sValue` empty, `Indicator=1` (template hardcode); premium from `Output_SubCover_PER.EXPPREMIUM` per code, `COALESCE 0`.

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `coverage/Type` | system-generated, not a user dropdown | {TYPE} — 8 literals (CMP_SD…ULG_SD) | — | OK |
| `coverage/limit/Type` | same as Type | {TYPE} duplicate | — | OK |
| `coverage/limit/iValue` | int | empty for all 8 blocks | — | → G-37 |
| `coverage/Indicator` | boolean | hardcoded "1" for every block, regardless of ProtectionType | — | G-37 P2 |
| `coverage/sValue` | optional | empty for all 8 blocks | — | → G-37 |
| `coverage/Code` | system-generated, not a user dropdown | {CODE} literal per block | — | OK |
| `coverage/Description` | free text | {DESCRIPTION} fixed per block | — | OK |
| `coverage/Premium` | numeric | {EXP_PREM} COALESCE 0 | Output_SubCover_PER.EXPPREMIUM per code | OK |

## Gaps

- **G-37 (P2) — all 8 sub-coverages emitted unconditionally for every motor policy**, regardless of ProtectionType (a Third-Party-Only vehicle still emits PMCMP_SD Comprehensive Property with Indicator=1, and vice versa) and regardless of whether Choice of Repair / Car Hire / Unlimited Glass were taken (those takens are separate seq 18 fields). Sub-coverage `Indicator` should plausibly follow ProtectionType and the option flags. Confirm the intended matrix with the client (which codes are "on" for which protection type). Validate: `seq15_vq.sql`.
- The blocks are keyed per policy+term (`PM_03` distinct on policy/expiring), not per vehicle — on multi-vehicle policies confirm the sub-coverage set is policy-level by design in DCT (the seq 18 template embeds `{SUBCOV}` inside each vehicle's coverage node).

## Validation queries

See [`seq15_vq.sql`](vq/seq15_vq.sql).
