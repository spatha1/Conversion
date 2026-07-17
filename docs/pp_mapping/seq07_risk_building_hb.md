# Seq 7 — Home Buildings Coverage Block (`RISK_Building_HB`)

| | |
|---|---|
| **Script name** | RISK_Building_HB |
| **Source view** | `AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD` (shared with seq 13) |
| **Target** | `AGGNE.DEV.PER_BUILDING_TARGET` (ITR_TYPE = RISK_Building_HB) |
| **Consumed by** | `{RISK_BUILDING}` in seq 14 via `PER_RISK_BUILDING_FINAL` (with Indicator=0 stub fallback) |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents` (HB* columns) → `HB_01`/`HB_02` (step-2 staging) + `Output_Coverage_PER` (claims/premium) + `PER_BUILDING_TARGET` (seq 4/6 sub-rows) → view → template → target |

## Template (live PP_ConversionConfig) — key lines

```xml
<coverage>
  <Type>Building</Type>
  <Excess>
    <Amount/> <Imposed/> <Flood/> <Voluntary>{VOLUNTARYEXCESS}</Voluntary>
    <Earthquake/> <Standard/> <Glass/>              <!-- all others hardcoded empty -->
  </Excess>
  {SUBCOV}
  <SetExcessAmount>0</SetExcessAmount>
  <Indicator>1</Indicator>                          <!-- hardcoded — see G-22 -->
  <CoverageLevel>Per Occurrence</CoverageLevel>
  <LossOfRentLimit>0</LossOfRentLimit>
  <AccidentalLossOrDamage>{ACCIDENTALLOSSORDAMAGE}</AccidentalLossOrDamage>
  <UWAdjustmentIndicator>0</UWAdjustmentIndicator>  <!-- hardcoded — see seq 5 G-20 -->
  <GlassLimit>{HOMEBUILDINGSLIMIT}</GlassLimit>     <!-- see G-24 -->
  <Code>HB</Code>
  <LandlordProtections>{LANDLORDPROTECTIONS}</LandlordProtections>
  <MinimumRentalPeriod>{MINIMUMRENTALPERIOD}</MinimumRentalPeriod>
  <WeeklyRent>{WEEKLYRENT}</WeeklyRent>
  <ClassCode><APRA>HH</APRA><Business>HBC</Business></ClassCode>  <!-- hardcoded — see G-25 -->
  {HB_CLAUSE}
  <ClaimsIncurred>{HBCLMINCD}</ClaimsIncurred>
  <NumberOfClaims>{HBCLMCNT}</NumberOfClaims>
  <Premium>{EXPPREM}</Premium>
</coverage>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `coverage/Type` | — | hardcoded "Building" | — | BY DESIGN |
| `coverage/Excess/Amount, /Imposed, /Flood, /Earthquake, /Standard, /Glass *(6 tags)*` | excess amounts | all empty — not tokenized | HB_02 carries STANDARDEXCESS/IMPOSEDEXCESS/EARTHQUAKEEXCESS/FLOODEXCESS but view does not expose them | G-23 P2 |
| `coverage/Excess/Voluntary` | HB excess option list | {VOLUNTARYEXCESS} COALESCE 0 int | HB_02/HC_02 voluntary excess | VQ values |
| `coverage/{SUBCOV}` | — | LISTAGG of seq 4 rows | PER_BUILDING_TARGET (Building_SubCov) | see seq 4 |
| `coverage/SetExcessAmount` | — | hardcoded "0" | — | BY DESIGN |
| `coverage/Indicator` | boolean | hardcoded "1" — {HB_INDICATOR} exists in view, unused | view derives HB_INDICATOR from HB_01/HC_02 union but template never reads it | G-22 P1 |
| `coverage/CoverageLevel` | — | hardcoded "Per Occurrence" | — | BY DESIGN |
| `coverage/LossOfRentLimit` | — | hardcoded "0" | — | BY DESIGN |
| `coverage/Glass *(2nd tag)*` | — | empty, duplicate of Excess/Glass | — | EMPTY |
| `coverage/AccidentalLossOrDamage` | boolean | {ACCIDENTALLOSSORDAMAGE} — 'Taken'→1 ELSE 0 | HB_02/HC_02 raw Taken/Not Taken, single conversion in CTE_EXCESS | OK |
| `coverage/UWAdjustmentIndicator` | — | hardcoded "0" | see seq 5 — {UW} never wired here | → G-20 |
| `coverage/GlassLimit` | int | {HOMEBUILDINGSLIMIT} NUMBER(10,0) cast | HB_02.HOMEBUILDINGSLIMIT ← PER_HomeContents | G-24 P2 |
| `coverage/Code` | — | hardcoded "HB" | — | BY DESIGN |
| `coverage/LandlordProtections` | free text | {LANDLORDPROTECTIONS} COALESCE '' | HB_02.LANDLORDPROTECTIONS | OK |
| `coverage/MinimumRentalPeriod` | Morethan90Days / Lessthan90Days *(PP base 5625)* | {MINIMUMRENTALPERIOD} maps 2 captions, ELSE raw | HB_02.MINIMUMRENTALPERIOD | OK |
| `coverage/WeeklyRent` | int *(PP base 5638)* | {WEEKLYRENT} NUMBER(10,0) cast | HB_02.WEEKLYRENT | OK |
| `coverage/ClassCode/APRA, /Business` | — | hardcoded "HH" / "HBC" | — | G-25 P2 |
| `coverage/{HB_CLAUSE}` | — | LISTAGG of seq 6 rows | PER_BUILDING_TARGET (HB_CLAUSE) | see seq 6 |
| `coverage/ClaimsIncurred` | numeric | {HBCLMINCD} COALESCE 0 | Output_Coverage_PER.HBCLMINCD | OK |
| `coverage/NumberOfClaims` | numeric | {HBCLMCNT} COALESCE 0 | Output_Coverage_PER.HBCLMCNT | OK |
| `coverage/Premium` | numeric | {EXPPREM} = HMEXPPREM (total home premium) | Output_Coverage_PER.HMEXPPREM | G-26 P2 |


## Gaps

- **G-22 (P1) — `<Indicator>1</Indicator>` hardcoded while the view exposes `{HB_INDICATOR}`.** The shared source view emits one row per policy from an HC_02 ∪ HB_01 union — an **HC-only policy still gets a seq 7 row**, so DCT receives a Home Buildings coverage block with Indicator=1 and zero limits. The view's HB_INDICATOR column (1 only when the policy is in HB_01) exists precisely for this; the template was never updated to `{HB_INDICATOR}`. Config-only fix. Validate: `seq07_vq.sql`.
- **G-24 (P2) — `{HOMEBUILDINGSLIMIT}` lands in `<GlassLimit>`.** The building sum insured flows correctly via the seq 4 sub-coverage iValues; mapping the same number into GlassLimit (whose SME caption reads "Flood Limit") needs one confirmation — likely should be blank or a genuine glass limit.
- **G-25 (P2) — `ClassCode HH/HBC` hardcoded** (same in seq 13). Reference payloads show `FISR/BSP` elsewhere; confirm the correct APRA/Business class codes for PP home risks.
- **G-23 (P2) — Excess sub-tags hardcoded empty** (`Standard`, `Imposed`, `Flood`, `Earthquake`, `Glass`): `HB_02` carries STANDARDEXCESS/IMPOSEDEXCESS/EARTHQUAKEEXCESS/FLOODEXCESS but the view doesn't expose them and the template doesn't tokenize them — excess data is dropped.
- **G-26 (P2) — premium double-carry:** both seq 7 (`{EXPPREM}`) and seq 13 (`{HBEXPPREM}`) are fed from the same `HMEXPPREM` total — an HB+HC policy reports the full home premium on **both** coverage blocks. Confirm whether DCT sums them.

## Validation queries

See [`seq07_vq.sql`](vq/seq07_vq.sql).
