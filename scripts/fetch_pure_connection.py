"""
Fetch the Pure Snowflake connection (id=14) from SQL Server,
decrypt the private key, test the Snowflake connection,
and write values to .env.
"""
import pyodbc
import os

SQLSERVER_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
)

def get_pure_row():
    conn = pyodbc.connect(SQLSERVER_CONN)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT
            sf_account, sf_warehouse, sf_role, sf_database, sf_schema, sf_username,
            sf_private_key_enc, sf_private_key_passphrase_enc
        FROM [ConversionAgent].[dbo].[conversion_source_connections]
        WHERE id = 14
    """)
    cols = [d[0] for d in cursor.description]
    row = dict(zip(cols, cursor.fetchone()))
    conn.close()
    return row

def list_db_objects():
    conn = pyodbc.connect(SQLSERVER_CONN)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT name, type_desc
        FROM sys.objects
        WHERE type IN ('P','FN','IF','TF')
        ORDER BY name
    """)
    rows = cursor.fetchall()
    conn.close()
    return rows

if __name__ == "__main__":
    row = get_pure_row()

    print("=== Pure Snowflake connection metadata ===")
    safe_fields = ['sf_account','sf_warehouse','sf_role','sf_database','sf_schema','sf_username']
    for f in safe_fields:
        print(f"  {f}: {row[f]}")

    pk = row['sf_private_key_enc']
    pp = row['sf_private_key_passphrase_enc']
    print(f"\n  sf_private_key_enc (first 300 chars):\n{str(pk)[:300] if pk else 'NULL'}")
    print(f"\n  sf_private_key_passphrase_enc:\n{str(pp) if pp else 'NULL'}")

    print("\n=== SQL Server DB objects (procs / functions) ===")
    for name, type_desc in list_db_objects():
        print(f"  {name}  [{type_desc}]")
