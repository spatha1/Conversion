# PP Conversion — Master Cross-Reference: Seq / Gap / ATP

## 2026-07-10 Ready Batch — live-reconfirmed before packaging

Re-checked every "🟡 Ready" item below against live Snowflake/SQL Server DDL before packaging (per
[[feedback_verify_live_not_repo]] — this table itself can drift). Two things changed:

1. **G-02, G-08, G-12, G-42 are actually deployed** — confirmed via DDL (fix comment markers +
   matching logic present in live `PER_COM_PAYLOAD`). This table's rows for those 4 below were stale.
2. **Everything else still "Ready" was genuinely NOT yet deployed** — consolidated into 3 deploy
   files, one per object, covering every remaining gap with no open client question:
   - `seq_fixes/READY_BATCH_20260710_SP_PURE_TO_WRITE.sql` — G-03(pt1), G-05(pt1a), G-06, G-09,
     G-10, G-39(SP part) — 7 patches on `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD`
   - `seq_fixes/READY_BATCH_20260710_VIEW_PER_COM_PAYLOAD.sql` — G-05(pt1b)
   - ~~`seq_fixes/READY_BATCH_20260710_SP_FINAL_LOAD.sql` — G-44 (symptom fix)~~ **RETRACTED
     2026-07-10** — HANDLERMAIL feeds the DCT session Producer property, not just a display field;
     blanking it for 83% of policies risks import failure, not just a cosmetic wrong name. Back to
     "needs Aggne decision" (does Producer accept blank? what's a safe fallback?). Do not deploy.
   - `sql/snowflake/1_conversion/PP/deploy/PP_CONVERSION_RUN_REGENERATED_FROM_CONFIG.sql` —
     re-generated fresh from current config (picks up G-47, which was already deployed to SQL
     Server but not yet synced into the Snowflake orchestrator's embedded copy)

Deploy order: SP patch → view patch → final-load SP patch → orchestrator regen → re-run
`PP_CONVERSION_RUN(TRUE)` → run the post-validation queries in each file.

## 2026-07-10 — Batch deployed, rebuilt, and validated (final for today)

All 3 ready-batch files deployed. One misapplied patch found and corrected (G-39 SP part landed on
the wrong of two near-identical clause blocks — CM_01 instead of PM_02 — reverted the wrong one,
applied the right one; see `READY_BATCH_20260710_STEP2_FIX_AND_RUN.sql`). One pre-existing,
unrelated bug hit and resolved by session context, not code (`Sample_CBP_` unqualified reference —
needs `USE DATABASE AGGNE; USE SCHEMA DEV;` before calling the Pure-to-Write SP; not a defect
introduced today). Both SPs re-run (`SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()` then
`PP_CONVERSION_RUN(TRUE)`), all fixes confirmed at the data level:

| Check | Before | After |
|---|---|---|
| PM_01 blanks (BodyType/Cyl/Drive/Induction/ImportFlag, override≠1 pop.) | 6,488 | ~2,750-2,769 (residual = genuine raw blanks, not a bug) |
| Override=1 regression | — | 0 |
| PER_COM_PAYLOAD blank BodyType | 3,217 | 686 |
| PER_COM_PAYLOAD zero cylinders | 3,105 | 407 (target ~512) |
| COM_CLAUSE forced caps (G-39) | ~175 | 0 |
| Seq4/10 Indicator variance (G-47) | 100% = 1 | 20,891 / 6,595 split, matches source |
| Motor Premium = 0 (G-42) | 100% | 0 |

Cross-validated against the same real policies in `AGGNE.UAT.PER_POLICY_MIGRATION_DCT` (38 matched
policies): blank BodyType 22→6, zero cylinders 22→4 in the actual generated XML, not just staging
tables.

## 2026-07-10 — G-49 (HB_02/HC_02 rebuild) also deployed and confirmed fixed same day

Dry-run validated read-only first (per [[feedback_verify_live_not_repo]] discipline — same-day
lesson from the `Sample_CBP_` surprise: test in isolation before pasting into the 440K-char SP), then
inserted into `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` right after `Sample_PER` builds. Confirmed
end-to-end: P00010162 Location 1 ($906,000 HB / $202,000 HC) now resolves under the correct current
`EXPIRINGID_P=2530787` at every layer through to the real `REQUEST_XML`. Orphaned `HB_02` rows
(broader impact, not just this one policy) dropped 1,749→549 — 549 not yet individually
characterized, follow-up item. ATP-11110/11117/11115 closed as Fixed & Validated — see
`CLIENT_BUG_STATUS_REPORT_20260710.md`.

## 2026-07-10 — ATP-10842 (Windscreen Glass Excess) and ATP-11112 (age increased) analyzed

**ATP-10842**: root cause found and scoped out of G-37 — `PER_COM_COVERAGES`'s `PMULG_SD`
(Unlimited Glass) had `INDICATOR` hardcoded to 1 for all 2,175 rows; real driver
(`EXCESSWAIVERFORGLASS`) already exists and varies. **First fix attempt caused a real regression**
(caught before being treated as done): drove the indicator straight off a per-vehicle column inside
a policy-level `SELECT DISTINCT`, producing duplicate/conflicting rows for 208 policies with
multiple vehicles on mixed waiver settings. Corrected with `GROUP BY`/`MAX` aggregation (any vehicle
waived → policy shows waived — an assumption, flagged for Aggne to confirm, not a proven rule).
Corrected version redeployed, pending final validation.

**ATP-11112**: investigated, initial "stale term" lead (matching G-49's shape) did not hold up on a
concrete example — age variation traced to normal per-vehicle driver differences, not a
term-selection bug. `AgeOfYoungestRegularDriver` is a raw PURE pass-through with no computation of
ours. Declined to guess further; needs a specific policy number from the client to trace precisely.
Still 🔬 Investigating / ⚪ blocked-on-more-info, not a coded fix.

## 2026-07-10 (end of day) — G-41 quick recon for Monday, plus 12 unclassified tickets triaged

**G-41 (ATP-11105)**: 10-minute recon, not age-filtered (ran out of time), rough map only:
`LOCATIONDETAILS_PER` 99.0% blank → `PERSONAL_RISK_01/02/03` ~85.4-85.5% blank (unexpectedly LOWER —
something fills in data the raw source doesn't have, worth understanding) → `PER_RISK_BUILDING_FINAL`
98.8% blank (jumps back up — this is the real funnel point, last hop before the payload). **Next
step Monday**: repeat the original age-41+ filtered comparison (raw 53.7% vs downstream 95.5%) at
each of these 5 stages specifically to find which hop reintroduces the blanks — this rough check
wasn't age-filtered so isn't directly comparable to that original finding.

## 2026-07-13 — G-41 ROOT CAUSE FOUND AND CORRECTED (supersedes the 2026-07-10 recon above)

The "PERSONAL_RISK_01/02/03 might be a better source, same pattern as G-49" idea from Friday's recon
was investigated first and **retracted**: those 3 tables are genuinely stale (created 2026-03-05,
never rebuilt since, not referenced by any of the 3 main orchestrator SPs, `POLICY_BINDER_ID` values
don't even match current `EXPIRINGID_P`s) — but that turned out to be a red herring, not the real bug.

**Real root cause**: `Locationdetails_PER`'s own build logic (inside
`SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD`, "derived" CTE) has a backwards `CASE` statement for
`YearLastReWired_new`/`YearLastRePlumbed_new` — intended to correct garbage years (0-1899) to 1900
while passing real years through unchanged, but the inner `ELSE` branch returns `NULL` instead of
the real value for every normal 4-digit year. Confirmed against raw `Sample_PER`: 787 rows have a
genuine rewire year (2000, 2010, 1970, 2008...) that this logic silently discards. Not a staleness
issue at all — both `Locationdetails_PER` and its own source `Sample_PER` are rebuilt fresh every
run; this is a straightforward logic bug. Fix drafted, ready to deploy, no client input needed — see
`seq_fixes/seq14_risk_building_outer/sp/G-41_fix.sql`. ATP-11105 moves from 🔬 Investigating to
🟡 Ready.

**12 previously-unclassified Batch 2 tickets** — quick title/description read (not live-verified):
all 12 look like PP-scope (policy numbers match PP's P0000XXXX format, no BP-exclusion keywords
present). Two flagged for likely-duplicate check against existing gaps: ATP-11089 and ATP-11042
(recurring UW adjustments) both look like restatements of already-known **G-19**, not new bugs —
check before treating as separate. Full list and reasoning in the conversation — not yet written to
a dedicated doc.

**Correction 2026-07-13**: ATP-10904 ("Hail/Malicious Damage Excess, Customer Vehicles") was
misclassified as a new PP Motor gap on the Friday quick pass — investigated properly and it's
actually **BP scope**, not PP. The field belongs to `ContentsAndStocksInput` in the manuscript, a
Business/Commercial concept (matches BP's `CustomerVehicle`/`StockVehicles` fields), not Personal
Motor. Handed off — not a PP gap.

**Correction 2026-07-13 (bigger one)**: the BP team's own tracked epic view
(`files/Issues/BP Conversion/BP_Issues_ATP-10219_12072026.html`, filtered to Raju Kallepelli's
assignments) already includes ALL remaining "unclassified" tickets from the Batch 2 triage —
ATP-11151, ATP-11145, ATP-11089, ATP-11088, ATP-11086, ATP-11042, ATP-11041, ATP-10980, ATP-10979,
ATP-10906, ATP-10903. These are being actively worked as BP tickets by Raju right now. Reclassifying
all of them BP and handing off — no longer tracked as PP-unclassified. The one exception: G-50 (the
fix drafted for ATP-11089/ATP-11042) stays valid as an independent PP finding — `SP_PP_ADJ_EXP_PREM`
is genuinely PP-specific infrastructure, confirmed and fixed regardless of which LOB the original
ticket describes — but it may not be the actual fix those two tickets were filed about if they're
reporting a BP-side symptom of a similar-shaped bug. Worth flagging to Raju that the same NULL=NULL
join pattern is worth checking on BP's equivalent pipeline.

**`<UnlimitedGlass>1</UnlimitedGlass>` (seq 18, no gap number assigned)** — investigated, NOT
confirmed as a bug, no fix drafted. Distinct tag from `PMULG_SD`'s Indicator (already fixed under
ATP-10842) — genuine field, `VehicleInput.UnlimitedGlass`, boolean, caption "Unlimited Glass"
(Protected/Not Protected), and **DCT itself defaults it to 1** when shown. Could be the same
business concept as `ExcessWaiverForGlass` (in which case the hardcode is wrong for the same 619
policies) or a genuinely distinct field DCT defaults to 1 anyway (in which case the hardcode is
harmless). No client ticket has reported this specifically — self-found while reading the template.
Declined to guess after the ATP-10842 near-miss; leaving as-is until real evidence appears.

**G-50 (NEW, 2026-07-13)** — investigating ATP-11089/ATP-11042 as possible G-19 duplicates found a
real, separate, more severe bug: `Output_UWAdjust_PER.UWAdjustAmount` is NULL for 97.3% of all
underwriting-adjustment rows (100% for HB/HC/SU, 90.1% even for Motor) because
`Adjustments_PER_Out`'s join on `Vehicle_ID` uses plain `=`, which fails whenever both sides are
NULL (true for every non-vehicle coverage). One-line fix (`IS NOT DISTINCT FROM`), drafted and
simulated against live data — see `seq_fixes/cross_cutting_final_load/sp/G-50_fix.sql`. Ready to
deploy, no client input needed. This is NOT G-19 (which only affects which rows exist at all, not
whether the dollar amount inside an existing row is populated) — both bugs coexist in the same
UW-adjustment pipeline.

**G-51 (NEW, 2026-07-14, client CR not a bug)** — client added 3 new Pure-to-Write fields on the
Motor (PM) vehicle: `MVRBFUELTYPEDESCRIPTION`, `MVRBPOWER`, `MVRBTRACKREAR` (RedBook fuel type,
power, and rear track width). The corresponding real XML tags were hardcoded closed/empty:
`<FuelType/>`, `<TrackRear/>`, `<PowerKW>0</PowerKW>` — no view column, no template token, nothing
wired at all. Fixed in two parts, deployed and verified end-to-end in DEV 2026-07-14: `PER_COM_PAYLOAD`
now selects the 3 fields (see `sql/snowflake/1_conversion/PP/change_requests/
CR_PM_NewFields_FuelType_Power_TrackRear.sql`), and `PP_CONVERSION_RUN`'s Seq 18 template now
carries `{FUELTYPE}`/`{TRACKREAR}`/`{POWERKW}` tokens (see `CR_PM_NewFields_PP_CONVERSION_RUN.sql`
in the same folder). Confirmed in real generated XML: 1,696 of 3,937 policies now show real values
(e.g. `Petrol - Unleaded ULP` / `1580` / `158.0`), 0 blank tags remaining. **DEV only** —
`AGGNE.UAT.PM_03` doesn't have the 3 source columns yet; port to UAT once that Pure-to-Write gap
closes there too.


Single reference table combining what was previously split across `SEQ_FIX_MATRIX.md`,
`DEPLOYMENT_CHECKLIST.md`, and `CLIENT_TICKET_MAPPING.md`. Compiled 2026-07-10 from the live
seq-by-seq walkthrough (SEQ 1–18) — every status below was confirmed against live Snowflake/SQL
Server during that walkthrough, not carried over from stale docs.

**Status legend:**
- ✅ **Deployed** — confirmed live via DDL diff + post-validation
- 🟡 **Ready** — drafted, live-verified impact, no client input needed, not yet deployed
- 🔵 **Awaiting client** — question sent to Aggne/PMO, cannot code until answered
- 🔬 **Investigating** — root cause partially found, not yet ready to draft a fix
- ⚪ **Closed** — false positive or by-design, no action needed
- 🚫 **Blocked** — code fix exists but scope decision needed first

---

## By sequence

| Seq | Area | Gap | Layer | ATP/JIRA | Status |
|---|---|---|---|---|---|
| 1 | Claim History | G-15 | View | — | 🟡 Ready (validation-rule addition, no live defect) |
| 1 | Claim History | G-16 | View | — | ✅ Deployed |
| 2 | Prior Insurance | G-17 | View | — | ⚪ Closed (no fix needed — already correct) |
| 3 | Account Location | G-43 | SP/investigation | ATP-11110 | ⚪ Closed (false positive — original 235-count was a measurement error; real number is 2 of 4,006 policies, benign source-data fact) |
| 4 | HB Sub-Coverages | G-18 (Landlords part) | View | — | ✅ Deployed (view correct — see G-47, template ignores it) |
| 4 | HB Sub-Coverages | **G-47 (NEW)** | Config | — | ✅ Deployed (2026-07-10 batch — orchestrator regenerated fresh from SQL Server config, which already had this fix; post-deploy validation: "Seq4/10 Indicator variance (G-47)" went from 100%=1 to a real 20,891/6,595 split matching source) |
| 5 | HB UW Adjustments | G-19 (new finding) | SP | — | 🔵 Awaiting client (non-recurring adjustments exclusion, ~60-64%) |
| 5 | HB UW Adjustments | G-20 | View | — | ✅ Deployed (2026-07-13 — see dated note below; `BUILDING_UW` repointed to `Output_UWAdjust_PER`, `{HB_UW}` token added to seq7 template, validated: `BUILDING_UW` rows 877 stale→314 real, 254 real `<UnderwritingAdjustment>` blocks now appear vs 0 before) |
| 6 | HB Clauses | G-21 (seq6) | View | — | ✅ Deployed |
| 7 | Risk Building HB | G-22 | Config | — | ✅ Deployed |
| 7 | Risk Building HB | G-25 | Config | — | ✅ Deployed |
| 7 | Risk Building HB | G-23 | Config/View | — | 🔵 Awaiting client (likely false positive, bundled with G-34) |
| 7 | Risk Building HB | G-24 | Config | — | 🔵 Awaiting client (GlassLimit reuses HOMEBUILDINGSLIMIT) |
| 7 | Risk Building HB | G-26 | View | — | 🔵 Awaiting client (premium double-carry, 60.3% of HB+HC policies) |
| 8 | HC Items Exceeding Value | G-21 (seq8) | View | — | ✅ Deployed |
| 9 | HC Specified Contents | G-27 + G-21 (seq9) | View | — | ✅ Deployed |
| 10 | HC Sub-Coverages | G-18 (HC side) | View | — | ✅ Deployed (view correct — see G-47, template ignores it) |
| 10 | HC Sub-Coverages | **G-47 (NEW)** | Config | — | ✅ Deployed (2026-07-10 batch, same fix as seq 4 instance above — see that row for validation) |
| 11 | HC UW Adjustments | G-19 | SP | — | ⚪ Closed (false positive — correctly sourced, 2,995 real rows) |
| 12 | HC Clauses | G-21 (seq12) | View | — | ✅ Deployed |
| 13 | Risk Building HC | G-25 | Config | — | ✅ Deployed |
| 13 | Risk Building HC | G-28 | Config | — | ✅ Deployed |
| 13 | Risk Building HC | G-29 | Config | — | ✅ Deployed |
| 13 | Risk Building HC | G-30 | Config | — | ✅ Deployed |
| 13 | Risk Building HC | G-31 | Config | — | ✅ Deployed |
| 13 | Risk Building HC | G-32 | Config | — | ✅ Deployed |
| 13 | Risk Building HC | G-40 | View | **ATP-11107** | 🔵 Awaiting client (DCT node shape for itemized list; source data ready: 1,278 items/495 policies) |
| 14 | Risk Building (outer) | G-21 (seq14) | View | — | ✅ Deployed |
| 14 | Risk Building (outer) | G-33 | Config | — | 🔵 Awaiting client (SICCode hardcode, 100% of 1,392 rows) |
| 14 | Risk Building (outer) | G-34 | Config | — | 🔵 Awaiting client (bundled with G-23) |
| 14 | Risk Building (outer) | G-35 | Config | — | 🔵 Awaiting client (6 fabricated risk-assessment answers, 100% of rows) |
| 14 | Risk Building (outer) | G-36 | View | — | ⚪ Closed (validation-rule only, 0% invalid live, no view change) |
| 14 | Risk Building (outer) | G-41 | SP | **ATP-11105** | 🟡 Ready (2026-07-13 — root cause found: backwards `CASE` in `Locationdetails_PER` returns NULL instead of real year for every normal 4-digit rewire/replumb year; 787 rows confirmed affected; fix drafted, no client input needed, not yet deployed) |
| 15 | Motor Sub-Coverages | G-37 | Config/View | — | 🔵 Awaiting client (matrix needed; all 8 codes always on for every policy) |
| 16 | Motor UW Adjustments | G-19 | SP | — | ⚪ Closed (false positive — correctly sourced, 429 real rows) |
| 17 | Motor Clauses | G-38 | SP | — | 🚫 Blocked (needs full client-agreed clause-code mapping table, 0/179 codes currently valid) |
| 17 | Motor Clauses | G-39 (view part) | View | — | ✅ Deployed |
| 17 | Motor Clauses | G-39 (SP part) | SP | — | ✅ Deployed (2026-07-10 batch — post-deploy validation confirmed "COM_CLAUSE forced caps (G-39)" went 175→0) |
| 18 | Risk Building PM (Motor) | G-13 | Config | — | ✅ Deployed |
| 18 | Risk Building PM (Motor) | G-01 | View | — | 🔵 Awaiting client (NZ State value) |
| 18 | Risk Building PM (Motor) | G-02 | View | **ATP-10963** | ✅ Deployed (2026-07-10 batch, confirmed via DDL per the "actually deployed" note at top of this doc) |
| 18 | Risk Building PM (Motor) | G-03 (part 1) | SP | **ATP-10963** | ✅ Deployed (2026-07-10 batch — post-deploy validation: PM_01 BodyType/Cyl/Drive/Induction/ImportFlag blanks 6,488→~2,750-2,769 residual genuine, PER_COM_PAYLOAD blank BodyType 3,217→686) |
| 18 | Risk Building PM (Motor) | G-03 (part 2) | View | **ATP-10963** | 🔵 Awaiting client (unmapped BodyType values — list will grow as part 1's residual blanks get investigated) |
| 18 | Risk Building PM (Motor) | G-04 | View | — | ⚪ Closed (false positive) |
| 18 | Risk Building PM (Motor) | G-05 (part 1a) | SP | **ATP-10963** | ✅ Deployed (2026-07-10 batch, covered by same combined SP patch as G-06/G-09/G-10) |
| 18 | Risk Building PM (Motor) | G-05 (part 1b) | View | **ATP-10963** | ✅ Deployed (2026-07-10 batch — post-deploy validation: PER_COM_PAYLOAD zero cylinders 3,105→407, target ~512) |
| 18 | Risk Building PM (Motor) | G-05 (part 2) | SP | **ATP-10963** | 🔵 Awaiting client (512 genuine no-cylinder vehicles — omit tag or not?) |
| 18 | Risk Building PM (Motor) | G-06/G-09/G-10 | SP | **ATP-10963** | ✅ Deployed (confirmed live 2026-07-17 via full reload + DCT resubmission on P00000713 — InductionType/ImportFlag/NumberOfCylinders/EngineSize/GrossVehicleMass/DriveDescription all populated with correct value-code formats; DriveDescription was also independently reported by client as blank Drive Description dropdown in Express) |
| 18 | Risk Building PM (Motor) | G-07 | SP | — | 🔵 Awaiting client (VoluntaryExcess banding, 9 vehicles) |
| 18 | Risk Building PM (Motor) | G-08 | View | — | ✅ Deployed (2026-07-10 batch, confirmed via DDL per the "actually deployed" note at top of this doc) |
| 18 | Risk Building PM (Motor) | G-11 | SP | — | ✅ Deployed (confirmed live 2026-07-17 via full reload — `BUGFIX_SP_PURE_TO_WRITE_CylindersAndAge_20260717.sql`; min `AgeOfYoungestRegularDriver` across 4,351 rows is now 17, zero rows below threshold. Not a client decision — DCT manuscript hardcodes `VehiclePrivate.MinAge=17`) |
| 18 | Risk Building PM (Motor) | G-12 | View | — | ✅ Deployed (2026-07-10 batch, confirmed via DDL per the "actually deployed" note at top of this doc) |
| 18 | Risk Building PM (Motor) | G-42 | View | **ATP-11111** | ✅ Deployed (confirmed live 2026-07-16 — join fix present in `PER_COM_PAYLOAD`, `PMEXPPREM` 100% non-zero with real varied values; this row was stale) |
| 18 | Risk Building PM (Motor) | G-51 | View + Config | — | ✅ Deployed (DEV only — FuelType/TrackRear/PowerKW, new Pure-to-Write fields, was 3 hardcoded closed tags) |

---

## Cross-cutting / final-load (not tied to a single seq — run after all 18 seqs)

| Gap | Layer | ATP/JIRA | Status |
|---|---|---|---|
| G-44 | Final SP | **ATP-10961** | 🟡 Symptom fix ready (removes misleading 'Aaron Pang' default) / 🔬 root cause still investigating (only 16.7% of PP policies match ACCOUNT_HANDLER at all — likely a data-coverage gap, not a join bug) |
| G-45 | Needs input | **ATP-10962** | 🔵 Awaiting client (which DCT field is "Legacy Start Date"? `Protection_Term` has 0 overlap with PP's population — client's given source table isn't real, needs re-clarification) |
| G-46 | Investigation | **ATP-10965** | 🔬 Investigating (260 of 4,076 policies, 6.4%, show both Motor and HB/HC indicators — suggestive, not proven) |

## 2026-07-13 — G-20 (HB UW Adjustments, seq 5) DEPLOYED AND VALIDATED

Decided in-scope this session (previously "decision needed"). Root cause: `BUILDING_UW` view read
BP-scoped `Output_UWAdjust_BSP`/`LOCATION_BB_COVERAGE` (0/736 overlap with PP), and seq 7's template
had no `{UW}`-equivalent token at all — `<UWAdjustmentIndicator>` was hardcoded `0` for every policy
regardless of real data. Fixed via 3 coordinated deploys, file:
`docs/pp_mapping/seq_fixes/seq05_hb_uw_adjustments/view/G-20_DEPLOY.sql`:

1. `BUILDING_UW` view repointed to `Output_UWAdjust_PER` (COVERAGE='HB') joined to `HB_02`.
2. `PER_HOME_BUILDING_PAYLOAD` view — added new `HB_UW`/`HB_UW_INDICATOR` columns, sourced from
   `PER_BUILDING_TARGET WHERE ITR_TYPE='BUILDING_UW'`. Kept separate from the pre-existing `UW`
   column, which is HC-only (sourced from `PER_HC_TARGET`) — reusing it would have leaked HC's
   adjustments onto HB policies, a new cross-contamination bug.
3. SQL Server `PP_ConversionConfig` SequenceID=7 — added `{HB_UW}` token, replaced hardcoded
   `<UWAdjustmentIndicator>0</UWAdjustmentIndicator>` with `{HB_UW_INDICATOR}`.
4. `PP_CONVERSION_RUN` regenerated fresh from live config (same two-source-drift step as G-47/
   ATP-10842) — old copy was from the 2026-07-10 G-30 pass and had none of the intervening fixes.

Validated end-to-end: `PER_BUILDING_TARGET` `BUILDING_UW` rows 877 (stale, BP-sourced) → 314 (real,
matches dry-run exactly). Real payload `<UWAdjustmentIndicator>` now shows two buckets (2,975 at 0,
254 at 1) instead of 100% hardcoded 0. 254 real `<UnderwritingAdjustment>` blocks now appear in HB
XML (was 0). One data-quality note, not a defect: all 314 real HB adjustment rows carry a blank
`UWADJUSTNOTE` (amount only, no description text) — confirmed this is a pre-existing source pattern
shared by HC (243 blank) and SU (39 blank); only Motor/PM has real note text — identical shape to
the population G-50 already validated, so `<UnderwritingDescription></UnderwritingDescription>`
rendering empty alongside a real dollar amount is expected.

## 2026-07-13 — Two new findings from the "prep for client batch" pass

**G-DUP-01 — duplicate PER_FINAL / DCT rows (P1, ready to deploy).** Found while validating for
duplicate final/XML rows per policy. `AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD`'s build does
`SELECT DISTINCT POLICY_BINDER_ID, SCHEMENAME` over the FULL `PFPREMIUMFINANCE` history per policy
binder, with no way to pick the current plan — when a policy's finance plan changed (revised, or a
new plan with a different payment frequency), 2 distinct `PAYMENT_METHOD` rows survive for one
policy. `PER_CONVERSION_FINAL_LOAD` joins on this with no de-dup, so the extra row fans out into a
full extra `PER_FINAL` row. Confirmed live: 72 policies duplicated in `PER_FINAL`, propagating to
the real DCT-facing `PER_POLICY_MIGRATION_DCT` (71-72 duplicated there too) — would double-submit
quotes to DCT if run as-is. Root-cause-traced to genuine finance-plan revision history (e.g.
P00024003: an older 2024 renewal plan, then a 2025 plan revised from Monthly to Annually) — fixable
by keeping only the most recent finance-plan row per policy binder (`ROW_NUMBER()` by
`STARTDATE`/`PFPREM_FINANCE_CNT`/`PFPREM_FINANCE_VERSION` DESC). Fix drafted:
`seq_fixes/cross_cutting_final_load/sp/G-DUP-01_PAYMENT_METHOD_fix.sql`. Patches
`SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD`'s `POLICYCONVERSION_PAYMENT_METHOD` build.

**G-DUP-02 — `<ModNumber>10</ModNumber>` hardcoded for every policy (parked, needs more source
investigation).** Confirmed live in `PER_CONVERSION_FINAL_XML` — every single PP policy gets the
literal value `10`, not a derived value. Confirmed `ModNumber` is a real DCT field
(`TransACTConfig.xml`: `<Path name="modno" path="ModNumber" />`, tied to
`data/policyAdmin/transactions`), not decorative. BP's equivalent procedure
(`DEV_POLICY_INSERTPAYLOADINDCT.sql`) leaves it as `<ModNumber/>` (empty) rather than hardcoding —
neither LOB derives it from real data today. Searched the extracted SAS conversion scripts
(`ApplicantInformation_conversionscriptCapricorn.txt` — covers this same policy-header block — plus
a full keyword sweep) and found no direct mapping. Traced the "policy details/dates" source chain
per the user's hint: `PER_CONVERSION_FINAL_LOAD`'s dates (`EFFECTIVEDATE`/`EXPIRATIONDATE`/
`MEMBERSHIPSYSTEMDATE`) come from `AGGNE.DEV.PER_VW_SAMPLE_FINAL` → `AGGNE.DEV.SAMPLE_FINAL` (a
transient table with no lineage visible via `GET_DDL` — it's populated by some other load step not
yet traced) — none of `SAMPLE_FINAL`'s 15 columns carry a transaction/mod/version number. Next step
when resumed: find what populates `SAMPLE_FINAL` (likely another CREATE-TABLE-AS block inside
`SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` or a separate load SP) and check the raw `PURE_SNAPSHOT`
policy-binder/transaction tables it draws from for a genuine per-policy transaction sequence number.
Explicitly deferred by user 2026-07-13 — deploy G-DUP-01 and continue the batch-prep plan first.

**G-DUP-01 validated 2026-07-13**: deployed and re-run. `POLICYCONVERSION_PAYMENT_METHOD` 191,054 →
189,525 rows (now exactly 1 row per `POLICY_BINDER_ID`, zero duplicates). After the full
`PP_CONVERSION_RUN(TRUE)` reload, `PER_FINAL` duplicates dropped from 72 policies to 1 (P00027855);
`PER_POLICY_MIGRATION_DCT` duplicates dropped from 71 to 1 correspondingly. 99.97% resolved.

**G-DUP-03 (NEW, 2026-07-13) — one residual duplicate, different root cause, likely a race
condition.** P00027855 still shows 2 `PER_FINAL` rows with different `PARTYID` values, sourced from
`AGGNE.UAT.VW_PARTYDET` (joined on `CML_NUMBER`). Checked both `VW_PARTYDET` (already has its own
`QUALIFY ROW_NUMBER()...=1` dedup, confirmed 0 duplicate `CML_NUMBER`s live) and
`AGGNE.DEV.DIM_PARTY_CML_CSL_NEW` (confirmed 1 row for this CML) — both clean right now. Most likely
explanation: `VW_PARTYDET`'s source, `AGGNE.UAT.CML_MIGRATION_DCT`, is written to by an external
process (probably the DCT-push automation noted in `project_psd_timer_trigger.md`) and had a
transient 2-row state for this CML at the exact moment `PER_CONVERSION_FINAL_LOAD` ran. Not a code
bug in this pipeline's SQL — a timing/concurrency risk when the reload runs at the same moment
`CML_MIGRATION_DCT` is being refreshed. Low severity (1 of 3,987 policies).

**Correction after re-running `PP_CONVERSION_RUN(FALSE)`**: did NOT self-resolve — P00027855 still
showed 2 rows, with a FRESH `LOAD_DATE` matching the table's own max (i.e. genuinely written by the
latest run, not stale). Re-traced: `AGGNE.DEV.PER_VW_SAMPLE_FINAL` (the base table everything else
LEFT JOINs onto) shows **0 rows** for this policy when queried immediately after — meaning at the
moment `PER_CONVERSION_FINAL_LOAD`'s `CREATE TABLE AS SELECT` executed, the underlying
`SAMPLE_FINAL`/`SAMPLE_PER` tables had 2 rows for this policy (a genuine multi-row source state at
that instant), and that state had already changed again by the time of the next query. Confirmed
`DIM_PARTY_CML_CSL_NEW` and `VW_PARTYDET` are both single-row/clean for this CML at every check —
ruling out the join-fanout theory. Conclusion: this is upstream data volatility in
`SAMPLE_FINAL`/`SAMPLE_PER` (likely another concurrent process refreshing them in this shared
environment), not a defect in this pipeline's SQL. At 1-in-3,987 (0.025%) and self-shifting between
runs, not worth further chase this session — parked. Worth a spot-check during the UAT batch
validation (Phase 5) to confirm it isn't recurring at meaningful scale there.

---

## ATP ticket index (client-facing tickets only)

| ATP | Summary | Gap(s) | Status |
|---|---|---|---|
| ATP-10963 | Personal motor vehicles failing to transfer | G-02, G-03, G-05, G-06, G-09, G-10 | Mixed — G-02/G-03pt1/G-05pt1/G-06/G-09/G-10 ready to deploy; G-03pt2/G-05pt2 awaiting client |
| ATP-11107 | Specified Items Away from the Premises not migrated | G-40 | Awaiting client (DCT node shape) |
| ATP-11105 | Rewired/Replumbed dates not migrated | G-41 | Investigating |
| ATP-11111 | Private Motor section not generating contribution amounts | G-42 | Deployed and confirmed live (2026-07-16) |
| ATP-11110 | Location 1 property sections missing | G-43 | Closed — false positive |
| ATP-10961 | Account handler default incorrect | G-44 | Symptom fix ready; root cause still open |
| ATP-10962 | Legacy start date incorrect | G-45 | Awaiting client |
| ATP-10965 | Motor Only protections migrating with Location sections | G-46 | Investigating |
| ATP-11112 | Age of regular driver has increased (renewal) | Related to G-11, not merged | Needs its own check — different symptom (renewal recompute, not initial-conversion threshold) |
| ATP-10842 | Windscreen Glass Excess incorrect | Related to G-37, not merged | Needs its own check — different flag than G-37's Unlimited Glass |
| ATP-11106 | Unspecified Items Away from Premises not migrated | — | Checked, not a bug — already correct |
| ATP-10845, ATP-10841, ATP-10808, ATP-10844, ATP-10843 | Various | — | Confirmed BP scope, not PP — closed |

---

## Summary counts

**Recomputed 2026-07-17** — the previous version of this section was frozen from before the
2026-07-10 batch deploy and never updated afterward (it still listed G-02/G-03pt1/G-05pt1a-1b/G-08/
G-12/G-39-SP-part/G-06/G-09/G-10 as "Ready", all of which the row-level table above already showed
deployed with live validation numbers). Recomputed directly from the corrected "By sequence" +
"Cross-cutting" tables above. Counted by **distinct gap number** (G-18, G-21, G-25, G-47 each span
multiple sequences — counted once, not once per sequence; G-19 and G-03/G-05 legitimately appear in
two buckets each since they split into genuinely separate findings/parts with different statuses):

- **Deployed and verified: 26** — G-02, G-03 (part 1), G-05 (parts 1a/1b), G-06, G-08, G-09, G-10,
  G-11, G-12, G-13, G-16, G-18, G-19 (seq11/16 instance — closed as false positive, not counted here,
  see Closed below), G-20, G-21, G-22, G-25, G-27, G-28, G-29, G-30, G-31, G-32, G-39, G-42, G-47,
  G-51.
- **Ready to deploy, no client input needed: 2** — G-15, G-41.
- **Awaiting Aggne/client: 14** — G-01, G-03 (part 2), G-05 (part 2), G-07, G-19 (new finding), G-23,
  G-24, G-26, G-33, G-34, G-35, G-40, G-44 (symptom fix retracted 2026-07-10 — back to "needs Aggne
  decision", not ready), G-45.
- **Investigating, not yet ready to draft: 1** — G-46.
- **Closed — false positive / by design, no action: 5** — G-04, G-17, G-19 (original claim, seq 11
  and seq 16), G-36, G-43.
- **Blocked — scope decision needed: 1** — G-38.

Total tracked: 49 distinct gap-numbers/parts.
