create or replace view VW_DIM_PARTY_CML_CSL_NEW_EXPORT_V2_USER(
	USERNAME,
	PARTY_DIM_ID,
	BK_CMLNUMBER,
	MEMBER_TA_NUMBER,
	CSL_LEGAL_ENTITY,
	CML_RISK_ACCOUNT_MANAGER,
	CSL_AREA_MANAGER,
	CSL_ZONE,
	CSL_REGION,
	CSL_NUMBER,
	CML_LEGAL_ENTITY,
	CSL_MEMBER_STATUS,
	ABN_NZBN,
	STOP_CREDIT,
	STOP_CREDIT_REASON,
	CSL_TENURE,
	CSL_MONTHLY_SPEND,
	STANDARD_INDUSTRY_CODE,
	STANDARD_INDUSTRY_CODE_DESCRIPTION,
	CSL_CREDIT_LIMIT,
	CSL_CREDIT_RISK,
	CSL_CREDIT_USAGE,
	PROBABILITY_OF_DEFAULT,
	TA_PAYMENT_METHOD,
	STREET,
	SUBURB,
	STATE,
	POSTCODE,
	CONTACT_NAME,
	PHONE,
	EMAIL,
	SITE_COUNTRY,
	MESSAGE,
	CMLNUMBER,
	COUNTRY,
	CMLLEGALENTITY,
	CMLTRADINGNAME,
	MAINCONTACT,
	CORRESPONDENCELINE1,
	CORRESPONDENCELINE2,
	CORRESPONDENCELINE3,
	CORRESPONDENCELINE4,
	LOCATIONSTATECODE,
	CORRESPONDENCEPOSTCODE,
	SITE_STREET,
	SITE_SUBURB,
	SITE_STATE,
	SITE_POSTCODE,
	CSLNUMBER,
	PHONE_DETAILS,
	PRIMARY_PHONE,
	PRIMARY_PHONE_TYPE,
	PRIMARY_EMAIL,
	PRIMARY_EMAIL_TYPE,
	PHONE_COUNT,
	EMAIL_COUNT,
	SECONDARYCONTACT_COUNT,
	SECONDARYCONTACT,
	SECONDARYCONTACTKEY,
	PAID2DATE,
	MEM_REF,
	EFFECTIVE_DATE,
	AMOUNT,
	HASH_DIFF,
	EFFECTIVE_FROM,
	EFFECTIVE_TO,
	IS_CURRENT,
	ACTIVE_FLAG,
	LOAD_DATE
) as
SELECT
concat('ConversionUser'::varchar,(ROW_NUMBER()Over(order by PARTY_DIM_ID)%5)+1 )as ConversionCounter,
    PARTY_DIM_ID ,
	BK_CMLNUMBER ,
	MEMBER_TA_NUMBER ,
	REPLACE(CSL_LEGAL_ENTITY,'&','&amp;')  ,
	REPLACE(CML_RISK_ACCOUNT_MANAGER,'&','&amp;')  ,
	REPLACE(CSL_AREA_MANAGER,'&','&amp;') ,
	REPLACE(CSL_ZONE,'&','&amp;') ,
	REPLACE(CSL_REGION,'&','&amp;') ,
	CSL_NUMBER ,
	REPLACE(CML_LEGAL_ENTITY,'&','&amp;') ,
	CSL_MEMBER_STATUS ,
	ABN_NZBN ,
	STOP_CREDIT ,
	REPLACE(STOP_CREDIT_REASON,'&','&amp;') , 
	CSL_TENURE ,
	CSL_MONTHLY_SPEND ,
	STANDARD_INDUSTRY_CODE ,
	REPLACE(STANDARD_INDUSTRY_CODE_DESCRIPTION,'&','&amp;') ,
	CSL_CREDIT_LIMIT ,
	CSL_CREDIT_RISK ,
	CSL_CREDIT_USAGE ,
	PROBABILITY_OF_DEFAULT FLOAT,
	TA_PAYMENT_METHOD ,
	REPLACE(STREET,'&','&amp;') ,
	REPLACE(SUBURB,'&','&amp;') ,
	STATE ,
	POSTCODE ,
	REPLACE(CONTACT_NAME,'&','&amp;') ,
	PHONE ,
	REPLACE(EMAIL,'&','&amp;') ,
    CASE
    WHEN TRIM(SITE_COUNTRY) = 'New Zealand' THEN 'NZ'
    WHEN TRIM(SITE_COUNTRY) = 'Australia' THEN 'AU'
    ELSE TRIM(SITE_COUNTRY)
  END AS SITE_COUNTRY,
	REPLACE(MESSAGE,'&','&amp;') ,
	CMLNUMBER ,
	CASE
    WHEN TRIM(COUNTRY) = 'New Zealand' THEN 'NZ'
    WHEN TRIM(COUNTRY) = 'Australia' THEN 'AU'
    ELSE TRIM(COUNTRY)
  END AS COUNTRY,
	REPLACE(CMLLEGALENTITY,'&','&amp;') ,
	REPLACE(CMLTRADINGNAME,'&','&amp;') ,
	REPLACE(MAINCONTACT,'&','&amp;'),
	REPLACE(CORRESPONDENCELINE1,'&','&amp;') ,
	REPLACE(CORRESPONDENCELINE2,'&','&amp;') ,
	REPLACE(CORRESPONDENCELINE3,'&','&amp;') ,
    CASE
    WHEN TRIM(COUNTRY) = 'New Zealand' THEN UPPER(CORRESPONDENCELINE4)
    WHEN TRIM(COUNTRY) = 'Australia' THEN CONCAT(CORRESPONDENCELINE4, 'AU')
    ELSE CORRESPONDENCELINE4
  END AS CORRESPONDENCELINE4,
   CASE
    WHEN TRIM(COUNTRY) = 'New Zealand' THEN '100'
    WHEN TRIM(COUNTRY) = 'Australia' THEN CONCAT(CORRESPONDENCELINE4, 'AU')
    ELSE CORRESPONDENCELINE4
  END AS LOCATIONSTATECODE,
	CORRESPONDENCEPOSTCODE ,
	REPLACE(SITE_STREET,'&','&amp;') , 
	SITE_SUBURB ,
	CASE
    WHEN TRIM(COUNTRY) = 'New Zealand' THEN SITE_STATE
    WHEN TRIM(COUNTRY) = 'Australia' THEN CONCAT(SITE_STATE, 'AU')
    ELSE SITE_STATE
  END AS SITE_STATE,
	SITE_POSTCODE ,
	CSLNUMBER ,
    LEFT(PRIMARY_PHONE, 2)  AS PHONE_DETAILS,
	PRIMARY_PHONE ,
	PRIMARY_PHONE_TYPE ,
	PRIMARY_EMAIL ,
	PRIMARY_EMAIL_TYPE ,
	PHONE_COUNT ,
	EMAIL_COUNT ,
	SECONDARYCONTACT_COUNT ,
	SECONDARYCONTACT ARRAY,
	SECONDARYCONTACTKEY ,
	PAID2DATE ,
	MEM_REF ,
	EFFECTIVE_DATE ,
	AMOUNT ,
	HASH_DIFF ,
	EFFECTIVE_FROM ,
	EFFECTIVE_TO ,
	IS_CURRENT ,
	ACTIVE_FLAG ,
    TO_VARCHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD') AS CURRENTDATE
FROM AGGNE.DEV.DIM_PARTY_CML_CSL_NEW_02
WHERE   street IS NOT NULL AND street != ''
  AND suburb IS NOT NULL AND suburb != ''
  AND state IS NOT NULL AND state != ''
  AND postcode IS NOT NULL AND postcode != ''
    and ((trim(country)='Australia' AND REGEXP_LIKE(REGEXP_REPLACE(phone,'[^0-9]',''),'^0\\d{9}$')) OR (trim(country)='New Zealand' AND (REGEXP_LIKE(REGEXP_REPLACE(phone,'[^0-9]',''),'^0(3|4|6|7|9)\\d{7}$') OR REGEXP_LIKE(REGEXP_REPLACE(phone,'[^0-9]',''),'^02\\d{8}$'))))
  and email IS NOT NULL and email != ''
  and ((trim(country)='Australia' AND REGEXP_LIKE(REGEXP_REPLACE(primary_phone,'[^0-9]',''),'^0\\d{9}$')) OR (trim(country)='New Zealand' AND (REGEXP_LIKE(REGEXP_REPLACE(primary_phone,'[^0-9]',''),'^0(3|4|6|7|9)\\d{7}$') OR REGEXP_LIKE(REGEXP_REPLACE(primary_phone,'[^0-9]',''),'^02\\d{8}$'))))
  AND primary_email IS NOT NULL AND primary_email != ''
  AND correspondenceline1 IS NOT NULL AND correspondenceline1 != ''
  ---AND amount IS NOT NULL   -- numeric
  AND maincontact IS NOT NULL AND maincontact != ''
  AND site_state IS NOT NULL AND site_state != ''
  AND csl_credit_risk IS NOT NULL    -- numeric
  AND csl_credit_limit IS NOT NULL   -- numeric
  AND csl_monthly_spend IS NOT NULL and csl_monthly_spend != '' 
  AND csl_tenure IS NOT NULL         -- numeric
  AND (abn_nzbn IS NOT NULL AND REGEXP_LIKE(TRIM(abn_nzbn), '^[0-9]{11}$|^[0-9]{13}$'))
  AND cml_risk_account_manager IS NOT NULL AND cml_risk_account_manager != ''
  and contact_name is not null and contact_name != ''
  AND (
    (cml_legal_entity IS NOT NULL AND cml_legal_entity != '')
    AND (cmllegalentity IS NOT NULL AND cmllegalentity != '')
  )
  AND site_postcode IS NOT NULL AND site_postcode != ''
  AND site_street IS NOT NULL AND site_street != ''
  AND site_suburb IS NOT NULL AND site_suburb != ''
  AND site_country IS NOT NULL AND site_country != ''
  AND country IS NOT NULL AND country != ''
  AND csl_area_manager IS NOT NULL AND csl_area_manager != ''
  AND csl_credit_usage IS NOT NULL
  AND csl_legal_entity IS NOT NULL AND csl_legal_entity != ''
  AND csl_member_status IS NOT NULL AND csl_member_status != ''
  AND csl_region IS NOT NULL AND csl_region != ''
  AND csl_zone IS NOT NULL AND csl_zone != ''
  AND cmltradingname IS NOT NULL AND cmltradingname != ''
  AND primary_email_type IS NOT NULL AND primary_email_type != ''
  AND primary_phone_type IS NOT NULL AND primary_phone_type != ''
  AND probability_of_default IS NOT NULL
  AND standard_industry_code IS NOT NULL AND standard_industry_code != ''
  AND standard_industry_code_description IS NOT NULL AND standard_industry_code_description != ''
  AND member_ta_number IS NOT NULL AND member_ta_number != ''
  AND cslnumber IS NOT NULL AND cslnumber != ''
  AND cmlnumber IS NOT NULL AND cmlnumber != ''
  AND stop_credit IS NOT NULL AND stop_credit != ''
  AND stop_credit_reason IS NOT NULL AND stop_credit_reason != ''
  AND ta_payment_method IS NOT NULL AND ta_payment_method != ''
  --and correspondenceline2 is not null and correspondenceline2 != ''
  and correspondenceline3 is not null and correspondenceline3 != ''
  and correspondenceline4 is not null and correspondenceline4 != ''
  and correspondencepostcode is not null and correspondencepostcode != ''
;