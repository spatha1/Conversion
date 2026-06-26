"""
Snowflake connection using the Fernet-encrypted private key stored in
ConversionAgent SQL Server (connection id=14, same as scripts/).
"""
import base64
import hashlib

import pyodbc
import snowflake.connector
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives.serialization import (
    Encoding, NoEncryption, PrivateFormat, load_pem_private_key,
)

from middleware.config import SQLSERVER

_CA_CONN_STR = (
    "DRIVER={{{driver}}};"
    "SERVER={host};"
    "DATABASE=ConversionAgent;"
    "UID={user};"
    "PWD={password};"
    "TrustServerCertificate=yes;"
).format(
    driver=SQLSERVER["driver"],
    host=SQLSERVER["host"],
    user=SQLSERVER["user"],
    password=SQLSERVER["password"],
)

_SF_CREDS: dict | None = None


def _fernet_key(secret: str = "change-me") -> bytes:
    return base64.urlsafe_b64encode(hashlib.sha256(secret.encode()).digest())


def _decrypt(token: str) -> str:
    return Fernet(_fernet_key()).decrypt(token.encode()).decode()


def _load_sf_creds() -> dict:
    global _SF_CREDS
    if _SF_CREDS is not None:
        return _SF_CREDS

    conn = pyodbc.connect(_CA_CONN_STR)
    cur = conn.cursor()
    cur.execute("""
        SELECT sf_account, sf_username, sf_private_key_enc,
               sf_private_key_passphrase_enc, sf_warehouse, sf_role
        FROM [dbo].[conversion_source_connections]
        WHERE id = 14
    """)
    row = dict(zip([d[0] for d in cur.description], cur.fetchone()))
    conn.close()

    pk_pem = _decrypt(row["sf_private_key_enc"])
    pp = _decrypt(row["sf_private_key_passphrase_enc"]) if row["sf_private_key_passphrase_enc"] else None
    pk_obj = load_pem_private_key(pk_pem.encode(), password=pp.encode() if pp else None)
    pk_der = pk_obj.private_bytes(Encoding.DER, PrivateFormat.PKCS8, NoEncryption())

    _SF_CREDS = {
        "account": row["sf_account"],
        "user": row["sf_username"],
        "private_key": pk_der,
        "warehouse": row["sf_warehouse"],
        "role": row["sf_role"],
    }
    return _SF_CREDS


def get_connection() -> snowflake.connector.SnowflakeConnection:
    creds = _load_sf_creds()
    return snowflake.connector.connect(**creds)
