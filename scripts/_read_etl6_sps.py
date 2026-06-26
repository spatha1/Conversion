import base64, hashlib, pyodbc
from pathlib import Path
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

OUT = Path(r"C:\Users\Admin-1\Desktop\Conversion\sql\snowflake\stored_procedures")
OUT.mkdir(parents=True, exist_ok=True)

targets = [
    ("DEV", "POLICY_INSERTPAYLOADINDCT"),
    ("DEV", "PER_CONVERSION_FINAL_LOAD"),
    ("DEV", "PER_CONVERSION_FINAL_XML"),
    ("DEV", "SP_POLICY_XML_INTEGRATION"),
]

for schema, sp in targets:
    try:
        cur2.execute(f"SELECT GET_DDL('PROCEDURE', 'AGGNE.{schema}.{sp}')")
        r = cur2.fetchone()
        if r:
            ddl = r[0]
            path = OUT / f"{sp}.sql"
            path.write_text(ddl, encoding="utf-8")
            print(f"=== AGGNE.{schema}.{sp}  len={len(ddl):,} ===")
            print(ddl)
            print()
    except Exception as e:
        print(f"AGGNE.{schema}.{sp}: {e}\n")

ctx.close()
