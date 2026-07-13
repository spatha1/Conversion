# Issue Summary — For Client QA Validation

*(Batch Details section — Environment, LegacyPolicy + Quote list — to be added from
`AGGNE.UAT_XML.PP_CONVERSIONINFORMATION`)*

---

## 1. Fixed — Ready for QA to Validate

### ATP-10963 — Personal Motor vehicle details failing to transfer
- **Issue (plain words):** Body Type, Number of Cylinders, Induction Type, Import Flag, Engine Size,
  Gross Vehicle Mass, and Drive Description were blank or wrong for most vehicles — only vehicles
  that hit a specific override matched correctly before.
- **Is Fixed:** Yes, for the core issue. A few narrower sub-items under this same ticket are still
  open (unmapped Body Type values, the cylinder-count omit-tag decision, driver age threshold) —
  keep this ticket open until those close too, even though the main fix is validated.
- **Validate against:** spot-check any Motor policy in this batch — Body Type and Cylinder Count
  should now show real values instead of blank/zero for the large majority of vehicles.

### ATP-11110 / ATP-11117 / ATP-11115 — Location, Home Buildings/Contents, Vehicle details missing
- **Issue (plain words):** For a policy with more than one location or a renewed term, the current
  location's Home Buildings / Home Contents cover — and in some cases the vehicle details — went
  missing from the converted policy.
- **Is Fixed:** Yes
- **Validate against:** **P00010162** (Quote **Q0114998**)

### ATP-10842 — Windscreen Glass Excess always shows "Taken"
- **Issue (plain words):** The "Unlimited Glass" excess-waiver flag always came through as ON, even
  for policies where the customer had not waived glass excess.
- **Is Fixed:** Yes
- **Validate against:** P00000371, P00007821, P00009965, P00010132, P00010168, P00017446,
  P00026339, P00026345, P00026440, P00026585, P00026586, P00026642

### ATP-11107 — Specified Items Away from the Premises not migrated
- **Issue (plain words):** Items a customer listed as kept away from the premises (e.g. a scheduled
  item taken travelling) weren't showing up in the converted policy — only the Yes/No flag was.
- **Is Fixed:** Yes
- **Known limitation:** only the single most recent item per policy carries across today, not a full
  multi-item list — flagged separately, not part of this validation.
- **Validate against:** P00000371, P00001380, P00009655, P00009818, P00010162, P00010168,
  P00014342, P00017446, P00017491, P00018498, P00018499, P00020329, P00023281, P00023285, P00024003

### ATP-11105 — Rewired / Replumbed dates not migrated
- **Issue (plain words):** For older buildings, the year the electrical wiring or plumbing was last
  replaced was blank in the converted policy even when the customer had provided it.
- **Is Fixed:** Yes
- **Validate against:** P00009655, P00014342, P00023281, P00030024, P00034447, P00034504

### ATP-11089 / ATP-11042 — Recurring adjustments not migrating / percentage shown instead of dollar amount
- **Issue (plain words):** Recurring loadings/discounts on a policy (e.g. a no-claims discount that
  should renew every term) were carrying through with a blank dollar amount instead of the real
  figure, for Home Contents, Home Buildings, and Special Items ("SU") cover.
- **Is Fixed:** Yes (Home Contents / Special Items / Motor). Home Buildings' version of this same
  problem is tracked separately below (see "HB Underwriting Adjustments").
- **Note:** these two tickets also appear on the Business Package team's own board — worth
  confirming with them whether this is the same fix they're expecting, or a separate issue.
- **Validate against:** aggregate check recommended (adjustment amounts now populate for HC/SU/Motor
  coverage lines generally) rather than one single policy.

### HB Underwriting Adjustments *(internal finding — no client ticket filed)*
- **Issue (plain words):** Underwriting adjustments recorded against Home Buildings cover (loadings/
  discounts) never reached the converted policy at all — they were being read from the wrong
  (Business Package) source table.
- **Is Fixed:** Yes
- **Validate against:** P00009655, P00014342, P00017446, P00026900, P00029182, P00034447

### Duplicate Quote Submissions *(internal finding — no client ticket filed)*
- **Issue (plain words):** A small number of policies whose payment plan had been changed (e.g.
  Monthly to Annually) were generating two conflicting quotes for the same policy instead of one.
- **Is Fixed:** Yes
- **Validate against:** confirmed zero duplicate policy numbers across this batch (46 policies in,
  46 distinct quotes out)

### Voluntary Excess (Motor) — wrong bands / no cap *(internal finding — no client ticket filed)*
- **Issue (plain words):** The Motor voluntary excess amount was being grouped into the wrong bands
  and had no upper cap, so high values didn't line up with Duck Creek's expected excess options.
- **Is Fixed:** Yes
- **Validate against:** P00000371, P00001380, P00007821, P00009655, P00009965, P00010132,
  P00010162, P00010168, P00017446, P00026339, P00026345, P00026440, P00026585, P00026586,
  P00026642, P00027855, P00030024, P00030171, P00034443, P00034501, P00034510, P00034535,
  P00034583, P00036708

### ATP-11111 — Motor Premium always showing $0
- **Issue (plain words):** The Motor section's premium contribution amount was always coming through
  as zero, regardless of the policy's actual premium.
- **Is Fixed:** Yes
- **Validate against:** validated against the full DEV population (0 of 3,307 vehicle rows now show
  zero premium, was 100%) — this batch's Motor policies should be spot-checked directly in
  UAT_XML rather than against one named example.

---

## 2. Closed — Checked, No Action Needed

| Ticket | What we checked | Finding |
|---|---|---|
| ATP-11123 | Live-checked against P00026900 | Already correct ("Model car collection", $10,000) — no fix needed |
| ATP-11106 | Unspecified Items Away from the Premises | Already populating correctly (400 of 1,831 policies show "Taken" with correct limit values) — no fix needed |
| (no ticket) | Blank cylinder-count fields on vehicles genuinely without an engine | Client confirmed blank-stays-blank is correct — matches our existing behaviour, closing with no change |

---

## 3. Open — Awaiting Your Answer

| Ticket | Question for you |
|---|---|
| ATP-10961 | Unmatched policies default to a real staff member's name as account handler. We drafted a "blank" fix but retracted it — that same field also controls the Duck Creek session's Producer setting, so blanking it risks breaking the import outright. Can you confirm (a) whether Duck Creek accepts a blank Producer, and (b) if not, a safe fallback value? |
| ATP-11116 | Motor "Imposed Excess" is always blank — there's no equivalent concept anywhere in the source data today, same as two other fields we've already asked about (Home Buildings equivalents). Can you confirm this is expected to be blank for Personal lines, or is there a source field we're missing? |
| ATP-11113 | Reported as Voluntary Excess "failed to migrate" — but checked live against the example policy and it isn't blank (one vehicle shows 500, the rest show 0). Can you give us the specific vehicle/value you expected, so we can confirm whether this is a real gap? |
| ATP-10842 (remaining scope) | The Windscreen Glass Excess symptom under this ticket is fixed (see Section 1). But the same "always-on" pattern exists on 7 other Motor coverage-selection codes, which need a client-defined rule for which coverages are mutually exclusive before we can fix those too. |

---

## 4. Still Investigating

| Ticket | Issue (plain words) | Status |
|---|---|---|
| ATP-10965 | Some policies show both Motor and Home cover selected at once | Checking whether this reflects real source data or a conversion issue |
| ATP-10962 | "Legacy Start Date" incorrect | Not yet started — no field in our data currently carries that exact name |
| ATP-11112 | Youngest regular driver's age appears to increase on renewal | Initial lead didn't hold up — needs a specific example policy number from you to trace further |
