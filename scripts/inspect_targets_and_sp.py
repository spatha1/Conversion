"""
1. Collect all unique ConversionTargetTable + AttachTargetTable from config
2. Get column definitions for each target table in Snowflake
3. Find stored procedures in AGGNE (DEV + PRD schemas)
4. Show SP DDL for any that look like the generic conversion SP
"""
import os, base64, hashlib
import pyodbc
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption
)
import snowflake.connector

ROOT      = Path(__file__).resolve().parent.parent
OUT_DIR   = ROOT / "sql" / "snowflake" / "stored_procedures"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SS_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "TrustServerCertificate=yes;"
    "UID=clarityAgentuser;PWD=AshuAdvi@2816;"
)

def _fernet_key():
    return base64.urlsafe_b64encode(hashlib.sha256(b"change-me").digest())

def decrypt(token):
    return Fernet(_fernet_key()).decrypt(token.encode()).decode()

def get_sf_conn():
    conn = pyodbc.connect(SS_CONN + "DATABASE=ConversionAgent;")
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
    pk_der = load_pem_private_key(pk_pem.encode(), password=pp.encode() if pp else None)\
             .private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())
    return snowflake.connector.connect(
        account=row["sf_account"], user=row["sf_username"],
        private_key=pk_der, warehouse=row["sf_warehouse"], role=row["sf_role"],
    )

def get_target_tables():
    """Return dict: {(db,schema,table): lob} from both config tables."""
    tables = {}
    conn = pyodbc.connect(SS_CONN + "DATABASE=PolicyConversion;")
    cur  = conn.cursor()
    for cfg_table, lob in [("ConversionConfig","BP"), ("PP_ConversionConfig","PP")]:
        for col in ("ConversionTargetTable", "AttachTargetTable"):
            cur.execute(f"SELECT DISTINCT [{col}], ScriptName FROM [dbo].[{cfg_table}] WHERE [{col}] IS NOT NULL")
            for name, script in cur.fetchall():
                parts = name.strip().split(".")
                if len(parts) == 3:
                    key = (parts[0].upper(), parts[1].upper(), parts[2].upper())
                    tables.setdefault(key, []).append(f"{lob}:{script}")
    conn.close()
    return tables

def run():
    print("=== Connecting to Snowflake ===")
    ctx = get_sf_conn()
    cur = ctx.cursor()
    print("  [OK] Connected\n")

    # ── 1. Target table schemas ──
    targets = get_target_tables()
    print(f"=== Target tables ({len(targets)} unique) ===")

    table_schemas = {}   # (db,schema,table) -> [col defs]
    for (db, schema, tbl), scripts in sorted(targets.items()):
        try:
            cur.execute(f"""
                SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
                FROM {db}.INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = '{schema}' AND TABLE_NAME = '{tbl}'
                ORDER BY ORDINAL_POSITION
            """)
            cols = cur.fetchall()
            table_schemas[(db, schema, tbl)] = cols
            col_str = ", ".join(f"{c[0]}({c[1]})" for c in cols)
            print(f"\n  [{db}.{schema}.{tbl}]")
            print(f"  Scripts: {', '.join(scripts)}")
            for c in cols:
                maxlen = f"({c[2]})" if c[2] else ""
                null   = "NULL" if c[3] == "YES" else "NOT NULL"
                print(f"    {c[0]:<40} {c[1]}{maxlen}  {null}")
        except Exception as e:
            print(f"\n  [{db}.{schema}.{tbl}]  ERROR: {e}")

    # ── 2. Find stored procedures ──
    print("\n\n=== Stored Procedures in AGGNE ===")
    for schema in ("DEV", "PRD"):
        try:
            cur.execute(f"SHOW PROCEDURES IN SCHEMA AGGNE.{schema}")
            procs = cur.fetchall()
            # columns: created_on, name, schema_name, ...
            col_names = [d[0] for d in cur.description]
            name_idx  = next(i for i,c in enumerate(col_names) if c.lower() in ("name","procedure_name"))
            print(f"\n  AGGNE.{schema} — {len(procs)} procedure(s)")
            for p in procs:
                print(f"    {p[name_idx]}")
        except Exception as e:
            print(f"  AGGNE.{schema} — error: {e}")

    # ── 3. Get DDL for every SP found ──
    print("\n\n=== SP Definitions ===")
    for schema in ("DEV", "PRD"):
        try:
            cur.execute(f"SHOW PROCEDURES IN SCHEMA AGGNE.{schema}")
            procs = cur.fetchall()
            col_names = [d[0] for d in cur.description]
            name_idx  = next(i for i,c in enumerate(col_names) if c.lower() in ("name","procedure_name"))
            args_idx  = next((i for i,c in enumerate(col_names) if "argument" in c.lower()), None)

            for p in procs:
                proc_name = p[name_idx]
                args_hint = p[args_idx] if args_idx is not None else ""
                print(f"\n--- AGGNE.{schema}.{proc_name} ---")
                print(f"  Signature hint: {args_hint}")
                try:
                    cur.execute(f"SELECT GET_DDL('PROCEDURE', 'AGGNE.{schema}.{proc_name}')")
                    ddl = cur.fetchone()
                    if ddl:
                        ddl_text = ddl[0]
                        print(ddl_text[:3000])   # first 3000 chars
                        # Save full DDL
                        out = OUT_DIR / f"AGGNE_{schema}_{proc_name}.sql"
                        out.write_text(ddl_text, encoding="utf-8")
                        print(f"  [Saved: {out.name}]")
                except Exception as e2:
                    print(f"  GET_DDL error: {e2}")
                    # Try with argument signature
                    try:
                        cur.execute(f"SELECT GET_DDL('PROCEDURE', 'AGGNE.{schema}.{proc_name}({args_hint})')")
                        ddl = cur.fetchone()
                        if ddl:
                            ddl_text = ddl[0]
                            print(ddl_text[:3000])
                            out = OUT_DIR / f"AGGNE_{schema}_{proc_name}.sql"
                            out.write_text(ddl_text, encoding="utf-8")
                            print(f"  [Saved: {out.name}]")
                    except Exception as e3:
                        print(f"  Retry error: {e3}")
        except Exception as e:
            print(f"  {schema} — {e}")

    ctx.close()
    print("\n=== Done ===")

if __name__ == "__main__":
    run()
