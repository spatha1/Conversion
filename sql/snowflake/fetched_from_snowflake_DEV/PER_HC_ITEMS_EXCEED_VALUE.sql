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
  AND T1.VALUE > 0;