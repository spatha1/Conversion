# HANDOFF — BP Conversion Validation

_Last updated: 2026-07-17. Read this file top to bottom before touching anything — no need to re-read the conversation history._

## Goal

Ongoing engagement validating the **BP (Business Protection)** Duck Creek policy conversion — finding, root-causing, and (where safe) fixing gaps between Pure (source system) and Duck Creek (target) across the full ~67-sequence BP conversion pipeline, then reporting status to the client (**Capricorn**; we are **Aggne**). A parallel PP (Personal Protection) workstream exists and is tracked separately (`docs/pp_mapping/`) but is out of scope for this handoff except where it shares infrastructure with BP.

## Current State

- **Gap register**: `docs/bp_mapping/README.md` — 107 gaps tracked (G-BP-1 through G-BP-104). Large majority fixed and verified live; 15 checked and confirmed *not* defects (faithful ports of client's original SAS design); a handful genuinely blocked on a Capricorn business-rule/data-source decision.
- **New this session — manuscript-based validation**: pulled Duck Creek's own authoritative field-definition manuscripts (AU + NZ) live from the UAT DCT server via `ManuScript.getModelImageRq`, built a parser, and cross-checked our live output against Duck Creek's own declared valid values/types — a fundamentally different, more authoritative validation method than anything used before this session. So far only run against **CM (Commercial Vehicle) fields** and only the **AU** manuscript.
  - Found **G-BP-102** — `BodyType` sends invalid enum values on 31.6% of CM vehicle rows.
  - Found **G-BP-103** — `InductionType` sends invalid/blank values on 11.6% of CM vehicle rows.
  - Found **G-BP-104 (CRITICAL)** — see "In Progress" below.
- **3 fixes drafted, not yet applied** (SAFE_MODE — nothing auto-applied): `G-BP-98` (1 of 3 fields, since 2 were already independently fixed live), `G-BP-101` (Fleet Summary duplicate rows), `G-BP-99` (2 variants, see Open Questions). Deploy package: `docs/bp_mapping/fixes/DEPLOY_20260715.md`.
- **Client status doc**: `docs/BP_PP_Status_Update_Consolidated_20260717.md` — BP and PP side by side, actively being refined for client delivery this session.

## In Progress

Manuscript validation is the active thread and is **far from complete** — only CM vehicle fields against the AU manuscript have been checked. Exact next step: pick up the same methodology (see "Key Files" → `parse_manuscript.py`) and run it against:
1. Fleet vehicle fields (`FLEET_VEHICLE_MAIN_VIEW` / `RISK_FLEET_VEHICLE_TARGET`)
2. NZ manuscript (already downloaded, not yet parsed/validated — see caveat below)
3. Other BP sections: Business Details, Location, Additional Interest

**Caveat**: the downloaded manuscript XML/JSON files live in this session's temp scratchpad directory, which is **not persistent** — a fresh session will need to re-pull them from DCT (see "Decisions & Constraints" for the login gotcha) before continuing.

## Key Files

| Path | What it is |
|---|---|
| `docs/bp_mapping/README.md` | Master BP gap register — the source of truth. **Always search this before concluding something is a "new" bug** (see constraints). |
| `docs/bp_mapping/fixes/*.sql` | Individual drafted fix scripts, one per gap ID, not applied. |
| `docs/bp_mapping/fixes/DEPLOY_20260715.md` | Deployment summary for the 3 most recent fixes, grouped by SP/Config/Views/XMLs. |
| `docs/BP_PP_Status_Update_Consolidated_20260717.md` | Client-facing status doc, BP + PP columns side by side. |
| `scripts/parse_manuscript.py` | Parses a Duck Creek `ManuScript.getModelImageRq` response XML into a flat field index (path, type, maxLength, required, allowed enum values). Reusable for any future manuscript pull. |
| `middleware/snowflake_client.py`, `middleware/sqlserver_client.py` | DB connection helpers used for all live queries this session. |
| `middleware/dct_client.py` | Proven-working POST helper for the DCT server — has the documented browser-User-Agent fix baked in. |
| `middleware/config.py` | Env-driven config, incl. `SAFE_MODE` flag and DCT dev/uat URLs. |

## Decisions & Constraints

- **SAFE_MODE — never write/execute DDL/DML in Snowflake.** Only ever draft `.sql` fix files; the user applies them manually. This is a hard rule, not a suggestion.
- **"Verify live, not repo."** Always pull live `GET_DDL(...)` / live table state before drafting a fix. Proven necessary repeatedly this session — e.g. the currently-deployed main conversion stored procedure no longer matches its own repo copy (see Open Questions).
- **Check the client's original SAS script before calling something a bug.** Several near-misses this session where logic that looked wrong was actually a faithful, intentional port of the client's own design (e.g. the tyre-eligibility SIC/ANZSIC gate — confirmed byte-for-byte against `SAS/txt/BusinessDetails_conversionscriptCapricorn Corrected V2.txt` before concluding ATP-10998 was not a defect).
- **Always search `README.md` for an existing gap before registering a new one.** Nearly re-discovered and mis-registered 3 "new" bugs this session that turned out to already be known, fixed, and verified (G-BP-73/74/01) — caught only by searching the register first.
- **DCT login gotcha**: the request attribute is `password="..."`, **not** `p1word="..."` (a sample request body in circulation has this typo). Also requires a browser-style `User-Agent` header or the DCT server's WAF silently mangles the request — see the comment in `middleware/dct_client.py`.
- **Never print full credentials/secrets in tool output** — redact when dumping DB config or similar.

## Open Questions / TODO

- **G-BP-104 (blocking, needs a decision from whoever owns test scope)**: `VW_CBP_OUTPUT_CONVERSION` — the view that the payload-builder procedure (`POLICY_INSERTPAYLOADINDCT`) actually reads from to decide which policies to submit to Duck Creek — has a hardcoded policy-number whitelist. Only 152 of 13,620+ policies with fully correct, ready conversion data are actually included, in both DEV and UAT. Is this deliberate phased-UAT scoping, or a leftover debug filter that should be widened? Until resolved, testing outside that ~152-policy list will look "broken" regardless of actual data quality — real risk of wrongly re-opening already-fixed tickets.
- **Which live stored procedure is the real production driver?** The currently-deployed `SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD` (main, redeployed 2026-07-14) no longer contains the Commercial Vehicle build chain (`Sample_CBP_CommercialVechicle` → `CM_01/02/03`) at all, yet those tables were freshly rebuilt the next day — meaning some *other* procedure actually ran that batch. The two candidates that still contain the logic are `..._SAI` and `..._BKP_12072026` (both have the identical G-BP-99 bug); fix drafted for both, but which one is actually scheduled needs confirming before results can be trusted.
- Continue manuscript validation per "In Progress" above (Fleet, NZ, Business Details, Location, Additional Interest).
- Long-standing, not yet actioned: re-patch both SP copies with the corrected `G-BP-95` logic; apply `G-BP-97` fix (Run-Off+PL exclusion) to both SP copies once approved; find `G-BP-14`'s true root cause (`ADJUSTMENTS_BSP_OUT` join); `G-BP-61`/`G-BP-62`/`G-BP-65`/`G-BP-72` all blocked on client input; `G-BP-67` fix is ready to deploy, just needs a go-ahead.
- `docs/BP_PP_Status_Update_Consolidated_20260717.md` was mid-refinement for client delivery when this session ended — check with the user whether it's ready to send or still needs review.
