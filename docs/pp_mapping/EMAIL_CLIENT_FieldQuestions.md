Subject: PP Conversion — field questions needing confirmation (18 items)

Hi team,

While preparing the Personal Protection policy conversion, we've identified 18 fields where we need your input before we can finalize the mapping. For each one below: what's expected, what we currently have, the issue, how many records are affected, what's missing, and the specific question we need answered.

(Items 17-18 are new this round, found while cross-referencing your recently reported defect
tickets against our field-by-field review.)

---

## 1. Body Type
- Path: risk/BodyType
- Type: Dropdown (required)
- Expected: One of these 17 values — Bus, Convertible, Coupe, Hatchback, PrimeMover, Sedan,
  Utility, Van, Wagon, TowTruck, Transporter, MobilePlant, Motorcycle, Trailer, CamperVan,
  Caravan, Forklift
- What we have: Blank for most vehicles; some show "Other" or "Cab Chassis"
- Issue: "Other" and "Cab Chassis" aren't accepted values
- Impacted Count: 4,271 of 4,362 vehicles (3,600 blank, 661 "Other", 10 "Cab Chassis")
- Missing: Mapping for "Other" and "Cab Chassis"
- Question: What should "Other" and "Cab Chassis" map to? Has this already been solved on the Business side?

---

## 2. Number of Cylinders
- Path: risk/NumberOfCylinders
- Type: Dropdown (required), 1–16
- Expected: A number from 1 to 16
- What we have: `0` for vehicles with no engine (trailers, EVs)
- Issue: `0` isn't an accepted value
- Impacted Count: 512 vehicles
- Missing: Correct value for engine-less vehicles
- Question: Should this field be left blank for engine-less vehicles, or is a different value expected?

---

## 3. Voluntary Excess
- Path: risk/VoluntaryExcess
- Type: Dropdown
- Expected: One of $0 / $250 / $500 / $750 / $1,000 / $1,250 / $1,500
- What we have: Some vehicles show $2,000 or $5,000
- Issue: Amounts above $1,000 aren't accepted values
- Impacted Count: 9 vehicles
- Missing: Mapping rule for amounts above $1,000
- Question: What should an excess above $1,000 be mapped to?

---

## 4. Age of Youngest Regular Driver
- Path: risk/AgeOfYoungestRegularDriver
- Type: Number (required)
- Expected: Driver age between 17 and 99
- What we have: Blank on some records; a small number show age 16
- Issue: Unclear if 16 or 17 is the correct minimum
- Impacted Count: 218 blank (6.6%); 2 records at age 16
- Missing: Correct minimum driver age
- Question: Is 16 or 17 the correct minimum age for this field?

---

## 5. Underwriting Adjustments (one-off)
- Path: UnderwritingAdjustment (Motor / Home Contents)
- Type: Record inclusion
- Expected: All underwriting adjustments that apply to the policy
- What we have: Only "ongoing" adjustments are currently included; one-off adjustments are left out entirely
- Issue: The majority of adjustment records aren't being carried across
- Impacted Count: ~19,800 adjustment records (60–64% of all adjustments)
- Missing: Confirmation on whether one-off adjustments belong in the conversion
- Question: Should one-off (non-recurring) underwriting adjustments be included?

---

## 6. Premium (Home)
- Path: coverage/Premium (Buildings & Contents)
- Type: Numeric
- Expected: A premium specific to each coverage section
- What we have: The same total home premium shown on both the Buildings and Contents sections
- Issue: Possible premium double-counting when a policy has both
- Impacted Count: 1,109 of 1,843 policies (60.2%)
- Missing: Confirmation on whether the premium should be split
- Question: Should the premium be split between Buildings and Contents, or is showing the same total on both expected?

---

## 7. Motor Clause Codes
- Path: Clauses/ClausesSelection
- Type: Dropdown
- Expected: A current, active clause code
- What we have: A number of clauses use retired/legacy codes
- Issue: Legacy codes aren't recognized
- Impacted Count: 71 clause records total, broken down below
- Missing: Current-code equivalent for each legacy code
- Question: Please confirm (or correct) the 4 likely pairings below, and tell us the correct
  current equivalent for the 2 we couldn't match:

  | Legacy code (record count) | Our best guess at current equivalent |
  |---|---|
  | CM_C03_NOAR (37) | PM_C05_NOAR |
  | CM_C01_LEARNER (17) | PM_C03_LEARNER |
  | CM_C04_EFF_DATE (14) | PM_C06_EFF_DATE |
  | CM_C06_MODSACCS (1) | PM_C07_MODSACCS |
  | CM_C02_YNGDRIVER (1) | *no obvious equivalent — please advise* |
  | CM_C10_FTLIAB (1) | *no obvious equivalent — please advise* |

  The first four are a name-pattern guess only, not confirmed — please don't assume they're
  correct without checking.

---

## 8. Landlords Protections Indicator
- Path: coverage/Indicator (Landlords Protections)
- Type: Yes/No
- Expected: Reflects whether Landlord Protections was actually selected
- What we have: Always shown as selected, even for owner-occupied properties
- Issue: No data currently available to say whether it was actually taken
- Impacted Count: 2,097 of 3,054 policies (68.7%, owner-occupied)
- Missing: A source flag for "Landlord Protections taken"
- Question: Is there a "Landlord Protections taken" flag available? If not, can occupancy type be used instead?

---

## 9. Home Buildings Underwriting Adjustments
- Path: UnderwritingAdjustment (Home Buildings)
- Type: N/A
- Expected: Adjustments should reach the finished policy
- What we have: Not currently reaching the policy at all
- Issue: Home Buildings adjustments are effectively missing end to end
- Impacted Count: All Home Buildings adjustment records
- Missing: Confirmation on scope
- Question: Are Home Buildings underwriting adjustments in scope for this conversion?

---

## 10. State
- Path: risk/State
- Type: Text
- Expected: One of the 8 Australian state/territory codes — ACT, NSW, QLD, VIC, NT, SA, TAS, WA
  (there is no New Zealand code in this list at all)
- What we have: Every vehicle currently shows "NSW," including New Zealand risks
- Issue: No accepted value exists for New Zealand
- Impacted Count: 629 of 4,377 vehicles are NZ risks (full breakdown: VIC 1,342, WA 891,
  NSW 747, NZ 629, QLD 392, SA 290, TAS 63, NT 16, ACT 7)
- Missing: Value to use for NZ risks
- Question: What should be shown for NZ risks?

---

## 11. Home Buildings Excess Breakdown
- Path: Excess (Standard / Imposed / Earthquake / Flood / Glass)
- Type: N/A
- Expected: N/A
- What we have: Blank
- Issue: —
- Impacted Count: 3,054 Home Buildings policies (scope, not an error)
- Missing: Confirmation this breakdown applies to PP at all
- Question: Does this excess breakdown apply to personal Home Buildings policies?

---

## 12. Glass Limit
- Path: coverage/GlassLimit
- Type: Numeric
- Expected: A glass-cover-specific limit
- What we have: The full building sum insured amount
- Issue: Likely the wrong figure for this field
- Impacted Count: 3,054 of 3,054 Home Buildings rows (100%)
- Missing: Correct source (or confirmation it should be blank)
- Question: Should this be blank, or is there a separate glass limit value?

---

## 13. Risk-Level Excess Breakdown
- Path: StandardExcess / ImposedExcess (risk level)
- Type: N/A
- Expected: N/A
- What we have: Blank
- Issue: —
- Impacted Count: 1,399 of 1,399 risk records (100%, scope not error)
- Missing: Confirmation this breakdown applies to PP at all
- Question: Same as #11 — does this apply to personal policies?

---

## 14. SIC Code
- Path: risk/SICCode
- Type: Text
- Expected: Something reflecting the policy
- What we have: "General Mechanical Workshop" (a commercial description)
- Issue: Shown on every personal home policy, doesn't fit
- Impacted Count: 1,399 of 1,399 risk records (100%)
- Missing: Correct value (or confirmation it should be blank)
- Question: Should this be blank, or is a specific value expected for personal policies?

---

## 15. Risk-Assessment Answers
- Path / current value, all 6 fields:
  - ExternalDoors — currently "Yes"
  - SecurityAccessibleWindows — currently "Yes"
  - SecurityAlarm — currently "No"
  - LocationConnectedToTownWaterMain — currently "No"
  - StoreFlammableGoods — currently "No"
  - IsAusStandardFollowed — currently "Yes"
- Type: Yes/No
- Expected: Should reflect the actual property
- What we have: Fixed answers as listed above, identical on every property regardless of the
  property's actual condition
- Issue: Not based on any actual property information
- Impacted Count: 1,399 of 1,399 risk records (100%)
- Missing: A real data source, or confirmation to leave blank
- Question: Is there source data for any of these six? If not, should they be left blank instead
  of asserting a fixed answer?

---

## 16. Motor Coverage Selections
- Path: coverage/Indicator — all 8 coverage types below:
  - Comprehensive Property
  - Choice of Repair
  - Fire & Theft excluding Liability
  - Comprehensive Liability
  - Car Hire
  - Third Party Fire & Theft
  - Third Party Only
  - Unlimited Glass
- Type: Yes/No
- Expected: Only the relevant coverages selected per protection type
- What we have: All 8 coverage types always shown as selected, regardless of the vehicle's actual
  protection type
- Issue: e.g. Third Party Only policies show Comprehensive Property, Choice of Repair, Car Hire,
  and Unlimited Glass all as selected; Comprehensive policies show Third Party Only as selected
- Impacted Count: 230 Third Party Only policies with 4 spurious coverages each; 2,701
  Comprehensive policies (900 Agreed Value + 1,801 Market Value) each showing a spurious Third
  Party Only selection — ~2,931 mismatched rows across 2,178 policies total
- Missing: The correct coverage-per-protection-type matrix
- Question: Which of the 8 coverages should apply to which protection type? Separately, should
  Car Hire / Choice of Repair / Unlimited Glass also depend on whether those options were
  individually taken, rather than protection type alone?

---

## 17. Specified Items Away From the Premises
- Path: coverage/SpecifiedItemsPremises (item detail)
- Type: Record inclusion
- Expected: Each item's description and value should carry across for policies where this cover was taken
- What we have: A working Taken/Not Taken flag, but no item descriptions or values behind it at all
- Issue: The response survives, the itemized list of what was actually covered does not
- Impacted Count: 195 of 1,831 Home Contents policies show "Taken" with zero item detail (100% of the Taken cases)
- Missing: The item-level list (description + value) and confirmation of what format it should take
- Question: What's the expected format for the itemized list of items away from the premises — is there a specific field/section we should be populating that we're missing?

---

## 18. Legacy Start Date
- Path: Policy header — exact field unconfirmed
- Type: Date
- Expected: A specific date field labeled "Legacy Start Date"
- What we have: We have Inception Date, Effective Date, Expiration Date, and Membership System Date, but none of these are literally named "Legacy Start Date"
- Issue: We can't confirm or rule out a bug without knowing which of our date fields this refers to
- Impacted Count: N/A — pending field identification
- Missing: Confirmation of which date field "Legacy Start Date" maps to
- Question: Which specific date field is "Legacy Start Date" — is it one of Inception Date, Effective Date, or Membership System Date, or something else entirely?

---

Happy to walk through any of these together if that's easier.

Thanks,
[Your name]
