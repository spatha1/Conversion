# PP Conversion — Client Questions with Source Data Queries

Compiled 2026-07-17. Each item below is a real open question where we need your (or the policy team's) input before we can finish the field correctly. Every query is runnable as-is against the Pure source data, and now carries a header comment with the SEQ number, the question, and the DCT manuscript citation (file:line) where one exists — so you can trace exactly which step of the conversion this affects and what DCT itself does or doesn't constrain.

(BodyType was a separate question — already sent, still awaiting the client's answer, not included here. A handful of other items turned out to be things we could safely default ourselves — the client only needs to weigh in on what's below.)

**Resolved since this doc was first compiled (removed from the list below):**
- **Number of Cylinders** — client confirmed: blank for cylinder-less vehicles, not "0".
- **Voluntary Excess above $1,000** — client confirmed: cap at $1,500. Checked live data — this is already exactly what's deployed (max value in production is 1500, verified 2026-07-17). No fix needed.
- **"Legacy Start Date" field identity** — decision made to keep existing code as-is for now; not asking the client on this one.
- **Age of Youngest Regular Driver — minimum age** — not actually a client decision: DCT's manuscript hardcodes the minimum unconditionally (`VehiclePrivate.MinAge = 17`, `Carrier_Package_Data_CW_1_0_0_0.xml:12343-12348`, referenced directly by `VehicleInput.AgeOfYoungestRegularDriver`'s validation rule).
- **Underwriting Adjustments — non-recurring ones dropped (Motor + Home Contents + Home Buildings)** — not a bug, confirmed intentional by the client's own original design. The original SAS source (`SAS/txt/ExpiringPremiumClaimHistory_V3_conversionscriptCapricorn.txt`, section *"Second, establish any reoccurring UW adjustments..."*) filters `PM_ADJUST`/`HC_ADJUST`/`HB_ADJUST`/`SU_ADJUST` to `AJRecurringIndicator = 1` — the exact same filter carried into the live SP (`SP_PP_ADJ_EXP_PREM`, PRD Policy-Attach copy `SP_PP_ADJ_EXP_PREM_POLICYATTACH.sql` lines ~635/652/668/685). Nothing to ask the client.
- **Home Buildings — Underwriting Adjustments in scope** — resolved, and the original premise was wrong: there was never meant to be a separate `PER_ADJUSTMENTSHB` table. SAS/PRD logic sources `HB_ADJUST` from the same `PER_ADJUSTMENTSHC` table Home Contents uses, filtered to `Coverage = 'HB'` via a join to the expiring-premium split. It's in scope by original design. **Internal follow-up (not a client question):** still need to confirm DEV's `SP_PP_ADJ_EXP_PREM` implements the same `HB_ADJUST` block as PRD's Policy-Attach copy — not yet verified live.
- **State — New Zealand risks** — not a client decision, and the original premise was wrong twice over. First: `VehicleInput.State` (`Carrier_Package_Data_CW_1_0_0_0.xml:11466`) has **no `<options>` list and no validation at all** — the "8 AU states only" claim mistakenly cited an unrelated rating/excess lookup table, not a field constraint. Second, and more importantly: **the "NSW hardcoded for every vehicle" claim itself was wrong** — that was true only of a stale, disconnected copy of the template sitting in the SQL Server `PP_ConversionConfig` table. The real live source of truth is the Snowflake `PP_CONVERSION_RUN` SP body, which already has `<State>{STATE}</State>` (not hardcoded). Checked the actual generated XML for real NZ policies (P00010046, P00032991, P00036201) — 16 of 17 `<State>` tags already correctly show `NZ`. **Already working in live DEV output, no fix needed.** (One unrelated minor oddity spotted in passing: one tag showed a town name, "TAIHAPE", instead of a state code — different field, not chased further.)

Number of Cylinders and Age of Youngest Regular Driver fixes are deployed: `BUGFIX_SP_PURE_TO_WRITE_CylindersAndAge_20260717.sql`.

---

## 1. Home Buildings + Home Contents — same premium sent to both

**In plain terms:** On policies with both Home Buildings and Home Contents, we currently send the exact same total premium figure to both coverage blocks — not split between the two.

**This is confirmed original design, not a conversion bug** — traced all the way back to the client's own original SAS conversion script and to a real limitation in how Pure itself stores Personal Lines premium. Evidence, in order:

1. **Table evidence (Pure source):** `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_SUMMARY` has only a single `SUHC*` column family for Home (`SUHCTOTALCONTRIB`, `SUHCBASECONTRIB`, `SUHCUWADJUST`, etc.) — **there is no `SUHB*` family at all.** Compare this to the Business side, where `CBP_SUMMARY` has fully separate `SUBB*` (Business Buildings) and `SUBC*` (Business Contents) columns. Pure itself never computed a Buildings-only total for Personal Lines — confirmed live 2026-07-17.
2. **SAS evidence (original design intent):** the client's own SAS script (`SAS/txt/ExpiringPremiumClaimHistory_V3_conversionscriptCapricorn.txt`, `Policy_Sample_PER_01`) computes `HMExpPrem` directly as `t20.SUHCTotalContrib LABEL='' AS HMExpPrem` — i.e. the SAS author used Pure's one combined Home total and explicitly labelled it "HM" (Home, not Home Buildings or Home Contents specifically). This was never split in the original design because Pure never gave it a split to work with.
3. **View evidence (live, current behavior):** queried `AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD` directly for every policy with both `HB_INDICATOR = '1'` and `HC_INDICATOR = '1'` — **2,408 of 2,408 rows (100%) have `HBEXPPREM` exactly equal to `EXPPREM`** (the HC-side premium column), zero exceptions. This is the live, current, reproducible proof of the symptom, not just a code-trace.
4. **Manuscript evidence (DCT does track this per-coverage, so the split matters if we build one):** DCT's shared manuscript object family `AllCoveragesSharePrivate.SetExpiringPremium` / `AllCoveragesContainerPrivate.SetExpiringPremium` (`Carrier_PersonalProtectionBase_1_0_0_0.xml:12797-12802`) confirms DCT has a real per-coverage-instance expiring-premium concept — it isn't just cosmetic display text, so if we do build a Building/Contents split, it will actually land as two distinct real values in DCT rather than being irrelevant.

Since Pure never natively split this, the only way to produce a real Buildings-only and Contents-only figure is to derive it from the **sub-peril rating detail**, which does split cleanly in most cases. At the top level, Pure rates everything Home-related under one section code, `HC` — there's no separate `HB` section — but one level deeper, the *sub-section* code clearly falls into two families:

| Sub-section | Rows | Side |
|---|---|---|
| BDNN, BANN, BFNN, BLNN | 43,960 / 21,298 / 10,277 / 3,589 | Building (`B`-prefix) |
| CNNN, CANN, CFNN, CLNN | 36,874 / 15,842 / 8,091 / 2,706 | Contents (`C`-prefix) |
| PONN, SPNN, HBNN, LLNN, HFNN | 16,196 / 7,213 / 1,142 / 943 / 919 | **Unclear — needs your confirmation** |

This matches a second, independent source we'd already flagged (`PER_SUEXPIRINGPREMIUM.SURSTYPECODE`, which shows the same B/C-prefix pattern: `HCBLD`/`HCBAD`/`HCBFL` vs `HCCNT`/`HCCAD`/`HCCFL`) — two separate Pure tables agreeing on the same split gives us confidence the B/C prefix itself is real. What we can't safely guess is the 5 ambiguous codes above (`PONN`, `SPNN`, `HBNN`, `LLNN`, `HFNN`) — whether each belongs to Building, Contents, or is a genuinely shared line (e.g. a shared policy excess).

```sql
/*
SEQ number: 7 and 13 (same as below) -- LIVE PROOF, ready to run on a call
Question: N/A -- this is the verification query, not a client question. Shows the current behavior
  concretely: every policy with both HB and HC confirmed shows an identical premium on both sides.
DCT Values : N/A
Result when run 2026-07-17: 2,408 total rows / 2,408 SAME_COUNT / 0 DIFFERENT_COUNT (100% identical)
*/

SELECT PUREPOLICYNUMBER, HB_INDICATOR, HC_INDICATOR, HBEXPPREM, EXPPREM,
       (HBEXPPREM = EXPPREM) AS SAME_VALUE
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
WHERE HB_INDICATOR = '1' AND HC_INDICATOR = '1'
LIMIT 15;
```

```sql
/*
SEQ number: 7 (RISK_Building_HB) and 13 (RISK_Building_HC) -- both source from
  AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD, which reads AGGNE.DEV.Output_Coverage_PER.HMEXPPREM (one
  combined column) for both blocks -- confirmed live 2026-07-17
Question: Pure rates all Home coverage under a single section code (HC) -- there's no separate HB
  section to filter on. The real split lives in the sub-section code prefix (B vs C, see table
  above). Can you confirm: (1) the B/C prefix split is correct for BDNN/BANN/BFNN/BLNN (Building)
  vs CNNN/CANN/CFNN/CLNN (Contents), and (2) which side PONN, SPNN, HBNN, LLNN, and HFNN belong to
  -- Building, Contents, or shared across both?
DCT Values : N/A -- DCT just receives whatever premium figure we populate per coverage block; the
  split has to come from Pure source data, not a DCT rule.
*/

-- Confirms: everything Home-related sits under Section_01 = 'HC' (no separate 'HB' section),
-- and shows the sub-section codes that need classifying into Building vs Contents vs shared.
SELECT
    SUBSTR(cob.code,3,2) AS SECTION_01,
    SUBSTR(cob.code,5,4) AS SUB_SECTION_01,
    COUNT(*) AS ROW_COUNT
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.rating_section rs
JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Rating_Section_Type rst ON rs.rating_section_type_id = rst.rating_section_type_id
JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Class_Of_Business cob ON rst.caption_id = cob.caption_id AND cob.is_deleted = 0
JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk r ON rs.risk_cnt = r.risk_cnt
JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link l ON r.risk_cnt = l.risk_cnt
JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file i ON l.insurance_file_cnt = i.insurance_file_cnt
WHERE rs.original_flag = 0
  AND SUBSTR(i.insurance_ref,1,1) = 'P'
  AND (SUBSTR(cob.code,3,2) IN ('HB','HC','HM') OR cob.code ILIKE '%HOME%')
GROUP BY 1, 2
ORDER BY 3 DESC;
```

```sql
/*
SEQ number: 7 and 13 (same as above)
Question: Cross-check against the second, independent source -- does SURSTYPECODE agree with the
  B/C split found in the rating-section codes above?
DCT Values : N/A -- same as above.
*/

SELECT SURSTYPECODE, COUNT(*) AS ROW_COUNT
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_SUEXPIRINGPREMIUM
GROUP BY 1
ORDER BY 2 DESC;
```

---

## 2. Motor Clause Codes — full mapping needed

**In plain terms:** When a policy has a special clause attached to a vehicle (e.g. "cover extended to drivers under 21"), we need to tell DCT which specific clause it is by sending a code.

**Correction to our earlier framing (2026-07-17):** we'd previously said none of DCT's codes are usable because the manuscript marks the numbered `CM_Cxx` options `validRef="False"`. That conclusion was wrong — `validRef="False"` only hides an option from the *interactive* dropdown picklist in Express, it doesn't block the underlying field from storing that value via XML import (which is how our conversion works). Proof: `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_CLAUSEAMENDMENTCM` (BP's equivalent table) shows these exact codes in massive live use — `CM_C03_NOAR` alone has 15,447 rows. There's also a real, working translation path we hadn't checked: `PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE` (an externally-populated staging table, not something our SP builds) already has correctly-captioned `PM`-prefixed entries — `PM Learner extension`, `PM AV/MV Caravan contents` — matching **21 confirmed real PP vehicles** (verified against `PER_VEHICLEDETAIL` live).

So this isn't "no path exists, needs a full client-built mapping from scratch" — it's "a working mechanism already exists and already covers a small slice of PP vehicles; the real question is why it doesn't cover the rest, and whether we can extend from it." Full breakdown (every code we have, how many vehicles use it, and DCT's actual valid option list) is in the separate [MOTOR_CLAUSES_MATRIX_20260717.md](MOTOR_CLAUSES_MATRIX_20260717.md) document — **also being corrected to reflect this**, not yet updated as of this edit.

```sql
/*
SEQ number: 17 (COM_CLAUSE — Motor)
Question: SCHEDULE_CLAUSES_TEMPLATE already correctly translates clauses for 21 PP vehicles (and
  much of BP's volume) but is essentially empty for the rest of PP's motor clause population. Do
  you know what populates this table upstream (a DCT-side or Duck Creek staging process, not ours),
  and whether it can be extended to cover the remaining PP vehicles -- or do we need a different
  mapping approach for those?
DCT Values : Carrier_CoverageLibrary_Data_1_0_0_0.xml:38191 -- public field
  CommercialVehicleClausesInput.ClausesSelection. Valid values are driven by the manuscript's
  "VehicleClauses" lookup table (Description/Indicator columns, same file lines 38238-38317).
  CONFIRMED LIVE (2026-07-17): the numbered CM_Cxx codes marked validRef="False" in the manuscript
  are NOT dead -- they're in heavy live use via CBP_CLAUSEAMENDMENTCM (BP side). validRef="False"
  hides a manuscript option from Express's interactive dropdown only; it does not block the
  underlying field from accepting that value via XML import.
*/

SELECT CAText, CADescription, COUNT(*) AS ROW_COUNT
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_CLAUSEAMENDMENTMV
GROUP BY 1, 2
ORDER BY 3 DESC;
```

```sql
/*
SEQ number: 17 (COM_CLAUSE — Motor)
Question: N/A -- supporting evidence query, confirms the 21 real PP-vehicle matches referenced
  above.
DCT Values : N/A
*/

SELECT COUNT(DISTINCT t.PUREVEHICLEID) AS PP_MATCHED_DISTINCT_VEHICLES
FROM PRD_T5_EXTERNAL_AGGNE.RISK.SCHEDULE_CLAUSES_TEMPLATE t
JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL v
  ON TRIM(t.PUREVEHICLEID) = TRIM(v.PER_VEHICLEDETAIL_id)
WHERE t.DCCLAUSETYPE ILIKE 'PM%';
```

---

## 3. Home Buildings — Landlords Protection flag

**In plain terms:** DCT wants to know whether Landlord Protections was actually taken on a policy (Yes/No). Right now we send "Yes" for every single policy, regardless of whether it was actually selected. We found a real field in Pure that looks like it should drive this (`HCHBLANDLORD`), but haven't confirmed it's the right one.

```sql
/*
SEQ number: 7 (RISK_Building_HB)
Question: Is HCHBLANDLORD the correct field to use for the Landlords Protection Taken/Not Taken
  flag?
DCT Values : Carrier_PersonalProtectionBase_1_0_0_0.xml:5606-5612 -- public field
  BuildingRiskSMEInput.LandlordProtections, options are exactly "Taken" / "NotTaken".
  Note: DCT's option value has NO space in "NotTaken" -- worth double-checking against what we
  currently send, since our HB_02 view outputs "Not Taken" WITH a space, which would silently fail
  to match DCT's option even once HCHBLANDLORD is confirmed as the right source field.
*/

SELECT HCHBLANDLORD, COUNT(*) AS POLICY_COUNT
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HOMECONTENTS
GROUP BY 1;
```

---

## 4. Motor — which coverages apply to which protection type?

**In plain terms:** A vehicle's Motor cover has 8 separate on/off coverage blocks (Comprehensive Property, Choice of Repair, Fire & Theft, Car Hire, Unlimited Glass, etc). Today, all 8 are switched "on" for every vehicle regardless of what protection type was actually chosen — e.g. a Third Party Only vehicle still shows Comprehensive Property switched on, which shouldn't be possible together.

```sql
/*
SEQ number: 18 (RISK_Building_PM)
Question: What's the correct rule for which of the 8 coverage blocks should be on for each
  protection type? We found a Pure table (PER_EXPIRINGPREMIUM) that has real per-coverage codes
  attached to actual premium amounts -- could this be the right source to derive "on/off" from
  directly, instead of a fixed rule?
DCT Values : Carrier_Package_Data_CW_1_0_0_0.xml:11389 -- public field VehicleInput.ProtectionType.
  Confirmed this field is referenced by at least 6 separate conditional rules elsewhere in the same
  manuscript file (lines 12402, 12503, 12866, 13019, 14042, 14050) that gate individual coverage
  blocks -- so DCT genuinely does enforce protection-type-based coverage visibility, we just
  haven't reverse-engineered the exact rule per block yet.
*/

-- Protection type per vehicle
SELECT MVCVProtectionType, COUNT(*) AS VEHICLE_COUNT
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL
GROUP BY 1;

-- Real per-coverage premium codes that might indicate which blocks are genuinely active
SELECT RSTYPECODE, COUNT(*) AS ROW_COUNT
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_EXPIRINGPREMIUM
GROUP BY 1
ORDER BY 2 DESC;
```

---

## 5. Home Contents — Specified Items Away From Premises, item-level detail

**In plain terms:** We correctly send whether a policy has "items away from the premises" cover Taken or Not Taken. But the actual list of items (what they are, what they're worth) never gets built — the source table exists in Pure, we just haven't wired it into the conversion yet.

```sql
/*
SEQ number: Not yet wired to any sequence -- the source table exists but has never been connected
  to the conversion pipeline.
Question: What shape/format does DCT expect for a list of these items (description + value,
  repeating per item)? Once you confirm, we can build this.
DCT Values : None found -- manuscript searched exhaustively this week for an itemized-list object
  (a repeating description+value structure) under Home Contents; no equivalent located. This may
  end up being a question for the DCT policy team rather than Capricorn, since it looks like a
  platform-capability question, not a business-rule one.
*/

SELECT *
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ITEMSAWAYFROMPREM
LIMIT 20;
```
