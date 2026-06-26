"""
Fetch DDL for all SPs involved in the BP/PP conversion flow.
Read-only — no writes.
"""
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

# All candidate flow SPs in DEV — ordered by likely execution sequence
targets = [
    # Source data / setup
    ("DEV", "SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD", "()"),
    ("DEV", "SP_LOAD_PURE_POLICY_BP", "()"),
    ("DEV", "POLICY_SOURCEDATA", "()"),
    ("DEV", "POLICY_PARTY_XML", "()"),
    # XML generation
    ("DEV", "DYNAMIC_XML_V1", "(VARCHAR,VARCHAR,VARCHAR,VARCHAR)"),
    ("DEV", "DYNAMIC_XML_GENERATOR", "(VARCHAR,VARCHAR,VARCHAR)"),
    ("DEV", "COMBINEPAYLOAD", "(VARCHAR,VARCHAR,VARCHAR,VARCHAR)"),
    # Final XML assembly / staging
    ("DEV", "POLICY_INSERTPAYLOADINDCT", "()"),
    ("DEV", "INSERT_VALID_POLICY", "(VARCHAR)"),
    ("DEV", "FINAL_TABLE_ARCHIVE_AND_DELETE_XML", "()"),
    # DCT integration
    ("DEV", "SP_POLICY_XML_INTEGRATION", "(VARCHAR,VARCHAR)"),
    ("DEV", "GETBUCKETJSON", "()"),
    # PP equivalents
    ("DEV", "PER_CONVERSION_FINAL_LOAD", "()"),
    ("DEV", "PER_CONVERSION_FINAL_XML", "()"),
    ("DEV", "PER_FINAL_TABLE_ARCHIVE_AND_DELETE_XML", "()"),
    ("DEV", "PER_FINAL_TABLE_ARCHIVE_AND_DELETE_XML_V2", "()"),
]

for schema, sp, args in targets:
    full = f"AGGNE.{schema}.{sp}"
    # Try with given args signature, then without
    for sig in (f"{full}{args}", full):
        try:
            cur2.execute(f"SELECT GET_DDL('PROCEDURE', '{sig}')")
            r = cur2.fetchone()
            if r:
                ddl = r[0]
                fname = OUT / f"DEV_{sp}.sql"
                fname.write_text(ddl, encoding="utf-8")
                print(f"\n{'='*60}")
                print(f"SP: {full}  (len={len(ddl):,})")
                print('='*60)
                print(ddl)
                break
        except Exception as e:
            if sig == full:  # last attempt
                print(f"\n[SKIP] {full}: {e}")

ctx.close()
print("\n\nDone.")
