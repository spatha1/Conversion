# PP Gap Deployment Checklist

Single tracker for all 41 gap-instances (39 gaps, G-18 and G-38 each split into a fixable part and
a needs-input part). Check items off here as they move — this replaces re-deriving status from
the conversation each time. Last synced: 2026-07-10.

## 0. Validation run — needed before checking off any "Bug fixed" item below

**CRITICAL, found 2026-07-10:** `AGGNE.DEV.PP_CONVERSION_RUN` is the real conversion orchestrator
and has all 18 templates hardcoded in its own procedure body — it does NOT read SQL Server
`PP_ConversionConfig` at call time. The two must be synced manually. Confirmed out of sync for
today's G-25/G-32 fixes (in sync for the 5 earlier ones). See
`feedback_verify_live_not_repo.md` addendum 2.

- [x] Run `PP_CONVERSION_RUN_REGENERATED_FROM_CONFIG.sql` (Snowflake) — regenerated
      `PP_CONVERSION_RUN` with all 18 templates pulled fresh from live `PP_ConversionConfig`.
      **Still to do:** copy the body into `sql/snowflake/1_conversion/PP/sps/DEV_PP_CONVERSION_RUN.sql`
      so the repo copy matches too.
- [x] **BUG-NEW-04 found 2026-07-10** — `PER_CONVERSION_FINAL_LOAD` line 52 did
      `CAST(PROBABILITY_OF_DEFAULT AS NUMBER(5,2))` but the column is text ('LowRisk'/'HighRisk'
      only). Fixed via `PER_CONVERSION_FINAL_LOAD_FIX_BUG-NEW-04.sql` — confirmed working,
      `PER_FINAL` now populates cleanly (4,076 rows, no cast error).
- [x] Ran `PP_VALIDATION_RUN.sql` (Snowflake) — Pure-to-Write → `PP_CONVERSION_RUN(TRUE)` →
      final load/XML, completed end to end with no errors.
- [x] Spot-checked generated XML for seq 7/13 — **G-25 (0 rows still `HH`/`HBC`) and G-32 (0 rows
      still showing 9100/622221) both confirmed fixed in real payload**, not just template text.
- [ ] Going forward: whenever `PP_ConversionConfig` changes, also check whether
      `PP_CONVERSION_RUN`'s embedded copy needs the same edit (diff via
      `GET_DDL('PROCEDURE', 'AGGNE.DEV.PP_CONVERSION_RUN(BOOLEAN)')`)

## 1. Email sent — awaiting Aggne policy team / client response (16)

- [x] G-01 — State/NZ
- [x] G-03 — BodyType 'Other'/'Cab Chassis' mapping
- [x] G-05 — NumberOfCylinders for engine-less vehicles
- [x] G-07 — VoluntaryExcess re-banding above $1,000
- [x] G-11 — AgeOfYoungestRegularDriver 16 vs 17 threshold
- [x] G-18 (Landlords) — Landlord Protections taken flag
- [x] G-19 (new finding) — non-recurring UW adjustments excluded
- [x] G-20 — HB UW Adjustments in scope?
- [x] G-23 — HB excess breakdown applicability
- [x] G-24 — GlassLimit intent
- [x] G-26 — Premium double-carry / does DCT sum
- [x] G-33 — SICCode blank vs specific value
- [x] G-34 — Risk-level excess breakdown applicability
- [x] G-35 — Fabricated risk-assessment answers
- [x] G-37 — Motor sub-coverage matrix
- [x] G-38 (Part 2) — CM_*→PM_* clause code mapping

*Sent via `EMAIL_SP_NeedInput.md` / `EMAIL_CLIENT_FieldQuestions.md`. Nothing to do here until a
reply arrives — re-check this list against the reply when it comes in, item by item.*

## 2. Bug fixed, need to validate XML (8)

- [x] G-02 — Year/Make/Model filter removed (2026-07-09)
- [x] G-13 — RedbookCode token (found already-deployed 2026-07-10)
- [x] G-22 — HB Indicator token (found already-deployed 2026-07-10)
- [x] G-25 — ClassCode HH/HBC → FISR/BSP (deployed 2026-07-10)
- [x] G-28 — `{clauses}` → `{HC_CLAUSE}` (found already-deployed 2026-07-10)
- [x] G-29 — HC Indicator token (found already-deployed 2026-07-10)
- [x] G-31 — HomeContentsLimits token (found already-deployed 2026-07-10)
- [x] G-32 — HomeContentsTotal/SpecifiedContentsTotal blanked (deployed 2026-07-10)

**Not checked off until Section 0's validation run confirms each in real generated XML — config/view
text being correct is necessary but not sufficient.**

## 3. Pending SP (5) — fully drafted 2026-07-09, ready to deploy from `seq_fixes/`

- [x] G-06 — InductionType: fallback to plain MVRBInduction when MVCVOverride<>1 (dead
      `Override='Yes'` gate removed, live-verified — see `seq18_risk_building_pm/sp/G-06_fix.sql`).
      Also picked up 2 undrafted same-root-cause fields: NumberOfCylinders, DriveDescription.
- [x] G-09 — ImportFlag: same fallback pattern, trims literal — same file as G-06.
- [x] G-10 — EngineSize/GrossVehicleMass: same fallback pattern — same file as G-06.
- [x] G-38 (Part 1) — Clause codes: **correction to original draft** — removing `UPPER()` does
      NOT fix this (raw Pure codes already uppercase, confirmed against
      `PRD_T5_EXTERNAL_AGGNE.PURE.PER_CLAUSEAMENDMENTMV`). Root cause is a naming-convention
      mismatch (Pure's `PM_C03_LEARNER` vs DCT's `PMLearnerextension`) needing a full client-agreed
      mapping table — converted to a needs-input note, see `seq17_motor_clauses/sp/G-38_fix.sql`.
- [x] G-39 — Clause descriptions: stop `UPPER()`-ing `CADescription` (cosmetic, confirmed safe) +
      added XML-escaping to `COM_CLAUSE.DCINPUT` (shares G-21) — see
      `seq17_motor_clauses/sp/G-39_fix.sql`.

*G-06/G-09/G-10 share the same root cause — applied as one combined code-only SP patch, not three
separate edits. Live impact turned out far larger than originally scoped: 6,488 of 7,312 (89%) PM
vehicle rows affected, not just the narrower InductionType/ImportFlag/EngineSize/GrossVehicleMass
set.*

## 4. Pending Config (1) — drafted 2026-07-09, ready to deploy

- [x] G-30 — FloodDamage: view prerequisite confirmed live (`FLOODDAMAGE` returning 1,615 Not
      Taken / 216 Taken); config token swap drafted as a standalone deployable script — see
      `seq13_risk_building_hc/config/G-30_fix.sql`.

## 5. Pending Views (9) — drafted 2026-07-09, ready to deploy from `seq_fixes/`

- [x] G-08 — RegistrationNumber: uppercase + strip non-alphanumeric. Live: 336 of 3,304 rows
      invalid format; 273 are genuine bad-data (VIN/serial typed into rego), only 63 are true
      formatting fixes — added a separate validation-report rule for the 273. See
      `seq18_risk_building_pm/view/G-08_fix.sql`.
- [x] G-12 — VehicleType: allow-list to the 9-code Override=1 set. 0 live impact today (hardening
      only) — see `seq18_risk_building_pm/view/G-12_fix.sql`.
- [x] G-15 — DateOfClaim: validation-report rule only (no view change) — see
      `seq01_claim_history/view/G-15_fix.sql`.
- [x] G-16 — Cause: caption→code CASE — see `seq01_claim_history/view/G-16_fix.sql`.
- [x] G-17 — PriorCarrier: **re-investigated, no fix needed** — the original draft's proposed
      mapping was already superseded live; production data confirms current behavior is correct.
      See `seq02_prior_insurance/view/G-17_fix.sql`.
- [x] G-18 (Flood/ALD/structural, HC side) — Indicator derived from existing sValue/limit columns.
      Live impact bigger than expected: 1,196 of 2,553 policies (46.8%) show Accidental-Damage
      Indicator=1 despite sValue=NotTaken. See `seq10_hc_subcoverages/view/G-18_fix.sql`.
- [x] G-21 — XML-escape free text across 6 views (seq 6/8/9/12/14/17). Live-breaking today in 2:
      `PER_HC_ITEMS_EXCEED_VALUE` (25 rows), `PER_HC_SPECIFIEDCONTENTS` (15 rows, combined with
      G-27). Hardening-only in the other 4 (0 current unsafe rows). See `G-21_fix.sql` in each
      seq's `view/` folder.
- [x] G-27 — HC Specified Contents: empty-item filter, combined with G-21 for this view — see
      `seq09_hc_specified_contents/view/G-27_fix.sql`.
- [x] G-36 — Construction/security dropdowns: confirmed 0% invalid live — converted to a
      validation-report rule (no view change) — see
      `seq14_risk_building_outer/view/G-36_fix.sql`.

## 6. Closed — False Positive, no action (3)

- [x] G-04 — DriveDescription (view already maps captions to codes correctly)
- [x] G-19 (original claim) — AdjustmentSelection/Recurring hardcodes confirmed correct
- [x] G-43 — original claim measured at wrong grain (235 policies); real number is 2 of 4,006
      (0.05%), traced to a source-data fact (PURE-side location deletion), not a conversion bug

---

## 7. New gaps from client ticket cross-reference (2026-07-09) — G-40 through G-46

Source: 13 client tickets from `files/Issues/Conversion/` (epic ATP-10219) that didn't match any
of G-01...G-39 — see `CLIENT_TICKET_MAPPING.md`. 6 had a findable PURE field/DCT path and were
validated live; 7 are scope-uncertain (Product & Public Liability / Professional Protection / other
Motor add-ons not found in any PP-scope manuscript) and were **not** validated — not counted below.

- [x] G-42 — Motor Premium (PMEXPPREM) always 0 (100% of 3,304 rows). **P1, confirmed root
      cause**: composite-vs-plain key mismatch in `PER_COM_PAYLOAD`'s join to `Output_Coverage_PER`.
      No input needed — drafted with pre/post validation, see
      `seq18_risk_building_pm/view/G-42_fix.sql`.
- [x] G-44 — Account Handler defaults to 'Aaron Pang' for 3,424 of 4,076 policies (84%). Symptom
      fix drafted (safe to apply now). Investigation query run live 2026-07-09: only 669 of 4,004
      PP policies (16.7%) exist ANYWHERE in `ACCOUNT_HANDLER` regardless of join conditions — this
      looks like a genuine data-coverage gap (table may not be scoped to cover PP), not a join-logic
      bug, but still needs Aggne to confirm and decide the correct fallback. See
      `cross_cutting_final_load/final/G-44_fix.sql`.
- [ ] G-40 — HC Specified Items Away From Premises: itemized description/value list never built
      (only the Taken/Not-Taken flag exists, 195 of 1,831 policies affected). Needs client input on
      the target DCT node shape before a view can be drafted — added to
      `EMAIL_CLIENT_FieldQuestions.md` as question #17.
- [ ] G-45 — "Legacy Start Date" — no column in `PER_FINAL` carries that literal name; needs the
      client to confirm which DCT field/path this refers to — added as question #18.
- [ ] G-41 — YearLastReWired/YearLastRePlumbed blank for 558 of 584 buildings aged 41+ (95.5%).
      View/config confirmed correct; root cause is further upstream, not yet located — needs more
      investigation before a fix can be drafted.
*(G-43 moved to Section 6, Closed — False Positive.)*
- [ ] G-46 — PURE Motor-Only protections migrating with Location sections selected. 260 of 4,076
      policies (6.4%) show both Motor and HB/HC indicators set — suggestive, not proof; needs a
      PURE-side source comparison before it's confirmed.

---

## Running total

| Section | Done | Remaining |
|---|---|---|
| 1. Email sent | 16 sent | 16 awaiting reply |
| 2. Bug fixed | 8 deployed | 8 need XML validation (Section 0) |
| 3. Pending SP | 0 | 5 |
| 4. Pending Config | 0 | 1 |
| 5. Pending Views | 0 | 9 |
| 6. Closed | 2 | 0 |
| 7. New (G-40...G-46) | 0 | 7 (2 fixable now, 2 need client input, 3 need investigation) |
| **Total** | **26 / 48 have a deployed, drafted, or sent action** | **22 items still to resolve** |
