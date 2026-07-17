# G-49 — HB_02/HC_02 built as a one-time manual snapshot, never refreshed — root cause CONFIRMED

**Status:** Root cause found (2026-07-10). Not a code/logic bug — an operational/pipeline gap.
Reopens/supersedes part of G-43's scope.

**Client tickets:** ATP-11117 (Home Buildings/Contents not selected), ATP-11115 (Private Motor
Vehicle details did not populate — Motor side has a related but distinct cause, see note at
bottom), likely contributes to ATP-11110 (Location 1 sections missing).

## Root cause

Per `files/KT/KT/Batch Running Steps.xlsx`, sheet "PolicyConversion Steps PP", Step 2 ("Loads all
the config source tables into views"): **"No specific SP Created, It was done manually as we had
run only single time till now."**

`HB_02` and `HC_02` are **static tables loaded once, manually, and never refreshed** — unlike
`PM_01`/`PM_02`/`PM_03` and every other staging table, which get rebuilt fresh on every
`SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()` run. Confirmed live for policy `P00010162`:

| Table | Location 2 (`EXPIRINGID_P=2178093`) | Location 1 |
|---|---|---|
| `PER_ACCOUNT_LOC` (rebuilt every run, current) | 2178093 ✓ | **2530787** |
| `HB_02` / `HC_02` (one-time manual load) | 2178093 ✓ (matches) | **2178092** (real data, $906,000 HB limit / $202,000 HC limit — but wrong ID) |

Location 1's real HB/HC data **exists and is correct** in `HB_02`/`HC_02` — it's just filed under
`EXPIRINGID_P=2178092`, an ID that `PER_ACCOUNT_LOC` no longer uses for that location (it's since
moved to `2530787`, presumably after an amendment/renewal was processed sometime after `HB_02`'s
one-time load). When seq 14 joins HB/HC data back to `PER_ACCOUNT_LOC` by the composite key
`PUREPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P`, Location 1's data never matches and silently disappears
downstream — not because it's missing, but because the join key has drifted since the snapshot was
taken. Location 2 wasn't affected because its `EXPIRINGID_P` happened to stay stable.

Scale: `HB_02` has 2,773 distinct policies, `Locationdetails_PER` (current, `HOMEBUILDINGS='Yes'`)
has 2,771 — very close, meaning most policies are unaffected (their `EXPIRINGID_P` hasn't drifted
since the one-time load). This will affect any policy that's had a location added, amended, or
renewed since `HB_02`/`HC_02` was last (and only) populated — not yet quantified how many, but
worth a broader scan, not just this one policy.

## Recommended fix

Not a SQL logic fix — `HB_02`/`HC_02` need to be wired into the routine refresh cycle the same way
every other staging table is (either folded into `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` itself,
or a new dedicated rebuild step run alongside it). Whoever owns the original manual load process
(check `SAS/txt/` or the KT docs' "SAS Query.sql" for the original build logic) needs to confirm
the source query so it can be turned into a repeatable step — **do not guess at rebuilding this
from scratch without that reference, since HB_02/HC_02's exact business logic (which PURE tables,
which filters) isn't yet confirmed.**

## Relationship to G-43

G-43 was re-measured and closed as "2 of 4,006 policies genuinely lack Location 1, benign
PURE-side fact" — that specific measurement (does Location 1 exist anywhere in `PER_ACCOUNT_LOC`)
is still correct and unrelated to this. This is a different problem: Location 1 IS present, but
its HB/HC coverage data can't be joined to it because of the staleness described above.

## Original source logic found

`SAS/txt/HomeBuilding_coversionscriptCapricorn.txt` has the client's original build recipe:

```
DATA HB_02 (DROP = HCAccidentalDamageHome HCFloodProtectionHome HCProtection BuildingContents_Ind
                    Vehicles_Ind HCHBLandlord HCHBMinRentPeriod HCHBExVoluntary);
SET HB_01;
  /* minimum-limit, accidental-damage, landslide, and landlord business rules, then: */
  IF BuildingContents_Ind = 0 THEN DELETE;
  IF BuildingContents_Ind = 1 AND HCProtection = 2 THEN DELETE;
RUN;
```

`HB_01` itself (same file, just above): built from `Sample_PER` (which supplies `ExpiringID_P`)
LEFT JOINed to `PER_HOMECONTENTS` and `PER_RISKSELECTION` on `ExpiringID_P`. So `HB_02`'s
`EXPIRINGID_P` was always meant to be sourced live from `Sample_PER` — confirming this is purely a
staleness problem (one-time capture, never re-run), not a different ID-assignment algorithm.
`HomeContents_coversionscriptCapricorn.txt` has the equivalent `HC_02` recipe — not yet read in
detail, check there for HC_02's exact build logic before drafting the Snowflake translation.

**This means the fix is realistic**: translate this SAS `DATA` step to a Snowflake
`CREATE OR REPLACE TABLE HB_02 AS SELECT ...` sourced from current `Sample_PER`/`ExpiringID_P`
(mirroring how `PM_01`/`PM_02`/`PM_03` are already rebuilt fresh every run), preserving the same
minimum-limit/accidental-damage/landslide/landlord business rules and delete conditions. Do this
for both HB_02 and HC_02, and wire the rebuild into the routine conversion cycle (either inside
`SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` or a dedicated step run alongside it) so it never goes
stale again.

## Next step (not done yet)

1. Find the original SAS/SQL logic that built `HB_02`/`HC_02` (check `SAS/txt/` and
   `files/KT/KT/SAS Query.sql`) so a repeatable rebuild step can be written.
2. Quantify how many policies are actually affected (not just P00010162) — compare
   `PER_ACCOUNT_LOC`'s current `EXPIRINGID_P` per location against `HB_02`/`HC_02`'s stored one,
   count mismatches.
3. Check whether `PM_01` (Motor) has an analogous staleness issue — separately noted that
   P00010162's Motor vehicles are tagged against `EXPIRINGID_P=585251` (a 2021 term), not either
   current 2026 location. Worth checking if `PM_01` is *also* built from a stale one-time source,
   or if this is a different, Motor-specific term-selection bug (unconfirmed which).
