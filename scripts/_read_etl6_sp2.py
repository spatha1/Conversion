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

sp_name = "POLICY_INSERTPAYLOADINDCT"

# Try different GET_DDL identifier formats for 0-arg procedures
attempts = [
    f"GET_DDL('PROCEDURE', 'AGGNE.UAT.{sp_name}()')",
    f"GET_DDL('PROCEDURE', 'AGGNE.UAT.{sp_name}')",
]

for attempt in attempts:
    try:
        print(f"Trying: SELECT {attempt}")
        cur2.execute(f"SELECT {attempt}")
        r = cur2.fetchone()
        if r:
            ddl = r[0]
            path = OUT / f"UAT_{sp_name}.sql"
            path.write_text(ddl, encoding="utf-8")
            print(f"\n=== SUCCESS  len={len(ddl):,} ===")
            print(ddl)
            break
    except Exception as e:
        print(f"  Failed: {e}\n")

# Also try SHOW for exact signature info
print("\n=== SHOW PROCEDURES LIKE in UAT ===")
try:
    cur2.execute(f"SHOW PROCEDURES LIKE '{sp_name}' IN SCHEMA AGGNE.UAT")
    rows = cur2.fetchall()
    cols = [d[0] for d in cur2.description]
    for r in rows:
        for c, v in zip(cols, r):
            print(f"  {c}: {v}")
except Exception as e:
    print(f"  {e}")

ctx.close()
