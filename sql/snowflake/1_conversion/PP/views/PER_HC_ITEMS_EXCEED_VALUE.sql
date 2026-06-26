-- ============================================================
-- View   : AGGNE.DEV.PER_HC_ITEMS_EXCEED_VALUE
-- Module : PP (Personal Package) — Seq 8 (HC_exceed_values)
-- Source : AGGNE.DEV.HC_02
-- Target : AGGNE.DEV.PER_HC_TARGET  (ITR_TYPE = 'HC_exceed_values')
--
-- Template (seq 8 ConversionScript):
--   <HomeContents>
--       {VALUE}
--       {DESCRIPTION}
--   </HomeContents>
--
-- Purpose:
--   Produces one XML row per individual item exceeding value.
--   Each row is inserted into PER_HC_TARGET by the seq 8 ETL.
--   CTE_LISTAGG in PER_HOME_BUILDING_PAYLOAD then aggregates
--   all rows for a policy into {HC_EXCEED_VALUES} for seq 13.
--
-- Fix (ATP-9652 Issue-1, 2026-06-25):
--   Root cause: ALL HC_02 rows were returned, including those where
--   ANYITEMSEXCEEDVALUE = 'No'. These produced empty nodes:
--     <HomeContents><Value></Value><Description></Description></HomeContents>
--   When aggregated into {HC_EXCEED_VALUES}, the block appeared non-empty
--   but contained no real data — DCT saw the node but no items, leaving
--   the "Individual Items Exceeding" field unselected.
--
--   Fix: filter to ANYITEMSEXCEEDVALUE = 'Yes' AND VALUE IS NOT NULL.
--   Policies with no items exceeding produce no rows here, so
--   {HC_EXCEED_VALUES} resolves to empty string for those policies.
--
--   Also fixed: stray trailing comma before FROM (syntax cleanup).
-- ============================================================

create or replace view PER_HC_ITEMS_EXCEED_VALUE(
    PUREPOLICYNUMBER,
    LEGACYPOLICYNUMBER,
    VALUE,
    DESCRIPTION
) as
SELECT
    -- Composite key: LEGACYPOLICYNUMBER|CMLNUMBER|EXPIRINGID_P
    CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,

    -- {VALUE}: wraps item value in XML tags
    -- T1.VALUE guaranteed non-null and > 0 by WHERE clause (alias collision avoided via T1.)
    CONCAT(
        '<Value>',
        CAST(CAST(T1.VALUE AS NUMBER(10, 0)) AS VARCHAR),
        '</Value>'
    ) AS VALUE,

    -- {DESCRIPTION}: wraps item description in XML tags
    CONCAT(
        '<Description>',
        CASE WHEN T1.DESCRIPTION IS NOT NULL
             THEN CAST(T1.DESCRIPTION AS VARCHAR)
             ELSE ''
        END,
        '</Description>'
    ) AS DESCRIPTION

FROM AGGNE.DEV.HC_02 T1
WHERE T1.EFFECTIVEDATE >= '2026-01-01'
  AND T1.ANYITEMSEXCEEDVALUE = 'Yes'  -- only policies with items exceeding value
  AND T1.VALUE IS NOT NULL            -- T1. prefix forces source column, not the computed alias
  AND T1.VALUE > 0;                   -- exclude zero-value items (no meaningful item data)
