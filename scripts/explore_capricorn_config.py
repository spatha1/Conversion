"""
Connect to Capricorn-SwiftConversion (Azure SQL) and explore
tables/views that hold ETL config — view names + XML formulas.
"""
import pyodbc, json

SERVER   = "aggneswiftconversion-prod.database.windows.net,1433"
DATABASE = "Capricorn-SwiftConversion"
USER     = "CapAgnprdcnvusr"
PASSWORD = "8>z611:L_m8W13JJ!XOb"

def make_conn_str(driver: str) -> str:
    # Wrap password in {} so ODBC treats it as a literal value
    safe_pwd = "{" + PASSWORD + "}"
    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={SERVER};"
        f"DATABASE={DATABASE};"
        f"UID={USER};"
        f"PWD={safe_pwd};"
        "Encrypt=yes;"
        "TrustServerCertificate=no;"
        "Connection Timeout=30;"
    )

def get_conn():
    drivers = [
        "ODBC Driver 18 for SQL Server",
        "ODBC Driver 17 for SQL Server",
        "SQL Server",
    ]
    for drv in drivers:
        try:
            cs = make_conn_str(drv)
            conn = pyodbc.connect(cs)
            print(f"[OK] Connected using: {drv}")
            return conn
        except pyodbc.Error as e:
            print(f"[FAIL] {drv}: {e.args[1][:120] if e.args else e}")
    raise RuntimeError("Could not connect with any available driver.")

def run():
    conn = get_conn()
    cur  = conn.cursor()

    # ── All tables + row counts ──
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

    print("\n=== Tables in Capricorn-SwiftConversion ===")
    for schema, name, rows in tables:
        print(f"  [{schema}].[{name}]  ({rows} rows)")

    # ── Views ──
    cur.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.VIEWS
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    views = cur.fetchall()
    if views:
        print(f"\n=== Views ({len(views)} total) ===")
        for schema, name in views:
            print(f"  [{schema}].[{name}]")

    # ── Stored procedures / functions ──
    cur.execute("""
        SELECT ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE
        FROM INFORMATION_SCHEMA.ROUTINES
        ORDER BY ROUTINE_TYPE, ROUTINE_NAME
    """)
    routines = cur.fetchall()
    if routines:
        print(f"\n=== Routines ({len(routines)} total) ===")
        for schema, name, rtype in routines:
            print(f"  [{schema}].[{name}]  ({rtype})")

    # ── Columns for likely-config tables ──
    keywords = ('config', 'formula', 'template', 'etl', 'mapping',
                'conversion', 'xml', 'view', 'source', 'target')
    config_tables = [(s, n) for s, n, _ in tables
                     if any(k in n.lower() for k in keywords)]

    if config_tables:
        print(f"\n=== Columns of likely-config tables ({len(config_tables)}) ===")
        for schema, name in config_tables:
            cur.execute("""
                SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
                ORDER BY ORDINAL_POSITION
            """, schema, name)
            cols = cur.fetchall()
            print(f"\n  [{schema}].[{name}]")
            for col, dtype, maxlen in cols:
                length_info = f"({maxlen})" if maxlen else ""
                print(f"    {col}  {dtype}{length_info}")

    # ── Sample rows from small config tables ──
    small_config = [(s, n, r) for s, n, r in tables
                    if any(k in n.lower() for k in keywords) and r <= 500]
    if small_config:
        print("\n=== Sample rows from config tables (<=500 rows) ===")
        for schema, name, rows in small_config:
            cur.execute(f"SELECT TOP 5 * FROM [{schema}].[{name}]")
            cols = [d[0] for d in cur.description]
            data = [dict(zip(cols, row)) for row in cur.fetchall()]
            print(f"\n  [{schema}].[{name}]  ({rows} rows total)")
            for d in data:
                print(f"    {json.dumps(d, default=str)}")

    conn.close()

if __name__ == "__main__":
    run()
