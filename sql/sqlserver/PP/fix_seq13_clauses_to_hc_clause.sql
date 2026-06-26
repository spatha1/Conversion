-- ============================================================
-- Fix: seq 13 template token {clauses} → {HC_CLAUSE}
-- ============================================================
-- DYNAMIC_XML_V1 reads column names from INFORMATION_SCHEMA, which always
-- returns uppercase.  The token {clauses} (lowercase) can NEVER be matched by
-- DYNAMIC_XML_V1 because the view column name HC_CLAUSE is returned as uppercase.
-- This UPDATE renames the template token so it matches the view column name.
--
-- Corresponding view change: PER_HOME_BUILDING_PAYLOAD must have a column
-- named HC_CLAUSE (added in same batch as this fix).
--
-- Apply to: CONVERSION DB (PolicyConversion database)
-- Apply to: LOCAL SQL Server (PP_ConversionConfig in local dev DB)
-- ============================================================

-- VERIFY before: expect to see {clauses} in SequenceID=13 template
SELECT SequenceID,
       CASE WHEN ConversionScript LIKE '%{clauses}%' THEN 'HAS {clauses} - NEEDS FIX' ELSE 'ok' END AS Status,
       CASE WHEN ConversionScript LIKE '%{HC_CLAUSE}%' THEN 'HAS {HC_CLAUSE}' ELSE 'missing {HC_CLAUSE}' END AS AfterStatus
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 13
  AND IsActive = 1;

-- FIX: replace {clauses} with {HC_CLAUSE}
UPDATE dbo.PP_ConversionConfig
SET ConversionScript = REPLACE(ConversionScript, '{clauses}', '{HC_CLAUSE}')
WHERE SequenceID = 13
  AND IsActive = 1
  AND ConversionScript LIKE '%{clauses}%';

-- VERIFY after: expect Status='ok' and AfterStatus='HAS {HC_CLAUSE}'
SELECT SequenceID,
       CASE WHEN ConversionScript LIKE '%{clauses}%' THEN 'STILL HAS {clauses} - ERROR' ELSE 'ok - {clauses} removed' END AS Status,
       CASE WHEN ConversionScript LIKE '%{HC_CLAUSE}%' THEN '{HC_CLAUSE} present - GOOD' ELSE 'missing {HC_CLAUSE} - ERROR' END AS AfterStatus
FROM dbo.PP_ConversionConfig
WHERE SequenceID = 13
  AND IsActive = 1;
