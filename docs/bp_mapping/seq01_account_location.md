# SEQ 1 — BP_ACC_LOC (Account Location)

**Source view:** `AGGNE.DEV.ACCOUNT_LOC` (11 columns) &nbsp;·&nbsp; **Target:** `ACCOUNT_LOC_TARGET`
**Upstream staging:** `AGGNE.DEV.location_01` (78 columns, built by the shared Pure-to-Write SP)

**Client tickets:**

| Ticket | Summary | Field | Notes |
|---|---|---|---|
| **ATP-10587** | "136 policies mismatch on suburb and postcode... address does not match DC address database" | `SUBURB`, `POSTCODE` (both `ACCOUNT_LOC` output columns) | **Resolved and closed** (2026-07-10, per user). Root cause not captured on our side — closed outside this investigation, no fix applied from this register. Reported 2026-05-15 by Jilna Rajesh, no assignee — not present in either ATP-10219 export used to build this register. |

**Scope caveat:** finding this ticket only by accident means the other 66 SEQ rows in
`SEQ_VS_ISSUES.md` may also be missing unassigned or differently-assigned tickets — that register
was built entirely from the two assignee-filtered ATP-10219 exports. Not re-auditing all 67 rows
against the full unfiltered epic yet, but flagging it as a known gap in the register's coverage.

---

## All 13 originally-empty template fields, resolved

| Field | Verdict | Fix location | Status |
|---|---|---|---|
| **Address2** | Real gap | **View + Config** | **Fixable now — code only.** `location_01` has `ADDRESS2` with data (built by the SP); `ACCOUNT_LOC` never selects it; config template has bare `<Address2/>`. See `fixes/G-BP-67_fix.sql`. |
| FloodExtremeRisk | Not a gap | — | DC self-computes. See below. |
| BushfireExtremeRisk | Not a gap | — | DC self-computes. |
| CycloneExtremeRisk | Not a gap | — | DC self-computes. |
| EarthquakeExtremeRisk | Not a gap | — | DC self-computes. |
| BushfireRate | Not a gap | — | DC self-computes. |
| CycloneRate | Not a gap | — | DC self-computes. |
| EarthquakeRate | Not a gap | — | DC self-computes. |
| StormRate | Not a gap | — | DC self-computes. |
| BurglaryRate | Not a gap | — | DC self-computes. |
| Latitude | Unresolved | Potentially **SP + View + Config** | See "Unresolved" below. |
| Longitude | Unresolved | Potentially **SP + View + Config** | See "Unresolved" below. |
| LocationType | Unresolved | Not yet located in manuscript | See "Unresolved" below. |

---

## 1. Address2 — fixable now (View + Config, no SP change needed)

**Procedure (SP) — already correct, no fix needed.** `location_01` is built by
`DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql`'s Locationdetails section (~line 3846–4422) and
already carries `ADDRESS2` with real Pure data — confirmed live, 2026-07-09. The SP does its job
here; the gap is entirely downstream.

**View fix required.** `AGGNE.DEV.ACCOUNT_LOC` selects only 11 of `location_01`'s 78 columns and
`ADDRESS2` isn't one of them. Add it to both CTEs and the final `SELECT`/column list.

**Config fix required.** SEQ 1's `ConversionScript` has `<Address2/>` as a bare tag with no token.
Needs `<Address2>{ADDRESS2}</Address2>`.

Full script: `docs/bp_mapping/fixes/G-BP-67_fix.sql` — includes the exact view DDL edit, the
whitespace-agnostic `REPLACE`-based config UPDATE, and before/after verification queries.

---

## 2. The 9 PropertyRiskProfile fields — not our bug, no fix

**Manuscript proof** (`Manuscripts/.../CarrierBusinessProtectionPackage/CW-INH/Carrier_BusinessProtectionBase_1_0_0_0.xml`,
object `LocationPrivate.SetPropertyRiskDataToFalse`, comment *"ATP-9994 Created field to set
PropertyRiskProfile group to null when address is modified"*):

DC itself resets `PropertyRiskProfile.BurglaryRate`, `.BushfireExtremeRisk`, `.BushfirePostCodeRate`,
`.BushfireRate`, `.CycloneExtremeRisk`, `.CyclonePostCodeRisk`, `.CycloneRate`,
`.EarthquakeExtremeRisk`, `.EarthquakePostCodeRisk`, `.EarthquakeRate`, `.Elevation`,
`.FloodExtremeRisk`, `.FloodPostCodeRisk`, `.FloodRate`, `.GnafCheck`, `.LandSqm`,
`.RoofConstruction`, `.RoofSqm`, `.StockVehiclePostCodeRisk`, `.StormRate` — the entire group —
to null whenever the address (or `GNAFID`) changes, then presumably repopulates it via its own
internal geocoding/risk-scoring service call. This is a DC-side, post-import workflow. **Sending
these fields blank from conversion is correct behavior**, not a defect.

**No fix — SP, View, or Config.** Nothing to change here. (Logged as G-BP-68, status "reviewed, no
fix recommended.")

---

## 3. Latitude, Longitude, LocationType — unresolved, not yet actionable

**Manuscript check** (`Carrier_Package_Data_CW_1_0_0_0.xml`): `LocationInput.Latitude` and
`LocationInput.Longtitude` (note — the manuscript's own field is misspelled "Longtitude", not
"Longitude"; worth checking whether that typo is also DC's actual expected XML tag name, since a
spelling mismatch alone would blank the field regardless of any fix) are defined as plain string
inputs with **no `readOnly` tag and no `value` formula** — unlike the PropertyRiskProfile group,
these are NOT flagged as DC-computed. They also aren't in `SetPropertyRiskDataToFalse`'s reset list.
That suggests real data is expected here, in principle.

**But:** `location_01` (78 columns, live-checked) has no `LATITUDE`, `LONGITUDE`, or `LOCATIONTYPE`
column at all — meaning if this data exists in Pure, the SP's Locationdetails section never pulls
it. Unlike Address2 (data exists upstream, just not selected downstream), this would require an SP
change (add the source column to `location_01`'s build), not just a view/config change — assuming
Pure has the data at all.

**Not yet checked:**
- Whether any `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.*` table (beyond what feeds `location_01`
  today) carries a lat/long or location-type field for BP locations.
- `LocationType`'s exact manuscript definition — grep for `id="LocationInput.LocationType"` (or
  similar) hasn't been run yet; `BUSINESSTYPE` exists in `location_01` but is a different concept
  (already used for the ANZSIC mapping), not location type.
- Whether the manuscript's "Longtitude" spelling is genuinely what DC expects on the wire, or just
  a typo in the manuscript's own internal field id that doesn't affect the actual XML tag name.

**Status:** Open, blocked on further investigation (not a business decision — a data-source and
manuscript-detail question). Not drafted as a fix yet; don't want to guess at a Pure source table
or assume the "Longtitude" spelling matters without confirming it against the actual DC xpath.

---

## 4. AddressVerified — missing entirely, config-only fix

**Not one of the original 13 empty-tag findings** — this field isn't even present in the template,
so the mechanical sweep (which only catches empty *tags*) missed it. Found while reviewing the
`SetPropertyRiskDataToFalse` manuscript block for G-BP-68 and noticing its paired trigger,
`LocationPrivate.SetAddressVerifiedToFalse`.

**Manuscript** (`Carrier_Package_Data_CW_1_0_0_0.xml`, `LocationOutput.AddressVerified`, DC xpath
`data/account/location/AddressVerified`):
```xml
<public id="LocationOutput.AddressVerified" path="AddressVerified" type="boolean">
  <definition><caption value="Address Verified" /></definition>
  <rules><default value="0" /></rules>
</public>
```
Same ATP-9994 family as the PropertyRiskProfile reset (G-BP-68) — tracks whether DC's own
address-verification/geocoding workflow has completed. Defaults to `0` (unverified); DC's own
process presumably flips it once verification succeeds.

**Fix — config-only, no view or SP change, no client decision. Applied and verified live 2026-07-10.**
`<AddressVerified>0</AddressVerified>` now sits between `<AddressOverride>1</AddressOverride>` and
`<LocationAddressTaken>` in the live Azure template — confirmed by re-querying
`Capricorn-Dev-SwiftConversion.dbo.ConversionConfig` after the user ran
`docs/bp_mapping/fixes/G-BP-69_fix.sql`.

---

## Summary — SEQ 1 fixability

| Fix type | Count | Fields |
|---|---|---|
| **SP fix needed** | 0 confirmed (Address2's SP layer is already correct) | — |
| **View + Config fix, ready now** | 1 | Address2 |
| **Config-only fix, applied & verified live** | 1 | AddressVerified |
| **No fix — confirmed correct as-is** | 9 | PropertyRiskProfile group |
| **Needs more investigation (possibly SP+View+Config once resolved)** | 3 | Latitude, Longitude, LocationType |
| **Resolved/closed, no fix from this register** | 1 | ATP-10587 (Suburb/Postcode mismatch) |
| **New ticket, verified NOT a conversion bug** | 1 | ATP-11145 (GNAF not showing in UI) |

## ATP-11145 — GNAF not showing on UI (verified 2026-07-10, not our bug)

*"None of the GNAF is showing on UI however clarity has values... GNAF values match in PURE and DC
but not showing in UI."* Policies: P00000018, P00009311, P00009491, P00009609, P00009659.

Checked all 5 policies live, `LOCATION_01` → `ACCOUNT_LOC`: every one has a real, correctly-formatted
`GNAFPID` in Pure staging, passed through unchanged to the SEQ 1 view/token. Our pipeline is correct
at every stage. The client's own description ("matches in PURE and DC, not showing in UI") confirms
this — it's a Duck Creek UI rendering issue, not a mapping/conversion defect. Possible connection
(unproven): DC's `SetPropertyRiskDataToFalse` trigger (ATP-9994, same mechanism as G-BP-68/69) nulls
`GNAFID`/`GnafCheck` until its own address-verification pass completes — worth mentioning to the
client's DC team, not something fixable from the conversion side.
