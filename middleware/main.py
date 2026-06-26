"""
Policy Conversion Orchestrator.

Usage:
    python -m middleware.main --lob BP
    python -m middleware.main --lob PP
    python -m middleware.main --lob BP --dry-run   # validate config, skip all SP calls
"""
import argparse
import logging
import os
import sys

from middleware.config import LOG_LEVEL, LOG_DIR, SAFE_MODE

os.makedirs(LOG_DIR, exist_ok=True)
logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
    handlers=[
        logging.FileHandler(f"{LOG_DIR}/conversion.log", encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)
logger = logging.getLogger(__name__)


def run(lob: str, dry_run: bool = False):
    from middleware import etl4, etl6

    if SAFE_MODE:
        logger.warning("SAFE_MODE=true — all SP calls are blocked. Pass --dry-run or set SAFE_MODE=false in .env.")

    logger.info(f"=== Policy Conversion START | LOB={lob} | dry_run={dry_run} ===")

    # ── ETL4: call DYNAMIC_XML_V1 per config row ─────────────────────────────
    etl4_results = etl4.run(lob, dry_run=dry_run)

    etl4_ok  = [r for r in etl4_results if r["status"] in ("OK", "DRY_RUN")]
    etl4_err = [r for r in etl4_results if r["status"] == "ERROR"]

    logger.info(f"=== ETL4 Summary: {len(etl4_ok)} OK / {len(etl4_err)} ERROR ===")
    if etl4_err:
        logger.error("ETL4 failed steps:")
        for r in etl4_err:
            logger.error(f"  seq={r['sequence_id']} {r['script_name']} [{r['step']}]: {r['message']}")
        logger.error("ETL4 errors — aborting before ETL6.")
        sys.exit(1)

    # ── ETL6: assemble final DCT XML into POLICY_MIGRATION_DCT ───────────────
    etl6_result = etl6.run(lob, dry_run=dry_run)

    if etl6_result["status"] == "ERROR":
        logger.error(f"ETL6 FAILED: {etl6_result['message']}")
        sys.exit(1)

    logger.info(f"=== Policy Conversion COMPLETE | LOB={lob} | ETL6={etl6_result['status']} ===")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Policy Conversion Middleware")
    parser.add_argument("--lob", required=True, choices=["BP", "PP"], help="Line of business")
    parser.add_argument("--dry-run", action="store_true", help="Read config but skip all SP calls")
    args = parser.parse_args()
    run(args.lob, dry_run=args.dry_run)
