# SEQ 27-29 — Tax Audit (TA) Coverage

| Seq | Name | Source view |
|---|---|---|
| 27 | BP_LINE_TA_UW | `LINE_TA_UW` |
| 28 | BP_LINE_TA_CLAUSE | `LINE_TA_CLAUSE` (by design, clause-only) |
| 29 | BP_LINE_TA | `LINE_TA_PAYLOAD` |

**Client tickets:** none found in either ATP-10219 export or the broader unfiltered export. Everything
in this card is self-identified — the client has not reported any of it yet.

---

## G-BP-26 — DOWNGRADED, checked correct-by-design — TA line-level & STD_SD Indicator=1

Previously flagged as 2 hardcoded `<Indicator>1</Indicator>` (line-level, and `STD_SD` "Standard"
sub-coverage), with a scripted fix note to reuse `TAXAUDIT_IND`. Checked against manuscript and live
data — same pattern as every other coverage's line-level indicator this session:

- Manuscript: `TaxAuditInput.StandardPerilIndicator` (`STD_SD`/`Indicator`) `= ProductsInput.TaxAudit`
  — mirrors the overall "is TA line taken" flag.
- Live check: `Line_TA_Coverage.TAXAUDIT_IND` is **`1` for all 2,162 rows, no exceptions** — this
  staging table only contains policies that already have a TA line, so the flag is trivially always
  true.

Both hardcodes are correct-by-design for every record that can reach this view. No fix needed. Closing.

---

## G-BP-72 (new) — 3 required fields with zero Pure source: SumInsured, ListOfDirectors, PreviousTaxAudit

While checking SEQ 29's other bare empty tags (`<ListOfDirector/>`, `<PreviousTaxAudit/>`, `<SumInsured/>`),
found this is **not** the same as the harmless "testing only" columns found in GT/SV — these three are
manuscript fields marked `required` whenever the TA line is taken, and the TA line is taken for
**100% of the 2,162 Tax Audit records** in the current dataset (`TAXAUDIT_IND=1` always):

| Field | Manuscript definition | Pure source found? |
|---|---|---|
| `TaxAuditInput.SumInsured` (`SumInsured`) | Dropdown: `$10000`/`$20000`/`$50000`/`0`, `required` when `Indicator=true` | **None.** Not a formula, not derived from anything — a standalone required input with no `value`/`default` rule tying it to `TaxAuditLimit` or any other field. Note the dropdown's valid values ($10k/$20k/$50k/0) don't even overlap with `TaxAuditLimit`'s own banding ($10k/$25k/$50k/$75k/$100k/$150k/$200k), so `{TAXAUDITLIMIT}` can't be safely reused here even as an approximation — it would send invalid dropdown values for most policies. |
| `TaxAuditInput.ListOfDirectors` (`ListOfDirector`) | Free-text string, `required` when `Indicator=true` | **None.** |
| `TaxAuditInput.PreviousTaxAudit` (`PreviousTaxAudit`) | Boolean Yes/No, `default value="0"`, `required` | **None.** Unlike CV's Hail/Malicious field, there's no `onChange`/cross-screen-sync rule here — this looks like a genuine standalone question with no computed fallback at all. |

**Confirmed via the SP**: `cbp_taxaudit` (Pure's entire Tax Audit source table) only exposes `TALimit`,
`TATaxNotification`, `TATaxInvestigation`, `TATaxInvesDetails`, `TAVoluntary` — matches the client's
original SAS (`GoodsInTransit_LegalExpenses_TaxAudit_conversionscriptCapricorn.txt`) exactly, so this
isn't a regression from the Snowflake port; these three fields were never captured by the original
design either.

**Why this is worth flagging even though no ticket exists yet**: `required` fields sent blank on
every single Tax Audit policy (100% of 2,162 records, not an edge case) is a materially different risk
profile than a single optional field like CV's Hail excess — if DC enforces `required` at
import/validation time rather than just at UI-entry time, this could be silently failing or
defaulting in a way nobody has surfaced yet precisely because it affects every policy uniformly
rather than showing up as a comparison mismatch.

**No fix possible without the client** — same as G-BP-65/G-BP-71, there's no source data anywhere to
wire in. Recommend raising proactively rather than waiting for a ticket: does Pure capture Tax Audit
director names / previous-audit history / sum insured under any field we haven't found, or does the
business intend these to stay blank/default post-conversion?

---

## G-BP-70 — applies to SEQ 27

`LINE_TA_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`, hardcoded
`AdjustmentSelection='1'` regardless of whether Pure recorded a percent or dollar adjustment). Same
open, business-decision-pending finding as documented in `seq05-08_general_property.md` — no new
analysis needed here, just confirming SEQ 27 is in scope.

## Checked clean

- **SEQ 28** (`BP_LINE_TA_CLAUSE`) — by design, clause-only pass-through, no gap.
