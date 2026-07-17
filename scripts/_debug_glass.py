"""Debug ATP-11003: inspect ExcessWaiverForGlass in XML vs PM_03 source. Read-only."""
import os, base64, hashlib, pyodbc
from pathlib import Path
from dotenv import load_dotenv
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption,
)
import snowflake.connector

ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / ".env")
assert os.environ.get("SAFE_MODE", "true").lower() == "true"

SF_CRED_CONN = (
    f"DRIVER={{{os.environ['SQLSERVER_DRIVER']}}};"
    f"SERVER={os.environ['SQLSERVER_HOST']};"
    "DATABASE=ConversionAgent;"
    f"UID={os.environ['SQLSERVER_USER']};"
    f"PWD={os.environ['SQLSERVER_PASSWORD']};"
    "TrustServerCertificate=yes;"
)

def _fernet_key(s="change-me"):
    return base64.urlsafe_b64encode(hashlib.sha256(s.encode()).digest())

def decrypt(t):
    return Fernet(_fernet_key()).decrypt(t.encode()).decode()

def sf_connect():
    conn = pyodbc.connect(SF_CRED_CONN)
    cur  = conn.cursor()
    cur.execute("""SELECT sf_account,sf_warehouse,sf_role,sf_username,
                          sf_private_key_enc,sf_private_key_passphrase_enc
                   FROM dbo.conversion_source_connections WHERE id=14""")
    row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
    conn.close()
    pk_pem = decrypt(row["sf_private_key_enc"])
    pp     = decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
    pk_obj = load_pem_private_key(pk_pem.encode(), password=pp.encode() if pp else None)
    der    = pk_obj.private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())
    return snowflake.connector.connect(
        account=row["sf_account"], user=row["sf_username"],
        private_key=der, warehouse=row["sf_warehouse"], role=row["sf_role"],
        database="AGGNE", schema="DEV",
    )

sf  = sf_connect()
cur = sf.cursor()

# 1. What glass-related tags exist in the XML at all?
print("=== 1. Distinct ExcessWaiver tag occurrences (sample) ===")
cur.execute(r"""
SELECT REGEXP_SUBSTR(REQUEST_XML, '<[A-Za-z]*ExcessWaiver[A-Za-z]*>[^<]*</[A-Za-z]*>', 1, 1) AS SAMPLE_TAG,
       COUNT(*) AS CNT
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE REQUEST_XML ILIKE '%ExcessWaiver%'
GROUP BY 1 ORDER BY 2 DESC LIMIT 10
""")
for r in cur.fetchall():
    print(f"  {r[1]:>6}  {r[0]}")

# 2. How many XMLs mention the tag at all?
cur.execute("""
SELECT COUNT(*) FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
WHERE REQUEST_XML ILIKE '%ExcessWaiverForGlass%'
""")
print(f"\n=== 2. XMLs containing 'ExcessWaiverForGlass' tag: {cur.fetchone()[0]} ===")

# 3. Source distribution in PM_03
print("\n=== 3. PM_03.EXCESSWAIVERFORGLASS distribution ===")
cur.execute("""
SELECT EXCESSWAIVERFORGLASS, COUNT(*) AS CNT, COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)) AS POLICIES
FROM AGGNE.DEV.PM_03
GROUP BY 1 ORDER BY 2 DESC
""")
for r in cur.fetchall():
    print(f"  {str(r[0]):<20} rows={r[1]:>6}  policies={r[2]:>6}")

# 4. Sample 5 "failing" policies — what does their XML actually contain?
print("\n=== 4. Sample failing policies: source vs XML value ===")
cur.execute(r"""
SELECT F.LEGACYPOLICYNUMBER,
       MAX(C.EXCESSWAIVERFORGLASS)                                   AS SRC_VALUE,
       REGEXP_SUBSTR(MAX(F.REQUEST_XML),
           '<ExcessWaiverForGlass>([^<]*)</ExcessWaiverForGlass>',1,1,'e',1) AS XML_VALUE,
       CASE WHEN MAX(F.REQUEST_XML) ILIKE '%ExcessWaiverForGlass%' THEN 'tag present' ELSE 'TAG ABSENT' END AS TAG
FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT F
JOIN   AGGNE.DEV.PM_03 C ON TRIM(C.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
WHERE  UPPER(TRIM(C.EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
  AND  F.REQUEST_XML NOT LIKE '%<ExcessWaiverForGlass>1</ExcessWaiverForGlass>%'
GROUP BY F.LEGACYPOLICYNUMBER
LIMIT 5
""")
for r in cur.fetchall():
    print(f"  {r[0]:<15} src={str(r[1]):<10} xml={str(r[2]):<8} {r[3]}")

# 5. Does the XML contain ANY vehicle/motor section for these failing policies?
print("\n=== 5. Failing policies: does XML have a motor section at all? ===")
cur.execute(r"""
WITH failing AS (
    SELECT DISTINCT F.LEGACYPOLICYNUMBER, F.REQUEST_XML
    FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT F
    JOIN   AGGNE.DEV.PM_03 C ON TRIM(C.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
    WHERE  UPPER(TRIM(C.EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
      AND  F.REQUEST_XML NOT LIKE '%<ExcessWaiverForGlass>1</ExcessWaiverForGlass>%'
)
SELECT CASE WHEN REQUEST_XML LIKE '%<VehicleType>%' THEN 'has motor section' ELSE 'NO motor section' END,
       COUNT(*)
FROM failing GROUP BY 1
""")
for r in cur.fetchall():
    print(f"  {r[0]:<20} {r[1]}")

sf.close()
print("\nDone.")
