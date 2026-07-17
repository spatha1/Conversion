# Pure Snowflake — Key-Pair Connection Guide

How to connect to the Pure (Capricorn/AGGNE) Snowflake instance using RSA key-pair
authentication from a **new project**. Based on the working setup in the Policy
Conversion project (`middleware/snowflake_client.py`).

> **Secrets policy:** This document contains **no passwords, private keys, or
> passphrases** — only placeholders. Actual secrets live in your local `.env`
> (never committed) and in the ConversionAgent SQL Server key store described below.

---

## 1. Connection details (non-secret)

| Setting   | Value                                        |
|-----------|----------------------------------------------|
| Account   | `extqkir-external_contractor` (account locator: `XK23280`) |
| User      | `RAMASUBRAMANYAM.SWAYAMPAKULA@CAPRICORN.COOP` |
| Warehouse | `AGGNE_XS`                                   |
| Role      | `FR_ARCHITECT`                               |
| Database  | `AGGNE`                                      |
| Schema    | `DEV` (source data; conversion output also in `DEV`) |
| Host URL  | `https://extqkir-external_contractor.snowflakecomputing.com` |

Authentication is **key-pair only** (no password) — the `SF_SOURCE_PASSWORD`
entry in `.env` is intentionally blank. The RSA public key is already registered
on the Snowflake user above, so a new project only needs the **private key**.

> **Verified 2026-07-13:** key-pair connection tested successfully —
> `SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE(), CURRENT_ACCOUNT()`
> returned `RAMASUBRAMANYAM.SWAYAMPAKULA@CAPRICORN.COOP, FR_ARCHITECT, AGGNE_XS, XK23280`.

> **Access rule:** this connection is treated as **READ-ONLY** by convention.
> All DDL/DML is applied manually through the Snowflake UI, never from scripts.

---

## 2. Where the private key lives today

The Policy Conversion project does not keep the key on disk. It is stored
**Fernet-encrypted** in the local SQL Server:

| Setting  | Value |
|----------|-------|
| Server   | `DESKTOP-G01PH8C\SQLEXPRESS` |
| Database | `ConversionAgent` |
| Table    | `dbo.conversion_source_connections` (row `id = 14`) |
| Columns  | `sf_account`, `sf_username`, `sf_private_key_enc`, `sf_private_key_passphrase_enc`, `sf_warehouse`, `sf_role` |
| Login    | `clarityAgentuser` / password in local `.env` (`SQLSERVER_PASSWORD`) |

Decryption: Fernet key = `base64.urlsafe_b64encode(sha256(<secret>).digest())`.
See `middleware/snowflake_client.py` for the reference implementation.

For the new project, either:

- **Option A (recommended for a separate machine/project):** export the
  decrypted key once to a local `rsa_key.p8` file and use the standalone
  setup below, or
- **Option B (same machine):** copy `middleware/snowflake_client.py` and the
  `SQLSERVER` block of `middleware/config.py` and keep reading from the
  ConversionAgent table.

---

## 3. Standalone setup (Option A)

### 3.1 Install

```bash
pip install snowflake-connector-python cryptography python-dotenv
```

### 3.2 `.env` for the new project

```dotenv
# --- Pure Snowflake (key-pair auth) ---
SF_ACCOUNT=extqkir-external_contractor
SF_USER=RAMASUBRAMANYAM.SWAYAMPAKULA@CAPRICORN.COOP
SF_WAREHOUSE=AGGNE_XS
SF_ROLE=FR_ARCHITECT
SF_DATABASE=AGGNE
SF_SCHEMA=DEV

# Path to the PKCS#8 private key file (never commit this file)
SF_PRIVATE_KEY_PATH=./secrets/rsa_key.p8
# Leave empty if the .p8 file is unencrypted
SF_PRIVATE_KEY_PASSPHRASE=<passphrase-or-empty>
```

Add to `.gitignore`:

```gitignore
.env
secrets/
*.p8
*.pem
```

### 3.3 Connection code

```python
import os

import snowflake.connector
from cryptography.hazmat.primitives.serialization import (
    Encoding, NoEncryption, PrivateFormat, load_pem_private_key,
)
from dotenv import load_dotenv

load_dotenv()


def get_connection() -> snowflake.connector.SnowflakeConnection:
    with open(os.environ["SF_PRIVATE_KEY_PATH"], "rb") as f:
        passphrase = os.environ.get("SF_PRIVATE_KEY_PASSPHRASE") or None
        pk = load_pem_private_key(
            f.read(), password=passphrase.encode() if passphrase else None
        )

    return snowflake.connector.connect(
        account=os.environ["SF_ACCOUNT"],
        user=os.environ["SF_USER"],
        # Connector requires the key as unencrypted DER/PKCS8 bytes
        private_key=pk.private_bytes(
            Encoding.DER, PrivateFormat.PKCS8, NoEncryption()
        ),
        warehouse=os.environ["SF_WAREHOUSE"],
        role=os.environ["SF_ROLE"],
        database=os.environ.get("SF_DATABASE"),
        schema=os.environ.get("SF_SCHEMA"),
    )


if __name__ == "__main__":
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE()")
    print(cur.fetchone())
    conn.close()
```

Newer connector versions (>= 3.x) also support the shortcut — no
`cryptography` boilerplate needed:

```python
conn = snowflake.connector.connect(
    account=os.environ["SF_ACCOUNT"],
    user=os.environ["SF_USER"],
    private_key_file=os.environ["SF_PRIVATE_KEY_PATH"],
    private_key_file_pwd=os.environ.get("SF_PRIVATE_KEY_PASSPHRASE") or None,
    warehouse=os.environ["SF_WAREHOUSE"],
    role=os.environ["SF_ROLE"],
)
```

---

## 4. Generating a brand-new key pair (only if not reusing the existing one)

```bash
# Encrypted PKCS#8 private key (prompts for a passphrase)
openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 aes-256-cbc -inform PEM -out rsa_key.p8

# Matching public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
```

Then a Snowflake admin registers the public key on the user
(strip the `BEGIN/END PUBLIC KEY` lines and join into one string):

```sql
ALTER USER "RAMASUBRAMANYAM.SWAYAMPAKULA@CAPRICORN.COOP"
  SET RSA_PUBLIC_KEY = 'MIIBIjANBgkq...';

-- Verify (compare fingerprint):
DESC USER "RAMASUBRAMANYAM.SWAYAMPAKULA@CAPRICORN.COOP";
-- → RSA_PUBLIC_KEY_FP
```

Snowflake supports two keys per user (`RSA_PUBLIC_KEY` and `RSA_PUBLIC_KEY_2`),
which allows zero-downtime rotation.

---

## 5. Troubleshooting

| Error | Usual cause |
|-------|-------------|
| `JWT token is invalid` | Public key on the user doesn't match your private key; wrong `user`; or malformed account identifier. |
| `250001: Could not connect` / DNS failure | Account identifier wrong — use only the part before `.snowflakecomputing.com` (here: `extqkir-external_contractor`), not the full URL. |
| `Private key provided is invalid or not in PKCS#8 format` | Passing PEM text instead of DER bytes to `private_key=`, or the key file isn't PKCS#8 — regenerate with `openssl pkcs8 -topk8`. |
| `Password was given but private key is not encrypted` | `SF_PRIVATE_KEY_PASSPHRASE` set for an unencrypted `.p8` — leave it empty. |
| Works but no tables visible | Wrong role — confirm `FR_ARCHITECT` and check `CURRENT_ROLE()`. |

---

## 6. Reference implementation in this repo

- `middleware/snowflake_client.py` — key-pair connect via the encrypted key store
- `middleware/config.py` — `.env` loading pattern (`SNOWFLAKE_SOURCE`, `SQLSERVER`)
- `scripts/` — original scripts using connection id 14
