# BP Fix-Location Matrix — All 67 Sequences

Same shape as PP's seq-by-seq fix breakdown. **SP fix** = staging-level change in
`DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql`. **Config fix** = `ConversionConfig` template
(Azure). **View fix** = the Snowflake source view feeding that SEQ. `—` = no gap currently
registered against that SEQ. Gaps marked *(candidate)* are suspected but not yet confirmed to live
at that SEQ — listed for visibility, not as a settled finding.

| Seq | Name | SP fix | Config fix | View fix |
|---|---|---|---|---|
| 1 | BP_ACC_LOC | — | G-BP-67 | G-BP-67 |
| 2 | BP_Policy_AOI | G-BP-16 *(candidate — AOI record drop, not yet confirmed staging vs view)* | — | — |
| 3 | BP_account_info_claim_history | — | — | — |
| 4 | BP_Prior_INFO | — | — | — |
| 5 | BP_Line_GP_1_SpecifiedTools | — | — | — |
| 6 | BP_Line_GP_2_UW | — | — | — |
| 7 | BP_Line_GP_3_CLAUSE | — | *by design, not a gap* | — |
| 8 | BP_LINE_GP | — | G-BP-17 *(done, live)* | G-BP-17 *(blocking — view not yet deployed)* |
| 9 | BP_Line_PPL_1_UW | — | — | — |
| 10 | BP_Line_PPL_2_CLAUSE | — | *by design, not a gap* | — |
| 11 | BP_LINE_PPL | — | G-BP-18, G-BP-50 | G-BP-19 *(not traced)*, G-BP-49, G-BP-50 |
| 12 | BP_LINE_PF_UW | — | — | — |
| 13 | BP_LINE_PF_CLAUSE | — | *by design, not a gap* | — |
| 14 | BP_LINE_PF | — | G-BP-20 | G-BP-20, G-BP-21 *(not traced)* |
| 15 | BP_LINE_GT_UW | — | — | — |
| 16 | BP_LINE_GT_CLAUSE | — | *by design, not a gap* | — |
| 17 | BP_LINE_GT | — | G-BP-22 | — |
| 18 | BP_LINE_LE_UW | — | — | — |
| 19 | BP_LINE_LE_CLAUSE | — | *by design, not a gap* | — |
| 20 | BP_LINE_LE | — | G-BP-23 | — |
| 21 | BP_LINE_SV_UW | — | — | — |
| 22 | BP_LINE_SV_CLAUSE | — | *by design, not a gap* | — |
| 23 | BP_LINE_SV | — | G-BP-24 | G-BP-62 *(not traced)* |
| 24 | BP_LINE_CV_UW | — | — | — |
| 25 | BP_LINE_CV_CLAUSE | — | *by design, not a gap* | — |
| 26 | BP_LINE_CV | — | G-BP-25, G-BP-65 | G-BP-65 *(confirm data exists before scripting)* |
| 27 | BP_LINE_TA_UW | — | — | — |
| 28 | BP_LINE_TA_CLAUSE | — | *by design, not a gap* | — |
| 29 | BP_LINE_TA | — | G-BP-26 | — |
| 30 | BP_Building_SubCov | — | — | — |
| 31 | BP_BUILDING_UW | G-BP-14 *(candidate — BB not explicitly named in the cross-cutting UW finding, check when reached)* | — | — |
| 32 | BP_LOC_BB_CLAUSE | — | *by design, not a gap* | — |
| 33 | BP_RISK_Building_Cov_Building | — | — | — *(G-BP-45: reviewed, no fix)* |
| 34 | BP_Risk_Building_BI_Subcov | — | G-BP-27 | G-BP-27 |
| 35 | BP_Risk_Building_BI_UW | G-BP-14 *(candidate — one of the 4 named UW screens)* | — | — |
| 36 | BP_LOC_BI_CLAUSE | — | *by design, not a gap* | — |
| 37 | BP_RISK_Building_BI | — | G-BP-28 | G-BP-28 |
| 38 | BP_Risk_Building_BG_Subcov | — | — | G-BP-01 *(not yet drafted — needs NZ conditional)*, G-BP-51 *(scripted)* |
| 39 | BP_RISK_BUILDING_BG_UW | G-BP-14 *(candidate — one of the 4 named UW screens)* | — | — |
| 40 | BP_LOC_BG_CLAUSE | — | *by design, not a gap* | — |
| 41 | BP_RISK_Building_BG | — | — | — |
| 42 | BP_Risk_Building_Money_Subcov | — | — | G-BP-04 *(needs client confirm)*, G-BP-05 |
| 43 | BP_RISK_BUILDING_MY_UW | G-BP-14 *(candidate — one of the 4 named UW screens)* | — | — |
| 44 | BP_LOC_MY_CLAUSE | — | *by design, not a gap* | — |
| 45 | BP_RISK_Building_Money | — | — | — |
| 46 | BP_Risk_Building_EN_Subcov | — | — | *unregistered finding — hardcoded `Indicator='1'` across all branches, same pattern as G-BP-01/50 class, never assigned a gap ID, see note below* |
| 47 | BP_RISK_BUILDING_EN_UW | G-BP-14 *(candidate — one of the 4 named UW screens)* | — | — |
| 48 | BP_LOC_EN_CLAUSE | — | *by design, not a gap* | — |
| 49 | BP_RISK_Building_EN | — | — | G-BP-52 *(not traced)* |
| 50 | BP_Risk_Building_BC_Subcov | — | — | G-BP-02, G-BP-03, *(Contents 30k hardcode — fixed live, no G-BP ID assigned)* |
| 51 | BP_RISK_BUILDING_BC_UW | — | — | — |
| 52 | BP_LOC_BC_CLAUSE | — | *by design, not a gap* | — |
| 53 | BP_RISK_Building_BC | — | G-BP-29 | G-BP-29 |
| 54 | BP_RISK_LOCATION_UW_COMBINE | G-BP-14 *(candidate — combines the 4 UW screens above, worth checking first since it's the single downstream point)* | — | — |
| 55 | BP_RISK_Building | — | — | G-BP-12, G-BP-33 *(confirm-only)* |
| 56 | BP_fleet_coverage_Vehicle_SubCov | — | G-BP-30 | G-BP-30 |
| 57 | BP_Fleet_Vehicle_coverage | — | G-BP-53/54 *(blocked, no source data)* | G-BP-55 *(scripted)*, G-BP-53/54 *(blocked)*, ATP-11127 remainder *(FuelType/PowerKW/TrackRear/VehicleType/DriveDescription/ImportType — not yet drafted)* |
| 58 | BP_FL_MOTOR_EXCESS | — | — | — |
| 59 | BP_FL_Motor_Clauses | G-BP-38 *(candidate — same `SCHEDULE_CLAUSES_TEMPLATE` source as the confirmed CM dedup issue)* | — | — |
| 60 | BP_FL_Motor_UW | — | — | — |
| 61 | BP_Fleet_Vehicle_main | — | — | G-BP-48 *(downgraded — likely not a real gap, see README)* |
| 62 | BP_CV_Vehicle_SubCov | — | G-BP-31 | G-BP-31, G-BP-32 *(investigating)* |
| 63 | BP_CV_vehicle_Cov | — | — | — *(G-BP-47: reviewed, no fix)* |
| 64 | BP_CV_MOTOR_EXCESS | — | — | — |
| 65 | BP_CV_Motor_Clauses | G-BP-06, G-BP-38 *(candidate — this is exactly where the confirmed CM dedup silently drops a vehicle's second clause)* | — | — |
| 66 | BP_CV_Motor_UW | G-BP-06 *(candidate — RIDESHARE/CONTRACTRESTRICTION/HIREVEHDRIVERSUPPLIED are the exact fields the dedup was shown to corrupt)*, G-BP-39 | — | — |
| 67 | BP_CV_Vehicle_main | — | — | G-BP-07 *(needs confirm)*, G-BP-08 *(needs confirm)*, G-BP-09, G-BP-10 *(blocked)*, G-BP-11 *(code-only, no decision needed)*, G-BP-56 *(not traced)*, G-BP-57 *(not traced)*, G-BP-58 *(blocked)*, G-BP-59 *(not traced)* |

## Note — SEQ 46 finding with no gap ID

`RISK_BUILDING_EN_COVERAGES` has the same hardcoded `Indicator='1'` pattern across all branches
(CWS_SD Car Wash, DET_SD Deterioration of Stock, ICW_SD Increased Cost of Working, MAC_SD
Machinery) that was already fixed for BG (G-BP-38... actually G-BP-01/51's view) and BC
(G-BP-02/03/29). This was mentioned in an earlier pass (`project_bp_indicator_fixes.md` /
`project_atp10219_bp_triage.md` memory) but never got its own `G-BP-` number in this register —
should be assigned before the SEQ 46 gap-by-gap pass, not left implicit.

## Cross-cutting rows worth investigating together, not one-by-one

- **G-BP-14** appears as a *(candidate)* on 5 rows (31, 35, 39, 43, 47) plus the combine step (54).
  If the root cause really is one shared block (PP's PR-04 shape), checking SEQ 54
  (`RISK_LOCATION_UW_COMBINE`, the single downstream point all four feed into) or the SP's shared UW
  section first would settle all 5 at once rather than tracing each screen independently.
- **G-BP-06 / G-BP-38** appears as a *(candidate)* on rows 59, 65, 66. The CM dedup bug is already
  confirmed (`CM_02`→`CM_03`); this flags where its downstream damage likely surfaces (Fleet clauses,
  CM clauses, CM UW answers) — worth checking these three views' output against the dedup fix once
  that's applied, rather than treating them as independent gaps.

## Summary counts (of the 67 configs)

| Category | Count |
|---|---|
| Has a confirmed, scripted fix (view and/or config) ready to deploy | 13 (seqs 1, 8*, 11, 14, 17, 20, 23, 25→26, 29, 34, 37, 53, 56, 62) |
| Has an identified gap but blocked on client/business input | 6 (seqs 11 G-BP-19, 42, 57 G-BP-53/54, 67 G-BP-10/58) |
| Has an identified gap, root cause not yet traced | ~14 |
| Candidate cross-cutting gap, not yet confirmed at this SEQ | 9 |
| No gap currently registered | remainder (~34) — **not the same as "clean," most of these have not had a PL101/manuscript check yet, only the mechanical empty-tag/hardcode sweep** |

*8 = config already live but currently broken pending the view deploy — see G-BP-17.
