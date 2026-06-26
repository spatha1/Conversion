# Policy Attach — Coverage Reference
## BP (Business Pack) and PP (Personal Pack)
> Source: AGGNE.PRD schema views, derived from PRD sub-coverage views (2026-06-25)
> Data flow: PURE → `SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD` → PRD staging tables → `_IDENTIFIER` views → `DYNAMIC_XML_V1` → `_TARGET` tables → XML payload

---

## 1. BP — Business Pack

BP policies can have risk-level coverages (per location) and line-level coverages (across the whole policy).

### Key scope table
`AGGNE.PRD.SAMPLE_POLICYATTACH_FINAL_IDENTIFIER` — controls which BP policies enter the attach run.

---

### 1.1 BB — Business Buildings (Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `Building` |
| PRD staging table | `AGGNE.PRD.LOCATION_BB_COVERAGE_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.LOCATION_BB_COVERAGE_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_BUILDING_SUBCOVERAGES` |
| Key value field | `BUSINESSBUILDINGSLIMIT` |

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `BBGLS_SD` | `GLS_SD` | Glass | `FIXEDGLASS`, `glass` | glass ≠ 'Not Taken' |
| 2 | `BBFLD_SD` | `FLD_SD` | Flood | `BBFLOODPROTECTION`, `flooddamage` | flooddamage ≠ 'Not Taken' |
| 3 | `BBLOR_SD` | `LOR_SD` | Loss of Rent | `LOSSOFRENTLIMIT` | limit ≠ 0 |
| 4 | `BBACC_SD` | `ACC_SD` | Accidental Damage | `ACCIDENTALLOSSORDAMAGELIMIT` | limit ≠ 0 |
| 5 | `BBSTD_SD` | `STD_SD` | Standard | `BUSINESSBUILDINGSLIMIT` | always included |
| 6 | `BBSTD_BF` | `STD_BF` | Bushfire | `BUSINESSBUILDINGSLIMIT` | always included |
| 7 | `BBSTD_CY` | `STD_CY` | Cyclone | `BUSINESSBUILDINGSLIMIT` | always included |
| 8 | `BBSTD_EQ` | `STD_EQ` | Earthquake | `BUSINESSBUILDINGSLIMIT` | always included |
| 9 | `BBSTD_ST` | `STD_ST` | Storm | `BUSINESSBUILDINGSLIMIT` | always included |
| 10 | `BBLND_SD` | `LND_SD` | Landslide *(NZ only)* | `LANDSLIDELIMIT` | NZ + limit ≠ 0 |

**Total: 10 sub-coverages**

---

### 1.2 BC — Business Contents / Stocks (Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `Building_BC` |
| PRD staging table | `AGGNE.PRD.LOCATION_BC_COVERAGE_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.LOCATION_BC_COVERAGE_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_RISK_BUILDING_BC_COVERAGES` |

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `BCSTD_SD` | `STD_SD` | Contents & Stocks (Standard) | `CONTENTSLIMIT` | always included |
| 2 | `BCFLD_SD` | `FLD_SD` | Flood | `BCFLOODPROTECTION`, `FLOODDAMAGE` | BCFLOODPROTECTION ≠ 0 |
| 3 | `BCPER_SD` | `PER_SD` | Handtools (Personal Effects) | `PERSONALEFFECTSLIMIT` | limit ≠ 0 |
| 4 | `BCMFL_SD` | `MFL_SD` | Motor Fuels | `MOTORFUELSLIMIT` | limit ≠ 0 |
| 5 | `BCEMP_SD` | `EMP_SD` | Employees Effects | `EMPLOYEETOOLSOFTRADELIMIT` | limit ≠ 0 |
| 6 | `BCVIS_SD` | `VIS_SD` | Vehicles in Stock | `VEHICLESINSTOCKLIMIT` | limit ≠ 0 |
| 7 | `BCCUV_SD` | `CUV_SD` | Customer Vehicles | `CUSTOMERSVEHICLESLIMIT` | limit ≠ 0 |
| 8 | `BCWIS_SD` | `WIS_SD` | Watercraft in Stock | `WATERCRAFTINSTOCKUNDER8MLIMIT` | limit ≠ 0 |
| 9 | `BCCUW_SD` | `CUW_SD` | Customers Watercraft | `CUSTOMERSWATERCRAFTUNDER8MLIMIT` | limit ≠ 0 |
| 10 | `BCACC_SD` | `ACC_SD` | Accidental Damage | `ACCIDENTALLOSSORDAMAGELIMIT` | limit ≠ 0 |
| 11 | `BCHAL_SD` | `HAL_SD` | Hail Standard | `HAILDAMAGE` | limit ≠ 0 |
| 12 | `BCLND_SD` | `LND_SD` | Landslide *(NZ only)* | `LANDSLIDELIMIT` | NZ + limit ≠ 0 |
| 13 | `BCSWP_SD` | `SWP_SD` | Stock & Works in Progress | `STOCKLIMITEXVEHICLESWATERCRAFT` | limit ≠ 0 |

**Total: 13 sub-coverages**

---

### 1.3 BI — Business Interruption (Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `Building_BI` |
| PRD staging table | `AGGNE.PRD.LOCATION_BI_COVERAGE_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.LOCATION_BI_COVERAGE_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_RISK_BUILDING_BI_COVERAGES` |

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `BICLP_SD` | `CLP_SD` | Claim Preparation | `BICLAIMSPREPCOST` | limit ≠ 0 |
| 2 | `BIACR_SD` | `ACR_SD` | Accounts Receivable | `BIRECEIVABLES` | limit ≠ 0 |
| 3 | `BIICW_SD` | `ICW_SD` | Additional Increased Cost of Working | `BICOSTOFWORKING` | limit ≠ 0 |

**Total: 3 sub-coverages**

---

### 1.4 BG — Business Glass / Goods (Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `Building_BG` |
| PRD staging table | `AGGNE.PRD.LOCATION_BG_COVERAGE_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.LOCATION_BG_COVERAGE_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_RISK_BUILDING_BG_COVERAGES` |

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `BGALC_SD` | `ALC_SD` | Alcohol | `ALCOHOLLIMIT` | limit ≠ 0 |
| 2 | `BGCUV_SD` | `CUV_SD` | Customer Vehicles / Watercraft | `CUSTOMERVEHICLESWATERCRAFTLIMIT` | limit ≠ 0 |
| 3 | `BGMFL_SD` | `MFL_SD` | Motor Fuels | `MOTORFUELSLIMIT` | limit ≠ 0 |
| 4 | `BGPER_SD` | `PER_SD` | Personal Effects | `PERSONALEFFECTSLIMIT` | limit ≠ 0 |
| 5 | `BGMVH_SD` | `MVH_SD` | Stock Vehicles / Watercraft | `STOCKVEHICLESWATERCRAFTLIMIT` | limit ≠ 0 |
| 6 | `BGTOB_SD` | `TOB_SD` | Tobacco | `TOBACCOLIMIT` | limit ≠ 0 |
| 7 | `BGEMP_SD` | `EMP_SD` | Employee Handtools | `CONTENTSSTOCKEMPLOYEETOOLSLIMIT` | limit ≠ 0 |
| 8 | `BGETH_SD` | `ETH_SD` | Employee Theft | `EMPLOYEETHEFTLIMIT` | limit ≠ 0 |

**Total: 8 sub-coverages**

---

### 1.5 EN — Equipment / Engineering Breakdown (Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `Building_EN` |
| PRD staging table | `AGGNE.PRD.LOCATION_EN_COVERAGE_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.LOCATION_EN_COVERAGE_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_RISK_BUILDING_EN_COVERAGES` |

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `ENCWS_SD` | `CWS_SD` | Car Wash | `ENCARWASHVALUE` | value ≠ 0 |
| 2 | `ENDET_SD` | `DET_SD` | Deterioration of Stock | `ENSTOCKDETERIORATION` | value ≠ 0 |
| 3 | `ENICW_SD` | `ICW_SD` | Increased Cost of Working | `ENINCREASECOST` | value ≠ 0 |
| 4 | `ENLOI_SD` | `LOI_SD` | Loss of Information | `ENLOSSINFO` | value ≠ 0 |
| 5 | `ENMAC_SD` | `MAC_SD` | Machinery | `ENMACHINERYECEVALUE` | value ≠ 0 |

**Total: 5 sub-coverages**

---

### 1.6 MY — Money (Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `Building_MY` |
| PRD staging table | `AGGNE.PRD.LOCATION_MONEY_COVERAGE_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.LOCATION_MONEY_COVERAGE_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_RISK_BUILDING_MONEY_COVERAGES` |

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `MYMSO_SD` | `MSO_SD` | Money at Situation outside Business Hours | `MYOUTSIDEBUSHOURS` | value ≠ 0 |
| 2 | `MYMSS_SD` | `MSS_SD` | Money in secure locked safe or strongroom | `MYLOCKEDSAFE` | value ≠ 0 |
| 3 | `MYMPC_SD` | `MPC_SD` | Money in personal custody / private residence outside Business Hours | `MYOUTSIDEBUSHOURSPRIVATE` | value ≠ 0 |
| 4 | `MYMIT_SD` | `MIT_SD` | Money in Transit | `MYINTRANSIT` | value ≠ 0 |
| 5 | `MYEMP_SD` | `EMP_SD` | Employee Dishonesty | `EMPLOYEEDISHONESTYLIMIT` | value ≠ 0 |
| 6 | `MYMSB_SD` | `MSB_SD` | Money at Situation during Business Hours | `MYDURINGBUSHOURS` | value ≠ 0 |

**Total: 6 sub-coverages**

---

### 1.7 BP Line-Level Coverages

These coverages apply across the whole policy (not per location/building).

| Line | Full Name | Identifier view | Payload view |
|---|---|---|---|
| CV | Commercial Vehicles | `LINE_CV_COVERAGE_POLICYATTACH_IDENTIFIER` | `PA_LINE_CV_PAYLOAD` |
| GP | General Property | `LINE_GP_COVERAGE_POLICYATTACH_IDENTIFIER` | `PA_LINE_GP_PAYLOAD` |
| GT | Goods in Transit | `LINE_GT_COVERAGE_POLICYATTACH_IDENTIFIER` | `PA_LINE_GT_PAYLOAD` |
| LE | Liability (Public Liability) | `LINE_PUBLICLIABILITY_COVERAGE_POLICYATTACH_IDENTIFIER` | `PA_LINE_LE_PAYLOAD` |
| PF | Professional Protection | `LINE_PROFESSIONALPROTECTION_POLICYATTACH_IDENTIFIER` | `PA_LINE_PF_PAYLOAD` |
| PPL | Public / Products Liability | `LINE_PUBLICLIABILITY_COVERAGE_POLICYATTACH_IDENTIFIER` | `PA_LINE_PPL_PAYLOAD` |
| SV | Special Values | `LINE_SV_COVERAGE_POLICYATTACH_IDENTIFIER` | `PA_LINE_SV_PAYLOAD` |
| TA | Business Travel / Accident | `LINE_TA_COVERAGE_POLICYATTACH_IDENTIFIER` | `PA_LINE_TA_PAYLOAD` |

Each line has a corresponding UW view (e.g. `PA_LINE_CV_UW`) and clause view (e.g. `PA_LINE_CV_CLAUSE`).

---

### BP Risk-Level Final Assembly

The `PA_RISK_BUILDING_FINAL` view assembles all 6 risk-block coverages per location into one XML row:

| XML Block | Source target table | Coverage type |
|---|---|---|
| `RISK_BUILDING` | `PA_RISK_BUILDING_TARGET` | BB — Business Buildings |
| `RISK_BI` | `PA_RISK_BUILDING_BI_TARGET` | BI — Business Interruption |
| `RISK_BG` | `PA_RISK_BUILDING_BG_TARGET` | BG — Business Glass/Goods |
| `RISK_Money` | `PA_RISK_BUILDING_MONEY_TARGET` | MY — Money |
| `RISK_EN` | `PA_RISK_BUILDING_EN_TARGET` | EN — Equipment Breakdown |
| `RISK_BC` | `PA_RISK_BUILDING_BC_TARGET` | BC — Business Contents |

---

## 2. PP — Personal Pack

PP policies are per-member and cover residential/personal risks.

### Key scope table
`AGGNE.PRD.POLICYATTACH_PER_IDENTIFIER` — controls which PP policies enter the attach run.

---

### 2.1 HB — Home Buildings (Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `Building` |
| PRD staging table | `AGGNE.PRD.HB_02_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.HB_02_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_PER_BB_SUBCOVERAGES` |
| Payload view | `AGGNE.PRD.PA_PER_HOME_BUILDING_PAYLOAD` |
| Key value field | `HOMEBUILDINGSLIMIT` |

The identifier view joins `AGGNE.PRD.POLICYATTACH_PER_V1` (scope) with `AGGNE.PRD.HB_02_POLICYATTACH` (coverage data).

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `HBBFL_SD` | `BFL_SD` | Buildings Flood | `HOMEBUILDINGSLIMIT`, `FLOODDAMAGE` | FLOODDAMAGE = 'Taken' |
| 2 | `HBBLD_SD` | `BLD_SD` | Standard | `HOMEBUILDINGSLIMIT` | limit ≠ 0 |
| 3 | `HBBAD_SD` | `BAD_SD` | Accidental Damage | `ACCIDENTALLOSSORDAMAGELIMIT`, `ACCIDENTALLOSSORDAMAGE` | = 'Taken' |
| 4 | `HBBLD_BF` | `BLD_BF` | Bushfire | `HOMEBUILDINGSLIMIT` | limit ≠ 0 |
| 5 | `HBBLD_CY` | `BLD_CY` | Cyclone | `HOMEBUILDINGSLIMIT` | limit ≠ 0 |
| 6 | `HBBLD_EQ` | `BLD_EQ` | Earthquake | `HOMEBUILDINGSLIMIT` | limit ≠ 0 |
| 7 | `HBBLD_ST` | `BLD_ST` | Storm | `HOMEBUILDINGSLIMIT` | limit ≠ 0 |
| 8 | `HBBLI_SD` | `BLI_SD` | Building Liability | `HOMEBUILDINGSLIMIT` | limit ≠ 0 |
| 9 | `HBLLB_SD` | `LLB_SD` | Landlord Protection | `LANDLORDPROTECTIONS` | = 'Taken' |
| 10 | `HBBLN_SD` | `BLN_SD` | Landslide *(NZ only)* | `LANDSLIDELIMIT` | NZ + limit ≠ 0 |

**Total: 10 sub-coverages**

---

### 2.2 HC — Home Contents (Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `ContentsAndStocks` (in payload; `Building` in sub-coverage type) |
| PRD staging table | `AGGNE.PRD.HC_02_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.HC_02_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_PER_HC_SUBCOVERAGES` |
| Payload view | `AGGNE.PRD.PA_PER_HOME_CONTENTS_PAYLOAD` |
| Key value field | `HOMECONTENTSLIMIT_NEW` |

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `HCCNT_SD` | `CNT_SD` | Standard | `HOMECONTENTSLIMIT_NEW` | limit ≠ 0 |
| 2 | `HCCAD_SD` | `CAD_SD` | Accidental Damage | `ACCIDENTALLOSSORDAMAGELIMIT`, `ACCIDENTALLOSSORDAMAGE` | = 'Taken' |
| 3 | `HCSPE_SD` | `SPE_SD` | Specified Items | `HCOTHITEMSTOTAL` | SPECIFIEDITEMSAWAY = 'Taken' |
| 4 | `HCCNT_BF` | `CNT_BF` | Bushfire | `HOMECONTENTSLIMIT_NEW` | limit ≠ 0 |
| 5 | `HCCNT_CY` | `CNT_CY` | Cyclone | `HOMECONTENTSLIMIT_NEW` | limit ≠ 0 |
| 6 | `HCCNT_EQ` | `CNT_EQ` | Earthquake | `HOMECONTENTSLIMIT_NEW` | limit ≠ 0 |
| 7 | `HCCNT_ST` | `CNT_ST` | Storm | `HOMECONTENTSLIMIT_NEW` | limit ≠ 0 |
| 8 | `HCPOR_SD` | `POR_SD` | Portable Items (away from home) | *(no iValue)* | always included when present |
| 9 | `HCCFL_SD` | `CFL_SD` | Flood | `HCHOMEHOBBYFARMFLOODPROTECTION`, `FLOODDAMAGE` | = 'Taken' |
| 10 | `HCCLI_SD` | `CLI_SD` | Contents Liability | `HOMECONTENTSLIMIT_NEW` | limit ≠ 0 |
| 11 | `HCCLN_SD` | `CLN_SD` | Landslide *(NZ only)* | `LANDSLIDELIMIT` | NZ + limit ≠ 0 |

**Total: 11 sub-coverages**

---

### 2.3 PM — Private Motor / Personal Motor (per vehicle, Risk Level)

| Field | Value |
|---|---|
| Coverage Type | `CommercialVehicle` *(DCT type name for personal motor in this system)* |
| PRD staging table | `AGGNE.PRD.PM_03_POLICYATTACH` |
| Identifier view | `AGGNE.PRD.PM_03_POLICYATTACH_IDENTIFIER` |
| Sub-coverage view | `AGGNE.PRD.PA_PER_COM_COVERAGES` |
| Payload view | `AGGNE.PRD.PA_PER_COM_PAYLOAD` |
| Key field | Composite: `trim(ID) \|\| '\|' \|\| TRIM(VEHICLEID)` |

One row per vehicle. `VEHICLEID` distinguishes multiple vehicles on the same policy.

| # | Code | Type | Description | PURE field | Condition |
|---|---|---|---|---|---|
| 1 | `PMCMP_SD` | `CMP_SD` | Comprehensive — Market Value | `MARKETVALUEWITHACCESSORIESAMOUNT` | PROTECTIONTYPE = 'Comprehensive - Market Value' |
| 2 | `PMCMP_SD` | `CMP_SD` | Comprehensive — Agreed Value | `AGREEDVALUEDESCRIPTIONVALUE + AVVALUEWITHOUTACCESSORIES` | PROTECTIONTYPE = 'Comprehensive - Agreed Value' |
| 3 | `PMCOR_SD` | `COR_SD` | Choice of Repair | *(no iValue)* | CHOICEOFREPAIR = 'Taken' |
| 4 | `PMFTL_SD` | `FTL_SD` | Fire & Theft excl. Liability | `MARKETVALUEWITHACCESSORIESAMOUNT` | PROTECTIONTYPE = 'Fire and Theft' |
| 5 | `PMLIA_SD` | `LIA_SD` | Comprehensive Liability | `MARKETVALUEWITHACCESSORIESAMOUNT` | Comprehensive (Market or Agreed Value) |
| 6 | `PMPCH_SD` | `PCH_SD` | Car Hire after Incident | *(no iValue)* | HIRECARHIREAFTERINCIDENT = 'Taken' |
| 7 | `PMTFT_SD` | `TFT_SD` | Third Party Fire & Theft | `MARKETVALUEWITHACCESSORIESAMOUNT` | PROTECTIONTYPE = 'Third Party, Fire and Theft' |
| 8 | `PMTPO_SD` | `TPO_SD` | Third Party Only | `MARKETVALUEWITHACCESSORIESAMOUNT` | PROTECTIONTYPE = 'Third Party Only' |
| 9 | `PMULG_SD` | `ULG_SD` | Unlimited Glass | *(no iValue)* | EXCESSWAIVERFORGLASS = 'Yes' |

**Total: 9 sub-coverage variants (8 distinct codes — PMCMP_SD appears twice for two protection types)**

---

### PP Risk-Level Final Assembly

The `PA_PER_RISK_BUILDING_FINAL` view assembles HB and HC coverages into one XML row per location:

| XML Block | Source target table | Coverage |
|---|---|---|
| `RISK_BUILDING` | `PA_PER_BUILDING_TARGET` | HB — Home Buildings |
| `RISK_BC` | `PA_PER_HC_TARGET` | HC — Home Contents |

If either target table has no data for a policy, the view emits a fallback `<Indicator>0</Indicator>` stub so the XML structure is preserved.

---

### PP Supporting Views

| View | Description |
|---|---|
| `PA_PER_ACCOUNT_LOC` | Location / address per policy (AU/NZ logic) |
| `PA_PER_VW_CLAIM_HISTORY` | Claims history from `CLAIMHISTORY_POLICYATTACH_IDENTIFIER` |
| `PA_PER_VW_CBP_COMPETITOR_INFORMATION` | Prior insurer details |
| `PA_PER_VW_CBP_DUTY_DISCLOSURE` | Duty of disclosure answers |
| `PA_PER_VW_CM` | Personal motor (CM) payload |
| `PER_HC_CLAUSE` | HC clause text (filter `_IS_CURRENT='TRUE'`) |
| `PA_PER_COM_CLAUSE` | PM vehicle clause text (composite key: `ID\|VEHICLEID`) |
| `PER_HB_BUILDING_UW` | HB underwriting adjustments |
| `PA_PER_HC_BUILDING_UW` | HC underwriting adjustments |
| `PA_PER_PM_BUILDING_UW` | PM per-vehicle underwriting adjustments |
| `PA_PER_HC_SPECIFIEDCONTENTS` | HC specified contents items |
| `PA_PER_HC_ITEMS_EXCEED_VALUE` | HC items exceeding value threshold |
| `PA_PER_VW_SAMPLE_FINAL` | Final PP policy scope view |

---

## 3. PURE → PRD Data Flow Summary

```
PURE (DEV_T5_EXTERNAL_AGGNE.PURE.*)
        ↓
SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD   (AGGNE.PRD)
        ↓
PRD staging tables  (AGGNE.PRD.*_POLICYATTACH)
        ↓
_IDENTIFIER views   (AGGNE.PRD.*_POLICYATTACH_IDENTIFIER)
        ↓
DYNAMIC_XML_V1      (AGGNE.PRD.DYNAMIC_XML_V1 — per config row)
        ↓
_TARGET tables      (AGGNE.PRD.PA_*_TARGET)
        ↓
Final assembly views (PA_RISK_BUILDING_FINAL / PA_PER_RISK_BUILDING_FINAL)
        ↓
AGGNE.PRD_XML.POLICYATTACH_MIGRATION_DCT          (BP)
AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT   (PP)
        ↓
DCT API (LegacyPolicyNumber + DOL)
```

---

## 4. Coverage Count Summary

| LOB | Coverage | Level | Sub-coverages |
|---|---|---|---|
| BP | BB — Business Buildings | Risk / Location | 10 |
| BP | BC — Business Contents | Risk / Location | 13 |
| BP | BI — Business Interruption | Risk / Location | 3 |
| BP | BG — Business Glass / Goods | Risk / Location | 8 |
| BP | EN — Equipment Breakdown | Risk / Location | 5 |
| BP | MY — Money | Risk / Location | 6 |
| BP | CV — Commercial Vehicles | Line (policy) | varies |
| BP | GP — General Property | Line (policy) | varies |
| BP | GT — Goods in Transit | Line (policy) | varies |
| BP | LE — Public Liability | Line (policy) | varies |
| BP | PF — Professional Protection | Line (policy) | varies |
| BP | PPL — Public/Products Liability | Line (policy) | varies |
| BP | SV — Special Values | Line (policy) | varies |
| BP | TA — Business Travel / Accident | Line (policy) | varies |
| PP | HB — Home Buildings | Risk / Location | 10 |
| PP | HC — Home Contents | Risk / Location | 11 |
| PP | PM — Private Motor | Per vehicle | 9 |

**BP risk-level sub-coverages total: 45**
**PP sub-coverages total: 30**
