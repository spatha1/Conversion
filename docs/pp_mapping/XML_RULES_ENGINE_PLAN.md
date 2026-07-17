# XML Validation Rules Engine — Plan (not built yet, target: Monday 2026-07-13)

Replaces XSD-based validation (`docs/PP_XML_Validation_Building.xsd`, `docs/PP_XML_Validation_Motor.xsd`)
with a config-driven rules table + one SP that runs every active rule against every XML we have,
writing a Pass/Fail + reason report. XSD only checks structural shape (element exists, right type) —
it can't express business rules like "Indicator must be 0 when sValue=NotTaken" or "BodyType must not
be blank when raw MVCVBodyType has data." A rules table can express both, and grows one row at a time
as we find new bugs, instead of needing a schema edit + redeploy for every new check.

## 1. Rule storage — `AGGNE.DEV.XML_VALIDATION_RULES` (new table)

| Column | Type | Purpose |
|---|---|---|
| RULE_ID | VARCHAR | e.g. `G-03-BODYTYPE-BLANK`, `G-47-INDICATOR-HARDCODE`, `XSD-MOTOR-001` |
| RULE_CATEGORY | VARCHAR | `GAP` (tied to a G-number), `BUG` (tied to an ATP), `XML` (generic structural/XSD-derived), `BUSINESS` (cross-field logic not tied to a specific bug) |
| GAP_OR_ATP_REF | VARCHAR | `G-03`, `ATP-10963`, or NULL for generic XML rules |
| SCOPE | VARCHAR | `SEQ4`, `SEQ18`, `ALL`, etc. — which part of the XML this applies to |
| DESCRIPTION | VARCHAR | Human-readable: what the rule checks and why |
| CHECK_SQL | VARCHAR | A SQL **expression** (not a full query) evaluated per-row against the XML/payload table — returns TRUE (pass) or FALSE (fail). e.g. `REGEXP_SUBSTR(REQUEST_XML,'<BodyType>(.*?)</BodyType>',1,1,'e',1) IS NOT NULL AND TRIM(REGEXP_SUBSTR(...)) <> ''` |
| TARGET_TABLE | VARCHAR | Which table this rule runs against — `AGGNE.DEV.PER_POLICY_MIGRATION_DCT`, `AGGNE.UAT.PER_POLICY_MIGRATION_DCT`, or an intermediate like `PER_COM_PAYLOAD` |
| FAIL_MESSAGE | VARCHAR | Template for the "why failed" comment, e.g. `'BodyType blank for a vehicle with real source data'` |
| SEVERITY | VARCHAR | `P1`/`P2`/`P3` — carried from the gap register so the report can be sorted by severity |
| IS_ACTIVE | BOOLEAN | Turn a rule off without deleting its history |
| CREATED_DATE | DATE | When added |
| ADDED_BY_GAP | VARCHAR | Free-text note on which investigation produced this rule (traceability back to the gap doc) |

Seeded from day one with every check we've already written by hand this project — the `Step 4`
validation queries, the gap-fix files' post-validation blocks, the old XSD's structural rules
(element-exists / type checks translated into `CHECK_SQL` expressions), and `VALIDATION_RULES.md`'s
existing content. Not starting from zero — just centralizing what already exists as ad-hoc Python/SQL
scripts scattered across the scratchpad into one queryable table.

## 2. Runner SP — `AGGNE.DEV.SP_RUN_XML_VALIDATION_RULES(P_TARGET_SCHEMA VARCHAR, P_RULE_CATEGORY VARCHAR DEFAULT NULL)`

For each active rule (optionally filtered by category/scope), for each policy row in the specified
target table:
1. Evaluate `CHECK_SQL` against that row (dynamic SQL — `EXECUTE IMMEDIATE` building a per-rule
   `SELECT policy_key, CASE WHEN <check_sql> THEN 'PASS' ELSE 'FAIL' END, ...`)
2. Write one row per (policy, rule) into a report table

## 3. Report table — `AGGNE.DEV.XML_VALIDATION_REPORT`

| Column | Purpose |
|---|---|
| RUN_ID | Groups one full run together (timestamp-based) |
| RUN_DATE | When this run happened |
| TARGET_SCHEMA | DEV or UAT |
| LEGACYPOLICYNUMBER | Which policy |
| RULE_ID | Which rule |
| RESULT | PASS / FAIL / ERROR (rule itself broke — e.g. bad regex) |
| FAIL_REASON | The rule's `FAIL_MESSAGE`, plus the actual offending value where feasible |
| SEVERITY | Carried from the rule |

This is the "pass or fail and why failed comment" deliverable — one row per policy per rule,
queryable/filterable/exportable straight into a client-facing report.

## 4. How new rules get added going forward

Every time we close a gap investigation (like today's G-03/G-05/G-06 etc.), the post-validation
query we already write by hand becomes a new `CHECK_SQL` row instead of a one-off script — no new
process, just point the existing habit at a table instead of a scratchpad `.py` file. Same for any
XML-shape rule that would previously have been an XSD edit (mandatory-field-present, enum-value-valid,
etc.) — translate the XSD constraint into a `CHECK_SQL` expression once, retire the XSD check.

## 5. Open questions before building (Monday)

- Confirm `CHECK_SQL` as a **row-level expression** (evaluated per policy via dynamic SQL) vs. rules
  that are inherently **aggregate** (e.g. "no more than 5% of policies should have X") — may need a
  second `RULE_TYPE` (`ROW` vs `AGGREGATE`) with a different runner path for the aggregate ones,
  since a single boolean expression can't express a threshold rule.
- Where do BP rules live — same table with a `LOB` column (`PP`/`BP`), or a separate table? Given BP
  has its own gap register and dropdown-validation work already (`BP_DROPDOWN_FIELD_VALIDATION.sql`),
  probably the same table with an `LOB` column, so one runner SP and one report cover both.
- Decide the dynamic-SQL construction pattern carefully — this project has hit `EXECUTE IMMEDIATE`
  quoting/escaping bugs before (BUG-NEW-04-style issues); needs the same "test in isolation before
  wiring into a big SP" discipline used for G-49 today.
