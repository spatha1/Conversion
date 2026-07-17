# PP Conversion — Field Mapping & Gap Analysis (All 18 Sequences)

**Scope:** every field in every XML template of the PP conversion pipeline, traced end to end —
DCT target path → conversion token → view logic → staging rules → raw Pure (PRD_T5) source —
and cross-checked against the Duck Creek manuscript rules (the PL101 source).
**Gaps are established from code and rules only** (current snapshot); every gap carries a
read-only validation query (`vq/seqNN_vq.sql`) to quantify it on demand.

**Client-facing HTML (all sequences):** [`PP_FieldMapping_AllSeqs.html`](PP_FieldMapping_AllSeqs.html) —
single page with the combined gap register and one section per sequence.
Seq 18 per-field deep-dive: [`PP_FieldMapping_Seq18_Motor.html`](PP_FieldMapping_Seq18_Motor.html).

> Template note: this structure is LOB-agnostic. The BP equivalent uses `ConversionConfig`
> (not `PP_ConversionConfig`), the BP views, and the `CarrierBusinessPackage` manuscripts —
> everything else in the method carries over unchanged.

---

## Pipeline lineage

```
PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.<pure tables>
      │  SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD (+ SP_PP_ADJ_EXP_PREM for premiums/UW)
      ▼
Staging: Sample_PER · HB_01/HB_02 · HC_02 · PM_01→PM_02→PM_03 · Locationdetails_PER
         CLAIMHISTORY · PER_Competitor_Information · CLAUSES · Output_Coverage/SubCover/UWAdjust_PER
      │
      ▼
Source views (one per sequence, below) → PP_ConversionConfig templates (token substitution)
      │
      ▼
Target tables (PER_*_TARGET) → PER_CONVERSION_FINAL_LOAD → PER_CONVERSION_FINAL_XML
      ▼
PER_POLICY_MIGRATION_DCT.REQUEST_XML → DCT
```

## Considered sources

- **PL101 / DCT manuscripts** — `Carrier_PersonalProtectionBase_1_0_0_0.xml`, `Carrier_CoverageLibrary_Data_1_0_0_0.xml`, `Carrier_Package_Data_CW_1_0_0_0.xml` (dropdown values, mandatory conditions, defaults, format masks)
- **PL101 field reference** — `docs/PL101_FieldReference.html`
- **ETL config (live)** — `PP_ConversionConfig` seq 1–18 templates, fetched 2026-07-08
- **Repo — views** — `sql/snowflake/1_conversion/PP/views/` (+3 views fetched live from Snowflake: `BUILDING_UW`, `HB_CLAUSE`, `COM_CLAUSE`)
- **Repo — Pure-to-Write SP** — `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql` (incl. SAS-inherited business rules)
- **Pure source (PRD_T5)** — `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.*` + `RISK.SCHEDULE_CLAUSES_TEMPLATE`
- **DCT extract map** — `Carrier_PersonalProtection_Risk_ExtractMap.xml`
- **Not covered** — original SAS programs (`SAS/` folder); line-by-line SAS-vs-SP diff available as follow-up

## Sequence index

| Seq | Screen / block | Detail | Validation SQL | Gaps |
|---|---|---|---|---|
| 1 | Claim history (losshistory) | [seq01](seq01_claim_history.md) | [vq](vq/seq01_vq.sql) | G-15, **G-16** |
| 2 | Prior insurance | [seq02](seq02_prior_insurance.md) | [vq](vq/seq02_vq.sql) | G-17 |
| 3 | Account location | [seq03](seq03_account_location.md) | [vq](vq/seq03_vq.sql) | confirm-only |
| 4 | HB sub-coverages | [seq04](seq04_hb_subcoverages.md) | [vq](vq/seq04_vq.sql) | G-18 |
| 5 | HB UW adjustments | [seq05](seq05_hb_uw_adjustments.md) | [vq](vq/seq05_vq.sql) | **G-20**, G-19 |
| 6 | HB clauses | [seq06](seq06_hb_clauses.md) | [vq](vq/seq06_vq.sql) | G-21 |
| 7 | HB coverage block | [seq07](seq07_risk_building_hb.md) | [vq](vq/seq07_vq.sql) | **G-22**, G-23, G-24, G-25, G-26 |
| 8 | HC items exceeding | [seq08](seq08_hc_items_exceeding.md) | [vq](vq/seq08_vq.sql) | (G-21) |
| 9 | HC specified contents | [seq09](seq09_hc_specified_contents.md) | [vq](vq/seq09_vq.sql) | G-27 |
| 10 | HC sub-coverages | [seq10](seq10_hc_subcoverages.md) | [vq](vq/seq10_vq.sql) | G-18, confirm |
| 11 | HC UW adjustments | [seq11](seq11_hc_uw_adjustments.md) | [vq](vq/seq11_vq.sql) | G-19 |
| 12 | HC clauses | [seq12](seq12_hc_clauses.md) | [vq](vq/seq12_vq.sql) | (G-28), G-21 |
| 13 | HC coverage block | [seq13](seq13_risk_building_hc.md) | [vq](vq/seq13_vq.sql) | **G-28**, **G-29**, **G-31**, G-30, G-32 |
| 14 | Outer building risk | [seq14](seq14_risk_building.md) | [vq](vq/seq14_vq.sql) | **G-33**, G-34, G-35, G-36 |
| 15 | Motor sub-coverages | [seq15](seq15_motor_subcoverages.md) | [vq](vq/seq15_vq.sql) | G-37 |
| 16 | Motor UW adjustments | [seq16](seq16_motor_uw_adjustments.md) | [vq](vq/seq16_vq.sql) | G-19 |
| 17 | Motor clauses | [seq17](seq17_motor_clauses.md) | [vq](vq/seq17_vq.sql) | **G-38**, G-39 |
| 18 | Motor risk block | [seq18](seq18_risk_motor.md) · [interactive HTML](PP_FieldMapping_Seq18_Motor.html) | [vq](vq/seq18_vq.sql) | **G-01…G-07**, G-08…G-13 |

**Bold** = P1.

---

## Combined gap register

### P1 — invalid values sent, silent data loss, or wrong data asserted (15)

| ID | Seq | Field | Gap (from code) |
|---|---|---|---|
| G-01 | 18 | State | Template hardcodes `NSW` for every vehicle; real state derived in staging but never tokenized |
| G-02 | 18 | Year/Make/Model | View filter silently drops vehicles with Year=0 / blank Make/Model — no error, no report |
| G-03 | 18 | BodyType | 34 RedBook names emitted vs 17 DCT codes constrained by VehicleType; unmapped → blank on a required field |
| G-04 | 18 | DriveDescription | Captions sent; DCT values are code-form (`Frontwheeldrive` etc.) |
| G-05 | 18 | NumberOfCylinders | `0` sent; DCT dropdown is 1–16 |
| G-06 | 18 | InductionType | "Turbo and supercharged" unmapped → blanked on a required field |
| G-07 | 18 | VoluntaryExcess (motor) | Banded to 2000/5000; PP options stop at 1500 |
| G-16 | 1 | Cause | Raw source text sent; DCT values are code-form (`AtFault`, `NotAtFault`…) — required field |
| G-20 | 5 | HB UW adjustments | View reads **BSP (Business) tables** for PP, and seq 7 template has no `{UW}` token — output both wrong-sourced and never consumed |
| G-22 | 7 | HB Indicator | `<Indicator>1</Indicator>` hardcoded; HC-only policies get a Home Buildings block with Indicator=1 (view's `{HB_INDICATOR}` exists, unused) |
| G-28 | 13 | HC clauses | Live template carries `{clauses}` but the view column is `HC_CLAUSE` — token never resolves; HC clauses absent from every policy |
| G-29 | 13 | HC Indicator | `<Indicator>1</Indicator>` hardcoded; HB-only policies get an HC block with Indicator=1 (`{HC_INDICATOR}` exists, unused) |
| G-31 | 13 | HomeContentsLimits | Hardcoded `1`; DCT options are `Yes`/`No` — invalid value; view's `{ANYITEMSEXCEEDVALUE}` ready to use |
| G-33 | 14 | SICCode | `General Mechanical Workshop` hardcoded on every personal home risk |
| G-38 | 17 | Motor clause codes | `UPPER()` breaks mixed-case PM* codes AND legacy CM_*/FV_* codes are disabled in PP — no valid clause can be emitted |

### P2 — wrong/dropped data needing a business rule or confirmation (17)

| ID | Seq | Field | Gap |
|---|---|---|---|
| G-08 | 18 | RegistrationNumber | No cleanup vs DCT format mask (A–Z, 0–9) |
| G-09 | 18 | ImportType | SP literal `'N/A '` trailing space; blank when source Override≠1 |
| G-10 | 18 | EngineSize / GVM | RedBook-override-sourced (structurally sparse) yet required because Override=1 |
| G-11 | 18 | AgeOfYoungestRegularDriver | No default for a required field after <16 nulling |
| G-12 | 18 | VehicleType | ELSE raw passthrough; blank→PassengerVehicle default pending sign-off |
| G-13 | 18 | RedbookCode | Carried in the view, never emitted (empty hardcoded tag) |
| G-15 | 1 | DateOfClaim | Unparseable dates silently emit an empty required tag |
| G-17 | 2 | PriorCarrier | Manuscript value `MotorTradeDirect` (no spaces) vs view keeping spaces — conflicting evidence; off-list insurers pass unvalidated |
| G-18 | 4/10 | HB/HC sub-coverages | All blocks emitted unconditionally with Indicator=1 (incl. Landlords for owner-occupied) |
| G-19 | 5/11/16 | UW adjustments | `AdjustmentSelection` hardcoded `1` ($) and `Recurring` hardcoded `1` — percent adjustments would apply as dollars |
| G-21 | 6/8/9/12/17 | Clause/item free text | Not XML-escaped — `&`/`<` in source text breaks the policy payload |
| G-23 | 7 | HB excesses | Standard/Imposed/Earthquake/Flood excess exist in staging, dropped (not exposed/tokenized) |
| G-24 | 7 | GlassLimit | `{HOMEBUILDINGSLIMIT}` mapped into `<GlassLimit>` — confirm intent |
| G-25 | 7/13 | ClassCode | `HH`/`HBC` hardcoded — reference payloads show other codes |
| G-26 | 7/13 | Premium | Same `HMEXPPREM` total carried on both HB and HC blocks — possible double-count |
| G-27 | 9 | Specified contents | No empty-item filter (the seq 8 fix pattern not applied) — empty nodes mark the section selected |
| G-30/32 | 13 | FloodDamage / totals | `FloodDamage=Taken` hardcoded; `HomeContentsTotal=9100` / `SpecifiedContentsTotal=622221` are test residue |
| G-34/35/36 | 14 | Building risk | Excess tags empty; fabricated UW answers (ExternalDoors=1 etc.); unmapped construction/security values pass raw |
| G-37 | 15 | Motor sub-coverages | All 8 blocks emitted regardless of ProtectionType / options taken |

### P3 — cosmetic (1)

| ID | Seq | Field | Gap |
|---|---|---|---|
| G-39 | 17 | Clause descriptions | Forced ALL CAPS by `UPPER()` — client-visible on the quote |

---

## Cross-cutting patterns (worth fixing as classes, not one-offs)

1. **Caption vs code** — DCT dropdown *values* are code-form; captions are display-only. Hit: Cause (G-16), DriveDescription (G-04), BodyType (G-03), PriorCarrier (G-17), clause codes (G-38). One systematic pass over every dropdown mapping closes the class.
2. **Hardcoded indicators/answers in templates** — `Indicator=1` (G-18, G-22, G-29, G-37), `HomeContentsLimits=1` (G-31), fabricated UW answers (G-35), `FloodDamage=Taken` (G-30). The views often already expose the correct column — these are mostly config-only fixes.
3. **Unresolved / missing tokens** — `{clauses}` (G-28), missing `{UW}`+`{STATE}`+`{REDBOOKCODE}` tokens (G-20, G-01, G-13). Token-to-column reconciliation between each template and its source view catches all of these mechanically.
4. **Unescaped free text** (G-21) — one escaping helper applied in every clause/description view.
5. **Forced overrides make fields mandatory** — `VehicleInfoOverride=1` (vehicles) and `AddressOverride=1` (locations) are recorded client decisions that unblock screens, but the vehicle one drags all RedBook detail fields into required-status — the root pressure behind G-03/05/06/10.

## How to run the validation pack

All queries are read-only against `AGGNE.DEV`. Run after a fresh staging build
(`CALL AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD();` + seq re-run) so counts reflect current SP logic.
Each `vq/seqNN_vq.sql` maps 1:1 to the gaps in its sequence sheet.

## Suggested client conversation order

1. **Config-only P1s** (fast wins, no code): G-28 `{clauses}` rename, G-31 HomeContentsLimits token, G-22/G-29 indicator tokens, G-01 State token, G-33 SICCode.
2. **Mapping-decision P1s**: G-03 BodyType table, G-16 Cause table, G-38 clause code strategy, G-07 excess re-banding.
3. **Business-rule P2s**: G-19 adjustment type, G-18/G-37 sub-coverage indicator matrix, G-26 premium split, G-10/G-11 defaults for required-but-sparse fields.
4. **Hygiene batch**: G-21 escaping, G-27 filter, G-09 trim, G-08 rego cleanup, G-32 test residue.
