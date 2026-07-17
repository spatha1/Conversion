"""Debug ATP-11003 part 2: why do 1,125 policies with PM_03 glass=Yes have no motor section? Read-only."""
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

# 1. PM_03 load dates — is there more than one batch in the table?
print("=== 1. PM_03 LOAD_DATE distribution ===")
cur.execute("""
SELECT CAST(LOAD_DATE AS DATE) AS D, COUNT(*) AS ROWS_, COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)) AS POLICIES
FROM AGGNE.DEV.PM_03 GROUP BY 1 ORDER BY 1 DESC
""")
for r in cur.fetchall():
    print(f"  {r[0]}  rows={r[1]:>6}  policies={r[2]:>6}")

# 2. For the 1,125 no-motor-section policies: MOTOR_INDICATOR in the XML?
print("\n=== 2. No-motor-section failing policies: PrivateMotorVehicles indicator ===")
cur.execute(r"""
WITH failing AS (
    SELECT DISTINCT F.LEGACYPOLICYNUMBER, F.REQUEST_XML
    FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT F
    JOIN   AGGNE.DEV.PM_03 C ON TRIM(C.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
    WHERE  UPPER(TRIM(C.EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
      AND  F.REQUEST_XML NOT LIKE '%<ExcessWaiverForGlass>1</ExcessWaiverForGlass>%'
      AND  F.REQUEST_XML NOT LIKE '%<VehicleType>%'
)
SELECT REGEXP_SUBSTR(REQUEST_XML,'<PrivateMotorVehicles>(.*?)</PrivateMotorVehicles>',1,1,'e',1) AS PMV,
       COUNT(*) AS POLICIES
FROM failing GROUP BY 1
""")
for r in cur.fetchall():
    print(f"  PMV={str(r[0]):<6} policies={r[1]}")

# 3. Are those policies' vehicles in latest PM_03 batch or only in old batches?
print("\n=== 3. Failing no-motor policies: latest PM_03 batch membership ===")
cur.execute(r"""
WITH failing AS (
    SELECT DISTINCT F.LEGACYPOLICYNUMBER
    FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT F
    JOIN   AGGNE.DEV.PM_03 C ON TRIM(C.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
    WHERE  UPPER(TRIM(C.EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
      AND  F.REQUEST_XML NOT LIKE '%<ExcessWaiverForGlass>1</ExcessWaiverForGlass>%'
      AND  F.REQUEST_XML NOT LIKE '%<VehicleType>%'
),
latest AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.PM_03)
SELECT CASE WHEN L.LEGACYPOLICYNUMBER IS NOT NULL THEN 'in latest PM_03 batch' ELSE 'only in OLD batch' END,
       COUNT(*)
FROM failing F
LEFT JOIN (
    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS LEGACYPOLICYNUMBER
    FROM AGGNE.DEV.PM_03, latest
    WHERE CAST(LOAD_DATE AS DATE) = latest.D
      AND UPPER(TRIM(EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
) L ON L.LEGACYPOLICYNUMBER = TRIM(F.LEGACYPOLICYNUMBER)
GROUP BY 1
""")
for r in cur.fetchall():
    print(f"  {r[0]:<25} {r[1]}")

# 4. The 33 with motor section: vehicle-level detail
print("\n=== 4. The 33 with motor section but glass<>1: XML glass values ===")
cur.execute(r"""
WITH failing AS (
    SELECT DISTINCT F.LEGACYPOLICYNUMBER, F.REQUEST_XML
    FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT F
    JOIN   AGGNE.DEV.PM_03 C ON TRIM(C.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
    WHERE  UPPER(TRIM(C.EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
      AND  F.REQUEST_XML NOT LIKE '%<ExcessWaiverForGlass>1</ExcessWaiverForGlass>%'
      AND  F.REQUEST_XML LIKE '%<VehicleType>%'
)
SELECT LEGACYPOLICYNUMBER,
       CASE WHEN REQUEST_XML LIKE '%<ExcessWaiverForGlass>%' THEN 'tag present (=0)' ELSE 'tag absent' END AS GLASS_TAG
FROM failing
ORDER BY 1 LIMIT 40
""")
rows = cur.fetchall()
from collections import Counter
c = Counter(r[1] for r in rows)
for k, v in c.items():
    print(f"  {k:<20} {v}")
print("  policies:", ", ".join(r[0] for r in rows[:10]), "...")

# 5. Glass tag by protection type — is the tag only emitted for Comprehensive?
print("\n=== 5. Latest PM_03 batch: glass=Yes policies by PROTECTIONTYPE ===")
cur.execute("""
WITH latest AS (SELECT MAX(CAST(LOAD_DATE AS DATE)) AS D FROM AGGNE.DEV.PM_03)
SELECT PROTECTIONTYPE, COUNT(DISTINCT TRIM(PUREPOLICYNUMBER)) AS POLICIES
FROM AGGNE.DEV.PM_03, latest
WHERE CAST(LOAD_DATE AS DATE) = latest.D
  AND UPPER(TRIM(EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
GROUP BY 1 ORDER BY 2 DESC
""")
for r in cur.fetchall():
    print(f"  {str(r[0]):<40} {r[1]}")

sf.close()
print("\nDone.")
