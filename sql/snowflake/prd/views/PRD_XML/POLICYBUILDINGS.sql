create or replace view POLICYBUILDINGS(
	POLICY_KEY,
	ID,
	POLICY_NUMBER,
	LOAD_TS,
	BUILDING_SEQ,
	BUILDING_ID,
	LOCATION_ID,
	BUILDING_TYPE,
	DESCRIPTION,
	DETAILS
) as

WITH base AS (
    SELECT
        POLICY_KEY, ID, POLICY_NUMBER, LOAD_TS,
        REGEXP_COUNT(POLICY_ATTACH_XML, '<Building id=')       AS total_buildings,
        POLICY_ATTACH_XML
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
),

occurrences AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 50))
),

building_blocks AS (
    SELECT
        b.POLICY_KEY, b.ID, b.POLICY_NUMBER, b.LOAD_TS,
        o.n                                                     AS building_seq,
        REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                      '<Building id="[^"]+">.*?</Building>',
                      1, o.n, 'es')                            AS bld_block
    FROM base b
    JOIN occurrences o ON o.n <= b.total_buildings
    WHERE REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                        '<Building id="[^"]+">.*?</Building>',
                        1, o.n, 'es') IS NOT NULL
)

SELECT
    POLICY_KEY, ID, POLICY_NUMBER, LOAD_TS,
    building_seq,
    REGEXP_SUBSTR(bld_block, 'Building id="([^"]+)"',           1,1,'e',1)  AS building_id,
    REGEXP_SUBSTR(bld_block, '<LocationId>([^<]+)</LocationId>',1,1,'e',1)  AS location_id,
    REGEXP_SUBSTR(bld_block, '<Type>([^<]+)</Type>',             1,1,'e',1)  AS building_type,
    REGEXP_SUBSTR(bld_block, '<Description>([^<]+)</Description>',1,1,'e',1) AS description,
    REGEXP_SUBSTR(bld_block, '<Details>([^<]+)</Details>',       1,1,'e',1)  AS details

FROM building_blocks;