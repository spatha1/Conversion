"""
Run BP_GAP_ANALYSIS.sql against Snowflake and print results.
Skips the PRD_STATUS column if AGGNE.PRD.POLICY_ATTACH_TABLE is not accessible.
Read-only, SAFE_MODE enforced.
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

SQL = (ROOT / "sql/snowflake/1_conversion/BP/diagnostics/BP_GAP_ANALYSIS.sql").read_text(encoding="utf-8")

# Strip the commented-out SUMMARY section at the end
main_sql = SQL[:SQL.index("/*")].strip() if "/*" in SQL else SQL.strip()

print("Connecting to Snowflake ...")
sf  = sf_connect()
cur = sf.cursor()
print("  [OK]\n")

try:
    cur.execute(main_sql)
except Exception as e:
    if "POLICY_ATTACH_TABLE" in str(e) or "PRD" in str(e):
        print("[INFO] PRD table not accessible — rerunning without PRD column ...")
        no_prd_sql = main_sql \
            .replace(
                "-- ── PRD: policies that have been successfully attached in PRD ────────────────\n"
                "-- (= policies already migrated; compare against AGGNE.PRD.POLICY_ATTACH_TABLE)\n"
                "prd_attached AS (\n"
                "    SELECT DISTINCT TRIM(PUREPOLICYNUMBER) AS POLICY\n"
                "    FROM AGGNE.PRD.POLICY_ATTACH_TABLE\n"
                "    WHERE LINEOFBUSINESS = 'BP'\n"
                "),\n",
                "prd_attached AS (SELECT NULL::VARCHAR AS POLICY WHERE 1=0),\n"
            ) \
            .replace(
                "LEFT JOIN prd_attached ON p.POLICY = prd_attached.POLICY",
                ""
            )
        cur.execute(no_prd_sql)
    else:
        raise

cols  = [d[0] for d in cur.description]
rows  = cur.fetchall()
sf.close()

print(f"{'POLICY':<12}", end="")
for c in cols[1:]:
    print(f"{c:<25}", end="")
print()
print("-" * (12 + 25 * (len(cols)-1)))

gap_count = 0
mandatory_miss = 0

for r in rows:
    policy = str(r[0])
    print(f"{policy:<12}", end="")
    for i, v in enumerate(r[1:], 1):
        val = str(v)
        print(f"{val:<25}", end="")
    print()
    if r[cols.index("GAP_COUNT")] and int(r[cols.index("GAP_COUNT")]) > 0:
        gap_count += 1
    if r[cols.index("MANDATORY_MISSING_COUNT")] and int(r[cols.index("MANDATORY_MISSING_COUNT")]) > 0:
        mandatory_miss += 1

print()
print(f"Total policies : {len(rows)}")
print(f"Policies with GAPs              : {gap_count}")
print(f"Policies with MANDATORY_MISSING : {mandatory_miss}")
print()
print("Legend:")
print("  OK               - source has data, target has data")
print("  GAP              - source has data, target MISSING (ETL4 conversion gap)")
print("  MANDATORY_MISSING- all-policy mandatory step, NEITHER source nor target has data")
print("  N/A              - conditional section, policy has no this coverage")
print("  PRD_ATTACHED     - policy already sent to DCT in AGGNE.PRD")
print("  NOT_IN_PRD       - not yet in PRD")
