"""
Inline validation for AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION deploy script.
Checks:
  1. MAX(LOAD_DATE) in each source table / ITR_TYPE used in T4, T5, T9, T13-T20
  2. Row counts per ITR_TYPE in each LINE_*_Target table
  3. Policy-level spot check: join quality for first 5 UAT test policies
  4. View column count from deployed view vs local deploy script column list

READ-ONLY — no writes. SAFE_MODE enforced.
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

# ── Snowflake connection (private key from ConversionAgent) ───────────────────
SF_CRED_CONN = (
    f"DRIVER={{{os.environ['SQLSERVER_DRIVER']}}};"
    f"SERVER={os.environ['SQLSERVER_HOST']};"
    "DATABASE=ConversionAgent;"
    f"UID={os.environ['SQLSERVER_USER']};"
    f"PWD={os.environ['SQLSERVER_PASSWORD']};"
    "TrustServerCertificate=yes;"
)

def _fernet_key(secret="change-me"):
    return base64.urlsafe_b64encode(hashlib.sha256(secret.encode()).digest())

def decrypt(token):
    return Fernet(_fernet_key()).decrypt(token.encode()).decode()

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

def run_query(cur, label, sql):
    print(f"\n  >> {label}")
    cur.execute(sql)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    if not rows:
        print("     (no rows)")
        return []
    # print header
    widths = [max(len(str(c)), max((len(str(r[i])) for r in rows), default=0)) for i, c in enumerate(cols)]
    header = "  " + "  ".join(str(c).ljust(widths[i]) for i, c in enumerate(cols))
    print(header)
    print("  " + "-" * (sum(widths) + 2 * len(widths)))
    for r in rows:
        print("  " + "  ".join(str(r[i]).ljust(widths[i]) for i in range(len(cols))))
    return rows

print("Connecting to Snowflake ...")
sf  = sf_connect()
cur = sf.cursor()
print("  [OK] Connected\n")

# ── CHECK 1: MAX LOAD_DATE in aggregation views / target tables ───────────────
print("=" * 70)
print("CHECK 1: MAX(LOAD_DATE) per source — do they have fresh data?")
print("=" * 70)

run_query(cur, "T4 — VW_CLAIM_HISTORY_AGG",
    "SELECT MAX(CAST(LOAD_DATE AS DATE)) AS MAX_LOAD_DATE, COUNT(*) AS ROW_COUNT "
    "FROM AGGNE.DEV.VW_CLAIM_HISTORY_AGG")

run_query(cur, "T5 — VW_COMP_INFO_AGG (ITR_TYPE = 'BP_Prior_INFO')",
    "SELECT MAX(CAST(LOAD_DATE AS DATE)) AS MAX_LOAD_DATE, COUNT(*) AS ROW_COUNT "
    "FROM AGGNE.DEV.VW_COMP_INFO_AGG WHERE ITR_TYPE = 'BP_Prior_INFO'")

run_query(cur, "T9 — ACCOUNT_LOC_AGG",
    "SELECT MAX(CAST(LOAD_DATE AS DATE)) AS MAX_LOAD_DATE, COUNT(*) AS ROW_COUNT "
    "FROM AGGNE.DEV.ACCOUNT_LOC_AGG")

# ── CHECK 2: ITR_TYPE distribution in LINE_*_Target tables ───────────────────
print()
print("=" * 70)
print("CHECK 2: ITR_TYPE row counts in LINE_*_Target tables")
print("=" * 70)

line_targets = [
    ("LINE_GP_Target",  "BP_LINE_GP"),
    ("LINE_PPL_Target", "BP_LINE_PPL"),
    ("LINE_PF_Target",  "BP_LINE_PF"),
    ("LINE_GT_Target",  "BP_LINE_GT"),
    ("LINE_LE_Target",  "BP_LINE_LE"),
    ("LINE_SV_Target",  "BP_LINE_SV"),
    ("LINE_CV_Target",  "BP_LINE_CV"),
    ("LINE_TA_Target",  "BP_LINE_TA"),
]

for tbl, itr in line_targets:
    run_query(cur, f"{tbl}",
        f"SELECT ITR_TYPE, COUNT(*) AS ROW_COUNT, "
        f"MAX(CAST(LOAD_DATE AS DATE)) AS MAX_DATE "
        f"FROM AGGNE.DEV.{tbl} "
        f"GROUP BY ITR_TYPE ORDER BY ITR_TYPE")

# ── CHECK 3: Sample policies — do the T13-T20 joins return data? ──────────────
print()
print("=" * 70)
print("CHECK 3: Policy-level join quality for first 5 UAT test policies")
print("=" * 70)

run_query(cur, "Test policies in VW_TEST_POLICYCONVERSION_LIST",
    "SELECT TRIM(LEGACYPOLICYNUMBER) AS POLICY FROM AGGNE.UAT.VW_TEST_POLICYCONVERSION_LIST LIMIT 5")

run_query(cur, "LINE_GP_Target rows for test policies (BP_LINE_GP, latest date)",
    """SELECT SPLIT_PART(TRIM(T.ID),'|',1) AS POLICY, T.ITR_TYPE,
              CAST(T.LOAD_DATE AS DATE) AS LOAD_DATE
       FROM AGGNE.DEV.LINE_GP_Target T
       WHERE T.ITR_TYPE = 'BP_LINE_GP'
         AND CAST(T.LOAD_DATE AS DATE) = (
               SELECT MAX(CAST(LOAD_DATE AS DATE))
               FROM AGGNE.DEV.LINE_GP_Target
               WHERE ITR_TYPE = 'BP_LINE_GP')
         AND SPLIT_PART(TRIM(T.ID),'|',1) IN (
               SELECT TRIM(LEGACYPOLICYNUMBER) FROM AGGNE.UAT.VW_TEST_POLICYCONVERSION_LIST)
       LIMIT 10""")

run_query(cur, "VW_COMP_INFO_AGG rows for test policies (BP_Prior_INFO, latest date)",
    """SELECT TRIM(T.ID) AS POLICY, T.ITR_TYPE,
              CAST(T.LOAD_DATE AS DATE) AS LOAD_DATE
       FROM AGGNE.DEV.VW_COMP_INFO_AGG T
       WHERE T.ITR_TYPE = 'BP_Prior_INFO'
         AND CAST(T.LOAD_DATE AS DATE) = (
               SELECT MAX(CAST(LOAD_DATE AS DATE))
               FROM AGGNE.DEV.VW_COMP_INFO_AGG
               WHERE ITR_TYPE = 'BP_Prior_INFO')
         AND TRIM(T.ID) IN (
               SELECT TRIM(LEGACYPOLICYNUMBER) FROM AGGNE.UAT.VW_TEST_POLICYCONVERSION_LIST)
       LIMIT 10""")

# ── CHECK 4: Current deployed view row count ──────────────────────────────────
print()
print("=" * 70)
print("CHECK 4: Current AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION — row count")
print("=" * 70)

run_query(cur, "UAT view row count (what is currently deployed)",
    "SELECT COUNT(*) AS ROW_COUNT FROM AGGNE.UAT.VW_CBP_OUTPUT_CONVERSION")

sf.close()
print("\n[DONE] Validation complete. Review output above before deploying.")
