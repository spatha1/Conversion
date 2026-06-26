import pyodbc
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=PolicyConversion;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)
cur = conn.cursor()
cur.execute("""
    SELECT t.TABLE_NAME,
           (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c
            WHERE c.TABLE_NAME = t.TABLE_NAME) AS col_count,
           p.rows AS row_count
    FROM INFORMATION_SCHEMA.TABLES t
    JOIN sys.partitions p
      ON p.object_id = OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME)
     AND p.index_id IN (0,1)
    WHERE t.TABLE_TYPE = 'BASE TABLE'
    ORDER BY t.TABLE_NAME
""")
print("Tables in PolicyConversion:")
for row in cur.fetchall():
    print(f"  {row[0]:35s}  {row[1]} cols  |  {row[2]} rows")
conn.close()
