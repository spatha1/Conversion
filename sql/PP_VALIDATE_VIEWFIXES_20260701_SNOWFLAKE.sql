-- ══════════════════════════════════════════════════════════════════════════
-- PP_VALIDATE_VIEWFIXES_20260701_SNOWFLAKE.sql
--
-- Run AFTER PP_DEPLOY_VIEWFIXES_20260701_SNOWFLAKE.sql has been applied.
-- Each block has an EXPECTED result comment.
-- All queries are read-only SELECT statements.
-- ══════════════════════════════════════════════════════════════════════════


-- ──────────────────────────────────────────────────────────────────────────
-- CHECK 1 — PP-CF-15: NULL STATE guard (PER_ACCOUNT_LOC)
-- Expected: 0 rows  (any row here = the fix did not take or a new NULL STATE exists)
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    PUREPOLICYNUMBER,
    STATE,
    LOC_COUNTRY
FROM AGGNE.DEV.PER_ACCOUNT_LOC
WHERE STATE = 'AU'         -- 'AU' alone is the bad value produced by NULL + CONCAT
  AND LOC_COUNTRY = 'AU';


-- ──────────────────────────────────────────────────────────────────────────
-- CHECK 2 — BUG-NEW-02: HC_CLAUSE now populated (PER_HOME_BUILDING_PAYLOAD)
-- Expected: with_hc_clause > 0 for any policy that had HC clause rows loaded
--           (loc_hc_clause_rows should match with_hc_clause count)
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    COUNT(*) AS total_hc_policies,
    SUM(CASE WHEN HC_CLAUSE != '' AND HC_CLAUSE IS NOT NULL THEN 1 ELSE 0 END) AS with_hc_clause,
    SUM(CASE WHEN HC_CLAUSE = ''  OR  HC_CLAUSE IS NULL     THEN 1 ELSE 0 END) AS without_hc_clause
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
WHERE HC_INDICATOR = '1';

-- Cross-check: raw count of LOC_HC_CLAUSE rows in PER_HC_TARGET today
SELECT COUNT(DISTINCT ID) AS policies_with_hc_clause_rows
FROM AGGNE.DEV.PER_HC_TARGET
WHERE ITR_TYPE = 'LOC_HC_CLAUSE'
  AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE);


-- ──────────────────────────────────────────────────────────────────────────
-- CHECK 3 — BUG-NEW-03: UW column now populated (PER_HOME_BUILDING_PAYLOAD)
-- Expected: 0 rows  (any row here = a policy had BUILDING_UW rows but view still returns '')
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    p.PUREPOLICYNUMBER,
    p.UW AS view_uw_value,
    src.building_uw_count
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD p
JOIN (
    SELECT
        ID,
        COUNT(*) AS building_uw_count
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE = 'BUILDING_UW'
      AND CAST(LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    GROUP BY ID
) src ON p.PUREPOLICYNUMBER = src.ID
WHERE (p.UW = '' OR p.UW IS NULL)   -- should be zero rows after fix
LIMIT 20;


-- ──────────────────────────────────────────────────────────────────────────
-- CHECK 4 — MainWallConstruction 'Steel' → 'IronSteel' (PER_RISK_BUILDING_FINAL)
-- Expected: dct_value = 'IronSteel' for all rows (none should show raw 'Steel')
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    src.MAINWALLCONSTRUCTION   AS source_value,
    fin.MAINWALLCONSTRUCTION_FINAL AS dct_value,
    COUNT(*) AS policy_count
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL fin
JOIN AGGNE.DEV.Locationdetails_PER src
    ON CAST(TRIM(src.PUREPOLICYNUMBER) || '|' || TRIM(src.cmlnumber) || '|' || TRIM(src.EXPIRINGID_P) AS VARCHAR)
       = fin.PUREPOLICYNUMBER
WHERE src.MAINWALLCONSTRUCTION = 'Steel'
GROUP BY 1, 2;


-- ──────────────────────────────────────────────────────────────────────────
-- CHECK 5 — HOWOCCUPPIED ILIKE fix (PER_RISK_BUILDING_FINAL)
-- Expected: dct_value = 'TenantedbyMember' for ALL rows regardless of source casing
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    src.HOWOCCUPPIED   AS source_value,
    fin.HOWOCCUPPIED   AS dct_value,
    COUNT(*) AS policy_count
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL fin
JOIN AGGNE.DEV.Locationdetails_PER src
    ON CAST(TRIM(src.PUREPOLICYNUMBER) || '|' || TRIM(src.cmlnumber) || '|' || TRIM(src.EXPIRINGID_P) AS VARCHAR)
       = fin.PUREPOLICYNUMBER
WHERE src.HOWOCCUPPIED ILIKE 'Tenanted by member'
GROUP BY 1, 2;


-- ──────────────────────────────────────────────────────────────────────────
-- CHECK 6 — Sanity: full HOWOCCUPPIED distribution (PER_RISK_BUILDING_FINAL)
-- Expected: no raw source values in dct_value — all should be DCT camelCase codes
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    HOWOCCUPPIED AS dct_value,
    COUNT(*) AS policy_count
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL
GROUP BY 1
ORDER BY 2 DESC;


-- ──────────────────────────────────────────────────────────────────────────
-- CHECK 7 — Sanity: full MAINWALLCONSTRUCTION distribution (PER_RISK_BUILDING_FINAL)
-- Expected: all DCT camelCase codes — flag any raw passthrough values
-- (SomeAsbestosAndBrick / Other are expected passthroughs pending client confirmation)
-- ──────────────────────────────────────────────────────────────────────────
SELECT
    MAINWALLCONSTRUCTION_FINAL AS dct_value,
    COUNT(*) AS policy_count
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL
GROUP BY 1
ORDER BY 2 DESC;


-- ──────────────────────────────────────────────────────────────────────────
-- CHECK 8 — Sanity: row counts for all 3 deployed views (basic smoke test)
-- Expected: non-zero row counts matching previous run counts
-- ──────────────────────────────────────────────────────────────────────────
SELECT 'PER_ACCOUNT_LOC'         AS view_name, COUNT(*) AS row_count FROM AGGNE.DEV.PER_ACCOUNT_LOC
UNION ALL
SELECT 'PER_HOME_BUILDING_PAYLOAD', COUNT(*) FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
UNION ALL
SELECT 'PER_RISK_BUILDING_FINAL',   COUNT(*) FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL;
