"""
Fetch the current DDL of AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION from Snowflake
and save it to sql/snowflake/views/AGGNE/UAT/VW_CBP_OUTPUT_CONVERSION.sql
"""
import base64, hashlib, sys, pyodbc
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption
)
import snowflake.connector

ROOT      = Path(__file__).resolve().parent.parent
OUT_PATH  = ROOT / "sql" / "snowflake" / "views" / "AGGNE" / "UAT" / "VW_CBP_OUTPUT_CONVERSION.sql"

SF_CRED_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

def _fernet_key(secret_key="change-me"):
    digest = hashlib.sha256(secret_key.encode()).digest()
    return base64.urlsafe_b64encode(digest)

def decrypt(token: str) -> str:
    return Fernet(_fernet_key()).decrypt(token.encode()).decode()

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

def run():
    print("Connecting to SQL Server for Snowflake credentials ...")
    sf_meta, pk_der = get_sf_private_key_der()
    print(f"  [OK] Got key for {sf_meta['sf_username']}")

    print("Connecting to Snowflake ...")
    ctx = snowflake.connector.connect(
        account     = sf_meta["sf_account"],
        user        = sf_meta["sf_username"],
        private_key = pk_der,
        warehouse   = sf_meta["sf_warehouse"],
        role        = sf_meta["sf_role"],
        database    = "AGGNE",
        schema      = "UAT",
    )
    print("  [OK] Connected")

    cur = ctx.cursor()
    print("Fetching DDL for AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION ...")
    cur.execute("SELECT GET_DDL('VIEW', 'AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION')")
    row = cur.fetchone()
    ctx.close()

    if not row or not row[0]:
        print("  [FAIL] No DDL returned — check that the view exists in AGGNE.UAT")
        sys.exit(1)

    ddl = row[0]
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(ddl, encoding="utf-8")
    print(f"  [OK] Saved to {OUT_PATH}")
    print(f"  Lines: {len(ddl.splitlines())}")

if __name__ == "__main__":
    run()
