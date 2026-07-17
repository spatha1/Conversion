# SEQ 21-23 — Stock Vehicles (SV) Coverage

| Seq | Name | Source view |
|---|---|---|
| 21 | BP_LINE_SV_UW | `LINE_SV_UW` |
| 22 | BP_LINE_SV_CLAUSE | `LINE_SV_CLAUSE` (by design, clause-only) |
| 23 | BP_LINE_SV | `LINE_SV_PAYLOAD` |

**Client tickets:** ATP-10842 — *"SV 'Is Windscreen Glass Excess Taken' is incorrect in Clarity"*
(High, In Progress, assignee Raju Kallepelli).

---

## G-BP-24 — CONFIRMED, real impact quantified — LIA_SD/STD_SD/TPO_SD hardcoded Taken

**Live config (SEQ 23, pulled 2026-07-11):** `LIA_SD` (Comprehensive Liability), `STD_SD`
(Comprehensive Property) and `TPO_SD` (Third Party Only) all hardcode `<Indicator>1</Indicator>`
unconditionally. These are **mutually exclusive** protection-type selections, not independent
optional add-ons — a policy has either comprehensive cover or third-party-only cover, never both.

**Manuscript** (`Carrier_CoverageLibrary_Data_1_0_0_0.xml`) confirms each should be conditional:

| Field | Manuscript rule |
|---|---|
| `LIA_SD/Indicator` (`ComprehensiveLiabilityIndicator`) | `= (LossOrDamageLimit > 0)` |
| `STD_SD/Indicator` (`StandardPerilIndicator`) | `= (ComprehensiveProperty > 0)`, where `ComprehensiveProperty = LossOrDamageLimit` |
| `TPO_SD/Indicator` (`ThirdPartyOnlyIndicator`, comment references **ATP-9792**) | `= (ProtectionType == "ThirdPartyOnly")` |

`LINE_SV_PAYLOAD` **already computes** `COM_INDICATOR` (`PROTECTIONTYPE='FullComprehensive'`) and
`TPO_INDICATOR` (`PROTECTIONTYPE='ThirdPartyOnly'`) — SEQ 23 just never references either token. Live
data confirms both are exact, 100%-reliable proxies for the manuscript's `LossOrDamageLimit`-based
rule:

| PROTECTIONTYPE | LOSSDAMAGELIMIT | Count |
|---|---|---|
| FullComprehensive | > 0 (every row) | 676 |
| ThirdPartyOnly | = 0 (every row) | 19 |

**Confirmed bug: 19 of 695 SV records (2.7%) — every "Third Party Only" policy — incorrectly show
both Comprehensive Liability and Comprehensive Property as "Taken"** (should be 0/NotTaken), while
**0 of 695 records ever show Third Party Only as Taken**, even though 19 of them should. This sends
contradictory, mutually-exclusive coverage flags simultaneously for the affected 19 policies.

**Fix:** `docs/bp_mapping/fixes/G-BP-24_fix.sql` — **config-only**, no view change needed (the tokens
already exist). Rewires `LIA_SD`/`STD_SD` to `{COM_INDICATOR}` and `TPO_SD` to `{TPO_INDICATOR}`.
**Applied live 2026-07-11, verified**: `LIA_SD` and `STD_SD` now reference `{COM_INDICATOR}`, `TPO_SD`
references `{TPO_INDICATOR}`, and `STD_ST`'s hardcode (the unrelated G-BP-71 gap) was correctly left
untouched.

---

## G-BP-71 (new) — STD_ST "Storm" hardcode, no Pure source exists at all

While confirming G-BP-24's scope, found a 4th hardcoded sub-coverage: `STD_ST` ("Storm"),
`<Indicator>1</Indicator>`, unconditional for all 695 rows. Manuscript ties it to a distinct field:

```
StockVehiclesInput.StormIndicator (STD_ST/Indicator) = (LegalLiabilityStorm > 0)
```

Searched the SP and the client's original SAS for any Stock-Vehicles-specific storm/legal-liability
field — **none exists**. The only `Storm` references anywhere in
`DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql` are for **Building** coverage (`BBSTD_ST`/`BCSTD_ST`/`BIGRP_ST`
perils), an entirely separate coverage line. There is no Pure column, staging column, or SAS mapping
for a Stock-Vehicles "Legal Liability Storm" limit anywhere in this codebase.

This isn't a wiring gap like G-BP-24 — there's no source data to wire in. Two possibilities: (a) Pure
genuinely has no such field for Stock Vehicles and the hardcoded 1 is meaningless-but-harmless
(Storm cover may just always be bundled with Comprehensive cover, making it correct-by-design like
the earlier line-level indicators), or (b) Pure does capture this and the SP/SAS never built the
extraction for it (a real gap). Not resolvable without a client/business conversation — no fix
scripted. Not part of `G-BP-24_fix.sql`.

---

## G-BP-62 (ATP-10842) — REOPENED, real bug found via ticket screenshot

Ticket: *"SV 'Is Windscreen Glass Excess Taken' is incorrect in Clarity."* First pass (below, kept for
the record) traced `Indicator`/`sValue` and found them internally consistent — that part is correct.
**The ticket title is misleading.** A screenshot of the actual ticket (shared 2026-07-11) shows the
real complaint: `<limit><Type>GLS_SD</Type><iValue/></limit>` is genuinely blank, sitting right next
to a correct `<sValue>Taken</sValue>` and `<Indicator>1</Indicator>`.

**Root cause**: manuscript (`Carrier_CoverageLibrary_Data_1_0_0_0.xml`) defines this limit as a
derived value, not something to leave blank:

```
StockVehiclesInput.LegalLiabilityLimitWindscreenGlass (GLS_SD/limit/iValue)
  value = StockVehiclesInput.WindscreenAndWindowGlassExcess (Excess/WindscreenAndWindowGlass)

StockVehiclesInput.WindscreenAndWindowGlassExcess
  value = StockVehiclesPrivate.WindscreenAndWindowGlassExcessConditional:
    IF (Indicator=False) OR (GLS_SD.Indicator=False) THEN 0
    ELSE IF LossOrDamageLimit >= 100001 THEN <MaxLength.MinimumOneThousand>
    ELSE <MaxLength.MaximumFiveHundred>
```

Both nodes are marked `readOnly="True"` — which is why the first pass assumed DC would compute this
itself and treated the blank as correct-by-design. But G-BP-18's `DFW_SD` sValue (also readOnly,
also formula-driven) proved that assumption wrong: a blank/incorrect value sent at import can persist
exactly as sent, not get silently recalculated by DC. Same shape here — all 3 driving inputs
(`STOCKVEHICLES_IND`, `UVGLASSREMOVAL_IND`, `LOSSDAMAGELIMIT`) are already sent correctly elsewhere
in this same template; the gap is purely a missing derivation.

**Unverified**: `MaxLength.MinimumOneThousand`/`MaxLength.MaximumFiveHundred` aren't defined in any
manuscript file available to us. Their values (1000 and 500) are inferred from this manuscript's
otherwise-literal naming convention (e.g. `MaxLength.MinimumZero` = 0 elsewhere) — not confirmed
against DC's actual constant table. Flagged explicitly in the fix script; verify against a real DCT
quote before treating as final.

**Fix:** `docs/bp_mapping/fixes/G-BP-62_fix.sql` — view+config. Adds `GLSLIMIT` to `LINE_SV_PAYLOAD`
(the manuscript's formula, computed from data already in the view), wires it into both
`GLS_SD/limit/iValue` and the top-level `Excess/WindscreenAndWindowGlass` (sending both since the
manuscript chains one from the other and it's unclear which one DC actually persists from). Confirmed
Pure has no native numeric source for this field at all — `UVGlassExcessRemoval` is a boolean
Taken/NotTaken flag only, so the derived formula is the only path to a value, not a shortcut around
real data.

**BLOCKED on client clarification 2026-07-11** — the formula's two dollar constants
(`MaxLength.MinimumOneThousand`/`MaxLength.MaximumFiveHundred`, inferred as $1,000/$500 from
manuscript naming convention, not confirmed against DC's actual constant table) need client/DC
sign-off before this gets applied. Script is drafted and ready, held pending confirmation — do not
deploy with guessed dollar figures on a client-visible field.

### First-pass trace (Indicator/sValue only — still valid, just answered the wrong question)

- **Config**: both `<sValue>{EXCESSWAIVERFORWINDSCREEN}</sValue>` and `<Indicator>{UVGLASSREMOVAL_IND}</Indicator>`
  are already dynamic tokens — not a hardcode gap.
- **View**: `UVGLASSREMOVAL_IND` and `EXCESSWAIVERFORWINDSCREEN` are both sourced from the same raw
  staging column (`UVGLASSEXCESSREMOVAL`), just via two different CASE expressions. Live data
  confirms they're 100% internally consistent: `0`/`'NotTaken'` → 408 rows, `1`/`'Taken'` → 287 rows,
  no mismatches.
- **SP vs. SAS**: `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql:5855-5860`'s `UVGlassExcessRemoval`
  → `ExcessWaiverForWindscreen` CASE is byte-for-byte identical to the client's original SAS
  (`CustomerVehicles_StockVehicle_conversionscriptCapricorn.txt`) — no drift, no mapping error.
- **Manuscript**: `ExcessWaiverForWindscreenAndWindowGlassIndicator` (`GLS_SD/Indicator`) `= (sValue == "Taken")`
  — our independently-computed `Indicator` and `sValue` are already consistent with each other and
  with this rule by construction.

---

## G-BP-70 — applies to SEQ 21

`LINE_SV_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`, hardcoded
`AdjustmentSelection='1'` regardless of whether Pure recorded a percent or dollar adjustment). Same
open, business-decision-pending finding as documented in `seq05-08_general_property.md` — no new
analysis needed here, just confirming SEQ 21 is in scope.

## Checked clean

- **SEQ 22** (`BP_LINE_SV_CLAUSE`) — by design, clause-only pass-through, no gap.
