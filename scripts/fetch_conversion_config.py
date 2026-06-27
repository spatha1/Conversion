"""
Fetch PolicyConversion.dbo.ConversionConfig (BP) and dbo.PP_ConversionConfig (PP)
and save to reference/ConversionConfig_BP.csv and reference/ConversionConfig_PP.csv

Actual column mapping:
  SequenceID          = logical "Seq"
  ScriptName          = logical "ConversionStep" / ITR_TYPE written by ETL4
  ConversionTargetTable = logical "TargetTable"
"""
import os, csv, pyodbc
from pathlib import Path
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / ".env")

CONN_STR = (
    f"DRIVER={{{os.environ['SQLSERVER_DRIVER']}}};"
    f"SERVER={os.environ['SQLSERVER_HOST']};"
    f"DATABASE={os.environ['SQLSERVER_DATABASE']};"
    f"UID={os.environ['SQLSERVER_USER']};"
    f"PWD={os.environ['SQLSERVER_PASSWORD']};"
    "TrustServerCertificate=yes;"
)

REF_DIR = ROOT / "reference"
REF_DIR.mkdir(parents=True, exist_ok=True)

conn = pyodbc.connect(CONN_STR)
cur  = conn.cursor()

def dump_table(table_name: str, out_name: str, label: str):
    cur.execute(f"SELECT * FROM dbo.[{table_name}] ORDER BY SequenceID")
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    out  = REF_DIR / out_name
    with open(out, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(cols)
        writer.writerows(rows)
    print(f"\n{'='*70}")
    print(f"  {label}  ({len(rows)} rows) -> {out}")
    print(f"{'='*70}")
    # Summarise: Seq | ScriptName (=ConversionStep) | ConversionTargetTable | IsActive
    si  = cols.index("SequenceID")
    ni  = cols.index("ScriptName")
    ti  = cols.index("ConversionTargetTable")
    ai  = cols.index("IsActive")
    src = cols.index("ConversionSourceTable")
    print(f"{'Seq':<6} {'ScriptName (ConversionStep / ITR_TYPE)':<40} {'TargetTable':<35} {'SourceTable':<35} {'Active'}")
    print("-" * 125)
    for r in rows:
        print(f"{str(r[si]):<6} {str(r[ni]):<40} {str(r[ti]):<35} {str(r[src]):<35} {r[ai]}")

dump_table("ConversionConfig", "ConversionConfig_BP.csv", "dbo.ConversionConfig (BP)")

conn.close()
print("\n[DONE] CSVs saved to reference/")
