# ConversionConfig — SEQ-wise vs. Client Issues

Live from `Capricorn-Dev-SwiftConversion.dbo.ConversionConfig` (`aggneswiftconversion-dev.database.windows.net`),
confirmed 2026-07-10 — 67 active rows, no drift from the baseline used throughout this register.
`ModifiedOn`/`ModifiedBy` are `NULL` on all 67 rows (including SEQ 8, whose token fix was applied
earlier this session) — that column doesn't appear to get populated by whatever process runs these
updates, not evidence the change didn't take; SEQ 8's live state was independently re-verified by
reading the script back.

**Coverage caveat (found 2026-07-10 while building the SEQ 1 card):** the "Tickets" column below is
built entirely from two ATP-10219 exports, both filtered to `assignee IN (Raju Kallepelli, saichand
patha)`. ATP-10587 (SEQ 1, unassigned) was found only by accident, via a broader search of
`files/PP_Policy_Conversion_Issues_Export.html`, which isn't assignee-scoped. This means other rows
here may also be missing unassigned or differently-assigned tickets — the table hasn't been
re-audited against the full unfiltered ATP-10219 epic. Treat "—" in the Tickets column as "none
found in the two exports we have," not "none exist."

| Seq | ScriptName | Source view | Target table | Tickets | Gap(s) |
|---|---|---|---|---|---|
| 1 | BP_ACC_LOC | ACCOUNT_LOC | ACCOUNT_LOC_TARGET | ATP-10587 *(closed)*, ATP-11145 *(verified not our bug)* | G-BP-67, G-BP-68, G-BP-69 *(fixed live)* |
| 2 | BP_Policy_AOI | AOI_FINAL | AOI_Target | ATP-6221, ATP-10980 *(fixed live)*, ATP-10586 | G-BP-16a *(fixed live)*, G-BP-16b, G-BP-16c *(fixed live)* |
| 3 | BP_account_info_claim_history | VW_CLAIM_HISTORY | CLAIM_HISTORY_TARGET | none found | none — checked clean, see `seq03_claim_history.md` |
| 4 | BP_Prior_INFO | VW_CBP_COMPETITOR_INFORMATION | COMPETITOR_INFORMATION_TARGET | none found | none — checked clean, see `seq04_prior_insurance.md` |
| 5 | BP_Line_GP_1_SpecifiedTools | LINE_GP_SPECIFIEDTOOLS | LINE_GP_Target | — | Value=0 rate unconfirmed, see `seq05-08_general_property.md` |
| 6 | BP_Line_GP_2_UW | LINE_GP_UW | LINE_GP_Target | — | G-BP-70 (1 of 14 shared UW-adjustment views) |
| 7 | BP_Line_GP_3_CLAUSE | LINE_GP_CLAUSE | LINE_GP_Target | — | *by design* |
| 8 | BP_LINE_GP | LINE_GP_PAYLOAD | LINE_GP_Target | — | G-BP-17 *(resolved, verified live)* |
| 9 | BP_Line_PPL_1_UW | LINE_PPL_UW | LINE_PPL_Target | — | G-BP-70 |
| 10 | BP_Line_PPL_2_CLAUSE | LINE_PPL_CLAUSE | LINE_PPL_Target | — | *by design* |
| 11 | BP_LINE_PPL | LINE_PPL_PAYLOAD | LINE_PPL_Target | ATP-10845 *(traced, no defect found)* | G-BP-18 *(fixed live, verified)*, G-BP-50 *(fixed live, verified)*, G-BP-49 *(closed, correct-by-design)*, G-BP-19 *(traced, no fix)* |
| 12 | BP_LINE_PF_UW | LINE_PF_UW | LINE_PF_Target | — | G-BP-70 |
| 13 | BP_LINE_PF_CLAUSE | LINE_PF_CLAUSE | LINE_PF_Target | — | *by design* |
| 14 | BP_LINE_PF | LINE_PF_PAYLOAD | LINE_PF_Target | ATP-10843 *(resolved/closed)* | G-BP-20 *(closed, correct-by-design)*, G-BP-21 *(fixed live, verified, P1)* |
| 15 | BP_LINE_GT_UW | LINE_GT_UW | LINE_GT_Target | — | G-BP-70 |
| 16 | BP_LINE_GT_CLAUSE | LINE_GT_CLAUSE | LINE_GT_Target | — | *by design* |
| 17 | BP_LINE_GT | LINE_GT_PAYLOAD | LINE_GT_Target | — | G-BP-22 *(closed, correct-by-design)* — checked clean overall, see `seq15-17_goodsintransit.md` |
| 18 | BP_LINE_LE_UW | LINE_LE_UW | LINE_LE_Target | — | G-BP-70 |
| 19 | BP_LINE_LE_CLAUSE | LINE_LE_CLAUSE | LINE_LE_Target | — | *by design* |
| 20 | BP_LINE_LE | LINE_LE_PAYLOAD | LINE_LE_Target | — | G-BP-23 *(closed, correct-by-design)* — checked clean overall, see `seq18-20_legalexpenses.md` |
| 21 | BP_LINE_SV_UW | LINE_SV_UW | LINE_SV_Target | — | G-BP-70 |
| 22 | BP_LINE_SV_CLAUSE | LINE_SV_CLAUSE | LINE_SV_Target | — | *by design* |
| 23 | BP_LINE_SV | LINE_SV_PAYLOAD | LINE_SV_Target | ATP-10842 *(blocked on client clarification)* | G-BP-24 *(fixed live, verified, P1)*, G-BP-71 *(new, no fix — needs client input)*, G-BP-62 *(fix ready, blocked — dollar constants need client/DC confirmation)* |
| 24 | BP_LINE_CV_UW | LINE_CV_UW | LINE_CV_Target | — | G-BP-70 |
| 25 | BP_LINE_CV_CLAUSE | LINE_CV_CLAUSE | LINE_CV_Target | — | *by design* |
| 26 | BP_LINE_CV | LINE_CV_PAYLOAD | LINE_CV_Target | ATP-10904 *(casing bug fixed live; data-source question still needs client input)* | G-BP-25 *(closed, correct-by-design)*, G-BP-65 *(casing fixed live, verified; value still needs client input)* |
| 27 | BP_LINE_TA_UW | LINE_TA_UW | LINE_TA_Target | — | G-BP-70 |
| 28 | BP_LINE_TA_CLAUSE | LINE_TA_CLAUSE | LINE_TA_Target | — | *by design* |
| 29 | BP_LINE_TA | LINE_TA_PAYLOAD | LINE_TA_Target | none found — self-identified only | G-BP-26 *(closed, correct-by-design)*, G-BP-72 *(new, no fix — needs client input, no ticket yet)* |
| 30 | BP_Building_SubCov | BUILDING_SUBCOVERAGES | BUILDING_Target | none found | checked clean — Landslide NZ rule verified correct, `>1` vs `>0` comparison confirmed zero live impact, see `seq30-33_building_base.md` |
| 31 | BP_BUILDING_UW | BUILDING_UW | BUILDING_Target | — | G-BP-70, G-BP-14 *(root cause still open)* |
| 32 | BP_LOC_BB_CLAUSE | LOC_BB_CLAUSE | BUILDING_Target | — | *by design* |
| 33 | BP_RISK_Building_Cov_Building | BUILDING_PAYLOAD | BUILDING_Target | none found | G-BP-45 *(closed, correct-by-design)* — Excess sub-tags checked against PL101, correct-by-design, see `seq30-33_building_base.md` |
| 34 | BP_Risk_Building_BI_Subcov | RISK_BUILDING_BI_COVERAGES | RISK_BUILDING_BI_TARGET | — | G-BP-27 *(fixed live, verified, P1 — 80.3% of ACR_SD rows corrected)*, G-BP-77 *(missing active-term filter, fixed 2026-07-11 — 23.9% of BI policies exposed)* |
| 35 | BP_Risk_Building_BI_UW | RISK_BUILDING_BI_UW | RISK_BUILDING_BI_TARGET | ATP-1399 (BI) | G-BP-70, G-BP-14 *(root cause still open)* |
| 36 | BP_LOC_BI_CLAUSE | LOC_BI_CLAUSE | RISK_BUILDING_BI_TARGET | — | *by design* |
| 37 | BP_RISK_Building_BI | BUILDING_BI_PAYLOAD | RISK_BUILDING_BI_TARGET | ATP-10775 | G-BP-28 *(closed, correct-by-design)*, G-BP-73 *(fixed live, verified — ATP-10775 min value)* |
| 38 | BP_Risk_Building_BG_Subcov | RISK_BUILDING_BG_COVERAGES | RISK_BUILDING_BG_TARGET | ATP-10960, ATP-10950 *(closed)*, ATP-10775 | G-BP-01 *(fixed live, verified — 63.9% of NZ rows corrected)*, G-BP-51 *(closed, confirmed live)*, G-BP-73 *(fixed live, verified — ATP-10775 min value)*, G-BP-81 *(supersedes G-BP-78 — missing active-term filter + premium-join fan-out, fixed 2026-07-11 — 24.5% of BG policies exposed by the first bug, 5 more by the second; combined fix `fixes/G-BP-81_fix.sql`)* |
| 39 | BP_RISK_BUILDING_BG_UW | RISK_BUILDING_BG_UW | RISK_BUILDING_BG_TARGET | ATP-1399 (Burglary) | G-BP-70, G-BP-14 *(root cause still open)* |
| 40 | BP_LOC_BG_CLAUSE | LOC_BG_CLAUSE | RISK_BUILDING_BG_TARGET | — | *by design* |
| 41 | BP_RISK_Building_BG | BUILDING_BG_PAYLOAD | RISK_BUILDING_BG_TARGET | none found | checked clean — `{BURGLARY_IND}` already dynamic |
| 42 | BP_Risk_Building_Money_Subcov | RISK_BUILDING_MONEY_COVERAGES | RISK_BUILDING_Money_TARGET | ATP-10956, ATP-1396, ATP-10775 | G-BP-04 *(RETRACTED — was correct-by-design per ATP-10775, do not apply)*, G-BP-05 *(fixed live, verified — 32.7% affected)*, G-BP-80 *(missing active-term filter, fixed 2026-07-11 — 21.7% of Money policies exposed)* |
| 43 | BP_RISK_BUILDING_MY_UW | RISK_BUILDING_MY_UW | RISK_BUILDING_Money_TARGET | ATP-1396 (UW) | G-BP-70, G-BP-14 *(root cause still open)* |
| 44 | BP_LOC_MY_CLAUSE | LOC_MY_CLAUSE | RISK_BUILDING_Money_TARGET | — | *by design* |
| 45 | BP_RISK_Building_Money | BUILDING_MONEY_PAYLOAD | RISK_BUILDING_Money_TARGET | ATP-10956 (G-BP-05) | see SEQ 42 — G-BP-05's fix lives in this view |
| 46 | BP_Risk_Building_EN_Subcov | RISK_BUILDING_EN_COVERAGES | RISK_BUILDING_EN_TARGET | — | G-BP-82 *(supersedes G-BP-79 — missing active-term filter + hardcoded Indicator, fixed 2026-07-11 — 20.9% of EN policies exposed by the first bug, CWS_SD wrong on 99.7% of rows by the second (largest mismatch found this session); combined fix `fixes/G-BP-82_fix.sql`)* |
| 47 | BP_RISK_BUILDING_EN_UW | RISK_BUILDING_EN_UW | RISK_BUILDING_EN_TARGET | ATP-1399 (Engineering) | G-BP-70, G-BP-14 *(root cause still open — standard shared UW-adjustment pattern, checked 2026-07-11, no new gap)* |
| 48 | BP_LOC_EN_CLAUSE | LOC_EN_CLAUSE | RISK_BUILDING_EN_TARGET | — | *by design* |
| 49 | BP_RISK_Building_EN | BUILDING_EN_PAYLOAD | RISK_BUILDING_EN_TARGET | ATP-10952 | G-BP-52 — **does not reproduce 2026-07-11**, closed |
| 50 | BP_Risk_Building_BC_Subcov | RISK_BUILDING_BC_COVERAGES | RISK_Building_BC_TARGET | ATP-10949, ATP-10947, ATP-10946 | G-BP-02 *(Landslide value, fixed 2026-07-11)*, G-BP-03 *(Flood, closed — no live impact)*, G-BP-74 *(Contents 30k floor, fixed 2026-07-11)*, G-BP-75 *(Hail Storm indicator, fixed 2026-07-11 — 97.8% impact)*, **G-BP-76 *(missing active-term filter, client-confirmed duplicate coverage, fixed 2026-07-11 — 24.9% of BC policies exposed, largest/most severe this session — combined fix: `fixes/G-BP-76_fix.sql`)*** |
| 51 | BP_RISK_BUILDING_BC_UW | RISK_BUILDING_BC_UW | RISK_Building_BC_TARGET | — | *checked clean 2026-07-11 — standard shared UW-adjustment pattern* |
| 52 | BP_LOC_BC_CLAUSE | LOC_BC_CLAUSE | RISK_Building_BC_TARGET | — | *by design* |
| 53 | BP_RISK_Building_BC | BUILDING_BC_PAYLOAD | RISK_Building_BC_TARGET | ATP-10949 | G-BP-74 *(Contents 30k floor, fixed)* — HAL_SD hardcoded block flagged (G-BP-75 note), needs dev-team confirmation before fixing |
| 54 | BP_RISK_LOCATION_UW_COMBINE | RISK_LOCATION_UW_COMBINE | RISK_BUILDING_FINAL_TARGET | ATP-10937 | G-BP-14 *(candidate lead checked 2026-07-12 — ruled out, 104-row gap is correct active-term filtering of expired 2021-2022 terms, not a bug)*, G-BP-61 *(still open, different symptom — "incorrect values" not "missing")* |
| 55 | BP_RISK_Building | RISK_BUILDING_FINAL | RISK_BUILDING_FINAL_TARGET | — | G-BP-12 *(closed 2026-07-12 — contradicted by PL101, does not reproduce)*, G-BP-33 *(resolved 2026-07-12 — full dropdown audit run, all 16 remaining CASE blocks checked)*, G-BP-83 *(RoofConstruction Fibro typo, fixed — 0.2%)*, G-BP-84 *(ClearLandSqm unreachable branch, fixed — 0 impact, latent)*, G-BP-85 *(ConditionOfBuilding poor→good mislabel, fixed — 0.14%, wrong-value-asserted not just passthrough)*, G-BP-86 *(VehiclesStacked text mismatch, fixed — 0.01%)*, G-BP-87 *(FuelStore text mismatch, fixed — 0.04%); combined fix `fixes/G-BP-83_thru_87_fix.sql`* |
| 56 | BP_fleet_coverage_Vehicle_SubCov | FLEET_VEHICLE_SUBCOVERAGES | RISK_FLEET_VEHICLE_TARGET | — | G-BP-88 *(fixed 2026-07-12, includes G-BP-30 — composite key widened with REGISTRATIONNUMBER + dynamic Indicator — OHL_SD was 100% of vehicles wrongly showing Taken; combined fix `fixes/G-BP-88_fix.sql`)* |
| 57 | BP_Fleet_Vehicle_coverage | FLEET_VEHICLE_VIEW | RISK_FLEET_VEHICLE_TARGET | ATP-11134, ATP-11130, ATP-11129, ATP-11127 | G-BP-53 *(blocked, needs client input)*, G-BP-54 *(blocked, needs client input)*, G-BP-88 *(fixed 2026-07-12, includes G-BP-55 — key widened + silent-drop filter removed; combined fix `fixes/G-BP-88_fix.sql`)* |
| 58 | BP_FL_MOTOR_EXCESS | FL_MOTOR_EXCESS | RISK_FLEET_VEHICLE_TARGET | — | *checked 2026-07-12 — correctly fleet-level by design (VOLUNTARYEXCESS never varies within a fleet, 0/30); OnHook=0 correct-by-design (live data always 0); HireVehicle=0 hardcode left unchanged, Car Hire already correctly captured separately in SEQ 56* |
| 59 | BP_FL_Motor_Clauses | FL_MOTOR_CLAUSE | RISK_FLEET_VEHICLE_TARGET | — | G-BP-38 *(candidate)* — correctly fleet-level by design, not affected by G-BP-88 |
| 60 | BP_FL_Motor_UW | FL_MOTOR_UW | RISK_FLEET_VEHICLE_TARGET | — | G-BP-89 *(fixed 2026-07-12 — AdjustmentSelection never wired, 0 current impact, latent)* — correctly fleet-level by design, not affected by G-BP-88 |
| 61 | BP_Fleet_Vehicle_main | FLEET_VEHICLE_MAIN_VIEW | RISK_FLEET_VEHICLE_TARGET | — | G-BP-48 *(downgraded, not re-opened)*, G-BP-88 *(fixed 2026-07-12 — own key confirmed correct-by-design (fleet-level, 30 rows), but vehicle_xml join changed to prefix-match + own copy of G-BP-55's filter removed; combined fix `fixes/G-BP-88_fix.sql`)* |
| 62 | BP_CV_Vehicle_SubCov | CV_COVERAGE_VEHICLE_SUBCOV | CV_FLEET_VEHICLE_TARGET | ATP-11003 | G-BP-31 *(check for staleness, not re-verified this pass)*, G-BP-32 *(likely explained by G-BP-90 below)*, G-BP-90 *(fixed 2026-07-12 - composite key had no VEHICLEID, cross-contaminating sub-coverage flags across every vehicle sharing a policy/location; combined fix fixes/G-BP-90_fix.sql)*, G-BP-91 *(fixed 2026-07-12 - VW_OUTPUT_SUBCOVERAGE_BSP premium-join fan-out, same class as G-BP-81, found verifying G-BP-90; fix fixes/G-BP-91_fix.sql)* |
| 63 | BP_CV_vehicle_Cov | CV_COVERAGE_VEHICLE_COV | CV_FLEET_VEHICLE_TARGET | - | G-BP-47 *(no fix)*, G-BP-90 *(fixed 2026-07-12 - same composite key bug, LISTAGGs SEQ62 contaminated rows on the same unkeyed ID; combined fix fixes/G-BP-90_fix.sql)* |
| 64 | BP_CV_MOTOR_EXCESS | CV_MOTOR_EXCESS | CV_FLEET_VEHICLE_TARGET | - | checked 2026-07-12 - key already correctly includes VEHICLEID, not affected by G-BP-90 |
| 65 | BP_CV_Motor_Clauses | CV_MOTOR_CLAUSE | CV_FLEET_VEHICLE_TARGET | ATP-10979 | G-BP-06, G-BP-38 *(candidate)* - checked 2026-07-12, key correctly includes VEHICLEID, not affected by G-BP-90 |
| 66 | BP_CV_Motor_UW | CV_MOTOR_UW | CV_FLEET_VEHICLE_TARGET | ATP-10972 | G-BP-06 *(candidate)*, G-BP-39 - checked 2026-07-12, key correctly includes VEHICLEID, not affected by G-BP-90 |
| 67 | BP_CV_Vehicle_main | CV_RISK_COV_FINAL_VIEW | CV_FLEET_VEHICLE_TARGET | ATP-11002, 11004, 11005, 11017, 11093, 11108, 11118, 11122, 11124, 11061, 11062 | G-BP-07, 08, 09, 10, 11, 56, 57, 58, 59, G-BP-90 *(fixed 2026-07-12 - CV_VEHICLE_COV join repointed to vehicle-level key, matching EXCESS/CLAUSES/UW joins already correct; combined fix fixes/G-BP-90_fix.sql)* |

## Reading this table

- **SEQ 67 carries the most client tickets (11)** of any single config row — the CM vehicle-detail
  screen is the single highest-density area in the whole register.
- **SEQ 38, 42, 50, 57 are the next tier** (2–4 tickets each) — Burglary Theft/Contents, Money,
  Business Contents, and Fleet vehicle details.
- **14 rows carry G-BP-70** (SEQ 6, 9, 12, 15, 18, 21, 24, 27, 31, 35, 39, 43, 47, 51) — every BP
  UW-adjustment view, confirmed live: all source `Output_UWAdjust_BSP`, all hardcode
  `AdjustmentSelection='1'` ($) regardless of whether Pure recorded a percent or dollar adjustment.
  Confirmed structural finding, not yet a scoped fix — needs a business decision (see
  `seq05-08_general_property.md`). Checked and ruled out as the explanation for G-BP-14 (only 1
  dollar-only adjustment silently dropped across ~16,600 source rows).
- **5 of those rows (31, 35, 39, 43, 47) also carry a *(root cause still open)* G-BP-14 tag** — the
  client tickets on these rows (ATP-1395/1396/1399) complain of UW adjustments "not populating,"
  which G-BP-70 does not explain. SEQ 54 is the one row where all four upstream UW seqs (35, 39, 43,
  47) converge before the final XML assembly — checking it first is still the highest-leverage move
  if you want to isolate G-BP-14's true root cause.
- **19 rows have zero client tickets and zero gaps** — these are the ones that only got the
  mechanical sweep, not a real trace. Not verified clean, just untouched.
