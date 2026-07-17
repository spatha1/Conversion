# Prompt — hand this to the BP agent session

Copy everything below this line into a fresh Claude Code session scoped to BP work.

---

I need you to run a systematic, rigorous, one-gap-at-a-time field-mapping validation for the **BP
(Business Protection)** side of this Duck Creek policy conversion project — mirroring a
methodology already completed for **PP (Personal Protection)** in `docs/pp_mapping/`. Read that
folder first (`docs/pp_mapping/README.md`, `docs/pp_mapping/VALIDATION_RULES.md`, and 2-3 files
under `docs/pp_mapping/fixes/`) to see the exact format and rigor level expected before starting.
Do not skip this — the output format is precise and I want BP to match it exactly.

## Do not create any HTML files

The PP side has interactive HTML deliverables (`PP_FieldMapping_AllSeqs.html`,
`PP_FieldMapping_Seq18_Motor.html`, `BP_PureToWrite_Viewer.html`). **Do not build anything like
that for BP** — no HTML output at all, for individual gap cards or for the final compiled
deliverable. Everything you produce is Markdown (the gap cards, `README.md`, `VALIDATION_RULES.md`)
and `.sql` (the fix drafts, validation queries). If the user wants an HTML/interactive version
later, they'll ask for it explicitly — don't build toward one preemptively.

## Heads-up: this project has persistent memory — one entry does NOT apply to you

This working directory has an auto-memory system
(`C:\Users\Admin-1\.claude\projects\...\memory\MEMORY.md`) that will load automatically. One
existing entry, "PP Conversion Scope & Deployment Rules," says PP work is restricted to DEV views
only and to hold deployment scripts until asked. **That rule is PP-specific — it does not mean BP
is similarly restricted.** Don't infer a BP scope limit from a PP memory entry; if you're unsure of
BP's actual scope (DEV-only vs. also touching UAT/PRD views), ask the user directly rather than
assuming the PP restriction carries over.

## Pacing — how this actually gets driven

This is not a "run it all and report back" task. The PP version of this was driven **conversationally,
one gap at a time**: the user says a gap ID, you produce the full card + fix file + validation-rule
catalog entry for that one gap, then you stop and wait for the next explicit trigger. Expect the
user to also **correct you mid-stream** — reject a fix direction, ask you to re-verify something
against the client's SAS instead of guessing, or clarify scope (this happened repeatedly on the PP
side: e.g. a COALESCE-based fix was rejected in favor of the exact condition found in the client's
SAS text; a "no data for Fleet" claim was later corrected to "field still needed for Fleet"). Treat
those corrections as authoritative and update any already-written fix files/catalog entries to
match — don't leave stale guidance sitting in files after being corrected.

## Worked example — copy this shape exactly

This is the actual card format used for every PP gap (this one is G-10 from `docs/pp_mapping/`,
included here so you have a concrete template rather than just a description):

> ## G-10 — EngineSize / GrossVehicleMass (seq 18, Motor, P2)
>
> **Field:** EngineSize, GrossVehicleMass (`risk/EngineSize`, `risk/GrossVehicleMass`)
> **Type:** Numeric free text (no dropdown, no format mask beyond `int`)
> **DCT Values:** N/A — but both `required` per `RedBookDetailsRequiredCondition`
> **Wrong value sent:** blank/`0` — PM_01 sources both fields exclusively from the RedBook
> Override columns; the raw non-override columns are pulled but never used as a fallback.
>
> ### Data
>
> | Metric | Count | % |
> |---|---|---|
> | Total vehicles | 3,306 | — |
> | EngineSize blank/0 | 3,139 | 95.0% |
> | GrossVehicleMass blank/0 | 3,294 | 99.6% |
>
> ### Query
> ```sql
> SELECT COUNT(*) AS TOTAL,
>   SUM(CASE WHEN COALESCE(TRIM(ENGINESIZE),'')='' OR ENGINESIZE='0' THEN 1 ELSE 0 END) AS ENGINESIZE_ZERO_BLANK
> FROM AGGNE.DEV.PER_COM_PAYLOAD;
> ```
>
> ### Honest scope
> [what's proven by the query vs. what's still an open question needing the client/policy team]
>
> **Status:** Open. Fix drafted in `fixes/G-10_fix.sql`.

Match this structure — header block, Data table, Query block, Honest scope paragraph, Status line —
for every BP gap. See `docs/pp_mapping/fixes/G-10_fix.sql` and `G-13_fix.sql` in the actual repo for
full worked examples of the companion fix-draft file format too.

## Why this matters / shared code context

The PP and BP conversions share the **same stored procedure**:
`sql/snowflake/stored_procedures/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql`. Inside it:

- PP (Personal Motor) uses `MV`-prefixed Pure columns (`MVCVRegNo`, `MVRBVehicleKey`,
  `MVRBEngineSizeOV`, ...) building `PM_01` → `PM_02` → `PM_03`.
- BP (Commercial Motor / Fleet) uses `CM`-prefixed Pure columns (`CMCVRegNo`, `CMRBVehicleKey`,
  `CMRBGrossVehMass`, ...) around line ~2170-3500 of the same file, and Fleet has its own further
  variant.

Because the two sides were built from the same original client-provided SAS logic (see below), **a
bug found and fixed on the PP side is a strong hint to check the equivalent BP code path** — and
vice versa. Several PP gaps turned out to trace back to one root cause; assume the same is possible
for BP and look for it deliberately, don't treat each field as isolated.

## The exact methodology to follow (per gap)

For each gap in the BP register (find/build a list the same way PP's `docs/pp_mapping/README.md`
did — likely from existing BP defect docs, see "Where to start" below):

1. **Explain the gap** — plain description of what's wrong, in your own words.
2. **Verify DCT rules fresh from the manuscripts** — do not reuse cached/remembered dropdown
   values or required-conditions. Every dropdown's valid values, every `required` condition, must
   be re-grepped/read directly from `Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/` for this
   specific gap, with exact file + line citations. This was a hard requirement on the PP side after
   an early miss — don't repeat that miss here.
   - Watch for **multi-branch `<options>` blocks gated by `validRef`** (e.g. keyed on
     `VehicleInfoOverride` or `VehicleType`) — the "obvious" flat option list is often a union of
     several conditional sets, and only one branch is ever reachable given how this pipeline forces
     certain flags (see PR-03 below).
   - Watch for `required` conditions that reference **role-based UI context** (e.g.
     `Context.IsUnderwriters`, `Context.IsAccountHolderWithSystemAdmin`) rather than a data
     condition — these may not even apply to batch/XML import. Flag this as an open question, don't
     assume either way (see PR-03).
3. **Explain with data** — run a real read-only Snowflake query (READ-ONLY connection, see Safety
   below) against `AGGNE.DEV.*` and show actual counts/distributions. Don't estimate — query.
4. **Check the client's original SAS before drafting any fix.** `SAS/txt/` in this repo has the
   client-delivered pre-Snowflake-port SAS scripts. For BP/Commercial Motor specifically:
   `SAS/txt/CommercialVehicles_conversionscriptCapricorn.txt` and
   `SAS/txt/FleetVehiclesSummary_conversionscriptCapricorn.txt` (there are others for BP's other
   lines — Business Details, Business Protections, Burglary/Engineering/BI, Business
   Building/Contents/Money — grep the relevant one per gap). On the PP side, an "Override-gating"
   bug in 5 different fields turned out to be **one single client-authored SAS `DO` block** that
   only partially survived the Snowflake port — see `docs/pp_mapping/VALIDATION_RULES.md` PR-04 for
   the exact writeup. Check whether the same pattern exists on BP's `CM`-prefixed side before
   guessing a fix — the client's own SAS may already contain the correct logic.
5. **Present as one consolidated "card"** — not fragmented with debugging output. Format:
   - `Field:` / `Type:` / `DCT Values:` / `Wrong value sent:` header lines
   - A markdown **Data table** with real counts
   - A fenced **Query** code block with the exact SQL used
   - An **Honest scope** paragraph — what's proven vs. what's still open/needs the client
   - A **Status:** line (Open / Fixed / False Positive)
6. **Draft a standalone fix file** per gap: `docs/bp_mapping/fixes/G-BP-NN_fix.sql` (or match
   whatever gap-ID scheme the existing BP defect docs use — check first, see below). Draft-only,
   never applied to live Snowflake/SQL Server. Separate pure code fixes (no external input needed)
   from fixes that need Aggne-policy-team-then-client sign-off — mark unresolved business decisions
   with `<TBD>`, never fabricate a value for something that needs human judgment.
7. **Log the field-level rule to a living catalog**: `docs/bp_mapping/VALIDATION_RULES.md` (create
   it, mirroring `docs/pp_mapping/VALIDATION_RULES.md`'s entry format exactly — Field / Type / DCT
   Values / Wrong value sent / Count / Query / Status). Also carry forward the **process rules**
   below since they're proven to apply across both lines.

**Work one gap at a time. Do not batch ahead.** Wait for explicit confirmation before moving to the
next gap, same as the PP methodology.

## Process rules already proven on the PP side — treat as active for BP too

Read `docs/pp_mapping/VALIDATION_RULES.md` in full for these; summarized:

- **PR-01** — never silently drop a whole record because one field fails validation. Always flow
  the record through; catch bad fields via a validation-report rule instead.
- **PR-02** — some reference tables were manually loaded by the client scoped to ~3 months, not the
  full book (`PRD_T5_EXTERNAL_AGGNE.RISK` schema, e.g. `SCHEDULE_CLAUSES_TEMPLATE`,
  `FLEET_TEMPLATE`, `QU_*` questionnaire tables — several are BP/Fleet-specific and directly
  relevant to you). Missing data outside that window is expected scope, not a bug — confirm with
  the client before treating it as one.
- **PR-03** — several `required` conditions in the manuscript are gated on UI role context
  (`Context.IsUnderwriters`, etc.), not on data. Unconfirmed whether XML/batch import enforces these
  at all. Flag, don't assume.
- **PR-04** — the client's original SAS scripts may already contain fallback logic that didn't
  fully survive the Snowflake port. Check `SAS/txt/*.txt` for the relevant BP line before drafting
  a fix from scratch.
- **PR-05** — RedbookCode is a needed field on **all** vehicle types, including Fleet — an earlier
  note wrongly implied Fleet RedBook gaps could be waved off; the client corrected this. Check
  Fleet's own RedbookCode wiring (`FleetVehicleInput.RedbookCode` in the manuscript) rather than
  assuming PP's fix already covers it.

## Where to start — don't duplicate existing BP work

Before treating anything as a "new" gap, check what's already been found:

- `files/Issues/BP Conversion/2028-07-07/ATP-10219-Policy-Conversion-Defects.html` — a 37-ticket
  client bug list with root causes already confirmed for several fields (CM vehicle details —
  BodyType/ImportType/AddAccessories/FuelType in `CV_RISK_COV_FINAL_VIEW`; Building BG/BC tied to
  indicator fixes; a Landslide indicator bug). ~15 of those tickets reportedly still need
  investigation — that's a natural place to pick up.
- `sql/snowflake/1_conversion/BP/validation/BP_DROPDOWN_FIELD_VALIDATION.sql` and
  `sql/snowflake/1_conversion/BP/views/BP_DROPDOWN_VALIDATION.sql` — confirmed invalid dropdown
  mappings already identified (Building RoofCon/MainWall/Deadlocks/Bars type mismatches, CM
  VehicleType NULL on ELSE, FL HighestRiskUse not mapped at all).
- `docs/BP_PureToWrite_Viewer.html` and `docs/Policy_Conversion_HowItWorks_PP_BP.md` — existing
  structural documentation of the BP flow.
- `files/Issues/BP Conversion/2026-06-26/*.docx` — earlier test-execution defect docs (ATP-1399,
  ATP-1395, ATP-1396, ATP-6221, US-5977).

Build your BP gap register (`docs/bp_mapping/README.md`, mirroring
`docs/pp_mapping/README.md`'s structure) from these sources first, rather than re-discovering
everything from zero. Assign gap IDs (e.g. `G-BP-01`...) once you have the consolidated list, and
confirm the list with me before starting the one-by-one validation pass.

## Source materials — exact paths, so you don't have to rediscover them

**Manuscripts (DCT rule verification — re-read fresh per gap, never from memory):**
- `Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/CarrierBusinessProtectionPackage/` — BP's
  own product manuscript tree (parallel to PP's `CarrierPersonalPackage/`). Field-level dropdowns,
  `required` conditions, format masks live here — same structure as PP, different product folder.
- `Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/CarrierCoverageLibrary/` — shared library
  used by **both** PP and BP (this is where most PP field definitions actually lived, e.g.
  `VehicleInput.RedbookCode`, `VehicleInput.EngineSize`). Check here even for BP gaps — many
  vehicle-level fields are defined once and reused across products via `idref`.
- `Manuscripts/Policy/Policy/ManuScripts/DCTTemplates/CarrierPackage/CW-INH/Carrier_Package_Data_CW_1_0_0_0.xml`
  — the shared "Package" base (both PP and BP inherit from this) — this is where cross-product
  `required` conditions like `VehiclePrivate.RedBookDetailsRequiredCondition` and
  `Context.IsUnderwriters` are actually defined (not just referenced). PR-03's discovery came from
  here.
- `Manuscripts/Policy/Policy/ManuScripts/Commercial/CarrierSME/` — if any BP line maps closer to
  SME/Commercial than to the Business Protection package, check here too.
- `Manuscripts/ServerExtract/ServerExtract/ManuScripts/ExtractMap/BusinessProtection/` — extract-map
  XML (field-to-column bindings), parallel to the `PersonalProtection/` one used on the PP side.

**The shared stored procedure:**
- `sql/snowflake/stored_procedures/DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql` — single file,
  builds both `PM_01/02/03` (PP, `MV`-prefixed) and BP's Commercial Motor tables (`CM`-prefixed,
  roughly line 2170-3500 based on what was seen while working PP gaps — re-verify current line
  numbers, the file is large and both sides get edited). Also check
  `DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD_LIVE.sql` and `..._SAI_FETCHED.sql` in
  `sql/snowflake/stored_procedures/` — appear to be reference/comparison copies, confirm which one
  is actually live before trusting any of them as ground truth (this exact "repo copy vs. live
  config" mismatch is what G-13 found on the PP side — check don't assume).

**BP views (the equivalent of PP's `sql/snowflake/1_conversion/PP/views/`):**
`sql/snowflake/1_conversion/BP/views/` — in particular for vehicle/motor gaps:
`CV_RISK_COV_FINAL_VIEW.sql`, `CV_COVERAGE_VEHICLE_COV.sql`, `CV_COVERAGE_VEHICLE_SUBCOV.sql`,
`CV_MOTOR_CLAUSE.sql`, `CV_MOTOR_EXCESS.sql`, `CV_MOTOR_UW.sql`,
`FLEET_VEHICLE_MAIN_VIEW.sql`, `FLEET_VEHICLE_VIEW.sql`, `FLEET_VEHICLE_SUBCOVERAGES.sql`,
`FL_MOTOR_CLAUSE.sql`, `FL_MOTOR_EXCESS.sql`, `FL_MOTOR_UW.sql`. For buildings/property:
`BUILDING_BC_PAYLOAD.sql`, `BUILDING_BG_PAYLOAD.sql`, `BUILDING_BI_PAYLOAD.sql`,
`BUILDING_EN_PAYLOAD.sql`, `BUILDING_MONEY_PAYLOAD.sql`, `BUILDING_PAYLOAD.sql`,
`BUILDING_SUBCOVERAGES.sql`, `BUILDING_UW.sql`. Also `BP_DROPDOWN_VALIDATION.sql` (already-built
validation view, check what it already covers before duplicating).

**BP stored procedures:** `sql/snowflake/1_conversion/BP/sps/` —
`DEV_SP_LOAD_PURE_POLICY_BP.sql`, `DEV_POLICY_INSERTPAYLOADINDCT.sql`,
`DEV_POLICY_SOURCEDATA.sql`, `DEV_POLICY_PARTY_XML.sql`, `DEV_SP_POLICY_XML_INTEGRATION.sql`.

**BP validation/diagnostics (existing):** `sql/snowflake/1_conversion/BP/validation/`
(`BP_DROPDOWN_FIELD_VALIDATION.sql`) and `sql/snowflake/1_conversion/BP/diagnostics/` — check what
these already catch before writing new validation rules that duplicate them.

**Client SAS source (pre-Snowflake-port ground truth) — `SAS/txt/`, BP-relevant files:**
`CommercialVehicles_conversionscriptCapricorn.txt`, `FleetVehiclesSummary_conversionscriptCapricorn.txt`,
`BusinessDetails_conversionscriptCapricorn Corrected V2.txt`,
`BusinessProtections_V3_conversionscriptCapricorn.txt`,
`Businessbuilding, businessContents and Money conversionscriptCapricorn.txt`,
`Burglary, Engineering, Business interruption_conversionscriptCapricorn.txt`,
`GoodsInTransit_LegalExpenses_TaxAudit_conversionscriptCapricorn.txt`,
`ProductandPublicLiability_conversionscriptCapricorn.txt`,
`ExpiringPremiumClaimHistory_V3_conversionscriptCapricorn.txt`,
`Additional interested conversionscriptCapricorn.txt`,
`Manual Referral_conversionscriptCapricorn.txt`. (Full raw source also sits zipped at
`SAS/PolicyConversion_SAS_Logic.zip` and unzipped per-line under `SAS/extracted/Conversion/` with
matching `.docx`/`.xlsx` data-mapping companions per topic — useful if the `.txt` extraction is
unclear on a specific field.)

**BP config (equivalent of PP's `PP_ConversionConfig`):** `reference/ConversionConfig_BP.csv` and
`reference/ConversionConfig_full.json` — check these the same way G-13 checked
`PP_ConversionConfig_snapshot_20260703.json`: the repo's SQL files may show a fix that was never
actually deployed to the live SQL Server config table. Don't assume a repo-visible fix is live.

**Existing BP defect/issue tracking (read before treating anything as new):**
- `files/Issues/BP Conversion/2028-07-07/ATP-10219-Policy-Conversion-Defects.html` — 37-ticket
  client bug list, several root causes already confirmed.
- `files/Issues/BP Conversion/2026-06-26/*.docx` — ATP-1399 (Burglary/Business
  Interruption/Engineering), ATP-1395 (UW Adjustment defect), ATP-1396, ATP-6221, US-5977 test
  executions.
- `files/Issues/BP Conversion/2026-07-04/Jira.html` — Jira export.
- `docs/BP_PureToWrite_Viewer.html`, `docs/Policy_Conversion_HowItWorks_PP_BP.md` — existing
  structural docs for the shared flow.

**Querying:** `middleware/snowflake_client.py` (`get_connection()`, read-only) and
`middleware/sqlserver_client.py` for any SQL Server config-table checks — same pattern used
throughout the PP work (see any `docs/pp_mapping/fixes/*.sql` "Verify after applying" block for the
query style).

## Safety rules — non-negotiable

- **SAFE_MODE**: never write/delete data without explicit user go-ahead. This is a read-only
  investigation and fix-drafting exercise. No DDL/DML gets applied to Snowflake or SQL Server.
- **Snowflake access is READ-ONLY** — all fixes are drafts for the user to review and apply
  manually later.
- **Credential redaction**: if dumping any config/connection table, use an allowlist of safe
  columns, not a blocklist — a blocklist previously missed a private-key column and leaked
  credentials. Ask before dumping anything that might contain secrets.
- **PP scope**: this brief is BP-only. Don't modify anything under `docs/pp_mapping/` or PP's SQL
  views/SPs — if you find something relevant to PP while investigating BP, note it and flag it back
  to the user rather than editing PP files directly.

## Final deliverable (once all BP gaps are validated)

Compile everything into one consolidated **Markdown** document in the card style described above
(Field/Type/DCT-Values/Wrong-value-sent header, Data table, fenced Query block, Honest-scope note,
Status line) — the user will ask for this explicitly once the gap-by-gap pass is done, similar to
the PP side. **Markdown, not HTML** — see "Do not create any HTML files" above.
