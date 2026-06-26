import os
from dotenv import load_dotenv

load_dotenv()

SNOWFLAKE_SOURCE = {
    "account": os.getenv("SF_SOURCE_ACCOUNT"),
    "user": os.getenv("SF_SOURCE_USER"),
    "password": os.getenv("SF_SOURCE_PASSWORD"),
    "warehouse": os.getenv("SF_SOURCE_WAREHOUSE"),
    "database": os.getenv("SF_SOURCE_DATABASE"),
    "schema": os.getenv("SF_SOURCE_SCHEMA"),
    "role": os.getenv("SF_SOURCE_ROLE"),
}

SNOWFLAKE_STAGING = {
    "account": os.getenv("SF_STAGING_ACCOUNT"),
    "user": os.getenv("SF_STAGING_USER"),
    "password": os.getenv("SF_STAGING_PASSWORD"),
    "warehouse": os.getenv("SF_STAGING_WAREHOUSE"),
    "database": os.getenv("SF_STAGING_DATABASE"),
    "schema": os.getenv("SF_STAGING_SCHEMA"),
    "role": os.getenv("SF_STAGING_ROLE"),
}

SQLSERVER = {
    "host": os.getenv("SQLSERVER_HOST"),
    "port": os.getenv("SQLSERVER_PORT", "1433"),
    "database": os.getenv("SQLSERVER_DATABASE"),
    "user": os.getenv("SQLSERVER_USER"),
    "password": os.getenv("SQLSERVER_PASSWORD"),
    "driver": os.getenv("SQLSERVER_DRIVER", "ODBC Driver 17 for SQL Server"),
}

DCT = {
    "base_url": os.getenv("DCT_BASE_URL"),
    "api_key": os.getenv("DCT_API_KEY"),
    "environment": os.getenv("DCT_ENVIRONMENT"),
    "timeout": int(os.getenv("DCT_TIMEOUT_SECONDS", "60")),
}

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")
LOG_DIR = os.getenv("LOG_DIR", "logs")

# Safety gate — blocks any SP call that writes data when True.
# Must be explicitly set to "false" in .env to allow real loads.
SAFE_MODE: bool = os.getenv("SAFE_MODE", "true").strip().lower() != "false"
