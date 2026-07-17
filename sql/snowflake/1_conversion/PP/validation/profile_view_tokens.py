"""
Token-level anomaly profiler for PP conversion views.

For a given view, computes per-column NON_NULL / DISTINCT / NULL / BLANK / ZERO counts across
every row, and flags columns that look suspicious:
  SINGLE-VALUE     — every row has the same value (dead field, or a hardcoded/constant tag)
  MOSTLY-MISSING   — >=90% NULL+blank
  MOSTLY-ZERO      — >=90% of rows are '0'/'0.00'

A flag is a starting point for investigation, not proof of a bug — always check the source table
before concluding a fix is needed (see check_pmclm_and_marketvaldesc.py-style follow-up queries;
some flagged columns turn out to be genuinely sparse source data, not conversion defects).

Usage:
    python profile_view_tokens.py AGGNE.DEV.PER_COM_PAYLOAD
"""
import sys

sys.stdout.reconfigure(encoding="utf-8")
sys.path.insert(0, r"c:\Users\Admin-1\Desktop\Conversion")
from middleware.snowflake_client import get_connection

VIEW = sys.argv[1] if len(sys.argv) > 1 else "AGGNE.DEV.PER_COM_PAYLOAD"

conn = get_connection()
cur = conn.cursor()

cur.execute(f"DESCRIBE VIEW {VIEW}")
cols = [r[0] for r in cur.fetchall()]

cur.execute(f"SELECT COUNT(*) FROM {VIEW}")
total = cur.fetchone()[0]
print(f"View: {VIEW}")
print(f"Total rows: {total}\n")

parts = [
    f"""
SELECT '{c}' AS TOKEN,
    COUNT({c}) AS NON_NULL,
    COUNT(DISTINCT {c}) AS DISTINCT_VALS,
    SUM(CASE WHEN {c} IS NULL THEN 1 ELSE 0 END) AS NULL_CNT,
    SUM(CASE WHEN {c} IS NOT NULL AND TRIM(CAST({c} AS VARCHAR)) = '' THEN 1 ELSE 0 END) AS BLANK_CNT,
    SUM(CASE WHEN CAST({c} AS VARCHAR) IN ('0','0.00') THEN 1 ELSE 0 END) AS ZERO_CNT
FROM {VIEW}
"""
    for c in cols
]
cur.execute("\nUNION ALL\n".join(parts))
rows = cur.fetchall()

print(f"{'TOKEN':38} {'NON_NULL':>9} {'DISTINCT':>9} {'NULL':>7} {'BLANK':>7} {'ZERO':>7}  {'NULL+BLANK%':>12}  FLAG")
print("-" * 115)

flagged = []
for token, non_null, distinct, null_cnt, blank_cnt, zero_cnt in rows:
    missing_pct = round((null_cnt + blank_cnt) / total * 100, 1) if total else 0
    flags = []
    if distinct <= 1:
        flags.append("SINGLE-VALUE")
    if missing_pct >= 90:
        flags.append("MOSTLY-MISSING")
    if zero_cnt and total and (zero_cnt / total) >= 0.90:
        flags.append("MOSTLY-ZERO")
    flag_str = ",".join(flags)
    if flags:
        flagged.append((token, distinct, missing_pct, zero_cnt, flag_str))
    print(f"{token:38} {non_null:9} {distinct:9} {null_cnt:7} {blank_cnt:7} {zero_cnt:7}  {missing_pct:11}%  {flag_str}")

print("\n" + "=" * 60)
print(f"FLAGGED TOKENS ({len(flagged)} of {len(cols)}):")
print("=" * 60)
for token, distinct, missing_pct, zero_cnt, flag_str in flagged:
    print(f"  {token:38} distinct={distinct:<6} missing={missing_pct}%  zero={zero_cnt}  [{flag_str}]")

cur.close()
conn.close()
