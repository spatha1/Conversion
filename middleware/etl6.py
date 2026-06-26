"""
ETL6 — Assemble and stage the final DCT request XML.

Calls the Snowflake SP that:
  1. Archives POLICY_MIGRATION_DCT -> POLICY_MIGRATION_DCT_PREVDATA
  2. Truncates POLICY_MIGRATION_DCT
  3. Reads VW_CBP_OUTPUT_CONVERSION / PER_FINAL (WHERE PARTYID IS NOT NULL)
  4. Substitutes all {COLUMN} placeholders into the full DCT XML envelope
  5. Inserts (CML_NUMBER, BUCKET, LEGACYPOLICYNUMBER, REQUEST_XML)
     into POLICY_MIGRATION_DCT

POLICY_MIGRATION_DCT is the staging table that the DCT POST step reads from.
SAFE_MODE=true blocks the SP call (no writes).
"""
import logging
import time

from middleware.config import SAFE_MODE
from middleware.snowflake_client import get_connection

logger = logging.getLogger(__name__)

# BP: POLICY_INSERTPAYLOADINDCT (confirmed from UAT definition)
# PP: PER_CONVERSION_FINAL_LOAD (confirm with team — candidate from DEV SP list)
_ETL6_SP = {
    "BP": "AGGNE.DEV.POLICY_INSERTPAYLOADINDCT",
    "PP": "AGGNE.DEV.PER_CONVERSION_FINAL_LOAD",
}


def run(lob: str, dry_run: bool = False) -> dict:
    if SAFE_MODE:
        logger.warning("[ETL6] SAFE_MODE=true — SP call blocked. No data will be written.")
        dry_run = True

    sp = _ETL6_SP.get(lob.upper())
    if not sp:
        raise ValueError(f"[ETL6] Unknown LOB: {lob!r}. Must be BP or PP.")

    if dry_run:
        logger.info(f"[ETL6] DRY RUN — would call: CALL {sp}()")
        return {"lob": lob, "sp": sp, "status": "DRY_RUN", "elapsed_s": 0.0}

    logger.info(f"[ETL6] Calling {sp}()")
    t0 = time.monotonic()
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(f"CALL {sp}()")
        result = cur.fetchone()
        elapsed = round(time.monotonic() - t0, 2)
        msg = str(result[0]) if result else "OK"
        logger.info(f"[ETL6] {sp}() completed in {elapsed}s — {msg}")
        return {"lob": lob, "sp": sp, "status": "OK", "message": msg, "elapsed_s": elapsed}
    except Exception as exc:
        elapsed = round(time.monotonic() - t0, 2)
        logger.error(f"[ETL6] {sp}() FAILED in {elapsed}s — {exc}")
        return {"lob": lob, "sp": sp, "status": "ERROR", "message": str(exc), "elapsed_s": elapsed}
    finally:
        conn.close()
