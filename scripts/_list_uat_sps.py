import base64, hashlib, pyodbc
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import load_pem_private_key, Encoding, PrivateFormat, NoEncryption
import snowflake.connector

def decrypt(token):
    key = base64.urlsafe_b64encode(hashlib.sha256(b"change-me").digest())
    return Fernet(key).decrypt(token.encode()).decode()

conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;UID=clarityAgentuser;PWD=AshuAdvi@2816;TrustServerCertificate=yes;"
)
cur = conn.cursor()
cur.execute("SELECT sf_account, sf_username, sf_private_key_enc, sf_private_key_passphrase_enc, sf_warehouse, sf_role FROM [dbo].[conversion_source_connections] WHERE id = 14")
row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
conn.close()

pk_pem = decrypt(row["sf_private_key_enc"])
pp = decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
pk_der = load_pem_private_key(pk_pem.encode(), password=pp.encode() if pp else None).private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())
ctx = snowflake.connector.connect(account=row["sf_account"], user=row["sf_username"], private_key=pk_der, warehouse=row["sf_warehouse"], role=row["sf_role"])
cur2 = ctx.cursor()

for schema in ("UAT", "DEV"):
    print(f"\n=== Stored Procedures in AGGNE.{schema} ===")
    try:
        cur2.execute(f"SHOW PROCEDURES IN SCHEMA AGGNE.{schema}")
        rows = cur2.fetchall()
        cols = [d[0] for d in cur2.description]
        name_idx = next(i for i, c in enumerate(cols) if c.lower() == "name")
        args_idx = next((i for i, c in enumerate(cols) if "argument" in c.lower()), None)
        for r in rows:
            args = r[args_idx] if args_idx is not None else ""
            print(f"  {r[name_idx]}  {args}")
        if not rows:
            print("  (none found)")
    except Exception as e:
        print(f"  Error: {e}")

ctx.close()
