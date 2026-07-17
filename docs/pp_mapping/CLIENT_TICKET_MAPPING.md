# Client Ticket ↔ Gap Register Mapping

Cross-reference of the client-reported Jira tickets under epic **ATP-10219** (folder
`files/Issues/Conversion/`) against our PP gap register (`VALIDATION_RULES.md` / G-01...G-39).

Source files:
- `ATP-10219_Policy_Conversion_Defects.html` — 60 child issues, exported 2026-07-06
- `ATP-10219-Open-Tickets (1).html` — 67 open tickets assigned to Raju Kallepelli & saichand patha, generated 2026-07-09

**Scope filter applied:** tickets labeled "CM details", "Fleet Details", "Business details screen",
or "Location coverages BG/BC/BB/MY/EN" are Commercial/Business Package (BP) scope, not this
register (PP-only, per established project scope). They're counted but not itemized below.

- BP-scope tickets excluded: 44 (across both files, deduped)
- PP-scope tickets found: 16 (deduped)

---

## 1. Already mapped to an existing gap

| Ticket | Summary | Status | Gap(s) | Note |
|---|---|---|---|---|
| **ATP-10963** | Renewal - PP - Personal motor vehicles failing to transfer | Backlog | **G-02, G-03, G-05, G-06, G-09, G-10** | This is the original client ticket behind the whole Override-gating / PR-04 investigation (per `project_pp_field_bugs.md`). G-02 already fixed & deployed (2026-07-09). G-03/G-05 emailed, awaiting client. G-06/G-09/G-10 drafted, pending SP deployment (Section 3 of `DEPLOYMENT_CHECKLIST.md`). **This ticket should not close until all 5 remaining pieces are done.** |

## 2. Related to an existing gap, but describes a different symptom — verify before assuming same fix

| Ticket | Summary | Status | Related gap | Why it's not a clean match |
|---|---|---|---|---|
| **ATP-11112** (new since 07-06) | PP - Private Motor section - age of regular driver **has increased** | Backlog | G-11 (AgeOfYoungestRegularDriver 16 vs 17 threshold) | G-11 is about a blank/16-vs-17 *minimum* value at initial conversion. This ticket describes age *increasing*, which sounds like a renewal/re-conversion recompute issue, not the same root cause. Needs its own check against renewal-batch data before merging into G-11. |
| **ATP-10842** | SV 'Is Windscreen Glass Excess Taken' incorrect in Clarity | In Progress | G-37 (Motor Coverage Selections — includes "Unlimited Glass") | G-37's email covers whether the *Unlimited Glass* coverage indicator is selected; this ticket is about a separate "Windscreen Glass Excess" flag, which may or may not be sourced from the same PURE field. Needs its own look at the view before folding into G-37. |

## 3. Genuinely new — validated, became G-40...G-46

| Ticket | Summary | Gap |
|---|---|---|
| **ATP-11107** | PP - Specified Items Away from the Premises not migrated | G-40 |
| **ATP-11105** | PP - Building Construction - Rewired and Replumbed dates not migrated | G-41 |
| **ATP-11111** | PP - Private Motor section not generating contribution amounts | G-42 |
| **ATP-11110** | PP - Location 1 property sections missing from migration | G-43 |
| **ATP-10961** | Renewal - PP - Account handler default incorrect | G-44 |
| **ATP-10962** | Renewal - PP - Legacy start date incorrect | G-45 |
| **ATP-10965** | Renewal - PP - PURE Motor Only protections migrating with Location section(s) selected | G-46 |

## 4. Checked, found not to be a bug

| Ticket | Summary | Finding |
|---|---|---|
| **ATP-11106** | PP - Unspecified Items Away from the Premises not migrated | Investigated alongside G-40 — the flag and its limit bands are actually populated correctly (400/1,831 "Taken" with correct values). No gap needed. |

## 5. Confirmed BP scope, not PP — closed, no gap number

Checked directly against the Personal PP manuscripts (`Carrier_PP_CW_Data`, `Carrier_PP_CW_VM`,
`Carrier_PP_AU_Rating`, etc.), not assumed from ticket labels.

| Ticket | Summary | Evidence |
|---|---|---|
| **ATP-10845** | PP 'Contractors and Subcontractors' limit not coming through in Clarity | Traces to `PublicProductLiabilityInput`/`ProfessionalProtectionInput` — Business Package fields |
| **ATP-10841** | PP 'Is Type Standard' incorrect in UI + Clarity | Every hit is `PublicProductLiabilityInput.ProtectionTypeStandard` — Business Package |
| **ATP-10808** | Tyre question not coming through in UI + Clarity | Every "Tyre" reference in Personal manuscripts is `BusinessInformationInput.IsTheSaleOfSecondHandTyresConducted` / `ShowTyreDealerUWQuestions` / rate-table codes (`TYREHEAVY`, `TYREIMPORT`, etc.) — Business Information tyre-dealer UW questions, not a Personal Motor tyre condition |
| **ATP-10844** | PF 'Is Vehicle Assessment/Breakdown Protection Taken/Not' incorrect | Zero matches anywhere in the Personal package manuscripts |
| **ATP-10843** | PF 'Is Previous PF in place' incorrect in UI + Clarity | Zero matches anywhere in the Personal package manuscripts |

---

## Summary

- **1 ticket** (ATP-10963) directly explains 6 existing gaps (G-02, G-03, G-05, G-06, G-09, G-10) — already fully accounted for.
- **2 tickets** (ATP-11112, ATP-10842) look related to existing gaps (G-11, G-37) but describe different symptoms — not merged in, need their own check before assuming same fix.
- **13 tickets** were genuinely new: 7 became gaps G-40...G-46, 1 was checked and found not to be a bug, 5 confirmed BP scope and closed.

All 13 are now resolved one way or another — nothing left "scope-uncertain" from this cross-reference.
