-- SP: AGGNE.PRD.SP_PP_ADJ_EXP_PREM_POLICYATTACH
-- Signature: ()
-- Language:  SQL
-- Collected: 2026-06-25


BEGIN
-----------Per_ Ajustments and Exp Prem --------------------------------------

-----------------------------Policy_Sample_PER_01---------------------------------------------------------
   CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Policy_Sample_PER_01_Policyattach AS
         SELECT DISTINCT 
                   t3.INSURANCE_REF AS PolicyNumber, 
                   t3.INSURANCE_FILE_TYPE_ID,
                   t18.PER_Policy_Binder_id AS ExpiringID_P,
                   t1.RISK_CNT AS risk_cnt,
                   CAST(t3.expiry_date AS DATE) AS ExpiryDate,
                   t13.description AS Country,
                   t19.code AS Product,
                   t1.risk_number AS RiskNumber,
                   CAST(t20.SUHCTotalContrib AS NUMBER(11,2))  AS HMExpPrem,
                   CAST(t20.SUMVTotalContrib AS NUMBER(11,2)) AS PMExpPrem,
                   CAST(t20.SUHCBaseContrib AS NUMBER(11,2)) AS TotalBase,
                   CAST(t20.SUTotStormBase AS NUMBER(11,2)) AS StormBase,  
                   CAST(t20.SUTotCycloneBase AS NUMBER(11,2)) AS CycloneBase,     
                   CAST(t20.SUTotBushFireBase AS NUMBER(11,2)) AS BushFireBase,     
                   CAST(t20.SUTotEarthquakeBase AS NUMBER(11,2)) AS EarthquakeBase
          FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t1
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Folder              t0  ON t1.risk_folder_cnt = t0.risk_folder_cnt
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2  ON t1.risk_cnt = t2.risk_cnt
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File           t3  ON t2.insurance_file_cnt = t3.insurance_file_cnt
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link          t6  ON t3.insured_cnt = t6.party_cnt  
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_Policy_Binder   t7  ON t6.gis_policy_link_id = t7.gis_policy_link_id   
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_MEMBERCSL       t9  ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Party                    t14 ON t3.insured_cnt = t14.party_cnt
          LEFT JOIN AGGNE.PRD.CLIENTCONTACTS                     t10 ON t6.party_cnt = T10.clientid
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Source                   t13 ON t3.source_id = t13.source_id
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Status              t15 ON t1.risk_status_id = t15.risk_status_id
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status    t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
          LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link          t17 ON t1.risk_cnt = t17.risk_id
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder        t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
         INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Product                  t19 ON (t3.product_id = t19.product_id) 
        INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_SUMMARY t20 ON (t20.PER_Policy_Binder_id = t18.PER_Policy_Binder_id)
        WHERE 
        --CAST(t3.expiry_date AS DATE) = CURRENT_DATE() + 42
              SUBSTR(t3.insurance_ref,1,1) = 'P'
             AND t3.insurance_file_type_id <> 3                 /* (3=Policy under Renewal) */
             AND COALESCE(t3.insurance_file_status_id,NULL,0) NOT IN (1, 2)      /* (1=Cancelled, 2=Lapsed) */
             AND t15.risk_status_id IN (1, 3)                   /* (1=Referred, 3=Quoted) */
                AND t2.status_flag <> 'D'                         /* (D=Deleted) */
             AND t3.insurance_ref NOT IN (
                 SELECT DISTINCT t13.insurance_ref 
                 FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk t11
                 INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t12 ON t11.risk_cnt = t12.risk_cnt
                 INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File t13 ON t12.insurance_file_cnt = t13.insurance_file_cnt
                 WHERE CAST(t13.expiry_date AS DATE) > CURRENT_DATE()
                   AND t13.insurance_file_type_id = 8        /* (8 = MTA Cancelled) */
             )
             AND (
                 /* Case 1: Only one insurance_file_cnt for the policy */
                 (SELECT COUNT(DISTINCT ins.insurance_file_cnt)
                  FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
                  WHERE ins.insurance_ref = t3.insurance_ref) = 1
                 OR

                 /* Case 2: Multiple insurance_file_cnts — pick the latest non-cancelled one */
                 t3.insurance_file_cnt = (
                     SELECT MAX(ins.insurance_file_cnt)
                     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File ins
                     LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status status 
                       ON ins.insurance_file_status_id = status.insurance_file_status_id
                     WHERE ins.insurance_ref = t3.insurance_ref
                       AND (status.insurance_file_status_id <> 1 OR status.insurance_file_status_id  IS NULL) /* (1=Cancelled) */
                 )
             )
       ORDER BY ExpiryDate, PolicyNumber;

------------------------------------------------Policy_Sample_PER----------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Policy_Sample_PER_Policyattach AS
SELECT
    t.*,
    -- Initialize fields (they’ll be 0 if HMExpPrem <= 0)
    CASE 
        WHEN HMExpPrem > 0 THEN 
            ROUND(
                ( (TotalBase - (StormBase + CycloneBase + BushFireBase + EarthquakeBase))
                  - LEAST(250, (TotalBase - (StormBase + CycloneBase + BushFireBase + EarthquakeBase)) * 0.20)
                ) / TotalBase,
            4)
        ELSE 0
    END AS Standard,

    CASE 
        WHEN HMExpPrem > 0 THEN 
            ROUND(
                LEAST(250, (TotalBase - (StormBase + CycloneBase + BushFireBase + EarthquakeBase)) * 0.20) 
                / TotalBase,
            4)
        ELSE 0
    END AS Liability,

    CASE 
        WHEN HMExpPrem > 0 THEN ROUND(StormBase / TotalBase, 4)
        ELSE 0
    END AS Storm,

    CASE 
        WHEN HMExpPrem > 0 THEN ROUND(CycloneBase / TotalBase, 4)
        ELSE 0
    END AS Cyclone,

    CASE 
        WHEN HMExpPrem > 0 THEN ROUND(BushFireBase / TotalBase, 4)
        ELSE 0
    END AS BushFire,

    CASE 
        WHEN HMExpPrem > 0 THEN ROUND(EarthquakeBase / TotalBase, 4)
        ELSE 0
    END AS Earthquake

   FROM AGGNE.PRD.Policy_Sample_PER_01_Policyattach  t;

-----------------------------------------CLAIM_SAMPLE_PER--------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT  TABLE AGGNE.PRD.CLAIM_SAMPLE_PER_Policyattach AS
SELECT DISTINCT clm.Claim_Number AS ClaimNumber
	,Sam.ExpiringID_P
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM AS clm
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.INSURANCE_FILE AS ins ON clm.Policy_id = ins.insurance_file_cnt
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk AS Risk ON clm.Risk_type_id = Risk.risk_cnt
INNER JOIN AGGNE.PRD.Policy_Sample_PER_Policyattach AS Sam ON Sam.PolicyNumber = TRIM(ins.insurance_ref)
	AND Risk.risk_number = Sam.RiskNumber
	AND CAST(clm.Reported_date AS DATE) > CURRENT_DATE () - 366
	AND clm.is_dirty = 0
ORDER BY clm.Claim_Number;

-----------------------------------------CLAIM_COVER_PER_01---------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIM_COVER_PER_01_Policyattach AS
SELECT DISTINCT t0.ClaimNumber
	,t0.ExpiringID_P
	,t3.HomeBuildings
	,t3.HomeContents
	,t3.MotorVehicles
	,MAX(t3.CPPCLMS_Policy_Binder_id) AS MAX_PB
FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM AS t1
INNER JOIN AGGNE.PRD.CLAIM_SAMPLE_PER_Policyattach AS t0 ON (t0.ClaimNumber = T1.Claim_Number)
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_POLICY_LINK AS T2 ON (T1.Claim_id = T2.claim_id)
INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CPPCLMS_RISKSELECTION AS T3 ON (T2.gis_policy_link_id = T3.CPPCLMS_Policy_Binder_id)
GROUP BY t0.ClaimNumber,t0.ExpiringID_P, t3.HomeBuildings, t3.HomeContents, t3.MotorVehicles;

-----------------------------------------CLAIM_COVER_PER_02-------------------------------------------------------------------
    CREATE OR REPLACE TRANSIENT  TABLE AGGNE.PRD.CLAIM_COVER_PER_02_Policyattach AS
    SELECT DISTINCT CS.*
    	,SUBSTR(t2.ReserveType, 1, 2) AS Coverage
    	,ROUND(SUM(t2.InitialReserve) + SUM(t2.RevisedReserve)) AS COST
    FROM Aggne.PRD.VW_PRD_T5_EXTERNAL_AGGNE_PURE_SNAPSHOT_claims t2
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM t1 ON (t2.ID = t1.Claim_id)
    INNER JOIN AGGNE.PRD.CLAIM_COVER_PER_01_Policyattach AS CS ON (CS.ClaimNumber = t1.Claim_Number)
    	AND t1.Claim_id = (
    		SELECT MAX(t3.Claim_id)
    		FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM AS t3
    		WHERE t1.Claim_Number = t3.Claim_Number
    		)
    GROUP BY 
    Coverage,
    cs.claimnumber,
    cs.expiringid_p,
    cs.HomeBuildings,
    cs.HomeContents,
    cs.MotorVehicles,
    cs.max_pb
    ORDER BY cs.claimnumber, COST;

-------------------------------------------CLAIM_COVER_PER_03-------------------------------------------------------------------
    CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIM_COVER_PER_03_Policyattach AS
    SELECT 
        t1.CLAIMNUMBER,
        t1.EXPIRINGID_P,
        t1.HomeBuildings,
        t1.HomeContents,
        t1.MotorVehicles,
        t1.MAX_PB,
        t1.coverage,
        CASE 
            WHEN Coverage = 'HB' THEN COST + HomeBuildings
            WHEN Coverage = 'HC' THEN COST + HomeContents
            WHEN Coverage = 'PM' THEN COST + MotorVehicles
            ELSE COST
        END AS COST
    FROM AGGNE.PRD.CLAIM_COVER_PER_02_Policyattach t1
    ORDER BY t1.CLAIMNUMBER, COST;

----------------------------------------------------CLAIM_COVER_PER-------------------------------------------------------------------
    CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIM_COVER_PER_Policyattach AS
    SELECT
        ClaimNumber,
        Coverage,
        ExpiringID_P
    FROM (
        SELECT 
            ClaimNumber,
            Coverage,
            ExpiringID_P,
            ROW_NUMBER() OVER (
                PARTITION BY ClaimNumber
                ORDER BY COST DESC
            ) AS rn
        FROM AGGNE.PRD.CLAIM_COVER_PER_02_Policyattach
    )
    WHERE rn = 1;
--------------------------------------------------CLAIM_PAYMENT_PER-------------------------------------------------------------
 CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIM_PAYMENT_PER_Policyattach AS 
       SELECT t1.Claim_Number  AS ClaimNumber,
       ROUND(SUM(t2.InitialReserve)
       + SUM(t2.RevisedReserve)
       - SUM(t2.PaidToDate)) AS Reserves,
       ROUND(SUM(t2.PaidToDate)) AS PaidToDate
             FROM Aggne.PRD.VW_PRD_T5_EXTERNAL_AGGNE_PURE_SNAPSHOT_claims t2
       INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM t1 ON (t2.ID = t1.Claim_id)
       INNER JOIN AGGNE.PRD.CLAIM_SAMPLE_PER_Policyattach AS CS ON (CS.ClaimNumber = t1.Claim_Number)
           AND t1.Claim_id = 
              (
       SELECT MAX(t3.Claim_id)
         FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM AS t3
           WHERE t1.Claim_Number = t3.Claim_Number
           )    
       GROUP BY t1.Claim_Number
       ORDER BY t1.Claim_Number;

---------------------------------------------------CLAIM_RECEIPT_PER_01--------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIM_RECEIPT_PER_01_Policyattach AS 
   SELECT DISTINCT t2.Claim_Number  AS ClaimNumber,
          TO_DECIMAL((t1.Amount - t1.tax_amount),11,0) AS Recovered_TEMP
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Claim_Receipt t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM t2 ON (t2.Claim_id = t1.claim_id)
     INNER JOIN AGGNE.PRD.CLAIM_SAMPLE_PER_Policyattach AS CS ON (CS.ClaimNumber = t2.Claim_Number)
    ORDER BY t2.Claim_Number;

--------------------------------------------------CLAIM_RECEIPT_PER-------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIM_RECEIPT_PER_Policyattach AS 
   SELECT t1.ClaimNumber, 
             TO_DECIMAL(SUM(t1.Recovered_TEMP),11,0) AS Recovered
     FROM AGGNE.PRD.CLAIM_RECEIPT_PER_01_Policyattach t1
    GROUP BY t1.ClaimNumber;

---------------------------------------------CLAIMS_PER_01--------------------------------------------------------------------------
    CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIMS_PER_01_Policyattach AS
    SELECT  
        a.ClaimNumber,
        a.expiringid_p,
        c.coverage,
        COALESCE(r.recovered, 0) AS Recovered,
        p.RESERVES,
        p.paidtodate
    FROM AGGNE.PRD.CLAIM_SAMPLE_PER_Policyattach a
    LEFT JOIN AGGNE.PRD.CLAIM_COVER_PER_Policyattach     c ON a.ClaimNumber = c.ClaimNumber
    LEFT JOIN AGGNE.PRD.CLAIM_PAYMENT_PER_Policyattach   p ON a.ClaimNumber = p.ClaimNumber
    LEFT JOIN AGGNE.PRD.CLAIM_RECEIPT_PER_Policyattach   r ON a.ClaimNumber = r.ClaimNumber
    ORDER BY a.ClaimNumber;

-----------------------------------------CLAIMS_PER_02--------------------------------------------------------------------------------
    CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIMS_PER_02_Policyattach AS 
   SELECT t1.ExpiringID_P, 
          t1.Coverage, 
             ROUND(SUM(t1.Reserves)) + (SUM(t1.PaidToDate)) - TO_DECIMAL((SUM(t1.Recovered)),11,0) AS Incurred,
                TO_DECIMAL((COUNT(t1.ExpiringID_P)),11,0) AS Count
      FROM AGGNE.PRD.CLAIMS_PER_01_Policyattach t1
     GROUP BY t1.ExpiringID_P,
              t1.Coverage;

-----------------------------------------CLAIMS_PER_03a--------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIMS_PER_03a_Policyattach AS
    SELECT *
    FROM AGGNE.PRD.CLAIMS_PER_02_Policyattach
    PIVOT (
        SUM(Incurred)                -- equivalent to placing VAR=Incurred into cells
        FOR Coverage IN (            -- equivalent to ID Coverage
            'HB' AS HB,
            'PM' AS PM,
            'HC' AS HC
        )
    ) AS P
    ORDER BY ExpiringID_P;

----------------------------------------------CLAIMS_PER_03---------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIMS_PER_03_Policyattach AS
SELECT t1.ExpiringID_P,
    t1.hb AS HBClmIncd,
    t1.hc AS HCClmIncd,
    t1.pm AS PMClmIncd
    FROM AGGNE.PRD.CLAIMS_PER_03a_Policyattach t1;

-------------------------------------------CLAIMS_PER_04a-------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIMS_PER_04a_Policyattach AS
    SELECT *
    FROM AGGNE.PRD.CLAIMS_PER_02_Policyattach
    PIVOT (
        SUM(Count)                -- equivalent to placing Count=Incurred into cells
        FOR Coverage IN (            -- equivalent to ID Coverage
            'HB' AS HB,
            'PM' AS PM,
            'HC' AS HC
        )
    ) AS P
    ORDER BY ExpiringID_P;
    
------------------------------------------CLAIMS_PER_04------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.CLAIMS_PER_04_Policyattach AS
SELECT t1.ExpiringID_P,
    t1.hb AS HBClmCnt,
    t1.hc AS HCClmCnt,
    t1.pm AS PMClmCnt
    FROM AGGNE.PRD.CLAIMS_PER_04a_Policyattach t1;

---------------------------------------Policy_Sample_PER-----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Policy_Sample_PER_Policyattach AS
SELECT * FROM AGGNE.PRD.Policy_Sample_PER_Policyattach t1
ORDER BY t1.expiringid_p;

--------------------------------------COVERAGE_PER------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.COVERAGE_PER_Policyattach AS
SELECT
    p.*,
    COALESCE(c03.HBClmIncd, 0) AS HBClmIncd,
    COALESCE(c03.HCClmIncd, 0) AS HCClmIncd,
    COALESCE(c03.PMClmIncd, 0) AS PMClmIncd,
    COALESCE(c04.HBClmCnt, 0) AS HBClmCnt,
    COALESCE(c04.HCClmCnt, 0) AS HCClmCnt,
    COALESCE(c04.PMClmCnt, 0) AS PMClmCnt
FROM AGGNE.PRD.Policy_Sample_PER_Policyattach p
LEFT JOIN AGGNE.PRD.CLAIMS_PER_03_Policyattach c03
    ON p.ExpiringID_P = c03.ExpiringID_P
LEFT JOIN AGGNE.PRD.CLAIMS_PER_04_Policyattach c04
    ON p.ExpiringID_P = c04.ExpiringID_P;

---------------------------------------Output_Coverage_PER--------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Output_Coverage_PER_Policyattach AS
SELECT t1.PolicyNumber, 
          t1.ExpiringID_P, 
             t1.RiskNumber,
          t1.ExpiryDate, 
          t1.Country, 
          t1.Product, 
          t1.HMExpPrem, 
          t1.HBClmIncd, 
          t1.HBClmCnt,         
          t1.HCClmIncd, 
          t1.HCClmCnt, 
          t1.PMExpPrem, 
          t1.PMClmIncd, 
          t1.PMClmCnt 
      FROM AGGNE.PRD.COVERAGE_PER_Policyattach t1;

--------------------------------------------Rego_PER_01-----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Rego_PER_01_Policyattach  AS 
         SELECT DISTINCT PB.PolicyNumber 
              , PB.ExpiringID_P 
              , PB.ExpiryDate  
              , t1.MVVehReg  AS RegoNumber
                  , t1.MVVehClaimOn AS MVVehClaimOn
                  , CS.ClaimNumber AS ClaimNumber
           FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CPPCLMS_VEHICLE AS t1
             INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_POLICY_LINK AS t2 ON (t1.CPPCLMS_Policy_Binder_id = t2.gis_policy_link_id)
             INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM AS t3 ON (t2.claim_id = t3.Claim_id)
             INNER JOIN AGGNE.PRD.CLAIM_COVER_PER_Policyattach AS CS ON (CS.ClaimNumber = t3.Claim_Number)
             INNER JOIN AGGNE.PRD.Policy_Sample_PER_Policyattach AS PB ON (CS.ExpiringID_P = PB.ExpiringID_P)
          WHERE CS.Coverage = 'PM'
            AND t1.CPPCLMS_Policy_Binder_id = 
              (
       SELECT MAX(t4.CPPCLMS_Policy_Binder_id)
         FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CPPCLMS_VEHICLE AS t4
           INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_POLICY_LINK AS t5 ON (t4.CPPCLMS_Policy_Binder_id = t5.gis_policy_link_id)
           INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CLAIM AS t6 ON (t5.claim_id = t6.Claim_id )
           WHERE t3.Claim_Number = t6.Claim_Number)
           ORDER BY ClaimNumber, MVVehClaimOn;

----------------------------------------------Rego_PER_02-----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Rego_PER_02_Policyattach AS
    SELECT *
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY ClaimNumber
                ORDER BY MVVehClaimOn DESC
            ) AS rn
        FROM AGGNE.PRD.Rego_PER_01_Policyattach
    )
    WHERE rn = 1;

-----------------------------------------------ExpiringPrem_PER-----------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.ExpiringPrem_PER_Policyattach AS 
   SELECT DISTINCT t2.PolicyNumber,
             t2.ExpiringID_P,
             t2.Standard,
             t2.Liability,
             t2.Storm,
             t2.Cyclone,
             t2.BushFire,
             t2.Earthquake,
             SUBSTR(t4.code,3,2) AS Section_01,
             SUBSTR(t4.code,5,4) AS Sub_Section_01, 
          TO_DECIMAL(t1.annual_premium,11,2)  AS annual_premium_
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Rating_Section t1
    INNER JOIN AGGNE.PRD.COVERAGE_PER_Policyattach t2 ON (t1.risk_cnt = t2.risk_cnt)
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Rating_Section_Type t3 ON (t1.rating_section_type_id = t3.rating_section_type_id)
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Class_Of_Business t4 ON (t3.caption_id = t4.caption_id AND t4.is_deleted = 0)
    WHERE t1.original_flag = 0 AND SUBSTR(t3.code,1,5) <> 'NZFSC';

--------------------------------Output_SubCover_PER-----------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Output_SubCover_PER_Policyattach AS

WITH base AS (
    SELECT
        PolicyNumber,
        ExpiringID_P,
        Section_01,
        Sub_Section_01,
        annual_premium_,
        BushFire,
        Cyclone,
        Earthquake,
        Standard,
        Storm,
        Liability
    FROM AGGNE.PRD.ExpiringPrem_PER_Policyattach
),

/* Simple 1:1 mappings */
simple AS (
    SELECT 
        PolicyNumber,
        ExpiringID_P,
        CASE
            WHEN Section_01='HC' AND Sub_Section_01='BANN' THEN 'HBBAD_SD'
            WHEN Section_01='HC' AND Sub_Section_01='BFNN' THEN 'HBBFL_SD'
            WHEN Section_01='HC' AND Sub_Section_01='BLNN' THEN 'HBBLN_SD'
            WHEN Section_01='HC' AND Sub_Section_01='CANN' THEN 'HCCAD_SD'
            WHEN Section_01='HC' AND Sub_Section_01='CFNN' THEN 'HCCFL_SD'
            WHEN Section_01='HC' AND Sub_Section_01='CLNN' THEN 'HCCLN_SD'
            WHEN Section_01='HC' AND Sub_Section_01='LLNN' THEN 'HBLLB_SD'
            WHEN Section_01='HC' AND Sub_Section_01='PONN' THEN 'HCPOR_SD'
            WHEN Section_01='HC' AND Sub_Section_01='SPNN' THEN 'HCSPE_SD'

            WHEN Section_01='PM' AND Sub_Section_01='CONN' THEN 'PMCOR_SD'
            WHEN Section_01='PM' AND Sub_Section_01='FTNN' THEN 'PMFTL_SD'
            WHEN Section_01='PM' AND Sub_Section_01='PCNN' THEN 'PMPCH_SD'
            WHEN Section_01='PM' AND Sub_Section_01='TFNN' THEN 'PMTFT_SD'
            WHEN Section_01='PM' AND Sub_Section_01='TPNN' THEN 'PMTPO_SD'
            WHEN Section_01='PM' AND Sub_Section_01='ULNN' THEN 'PMULG_SD'
        END AS Sub_Coverage,
        annual_premium_ AS ExpPremium
    FROM base
    WHERE (
        (Section_01='HC' AND Sub_Section_01 IN ('BANN','BFNN','BLNN','CANN','CFNN','CLNN','LLNN','PONN','SPNN'))
        OR
        (Section_01='PM' AND Sub_Section_01 IN ('CONN','FTNN','PCNN','TFNN','TPNN','ULNN'))
    )
),

/* BDNN block */
bdnn AS (
    SELECT PolicyNumber, ExpiringID_P, 'HBBLD_BF',
           GREATEST(1, annual_premium_ * BushFire)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='BDNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HBBLD_CY',
           GREATEST(1, annual_premium_ * Cyclone)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='BDNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HBBLD_EQ',
           GREATEST(1, annual_premium_ * Earthquake)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='BDNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HBBLD_SD',
           GREATEST(1, annual_premium_ * Standard)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='BDNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HBBLD_ST',
           GREATEST(1, annual_premium_ * Storm)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='BDNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HBBLI_SD',
           GREATEST(1, annual_premium_ * Liability)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='BDNN'
),

/* CNNN block */
cnnn AS (
    SELECT PolicyNumber, ExpiringID_P, 'HCCNT_BF',
           GREATEST(1, annual_premium_ * BushFire)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='CNNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HCCNT_CY',
           GREATEST(1, annual_premium_ * Cyclone)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='CNNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HCCNT_EQ',
           GREATEST(1, annual_premium_ * Earthquake)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='CNNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HCCNT_SD',
           GREATEST(1, annual_premium_ * Standard)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='CNNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HCCNT_ST',
           GREATEST(1, annual_premium_ * Storm)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='CNNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'HCCLI_SD',
           GREATEST(1, annual_premium_ * Liability)
    FROM base WHERE Section_01='HC' AND Sub_Section_01='CNNN'
),

/* CMNN block */
cmnn AS (
    SELECT PolicyNumber, ExpiringID_P, 'PMCMP_SD',
           annual_premium_ * (2/3)
    FROM base WHERE Section_01='PM' AND Sub_Section_01='CMNN'
    UNION ALL
    SELECT PolicyNumber, ExpiringID_P, 'PMLIA_SD',
           annual_premium_ * (1/3)
    FROM base WHERE Section_01='PM' AND Sub_Section_01='CMNN'
)

SELECT * FROM simple
UNION ALL SELECT * FROM bdnn
UNION ALL SELECT * FROM cnnn
UNION ALL SELECT * FROM cmnn;

----------------------------------------------ExpPremium_PER_A----------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.ExpPremium_PER_A_Policyattach AS 
   SELECT t1.PolicyNumber,
          t1.ExpiringID_P, 
          NULL AS Vehicle_ID,
          'SU' AS Coverage,
            TO_DECIMAL(SUM(t1.ExpPremium),11,2) AS ExpPremium,
            NULL AS HBMix,
            NULL AS HCMix,
     FROM AGGNE.PRD.Output_SubCover_PER_Policyattach t1
    GROUP BY t1.PolicyNumber,
             t1.ExpiringID_P;

-----------------------------------------ExpPremium_PER_B_a-----------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.ExpPremium_PER_B_a_Policyattach AS 
   SELECT t1.PolicyNumber,
          t1.ExpiringID_P, 
          SUBSTR(t1.Sub_Coverage,1,2) AS Coverage,
            TO_DECIMAL(SUM(t1.ExpPremium),11,2)  AS ExpPremium
      FROM AGGNE.PRD.Output_SubCover_PER_Policyattach t1
     WHERE SUBSTR(t1.Sub_Coverage,1,2) <> 'PM'
     GROUP BY t1.PolicyNumber,
              t1.ExpiringID_P,
           SUBSTR(t1.Sub_Coverage,1,2)
           ORDER BY t1.ExpiringID_P;

---------------------------------------ExpPremium_PER_B_HB--------------------------------------------------------------------
 CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.ExpPremium_PER_B_HB_Policyattach AS
    SELECT
        PolicyNumber,
        ExpiringID_P,
        ExpPremium AS HB_
    FROM AGGNE.PRD.ExpPremium_PER_B_a_Policyattach
    WHERE Coverage = 'HB'
    ORDER BY ExpiringID_P;

-------------------------------------ExpPremium_PER_B_HC------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.ExpPremium_PER_B_HC_Policyattach AS
    SELECT
        PolicyNumber,
        ExpiringID_P,
        ExpPremium AS HC_
    FROM AGGNE.PRD.ExpPremium_PER_B_a_Policyattach
    WHERE Coverage = 'HC'
    ORDER BY ExpiringID_P;

-----------------------------------------------ExpPremium_PER_B----------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.ExpPremium_PER_B_Policyattach AS
SELECT 
      t1.PolicyNumber,
      t1.ExpiringID_P,
      NULL AS Vehicle_ID,
      t1.coverage,
      t1.exppremium,
      /* Compute totals */
      CASE 
          WHEN COALESCE(t2.HB_, 0) + COALESCE(t3.HC_, 0) > 0
          THEN TO_DECIMAL(COALESCE(t2.HB_, 0) / (COALESCE(t2.HB_, 0) + COALESCE(t3.HC_, 0)),6,2)
          ELSE 0
      END AS HBMix,
      CASE 
          WHEN COALESCE(t2.HB_, 0) + COALESCE(t3.HC_, 0) > 0
          THEN TO_DECIMAL(COALESCE(t3.HC_, 0) / (COALESCE(t2.HB_, 0) + COALESCE(t3.HC_, 0)),11,2)
          ELSE 0
      END AS HCMix
FROM AGGNE.PRD.ExpPremium_PER_B_a_Policyattach t1
FULL OUTER JOIN AGGNE.PRD.ExpPremium_PER_B_HB_Policyattach t2
       ON t1.ExpiringID_P = t2.ExpiringID_P
FULL OUTER JOIN AGGNE.PRD.ExpPremium_PER_B_HC_Policyattach t3
       ON COALESCE(t1.ExpiringID_P, t2.ExpiringID_P) = t3.ExpiringID_P;

---------------------------------ExpPremium_PER_C-------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.ExpPremium_PER_C_Policyattach AS 
   SELECT DISTINCT t2.PolicyNumber,
          t1.PER_Policy_Binder_id AS ExpiringID_P, 
         RTRIM(t1.PER_VEHICLEDETAIL_id) AS Vehicle_ID, 
             'PM' AS Coverage,
          TO_DECIMAL(t1.MVNetContribution,11,2)  AS ExpPremium,
          NULL AS HBMix,
            NULL AS HCMix
      FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL t1
     INNER JOIN AGGNE.PRD.Output_SubCover_PER_Policyattach t2 ON (t1.PER_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.MVNetContribution > 0;

-------------------------------------------ExpPremium_PER-------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.ExpPremium_PER_Policyattach AS
SELECT * FROM AGGNE.PRD.ExpPremium_PER_A_Policyattach
UNION ALL SELECT * FROM AGGNE.PRD.ExpPremium_PER_B_Policyattach
UNION ALL SELECT * FROM AGGNE.PRD.ExpPremium_PER_C_Policyattach
ORDER BY EXPIRINGID_P,VEHICLE_ID, COVERAGE;

---------------------------------------PM_ADJUST---------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.PM_ADJUST_Policyattach AS 
   SELECT DISTINCT t1.PER_Policy_Binder_id AS ExpiringID_P, 
          RTRIM(t1.PER_VEHICLEDETAIL_id) AS Vehicle_ID, 
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
          t1.AJAdjustmentNote,
          NULL AS HCMix,
          NULL AS HBMix,
             'PM' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSMV t1
     INNER JOIN AGGNE.PRD.ExpPremium_PER_Policyattach t2 ON (t1.PER_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
       AND t2.Coverage = 'PM'
    ORDER BY t1.PER_Policy_Binder_id;

----------------------------------------HC_ADJUST----------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.HC_ADJUST_Policyattach AS 
    SELECT DISTINCT t1.PER_Policy_Binder_id AS ExpiringID_P, 
              t2.vehicle_id AS Vehicle_ID,
              t1.AJAdjustmentPercent, 
              t1.AJAdjustmentValue, 
              t1.AJType,
              t1.AJAdjustmentNote,
              t2.HCMix,
               t2.HBMix,
                 'HC' AS Coverage 
         FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSHC t1
         INNER JOIN AGGNE.PRD.ExpPremium_PER_Policyattach t2 ON (t1.PER_Policy_Binder_id = t2.ExpiringID_P)
         WHERE t1.AJRecurringIndicator = 1
           AND t2.Coverage = 'HC' 
        ORDER BY t1.PER_Policy_Binder_id;
--------------------------------------HB_ADJUST----------------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.HB_ADJUST_Policyattach AS 
   SELECT DISTINCT t1.PER_Policy_Binder_id AS ExpiringID_P, 
          t2.vehicle_id AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
          t1.AJAdjustmentNote,
          t2.HCMix,
          t2.HBMix,
             'HB' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSHC t1
     INNER JOIN AGGNE.PRD.ExpPremium_PER_Policyattach t2 ON (t1.PER_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
       AND t2.Coverage = 'HB' 
    ORDER BY t1.PER_Policy_Binder_id;

----------------------------------------SU_ADJUST_PER---------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.SU_ADJUST_PER_Policyattach AS 
   SELECT DISTINCT  t1.PER_Policy_Binder_id AS ExpiringID_P,
          t2.vehicle_id AS Vehicle_ID,
          t1.AJAdjustmentPercent, 
          t1.AJAdjustmentValue, 
          t1.AJType,
          t1.AJAdjustmentNote,
          t2.HCMix,
          t2.HBMix,
             'SU' AS Coverage 
     FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_ADJUSTMENTSSU t1
     INNER JOIN AGGNE.PRD.ExpPremium_PER_Policyattach t2 ON (t1.PER_Policy_Binder_id = t2.ExpiringID_P)
     WHERE t1.AJRecurringIndicator = 1
    ORDER BY t1.PER_Policy_Binder_id; 

----------------------------------------Adjustments_PER_A------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Adjustments_PER_A_Policyattach AS
SELECT * FROM AGGNE.PRD.PM_ADJUST_Policyattach
UNION ALL SELECT * FROM AGGNE.PRD.HC_ADJUST_Policyattach
UNION ALL SELECT * FROM AGGNE.PRD.HB_ADJUST_Policyattach
UNION ALL SELECT * FROM AGGNE.PRD.SU_ADJUST_PER_Policyattach
ORDER BY EXPIRINGID_P, VEHICLE_ID, COVERAGE;

--------------------------------------Adjustments_PER_B----------------------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Adjustments_PER_B_Policyattach AS 
   SELECT t1.ExpiringID_P,
          t1.vehicle_id,
          t1.Coverage, 
            TO_DECIMAL(SUM(t1.AJAdjustmentPercent),11,6)  AS SUM_Adjustments
     FROM AGGNE.PRD.ADJUSTMENTS_PER_A_Policyattach t1
    GROUP BY t1.ExpiringID_P,
             t1.vehicle_id,
             t1.Coverage
    ORDER BY EXPIRINGID_P, VEHICLE_ID, COVERAGE;
             
--------------------------------Adjustments_PER----------------------------------------------------------------
CREATE OR REPLACE TABLE AGGNE.PRD.Adjustments_PER_Policyattach AS
    SELECT DISTINCT
        COALESCE(A.ExpiringID_P, B.ExpiringID_P) AS ExpiringID_P,
        COALESCE(A.Coverage, B.Coverage) AS Coverage,
        COALESCE(A.Vehicle_ID, B.Vehicle_ID) AS Vehicle_ID,
        COALESCE(a.AJAdjustmentPercent, b.SUM_Adjustments) AS AJAdjustmentPercent,
        a.AJAdjustmentValue, a.AJType, a.AJAdjustmentNote, b.sum_adjustments
    FROM AGGNE.PRD.Adjustments_PER_A_Policyattach A
    FULL OUTER JOIN AGGNE.PRD.Adjustments_PER_B_Policyattach B
        ON  A.ExpiringID_P = B.ExpiringID_P
        AND A.Coverage     = B.Coverage
        AND A.Vehicle_ID   = B.Vehicle_ID
    
    WHERE COALESCE(a.AJAdjustmentPercent, b.SUM_Adjustments) <> 0
    ORDER BY EXPIRINGID_P, VEHICLE_ID, COVERAGE;

--------------------------------Adjustments_PER_Out---------------------------------------------------------------------
CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Adjustments_PER_Out_Policyattach AS
    SELECT DISTINCT e.policynumber
    	,e.ExpiringID_P
    	,e.Coverage
    	,e.Vehicle_ID
    	,e.ExpPremium
    	,a.SUM_Adjustments
    	,a.AJAdjustmentPercent
    	,a.AJAdjustmentNote
    	,
    	/* UWAdjust calculation with divide-by-zero protection */
    	CASE 
    		WHEN (100 + a.SUM_Adjustments) <> 0
    			THEN TO_DECIMAL((e.ExpPremium / (100 + a.SUM_Adjustments)) * a.AJAdjustmentPercent, 11, 2)
    		ELSE NULL
    		END AS UWAdjust
    FROM AGGNE.PRD.ExpPremium_PER_Policyattach e
    LEFT JOIN AGGNE.PRD.Adjustments_PER_Policyattach a ON e.ExpiringID_P = a.ExpiringID_P
    	AND e.Coverage = a.Coverage
    	AND e.Vehicle_ID = a.Vehicle_ID;

----------------------------------------Output_UWAdjust_PER------------------------------------------------------------
  CREATE OR REPLACE TRANSIENT TABLE AGGNE.PRD.Output_UWAdjust_PER_Policyattach AS 
   SELECT DISTINCT
          t1.PolicyNumber,
          t1.ExpiringID_P  AS ExpiringID_P, 
          t1.Vehicle_ID  AS Vehicle_ID, 
          t1.Coverage, 
          t1.AJAdjustmentNote  AS UWAdjustNote, 
          t1.UWAdjust AS UWAdjustAmount
     FROM AGGNE.PRD.Adjustments_PER_Out_Policyattach t1;

END;
