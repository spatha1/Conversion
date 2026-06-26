import pyodbc

CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=PolicyConversion;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

conn = pyodbc.connect(CONN)
cur  = conn.cursor()

for table, lob in [("ConversionConfig", "BP"), ("PP_ConversionConfig", "PP")]:
    cur.execute(f"""
        SELECT ConversionConfigId, SequenceID, ScriptName,
               ConversionSourceTable, ConversionTargetTable, IsActive
        FROM [dbo].[{table}]
        ORDER BY SequenceID
    """)
    rows = cur.fetchall()
    print(f"\n=== {table} ({lob}) — {len(rows)} rows ===")
    print(f"  {'ID':>3}  {'Seq':>3}  {'ScriptName':<30}  {'SourceTable':<40}  Active")
    print(f"  {'-'*3}  {'-'*3}  {'-'*30}  {'-'*40}  ------")
    for r in rows:
        src = r[3].split(".")[-1] if r[3] else ""
        print(f"  {r[0]:>3}  {r[1]:>3}  {str(r[2]):<30}  {str(r[3]):<40}  {'Y' if r[5] else 'N'}")

conn.close()
