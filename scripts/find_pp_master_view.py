"""
Find the PP master consolidation view in Snowflake — the equivalent of
VW_CBP_OUTPUT_CONVERSION for the PP (Personal Pack) LOB.

Strategy:
  1. Look at PP_ConversionConfig target tables to know which *_Target tables
     PP writes to, then find the view that reads from them.
  2. List all AGGNE.DEV views with PER_ / PP_ / VW_PP_ prefix.
  3. For each candidate, print first 600 chars so we can spot the one
     that does many LEFT JOINs across PP *_Target tables.

Read-only — no writes, no SP calls.
"""
import base64, hashlib
import pyodbc
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption,
)
import snowflake.connector

_CA_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;UID=clarityAgentuser;PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)
_CV_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=Conversion;UID=clarityAgentuser;PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)


def decrypt(token):
    key = base64.urlsafe_b64encode(hashlib.sha256(b"change-me").digest())
    return Fernet(key).decrypt(token.encode()).decode()


def get_sf():
    conn = pyodbc.connect(_CA_CONN)
    cur = conn.cursor()
    cur.execute("""
        SELECT sf_account, sf_username, sf_private_key_enc,
               sf_private_key_passphrase_enc, sf_warehouse, sf_role
        FROM [dbo].[conversion_source_connections] WHERE id = 14
    """)
    row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
    conn.close()
    pk_pem = decrypt(row["sf_private_key_enc"])
    pp_pass = decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
    pk_der = load_pem_private_key(pk_pem.encode(), password=pp_pass.encode() if pp_pass else None) \
             .private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())
    return snowflake.connector.connect(
        account=row["sf_account"], user=row["sf_username"],
        private_key=pk_der, warehouse=row["sf_warehouse"], role=row["sf_role"],
    )


def get_pp_target_tables():
    """Read PP_ConversionConfig to find which target tables PP writes to."""
    conn = pyodbc.connect(_CV_CONN)
    cur = conn.cursor()
    cur.execute("""
        SELECT DISTINCT ConversionTargetTable
        FROM [dbo].[PP_ConversionConfig]
        WHERE IsActive = 1 AND ConversionTargetTable IS NOT NULL
        ORDER BY ConversionTargetTable
    """)
    targets = [r[0].strip().upper() for r in cur.fetchall() if r[0]]
    conn.close()
    return targets


def run():
    # Step 1 — PP target tables from config
    print("=== PP Target tables (from PP_ConversionConfig) ===")
    try:
        pp_targets = get_pp_target_tables()
        for t in pp_targets:
            print(f"  {t}")
    except Exception as e:
        print(f"  Could not read PP_ConversionConfig: {e}")
        pp_targets = []

    # Step 2 — Connect to Snowflake and list candidate views
    ctx = get_sf()
    cur = ctx.cursor()
    print("\n[OK] Snowflake connected\n")

    cur.execute("SHOW VIEWS IN SCHEMA AGGNE.DEV")
    rows = cur.fetchall()
    cols = [d[0] for d in cur.description]
    name_idx = next(i for i, c in enumerate(cols) if c.lower() == "name")
    all_views = [r[name_idx] for r in rows]

    # Candidates: views with PP/PER prefix, or containing OUTPUT/FINAL/PAYLOAD
    candidates = [
        v for v in all_views
        if any(v.upper().startswith(p) for p in ("PER_", "PP_", "VW_PP", "VW_PER"))
        or any(k in v.upper() for k in ("PP_OUTPUT", "PER_OUTPUT", "PP_FINAL", "PER_FINAL"))
    ]
    print(f"=== Candidate PP views in AGGNE.DEV ({len(candidates)}) ===")
    for v in sorted(candidates):
        print(f"  {v}")

    # Step 3 — Peek at each candidate's DDL
    print("\n=== DDL preview (first 800 chars) ===")
    for vname in sorted(candidates):
        try:
            cur.execute(f"SELECT GET_DDL('VIEW', 'AGGNE.DEV.{vname}')")
            row = cur.fetchone()
            if row:
                body = row[0]
                # Count how many LEFT JOINs — high count = likely master view
                join_count = body.upper().count("LEFT JOIN")
                print(f"\n[{vname}]  LEFT JOINs={join_count}  len={len(body):,}")
                print(body[:800].replace("\n", " "))
        except Exception as e:
            print(f"\n[{vname}] error: {e}")

    ctx.close()


if __name__ == "__main__":
    run()
