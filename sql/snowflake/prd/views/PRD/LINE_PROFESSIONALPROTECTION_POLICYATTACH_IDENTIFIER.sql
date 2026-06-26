create or replace view LINE_PROFESSIONALPROTECTION_POLICYATTACH_IDENTIFIER(
	ID,
	ACTUALID,
	PUREPOLICYNUMBER,
	EXPIRINGID_P,
	CMLNUMBER,
	PUREEXPIRYDATE,
	COUNTRY,
	PRODUCT,
	PROFESSIONAL_IND,
	COVERAGE,
	INSURANCE_FILE_CNT,
	PIINDEMNITY,
	PROFESSIONALPROTECTIONLIMIT,
	OVERRIDDEN,
	PIASSESSMENTPROTECTION,
	VEHICLEASSESSMENTPROTECTION,
	VEHICLEASSESSMENTSANNUALTURNOVER,
	PIASSESSMENTLIMIT,
	PIBREAKDOWNPROTECTION,
	VEHICLEBREAKDOWNPROTECTION,
	VEHICLEBREAKDOWNANNUALTURNOVER,
	PIBREAKDOWNLIMIT,
	PIACTSOFOTHERS,
	CONTRACTORSANDSUBCONTRACTORS,
	DETAILS,
	PIACTSOFOTHERSLIMIT,
	PIRETROACTIVECOVER,
	RETROACTIVEPROTECTION,
	PIDATE,
	PIPREVPROTECTION,
	PREVIOUSPROFESSIONALPROTECTION,
	PIPREVCLAIMEVENTS,
	PREVIOUSEVENT,
	PIVOLUNTARY,
	VOLUNTARYEXCESS,
	STANDARDEXCESS,
	IMPOSEDEXCESS
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
            AGGNE.PRD.POLICYATTACH_BP_V1
    ),
    BD AS (
        SELECT
            *
        FROM
            AGGNE.PRD.Line_ProfessionalProtection_Policyattach
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
                AGGNE.PRD.POLICYATTACH_TO_PROCESS
        )
        OR EXISTS (
            SELECT
                1
            FROM
                AGGNE.PRD.POLICYATTACH_TO_PROCESS p
            WHERE
                TRIM(p.PUREPOLICYNUMBER) = TRIM(pb.PUREPOLICYNUMBER)
        )
    );