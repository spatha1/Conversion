"""
Check 1: What ITR_TYPE does ConversionConfig configure for BP line coverage steps?
Check 2: What ITR_TYPE values are actually IN the LINE_*_Target tables in Snowflake?
"""
import base64, hashlib, pyodbc
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption
)
import snowflake.connector

SS_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=PolicyConversion;"
    "UID=clarityAgentuser;PWD=AshuAdvi@2816;TrustServerCertificate=yes;"
)
SF_CRED_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;"
    "UID=clarityAgentuser;PWD=AshuAdvi@2816;TrustServerCertificate=yes;"
)

def _fernet_key(secret_key="change-me"):
    digest = hashlib.sha256(secret_key.encode()).digest()
    return base64.urlsafe_b64encode(digest)

def decrypt(token):
    return Fernet(_fernet_key()).decrypt(token.encode()).decode()

def get_sf_connection():
    conn = pyodbc.connect(SF_CRED_CONN)
    cur  = conn.cursor()
    cur.execute("""SELECT sf_account,sf_warehouse,sf_role,sf_username,
                          sf_private_key_enc,sf_private_key_passphrase_enc
                   FROM [ConversionAgent].[dbo].[conversion_source_connections] WHERE id=14""")
    row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
    conn.close()
    pk_pem   = decrypt(row["sf_private_key_enc"])
    pp_plain = decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
    pk_obj   = load_pem_private_key(pk_pem.encode(), password=pp_plain.encode() if pp_plain else None)
    der      = pk_obj.private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())
    return snowflake.connector.connect(
        account=row["sf_account"], user=row["sf_username"],
        private_key=der, warehouse=row["sf_warehouse"], role=row["sf_role"],
        database="AGGNE", schema="DEV"
    )

# ── CHECK 1: ConversionConfig for BP line coverage steps ─────────────────────
print("=" * 70)
print("CHECK 1: ConversionConfig — BP line coverage ETL4 steps")
print("=" * 70)
conn = pyodbc.connect(SS_CONN)
cur  = conn.cursor()
cur.execute("""
    SELECT Seq, LineOfBusiness, ConversionStep, TargetTable,
           ConversionSourceTable, ITR_Type, IsActive
    FROM [dbo].[ConversionConfig]
    WHERE LineOfBusiness = 'BP'
      AND TargetTable LIKE '%LINE_%Target%'
      AND IsActive = 1
    ORDER BY Seq
""")
rows = cur.fetchall()
cols = [d[0] for d in cur.description]
if rows:
    print(f"{'Seq':<5} {'Step':<25} {'TargetTable':<25} {'ITR_Type':<20} {'Active'}")
    print("-" * 90)
    for r in rows:
        d = dict(zip(cols, r))
        print(f"{str(d['Seq']):<5} {str(d['ConversionStep']):<25} {str(d['TargetTable']):<25} {str(d['ITR_Type']):<20} {d['IsActive']}")
else:
    print("No rows found — checking without IsActive filter ...")
    cur.execute("""
        SELECT Seq, LineOfBusiness, ConversionStep, TargetTable, ITR_Type, IsActive
        FROM [dbo].[ConversionConfig]
        WHERE LineOfBusiness = 'BP' AND TargetTable LIKE '%LINE_%Target%'
        ORDER BY Seq
    """)
    for r in cur.fetchall():
        d = dict(zip([c[0] for c in cur.description], r))
        print(f"  Seq={d['Seq']}  Step={d['ConversionStep']}  Target={d['TargetTable']}  ITR_Type={d['ITR_Type']}  Active={d['IsActive']}")
conn.close()

# ── CHECK 2: Actual ITR_TYPE values in Snowflake LINE_*_Target tables ─────────
print()
print("=" * 70)
print("CHECK 2: Distinct ITR_TYPE values in LINE_*_Target tables (Snowflake DEV)")
print("=" * 70)
sf = get_sf_connection()
cur2 = sf.cursor()
targets = ["LINE_GP_Target","LINE_PPL_Target","LINE_PF_Target","LINE_GT_Target",
           "LINE_LE_Target","LINE_SV_Target","LINE_CV_Target","LINE_TA_Target"]
for t in targets:
    try:
        cur2.execute(f"SELECT DISTINCT ITR_TYPE, COUNT(*) AS CNT FROM AGGNE.DEV.{t} GROUP BY ITR_TYPE ORDER BY ITR_TYPE")
        rows2 = cur2.fetchall()
        vals = ", ".join(f"'{r[0]}' ({r[1]} rows)" for r in rows2) if rows2 else "(empty)"
        print(f"  {t:<25} → {vals}")
    except Exception as e:
        print(f"  {t:<25} → ERROR: {e}")
sf.close()
