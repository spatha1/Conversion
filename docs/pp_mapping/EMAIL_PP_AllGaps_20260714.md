# PP Conversion — Complete Gap List (All Sources, All Statuses)

Every gap identified in the Personal Package (PP) conversion to date, regardless of status.
Compiled from cross-referencing four sources throughout this project: the legacy **SAS**
conversion scripts, the **Pure-to-Write** source data/procedure, **PL101** field specifications,
and the DCT **Manuscript** (Carrier_PersonalProtectionBase and related XML schemas). Status as of
2026-07-14.

**Status key:** ✅ Deployed & Verified · 🟡 Ready (drafted, no blocker) · 🔵 Awaiting Client ·
🟠 Awaiting Policy Team · 🔬 Investigating · 🚫 Blocked (needs scope decision) · ⚪ Closed (no
action needed)

---

## Summary

| Status | Count |
|---|---|
| ✅ Deployed & Verified | 14 |
| 🟡 Ready to deploy | 10 |
| 🔵 Awaiting client confirmation | 17 |
| 🟠 Awaiting policy team input | 2 |
| 🔬 Investigating | 4 |
| 🚫 Blocked (scope decision needed) | 1 |
| ⚪ Closed (false positive / by design) | 7 |
| **Total gaps tracked** | **55** |

---

## ✅ Deployed & Verified

| Gap | Seq/Area | ATP | Description |
|---|---|---|---|
| G-13 | 18 – Motor | — | Config fix, motor risk template |
| G-16 | 1 – Claim History | — | View fix |
| G-18 (HB) | 4 – HB Sub-Coverages | — | Landlord protections view fix |
| G-18 (HC) | 10 – HC Sub-Coverages | — | Same fix, HC side |
| G-21 (×6) | Seq 6/8/9/12/14 | — | XML escaping/empty-item filter, 6 instances |
| G-22 | 7 – Risk Building HB | — | Config fix |
| G-25 (×2) | 7, 13 | — | Config fix, HB and HC |
| G-27 | 9 – HC Specified Contents | — | Empty-item filter |
| G-28, G-29, G-30, G-31, G-32 | 13 – Risk Building HC | — | Config fixes |
| G-39 (view part) | 17 – Motor Clauses | — | View fix |
| G-20 | 5 – HB UW Adjustments | — | HB UW adjustments were reading BP-scoped source (0% overlap with PP) — repointed to correct PP source; real payload now shows 254 real adjustments (was 0) |
| G-47 | 4, 10 – Sub-Coverages | — | Template hardcoded `<Indicator>1</Indicator>`, ignored the view's real value — fixed |
| G-49 | 3 – Account Location | ATP-11110/11117/11115 | HB_02/HC_02 snapshot tables weren't refreshed on location/term changes — rebuilt; P00010162 and others now resolve correctly |
| G-50 | Cross-cutting (final load) | related ATP-11089/11042 | `Adjustments_PER_Out` join used `=` on `Vehicle_ID`, silently failing for all non-vehicle coverage (NULL=NULL) — fixed; recovered 596 real adjustment amounts (HC/HB/SU) |
| G-DUP-01 | Cross-cutting (final load) | — | Duplicate `PER_FINAL`/DCT rows from unresolved payment-plan history — fixed; 72 duplicated policies → 1 residual (99.97% resolved) |
| G-51 | 18 – Motor (client CR) | — | New Pure-to-Write fields (FuelType/PowerKW/TrackRear) wired to real XML tags — DEV only, UAT pending source columns |
| ATP-10842 | 15 – Motor Sub-Coverages | ATP-10842 | Windscreen Glass Excess hardcoded to always "Taken" — fixed via real driver field, corrected after a regression was caught and resolved |
| ATP-11111 (G-42) | 18 – Motor | ATP-11111 | Motor Premium always $0 — join key mismatch fixed |

---

## 🟡 Ready to deploy (drafted, live-verified, no blocker)

| Gap | Seq/Area | ATP | Description |
|---|---|---|---|
| G-02 | 18 – Motor | ATP-10963 | BodyType/etc. Override-gating — corrected fix ready |
| G-03 (part 1) | 18 – Motor | ATP-10963 | BodyType blank for 97.4% of vehicles without a RedBook override |
| G-05 (parts 1a/1b) | 18 – Motor | ATP-10963 | NumberOfCylinders COALESCE-to-0 removal |
| G-06/G-09/G-10 | 18 – Motor | ATP-10963 | InductionType/ImportFlag/EngineSize/GrossVehicleMass/DriveDescription — 89% of vehicles affected |
| G-08 | 18 – Motor | — | RegistrationNumber formatting cleanup |
| G-12 | 18 – Motor | — | VehicleType allow-list hardening (0 live impact today) |
| G-15 | 1 – Claim History | — | Validation-rule addition, no live defect |
| G-39 (SP part) | 17 – Motor Clauses | — | Remove forced-uppercase on clause description (175 rows) |
| G-44 (symptom fix) | Cross-cutting | ATP-10961 | Removes misleading "Aaron Pang" default — root cause still open, see below |
| G-41 | 14 – Risk Building | ATP-11105 | Rewired/Replumbed backwards CASE statement discarding 787 real years — fix drafted |

---

## 🔵 Awaiting client confirmation

| Gap | Seq/Area | ATP | Question |
|---|---|---|---|
| G-01 | 18 – Motor | — | NZ State value handling |
| G-03 (part 2) | 18 – Motor | ATP-10963 | Unmapped BodyType values — list grows once part 1 deploys |
| G-05 (part 2) | 18 – Motor | ATP-10963 | 512 genuinely cylinder-less vehicles — omit the tag or not? |
| G-07 | 18 – Motor | — | VoluntaryExcess banding (9 vehicles) |
| G-11 | 18 – Motor | — | Age threshold 16 vs 17 (2 vehicles) |
| G-23 | 7 – Risk Building HB | — | Likely false positive, bundled with G-34 |
| G-24 | 7 – Risk Building HB | — | GlassLimit reuses HOMEBUILDINGSLIMIT — intended? |
| G-26 | 7 – Risk Building HB | — | Premium double-carry, 60.3% of HB+HC policies |
| G-33 | 14 – Risk Building | — | SICCode hardcoded, 100% of 1,392 rows |
| G-34 | 14 – Risk Building | — | Bundled with G-23 |
| G-35 | 14 – Risk Building | — | 6 fabricated risk-assessment answers, 100% of rows |
| G-37 | 15 – Motor Sub-Coverages | — | Coverage-selection matrix needed; all 8 codes always on |
| G-40 | 13 – Risk Building HC | ATP-11107 | DCT node shape for itemized "away from premises" list |
| G-45 | Cross-cutting | ATP-10962 | Which DCT field is "Legacy Start Date"? No confirmed target field exists yet |
| ATP-11116 (G-48) | 18 – Motor | ATP-11116 | Motor "Imposed Excess" — no source concept exists; confirm expected blank |
| ATP-10842 (remaining) | 15 – Motor Sub-Coverages | ATP-10842 | 7 other coverage codes with the same "always-on" pattern — need exclusivity rule |
| ATP-11113 | related to G-07 | ATP-11113 | Doesn't match its own described symptom — needs a specific example |

---

## 🟠 Awaiting policy team input

| Gap | Seq/Area | Description |
|---|---|---|
| PP-CF (VehicleType default) | 18 – Motor | 32 blank VehicleType values defaulted to PassengerVehicle — pending explicit sign-off |
| Dropdown mandatory-field defaults | Location (RoofConstruction/MainWallConstruction) | 432 policies blank on both fields — Business default decision needed |

---

## 🔬 Investigating

| Gap | Seq/Area | ATP | Status |
|---|---|---|---|
| G-19 (new finding) | 5, 11, 16 – UW Adjustments | — | Non-recurring adjustments exclusion, ~60-64% |
| G-44 (root cause) | Cross-cutting | ATP-10961 | Only 16.7% of PP policies match ACCOUNT_HANDLER at all — likely a data-coverage gap |
| G-46 | Cross-cutting | ATP-10965 | Motor+Location dual-coverage pattern — investigated 2026-07-14, found overwhelmingly genuine (82% of matched rows show real PURE dual-coverage flags); small residual (<17 policies) not conclusively a bug, needs a specific client example |
| G-DUP-02 | Cross-cutting | — | `<ModNumber>10</ModNumber>` hardcoded for every policy — real DCT field, no source mapping found in SAS or Pure-to-Write yet; deferred |
| G-DUP-03 | Cross-cutting | — | 1 residual duplicate policy (P00027855), traced to upstream source-table timing volatility, not this pipeline's code — low severity (0.025%) |

---

## 🚫 Blocked (needs scope decision)

| Gap | Seq/Area | Description |
|---|---|---|
| G-38 | 17 – Motor Clauses | Needs full client-agreed clause-code mapping table — 0 of 179 codes currently valid |

---

## ⚪ Closed (false positive / by design, no action needed)

| Gap | Seq/Area | ATP | Finding |
|---|---|---|---|
| G-04 | 18 – Motor | — | False positive, already correct |
| G-17 | 2 – Prior Insurance | — | Already correct, no fix needed |
| G-19 (original claim, seq 11/16) | HC/Motor UW Adjustments | — | False positive — correctly sourced (2,995 and 429 real rows respectively) |
| G-36 | 14 – Risk Building | — | Validation-rule only, 0% invalid live |
| G-43 | 3 – Account Location | ATP-11110 | Original 235-count was a measurement error — real number is 2 of 4,006 policies |
| ATP-11123 | — | ATP-11123 | Checked live — already correct |
| ATP-11106 | — | ATP-11106 | Checked live — already correct, not a bug |

---

## Reference

Full technical detail, root-cause analysis, and deploy files for every gap above are maintained in
`docs/pp_mapping/SEQ_GAP_ATP_MASTER.md` (internal working doc — not for external distribution).
