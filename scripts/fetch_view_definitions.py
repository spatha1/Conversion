"""
1. Read all ConversionSourceTable + AttachSourceTable values from
   PolicyConversion.[dbo].[ConversionConfig] and [PP_ConversionConfig]
2. Connect to Snowflake (Pure connection, private key from SQL Server)
3. GET_DDL for every unique view
4. Save each definition under sql/snowflake/views/<DB>/<SCHEMA>/<VIEW>.sql
"""
import os, sys, base64, hashlib, re
import pyodbc
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption
)
import snowflake.connector

# ── Paths ──
ROOT     = Path(__file__).resolve().parent.parent
VIEWS_DIR = ROOT / "sql" / "snowflake" / "views"

# ── SQL Server (config store) ──
SS_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=PolicyConversion;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

# ── Snowflake credentials source ──
SF_CRED_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

# ── Fernet decrypt (mirrors Ai-Conversion app/config.py) ──
def _fernet_key(secret_key="change-me"):
    digest = hashlib.sha256(secret_key.encode()).digest()
    return base64.urlsafe_b64encode(digest)

def decrypt(token: str) -> str:
    from cryptography.fernet import Fernet
    return Fernet(_fernet_key()).decrypt(token.encode()).decode()

# ── Step 1: collect unique view names ──
def get_source_views() -> set[tuple[str, str, str]]:
    """Return set of (database, schema, view_name) tuples."""
    conn = pyodbc.connect(SS_CONN)
    cur  = conn.cursor()
    views = set()
    for col in ("ConversionSourceTable", "AttachSourceTable"):
        for table in ("ConversionConfig", "PP_ConversionConfig"):
            cur.execute(f"SELECT DISTINCT [{col}] FROM [dbo].[{table}] WHERE [{col}] IS NOT NULL AND IsActive = 1")
            for (name,) in cur.fetchall():
                parts = name.strip().split(".")
                if len(parts) == 3:
                    views.add((parts[0].upper(), parts[1].upper(), parts[2].upper()))
    conn.close()
    return views

# ── Step 2: get Snowflake private key ──
def get_sf_private_key_der():
    conn = pyodbc.connect(SF_CRED_CONN)
    cur  = conn.cursor()
    cur.execute("""
        SELECT sf_account, sf_warehouse, sf_role, sf_database, sf_schema,
               sf_username, sf_private_key_enc, sf_private_key_passphrase_enc
        FROM [ConversionAgent].[dbo].[conversion_source_connections]
        WHERE id = 14
    """)
    row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
    conn.close()

    pk_pem   = decrypt(row["sf_private_key_enc"])
    pp_plain = decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
    pk_obj   = load_pem_private_key(pk_pem.encode(), password=pp_plain.encode() if pp_plain else None)
    der      = pk_obj.private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())
    return row, der

# ── Step 3: fetch DDL from Snowflake ──
def get_ddl(cur, db: str, schema: str, view: str) -> str | None:
    try:
        cur.execute(f"SELECT GET_DDL('VIEW', '{db}.{schema}.{view}')")
        row = cur.fetchone()
        return row[0] if row else None
    except Exception as e:
        return f"-- ERROR: {e}\n"

# ── Step 4: save ──
def save_ddl(db: str, schema: str, view: str, ddl: str):
    out_dir = VIEWS_DIR / db / schema
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{view}.sql"
    out_path.write_text(ddl, encoding="utf-8")
    return out_path

# ── Main ──
def run():
    print("=== Step 1: Collecting unique view names from config tables ===")
    views = get_source_views()
    print(f"  Found {len(views)} unique views across ConversionConfig + PP_ConversionConfig")

    # Group by (db, schema) for display
    by_schema: dict[tuple, list] = {}
    for db, schema, view in sorted(views):
        by_schema.setdefault((db, schema), []).append(view)
    for (db, schema), names in sorted(by_schema.items()):
        print(f"  {db}.{schema} — {len(names)} views")

    print("\n=== Step 2: Connecting to Snowflake (Pure connection) ===")
    sf_meta, pk_der = get_sf_private_key_der()
    ctx = snowflake.connector.connect(
        account     = sf_meta["sf_account"],
        user        = sf_meta["sf_username"],
        private_key = pk_der,
        warehouse   = sf_meta["sf_warehouse"],
        role        = sf_meta["sf_role"],
    )
    print(f"  [OK] Connected as {sf_meta['sf_username']}")

    print("\n=== Step 3: Fetching view DDLs ===")
    cur = ctx.cursor()
    saved = 0
    errors = []

    for db, schema, view in sorted(views):
        # Switch context so GET_DDL resolves correctly
        try:
            cur.execute(f"USE DATABASE {db}")
            cur.execute(f"USE SCHEMA {schema}")
        except Exception:
            pass

        ddl = get_ddl(cur, db, schema, view)
        if ddl:
            path = save_ddl(db, schema, view, ddl)
            status = "ERROR" if ddl.startswith("-- ERROR") else "OK"
            if status == "OK":
                saved += 1
                print(f"  [OK]    {db}.{schema}.{view}")
            else:
                errors.append(f"{db}.{schema}.{view}")
                print(f"  [FAIL]  {db}.{schema}.{view}  — {ddl[10:80]}")
        else:
            errors.append(f"{db}.{schema}.{view}")
            print(f"  [MISS]  {db}.{schema}.{view}  — no rows returned")

    ctx.close()

    print(f"\n=== Done: {saved} saved, {len(errors)} errors ===")
    if errors:
        print("  Failed views:")
        for e in errors:
            print(f"    {e}")
    print(f"\n  Output directory: {VIEWS_DIR}")

if __name__ == "__main__":
    run()
