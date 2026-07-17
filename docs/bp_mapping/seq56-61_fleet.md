# SEQ 56-61 — Fleet Vehicle Coverage

| Seq | Name | Source view |
|---|---|---|
| 56 | BP_fleet_coverage_Vehicle_SubCov | `FLEET_VEHICLE_SUBCOVERAGES` (5 sub-coverage types per vehicle: primary protection type, On Hook, Unlimited Glass, Car Hire, Choice of Repairer) |
| 57 | BP_Fleet_Vehicle_coverage | `FLEET_VEHICLE_VIEW` (per-vehicle identity/registration + assembles `{SUBCOV_XML}` from SEQ 56) |
| 58 | BP_FL_MOTOR_EXCESS | `FL_MOTOR_EXCESS` |
| 59 | BP_FL_Motor_Clauses | `FL_MOTOR_CLAUSE` |
| 60 | BP_FL_Motor_UW | `FL_MOTOR_UW` |
| 61 | BP_Fleet_Vehicle_main | `FLEET_VEHICLE_MAIN_VIEW` (top-level `<risk><Type>Motor</Type>...` node, one row per fleet/location) |

**Client tickets:** ATP-11130 (G-BP-53), ATP-11129 (G-BP-54), ATP-11134 (G-BP-55).

---

## G-BP-88 — Fleet per-vehicle sub-coverage cross-contamination — FIXED, drafted

**What's wrong**: `FLEET_VEHICLE_SUBCOVERAGES` (SEQ 56) and `FLEET_VEHICLE_VIEW` (SEQ 57) both key on
`PUREPOLICYNUMBER|cmlnumber|EXPIRINGID_P` — the same location/term key used everywhere else in this
project — but for Fleet specifically, that key is **not unique per vehicle**. An entire fleet of
vehicles at one location shares the same key.

**Live check** (`VEHICLECOVERAGES_FLEETVEHICLE`, 2026-07-12): 1,222 total vehicle rows collapse to
just **52 distinct composite keys**. One example (`P00026745|CML00007725|2202826`) has **54
vehicles** sharing a single key. 30 of the 52 keys have more than one vehicle.

**Confirmed live**: `FLEET_VEHICLE_VIEW.SUBCOV_XML` is `LISTAGG`'d by this shared key then
`LEFT JOIN`ed back onto every vehicle sharing it — 5 sample vehicles under the `P00026745` key
(Honda Accord, Toyota Caldina, Toyota Vitz, Honda Civic, Toyota Hiace) all returned byte-identical
`SUBCOV_XML` (1,115 chars).

**Live impact today is 0** — checked all 30 multi-vehicle fleet groups on
`PROTECTIONTYPE`/`ONHOOK`/`UNLIMITEDGLASS`/`CARHIRE`/`CHOICEOFREPAIR`/`VOLUNTARYEXCESS`: every single
one is currently 100% homogeneous. Real-world plausible (fleets are often insured under uniform
terms), but the design has never been tested against a real mismatch.

### Confirming the fix was mechanically safe

Pulled the actual `DYNAMIC_XML_V1` Snowflake procedure source (the generic engine that populates
every `*_TARGET` table across the whole project, both BP and PP):

```sql
v_sql := 'INSERT INTO ' || :TargetTable ||
         ' (ID,ITR_TYPE, PAYLOAD,LOAD_DATE) ' ||
         'SELECT DISTINCT PUREPOLICYNUMBER,  ''' || :ITR_TYPE || ''',' || v_replacement_expr ||
         ',GETDATE() FROM ' || :SourceTable;
```

`ID` is a **literal, hardcoded passthrough** of whatever a source view names its `PUREPOLICYNUMBER`
column — not config-driven, not independently computed. This confirms widening a source view's key
automatically flows through to the target table with zero ETL changes needed, as long as every view
that reads that target table's `ID` is updated to build the matching new key shape.

### Scope narrower than first thought

`FLEET_VEHICLE_MAIN_VIEW` (SEQ 61) was checked directly and confirmed **intentionally fleet-level**
(30 rows total — one per fleet/location, not per vehicle), aggregating every vehicle under one risk
node. That's correct design, not a bug. `FL_MOTOR_EXCESS`/`CLAUSE`/`UW` (SEQ 58/59/60) feed SEQ 61
directly as fleet-wide attributes, and `VOLUNTARYEXCESS` never varies within any of the 30
multi-vehicle fleets (0/30) — consistent with real Fleet policies using uniform terms across the
whole fleet. **These are correct-by-design and were not touched.**

The real bug is contained to the SEQ 56 → SEQ 57 chain only.

### The fix

`REGISTRATIONNUMBER` is the missing per-vehicle disambiguator — adding it to the composite key takes
52 distinct keys to 1,194 (of 1,222 total vehicles). 22 have blank registration (same shape as
G-BP-55's blank Make/Model, an accepted edge case) and 2 residual duplicate-registration keys remain
— both small and acceptable, same class as gaps already accepted elsewhere this session.

1. **`FLEET_VEHICLE_SUBCOVERAGES` (SEQ 56)**: widen `PUREPOLICYNUMBER` to append
   `TRIM(COALESCE(REGISTRATIONNUMBER,''))`. Combined with G-BP-30's Indicator fix (same view).
2. **`FLEET_VEHICLE_VIEW` (SEQ 57)**: widen its own key the same way. Combined with G-BP-55's
   filter-removal fix (same view).
3. **`FLEET_VEHICLE_MAIN_VIEW` (SEQ 61)**: own key **stays fleet-level, unchanged** (correct). Its
   `vehicle_xml` join changes from exact-match to prefix-match
   (`t2.id LIKE t1.PUREPOLICYNUMBER || '|%'`), since SEQ 57's rendered rows are now vehicle-specific
   and would no longer exact-match the fleet-level key — this keeps it aggregating every vehicle
   correctly. `FL_MOTOR_CLAUSES`/`EXCESS`/`UW` joins are untouched (still correctly exact-match on
   the fleet-level key). **Also found**: this view has its own separate copy of G-BP-55's silent-drop
   filter (`WHERE YEAR<>0 and MAKE<>'' and MODEL<>''`) — fixed here too.

**Fix**: `docs/bp_mapping/fixes/G-BP-88_fix.sql` — 3 views + 1 config change (SEQ 56's Indicator
token). Combines and supersedes the standalone `G-BP-30_fix.sql` and `G-BP-55_fix.sql` — run this
file instead of those two.

---

## G-BP-30 — Fleet Subcov indicator (SEQ 56) — folded into G-BP-88, largest-scope mismatch this session

**Corrects a stale register claim.** Previously marked "view+config fix scripted, verified" from an
earlier session; live check 2026-07-12 found the config still hardcodes `<Indicator>1</Indicator>`
and the view had no `INDICATOR` column at all — never actually applied.

`FLEET_VEHICLE_SUBCOVERAGES`'s `base` CTE unions 5 sources per vehicle: the vehicle's own selected
protection type (correctly always "taken", it's literally what the vehicle has) plus 4 fixed
"optional extra" rows (On Hook, Unlimited Glass, Car Hire, Choice of Repairer) that should be gated
on whether Pure shows them taken, but weren't.

**Live impact** (`VEHICLECOVERAGES_FLEETVEHICLE`, 1,222 vehicles):

| Sub-coverage | Wrongly shows "Taken" | % of 1,222 |
|---|---|---|
| **On Hook Liability (OHL_SD)** | 1,222 | **100.0%** — every vehicle in the entire Fleet portfolio |
| Car Hire (TCH_SD) | 1,192 | 97.5% |
| Choice of Repairer (COR_SD) | 464 | 38.0% |
| Unlimited Glass (ULG_SD) | 128 | 10.5% |

OHL_SD's 100% is the largest-scope mismatch found in this entire BP gap-analysis pass.

**Fix**: folded into `docs/bp_mapping/fixes/G-BP-88_fix.sql` (Step 1) since it touches the same view
as the key-widening fix.

---

## G-BP-55 (ATP-11134) — Fleet Make/Model silent drop — folded into G-BP-88

`FLEET_VEHICLE_VIEW`'s `fleet_table` CTE has `WHERE YEAR<>0 and MAKE<>'' and MODEL<>''` — silently
drops the entire vehicle record when any of the three is blank. Same shape as PP's retired PR-01.
**Also found an independent second copy of this exact filter in `FLEET_VEHICLE_MAIN_VIEW`** while
investigating G-BP-88 — fixed at the same time.

**Live data** (2026-07-12): 1,222 total Fleet vehicles; 22 blank `MAKE`, 22 blank `MODEL` (largely
the same 22), 0 with `YEAR=0` — **1.8% currently silently dropped**.

**Fix**: folded into `docs/bp_mapping/fixes/G-BP-88_fix.sql` (Steps 2 and 3).

---

## G-BP-89 (new, self-identified) — FL_MOTOR_UW AdjustmentSelection never wired — FIXED, drafted

SEQ 60's config has `<AdjustmentSelection></AdjustmentSelection>` — a bare, permanently-empty tag
with no token at all, unlike every one of the other 14 shared UW-adjustment views in this codebase
(all hardcode `AdjustmentSelection='1'` and wire it). `FL_MOTOR_UW`'s view doesn't even output an
`ADJUSTMENTSELECTION` column.

**Live impact**: 0 — there are currently 0 live Fleet UW-adjustment notes at all
(`Output_UWAdjust_BSP`, `COVERAGE='FL'`). Fixed anyway per this session's standard of correcting
structural defects regardless of current data coverage. **Not affected by G-BP-88** — SEQ 60 is
correctly fleet-level by design, its key was not changed.

**Fix**: `docs/bp_mapping/fixes/G-BP-89_fix.sql` — view (adds the column, hardcoded `'1'` matching
the sibling pattern) + config (wires the token). Two-step PRE-CHECK/UPDATE/POST-CHECK for the config
half. Standalone, not part of `G-BP-88_fix.sql`.

---

## Already registered, unchanged this pass

- **G-BP-53** (ATP-11130, SEQ 57) — Fleet RB Vehicle Key: no source column exists anywhere in scope,
  needs client/Aggne policy team input before any fix. Still blocked.
- **G-BP-54** (ATP-11129, SEQ 57) — Fleet Market Value without Accessories: no source column exists,
  same blocker as G-BP-53. Still blocked.
- **G-BP-48** (SEQ 61) — Fleet `<risk>` block's ~100 empty fields: previously corrected to
  "likely non-issue" after a manuscript cross-check showed these fields belong at the `<Vehicle>`
  level (SEQ 57), not `<risk>` (SEQ 61) — not re-opened this pass.

## Checked, no new issues

- **SEQ 58** (`FL_MOTOR_EXCESS`): `<OnHook>0</OnHook>` hardcoded in config — checked live
  `ONHOOK` column, always `0` today (0 of 1,222 rows), so correct-by-design with current data
  (same "trivially satisfied" pattern seen elsewhere this session). `<HireVehicle>0</HireVehicle>`
  also hardcoded — `CARHIRE` has real `Taken`/`Not Taken` data (30 of 1,222 = 2.5% Taken), but Car
  Hire is separately and correctly captured as its own sub-coverage line (`TCH_SD`) in SEQ 56 — this
  `<Excess>`-block tag is very likely a different, excess-specific attribute rather than "is Car Hire
  taken," so left unchanged pending confirmation rather than guessed at.
- **SEQ 59** (`FL_MOTOR_CLAUSE`) — standard clause pass-through, dropdown mapping list checked
  against live `DCCLAUSETYPE` values, no unmapped values found.
