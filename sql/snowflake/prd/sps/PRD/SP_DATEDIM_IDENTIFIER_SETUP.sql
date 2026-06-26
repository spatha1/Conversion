-- SP: AGGNE.PRD.SP_DATEDIM_IDENTIFIER_SETUP
-- Signature: ()
-- Language:  SQL
-- Collected: 2026-06-25




BEGIN

-- DATE DIM
CREATE OR REPLACE  TABLE AGGNE.PRD.DATE_DIM
AS
SELECT
    ROW_NUMBER() OVER (ORDER BY date_day) AS row_num,
    date_day
FROM (
    SELECT DATEADD(
               DAY,
               SEQ4(),
               DATEADD(YEAR, -2, CURRENT_DATE())
           ) AS date_day
    FROM TABLE(GENERATOR(ROWCOUNT => 1461))  -- 4 years window incl leap day possibility
)
WHERE date_day <= DATEADD(YEAR,  2, CURRENT_DATE())
ORDER BY date_day;

SELECT * FROM AGGNE.PRD.DATE_DIM;

CREATE OR REPLACE TABLE AGGNE.PRD.STEP1
AS
SELECT * 
FROM AGGNE.PRD.POLICYATTACH_BP T1 INNER JOIN AGGNE.PRD.DATE_DIM T2 ON T2.date_day BETWEEN T1.COVERSTARTDATE and T1.COVERENDDATE
;


CREATE OR REPLACE TABLE AGGNE.PRD.PA_STEP2
AS
SELECT date_day,PUREPOLICYNUMBER,CMLNUMBER,LISTAGG( EXPIRINGID_P,',') AS EXPIRINGID_P_LIST,LISTAGG( INSURANCE_FILE_CNT,',') AS INSURANCE_FILE_CNT_LIST FROM AGGNE.PRD.STEP1
GROUP BY date_day,PUREPOLICYNUMBER,CMLNUMBER;




create or replace view AGGNE.PRD.POLICYATTACH_BP_V1(
 PUREPOLICYNUMBER,
 CMLNUMBER,
 SD,
 ED,
 EXPIRINGID_P_LIST,
 INSURANCE_FILE_CNT_LIST,
 EXPIRINGID_P_COUNT,
 INSURANCE_FILE_CNT_COUNT
) as
select PUREPOLICYNUMBER,CMLNUMBER,MIN(date_day) AS SD,MAX(date_day) AS ED ,
EXPIRINGID_P_LIST,INSURANCE_FILE_CNT_LIST
,1 as INSURANCE_FILE_CNT_COUNT,1 as EXPIRINGID_P_COUNT
from  AGGNE.PRD.PA_STEP2
group by PUREPOLICYNUMBER,CMLNUMBER,EXPIRINGID_P_LIST,INSURANCE_FILE_CNT_LIST
;


create or replace view AGGNE.PRD.SAMPLE_POLICYATTACH_FINAL_IDENTIFIER(
	ID,
	ACTUALID,
	CMLNUMBER,
	CSLNUMBER,
	LEGACYPOLICYNUMBER,
	EXPIRINGID_P,
	INSURANCE_FILE_CNT,
	COUNTRY,
	PRIMARYRATINGSTATE,
	LINEOFBUSINESS,
	EFFECTIVEDATE,
	EXPIRATIONDATE,
	MEMBERSHIPSYSTEMDATE,
	LINEOFBUSINESS_STD,
	CHOOSEPROTECTION,
	INCEPTIONDATE,
	COMMENCEMENTDATE
) as  


WITH PB AS (
    SELECT
        ROW_NUMBER() OVER (
            PARTITION BY TRIM(PUREPOLICYNUMBER)
            ORDER BY
                SD ASC,
                ED DESC,
                LENGTH(INSURANCE_FILE_CNT_LIST) DESC
        ) AS RNO,
        CONCAT(
            TRIM(PUREPOLICYNUMBER), '|',
            TRIM(CMLNUMBER), '|',
            TRIM(EXPIRINGID_P_LIST), '|',
            TRIM(INSURANCE_FILE_CNT_LIST)
        ) AS ID,
        *
    FROM POLICYATTACH_BP_V1
),
BD AS (
    SELECT *
    FROM AGGNE.PRD.Sample_Policyattach_Final
),
PB_FLAT AS (
    SELECT
        pb.*,
        TRIM(f_ifc.value::STRING) AS INSURANCE_FILE_CNT_TOKEN,
        TRIM(f_exp.value::STRING) AS EXPIRINGID_P_TOKEN
    FROM PB pb,
         LATERAL FLATTEN(
             INPUT => SPLIT(pb.INSURANCE_FILE_CNT_LIST, ',')
         ) f_ifc,
         LATERAL FLATTEN(
             INPUT => SPLIT(pb.EXPIRINGID_P_LIST, ',')
         ) f_exp
    WHERE f_ifc.index = f_exp.index
)
SELECT DISTINCT
    CONCAT(
        pb.ID, '/',
        BD.EXPIRINGID_P, '/',
        BD.INSURANCE_FILE_CNT
    ) AS id,
    pb.id AS ACTUALID,
    bd.*
FROM PB_FLAT pb
INNER JOIN BD bd
    ON TRIM(pb.PUREPolicyNumber)         = TRIM(bd.legacypolicynumber)
   AND TRIM(pb.CMLNumber)                = TRIM(bd.CMLNumber)
   AND TRIM(pb.EXPIRINGID_P_TOKEN)       = TRIM(bd.ExpiringID_P)
   AND TRIM(pb.INSURANCE_FILE_CNT_TOKEN) = TRIM(bd.INSURANCE_FILE_CNT)
WHERE (
    NOT EXISTS (
        SELECT 1
        FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS
    )
    OR EXISTS (
        SELECT 1
        FROM AGGNE.PRD.POLICYATTACH_TO_PROCESS p
        WHERE TRIM(p.PUREPOLICYNUMBER) = TRIM(pb.PUREPolicyNumber)
    )
);


CREATE
OR REPLACE VIEW AGGNE.PRD.Additional_Interest_Policyattach_IDENTIFIER AS WITH PB AS (
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
        POLICYATTACH_BP_V1
),
BD AS (
    SELECT
        *
    FROM
        AGGNE.PRD.Additional_Interest_Policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.Businessdetails_Final_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.Businessdetails_Final_policyattach
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
        BD.EXPIRINGID,
        '/',
        BD.INSURANCE_FILE_CNT
    ) as id,
    pb.id as ACTUALID,
    bd.*
FROM
    PB_FLAT pb
    INNER JOIN BD bd ON TRIM(pb.PUREPolicyNumber) = TRIM(bd.PUREPolicyNumber)
    AND TRIM(pb.CMLNumber) = TRIM(bd.CMLNumber)
    AND TRIM(pb.EXPIRINGID_P_TOKEN) = TRIM(bd.ExpiringID)
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.CLAIMHISTORY_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.CLAIMHISTORY_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.CM_03_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.CM_03_Policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.Competitor_Information_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.Competitor_Information_Policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.Duty_Disclosure_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.Duty_Disclosure_policyattach
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

CREATE
    OR REPLACE VIEW AGGNE.PRD.line_cv_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.line_cv_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.line_gp_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.line_gp_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.Line_GT_Coverage_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.Line_GT_Coverage_Policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.line_le_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.line_le_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.Line_ProfessionalProtection_Policyattach_IDENTIFIER AS WITH PB AS (
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.Line_PublicLiability_Coverage_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.Line_PublicLiability_Coverage_Policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.line_sv_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.line_sv_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.line_ta_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.line_ta_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.Location_01_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.Location_01_Policyattach
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
        BD.EXPIRINGID,
        '/',
        BD.INSURANCE_FILE_CNT
    ) as id,
    pb.id as ACTUALID,
    bd.*
FROM
    PB_FLAT pb
    INNER JOIN BD bd ON TRIM(pb.PUREPolicyNumber) = TRIM(bd.PUREPolicyNumber)
    AND TRIM(pb.CMLNumber) = TRIM(bd.CMLNumber)
    AND TRIM(pb.EXPIRINGID_P_TOKEN) = TRIM(bd.ExpiringID)
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.location_bb_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.location_bb_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.location_bc_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.location_bc_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.location_bg_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.location_bg_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.location_bi_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.location_bi_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.location_en_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.location_en_coverage_policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.location_money_coverage_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.location_money_coverage_policyattach
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

CREATE
    OR REPLACE VIEW AGGNE.PRD.VehicleCoverages_FleetVehicle_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.VehicleCoverages_FleetVehicle_Policyattach
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

-------------------DELETE ALL THE TARGET TABLES BEFORE LOADING---------------------
DELETE  FROM AGGNE.PRD.CV_FLEET_VEHICLE_TARGET_POLICYATTACH;
DELETE  FROM AGGNE.PRD.PA_ACCOUNT_LOC_TARGET;
DELETE  FROM AGGNE.PRD.PA_AOI_Target;
DELETE  FROM AGGNE.PRD.PA_CLAIM_HISTORY_TARGET;
DELETE  FROM AGGNE.PRD.PA_COMPETITOR_INFORMATION_TARGET;
DELETE  FROM AGGNE.PRD.PA_LINE_CV_Target;
DELETE  FROM AGGNE.PRD.PA_LINE_GP_Target;
DELETE  FROM AGGNE.PRD.PA_LINE_GT_Target;
DELETE  FROM AGGNE.PRD.PA_LINE_LE_Target;
DELETE  FROM AGGNE.PRD.PA_LINE_PF_Target;
DELETE  FROM AGGNE.PRD.PA_LINE_PPL_Target;
DELETE  FROM AGGNE.PRD.PA_LINE_SV_Target;
DELETE  FROM AGGNE.PRD.PA_LINE_TA_Target;
DELETE  FROM AGGNE.PRD.PA_RISK_Building_BC_TARGET;
DELETE  FROM AGGNE.PRD.PA_RISK_BUILDING_BG_TARGET;
DELETE  FROM AGGNE.PRD.PA_RISK_BUILDING_BI_TARGET;
DELETE  FROM AGGNE.PRD.PA_RISK_BUILDING_EN_TARGET;
DELETE  FROM AGGNE.PRD.PA_RISK_BUILDING_FINAL_TARGET;
DELETE  FROM AGGNE.PRD.PA_RISK_BUILDING_Money_TARGET;
DELETE  FROM AGGNE.PRD.PA_RISK_BUILDING_TARGET;
DELETE  FROM AGGNE.PRD.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH;

insert into AGGNE.PRD.LOAD_Policyattach
select 'AGGNE.PRD.SP_DATEDIM_IDENTIFIER_SETUP' as D_INFO,getdate() LoadDate;

RETURN 'SP_Datedim_Identifier_Setup Completed';
END;
