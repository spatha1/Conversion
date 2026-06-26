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

# Check object types
cur2.execute("""
SELECT TABLE_NAME, TABLE_TYPE
FROM AGGNE.INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DEV'
AND TABLE_NAME IN ('PER_FINAL','VW_PER_FINAL','PP_OUTPUT_CONVERSION','PER_OUTPUT_CONVERSION','PP_FINAL','VW_PP_CONVERSION')
""")
rows = cur2.fetchall()
print("Found objects:")
for r in rows:
    print(f"  {r[0]}  type={r[1]}")

# Try GET_DDL for PER_FINAL as view then table
for obj_type in ("VIEW", "TABLE"):
    try:
        cur2.execute(f"SELECT GET_DDL('{obj_type}', 'AGGNE.DEV.PER_FINAL')")
        r = cur2.fetchone()
        if r:
            ddl = r[0]
            print(f"\n--- PER_FINAL ({obj_type})  len={len(ddl):,}  LEFT JOINs={ddl.upper().count('LEFT JOIN')} ---")
            print(ddl[:2000])
            break
    except Exception as e:
        print(f"PER_FINAL as {obj_type}: {e}")

ctx.close()
