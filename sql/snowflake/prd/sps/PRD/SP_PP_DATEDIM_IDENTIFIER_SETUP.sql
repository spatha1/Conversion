-- SP: AGGNE.PRD.SP_PP_DATEDIM_IDENTIFIER_SETUP
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


CREATE OR REPLACE TABLE AGGNE.PRD.PER_STEP1
AS
SELECT * 
FROM AGGNE.PRD.POLICYATTACH_PER T1 INNER JOIN AGGNE.PRD.DATE_DIM T2 ON T2.date_day BETWEEN T1.COVERSTARTDATE and T1.COVERENDDATE
;

CREATE OR REPLACE TABLE AGGNE.PRD.PER_STEP2
AS
SELECT date_day,PUREPOLICYNUMBER,CMLNUMBER,LISTAGG( EXPIRINGID_P,',') AS EXPIRINGID_P_LIST,LISTAGG( INSURANCE_FILE_CNT,',') AS INSURANCE_FILE_CNT_LIST FROM AGGNE.PRD.PER_STEP1
GROUP BY date_day,PUREPOLICYNUMBER,CMLNUMBER;


create or replace view AGGNE.PRD.POLICYATTACH_PER_V1 as

select PUREPOLICYNUMBER,CMLNUMBER,MIN(date_day) AS SD,MAX(date_day) AS ED ,
EXPIRINGID_P_LIST,INSURANCE_FILE_CNT_LIST
,1 as INSURANCE_FILE_CNT_COUNT,1 as EXPIRINGID_P_COUNT
from  AGGNE.PRD.PER_STEP2
group by PUREPOLICYNUMBER,CMLNUMBER,EXPIRINGID_P_LIST,INSURANCE_FILE_CNT_LIST
; 


DELETE  FROM AGGNE.PRD.PA_PER_ACCOUNT_LOC_TARGET;
DELETE  FROM AGGNE.PRD.PA_PER_BUILDING_TARGET;
DELETE  FROM AGGNE.PRD.PA_PER_CLAIM_HISTORY_TARGET;
DELETE  FROM AGGNE.PRD.PA_PER_COM_COVERAGES_TARGET;
DELETE  FROM AGGNE.PRD.PA_PER_COMPETITOR_INFORMATION_TARGET;
DELETE  FROM AGGNE.PRD.PA_PER_HC_TARGET;
DELETE  FROM AGGNE.PRD.PA_PER_RISK_BUILDING_TARGET;




create or replace view AGGNE.PRD.PER_SAMPLE_POLICYATTACH_FINAL_IDENTIFIER
AS 
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
    FROM AGGNE.PRD.POLICYATTACH_PER_V1
),

BD AS (
    SELECT *
    FROM AGGNE.PRD.SAMPLE_POLICYATTACH_FINAL WHERE TRIM(LINEOFBUSINESS)='Personal Protections'
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
        bd.EXPIRINGID_P, '/',
        bd.INSURANCE_FILE_CNT
    ) AS ID,
    pb.ID AS ACTUALID,
    bd.*
FROM PB_FLAT pb
INNER JOIN BD bd
    ON TRIM(pb.PUREPolicyNumber)          = TRIM(bd.legacypolicynumber)
   AND TRIM(pb.CMLNumber)                 = TRIM(bd.CMLNumber)
   AND TRIM(pb.EXPIRINGID_P_TOKEN)        = TRIM(bd.ExpiringID_P)
   AND TRIM(pb.INSURANCE_FILE_CNT_TOKEN)  = TRIM(bd.INSURANCE_FILE_CNT)
WHERE
    (
        NOT EXISTS (
            SELECT 1
            FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS
        )
        OR EXISTS (
            SELECT 1
            FROM AGGNE.PRD.PER_POLICYATTACH_TO_PROCESS p
            WHERE TRIM(p.PUREPOLICYNUMBER) = TRIM(pb.PUREPOLICYNUMBER)
        )
    );
CREATE
    OR REPLACE VIEW AGGNE.PRD.Locationdetails_PER_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.Locationdetails_PER_Policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.ManualRef_PER_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.ManualRef_PER_Policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.PM_03_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.PM_03_Policyattach
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.Policyattach_PER_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.Policyattach_PER
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.HB_02_Policyattach_IDENTIFIER AS WITH PB AS (
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
CREATE
    OR REPLACE VIEW AGGNE.PRD.HC_02_Policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.HC_02_Policyattach
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

CREATE
    OR REPLACE VIEW AGGNE.PRD.PER_Competitor_Information_policyattach_IDENTIFIER AS WITH PB AS (
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
            AGGNE.PRD.PER_Competitor_Information_policyattach
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

insert into AGGNE.PRD.LOAD_Policyattach
select 'AGGNE.PRD.SP_PP_Datedim_Identifier_Setup' as D_INFO,getdate() LoadDate;

RETURN 'SP_PP_Datedim_Identifier_Setup Completed';

END;
