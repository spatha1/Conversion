"""
Get SP definitions for the key conversion procedures via INFORMATION_SCHEMA.
Focus on DYNAMIC_XML_GENERATOR, DYNAMIC_XML_V1, SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD
and anything else that looks like the main ETL4 driver.
"""
import base64, hashlib
import pyodbc
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption
)
import snowflake.connector

OUT_DIR = Path(__file__).resolve().parent.parent / "sql" / "snowflake" / "stored_procedures"
OUT_DIR.mkdir(parents=True, exist_ok=True)

def decrypt(token):
    key = base64.urlsafe_b64encode(hashlib.sha256(b"change-me").digest())
    return Fernet(key).decrypt(token.encode()).decode()

def get_sf_conn():
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
        "DATABASE=ConversionAgent;UID=clarityAgentuser;PWD=AshuAdvi@2816;"
        "TrustServerCertificate=yes;"
    )
    cur = conn.cursor()
    cur.execute("""
        SELECT sf_account, sf_username, sf_private_key_enc,
               sf_private_key_passphrase_enc, sf_warehouse, sf_role
        FROM [dbo].[conversion_source_connections] WHERE id = 14
    """)
    row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
    conn.close()
    pk_pem = decrypt(row["sf_private_key_enc"])
    pp     = decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
    pk_der = load_pem_private_key(pk_pem.encode(), password=pp.encode() if pp else None) \
             .private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())
    return snowflake.connector.connect(
        account=row["sf_account"], user=row["sf_username"],
        private_key=pk_der, warehouse=row["sf_warehouse"], role=row["sf_role"],
    )

# Key SPs to investigate
TARGET_SPS = [
    "DYNAMIC_XML_GENERATOR",
    "DYNAMIC_XML_V1",
    "DYNAMIC_XML_V1_RISK",
    "SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD",
    "SP_POLICYATTACH_XML_INTEGRATION",
    "SP_POLICY_XML_INTEGRATION",
    "SP_PURE_TO_WRITE_LOAD",
    "COMBINEPAYLOAD",
]

def run():
    ctx = get_sf_conn()
    cur = ctx.cursor()
    print("[OK] Connected to Snowflake\n")

    for schema in ("DEV", "PRD"):
        print(f"=== AGGNE.{schema} — INFORMATION_SCHEMA.PROCEDURES ===")
        try:
            cur.execute(f"""
                SELECT PROCEDURE_NAME,
                       ARGUMENT_SIGNATURE,
                       PROCEDURE_DEFINITION
                FROM AGGNE.INFORMATION_SCHEMA.PROCEDURES
                WHERE PROCEDURE_SCHEMA = '{schema}'
                  AND PROCEDURE_NAME IN ({','.join("'" + s + "'" for s in TARGET_SPS)})
                ORDER BY PROCEDURE_NAME
            """)
            rows = cur.fetchall()
            if not rows:
                print(f"  (no matching procedures found in {schema})\n")
                continue
            for name, sig, defn in rows:
                print(f"\n--- {schema}.{name}{sig} ---")
                if defn:
                    print(defn[:5000])
                    out = OUT_DIR / f"AGGNE_{schema}_{name}.sql"
                    out.write_text(defn, encoding="utf-8")
                    print(f"  [Saved → {out.name}]")
                else:
                    print("  (definition not accessible)")
        except Exception as e:
            print(f"  Error: {e}")

        # Also try DESCRIBE PROCEDURE for argument details
        print(f"\n--- DESCRIBE key SPs in {schema} ---")
        for sp in TARGET_SPS:
            try:
                cur.execute(f"SHOW PROCEDURES LIKE '{sp}' IN SCHEMA AGGNE.{schema}")
                rows = cur.fetchall()
                for row in rows:
                    cols = [d[0] for d in cur.description]
                    d    = dict(zip(cols, row))
                    name = d.get("name", sp)
                    args = d.get("arguments", d.get("signature", ""))
                    print(f"  {name}  →  {args}")
            except Exception as e:
                pass

    ctx.close()
    print("\n=== Done ===")

if __name__ == "__main__":
    run()
