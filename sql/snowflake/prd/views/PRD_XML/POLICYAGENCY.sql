create or replace view POLICYAGENCY(
	POLICY_KEY,
	POLICY_NUMBER,
	ID,
	AGENCY_ID,
	AGENCY_NAME,
	AGENCY_PHONE,
	AGENCY_CONTACT_NAME,
	AGENCY_ADDRESS1,
	AGENCY_ADDRESS2,
	AGENCY_CITY,
	AGENCY_STATE,
	AGENCY_ZIP,
	AGENCY_COUNTRY,
	AGENCY_INTERNAL_PARTY_ID,
	LOAD_TS
) as
WITH deduped AS (
    SELECT
        POLICY_KEY,
        POLICY_NUMBER,
        ID,
        POLICY_ATTACH_XML,
        LOAD_TS,
        ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS rn
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
),
policy_block AS (
    SELECT
        POLICY_KEY,
        POLICY_NUMBER,
        ID,
        LOAD_TS,
        REGEXP_SUBSTR(POLICY_ATTACH_XML, '<Policy[^>]*>.*?</Policy>', 1, 1, 'es') AS policy_xml
    FROM deduped
    WHERE rn = 1
),
agency_block AS (
    SELECT
        POLICY_KEY,
        POLICY_NUMBER,
        ID,
        LOAD_TS,
        REGEXP_SUBSTR(policy_xml, '<Agency[^>]*>.*?</Agency>', 1, 1, 'es') AS agency_xml
    FROM policy_block
)
SELECT
    POLICY_KEY,
    POLICY_NUMBER,
    ID,
    REGEXP_SUBSTR(agency_xml, '<Agency[^>]*id="([^"]*)"',   1, 1, 'e', 1) AS agency_id,
    REGEXP_SUBSTR(agency_xml, '<Name>([^<]*)</Name>',        1, 1, 'e', 1) AS agency_name,
    REGEXP_SUBSTR(agency_xml, '<Phone>([^<]*)</Phone>',      1, 1, 'e', 1) AS agency_phone,
    REGEXP_SUBSTR(agency_xml, '<Contact>.*?<Name>([^<]*)</Name>.*?</Contact>', 1, 1, 'es', 1) AS agency_contact_name,
    REGEXP_SUBSTR(agency_xml, '<Address1>([^<]*)</Address1>',1, 1, 'e', 1) AS agency_address1,
    REGEXP_SUBSTR(agency_xml, '<Address2>([^<]*)</Address2>',1, 1, 'e', 1) AS agency_address2,
    REGEXP_SUBSTR(agency_xml, '<City>([^<]*)</City>',        1, 1, 'e', 1) AS agency_city,
    REGEXP_SUBSTR(agency_xml, '<State>([^<]*)</State>',      1, 1, 'e', 1) AS agency_state,
    REGEXP_SUBSTR(agency_xml, '<ZipCode>([^<]*)</ZipCode>',  1, 1, 'e', 1) AS agency_zip,
    REGEXP_SUBSTR(agency_xml, '<Country>([^<]*)</Country>',  1, 1, 'e', 1) AS agency_country,
    REGEXP_SUBSTR(agency_xml, '<InternalPartyId>([^<]*)</InternalPartyId>', 1, 1, 'e', 1) AS agency_internal_party_id,
    LOAD_TS
FROM agency_block;