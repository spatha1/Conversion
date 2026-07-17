"""
Validate the July 2026 PP fixes against AGGNE.DEV.PER_POLICY_MIGRATION_DCT.
One PASS/FAIL row per fix. Read-only, SAFE_MODE enforced.
"""
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

assert os.environ.get("SAFE_MODE", "true").lower() == "true", "SAFE_MODE must be true"

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

SQL = r"""
WITH src AS (
    SELECT LEGACYPOLICYNUMBER, REQUEST_XML
    FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT
),
f_inception AS (
    SELECT COUNT(*) AS bad FROM src
    WHERE  TRIM(IFNULL(REGEXP_SUBSTR(REQUEST_XML,'<InceptionDate>(.*?)</InceptionDate>',1,1,'e',1),'')) = ''
),
f_hbc_pmv AS (
    SELECT COUNT(*) AS bad FROM src
    WHERE  REGEXP_SUBSTR(REQUEST_XML,'<HomeBuildingsContents>(.*?)</HomeBuildingsContents>',1,1,'e',1) IS NULL
       OR  REGEXP_SUBSTR(REQUEST_XML,'<PrivateMotorVehicles>(.*?)</PrivateMotorVehicles>',1,1,'e',1)   IS NULL
),
f_motor_leak AS (
    SELECT COUNT(*) AS bad FROM src
    WHERE  REGEXP_SUBSTR(REQUEST_XML,'<PrivateMotorVehicles>(.*?)</PrivateMotorVehicles>',1,1,'e',1) = '1'
      AND  REGEXP_SUBSTR(REQUEST_XML,'<HomeBuildingsContents>(.*?)</HomeBuildingsContents>',1,1,'e',1) = '0'
      AND  REQUEST_XML LIKE '%<RoofConstruction>%'
),
f_override AS (
    SELECT COUNT(*) AS bad FROM src
    WHERE  REQUEST_XML LIKE '%<VehicleType>%'
      AND  (REQUEST_XML LIKE '%<Override>0</Override>%' OR REQUEST_XML LIKE '%<Override></Override>%')
),
f_vehicletype AS (
    SELECT COUNT(*) AS bad FROM src
    WHERE  REQUEST_XML LIKE '%<VehicleType>Passenger Vehicle%'
       OR  REQUEST_XML LIKE '%<VehicleType>Motor Cycle%'
       OR  REQUEST_XML LIKE '%<VehicleType>Light Commercial%'
       OR  REQUEST_XML LIKE '%<VehicleType>Heavy Commercial%'
),
f_protection AS (
    SELECT COUNT(*) AS bad FROM src
    WHERE  REQUEST_XML LIKE '%<ProtectionType>Comprehensive - %'
       OR  REQUEST_XML LIKE '%<ProtectionType>Third Party Property%'
       OR  REQUEST_XML LIKE '%<ProtectionType>Third Party Fire%'
),
f_glass AS (
    SELECT COUNT(DISTINCT F.LEGACYPOLICYNUMBER) AS bad
    FROM   AGGNE.DEV.PER_POLICY_MIGRATION_DCT  F
    JOIN   AGGNE.DEV.PM_03                      C  ON TRIM(C.PUREPOLICYNUMBER) = TRIM(F.LEGACYPOLICYNUMBER)
    WHERE  UPPER(TRIM(C.EXCESSWAIVERFORGLASS)) IN ('TAKEN','YES')
      AND  F.REQUEST_XML NOT LIKE '%<ExcessWaiverForGlass>1</ExcessWaiverForGlass>%'
),
f_tokens AS (
    SELECT COUNT(*) AS bad FROM src
    WHERE  REQUEST_XML REGEXP '.*\\{[A-Z_0-9]+\\}.*'
)
SELECT 'ATP-10962'   AS TICKET, 'InceptionDate populated'                              AS FIX_DESCRIPTION, bad AS BAD_POLICIES, CASE WHEN bad=0 THEN 'PASS' ELSE 'FAIL' END AS STATUS FROM f_inception
UNION ALL
SELECT 'ATP-10965',   'Coverage Indicators (HBC/PMV present)',                          bad, CASE WHEN bad=0 THEN 'PASS' ELSE 'FAIL' END FROM f_hbc_pmv
UNION ALL
SELECT 'ATP-10965',   'Motor-only: no building section leaking',                        bad, CASE WHEN bad=0 THEN 'PASS' ELSE 'FAIL' END FROM f_motor_leak
UNION ALL
SELECT 'PP-CF-26',    'Override=1 on all motor vehicles',                               bad, CASE WHEN bad=0 THEN 'PASS' ELSE 'FAIL' END FROM f_override
UNION ALL
SELECT 'VehicleType', 'VehicleType camelCase (no spaces)',                              bad, CASE WHEN bad=0 THEN 'PASS' ELSE 'FAIL' END FROM f_vehicletype
UNION ALL
SELECT 'ProtectionType','ProtectionType camelCase (no dashes/spaces)',                  bad, CASE WHEN bad=0 THEN 'PASS' ELSE 'FAIL' END FROM f_protection
UNION ALL
SELECT 'ATP-11003',   'ExcessWaiverForGlass: Taken/Yes -> 1',                           bad, CASE WHEN bad=0 THEN 'PASS' ELSE 'FAIL' END FROM f_glass
UNION ALL
SELECT 'Tokens',      'No unreplaced {TOKEN} in XML',                                   bad, CASE WHEN bad=0 THEN 'PASS' ELSE 'FAIL' END FROM f_tokens
ORDER BY STATUS, TICKET
"""

COUNT_SQL = """
SELECT COUNT(*) AS TOTAL_ROWS, COUNT(DISTINCT LEGACYPOLICYNUMBER) AS UNIQUE_POLICIES
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
"""

print("Connecting to Snowflake ...")
sf  = sf_connect()
cur = sf.cursor()

cur.execute(COUNT_SQL)
total, uniq = cur.fetchone()
print(f"\nPER_POLICY_MIGRATION_DCT: {total} rows, {uniq} unique policies\n")

cur.execute(SQL)
rows = cur.fetchall()
w1 = max(len(r[0]) for r in rows) + 2
w2 = max(len(r[1]) for r in rows) + 2
print(f"{'TICKET':<{w1}}{'FIX':<{w2}}{'BAD':>6}  STATUS")
print("-" * (w1 + w2 + 14))
for t, d, bad, status in rows:
    print(f"{t:<{w1}}{d:<{w2}}{bad:>6}  {status}")

sf.close()
print("\nDone.")
