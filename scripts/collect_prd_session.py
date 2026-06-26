"""
Collect all PRD-schema objects from Snowflake and save to sql/snowflake/prd/.

Targets:
  AGGNE.PRD     — attach views, stored procedures, tables
  AGGNE.PRD_XML — XML staging schema (if it exists in Snowflake)

Output layout:
  sql/snowflake/prd/views/<SCHEMA>/<VIEW>.sql
  sql/snowflake/prd/sps/<SCHEMA>/<SP>.sql
  sql/snowflake/prd/tables/<SCHEMA>/<TABLE>.sql   (CREATE TABLE DDL)
  sql/snowflake/prd/_inventory.txt                 (summary of everything found)
"""
import base64, hashlib, sys
from pathlib import Path
import pyodbc
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    load_pem_private_key, Encoding, PrivateFormat, NoEncryption,
)
import snowflake.connector

ROOT    = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "sql" / "snowflake" / "prd"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SF_CRED_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=ConversionAgent;"
    "UID=clarityAgentuser;PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

SCHEMAS_TO_COLLECT = ["PRD", "PRD_XML"]
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


def save(folder: Path, name: str, text: str) -> Path:
    folder.mkdir(parents=True, exist_ok=True)
    p = folder / f"{name}.sql"
    p.write_text(text, encoding="utf-8")
    return p


def collect_views(cur, schema: str, inventory: list):
    print(f"\n  -- Views in {DATABASE}.{schema} --")
    try:
        cur.execute(f"""
            SELECT TABLE_NAME
            FROM {DATABASE}.INFORMATION_SCHEMA.VIEWS
            WHERE TABLE_SCHEMA = '{schema}'
            ORDER BY TABLE_NAME
        """)
        views = [r[0] for r in cur.fetchall()]
    except Exception as e:
        print(f"    [ERROR listing views] {e}")
        return

    folder = OUT_DIR / "views" / schema
    ok = err = 0
    for v in views:
        try:
            cur.execute(f"SELECT GET_DDL('VIEW', '{DATABASE}.{schema}.{v}')")
            row = cur.fetchone()
            ddl = row[0] if row else ""
            save(folder, v, ddl)
            print(f"    [VIEW  OK] {v}")
            inventory.append(f"VIEW   {DATABASE}.{schema}.{v}")
            ok += 1
        except Exception as e:
            msg = f"-- ERROR: {e}\n"
            save(folder, v, msg)
            print(f"    [VIEW ERR] {v}  — {e}")
            inventory.append(f"VIEW   {DATABASE}.{schema}.{v}  [ERROR]")
            err += 1

    print(f"    => {ok} saved, {err} errors")


def collect_sps(cur, schema: str, inventory: list):
    print(f"\n  -- Stored Procedures in {DATABASE}.{schema} --")
    try:
        cur.execute(f"SHOW PROCEDURES IN SCHEMA {DATABASE}.{schema}")
        rows     = cur.fetchall()
        col_names = [d[0] for d in cur.description]
        name_idx  = next(i for i, c in enumerate(col_names) if c.lower() in ("name", "procedure_name"))
        args_idx  = next((i for i, c in enumerate(col_names) if "argument" in c.lower()), None)
    except Exception as e:
        print(f"    [ERROR listing SPs] {e}")
        return

    folder = OUT_DIR / "sps" / schema
    ok = err = 0
    for p in rows:
        sp_name  = p[name_idx]
        args_sig = p[args_idx] if args_idx is not None else ""
        try:
            cur.execute(f"SELECT GET_DDL('PROCEDURE', '{DATABASE}.{schema}.{sp_name}')")
            row = cur.fetchone()
            ddl = row[0] if row else ""
            save(folder, sp_name, ddl)
            print(f"    [SP    OK] {sp_name}")
            inventory.append(f"SP     {DATABASE}.{schema}.{sp_name}  {args_sig}")
            ok += 1
        except Exception as e1:
            # Retry with argument signature
            try:
                cur.execute(f"SELECT GET_DDL('PROCEDURE', '{DATABASE}.{schema}.{sp_name}({args_sig})')")
                row = cur.fetchone()
                ddl = row[0] if row else ""
                save(folder, sp_name, ddl)
                print(f"    [SP    OK] {sp_name}  (with sig)")
                inventory.append(f"SP     {DATABASE}.{schema}.{sp_name}  {args_sig}")
                ok += 1
            except Exception as e2:
                msg = f"-- ERROR: {e2}\n"
                save(folder, sp_name, msg)
                print(f"    [SP   ERR] {sp_name}  — {e2}")
                inventory.append(f"SP     {DATABASE}.{schema}.{sp_name}  [ERROR]")
                err += 1

    print(f"    => {ok} saved, {err} errors")


def collect_tables(cur, schema: str, inventory: list):
    print(f"\n  -- Tables in {DATABASE}.{schema} --")
    try:
        cur.execute(f"""
            SELECT TABLE_NAME
            FROM {DATABASE}.INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = '{schema}'
              AND TABLE_TYPE = 'BASE TABLE'
            ORDER BY TABLE_NAME
        """)
        tables = [r[0] for r in cur.fetchall()]
    except Exception as e:
        print(f"    [ERROR listing tables] {e}")
        return

    folder = OUT_DIR / "tables" / schema
    ok = err = 0
    for t in tables:
        try:
            cur.execute(f"SELECT GET_DDL('TABLE', '{DATABASE}.{schema}.{t}')")
            row = cur.fetchone()
            ddl = row[0] if row else ""
            save(folder, t, ddl)
            print(f"    [TABLE OK] {t}")
            inventory.append(f"TABLE  {DATABASE}.{schema}.{t}")
            ok += 1
        except Exception as e:
            msg = f"-- ERROR: {e}\n"
            save(folder, t, msg)
            print(f"    [TABLE ERR] {t}  — {e}")
            inventory.append(f"TABLE  {DATABASE}.{schema}.{t}  [ERROR]")
            err += 1

    print(f"    => {ok} saved, {err} errors")


def run():
    print("=== Connecting to Snowflake ===")
    ctx, username = get_sf_conn()
    cur = ctx.cursor()
    print(f"  [OK] Connected as {username}\n")

    inventory = []

    for schema in SCHEMAS_TO_COLLECT:
        print(f"\n{'='*60}")
        print(f"  Schema: {DATABASE}.{schema}")
        print(f"{'='*60}")
        collect_views(cur, schema, inventory)
        collect_sps(cur, schema, inventory)
        collect_tables(cur, schema, inventory)

    ctx.close()

    inv_path = OUT_DIR / "_inventory.txt"
    inv_path.write_text(
        f"PRD Session Inventory — {DATABASE}.PRD + {DATABASE}.PRD_XML\n"
        f"Collected: {__import__('datetime').datetime.now().isoformat()}\n"
        f"{'='*60}\n"
        + "\n".join(inventory) + "\n",
        encoding="utf-8",
    )

    print(f"\n{'='*60}")
    print(f"  Total objects collected: {len(inventory)}")
    print(f"  Inventory saved to: {inv_path}")
    print(f"  Output root:        {OUT_DIR}")
    print(f"{'='*60}")


if __name__ == "__main__":
    run()
