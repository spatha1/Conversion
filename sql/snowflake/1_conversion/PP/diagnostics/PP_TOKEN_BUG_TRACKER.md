# PP Token Bug Tracker

## Purpose
This document tracks every token in the PP conversion pipeline — its status, which ETL layer it comes from, and any known bugs. Use alongside `PP_TOKEN_LINEAGE.sql` to diagnose DCT UI mandatory field failures.

---

## How to Read GAP_LAYER

| GAP_LAYER | Meaning | Action |
|---|---|---|
| `PURE` | Value missing in PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT source | Data issue in PURE system — check source table |
| `STEP1` | PURE has data but Sample_PER (step 1) is not picking it up | Fix the join or column selection in Pure_to_Write SP |
| `STEP2` | Sample_PER has it but HB_02/HC_02 (step 2) is not propagating | Fix the step 2 table creation in Pure_to_Write SP |
| `VIEW` | Step 2 table has it but DEV source view is not exposing the column | Add the column to the DEV source view |
| `XML_CHAIN` | View has it but token is missing from REPLACE chain or template | Add to PP_ConversionConfig template or PER_CONVERSION_FINAL_XML SP |
| `OK` | All layers populated | No action needed |

---

## ETL Layer Map

```
PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT  (PRD05 = PURE source, used for both DEV and PRD)
        │
        ▼
SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD
        │
        ├──► AGGNE.DEV.Sample_PER              ← Step 1 table  (staging)
        │
        ├──► AGGNE.DEV.HB_02                   ← Step 2 table (Home Buildings, staging)
        ├──► AGGNE.DEV.HC_02                   ← Step 2 table (Home Contents, staging)
        ├──► AGGNE.DEV.COM_02                  ← Step 2 table (Commercial Motor, staging)
        └──► AGGNE.DEV.Output_Coverage_PER     ← Coverage/premium data (staging)
                │
                ▼
        DEV Source Views (AGGNE.DEV.*)
        PER_HOME_BUILDING_PAYLOAD  ← feeds Seq 7 (HB) and Seq 13 (HC)
        PER_BB_SUBCOVERAGES        ← feeds Seq 4 (BB sub-coverages)
        BUILDING_UW                ← feeds Seq 5 (HB UW adjustments)
        HB_CLAUSE                  ← feeds Seq 6 (HB clauses)
        PER_HC_ITEMS_EXCEED_VALUE  ← feeds Seq 8
        PER_HC_SPECIFIEDCONTENTS   ← feeds Seq 9
        PER_HC_SUBCOVERAGES        ← feeds Seq 10
        PER_HC_BUILDING_UW         ← feeds Seq 11
        PER_HC_CLAUSE              ← feeds Seq 12
        PER_RISK_BUILDING_FINAL    ← feeds Seq 14 (outer risk block)
        COM_CLAUSE                 ← feeds Seq 17 (motor clauses)
        PER_COM_PAYLOAD            ← feeds Seq 18 (motor risk)
                │
                ▼
        DYNAMIC_XML_V1 resolves tokens → ETL target tables
        PER_BUILDING_TARGET        ← HB sub-payloads + RISK_Building_HB
        PER_HC_TARGET              ← HC sub-payloads + RISK_Building_HC
        PER_RISK_BUILDING_TARGET   ← outer RISK_Building block
        PER_COM_COVERAGES_TARGET   ← motor clauses + RISK_Building_PM
                │
                ▼
        PER_BUILDING_FINAL_AGG (view)
        Resolves {HB_CLAUSE}, {UW} tokens
        Injects BB sub-coverages inside </coverage>
        Aggregates multiple buildings per policy
                │
                ▼
        PER_CONVERSION_FINAL_LOAD SP  →  PER_FINAL
        PER_CONVERSION_FINAL_XML SP   →  PER_POLICY_MIGRATION_DCT.REQUEST_XML
```

---

## Token Status Table

### Config Step Seq 04 — Building_SubCov (BB sub-coverages)
Source view: `PER_BB_SUBCOVERAGES` | Target: `PER_BUILDING_TARGET` ITR_TYPE=Building_SubCov

| Token | Status | Notes |
|---|---|---|
| `{TYPE}` | OK | Sub-coverage type code |
| `{IVALUE}` | OK | Integer limit value |
| `{SVALUE}` | OK | String value (e.g. Taken/NotTaken) |
| `{CODE}` | OK | Coverage code |
| `{DESCRIPTION}` | OK | Coverage description |
| `{EXP_PREM}` | OK | Expiring premium |

---

### Config Step Seq 05 — BUILDING_UW (HB underwriting adjustments)
Source view: `BUILDING_UW` | Target: `PER_BUILDING_TARGET` ITR_TYPE=BUILDING_UW

| Token | Status | Notes |
|---|---|---|
| `{COVERAGE}` | OK | |
| `{ADJUSTMENTSELECTION}` | OK | |
| `{ADJUSTMENTDOLLARANDPERCENT}` | OK | |
| `{RECURRINGINDICATOR}` | OK | |
| `{UNDERWRITINGDESCRIPTION}` | OK | |

---

### Config Step Seq 06 — HB_CLAUSE (Home Buildings clauses)
Source view: `HB_CLAUSE` | Target: `PER_BUILDING_TARGET` ITR_TYPE=HB_CLAUSE

| Token | Status | Notes |
|---|---|---|
| `{DCCLAUSETYPE}` | OK | |
| `{DCINPUT}` | OK | |

---

### Config Step Seq 07 — RISK_Building_HB (main HB coverage block)
Source view: `PER_HOME_BUILDING_PAYLOAD` | Target: `PER_BUILDING_TARGET` ITR_TYPE=RISK_Building_HB

| Token | Status | GAP_LAYER | Notes |
|---|---|---|---|
| `{VOLUNTARYEXCESS}` | OK | — | From HB_02.VOLUNTARYEXCESS |
| `{ACCIDENTALLOSSORDAMAGE}` | OK | — | From HB_02, converted 0/1 |
| `{HOMEBUILDINGSLIMIT}` | OK | — | From HB_02 via HB_02 join |
| `{LANDLORDPROTECTIONS}` | OK | — | From HB_02 |
| `{MINIMUMRENTALPERIOD}` | OK | — | From HB_02 |
| `{WEEKLYRENT}` | OK | — | From HB_02 |
| `{HB_CLAUSE}` | FIXED 2026-06-24 | — | Was missing; added column to PER_HOME_BUILDING_PAYLOAD |
| `{HBCLMINCD}` | FIXED 2026-06-24 | — | Was missing; added from Output_Coverage_PER |
| `{HBCLMCNT}` | FIXED 2026-06-24 | — | Was missing; added from Output_Coverage_PER |
| `{EXPPREM}` | OK | — | From Output_Coverage_PER.HMEXPPREM |
| `{STANDARDEXCESS}` | **BUG — VIEW** | VIEW | HB_02 has it; DEV view NOT exposing it → empty in XML |
| `{IMPOSEDEXCESS}` | **BUG — VIEW** | VIEW | HB_02 has it; DEV view NOT exposing it → empty in XML |
| `{EARTHQUAKEEXCESS}` | **BUG — VIEW** | VIEW | HB_02 has it; DEV view NOT exposing it → empty in XML |
| `{FLOODEXCESS}` | **BUG — VIEW** | VIEW | HB_02 has it; DEV view NOT exposing it → empty in XML |

**Fix needed**: Add `STANDARDEXCESS`, `IMPOSEDEXCESS`, `EARTHQUAKEEXCESS`, `FLOODEXCESS` columns to `PER_HOME_BUILDING_PAYLOAD` from the HB_02 join, matching what `PA_PER_HOME_BUILDING_PAYLOAD` (PRD reference view) exposes.

---

### Config Step Seq 08 — HC_exceed_values
Source view: `PER_HC_ITEMS_EXCEED_VALUE` | Target: `PER_HC_TARGET` ITR_TYPE=HC_exceed_values

| Token | Status | Notes |
|---|---|---|
| `{VALUE}` | OK | |
| `{DESCRIPTION}` | OK | |

---

### Config Step Seq 09 — HC_Specified_Contents
Source view: `PER_HC_SPECIFIEDCONTENTS` | Target: `PER_HC_TARGET` ITR_TYPE=HC_Specified_Contents

| Token | Status | Notes |
|---|---|---|
| `{VALUE}` | OK | |
| `{DESCRIPTION}` | OK | |

---

### Config Step Seq 10 — Building_SubCov (HC sub-coverages)
Source view: `PER_HC_SUBCOVERAGES` | Target: `PER_HC_TARGET` ITR_TYPE=Building_SubCov

| Token | Status | Notes |
|---|---|---|
| `{TYPE}` | OK | |
| `{IVALUE}` | OK | |
| `{SVALUE}` | OK | |
| `{CODE}` | OK | |
| `{DESCRIPTION}` | OK | |
| `{EXP_PREM}` | OK | |

---

### Config Step Seq 11 — BUILDING_UW (HC underwriting adjustments)
Source view: `PER_HC_BUILDING_UW` | Target: `PER_HC_TARGET` ITR_TYPE=BUILDING_UW

| Token | Status | Notes |
|---|---|---|
| `{COVERAGE}` | OK | |
| `{ADJUSTMENTSELECTION}` | OK | |
| `{ADJUSTMENTDOLLARANDPERCENT}` | OK | |
| `{RECURRINGINDICATOR}` | OK | |
| `{UNDERWRITINGDESCRIPTION}` | OK | |

---

### Config Step Seq 12 — LOC_HC_CLAUSE (Home Contents clauses)
Source view: `PER_HC_CLAUSE` | Target: `PER_HC_TARGET` ITR_TYPE=LOC_HC_CLAUSE

| Token | Status | Notes |
|---|---|---|
| `{DCCLAUSETYPE}` | OK | |
| `{DCINPUT}` | OK | |

---

### Config Step Seq 13 — RISK_Building_HC (main HC coverage block)
Source view: `PER_HOME_BUILDING_PAYLOAD` | Target: `PER_HC_TARGET` ITR_TYPE=RISK_Building_HC

| Token | Status | GAP_LAYER | Notes |
|---|---|---|---|
| `{VOLUNTARYEXCESS}` | OK | — | |
| `{ACCIDENTALLOSSORDAMAGE}` | OK | — | |
| `{SPECIFIEDITEMSAWAY}` | OK | — | |
| `{UNSPECIFIEDITEMSAWAY}` | OK | — | |
| `{UNSPECIFIEDITEMSAWAYLIMIT}` | OK | — | |
| `{HC_EXCEED_VALUES}` | OK | — | From PER_HC_TARGET sub-rows |
| `{HC_SPECIFIED_CONTENTS}` | OK | — | From PER_HC_TARGET sub-rows |
| `{SUBCOV}` | OK | — | HC sub-coverages from PER_HC_TARGET |
| `{HC_CLAUSE}` | FIXED 2026-06-24 | — | Was `{clauses}`; renamed in CONVERSION DB seq 13 template |
| `{UW}` | DEFAULTED | — | Hardcoded '' (empty) — UW source not yet identified |
| `{HCCLMINCD}` | OK | — | From Output_Coverage_PER |
| `{HCCLMCNT}` | OK | — | From Output_Coverage_PER |
| `{HBEXPPREM}` | OK | — | From Output_Coverage_PER.HMEXPPREM |
| `{STANDARDEXCESS}` | **BUG — VIEW** | VIEW | HC_02 has it; DEV view NOT exposing it |
| `{IMPOSEDEXCESS}` | **BUG — VIEW** | VIEW | HC_02 has it; DEV view NOT exposing it |
| `{EARTHQUAKEEXCESS}` | **BUG — VIEW** | VIEW | HC_02 has it; DEV view NOT exposing it |
| `<FloodDamage>Taken</FloodDamage>` | DEFAULTED | — | Hardcoded "Taken" — PA shows numeric |
| `<ClassCode>HH/HBC` | DEFAULTED | — | Hardcoded — PA shows FISR/BSP |
| `<HomeContentsTotal>9100` | DEFAULTED | — | Hardcoded — should be from data |
| `<SpecifiedContentsTotal>622221` | DEFAULTED | — | Hardcoded — should be from data |

---

### Config Step Seq 14 — RISK_Building (outer risk block)
Source view: `PER_RISK_BUILDING_FINAL` | Target: `PER_RISK_BUILDING_TARGET` ITR_TYPE=RISK_Building

| Token | Status | GAP_LAYER | Notes |
|---|---|---|---|
| `{RISKNUMBER}` | OK | — | Location/risk number |
| `{RISK_BUILDING}` | OK | — | HB coverage block (from PER_BUILDING_FINAL_AGG) |
| `{RISK_BC}` | OK | — | HC coverage block |
| `{ROOFCONSTRUCTION_FINAL}` | OK | — | From Sample_PER.RoofConst |
| `{STOREYS}` | OK | — | From Sample_PER |
| `{YEARBUILDINGCONSTRUCTED}` | OK | — | From Sample_PER |
| `{YEARLASTREWIRED}` | OK | — | From Sample_PER |
| `{YEARLASTREPLUMBED}` | OK | — | From Sample_PER |
| `{MAINWALLCONSTRUCTION_FINAL}` | OK | — | From Sample_PER.WallConst |
| `{FLOORCONSTRUCTION_FINAL}` | OK | — | From Sample_PER.FloorConst |
| `{ALARMSYSTEMINSTALLED_FINAL}` | OK | — | From Sample_PER.AlarmSystem |
| `{DEADLOCKSINSTALLED_FINAL}` | OK | — | From Sample_PER.Deadlocks |
| `{GRILLKEYLOCKINSTALLED_FINAL}` | OK | — | From Sample_PER.GrillKeyLock |
| `{SECURITYDETAILS}` | OK | — | From Sample_PER |
| `{HOWOCCUPPIED}` | OK | — | From Sample_PER.HowOccup |
| `{INTERESTEDPARTY}` | TO CHECK | — | Need to verify source |
| `<ImposedExcess></ImposedExcess>` | DEFAULTED | — | Hardcoded empty in seq 14 template |
| `<StandardExcess></StandardExcess>` | DEFAULTED | — | Hardcoded empty in seq 14 template |

---

### Config Step Seq 17 — COM_CLAUSE (Motor clauses)
Source view: `COM_CLAUSE` | Target: `PER_COM_COVERAGES_TARGET` ITR_TYPE=COM_CLAUSE

| Token | Status | Notes |
|---|---|---|
| `{DCCLAUSETYPE}` | OK | |
| `{DCINPUT}` | OK | |

---

### Config Step Seq 18 — RISK_Building_PM (Motor risk)
Source view: `PER_COM_PAYLOAD` | Target: `PER_COM_COVERAGES_TARGET` ITR_TYPE=RISK_Building_PM

| Token | Status | GAP_LAYER | Notes |
|---|---|---|---|
| `{VOLUNTARYEXCESS}` | OK | — | |
| `{EXCESSWAIVERFORGLASS}` | OK | — | |
| `{PROTECTIONTYPE}` | OK | — | |
| `{VEHICLETYPE}` | OK | — | |
| `{IMPORTFLAG}` | OK | — | |
| `{MAKE}` | OK | — | |
| `{MODEL}` | OK | — | |
| `{YEAR}` | OK | — | |
| `{REGISTRATIONNUMBER}` | OK | — | |
| `{CHOICEOFREPAIR}` | OK | — | |
| `{PMCLMINCD}` | OK | — | |
| `{PMCLMCNT}` | OK | — | |
| `{MARKETVALUEWITHACCESSORIESAMOUNT}` | OK | — | |
| `{COM_CLAUSE}` | FIXED 2026-06-24 | — | Was `{CLAUSE}`; renamed in CONVERSION DB seq 18 template |
| `{UW}` | OK | — | From PER_COM_PAYLOAD.UW column |
| `{SUBCOV}` | OK | — | Motor sub-coverages (correct here, unlike seq 7) |

---

### Final SP — PER_CONVERSION_FINAL_XML (Account/Policy level)
Source table: `PER_FINAL` | Output: `PER_POLICY_MIGRATION_DCT.REQUEST_XML`

| Token | Status | GAP_LAYER | Notes |
|---|---|---|---|
| `{CMLLEGALENTITY}` | OK | — | |
| `{CMLNUMBER}` | OK | — | |
| `{CSLNUMBER}` | OK | — | |
| `{CSL_LEGAL_ENTITY}` | FIXED 2026-06-24 | — | Added to REPLACE chain; was in template but not resolved (33 policies) |
| `{ABN_NZBN}` | OK | — | |
| `{PARTYID}` | OK | — | |
| `{PHONE}` | OK | — | |
| `{EMAIL}` | OK | — | |
| `{MAINCONTACT}` | OK | — | |
| `{EFFECTIVEDATE}` | OK | — | |
| `{EXPIRATIONDATE}` | OK | — | |
| `{MANUSCRIPT}` | OK | — | |
| `{PRIMARYRATINGSTATE}` | OK | — | |
| `{PAYMENT_METHOD}` | OK | — | |
| `{STANDARD_INDUSTRY_CODE}` | OK | — | |
| `{SITE_SUBURB}` | OK | — | |
| `{SITE_STATE}` | OK | — | |
| `{SITE_POSTCODE}` | OK | — | |
| `{SITE_STREET}` | OK | — | |
| `{SITE_COUNTRY}` | OK | — | |
| `{COUNTRY}` | OK | — | |
| `{CURRENCY}` | OK | — | |
| `{COUNTRYCODE}` | OK | — | |
| `{LOAD_DATE}` | OK | — | |
| `{LOC}` | OK | — | Full location/risk XML block (from PER_ACCOUNT_LOC) |
| `{PM}` | OK | — | Motor block |
| `{ACC_LOC}` | OK | — | Account location |
| `{PRIOR_INFO}` | OK | — | |
| `{CLAIMS_PAYLOAD}` | OK | — | |
| `{CSL_REGION}` | OK | — | |
| `{CSL_ZONE}` | OK | — | |
| `{CSL_AREA_MANAGER}` | OK | — | |
| `{CML_RISK_ACCOUNT_MANAGER}` | OK | — | |
| `{CSL_MEMBER_STATUS}` | OK | — | |
| `{CSL_CREDIT_LIMIT}` | OK | — | |
| `{STOP_CREDIT}` | OK | — | |
| `{PROBABILITY_OF_DEFAULT}` | OK | — | |
| `{STREET}` | OK | — | |
| `{SUBURB}` | OK | — | |
| `{STATE}` | OK | — | |
| `{POSTCODE}` | OK | — | |

---

## Bug Priority List

### P1 — Causing DCT UI mandatory field failures (fix now)

| # | Bug | File to Fix | Fix |
|---|---|---|---|
| 1 | `{STANDARDEXCESS}`, `{IMPOSEDEXCESS}`, `{EARTHQUAKEEXCESS}`, `{FLOODEXCESS}` not in HB template | `PER_HOME_BUILDING_PAYLOAD.sql` | Add 4 columns from HB_02 (see PA_PER_HOME_BUILDING_PAYLOAD for reference) |
| 2 | `{STANDARDEXCESS}`, `{IMPOSEDEXCESS}`, `{EARTHQUAKEEXCESS}` not in HC template | `PER_HOME_BUILDING_PAYLOAD.sql` | Same view, add for HC path (from HC_02) |
| 3 | `<ImposedExcess>` and `<StandardExcess>` hardcoded empty in seq 14 outer risk template | `PP_ConversionConfig` seq 14 | Replace hardcoded empty with proper tokens referencing HB_02 fields |

### P2 — Data accuracy (defaulted / wrong values)

| # | Bug | File to Fix | Fix |
|---|---|---|---|
| 4 | `<FloodDamage>Taken</FloodDamage>` hardcoded in HC template | `PP_ConversionConfig` seq 13 | Replace with `{FLOODDAMAGE}` token; expose from HC_02 |
| 5 | `<ClassCode><APRA>HH</APRA><Business>HBC</Business>` hardcoded | Seq 7 and 13 templates | PA shows FISR/BSP — determine correct mapping |
| 6 | `<HomeContentsTotal>9100` hardcoded | Seq 13 template | Source from HC_02 |
| 7 | `<SpecifiedContentsTotal>622221` hardcoded | Seq 13 template | Source from HC_02 |

### P3 — To investigate

| # | Bug | Notes |
|---|---|---|
| 8 | `{UW}` (HB) defaulted to empty | UW adjustment source not identified |
| 9 | `{INTERESTEDPARTY}` in seq 14 | Verify source is correctly joined in PER_RISK_BUILDING_FINAL |

---

## How to Use PP_TOKEN_LINEAGE.sql

1. Run the full end-to-end first: `run_all_seqs_pp.sql` → `CALL PER_CONVERSION_FINAL_LOAD()` → `CALL PER_CONVERSION_FINAL_XML()`
2. Open `PP_TOKEN_LINEAGE.sql` in Snowflake
3. Run the main query to see all tokens per policy per step
4. Filter by `GAP_LAYER <> 'OK'` to see only rows with issues
5. Use the `NOTE` column — tokens marked `⚠️` are known bugs documented above
6. Run the QUICK SUMMARY block (commented at bottom) to see which tokens have the most policy-level failures

---

## Key Source Table Reference

| Table | Schema | What It Contains |
|---|---|---|
| `PER_POLICY_MIGRATION_DCT` | AGGNE.DEV | Final REQUEST_XML output |
| `PER_FINAL` | AGGNE.DEV | Assembled policy/account flat row for final SP |
| `PER_BUILDING_TARGET` | AGGNE.DEV | HB sub-payloads + RISK_Building_HB blocks |
| `PER_HC_TARGET` | AGGNE.DEV | HC sub-payloads + RISK_Building_HC blocks |
| `PER_RISK_BUILDING_TARGET` | AGGNE.DEV | Outer RISK_Building blocks |
| `PER_COM_COVERAGES_TARGET` | AGGNE.DEV | Motor clause + risk blocks |
| `HB_02` | AGGNE.DEV | Home Buildings data (step 2 staging table) |
| `HC_02` | AGGNE.DEV | Home Contents data (step 2 staging table) |
| `Sample_PER` | AGGNE.DEV | Policy/location data (step 1 staging table) |
| `Output_Coverage_PER` | AGGNE.DEV | Claims count and premium data (staging) |
| `insurance_file` | PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT | PRD05 — raw PURE policy records |
| `PER_HomeContents` | PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT | PRD05 — raw building/contents data |
| `PER_RiskSelection` | PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT | PRD05 — raw location/address data |
