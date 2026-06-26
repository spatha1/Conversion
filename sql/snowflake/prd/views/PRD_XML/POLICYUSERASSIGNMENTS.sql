create or replace view POLICYUSERASSIGNMENTS(
	POLICY_KEY,
	ID,
	POLICY_NUMBER,
	LOAD_TS,
	USER_ID,
	FULL_NAME,
	EMAIL,
	DETAIL_SEQ,
	AGENCY_ID,
	HOME_ENTITY,
	IS_PRODUCER,
	AGENCY_NAME,
	ROLE_ID,
	ROLE_NAME
) as

WITH base AS (
    SELECT
        POLICY_KEY, ID, POLICY_NUMBER, LOAD_TS,
        REGEXP_SUBSTR(POLICY_ATTACH_XML, 'userDetails userID="([^"]+)"',
                      1,1,'e',1)                               AS user_id,
        REGEXP_SUBSTR(POLICY_ATTACH_XML, '<fullName>([^<]+)</fullName>',
                      1,1,'e',1)                               AS full_name,
        REGEXP_SUBSTR(POLICY_ATTACH_XML, '<email>([^<]+)</email>',
                      1,1,'e',1)                               AS email,
        REGEXP_COUNT(POLICY_ATTACH_XML, '<userDetail>')        AS total_user_details,
        POLICY_ATTACH_XML
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
),

occurrences AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 20))
),

detail_blocks AS (
    SELECT
        b.POLICY_KEY, b.ID, b.POLICY_NUMBER, b.LOAD_TS,
        b.user_id, b.full_name, b.email,
        o.n                                                    AS detail_seq,
        REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                      '<userDetail>.*?</userDetail>',
                      1, o.n, 'es')                           AS detail_block
    FROM base b
    JOIN occurrences o ON o.n <= b.total_user_details
    WHERE REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                        '<userDetail>.*?</userDetail>',
                        1, o.n, 'es') IS NOT NULL
)

SELECT
    POLICY_KEY, ID, POLICY_NUMBER, LOAD_TS,
    user_id, full_name, email,
    detail_seq,
    REGEXP_SUBSTR(detail_block, 'agencyID="([^"]+)"',          1,1,'e',1)  AS agency_id,
    REGEXP_SUBSTR(detail_block, 'homeEntity="([^"]+)"',         1,1,'e',1)  AS home_entity,
    REGEXP_SUBSTR(detail_block, 'producer="([^"]+)"',           1,1,'e',1)  AS is_producer,
    REGEXP_SUBSTR(detail_block, '<agency[^>]*>([^<]+)</agency>',1,1,'e',1)  AS agency_name,
    REGEXP_SUBSTR(detail_block, 'Role id="([^"]+)"',            1,1,'e',1)  AS role_id,
    REGEXP_SUBSTR(detail_block, 'name="([^"]+)"',               1,2,'e',1)  AS role_name

FROM detail_blocks;