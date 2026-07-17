# PP End-to-End Pipeline — Pilot Run Plan

Updated plan incorporating gaps found while mapping the architecture this session. Run scripts in order. Nothing here has been executed — every DDL step is marked and should be reviewed before running.

## Step map

| # | Script | System | Type | Depends on |
|---|---|---|---|---|
| 0 | `STEP0_SAFETY_AND_PILOT_SCOPE.sql` | SQL Server | read-only + DDL (pilot table) | — |
| 1 | `STEP1_IDENTIFY_MISSING_CMLS.sql` | Snowflake | read-only | Step 0 |
| 2 | `STEP2_CREATE_PARTY_XMLS_DEV.sql` + `STEP2b_..._PROCEDURE.sql` | Snowflake | DDL (new SP) + DML | Step 1 |
| 3 | `STEP3_QUEUE_PARTY_TO_PSD.sql` | SQL Server | DML + **DDL (9x ALTER VIEW)** | Step 2 |
| 4 | `STEP4_VALIDATE_PARTY_RESPONSE.sql` | SQL Server + Snowflake | read-only | Step 3 + Timer Trigger run |
| 5 | `STEP5_CREATE_POLICY_XMLS.sql` | Snowflake | DML (existing SP) | Step 4 gate passed |
| 6 | `STEP6_QUEUE_POLICY_TO_PSD.sql` | SQL Server | DML | Step 5 gate passed |
| 7 | `STEP7_VALIDATE_POLICY_RESPONSE.sql` | SQL Server + Snowflake | read-only (partial — see below) | Step 6 + Timer Trigger run |
| 8 | `STEP8_VALIDATE_CLARITY_BRONZE.sql` | Snowflake (Clarity DEV_01) | read-only | Step 7 |
| 9 | *(pending — you'll provide Clarity reconciliation details)* | — | — | Step 8 |
| 10 | `STEP10_VALIDATE_BUGS_AND_MANDATORY_FIELDS.sql` | Snowflake | read-only, reuses existing tooling | Step 8 |

## What changed from the original 10-step plan

1. **Added Step 0** — global kill-switch check (`PSD.Enable_View`), current backlog sanity check, and a fixed pilot policy list. Nothing runs against full DEV volume until this pilot proves out.
2. **Party push is DEV-scoped, not the existing UAT one.** The proven `INSERT_PARTY_TO_DCTTABLE_SEC_CONTACT()` writes to `AGGNE.UAT.CML_MIGRATION_DCT` — but `AGGNE.DEV.VW_PARTYDET` (what policy conversion actually reads for `{PARTYID}`) is keyed off DEV's own tables. Mixing environments would mean Party succeeds in UAT while Policy conversion in DEV never sees the PartyId. Step 2 is a new, DEV-targeted copy of the same proven manuscript.
3. **Step 3 requires new infrastructure, not just a queue insert.** The Timer Trigger's 10 `Process_N` views only poll `ConfigrequestId IN (33,35,17,42)` today. A DEV-Party config doesn't exist in that rotation — Step 3 registers a new `PSD.CONFIGREQUEST` row *and* adds it to all 9 active `Process_N` views (`Process_1` is currently dormant/fully commented out — left alone unless you want it reactivated too). **This ALTER VIEW step is exactly the kind of DDL you mentioned gating behind a password in the future UI.**
4. **Step 6 does NOT rely on `HB_PP_PolicyConversion_LoadViews`.** That SP calls `EXEC PSD.udf_generate_configdata 16` — **16 is `BP_ConfigRequest`, not PP** (confirmed bug, separate from this plan). Config 42 (`PP_CreatePolicy`) is already in the polling rotation, so Step 6 queues directly into it, mirroring `Party_FinalRun`'s proven pattern instead.
5. **Step 5 gates on validation, doesn't defer it.** `SP_PP_XML_VALIDATE` already exists and is proven — Step 5 runs it before Step 6 pushes anything to DCT, so we don't create live quotes for policies with known mandatory-field gaps.
6. **Step 7 is intentionally incomplete.** The Timer Trigger already calls DCT for PP (confirmed: 388/430 historically processed) — but nothing parses the response into `PER_POLICY_MIGRATION_DCT.RESULTS_JSON` (confirmed: 0% populated). Party's equivalent works only because `Party_FinalRun` explicitly registers a parser. **I need one real raw DCT response body for a processed PP policy before I can write PP's parser accurately** — guessing the QuoteID/Status field names would be worse than leaving it open. Step 7's script pulls whatever raw response is available today (via `PSD.Configdata.Response`) as the starting point.

## Open items still needed from you

- **Confirm the Snowflake linked server name** used in Steps 3 and 6 (`OPENQUERY([<SNOWFLAKE_LINKED_SERVER_NAME>], ...)`) — I don't have this from anything queried this session.
- **One real raw DCT response** for a processed PP policy (Step 7) — needed to finalize the response parser.
- **Confirm `PP_Policy_Request_Load_v1`'s actual columns** (Step 6 has a precheck query for this — I inferred the shape by analogy to Party's table, never queried this one directly).
- **Pick the pilot policy list** (Step 0) — 5-10 policies, ideally including one from the known-good 38-policy UAT batch as a comparison point.
- **Clarity reconciliation details** for Step 9, as you mentioned.

## Safety notes

- Every `CREATE OR REPLACE PROCEDURE` / `ALTER VIEW` in these scripts is a **new object or an addition to an existing one** — nothing overwrites or removes existing working procedures (`INSERT_PARTY_TO_DCTTABLE_SEC_CONTACT`, the 10 `Process_N` views' existing `ConfigrequestId` list, etc.).
- Steps 3 and 6 cause **real external side effects** once the Timer Trigger picks up the queued rows (creates real Party/Policy records in DCT). Pilot scope keeps the blast radius small; nothing here should run against full volume until the pilot is confirmed end to end.
- Matches the standing project rule: I draft, you review and run — nothing gets executed by me without your explicit go-ahead each step.
