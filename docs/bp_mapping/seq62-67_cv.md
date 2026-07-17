# SEQ 62-67 — Commercial Vehicle (CV) Coverage

| Seq | Name | Source view |
|---|---|---|
| 62 | BP_CV_Vehicle_SubCov | `CV_COVERAGE_VEHICLE_SUBCOV` (5 sub-coverage/protection-type rows per vehicle: primary protection type, On Hook, Unlimited Glass, Car Hire, Choice of Repairer) |
| 63 | BP_CV_vehicle_Cov | `CV_COVERAGE_VEHICLE_COV` (per-vehicle market value + assembles `{SUBCOV_XML}` from SEQ 62 + policy-level claim/premium totals from `VW_OUTPUT_COVERAGE_BSP`) |
| 64 | BP_CV_MOTOR_EXCESS | `CV_MOTOR_EXCESS` |
| 65 | BP_CV_Motor_Clauses | `CV_MOTOR_CLAUSE` |
| 66 | BP_CV_Motor_UW | `CV_MOTOR_UW` |
| 67 | BP_CV_Vehicle_main | `CV_RISK_COV_FINAL_VIEW` (per-vehicle final assembly — one row per vehicle, `<risk><Type>Motor</Type>...<Vehicle>...` node) |

All 6 target `AGGNE.DEV.CV_FLEET_VEHICLE_TARGET` (misleadingly named — shared with nothing Fleet-related, same table name pattern as `RISK_FLEET_VEHICLE_TARGET` used by SEQ 56-61).

---

## G-BP-90 — CV per-vehicle sub-coverage cross-contamination — FIXED, drafted

**Largest-scale, highest-severity finding in this entire BP gap-analysis pass.** Same bug SHAPE
as G-BP-88 (Fleet), but worse in two ways: larger scale, and a two-hop `LISTAGG` chain instead of
a single-hop `LEFT JOIN`, meaning contamination compounds rather than just duplicates.

### What's wrong

`CV_COVERAGE_VEHICLE_SUBCOV` (SEQ 62) and `CV_COVERAGE_VEHICLE_COV` (SEQ 63) both key on
`PUREPOLICYNUMBER|cmlnumber|EXPIRINGID_P` — a policy/location/term key, not a vehicle key — even
though `VEHICLEID` is available as a column in both views' source (`cm_03`) and is already
correctly included in the key by every OTHER Commercial Vehicle view in this chain:

- `CV_MOTOR_EXCESS` (SEQ 64), `CV_MOTOR_CLAUSE` (SEQ 65), `CV_MOTOR_UW` (SEQ 66): all key
  `policy|cml|expiringid_p|VEHICLEID` — correct, confirmed live.
- `CV_RISK_COV_FINAL_VIEW` (SEQ 67): computes `PUREPOLICYNUMBER` the same vehicle-specific way
  (line 72 of its `GET_DDL`) — and joins EXCESS/CLAUSES/UW on it correctly (lines 359-361).

This confirms CV's design intent is genuinely per-vehicle throughout — unlike Fleet, where the
equivalent SEQ 58-60 views are correctly fleet-level by design (uniform terms across a fleet).
SEQ 62/63's missing `VEHICLEID` is a real gap, not an intentional rollup.

### How the contamination compounds (two hops, worse than Fleet)

1. SEQ 62 renders one row per (vehicle, sub-coverage-type) into `CV_FLEET_VEHICLE_TARGET` under
   `ITR_TYPE='BP_CV_Vehicle_SubCov'`, but the `ID` for every vehicle sharing a policy/location is
   identical (missing `VEHICLEID`).
2. SEQ 63's `cv_coverage_xml` CTE does `LISTAGG(payload,'') ... WHERE itr_type='BP_CV_Vehicle_SubCov'
   GROUP BY id` — this concatenates EVERY vehicle's sub-coverage rows at that shared key into one
   blob, then `LEFT JOIN`s that blob onto every vehicle's own SEQ 63 output row (also emitted under
   the same shared, non-vehicle-specific `ID`).
3. SEQ 67's `CV_VEHICLE_COV` CTE does the exact same `LISTAGG(payload,'') ... WHERE
   itr_type='BP_CV_vehicle_Cov' GROUP BY id` AGAIN — concatenating every vehicle's already-
   contaminated SEQ 63 payload together a SECOND time — then joins it onto every final vehicle row
   via `WITHOUT_VEHID_PUREPOLICYNUMBER` (SEQ 67's own deliberately policy-level key variant, used
   for this one join only; EXCESS/CLAUSES/UW correctly use the vehicle-level key instead).

### Confirmed live (2026-07-12)

Policy `P00009911|CML00000309|575099` (3 vehicles sharing one key) — the rendered
`BP_CV_vehicle_Cov` payload for that key contains, inside ONE vehicle's `<coverage>` block:

- Three separate `<CMP_SD>` "Comprehensive Property" entries with three different `<iValue>`
  amounts: `121500.00000`, `309200.00000`, `0.00000` — clearly three different vehicles' agreed
  values, all attached to every vehicle at this key.
- Two separate `<OHL_SD>` "On Hook Liability" entries with conflicting `<iValue>` (`1.00000` vs
  `0.00000`).
- All 3 `BP_CV_vehicle_Cov` rows for this key returned byte-identical `SUBCOV_XML` length (2,269
  chars) before this fix.

This is malformed, self-contradictory XML being sent to DCT for every multi-vehicle Commercial
Vehicle policy — not just a "wrong field," but duplicate/nested coverage blocks with irreconcilable
values for the same `<Type>`.

### Live impact (`cm_03`, 2026-07-12)

| Metric | Value |
|---|---|
| Total CV vehicle rows | 44,836 |
| Distinct policy/location keys (`policy\|cml\|expiringid_p`) | 11,438 |
| Keys with more than one distinct `VEHICLEID` | 8,256 (72.2%) |
| Keys with vehicles showing **genuinely different `ProtectionType`** sharing one key | **5,017 (43.9%)** |
| Total vehicle rows sitting inside a contaminated key group | **29,327 (65.4%)** |

Unlike G-BP-88 (0 live impact today, real data happened to be uniform per fleet), this is **active,
confirmed data corruption today** at a much larger scale — the single biggest live-impact number
found in the whole BP pass.

### The fix

`VEHICLEID` is the missing per-vehicle disambiguator — already present as a column in every
relevant view, just not used in SEQ 62/63's key.

1. **`CV_COVERAGE_VEHICLE_SUBCOV` (SEQ 62)**: `CM_BASE` CTE's `purepolicynumber` widened to append
   `TRIM(vehicleid)`.
2. **`CV_COVERAGE_VEHICLE_COV` (SEQ 63)**: `cv_table` CTE's output `PUREPOLICYNUMBER` widened the
   same way. A SEPARATE `POLICY_LEVEL_KEY` column (unwidened) is kept for the `VW_OUTPUT_COVERAGE_BSP`
   join only — confirmed live that source table is genuinely one row per `policy|cml|expiringid_p`
   (fleet-wide `CMEXPPREM`/`CMNOVEHS`/`CMCLMCNT`/`CMCLMINCD` totals), so widening that join would
   have broken it (returned NULL for every vehicle).
3. **`CV_RISK_COV_FINAL_VIEW` (SEQ 67)**: the `CV_VEHICLE_COV` join changed from
   `a.WITHOUT_VEHID_PUREPOLICYNUMBER = e.ID` (policy-level, the bug) to `a.PUREPOLICYNUMBER = e.ID`
   (vehicle-level) — now matches the other 3 joins (`CV_MOTOR_EXCESS`/`CLAUSES`/`UW`) in the same
   view, which were already correct. No other line in this view changes.

**Fix**: `docs/bp_mapping/fixes/G-BP-90_fix.sql` — 3 views (full `CREATE OR REPLACE VIEW`, single
targeted change each).

### Hotfix (2026-07-12, after first live reload)

The first version of STEP 1 built SEQ 62's key using `NVL(CAST(VEHICLEID AS VARCHAR),0)`, which
renders this `NUMBER` column as `'1060225.00000'` (decimal scale preserved) — a different text
format than SEQ63/64/65/66/67's plain `TRIM(VEHICLEID)` on the raw numeric column, which renders
`'1060225'` (no decimals). Confirmed live after the user's first reload: **0 of 45,142**
`CV_COVERAGE_VEHICLE_COV` rows had a non-null `SUBCOV_XML` — the mismatched key format meant SEQ
63's join to SEQ 62's rendered rows never matched anything, so sub-coverage data stopped being
cross-contaminated but became silently missing for every vehicle instead. STEP 1 corrected to
`NVL(TRIM(VEHICLEID),'0')`, verified byte-for-byte matching the format used everywhere else in
this chain. `fixes/G-BP-90_fix.sql` has been updated in place with this correction — re-apply
STEP 1 and re-run `fixes/G-BP-90_rerun_seq62_63.py` again.

### Target-table refresh required (same caveat as G-BP-88)

`DYNAMIC_XML_V1` (the generic Snowflake procedure that populates every `*_TARGET` table) does a
plain `INSERT INTO ... SELECT DISTINCT` from the source view — it does not auto-refresh when a
source view's key shape changes, and its `TRUNCATE` line is commented out. After applying the view
changes, `CV_FLEET_VEHICLE_TARGET`'s existing rows for `ITR_TYPE IN ('BP_CV_Vehicle_SubCov',
'BP_CV_vehicle_Cov')` are still the OLD policy-level rows and must be deleted and re-rendered.

**Script**: `docs/bp_mapping/fixes/G-BP-90_rerun_seq62_63.py` — deletes stale rows for both
`ITR_TYPE`s, then re-runs `DYNAMIC_XML_V1` for SEQ 62 THEN SEQ 63 in order (63 depends on 62's
freshly-rendered rows). `CV_RISK_COV_FINAL_VIEW` (SEQ 67) needs no re-run of its own — it's a live
view, not a target table, so it picks up the corrected join automatically once the view change is
applied.

### Post-fix verification (to run after both the view changes and the rerun script)

1. `CV_COVERAGE_VEHICLE_SUBCOV`/`CV_COVERAGE_VEHICLE_COV` key granularity — expect ~1 vehicle per
   key (small residual acceptable, same shape as G-BP-88's 22 blank-registration vehicles).
2. Policy `P00009911|CML00000309|575099` should show 3 DIFFERENT `SUBCOV_XML` values (one per
   vehicle) instead of 1 shared blob.
3. No more duplicate `<coverage><Type>` blocks with conflicting `<iValue>` inside one vehicle's
   final `BP_CV_vehicle_Cov` payload.

Full PRE/POST-CHECK queries are commented at the bottom of `fixes/G-BP-90_fix.sql`.

---

## G-BP-91 (new, self-identified) — CV sub-coverage premium-join fan-out, same class as G-BP-81

**Found while verifying G-BP-90 in the final `AGGNE.UAT.POLICY_MIGRATION_DCT.REQUEST_XML` output.**
After G-BP-90 correctly isolated each vehicle's own key, a broad sample of vehicle payloads still
showed duplicate `<Code>` sub-coverage blocks *within a single vehicle's own XML* — e.g. two
`<Code>CMULG_SD</Code>` blocks with different `<iValue>`/`<Premium>` inside one vehicle.

**Root cause**: `CV_COVERAGE_VEHICLE_SUBCOV`'s `SUB_COV_EXP_PRM` CTE reads
`VW_OUTPUT_SUBCOVERAGE_BSP` (policy-level premium data) and joins it onto `CM_BASE` keyed only on
`(POLICYNUMBER, cmlnumber, CMCODE)` — no vehicle disambiguator, because this premium source is
genuinely policy-level. `VW_OUTPUT_SUBCOVERAGE_BSP` has duplicate rows for some (policy, cml,
sub_coverage) keys — confirmed live, policy `P00023483|CML00022885`/`CMULG_SD` has two rows
(`EXPPREMIUM` 2635.00 and 71.00) — so the `LEFT JOIN` fans out, and **every vehicle** at that
policy/cml gets duplicated for that sub-coverage code. Same exact bug shape as **G-BP-81**
(Building BG), against the same underlying `VW_OUTPUT_SUBCOVERAGE_BSP` table family — this bug
predates G-BP-90 and was always present in this view; it was invisible before because the much
larger cross-vehicle contamination bug swamped it.

**Live impact (2026-07-12)**: 4,392 of the `(policy,cml,sub_coverage)` keys in
`VW_OUTPUT_SUBCOVERAGE_BSP` (`sub_coverage LIKE 'CM%'`) have duplicate premium rows, affecting
**1,939 distinct policies**. Sampled 3,000 random `BP_CV_vehicle_Cov` vehicle rows after G-BP-90:
**~41% had a duplicate `<Code>` block** traceable to this fan-out. (A separate, smaller, already-
documented issue — **G-BP-06**'s CM staging dedup, ~1.75-7.5% of vehicles — also produces the same
symptom via a different mechanism: duplicate raw rows in `cm_03` itself. Not fixed by this script.)

**Fix**: `docs/bp_mapping/fixes/G-BP-91_fix.sql` — pre-aggregates `SUB_COV_EXP_PRM` with
`SUM(EXPPREMIUM)` grouped by the join key before joining, same technique as G-BP-81. Verified live
this collapses `VW_OUTPUT_SUBCOVERAGE_BSP` (CM subset) from having fan-out-prone duplicates to
exactly 1 row per key (35,268 aggregated rows == 35,268 distinct keys). Only `SEQ 62`
(`CV_COVERAGE_VEHICLE_SUBCOV`) changes — no other sequence in this chain joins
`VW_OUTPUT_SUBCOVERAGE_BSP` directly. Re-use the existing `fixes/G-BP-90_rerun_seq62_63.py` to
refresh the target table after applying.

**FULLY VERIFIED 2026-07-12 — both G-BP-90 and G-BP-91 confirmed clean end-to-end in the actual
final DCT output** (`AGGNE.UAT.POLICY_MIGRATION_DCT.REQUEST_XML`, the XML that would be sent to
Duck Creek, not an intermediate view):
- Full-table scan of `CV_COVERAGE_VEHICLE_SUBCOV` (not a sample): **0** `(vehicle, CMCODE)` groups
  with duplicates anywhere.
- Across the entire 152-policy UAT batch: **349 total CV vehicle blocks, 0 policies with any
  duplicate coverage code** within a vehicle. 307 of 349 vehicles have sub-coverage data present
  (the remaining 42 genuinely have no CM sub-coverage selections in source).
- Spot check `P00023483|CML00022885|2519919|1751293` (the exact diagnosed example): now exactly 5
  sub-coverage rows (was 7 with duplicates), `CMULG_SD`=2706.00 (2635+71 summed correctly),
  `CMCMP_SD`=73244.67 (642+72602.67 summed correctly).
- Fleet (`P00034478`, G-BP-88, unaffected by these CV-specific fixes) re-confirmed still clean: 42
  vehicle blocks, no identical vehicles.
- Along the way, a hotfix was needed for G-BP-90's own STEP 1 (`NVL(CAST(VEHICLEID AS VARCHAR),0)`
  produced `'1060225.00000'`, a different text format than the rest of the chain's plain
  `TRIM(VEHICLEID)` → `'1060225'`, which silently broke the SEQ62→63 join for every vehicle after
  the first reload) — corrected in `fixes/G-BP-90_fix.sql` in place, and the rerun script
  (`fixes/G-BP-90_rerun_seq62_63.py`) needed a `snowflake.connector.paramstyle = "qmark"` fix since
  the connector defaults to `pyformat` and rejects `?` placeholders — the same latent bug exists
  in `middleware/etl4.py`'s own `_call_sp` helper, never caught because `SAFE_MODE` has always
  blocked it from running for real.

---

## Already registered, unchanged this pass

- **G-BP-57** (ATP-11122, SEQ 67) — CM Market Value without Accessories: token IS wired
  (`{MARKETVALUEWITHOUTACCESSORIESAMOUNT}`), so the value arrives but is reportedly wrong — bug is
  in derivation, not missing-wiring. Not re-investigated this pass; still open.
- **G-BP-58** (ATP-11118, SEQ 67) — CM Agreed Value without Accessories: `<AgreedValue/>` bare
  empty tag, no token — same missing-column pattern as G-BP-10 (Fleet Fuel/Power/TrackRear). Not
  re-investigated this pass; still open.
- **G-BP-07/08/09/10/11** (SEQ 67) — CM BodyType/ImportType/AddAccessories/FuelType/VehicleType
  dropdown and wiring gaps, already root-caused in the ATP-10219 triage — not re-touched this pass.

## Checked, no new issues

- **SEQ 64/65/66** (`CV_MOTOR_EXCESS`/`CLAUSE`/`UW`): key construction confirmed correct
  (`policy|cml|expiringid_p|VEHICLEID`) — no fix needed, used as the reference pattern for G-BP-90's
  fix.
- **SEQ 67**'s EXCESS/CLAUSES/UW joins (`CV_RISK_COV_FINAL_VIEW` lines 359-361): confirmed already
  correctly vehicle-keyed — only the `CV_VEHICLE_COV` join (line 362) needed the fix.
