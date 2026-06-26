create or replace view POLICYVEHICLES(
	POLICY_KEY,
	ID,
	POLICY_NUMBER,
	CML_NUMBER,
	CSL_NUMBER,
	INSURED_NAME,
	POLICYEFFECTIVEDATE,
	POLICYEXPIRATIONDATE,
	LOAD_TS,
	VEHICLE_SEQ,
	RISK_ID,
	RISK_TYPE,
	REGISTRATION_NUMBER,
	VIN,
	MAKE,
	MODEL,
	YEAR,
	BODY_TYPE,
	VEHICLE_TYPE,
	STATE,
	USAGE,
	COVER_TYPE,
	DESCRIPTION,
	TOTAL_VALUE,
	VEHICLE_FULL_DESCRIPTION,
	ADDITIONAL_PARTY,
	WINDSCREEN_EXTENSION,
	EXCESS_TYPE,
	EXCESS_TOTAL,
	EXCESS_ON_HOOK_TOWING,
	YOUNGEST_DRIVER_AGE,
	DRIVER_AGE_RESTRICTION,
	EXCESS_AGE_LESS_THAN_20,
	EXCESS_AGE_20_TO_21,
	EXCESS_AGE_22_TO_25,
	CMLIA_LIMIT,
	CMLIA_PREMIUM,
	CMFTL_LIMIT,
	CMFTL_PREMIUM,
	CMCMP_LIMIT,
	CMCMP_PREMIUM,
	CMCOR_LIMIT,
	CMCOR_PREMIUM,
	CMULG_LIMIT,
	CMULG_PREMIUM,
	COVERAGE_COUNT
) as

WITH base AS (
    SELECT
        POLICY_KEY, ID, POLICY_NUMBER,
        POLICYEFFECTIVEDATE, POLICYEXPIRATIONDATE, LOAD_TS,
        REGEXP_SUBSTR(POLICY_ATTACH_XML, '<CMLNumber>([^<]+)</CMLNumber>',   1,1,'e',1) AS cml_number,
        REGEXP_SUBSTR(POLICY_ATTACH_XML, '<CSLNumber>([^<]+)</CSLNumber>',   1,1,'e',1) AS csl_number,
        REGEXP_SUBSTR(POLICY_ATTACH_XML, '<Insured[^>]*>.*?<Name>([^<]+)</Name>',
                      1,1,'es',1)                                                       AS insured_name,
        REGEXP_COUNT(POLICY_ATTACH_XML, '<Risk id=')                                    AS total_risks,
        POLICY_ATTACH_XML
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
),

occurrences AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS n
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
),

risk_blocks AS (
    SELECT
        b.POLICY_KEY, b.ID, b.POLICY_NUMBER,
        b.POLICYEFFECTIVEDATE, b.POLICYEXPIRATIONDATE, b.LOAD_TS,
        b.cml_number, b.csl_number, b.insured_name,
        o.n                                                                             AS vehicle_seq,
        REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                      '<Risk id="[^"]+">.*?</Risk>', 1, o.n, 'es')                     AS risk_block
    FROM base b
    JOIN occurrences o ON o.n <= b.total_risks
    WHERE REGEXP_SUBSTR(b.POLICY_ATTACH_XML,
                        '<Risk id="[^"]+">.*?</Risk>', 1, o.n, 'es') IS NOT NULL
)

SELECT
    POLICY_KEY, ID, POLICY_NUMBER,
    cml_number, csl_number, insured_name,
    POLICYEFFECTIVEDATE, POLICYEXPIRATIONDATE, LOAD_TS,
    vehicle_seq,
    REGEXP_SUBSTR(risk_block, 'Risk id="([^"]+)"',                    1,1,'e',1)       AS risk_id,
    REGEXP_SUBSTR(risk_block, '<Type>([^<]+)</Type>',                  1,1,'e',1)       AS risk_type,
    REGEXP_SUBSTR(risk_block, '<RegistrationNumber>([^<]+)</RegistrationNumber>',
                  1,1,'e',1)                                                            AS registration_number,
    REGEXP_SUBSTR(risk_block, '<VIN>([^<]+)</VIN>',                    1,1,'e',1)       AS vin,
    REGEXP_SUBSTR(risk_block, '<Make>([^<]+)</Make>',                  1,1,'e',1)       AS make,
    REGEXP_SUBSTR(risk_block, '<Model>([^<]+)</Model>',                1,1,'e',1)       AS model,
    REGEXP_SUBSTR(risk_block, '<Year>([^<]+)</Year>',                  1,1,'e',1)       AS year,
    REGEXP_SUBSTR(risk_block, '<BodyType>([^<]+)</BodyType>',          1,1,'e',1)       AS body_type,
    REGEXP_SUBSTR(risk_block, '<VehicleType>([^<]+)</VehicleType>',    1,1,'e',1)       AS vehicle_type,
    REGEXP_SUBSTR(risk_block, '<State>([^<]+)</State>',                1,1,'e',1)       AS state,
    REGEXP_SUBSTR(risk_block, '<Usage>([^<]+)</Usage>',                1,1,'e',1)       AS usage,
    REGEXP_SUBSTR(risk_block, '<CoverType>([^<]+)</CoverType>',        1,1,'e',1)       AS cover_type,
    REGEXP_SUBSTR(risk_block, '<Description>([^<]+)</Description>',    1,1,'e',1)       AS description,
    TRY_CAST(REGEXP_SUBSTR(risk_block,
             '<TotalValue>([^<]+)</TotalValue>',                       1,1,'e',1)
             AS FLOAT)                                                                  AS total_value,
    REGEXP_SUBSTR(risk_block, '<VehicleFullDescription>([^<]+)</VehicleFullDescription>',
                  1,1,'e',1)                                                            AS vehicle_full_description,
    REGEXP_SUBSTR(risk_block, '<AdditonalParty>([^<]+)</AdditonalParty>',
                  1,1,'e',1)                                                            AS additional_party,
    REGEXP_SUBSTR(risk_block, '<WindscreenExtensionBenefitUsed>([^<]+)</WindscreenExtensionBenefitUsed>',
                  1,1,'e',1)                                                            AS windscreen_extension,

    -- Excess
    REGEXP_SUBSTR(risk_block, 'Excess type="([^"]+)"',                1,1,'e',1)       AS excess_type,
    TRY_CAST(REGEXP_SUBSTR(risk_block,
             '<Total>([^<]+)</Total>',                                 1,1,'e',1)
             AS FLOAT)                                                                  AS excess_total,
    TRY_CAST(REGEXP_SUBSTR(risk_block,
             '<OnHookTowing>([^<]+)</OnHookTowing>',                   1,1,'e',1)
             AS FLOAT)                                                                  AS excess_on_hook_towing,
    TRY_CAST(REGEXP_SUBSTR(risk_block,
             '<AgeOfYoungestRegularDriver>([^<]+)</AgeOfYoungestRegularDriver>',
             1,1,'e',1) AS INTEGER)                                                     AS youngest_driver_age,
    TRY_CAST(REGEXP_SUBSTR(risk_block,
             '<RestrictionOfDriverAge>([^<]+)</RestrictionOfDriverAge>',
             1,1,'e',1) AS INTEGER)                                                     AS driver_age_restriction,
    TRY_CAST(REGEXP_SUBSTR(risk_block,
             '<AgeLessThan20>([^<]+)</AgeLessThan20>',                 1,1,'e',1)
             AS FLOAT)                                                                  AS excess_age_less_than_20,
    TRY_CAST(REGEXP_SUBSTR(risk_block,
             '<AgeBetween20To21>([^<]+)</AgeBetween20To21>',           1,1,'e',1)
             AS FLOAT)                                                                  AS excess_age_20_to_21,
    TRY_CAST(REGEXP_SUBSTR(risk_block,
             '<AgeBetween22To25>([^<]+)</AgeBetween22To25>',           1,1,'e',1)
             AS FLOAT)                                                                  AS excess_age_22_to_25,

    -- Coverages pivoted by type code
    REGEXP_SUBSTR(risk_block, 'Type>CMLIA.*?Limit type="[^"]*" value="([^"]*)"',
                  1,1,'es',1)                                                           AS cmlia_limit,
    TRY_CAST(REGEXP_SUBSTR(risk_block, 'Type>CMLIA.*?<Premium>([^<]+)</Premium>',
             1,1,'es',1) AS FLOAT)                                                      AS cmlia_premium,

    REGEXP_SUBSTR(risk_block, 'Type>CMFTL.*?Limit type="[^"]*" value="([^"]*)"',
                  1,1,'es',1)                                                           AS cmftl_limit,
    TRY_CAST(REGEXP_SUBSTR(risk_block, 'Type>CMFTL.*?<Premium>([^<]+)</Premium>',
             1,1,'es',1) AS FLOAT)                                                      AS cmftl_premium,

    REGEXP_SUBSTR(risk_block, 'Type>CMCMP.*?Limit type="[^"]*" value="([^"]*)"',
                  1,1,'es',1)                                                           AS cmcmp_limit,
    TRY_CAST(REGEXP_SUBSTR(risk_block, 'Type>CMCMP.*?<Premium>([^<]+)</Premium>',
             1,1,'es',1) AS FLOAT)                                                      AS cmcmp_premium,

    REGEXP_SUBSTR(risk_block, 'Type>CMCOR.*?Limit type="[^"]*" value="([^"]*)"',
                  1,1,'es',1)                                                           AS cmcor_limit,
    TRY_CAST(REGEXP_SUBSTR(risk_block, 'Type>CMCOR.*?<Premium>([^<]+)</Premium>',
             1,1,'es',1) AS FLOAT)                                                      AS cmcor_premium,

    REGEXP_SUBSTR(risk_block, 'Type>CMULG.*?Limit type="[^"]*" value="([^"]*)"',
                  1,1,'es',1)                                                           AS cmulg_limit,
    TRY_CAST(REGEXP_SUBSTR(risk_block, 'Type>CMULG.*?<Premium>([^<]+)</Premium>',
             1,1,'es',1) AS FLOAT)                                                      AS cmulg_premium,

    REGEXP_COUNT(risk_block, '<Coverage id=')                                           AS coverage_count

FROM risk_blocks;