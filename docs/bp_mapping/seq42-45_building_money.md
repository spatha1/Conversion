# SEQ 42-45 — Building: Money (MY) Sub-Coverage

| Seq | Name | Source view |
|---|---|---|
| 42 | BP_Risk_Building_Money_Subcov | `RISK_BUILDING_MONEY_COVERAGES` (6 sub-coverage blocks unioned: outside business hours, locked safe, private residence, in transit, employee dishonesty, during business hours) |
| 43 | BP_RISK_BUILDING_MY_UW | `RISK_BUILDING_MY_UW` |
| 44 | BP_LOC_MY_CLAUSE | `LOC_MY_CLAUSE` (by design, clause-only) |
| 45 | BP_RISK_Building_Money | `BUILDING_MONEY_PAYLOAD` |

**Client tickets:** ATP-10956 (G-BP-05), ATP-1396 (G-BP-05 "inverse symptom" + tracked under G-BP-14
on SEQ 43).

---

## G-BP-04 — RETRACTED 2026-07-11 — the $2,000 hardcode is correct-by-design

**Reversed after client instruction ATP-10775** (2026-07-11, "Highest" priority): DC's UI enforces a
hard **minimum value** on several "Standard Protection" limit fields, including this one ($2,000 for
MSB_SD), and sending below-minimum or blank **fails migration for the whole policy** — not a display
preference. Live check: the existing `0→2000` hardcode already satisfies this minimum for all 1,339
current records (0 violations). The analysis below (originally written to justify a "fix" to make this
field blank at $0) is kept for the record, but **the original fix (`G-BP-04_fix.sql`) must not be
applied** — it would have introduced blanks that trigger exactly the migration failure ATP-10775
describes. See G-BP-73 for the broader minimum-value initiative across all 5 client-specified fields.

**Follow-up, G-BP-73 Step 3, applied live 2026-07-11**: rewrote the `0→2000` CASE as
`GREATEST(COALESCE(MONEYDURINGBUSINESSHOURS,0), 2000)` for consistency with the other two floored
fields in G-BP-73 and robustness against any future value between $1-$1,999 (not currently possible
given the SP's banding, but not guaranteed to stay that way). Not a behavior change — confirmed live:
`MSB_SD`'s minimum is still exactly $2,000, and the value distribution (908/756/480/124 across
$5,000/$10,000/$2,000/$20,000) is identical to before the rewrite.

### Original (superseded) analysis

**Live view**: `RISK_BUILDING_MONEY_COVERAGES`'s `MSB_SD` ("Money at Situation during Business Hours")
branch:
```sql
case when COALESCE(MONEYDURINGBUSINESSHOURS,0)=0 then 2000 else ... end AS iValue,
cast('1' as varchar) AS Indicator   -- dynamic version commented out just above it
```

**PL101** (`MoneyInput.MoneyOnThePremisesDuringBusinessHoursLimit`) states: *"If MYDURINGBUSHOURS = 0
THEN Select"* — blank, not a dollar tier (valid options are $2,000/$5,000/$10,000/$20,000 only). The
view fabricates a $2,000 value that Pure never sent, and hardcodes the Indicator to always-Taken —
inconsistent with every sibling branch in the same view (`MSO_SD`/`MSS_SD`/`MPC_SD`/`MIT_SD`/`EMP_SD`),
which all correctly derive `Indicator` from `limit > 0`. The correct dynamic Indicator line is present
in the source, just commented out.

**Live data** (`Location_Money_Coverage`, filtered to `EXPIRYDATE>='2026-01-01'`, matching every other
SEQ this session — 1,339 rows): `MONEYDURINGBUSINESSHOURS` is never literally `0` — only `NULL` (32 of
1,339 rows, 2.4%), which `COALESCE(...,0)` treats identically. **Confirmed: 32 records get a
fabricated $2,000 limit and an always-Taken indicator when Pure recorded nothing for this field.**
*(Corrected 2026-07-11 — an earlier pass of this number, 53/2,268, was checked against the table
without the date filter; the SP/view logic and conclusion are unchanged, only the row count.)*

**Fix**: `docs/bp_mapping/fixes/G-BP-04_fix.sql` — view-only, single `UNION ALL` branch (`MSB_SD`).
`0`/`NULL` now maps to blank; `Indicator` restored to the same dynamic `limit>0` logic already used
by every sibling. No config change. Drafted, not applied.

---

## G-BP-05 (ATP-10956) — CONFIRMED, real impact quantified — location field shows "Other" at $0 limit

**Live view**: `BUILDING_MONEY_PAYLOAD`'s final `CASE` for `LOCATIONOUTSIDEBUSINESSHOURS` always
defaults to `'Other'` when the raw text doesn't match `'Locked Safe'`/`'Locked Til'` — with no gate on
whether the corresponding limit (`MSO_SD`'s `MONEYOUTSIDEBUSINESSHOURS`) is actually greater than $0.
That column isn't even carried through this view's CTE chain to check against.

**PL101** (`MoneyInput.LocationOfMoneyOutsideBusinessHours`): *"Display only when user has selected
GREATER THAN $0 under the field 'Money on the premises outside business hours Limit'."*

**Live data** (`Location_Money_Coverage`, filtered to `EXPIRYDATE>='2026-01-01'` — 1,339 rows):

| Condition | `LOCATIONOUTSIDEBUSINESSHOURS` | Count |
|---|---|---|
| limit = $0 | `'Other'` | **438 (32.7%)** |
| limit > $0 | `'Other'`/`'Locked Safe'`/`'Locked Til'` | 901 (correct — field is relevant) |

**438 of 1,339 Money records show a location value for a field that per PL101 shouldn't be there at
all**, since the underlying limit is $0. *(Corrected 2026-07-11 — an earlier pass of this number,
722/2,268, was checked against the table without the date filter; conclusion and fix are unchanged,
only the row count. Confirmed live after applying the fix: `BUILDING_MONEY_PAYLOAD` now returns
exactly 1,339 rows split 438/832/64/5 across blank/Other/LockedSafe/LockedTil — a perfect match, and
proof the location-matching join between `Location_01` and `Location_Money_Coverage` drops zero rows
when both sides use the same date filter.)*

**Fix**: `docs/bp_mapping/fixes/G-BP-05_fix.sql` — view-only (`BUILDING_MONEY_PAYLOAD`). Adds
`MONEYOUTSIDEBUSINESSHOURS` to the CTE chain, gates the field to blank when that limit is `0`. No
config change. Drafted, not applied.

**Not addressed by this fix** — the register's other half of G-BP-05, ATP-1396's *"inverse symptom,
sometimes not populated when it should be"* (2026-06-26). That's a different failure mode (limit > 0
but the location comes out wrong/blank) requiring a separate look at `MYOUTSIDEBUSLOCATION`'s raw
text-cleanup logic — not yet investigated this pass.

### Client comments on ATP-10956 (2026-07-11), cross-checked

The client (Raju Kallepelli) left two comments on the ticket:

1. *"'Money on the Premises Outside Business Hours Limit' is showing as 0, however in the payload the
   corresponding Selected Indicator = 1. Unless this coverage is applicable and selected, the
   indicator should be 0."*
2. *"If the 'Money on the Premises Outside Business Hours Limit' is 0, then
   LocationOMoneyOutsideBusinessHours should not contain a value and should be returned as empty."*

**Comment 2 matches exactly** — this is precisely what the fix above addresses.

**Comment 1 does not reproduce.** Checked both the live view (`GROUP BY IVALUE, INDICATOR` on
`RISK_BUILDING_MONEY_COVERAGES` `MSO_SD` rows) and a full scan of the actual stored payload in
`RISK_BUILDING_Money_TARGET` (latest load 2026-07-09) for the exact pattern described
(`<iValue>0</iValue>` with `<Indicator>1</Indicator>`) — **zero matches in either place**, out of
2,268 records. `MSO_SD`'s indicator is already 100% consistent with its limit everywhere we can check.
Most likely this reflects a specific policy converted before the current indicator logic was in
place, or a DC-side behavior after import — not a current gap in this pipeline. Worth asking the
client which policy/date the screenshot is from so that specific record can be checked directly if it
still looks wrong after a fresh conversion run.

---

## G-BP-80 (new, 2026-07-11) — RISK_BUILDING_MONEY_COVERAGES missing active-term filter — FIXED, drafted

Follow-up to the client's ATP-10947 duplicate-coverage comment on BC (see `seq50-53_building_contents.md`,
G-BP-76). Same root cause found here: `RISK_BUILDING_MONEY_COVERAGES` selects directly from
`Location_Money_Coverage` with no filter restricting to the current/active policy term, so any policy
with more than one staging row gets duplicate `MSO_SD`/`MSS_SD`/`MPC_SD`/`MIT_SD`/`EMP_SD`/`MSB_SD`
entries — one set per term.

**Live data**: 391 of 1,799 distinct Money policies (21.7%) have more than one `Location_Money_Coverage`
row. Confirmed directly in the view's own output: 2,346 (policy, `Type`) combinations currently return
more than one row.

**Fix**: `docs/bp_mapping/fixes/G-BP-80_fix.sql` — view-only, adds the same active-term `EXISTS` filter
used in `G-BP-76_fix.sql` to all 6 `UNION ALL` branches. Preserves the G-BP-73 Step 3 (`MSB_SD` $2,000
floor) fix already live in this view.

---

## G-BP-70 — applies to SEQ 43

`RISK_BUILDING_MY_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`,
hardcoded `AdjustmentSelection='1'`) — already tracked in the register for this SEQ, alongside the
still-open G-BP-14 investigation (ATP-1396 Money ticket). No new analysis this pass.

## Checked clean

- **SEQ 44** (`BP_LOC_MY_CLAUSE`) — by design, clause-only pass-through, no gap.
