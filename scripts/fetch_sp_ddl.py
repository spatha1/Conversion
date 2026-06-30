"""
Fetch the current DDL for SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD from Snowflake.
Read-only — uses GET_DDL(), no writes.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from middleware.snowflake_client import get_connection

SP_NAME = "AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD()"
OUT_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "..", "sql", "snowflake", "1_conversion", "BP", "sps",
                        "DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD_LIVE.sql")

def main():
    print(f"Connecting to Snowflake...")
    conn = get_connection()
    cur = conn.cursor()

    print(f"Fetching DDL for {SP_NAME}...")
    cur.execute(f"SELECT GET_DDL('PROCEDURE', '{SP_NAME}')")
    row = cur.fetchone()
    if not row:
        print("ERROR: No DDL returned.")
        return

    ddl = row[0]
    out_path = os.path.normpath(OUT_FILE)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(ddl)

    print(f"Saved to: {out_path}")
    print(f"Characters: {len(ddl)}")
    cur.close()
    conn.close()

if __name__ == "__main__":
    main()
