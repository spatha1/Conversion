# PP DEV Batch — UI Test Matrix (2026-07-16)

Built from the live 46-policy DEV batch results (`uat_batch_dev_results.json`) cross-checked against
the actual source tables (`BUILDING_UW`, `PER_HC_BUILDING_UW`, `PER_PM_BUILDING_UW`, `HB_CLAUSE`,
`PER_HC_CLAUSE`, `COM_CLAUSE`, `PER_HC_ITEMS_EXCEED_VALUE`, `PER_HC_SPECIFIEDCONTENTS`, `PM_03`) — every
policy below is picked because it actually has that scenario's data, not a guess. Quote numbers are the
**DEV** quotes from this batch (submitted 2026-07-16); UAT quote numbers are in the evidence table if
you need to cross-reference.

Policies with a DCT-side failure (`fail > 0`) are called out separately at the bottom — don't use those
for clean recordings until the failure is investigated.

## 1. CommercialVehicle → PersonalMotor mislabel (client-reported, fixed 2026-07-16)

| Legacy Policy | DEV Quote ID | What to test |
|---|---|---|
| P00026345 | Q0132780 | Vehicle risk coverage block: confirm Type/Description show **Personal Motor**, not Commercial Vehicle |
| P00026339 | Q0132779 | Same check |

## 2. Motor premium no longer $0 (Comprehensive Market fix, fixed 2026-07-16)

| Legacy Policy | DEV Quote ID | What to test |
|---|---|---|
| P00010162 | Q0132768 | Vehicle premium should show **$14,921.60** (Motor), not $0 |
| P00026642 | Q0132787 | Vehicle premium should show **$8,708.53** (Motor), not $0 |

## 3. Blank PartyID / culture=en-NZ Express crash (workaround confirmed, root cause still open)

| Legacy Policy | DEV Quote ID | What to test |
|---|---|---|
| P00001380 | Q0132762 | Open the quote in Express; confirm it loads cleanly with no 500 error, despite blank Pure PartyID |
| P00009965 | Q0132766 | Same check |
| P00010168 | Q0132769 | Same check (also covers item #9 below — bonus coverage) |

## 4. Home Building Underwriting Adjustment (XML confirmed correct — expect grid still blank, open item)

| Legacy Policy | DEV Quote ID | What to test |
|---|---|---|
| P00014342 | Q0132770 | Building coverage → Underwriting Adjustments grid — currently expected to still show no results (escalated to Duck Creek/policy team) |

## 5. Home Contents Underwriting Adjustment (same open item, Contents side)

| Legacy Policy | DEV Quote ID | What to test |
|---|---|---|
| P00009655 | Q0132764 | Contents coverage → Underwriting Adjustments grid — same expected-blank check |

## 6. Vehicle Underwriting Adjustment (same open item, Motor side — the one under investigation)

| Legacy Policy | DEV Quote ID | What to test |
|---|---|---|
| P00026440 | Q0132781 | Vehicle → Underwriting Adjustments grid — currently expected to still show no results |
| P00036708 | Q0132806 | Same check |

## 7. Home Contents Clause

| Legacy Policy | DEV Quote ID | What to test |
|---|---|---|
| P00009655 | Q0132764 | Contents → Clauses: confirm clause text/code displays correctly |

## 8. Motor Clause — SKIP for now

Only one policy in the batch has Motor clause data (P00017446 / Q0132771), and it's one of the 9
policies below with a DCT-side failure. Don't use it for a clean recording until that failure is
investigated.

## 9. Contents Items-Over-Limit / Specified Items

| Legacy Policy | DEV Quote ID | What to test |
|---|---|---|
| P00010168 | Q0132769 | Contents → Items Over Limit: confirm the listed item's description/value |
| P00000371 | Q0132761 | Contents → Specified Items: confirm the listed item(s) |

## Policies with a DCT-side failure — investigate before recording, don't use yet

| Legacy Policy | DEV Quote ID | Failure count |
|---|---|---|
| P00007821 | Q0132763 | 2 |
| P00017446 | Q0132771 | 2 |
| P00026900 | Q0132788 | 2 |
| P00030171 | Q0132793 | 1 |
| P00034443 | Q0132795 | 1 |
| P00034444 | Q0132796 | 1 |
| P00034447 | Q0132797 | 1 |
| P00034501 | Q0132798 | 2 |
| P00034583 | Q0132805 | 1 |

## Separate open item — not covered above

**P00010162 (Q0132768)** already appears above for the Motor-premium check, but it also has a
*separate, still-unresolved* Party Conversion issue tied to `CML00001418` (not the same as the blank
`InputClientID` covered in section 3) — don't treat a clean load here as closing that item out.

## Query to re-pull this matrix any time

```sql
SELECT LEGACY_POLICY_NUMBER, DEV_QUOTE_NUMBER, PARTY_ID_BLANK,
       RISK_TOTAL_PREMIUMS_VEHICLE, RISK_TOTAL_PREMIUMS_PROPERTY, FAILURE_COUNT
FROM AGGNE.DEV.PP_DEV_BATCH_VALIDATION_EVIDENCE
ORDER BY LEGACY_POLICY_NUMBER;
```
