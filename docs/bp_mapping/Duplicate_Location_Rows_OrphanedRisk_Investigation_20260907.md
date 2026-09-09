# Duplicate Location Rows → Orphaned Risk References — Investigation

**Date:** 2026-09-07
**Found via:** P00029683 (request ID `P00029683|CML00027813|2538198,2538201,2538201,2538867,2538200|485923,485923,485923,485923,485923`)
**Status:** Root cause traced as far as Snowflake visibility allows — the actual defect is upstream, in an external load process. Needs handoff to whoever owns that process.

---

## The symptom

P00029683's policy attach request contains **5 `<risk type="Building">` blocks** (numbered `LocationNumber` 1–5), but only **4 `<location>` blocks** (numbered 1–4). Risk #5 references a location number that was never defined anywhere in the request — an orphaned/invalid reference sent to DCT.

---

## Root cause chain (traced through the actual live tables, not assumed)

| # | Table | Role | What was found |
|---|---|---|---|
| 1 | `AGGNE.PRD.policyattach_bp` | Master source list of every BP policy's location/risk records — the true starting point for this whole pipeline | **Contains the duplicate itself**: for P00029683, `ExpiringID_P = 2538201` (604 Lower North East Rd, Campbelltown) appears **twice** — same policy, same location, same `RiskNumber = 3`, same expiry date. Confirmed via direct query. |
| 2 | `AGGNE.PRD.locationdetails_policyattach_1` | Reads directly from `policyattach_bp`, joins in risk-survey data (heavy-duty diesel / tyre dealer / smash repairer / dismantler questionnaires) | No deduplication applied — inherits both copies. (Ruled out the 4 survey-table joins as the fan-out source: checked all 4 for this policy/location, zero matching rows in any of them, so they can't be creating the duplicate.) |
| 3 | `AGGNE.PRD.LOCATION_01_POLICYATTACH` | Builds the final `<location>` XML blocks | Computes a `ROW_NUMBER()` (`Count_ID`) but only uses it to build a display string (`Count_ID_String`), not to filter — yet the final `<location>` list still comes out correctly deduplicated to 4. (Some later step collapses it correctly for this specific output.) |
| 4 | `AGGNE.PRD.PA_RISK_BUILDING_FINAL` (reads via `LOCATION_01_POLICYATTACH_IDENTIFIER`) | Builds the `<risk type="Building">` XML blocks | **Does not deduplicate.** `RISKNUMBER` is computed as `ROW_NUMBER() OVER (PARTITION BY ACTUALID ORDER BY ID)` **inside** a `SELECT DISTINCT`. Since `ROW_NUMBER()` gives every row — including true duplicates — its own unique value, the wrapping `DISTINCT` can never collapse them (each copy looks "different" purely because its own row-number column differs). The duplicate location gets assigned an extra sequential number and sent as risk #5, with no matching location. |

**In plain terms:** the location itself is only stored once in the *output* location list, but the *risk* list processes every raw row without checking whether it's a repeat — so a genuine duplicate at the very start of the pipeline (`policyattach_bp`) surfaces downstream as a phantom risk pointing at a location that doesn't exist.

---

## Scale

Checked across the entire BP book, not just this one policy:

| Metric | Count |
|---|---|
| Distinct impacted policies | **3,206** |
| Duplicate location groupings | 8,149 |
| Total extra/phantom rows | 17,155 |

Some locations are duplicated more than twice — one policy has the same location appearing **5 times**. Full list and query: `sql/snowflake/prd/fixes/QUERY_DUPLICATE_LOCATION_ROWS_20260907.sql`.

---

## Where the trace stops, and why

Traced back through every Snowflake object in the chain to find where the duplicate is actually introduced. It stops at `AGGNE.PRD.policyattach_bp` itself, because:

- **No Snowflake stored procedure writes to it.** Checked all 33 procedures in `AGGNE.PRD` and all 94 in `AGGNE.DEV` — none of them have `policyattach_bp` as an `INSERT INTO` or `CREATE OR REPLACE TABLE` target.
- **Its table metadata shows a full rebuild pattern, not incremental updates.** `CREATED` and `LAST_ALTERED` are 2026-09-04 22:54:01 and 22:54:04 — three seconds apart, consistent with a `CREATE OR REPLACE TABLE ... AS SELECT` from an external process, not a Snowflake SP maintaining it over time.

**Conclusion: `policyattach_bp` is loaded by something outside Snowflake entirely** — most likely Informatica (the client's own middleware layer, already established elsewhere in this project as the system that pulls directly from Pure/Capricorn) or an equivalent external ETL job. Whatever join or extract logic that external process uses is where the actual duplicate-producing defect lives. It isn't visible or fixable from any Snowflake object.

**This isn't a one-off from a recent bad run.** P00029683's duplicate is present on *every* historical term for this policy going back to 2019 — meaning the external load process has been reproducing this exact duplication every single time it rebuilds the table, consistently, for years. This is a longstanding, systemic characteristic of that external load, not a transient glitch.

---

## Recommendation

1. **Hand this off to whoever owns the external `policyattach_bp` load process** (likely Informatica/Pure integration team) — they need to check why their extract produces two identical rows for the same policy + location + risk number combination. This is outside conversion/attach-pipeline scope.
2. **Once fixed upstream**, no Snowflake-side fix is needed for `PA_RISK_BUILDING_FINAL`'s `ROW_NUMBER()`/`DISTINCT` pattern — it only manifests as a bug because the duplicate exists at the source; if the source is clean, the existing logic behaves correctly.
3. If a Snowflake-side safety net is wanted regardless of the upstream fix (defensive dedup before the risk numbering happens), that's a separate, smaller change — happy to draft it if useful, but it treats the symptom, not the cause.
4. Once the external load is confirmed fixed, re-run the query in `QUERY_DUPLICATE_LOCATION_ROWS_20260907.sql` to confirm the 3,206-policy count drops to 0, then identify which of those (if any) need reprocessing to pick up corrected data.
