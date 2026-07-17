"""
G-BP-90 follow-up -- re-run SEQ 62/63's ETL step after the view key-shape fix.

Why this is needed: CV_FLEET_VEHICLE_TARGET.ID is populated by the Snowflake
procedure DYNAMIC_XML_V1, which does a plain
`INSERT INTO ... SELECT DISTINCT PUREPOLICYNUMBER, ...` from the source view
-- it does NOT auto-refresh when the source view's PUREPOLICYNUMBER shape
changes, and it does not truncate the target table first (that line is
commented out in the SP itself). So after applying G-BP-90_fix.sql (which
widened CV_COVERAGE_VEHICLE_SUBCOV/CV_COVERAGE_VEHICLE_COV's key to include
VEHICLEID), CV_FLEET_VEHICLE_TARGET still has the OLD policy-level-only rows
for these two ITR_TYPEs, and every join against them returns NULL or (worse)
the stale cross-contaminated rows stay live.

What this script does, for SEQ 62 and SEQ 63 ONLY (not the whole BP LOB):
  1. Deletes the stale rows for these two ITR_TYPEs from
     CV_FLEET_VEHICLE_TARGET (the SP does not do this itself).
  2. Re-fetches SEQ 62/63's CURRENT ConversionScript from ConversionConfig.
  3. Calls AGGNE.DEV.DYNAMIC_XML_V1 for each, same as the normal ETL4 run
     but scoped to just these two sequences, IN ORDER (62 before 63 --
     SEQ63's view LISTAGGs SEQ62's rendered rows, so 62 must be re-populated
     first or SEQ63's SUBCOV_XML will render against stale/empty data).

Note: after this script, CV_RISK_COV_FINAL_VIEW (SEQ 67) does NOT need its
own ETL re-run -- it is a live view (not a target table), so it picks up the
corrected join automatically once G-BP-90_fix.sql's Step 3 (the
CREATE OR REPLACE VIEW for CV_RISK_COV_FINAL_VIEW) has been applied.

Before running this:
  - Apply all 3 view changes in G-BP-90_fix.sql first.
  - This performs DELETE + INSERT against Snowflake. Read it, then run it
    yourself -- same SAFE_MODE discipline as every other script this session.

Usage:
    python docs/bp_mapping/fixes/G-BP-90_rerun_seq62_63.py
"""
import sys
sys.path.insert(0, r"C:\Users\Admin-1\Desktop\Conversion")

import snowflake.connector
snowflake.connector.paramstyle = "qmark"

from middleware.sqlserver_client import get_connection as get_sqlserver_connection
from middleware.snowflake_client import get_connection as get_snowflake_connection

TARGET_TABLE = "AGGNE.DEV.CV_FLEET_VEHICLE_TARGET"
SEQS_IN_ORDER = [62, 63]


def fetch_config(seq_ids):
    conn = get_sqlserver_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT SequenceID, ScriptName, ConversionSourceTable, ConversionScript, ConversionTargetTable
        FROM ConversionConfig
        WHERE SequenceID IN ({})
        """.format(",".join("?" for _ in seq_ids)),
        seq_ids,
    )
    rows = {r[0]: r for r in cur.fetchall()}
    conn.close()
    return [
        {
            "sequence_id": rows[s][0],
            "itr_type": rows[s][1],
            "source": rows[s][2],
            "script": rows[s][3],
            "target": rows[s][4],
        }
        for s in seq_ids
        if s in rows
    ]


def main():
    configs = fetch_config(SEQS_IN_ORDER)
    if len(configs) != len(SEQS_IN_ORDER):
        print(f"ERROR: expected {len(SEQS_IN_ORDER)} config rows, got {len(configs)}. Aborting.")
        return

    for cfg in configs:
        print(f"SEQ {cfg['sequence_id']} ({cfg['itr_type']}): source={cfg['source']}")

    sf = get_snowflake_connection()
    cur = sf.cursor()

    itr_types = [cfg["itr_type"] for cfg in configs]
    itr_list = ", ".join(f"'{t}'" for t in itr_types)

    print(f"\nDeleting stale rows from {TARGET_TABLE} for ITR_TYPE IN ({itr_list}) ...")
    cur.execute(f"DELETE FROM {TARGET_TABLE} WHERE ITR_TYPE IN ({itr_list})")
    print(f"  deleted {cur.rowcount} rows")

    for cfg in configs:
        print(f"\nRe-running DYNAMIC_XML_V1 for SEQ {cfg['sequence_id']} ({cfg['itr_type']}) ...")
        cur.execute(
            "CALL AGGNE.DEV.DYNAMIC_XML_V1(?, ?, ?, ?)",
            (cfg["source"], cfg["script"], cfg["target"], cfg["itr_type"]),
        )
        result = cur.fetchone()
        print(f"  result: {result[0] if result else 'no return value'}")

    print("\nDone. Verify with:")
    print(f"  SELECT ITR_TYPE, COUNT(*) FROM {TARGET_TABLE} WHERE ITR_TYPE IN ({itr_list}) GROUP BY 1;")
    print("  SELECT PUREPOLICYNUMBER, LEN(SUBCOV_XML) FROM AGGNE.DEV.CV_COVERAGE_VEHICLE_COV")
    print("  WHERE PUREPOLICYNUMBER LIKE 'P00009911|CML00000309|575099%';")

    sf.close()


if __name__ == "__main__":
    main()
