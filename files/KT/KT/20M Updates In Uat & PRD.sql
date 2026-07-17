
--HCCLI
SELECT
    REGEXP_REPLACE(
        RESPONSE_XML,
        '<Type>HCCLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HCCLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    ) AS UPDATED_XML
FROM AGGNE.UAT.PA_PER_POLICYATTACH_MIGRATION_DCT
WHERE RESPONSE_XML LIKE '%<Type>HCCLI</Type>%';


UPDATE AGGNE.UAT.PA_PER_POLICYATTACH_MIGRATION_DCT SET RESPONSE_XML=REGEXP_REPLACE(
        RESPONSE_XML,
        '<Type>HCCLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HCCLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    )
WHERE RESPONSE_XML LIKE '%<Type>HCCLI</Type>%';

UPDATE AGGNE.UAT.POLICY_ATTACH_TABLE SET POLICY_ATTACH_XML=REGEXP_REPLACE(
        POLICY_ATTACH_XML,
        '<Type>HCCLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HCCLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    )
WHERE POLICY_ATTACH_XML LIKE '%<Type>HCCLI</Type>%';


-- HBBLI
SELECT
    REGEXP_REPLACE(
        RESPONSE_XML,
        '<Type>HBBLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HBBLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    ) AS UPDATED_XML
FROM AGGNE.UAT.PA_PER_POLICYATTACH_MIGRATION_DCT
WHERE RESPONSE_XML LIKE '%<Type>HBBLI</Type>%';

UPDATE AGGNE.UAT.PA_PER_POLICYATTACH_MIGRATION_DCT SET RESPONSE_XML=REGEXP_REPLACE(
        RESPONSE_XML,
        '<Type>HBBLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HBBLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    )
WHERE RESPONSE_XML LIKE '%<Type>HBBLI</Type>%';

UPDATE AGGNE.UAT.POLICY_ATTACH_TABLE SET POLICY_ATTACH_XML=REGEXP_REPLACE(
        POLICY_ATTACH_XML,
        '<Type>HBBLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HBBLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    )
WHERE POLICY_ATTACH_XML LIKE '%<Type>HBBLI</Type>%';

---------------------------PROD-------------------------------------------------------------------------------------------------------------

SELECT
    REGEXP_REPLACE(
        RESPONSE_XML,
        '<Type>HCCLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HCCLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    ) AS UPDATED_XML
FROM AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT
WHERE RESPONSE_XML LIKE '%<Type>HCCLI</Type>%';


UPDATE AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT SET RESPONSE_XML=REGEXP_REPLACE(
        RESPONSE_XML,
        '<Type>HCCLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HCCLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    )
WHERE RESPONSE_XML LIKE '%<Type>HCCLI</Type>%';

UPDATE AGGNE.PRD.POLICY_ATTACH_TABLE SET POLICY_ATTACH_XML=REGEXP_REPLACE(
        POLICY_ATTACH_XML,
        '<Type>HCCLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HCCLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    )
WHERE POLICY_ATTACH_XML LIKE '%<Type>HCCLI</Type>%';


-- HBBLI
SELECT
    REGEXP_REPLACE(
        RESPONSE_XML,
        '<Type>HBBLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HBBLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    ) AS UPDATED_XML
FROM AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT
WHERE RESPONSE_XML LIKE '%<Type>HBBLI</Type>%';

UPDATE AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT SET RESPONSE_XML=REGEXP_REPLACE(
        RESPONSE_XML,
        '<Type>HBBLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HBBLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    )
WHERE RESPONSE_XML LIKE '%<Type>HBBLI</Type>%';

UPDATE AGGNE.PRD.POLICY_ATTACH_TABLE SET POLICY_ATTACH_XML=REGEXP_REPLACE(
        POLICY_ATTACH_XML,
        '<Type>HBBLI</Type>\\s*<Deductible type="Total" value=""\\s*/>\\s*<Limit type="Per Occurrence" value="[^"]*"\\s*/>',
        '<Type>HBBLI</Type>\n<Deductible type="Total" value="" />\n<Limit type="Per Occurrence" value="20000000" />'
    )
WHERE POLICY_ATTACH_XML LIKE '%<Type>HBBLI</Type>%';