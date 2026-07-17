# SEQ 30-33 — Building (BB) Base Coverage

| Seq | Name | Source view |
|---|---|---|
| 30 | BP_Building_SubCov | `BUILDING_SUBCOVERAGES` (9 sub-coverage blocks unioned: Glass, Flood, Loss of Rent, Accidental Damage, Standard, Bushfire, Cyclone, Earthquake, Storm, Landslide) |
| 31 | BP_BUILDING_UW | `BUILDING_UW` |
| 32 | BP_LOC_BB_CLAUSE | `LOC_BB_CLAUSE` (by design, clause-only) |
| 33 | BP_RISK_Building_Cov_Building | `BUILDING_PAYLOAD` |

**Client tickets:** none found in either ATP-10219 export or the broader unfiltered export for the
base Building/BB line specifically (ticket clusters for sub-coverages like BI/BG/Money/EN/BC live
under their own SEQ ranges, 34+).

---

## G-BP-45 — already closed, reconfirmed correct-by-design

Line-level `<Indicator>1</Indicator>` (SEQ 33) — previously reviewed: no limit column exists at this
level, row presence in `BUILDING_PAYLOAD` is itself the "coverage active" signal. Reconfirmed, no
change.

---

## Checked — Landslide (LND_SD), the one field that looked like a repeat of G-BP-02

PL101 (`Location v1.1`) documents Building's Landslide limit with an explicit NZ-only rule:
*"1. NZ Rule: Default to Business Building Limit AND Max allowed = $250,000."* This is the exact same
rule shape as G-BP-02 (Business Contents' Landslide, SEQ 50), where the raw `LANDSLIDELIMIT` column
was found NOT to implement this formula — worth checking whether Building's version has the same bug.

**It doesn't.** `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql:6236` passes through Pure's own
`BBLandslideLimit` directly, same shape as BC's version — but live data shows Pure's raw field
*already* enforces the rule correctly here:

| Check (`LOCATION_BB_COVERAGE`, all NZ rows, n=901) | Result |
|---|---|
| `LANDSLIDELIMIT > BUSINESSBUILDINGSLIMIT` | 0 rows |
| `LANDSLIDELIMIT > 250,000` | 0 rows |
| `LANDSLIDELIMIT` null while `BUSINESSBUILDINGSLIMIT > 0` (missing default) | 0 rows |
| Australia rows with any non-zero `LANDSLIDELIMIT` | 0 of 7,062 |

Pure itself already caps and NZ-gates this field before it ever reaches the SP — the raw passthrough
is correct. (This doesn't retroactively clear G-BP-02 — that's Business Contents' own separate raw
column, `BCLandslideLimit`, checked and confirmed broken independently; not re-verified again here.)

## Checked — indicator comparison uses `>1` instead of PL101's documented `>0`, zero live impact

`BUILDING_SUBCOVERAGES` computes 7 of its 9 `INDICATOR` values with `CASE WHEN <limit> > 1 THEN 1
ELSE 0 END` (Flood, Loss of Rent, Accidental Damage, Standard, Bushfire, Cyclone, Earthquake, Storm),
while PL101 documents the rule as `IF <field> > 0 THEN "Taken"`. Technically non-compliant with the
documented rule, but checked all 5 underlying limit columns
(`BBFLOODPROTECTION`/`LOSSOFRENTLIMIT`/`ACCIDENTALLOSSORDAMAGELIMIT`/`BUSINESSBUILDINGSLIMIT`/`LANDSLIDELIMIT`)
against live data — every non-zero value is a real dollar limit ($5,000+), never exactly `1`. `>1` and
`>0` produce identical results on every row in the current dataset. Flagged as a fragile pattern (a
future $1 limit would silently be treated as "not taken"), not a live bug. Not scripted; not worth a
fix disturbing working code for zero current benefit — noted here in case it resurfaces later.

## Checked — bare `<Excess>` sub-tags at SEQ 33 (`Amount`, `Imposed`, `Flood`, `Earthquake`, `Standard`, `Glass`)

Same shape as the CV `LegalLiability` limit (SEQ 26) and unlike the CV `HailAndMaliciousDamage` gap —
checked PL101 and the manuscript before assuming these needed a fix:

- `StandardExcess`, `ImposedExcess`, `EarthquakeExcess`, `GlassExcess`, `FloodExcess` are all
  documented in PL101 (`BuildingRiskSMEInput.*`) with matching `DC xpath`s (`Excess/Standard`,
  `Excess/Imposed`, etc.) but **no `PURE table`/`PURE Field` populated for any of them** — unlike
  `BusinessBuildingsLimit`, which explicitly maps to `CBP_BUSINESSBUILDINGS.BBSUMPROTECTED`.
  `ImposedExcess`'s comment states *"This shall be editable by Underwriter"*; `GlassExcess`/`FloodExcess`
  are UI-conditional display fields, not source-mapped inputs.
- `Excess/Amount` isn't in PL101 at all. Manuscript shows it maps to `BuildingRiskSMEInput.ExcessAmount`,
  tied to DC-internal private comparison/referral logic (a `$1,000` threshold check against other
  excess inputs) — clearly DC-computed, not conversion's to populate.

All correct-by-design. No fix needed, not a gap.

---

## G-BP-70 — applies to SEQ 31

`BUILDING_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`, hardcoded
`AdjustmentSelection='1'` regardless of whether Pure recorded a percent or dollar adjustment) — already
tracked in the register for this SEQ. No new analysis needed here.

## Checked clean

- **SEQ 32** (`BP_LOC_BB_CLAUSE`) — by design, clause-only pass-through, no gap.
- **SEQ 30/33 overall** — no gaps found beyond the items above. No client tickets exist against the
  base Building line.
