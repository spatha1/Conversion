create or replace view CML_CLIENT_PHONE_EMAIL(
	PARTY_NUMBER,
	PHONE_TYPE,
	PHONE_NUMBER,
	EMAIL_ID,
	EMAIL_TYPE
) as 
WITH contact_cte AS
(
    SELECT  contact.contact_cnt
          , TRIM(contact_type.code) AS contact_type_code
          , contact_type.description AS contact_type
          , contact_type.is_contact_type
          , contact_type.is_correspondence_type
          , NVL(contact.description, '') AS contact_description
          , NVL(contact.area_code, '') AS contact_area_code
          , NVL(contact.extension, '') AS contact_extension
          , NVL(contact.number, '') AS contact_number
          , NVL(contact.number, '') AS contact_email
          , contact.date_created AS contact_created_date
          , contact.last_modified AS contact_last_modified_date
    FROM PRD_T5_EXTERNAL_AGGNE.PURE.contact AS contact
    JOIN PRD_T5_EXTERNAL_AGGNE.PURE.contact_type AS contact_type 
      ON contact.contact_type_id = contact_type.contact_type_id
    ORDER BY DATE_CREATED DESC
) 
, contact_cleaned_cte AS 
(
    SELECT  contact_cnt
          , contact_type_code
          , contact_type
          , is_contact_type
          , is_correspondence_type
          , contact_description
          , contact_area_code
          , contact_number
          , contact_extension
          , REPLACE(TRIM(contact_area_code || contact_number || contact_extension), ' ', '') AS cleaned_contact_phone_number
          , REPLACE(TRIM(contact_email), ' ', '') AS cleaned_contact_email
          , contact_created_date
          , contact_last_modified_date
    FROM contact_cte
)
, contact_prepared_cte AS
(
    SELECT  contact_cnt
          , contact_type_code
          , contact_type
          , (is_contact_type = 1 OR is_correspondence_type = 1) AS is_contact_method
          , contact_description
          , cleaned_contact_phone_number
          , cleaned_contact_email
          , CASE 
              WHEN contact_type_code ILIKE 'MEMAIL'     THEN cleaned_contact_email
              WHEN contact_type_code ILIKE 'E-MAIL'     THEN cleaned_contact_email

              WHEN contact_type_code ILIKE 'FAX'        THEN cleaned_contact_phone_number
              WHEN contact_type_code ILIKE 'HOMEPHONE'  THEN cleaned_contact_phone_number
              WHEN contact_type_code ILIKE 'MOBILE'     THEN cleaned_contact_phone_number
              WHEN contact_type_code ILIKE 'TELEPHONE'  THEN cleaned_contact_phone_number
              WHEN contact_type_code ILIKE 'WEB'        THEN cleaned_contact_phone_number

              WHEN contact_type_code ILIKE 'LETTER'     THEN INITCAP(contact_description)
              WHEN contact_type_code ILIKE 'MAIN'       THEN INITCAP(contact_description)
              WHEN contact_type_code ILIKE 'OTHER'      THEN INITCAP(contact_description)
            END AS contact_details
          , contact_created_date
          , contact_last_modified_date
    FROM contact_cleaned_cte
)
, contact_pivot_cte AS 
(
    SELECT *
    FROM (
      SELECT contact_cnt, contact_type_code, contact_details
      FROM contact_prepared_cte
      WHERE contact_details IS NOT NULL
        AND TRIM(contact_details) <> ''
    )
    PIVOT (
      MAX(contact_details) FOR contact_type_code IN                 
      (
        'MEMAIL'    AS main_email,
        'E-MAIL'    AS email,
        'FAX'       AS fax,
        'HOMEPHONE' AS home_phone,
        'MOBILE'    AS mobile,
        'TELEPHONE' AS telephone,
        'WEB'       AS web,
        'LETTER'    AS letter,
        'MAIN'      AS main_contact,
        'OTHER'     AS other
      )
    )
)
, base_output AS
(
    SELECT  party.party_cnt AS party_cnt
          , party.shortname AS party_number
          , party.resolved_name AS party_name
          , party_type.code AS party_type_code
          , party_type.description AS party_type
          , party.is_deleted AS party_is_deleted
          , MAX(NVL(contact_pivot_cte.main_contact, '')) AS main_contact
          , MAX(NVL(contact_pivot_cte.other, '')) AS other_contact
          , MAX(NVL(contact_pivot_cte.main_email, '')) AS main_email
          , MAX(NVL(contact_pivot_cte.email, '')) AS email
          , MAX(NVL(contact_pivot_cte.fax, '')) AS fax
          , MAX(NVL(contact_pivot_cte.home_phone, '')) AS home_phone
          , MAX(NVL(contact_pivot_cte.mobile, '')) AS mobile
          , MAX(NVL(contact_pivot_cte.telephone, '')) AS telephone
          , MAX(NVL(contact_pivot_cte.web, '')) AS web
          , MAX(NVL(contact_pivot_cte.letter, '')) AS letter
    FROM PRD_T5_EXTERNAL_AGGNE.PURE.party AS party
    JOIN PRD_T5_EXTERNAL_AGGNE.PURE.party_type AS party_type
      ON party.party_type_id = party_type.party_type_id    
    JOIN PRD_T5_EXTERNAL_AGGNE.PURE.party_contact_usage AS pcu 
      ON party.party_cnt = pcu.party_cnt
    JOIN contact_pivot_cte
      ON pcu.contact_cnt = contact_pivot_cte.contact_cnt
    WHERE TRIM(party_type.code) ILIKE 'PC'
       OR TRIM(party_type.code) ILIKE 'CC'
    GROUP BY ALL
)
SELECT
    /* One row per PARTY_NUMBER with prioritized phone & email */
    party_number,

    /* PHONE_TYPE priority: MOBILE > HOME_PHONE > TELEPHONE */
    CASE
      WHEN NULLIF(TRIM(mobile), '')     IS NOT NULL THEN 'MOBILE'
      WHEN NULLIF(TRIM(home_phone), '') IS NOT NULL THEN 'HOME_PHONE'
      WHEN NULLIF(TRIM(telephone), '')  IS NOT NULL THEN 'TELEPHONE'
      ELSE NULL
    END AS phone_type,

    /* PHONE_NUMBER cleaned to digits only */
    REGEXP_REPLACE(
      COALESCE(
        NULLIF(TRIM(mobile), ''),
        NULLIF(TRIM(home_phone), ''),
        NULLIF(TRIM(telephone), '')
      ),
      '[^0-9]',
      ''
    ) AS phone_number,

    /* EMAIL_ID priority: MAIN_EMAIL > EMAIL, lower-cased */
    LOWER(
      COALESCE(
        NULLIF(TRIM(main_email), ''),
        NULLIF(TRIM(email), '')
      )
    ) AS email_id,

    CASE
      WHEN NULLIF(TRIM(main_email), '') IS NOT NULL THEN 'MAIN_EMAIL'
      WHEN NULLIF(TRIM(email), '')      IS NOT NULL THEN 'EMAIL'
      ELSE NULL
    END AS email_type
FROM base_output;