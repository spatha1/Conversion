-- ============================================================
-- PP Conversion Validation: SAI_CONFIGURATION example vs REQUEST_XML
--
-- Shows for each policy: PolicyNumber | Path | Payload_Value | SAI_Example_Value
--
-- SAI_CONFIGURATION.VALUE = reference PP_Comprehensive_PayLoad (valid example)
-- PER_POLICY_MIGRATION_DCT.REQUEST_XML = our converted output
-- ============================================================

WITH
-- ── 1. Extract fields from SAI_CONFIGURATION (reference example) ──────────
sai_extract AS (
    SELECT
        -- Request-level
        CAST(NULL AS VARCHAR)                                                                                         AS ImportManuscriptId,
        CAST(NULL AS VARCHAR)                                                                                         AS ProductManuscriptId,
        -- Account
        CAST(REGEXP_SUBSTR(VALUE, '<ABNNumber>([^<]+)</ABNNumber>',         1,1,'e',1) AS VARCHAR)                   AS ABNNumber,
        CAST(REGEXP_SUBSTR(VALUE, '<Name>([^<]+)</Name>',                   1,1,'e',1) AS VARCHAR)                   AS AccountName,
        CAST(REGEXP_SUBSTR(VALUE, '<CMLNumber>([^<]+)</CMLNumber>',         1,1,'e',1) AS VARCHAR)                   AS CMLNumber,
        CAST(REGEXP_SUBSTR(VALUE, '<CSLNumber>([^<]+)</CSLNumber>',         1,1,'e',1) AS VARCHAR)                   AS CSLNumber,
        CAST(REGEXP_SUBSTR(VALUE, '<Address1>([^<]+)</Address1>',           1,1,'e',1) AS VARCHAR)                   AS Addr_Address1,
        CAST(REGEXP_SUBSTR(VALUE, '<City>([^<]+)</City>',                   1,1,'e',1) AS VARCHAR)                   AS Addr_City,
        CAST(REGEXP_SUBSTR(VALUE, '<State>([^<]+)</State>',                 1,1,'e',1) AS VARCHAR)                   AS Addr_State,
        CAST(REGEXP_SUBSTR(VALUE, '<ZipCode>([^<]+)</ZipCode>',             1,1,'e',1) AS VARCHAR)                   AS Addr_ZipCode,
        CAST(REGEXP_SUBSTR(VALUE, '<StandardIndustryCode>([^<]+)</StandardIndustryCode>', 1,1,'e',1) AS VARCHAR)     AS StandardIndustryCode,
        CAST(REGEXP_SUBSTR(VALUE, '<PartyType>([^<]+)</PartyType>',         1,1,'e',1) AS VARCHAR)                   AS PartyType,
        -- Policy
        CAST(REGEXP_SUBSTR(VALUE, '<EffectiveDate>([^<]+)</EffectiveDate>', 1,1,'e',1) AS VARCHAR)                   AS EffectiveDate,
        CAST(REGEXP_SUBSTR(VALUE, '<ExpirationDate>([^<]+)</ExpirationDate>',1,1,'e',1) AS VARCHAR)                  AS ExpirationDate,
        CAST(REGEXP_SUBSTR(VALUE, '<LineOfBusiness>([^<]+)</LineOfBusiness>',1,1,'e',1) AS VARCHAR)                  AS LineOfBusiness,
        CAST(REGEXP_SUBSTR(VALUE, '<Term>([^<]+)</Term>',                   1,1,'e',1) AS VARCHAR)                   AS PolicyTerm,
        CAST(REGEXP_SUBSTR(VALUE, '<ModNumber>([^<]+)</ModNumber>',         1,1,'e',1) AS VARCHAR)                   AS ModNumber,
        CAST(REGEXP_SUBSTR(VALUE, '<PrimaryRatingState>([^<]+)</PrimaryRatingState>',1,1,'e',1) AS VARCHAR)          AS PrimaryRatingState,
        -- Line
        CAST(REGEXP_SUBSTR(VALUE, '<NewFleetCode>([^<]+)</NewFleetCode>',   1,1,'e',1) AS VARCHAR)                   AS Line_NewFleetCode,
        CAST(REGEXP_SUBSTR(VALUE, '<NewFleetType>([^<]+)</NewFleetType>',   1,1,'e',1) AS VARCHAR)                   AS Line_NewFleetType,
        -- Risk block presence
        CAST(CASE WHEN VALUE LIKE '%<Type>Motor</Type>%'    THEN 'present' ELSE '(not present)' END AS VARCHAR)      AS Motor_Block_Present,
        CAST(CASE WHEN VALUE LIKE '%<Type>Building</Type>%' THEN 'present' ELSE '(not present)' END AS VARCHAR)      AS Building_Block_Present
    FROM AGGNE.DEV.SAI_CONFIGURATION
    WHERE ID = 1
),

-- ── 2. Unpivot SAI fields to rows ─────────────────────────────────────────
sai_unpivot AS (
    SELECT FIELD_NAME, COALESCE(SAI_VALUE, '(null)') AS SAI_VALUE
    FROM sai_extract
    UNPIVOT INCLUDE NULLS (SAI_VALUE FOR FIELD_NAME IN (
        ImportManuscriptId, ProductManuscriptId,
        ABNNumber, AccountName, CMLNumber, CSLNumber,
        Addr_Address1, Addr_City, Addr_State, Addr_ZipCode,
        StandardIndustryCode, PartyType,
        EffectiveDate, ExpirationDate, LineOfBusiness, PolicyTerm, ModNumber, PrimaryRatingState,
        Line_NewFleetCode, Line_NewFleetType,
        Motor_Block_Present, Building_Block_Present
    ))
),

-- ── 3. Extract same fields from our REQUEST_XML ───────────────────────────
our_extract AS (
    SELECT
        LEGACYPOLICYNUMBER,
        -- Request-level metadata
        CAST(REGEXP_SUBSTR(REQUEST_XML, 'name="ImportManuscriptId" value="([^"]+)"',  1,1,'e',1) AS VARCHAR)        AS ImportManuscriptId,
        CAST(REGEXP_SUBSTR(REQUEST_XML, 'name="ProductManuscriptId" value="([^"]+)"', 1,1,'e',1) AS VARCHAR)        AS ProductManuscriptId,
        -- Account
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<ABNNumber>([^<]+)</ABNNumber>',             1,1,'e',1) AS VARCHAR)        AS ABNNumber,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<Name>([^<]+)</Name>',                       1,1,'e',1) AS VARCHAR)        AS AccountName,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<CMLNumber>([^<]+)</CMLNumber>',             1,1,'e',1) AS VARCHAR)        AS CMLNumber,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<CSLNumber>([^<]+)</CSLNumber>',             1,1,'e',1) AS VARCHAR)        AS CSLNumber,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<Address1>([^<]+)</Address1>',               1,1,'e',1) AS VARCHAR)        AS Addr_Address1,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<City>([^<]+)</City>',                       1,1,'e',1) AS VARCHAR)        AS Addr_City,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<State>([^<]+)</State>',                     1,1,'e',1) AS VARCHAR)        AS Addr_State,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<ZipCode>([^<]+)</ZipCode>',                 1,1,'e',1) AS VARCHAR)        AS Addr_ZipCode,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<StandardIndustryCode>([^<]+)</StandardIndustryCode>',1,1,'e',1) AS VARCHAR) AS StandardIndustryCode,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<PartyType>([^<]+)</PartyType>',             1,1,'e',1) AS VARCHAR)        AS PartyType,
        -- Policy
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<EffectiveDate>([^<]+)</EffectiveDate>',     1,1,'e',1) AS VARCHAR)        AS EffectiveDate,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<ExpirationDate>([^<]+)</ExpirationDate>',   1,1,'e',1) AS VARCHAR)        AS ExpirationDate,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<LineOfBusiness>([^<]+)</LineOfBusiness>',   1,1,'e',1) AS VARCHAR)        AS LineOfBusiness,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<Term>([^<]+)</Term>',                       1,1,'e',1) AS VARCHAR)        AS PolicyTerm,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<ModNumber>([^<]+)</ModNumber>',             1,1,'e',1) AS VARCHAR)        AS ModNumber,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<PrimaryRatingState>([^<]+)</PrimaryRatingState>',1,1,'e',1) AS VARCHAR)   AS PrimaryRatingState,
        -- Line
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<NewFleetCode>([^<]+)</NewFleetCode>',       1,1,'e',1) AS VARCHAR)        AS Line_NewFleetCode,
        CAST(REGEXP_SUBSTR(REQUEST_XML, '<NewFleetType>([^<]+)</NewFleetType>',       1,1,'e',1) AS VARCHAR)        AS Line_NewFleetType,
        -- Risk block presence
        CAST(CASE WHEN REQUEST_XML LIKE '%<Type>Motor</Type>%'    THEN 'present' ELSE '(not present)' END AS VARCHAR) AS Motor_Block_Present,
        CAST(CASE WHEN REQUEST_XML LIKE '%<Type>Building</Type>%' THEN 'present' ELSE '(not present)' END AS VARCHAR) AS Building_Block_Present
    FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
),

-- ── 4. Unpivot our fields to rows ─────────────────────────────────────────
our_unpivot AS (
    SELECT LEGACYPOLICYNUMBER, FIELD_NAME, COALESCE(OUR_VALUE, '(null)') AS OUR_VALUE
    FROM our_extract
    UNPIVOT INCLUDE NULLS (OUR_VALUE FOR FIELD_NAME IN (
        ImportManuscriptId, ProductManuscriptId,
        ABNNumber, AccountName, CMLNumber, CSLNumber,
        Addr_Address1, Addr_City, Addr_State, Addr_ZipCode,
        StandardIndustryCode, PartyType,
        EffectiveDate, ExpirationDate, LineOfBusiness, PolicyTerm, ModNumber, PrimaryRatingState,
        Line_NewFleetCode, Line_NewFleetType,
        Motor_Block_Present, Building_Block_Present
    ))
)

-- ── 5. Final comparison ───────────────────────────────────────────────────
SELECT
    o.LEGACYPOLICYNUMBER                                AS PolicyNumber,
    o.FIELD_NAME                                        AS Path,
    o.OUR_VALUE                                         AS Payload_Value,
    s.SAI_VALUE                                         AS Example_Payload_Value,
    CASE
        WHEN o.OUR_VALUE IN ('(null)', '')              THEN 'MISSING'
        WHEN s.SAI_VALUE IN ('(null)', '') OR s.SAI_VALUE IS NULL THEN 'NO_SAI_REF'
        WHEN o.OUR_VALUE = s.SAI_VALUE                  THEN 'MATCH'
        ELSE                                                 'DIFFERENT'
    END                                                 AS Match_Status
FROM our_unpivot o
LEFT JOIN sai_unpivot s ON o.FIELD_NAME = s.FIELD_NAME
ORDER BY o.LEGACYPOLICYNUMBER, o.FIELD_NAME;

-- ── Quick summary: field-level match rates ────────────────────────────────
-- Run separately if needed:
/*
WITH ... (same CTEs above) ...
SELECT
    FIELD_NAME                                          AS Path,
    MIN(s.SAI_VALUE)                                    AS Example_Payload_Value,
    COUNT(DISTINCT o.OUR_VALUE)                         AS Distinct_Our_Values,
    LISTAGG(DISTINCT o.OUR_VALUE, ' | ')
        WITHIN GROUP (ORDER BY o.OUR_VALUE)             AS Our_Values_Sample
FROM our_unpivot o
LEFT JOIN sai_unpivot s ON o.FIELD_NAME = s.FIELD_NAME
GROUP BY FIELD_NAME
ORDER BY FIELD_NAME;
*/
