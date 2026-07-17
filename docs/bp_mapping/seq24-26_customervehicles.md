# SEQ 24-26 — Customer Vehicles (CV) Coverage

| Seq | Name | Source view |
|---|---|---|
| 24 | BP_LINE_CV_UW | `LINE_CV_UW` |
| 25 | BP_LINE_CV_CLAUSE | `LINE_CV_CLAUSE` (by design, clause-only) |
| 26 | BP_LINE_CV | `LINE_CV_PAYLOAD` |

**Client tickets:** ATP-10904 — *"Renewal - Policy Conversion - S.14 Customer vehicles - Hail and
Malicious Damage Excess not populating"* (High, In Progress, assignee Raju Kallepelli).

---

## G-BP-25 — DOWNGRADED, checked correct-by-design — CV line-level Indicator=1

Previously flagged as 1 hardcoded `<Indicator>1</Indicator>`, with a scripted fix note to reuse
`CUSTOMERVEHICLES_IND`. Live config check found `STD_SD`'s `<Indicator>` **already correctly wired**
to `{CUSTOMERVEHICLES_IND}` — only the line-level `<Indicator>1</Indicator>` is the literal hardcode,
same shape as PPL/PF/GT/LE/SV's line-level indicators.

- Live check: `Line_CV_Coverage.CUSTOMERVEHICLES_IND` is **`1` for all 8,833 rows, no exceptions** —
  same pattern as every other line-level flag checked this session: this staging table only contains
  policies that already have a CV line, so the flag is trivially always true.

Correct-by-design for every record that can reach this view. No fix needed. Closing.

---

## G-BP-65 (ATP-10904) — RECLASSIFIED, no Pure source exists anywhere

Ticket: *"Hail and Malicious Damage Excess not populating."* Live config confirms `<Excess><HailandMaliciousDamage/></Excess>`
is a bare empty tag — matches the original full-config-sweep finding.

**Checked whether this is a wiring gap (like G-BP-24/G-BP-62) or a missing-source gap (like G-BP-71):**

- Searched the *entire* `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql` for `Hail` or `Malicious` —
  Pure's Customer Vehicles table (`cbp_customervehicle`) only carries `CVSumProtected` (loss/damage
  limit) and `CVVoluntaryExcess`. The **only** other `Hail` reference anywhere in the SP is
  `BCHailDamage` under **Building Contents** ("Hail Damage to Vehicles or Watercrafts in Stock
  Limit") — a completely different coverage and concept, not a source for this field. `Malicious`
  doesn't appear anywhere in the SP at all.
- Manuscript (`Carrier_CoverageLibrary_Data_1_0_0_0.xml`, `CustomerVehiclesInput.HailandMaliciousDamage`,
  comment references **ATP-9064**): `default value="0"`, and its only `rules` entry is `<affects>` a
  private cross-screen sync (`LinePrivate.GenerateNewMaliciousAndCustomerVehExcessForAllLocBCTheftCov`)
  triggered `onChange` — i.e., this field is designed to be set/synced from the **Building BC Theft**
  coverage screen inside DC's own UI, not populated from a standalone Pure value.

**Conclusion: same class of gap as G-BP-71 (SV Storm)** — the manuscript expects a field that has no
Pure source anywhere in the conversion pipeline. Not a wiring bug; nothing to reuse or rewire. Two
open questions for the client: (1) does Pure capture an equivalent value under a different field name
we haven't identified, or (2) is `0`/blank the expected post-conversion state until DC's own
Building-Theft-driven sync populates it once someone opens the policy in DC? No value-level fix
scripted pending that answer.

**Separate casing bug found and fixed live 2026-07-11**: the manuscript's actual XML path is
`Excess/HailAndMaliciousDamage` (capital **A**), but SEQ 26 was sending `<HailandMaliciousDamage/>`
(lowercase). XML element names are case-sensitive, so DC would never have recognized this node at
all regardless of the Pure-source question above — fixing this was a prerequisite for any future fix
either way. Applied (`fixes/G-BP-65_fix.sql`), confirmed live: `<HailAndMaliciousDamage/>`, still
empty pending the client's answer on data source.

---

## Investigated and ruled out — `LegalLiability` limit also blank, but for a different reason

SEQ 26 also has `<limit><Type>LegalLiability</Type><iValue/></limit>` — a second bare empty tag not
previously tracked as a gap. Checked the manuscript before assuming it was another instance of
G-BP-65's class:

```
CustomerVehiclesInput.LegalLiabilityLimit (limit[Type="LegalLiability"]/iValue)
  readOnly=True, required=True
  value = CustomerVehiclesPrivate.LegalLiabilityLimit:
    IF Indicator=False THEN False
    ELSE lookup(TableNames.LegalLiabilityLimit, CoverageKey="CustomerVehicles", ProtectionType="Default")
```

This is a **rate-table lookup** — DC's own internal pricing/rating table, keyed by coverage and
protection type, not a formula computable from any data conversion has access to (unlike SV's
`GLS_SD` limit, which was derivable from `LossOrDamageLimit` and two indicators we already send).
There is no equivalent table, mapping, or source anywhere in the SP or SAS, and there couldn't be —
this is DC's proprietary rating data. Correct-by-design that conversion leaves this blank for DC to
compute. No fix needed, not a gap.

---

## G-BP-70 — applies to SEQ 24

`LINE_CV_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`, hardcoded
`AdjustmentSelection='1'` regardless of whether Pure recorded a percent or dollar adjustment). Same
open, business-decision-pending finding as documented in `seq05-08_general_property.md` — no new
analysis needed here, just confirming SEQ 24 is in scope.

## Checked clean

- **SEQ 25** (`BP_LINE_CV_CLAUSE`) — by design, clause-only pass-through, no gap.
