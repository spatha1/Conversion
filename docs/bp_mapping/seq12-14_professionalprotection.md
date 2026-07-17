# SEQ 12-14 — Professional Protection (PF) Coverage

| Seq | Name | Source view |
|---|---|---|
| 12 | BP_LINE_PF_UW | `LINE_PF_UW` |
| 13 | BP_LINE_PF_CLAUSE | `LINE_PF_CLAUSE` (by design, clause-only) |
| 14 | BP_LINE_PF | `LINE_PF_PAYLOAD` |

**Client tickets:** ATP-10843 — *"PF 'Is Previous PF in place' is incorrect in UI + Clarity"* —
**Resolved/Closed 2026-07-11**, after the view fix below was applied and verified live.

---

## G-BP-21 (ATP-10843) — CONFIRMED, real root cause found — SP CASE-condition inversion

**Symptom, confirmed against live data:** out of 4,655 PF policies, **zero** show
`PreviousProfessionalProtection = 'Yes'` in the final `LINE_PF_PAYLOAD` output — every single record
is `'No'`, even though Pure's raw data (`PIPREVPROTECTION`) shows 498 policies (10.7%) explicitly
answered "Yes."

**Root cause — a genuine logic bug in the SP**, not the view or config. `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql:5327-5332`:

```sql
CASE
     WHEN (t3.PIPrevProtection IS NOT NULL AND t3.PIPrevProtection <>2) THEN ''
     WHEN t3.PIPrevProtection = 1 THEN 'Yes'
     ELSE 'No'
END AS PreviousProfessionalProtection
```

The first `WHEN` is a superset of the second: any value that is not null and not `2` — which
includes `1` — matches the first branch and returns blank. `WHEN = 1 THEN 'Yes'` is dead code; it can
never be reached. The client's original SAS (`ProfessionalProtection_conversionscriptCapricorn.txt`)
has the correct, non-inverted version:

```sas
CASE WHEN PIPrevProtection IN (.,2) THEN ''
     WHEN PIPrevProtection = 1 THEN 'Yes'
     ELSE 'No' END AS PreviousProfessionalProtection
```

**Identical bug shape, 3 places in the SP:**

| Field | SP lines | Raw column | Live distribution | Consequence |
|---|---|---|---|---|
| `RetroactiveProtection` | 5316-5321 | `PIRetroactiveCover` | not separately checked | **No live impact** — `LINE_PF_PAYLOAD`'s `ROL_SD` indicator is independently re-derived from the raw `PIRETROACTIVECOVER` column, not from this broken computed column (see view below) |
| `PreviousProfessionalProtection` | 5327-5332 | `PIPrevProtection` | `2`→3,933, `1`→498, `0`→224 | **Confirmed: 498 of 4,655 (10.7%) wrongly show 'No' instead of 'Yes'** |
| `PreviousEvent` | 5333-5338 | `PIPrevClaimEvents` | `2`→3,933, `0`→722, **no `1` rows** | Same bug, **zero current live impact** — no policy in the dataset currently has `PIPrevClaimEvents=1`, but the bug is live-data-dependent, not logically inert |

The view compounds the SP bug: its own final-`SELECT` CASE (`WHEN PIDATE IS NOT NULL AND ... ='' THEN 'No' ... ELSE 'No'`)
collapses everything — blank or otherwise — to `'No'`, so the true "Yes" answers are lost twice over
before reaching DCT. Manuscript (`ProfessionalProtectionInput.PreviousProfessionalProtection`/`.PreviousEvent`)
confirms both are plain Yes/No dropdowns with no `PIDate` dependency, so that gating was never
manuscript-required — a secondary symptom, not the root cause.

**Fix:** `docs/bp_mapping/fixes/G-BP-21_fix.sql` — **view-only**. Re-derives both fields directly from
the raw `PIPREVPROTECTION`/`PIPREVCLAIMEVENTS` columns (the same pattern `LINE_PF_PAYLOAD` already
uses correctly for `PIRETROACTIVECOVER`→`RETROACTIVE_IND`), bypassing the SP's broken computed
columns entirely, and removes the non-manuscript-required `PIDATE` gate. No config change needed —
SEQ 14 already references `{PREVIOUSPROFESSIONALPROTECTION}`/`{PREVIOUSEVENT}` correctly. **Applied
live 2026-07-11, verified**: `LINE_PF_PAYLOAD.PREVIOUSPROFESSIONALPROTECTION` now returns `'No'`→3,933,
`'Yes'`→498, `''`→224 (previously 100% `'No'`) — the 498 previously-lost "Yes" answers are now
correctly surfacing. `PREVIOUSEVENT` unchanged at `'No'`→3,933, `''`→722, as expected (no policy
currently has the raw `1`/"Yes" value, so there was nothing to recover yet — the fix is still live
and correct for when one does).

**Also recommend fixing the SP at the source** (all 3 CASE blocks) since any other consumer reading
`Line_ProfessionalProtection_Coverage.RETROACTIVEPROTECTION`/`.PREVIOUSPROFESSIONALPROTECTION`/`.PREVIOUSEVENT`
directly — not through this view — would still see the bug. Not scripted here; SP changes go through
the SP SAI review-copy process (see `project_sp_sai_review.md`), not a direct view/config fix.

---

## G-BP-20 — DOWNGRADED, checked correct-by-design — PF line-level & STD_SD Indicator=1

Previously flagged as 2 hardcoded `<Indicator>1</Indicator>` (line-level, and `STD_SD` "Standard"
sub-coverage). Checked against manuscript and live data:

- Manuscript: `ProfessionalProtectionInput.StandardPerilIndicator` (`STD_SD`/`Indicator`) `= ProductsInput.ProfessionalProtection`
  — i.e., it mirrors the overall "is the Professional Protection product/line taken" flag, the same
  relationship PPL's `STB_SD`/`STD_SD` had to `ProtectionTypeStandard` (G-BP-18) — except here the
  driving flag is line-level, not a sub-selectable "Standard" option.
- Live check: `Line_ProfessionalProtection_Coverage.PROFESSIONAL_IND` is **`1` for all 4,655 rows,
  no exceptions** — this staging table only contains policies that already have a PF line, so the
  flag is trivially always true, exactly like PPL's `PRODUCTANDPUBLIC_IND` (G-BP-18's investigation).

Both hardcodes are correct-by-design for every record that can reach this view. No fix needed.
Closing.

---

## G-BP-70 — applies to SEQ 12

`LINE_PF_UW` is 1 of the 14 shared UW-adjustment views (source `Output_UWAdjust_BSP`, hardcoded
`AdjustmentSelection='1'` regardless of whether Pure recorded a percent or dollar adjustment). Same
open, business-decision-pending finding as documented in `seq05-08_general_property.md` — no new
analysis needed here, just confirming SEQ 12 is in scope.

## Checked clean

- **SEQ 13** (`BP_LINE_PF_CLAUSE`) — by design, clause-only pass-through, no gap.
