# Seq 3 — Account Location (`location`)

| | |
|---|---|
| **Script name** | ACC_LOC |
| **Source view** | `AGGNE.DEV.PER_ACCOUNT_LOC` |
| **Target** | `AGGNE.DEV.PER_ACCOUNT_LOC_TARGET` |
| **Lineage** | `PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_RiskSelection` (RL* address/state fields) → `Locationdetails_PER` (staging, Pure-to-Write SP) → view → template → target |

## Template (live PP_ConversionConfig)

```xml
<location>
  <Number>{RISKNUMBER}</Number>
  <address>
    <State>{STATE}</State>
    <Address1>{ADDRESS1}</Address1>
    <Address2></Address2>
    <City>{SUBURB}</City>
    <ZipCode>{POSTCODE}</ZipCode>
    <Country>{LOC_COUNTRY}</Country>
  </address>
  <GeocodeStatusDisplay>Unverified</GeocodeStatusDisplay>  <!-- hardcoded -->
  <LocationType/>
  <BusinessType/>
  <AddressOverride>1</AddressOverride>                     <!-- hardcoded -->
</location>
```

## Field matrix (XML-path driven)

| XML Path | DCT Expects | View Transform | Staging / SAS Logic (Pure) | Gap |
|---|---|---|---|---|
| `location/Number` | required | {RISKNUMBER} — source value preserved (not ROW_NUMBER) | Locationdetails_PER.RISKNUMBER ← PER_RiskSelection | OK |
| `location/address/State` | required, state code list | {STATE} — AU: STATE\|\|'AU'; NZ: raw | Locationdetails_PER ← PER_RiskSelection.RLState | CONFIRM code form |
| `location/address/Address1` | required | {ADDRESS1} pass-through | Locationdetails_PER ← RL address | OK |
| `location/address/Address2` | optional | empty — no source column | — | EMPTY |
| `location/address/City` | required | {SUBURB} pass-through | Locationdetails_PER ← RL suburb | OK |
| `location/address/ZipCode` | required *(Package_Data 54880)* | {POSTCODE} cast varchar | Locationdetails_PER ← RL postcode | VQ blanks |
| `location/address/Country` | required, country code | {LOC_COUNTRY} — New Zealand→NZ, Australia→AU | Locationdetails_PER ← insurance_file.Country | OK |
| `location/GeocodeStatusDisplay` | display field | hardcoded "Unverified" | — | BY DESIGN |
| `location/LocationType` | optional | empty — no source column | — | EMPTY |
| `location/BusinessType` | optional | empty — no source column | — | EMPTY |
| `location/AddressOverride` | boolean *(Package_Data 54909)* | hardcoded "1" — converted addresses never pass DC validation | source OVERRIDE column intentionally ignored | DECISION MADE |


## Gaps

- No new code gaps. One confirmation item: the `STATE+'AU'` concatenation (`NSWAU`) — verify the state-code form against a working DCT quote once, then close. Blank-postcode/state counts: `seq03_vq.sql`.
- Note: `AddressOverride=1` is a recorded client/QA decision (all converted locations), same pattern as vehicle `Override=1` in seq 18 — listed here so the client sees the full set of forced-override decisions in one place.

## Validation queries

See [`seq03_vq.sql`](vq/seq03_vq.sql).
