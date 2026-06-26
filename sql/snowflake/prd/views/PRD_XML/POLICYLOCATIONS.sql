create or replace view POLICYLOCATIONS(
	POLICY_KEY,
	ID,
	POLICY_NUMBER,
	LOAD_TS,
	LOCATION_SEQ,
	LOCATION_ID,
	DESCRIPTION,
	ADDRESS1,
	ADDRESS2,
	CITY,
	STATE,
	POSTCODE,
	COUNTRY
) as

WITH base AS (
    SELECT
        POLICY_KEY, ID, POLICY_NUMBER, LOAD_TS,
        REGEXP_COUNT(POLICY_ATTACH_XML, '<Location id=')       AS total_locations,
        POLICY_ATTACH_XML
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
),

occurrences AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 50))
),

location_blocks AS (
    SELECT
        b.POLICY_KEY, b.ID, b.POLICY_NUMBER, b.LOAD_TS,
        o.n                                                     AS location_seq,
        REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                      '<Location id="[^"]+">.*?</Location>',
                      1, o.n, 'es')                            AS loc_block
    FROM base b
    JOIN occurrences o ON o.n <= b.total_locations
    WHERE REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                        '<Location id="[^"]+">.*?</Location>',
                        1, o.n, 'es') IS NOT NULL
)

SELECT
    POLICY_KEY, ID, POLICY_NUMBER, LOAD_TS,
    location_seq,
    REGEXP_SUBSTR(loc_block, 'Location id="([^"]+)"',          1,1,'e',1)   AS location_id,
    REGEXP_SUBSTR(loc_block, '<Description>([^<]+)</Description>',1,1,'e',1) AS description,
    REGEXP_SUBSTR(loc_block, '<Address1>([^<]+)</Address1>',   1,1,'e',1)   AS address1,
    REGEXP_SUBSTR(loc_block, '<Address2>([^<]+)</Address2>',   1,1,'e',1)   AS address2,
    REGEXP_SUBSTR(loc_block, '<City>([^<]+)</City>',           1,1,'e',1)   AS city,
    REGEXP_SUBSTR(loc_block, '<State>([^<]+)</State>',         1,1,'e',1)   AS state,
    REGEXP_SUBSTR(loc_block, '<ZipCode>([^<]+)</ZipCode>',     1,1,'e',1)   AS postcode,
    REGEXP_SUBSTR(loc_block, '<Country>([^<]+)</Country>',     1,1,'e',1)   AS country

FROM location_blocks;