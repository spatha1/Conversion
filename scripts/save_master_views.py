"""
Fetch and save the full DDL for the master consolidation views:
  - AGGNE.DEV.VW_CBP_OUTPUT_CONVERSION  (BP conversion — the main final view)
  - AGGNE.DEV.VW_CBP_OUTPUT_PA_V2       (BP policy attach final output)
  - AGGNE.DEV.CBP_PAYLOAD               (policy-level payload assembly)
  - AGGNE.DEV.VW_BUSINESS_FINAL         (business/policy header)
Read-only — no writes.
"""
import base64, hashlib
from pathlib import Path
import pyodbc
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption,
)
import snowflake.connector

OUT = Path(__file__).resolve().parent.parent / "sql" / "snowflake" / "views" / "AGGNE" / "DEV"
OUT.mkdir(parents=True, exist_ok=True)

TARGETS = [
    ("DEV", "VW_CBP_OUTPUT_CONVERSION"),
    ("DEV", "VW_CBP_OUTPUT_PA_V2"),
    ("DEV", "CBP_PAYLOAD"),
    ("DEV", "VW_BUSINESS_FINAL"),
    ("DEV", "VW_BUSINESS_FINAL_POLICYATTACH"),
]

def decrypt(token):
    key = base64.urlsafe_b64encode(hashlib.sha256(b"change-me").digest())
    return Fernet(key).decrypt(token.encode()).decode()

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

def run():
    ctx = get_sf()
    cur = ctx.cursor()
    print("[OK] Connected\n")

    for schema, vname in TARGETS:
        print(f"--- AGGNE.{schema}.{vname} ---")
        try:
            cur.execute(f"SELECT GET_DDL('VIEW', 'AGGNE.{schema}.{vname}')")
            row = cur.fetchone()
            if row:
                ddl = row[0]
                out_dir = OUT.parent.parent / "AGGNE" / schema
                out_dir.mkdir(parents=True, exist_ok=True)
                path = out_dir / f"{vname}.sql"
                path.write_text(ddl, encoding="utf-8")
                print(f"  Saved {len(ddl):,} chars -> {path.name}")
                print(f"  Columns: {ddl[:600]}\n")
            else:
                print("  No DDL returned\n")
        except Exception as e:
            print(f"  Error: {e}\n")

    ctx.close()

if __name__ == "__main__":
    run()
