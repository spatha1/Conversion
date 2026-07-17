"""
G-BP-88 follow-up — re-run SEQ 56/57's ETL step after the view key-shape fix.

Why this is needed: RISK_FLEET_VEHICLE_TARGET.ID is populated by the
Snowflake procedure DYNAMIC_XML_V1, which does a plain
`INSERT INTO ... SELECT DISTINCT PUREPOLICYNUMBER, ...` from the source view
-- it does NOT auto-refresh when the source view's PUREPOLICYNUMBER shape
changes, and it does not truncate the target table first (that line is
commented out in the SP itself). So after applying G-BP-88_fix.sql (which
widened FLEET_VEHICLE_SUBCOVERAGES/FLEET_VEHICLE_VIEW's key to include
REGISTRATIONNUMBER), RISK_FLEET_VEHICLE_TARGET still has the OLD
fleet-level-only rows for these two ITR_TYPEs, and every join against them
returns NULL.

What this script does, for SEQ 56 and SEQ 57 ONLY (not the whole BP LOB):
  1. Deletes the stale rows for these two ITR_TYPEs from
     RISK_FLEET_VEHICLE_TARGET (the SP does not do this itself).
  2. Re-fetches SEQ 56/57's CURRENT ConversionScript from ConversionConfig
     (so it picks up the {INDICATOR} token fix automatically, once you've
     re-applied Step 4 of G-BP-88_fix.sql -- this script does NOT re-apply
     that config UPDATE, only re-runs the ETL step using whatever is
     currently stored).
  3. Calls AGGNE.DEV.DYNAMIC_XML_V1 for each, same as the normal ETL4 run
     but scoped to just these two sequences.

Before running this:
  - Re-apply Step 4 of fixes/G-BP-88_fix.sql (the SEQ 56 Indicator token
    UPDATE) if you haven't already -- this script will just re-run
    whatever ConversionScript is currently live, hardcode and all.
  - This performs DELETE + INSERT against Snowflake. Read it, then run it
    yourself -- same SAFE_MODE discipline as every other script this
    session.

Usage:
    python docs/bp_mapping/fixes/G-BP-88_rerun_seq56_57.py
"""
import sys
sys.path.insert(0, r"C:\Users\Admin-1\Desktop\Conversion")

from middleware.sqlserver_client import get_connection as get_sqlserver_connection
from middleware.snowflake_client import get_connection as get_snowflake_connection

TARGET_TABLE = "AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET"
SEQS = [56, 57]


def fetch_config(seq_ids):
    conn = get_sqlserver_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT SequenceID, ScriptName, ConversionSourceTable, ConversionScript, ConversionTargetTable
        FROM ConversionConfig
        WHERE SequenceID IN ({})
        ORDER BY SequenceID
        """.format(",".join("?" for _ in seq_ids)),
        seq_ids,
    )
    rows = cur.fetchall()
    conn.close()
    return [
        {
            "sequence_id": r[0],
            "itr_type": r[1],
            "source": r[2],
            "script": r[3],
            "target": r[4],
        }
        for r in rows
    ]


def main():
    configs = fetch_config(SEQS)
    if len(configs) != len(SEQS):
        print(f"ERROR: expected {len(SEQS)} config rows, got {len(configs)}. Aborting.")
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
    print(f"  SELECT ID, LEN(PAYLOAD) FROM {TARGET_TABLE} WHERE ID LIKE 'P00026745%' AND ITR_TYPE='BP_fleet_coverage_Vehicle_SubCov';")

    sf.close()


if __name__ == "__main__":
    main()
