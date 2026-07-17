# Seq 13 — Home Contents Coverage Block (`RISK_Building_HC`)

| | |
|---|---|
| **Script name** | RISK_Building_HC |
| **Source view** | `AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD` (shared with seq 7) |
| **Target** | `AGGNE.DEV.PER_HC_TARGET` (ITR_TYPE = RISK_Building_HC) |
| **Consumed by** | `{RISK_BC}` in seq 14 via `PER_RISK_BUILDING_FINAL` (with Indicator=0 stub fallback) |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents` (HC* columns) → `HC_02` (step-2 staging) + `Output_Coverage_PER` + `PER_HC_TARGET` (seq 8/9/10/11/12 sub-rows) → view → template → target |

## Template (live PP_ConversionConfig) — key lines

```xml
<coverage>
  <Type>ContentsAndStocks</Type>
  <Indicator>1</Indicator>                              <!-- hardcoded — see G-29 -->
  <FloodDamage>Taken</FloodDamage>                      <!-- hardcoded — see G-30 -->
  <Excess>… <Voluntary>{VOLUNTARYEXCESS}</Voluntary> …</Excess>
  <Code>HC</Code>
  <AccidentalLossOrDamage>{ACCIDENTALLOSSORDAMAGE}</AccidentalLossOrDamage>
  <HomeContentsLimits>1</HomeContentsLimits>            <!-- hardcoded — see G-31 -->
  <SpecifiedItemsPremises>{SPECIFIEDITEMSAWAY}</SpecifiedItemsPremises>
  <UnspecifiedItemsAwayPremises>{UNSPECIFIEDITEMSAWAY}</UnspecifiedItemsAwayPremises>
  <UnspecifiedItemsAwayPremisesLimit>{UNSPECIFIEDITEMSAWAYLIMIT}</UnspecifiedItemsAwayPremisesLimit>
  <HomeContentsTotal>9100</HomeContentsTotal>           <!-- hardcoded — see G-32 -->
  <SpecifiedContentsTotal>622221</SpecifiedContentsTotal><!-- hardcoded — see G-32 -->
  {HC_EXCEED_VALUES} {HC_SPECIFIED_CONTENTS} {SUBCOV}
  <ClassCode><APRA>HH</APRA><Business>HBC</Business></ClassCode>  <!-- shares G-25 -->
  <ClaimsIncurred>{HCCLMINCD}</ClaimsIncurred>
  <NumberOfClaims>{HCCLMCNT}</NumberOfClaims>
  <Premium>{HBEXPPREM}</Premium>
  {clauses} {UW}                                         <!-- {clauses} — see G-28 -->
</coverage>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `coverage/Type` | — | hardcoded "ContentsAndStocks" | — | BY DESIGN |
| `coverage/Indicator` | boolean | hardcoded "1" — {HC_INDICATOR} exists, unused | view derives HC_INDICATOR from HC_02/HB_01 union | G-29 P1 |
| `coverage/CoverageLevel` | — | hardcoded "Per Occurrence" | — | BY DESIGN |
| `coverage/FloodDamage` | Taken/NotTaken (actual) | hardcoded "Taken" | HC_02.FLOODDAMAGE ignored (already drives seq 10 sValue) | G-30 P2 |
| `coverage/Excess/Flood, /Earthquake, /Imposed, /Standard, /Hail *(5 tags)*` | excess amounts | all empty — not tokenized | no HC excess columns exposed | NEW P2 |
| `coverage/Excess/Voluntary` | HC excess option list | {VOLUNTARYEXCESS} COALESCE 0 | HC_02 | VQ values |
| `coverage/StockLimitExcludingVehiclesWatercraft, /EmployeeToolsofTradeLimit, /PersonalEffectsLimit, /MotorFuelsLimit, /VehiclesInStockLimit, /CustomersVehiclesLimit, /WatercraftInStockUnder8mLimit, /CustomersWatercraftUnder8mLimit, /HailDamagetoVehiclesorWatercraftsInStockLimit *(9 tags)*` | business/commercial stock limits | all empty — no PP source | business-only fields inherited from a shared/commercial schema — likely inapplicable to personal home contents | NEW — confirm inapplicable |
| `coverage/Code` | — | hardcoded "HC" | — | BY DESIGN |
| `coverage/AccidentalLossOrDamage` | boolean | {ACCIDENTALLOSSORDAMAGE} — 'Taken'→1 | HC_02 | OK |
| `coverage/HomeContentsLimits` | optional — Yes/No *(PP base 6602)* | hardcoded "1" — invalid value | view already exposes {ANYITEMSEXCEEDVALUE} Yes/No, unused here | G-31 P1 |
| `coverage/SpecifiedItemsPremises` | Taken/Not Taken *PL101 #104* | {SPECIFIEDITEMSAWAY} mapped | HC_02.SPECIFIEDITEMSAWAY | OK |
| `coverage/UnspecifiedItemsAwayPremises` | Taken/Not Taken *PL101 #113* | {UNSPECIFIEDITEMSAWAY} mapped | HC_02.UNSPECIFIEDITEMSAWAY | OK |
| `coverage/UnspecifiedItemsAwayPremisesLimit` | conditional required — 2 codes *(PP base 6668)* | {UNSPECIFIEDITEMSAWAYLIMIT} 2 $-captions → codes; ELSE '' | HC_02.UNSPECIFIEDITEMSAWAYLIMIT | OK |
| `coverage/HomeContentsTotal` | readOnly output field | hardcoded "9100" | — | G-32 P2 |
| `coverage/SpecifiedContentsTotal` | readOnly output field | hardcoded "622221" | — | G-32 P2 |
| `coverage/{HC_EXCEED_VALUES}` | — | LISTAGG of seq 8 rows | PER_HC_TARGET (HC_exceed_values) | see seq 8 |
| `coverage/{HC_SPECIFIED_CONTENTS}` | — | LISTAGG of seq 9 rows | PER_HC_TARGET (HC_Specified_Contents) | see seq 9 |
| `coverage/{SUBCOV}` | — | LISTAGG of seq 10 rows | PER_HC_TARGET (Building_SubCov) | see seq 10 |
| `coverage/ClassCode/APRA, /Business` | — | hardcoded "HH" / "HBC" | — | G-25 P2 |
| `coverage/ClaimsIncurred` | numeric | {HCCLMINCD} COALESCE 0 | Output_Coverage_PER.HCCLMINCD | OK |
| `coverage/NumberOfClaims` | numeric | {HCCLMCNT} COALESCE 0 | Output_Coverage_PER.HCCLMCNT | OK |
| `coverage/Premium` | numeric | {HBEXPPREM} = HMEXPPREM (total home premium) | Output_Coverage_PER.HMEXPPREM | G-26 P2 |
| `coverage/{clauses}` | — | unresolved — view column is HC_CLAUSE, not "clauses" | PER_HC_TARGET (LOC_HC_CLAUSE) rows exist but are orphaned | G-28 P1 |
| `coverage/{UW}` | — | LISTAGG of seq 11 rows | PER_HC_TARGET (BUILDING_UW) | OK |


## Gaps

- **G-28 (P1) — `{clauses}` is an unresolved token.** The token substitution engine resolves tokens from view column names; the view's column is `HC_CLAUSE`, so `{clauses}` never resolves — HC clauses are absent from every converted policy and the literal `{clauses}` text can leak into the payload. Config-only fix: rename the token to `{HC_CLAUSE}` in the seq 13 template. Validate: `seq13_vq.sql`.
- **G-29 (P1) — `<Indicator>1</Indicator>` hardcoded while the view exposes `{HC_INDICATOR}`.** An HB-only policy still gets an HC block with Indicator=1 (mirror of seq 7's G-22). Config-only fix.
- **G-31 (P1) — `<HomeContentsLimits>1</HomeContentsLimits>` hardcoded and invalid.** DCT options are `Yes`/`No` *(PP base 6602 — "any individual items exceeding the PDS limits?")*; `1` is not an option value. The view already exposes `{ANYITEMSEXCEEDVALUE}` (Yes/No, defaulted No) for exactly this tag. Config-only fix.
- **G-30 (P2) — `<FloodDamage>Taken</FloodDamage>` hardcoded.** `HC_02.FLOODDAMAGE` carries the real Taken/NotTaken (it already drives the seq 10 flood sub-coverage sValue) — policies without flood cover are told they have it at coverage level.
- **G-32 (P2) — `HomeContentsTotal=9100` / `SpecifiedContentsTotal=622221` hardcoded sample values.** Both are readOnly *output* fields in DCT (recalculated from the items), so the fabricated numbers are likely overwritten — but they should be blank or derived, not test residue.
- **Shares G-25 (P2)** — ClassCode HH/HBC hardcoded; **shares G-26 (P2)** — total home premium carried on both HB and HC blocks.

## Validation queries

See [`seq13_vq.sql`](vq/seq13_vq.sql).
