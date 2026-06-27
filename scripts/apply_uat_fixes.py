"""
Take the live AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION DDL and apply bug fixes.

Changes applied:
  US-5977 : T4 (VW_CLAIM_HISTORY_AGG) — remove commented-out GETDATE, add MAX(LOAD_DATE)
  US-5977 : T5 (VW_COMP_INFO_AGG)     — remove commented-out GETDATE, add MAX(LOAD_DATE)
                                         ITR_TYPE = 'BP_Prior_INFO' KEPT AS-IS
  US-5977 : T9 (ACCOUNT_LOC_AGG)      — remove commented-out GETDATE, add MAX(LOAD_DATE)
  ATP-6221: T13-T20 (LINE_*_Target)   — add MAX(LOAD_DATE) scoped to each BP_LINE_* ITR_TYPE
                                         ITR_TYPE names KEPT AS-IS (BP_LINE_GP etc. are correct)

NOTE: ConversionConfig.ConversionStep IS the ITR_TYPE written by ETL4.
      ConversionConfig rows use BP_Prior_INFO, BP_LINE_GP, BP_LINE_PPL, etc.
      Do NOT change these names.

Output: sql/snowflake/1_conversion/BP/deploy/UAT_VW_CBP_OUTPUT_CONVERSION_DEPLOY.sql
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC  = ROOT / "sql/snowflake/views/AGGNE/UAT/VW_CBP_OUTPUT_CONVERSION.sql"
OUT  = ROOT / "sql/snowflake/1_conversion/BP/deploy/UAT_VW_CBP_OUTPUT_CONVERSION_DEPLOY.sql"

ddl = SRC.read_text(encoding="utf-8")

# ── 1. Qualify view name ──────────────────────────────────────────────────────
ddl = ddl.replace(
    "create or replace view VW_CBP_OUTPUT_CONVERSION(",
    "create or replace view AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION(",
    1,
)
print("[OK] View name qualified to AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION")

# ── 2. T4: remove commented GETDATE, add MAX(LOAD_DATE) ──────────────────────
old_t4 = (
    "    LEFT JOIN AGGNE.DEV.VW_CLAIM_HISTORY_AGG T4 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T4.ID), '|', 1)\n"
    "    --AND CAST(T4.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)"
)
new_t4 = (
    "    LEFT JOIN AGGNE.DEV.VW_CLAIM_HISTORY_AGG T4 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T4.ID), '|', 1)\n"
    "    AND CAST(T4.LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.VW_CLAIM_HISTORY_AGG)"
)
if old_t4 in ddl:
    ddl = ddl.replace(old_t4, new_t4, 1)
    print("[OK] T4 LOAD_DATE: GETDATE removed, MAX(LOAD_DATE) added")
else:
    print("[WARN] T4 pattern not found — check VW_CBP_OUTPUT_CONVERSION.sql manually")

# ── 3. T5: remove commented GETDATE, add MAX(LOAD_DATE) — keep BP_Prior_INFO ─
old_t5 = (
    "    LEFT JOIN AGGNE.DEV.VW_COMP_INFO_AGG T5 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.ID)\n"
    "    AND T5.ITR_TYPE = 'BP_Prior_INFO'\n"
    "   -- AND CAST(T5.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)"
)
new_t5 = (
    "    LEFT JOIN AGGNE.DEV.VW_COMP_INFO_AGG T5 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.ID)\n"
    "    AND T5.ITR_TYPE = 'BP_Prior_INFO'\n"
    "    AND CAST(T5.LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.VW_COMP_INFO_AGG WHERE ITR_TYPE = 'BP_Prior_INFO')"
)
if old_t5 in ddl:
    ddl = ddl.replace(old_t5, new_t5, 1)
    print("[OK] T5 LOAD_DATE: GETDATE removed, MAX(LOAD_DATE) added  [ITR_TYPE='BP_Prior_INFO' unchanged]")
else:
    print("[WARN] T5 pattern not found — check VW_CBP_OUTPUT_CONVERSION.sql manually")

# ── 4. T9: remove commented GETDATE, add MAX(LOAD_DATE) ──────────────────────
old_t9 = (
    "    LEFT JOIN AGGNE.DEV.ACCOUNT_LOC_AGG T9 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T9.PUREPOLICYNUMBER)\n"
    "   -- AND CAST(T9.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)"
)
new_t9 = (
    "    LEFT JOIN AGGNE.DEV.ACCOUNT_LOC_AGG T9 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T9.PUREPOLICYNUMBER)\n"
    "    AND CAST(T9.LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.ACCOUNT_LOC_AGG)"
)
if old_t9 in ddl:
    ddl = ddl.replace(old_t9, new_t9, 1)
    print("[OK] T9 LOAD_DATE: GETDATE removed, MAX(LOAD_DATE) added")
else:
    print("[WARN] T9 pattern not found — check VW_CBP_OUTPUT_CONVERSION.sql manually")

# ── 5. T13-T20: add MAX(LOAD_DATE) — all ITR_TYPEs kept as BP_LINE_* ─────────
# Each target table has multiple ConversionStep rows (sub-steps + main payload).
# Scope the LOAD_DATE subquery to the same ITR_TYPE to get the right max date.

line_fixes = [
    # (alias, table, itr_type, original_block)
    (
        "T13", "LINE_GP_Target", "BP_LINE_GP",
        "    LEFT JOIN AGGNE.DEV.LINE_GP_Target T13 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T13.ID), '|', 1)\n"
        "    AND T13.ITR_TYPE = 'BP_LINE_GP'",
    ),
    (
        "T14", "LINE_PPL_Target", "BP_LINE_PPL",
        # T14 is on ONE line with extra spaces in the live UAT DDL
        "    LEFT JOIN AGGNE.DEV.LINE_PPL_Target T14 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T14.ID), '|', 1)     AND T14.ITR_TYPE = 'BP_LINE_PPL'",
    ),
    (
        "T15", "LINE_PF_Target", "BP_LINE_PF",
        "    LEFT JOIN AGGNE.DEV.LINE_PF_Target T15 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T15.ID), '|', 1)\n"
        "    AND T15.ITR_TYPE = 'BP_LINE_PF'",
    ),
    (
        "T16", "LINE_GT_Target", "BP_LINE_GT",
        "    LEFT JOIN AGGNE.DEV.LINE_GT_Target T16 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T16.ID), '|', 1)\n"
        "    AND T16.ITR_TYPE = 'BP_LINE_GT'",
    ),
    (
        "T17", "LINE_LE_Target", "BP_LINE_LE",
        "    LEFT JOIN AGGNE.DEV.LINE_LE_Target T17 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T17.ID), '|', 1)\n"
        "    AND T17.ITR_TYPE = 'BP_LINE_LE'",
    ),
    (
        "T18", "LINE_SV_Target", "BP_LINE_SV",
        "    LEFT JOIN AGGNE.DEV.LINE_SV_Target T18 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T18.ID), '|', 1)\n"
        "    AND T18.ITR_TYPE = 'BP_LINE_SV'",
    ),
    (
        "T19", "LINE_CV_Target", "BP_LINE_CV",
        "    LEFT JOIN AGGNE.DEV.LINE_CV_Target T19 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T19.ID), '|', 1)\n"
        "    AND T19.ITR_TYPE = 'BP_LINE_CV'",
    ),
    (
        "T20", "LINE_TA_Target", "BP_LINE_TA",
        "    LEFT JOIN AGGNE.DEV.LINE_TA_Target T20 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T20.ID), '|', 1)\n"
        "    AND T20.ITR_TYPE = 'BP_LINE_TA'",
    ),
]

for alias, table, itr, old_block in line_fixes:
    new_block = (
        f"    LEFT JOIN AGGNE.DEV.{table} {alias} ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM({alias}.ID), '|', 1)\n"
        f"    AND {alias}.ITR_TYPE = '{itr}'\n"
        f"    AND CAST({alias}.LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE)) FROM AGGNE.DEV.{table} WHERE ITR_TYPE = '{itr}')"
    )
    if old_block in ddl:
        ddl = ddl.replace(old_block, new_block, 1)
        print(f"[OK] {alias} ({table}) LOAD_DATE added  [ITR_TYPE='{itr}' unchanged]")
    else:
        print(f"[WARN] {alias} pattern not found — check manually")

# ── 6. Prepend deployment header ──────────────────────────────────────────────
header = """\
-- ============================================================
-- DEPLOYMENT SCRIPT: AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION
-- Date        : 2026-06-26
-- Base DDL    : live AGGNE.UAT (fetched via GET_DDL)
-- Environment : UAT
-- ============================================================
-- Fixes included:
--
--   US-5977 — T4 (VW_CLAIM_HISTORY_AGG) LOAD_DATE
--     Was: --AND CAST(T4.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)  [commented out]
--     Now: AND CAST(T4.LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE))
--                                             FROM AGGNE.DEV.VW_CLAIM_HISTORY_AGG)
--
--   US-5977 — T5 (VW_COMP_INFO_AGG) LOAD_DATE
--     Was: -- AND CAST(T5.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)  [commented out]
--     Now: AND CAST(T5.LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE))
--                                             FROM AGGNE.DEV.VW_COMP_INFO_AGG
--                                             WHERE ITR_TYPE = 'BP_Prior_INFO')
--     Note: ITR_TYPE = 'BP_Prior_INFO' UNCHANGED — matches ConversionConfig.ConversionStep
--
--   US-5977 — T9 (ACCOUNT_LOC_AGG) LOAD_DATE
--     Was: -- AND CAST(T9.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)  [commented out]
--     Now: AND CAST(T9.LOAD_DATE AS DATE) = (SELECT MAX(CAST(LOAD_DATE AS DATE))
--                                             FROM AGGNE.DEV.ACCOUNT_LOC_AGG)
--
--   ATP-6221 — T13-T20 (LINE_*_Target) LOAD_DATE added
--     Added LOAD_DATE = MAX(LOAD_DATE) WHERE ITR_TYPE = 'BP_LINE_*' to each join
--     to prevent duplicate rows when ETL4 has run multiple times.
--     ITR_TYPE values UNCHANGED:
--       T13 BP_LINE_GP, T14 BP_LINE_PPL, T15 BP_LINE_PF, T16 BP_LINE_GT,
--       T17 BP_LINE_LE, T18 BP_LINE_SV, T19 BP_LINE_CV, T20 BP_LINE_TA
--     These exactly match ConversionConfig.ConversionStep values (confirmed).
--
-- No other changes. Columns, WHERE clause (VW_TEST_POLICYCONVERSION_LIST),
-- T21 (AGGNE.UAT.VW_PARTYDET), and all source table references preserved as-is.
-- All config/source views reference AGGNE.DEV — no PRD references.
-- ============================================================
-- Deploy instructions:
--   1. Open Snowflake Worksheet
--   2. Run:  USE DATABASE AGGNE;  USE SCHEMA UAT;
--   3. Paste and execute this entire script
-- ============================================================

"""
ddl = header + ddl

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(ddl, encoding="utf-8")
print(f"\n[DONE] Written to {OUT}")
print(f"       Lines: {len(ddl.splitlines())}")
