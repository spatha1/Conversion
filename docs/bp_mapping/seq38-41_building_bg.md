# SEQ 38-41 — Building: Burglary (BG) Sub-Coverage

| Seq | Name | Source view |
|---|---|---|
| 38 | BP_Risk_Building_BG_Subcov | `RISK_BUILDING_BG_COVERAGES` (10 sub-coverage blocks unioned: Alcohol, Customer Vehicles/Watercraft, Motor Fuels, Personal Effects, Stock Vehicles/Watercraft, Tobacco, Standard, Employee Handtools, Employee Theft, Theft) |
| 39 | BP_RISK_BUILDING_BG_UW | `RISK_BUILDING_BG_UW` |
| 40 | BP_LOC_BG_CLAUSE | `LOC_BG_CLAUSE` (by design, clause-only) |
| 41 | BP_RISK_Building_BG | `BUILDING_BG_PAYLOAD` |

**Client tickets:** ATP-10960 (G-BP-01), ATP-10950 (G-BP-51), ATP-1399 (Burglary, tracked under G-BP-14
on SEQ 39).

---

## G-BP-01 (ATP-10960) — CONFIRMED, real impact quantified — TFT_SD missing NZ override

**Live view**: `RISK_BUILDING_BG_COVERAGES`'s `TFT_SD` (Theft) branch sends Pure's raw `THEFTLIMIT`
(`BGTHEFTPROTECTION`) unconditionally for every country.

**PL101** (`Location v1.1`, `TheftInput.TheftLimit`) states explicitly: *"For (NZ) Theft Limit should
always default to the Contents, Stock & Employee Tools Limit."* The correct value
(`CONTENTSSTOCKEMPLOYEETOOLSLIMIT` = `BGCONTENTS + BGEMPLOYEETOOLS` per PL101) is **already** computed
in the same staging table (`Location_BG_Coverage`) and already used correctly by this same view's
`STD_SD`/`EMP_SD` branches — no new data sourcing needed, this is purely a missing country-conditional
swap on one branch.

**Live data confirms real, quantified impact**:

| Country | Rows | `THEFTLIMIT ≠ ContentsStockEmployeeToolsLimit` |
|---|---|---|
| Australia | 11,462 | 11,355 (expected — override doesn't apply) |
| New Zealand | 1,978 | **1,265 (63.9%)** |

**1,265 of 1,978 NZ Burglary policies send the wrong Theft limit.**

**Fix**: `docs/bp_mapping/fixes/G-BP-01_fix.sql` — **view-only**, single `UNION ALL` branch (`TFT_SD`).
Both `iValue` and `INDICATOR` now branch on `COUNTRY`: NZ uses `CONTENTSSTOCKEMPLOYEETOOLSLIMIT`,
everyone else keeps the existing raw `THEFTLIMIT`. No config change — SEQ 38's config already
references the generic `{IVALUE}`/`{INDICATOR}` tokens per branch. **Applied live 2026-07-11,
verified**: 0 of 1,978 NZ rows now mismatch `CONTENTSSTOCKEMPLOYEETOOLSLIMIT` (down from 1,265), and 0
of 11,462 Australia rows deviate from the untouched raw `THEFTLIMIT` — confirming the fix landed
exactly on the NZ population with zero effect elsewhere.

*(Previous register note said "as scripted, deploying it would still be wrong for NZ" — referring to
an earlier draft attempt, not this fix. This is a fresh derivation verified against the live view and
live data, not the old draft.)*

---

## G-BP-51 (ATP-10950) — CONFIRMED CLOSED, already fixed and live

Companion finding to G-BP-01 — the `EMP_SD`/`STD_SD` branches' `INDICATOR`. Live view check confirms
both are **already correctly wired**: `CASE WHEN COALESCE("CONTENTSSTOCKEMPLOYEETOOLSLIMIT",0) > 0
THEN '1' ELSE '0' END`, and in fact **all 10 sub-coverage branches** in `RISK_BUILDING_BG_COVERAGES`
now compute a real, per-branch `INDICATOR` (not a hardcode) — SEQ 38's config already reads the
dynamic `{INDICATOR}` token, not a literal `1`. Whatever deployed this must have happened between the
register note being written and now. Confirmed correct, no action needed. Closing.

---

## G-BP-73 (new, 2026-07-11) — ATP-10775 minimum-value enforcement, Burglary

**Client instruction, ATP-10775** (2026-06-15, "Highest" priority, status Review): *"Policy Conversion
- Current policies that will fail migration due to field restriction in UI - Business Contents,
Burglary, Business Interruption, Money."* Description: *"Limits fields for coverages have minimum LOP
set up on UI causing migration failures. Capricorn has started fixing these issues."* This is a hard
DC import validation, not a display preference — sending a value below the client-specified minimum
(including $0/blank) can make the entire policy fail to migrate.

Client-provided minimums (5 fields total, cross-checked against this codebase 2026-07-11):

| Field | Coverage | Minimum | Status |
|---|---|---|---|
| Total Annual Turnover | Business Details | $50,000 | Not yet checked — different SEQ area, not reached this pass |
| Contents Limit (STD_SD) | Business Contents | $30,000 | Not yet checked — BC coverage not reached this pass |
| **Contents/Stock/EmployeeTools Limit (EMP_SD)** | **Burglary** | **$10,000** | **Confirmed violated, fixed here** |
| **Annual Gross Profit (GRP_SD family)** | **Business Interruption** | **$30,000** | **Confirmed violated, fixed here (see `seq34-37_building_bi.md`)** |
| Money during business hours (MSB_SD) | Money | $2,000 | Already compliant — see G-BP-04 (retracted) |

**Burglary check**: `STD_SD` and `EMP_SD` both source `CONTENTSSTOCKEMPLOYEETOOLSLIMIT` as a raw
passthrough with no floor. Live data (`Location_BG_Coverage`, 13,440 rows): 118 rows at `$0`/`NULL`,
7 rows between `$1`-`$9,999` — **125 of 13,440 (0.93%) below the $10,000 minimum**. This also affects
G-BP-01's already-applied NZ Theft fix, since `TFT_SD`'s NZ branch reuses this same source column —
if left unfloored, the NZ Theft limit could itself fall below whatever minimum applies there too.

**Fix**: `docs/bp_mapping/fixes/G-BP-73_fix.sql` (Step 1) — view-only, `RISK_BUILDING_BG_COVERAGES`.
Floors `STD_SD`, `EMP_SD`, and `TFT_SD`'s NZ branch to `GREATEST(value, 10000)`; `Indicator` becomes
unconditional `1` for `STD_SD`/`EMP_SD` once floored (matches their "mandatory Standard Protection"
nature); Australia's `TFT_SD` branch (raw `THEFTLIMIT`) is untouched since the client's table doesn't
list a separate Theft Limit minimum. **Applied live 2026-07-11, verified**: `STD_SD`/`EMP_SD` both
floor at exactly $10,000, and 0 NZ `TFT_SD` rows remain below the $10,000 floor.

Business Contents `STD_SD` (min $30,000) fixed 2026-07-11 as G-BP-74 — **still open**: Total Annual
Turnover (min $50,000) needs the same check once Business Details is reached in the sequential pass.

---

## G-BP-78 (new, 2026-07-11) — RISK_BUILDING_BG_COVERAGES missing active-term filter — FIXED, drafted

Follow-up to the client's ATP-10947 duplicate-coverage comment on BC (see `seq50-53_building_contents.md`,
G-BP-76). Same root cause found here: `RISK_BUILDING_BG_COVERAGES` selects directly from
`Location_BG_Coverage` with no filter restricting to the current/active policy term, so any policy with
more than one staging row gets duplicate sub-coverage entries across all 10 branches — one set per term.

**Live data**: 2,544 of 10,371 distinct BG policies (24.5%) have more than one `Location_BG_Coverage`
row. Confirmed directly in the view's own output: **25,442** (policy, `Type`) combinations currently
return more than one row — the largest raw duplicate count found across all 5 Building coverage lines
checked.

**Fix**: `docs/bp_mapping/fixes/G-BP-78_fix.sql` — view-only, adds the same active-term `EXISTS` filter
used in `G-BP-76_fix.sql` to all 10 `UNION ALL` branches. Preserves the G-BP-73 ($10,000 floor) and
G-BP-01 (TFT_SD NZ override) fixes already live in this view. **Superseded by G-BP-81** (below) — this
fix alone left 5 residual true duplicates from a separate bug.

---

## G-BP-81 (new, 2026-07-11) — RISK_BUILDING_BG_COVERAGES premium-join fan-out — FIXED, drafted

Found while verifying G-BP-78's fix live. The correct POST-CHECK (grouping by the full composite key,
including `EXPIRINGID_P`, not the coarser policy+type key used by mistake in G-BP-76 through 80's
original POST-CHECK queries) still showed **5 true duplicates**, all `Type='CUV_SD'` (Customer
Vehicles/Watercraft).

**Root cause**: `VW_OUTPUT_SUBCOVERAGE_BSP` has **two premium rows** for the same
(policy, location, sub-coverage) key on these 5 policies — e.g.
`P00027392|CML00025971|2262193`/`BGCUV_SD` has `EXPPREMIUM` `29.00` on one row and `103.00` on another.
`Location_BG_Coverage` (the view's main source) has exactly **one** row for each of these 5 keys — the
fan-out is entirely on the premium side. Every branch's `LEFT JOIN` to `VW_OUTPUT_SUBCOVERAGE_BSP`
matches on that same key, so whenever it isn't unique the join produces one output row per premium row
instead of one row per coverage — a duplicate `<coverage>` node in the final payload, structurally
identical in effect to the client's original complaint even though the underlying cause is completely
different from G-BP-76 through 80's active-term issue.

Checked the same premium-duplication pattern against `VW_OUTPUT_SUBCOVERAGE_BSP` for BC/BI/EN/Money
(`SUB_COVERAGE LIKE 'BC%'`/`'BI%'`/`'EN%'`/`'MY%'`) — **0 duplicate premium keys in all 4** — this bug
is currently isolated to BG's `CUV_SD`.

**Fix**: `docs/bp_mapping/fixes/G-BP-81_fix.sql` — view-only, `RISK_BUILDING_BG_COVERAGES`. Pre-aggregates
`VW_OUTPUT_SUBCOVERAGE_BSP` with `SUM(EXPPREMIUM)` grouped by (policy composite key, sub-coverage) in a
CTE before joining, applied to all 10 branches structurally (not just `CUV_SD`) since the same fan-out
risk exists in any of them if the source data ever duplicates for another sub-coverage. `SUM` rather
than picking one value, since multiple premium rows for the same sub-coverage most likely represent a
genuine split that should total to the real premium. Includes G-BP-78's active-term filter — **supersedes
it, run this file instead**.

## G-BP-70 — applies to SEQ 39

`RISK_BUILDING_BG_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`,
hardcoded `AdjustmentSelection='1'`) — already tracked in the register for this SEQ, alongside the
still-open G-BP-14 investigation (ATP-1399 Burglary ticket). No new analysis this pass.

## Checked clean

- **SEQ 40** (`BP_LOC_BG_CLAUSE`) — by design, clause-only pass-through, no gap.
- **SEQ 41** (`BP_RISK_Building_BG`) — `{BURGLARY_IND}` already dynamic, no hardcodes found, no gap.
