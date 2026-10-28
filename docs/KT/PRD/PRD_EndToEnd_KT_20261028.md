# PRD — End-to-End Knowledge Transfer

**Compiled:** 2026-10-28, from session memory, `PROGRESS.md`, `docs/bp_mapping/`/`docs/pp_mapping/` dated
folders, and `git log`. This is a point-in-time consolidation, not a live source — verify anything
load-bearing against Snowflake (`GET_DDL`, `INFORMATION_SCHEMA`) before acting on it.

---

## 1. Purpose / scope

This engagement converts PURE-sourced insurance policies into Duck Creek (DCT) via Snowflake, for two
lines of business for client Capricorn (contractor Aggne):
- **BP** (Business Package) — went to production 2026-10-08.
- **PP** (Personal Package) — no formal go-live date found in memory or `PROGRESS.md`; PP policies are
  actively landing in a PRD-labeled table today (see §2), but this doc could not confirm whether that
  reflects an official go-live or ongoing pre-work. **Flag to confirm, don't assume.**

This doc covers what actually happened in/around **PRD** specifically — architecture, go-live timeline,
operating rules, and the status of every PRD-relevant fix/finding found in memory and docs. It does not
re-document the much larger body of DEV/UAT-only investigation work (see `PROGRESS.md`,
`docs/bp_mapping/`, `docs/pp_mapping/` for that).

## 2. PRD architecture summary

**Two separate conversion pipelines exist, each with its own PRD reprocessing norms — do not conflate them:**

- **Policy Conversion** (new/renewing PURE policies, first-time DCT submission):
  `AGGNE.PRD.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()` (builds ~150+ BP+PP staging tables from raw PURE,
  one shared SP for both LOBs) → config-driven view layer (`BP_XML_CONFIG`, 68 sequences, rendered via
  `BP_CONVERSION_LOAD_VIEWS_FROM_CONFIG()`) → `AGGNE.PRD.VW_CBP_OUTPUT_CONVERSION` (final BP output
  assembly, whitelist-scoped only in PRD — no auto date-scope like UAT/DEV) →
  `AGGNE.PRD.POLICY_INSERTPAYLOADINDCT()` → **`AGGNE.PRD.POLICY_MIGRATION_DCT`** (BP:
  `REQUEST_XML`/`RESPONSE_XML`/`RESULTS_JSON`, one row per policy, insert-only, `PREVDATA` empty).
  PP's equivalent landing table, queried live this session, is **`AGGNE.PRD_XML.PER_POLICY_MIGRATION_DCT`**
  — same shape, `PER_`-prefixed. Note: a 2026-09-20 architecture note in `PROGRESS.md` states
  `AGGNE.PRD_XML` "belongs to the unrelated Policy Attach/CML pipeline" — that note was specifically about
  BP's own `POLICY_MIGRATION_DCT` *not* living there (it lives in plain `AGGNE.PRD`). Whether PP's table
  genuinely shares that schema with Policy Attach/CML, or this is a naming collision, wasn't reconciled
  here — worth a live check if it matters.
- **Policy Attach** (re-attaching/searching already-issued policies into DCT, a separate runtime with its
  own PSD middleware): `AGGNE.PRD.SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD` → `PA_*` views
  (`PA_ACCOUNT_LOC_AGG`, `PA_BUILDING_FINAL_AGG`, etc.) → `AGGNE.PRD.POLICY_ATTACH_TABLE` /
  `policyattach_bp`. This pipeline has its own normal, designed reprocessing mechanism — a Delta-process
  queue (`POLICYATTACH_TO_PROCESS`) that already reprocesses policies as routine operation (used for
  ATP-11338 and ATP-11883, §5). **This is why ATP-11883 got a live backfill while Policy Conversion
  tickets don't** — different pipeline, different norm, not an exception to §4's rule.

Both pipelines are config/SAFE_MODE-governed: every fix is a drafted `.sql` file + backup; the user
applies all DDL/DML manually against the read-only-to-us Snowflake connection.

## 3. PRD go-live timeline

| Date | Event |
|---|---|
| 2026-09-20/21 | Entire Policy Conversion pipeline (Pure-to-Write SP, 68-sequence config-view layer, output assembly view, `POLICY_INSERTPAYLOADINDCT`) regenerated and deployed into `AGGNE.PRD` as pre-work, object-by-object, from live DEV/UAT state. Confirmed live via `INFORMATION_SCHEMA`, but `BP_POLICY_WHITELIST` had 0 rows — pipeline ran clean but produced no XML, as expected pre-go-live. |
| 2026-09-23 (planned) | Originally targeted production go-live date (per `PROGRESS.md`, written ~2026-09-20). |
| 2026-09-29 | User explicitly corrected the go-live date: **"we did not go PRD yet and we will go on 8th"** — actual go-live confirmed as 2026-10-08, superseding the 09-23 target. |
| 2026-10-08 | **BP production go-live.** |
| 2026-10-10 | ATP-11883 fix deployed to PRD (Policy Attach pipeline) — first confirmed post-go-live PRD code deploy found in memory. |
| ~2026-10-26 | An unspecified PRD load issue was fixed (referenced in the "No PRD Reprocess" memory as the cutoff for "is it still happening" checks — the underlying issue behind ATP-11965's staleness wasn't recurring in 10-26/27 builds). |
| 2026-10-28 (today) | User explicitly ruled out PRD reprocessing/requoting as a fix strategy (§4); PP's missing-location finding closed as expected behavior; ATP-11965/11969 root-caused as non-code issues; ATP-11991/11984 sitting drafted-but-undeployed. |

## 4. PRD operating rules

1. **SAFE_MODE** — never execute CREATE/ALTER/UPDATE/DELETE/CALL directly against Snowflake; every fix is
   a drafted `.sql` file, user applies manually. Connection is read-only (SELECT/GET_DDL/SHOW only).
2. **No PRD reprocess (Policy Conversion pipeline only)** — `AGGNE.PRD.POLICY_MIGRATION_DCT` /
   `AGGNE.PRD_XML.PER_POLICY_MIGRATION_DCT` rows are frozen at first build; already-quoted PRD policies
   are never rebuilt or re-quoted by us. User explicitly ruled this out 2026-10-28: "we should not
   reprocess the policies in PRD." **Fixes are forward-only** — a source/template/SP change makes
   *future* builds correct; exposure is measured on recent builds (10-26 onward), not fixed retroactively.
   Correcting an already-quoted policy, if ever needed, is the policy team's call, not ours to plan.
3. **Post-go-live PRD tickets ≠ UAT tickets** — since 2026-10-08, client ATP tickets that cite a quote
   number refer to PRD, not UAT. Trace via `AGGNE.PRD.POLICY_MIGRATION_DCT`, matching
   `RESULTS_JSON[0]:QuoteNumber` to the ticket's quote. Tracing UAT first on a post-go-live ticket is a
   documented mistake (made once, corrected 2026-10-28).
4. **Policy Attach pipeline is the exception** — it has its own pre-existing Delta-process reprocess
   queue as normal design; that mechanism reprocessing policies is not a violation of rule 2.
5. **UAT/DEV stay the normal validation grounds** — backup-then-rebuild batches, fresh quote generation
   (`quote_log/create_quote.py --env uat|dev`), and requoting are routine there, and remain the way fixes
   get proven before anyone asks about PRD.

## 5. PRD-relevant tickets — status table

| Ticket | Pipeline | Issue | Root cause / outcome | PRD status |
|---|---|---|---|---|
| ATP-11883 | Policy Attach | Duplicate `<LocationId>` GUIDs in BP attach response (P00003346) | `PA_ACCOUNT_LOC_AGG`'s `LISTAGG` missing `DISTINCT` (same pattern as an earlier `PA_BUILDING_FINAL_AGG` fix) | **Fixed and deployed to PRD 2026-10-10**, verified end-to-end 2026-10-12. 6,693 policies impacted book-wide (3,355 in-force); team backfilling via the existing Delta queue at ~1,000/day. |
| ATP-11991 | Policy Conversion | CM vehicle contribution $0 after a Protection Type change (missing perils) | Each vehicle now sent all 9 CM perils, with not-taken ones at Indicator 0 | Fix drafted, verified in DEV/UAT (4 UAT quotes Q0130943–46). **Not yet deployed to PRD** — pending policy-team verification, then approval. |
| ATP-11984 | Policy Conversion | Location coverage fallbacks sent as empty XML shells | Fixed in DEV 2026-10-23 | **Confirmed never deployed to PRD.** Pending approval. |
| ATP-11969 | Policy Conversion | Missing schedule clauses (28 rows / 18 policies in PRD, 25 in UAT) | 8 of 9 example rows trace to the client's own `RISK.SCHEDULE_CLAUSES_TEMPLATE` pointing at stale binders — a client data issue. 1 row (P00001692, CM rego with a space) is sent correctly by us but dropped on the DC side — routed to the policy team. Also showed an earlier ATP-11978 "closed, not our issue" verdict was wrong. | **No PRD code change** — needs a client template refresh. |
| ATP-11965 | Policy Conversion | Dismantler UW questions blank + extra whitespace in ANZSIC text (P00035584/Q0103502) | ANZSIC text verified clean character-by-character — visible break was viewer line-wrapping, not stored data. Dismantler blanks traced to a quote (10-19) older than a since-fixed PRD load issue (~10-26); no recurrence in 10-26/27 builds. | **No PRD code change** — not currently reproducing; no reprocess of the old quote per rule 2. |
| *(no ATP yet)* | Policy Conversion (PP) | 70 PP policies (9 in the last 2 days) missing the `<account><location>` XML node on motor-only policies | `PER_ACCOUNT_LOC`'s `cte2` drops the location row when neither Home Building nor Home Contents is taken — confirmed live that DC approves/pends these identically with or without the node, zero rejections either side | **Closed as expected behaviour.** Gate stays as-is; no PRD change. Separate open item flagged by the PP team: a 4-policy GNAF address-match loss, not yet characterized. |
| ATP-11962 | Policy Conversion | Missing CM/BI/location-level adjustments on 3 quotes (P00031231, P00027630, P00018148) | Symptoms confirmed live via XML on all 3. Working hypothesis ties it to the already-disabled `RISK_LOCATION_UW_COMBINE` view, unverified. | **Open — investigation paused**, not concluded. |
| ATP-11338 | Policy Attach | 644 BSP policies with empty-shell response XML | `POLICYATTACH_LOAD_FINALDATA_XML`'s `xsltOut` transform path had its backslashes stripped, breaking DCT's manuscript resolution | Root cause confirmed; 644 policies queued into `POLICYATTACH_TO_PROCESS` for reprocessing via the normal Delta-queue mechanism. SP fix itself was flagged as owned by "the policy team," outside conversion-team scope — last known status before this doc was drafted-and-waiting, not confirmed deployed. |

**Pre-go-live PRD environment build-out (context, not open tickets):** between 2026-09-20 and 09-21, the
full Policy Conversion pipeline was regenerated object-by-object into `AGGNE.PRD` ahead of go-live
(Pure-to-Write SP, 68-sequence config-view layer — 21 target tables + 72 source views, output assembly
view, `POLICY_INSERTPAYLOADINDCT`), with DEV-vs-PRD row-count parity confirmed exact across all 21 target
tables. Two logging tables (`SP_EXECUTION_LOG`, `POLICY_JOURNEY_LOG`) and a T-42 trigger-table whitelist
redesign were designed for PRD operations but explicitly deferred by the user ("Journey will deploy
later") — unclear from memory whether either has since been built; worth checking if PRD operations
tooling comes up again.

## 6. Currently open PRD items

- **ATP-11991** and **ATP-11984** — fixes drafted and verified in DEV/UAT, not yet deployed to PRD; both
  waiting on policy-team verification/approval.
- **ATP-11962** — unresolved, investigation paused mid-query.
- **PP GNAF match loss (4 policies)** — flagged by the PP team 2026-10-28, not yet characterized (which
  policies, which field: likely `GNAFID`/`ADDRESSVERIFIED` going null/0 where PURE's `RLGNAFPID` is
  populated).
- **ATP-11338's SP-level fix** (the `xsltOut` backslash bug) — last known status is "owned by the policy
  team," not confirmed deployed; worth a status check if it hasn't come up recently.
- **PP go-live status** — unconfirmed in memory/docs; worth asking directly since PP policies are
  visibly landing in a PRD-labeled table today.
- **PRD operations tooling** (`SP_EXECUTION_LOG`, `POLICY_JOURNEY_LOG`, T-42 whitelist redesign) —
  designed but deferred pre-go-live; current status unverified.

## 7. Evidence / sources

Compiled 2026-10-28 from: this engagement's memory store (`project_prd_golive_date.md`,
`feedback_prd_tickets_check_prd_tables.md`, `feedback_no_prd_reprocess.md`,
`project_atp11883_duplicate_location_agg.md`, `project_bp_clause_template_binder_staleness.md`,
`feedback_vw_cbp_output_conversion_uat_target.md`,
`project_vw_cbp_output_conversion_hardcoded_fallbacks.md`, `project_jira_known_issues.md`,
`project_bp_status_20260828.md`, `project_bp_mom_20260828.md`, `project_atp11338_bsp_delta_rerun.md`,
`project_pp_field_bugs.md`, MEMORY.md index); `PROGRESS.md` (repo root, full read); directory listings of
`docs/bp_mapping/` and `docs/pp_mapping/` dated subfolders; and today's own session findings (ATP-11969,
ATP-11965, ATP-11962, PP missing-location, ATP-11991, ATP-11984 status recap). `git log --oneline -50`
showed only 6 broad, non-ticket-scoped commits — no commit-level PRD-deploy evidence; `git log --grep=PRD`
returned nothing. Where a detail couldn't be verified against a live source, it's marked "unverified" or
"worth checking" above rather than stated as fact.
