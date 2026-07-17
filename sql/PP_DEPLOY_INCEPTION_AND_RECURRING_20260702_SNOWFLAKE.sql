-- ============================================================
-- PP_DEPLOY_INCEPTION_AND_RECURRING_20260702_SNOWFLAKE.sql
--
-- Target  : Snowflake — AGGNE.DEV (run in Snowflake worksheet)
-- Date    : 2026-07-02
-- Bugs    : ATP-10962 (Legacy start date incorrect)
--           ATP-10972 (CM recurring adjustment showing when not in PURE)
--
-- DEPLOY ORDER:
--   Step 1 — Deploy PER_PM_BUILDING_UW view (ATP-10972)
--   Step 2 — Deploy PER_CONVERSION_FINAL_LOAD SP (ATP-10962)
--   Step 3 — Deploy PER_CONVERSION_FINAL_XML SP (ATP-10962)
--
-- AFTER DEPLOY — Aggne must re-run:
--   ATP-10972: Re-run seq 16 (PER_PM_BUILDING_UW → PER_COM_COVERAGES_TARGET)
--              then PER_CONVERSION_FINAL_XML() for affected motor policies
--   ATP-10962: Re-run PER_CONVERSION_FINAL_LOAD() then PER_CONVERSION_FINAL_XML()
--              for all affected policies
-- ============================================================

USE DATABASE AGGNE;
USE SCHEMA DEV;


-- ══════════════════════════════════════════════════════════════
-- STEP 1: PER_PM_BUILDING_UW (ATP-10972)
--
-- Root cause: UWADJUSTAMOUNT IS NOT NULL allows 0-amount UW
-- adjustments through. DCT then creates a recurring adjustment
-- entry (RECURRINGINDICATOR=1) even when PURE has no adjustment.
-- Fix: exclude UWADJUSTAMOUNT = 0 rows.
-- ══════════════════════════════════════════════════════════════

create or replace view PER_PM_BUILDING_UW(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	EXPIRINGID_P,
	CMLNUMBER,
	RECURRINGINDICATOR,
	UNDERWRITINGDESCRIPTION,
	ADJUSTMENTDOLLARANDPERCENT,
	ADJUSTMENTSELECTION,
	COVERAGE
) as
SELECT DISTINCT
    CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    CAST(T1.POLICYNUMBER AS VARCHAR) AS LEGACYPOLICYNUMBER,
    CAST(T1.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
    CAST(T2.cmlnumber AS VARCHAR) AS CMLNUMBER,
    CAST('1'  AS VARCHAR)AS RECURRINGINDICATOR,
    CAST(REPLACE(REPLACE(T1.UWADJUSTNOTE,  '&', '&amp;'),'''', '''''') AS VARCHAR) AS UnderwritingDescription,
    CAST(T1.UWADJUSTAMOUNT AS VARCHAR) AS AdjustmentDollarAndPercent,
    CAST('1'  AS VARCHAR)AS AdjustmentSelection,
    CAST(T1.COVERAGE AS VARCHAR) AS COVERAGE
FROM AGGNE.DEV.Output_UWAdjust_PER T1
INNER JOIN AGGNE.DEV.PM_03 T2
    ON T1.POLICYNUMBER = T2.PUREPOLICYNUMBER
    AND T1.EXPIRINGID_P = T2.EXPIRINGID_P
    WHERE COVERAGE='PM' AND UWADJUSTAMOUNT IS NOT NULL AND UWADJUSTAMOUNT != 0;


-- ── POST-DEPLOY VALIDATION ─────────────────────────────────────
-- Expected: all rows have non-zero adjustment amounts
SELECT UWADJUSTAMOUNT_CHECK, COUNT(*) AS ROW_COUNT
FROM (
    SELECT CASE WHEN AdjustmentDollarAndPercent = '0' THEN 'ZERO (bad)'
                WHEN AdjustmentDollarAndPercent IS NULL THEN 'NULL (bad)'
                ELSE 'OK'
           END AS UWADJUSTAMOUNT_CHECK
    FROM AGGNE.DEV.PER_PM_BUILDING_UW
)
GROUP BY 1;
-- Expected: only 'OK' rows, 0 rows for 'ZERO (bad)' and 'NULL (bad)'


-- ══════════════════════════════════════════════════════════════
-- STEP 2: PER_CONVERSION_FINAL_LOAD SP (ATP-10962)
--
-- Root cause: PER_FINAL did not include the original inception
-- date from PURE. The XML used {EFFECTIVEDATE} for both
-- EffectiveDate (renewal start) AND InceptionDate (original
-- policy start), making them identical. This incorrectly set
-- the Legacy Start Date to the renewal date in DCT.
-- Fix: join POLICYATTACH_PER to get MIN(INCEPTIONDATE) per
-- policy, defaulting to EFFECTIVEDATE if no match.
-- ══════════════════════════════════════════════════════════════

-- Paste full content of DEV_PER_CONVERSION_FINAL_LOAD.sql here
-- (run from: sql/snowflake/1_conversion/PP/sps/DEV_PER_CONVERSION_FINAL_LOAD.sql)


-- ══════════════════════════════════════════════════════════════
-- STEP 3: PER_CONVERSION_FINAL_XML SP (ATP-10962)
--
-- Changes:
--   1. <InceptionDate> now uses {INCEPTIONDATE} token (original
--      policy start date from POLICYATTACH_PER) instead of
--      {EFFECTIVEDATE} (renewal date).
--   2. Removed duplicate <InceptionDate> tag that appeared
--      twice in the policy XML block.
--   3. Added {INCEPTIONDATE} to the REPLACE chain so the token
--      is substituted at XML generation time.
-- ══════════════════════════════════════════════════════════════

-- Paste full content of DEV_PER_CONVERSION_FINAL_XML.sql here
-- (run from: sql/snowflake/1_conversion/PP/sps/DEV_PER_CONVERSION_FINAL_XML.sql)


-- ══════════════════════════════════════════════════════════════
-- STEP 4: Re-run sequence after deploy
--
-- For ATP-10972 (motor recurring adjustment):
--   Re-run seq 16 for affected motor policies, then final XML.
--
-- For ATP-10962 (inception date):
--   Re-run FINAL_LOAD (recreates PER_FINAL with INCEPTIONDATE),
--   then re-run FINAL_XML (regenerates DCT XML with correct date).
-- ══════════════════════════════════════════════════════════════

-- Seq 16 re-run (motor UW adjustment — ATP-10972):
DELETE FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET WHERE ITR_TYPE = 'PER_PM_BUILDING_UW';

CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.PER_PM_BUILDING_UW',
    $$<UnderwritingAdjustment>
<Type>{COVERAGE}</Type>
<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
<AdjustmentAmount></AdjustmentAmount>
<Recurring>
        <Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>$$,
    'AGGNE.DEV.PER_COM_COVERAGES_TARGET',
    'PER_PM_BUILDING_UW'
);

-- Final XML regeneration (both fixes):
CALL AGGNE.DEV.PER_CONVERSION_FINAL_LOAD();
CALL AGGNE.DEV.PER_CONVERSION_FINAL_XML();


-- ══════════════════════════════════════════════════════════════
-- STEP 5: Validation
-- ══════════════════════════════════════════════════════════════

-- ATP-10972: Confirm no recurring adjustment rows with 0 amount
SELECT COUNT(*) AS ZERO_AMOUNT_UW_ROWS
FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE ITR_TYPE = 'PER_PM_BUILDING_UW'
  AND PAYLOAD LIKE '%<AdjustmentDollarAndPercent>0<%';
-- Expected: 0

-- ATP-10962: Confirm InceptionDate differs from EffectiveDate for policies
-- with commencement dates older than the current renewal
SELECT
    LEGACYPOLICYNUMBER,
    REGEXP_SUBSTR(REQUEST_XML, '<EffectiveDate>(.*?)</EffectiveDate>', 1, 1, 'e', 1) AS EFFECTIVE_DATE,
    REGEXP_SUBSTR(REQUEST_XML, '<InceptionDate>(.*?)</InceptionDate>', 1, 1, 'e', 1) AS INCEPTION_DATE
FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT        -- PP Conversion table (no PA_ prefix)
WHERE REQUEST_XML LIKE '%<InceptionDate>%'
QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(LEGACYPOLICYNUMBER) ORDER BY LEGACYPOLICYNUMBER) = 1
LIMIT 20;
-- Expected: INCEPTION_DATE should be <= EFFECTIVE_DATE (earlier or equal)
-- Policies renewed from prior years should show a different (older) INCEPTION_DATE
