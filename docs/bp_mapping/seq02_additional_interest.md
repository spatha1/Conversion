# SEQ 2 — BP_Policy_AOI (Additional Interest)

**Source view:** `AGGNE.DEV.AOI_FINAL` &nbsp;·&nbsp; **Target:** `AOI_Target`
**Upstream staging:** `AGGNE.DEV.ADDITIONAL_INTEREST`, joined to `AGGNE.DEV.LOCATION_01` (coverage
flags) and `AGGNE.DEV.BUSINESSDETAILS_FINAL` (line coverage flags)
**Original client SAS:** `SAS/txt/Additional interested conversionscriptCapricorn.txt`

**Client tickets:**

| Ticket | Summary | Notes |
|---|---|---|
| **ATP-10980** | "not showing all the interested parties, and some are showing incorrect values" (P00010027) | Root-caused to two separate bugs: G-BP-16a (dropped party) and G-BP-16c (wrong displayed value). Screenshot from the ticket confirms both. |
| **ATP-6221** | "3 Additional Interest Details should be displayed, however 1 is not displayed" | Same class as G-BP-16a. |
| **ATP-10586** | "186 policies mismatch on additional interested party to coverage sample... coverage is selected as yes however the coverage sample data does not have that coverage" | Unassigned/differently-assigned — not in either ATP-10219 export, found via broader search. Maps to G-BP-16b. |

---

## G-BP-16a — Parties with no Location/Line tie silently dropped (FIXED LIVE 2026-07-10, verified)

**Root cause.** `AOI_FINAL`'s final `WHERE LOC_VALUE IS NOT NULL OR LINE_VALUE IS NOT NULL` drops
any interested party that isn't tied to a specific Location or Line coverage — e.g. a
finance-only party like "Australia and New Zealand Banking Group Ltd : Finance".

**This is a confirmed missing block, not a guess.** The client's original SAS
(`Additional interested conversionscriptCapricorn.txt`) has an explicit third branch for exactly
this case:
```sas
/*Step 3: when no location or line coverage listed but interested party listed*/
CREATE TABLE NO_LOC_LINE AS
SELECT DISTINCT t1.PUREPolicyNumber, t1.ExpiringID_P, t1.CMLNumber, t1.ExpiryDate, t1.Country,
       t1.AdditionalIntDets
FROM AI_01 t1
WHERE t1.AdditionalInterestLoc = 'No' AND t1.AdditionalInterestLine = 'No';

/* Step 5: Combine both transposed datasets*/
DATA AI_MERGED;
SET AI_02 (IN=A) AI_03 (IN=B) NO_LOC_LINE;
```
The Snowflake port only implements the `AI_02`+`AI_03` equivalent (location-tied and line-tied
rows); the `NO_LOC_LINE` union branch was never added. Same shape as PP's PR-04 finding — check the
original SAS before guessing, and it turns out the fix is already fully specified.

**Screenshot confirmation (ATP-10980, policy Q0113129/P00010027):** DC UI shows only 2 of 3
interested parties. The missing one — "Australia and New Zealand Banking Group Ltd : Finance" — has
blank `AdditionalInterestLoc`/`Loc_value`/`AdditionalInterestLine`/`Line_value` in the raw data,
exactly the `NO_LOC_LINE` case.

**Data (live, 2026-07-10):**

| Metric | Count |
|---|---|
| Total `ADDITIONAL_INTEREST` rows (post date filter) | 5,647 |
| Rows surviving into `AOI_FINAL` | 4,897 |
| Rows dropped | 750 (13.3%) |
| Policies losing **all** their AOI records | 350 of 2,847 |
| Dropped rows with no coverage tie at all in source (this bug) | 267 |
| Dropped rows with real coverage text but a flag mismatch (see G-BP-16b) | 349 |

**Query:**
```sql
SELECT COUNT(*) AS TOTAL FROM AGGNE.DEV.ADDITIONAL_INTEREST WHERE EXPIRYDATE >= '2026-01-01';
SELECT COUNT(*) AS SURVIVORS FROM AGGNE.DEV.AOI_FINAL;
```

**Status:** **Fixed live, verified 2026-07-10.** `fixes/G-BP-16a_fix.sql` applied. Post-fix live
check: `AOI_FINAL` row count 4,897 → 5,167 (+270, close to the predicted +267 — minor drift
expected since the estimate was based on an approximate anti-join). P00010027 now returns all 3
interested parties:
```
('P00010027|CML00004747|2497011', 'Australia and New Zealand Banking Group Ltd : Finance', None, None, '0', '0')
('P00010027|CML00004747|2497011', 'GC Syndey Leasing Pty Ltd', 'BusinessContents', None, '1', '0')
('P00010027|CML00004747|2497011', 'National Retail Group 834 - 840 Wembley Rd Browns Plains PTY LTD', None, 'PublicandProductLiability', '0', '1')
```

---

## G-BP-16b — Coverage-flag mismatch drops parties with real coverage text (not yet resolved)

349 of the 750 dropped rows have real `LOC_VALUE`/`LINE_VALUE` text in Pure, but the corresponding
coverage-selected flag (e.g. `Location_01.BUSINESSBUILDINGS=1`) doesn't match, so the view's CASE
nulls it anyway. The client's SAS uses this same flag-gated pattern for its own AI_02/AI_03
branches, so the *mechanism* isn't a Snowflake-introduced bug — but whether the specific flag
values themselves are stale/wrong (a data-timing issue between `ADDITIONAL_INTEREST` and
`LOCATION_01`/`BUSINESSDETAILS_FINAL`) is unconfirmed. Likely maps to ATP-10586's 186-policy count,
though not yet matched 1:1 against specific policies.

**Status:** Open, not yet root-caused to a specific fix. Needs the 186 ATP-10586 policies pulled and
compared against their `Location_01`/`BusinessDetails_Final` flags directly — not yet done.

---

## G-BP-16c — LineProtectionSection value mismatch, 3 of 8 coverages (FIXED LIVE 2026-07-10, verified)

**Root cause.** `AOI_FINAL`'s `LINE_VALUE` CASE outputs strings that don't exactly match DC's
canonical enum for `AdditionalInterestSMEInput.LineProtectionSection`
(`Carrier_Package_Data_CW_1_0_0_0.xml`, options block, exactly 8 allowed values):

| Coverage | DC expects | We output | Match |
|---|---|---|---|
| Public and Products Liability | `PublicandProductLiability` | `PublicProductLiability` | ❌ |
| Stock Vehicles | `StockVehicle` | `StockVehicles` | ❌ |
| Customer Vehicles | `CustomerVehicle` | `CustomerVehicles` | ❌ |
| General Property | `GeneralProperty` | `GeneralProperty` | ✓ |
| Goods In Transit | `GoodsInTransit` | `GoodsInTransit` | ✓ |
| Professional Protection | `ProfessionalProtection` | `ProfessionalProtection` | ✓ |
| Legal Expenses | `LegalExpenses` | `LegalExpenses` | ✓ |
| Tax Audit | `TaxAudit` | `TaxAudit` | ✓ |

When the string doesn't match a known option, DC's UI can't resolve a caption and falls back to
"NA" — the data isn't missing, it's unrecognized. Confirmed visually: ATP-10980's screenshot shows
National Retail Group's Line Protection Section as "NA" despite `LINE_VALUE='PublicProductLiability'`
being correctly present in the underlying data.

**LocationProtectionSection side checked clean** — `AdditionalInterestSMEInput.LocationProtectionSection`'s
6 options (`BusinessBuilding`, `BusinessContents`, `Burglary`, `Money`, `Engineering`,
`BusinessInterruption`) all match `AOI_FINAL`'s `LOC_VALUE` output exactly. No fix needed there.

**Status:** **Fixed live, verified 2026-07-10.** `fixes/G-BP-16c_fix.sql` applied (as part of the
combined `G-BP-16a_fix.sql` view rewrite). Live distinct `LINE_VALUE` check now returns exactly the
8 canonical values: `CustomerVehicle`, `GeneralProperty`, `GoodsInTransit`, `LegalExpenses`,
`ProfessionalProtection`, `PublicandProductLiability`, `StockVehicle`, `TaxAudit` — no mismatched
strings remain. `LOC_VALUE`'s 6 values also re-checked post-fix, unchanged and still correct
(`Burglary`, `BusinessBuilding`, `BusinessContents`, `BusinessInterruption`, `Engineering`,
`Money`).
