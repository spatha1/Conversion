create or replace view HB_02_POLICYATTACH_IDENTIFIER(
	ID,
	ACTUALID,
	PUREPOLICYNUMBER,
	EXPIRINGID_P,
	CMLNUMBER,
	INSURANCE_FILE_CNT,
	EFFECTIVEDATE,
	COUNTRY,
	PRODUCT,
	ACCIDENTALLOSSORDAMAGE,
	FLOODDAMAGE,
	VOLUNTARYEXCESS,
	STANDARDEXCESS,
	IMPOSEDEXCESS,
	EARTHQUAKEEXCESS,
	FLOODEXCESS,
	HOMEBUILDINGSLIMIT,
	ACCIDENTALLOSSORDAMAGELIMIT,
	LANDSLIDELIMIT,
	MINIMUMRENTALPERIOD,
	WEEKLYRENT,
	LANDLORDPROTECTIONS
) as WITH PB AS (
        SELECT
            ROW_NUMBER() OVER (
                PARTITION BY TRIM(PUREPOLICYNUMBER)
                ORDER BY
                    SD ASC,
                    ED DESC,
                    LENGTH(INSURANCE_FILE_CNT_LIST) DESC
            ) AS RNO,
            CONCAT(
                TRIM(PUREPOLICYNUMBER),
                '|',
                TRIM(CMLNUMBER),
                '|',
                TRIM(EXPIRINGID_P_LIST),
                '|',
                TRIM(INSURANCE_FILE_CNT_LIST)
            ) AS ID,
            *
        FROM
            AGGNE.PRD.POLICYATTACH_PER_V1
    ),
    BD AS (
        SELECT
            *
        FROM
            AGGNE.PRD.HB_02_Policyattach
    ),
    PB_FLAT AS (
        SELECT
            pb.*,
            TRIM(f_ifc.value::STRING) AS INSURANCE_FILE_CNT_TOKEN,
            TRIM(f_exp.value::STRING) AS EXPIRINGID_P_TOKEN
        FROM
            PB pb,
            LATERAL FLATTEN(
                INPUT => SPLIT(pb.INSURANCE_FILE_CNT_LIST, ',')
            ) f_ifc,
            LATERAL FLATTEN(
                INPUT => SPLIT(pb.EXPIRINGID_P_LIST, ',')
            ) f_exp
        WHERE
            f_ifc.index = f_exp.index
    )
SELECT
    DISTINCT concat(
        pb.ID,
        '/',
        BD.EXPIRINGID_P,
        '/',
        BD.INSURANCE_FILE_CNT
    ) as id,
    pb.id as ACTUALID,
    bd.*
FROM
    PB_FLAT pb
    INNER JOIN BD bd ON TRIM(pb.PUREPolicyNumber) = TRIM(bd.PUREPolicyNumber)
    AND TRIM(pb.CMLNumber) = TRIM(bd.CMLNumber)
    AND TRIM(pb.EXPIRINGID_P_TOKEN) = TRIM(bd.ExpiringID_P)
    AND TRIM(pb.INSURANCE_FILE_CNT_TOKEN) = TRIM(bd.INSURANCE_FILE_CNT)
WHERE
    (
        NOT EXISTS (
            SELECT
                1
            FROM
                AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS
        )
        OR EXISTS (
            SELECT
                1
            FROM
                AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS p
            WHERE
                TRIM(p.PUREPOLICYNUMBER) = TRIM(pb.PUREPOLICYNUMBER)
        )
    );