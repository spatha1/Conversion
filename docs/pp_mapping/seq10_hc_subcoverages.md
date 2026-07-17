# Seq 10 — Home Contents Sub-Coverages (`coverage` blocks)

| | |
|---|---|
| **Script name** | Building_SubCov (HC) |
| **Source view** | `AGGNE.DEV.PER_HC_SUBCOVERAGES` |
| **Target** | `AGGNE.DEV.PER_HC_TARGET` (ITR_TYPE = Building_SubCov) |
| **Consumed by** | `{SUBCOV}` in seq 13 via `PER_HOME_BUILDING_PAYLOAD` LISTAGG |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents` (HC* columns) → `HC_02` (step-2 staging) + `VW_OUTPUT_SUBCOVERAGE_BSP` (premiums) → view → template → target |

## Template — identical shape to seq 4 (`<coverage>` with hardcoded `Indicator=1`).

## Sub-coverage blocks emitted (fixed list)

| Code | Type | Description | iValue source | sValue |
|---|---|---|---|---|
| HCCNT_SD | CNT_SD | Standard | `HOMECONTENTSLIMIT_NEW` | — |
| HCCAD_SD | CAD_SD | Accidental Damage | `ACCIDENTALLOSSORDAMAGELIMIT` | `ACCIDENTALLOSSORDAMAGE` → Taken/NotTaken |
| HCSPE_SD | SPE_SD | Specified Items | — | — |
| HCCNT_BF | CNT_BF | Bushfire | `HOMECONTENTSLIMIT_NEW` | — |
| HCCNT_CY | CNT_CY | Cyclone | `HOMECONTENTSLIMIT_NEW` | — |
| HCCNT_EQ | CNT_EQ | Earthquake | `HOMECONTENTSLIMIT_NEW` | — |
| HCCNT_ST | CNT_ST | Storm | `HOMECONTENTSLIMIT_NEW` | — |
| HCCFL_SD | CFL_SD | Flood | `HCHOMEHOBBYFARMFLOODPROTECTION` | `FLOODDAMAGE` → Taken/NotTaken |
| HCCLI_SD | CLI_SD | Contents Liability | `HOMECONTENTSLIMIT_NEW` | — |
| ~~HCPOR_SD~~ | POR_SD | Contents Portable Items | **commented out** — block disabled in the view | |

Design note (from the view header, PL101 cross-check): SpecifiedItemsPremises / UnspecifiedItemsAwayPremises are **direct fields** on the seq 13 template, *not* sub-coverage blocks — adding them here would produce spurious coverage nodes.

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `coverage/Type` | system-generated, not a user dropdown | {TYPE} — 9 literals incl. disabled HCPOR_SD | — | OK |
| `coverage/limit/Type` | same as Type | {TYPE} duplicate | — | OK |
| `coverage/limit/iValue` | int | {IVALUE} — mostly HOMECONTENTSLIMIT_NEW; Flood block uses HCHOMEHOBBYFARMFLOODPROTECTION | HC_02 | CONFIRM flood proxy |
| `coverage/Indicator` | boolean | hardcoded "1" for every block | — | G-18 P2 |
| `coverage/sValue` | optional — Taken/NotTaken (ALD, Flood blocks only) | {SVALUE} mapped | HC_02.ACCIDENTALLOSSORDAMAGE, FLOODDAMAGE | OK |
| `coverage/Code` | system-generated, not a user dropdown | {CODE} literal — HCPOR_SD block commented out | — | Portable Items disabled — confirm |
| `coverage/Description` | free text | {DESCRIPTION} fixed per block | — | OK |
| `coverage/Premium` | numeric | {EXP_PREM} COALESCE 0 | VW_OUTPUT_SUBCOVERAGE_BSP.EXPPREMIUM | OK |

## Gaps

- **Shares G-18 (P2)** — all blocks emitted unconditionally with `Indicator=1` per HC policy.
- **CONFIRM — Portable Items (HCPOR_SD) disabled.** The block is commented out in the view. If any converted policy has portable-items cover in Pure, it is silently dropped. One yes/no from the business closes this. Validate: `seq10_vq.sql`.
- Flood limit uses `HCHOMEHOBBYFARMFLOODPROTECTION` (hobby-farm flood field) as the iValue — naming suggests a proxy; confirm the source column is right for standard home contents flood.

## Validation queries

See [`seq10_vq.sql`](vq/seq10_vq.sql).
