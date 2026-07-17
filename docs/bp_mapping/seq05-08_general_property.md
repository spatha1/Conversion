# SEQ 5-8 — General Property (GP) Coverage

| Seq | Name | Source view |
|---|---|---|
| 5 | BP_Line_GP_1_SpecifiedTools | `LINE_GP_SPECIFIEDTOOLS` |
| 6 | BP_Line_GP_2_UW | `LINE_GP_UW` |
| 7 | BP_Line_GP_3_CLAUSE | `LINE_GP_CLAUSE` (by design, clause-only) |
| 8 | BP_LINE_GP | `LINE_GP_PAYLOAD` |

**Client tickets:** none found directly on GP. The UW-adjustment finding below (G-BP-70) is a
cross-cutting pattern shared with G-BP-14's tickets (ATP-1395, ATP-1399, ATP-1396), none of which
name GP specifically.

---

## G-BP-17 — RESOLVED, verified live 2026-07-10

Previously flagged as "config live but view not deployed, currently broken." Re-checked:
`LINE_GP_PAYLOAD` now produces `UNSPECIFIEDTOOLSLIMIT_INDICATOR`, `UNSPECIFIEDSTOCKLIMIT_INDICATOR`,
`SPECIFIEDTOOL_INDICATOR` — matches the config template exactly. No longer blocked.

---

## G-BP-70 — UW Adjustment type mislabeled across all 14 coverage screens (needs business decision)

**Scope:** SEQ 6, 9, 12, 15, 18, 21, 24, 27, 31, 35, 39, 43, 47, 51 — every BP UW-adjustment view
(GP, PPL, PF, GT, LE, SV, CV, TA, BI, BG, MY, EN, BC, BB), confirmed via live `GET_DDL` scan: all
source `AGGNE.DEV.Output_UWAdjust_BSP`, all hardcode `RECURRINGINDICATOR='1'`, differing only by
`WHERE COVERAGE='XX'`.

**Root cause chain (SP, `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql`):**
```
<coverage>_ADJUST (16 tables, one per coverage)
  -> Adjustments_BSP_A   -- UNION ALL, WHERE AJAdjustmentPercent <> 0
  -> Adjustments_BSP_B   -- SUM(AJAdjustmentPercent) per policy/coverage
  -> Adjustments_BSP     -- FULL OUTER JOIN A+B
  -> ADJUSTMENTS_BSP_OUT -- UWAdjust = (ExpPremium / (100+SUM_Adjustments)) * AJAdjustmentPercent
  -> Output_UWAdjust_BSP -- final: PolicyNumber, ExpiringID_P, CMLNumber, Vehicle_ID, Coverage,
                            UWAdjustNote, UWAdjustAmount only (no recurring flag, no percent/$ type)
```
Every adjustment that survives is reverse-calculated to a dollar-equivalent figure from a
percentage. The 14 downstream views then hardcode `AdjustmentSelection='1'` ($) unconditionally.

**Client's original SAS design differs** (`Generalproperty_conversionscriptCapricorn.txt`,
`CBP_ADJUSTMENTSGP`):
```sas
AdjustmentSelection =
  CASE WHEN AJAdjustmentValue=0 AND AJAdjustmentPercent=0 THEN '%'
       WHEN (AJAdjustmentValue=. OR =0) AND AJAdjustmentPercent<>0 THEN '%'
       WHEN AJAdjustmentValue<>0 AND (AJAdjustmentPercent=. OR =0) THEN '$'
       ELSE '' END
```
The client's design preserves the original entered type and value; the current Snowflake pipeline
normalizes everything to a computed dollar figure.

**Checked against G-BP-14 — does NOT explain it.** I initially suspected the `WHERE
AJAdjustmentPercent <> 0` filter in `Adjustments_BSP_A` was silently dropping dollar-only
adjustments and explained the "not populating" client complaints. Checked live data across all 16
`_ADJUST` source tables:

| Table | Total | Percent-based (survives) | Dollar-only (dropped) |
|---|---|---|---|
| BB_ADJUST | 1,090 | 955 | 0 |
| BC_ADJUST | 1,716 | 1,566 | 0 |
| BI_ADJUST | 1,021 | 977 | 1 |
| CM_ADJUST | 6,343 | 4,707 | 0 |
| CV_ADJUST | 559 | 515 | 0 |
| EN_ADJUST | 149 | 129 | 0 |
| GP_ADJUST | 126 | 114 | 0 |
| GT_ADJUST | 8 | 7 | 0 |
| LE_ADJUST | 5 | 2 | 0 |
| MY_ADJUST | 120 | 99 | 0 |
| PF_ADJUST | 23 | 22 | 0 |
| PP_ADJUST | 2,945 | 2,237 | 0 |
| TA_ADJUST | 5 | 4 | 0 |
| SV_ADJUST | 646 | 397 | 0 |
| BG_ADJUST | 405 | 354 | 0 |
| SU_ADJUST_BSP | 2,452 | 575 | 0 |

**Total dollar-only adjustments dropped: 1**, out of ~16,600 rows. Negligible. The remaining gap
between "total" and "percent-based" in each table is rows where both value and percent are 0 (no
real adjustment recorded) — correctly excluded, not a bug.

**What this finding actually is:** a confirmed type-labeling divergence from the client's original
design (every adjustment shown as '$' even when Pure recorded it as '%'), not a data-loss bug. Real
impact depends on whether DC's UI/rating treats a mislabeled '%'-as-'$' adjustment differently
(e.g. a 10% discount incorrectly read as a $10 discount would be materially wrong; if DC just
displays the already-computed dollar figure regardless of the label, impact may be cosmetic only).

**Status:** Open. Needs a business/product decision — confirm with Aggne policy team whether the
dollar-normalization is intentional before treating this as a fix candidate. Not a code-only fix
like G-BP-16a/c — changing behavior here affects all 14 screens at once and changes what data DC
receives, not just how it's labeled.

---

## Still open — not deep-dived this pass

- **RECURRINGINDICATOR hardcode** (`'1'` always, view filters on `UWADJUSTNOTE IS NOT NULL` instead
  of replicating the SAS's `WHERE AJRecurringIndicator=1`): matches a concern already raised for
  FL/CV_MOTOR_UW in `project_bp_dev_review.md` (dev rejected a fix, kept `'1'`, added a NULL-note
  filter instead — same shape found here independently). Whether this causes real ghost-adjustment
  risk on re-conversion needs the same live-data check applied to `Output_UWAdjust_BSP` that was
  applied to `_ADJUST` above — not yet done.
- **G-BP-14's true root cause** — still unidentified. Next candidate: the `ExpPremium_BSP` /
  `Adjustments_BSP` join in `ADJUSTMENTS_BSP_OUT` (keyed on `ExpiringID_P`+`Coverage`+`Vehicle_ID`+
  `cmlnumber`) for silent match failures.
- **SEQ 5 SpecifiedTools `VALUE='0'`**: 1,410 of 6,101 rows (23%). Not yet checked against manuscript
  whether 0 is a legitimate specified-tool value or should be blank/omitted.

## Checked clean

- `GeneralPropertyOutput.CurrentActiveSpecifiedTools` (SEQ 8's empty tag) — manuscript confirms this
  is a UI-workflow-state output field DC manages itself (set via `SetDisableFlagTrue`-style
  triggers), not a conversion gap.
