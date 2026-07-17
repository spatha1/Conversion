# PP ATP Ticket — Validation Matrix (2026-07-16)

Every client-facing ATP ticket from `SEQ_GAP_ATP_MASTER.md`, mapped to a real policy/quote from the
46-policy DEV batch where one exists. Status is carried over from the master doc — **only "Ready" or
already-"Deployed" items will show correct behavior right now; "Awaiting client" and "Investigating"
items will still show the current (reported) symptom**, which is still useful to confirm you're
looking at the right field/state.

| ATP | Summary | Status | Legacy Policy | DEV Quote | What to test |
|---|---|---|---|---|---|
| ATP-10963 | Personal motor vehicles failing to transfer (BodyType/Cylinders/Engine/Drive/Induction/Import blank) | Mixed — several sub-gaps ready, 2 still awaiting client | P00010162 | Q0132768 | Vehicle details: BodyType, NumberOfCylinders, EngineSize, DriveDescription, InductionType, ImportType should be populated, not blank |
| ATP-11111 | Private Motor section not generating contribution amounts (Motor premium $0) | **Deployed and confirmed** (G-42, live 2026-07-15 — master doc's "Ready" status was stale) | P00026642 | Q0132787 | Motor premium should show $8,708.53, not $0 |
| ATP-11105 | Rewired/Replumbed dates not migrated | Root cause found, fix drafted (G-41), not yet confirmed deployed | P00030024 | Q0132792 | Building details: Year Last Rewired/Replumbed should show 2010, not blank |
| ATP-11105 | (same, second example) | same | P00009655 | Q0132764 | Should show 2007 for both fields |
| ATP-10961 | Account handler default incorrect ("Aaron Pang" placeholder) | Symptom fix ready; root cause still open | P00000371 | Q0132761 | Account Handler name should NOT show the "Aaron Pang" default |
| ATP-10842 | Windscreen Glass Excess incorrect | Fix redeployed after a regression fix, pending final validation | P00026642 | Q0132787 | Vehicle Excess Waiver for Glass should reflect the real per-vehicle flag, not a hardcoded value |
| ATP-10965 | Motor Only protections migrating with Location sections | Investigating — not proven, checking candidate policies | P00030024 | Q0132792 | Confirm Location/HB sections don't appear incorrectly on what should be a Motor-only policy |
| ATP-10965 | (second candidate) | same | P00017446 | Q0132771 | Same check — note this policy also has a DCT-side failure (AU PartyID), so verify import succeeds first |
| ATP-11107 | Specified Items Away from Premises not migrated | Awaiting client (DCT node shape unresolved) | P00000371 | Q0132761 | Expect this to still be wrong/missing — confirms current (reported) state, not a validation of a fix |
| ATP-10962 | Legacy start date incorrect | Awaiting client (source field still unclear) | P00000371 | Q0132761 | Expect current (likely wrong) value — no fix deployed yet |
| ATP-11110 | Location 1 property sections missing | Closed — false positive, already resolved 2026-07-10 (G-49) | P00010162 | Q0132768 | Confirm Location 1 ($906,000 HB / $202,000 HC) still resolves correctly |
| ATP-11106 | Unspecified Items Away from Premises not migrated | Closed — checked, was never actually broken | P00010168 | Q0132769 | Confirm this still displays correctly (sanity check only) |
| ATP-11112 | Age of regular driver increased (renewal) | Needs a specific policy from the client — renewal-recompute symptom, not an initial-conversion issue | — | — | **Cannot test from this batch** — ask client for the exact policy number that showed the age increase |
| ATP-10845, ATP-10841, ATP-10808, ATP-10844, ATP-10843 | Various | Confirmed BP scope, not PP | — | — | Not applicable — these are BP tickets |

## Notes

- **ATP-11111 reconciled (2026-07-16):** G-42 and yesterday's PM_01/PM_02 fix are two genuinely
  separate bugs, not duplicates — confirmed live, not assumed:
  - **G-42** = `PMEXPPREM` (the `<Premium>` tag inside seq18's vehicle `<coverage>` block) — was $0
    for 100% of rows due to a join-key mismatch (composite vs plain policy number) in
    `PER_COM_PAYLOAD`. Live-checked just now: fix is deployed (view comment dated 2026-07-15),
    `PMEXPPREM` is 100% non-zero with real varied values ($554, $5,545, $20,502, etc.). The master
    doc's "Ready to deploy" status for this was stale — it's actually done.
  - **PM_01/PM_02 fix (2026-07-16)** = `MVValueWithoutAccessories` was blank for Comprehensive Market
    vehicles, starving DCT's own rating engine of a market value, so `TotalPremium`/
    `RiskTotalPremiumsVehicle` computed $0. Different field, different mechanism, both now fixed.
- **ATP-10965 / G-46**: "Investigating" status means the overlap (Motor + HB/HC indicators both set)
  isn't confirmed as a bug yet — plenty of real customers legitimately have both Motor and Home
  cover. Treat a UI check here as data-gathering, not pass/fail validation.
- Full ATP-to-gap detail, including everything not yet client-facing, is in
  [SEQ_GAP_ATP_MASTER.md](SEQ_GAP_ATP_MASTER.md).
