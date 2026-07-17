# BUG → GAP Mapping — ATP-10219 Open Tickets (2026-07-09 export)

Source: `files/Issues/BP Conversion/2028-07-09/ATP-10219-Open-Tickets.html`, 67 open tickets
assigned to Raju Kallepelli / saichand patha. Cross-referenced against `docs/bp_mapping/README.md`'s
gap register. **16 new gaps** created (G-BP-51 through G-BP-66, skipping 52/53/54/57/58 which are
interspersed by area above — full list at the bottom) where no existing gap covered the ticket.

**9 tickets excluded — confirmed PP, not BP** (see table 2).

---

## 1. BP tickets mapped to gaps

| # | Ticket | Summary | Gap ID | New? |
|---|---|---|---|---|
| 1 | ATP-11137 | Business details — Tyre dealer UW Questions Clarity/DC UI = 0 | G-BP-94 *(FIXED LIVE 2026-07-13, verified against this ticket's own example policy P00009659 — PERTOVEHSERVICE now correctly shows 90 end-to-end in VW_CBP_OUTPUT_CONVERSION)* | split from G-BP-35 |
| 2 | ATP-11136 | Business details — sideline business turnover, UI correct Clarity incorrect | G-BP-95 *(CONFIRMED 2026-07-13 — live check: 0 of 18,889 policies now have IsSidelineBusinessEntity='No' with a nonzero VehicleTurnoverDisplay_Side; pre-fix this field-group had 50 live mismatches)* | existing |
| 3 | ATP-11135 | Business details — recondition engines/gearboxes turnover | G-BP-95 *(CONFIRMED 2026-07-13 — same field as ATP-11095 below; live check: 0 of 18,889 remaining IsGearboxesRecondition='No'-with-nonzero-detail leaks)* | existing |
| 4 | ATP-11134 | Fleet Details — Make & Model broken in UI | **G-BP-55** | **new** |
| 5 | ATP-11131 | Business details — Tyre sales % turnover | G-BP-35 | existing |
| 6 | ATP-11130 | Fleet Details — RB Vehicle Key broken in Clarity | **G-BP-53** | **new** |
| 7 | ATP-11129 | Fleet Details — Market Value without accessories broken | **G-BP-54** | **new** |
| 8 | ATP-11127 | Fleet Details — Fuel Type, Import Type, Power KW, CMRB Track Rear broken | G-BP-48 | existing (direct confirmation) |
| 9 | ATP-11124 | CM details — Incorrect for Overridden Vehicles | **G-BP-56** | **new** |
| 10 | ATP-11122 | CM details — Incorrect value for Market Value without Accessories | **G-BP-57** | **new** |
| 11 | ATP-11118 | CM details — Incorrect value for Agreed Value without Accessories | **G-BP-58** | **new** |
| 12 | ATP-11108 | CM details — RB Induction type not retrieving if PURE='N/A' (overridden) | **G-BP-59** | **new** |
| 13 | ATP-11099 | Business details — manufacture/import products turnover | G-BP-95 *(CONFIRMED 2026-07-13 — live check: 0 of 18,889 remaining IsProductsManufacturedorImported='No'-with-nonzero-detail leaks; pre-fix 62 live mismatches; also confirmed via ATP-11067's exact policy P00034530 below)* | existing |
| 14 | ATP-11098 | Business details — mining equipment services turnover | G-BP-95 *(CONFIRMED 2026-07-13 — this is ATP-11050's own field-group, verified against ATP-11050's exact example P00034499: 'No', 0, 0)* | existing |
| 15 | ATP-11096 | Business details — heavy transport vehicles turnover | G-BP-95 *(CONFIRMED 2026-07-13 — live check: 0 of 18,889 remaining IsHeavyTransportVehicles='No'-with-nonzero-detail leaks; pre-fix 196 live mismatches, the largest single field-group)* | existing |
| 16 | ATP-11095 | Business details — recondition engines/gearboxes turnover | G-BP-95 *(CONFIRMED 2026-07-13 — same field as ATP-11135 above; live check: 0 of 18,889 remaining leaks)* | existing |
| 17 | ATP-11094 | Business details — construction/earthmoving equipment turnover | G-BP-95 *(CONFIRMED 2026-07-13 — live check: 0 of 18,889 remaining IsConstructionServices='No'-with-nonzero-detail leaks; pre-fix 22 live mismatches)* | existing |
| 18 | ATP-11093 | CM details — Incorrect value for RB Vehicle Type | G-BP-11 | existing (direct confirmation) |
| 19 | ATP-11076 | Business details — 2nd hand tyres % turnover | G-BP-35 | existing |
| 20 | ATP-11075 | Business details — Heavy Duty Diesel Mechanic UW Questions = 0 | G-BP-94 *(FIXED LIVE 2026-07-13, verified — same fix, shares the root cause with ATP-11137)* | split from G-BP-35 |
| 21 | ATP-11074 | Business details — Management/Proprietors/Partners incorrect in Clarity | **G-BP-60** | **new** |
| 22 | ATP-11072 | Business details — Heavy transport tyres % turnover | G-BP-35 | existing |
| 23 | ATP-11069 | Business details — Primary/secondary ANZSIC vs SAS logic | G-BP-35 | existing |
| 24 | ATP-11068 | Business details — run-off protection quotes broken | G-BP-35 | existing — G-BP-49 candidate link retracted 2026-07-11, see below |
| 25 | ATP-11067 | Business details — manufacture/import + Management/Partners (no PL section) | G-BP-95 *(CONFIRMED 2026-07-13 against this ticket's own exact policy Q0114282/P00034530 — source data confirms PublicAndProductLiability=0 exactly as the ticket describes ("this policy doesn't have PL section"); pre-fix would have shown IsProductsManufacturedorImported='Yes', Display_ManIm=$722,500, ManagementProprietorsAndPartners=3; post-fix all four fields correctly collapse to 'No'/0/0/0 via the new outer-gate condition)* | existing |
| 26 | ATP-11066 | Business details — high-performance vehicle turnover % | G-BP-35 | existing |
| 27 | ATP-11064 | Fleet Summary — Total Value Excl. Accessories & Highest Value Vehicle | G-BP-36 (+ ties to G-BP-48 — `HighestValueVehicleinFleet` is also an empty SEQ 61 tag) | existing |
| 28 | ATP-11062 | CM details — RB Description, RB Engine Size, RB Gross Vehicle Mass broken | G-BP-37 (scope extended — GVM added) | existing |
| 29 | ATP-11061 | CM details — RB Drive Description blank | G-BP-37 *(RESOLVED 2026-07-13 per user confirmation, not traced to a conversion-side fix this session)* | existing |
| 30 | ATP-11050 | Business details — mining equipment services Clarity outputs value when "No" | G-BP-95 *(FIXED LIVE 2026-07-13, verified live against this ticket's own example P00034499 — IsMiningEquipmentServices/VehicleTurnoverDetails_Mine/Display_Mine now return 'No', 0, 0 exactly)* | split from G-BP-35 |
| 31 | ATP-11048 | Business details — Clarity differs from UI (Q0114162/P00017474) | G-BP-35 *(assigned to policy team 2026-07-13, not yet root-caused on the conversion side)* | existing |
| 32 | ATP-11047 | Business details — turnover/staff/year populate when ANZSIC=222222 | G-BP-35 | existing |
| 33 | ATP-11017 | CM details — Fuel Type, CMRB Power, CMRB Trackrear broken | G-BP-10 | existing |
| 34 | ATP-11005 | CM details — Add accessories/modifications broken | G-BP-09 *(RESOLVED 2026-07-13 per user confirmation, not traced to a conversion-side fix this session)* | existing |
| 35 | ATP-11004 | CM details — Incorrect Import Type | G-BP-08 *(RESOLVED 2026-07-13 per user confirmation, not traced to a conversion-side fix this session)* | existing |
| 36 | ATP-11003 | CM details — Excess Waiver for Glass wrong in Clarity | G-BP-32, G-BP-90 *(fixed 2026-07-12 — likely root cause: SEQ62/63's composite key had no VEHICLEID, so ExcessWaiverForGlass and every other sub-coverage flag could bleed from a different vehicle sharing the same policy/location; see `seq62-67_cv.md`)* | existing |
| 37 | ATP-11002 | CM details — Incorrect RB Body Type | G-BP-07 | existing |
| 38 | ATP-10998 | Business details Q0113196 — 1st Sept batch | G-BP-35 | existing |
| 39 | ATP-10980 | Additional Interest — data missing/incorrect | G-BP-16 (16a/16c fixed live, verified 2026-07-10 — see P00010027/Q0114947 screenshot cross-check 2026-07-13) + G-BP-93 (16b's line-tied population, root-caused and fixed 2026-07-13, drafted, not yet applied) | existing |
| 40 | ATP-10979 | Schedule clause reference template missing in DC UI | G-BP-38 | existing |
| 41 | ATP-10972 | CM reoccurring adjustment on vehicles not in PURE | G-BP-39 | existing |
| 42 | ATP-10960 | BG Theft Limit NZ incorrect | G-BP-01 | existing |
| 43 | ATP-10958 | Business Protection screen — effective/expiration date wrong | G-BP-40 | existing |
| 44 | ATP-10956 | MY "Location of money outside business hours" → "Other" at $0 | G-BP-05 | existing |
| 45 | ATP-10952 | EN Voluntary Excess not returning a value | G-BP-52 | **closed 2026-07-11 — does not reproduce (checked live view + latest stored target, 0 mismatches out of 6,000+; symptom predates 2026-07-09 load)** |
| 46 | ATP-10950 | BG Contents/Stock/Employee Tools Limit populates at 0 | **G-BP-51** | **new** |
| 47 | ATP-10949 | BC Contents Limit populates at 0 | G-BP-74 | **resolved 2026-07-11 — superseded by ATP-10775 (Highest priority, requires a $30,000 minimum, opposite direction from this ticket's original complaint); fix drafted `fixes/G-BP-76_fix.sql` (SEQ 50 side) + `fixes/G-BP-02_fix.sql` Step 2 (SEQ 53 side), not yet applied (prior "already fixed live" note in this row was inaccurate — verified live 2026-07-11, the fix was actually still commented out)** |
| 48 | ATP-10947 | BC Landslide Limit incorrect vs UI | G-BP-02 | **fixed 2026-07-11, drafted, 67.3% of NZ records confirmed mismatched — `fixes/G-BP-76_fix.sql`** |
| 48b | ATP-10947 (client comment) | BC duplicate BCLND_SD coverage entry, policy P00010139 | **G-BP-76** | **new — client-confirmed root cause: `RISK_BUILDING_BC_COVERAGES` has no active-term filter, returns both an expired-term and current-term row for every sub-coverage on any policy with more than one staging record (24.9% of BC policies). Fixed `fixes/G-BP-76_fix.sql`. Same missing-filter shape flagged in BI/BG/EN/Money sibling views, not yet fixed.** |
| 49 | ATP-10946 | BC Flood Taken/Not Taken incorrect | G-BP-03 | **closed 2026-07-11 — 0 current live impact, ticket's example not reproduced (stale batch); robustness fallback added anyway** |
| 50 | ATP-10937 | Location details — UW Questions from Templates incorrect | **G-BP-61** | **new** |
| 51 | ATP-10906 | Renewal — Contribution summary/payment frequency tabs missing (quoted status) | **G-BP-64** | **new** (LOB not fully confirmed) |
| 52 | ATP-10904 | Renewal — S.14 Customer Vehicles Hail/Malicious Damage Excess not populating | **G-BP-65** | **new** — reclassified 2026-07-11: no Pure source anywhere in the SP, manuscript shows it's DC-side-synced from Building BC Theft, needs client clarification for a value. Separate casing bug (`HailandMaliciousDamage`→`HailAndMaliciousDamage`) found and fixed live same day — see `seq24-26_customervehicles.md` |
| 53 | ATP-10903 | Renewal — Locations validated in PURE not validating in DC | **G-BP-66** | **new** (LOB not fully confirmed) |
| 54 | ATP-10845 | PPL Contractors/Subcontractors limit not in Clarity | G-BP-19 | existing — traced 2026-07-11, no conversion-side defect found, see `seq09-11_publicproductliability.md` |
| 55 | ATP-10843 | PF "Is Previous PF in place" incorrect | G-BP-21 | existing — **fixed live 2026-07-11, ticket resolved/closed**, see `seq12-14_professionalprotection.md` |
| 56 | ATP-10842 | SV "Is Windscreen Glass Excess Taken" incorrect | **G-BP-62** | **new** — real cause found 2026-07-11 (blank GLS_SD limit, not the indicator), fix ready but **blocked on client/DC confirmation of $500/$1,000 constants** before deploying, see `seq21-23_stockvehicles.md` |
| 57 | ATP-10808 | Tyre question not coming through | G-BP-35 | existing |

## 2. Excluded — confirmed PP, not BP

| # | Ticket | Summary | Reason |
|---|---|---|---|
| — | ATP-11112 | PP — Private Motor age of regular driver increased | "PP" explicit, Private Motor = Personal Package |
| — | ATP-11111 | PP — Private Motor not generating contribution amounts | same |
| — | ATP-11110 | PP — Location 1 property sections missing from migration | same |
| — | ATP-11107 | PP — Specified Items Away from the Premises | same |
| — | ATP-11106 | PP — Unspecified Items Away from the Premises | same |
| — | ATP-11105 | PP — Building Construction rewired/replumbed dates | same |
| — | ATP-10965 | Renewal — PP — PURE Motor Only migrating with Location sections | "PP" explicit |
| — | ATP-10963 | Renewal — PP — Personal motor vehicles failing to transfer | already excluded in prior register pass |
| — | ATP-10962 | Renewal — PP — Legacy start date incorrect | "PP" explicit |
| — | ATP-10961 | Renewal — PP — Account handler default incorrect | "PP" explicit |

## 3. New gaps created this pass (16)

| Gap ID | Area | One-line |
|---|---|---|
| G-BP-51 | SEQ 38, BG Contents/Stock/Employee Tools | Companion to G-BP-01, same script, believed already correct as scripted |
| G-BP-52 | SEQ 47/49, EN Voluntary Excess | Not yet traced to root cause |
| G-BP-53 | SEQ 61, Fleet RB Vehicle Key | Instance of G-BP-48 (missing column) |
| G-BP-54 | SEQ 61, Fleet Market Value w/o Accessories | Instance of G-BP-48 (missing column) |
| G-BP-55 | SEQ 61, Fleet Make & Model | Instance of G-BP-48 — key evidence for which XML node DCT actually reads |
| G-BP-56 | SEQ 67, CM Overridden Vehicles | Possible PP-PR-04-style override-fallback gap, needs SAS check |
| G-BP-57 | SEQ 67, CM Market Value w/o Accessories | Token IS wired — wrong value, not missing field |
| G-BP-58 | SEQ 67, CM Agreed Value w/o Accessories | Missing column, same pattern as G-BP-10 |
| G-BP-59 | SEQ 67, CM Induction Type override edge case | Narrower than the general InductionType gap |
| G-BP-60 | Business Details, Management/Proprietors/Partners | Provisionally folded into G-BP-35's cluster |
| G-BP-61 | Location details, UW Questions from Templates | Candidate same root cause as G-BP-06 |
| G-BP-62 | SEQ 23, SV Windscreen Glass Excess Taken | Token already dynamic — bug is in source derivation |
| G-BP-64 | Renewal, Contribution/payment tabs | LOB not fully confirmed |
| G-BP-65 | SEQ 26, S.14 Customer Vehicles Hail/Malicious Damage Excess | Confirmed empty tag from full-67 sweep |
| G-BP-66 | Renewal, Location override | LOB not fully confirmed |

All 16 are written into `docs/bp_mapping/README.md`'s P1/P2 tables (not duplicated here — this file
is the ticket-facing crosswalk, README is the gap-facing register).

## Notable cross-checks surfaced by this pass

- **G-BP-48 gained 3 new client-reported confirmations** (ATP-11134 Make/Model, ATP-11130 RB
  Vehicle Key, ATP-11129 Market Value w/o Accessories) on top of ATP-11127 (Fuel/Import/Power/
  TrackRear) already known — 4 independent tickets now point at the same SEQ 61 view gap. Make/Model
  being broken specifically (G-BP-55) is the strongest evidence yet that DCT reads Fleet vehicle
  identity from the `<risk>` node, not the working nested `<Vehicle>` node — worth escalating this
  gap's investigation priority.
- ~~G-BP-49 (Runoff Liability hardcoded inactive) has a plausible client-reported symptom
  (ATP-11068)~~ — **retracted 2026-07-11.** Checked against the SP and the client's original SAS:
  both exclude any Runoff Liability policy from the entire BP conversion extraction upstream, so
  `RUF_SD`'s hardcoded `Indicator=0` is always correct for every record that reaches SEQ 11.
  ATP-11068 is filed against the Business Details screen's own "run-off" concept, unrelated to
  PPL's Runoff Liability sub-coverage — still open, untraced, tracked only under G-BP-35.
- **G-BP-65 confirms another full-67-sweep empty-tag finding** (SEQ 26's `HailandMaliciousDamage`)
  against a real client ticket — second such confirmation after G-BP-48/55, suggesting the empty-tag
  sweep is a good leading indicator worth trusting for future tickets.
