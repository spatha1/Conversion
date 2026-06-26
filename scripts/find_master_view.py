"""
Find the master consolidation view in Snowflake — the one that combines
all payload views into a single XML per policy.
Strategy:
  1. List ALL views in AGGNE.DEV and AGGNE.PRD
  2. Show which ones we DON'T already have saved (i.e. not in ConversionConfig)
  3. For interesting candidates, print the first 200 chars of the view body
     so we can spot the one that JOINs many payload views.
Read-only — no writes, no SP calls.
"""
import base64, hashlib
import pyodbc
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption,
)
import snowflake.connector

SAVED_DIR = Path(__file__).resolve().parent.parent / "sql" / "snowflake" / "views"

def _fernet_key():
    return base64.urlsafe_b64encode(hashlib.sha256(b"change-me").digest())

def decrypt(token):
    return Fernet(_fernet_key()).decrypt(token.encode()).decode()

def get_sf():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
        "DATABASE=ConversionAgent;UID=clarityAgentuser;PWD=AshuAdvi@2816;"
        "TrustServerCertificate=yes;"
    )
    cur = conn.cursor()
    cur.execute("""
        SELECT sf_account, sf_username, sf_private_key_enc,
               sf_private_key_passphrase_enc, sf_warehouse, sf_role
        FROM [dbo].[conversion_source_connections] WHERE id = 14
    """)
    row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
    conn.close()
    pk_pem = decrypt(row["sf_private_key_enc"])
    pp = decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
    pk_der = load_pem_private_key(pk_pem.encode(), password=pp.encode() if pp else None)\
             .private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())
    return snowflake.connector.connect(
        account=row["sf_account"], user=row["sf_username"],
        private_key=pk_der, warehouse=row["sf_warehouse"], role=row["sf_role"],
    )

def saved_names(schema):
    d = SAVED_DIR / "AGGNE" / schema
    return {p.stem.upper() for p in d.glob("*.sql")} if d.exists() else set()

def run():
    ctx = get_sf()
    cur = ctx.cursor()
    print("[OK] Connected\n")

    for schema in ("DEV", "PRD"):
        already_saved = saved_names(schema)
        print(f"=== AGGNE.{schema} — views NOT in ConversionConfig (potential master views) ===")

        cur.execute(f"SHOW VIEWS IN SCHEMA AGGNE.{schema}")
        rows = cur.fetchall()
        cols = [d[0] for d in cur.description]
        name_idx = next(i for i, c in enumerate(cols) if c.lower() == "name")

        unsaved = [r[name_idx] for r in rows if r[name_idx].upper() not in already_saved]
        print(f"  Total views: {len(rows)}  |  Unsaved (not in config): {len(unsaved)}")
        for vname in sorted(unsaved):
            print(f"    {vname}")

        # For candidate views, peek at the body
        print(f"\n  --- Peeking at unsaved views in AGGNE.{schema} ---")
        for vname in sorted(unsaved):
            try:
                cur.execute(f"SELECT GET_DDL('VIEW', 'AGGNE.{schema}.{vname}')")
                row = cur.fetchone()
                if row:
                    body = row[0][:400].replace('\n', ' ')
                    print(f"\n  [{vname}]")
                    print(f"  {body}")
            except Exception as e:
                print(f"  [{vname}] error: {e}")

        print()

    ctx.close()

if __name__ == "__main__":
    run()
