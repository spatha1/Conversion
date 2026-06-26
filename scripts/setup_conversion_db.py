"""
Create PolicyConversion database on DESKTOP-G01PH8C\SQLEXPRESS
and set up the ETL config table that drives the XML generation pipeline.
"""
import pyodbc

# Connect to master to create the DB
MASTER_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=master;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

CONV_CONN = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    r"SERVER=DESKTOP-G01PH8C\SQLEXPRESS;"
    "DATABASE=PolicyConversion;"
    "UID=clarityAgentuser;"
    "PWD=AshuAdvi@2816;"
    "TrustServerCertificate=yes;"
)

DB_NAME = "PolicyConversion"

CREATE_DB_SQL = f"""
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = '{DB_NAME}')
BEGIN
    CREATE DATABASE [{DB_NAME}]
END
"""

CREATE_TABLE_SQL = """
IF NOT EXISTS (
    SELECT 1 FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[etl_config]') AND type = 'U'
)
BEGIN
    CREATE TABLE [dbo].[etl_config] (
        [config_id]       INT            IDENTITY(1,1) PRIMARY KEY,
        [lob]             VARCHAR(20)    NOT NULL,          -- 'BP' or 'PP'
        [entity]          VARCHAR(200)   NOT NULL,          -- e.g. 'PolicyHeader', 'Coverage'
        [source_view]     VARCHAR(500)   NOT NULL,          -- Snowflake view from ETL2
        [formula]         NVARCHAR(MAX)  NOT NULL,          -- XML template with {fieldName} placeholders
        [output_table]    VARCHAR(500)   NOT NULL,          -- Snowflake staging output table
        [identifier_col]  VARCHAR(200)   NOT NULL DEFAULT 'POLICY_NUMBER',
        [seq_col]         VARCHAR(200)   NULL,              -- column for LISTAGG ordering (ETL5)
        [is_active]       BIT            NOT NULL DEFAULT 1,
        [exec_order]      INT            NOT NULL DEFAULT 1, -- order within a LOB run
        [notes]           NVARCHAR(1000) NULL,
        [created_at]      DATETIME       NOT NULL DEFAULT GETDATE(),
        [updated_at]      DATETIME       NOT NULL DEFAULT GETDATE()
    )
    PRINT 'Created table etl_config'
END
ELSE
    PRINT 'Table etl_config already exists'
"""

# Index for fast LOB + active lookups
CREATE_INDEX_SQL = """
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_etl_config_lob_active'
      AND object_id = OBJECT_ID('dbo.etl_config')
)
    CREATE INDEX IX_etl_config_lob_active
        ON dbo.etl_config (lob, is_active, exec_order)
"""

def run():
    # Step 1 — create database
    conn = pyodbc.connect(MASTER_CONN, autocommit=True)
    cur  = conn.cursor()
    cur.execute(CREATE_DB_SQL)
    print(f"[OK] Database '{DB_NAME}' ready on DESKTOP-G01PH8C\\SQLEXPRESS")
    conn.close()

    # Step 2 — create table + index inside PolicyConversion
    conn = pyodbc.connect(CONV_CONN, autocommit=True)
    cur  = conn.cursor()
    cur.execute(CREATE_TABLE_SQL)
    cur.execute(CREATE_INDEX_SQL)
    print("[OK] Table [dbo].[etl_config] ready")

    # Step 3 — verify
    cur.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, COLUMN_DEFAULT
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'etl_config'
        ORDER BY ORDINAL_POSITION
    """)
    print("\n=== etl_config columns ===")
    for col, dtype, maxlen, default in cur.fetchall():
        l = f"({maxlen})" if maxlen and maxlen != -1 else ("(MAX)" if maxlen == -1 else "")
        d = f"  DEFAULT={default}" if default else ""
        print(f"  {col:20s}  {dtype}{l}{d}")

    conn.close()
    print("\n[READY] Paste your config INSERT scripts to populate etl_config.")

if __name__ == "__main__":
    run()
