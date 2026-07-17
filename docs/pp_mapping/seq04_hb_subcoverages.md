# Seq 4 — Home Buildings Sub-Coverages (`coverage` blocks)

| | |
|---|---|
| **Script name** | Building_SubCov |
| **Source view** | `AGGNE.DEV.PER_BB_SUBCOVERAGES` |
| **Target** | `AGGNE.DEV.PER_BUILDING_TARGET` (ITR_TYPE = Building_SubCov) |
| **Consumed by** | `{SUBCOV}` in seq 7 (RISK_Building_HB) via `PER_HOME_BUILDING_PAYLOAD` LISTAGG |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents` (HB* columns) → `HB_02` (step-2 staging) + `Output_SubCover_PER` (premiums, `SP_PP_ADJ_EXP_PREM`) → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<coverage>
  <Type>{TYPE}</Type>
  <limit><Type>{TYPE}</Type><iValue>{IVALUE}</iValue></limit>
  <Indicator>1</Indicator>          <!-- hardcoded -->
  {SVALUE}                          <!-- column carries its own <sValue> tags -->
  <Code>{CODE}</Code>
  <Description>{DESCRIPTION}</Description>
  <Premium>{EXP_PREM}</Premium>
</coverage>
```

## Sub-coverage blocks emitted (one per policy per block, fixed list)

| Code | Type | Description | iValue source | sValue |
|---|---|---|---|---|
| HBBFL_SD | BFL_SD | Buildings Flood | — | `FLOODDAMAGE` → Taken/NotTaken |
| HBBLD_SD | BLD_SD | Buildings Standard | `HOMEBUILDINGSLIMIT` | — |
| HBBAD_SD | BAD_SD | Accidental Loss Or Damage | `ACCIDENTALLOSSORDAMAGELIMIT` | `ACCIDENTALLOSSORDAMAGE` → Taken/NotTaken |
| HBBLD_BF | BLD_BF | Bushfire | `HOMEBUILDINGSLIMIT` | — |
| HBBLD_CY | BLD_CY | Cyclone | `HOMEBUILDINGSLIMIT` | — |
| HBBLD_EQ | BLD_EQ | Earthquake | `HOMEBUILDINGSLIMIT` | — |
| HBBLD_ST | BLD_ST | Storm | `HOMEBUILDINGSLIMIT` | — |
| HBLLB_SD | LLB_SD | Buildings Landlords | `HOMEBUILDINGSLIMIT` | — |

Premium per block from `Output_SubCover_PER.EXPPREMIUM` matched on `SUB_COVERAGE` code; `COALESCE 0`.

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `coverage/Type` | system-generated, not a user dropdown | {TYPE} — 8 fixed literals, one per block (BFL_SD…LLB_SD) | HB_02 join defines which blocks apply | OK |
| `coverage/limit/Type` | same as Type | {TYPE} duplicate | — | OK |
| `coverage/limit/iValue` | optional, int sum insured | {IVALUE} — mostly HOMEBUILDINGSLIMIT, blank for Flood/ALD | HB_02.HOMEBUILDINGSLIMIT | OK |
| `coverage/Indicator` | boolean | hardcoded "1" for every block | — | G-18 P2 |
| `coverage/sValue` | optional — Taken/NotTaken (Flood, ALD blocks only) | {SVALUE} — FLOODDAMAGE / ACCIDENTALLOSSORDAMAGE mapped | HB_02.FLOODDAMAGE, ACCIDENTALLOSSORDAMAGE | OK |
| `coverage/Code` | system-generated, not a user dropdown | {CODE} literal per block | — | OK |
| `coverage/Description` | free text | {DESCRIPTION} fixed text per block | — | OK |
| `coverage/Premium` | numeric | {EXP_PREM} COALESCE 0 | Output_SubCover_PER.EXPPREMIUM per SUB_COVERAGE code | OK |

## Gaps

- **G-18 (P2) — every block emitted with `Indicator=1` for every HB policy**, regardless of whether the peril/option is actually taken (only Flood and ALD carry a Taken/NotTaken sValue; Landlords emits even for owner-occupied). Confirm with client whether DCT expects the full fixed block set with Indicator 1, or per-option indicators. Validate: `seq04_vq.sql`.
- Limits default to 0 via `COALESCE(HOMEBUILDINGSLIMIT, 0)` — a zero building limit on a live block is a data-quality signal, not a code bug. Counted in VQ.

## Validation queries

See [`seq04_vq.sql`](vq/seq04_vq.sql).
