Subject: PP Conversion — 18 open questions (need Aggne policy team / client input)

Hi team,

While validating the PP (Personal Protection) policy conversion field mappings against the DCT manuscript, we found 18 issues — spanning the Pure-to-Write stored procedure, the conversion views, and the DCT payload templates — that are ready to fix on our side except for one business decision each. Rather than guess, we've held these for your input. Each item below has the field, what DCT expects, what's currently being sent, the actual data counts from a read-only query against our dev environment, and the specific question we need answered.

This is grouped into four parts by where the fix will land:
- **Part A** — the Pure-to-Write stored procedure (7 items)
- **Part B** — the conversion views (2 items)
- **Part C** — the DCT payload templates/config (7 items)
- **Part D** — new items found while cross-referencing your recently reported defect tickets against our field-by-field review (2 items)

---

# Part A — Pure-to-Write stored procedure

## 1. BodyType — 'Other' and 'Cab Chassis' mapping

**Field:** BodyType (`risk/BodyType`) — Dropdown, required
**DCT accepts:** `Bus, Convertible, Coupe, Hatchback, PrimeMover, Sedan, Utility, Van, Wagon, TowTruck, Transporter, MobilePlant, Motorcycle, Trailer, CamperVan, Caravan, Forklift` (17 codes)
**Currently sent:** blank, or the raw source text `Other` / `Cab Chassis` — none of which are valid DCT codes.

**Data (4,362 vehicles):**
| Value | Count |
|---|---|
| (blank) | 3,600 |
| Other | 661 |
| Cab Chassis | 10 |

```sql
-- classification query — see docs/pp_mapping/vq/seq18_vq.sql (G-03 block)
SELECT BODYTYPE, COUNT(*) FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
```

**Question:** Has this same BodyType mapping already been solved on the BP (Business Protection) side? If so, we'd like to reuse that precedent rather than invent a new one. If not, what should `Other` and `Cab Chassis` map to?

---

## 2. NumberOfCylinders — cylinder-less vehicles

**Field:** NumberOfCylinders (`risk/NumberOfCylinders`) — Dropdown, required, integers 1–16 only (no 0 or blank option)
**Currently sent:** `0` for 512 vehicles that Pure/RedBook flags as genuinely having no cylinders (trailers, EVs, etc. — RedBook code 11 = "none"). `0` is not a valid dropdown value.

```sql
SELECT NUMBEROFCYLINDERS, COUNT(*),
       CASE WHEN NUMBEROFCYLINDERS BETWEEN 1 AND 16 THEN 'VALID' ELSE 'STILL INVALID' END
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
```

**Question:** For cylinder-less vehicle types, should the `NumberOfCylinders` tag be omitted entirely, or is there a specific value DCT expects instead of `0`?

---

## 3. VoluntaryExcess — re-banding above $1,000

**Field:** VoluntaryExcess (`risk/VoluntaryExcess`) — Dropdown
**DCT accepts:** `0, 250, 500, 750, 1000, 1250, 1500` (7 PP options)
**Currently sent:** `2000` or `5000` for excess amounts above $1,000 — both outside the valid option list (this banding looks copied from the BP/Business excess rules, which do allow higher bands).

**Data:** 9 vehicles currently affected. Structurally, the banding logic also never produces `250`, `750`, or `1250` at all — those three PP options are unreachable today regardless of the 2000/5000 issue.

```sql
SELECT VOLUNTARYEXCESS, COUNT(*),
       CASE WHEN VOLUNTARYEXCESS IN (0,250,500,750,1000,1250,1500) THEN 'VALID' ELSE 'STILL INVALID' END
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
```

**Question:** What should a raw excess amount above $1,000 map to — cap at $1,500 (nearest valid option), re-band more granularly across all 7 options, or a different pricing-driven rule? This is a customer-facing dollar amount, so we don't want to guess.

---

## 4. AgeOfYoungestRegularDriver — minimum age threshold conflict

**Field:** AgeOfYoungestRegularDriver (`risk/AgeOfYoungestRegularDriver`) — numeric, required
**Conflict:** the current code nulls out any age under 16, on the understanding (documented earlier in this project) that 16 matches DCT's minimum age rule. Re-checking the DCT manuscript directly, the actual minimum is defined as **17**, not 16.

**Data (3,306 vehicles):** 218 blank (6.6%); 2 vehicles currently carry age `16`, which passes today's `<16` check but would fail DCT's real minimum of 17.

```sql
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN COALESCE(TRIM(AGEOFYOUNGESTREGULARDRIVER),'')='' THEN 1 ELSE 0 END) AS AGE_BLANK
FROM AGGNE.DEV.PER_COM_PAYLOAD;
```

**Question:** Was 16 a deliberate choice for a reason outside the DCT manuscript (e.g. a local learner-driver age rule), or should the threshold be corrected to 17 to match DCT? We want to confirm before changing a rule that was previously documented as intentional.

---

## 5. UW Adjustments — non-recurring adjustments excluded entirely

**Field:** UnderwritingAdjustment (Home Contents / Motor UW adjustment blocks)
**Finding:** the procedure that builds these blocks only ever selects adjustments flagged recurring in Pure (`AJRecurringIndicator = 1`). Non-recurring adjustments are filtered out upstream and never reach DCT at all — not sent with a "No" recurring flag, simply absent.

**Data:**
| Source | Recurring (included) | Non-recurring (excluded) | % excluded |
|---|---|---|---|
| Motor adjustments | 7,686 | 11,450 | 59.9% |
| Home Contents/Buildings adjustments | 4,779 | 8,365 | 63.6% |

```sql
SELECT AJRecurringIndicator, COUNT(*) FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSMV GROUP BY 1;
SELECT AJRecurringIndicator, COUNT(*) FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSHC GROUP BY 1;
```

**Question:** Is excluding non-recurring UW adjustments from conversion intentional (e.g. one-time historical adjustments genuinely shouldn't carry forward onto a freshly-converted policy), or should they be included? Given this affects roughly 60% of all adjustment records, we wanted to confirm rather than assume either way.

---

## 6. Premium double-carry on combined Home Buildings + Home Contents policies — split logic found, confirmation requested (updated 2026-07-17)

**Field:** `coverage/Premium` on both the Home Buildings and Home Contents coverage blocks
**Finding:** on every policy that has both Buildings and Contents cover, both coverage blocks currently carry the exact same total home premium figure, rather than a split between the two. 1,109 of 1,843 combined policies (60.2%) are affected.

**Update — we found the split logic and can implement it.** The SAS Expiring Premium script (`ExpiringPremiumClaimHistory_V3`) derives per-sub-coverage premiums from the Pure rating sections (`Rating_Section.annual_premium` per class-of-business code, with the Buildings/Contents section amounts apportioned across perils by base-contribution ratios, Liability = min($250, 20% of base)). The coverage-level Buildings premium is then the **sum of the `HB*` sub-coverage premiums**, and Contents is the sum of the `HC*` rows. That data is already landed in our staging (`Output_SubCover_PER`) and reconciles: e.g. P00036644 splits to HB $1,578.84 + HC $172.79 against the $1,751 combined figure currently sent on both blocks.

```sql
SELECT TRIM(POLICYNUMBER) AS POLICY,
       SUM(IFF(SUB_COVERAGE LIKE 'HB%', EXPPREMIUM, 0)) AS HB_PREMIUM,
       SUM(IFF(SUB_COVERAGE LIKE 'HC%', EXPPREMIUM, 0)) AS HC_PREMIUM
FROM AGGNE.DEV.Output_SubCover_PER GROUP BY 1;
```

**Question (confirmation only):** we intend to change the two coverage-level `Premium` values to these prefix-sums instead of the combined total. Please confirm (a) that is the intended figure for `coverage/Premium`, and (b) the fallback for the small number of policies with no rating-section rows in the extract — keep the combined total on the primary coverage, or leave blank?

---

## 7. Motor clause codes — remap needed (re-corrected 2026-07-17: PP has its own valid option list)

**Field:** `Clauses[Type="Motor"]/Clause/Type` (Select Clause dropdown)
**Correction (final):** two earlier versions of this question were wrong in opposite directions. The Personal package manuscript (`Carrier_PersonalProtectionBase_1_0_0_0.xml`) **overrides** `CommercialVehicleClausesInput.ClausesSelection` with its own option list, and in that override every `CM_Cxx` numbered code, every `CM`-caption code, and every `FV*` code is marked `validRef="False"` (hidden). For Personal Protection, the only genuinely selectable Motor clause options are these **10 PM-caption codes**:

| Manuscript value (goes in XML) | Dropdown caption |
|---|---|
| `PMAVCaravancontents` | PM AV Caravan contents |
| `PMMVCaravancontents` | PM MV Caravan contents |
| `PMLearnerextension` | PM Learner extension |
| `PMAdditionalbenefit4increase` | PM Additional benefit 4 increase |
| `PMAdditionalbenefit7increase` | PM Additional benefit 7 increase |
| `PMAdditionalbenefit11increase` | PM Additional benefit 11 increase |
| `PMAdditionalbenefit12increase` | PM Additional benefit 12 increase |
| `PMGeneralexclusionproperty` | PM General exclusion property |
| `PMGeneralexclusionliability` | PM General exclusion liability |
| `PMGeneralextension` | PM General extension |

(The `CM`-caption list quoted in the previous version of this item is the Commercial/BP-side option set — not selectable on PP policies.)

**Source 2 — `SCHEDULE_CLAUSES_TEMPLATE.DCCLAUSETYPE`** (33 PP rows): all 4 distinct PP values match a manuscript caption exactly — `PM AV Caravan contents` → `PMAVCaravancontents`, `PM MV Caravan contents` → `PMMVCaravancontents`, `PM Learner extension` → `PMLearnerextension`, `PM Additional benefit 4 increase` → `PMAdditionalbenefit4increase`. **We consider these four safe to map** (exact caption match, only spaces removed) and plan to proceed unless you object.

**Source 1 — `PER_CLAUSEAMENDMENTMV.CAText`** (majority of volume) — remapped against the PM option list:

| Source code | Rows | Proposed mapping |
|---|---|---|
| PM_C05_NOAR | 410 | *no PM equivalent found* (NOAR — "no age restriction"? The Commercial "Hire Under 21" option is hidden for PP) |
| CM_C03_NOAR | 292 | same as above |
| PM_C03_LEARNER | 193 | `PMLearnerextension` — confident |
| CM_C01_LEARNER | 139 | same as above |
| PM_C01_CRVNCNTAV | 134 | `PMAVCaravancontents` — confident (AV = Agreed Value) |
| CM_C04_EFF_DATE | 122 | *no match* — no effective-date clause option |
| PM_C04_YNGDRIVER | 110 | *no match* — no Young Driver option |
| PM_C06_EFF_DATE | 85 | *no match* |
| PM_C02_CRVNCNTMV | 36 | `PMMVCaravancontents` — confident (MV = Market Value) |
| CM_C02_YNGDRIVER | 30 | *no match* |
| PM_C07_MODSACCS | 28 | *no match* — no modifications/accessories option |
| CM_C06_MODSACCS | 25 | same |
| PM_C09_RISKEXC | 15 | `PMGeneralexclusionproperty` or `PMGeneralexclusionliability`? ambiguous which |
| CM_C08_RISKEXT | 9 | `PMGeneralextension`? unconfirmed |
| CM_C10_FTLIAB | 7 | *no match* — the F&T Liability option (`CMF&TOnlyLiabilityExtension`) is hidden for PP |
| PM_C08_RISKEXT | 4 | `PMGeneralextension`? unconfirmed |
| PM_C10_ADDBENEXT | 3 | `PMAdditionalbenefit{4/7/11/12}increase` — can't tell which number |
| QFES EXTENSION | 1 (in-scope) | *no match* — free-text value found in live in-scope data 2026-07-17 (Queensland Fire & Emergency Services?); not part of either code scheme |

**Question:** (a) Confirm the three confident mappings (LEARNER, CRVNCNTAV, CRVNCNTMV) and the four exact Source-2 caption matches. (b) Disambiguate RISKEXC (property vs liability exclusion), RISKEXT, and ADDBENEXT (which benefit number). (c) For the codes with no PP equivalent (NOAR, YNGDRIVER, EFF_DATE, MODSACCS, FTLIAB — ~1,100 rows combined), how should they convert: drop the clause, carry the text into a free-text/description field, or is there another clause object we should be targeting? Given this determines what legal clause text attaches to a live policy, we want confirmation before mapping anything beyond the exact matches.

---

# Part B — Conversion views

## 8. Home Buildings — Landlords Protections indicator — RESOLVED, no input needed (2026-07-17)

**Withdrawn.** Pure does carry the explicit flag: the SAS conversion script (`HomeBuilding` program) derives LandlordProtections from `PER_HOMECONTENTS.HCHBLandlord` (`1 → Taken`, else Not Taken, forced Not Taken when `HCProtection = 3`), and our staging table already lands it as `HB_02.LANDLORDPROTECTIONS` (211 Taken / 2,843 Not Taken). The LLB_SD Indicator and sValue now derive from that column — fix verified live in DEV. Kept here only so the item numbering in earlier correspondence still lines up.

---

## 9. Home Buildings UW Adjustments — in scope or not?

**Field:** the entire `UnderwritingAdjustment` block for Home Buildings
**Finding:** the view that builds this currently reads two Business Protection (commercial) staging tables instead of the Personal-line equivalent, so it produces no usable rows for PP policies. Separately, the payload template has no token for this block at all, so even a correctly-sourced adjustment would never reach the final XML today.

**Question:** Is Home Buildings UW adjustment in scope for PP conversion at all?
- **If yes** — we'll repoint the view to the correct Personal-line source table (the same one already working correctly for Home Contents and Motor UW adjustments) and add the missing template token.
- **If no** — we'll retire this part of the conversion rather than keep producing rows nobody uses.

---

# Part C — DCT payload templates / config

## 10. State — what should NZ risks show?

**Field:** `risk/State`
**Currently sent:** hardcoded `"NSW"` for every vehicle, regardless of actual state.

**Data (4,377 vehicles):**
| State | Count |
|---|---|
| VIC | 1,342 |
| WA | 891 |
| NSW | 747 |
| NZ | 629 |
| QLD | 392 |
| SA | 290 |
| TAS | 63 |
| NT | 16 |
| ACT | 7 |

```sql
SELECT STATE, COUNT(*) AS VEHICLES FROM AGGNE.DEV.PM_03 GROUP BY STATE ORDER BY 2 DESC;
```

**Question:** DCT's own state logic only recognizes the 8 AU state/territory codes (ACT, NSW, QLD, VIC, NT, SA, TAS, WA) — there's no NZ case anywhere. What should `State` contain for the 629 NZ risks?

---

## 11. Home Buildings excess breakdown — confirm inapplicable

**Field:** Excess sub-tags (`Standard`, `Imposed`, `Earthquake`, `Flood`, `Glass`) at the Home Buildings coverage level
**Finding:** these five tags are currently empty. We checked whether real data exists anywhere upstream that's being dropped — it doesn't. No source column for a split Standard/Imposed/Earthquake/Flood excess exists in any of our staging tables, and the original source conversion logic for this line never computed these values either. The only excess concept that actually exists for Home Buildings is the single Voluntary Excess, which is already wired correctly.

**Question:** Can you confirm these five tags are genuinely inapplicable to PP Home Buildings (i.e. the PDS doesn't break excess into these components for this product)? If so, we'll leave them empty and close this out. If a real source for any of them does exist, let us know where.

---

## 12. GlassLimit — confirm intent

**Field:** `coverage/GlassLimit` (Home Buildings)
**Currently sent:** the full Home Buildings sum insured — the same number already correctly used for the building's own sum insured elsewhere in the payload. Affects all 3,054 Home Buildings rows (100%).

**Question:** `GlassLimit` reads like it should be a distinct, smaller glass-cover sub-limit. Should it be blank (no PP glass-limit concept exists), or does a genuine glass limit value exist in Pure that we should source instead of reusing the building sum insured?

---

## 13. Risk-level excess breakdown — confirm inapplicable

**Field:** `StandardExcess` / `ImposedExcess` at the outer risk level (Home Buildings risk node)
**Finding:** same situation as item 11, one level up — no source data exists anywhere for these two tags.

**Question:** Same as item 11 — please confirm these are inapplicable and we'll close both together.

---

## 14. SICCode — remove the commercial classification

**Field:** `risk/SICCode`
**Currently sent:** `"General Mechanical Workshop"` — a commercial/business occupancy classification — hardcoded on every single PP home risk (1,399 of 1,399, 100%).
**Note:** DCT's own template design defaults this field automatically from the account's underwriting group when it isn't explicitly supplied — sending our own fixed text overrides that default with an incorrect commercial classification on a personal policy.

**Question:** Are you comfortable with us removing the hardcoded value so DCT's own default takes over, or does PP conversion need to send a specific SIC code value of its own? If the latter, what value should it be?

---

## 15. Fabricated risk-assessment answers

**Field:** Six yes/no risk-assessment answers on every Home Buildings risk node (1,399 of 1,399, 100%): `ExternalDoors`, `SecurityAccessibleWindows`, `SecurityAlarm`, `LocationConnectedToTownWaterMain`, `StoreFlammableGoods`, `IsAusStandardFollowed`.
**Finding:** all six are currently hardcoded to a fixed answer (a mix of Yes/No) with no source data behind any of them — they're asserting specific factual claims about each property (e.g. "has a security alarm: No") identically for every policy.

**Question:** Does Pure capture any of these six answers anywhere we could source instead? If not, should these be left blank, or does DCT require a non-blank answer here that you'd like defaulted to a specific value regardless of the property's actual state?

---

## 16. Motor sub-coverage matrix — which coverages apply to which protection type

**Field:** `coverage/Indicator` across the 8 Motor sub-coverage blocks (Comprehensive Property, Choice of Repair, Fire & Theft, Comprehensive Liability, Car Hire, Third Party Fire & Theft, Third Party Only, Unlimited Glass)
**Finding:** all 8 blocks are currently sent with Indicator="on" for every vehicle regardless of the policy's actual protection type.

**Data:**
| ProtectionType | Unexpected block | Count |
|---|---|---|
| Third Party Only | Comprehensive Property | 230 |
| Third Party Only | Choice of Repair | 230 |
| Third Party Only | Car Hire | 230 |
| Third Party Only | Unlimited Glass | 230 |
| Comprehensive (Agreed Value) | Third Party Only | 900 |
| Comprehensive (Market) | Third Party Only | 1,801 |

```sql
SELECT P.PROTECTIONTYPE, C.CODE, COUNT(*) AS CNT
FROM AGGNE.DEV.PER_COM_COVERAGES C JOIN AGGNE.DEV.PER_COM_PAYLOAD P
  ON C.PUREPOLICYNUMBER = P.PUREPOLICYNUMBER
WHERE (P.PROTECTIONTYPE = 'ThirdPartyOnly' AND C.CODE IN ('PMCMP_SD','PMPCH_SD','PMULG_SD','PMCOR_SD'))
   OR (P.PROTECTIONTYPE LIKE 'Comprehensive%' AND C.CODE = 'PMTPO_SD')
GROUP BY 1, 2 ORDER BY 1, 2;
```

**Question:** What's the correct matrix of which of the 8 coverage codes should be "on" for which ProtectionType? Separately, should Car Hire / Choice of Repair / Unlimited Glass also depend on the existing Taken/NotTaken option fields already captured elsewhere on the policy, rather than ProtectionType alone?

---

# Part D — New items from client ticket cross-reference (2026-07-09)

Found while mapping your recently reported ATP-10219 defect tickets against our existing gap
register — see `docs/pp_mapping/CLIENT_TICKET_MAPPING.md` for the full cross-reference.

## 17. HC Specified Items Away From the Premises — itemized list never built (ATP-11107)

**Field:** `coverage/SpecifiedItemsPremises` (Taken/Not Taken flag) + the itemized item list behind it
**Finding:** the Taken/Not Taken flag itself is populated correctly (1,636 Not Taken / 195 Taken).
But PURE's source manuscript builds a separate itemized output for this section (`HC_AWAY`, sourced
from `PER_ITEMSAWAYFROMPREM` — item description + value per item) that was never carried into the
Snowflake pipeline. There's no view, target table, or template node anywhere that carries these
item-level details today.

```sql
SELECT SPECIFIEDITEMSAWAY, COUNT(*) AS CNT
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;
-- Not Taken: 1,636 | Taken: 195 — flag is fine, item detail behind the 195 "Taken" is 0% present
```

**Question:** What's the expected DCT node/shape for a repeating list of away-from-premises items
(description + value)? Once confirmed we can build the missing view.

## 18. "Legacy Start Date" — field identity unclear (ATP-10962)

**Field:** unclear which of our date columns "Legacy Start Date" refers to
**Finding:** `PER_FINAL` carries `INCEPTIONDATE`, `EFFECTIVEDATE`, `MEMBERSHIPSYSTEMDATE`,
`EXPIRATIONDATE` — none literally named "Legacy Start Date". In current data `MEMBERSHIPSYSTEMDATE`
always equals `INCEPTIONDATE`, and `INCEPTIONDATE <> EFFECTIVEDATE` on 4,019 of 4,076 rows (98.6%,
previously treated as expected renewal history, not re-examined against this specific ticket).

**Question:** Which exact field/path is "Legacy Start Date" — is it `MEMBERSHIPSYSTEMDATE`,
`INCEPTIONDATE`, or something we don't currently carry at all?

---

Happy to walk through any of these on a call if that's easier. Let us know which items need to go to the client vs. which the Aggne policy team can answer directly.

Thanks,
[Your name]
