# SEQ 3 — BP_account_info_claim_history (Claim History)

**Source view:** `AGGNE.DEV.VW_CLAIM_HISTORY` &nbsp;·&nbsp; **Target:** `CLAIM_HISTORY_TARGET`
**Upstream staging:** `AGGNE.DEV.CLAIMHISTORY`, joined to `AGGNE.DEV.SAMPLE_CBP`

**Client tickets:** none found — checked both ATP-10219 exports and the broader unfiltered search
used for SEQ 1/2. No open or historical ticket mentions Claim History, Loss History, or Date of
Claim.

---

## Manuscript check

DC's `LossHistory`/`ClaimInformationInput` object (`Carrier_Package_Data_CW_1_0_0_0.xml`, path
`losshistory` — matches our template's node name exactly):

- **`ClaimInformationInput.Line`** — required, exactly 3 options: `Property`, `Liability`, `Motor`.
- **`ClaimInformationInput.Cause`** — required, **conditionally validated on Line**
  (`ClaimInformationPrivate.IsLineMotor`/`IsLineLiability`/`IsLineProperty`):
  - Line=Motor → `AtFault`, `NotAtFault`, `Theft`, `Other`
  - Line=Liability → `CustomerPropertyDamage`, `CustomerInjury`, `Other`
  - Line=Property → `Fire`, `Flood`, `Burglary`, `Other`
  - (9 canonical values total across all three sets)
- **`ClaimInformationInput.DateOfClaim`** — required, `type="date"`, `maximum=DateTime.CurrentDate`.
- **`ClaimInformationInput.AmmountPaid`** — required, `type="float"` (note: "Ammount" is DC's own
  spelling, not a typo in our template).

The view already carries a comment referencing a prior fix (`FIX US-5977`/ATP-8656) that mapped
`CAUSE` from raw PURE text to DC's PascalCase codes — this was done correctly and completely.

## Data (live, 2026-07-10)

| Check | Result |
|---|---|
| Total rows | 4,815 |
| `LINE` — invalid/unmapped values | **0** (all 3 values present, all valid: Motor 1,912 / Liability 1,753 / Property 1,150) |
| `CAUSE` — distribution | Other 3,301, AtFault 550, CustomerPropertyDamage 543, Burglary 233, Theft 92, Flood 52, Fire 41, CustomerInjury 3 — all within DC's 9 canonical values |
| `LINE` × `CAUSE` cross-field violations (Motor cause on non-Motor line, etc.) | **0** |
| `DATEOFCLAIM` blank/unparseable | **0 of 4,815** |
| Raw `CLAIMHISTORY` → `VW_CLAIM_HISTORY` | 10,936 → 4,815 (expected — view intentionally scopes to `EXPIRYDATE >= '2026-01-01'`, documented in the view's own inline comments) |

## Findings

**No active bugs.** The US-5977 Cause fix is complete and correct — verified against DC's full
canonical enum, including the conditional Line-dependent validity rule (zero cross-field
violations in live data). DateOfClaim's defensive date-parsing is a no-op today, same latent
pattern PP found in their own G-15 (not a live risk, worth knowing if the source ever becomes free
text again).

**One latent structural risk, not a current bug:** `LINE` is a raw passthrough with no `CASE`
mapping or fallback — it happens to be 100% clean today because Pure only ever produces exactly the
3 values DC expects, but there's no defense if a 4th value ever appears (would pass through
unvalidated to DCT). Not worth a proactive fix given zero live impact; flagging so it isn't
mistaken for "checked and safe by design" if this view is revisited later.

**Status:** No gap opened for SEQ 3. Clean.
