# SEQ 46-49 — Building: Engineering (EN) Sub-Coverage

| Seq | Name | Source view |
|---|---|---|
| 46 | BP_Risk_Building_EN_Subcov | `RISK_BUILDING_EN_COVERAGES` (5 sub-coverage blocks unioned: Car Wash, Deterioration of Stock, Increased Cost of Working, Loss of Information, Machinery) |
| 47 | BP_RISK_BUILDING_EN_UW | `RISK_BUILDING_EN_UW` |
| 48 | BP_LOC_EN_CLAUSE | `LOC_EN_CLAUSE` (by design, clause-only) |
| 49 | BP_RISK_Building_EN | `BUILDING_EN_PAYLOAD` |

**Client ticket:** ATP-10952 (G-BP-52, "EN Voluntary Excess not returning a value in UI" — 13 policies
per the 2026-06-30 test note, "PURE has values (250-1000), DC=0").

---

## G-BP-52 — CLOSED 2026-07-11 — does not reproduce

**Structure**: `RISK_BUILDING_EN_COVERAGES` has 5 `UNION ALL` sub-coverage branches, all sourced
unconditionally from `Location_EN_Coverage` (every EN policy gets exactly 5 rows regardless of
take-up — confirmed: `BUILDING_EN_PAYLOAD` row count exactly equals distinct filtered policy-binder
count, 4,412 = 4,412, zero row loss on the `Location_01`/`SAMPLE_CBP`/`Location_EN_Coverage` join
chain). Only the `CWS_SD` (Car Wash) branch carries `EXCESSINFO`:

```sql
CONCAT('<Excess>','<Standard/>','<Voluntary>',cast(COALESCE(VOLUNTARYEXCESS,0) as varchar),
'</Voluntary>','<Imposed/>','<Amount/>','</Excess> <Code>EN</Code>')
```

Because the `CWS_SD` branch is unconditional (not gated on Car Wash being taken), the `<Excess>` block
is always emitted for every EN policy — ruling out "missing branch" as a cause. A sample rendered
`SUBCOV` XML shows `<Excess>` positioned as a sibling wedged between two `<coverage>` blocks
(non-deterministic order — `UNION ALL` has no `ORDER BY`), but this doesn't matter for DC's XPath
resolution (`coverage[Type="Engineering"]/Excess` is a child-selector, not order-dependent), so it was
ruled out as the root cause.

**Live data checks** (2026-07-11):
- `Location_EN_Coverage.VOLUNTARYEXCESS` has real, non-trivial values: `(0, 3306), (NULL, 1107),
  (1000, 704), (500, 536), (250, 350)` — 6,003 rows. Source data is not blank.
- **Live view**: comparing every policy where source `VOLUNTARYEXCESS > 0` against the rendered
  `BUILDING_EN_PAYLOAD.SUBCOV` string — **0 mismatches** where the source has a real value but the
  rendered `<Voluntary>` tag shows anything other than that exact value.
- **Stored target** (the actual payload sent to DCT, `RISK_BUILDING_EN_TARGET`, latest load
  2026-07-09): same cross-check against the stored `BP_Risk_Building_EN_Subcov` payload rows —
  **0 mismatches** out of 6,035 `CWS_SD` rows.
- 61 policies have no rows at all in `RISK_BUILDING_EN_TARGET` (blank `SUBCOV` in the live payload
  view) — these are simply newer policies not yet staged by the last SP run, the normal batch-refresh
  lag seen across every SEQ in this project, not a code defect.

**Conclusion**: the current pipeline (both live and as last loaded 2026-07-09) renders
`VoluntaryExcess` correctly for 100% of policies where Pure has a real value. ATP-10952's 13-policy
symptom was tested 2026-06-30, before this load — same pattern as G-BP-05's unreproduced Comment 1:
most likely a stale/pre-fix batch, or a DC-side/downstream display issue after import, not a gap in
this conversion pipeline. No fix drafted. Worth asking the client for the specific policy numbers from
the 2026-06-30 test if the symptom still shows after a fresh conversion run.

**PL101 note** (`EngineeringInput.VoluntaryExcess`, not a pipeline gap): the Options dropdown lists
values up to $5,000 but the documented Mapping Rule text only bands up to $1,000
(`ELSEIF ENVOLUNTARY > 1,000 THEN $1,000`). This view does no banding at all — it passes
`Location_EN_Coverage.VOLUNTARYEXCESS` straight through via `COALESCE(...,0)`. If Pure's own capture
process applies that $1,000 ceiling, it happens upstream of this pipeline and is out of scope here.

---

## SEQ 47 (`RISK_BUILDING_EN_UW`) — checked, no new gap

Matches the standard 14-view shared UW-adjustment template exactly: source `Output_UWAdjust_BSP`,
`RecurringIndicator`/`AdjustmentSelection` both hardcoded `'1'`. Same family as G-BP-70/G-BP-14 (the
still-open cross-SEQ "UW adjustments not populating" investigation — SEQ 54
`RISK_LOCATION_UW_COMBINE` remains the flagged next lead). No Engineering-specific defect found.

## G-BP-79 (new, 2026-07-11) — RISK_BUILDING_EN_COVERAGES missing active-term filter — FIXED, drafted

Follow-up to the client's ATP-10947 duplicate-coverage comment on BC (see `seq50-53_building_contents.md`,
G-BP-76). Same root cause found here: `RISK_BUILDING_EN_COVERAGES` selects directly from
`Location_EN_Coverage` with no filter restricting to the current/active policy term, so any policy with
more than one staging row gets duplicate `CWS_SD`/`DET_SD`/`ICW_SD`/`LOI_SD`/`MAC_SD` entries — one set
per term. Not surfaced by the earlier G-BP-52 investigation on this same SEQ because that pass checked
value correctness (source vs. rendered `VoluntaryExcess`), not row-count duplication.

**Live data**: 1,008 of 4,823 distinct EN policies (20.9%) have more than one `Location_EN_Coverage`
row. Confirmed directly in the view's own output: 5,040 (policy, `Type`) combinations currently return
more than one row.

**Fix**: `docs/bp_mapping/fixes/G-BP-79_fix.sql` — view-only, adds the same active-term `EXISTS` filter
used in `G-BP-76_fix.sql` to all 5 `UNION ALL` branches. **Superseded by G-BP-82** (below) — this fix
alone does not correct the Indicator hardcode.

---

## G-BP-82 (new, 2026-07-11) — RISK_BUILDING_EN_COVERAGES hardcoded Indicator — CORRECTION, FIXED, drafted

**This corrects a mistake from earlier in this same pass.** The "Checked clean" note originally here
closed the hardcoded `Indicator='1'` on all 5 branches as by-design, reasoning qualitatively ("staging
table only contains policies where Engineering is already active") without actually checking limit
data — unlike every other indicator fix this session, all of which quantified a live mismatch first.
The user flagged this directly by inspection of the fix file; checking the real data confirmed the
reasoning was wrong.

**Live data** (`Location_EN_Coverage`, 6,003 rows) — limit column vs. the always-hardcoded `Indicator`:

| Sub-coverage | Limit column | `$0`/`NULL` | % of 6,003 |
|---|---|---|---|
| **Car Wash (CWS_SD)** | `CARWASHLIMIT` | 5,985 | **99.7%** |
| Deterioration of Stock (DET_SD) | `DETERIORATIONOFSTOCKLIMIT` | 5,841 | 97.3% |
| Loss of Information (LOI_SD) | `LOSSOFINFORMATIONLIMIT` | 5,179 | 86.3% |
| Increased Cost of Working (ICW_SD) | `INCREASEDCOSTOFWORKINGLIMIT` | 4,819 | 80.3% |
| Machinery (MAC_SD) | `MACHINERYELECTRONICEQUIP` | 2 | 0.0% |

Confirmed live: `RISK_BUILDING_EN_COVERAGES` shows `Indicator='1'` for 6,003/6,003 rows on every
branch. **`CWS_SD`'s 99.7% is the largest single-field indicator-vs-limit mismatch found in this
entire BP gap-analysis pass** — larger than G-BP-75's 97.8% (BC Hail Storm), previously the largest.

**Fix**: `docs/bp_mapping/fixes/G-BP-82_fix.sql` — view-only, `RISK_BUILDING_EN_COVERAGES`. `Indicator`
now derives from `COALESCE(<limit>,0) > 0` per branch, the standard dynamic pattern used everywhere
else in this codebase. Includes G-BP-79's active-term filter — supersedes it, run this file instead.
No config change (SEQ 46 already reads the generic `{INDICATOR}` token).

---

## Checked clean

- **SEQ 48** (`BP_LOC_EN_CLAUSE`) — by design, clause-only pass-through, hardcoded
  `<Indicator>1</Indicator>` matches every other CLAUSE seq.
