# G-43 — Location 1 (RISKNUMBER=1) missing for some policies

**Status:** Root-caused 2026-07-10. Original impact estimate was wrong — measured at the wrong
grain. Real impact is negligible; no fix planned.

## Original claim (incorrect)

"235 of 4,239 policies (5.5%) have location rows in `PER_ACCOUNT_LOC` but none numbered '1'."

This was measured by grouping on `PER_ACCOUNT_LOC`'s own composite key
(`LEGACYPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P`). That key already bakes `EXPIRINGID_P` in, and
`Locationdetails_PER` assigns a **separate `EXPIRINGID_P` to every individual location** for the
same real term (confirmed across multiple sample policies — e.g. a policy with 9 locations has 9
distinct `EXPIRINGID_P` values, all sharing the same `EFFECTIVEDATE`, each with its own
`RISKNUMBER`). So grouping by the composite key is really just grouping by "one location at a
time" — of course a composite-key row for Location 2 doesn't itself contain Location 1's row.
That's expected, not a defect. The 235 count was essentially counting "how many location rows
aren't themselves Location 1," which is a meaningless question once you understand the key
includes `EXPIRINGID_P`.

## Corrected measurement (live-verified 2026-07-10)

Grouped instead by the **real policy** (`LEGACYPOLICYNUMBER + CMLNUMBER`, ignoring
`EXPIRINGID_P`) and checked whether Location 1 exists **anywhere** among that policy's rows:

```sql
WITH cur AS (
  SELECT TRIM(T1.PUREPOLICYNUMBER) AS POL, TRIM(T1.cmlnumber) AS CML, T1.RISKNUMBER
  FROM AGGNE.DEV.Locationdetails_PER T1
  INNER JOIN AGGNE.DEV.SAMPLE_PER T2
    ON TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND T1.EXPIRINGID_P=T2.EXPIRINGID_P
  WHERE T1.EFFECTIVEDATE >= '2026-01-01'
)
SELECT COUNT(DISTINCT POL||'|'||CML) AS TOTAL_POLICIES,
       COUNT(DISTINCT CASE WHEN RISKNUMBER=1 THEN POL||'|'||CML END) AS POLICIES_WITH_RISK1
FROM cur;
```

**Result: 4,006 total policies, 4,004 have Location 1. Only 2 policies (0.05%) genuinely lack it:**

| PUREPOLICYNUMBER | CMLNUMBER | RISKNUMBERs present |
|---|---|---|
| P00031705 | CML00028946 | 2 |
| P00035564 | CML00033291 | 2, 3 |

## Conclusion

No fix planned. 2 policies out of 4,006 is noise-level and consistent with the original
suspicion — a benign PURE-side edit (Location 1 removed from these two specific policies without
renumbering the remaining locations down), not a systemic conversion bug. Flagging for awareness
only; revisit if this count grows on a future data refresh.
