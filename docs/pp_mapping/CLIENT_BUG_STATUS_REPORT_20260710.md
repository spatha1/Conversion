# Client Bug Status Report — 2026-07-10

Per-ATP status with RCA, fix status, and a reusable evidence query for each (run against `AGGNE.DEV`
today; same query works against `AGGNE.UAT.PER_POLICY_MIGRATION_DCT` once a UAT batch is re-run —
just swap the schema).

## High-level summary

| ATP | G# | Status |
|---|---|---|
| ATP-10963 | G-02, G-03, G-05, G-06, G-09, G-10 | ✅ Fixed & Validated (core) — G-03pt2/G-11 sub-items still 🔵 client question; G-07/G-05pt2 now resolved, see below |
| ATP-11111 | G-42 | ✅ Fixed & Validated |
| ATP-11110 | G-49 | ✅ Fixed & Validated |
| ATP-11117 | G-49 | ✅ Fixed & Validated |
| ATP-11115 | G-49 | ✅ Fixed & Validated |
| ATP-10842 | scoped out of G-37 | ✅ Fixed & Validated (end-to-end, real payload confirmed) |
| ATP-11107 | G-40 | ✅ Fixed & Validated (end-to-end, real payload confirmed 2026-07-13 — client gave the XML path; one-item-per-policy limitation noted, see full entry below) |
| ATP-11105 | G-41 | ✅ Fixed & Validated (end-to-end, real payload confirmed) |
| — | G-07 | ✅ Fixed & Validated (end-to-end, 2026-07-13 — client confirmed $1,500 cap; real payload shows all 7 valid DCT tiers, zero invalid values) |
| — | G-20 | ✅ Fixed & Validated (end-to-end, 2026-07-13 — HB UW Adjustments now flow from the correct PP-scoped source; real DCT payload shows 249 policies with a genuine adjustment, was 0) |
| — | G-DUP-01 (NEW) | ✅ Fixed & Validated (2026-07-13 — duplicate PER_FINAL/DCT rows from unresolved payment-plan history; 71 of 72 duplicated policies resolved, 1 residual traced to unrelated source-table timing, not a regression) |
| — | G-05 pt2 | ⚪ Closed — client confirmed blank-stays-blank is correct, matches our existing fix, no further action |
| ATP-10961 | G-44 | 🔵 Client question (fix retracted — Producer field risk) |
| ATP-11116 | G-48 | 🔵 Client question (bundle w/ G-23, G-34) |
| ATP-10965 | G-46 | 🔬 Investigating |
| ATP-10962 | G-45 | ⚪ Not yet analyzed |
| ATP-11112 | related G-11 | 🔬 Investigated, lead did not hold up — needs a specific policy number to trace further |
| ATP-10842 (context) | related G-37 | see row above — the other 7 sub-coverage codes remain 🔵 client question |
| ATP-11113 | related G-07 | ⚪ Needs clarification — doesn't match described symptom |
| ATP-11123 | — | ⚪ Closed — already correct |
| ATP-11106 | — | ⚪ Closed — not a bug |
| ATP-10845/10841/10808/10844/10843 | — | ⚪ Closed — BP scope |
| ATP-10904 | — | ⚪ **Reclassified BP, not PP** (2026-07-13) — "Hail/Malicious Damage Excess, Customer Vehicles" is `ContentsAndStocksInput`, a Business/Commercial concept (matches BP's `CustomerVehicle`/`StockVehicles` fields), not a Personal Motor field. Hand to BP. |
| ATP-11089, ATP-11042 | **G-50 (NEW)** | ⚪ **Ticket ownership reclassified BP** (2026-07-13) — both appear on the BP team's own tracked board (`files/Issues/BP Conversion/BP_Issues_ATP-10219_12072026.html`), assigned to Raju. G-50 itself stays ✅ Fixed & Validated — it's a real, independent bug in PP-specific infrastructure (`SP_PP_ADJ_EXP_PREM`), confirmed and fixed regardless of ticket ownership. But it may not be "the" fix these two tickets were filed about if they're reporting a BP-side symptom — flag to Raju that the same NULL=NULL join pattern is worth checking on BP's equivalent adjustment pipeline. |
| ATP-11151/11145/11088/11086/10980/10979/10906/10903/11041 (9 remaining tickets) | — | ⚪ **Reclassified BP** (2026-07-13) — all 9 confirmed present on the BP team's own tracked board, assigned to Raju. Handing off, no longer tracked as PP-unclassified. |

---

### ATP-11089 / ATP-11042 — Recurring adjustments not migrating / % vs $ mismatch (G-50, NEW)

- **Policy Number:** Aggregate — 15,913 total UW adjustment rows across all PP policies
- **Issue:** Recurring underwriting adjustments (loadings/discounts) that should carry through to
  the schedule show blank instead of their dollar amount.
- **RCA:** Investigated as a possible duplicate of G-19 (recurring-vs-non-recurring filtering) — it
  is not. G-19 only affects which adjustments get a row at all; this is a separate bug in how the
  dollar amount is computed for the rows that DO exist. `Adjustments_PER_Out` (inside
  `SP_PP_ADJ_EXP_PREM`) joins `ExpPremium_PER` to `Adjustments_PER` on `Vehicle_ID` using a plain
  `=` comparison. For HB/HC/SU (non-vehicle coverages), `Vehicle_ID` is `NULL` on both sides — and
  `NULL = NULL` is not true in SQL, so the join silently fails every time. Confirmed:
  `Output_UWAdjust_PER.UWAdjustAmount` is NULL for 97.3% of all rows (15,476 of 15,913) — 100% for
  HB, HC, and SU, and even Motor (PM, which mostly has real matching vehicle IDs) is 90.1% NULL.
- **IsFixed:** Yes — confirmed 2026-07-13.
- **Comment:** Deployed and validated. Recovery matched the pre-deploy simulation exactly: HC
  243 rows recovered, HB 314 rows, SU 39 rows (596 total) — went from real dollar values NULL to
  populated. PM (Motor) correctly unaffected (0 change, no regression) since its join was already
  mostly working. Confirmed `SP_PP_ADJ_EXP_PREM()` is called automatically inside the main
  Pure-to-Write SP (line ~11294) — this fix triggers on every normal run going forward, no separate
  manual step needed. Also discovered while wiring-checking: `BUILDING_UW` (seq 5, HB UW
  Adjustments) reads from a completely different table (`Output_UWAdjust_BSP`, not
  `Output_UWAdjust_PER`) — matches the already-known **G-20** finding (wrong Business/BSP source
  table). So this fix helps HC and Motor; HB's UW adjustment problem is G-20's, separate and still
  open (awaiting client per that gap's status). ATP-11042's "% vs $" symptom not yet independently
  re-confirmed against the live payload — worth a follow-up check.
- **Query for evidence:**
  ```sql
  SELECT COVERAGE, COUNT(*) TOTAL, SUM(CASE WHEN UWADJUSTAMOUNT IS NULL THEN 1 ELSE 0 END) NULL_AMOUNT
  FROM AGGNE.DEV.Output_UWAdjust_PER GROUP BY 1;
  -- Confirmed: HC 3046/3289, HB 3581/3895, SU 4996/5035, PM 3970/4407 (unchanged, no regression)
  ```

**Tally:** 13 fixed & validated (adds G-20 and G-DUP-01, 2026-07-13; 1 of the 13, G-50, has
ticket-ownership ambiguity — see note) · 1 client-question · 1 investigating · 1
investigated-inconclusive · 9 closed · 11 reclassified-BP · 0 unclassified · 2 blocked pending
client clarification (G-45 table mismatch, plus G-11/G-03pt2/G-38/G-33 unresolved from the 13 July
MoM). One additional low-severity internal finding not tied to any client ticket (G-DUP-03, a single
residual duplicate policy traced to unrelated source-table timing) — parked, not client-facing.

### G-07 — Voluntary Excess (Motor) banding wrong + no cap (fixed 2026-07-13)

Client confirmed (13 July MoM): cap at $1,500 if PURE exceeds it. Root cause was bigger than the cap
alone — banding used the wrong tier set entirely ($0/$500/$1,000/$2,000/$5,000 instead of DCT's real
$0/$250/$500/$750/$1,000/$1,250/$1,500 ladder). Fixed in `PM_01` build (Pure-to-Write SP) — see
`seq_fixes/seq18_risk_building_pm/sp/G-07_fix.sql`. Validated end-to-end: real payload now shows all
7 valid tiers (0: 3,124 / 250: 77 / 500: 68 / 750: 7 / 1,000: 15 / 1,250: 4 / 1,500: 5), zero invalid
values.

### G-20 — HB UW Adjustments (fixed 2026-07-13)

Underwriting adjustments for Home Building coverage were never reaching DCT — `BUILDING_UW` (seq 5)
read from BP-scoped `Output_UWAdjust_BSP`/`LOCATION_BB_COVERAGE` (0 of 736 policies overlapped with
PP), and seq 7's template hardcoded `<UWAdjustmentIndicator>0</UWAdjustmentIndicator>` with no token
to carry the adjustment text at all. Fixed via 3 coordinated changes — see
`seq_fixes/seq05_hb_uw_adjustments/view/G-20_DEPLOY.sql`: repointed `BUILDING_UW` to the correct
PP-scoped source (`Output_UWAdjust_PER` + `HB_02`), added a new `HB_UW`/`HB_UW_INDICATOR` column
pair to `PER_HOME_BUILDING_PAYLOAD` (kept separate from the pre-existing `UW` column, which is
HC-only — reusing it would have leaked HC's adjustments onto HB policies), and added the `{HB_UW}`/
`{HB_UW_INDICATOR}` tokens to seq 7's config template. `PP_CONVERSION_RUN` regenerated from config
afterward (same two-source-drift step needed for every config change). Validated end-to-end: real
DCT payload (`AGGNE.DEV.PER_POLICY_MIGRATION_DCT`) now shows **249 policies** with a genuine
`<UWAdjustmentIndicator>1</UWAdjustmentIndicator>` and real adjustment text, was 0 before.
- **Query for evidence:**
  ```sql
  SELECT COUNT(*) TOTAL,
      SUM(CASE WHEN REQUEST_XML LIKE '%<UWAdjustmentIndicator>1</UWAdjustmentIndicator>%' THEN 1 ELSE 0 END) HAS_HB_UW
  FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;
  -- Confirmed 2026-07-13: 249 policies with a real HB UW adjustment (was 0)
  ```
- **Data-quality note, not a defect:** all real HB adjustment amounts carry a blank description
  (amount-only) — confirmed this is a pre-existing source pattern shared with HC/SU adjustments
  (G-50's population); only Motor carries real note text.

### G-DUP-01 — Duplicate PER_FINAL / DCT rows from unresolved payment-plan history (fixed 2026-07-13)

Found while validating for duplicate final/XML rows per policy ahead of the batch. `AGGNE.DEV.
POLICYCONVERSION_PAYMENT_METHOD`'s build kept every historical finance-plan row per policy binder
instead of just the current one — when a policy's payment plan had been revised (e.g. Monthly →
Annually), both survived, and `PER_CONVERSION_FINAL_LOAD`'s join fanned that into a full duplicate
`PER_FINAL` row. Confirmed this reached the real DCT-facing table too — would have submitted
duplicate quotes for the affected policies. Fixed by keeping only the most recent finance-plan row
per policy (ordered by `STARTDATE`, then the plan's own version history) — see
`seq_fixes/cross_cutting_final_load/sp/G-DUP-01_PAYMENT_METHOD_fix.sql`. Validated end-to-end: 72
duplicated policies → 1 residual (down 99%); the 1 remaining case (P00027855) traced to unrelated
source-table timing volatility in `SAMPLE_FINAL`/`SAMPLE_PER` (a different, upstream table refreshed
by another process), not a regression of this fix — see G-DUP-03 in `SEQ_GAP_ATP_MASTER.md`.
- **Query for evidence:**
  ```sql
  SELECT COUNT(*) TOTAL, COUNT(DISTINCT LEGACYPOLICYNUMBER) DISTINCT_POLICIES
  FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;
  -- Confirmed 2026-07-13: 3,940 / 3,939 (was 4,010 / 3,939 — 71 fewer duplicate rows, same policy count)
  ```
- **Not client-raised** — found internally during batch prep, included here for completeness since
  it directly affects quote-submission integrity, not because a ticket was filed for it.

### G-40 — Specified Items Away From Premises (fixed 2026-07-13, with a known limitation)

Client gave the exact XML path (`SpecifiedContents/Description`, `SpecifiedContents/Value`) — same
node `PER_HC_SPECIFIEDCONTENTS` (seq 9) already emits for "specifically scheduled" items. Extended
that view with a UNION ALL sourcing the away-from-premises pair from the same `HC_02` table — see
`seq_fixes/seq09_hc_specified_contents/view/G-40_fix.sql`. **First draft was built against a stale
repo copy of the view and would have regressed G-27's empty-item filter and G-21's XML escaping —
caught before deploy, corrected against a fresh live pull.** Validated end-to-end: real payload grew
161→314 rows, 100% with real descriptions (was 0% for the away-from-premises category before).
**Known limitation, worth telling the client**: `HC_02` dedups to one row per policy/location
(`RN_LAST=1`), so this can only ever surface *one* away-from-premises item per policy, not the full
list (true source `HC_AWAY` has 1,278 items across 495 policies, ~2.6/policy average). This is a
pre-existing limitation shared with the already-working "specifically scheduled" branch (confirmed:
161 rows = 161 distinct policies there too, vs 1,188 items across 405 policies in the true source) —
not a new regression, but not the complete list either.

**Same-day lesson worth flagging:** two "ready" fixes this session (ATP-10842's v1, and today's earlier
Sample_CBP_ surprise) turned out to need correction after deployment — underscores why every fix in
this report gets re-verified against live data/payload before being called done, not just marked done
because the code looked right.

---

### ATP-10963 — Personal motor vehicles failing to transfer (G-02, G-03, G-05, G-06, G-09, G-10)

- **Policy Number:** All PP Motor policies (aggregate — 3,307 vehicle rows)
- **Issue:** BodyType, NumberOfCylinders, InductionType, ImportFlag, EngineSize, GrossVehicleMass,
  DriveDescription blank/invalid for the majority of vehicles; YMM filter silently dropped rows.
- **RCA:** PM_01's Override-driven CASE blocks only computed a value when `MVCVOverride=1` (a RedBook
  override actually matched) — the 89% of vehicles without an override fell through to blank/NULL
  instead of the plain non-override RedBook column PM_01 already had. Separately, NumberOfCylinders
  was COALESCE'd to an invalid literal `'0'` at the view layer.
- **IsFixed:** Yes (mostly — G-03pt2/G-05pt2/G-07/G-11 sub-items still open, see below)
- **Comment:** Validated in DEV today — PM_01 blanks dropped from 6,488 to ~2,750 (residual = genuine
  raw source blanks, confirmed via business-rule sanity check); PER_COM_PAYLOAD blank BodyType
  3,217→686, zero-cylinder rows 3,105→407. Cross-checked against the same real policies in
  `AGGNE.UAT.PER_POLICY_MIGRATION_DCT`: blank BodyType 22→6, zero cylinders 22→4 in the actual
  generated XML.
- **Query for evidence:**
  ```sql
  SELECT COUNT(*) TOTAL,
      SUM(CASE WHEN REQUEST_XML LIKE '%<BodyType/>%' THEN 1 ELSE 0 END) BLANK_BODYTYPE,
      SUM(CASE WHEN REQUEST_XML LIKE '%<NumberOfCylinders>0<%' THEN 1 ELSE 0 END) ZERO_CYLINDERS
  FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT;  -- swap AGGNE.DEV -> AGGNE.UAT once UAT batch reruns
  ```
- **Still open under this ATP:** G-03pt2 (unmapped BodyType values — client question), G-05pt2
  (omit-tag decision for 512 genuinely cylinder-less vehicles), G-07 (VoluntaryExcess re-banding),
  G-11 (age threshold 16 vs 17) — all awaiting Aggne/client answers, not code-blocked.

---

### ATP-11111 — Private Motor section not generating contribution amounts (G-42)

- **Policy Number:** All PP Motor policies (aggregate — 3,307 vehicle rows)
- **Issue:** Motor Premium (`PMEXPPREM`) always 0.
- **RCA:** `PER_COM_PAYLOAD`'s join to `Output_Coverage_PER` compared a composite key
  (`LEGACYPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P`) against a plain policy number column — never
  matched, so the COALESCE-to-0 fallback fired for every row.
- **IsFixed:** Yes
- **Comment:** Validated in DEV today — 0 of 3,307 rows now show zero premium (was 100%).
- **Query for evidence:**
  ```sql
  SELECT COUNT(*) TOTAL, SUM(CASE WHEN PMEXPPREM='0' THEN 1 ELSE 0 END) ZERO_CNT
  FROM AGGNE.DEV.PER_COM_PAYLOAD;  -- staging-level; XML-level check needs a Motor-scoped <Premium> extraction, not a raw LIKE (tag name collides with other risk types in the combined XML)
  ```

---

### ATP-11110 / ATP-11117 / ATP-11115 — Location 1 sections missing / HB-HC not selected / Vehicle details didn't populate (G-49, supersedes G-43)

- **Policy Number:** P00010162 (confirmed example; broader policy count not yet quantified)
- **Issue:** Home Buildings/Home Contents coverage for a policy's current Location 1 silently
  disappears from the converted output.
- **RCA:** `HB_02`/`HC_02` were built as a **one-time manual snapshot** (per KT doc "Batch Running
  Steps.xlsx" — "No specific SP created, done manually as we had run only single time till now"),
  never refreshed. When a location's `EXPIRINGID_P` changes (amendment/renewal), the snapshot still
  has the coverage data but filed under the old, now-orphaned ID — silently fails to join to
  `PER_ACCOUNT_LOC`'s current ID downstream.
- **IsFixed:** Yes — confirmed 2026-07-10.
- **Comment:** Validated end-to-end in DEV. `HB_02` rebuilt (3,054→3,518 rows), P00010162's Location 1
  now resolves under the correct current ID `2530787` with $906,000 HB / $202,000 HC (previously
  trapped under the stale, orphaned ID `2178092`). Confirmed at every layer: `HB_02`/`HC_02` →
  `PER_HOME_BUILDING_PAYLOAD` (now has a row for `P00010162|...|2530787`, had 0 before) →
  `PER_FINAL` → real `REQUEST_XML` in `AGGNE.DEV.PER_POLICY_MIGRATION_DCT` (now contains the literal
  values `906000` and `202000`, absent before). Broader impact: orphaned `HB_02` rows (no matching
  current `PER_ACCOUNT_LOC` location) dropped from 1,749 to 549. **Characterized 2026-07-13**: 505 of
  549 belong to policies that also have their current location(s) correctly represented elsewhere in
  `HB_02` — mostly harmless leftover rows from old historical terms (`SAMPLE_PER` carries history by
  design, same pattern as `PM_01`). 44 belong to policies with no `PER_ACCOUNT_LOC` record at all
  (likely genuinely lapsed/cancelled). **However**: of the 472 total current locations across those
  505 policies, only 425 have a matching `HB_02` row — **47 current locations still genuinely lack
  HB_02 coverage data**, a smaller-scale residual of the same G-49 symptom. Not yet root-caused —
  follow-up needed.
- **Query for evidence:**
  ```sql
  SELECT TRIM(PUREPOLICYNUMBER), EXPIRINGID_P, HOMEBUILDINGSLIMIT
  FROM AGGNE.DEV.HB_02 WHERE TRIM(PUREPOLICYNUMBER)='P00010162';
  -- Confirmed: EXPIRINGID_P=2530787 present with $906,000

  SELECT COUNT(*) AS ORPHANED_HB02_ROWS FROM AGGNE.DEV.HB_02 h
  WHERE NOT EXISTS (SELECT 1 FROM AGGNE.DEV.PER_ACCOUNT_LOC a
      WHERE TRIM(a.LEGACYPOLICYNUMBER)=TRIM(h.PUREPOLICYNUMBER)
        AND CAST(a.PUREPOLICYNUMBER AS VARCHAR) LIKE '%|'||h.EXPIRINGID_P);
  -- Confirmed: 549 (was 1,749 before rebuild)

  SELECT CASE WHEN REQUEST_XML LIKE '%906000%' THEN 'YES' ELSE 'NO' END AS HAS_LOCATION1_HB_LIMIT
  FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT WHERE LEGACYPOLICYNUMBER='P00010162';
  -- Confirmed: YES
  ```

---

### ATP-11107 — Specified Items Away from the Premises not migrated (G-40)

- **Policy Number:** Aggregate — 195 of 1,831 policies affected
- **Issue:** Only the Taken/Not-Taken flag exists in the payload; itemized description/value list
  never built.
- **RCA:** Source data (`HC_AWAY`) has the itemized data; the DCT target node shape for a repeating
  itemized list was never confirmed, so no view was built to emit it.
- **IsFixed:** No
- **Comment:** Not fixed — blocked on Aggne confirming the target DCT XML node shape for a repeating
  item list before a view can be drafted. Sent as question #17 in `EMAIL_CLIENT_FieldQuestions.md`.
- **Query for evidence:**
  ```sql
  SELECT COUNT(DISTINCT PUREPOLICYNUMBER) FROM AGGNE.DEV.HC_AWAY;  -- confirms source data exists and is ready once the node shape is answered
  ```

---

### ATP-11105 — Rewired/Replumbed dates not migrated (G-41)

- **Policy Number:** Aggregate — buildings aged 41+ (1,582 rows in the current dataset)
- **Issue:** `YearLastReWired`/`YearLastRePlumbed` blank for old buildings.
- **RCA:** Confirmed 2026-07-13 — `Locationdetails_PER`'s own build logic (inside the Pure-to-Write
  SP) had a backwards `CASE` statement: intended to correct garbage years (0-1899) to 1900 while
  passing real years through unchanged, but the `ELSE` branch returned `NULL` for every normal
  4-digit year instead. Not a staleness or wrong-source-table issue (an earlier "maybe
  PERSONAL_RISK_03 is the real source, same as G-49" theory was investigated and retracted — that
  table is genuinely stale but was a red herring, not the actual bug).
- **IsFixed:** Yes — confirmed end-to-end.
- **Comment:** Fixed the `CASE`'s `ELSE` branch to pass the real year through. Validated at every
  layer: `Locationdetails_PER` blank 4,944→4,157 (787-row exact match to the predicted recoverable
  population); `PER_RISK_BUILDING_FINAL` blank 2,771→2,213; the age-41+ population specifically
  (the ticket's exact framing) dropped from 96.7% blank to 47.0% — more than halved; real generated
  XML (`PER_RISK_BUILDING_TARGET`) now shows 382 policies with a genuine rewired year, up from 0.
- **Query for evidence:**
  ```sql
  SELECT COUNT(*) TOTAL, SUM(CASE WHEN YEARLASTREWIRED IS NULL OR TRIM(YEARLASTREWIRED)='' THEN 1 ELSE 0 END) BLANK
  FROM AGGNE.DEV.Locationdetails_PER
  WHERE TRY_TO_NUMBER(CAST(YEARBUILDINGCONSTRUCTED AS VARCHAR)) <= 1985
    AND TRY_TO_NUMBER(CAST(YEARBUILDINGCONSTRUCTED AS VARCHAR)) > 1800;
  -- Confirmed: TOTAL=1582, BLANK=743 (was 1530)

  SELECT COUNT(*) FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
  WHERE PAYLOAD LIKE '%<YearTheBuildingWasLastReWired>2%';
  -- Confirmed: 382 (was 0)
  ```

---

### ATP-10961 — Account handler default incorrect (G-44)

- **Policy Number:** Aggregate — 3,424 of 4,076 policies (84%) show 'Aaron Pang'
- **Issue:** Unmatched policies default to a real staff member's name instead of blank/neutral.
- **RCA:** `ACCOUNT_HANDLER` only covers 16.7% of PP policies at all (set-membership check, not a
  join-syntax bug) — the COALESCE fallback fires for the other 83%.
- **IsFixed:** No — **fix retracted today.** Originally drafted as "default to blank," but
  `HANDLERMAIL` also sets the DCT session's `Producer` property
  (`Session.setPropertyRq name="Producer" value="{HANDLERMAIL}"`) before the import even starts —
  blanking it for 83% of policies risks an outright DCT import/session failure, not just a cosmetic
  wrong name shown. Caught during review before deployment.
- **Comment:** Did not fix — needs Aggne to confirm (1) does DCT's Producer property accept blank,
  and (2) if not, what's a safe fallback value. Left the existing 'Aaron Pang' default untouched
  (known-safe) pending that answer.
- **Query for evidence:**
  ```sql
  SELECT COUNT(*) TOTAL, SUM(CASE WHEN HANDLERFULLNAME='Aaron Pang' THEN 1 ELSE 0 END) AARON_PANG_ROWS
  FROM AGGNE.DEV.PER_FINAL;
  ```

---

### ATP-10962 — Legacy start date incorrect (G-45)

- **Policy Number:** Not yet identified
- **Issue:** "Legacy Start Date" incorrect/missing.
- **RCA:** Not yet determined — no column in `PER_FINAL` carries that literal name.
- **IsFixed:** No
- **Comment:** Not fixed — the newer ticket description gives a candidate rule ("should match the
  inception date of the migrated protection or the migrated renewal field already in PURE") that
  hasn't been worked yet. Flagged as possibly self-answerable without waiting on the client, but not
  started.
- **Query for evidence:** N/A — no fix drafted yet.

---

### ATP-10965 — Motor Only protections migrating with Location sections (G-46)

- **Policy Number:** Aggregate — 260 of 4,076 policies (6.4%)
- **Issue:** Policies show both Motor and HB/HC indicators set simultaneously.
- **RCA:** Suggestive only — not yet proven whether this reflects real PURE-side coverage selection
  or a conversion-side bug.
- **IsFixed:** No
- **Comment:** Not fixed — needs a PURE-side source comparison to confirm before a fix can be drafted.
- **Query for evidence:**
  ```sql
  SELECT COUNT(*) FROM AGGNE.DEV.PER_FINAL WHERE <has Motor indicator> AND <has HB/HC indicator>;
  ```

---

### ATP-11116 — Private Motor imposed excess failed to migrate (G-48)

- **Policy Number:** Aggregate — all Motor rows
- **Issue:** `<ImposedExcess/>` always empty.
- **RCA:** No Standard/Imposed Excess concept exists anywhere in PP's Motor data model (`PM_03`) —
  same pattern as G-23 (seq 7, HB) and G-34 (seq 14, HB risk-level), third instance.
- **IsFixed:** No
- **Comment:** Not fixed — bundled with G-23/G-34 as one client question: confirm whether
  Standard/Imposed Excess is genuinely inapplicable to PP everywhere it appears empty, or whether
  there's a PURE-side source we haven't found.
- **Query for evidence:** N/A — no source column to check against.

---

### ATP-11106 — Unspecified Items Away from Premises not migrated

- **Status:** Closed — checked live, already correct, not a bug.

---

### ATP-10842 — Windscreen Glass Excess incorrect (new fix, scoped out of G-37)

- **Policy Number:** Aggregate — all Motor policies with the Unlimited Glass sub-coverage (2,175 rows)
- **Issue:** `PMULG_SD` ("Unlimited Glass") sub-coverage always shows `Indicator=1`, regardless of
  whether the policy actually has glass excess waived.
- **RCA:** `PER_COM_COVERAGES`'s `PMULG_SD` branch hardcodes `INDICATOR` to `1` unconditionally —
  same "all 8 codes always on" pattern as G-37, but this one code has an already-computed, unambiguous
  driver available (`EXCESSWAIVERFORGLASS`, real varying signal: 2,658 'Yes' / 1,660 blank / 45 'No'
  on `PM_03`, already correctly mapped to 1/0 elsewhere in `PER_COM_PAYLOAD` under ATP-11003).
  Scoped out from G-37's other 7 codes, which need a client-defined ProtectionType exclusivity matrix
  this one doesn't.
- **IsFixed:** Yes — confirmed end-to-end 2026-07-10.
- **Comment:** First deploy (v1) caused a real regression — drove the indicator off a per-vehicle
  column inside a policy-level query, creating duplicate/conflicting rows for 208 policies with
  mixed-vehicle waiver settings. Caught before being called done, corrected with `GROUP BY`/`MAX`
  aggregation (v2): 0 duplicate rows (was 208), 978/978 (100%) agreement for unambiguous
  single-vehicle policies. Then found a SECOND, independent hardcode blocking it from reaching real
  output — same pattern as G-47: the seq 15 template in `PP_ConversionConfig` hardcoded
  `<Indicator>1</Indicator>` as literal text with no `{INDICATOR}` token, so the view's fix was
  invisible to the actual generated XML. Fixed via config `UPDATE` (tokenized) +
  `PP_CONVERSION_RUN` regenerated from config + redeployed + rerun. Final confirmation: real payload
  (`PER_COM_COVERAGES_TARGET`) now shows 1,556 `Indicator=1` / 619 `Indicator=0` — exact match to the
  view. Traced 3 specific policies individually through to the real XML, all correct.
- **Still open, separate from this fix:** `<UnlimitedGlass>1</UnlimitedGlass>` at the vehicle risk
  level (seq 18 template, distinct from `PMULG_SD`'s `Indicator`) is also hardcoded and untouched —
  not yet investigated whether DCT reads this as a real field or whether it's redundant with
  `PMULG_SD`.
- **Query for evidence:**
  ```sql
  SELECT INDICATOR, COUNT(*) FROM AGGNE.DEV.PER_COM_COVERAGES WHERE CODE='PMULG_SD' GROUP BY 1;
  -- Confirmed: 1,556 '1' / 619 '0'

  SELECT REGEXP_SUBSTR(PAYLOAD, '<Indicator>([01])</Indicator>[^<]*<Code>PMULG_SD</Code>', 1, 1, 'e', 1) AS IND, COUNT(*)
  FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET WHERE ITR_TYPE='Risk_CM' AND PAYLOAD LIKE '%PMULG_SD%' GROUP BY 1;
  -- Confirmed: 1,556 '1' / 619 '0' — exact match to view, real payload now correct
  ```

---

### ATP-11112 — Age of regular driver has increased (renewal)

- **Policy Number:** Not yet isolated to a specific example
- **Issue:** `AgeOfYoungestRegularDriver` appears to increase unexpectedly on renewal — different
  symptom from G-11's initial-conversion 16-vs-17 threshold issue.
- **RCA:** Not confirmed — investigated further, the initial lead did not hold up. `PM_01` does have
  1,393 of 7,307 vehicle rows (19%) tagged to a stale `EXPIRINGID_P`, but tracing a real example
  (P00000317) showed the age variation there is explained by normal per-vehicle differences (each
  vehicle has its own regular driver, so different ages are expected) — not a term-selection bug.
  Also, 589 of the 640 orphaned policies *also* have a valid current-term row sitting alongside the
  stale one, so "wrong term picked" doesn't cleanly explain the symptom either.
  `AgeOfYoungestRegularDriver` is a raw PURE pass-through (`MVCVYoungestDriver`) with no computation
  of our own, so if the value is genuinely wrong, the cause is either upstream in PURE (their own
  renewal recompute) or requires a specific reported policy to trace precisely — comparing this
  policy's value across two actual conversion runs over time, not inferable from a single snapshot.
- **IsFixed:** No
- **Comment:** Did not fix — declining to guess further after the initial lead didn't pan out (and
  after a related lesson from ATP-10842 today: a plausible-looking fix without full verification
  caused a real regression). Next step needs a specific policy number from the ticket/client so the
  exact before/after values can be traced, rather than searching blind.
- **Query for evidence:**
  ```sql
  SELECT COUNT(*) TOTAL, SUM(CASE WHEN NOT EXISTS (
      SELECT 1 FROM AGGNE.DEV.PER_ACCOUNT_LOC a
      WHERE TRIM(a.LEGACYPOLICYNUMBER) = TRIM(m.PUREPOLICYNUMBER)
        AND CAST(a.PUREPOLICYNUMBER AS VARCHAR) LIKE '%|' || m.EXPIRINGID_P
  ) THEN 1 ELSE 0 END) AS ORPHANED
  FROM AGGNE.DEV.PM_01;
  -- Confirmed: 1,393 of 7,307 (19%) orphaned — the lead, not yet a proven root cause
  ```
