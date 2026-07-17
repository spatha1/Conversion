Subject: PP Conversion — 10 field questions needing your input

Hi team,

We've finished a full field-by-field check of the Personal Protection (PP) policy conversion —
comparing exactly what our source system (PURE) has against what Duck Creek (DCT) actually
expects, using live data pulled directly from the generated policy XML. Out of everything we
checked, we've narrowed it down to 10 items that genuinely need your input before we can fix them
— everything else we could resolve ourselves.

For each item below: what DCT expects, what we're actually seeing, why it's a problem, how many
records are affected, the evidence behind it, and the specific question we need answered.

A quick note on the evidence types you'll see referenced below:
- **PURE** — our source system, where the original policy data lives before conversion
- **Manuscript** — Duck Creek's own technical manual describing every field, its rules, and its
  accepted values (this is Duck Creek's documentation, not ours)
- **SAS logic** — the original conversion instructions your team gave us at the start of this
  project, showing what was always intended to happen with each field
- **Live data** — a real-time check we ran directly against the actual converted data / generated
  policy XML, not a guess or something from documentation alone

---

## 1. Age of Youngest Regular Driver

- Path: risk/AgeOfYoungestRegularDriver
- Type: Number (required)
- Expected: DCT requires a number between 17 and 99
- What we're seeing: 218 vehicles have this field completely blank, and a further 2 vehicles show
  age 16 — below the minimum DCT will accept
- Impacted Count: 220 vehicles (218 blank + 2 at age 16)
- Evidence:
  - **Live data**: query against our converted data (`PER_COM_PAYLOAD`) — 220 records fall outside
    the 17–99 range DCT requires
  - **Duck Creek's own manual** (what we call the "manuscript" — the technical document Duck Creek
    publishes describing every field and its rules): explicitly states the minimum age (`MinAge`)
    is 17 and the maximum (`MaxAge`) is 99, confirming 16 is genuinely below the accepted range,
    not just a display preference
- Question: Is 16 a valid minimum age for this field, or should it be 17? Separately, is there a
  source we're missing for the 218 blank records, or should a default be used?

---

## 2. Body Type

- Path: risk/BodyType
- Type: Dropdown (required)
- Expected: One of 17 specific values — Bus, Convertible, Coupe, Hatchback, PrimeMover, Sedan,
  Utility, Van, Wagon, TowTruck, Transporter, MobilePlant, Motorcycle, Trailer, CamperVan,
  Caravan, Forklift
- What we're seeing: Our system already converts the source value "Cab Chassis" into "CabChassis"
  (removing the space) for 10 vehicles — but "CabChassis" itself still isn't one of DCT's 17
  accepted values, so it will still be rejected. Separately, 3,217 vehicles show a completely blank
  Body Type — this is a mix of vehicles where the source genuinely has no value, and vehicles where
  the source says "Other" (which we currently have no mapping for, so it silently becomes blank
  instead of showing "Other")
- Impacted Count: 3,227 vehicles (10 "CabChassis" + 3,217 blank/"Other")
- Evidence:
  - **PURE (our source system)**: the raw value stored against the vehicle is literally "Cab
    Chassis" (with a space) for 10 vehicles, and "Other" for 661 vehicles
  - **Our conversion code**: already has a rule that turns "Cab Chassis" into "CabChassis" (no
    space) — so that translation step is working — but confirmed there is no rule at all for
    "Other", so it falls through and comes out blank
  - **Live data**: confirmed "CabChassis" (no space) is still not in DCT's list of 17 accepted
    values, so even the translated version would fail
- Question: What should "Cab Chassis" actually map to among your 17 valid options? Separately,
  what should "Other" map to?

---

## 3. Landlords Protections Indicator

- Path: coverage/Indicator (a specific sub-section coded HBLLB_SD)
- Type: Yes/No
- Expected: Should reflect whether Landlord Protections cover was genuinely selected for that
  property
- What we're seeing: We found there are actually **two** separate places this information appears.
  One of them already works correctly (shows Taken / Not Taken / blank appropriately). The other —
  a separate technical element — is hardcoded to always say "Taken", even for 1,000 properties that
  are owner-occupied, where Landlord Protections shouldn't apply at all
- Impacted Count: 1,000 owner-occupied properties incorrectly show this second element as "Taken"
- Evidence:
  - **Live data**: pulled the actual generated policy XML directly (`PER_BUILDING_TARGET`) and
    compared the two elements side by side — the working one shows a real mix of answers (67 Taken
    / 1,250 Not Taken / 514 blank); the broken one shows "Taken" on every single record, with zero
    variation, which on its own is a strong sign it's hardcoded rather than sourced from real data
- Question: Since the correct version already works, is this second element something DCT actually
  reads and needs, or is it a leftover duplicate we can safely stop sending?

---

## 4. Motor Clause Codes

- Path: Clauses/ClausesSelection
- Type: Dropdown
- Expected: A currently-active clause code
- What we're seeing: 71 motor clause records are still using 6 different legacy/retired codes that
  DCT no longer recognizes: CM_C01_LEARNER (17 records), CM_C02_YNGDRIVER (1 record),
  CM_C03_NOAR (37 records), CM_C04_EFF_DATE (14 records), CM_C06_MODSACCS (1 record),
  CM_C10_FTLIAB (1 record)
- Impacted Count: 71 clause records
- Evidence:
  - **Live data**: query against our data (`COM_CLAUSE`) — confirmed these 6 legacy codes are still
    present in what we're converting
  - **Duck Creek's own manual (the manuscript)**: these legacy CM_* codes are explicitly marked as
    disabled/retired for our product, with no listed replacement code — meaning DCT's own
    documentation confirms they're no longer valid, it just doesn't say what to use instead
- Question: What are the correct, current-code replacements for each of these 6 legacy codes?

---

## 5. Motor Coverage Selections

- Path: coverage/Indicator, across 8 coverage types
- Type: Yes/No, one per coverage type
- Expected: Only the coverage types the customer actually purchased should show as selected
- What we're seeing: For 231 "Third Party Only" policies, 4 unrelated coverage types are also
  incorrectly showing as selected: Comprehensive Property, Choice of Repairer, Car Hire, and
  Unlimited Glass. Separately, for 2,698 "Comprehensive" policies, "Third Party Only" is also
  incorrectly showing as selected — even though the customer bought Comprehensive cover
- Impacted Count: 231 Third Party Only policies (4 spurious selections each) + 2,698 Comprehensive
  policies (1 spurious selection each)
- Evidence:
  - **Live data**: extracted directly from the real generated policy XML
    (`PER_COM_COVERAGES_TARGET`) — confirmed these coverage indicators show "selected" regardless
    of what protection type the customer actually purchased
  - **Duck Creek's own manual**: confirmed the 8 coverage type codes we're using (e.g. CMP_SD =
    Comprehensive Property, PCH_SD = Car Hire, COR_SD = Choice of Repairer) are DCT's genuine,
    correctly-spelled codes — so this isn't a code-naming mistake on our side, it's that all 8 are
    being marked "selected" together instead of only the relevant ones
- Question: Which of the 8 coverage types should be marked "selected" for each protection type?

---

## 6. Number of Cylinders

- Path: risk/NumberOfCylinders
- Type: Dropdown (required), 1–16
- Expected: A number from 1 to 16
- What we're seeing: 3,105 vehicles show "0" for this field, which falls outside the 1–16 range
  DCT requires
- Impacted Count: 3,105 vehicles
- Evidence:
  - **PURE (our source system)**: for these vehicles, PURE itself has no cylinder count recorded
    at all (the field is empty in the source) — our conversion currently turns that "nothing
    recorded" into a literal "0", which is what DCT is rejecting
  - **Live data**: query against our converted data (`PER_COM_PAYLOAD`) confirms the 3,105 count
- Question: Should this field be left blank for vehicles that don't have an engine (trailers,
  electric vehicles, etc.), or is a different value expected?

---

## 7. SIC Code

- Path: risk/SICCode
- Type: Free text
- Expected: Something appropriate for a personal home policy
- What we're seeing: Every single one of the 1,392 personal home risk records shows the exact same
  text — "General Mechanical Workshop" — which is a commercial business description, not something
  that fits a personal home policy
- Impacted Count: 1,392 records (100% of personal home risk records)
- Evidence:
  - **Live data**: extracted directly from the real generated policy XML
    (`PER_RISK_BUILDING_TARGET`) — confirmed the identical text appears on all 1,392 records with
    no variation, which is itself a sign it's a fixed value rather than something coming from real
    policy data
  - **Duck Creek's own manual**: this field is documented as defaulting from the account's own
    underwriting group setting, not a fixed piece of text — meaning DCT's own design expects this
    to come from account-level information (or be left for DCT to fill in), not a hardcoded value
- Question: Should this field be left blank for personal policies, or is a specific value expected?

---

## 8. Specified Items Away From the Premises

- Path: coverage/SpecifiedItemsPremises (the detailed item list behind the Yes/No answer)
- Type: Record inclusion (item description + value)
- Expected: For the 195 policies where this cover shows "Taken," the actual list of covered items
  (what they are and their value) should be included
- What we're seeing: The Yes/No answer itself is correct. But we found the detailed item list is
  never sent anywhere — even though we already have this data on our side: 1,278 individual items
  across 495 policies (for example, "0.2 Diamond Tennis Bracelet")
- Impacted Count: 195 policies (100% of the "Taken" policies have zero item detail sent)
- Evidence:
  - **The original conversion instructions (SAS logic)**: the client's own original script for this
    section explicitly builds a table of these items — item description and item value — pulled
    from the source system's "Items Away From Premises" records. This confirms the intent was
    always to carry this item-level detail across, not just the Yes/No answer
  - **PURE (our source system)**: we found this exact data already sitting in our own system —
    1,278 individual items across 495 policies, with real descriptions and dollar values (e.g.,
    "0.2 Diamond Tennis Bracelet")
  - **Live data**: confirmed separately that none of this item-level detail appears anywhere in the
    generated policy XML today — only the Yes/No flag reaches DCT
- Question: We already have the data — what is the correct place/format in the policy XML for us
  to send this itemized list?

---

## 9. Voluntary Excess

- Path: risk/VoluntaryExcess
- Type: Dropdown
- Expected: One of 7 specific amounts — $0, $250, $500, $750, $1,000, $1,250, $1,500
- What we're seeing: 9 vehicles show an excess of $2,000, which is above the highest amount DCT
  will accept
- Impacted Count: 9 vehicles
- Evidence: Live query against our converted data (`PER_COM_PAYLOAD`)
- Question: What should an excess amount above $1,000 be mapped to?

---

## 10. Legacy Start Date

- Path: unclear which policy date field this refers to
- Type: Date
- Expected: A specific date field labelled "Legacy Start Date"
- What we're seeing: We have several date fields on file (Inception Date, Effective Date,
  Membership System Date), but none of them is literally named "Legacy Start Date." We can't
  confirm whether there's an actual problem until we know which field you mean
- Evidence: This item comes directly from your reported ticket **ATP-10962** ("Renewal - PP -
  Legacy start date incorrect") — we searched our full data dictionary and none of our fields carry
  that exact name
- Question: Which of our date fields corresponds to "Legacy Start Date" — Inception Date, Effective
  Date, Membership System Date, or something we don't currently capture at all?

---

Happy to walk through any of these together if that's easier — several of them (Body Type, Motor
Coverage Selections) may already have precedent from decisions made on the Business/Commercial
side that we could reuse.

Thanks,
[Your name]
