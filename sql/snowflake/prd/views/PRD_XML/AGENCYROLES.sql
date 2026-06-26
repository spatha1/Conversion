create or replace view AGENCYROLES(
	ROLE_SEQ,
	ROLE_ID,
	ROLE_NAME,
	ROLE_DESCRIPTION,
	IN_USE
) as

WITH base AS (
    SELECT
        REGEXP_COUNT(POLICY_ATTACH_XML, '<Role id=')           AS total_roles,
        POLICY_ATTACH_XML
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    LIMIT 1
),

occurrences AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 50))
),

role_blocks AS (
    SELECT
        o.n                                                    AS role_seq,
        REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                      '<Role id="[^"]*"[^/]*/?>',
                      1, o.n, 'es')                           AS role_block
    FROM base b
    JOIN occurrences o ON o.n <= b.total_roles
    WHERE REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                        '<Role id="[^"]*"[^/]*/?>',
                        1, o.n, 'es') IS NOT NULL
)

SELECT
    role_seq,
    REGEXP_SUBSTR(role_block, 'id="([^"]+)"',                  1,1,'e',1)  AS role_id,
    REGEXP_SUBSTR(role_block, 'name="([^"]+)"',                 1,1,'e',1)  AS role_name,
    REGEXP_SUBSTR(role_block, 'description="([^"]+)"',          1,1,'e',1)  AS role_description,
    REGEXP_SUBSTR(role_block, 'inUse="([^"]+)"',                1,1,'e',1)  AS in_use

FROM role_blocks;