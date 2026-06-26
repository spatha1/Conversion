"""
Fetch the Pure Snowflake connection from SQL Server,
decrypt private key + passphrase using the Fernet key derived
from the Ai-Conversion app's SECRET_KEY, then test Snowflake.
"""
import sys, base64, hashlib, os
import pyodbc
from cryptography.fernet import Fernet, InvalidToken

SQLSERVER_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
)

# ── Fernet key derivation (mirrors api/config.py) ──
def derive_fernet_key(secret_key: str, encryption_key: str = "") -> bytes:
    raw = encryption_key.strip()
    if raw:
        try:
            key_bytes = base64.urlsafe_b64decode(raw + "==")
            if len(key_bytes) == 32:
                return base64.urlsafe_b64encode(key_bytes)
        except Exception:
            pass
    digest = hashlib.sha256(secret_key.encode()).digest()
    return base64.urlsafe_b64encode(digest)

def try_decrypt(token: str, secret_key: str, encryption_key: str = "") -> str | None:
    try:
        fkey = derive_fernet_key(secret_key, encryption_key)
        f = Fernet(fkey)
        return f.decrypt(token.encode()).decode()
    except (InvalidToken, Exception):
        return None

# ── Fetch raw row ──
def fetch_pure():
    conn = pyodbc.connect(SQLSERVER_CONN)
    cur = conn.cursor()
    cur.execute("""
        SELECT sf_account, sf_warehouse, sf_role, sf_database, sf_schema,
               sf_username, sf_private_key_enc, sf_private_key_passphrase_enc
        FROM [ConversionAgent].[dbo].[conversion_source_connections]
        WHERE id = 14
    """)
    cols = [d[0] for d in cur.description]
    row = dict(zip(cols, cur.fetchone()))
    conn.close()
    return row

if __name__ == "__main__":
    row = fetch_pure()

    pk_enc  = row["sf_private_key_enc"]
    pp_enc  = row["sf_private_key_passphrase_enc"]

    # Try candidate secret keys
    candidates = [
        ("change-me", ""),           # app default
        ("clarity2024", ""),         # ADMIN_PASSWORD used as key?
        ("Clarity@2026", ""),        # DB password
    ]

    private_key_pem = None
    passphrase      = None
    matched_key     = None

    for sk, ek in candidates:
        result = try_decrypt(pk_enc, sk, ek)
        if result:
            private_key_pem = result
            passphrase      = try_decrypt(pp_enc, sk, ek) if pp_enc else None
            matched_key     = sk
            break

    if not private_key_pem:
        print("ERROR: Could not decrypt private key with any known candidate key.")
        print("  Please provide the SECRET_KEY or ENCRYPTION_KEY used by the Ai-Conversion app.")
        sys.exit(1)

    print(f"[OK] Decrypted with SECRET_KEY='{matched_key}'")
    print(f"  passphrase: {'(set)' if passphrase else '(none)'}")
    print(f"  private key starts with: {private_key_pem[:50]}...")

    # ── Test Snowflake connection ──
    print("\n[...] Testing Snowflake connection...")
    try:
        from cryptography.hazmat.primitives.serialization import (
            load_pem_private_key, Encoding, PrivateFormat, NoEncryption
        )
        import snowflake.connector

        pk_bytes = private_key_pem.encode()
        pp_bytes = passphrase.encode() if passphrase else None
        private_key_obj = load_pem_private_key(pk_bytes, password=pp_bytes)
        private_key_der = private_key_obj.private_bytes(
            encoding=Encoding.DER,
            format=PrivateFormat.PKCS8,
            encryption_algorithm=NoEncryption()
        )

        ctx = snowflake.connector.connect(
            account   = row["sf_account"],
            user      = row["sf_username"],
            private_key = private_key_der,
            warehouse = row["sf_warehouse"],
            database  = row["sf_database"],
            schema    = row["sf_schema"],
            role      = row["sf_role"],
        )
        cur = ctx.cursor()
        cur.execute("SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_WAREHOUSE()")
        result = cur.fetchone()
        ctx.close()

        print("[OK] Snowflake connection successful!")
        print(f"  USER      : {result[0]}")
        print(f"  ROLE      : {result[1]}")
        print(f"  DATABASE  : {result[2]}")
        print(f"  SCHEMA    : {result[3]}")
        print(f"  WAREHOUSE : {result[4]}")

        # Write to .env
        env_path = os.path.join(os.path.dirname(__file__), "..", ".env")
        with open(env_path, "r") as f:
            env_content = f.read()

        updates = {
            "SF_SOURCE_ACCOUNT":   row["sf_account"],
            "SF_SOURCE_USER":      row["sf_username"],
            "SF_SOURCE_WAREHOUSE": row["sf_warehouse"],
            "SF_SOURCE_DATABASE":  row["sf_database"],
            "SF_SOURCE_SCHEMA":    row["sf_schema"],
            "SF_SOURCE_ROLE":      row["sf_role"],
            "SF_STAGING_ACCOUNT":  row["sf_account"],
            "SF_STAGING_USER":     row["sf_username"],
            "SF_STAGING_WAREHOUSE":row["sf_warehouse"],
            "SF_STAGING_ROLE":     row["sf_role"],
            "SQLSERVER_HOST":      r"DESKTOP-G01PH8C\SQLEXPRESS",
            "SQLSERVER_DATABASE":  "ConversionAgent",
            "SQLSERVER_USER":      "clarityAgentuser",
            "SQLSERVER_PASSWORD":  "AshuAdvi@2816",
        }

        import re
        for key, val in updates.items():
            env_content = re.sub(
                rf"^({re.escape(key)}=).*$",
                lambda m, v=val: m.group(1) + v,
                env_content,
                flags=re.MULTILINE
            )

        with open(env_path, "w") as f:
            f.write(env_content)

        print("\n[OK] .env updated with Pure Snowflake + SQL Server connection values.")
        print("  NOTE: Private key passphrase stored separately — do NOT commit .env.")

    except Exception as e:
        print(f"[FAIL] Snowflake connection failed: {e}")
        sys.exit(1)
