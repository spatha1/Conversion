import pyodbc
from middleware.config import SQLSERVER, AZURE_SQLSERVER

_CONFIG_TABLE = {
    "BP": "ConversionConfig",
    "PP": "PP_ConversionConfig",
}

_CONN_STR = (
    "DRIVER={{{driver}}};"
    "SERVER={host};"
    "DATABASE={database};"
    "UID={user};"
    "PWD={password};"
    "TrustServerCertificate=yes;"
)


def get_connection(database: str | None = None):
    db = database or SQLSERVER["database"]
    conn_str = _CONN_STR.format(
        driver=SQLSERVER["driver"],
        host=SQLSERVER["host"],
        database=db,
        user=SQLSERVER["user"],
        password=SQLSERVER["password"],
    )
    return pyodbc.connect(conn_str)


def get_azure_connection():
    """Connect to Azure SQL Server (PP_ConversionConfig — live ETL config)."""
    conn_str = _CONN_STR.format(
        driver=AZURE_SQLSERVER["driver"],
        host=AZURE_SQLSERVER["host"],
        database=AZURE_SQLSERVER["database"],
        user=AZURE_SQLSERVER["user"],
        password=AZURE_SQLSERVER["password"],
    )
    return pyodbc.connect(conn_str)


def fetch_etl_config(lob: str) -> list[dict]:
    """
    Read all active rows from ConversionConfig / PP_ConversionConfig ordered by SequenceID.
    Returns list of dicts with keys:
        conversion_config_id, sequence_id, script_name,
        conversion_source_table, conversion_script, conversion_target_table,
        attach_source_table, attach_script, attach_target_table
    """
    table = _CONFIG_TABLE.get(lob.upper())
    if not table:
        raise ValueError(f"Unknown LOB '{lob}'. Must be BP or PP.")

    conn = get_connection()
    cur = conn.cursor()
    cur.execute(f"""
        SELECT
            ConversionConfigId,
            SequenceID,
            ScriptName,
            ConversionSourceTable,
            ConversionScript,
            ConversionTargetTable,
            AttachSourceTable,
            AttachScript,
            AttachTargetTable
        FROM [dbo].[{table}]
        WHERE IsActive = 1
        ORDER BY SequenceID
    """)
    cols = [d[0].lower() for d in cur.description]
    rows = [dict(zip(cols, row)) for row in cur.fetchall()]
    conn.close()
    return rows
