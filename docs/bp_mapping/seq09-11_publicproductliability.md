# SEQ 9-11 — Public and Product Liability (PPL) Coverage

| Seq | Name | Source view |
|---|---|---|
| 9 | BP_Line_PPL_1_UW | `LINE_PPL_UW` |
| 10 | BP_Line_PPL_2_CLAUSE | `LINE_PPL_CLAUSE` (by design, clause-only) |
| 11 | BP_LINE_PPL | `LINE_PPL_PAYLOAD` |

**Client tickets:** ATP-10845 — *"PP 'Contractors and Subcontractors' limit not coming through in
Clarity"* (High, In Progress, assignee Raju Kallepelli).

---

## G-BP-18 / G-BP-50 — CONFIRMED, real impact quantified — DFW_SD/STB_SD/STD_SD/CCC_SD hardcoded Taken

**Live config (SEQ 11, `BP_LINE_PPL`, pulled 2026-07-11):** four sub-coverage blocks hardcode their
`<Indicator>` to `1` with no token at all, and one (`DFW_SD`) also hardcodes `<sValue>Taken</sValue>`:

```xml
<coverage><Type>DFW_SD</Type><sValue>Taken</sValue><Indicator>1</Indicator> ... </coverage>  <!-- Damage from Faulty Workmanship -->
<coverage><Indicator>1</Indicator><Type>STB_SD</Type> ... </coverage>                        <!-- Public Liability Standard -->
<coverage><Indicator>1</Indicator><Type>STD_SD</Type> ... </coverage>                        <!-- Products Liability Standard -->
<coverage><Indicator>1</Indicator><Type>CCC_SD</Type> ... </coverage>                        <!-- Property in Care, Custody or Control -->
```

**Manuscript** (`Carrier_CoverageLibrary_Data_1_0_0_0.xml`) shows every one of these is meant to be
computed, not constant:

| Field | Manuscript rule |
|---|---|
| `STB_SD/Indicator` (`PublicLiabilityStandardIndicator`, ATP-10064) | `= ProtectionTypeStandard` |
| `STD_SD/Indicator` (`ProductsLiabilityStandardIndicator`, ATP-10064) | `= ProtectionTypeStandard` |
| `CCC_SD/Indicator` (`PropertyCareCustodyOrControlIndicator`, ATP-10064) | `= (ProductsandPublicLiabilityLimit > 0)` |
| `DFW_SD/sValue` (comment references **ATP-7856**: *"will visible only when we select PPL with standard option ... otherwise the value is getting stored as Taken even if we didn't add PPL Coverage"*) | default/value `= "Taken"` only when `Indicator AND ProtectionTypeStandard` |
| `DFW_SD/Indicator` | `= (sValue == "Taken")` |

`ProtectionTypeStandard` is already a live token in this exact config template (`{PROTECTIONTYPESTANDARD}`,
sourced from `Line_PublicLiability_Coverage.STANDARD='Taken'`) — the fix doesn't need new Pure data,
just correct wiring.

**Live data quantifies real impact** (`AGGNE.DEV.Line_PublicLiability_Coverage`, `EXPIRYDATE>='2026-01-01'`):

| STANDARD | Count | PRODUCTSANDPUBLICLIABILITYLIMIT |
|---|---|---|
| Taken | 10,920 | > 0 in all 10,920 |
| Not Taken | 1,343 | = 0 in all 1,343 |

`ProductsandPublicLiabilityLimit > 0` and `STANDARD='Taken'` are the same 10,920/1,343 split exactly
— confirming `{PROTECTIONTYPESTANDARD}` alone is a valid proxy for all four manuscript conditions
above (CCC_SD's limit-based rule included).

**Confirmed bug: 1,343 of 12,263 PPL records (11%) will show DFW_SD, STB_SD, STD_SD and CCC_SD as
"Taken" in DCT when Pure recorded "Not Taken."** Not cosmetic — these are the four sub-coverages
that carry actual liability limits and premium under the Public and Product Liability line.

**Fix:** `docs/bp_mapping/fixes/G-BP-18_G-BP-50_fix.sql` — view change (add `PROTECTIONTYPESTANDARD_IND`,
a string twin of `PROTECTIONTYPESTANDARD`, mirroring the existing `RECTIFYINGFAULTY_IND` pattern
already in the same view) + config change (4× `<Indicator>1</Indicator>` → `<Indicator>{PROTECTIONTYPESTANDARD}</Indicator>`,
1× `<sValue>Taken</sValue>` → `<sValue>{PROTECTIONTYPESTANDARD_IND}</sValue>`). **Applied live 2026-07-11,
verified**: view returns the expected 10,920 `Taken`/1,343 `NotTaken` split, config shows all 4
indicators + DFW_SD's `sValue` correctly wired, RUF_SD's `<Indicator>0</Indicator>` untouched. The
Pure-to-Write SP needed no change — `Standard` was already derived correctly from Pure
(`DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql:5530-5533`, matches the client's original SAS
logic); the bug was confined to the view (missing string column) and config (hardcoded literals).

---

## G-BP-49 — DOWNGRADED, checked correct-by-design — RUF_SD hardcoded Indicator=0

Previously flagged alongside G-BP-18 as a hardcode. Checked against the SP and the client's original
SAS (`ProductandPublicLiability_conversionscriptCapricorn.txt`):

```sql
-- DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql, main policy/risk extraction (4 occurrences)
WHERE NOT (COALESCE(IsRunOffLiab,NULL,0) > 0 AND PublicAndProductLiability = 1) AND ...
```
```sas
-- client's original SAS, same rule
LEFT JOIN P_NO_PII.CBP_PUBLICPRODUCTS t3 ON (...) WHERE t3.PP1RunOffLiab < 1;
```

Both the current pipeline and the client's original design **exclude any policy with Runoff
Liability from the entire BP conversion extraction** before PPL coverage is even built. A record
that reaches `LINE_PPL_PAYLOAD` can therefore never have Runoff Liability Taken — the hardcoded
`<Indicator>0</Indicator>` (and the SEQ 11 top-level `<ProtectionTypeRunoff>0</ProtectionTypeRunoff>`)
is always correct for every row that survives to this stage. No fix needed. Closing.

---

## G-BP-19 (ATP-10845) — TRACED, no conversion-side defect found

Ticket: *"PP 'Contractors and Subcontractors' limit not coming through in Clarity."* Traced the full
chain for `CONTRACTANDSUBCONLIMIT` (`CCA_SD` sub-coverage):

- **View (`LINE_PPL_PAYLOAD`)**: `CONTRACTANDSUBCONLIMIT = CASE WHEN CONTRACTANDSUBCON=1 THEN PRODUCTSANDPUBLICLIABILITYLIMIT ELSE '' END`.
- **Live check**, all 12,263 rows: `CONTRACTANDSUBCON='Taken'` never co-occurs with `STANDARD='Not Taken'`
  (cross-tab: `Taken`/`Taken` = 7,433 rows, `Not Taken`/`Taken` = 3,487, blank/`Not Taken` = 1,343 —
  no `Taken`/`Not Taken` combination exists in the data at all).
- **Direct check of `LINE_PPL_PAYLOAD` output**: of the 7,433 rows with `CONTRACTANDSUBCON='1'`,
  **0 have a blank or zero `CONTRACTANDSUBCONLIMIT`** — every one carries a real, non-blank limit
  value (sample confirms `10000000`/`20000000` values matching `PRODUCTSANDPUBLICLIABILITYLIMIT`).
- **Manuscript** (`PublicProductLiabilityInput.PPCCALimit`, comment *"ATP-10064: Updated condition to
  set limit based on indicator"*): `value = IF ContractorsandSubcontractors THEN ProductsandPublicLiabilityLimit ELSE 0`
  — matches exactly what our view already computes and sends.

**No data defect found on the conversion side** — the Snowflake pipeline delivers a correct,
non-blank `CONTRACTANDSUBCONLIMIT` for 100% of the policies where the indicator is on, and that
value matches the manuscript's own formula. If Clarity genuinely isn't displaying it, the most
likely explanations are on the DC/Clarity side: an import-time `onChange` recompute ordering issue,
or a pure UI rendering bug — not a missing/wrong value in the data we send. Recommend routing this
back to the DC/Clarity team with the live-data proof above rather than scripting a conversion-side
fix. No fix drafted.

---

## G-BP-70 — applies to SEQ 9

`LINE_PPL_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`, hardcoded
`AdjustmentSelection='1'` regardless of whether Pure recorded a percent or dollar adjustment). Same
open, business-decision-pending finding as documented in `seq05-08_general_property.md` — no new
analysis needed here, just confirming SEQ 9 is in scope.

## Checked clean

- **SEQ 10** (`BP_Line_PPL_2_CLAUSE`) — by design, clause-only pass-through, no gap.
