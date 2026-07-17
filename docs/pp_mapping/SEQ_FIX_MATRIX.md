# PP Gap Fix Matrix — by Sequence and Layer

Every gap (G-01...G-46) mapped to its ETL sequence and the layer(s) it needs fixing at. Format per
cell: `G-N (Bug#)` — Bug# is the client-reported Jira ticket where one exists (from
`CLIENT_TICKET_MAPPING.md`); blank/— means internally-found only, no client ticket behind it.

Status is not repeated here — see `GAP_CATEGORIZATION.md` for need-input / can-fix-now / held /
False-Positive per gap. This matrix only answers "which seq, which layer."

| Seq | Name | SP fix | Config fix | View fix |
|---|---|---|---|---|
| 1 | Claim History (account_info_claim_history) | — | — | G-15, G-16 |
| 2 | Prior Insurance (Prior_INFO) | — | — | G-17 |
| 3 | Account Location (ACC_LOC) | G-43 | — | — |
| 4 | HB Sub-Coverages (Building_SubCov) | — | — | G-18 (Landlords part) |
| 5 | HB UW Adjustments (BUILDING_UW) | G-19 (new finding) | — | G-20 |
| 6 | HB Clauses (HB_CLAUSE) | — | — | G-21 |
| 7 | Risk Building HB (RISK_Building_HB) | — | G-23, G-24 | G-22, G-26 |
| 8 | HC Items Exceeding (HC_exceed_values) | — | — | G-21 |
| 9 | HC Specified Contents (HC_Specified_Contents) | — | — | G-21, G-27 |
| 10 | HC Sub-Coverages (Building_SubCov) | — | — | G-18 (Flood/ALD/structural part) |
| 11 | HC UW Adjustments (BUILDING_UW) | G-19 (new finding) | — | — |
| 12 | HC Clauses (LOC_HC_CLAUSE) | — | — | G-21 |
| 13 | Risk Building HC (RISK_Building_HC) | — | G-28, G-29, G-30, G-31, G-32 | G-40 (ATP-11107) |
| 14 | Risk Building — outer (RISK_Building) | G-41 | G-33, G-34, G-35 | G-21, G-36 |
| 15 | Motor Sub-Coverages (Risk_CM) | — | — | G-37 |
| 16 | Motor UW Adjustments (PER_PM_BUILDING_UW) | G-19 (new finding) | — | — |
| 17 | Motor Clauses (COM_CLAUSE) | G-38 (Part 1 + 2) | — | G-21, G-39 |
| 18 | Risk Building PM — Motor (RISK_Building_PM) | G-03 (ATP-10963), G-05 (ATP-10963), G-06 (ATP-10963), G-07, G-09 (ATP-10963), G-10 (ATP-10963), G-11 | G-13 | G-01, G-02, G-04 (False Positive), G-08, G-12, G-42 |

## Cross-cutting / not tied to a single seq (Post-Load, final XML)

These sit downstream of all 18 seqs, in `PER_CONVERSION_FINAL_LOAD` / `PER_CONVERSION_FINAL_XML` —
not a seq-specific fix.

| Layer | Gaps |
|---|---|
| SP (Final Load) | G-44 (Account Handler), G-45 (ATP-10962, Legacy Start Date) |
| SP (structural, protection-selection logic — likely Pure-to-Write) | G-46 |

## Notes on multi-seq / multi-part gaps

- **G-18** splits across two seqs because the same Landlords/Flood/ALD/structural Indicator pattern
  repeats in both the HB (seq 4) and HC (seq 10) sub-coverage blocks.
- **G-19** (new finding — non-recurring UW adjustments excluded) repeats identically across all
  three UW-adjustment seqs: HB (5), HC (11), Motor (16) — same root cause, one fix needed in each.
- **G-21** (XML-escaping free text) is explicitly cross-cutting across 6 seqs (6, 8, 9, 12, 14, 17)
  per the original validation note — one shared helper fix, applied everywhere it's used.
- **G-38** has two parts at the same seq (17): Part 1 (SP, case-preservation, can fix now) and
  Part 2 (SP, CM_*→PM_* mapping table, needs input) — both SP layer, listed together.
- **G-14** (seq 18, Clauses — CM_*/FV_* codes disabled in PP): superseded by **G-38** at seq 17,
  which covers the same clause-code problem more thoroughly. No separate fix needed for G-14 — it's
  folded into G-38's fix, not a distinct row in this matrix.

## Corrections made after building the `seq_fixes/` folder and re-checking live

- **G-15, G-16 (seq 1) and G-17 (seq 2) were missing from the original version of this table** —
  an omission, not a real "no gaps" state. Confirmed both sections exist in `VALIDATION_RULES.md`
  ("### Seq 1 — Claim History" and "### Seq 2 — Prior Insurance") with real fix files
  (`fixes/G-15_fix.sql`, `G-16_fix.sql`, `G-17_fix.sql`) already drafted. The `seq_fixes/` folder
  had these placed correctly from the start (it was built from the gap-level source docs, not from
  this matrix) — only this table was stale.
- **G-01 moved from seq 7 → seq 18**, and from Config → View. Live-checked the seq 7
  `PP_ConversionConfig` template directly — no `<State>` tag or literal "NSW" appears in it at all,
  confirming State is a straight `PM_03`/`PER_COM_PAYLOAD` view column (Motor, seq 18), not a seq 7
  config template literal as originally filed.
