# SEQ 50-53 — Building: Contents & Stocks (BC) Sub-Coverage

| Seq | Name | Source view |
|---|---|---|
| 50 | BP_Risk_Building_BC_Subcov | `RISK_BUILDING_BC_COVERAGES` (12 sub-coverage blocks unioned: STD_SD, FLD_SD, SWP_SD, PER_SD, MFL_SD, EMP_SD, VIS_SD, CUV_SD, WIS_SD, CUW_SD, ACC_SD, HAL_ST, LND_SD) |
| 51 | BP_RISK_BUILDING_BC_UW | `RISK_BUILDING_BC_UW` |
| 52 | BP_LOC_BC_CLAUSE | `LOC_BC_CLAUSE` (by design, clause-only) |
| 53 | BP_RISK_Building_BC | `BUILDING_BC_PAYLOAD` (also carries 6 hardcoded coverage blocks in its own config template — STD_BF/STD_CY/STD_EQ/STD_ST, HAL_SD, LND_SD — all sourced directly from this view, not from SEQ 50's `{SUBCOV}`) |

**Client tickets:** ATP-10775 (G-BP-74), ATP-10949 (Contents Limit, see G-BP-74 note), ATP-10947
(G-BP-02, plus its client-comment follow-up G-BP-76 — duplicate coverage), ATP-10946 (G-BP-03).
**Self-identified:** G-BP-75 (Hail Storm, no ticket).

---

## G-BP-74 (ATP-10775) — Contents Limit (STD_SD), min $30,000 — FIXED, drafted

Continues the G-BP-73 minimum-value initiative. Client's field table: *"Contents Limit (Business
Contents STD_SD), min $30,000."* Found the exact fix half-written and commented out, sitting right
next to the live line in `RISK_BUILDING_BC_COVERAGES`:

```sql
-- case when COALESCE(CONTENTSLIMIT ,0)=0 then 30000 else cast(...) end ::NUMBER(10,0)::varchar AS iValue,
CAST(CAST(COALESCE(CONTENTSLIMIT,0) AS NUMBER(20,0))AS VARCHAR) AS iValue,   -- live line, no floor
```

Two places carry `CONTENTSLIMIT` and both needed the floor:
1. **SEQ 50** (`RISK_BUILDING_BC_COVERAGES`, `STD_SD` branch) — `iValue`/`Indicator`.
2. **SEQ 53** (`BUILDING_BC_PAYLOAD`, `CONTENTSLIMIT` column) — feeds all 4 hardcoded peril coverages
   (Bushfire/Cyclone/Earthquake/Storm) in the SEQ 53 template, which all reuse the same token.

**Live data** (`Location_BC_Coverage`, `EXPIRYDATE>='2026-01-01'`, 10,437 rows): 257 rows (2.5%) =
$0/NULL — would fail migration under ATP-10775. 0 rows non-zero-but-below-$30,000.

**Fix**: `docs/bp_mapping/fixes/G-BP-02_fix.sql` (combined with G-BP-02's Landslide fix since both
touch the same two views — run that file, not the standalone `G-BP-74_fix.sql`). View-only, floors
`CONTENTSLIMIT` to `GREATEST(COALESCE(CONTENTSLIMIT,0), 30000)` in both views; `STD_SD`'s `Indicator`
becomes always `1` once floored (same pattern as Burglary `STD_SD`/`EMP_SD` in G-BP-73).

**Cross-check against ATP-10949** ("Contents Limit populating a value when it's 0 in PURE data",
2026-06-30, example: `P00023336`/`P00034238`, PURE=0 → DC=32000): this ticket predates ATP-10775
(2026-07-11, "Highest" priority) and complains about the *opposite* direction — a fabricated value
appearing when Pure sent 0. ATP-10775 later reframes this as a **requirement**, not a bug (same
resolution pattern as G-BP-04/Money). The two example policies are no longer present in the live
source table (renewed/reissued since testing), so the specific `$32,000` figure couldn't be directly
re-verified — it doesn't match this fix's `$30,000` floor, so it's worth asking the client whether
`$32,000` came from a different/earlier version of this logic or a different field entirely.

---

## G-BP-02 (ATP-10947) — BC Landslide (LND_SD) — FIXED, drafted, real impact quantified

**Two live bugs found**, both in `RISK_BUILDING_BC_COVERAGES`'s `LND_SD` branch:

1. **Wrong source column.** PL101 (`ContentsAndStocksInput.LandSlideLimit`): *"Hard coded, equals
   Contents+Stock+Employee Tools of Trade Limits) ... Cannot exceed [that sum]. (Max=$250k)"* — the
   view instead sources the raw `LANDSLIDELIMIT` column. **Live data**: 935 of 1,389 NZ Building
   Contents records (67.3%) have a raw value that doesn't match
   `LEAST(CONTENTSLIMIT+STOCKLIMITEXVEHICLESWATERCRAFT+EMPLOYEETOOLSOFTRADELIMIT, 250000)`.
2. **NZ-only gate is structurally broken.** The field is labelled "Landslide Limit **NZ ONLY**" in
   PL101, and the view has `AND TRIM(COUNTRY)='New Zealand'` — but it sits inside the `LEFT JOIN`'s
   `ON` clause (targeting the premium lookup), not a `WHERE`/`CASE` condition. A `LEFT JOIN`'s `ON`
   clause never filters the left table's rows — it only controls whether the right table matches. Live
   check: **12,495 non-NZ policies currently get an `LND_SD` row** (should be 0). Currently harmless in
   practice only because `LANDSLIDELIMIT` happens to always be `$0`/`NULL` for non-NZ Pure records (0
   non-NZ policies show `Indicator=1`) — a data coincidence, not a structural guarantee, so it's fixed
   properly rather than left as a latent risk.

`BUILDING_BC_PAYLOAD` (SEQ 53) has a **separate**, hardcoded `LND_SD` coverage block in its own config
template — same raw-column bug, plus an `Indicator` gated only on country (not on the computed value
being `>0`). Fixed to match.

**Flagged, still unresolved** (config-level, needs a dev-team decision, not a view fix): SEQ 50's
`LND_SD` (via `{SUBCOV}`) and SEQ 53's hardcoded `LND_SD` block render as **two separate**
`<coverage><Type>LND_SD</Type>` siblings in the same final payload. This is a real, separate design
question (does DC's schema tolerate two sibling `LND_SD` nodes) — but it turned out **not** to be what
the client actually reported (see G-BP-76 below).

**Fix**: `docs/bp_mapping/fixes/G-BP-02_fix.sql` — view-only, two views (combined with G-BP-74's
Contents floor since both touch the same views). `LND_SD` branch now computes
`LEAST(sum, 250000)`, gated on `TRIM(COUNTRY)='New Zealand'` in the `SELECT`, not the broken `ON`
clause. **Superseded for `RISK_BUILDING_BC_COVERAGES` by `fixes/G-BP-76_fix.sql`** (same value fix,
plus the real duplicate-coverage fix below) — run that file instead for SEQ 50; this file's SEQ 53
(`BUILDING_BC_PAYLOAD`) step is still current.

---

## G-BP-76 (ATP-10947 client comment) — RISK_BUILDING_BC_COVERAGES missing active-term filter — FIXED, drafted, client-confirmed root cause

The client (Raju Kallepelli) commented directly on ATP-10947, policy `P00010139`: *"We are seeing a
duplicate coverage entry for BCLND_SD. Could you please investigate this and confirm why the coverage
is being returned more than once? Additionally, can you please review the coverage mapping and ensure
there are no duplicate coverages being sent in the payload going forward?"*

**Traced live**: `P00010139`/`CML00010692` has **two** rows in `Location_BC_Coverage` — one under an
**expired** term (`EXPIRINGID_P` 177095, `Location_01.EXPIRYDATE` = 2019-09-01, Landslide = $52,500)
and one under the **current** term (2175291, `EXPIRYDATE` = 2026-09-01, Landslide = $83,000).

`RISK_BUILDING_BC_COVERAGES` (SEQ 50) selects directly from `Location_BC_Coverage` with **no filter
restricting to the active term** — so it emits *both* rows as separate `LND_SD` entries, and the same
is true for **all 13 sub-coverage types** in this view, not just Landslide. `BUILDING_BC_PAYLOAD`
(SEQ 53) does **not** have this bug — it already joins through `Location_01`/`SAMPLE_CBP` with
`WHERE EXPIRYDATE>='2026-01-01'`, which correctly restricts to the one active-term row (that's why the
client's ticket only flagged a *wrong* Landslide number there, not outright duplication — `83000` is
right there matching the current term, just via the wrong formula, see G-BP-02).

**This corrects the earlier G-BP-02 write-up above**, which speculated the client's duplicate was the
SEQ-50-vs-SEQ-53 dual-`LND_SD`-node issue. That issue is real but separate — this active-term gap is
the actual cause of what the client saw.

**Scope**: 2,749 of 11,055 distinct BC policies (24.9%) have more than one `Location_BC_Coverage` row
and are exposed to duplicate sub-coverage nodes of *every* type, not just Landslide — the client
happened to notice Landslide first because its value differs enough between terms to stand out.

**Same missing-filter shape found (flagged, not fixed yet) in 4 sibling views** — all source directly
from their own `Location_*_Coverage` table with the identical no-active-term-filter shape:

| View | Source table multi-term exposure |
|---|---|
| `RISK_BUILDING_BI_COVERAGES` | 1,817 / 7,592 (23.9%) |
| `RISK_BUILDING_BG_COVERAGES` | 2,544 / 10,371 (24.5%) |
| `RISK_BUILDING_EN_COVERAGES` | 1,008 / 4,823 (20.9%) |
| `RISK_BUILDING_MONEY_COVERAGES` | 391 / 1,799 (21.7%) |

Recommend applying the same `EXISTS`-against-`Location_01`/`SAMPLE_CBP` filter to all four, each with
its own live-verification pass (same discipline used everywhere else this session), as a follow-up.

**Fix**: `docs/bp_mapping/fixes/G-BP-76_fix.sql` — view-only, `RISK_BUILDING_BC_COVERAGES` only.
Combines every G-BP-02/G-BP-74/G-BP-75 value fix already drafted for this view with the new active-term
`EXISTS` filter applied to all 13 `UNION ALL` branches. Supersedes `G-BP-02_fix.sql`'s Step 1 for this
view — `G-BP-02_fix.sql`'s Step 2 (`BUILDING_BC_PAYLOAD`) is unaffected and still needed separately.

---

## G-BP-75 — BC Hail Storm (HAL_ST) — FIXED, drafted, largest live-impact bug this session

Self-identified while reviewing the other `RISK_BUILDING_BC_COVERAGES` branches (not tied to a client
ticket). The `HAL_ST` ("Hail Storm") branch hardcodes `<Indicator>1</Indicator>` regardless of the
underlying `HAILDAMAGE` limit — every other correctly-wired branch in this view derives `Indicator`
from its own `limit > 0`.

**Live data** (`Location_BC_Coverage`, `EXPIRYDATE>='2026-01-01'`, 10,437 rows): 10,179 rows (97.5%)
have `HAILDAMAGE = $0`/`NULL`. Checking the view directly: **14,216 of 14,533 `HAL_ST` rows (97.8%)
show `Indicator=1` with `iValue=0`** — the single largest live-impact percentage found in this entire
BP gap-analysis pass so far (exceeds G-BP-27's 80.3%, the previous largest).

**Separate, undocumented node found alongside it**: SEQ 53's config template hardcodes a *second*,
entirely separate coverage block — `Type="HAL_SD"`, `Code="BCHAL_SD"`, `Description="Hail Standard"` —
sourced from the same `HAILDAMAGE` column via `BUILDING_BC_PAYLOAD`, with its own baked-in
`<Indicator>1</Indicator>` **directly in the config template** (not even a view token). PL101 only
documents `HAL_ST` (`ContentsAndStocksInput.HailDamagetoVehiclesorWatercraftsInStockLimit`) as a valid
BC Hail coverage type — `HAL_SD` does not appear anywhere in the PL101 spec. This looks like either a
mistaken duplicate of `HAL_ST` or an undocumented/legacy coverage type; **needs dev-team confirmation**
before deciding whether to fix its indicator or remove the block entirely — same class of open
question as G-BP-02's `LND_SD` duplication above.

**Fix**: `docs/bp_mapping/fixes/G-BP-02_fix.sql` (combined, same view as G-BP-02/G-BP-74) — `HAL_ST`'s
`Indicator` now uses the standard `CASE WHEN COALESCE(HAILDAMAGE,0)>0 THEN '1' ELSE '0' END` pattern.

---

## G-BP-03 (ATP-10946) — BC Flood (FLD_SD) NZ default — CLOSED, no current live impact

PL101 (`ContentsAndStocksInput.FloodDamage`): *"For NZ Rule: Default to 'Taken'"* — the raw
`FLOODDAMAGE` text column has no NZ override; if blank/other for an NZ record, `sValue` would render
blank instead of defaulting to `Taken`.

**Live data** (`Location_BC_Coverage`, NZ, `EXPIRYDATE>='2026-01-01'`, 1,389 rows): **0 rows** have
`FLOODDAMAGE` outside `'Taken'`/`'Not Taken'` — the field is always cleanly populated for every current
NZ record, so this doesn't cause any live mismatch today (same "clean data, latent code gap" pattern as
several other closed gaps this session). Ticket example (76 policies, PURE=0/DC=1) not reproduced
against current data — same "stale batch, tested 2026-06-30" pattern seen elsewhere this session
(G-BP-05 Comment 1, G-BP-52).

**Fix applied anyway, for robustness**: folded into `fixes/G-BP-02_fix.sql`'s Step 1 (`FLD_SD` branch)
— added a `WHEN TRIM(COUNTRY)='New Zealand' THEN '<sValue>Taken</sValue>'` fallback so a future blank
NZ record doesn't silently lose the required default. No behavior change for current data (0 rows hit
the new branch).

---

## SEQ 51 (`RISK_BUILDING_BC_UW`) — checked, no new gap

Matches the standard 14-view shared UW-adjustment template exactly (same family as G-BP-70/G-BP-14).
No BC-specific defect found.

## Checked clean

- **SEQ 50** other 9 branches (`SWP_SD`/`PER_SD`/`MFL_SD`/`EMP_SD`/`VIS_SD`/`CUV_SD`/`WIS_SD`/`CUW_SD`/
  `ACC_SD`) — all correctly derive `Indicator` from their own `limit > 0`, no hardcodes. (`HAL_ST` was
  hardcoded — see G-BP-75 above.)
- **SEQ 52** (`BP_LOC_BC_CLAUSE`) — by design, clause-only pass-through.
