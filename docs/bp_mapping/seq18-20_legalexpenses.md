# SEQ 18-20 — Legal Expenses (LE) Coverage

| Seq | Name | Source view |
|---|---|---|
| 18 | BP_LINE_LE_UW | `LINE_LE_UW` |
| 19 | BP_LINE_LE_CLAUSE | `LINE_LE_CLAUSE` (by design, clause-only) |
| 20 | BP_LINE_LE | `LINE_LE_PAYLOAD` |

**Client tickets:** none found in either ATP-10219 export or the broader unfiltered export.

---

## G-BP-23 — DOWNGRADED, checked correct-by-design — LE line-level Indicator=1

Previously flagged as 1 hardcoded `<Indicator>1</Indicator>`, with a scripted fix note to reuse
`LEGALEXPENSES_IND`. Live config check found `STD_SD`'s `<Indicator>` **already correctly wired**
to `{LEGALEXPENSES_IND}` — only the line-level `<Indicator>1</Indicator>` (right before `{LINE_LE_CLAUSE}`)
is the literal hardcode, same shape as PPL/PF/GT's line-level indicators.

- Live check: `Line_LE_Coverage.LEGALEXPENSES_IND` is **`1` for all 1,600 rows, no exceptions** — same
  pattern as G-BP-18/G-BP-20/G-BP-22: this staging table only contains policies that already have an
  LE line, so the flag is trivially always true.

Correct-by-design for every record that can reach this view. No fix needed. Closing.

---

## Checked clean — no CASE-inversion bug (unlike PF)

Given G-BP-21 found a genuine CASE-condition inversion bug in the SP for PF's Yes/No fields
(`PreviousProfessionalProtection`/`PreviousEvent`), checked the equivalent LE fields
(`LegalDisputeActions`/`Redundancies`) for the same bug shape. **Clean** —
`DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql:5055-5067` uses the correct, non-inverted pattern:

```sql
CASE
     WHEN t3.LELegalDispute IN (NULL,2) THEN ''
     WHEN t3.LELegalDispute = 1 THEN 'Yes'
     ELSE 'No'
END AS LegalDisputeActions
```

Live data confirms real variance reaches the final payload: `LEGALDISPUTEACTIONS` — 'No'→1,584,
'Yes'→16; `REDUNDANCIES` — 'No'→1,598, 'Yes'→2. Both fields work correctly.

Also checked `LegalExpensesLimit`'s banding (10k/25k/50k/75k/100k/150k/200k) for the same
missing-`ELSE`-above-ceiling risk found in GT (G-BP-22 investigation) — **no live impact**: 0 of
1,600 rows have a zero/blank limit, max value in the data is $100,000, well under the $200,000
banding ceiling.

## Checked clean

- **SEQ 18** (`BP_LINE_LE_UW`) — G-BP-70 applies (1 of the 14 shared UW-adjustment views), same open
  business-decision-pending finding as `seq05-08_general_property.md`. No new analysis needed.
- **SEQ 19** (`BP_LINE_LE_CLAUSE`) — by design, clause-only pass-through, no gap.
- **SEQ 20** (`BP_LINE_LE`) — no gaps found. No client tickets exist against this coverage.
