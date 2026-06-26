"""
Explore ConversionAgent DB — list all tables and show any that look like
ETL config (view names, formulas, XML templates).
"""
import pyodbc

CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
)

def run():
    conn = pyodbc.connect(CONN)
    cur  = conn.cursor()

    # All tables + row counts
    cur.execute("""
        SELECT
            t.TABLE_SCHEMA,
            t.TABLE_NAME,
            p.rows AS row_count
        FROM INFORMATION_SCHEMA.TABLES t
        JOIN sys.partitions p
          ON p.object_id = OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME)
         AND p.index_id IN (0, 1)
        WHERE t.TABLE_TYPE = 'BASE TABLE'
        ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME
    """)
    tables = cur.fetchall()

    print("=== Tables in ConversionAgent ===")
    for schema, name, rows in tables:
        print(f"  [{schema}].[{name}]  ({rows} rows)")

    # Also list views
    cur.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.VIEWS
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    views = cur.fetchall()
    if views:
        print("\n=== Views ===")
        for schema, name in views:
            print(f"  [{schema}].[{name}]")

    # Peek columns of any table whose name suggests config / formula / template
    keywords = ('config', 'formula', 'template', 'etl', 'mapping', 'conversion', 'xml')
    config_tables = [(s, n) for s, n, _ in tables if any(k in n.lower() for k in keywords)]

    if config_tables:
        print("\n=== Columns of likely-config tables ===")
        for schema, name in config_tables:
            cur.execute(f"""
                SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{name}'
                ORDER BY ORDINAL_POSITION
            """)
            cols = cur.fetchall()
            print(f"\n  [{schema}].[{name}]")
            for col, dtype, maxlen in cols:
                length_info = f"({maxlen})" if maxlen else ""
                print(f"    {col}  {dtype}{length_info}")

    conn.close()

if __name__ == "__main__":
    run()
