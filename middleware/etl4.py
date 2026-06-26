"""
ETL4 — Calls AGGNE.DEV.DYNAMIC_XML_V1 / AGGNE.PRD.DYNAMIC_XML_V1 for each
active config row.  The SP reads source view columns from INFORMATION_SCHEMA,
builds nested REPLACE() chains, and INSERTs XML into the target table.

Call map:
  ConversionSourceTable + ConversionScript + ConversionTargetTable → DEV SP
  AttachSourceTable      + AttachScript     + AttachTargetTable      → PRD SP
"""
import logging
import time

from middleware.config import SAFE_MODE
from middleware.snowflake_client import get_connection
from middleware.sqlserver_client import fetch_etl_config

logger = logging.getLogger(__name__)

_SP_DEV = "AGGNE.DEV.DYNAMIC_XML_V1"
_SP_PRD = "AGGNE.PRD.DYNAMIC_XML_V1"


def _call_sp(cur, sp: str, source: str, script: str, target: str, itr_type: str) -> str:
    """Execute one CALL and return a status string."""
    sql = f"CALL {sp}(?, ?, ?, ?)"
    cur.execute(sql, (source, script, target, itr_type))
    row = cur.fetchone()
    return row[0] if row else "no return value"


def run(lob: str, dry_run: bool = False) -> list[dict]:
    """
    Run all active ETL4 steps for the given LOB.

    Returns a list of result dicts:
        {sequence_id, script_name, step, status, message, elapsed_s}
    """
    if SAFE_MODE:
        logger.warning("[ETL4] SAFE_MODE=true — SP calls are blocked. No data will be written.")
        logger.warning("[ETL4] Set SAFE_MODE=false in .env to enable real loads.")
        dry_run = True

    configs = fetch_etl_config(lob)
    logger.info(f"[ETL4] {lob} — {len(configs)} active config rows loaded")

    results = []
    ctx = get_connection()
    cur = ctx.cursor()

    try:
        for cfg in configs:
            seq = cfg["sequenceid"]
            name = cfg["scriptname"]

            # ── Conversion step (DEV) ─────────────────────────────────────
            src = cfg["conversionsourcetable"]
            script = cfg["conversionscript"]
            tgt = cfg["conversiontargettable"]

            if src and script and tgt:
                logger.info(f"[ETL4] seq={seq} {name} | DEV | {src} -> {tgt}")
                t0 = time.perf_counter()
                try:
                    if dry_run:
                        msg = "DRY RUN — skipped"
                    else:
                        msg = _call_sp(cur, _SP_DEV, src, script, tgt, name)
                    elapsed = round(time.perf_counter() - t0, 2)
                    logger.info(f"  [OK] {elapsed}s — {msg}")
                    results.append({
                        "sequence_id": seq, "script_name": name,
                        "step": "DEV", "status": "OK",
                        "message": msg, "elapsed_s": elapsed,
                    })
                except Exception as exc:
                    elapsed = round(time.perf_counter() - t0, 2)
                    logger.error(f"  [FAIL] seq={seq} {name} DEV: {exc}")
                    results.append({
                        "sequence_id": seq, "script_name": name,
                        "step": "DEV", "status": "ERROR",
                        "message": str(exc), "elapsed_s": elapsed,
                    })
            else:
                logger.debug(f"[ETL4] seq={seq} {name} | DEV step skipped (null source/script/target)")

            # ── Attach step (PRD) ─────────────────────────────────────────
            asrc = cfg["attachsourcetable"]
            ascript = cfg["attachscript"]
            atgt = cfg["attachtargettable"]

            if asrc and ascript and atgt:
                logger.info(f"[ETL4] seq={seq} {name} | PRD | {asrc} -> {atgt}")
                t0 = time.perf_counter()
                try:
                    if dry_run:
                        msg = "DRY RUN — skipped"
                    else:
                        msg = _call_sp(cur, _SP_PRD, asrc, ascript, atgt, name)
                    elapsed = round(time.perf_counter() - t0, 2)
                    logger.info(f"  [OK] {elapsed}s — {msg}")
                    results.append({
                        "sequence_id": seq, "script_name": name,
                        "step": "PRD", "status": "OK",
                        "message": msg, "elapsed_s": elapsed,
                    })
                except Exception as exc:
                    elapsed = round(time.perf_counter() - t0, 2)
                    logger.error(f"  [FAIL] seq={seq} {name} PRD: {exc}")
                    results.append({
                        "sequence_id": seq, "script_name": name,
                        "step": "PRD", "status": "ERROR",
                        "message": str(exc), "elapsed_s": elapsed,
                    })

    finally:
        cur.close()
        ctx.close()

    ok = sum(1 for r in results if r["status"] == "OK")
    err = sum(1 for r in results if r["status"] == "ERROR")
    logger.info(f"[ETL4] Done — {ok} OK, {err} ERRORS out of {len(results)} steps")
    return results
