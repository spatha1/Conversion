# How Policy Conversion Works — BP & PP

**Project:** Capricorn Policy Conversion (Pure → Duck Creek)
**Last updated:** 2026-07-03

---

## 1. What the project does

Legacy insurance policies live in the client's **Pure** system. The target policy-admin system is **Duck Creek (DCT)**, which accepts new policies only as XML posted to its REST API. This project converts every in-scope policy from Pure's relational data into a single, fully-formed DCT XML payload per policy, and loads it into DCT.

Two Lines of Business (LOBs) run through the same engine:

| LOB | Meaning | Config table | Config rows |
|-----|---------|--------------|-------------|
| **BP** | Business Protection (commercial package) | `ConversionConfig` | 67 |
| **PP** | Personal Protection (home building, home contents, private motor) | `PP_ConversionConfig` | 18 |

There are two distinct pipelines:

1. **Policy Conversion** — builds the full policy XML and creates the policy in DCT (runs in `AGGNE.DEV`).
2. **Policy Attach** — makes *legacy* policies visible in DCT so claims can be lodged against them by LegacyPolicyNumber + Date of Loss (runs in `AGGNE.PRD` / `PRD_XML`).

---

## 2. System map

```
Pure Snowflake (AGGNE db)          ← client source data
        │  ETL1: raw pull
        ▼
AGGNE.DEV staging tables + views   ← shaping / normalization
        │  ETL4: DYNAMIC_XML_V1 per config row
        ▼
*_TARGET XML fragment tables       ← one XML fragment per entity per policy
        │  ETL5/6: COMBINEPAYLOAD + final assembly
        ▼
Final XML per policy
        │  Python middleware POST
        ▼
Duck Creek (DCT) REST API
```

**Components:**

- **Pure Snowflake (`AGGNE` database)** — client source data; private-key auth (key Fernet-encrypted in the ConversionAgent SQL Server DB). Connection is **read-only** from tooling; all DDL/DML is applied manually.
- **SQL Server, `PolicyConversion` DB** — holds `ConversionConfig` (BP) and `PP_ConversionConfig` (PP). This config drives everything.
- **Python middleware** (`C:\Users\Admin-1\Desktop\Conversion\middleware\`) — the orchestrator. Entry point: `python -m middleware.main --lob BP|PP`. `SAFE_MODE=true` in `.env` blocks all SP calls by default and must be explicitly set to `false` for real loads.
- **Duck Creek (DCT)** — receives the final policy XML (Dev/UAT/TST/PROD `DCTServer.aspx` endpoints).

---

## 2.1 Source table inventory (AGGNE.DEV)

All source data lands as staging tables in `AGGNE.DEV` (ETL1) before views shape it.

**PP — 22 Pure source tables.** The main ones, grouped by role:

| Group | Tables | Notes |
|-------|--------|-------|
| Scope / universal filter | `SAMPLE_PER` (4,954 rows) | Every view joins to this; filter `EFFECTIVEDATE >= '2026-01-01'` |
| Location | `LOCATIONDETAILS_PER` | Address, construction, occupancy, security |
| Home Buildings | `HB_01`, `HB_02` | Limits, flood/accidental damage, landlord options |
| Home Contents | `HC_01`, `HC_02`, `HC_AWAY`, `HC_SPITEMS` | Contents limits, away-from-home items, specified items |
| Private Motor | `PM_03` | Vehicle details, coverages |
| Coverages / premiums | `OUTPUT_COVERAGE_PER`, `COVERAGE_PER`, `OUTPUT_SUBCOVER_PER` (52,846 rows), `EXPPREMIUM_PER_B_HB`, `EXPPREMIUM_PER_B_HC`, `OUTPUT_UWADJUST_PER` | Premium splits and sub-coverage premiums |
| Claims / prior carrier | `CLAIMHISTORY` (10,963 rows), `PER_COMPETITOR_INFORMATION` | |
| Clauses | `CLAUSES` | Shared with BP |
| Policy-level / attach | `POLICYATTACH_PER` (54,705 rows), `PERSONAL_RISK_01` (59,416 rows), `PER_FINAL` | |

Standard join key: `PUREPOLICYNUMBER + EXPIRINGID_P` (plus `CMLNUMBER` where needed).

**BP — ~55 Pure source tables** (larger because a commercial package has one staging table per line/section). The local BP SQL references ~74 distinct `AGGNE.DEV` base tables in total, of which ~55 are raw Pure extracts and the rest are intermediates built by `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` (e.g. `AI_MERGED`, `LINE_TRANSPOSED`, `SAMPLE_BP_*`, `CBP_CLAIMHISTORY_A–D`). Raw groups:

| Group | Tables |
|-------|--------|
| Scope / sample | `SAMPLE_CBP` (+ `_APPLICANT`, `_BUSINESS`, `_BUSINESSDETAIL`, `_COMMERCIALVECHICLE`, `_FLEETVEHICLE`), `SAMPLE_PER`, `SAMPLE_PER_APPLICANT` |
| Location | `LOCATION_01` |
| Line/section staging | `BB_01`, `BC_01`, `BG_01`, `BI_01`, `EN_01`, `GP`, `GT_01`, `LE_01`, `MY_01`, `PF_01`, `PP_01`, `SV_01`, `TA_01`, `CM_01`, `CM_03`, `PM_03` |
| Line coverages | `LINE_GP/GT/LE/SV/TA/CV_COVERAGE`, `LINE_PUBLICLIABILITY_COVERAGE`, `LINE_PROFESSIONALPROTECTION_COVERAGE` |
| Location coverages | `LOCATION_BB/BC/BG/BI/EN/MONEY_COVERAGE` |
| Interested parties | `AI_01`, `AI_02`, `AI_03`, `ADDITIONAL_INTEREST` |
| Business info | `BUSINESS_INFO_01`, `BUSINESS_PROTECTIONS_01`, `ANZSIC_RANK_01/02/03`, `PROTECTION_TERM` |
| Claims / competitor | `CLAIMHISTORY`, `CBP_COMPETITOR_INFORMATION`, `PER_COMPETITOR_INFORMATION` |
| Vehicles / other | `VEHICLECOVERAGES_FLEETVEHICLE`, `OUTPUT_UWADJUST_BSP`, `CLAUSES`, `PURE_POLICY_SEARCH_BP_PER` |

---

## 3. The six ETL phases (Conversion pipeline)

| Phase | What happens | Where |
|-------|-------------|-------|
| **ETL1** | Raw data pull from Pure into staging tables | Snowflake `AGGNE.DEV` |
| **ETL2** | Views over staging tables normalize and shape the data (joins, filters, derived fields, aggregations) | Snowflake `AGGNE.DEV` |
| **ETL3** | Config rows define the work: `ScriptName` + XML template (`ConversionScript`) + source view + target table | SQL Server `PolicyConversion` |
| **ETL4** | Python (`middleware/etl4.py`) loops config rows in `SequenceID` order and calls `DYNAMIC_XML_V1` once per row. The SP substitutes `{TOKEN}` placeholders with column values and writes XML fragments to the target table | Snowflake SP, driven by Python |
| **ETL5** | `COMBINEPAYLOAD` SP: `LISTAGG`s the XML fragments per policy, wrapped in HEADER + FOOTER | Snowflake |
| **ETL6** | Final XML assembly per policy; middleware POSTs each payload to the DCT API | Python + DCT |

**ETL6 read sources:**
- BP: `AGGNE.DEV.VW_CBP_OUTPUT_CONVERSION` (a view that dynamically joins all `*_Target` tables)
- PP: `AGGNE.DEV.PER_FINAL` (a pre-materialized table)

Both expose the same shape: `ID, LEGACYPOLICYNUMBER, PUREPOLICYNUMBER, PARTYID, <XML payload columns>`.

---

## 4. The XML engine: `DYNAMIC_XML_V1`

One generic stored procedure (in `AGGNE.DEV` and `AGGNE.PRD`) generates every XML fragment for both LOBs:

```
DYNAMIC_XML_V1(SOURCETABLE, PAYLOAD, TARGETTABLE, ITR_TYPE)
```

How it works:

1. Reads **all column names** of the source view from `INFORMATION_SCHEMA.COLUMNS`.
2. Builds a nested `REPLACE()` chain: `REPLACE(REPLACE(payload, '{COL1}', IFNULL(COL1,'')), '{COL2}', ...)` — one REPLACE per column.
3. Inserts the resolved XML into the target table:
   `INSERT INTO target (ID = PUREPOLICYNUMBER, ITR_TYPE, PAYLOAD, LOAD_DATE) SELECT DISTINCT ...`

All 56 target tables share the identical schema: `ID, ITR_TYPE, PAYLOAD, LOAD_DATE`.

**Two important behaviors** (these drive most bugs):
- Token matching is exact — a `{redbookCode}` token will not match a `REDBOOKCODE` column (Snowflake uppercases unquoted columns).
- A token whose name matches **no** column is left unresolved in the payload; a token that matches a column that happens to be `NULL`/empty is silently replaced with `''`. Both failure modes are invisible unless you inspect the output XML.

---

## 5. How the mapping was done (and why it's complex)

### The mapping approach

Mapping is **not** one big source-to-target field map. It is layered, and each layer owns a different part of the problem:

**Layer 1 — SQL views do the field-level mapping (ETL2).**
Every source Pure table (22 tables for PP, e.g. `HB_01`, `HB_02`, `HC_02`, `PM_03`, `OUTPUT_COVERAGE_PER`) is mapped through a view that:
- joins the relevant Pure tables (typical keys: `PUREPOLICYNUMBER` + `EXPIRINGID_P`),
- renames columns to match the `{TOKEN}` names the XML template expects,
- applies value transformations (date formats, code lookups, defaults, `CASE` mappings such as blank `VehicleType` → `PassengerVehicle`),
- derives indicator flags (`HB_INDICATOR`, `HC_INDICATOR`) that tell the template which blocks apply,
- pre-aggregates child XML with `LISTAGG` (e.g. all sub-coverage fragments for a policy rolled into a single `SUBCOV` column).

So: **column name in the view = token name in the template**. The view *is* the mapping document, executable.

**Layer 2 — XML templates define the target structure (ETL3).**
Each config row's `ConversionScript` is a DCT XML skeleton with `{TOKEN}` placeholders where data goes. The template encodes the DCT product model (manuscripts); the view encodes the Pure data model; the token names are the contract between them.

**Layer 3 — Sequencing composes fragments into a policy (ETL4→ETL6).**
Fragments are generated in `SequenceID` order because later views **read earlier fragments back out of the target tables**. Example from PP: seq 6 writes `HB_CLAUSE` fragments into `PER_BUILDING_TARGET`; the seq 7 source view (`PER_HOME_BUILDING_PAYLOAD`) then `LISTAGG`s those rows into its `HB_CLAUSE` column so the building risk block arrives with its clauses already embedded. Finally `COMBINEPAYLOAD`/final-agg views stitch the top-level blocks (location, party, risks, coverages) into one policy document.

### PP mapping: the full 18-sequence map

| Seq | ScriptName (ITR_TYPE) | Source view (AGGNE.DEV) | Target table |
|-----|----------------------|--------------------------|--------------|
| 1 | ACCOUNT_LOC | PER_ACCOUNT_LOC | PER_LOC_TARGET |
| 2 | PARTY | PER_PARTY | PER_PARTY_TARGET |
| 3 | CLAUSE | PER_CLAUSE | PER_CLAUSE_TARGET |
| 4 | Building_SubCov | PER_BB_SUBCOVERAGES | PER_BUILDING_TARGET |
| 5 | BUILDING_UW | BUILDING_UW | PER_BUILDING_TARGET |
| 6 | HB_CLAUSE | HB_CLAUSE | PER_BUILDING_TARGET |
| 7 | RISK_Building_HB | PER_HOME_BUILDING_PAYLOAD | PER_BUILDING_TARGET |
| 8 | HC_exceed_values | PER_HC_ITEMS_EXCEED_VALUE | PER_HC_TARGET |
| 9 | HC_Specified_Contents | PER_HC_SPECIFIEDCONTENTS | PER_HC_TARGET |
| 10 | Building_SubCov | PER_HC_SUBCOVERAGES | PER_HC_TARGET |
| 11 | BUILDING_UW | PER_HC_BUILDING_UW | PER_HC_TARGET |
| 12 | LOC_HC_CLAUSE | PER_HC_CLAUSE | PER_HC_TARGET |
| 13 | RISK_Building_HC | PER_HOME_BUILDING_PAYLOAD | PER_HC_TARGET |
| 14 | RISK_Building | PER_RISK_BUILDING_FINAL | PER_RISK_BUILDING_TARGET |
| 15 | Risk_CM | PER_COM_COVERAGES | PER_COM_COVERAGES_TARGET |
| 16 | PER_PM_BUILDING_UW | PER_PM_BUILDING_UW | PER_COM_COVERAGES_TARGET |
| 17 | COM_CLAUSE | PER_COM_CLAUSE | PER_COM_COVERAGES_TARGET |
| 18 | RISK_Building_PM | PER_COM_PAYLOAD | PER_COM_COVERAGES_TARGET |

Reading it as intent: seqs 1–3 build shared blocks (location, party, clauses); 4–7 assemble **Home Building**; 8–13 assemble **Home Contents**; 14 merges building risks; 15–18 assemble **Private Motor**. BP follows the same pattern, just wider — 67 config rows because a commercial package has many more coverage sections.

After seq 14, `PER_BUILDING_FINAL_AGG` does a **second-pass token resolution**: it reads `PER_RISK_BUILDING_TARGET` (the outer risk block) and injects remaining `{HB_CLAUSE}`, `{clauses}`, `{UW}` tokens and BB sub-coverages from the earlier fragment tables (via `REGEXP_REPLACE` before the first `</coverage>`).

### What makes the mapping complex

1. **One source can feed multiple targets.** `PER_HOME_BUILDING_PAYLOAD` feeds both seq 7 (HB) and seq 13 (HC). It's a UNION of an `HC_02` branch and an `HB_01`-only branch, with `HB_INDICATOR`/`HC_INDICATOR` computed via EXISTS checks so a single view serves both product blocks — a policy can be HB-only, HC-only, or HB+HC.
2. **Ordering dependencies.** Because views LISTAGG earlier fragments, running sequences out of order silently produces empty blocks (fragments simply aren't there yet). The dependency is invisible in the config table itself.
3. **Two-pass token resolution conflicts.** `DYNAMIC_XML_V1` resolves *every* token that matches a view column — including tokens intended for the later FINAL_AGG pass. If the view exposes `{UW}` as `''`, the engine consumes it before FINAL_AGG can inject real data (bugs BUG-NEW-02/03). The mapping design has to be careful about *which layer owns which token*.
4. **Silent failure modes.** Case-mismatched tokens (`{redbookCode}` vs `REDBOOKCODE`), `ITR_TYPE` label mismatches (data stored as `LOC_HC_CLAUSE` but a view filtering on `HC_CLAUSE` → always empty), and hardcoded template values (`HomeContentsTotal`, `FloodDamage`, `<State>NSW</State>`) all produce valid-looking XML with wrong or missing data. Validation therefore compares generated XML against source data field-by-field, plus XSD validation (`docs/PP_XML_Validation_Building.xsd`, `..._Motor.xsd`) and dropdown-value validation (`PER_DROPDOWN_FIELD_VALIDATION`).
5. **Mandatory-field gaps in source data.** Pure simply doesn't hold some fields DCT requires (see `docs/PP_MandatoryField_GapByPolicy.csv`). Each gap needs a business decision: default it (e.g. `PassengerVehicle`), derive it, or send it back to the client (e.g. 432 policies with blank `RoofConstruction`/`MainWallConstruction`).

### How a mapping change is made in practice

1. Identify the token in the XML template (config row's `ConversionScript`).
2. Trace it to the column in the source view (same name).
3. Fix the view SQL locally (`sql/snowflake/1_conversion/<LOB>/views/`), deploy to Snowflake manually (connection is read-only from tooling).
4. If the template itself is wrong, update the config row in `PolicyConversion` (`ConversionConfig` / `PP_ConversionConfig`).
5. Re-run the affected sequence(s) via the middleware, then validate the regenerated XML.

---

## 6. Policy Attach pipeline (BP & PP)

Attach exists so **legacy policies are queryable in DCT for claims**: the claims app looks up a policy by `LegacyPolicyNumber + DOL (Date of Loss)`.

**Key design decision — DOL combinations:** the DOL is unknown at conversion time, so instead of attaching once per transaction, the pipeline generates **start-date → end-date combinations** per policy (up to ~10) such that any possible DOL falls inside at least one combination. Each policy is attached once per combination. When a new transaction arrives, all combinations for that policy are regenerated.

### BP attach — batch run order

| Step | Name | SP / Action | Where |
|---|---|---|---|
| 0 | Old_PolicyInfo | `CALL AGGNE.PRD.DELTA_PROCESS_MAX_OLD()` | Snowflake PRD |
| 1 | Pure To Write | `CALL AGGNE.PRD.SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD()` | Snowflake PRD |
| 2 | DateDim & Identifier | `CALL AGGNE.PRD.SP_Datedim_Identifier_Setup()` | Snowflake PRD |
| 3 | Delta (Old vs New) | `CALL AGGNE.PRD.DELTA_PROCESS()` | Snowflake PRD |
| 4 | Load Views | `HB_BP_PolicyAttach_LoadViews` | Conversion DB (SQL Server) |
| 5 | Final Data Load | `AGGNE.PRD.LOAD_PA_BP_FINAL_OUPUT` | Snowflake PRD |
| 6 | Final XML Load | `POLICYATTACH_LOAD_FINALDATA_XML` | Snowflake PRD |
| 7 | DCT Hit | `HB_BP_PolicyAttach_Automation` | Conversion DB (SQL Server) |
| 8 | Load API Table | UPDATE `AGGNE.PRD_XML.POLICYATTACH_MIGRATION_DCT` with RESULTS_JSON | Snowflake PRD |

### PP attach — batch run order

| Step | Name | SP / Action | Where |
|---|---|---|---|
| 0 | Old_PolicyInfo | `CALL AGGNE.PRD.PER_DELTA_PROCESS_MAX_OLD()` | Snowflake PRD |
| 1 | Pure To Write | `CALL AGGNE.PRD.SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD()` | **same SP as BP** |
| 2 | DateDim & Identifier | `CALL AGGNE.PRD.SP_PP_DATEDIM_IDENTIFIER_SETUP()` | Snowflake PRD |
| 3 | Delta (Old vs New) | `CALL AGGNE.PRD.PER_DELTA_PROCESS()` | Snowflake PRD |
| 4 | Load Views | `HB_PP_PolicyAttach_LoadViews` | Conversion DB (SQL Server) |
| 5 | Final Data Load | `AGGNE.PRD.LOAD_PA_PER_FINAL_OUPUT` | Snowflake PRD |
| 6 | Final XML Load | `AGGNE.PRD.PER_POLICYATTACH_LOAD_FINALDATA_XML` | Snowflake PRD |
| 7 | DCT Hit | `HB_PP_PolicyAttach_Automation` | Conversion DB (SQL Server) |
| 8 | Load API Table | UPDATE `AGGNE.PRD_XML.POLICYATTACH_MIGRATION_DCT` + `PER_LOAD_POLICYATTACH_API_TABLE` | Snowflake PRD |

**Step 1 is shared** — `SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD` builds both `T_Policyattach_000` (BP) and `T_PERPolicyattach_000` (PP), so a fix there (e.g. `STATUS_FLAG='D'` exclusion) affects both LOBs in one change.

**Validation checkpoint (after Step 3, before Step 4):**

```sql
SELECT * FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS;        -- BP
SELECT * FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS;    -- PP
```

---

## 7. Downstream of the payload (attach)

```
Snowflake attach views → PRD_XML DB (SQL Server) → DCT REST request
   → AGGNE.PRD.POLICY_ATTACH_TABLE (API table) → Informatica → DCT claims app
```

The claims app takes **LegacyPolicyNumber + DOL** and resolves the policy via the API table (`POLICYEFFECTIVEDATE <= DOL < POLICYEXPIRATIONDATE`, latest record wins). `AGGNE.PRD.POLICY_ATTACH_TABLE` is the **end-to-end validation point**: if a fix shows there with correct dates and non-empty coverages, it is client-visible. Always start debugging a reported DCT policy issue by inspecting `POLICY_ATTACH_XML` in that table.

---

## 8. Operating rules

- **SAFE_MODE=true** is the non-negotiable default — no SP calls / data writes without explicitly enabling.
- **Snowflake access is read-only** from tooling; all DDL/DML is applied manually.
- PP conversion scope is **DEV views only** (no `PA_PER_*` / PRD objects); deployment scripts are held until explicitly requested.
- The pipeline is **not** a one-shot migration — it runs repeatedly (daily batches, delta processing), so fixes must be idempotent and re-runnable.

---

## 9. Key file locations

| What | Where |
|------|-------|
| Middleware entry point | `middleware/main.py` (`python -m middleware.main --lob BP\|PP`) |
| ETL4 runner | `middleware/etl4.py` |
| Config readers | `middleware/sqlserver_client.py` |
| Snowflake auth | `middleware/snowflake_client.py` |
| PP conversion views | `sql/snowflake/1_conversion/PP/views/` |
| BP conversion views | `sql/snowflake/1_conversion/BP/views/` |
| PRD attach objects | `sql/snowflake/prd/` |
| XML engine + combine SPs | `sql/snowflake/stored_procedures/` |
| XSD validation schemas | `docs/PP_XML_Validation_Building.xsd`, `docs/PP_XML_Validation_Motor.xsd` |
| Mandatory-field gap analysis | `docs/PP_MandatoryField_GapByPolicy.csv` |
