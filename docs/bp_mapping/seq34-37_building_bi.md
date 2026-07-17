# SEQ 34-37 — Building: Business Interruption (BI) Sub-Coverage

| Seq | Name | Source view |
|---|---|---|
| 34 | BP_Risk_Building_BI_Subcov | `RISK_BUILDING_BI_COVERAGES` (3 sub-coverage blocks unioned: Claims Prep, Accounts Receivable, Additional Cost of Working) |
| 35 | BP_Risk_Building_BI_UW | `RISK_BUILDING_BI_UW` |
| 36 | BP_LOC_BI_CLAUSE | `LOC_BI_CLAUSE` (by design, clause-only) |
| 37 | BP_RISK_Building_BI | `BUILDING_BI_PAYLOAD` |

**Client tickets:** ATP-1399 (BI) — already tracked against SEQ 35 under G-BP-14 (shared UW-adjustment
root-cause investigation, still open). No other BI-specific tickets found.

---

## G-BP-27 (SEQ 34) — CONFIRMED, largest live-impact bug found this session — pre-existing fix ready to deploy

**Live config**: SEQ 34's generic sub-coverage template hardcodes `<Indicator>1</Indicator>` for all 3
branches (CLP_SD "Claim Preparation", ACR_SD "Accounts Receivable", ICW_SD "Additional Increased Cost
of Working"). `RISK_BUILDING_BI_COVERAGES` doesn't compute an `INDICATOR` column at all — every row
this view produces gets marked "Taken" unconditionally, regardless of whether Pure actually recorded
a limit.

**Confirmed via live data on `Location_BI_Coverage`** (9,617 rows) — each of the 3 sub-coverages has a
real, large population of `$0`/blank limits that still get sent as `Indicator=1`:

| Sub-coverage | Limit column | `$0` | `NULL` | Combined affected | % of 9,617 |
|---|---|---|---|---|---|
| Claim Preparation (CLP_SD) | `CLAIMSPREPARATIONCOSTLIMIT` | 759 | 621 | 1,380 | 14.3% |
| **Accounts Receivable (ACR_SD)** | `ACCOUNTSRECEIVABLELIMIT` | 5,180 | 2,546 | **7,726** | **80.3%** |
| Additional Cost of Working (ICW_SD) | `ADDITIONALCOSTOFWORKINGLIMIT` | 664 | 563 | 1,227 | 12.8% |

**Accounts Receivable is wrong on 4 out of 5 Business Interruption policies** — the largest single
confirmed data-integrity gap found in this entire pass, by both row count and percentage.

**A fix already existed, drafted 2026-07-07, never applied until now** — found in
`sql/indicator_fixes/BP_SEQ34_BI_SUBCOV_INDICATOR_FIX_20260707_SNOWFLAKE.sql` (view: adds `INDICATOR`
column to all 3 `UNION ALL` branches, `1` when that branch's limit `> 0` else `0`) and
`BP_SEQ34_BI_SUBCOV_INDICATOR_FIX_20260707_CONFIG.sql` (config: `<Indicator>1</Indicator>` →
`<Indicator>{INDICATOR}</Indicator>`, PRE-CHECK/UPDATE/POST-CHECK pattern). Verified live 2026-07-11
that neither half had been applied before this session. Independently re-derived the same root cause
and fix shape from scratch before finding these files, which corroborated the July 7 draft's
correctness.

**Applied live 2026-07-11, verified both halves:**
- View: `RISK_BUILDING_BI_COVERAGES` now produces `INDICATOR`, confirmed via
  `GROUP BY TYPE, INDICATOR` — `ACR_SD`: 7,726 rows now correctly `0` / 1,891 `1`; `CLP_SD`: 1,380 `0`
  / 8,237 `1`; `ICW_SD`: 1,227 `0` / 8,390 `1` — matching the affected-row counts found during
  investigation exactly.
- Config: SEQ 34 now reads `<Indicator>{INDICATOR}</Indicator>`, confirmed live.

---

## G-BP-28 (SEQ 37) — DOWNGRADED, correct-by-design (with one small caveat)

6 hardcoded `<Indicator>1</Indicator>` (line-level + `GRP_SD`/`GRP_CY`/`GRP_EQ`/`GRP_ST`/`GRP_BF`, all
keyed to the same `{ANNUALGROSSPROFIT}` limit). Checked against manuscript and live data — same shape
as Building base's peril riders (`STD_BF`/`STD_CY`/`STD_EQ`/`STD_ST`, all closed correct-by-design in
`seq30-33_building_base.md`):

- Manuscript: no `GRP_CY`/`GRP_EQ`/`GRP_ST`/`GRP_BF`/Indicator field exists at all — only the
  line-level `InterruptionInput.Indicator`. These peril riders aren't independently controllable;
  PL101 only documents `AnnualGrossProfit` as a single required input.
- Live check: `Location_BI_Coverage.ANNUALGROSSPROFIT` is zero/null for **6 of 6,708 rows (0.09%)**.

Unlike SEQ 34's sub-coverages, there's no PL101-documented per-branch rule to violate, and the
practical impact is 3 orders of magnitude smaller than G-BP-27's. Consistent with this session's
"don't disturb working code for near-zero benefit" standard (see the Building base `>1`-vs-`>0`
finding) — **not scripting a fix**, but flagging the 6-row edge case for the record rather than
declaring it perfectly clean.

---

## G-BP-73 (new, 2026-07-11) — ATP-10775 minimum-value enforcement, GRP_SD family

Client instruction: DC's UI enforces a hard minimum ("LOP") on BI's Annual Gross Profit (`GRP_SD`,
and by extension `GRP_CY`/`GRP_EQ`/`GRP_ST`/`GRP_BF`, all keyed to the same `{ANNUALGROSSPROFIT}`
token) of **$30,000** — sending below-minimum (including $0) **fails migration for the whole policy**.
Live check: 6 of 6,708 BI records output literal `$0`. Fix applied (`fixes/G-BP-73_fix.sql`, Step 2):
floors `ANNUALGROSSPROFIT` to `$30,000` in `BUILDING_BI_PAYLOAD`, which automatically covers all 5
sub-coverage limits since they share the one token. **Applied live 2026-07-11, verified**: minimum
`ANNUALGROSSPROFIT` across all rows is now exactly $30,000. See the full writeup in
`seq38-41_building_bg.md` (where the Burglary half of this same fix lives) for the ATP-10775 context.

## G-BP-77 (new, 2026-07-11) — RISK_BUILDING_BI_COVERAGES missing active-term filter — FIXED, drafted

Follow-up to the client's ATP-10947 duplicate-coverage comment on BC (see `seq50-53_building_contents.md`,
G-BP-76). Same root cause found here: `RISK_BUILDING_BI_COVERAGES` selects directly from
`Location_BI_Coverage` with no filter restricting to the current/active policy term, so any policy with
more than one staging row gets duplicate `CLP_SD`/`ACR_SD`/`ICW_SD` entries — one set per term.

**Live data**: 1,817 of 7,592 distinct BI policies (23.9%) have more than one `Location_BI_Coverage`
row. Confirmed directly in the view's own output: 5,451 (policy, `Type`) combinations currently return
more than one row.

**Fix**: `docs/bp_mapping/fixes/G-BP-77_fix.sql` — view-only, adds the same active-term `EXISTS` filter
used in `G-BP-76_fix.sql` to all 3 `UNION ALL` branches. Preserves the G-BP-27 indicator fix already
live in this view.

---

## G-BP-70 — applies to SEQ 35

`RISK_BUILDING_BI_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`,
hardcoded `AdjustmentSelection='1'`) — already tracked in the register for this SEQ, alongside the
still-open G-BP-14 investigation (ATP-1399 BI ticket). No new analysis this pass.

## Checked clean

- **SEQ 36** (`BP_LOC_BI_CLAUSE`) — by design, clause-only pass-through, no gap.
