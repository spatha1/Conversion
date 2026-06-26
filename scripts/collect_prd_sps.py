"""
Collect stored procedure definitions from AGGNE.PRD and AGGNE.PRD_XML
using INFORMATION_SCHEMA.PROCEDURES (has PROCEDURE_DEFINITION column).
Saves each SP to sql/snowflake/prd/sps/<SCHEMA>/<SP_NAME>.sql
"""
import base64, hashlib
from pathlib import Path
import pyodbc
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption,
)
import snowflake.connector

ROOT    = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "sql" / "snowflake" / "prd" / "sps"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SF_CRED_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;"
    "UID=clarityAgentuser;PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

SCHEMAS = ["PRD", "PRD_XML"]
DATABASE = "AGGNE"


def _fernet_key():
    return base64.urlsafe_b64encode(hashlib.sha256(b"change-me").digest())


def decrypt(token: str) -> str:
    return Fernet(_fernet_key()).decrypt(token.encode()).decode()


def get_sf_conn():
    conn = pyodbc.connect(SF_CRED_CONN)
    cur  = conn.cursor()
    cur.execute("""
        SELECT sf_account, sf_username, sf_private_key_enc,
               sf_private_key_passphrase_enc, sf_warehouse, sf_role
        FROM [dbo].[conversion_source_connections] WHERE id = 14
    """)
    row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
    conn.close()

    pk_pem = decrypt(row["sf_private_key_enc"])
    pp     = decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
    pk_der = load_pem_private_key(
        pk_pem.encode(), password=pp.encode() if pp else None
    ).private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())

    return snowflake.connector.connect(
        account=row["sf_account"], user=row["sf_username"],
        private_key=pk_der, warehouse=row["sf_warehouse"], role=row["sf_role"],
    ), row["sf_username"]


def collect_sps_via_info_schema(cur, schema: str):
    folder = OUT_DIR / schema
    folder.mkdir(parents=True, exist_ok=True)

    print(f"\n  -- SPs in {DATABASE}.{schema} via INFORMATION_SCHEMA --")
    try:
        cur.execute(f"""
            SELECT
                PROCEDURE_NAME,
                ARGUMENT_SIGNATURE,
                PROCEDURE_LANGUAGE,
                PROCEDURE_DEFINITION
            FROM {DATABASE}.INFORMATION_SCHEMA.PROCEDURES
            WHERE PROCEDURE_SCHEMA = '{schema}'
            ORDER BY PROCEDURE_NAME
        """)
        rows = cur.fetchall()
    except Exception as e:
        print(f"    [ERROR] INFORMATION_SCHEMA query failed: {e}")
        return 0, 0

    ok = no_def = 0
    for name, sig, lang, defn in rows:
        if defn:
            header = (
                f"-- SP: {DATABASE}.{schema}.{name}\n"
                f"-- Signature: {sig}\n"
                f"-- Language:  {lang}\n"
                f"-- Collected: 2026-06-25\n\n"
            )
            (folder / f"{name}.sql").write_text(header + defn, encoding="utf-8")
            print(f"    [OK]     {name}  {sig}")
            ok += 1
        else:
            (folder / f"{name}.sql").write_text(
                f"-- {DATABASE}.{schema}.{name}{sig}\n-- Definition not accessible (role restriction)\n",
                encoding="utf-8",
            )
            print(f"    [NO DEF] {name}  {sig}  — definition null (owner-only)")
            no_def += 1

    print(f"    => {ok} with definition, {no_def} definition null")
    return ok, no_def


def try_get_ddl_fallback(cur, schema: str):
    """
    Fallback: use SHOW PROCEDURES + GET_DDL with correctly parsed argument types.
    GET_DDL signature must be just arg types e.g. 'SP_NAME(VARCHAR, VARCHAR)'
    """
    folder = OUT_DIR / schema
    folder.mkdir(parents=True, exist_ok=True)

    print(f"\n  -- GET_DDL fallback for {DATABASE}.{schema} --")
    try:
        cur.execute(f"SHOW PROCEDURES IN SCHEMA {DATABASE}.{schema}")
        rows      = cur.fetchall()
        col_names = [d[0] for d in cur.description]
        name_idx  = next(i for i, c in enumerate(col_names) if c.lower() in ("name", "procedure_name"))
        args_idx  = next((i for i, c in enumerate(col_names) if "argument" in c.lower()), None)
    except Exception as e:
        print(f"    [ERROR] SHOW PROCEDURES failed: {e}")
        return

    ok = err = 0
    for p in rows:
        sp_name  = p[name_idx]
        full_sig = p[args_idx] if args_idx is not None else ""

        # full_sig looks like "SP_NAME(VARCHAR, VARCHAR) RETURN VARCHAR"
        # Extract just the types inside the first pair of parens
        import re
        m = re.search(r'\(([^)]*)\)', full_sig)
        arg_types = m.group(1) if m else ""
        qualified = f"{DATABASE}.{schema}.{sp_name}({arg_types})"

        # Skip SYSTEM$ built-ins — they will never be accessible
        if sp_name.startswith("SYSTEM$") or sp_name in (
            "ASSOCIATE_SEMANTIC_CATEGORY_TAGS", "COMPUTE_AI_OBSERVABILITY_METRICS",
            "STORE_CLASSIFICATION", "EXECUTE_AI_EVALUATION",
            "EXECUTE_AI_OBSERVABILITY_SYNCHRONOUS_RUN",
        ):
            continue

        out_file = folder / f"{sp_name}.sql"
        if out_file.exists() and "Definition not accessible" not in out_file.read_text(encoding="utf-8"):
            print(f"    [SKIP]   {sp_name}  — already have definition")
            continue

        try:
            cur.execute(f"SELECT GET_DDL('PROCEDURE', '{qualified}')")
            row = cur.fetchone()
            ddl = row[0] if row else ""
            if ddl:
                out_file.write_text(ddl, encoding="utf-8")
                print(f"    [DDL OK] {sp_name}  ({qualified})")
                ok += 1
            else:
                print(f"    [NO DDL] {sp_name}")
                err += 1
        except Exception as e:
            print(f"    [ERR]    {sp_name}  — {str(e)[:100]}")
            err += 1

    print(f"    => GET_DDL: {ok} saved, {err} failed")


def run():
    print("=== Connecting to Snowflake ===")
    ctx, username = get_sf_conn()
    cur = ctx.cursor()
    print(f"  [OK] Connected as {username}\n")

    total_ok = total_null = 0

    for schema in SCHEMAS:
        print(f"\n{'='*60}")
        print(f"  Schema: {DATABASE}.{schema}")
        print(f"{'='*60}")

        ok, null = collect_sps_via_info_schema(cur, schema)
        total_ok   += ok
        total_null += null

        # If info schema gave no definitions, try GET_DDL with corrected signatures
        if null > 0:
            try_get_ddl_fallback(cur, schema)

    ctx.close()

    print(f"\n{'='*60}")
    print(f"  SPs with definitions : {total_ok}")
    print(f"  SPs definition null  : {total_null}")
    print(f"  Output: {OUT_DIR}")
    print(f"{'='*60}")


if __name__ == "__main__":
    run()
