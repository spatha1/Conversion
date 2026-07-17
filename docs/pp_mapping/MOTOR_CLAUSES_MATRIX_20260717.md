# Motor Clauses — Pure vs DCT Full Join Matrix

Scope: PP (Personal Protection) Private Motor "Select Clause" dropdown only.
(BodyType is a separate, already-answered item — not covered here.)

Manuscript object: `CommercialVehicleClausesInput.ClausesSelection`
(`Carrier_CoverageLibrary_Data_1_0_0_0.xml`, shared by BP and PP Motor clauses)

## How to read this

- **Pure Value** = the exact code/text currently sitting in our source data for this clause.
- **Sent to DCT as** = what we currently transmit in the payload (today: unchanged pass-through of the Pure Value — no translation happens).
- **Matching?** = does that value equal one of DCT's real, currently-selectable dropdown options?
- Every single Pure Value below is **NOT MATCHING** — 0 of 24 distinct source values currently resolve to a live DCT option. That's why the "Select Clause" dropdown shows blank in Express regardless of which clause was originally selected in Pure.

---

## Part 1 — Pure values in our data (left side of the join)

Source: `PER_CLAUSEAMENDMENTMV.CAText` unless noted.

| Pure Value | Rows | Sent to DCT as | Matching? | Best-guess DCT equivalent (unconfirmed) |
|---|---|---|---|---|
| PM_C05_NOAR | 410 | PM_C05_NOAR | **NO** | `CMHireUnderExtension` ("CM Hire Under 21 Extension") — text overlap with "drivers under the age of 21," not certain |
| CM_C03_NOAR | 292 | CM_C03_NOAR | **NO** | Exists in manuscript verbatim but is a dead/hidden option (`validRef="False"`) |
| PM_C03_LEARNER | 193 | PM_C03_LEARNER | **NO** | `CMLearnerExtension` ("CM Learner Extension") — confident by name |
| CM_C01_LEARNER | 139 | CM_C01_LEARNER | **NO** | Exists in manuscript verbatim but is a dead/hidden option |
| PM_C01_CRVNCNTAV | 134 | PM_C01_CRVNCNTAV | **NO** | No caravan-contents option exists anywhere in this clause list |
| CM_C04_EFF_DATE | 122 | CM_C04_EFF_DATE | **NO** | Exists in manuscript verbatim but is a dead/hidden option |
| PM_C04_YNGDRIVER | 110 | PM_C04_YNGDRIVER | **NO** | No "Young Driver" option exists at all (not even a dead one) |
| PM_C06_EFF_DATE | 85 | PM_C06_EFF_DATE | **NO** | No live Effective Date option (only the dead `CM_C04_EFF_DATE`) |
| PM_C02_CRVNCNTMV | 36 | PM_C02_CRVNCNTMV | **NO** | Same caravan-contents gap as above |
| CM_C02_YNGDRIVER | 30 | CM_C02_YNGDRIVER | **NO** | Doesn't exist in the manuscript at all — not even the dead-code list has a C02 entry |
| PM_C07_MODSACCS | 28 | PM_C07_MODSACCS | **NO** | No live Modifications/Accessories option |
| CM_C06_MODSACCS | 25 | CM_C06_MODSACCS | **NO** | Exists in manuscript verbatim but is a dead/hidden option |
| PM_C09_RISKEXC | 15 | PM_C09_RISKEXC | **NO** | Maybe `CMGeneralExclusionOD` or `CMGeneralExclusionPL` — ambiguous which |
| CM_C08_RISKEXT | 9 | CM_C08_RISKEXT | **NO** | Exists in manuscript verbatim but is a dead/hidden option |
| CM_C10_FTLIAB | 7 | CM_C10_FTLIAB | **NO** | Exists in manuscript verbatim but is a dead/hidden option |
| PM_C08_RISKEXT | 4 | PM_C08_RISKEXT | **NO** | No confident equivalent |
| CM_C04_EFF_DATE: *(trailing colon, data-entry variant)* | 4 | CM_C04_EFF_DATE: | **NO** | Even without the colon, still a dead option |
| PM_C10_ADDBENEXT | 3 | PM_C10_ADDBENEXT | **NO** | Maybe one of `CMAdditionalBenefitFourIncrease` / `TenIncrease` / `TwelveIncrease` — can't tell which number |
| GC_C03_INCLMT | 3 | GC_C03_INCLMT | **NO** | Different prefix entirely (not CM/PM) — unclear if this even belongs to Motor clauses |
| PM_C04_EFF_DATE *(numbering variant)* | 1 | PM_C04_EFF_DATE | **NO** | Likely a data-entry variant of `PM_C06_EFF_DATE` |
| PM_C03_LEARNERd *(typo variant)* | 1 | PM_C03_LEARNERd | **NO** | Data-entry typo of `PM_C03_LEARNER` |
| PM AV Caravan contents *(source: SCHEDULE_CLAUSES_TEMPLATE)* | — | PM AV Caravan contents | **NO** | No caravan-contents option exists |
| PM MV Caravan contents *(source: SCHEDULE_CLAUSES_TEMPLATE)* | — | PM MV Caravan contents | **NO** | Same gap |

**Match rate: 0 / 22 distinct Pure values (0%).**

---

## Part 2 — DCT's real, live options with no Pure source at all (right side of the join)

These are the only genuinely selectable values in the manuscript (`validRef` points to a real condition, not `False`) — every one of them currently has **zero** Pure data feeding it:

| DCT Value | Caption | Fed by Pure today? |
|---|---|---|
| CMLearnerExtension | CM Learner Extension | No |
| CMHireUnderExtension | CM Hire Under 21 Extension | No |
| CMGeneral | CM General | No |
| CMGeneralExclusionOD | CM General Exclusion OD | No |
| CMGeneralExclusionPL | CM General Exclusion PL | No |
| CMOptionalBenefitOneIncrease | CM Optional Benefit 1 Increase | No |
| CMAdditionalBenefitFourIncrease | CM Additional Benefit 4 Increase | No |
| CMAdditionalBenefitTenIncrease | CM Additional Benefit 10 Increase | No |
| CMAdditionalBenefitTwelveIncrease | CM Additional Benefit 12 Increase | No |
| CMF&TOnlyLiabilityExtension | CM F&T Only - Liability Extension | No |

(10 further `FV*` options exist for Fleet vehicles only — not applicable to PP Private Motor.)

---

## Part 3 — Dead/hidden options (for reference only, do not map to these)

`validRef="False"` — confirmed via pattern-match against two other manuscript fields (`IndemnityPeriod`'s `"0"` option, `ProductsandPublicLiabilityLimit`'s `"$0"` option) that this marks a permanently-hidden placeholder, never actually selectable in Express:

`CM_C01_LEARNER`, `CM_C03_NOAR`, `CM_C04_EFF_DATE`, `CM_C05_HVNOAR`, `CM_C06_MODSACCS`, `CM_C07_ADDBENEXT`, `CM_C08_RISKEXT`, `CM_C09_RISKEXC`, `CM_C10_FTLIAB`, `CM_C11_EXCESS`

---

## Bottom line

There is no mechanical fix here — every Pure value needs the client/policy team to confirm which (if any) of the 10 real DCT values in Part 2 it should map to. Several (Caravan Contents, Young Driver, `GC_C03_INCLMT`) may have **no equivalent at all**, meaning that clause type may not be representable in DCT today and would need a different manuscript object or a product decision.
