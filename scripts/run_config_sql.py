"""
Execute a .sql file (GO-delimited) against PolicyConversion on local SQL Server.
Usage: python scripts\run_config_sql.py <path_to_sql_file>
"""
import pyodbc, sys, re

CONN_STR = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=PolicyConversion;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

def run_sql_file(path: str):
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read()

    # Split on GO (standalone on a line)
    batches = re.split(r'^\s*GO\s*$', raw, flags=re.MULTILINE | re.IGNORECASE)
    batches = [b.strip() for b in batches if b.strip()]

    conn = pyodbc.connect(CONN_STR, autocommit=True)
    cur  = conn.cursor()

    ok = 0
    for i, batch in enumerate(batches, 1):
        # Skip USE statements — already targeting PolicyConversion
        if re.match(r'^\s*USE\s+', batch, re.IGNORECASE):
            continue
        try:
            cur.execute(batch)
            # Print any PRINT output
            while cur.nextset():
                pass
            ok += 1
        except pyodbc.Error as e:
            print(f"[ERROR] Batch {i}: {e.args[1][:200] if e.args else e}")
            print(f"  First 120 chars: {batch[:120]}")

    conn.close()
    print(f"\n[DONE] {ok}/{len(batches)} batches executed successfully.")

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else r"sql\sqlserver\config\ConversionConfig_DDL.sql"
    run_sql_file(path)
