create or replace view PER_HC_ITEMS_EXCEED_VALUE(
	PUREPOLICYNUMBER,
	LEGACYPOLICYNUMBER,
	VALUE,
	DESCRIPTION
) as
SELECT
    CAST(TRIM(T1.PUREPOLICYNUMBER) || '|' || TRIM(T1.cmlnumber) || '|' || TRIM(T1.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
    T1.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,

    CONCAT(
        '<Value>',
        CAST(CAST(T1.VALUE AS NUMBER(10, 0)) AS VARCHAR),
        '</Value>'
    ) AS VALUE,

    -- FIX: escape XML-breaking characters in the description before wrapping it in tags
    CONCAT(
        '<Description>',
        CASE WHEN T1.DESCRIPTION IS NOT NULL
             THEN REPLACE(REPLACE(REPLACE(CAST(T1.DESCRIPTION AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;')
             ELSE ''
        END,
        '</Description>'
    ) AS DESCRIPTION

FROM AGGNE.DEV.HC_02 T1
WHERE T1.EFFECTIVEDATE >= '2026-01-01'
  AND T1.ANYITEMSEXCEEDVALUE = 'Yes'
  AND T1.VALUE IS NOT NULL
  AND T1.VALUE > 0;