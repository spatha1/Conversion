# SEQ 15-17 — Goods in Transit (GT) Coverage

| Seq | Name | Source view |
|---|---|---|
| 15 | BP_LINE_GT_UW | `LINE_GT_UW` |
| 16 | BP_LINE_GT_CLAUSE | `LINE_GT_CLAUSE` (by design, clause-only) |
| 17 | BP_LINE_GT | `LINE_GT_PAYLOAD` |

**Client tickets:** none found in either ATP-10219 export or the broader unfiltered export.

---

## G-BP-22 — DOWNGRADED, checked correct-by-design — GT line-level & STD_SD Indicator=1

Previously flagged as 2 hardcoded `<Indicator>1</Indicator>` (line-level, and `STD_SD` "Standard"
sub-coverage), with a scripted fix note to reuse `GOODSINTRANSIT_IND`. Checked against manuscript and
live data — same pattern as PPL (G-BP-18) and PF (G-BP-20):

- Manuscript: `GoodsInTransitInput.StandardPerilIndicator` (`STD_SD`/`Indicator`) `= ProductsInput.GoodsInTransit`
  — mirrors the overall "is the GT product/line taken" flag.
- Live check: `Line_GT_Coverage.GOODSINTRANSIT_IND` is **`1` for all 815 rows, no exceptions** — this
  staging table only contains policies that already have a GT line, so the flag is trivially always
  true.

Both hardcodes are correct-by-design for every record that can reach this view. The originally
proposed fix (reusing `{GOODSINTRANSIT_IND}`) would have been a no-op change wearing the shape of a
fix. No fix needed. Closing.

---

## Investigated and ruled out — `GTINLANDSHIPLIMIT` looked like a dropped field, isn't one

`LINE_GT_PAYLOAD` exposes a `GOODSINTRANSIT_IND` and a `GTINLANDSHIPLIMIT` column that SEQ 17's
config never references at all. Live data shows `GTINLANDSHIPLIMIT` is non-zero for 814 of 815 rows
(99.9%) — enough to look, at first pass, like a real field silently dropped from the payload.

Traced against the SP and the client's original SAS
(`GoodsInTransit_LegalExpenses_TaxAudit_conversionscriptCapricorn.txt`) — both confirm
`GTInlandShipLimit` is explicitly commented `/*PURE Field for testing only*/` in both places: it's
the **raw, pre-banded** Pure value, kept in the staging table for diagnostic/QA comparison only. The
SP bands it into `BusinessContentAndStock` (10k/20k/30k/50k/75k/100k/150k buckets), and that derived
field **is** correctly wired into SEQ 17 (`{BUSINESSCONTENTANDSTOCK}` → `STD_SD`'s `<limit><iValue>`).

Checked the banding itself for a gap too — the SP's `CASE` has no `ELSE` above `150000`, which would
silently null out any raw value over that ceiling. Live data: **0 of 815 rows have a raw limit above
150000**, and **0 rows show a banding gap** (`BUSINESSCONTENTANDSTOCK=0` while the raw value is
non-zero). No live impact; not a bug in the current data, though the missing `ELSE` is a latent risk
if a larger value is ever recorded in Pure.

Also checked `EstimatedAnnualValue`'s source (`t3.GTInland`, an oddly-named field distinct from
`GTInlandShipLimit`) against the SAS — identical mapping in both, and live values look like genuine
dollar figures ($5,000-$1,000,000+ range), not a copy-paste field mix-up. Confirmed correct.

## Checked clean

- **SEQ 15** (`BP_LINE_GT_UW`) — G-BP-70 applies (1 of the 14 shared UW-adjustment views), same open
  business-decision-pending finding as `seq05-08_general_property.md`. No new analysis needed.
- **SEQ 16** (`BP_LINE_GT_CLAUSE`) — by design, clause-only pass-through, no gap.
- **SEQ 17** (`BP_LINE_GT`) — no gaps found. `HAZARDOUSGOODS`/`HAZARDOUSGOODSTRANSPORTED`/`ContentsAndStockTransported`
  mappings match the SAS exactly; no client tickets exist against this coverage.
