# SEQ 4 — BP_Prior_INFO (Competitor / Prior Insurance Information)

**Source view:** `AGGNE.DEV.VW_CBP_COMPETITOR_INFORMATION` &nbsp;·&nbsp; **Target:** `COMPETITOR_INFORMATION_TARGET`
**Upstream staging:** `AGGNE.DEV.CBP_COMPETITOR_INFORMATION`

**Client tickets:** none found — checked both ATP-10219 exports and the broader unfiltered search.

---

## Manuscript check

`PriorInsuranceInfoInput.PriorCarrier` (`Carrier_Package_Data_CW_1_0_0_0.xml`) — **required, closed
dropdown, exactly 13 values**:
```
Allianz, CGU, Elders, GIO, MotorTradeDirect, NRMA, Other, QBE, SGIC, SGIO, Unknown, VERO, Wesfarmers
```
The view only explicitly handles one case (`'Motor Trade Direct'` → `'MotorTradeDirect'`); every
other value passes through raw via `ELSE PRIORCARRIER`. Structurally this is the same shape as
PP's own G-17 finding (off-list insurers pass unvalidated) — worth checking live data rather than
assuming the risk materializes here too.

## Data (live, 2026-07-10)

| Value | Count | Status |
|---|---|---|
| Unknown | 580 | valid |
| Other | 360 | valid |
| Allianz | 356 | valid |
| VERO | 216 | valid |
| Elders | 144 | valid |
| QBE | 108 | valid |
| CGU | 97 | valid |
| GIO | 73 | valid |
| Wesfarmers | 68 | valid |
| NRMA | 58 | valid |
| MotorTradeDirect | 27 | valid |
| SGIO | 12 | valid |
| SGIC | 11 | valid |

**2,110 of 2,110 rows valid (0 invalid).** Every value present in live data exactly matches one of
DC's 13 canonical options. `PRICE` also checked — 0 rows hit the `COALESCE(...,0)` blank-default
fallback.

**Query:**
```sql
SELECT PRIORCARRIER, COUNT(*) FROM AGGNE.DEV.VW_CBP_COMPETITOR_INFORMATION GROUP BY PRIORCARRIER;
```

## Findings

**No active bug.** Unlike PP's equivalent (where off-list insurers genuinely leaked through), BP's
Pure source for `PriorCarrier` appears to already be constrained to exactly this 13-value set —
possibly a Pure-side dropdown/lookup rather than free text. The `ELSE PRIORCARRIER` raw passthrough
is structurally the same latent-risk shape as SEQ 3's `LINE` field (no fallback if an off-list value
ever appears) but has zero live impact today.

**Status:** No gap opened for SEQ 4. Clean.
