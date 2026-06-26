# Policy Conversion — End-to-End Migration Flow

**Purpose:** Document the current migration pipeline (Pure Snowflake → DuckCreek DCT) for both BP and PP lines of business, as a baseline for redesign.

**Environment:** All work targets `AGGNE.DEV` (not deployed to PRD yet).  
**Config store:** SQL Server `DESKTOP-G01PH8C\SQLEXPRESS` — `Conversion` database.

---

## Architecture Overview

```
Pure (Source)
    │
    ▼
[ETL1] Source Load SP
    │  Creates staging/transient tables in AGGNE.DEV
    ▼
[ETL2] Views
    │  Normalise and shape staging data
    ▼
[ETL3] ConversionConfig / PP_ConversionConfig (SQL Server)
    │  Drives what to process — SequenceID, ScriptName, XML template, table names
    ▼
[ETL4] DYNAMIC_XML_V1  ×N rows (one call per config row)
    │  Substitutes {FIELDNAME} placeholders → writes XML fragments to *_Target tables
    ▼
[ETL5] Aggregation (views or SP)
    │  LISTAGG fragments per policy
    ▼
[ETL6] Final XML Assembly SP
    │  Builds complete DCT request XML envelope → POLICY_MIGRATION_DCT / PER_POLICY_MIGRATION_DCT
    ▼
[ETL7] DCT POST  ← TBD (to be clarified)
    │  Reads REQUEST_XML from staging table → POSTs to DuckCreek API
    ▼
DuckCreek (DCT)
```

---

## Config Tables (SQL Server — Conversion DB)

Both LOBs share the same column structure:

| Column | Purpose |
|--------|---------|
| `ConversionConfigId` | PK |
| `SequenceID` | Execution order |
| `ScriptName` | = ITR_TYPE passed to DYNAMIC_XML_V1 |
| `IsActive` | 1 = run, 0 = skip |
| `ConversionSourceTable` | Snowflake source table (DEV step) |
| `ConversionScript` | XML template with `{FIELDNAME}` placeholders |
| `ConversionTargetTable` | Snowflake target table to write fragments into |
| `AttachSourceTable` | Source for policy-attach step (nullable) |
| `AttachScript` | XML template for attach (nullable) |
| `AttachTargetTable` | Target for attach step (nullable) |

| LOB | Config Table | Active Row Count |
|-----|-------------|-----------------|
| BP | `ConversionConfig` | 67 |
| PP | `PP_ConversionConfig` | 18 |

---

## BP — Business Protection

### ETL1 — Source Data Load

**SP:** `AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()`  
- Pulls from Pure (source system) via joined tables  
- Creates transient staging tables: `Sample_CBP`, and many others  
- Covers: policy header, coverages, vehicles, buildings, claims, party, competitor info  
- 412KB SP — most complex step in the pipeline

### ETL2 — Views over Staging

Approximately 80+ views in `AGGNE.DEV` shape the staging data:
- `VW_SAMPLE_FINAL` — active BP policy set (base/driver)
- `VW_CBP_DUTY_DISCLOSURE` — criminal conviction / refused insurance flags
- `VW_CLAIM_HISTORY` / `VW_CLAIM_HISTORY_AGG` — claims history
- `VW_COMP_INFO_AGG` — competitor / prior info
- `VW_BUSINESS_FINAL` — business details
- `VW_FV`, `VW_CM` — fleet vehicle / commercial motor XML views
- `VW_LINE_UW_COMBINED` — UW adjustments
- Plus building, location, AOI, coverage sub-views

### ETL3 — Config-driven Preparation

Python (or manual trigger) reads `ConversionConfig` ordered by `SequenceID`.  
Each row defines one `DYNAMIC_XML_V1` call.

### ETL4 — XML Fragment Generation

**SP:** `AGGNE.DEV.DYNAMIC_XML_V1(SOURCETABLE, PAYLOAD, TARGETTABLE, ITR_TYPE)`

- Reads column names from `INFORMATION_SCHEMA.COLUMNS` for `SOURCETABLE`
- Builds a nested `REPLACE()` chain substituting every `{COLUMN}` in the XML template
- `INSERT INTO TARGETTABLE (ID, ITR_TYPE, PAYLOAD, LOAD_DATE) SELECT DISTINCT ...`
- `ID` = `PUREPOLICYNUMBER` (composite key: `policy|cml|expiryid`)
- Runs once per config row (67 times for BP)

**Target tables written (BP examples):**

| Target Table | ITR_TYPE | Content |
|-------------|----------|---------|
| `LINE_GP_Target` | `BP_LINE_GP` | General Property XML |
| `LINE_PPL_Target` | `BP_LINE_PPL` | Public/Products Liability XML |
| `LINE_PF_Target` | `BP_LINE_PF` | Professional Protection XML |
| `LINE_GT_Target` | `BP_LINE_GT` | Goods in Transit XML |
| `LINE_LE_Target` | `BP_LINE_LE` | Legal Expenses XML |
| `LINE_SV_Target` | `BP_LINE_SV` | Stock Vehicles XML |
| `LINE_CV_Target` | `BP_LINE_CV` | Commercial Vehicles XML |
| `LINE_TA_Target` | `BP_LINE_TA` | Tax Audit XML |
| `BUILDING_Target` | `RISK_Building` | Building coverage XML |
| `CLAIM_HISTORY_TARGET` | `CLAIM_HISTORY` | Claims XML |
| ... | ... | ... |

All target tables share the same schema: `(ID, ITR_TYPE, PAYLOAD, LOAD_DATE)`

### ETL5 — Aggregation (Views)

BP aggregation is handled inline by views — no separate SP call needed:

- `*_PAYLOAD` views (e.g. `LINE_GP_PAYLOAD`) LISTAGG from `*_Target` tables
- `BUILDING_FINAL_AGG`, `VW_CLAIM_HISTORY_AGG`, `ACCOUNT_LOC_AGG`, `AOI_FINAL_AGG` etc. aggregate sub-fragments
- All consumed by the master consolidation view

### ETL6 — Final XML Assembly

**View:** `AGGNE.DEV.VW_CBP_OUTPUT_CONVERSION`
- LEFT JOINs ~25 tables/views to produce one row per policy
- Columns include all XML fragment columns: `RISK_BUILDING`, `GP`, `PPL`, `PF`, `GT`, `LE`, `SV`, `CV`, `TA`, `RISK_FLEETVEHICLE_PAYLOAD`, `RISK_CM_PAYLOAD`, `AOI`, `ACC_LOC`, `CLAIMS_PAYLOAD`, `LINE_UW`, `MANUSCRIPT`, `PRIOR_INFO`
- Filter: `WHERE PARTYID IS NOT NULL`

**SP:** `AGGNE.DEV.POLICY_INSERTPAYLOADINDCT()`
1. `INSERT INTO POLICY_MIGRATION_DCT_PREVDATA SELECT * FROM POLICY_MIGRATION_DCT` (archive)
2. `TRUNCATE TABLE POLICY_MIGRATION_DCT`
3. `INSERT INTO POLICY_MIGRATION_DCT (BUCKET, LEGACYPOLICYNUMBER, REQUEST_XML)`  
   — Reads `VW_CBP_OUTPUT_CONVERSION`  
   — Builds the full DCT XML request envelope using 130+ nested `REPLACE()` substitutions  
   — Inserts assembled XML per policy

**Output table:** `AGGNE.DEV.POLICY_MIGRATION_DCT`

| Column | Value |
|--------|-------|
| `BUCKET` | 1 (DEV hardcoded; UAT uses ROW_NUMBER) |
| `LEGACYPOLICYNUMBER` | Policy number |
| `REQUEST_XML` | Complete DCT API request XML |

### ETL7 — DCT POST *(TBD)*

**SP:** `AGGNE.DEV.GETBUCKETJSON()` — returns `{"P00001234": 1, ...}` JSON  
**Next:** Something reads `REQUEST_XML` from `POLICY_MIGRATION_DCT` per bucket and POSTs to DCT API.  
*Mechanism to be confirmed.*

---

## PP — Personal Protection

### ETL1 — Source Data Load *(TBD)*

PP equivalent of `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` — SP name to be confirmed.

### ETL2 — Views over Staging

PP-specific views in `AGGNE.DEV` prefixed `PER_`:
- `PER_VW_SAMPLE_FINAL` — active PP policy set (base/driver)
- `PER_VW_CBP_DUTY_DISCLOSURE` — criminal/refused flags
- `PER_VW_CLAIM_HISTORY` / `PER_VW_CLAIM_HISTORY_AGG` — claims
- `PER_VW_COMP_INFO_AGG` — prior/competitor info
- `PER_RISK_BUILDING_FINAL` — building details
- `PER_VW_CM` — commercial motor (PM) XML
- `PER_ACCOUNT_LOC`, `PER_ACCOUNT_LOC_AGG` — location / AOI
- `PER_BUILDING_FINAL_AGG` — aggregated building XML

### ETL3 — Config-driven Preparation

Python reads `PP_ConversionConfig` ordered by `SequenceID` (18 active rows).

### ETL4 — XML Fragment Generation

Same `DYNAMIC_XML_V1` SP, same pattern — writes to `PER_*_Target` tables:

| Target Table | ITR_TYPE | Content |
|-------------|----------|---------|
| `PER_RISK_BUILDING_TARGET` | `RISK_Building` | Building coverage XML |
| `PER_CLAIM_HISTORY_TARGET` | `CLAIM_HISTORY` | Claims XML |
| `PER_ACCOUNT_LOC_TARGET` | `ACC_LOC` | Location XML |
| `PER_COM_COVERAGES_TARGET` | `RISK_Building_PM` | Commercial motor XML |
| `PER_COMPETITOR_INFORMATION_TARGET` | `Prior_INFO` | Prior info XML |
| ... | ... | ... |

### ETL5 — Intermediate Materialisation

**SP:** `AGGNE.DEV.PER_CONVERSION_FINAL_LOAD()`  
Unlike BP (which uses a dynamic view), PP **materialises a physical table**:

```sql
CREATE OR REPLACE TABLE AGGNE.DEV.PER_FINAL AS
SELECT DISTINCT ...
FROM PER_VW_SAMPLE_FINAL T1
LEFT JOIN DIM_PARTY_CML_CSL_NEW T2      -- member/party data
LEFT JOIN PER_VW_CBP_DUTY_DISCLOSURE T3
LEFT JOIN PER_VW_CLAIM_HISTORY_AGG T4
LEFT JOIN PER_VW_COMP_INFO_AGG T5
LEFT JOIN PER_ACCOUNT_LOC_AGG T9
LEFT JOIN PER_BUILDING_FINAL_AGG T12
LEFT JOIN VW_PARTYDET T21               -- DCT party ID
LEFT JOIN PER_VW_CM T24
LEFT JOIN POLICYCONVERSION_PAYMENT_METHOD T28
```

Output: `AGGNE.DEV.PER_FINAL` — one row per policy with all XML payload columns  
Also logs to `LOAD_AUDIT_LOG`.

### ETL6 — Final XML Assembly

**SP:** `AGGNE.DEV.PER_CONVERSION_FINAL_XML()`
1. `INSERT INTO PER_POLICY_MIGRATION_DCT_PREVDATA SELECT * FROM PER_POLICY_MIGRATION_DCT` (archive)
2. `TRUNCATE TABLE PER_POLICY_MIGRATION_DCT`
3. `INSERT INTO PER_POLICY_MIGRATION_DCT (BUCKET, LEGACYPOLICYNUMBER, REQUEST_XML)`  
   — Reads `PER_FINAL`  
   — Filter: `LOAD_DATE = TODAY AND PHONE <> '' AND LEGACYPOLICYNUMBER IN (PP_Conversion_FixList)`  
   — Builds DCT XML using 60 nested `REPLACE()` substitutions  
   — `BUCKET = NTILE(10) OVER (ORDER BY LEGACYPOLICYNUMBER)` — distributes across 10 buckets

**Output table:** `AGGNE.DEV.PER_POLICY_MIGRATION_DCT`

| Column | Value |
|--------|-------|
| `BUCKET` | 1–10 (NTILE distribution) |
| `LEGACYPOLICYNUMBER` | Policy number |
| `REQUEST_XML` | Complete DCT API request XML |

### ETL7 — DCT POST *(TBD)*

Same pattern as BP but reading from `PER_POLICY_MIGRATION_DCT`.  
*Mechanism to be confirmed.*

---

## Key Differences — BP vs PP

| | BP | PP |
|--|----|----|
| ETL1 source SP | `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` | TBD |
| Config table | `ConversionConfig` (67 rows) | `PP_ConversionConfig` (18 rows) |
| Consolidation method | Dynamic VIEW (`VW_CBP_OUTPUT_CONVERSION`) | Materialised TABLE (`PER_FINAL` via `PER_CONVERSION_FINAL_LOAD`) |
| Final XML SP | `POLICY_INSERTPAYLOADINDCT` | `PER_CONVERSION_FINAL_XML` |
| Staging table | `POLICY_MIGRATION_DCT` | `PER_POLICY_MIGRATION_DCT` |
| Archive table | `POLICY_MIGRATION_DCT_PREVDATA` | `PER_POLICY_MIGRATION_DCT_PREVDATA` |
| Bucket strategy | BUCKET=1 (DEV) | NTILE(10) — 10 buckets |
| Policy filter | `PARTYID IS NOT NULL` | `PP_Conversion_FixList` + `LOAD_DATE = TODAY` |
| PartyType in XML | `O` (Organisation) | `P` (Person) |
| XML product tag | `BusinessPackage` | `PersonalPackage` |
| Coverage columns | RISK_BUILDING, GP, PPL, PF, GT, LE, SV, CV, TA, AOI, FV, CM, LINE_UW | LOC (buildings), PM (personal motor) |

---

## Snowflake Objects Summary

### Stored Procedures

| SP | Schema | Purpose | Args |
|----|--------|---------|------|
| `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` | DEV | BP source data load | 0 |
| `DYNAMIC_XML_V1` | DEV | XML fragment generation (ETL4) | 4 |
| `COMBINEPAYLOAD` | DEV | LISTAGG fragments (alternative ETL5) | 4 |
| `POLICY_INSERTPAYLOADINDCT` | DEV/UAT | BP final XML assembly (ETL6) | 0 |
| `PER_CONVERSION_FINAL_LOAD` | DEV | PP intermediate materialisation | 0 |
| `PER_CONVERSION_FINAL_XML` | DEV | PP final XML assembly (ETL6) | 0 |
| `GETBUCKETJSON` | DEV | Returns bucket map from POLICY_MIGRATION_DCT | 0 |
| `SP_POLICY_XML_INTEGRATION` | DEV/UAT | DCT policy search integration | 2 |
| `POLICY_PARTY_XML` | DEV | Builds policy search XML for PURE_POLICY_SEARCH_BP_PER | 0 |
| `INSERT_VALID_POLICY` | DEV | Loads specific policies into POLICYATTACH_TO_PROCESS | 1 |
| `FINAL_TABLE_ARCHIVE_AND_DELETE_XML` | DEV | Archive/delete from POLICYATTACH_MIGRATION_DCT | 0 |
| `PER_FINAL_TABLE_ARCHIVE_AND_DELETE_XML` | DEV | PP equivalent archive/delete | 0 |

### Key Tables

| Table | Schema | Purpose |
|-------|--------|---------|
| `Sample_CBP` | DEV | BP staging (transient, created by ETL1) |
| `*_Target` (56 tables) | DEV | XML fragment output from DYNAMIC_XML_V1 |
| `PER_*_Target` | DEV | PP XML fragment output |
| `PER_FINAL` | DEV | PP consolidated output (materialised by PER_CONVERSION_FINAL_LOAD) |
| `POLICY_MIGRATION_DCT` | DEV | BP final XML ready for DCT POST |
| `PER_POLICY_MIGRATION_DCT` | DEV | PP final XML ready for DCT POST |
| `POLICY_MIGRATION_DCT_PREVDATA` | DEV | BP archive of previous run |
| `PER_POLICY_MIGRATION_DCT_PREVDATA` | DEV | PP archive of previous run |
| `PP_Conversion_FixList` | DEV | Filter list of PP policies to process |
| `POLICYCONVERSION_PAYMENT_METHOD` | DEV | Payment method lookup |
| `LOAD_AUDIT_LOG` | DEV | Process audit trail |

### Key Views

| View | Purpose |
|------|---------|
| `VW_CBP_OUTPUT_CONVERSION` | BP master consolidation (ETL5 output, 25 JOINs) |
| `VW_CBP_OUTPUT_PA_V2` | BP policy attach version (adds USERNAME/PASSWORD/ACTUALID) |
| `VW_SAMPLE_FINAL` | Active BP policy set |
| `PER_VW_SAMPLE_FINAL` | Active PP policy set |
| `VW_CLAIM_HISTORY_AGG` | Claims LISTAGG |
| `PER_VW_CLAIM_HISTORY_AGG` | PP claims LISTAGG |
| `BUILDING_FINAL_AGG` | Building XML LISTAGG |
| `PER_BUILDING_FINAL_AGG` | PP building XML LISTAGG |
| `VW_LINE_UW_COMBINED` | UW adjustments combined |
| `VW_FV`, `VW_CM` | Fleet vehicle / commercial motor XML |
| `PER_VW_CM` | PP commercial motor XML |

---

## Open Items / TBD

| # | Item | Notes |
|---|------|-------|
| 1 | What triggers ETL4 (DYNAMIC_XML_V1 per row)? | Python loop, or a Snowflake SP that reads ConversionConfig? |
| 2 | PP ETL1 source load SP name | BP uses `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` — PP equivalent? |
| 3 | ETL7 DCT POST mechanism | What reads `POLICY_MIGRATION_DCT` / `PER_POLICY_MIGRATION_DCT` and POSTs to DCT? |
| 4 | BP BUCKET strategy for DEV | Currently hardcoded as 1 — needs proper bucketing like UAT (ROW_NUMBER) or PP (NTILE) |
| 5 | PP_Conversion_FixList scope | Currently PP only processes policies in this list — is this intentional for initial go-live? |

---

*Last updated: 2026-06-24*  
*Based on: AGGNE.DEV schema analysis, UAT SP definitions, SQL Server ConversionConfig review*
