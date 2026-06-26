-- SP: AGGNE.PRD.SP_LOAD_PURE_POLICY_SEARCH_BP_PP
-- Signature: ()
-- Language:  SQL
-- Collected: 2026-06-25


BEGIN
  -- 1) Ensure target table exists (simple, compatible schema)
  CREATE OR REPLACE TABLE  AGGNE.PRD.PURE_POLICY_SEARCH_BP_PER (
      PolicySearchType        VARCHAR,
      ManuscriptID            VARCHAR,
      PolicyMappedLOB         VARCHAR,
      ClaimPolicyType         VARCHAR,
      City                    VARCHAR,
      ExternalPolicySearchID  VARCHAR,
      FirstName               VARCHAR,
      LastName                VARCHAR,
      LineOfBusiness          VARCHAR,
      OrganizationName        VARCHAR,
      PolicyEffectiveDate     VARCHAR,
      PolicyExpirationDate    VARCHAR,
      PUREPolicyNumber        VARCHAR,
      PolicyTransactionType   VARCHAR,
      PolicyStatus            VARCHAR,
      RecordDeleteIndicator   VARCHAR,
      State                   VARCHAR,
      DefaultCurrency         VARCHAR,
      Country                 VARCHAR,
      Street                  VARCHAR,
      AdditionalAddress1      VARCHAR,
      Zip                     VARCHAR,
      CMLNumber               VARCHAR,
      INSURANCE_FILE_CNT NUMBER(38,0)
  );

  -- 2) Fresh load (truncate + insert)
  TRUNCATE TABLE AGGNE.PRD.PURE_POLICY_SEARCH_BP_PER;

  -- 3) Insert Business + Personal (your union logic)
  INSERT INTO AGGNE.PRD.PURE_POLICY_SEARCH_BP_PER (
    PolicySearchType, ManuscriptID, PolicyMappedLOB, ClaimPolicyType, City,
    ExternalPolicySearchID, FirstName, LastName, LineOfBusiness, OrganizationName,
    PolicyEffectiveDate, PolicyExpirationDate, PUREPolicyNumber, PolicyTransactionType,
    PolicyStatus, RecordDeleteIndicator, State, DefaultCurrency, Country, Street,
    AdditionalAddress1, Zip, CMLNumber,INSURANCE_FILE_CNT
  )

  
WITH
/* ===================== CBP ===================== */
Pol_Search_CBP_01 AS (
    SELECT DISTINCT
        TRIM(t19.code) AS POLICYSEARCHTYPE,
        'PURE' AS MANUSCRIPTID,
        'CarrierBusinessPackageAU' AS POLICYMAPPEDLOB,
        t18.CBP_Policy_Binder_id AS Policy_Binder_id,
        'ANZBU' AS CLAIMPOLICYTYPE,
        TRIM(t21.correspondenceaddress3) AS CITY,
        TRIM(t3.insurance_ref) AS EXTERNALPOLICYSEARCHID,
        t1.risk_folder_cnt,
        TRIM(t22.TRADINGNAME) AS FIRSTNAME,
        TRIM(t22.TRADINGNAME) AS LASTNAME,
        'LB8' AS LINEOFBUSINESS,
        TRIM(t22.TRADINGNAME) AS ORGANIZATIONNAME,
        TO_CHAR(CAST(t3.cover_start_date AS DATE), 'YYYY-MM-DD') AS POLICYEFFECTIVEDATE,
        TO_CHAR(CAST(t3.expiry_date AS DATE), 'YYYY-MM-DD') AS POLICYEXPIRATIONDATE,
        t16.description AS POLICYTRANSACTIONTYPE,
        t2.status_flag,
        '161' AS POLICYSTATUS,
        'false' AS RECORDDELETEINDICATOR,
        TRIM(t21.correspondenceaddress4) AS STATE,
        CASE WHEN TRIM(t13.description) = 'Australia' THEN 'AUD' ELSE 'NZ' END AS DEFAULTCURRENCY,
        TRIM(t13.description) AS COUNTRY,
        TRIM(t20.description) AS pol_type,
        UPPER(TRIM(t21.correspondenceaddress1)) AS STREET,
        TRIM(t21.correspondenceaddress3) AS ADDITIONALADDRESS1,
        t21.correspondenceaddress3 AS Suburb,
        t21.correspondenceaddress3 AS AdditionalAddress,
        t21.correspondencepostcode AS PostCode,
        t22.TradingName,
        TRIM(t21.correspondencepostcode) AS ZIP,
        TRIM(t14.shortname) AS CMLNUMBER,
        t3.insurance_file_cnt AS INSURANCE_FILE_CNT
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk                         t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Folder             t0  ON t1.risk_folder_cnt = t0.risk_folder_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File          t3  ON t2.insurance_file_cnt = t3.insurance_file_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link         t6  ON t3.insured_cnt = t6.party_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_Policy_Binder  t7  ON t6.gis_policy_link_id = t7.gis_policy_link_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_MEMBERCSL      t9  ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Party                   t14 ON t3.insured_cnt = t14.party_cnt
    LEFT  JOIN AGGNE.PRD.CLIENTCONTACTS                                    t10 ON t6.party_cnt = t10.ClientID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Source                  t13 ON t3.source_id = t13.source_id
    LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Status             t15 ON t1.risk_status_id = t15.risk_status_id
    LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status   t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
    LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link         t17 ON t1.risk_cnt = t17.risk_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_Policy_Binder       t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Product                 t19 ON t3.product_id = t19.product_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File_Type     t20 ON t3.insurance_file_type_id = t20.insurance_file_type_id
    LEFT  JOIN AGGNE.PRD.CLIENTS                                           t21 ON t21.ID = t10.ClientID
    LEFT  JOIN AGGNE.PRD.CLIENTSCORPORATE                                  t22 ON t6.party_cnt = t22.ClientID
    WHERE SUBSTRING(t3.insurance_ref, 1, 1) = 'P'
      AND t20.description IN ('Live Policy', 'MTA Cancelled', 'MTA Permanent')
),
ordered_cbp AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY s.EXTERNALPOLICYSEARCHID, s.risk_folder_cnt
            ORDER BY s.INSURANCE_FILE_CNT DESC
        ) AS rn_in_risk,
        LAG(s.POLICYEFFECTIVEDATE) OVER (
            PARTITION BY s.EXTERNALPOLICYSEARCHID, s.risk_folder_cnt
            ORDER BY s.INSURANCE_FILE_CNT DESC
        ) AS LagCoverStartDate
    FROM Pol_Search_CBP_01 s
),
Pol_Search_CBP_02 AS (
    SELECT
        o.*,
        o.LagCoverStartDate AS CoverEndDate,
        CASE WHEN o.status_flag = 'D' THEN 'MTA Cancelled' ELSE o.pol_type END AS Pol_type_adj
    FROM ordered_cbp o
    WHERE NOT (o.rn_in_risk > 1 AND o.LagCoverStartDate = o.POLICYEFFECTIVEDATE)
),
lagged_cbp AS (
    SELECT
        p.*,
        LAG(p.Pol_type_adj) OVER (
            PARTITION BY p.EXTERNALPOLICYSEARCHID
            ORDER BY p.risk_folder_cnt DESC, p.INSURANCE_FILE_CNT DESC
        ) AS LagPolType
    FROM Pol_Search_CBP_02 p
),
Pol_Search_CBP_03 AS (
    SELECT
        l.EXTERNALPOLICYSEARCHID,
        l.EXTERNALPOLICYSEARCHID AS PUREPOLICYNUMBER,
        MANUSCRIPTID,
        POLICYMAPPEDLOB,
        CLAIMPOLICYTYPE,
        POLICYTRANSACTIONTYPE,
        POLICYSTATUS,
        RECORDDELETEINDICATOR,
        ADDITIONALADDRESS1,
        ZIP,
        CMLNUMBER,
        CITY,
        FIRSTNAME,
        LASTNAME,
        LINEOFBUSINESS,
        ORGANIZATIONNAME,
        l.risk_folder_cnt,
        l.INSURANCE_FILE_CNT,
        l.Policy_Binder_id,
        l.POLICYSEARCHTYPE,
        l.STREET,
        l.Suburb,
        l.AdditionalAddress,
        l.PostCode,
        l.STATE,
        l.COUNTRY,
        l.TradingName,
        l.DEFAULTCURRENCY,
        l.POLICYEFFECTIVEDATE,
        l.POLICYEXPIRATIONDATE,
        l.Pol_type_adj AS Pol_type,
        CASE
            WHEN ROW_NUMBER() OVER (
                    PARTITION BY l.EXTERNALPOLICYSEARCHID, l.risk_folder_cnt
                    ORDER BY l.INSURANCE_FILE_CNT DESC
                 ) = 1
                 AND COALESCE(l.LagPolType, '') <> 'MTA Cancelled'
            THEN l.POLICYEXPIRATIONDATE
            WHEN l.LagPolType = 'MTA Cancelled'
            THEN DATEADD(day, 1, DATEADD(day, -1, l.CoverEndDate))
            ELSE DATEADD(day, -1, l.CoverEndDate)
        END AS CoverEndDate
    FROM lagged_cbp l
),

/* ===================== PER ===================== */
Pol_Search_PER_01 AS (
    SELECT DISTINCT
        TRIM(t19.code) AS POLICYSEARCHTYPE,
        'PURE' AS MANUSCRIPTID,
        'CarrierBusinessPackageAU' AS POLICYMAPPEDLOB,
        t18.PER_Policy_Binder_id AS Policy_Binder_id,
        'ANZBU' AS CLAIMPOLICYTYPE,
        TRIM(t21.correspondenceaddress3) AS CITY,
        TRIM(t3.insurance_ref) AS EXTERNALPOLICYSEARCHID,
        t1.risk_folder_cnt,
        TRIM(t22.TRADINGNAME) AS FIRSTNAME,
        TRIM(t22.TRADINGNAME) AS LASTNAME,
        'LB8' AS LINEOFBUSINESS,
        TRIM(t22.TRADINGNAME) AS ORGANIZATIONNAME,
        TO_CHAR(CAST(t3.cover_start_date AS DATE), 'YYYY-MM-DD') AS POLICYEFFECTIVEDATE,
        TO_CHAR(CAST(t3.expiry_date AS DATE), 'YYYY-MM-DD') AS POLICYEXPIRATIONDATE,
        t16.description AS POLICYTRANSACTIONTYPE,
        t2.status_flag,
        '161' AS POLICYSTATUS,
        'false' AS RECORDDELETEINDICATOR,
        TRIM(t21.correspondenceaddress4) AS STATE,
        CASE WHEN TRIM(t13.description) = 'Australia' THEN 'AUD' ELSE 'NZ' END AS DEFAULTCURRENCY,
        TRIM(t13.description) AS COUNTRY,
        TRIM(t20.description) AS pol_type,
        UPPER(TRIM(t21.correspondenceaddress1)) AS STREET,
        TRIM(t21.correspondenceaddress3) AS ADDITIONALADDRESS1,
        t21.correspondenceaddress3 AS Suburb,
        t21.correspondenceaddress3 AS AdditionalAddress,
        t21.correspondencepostcode AS PostCode,
        t22.TradingName,
        TRIM(t21.correspondencepostcode) AS ZIP,
        TRIM(t14.shortname) AS CMLNUMBER,
        t3.insurance_file_cnt AS INSURANCE_FILE_CNT
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk                         t1
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Folder             t0  ON t1.risk_folder_cnt = t0.risk_folder_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2 ON t1.risk_cnt = t2.risk_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File          t3  ON t2.insurance_file_cnt = t3.insurance_file_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link         t6  ON t3.insured_cnt = t6.party_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_Policy_Binder  t7  ON t6.gis_policy_link_id = t7.gis_policy_link_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CAPPARTY_MEMBERCSL      t9  ON t7.CAPPARTY_Policy_Binder_id = t9.CAPPARTY_Policy_Binder_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Party                   t14 ON t3.insured_cnt = t14.party_cnt
    LEFT  JOIN AGGNE.PRD.CLIENTCONTACTS                                    t10 ON t6.party_cnt = t10.ClientID
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Source                  t13 ON t3.source_id = t13.source_id
    LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Risk_Status             t15 ON t1.risk_status_id = t15.risk_status_id
    LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_status   t16 ON t3.insurance_file_status_id = t16.insurance_file_status_id
    LEFT  JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link         t17 ON t1.risk_cnt = t17.risk_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder       t18 ON t17.gis_policy_link_id = t18.gis_policy_link_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Product                 t19 ON t3.product_id = t19.product_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.Insurance_File_Type     t20 ON t3.insurance_file_type_id = t20.insurance_file_type_id
    LEFT  JOIN AGGNE.PRD.CLIENTS                                           t21 ON t21.ID = t10.ClientID
    LEFT  JOIN AGGNE.PRD.CLIENTSCORPORATE                                  t22 ON t6.party_cnt = t22.ClientID
    WHERE SUBSTRING(t3.insurance_ref, 1, 1) = 'P'
      AND t20.description IN ('Live Policy', 'MTA Cancelled', 'MTA Permanent')
),
ordered_per AS (
    SELECT
        s.*,
        ROW_NUMBER() OVER (
            PARTITION BY s.EXTERNALPOLICYSEARCHID, s.risk_folder_cnt
            ORDER BY s.INSURANCE_FILE_CNT DESC
        ) AS rn_in_risk,
        LAG(s.POLICYEFFECTIVEDATE) OVER (
            PARTITION BY s.EXTERNALPOLICYSEARCHID, s.risk_folder_cnt
            ORDER BY s.INSURANCE_FILE_CNT DESC
        ) AS LagCoverStartDate
    FROM Pol_Search_PER_01 s
),
Pol_Search_PER_02 AS (
    SELECT
        o.*,
        o.LagCoverStartDate AS CoverEndDate,
        CASE WHEN o.status_flag = 'D' THEN 'MTA Cancelled' ELSE o.pol_type END AS Pol_type_adj
    FROM ordered_per o
    WHERE NOT (o.rn_in_risk > 1 AND o.LagCoverStartDate = o.POLICYEFFECTIVEDATE)
),
lagged_per AS (
    SELECT
        p.*,
        LAG(p.Pol_type_adj) OVER (
            PARTITION BY p.EXTERNALPOLICYSEARCHID
            ORDER BY p.risk_folder_cnt DESC, p.INSURANCE_FILE_CNT DESC
        ) AS LagPolType
    FROM Pol_Search_PER_02 p
),
Pol_Search_PER_03 AS (
    SELECT
        l.EXTERNALPOLICYSEARCHID,
        l.EXTERNALPOLICYSEARCHID AS PUREPOLICYNUMBER,
        MANUSCRIPTID,
        POLICYMAPPEDLOB,
        CLAIMPOLICYTYPE,
        POLICYTRANSACTIONTYPE,
        POLICYSTATUS,
        RECORDDELETEINDICATOR,
        ADDITIONALADDRESS1,
        ZIP,
        CMLNUMBER,
        CITY,
        FIRSTNAME,
        LASTNAME,
        LINEOFBUSINESS,
        ORGANIZATIONNAME,
        l.risk_folder_cnt,
        l.INSURANCE_FILE_CNT,
        l.Policy_Binder_id,
        l.POLICYSEARCHTYPE,
        l.STREET,
        l.Suburb,
        l.AdditionalAddress,
        l.PostCode,
        l.STATE,
        l.COUNTRY,
        l.TradingName,
        l.DEFAULTCURRENCY,
        l.POLICYEFFECTIVEDATE,
        l.POLICYEXPIRATIONDATE,
        l.Pol_type_adj AS Pol_type,
        CASE
            WHEN ROW_NUMBER() OVER (
                    PARTITION BY l.EXTERNALPOLICYSEARCHID, l.risk_folder_cnt
                    ORDER BY l.INSURANCE_FILE_CNT DESC
                 ) = 1
                 AND COALESCE(l.LagPolType, '') <> 'MTA Cancelled'
            THEN l.POLICYEXPIRATIONDATE
            WHEN l.LagPolType = 'MTA Cancelled'
            THEN DATEADD(day, 1, DATEADD(day, -1, l.CoverEndDate))
            ELSE DATEADD(day, -1, l.CoverEndDate)
        END AS CoverEndDate
    FROM lagged_per l
)

/* ===================== UNION ALL ===================== */
SELECT
    POLICYSEARCHTYPE,
    MANUSCRIPTID,
    POLICYMAPPEDLOB,
    CLAIMPOLICYTYPE,
    CITY,
    EXTERNALPOLICYSEARCHID,
    FIRSTNAME,
    LASTNAME,
    LINEOFBUSINESS,
    ORGANIZATIONNAME,
    POLICYEFFECTIVEDATE,
    POLICYEXPIRATIONDATE,
    PUREPOLICYNUMBER,
    POLICYTRANSACTIONTYPE,
    POLICYSTATUS,
    RECORDDELETEINDICATOR,
    STATE,
    DEFAULTCURRENCY,
    COUNTRY,
    STREET,
    ADDITIONALADDRESS1,
    ZIP,
    CMLNUMBER,
    INSURANCE_FILE_CNT
FROM Pol_Search_CBP_03 t
WHERE t.Pol_type IN ('Live Policy', 'MTA Permanent')

UNION ALL

SELECT
    POLICYSEARCHTYPE,
    MANUSCRIPTID,
    POLICYMAPPEDLOB,
    CLAIMPOLICYTYPE,
    CITY,
    EXTERNALPOLICYSEARCHID,
    FIRSTNAME,
    LASTNAME,
    LINEOFBUSINESS,
    ORGANIZATIONNAME,
    POLICYEFFECTIVEDATE,
    POLICYEXPIRATIONDATE,
    PUREPOLICYNUMBER,
    POLICYTRANSACTIONTYPE,
    POLICYSTATUS,
    RECORDDELETEINDICATOR,
    STATE,
    DEFAULTCURRENCY,
    COUNTRY,
    STREET,
    ADDITIONALADDRESS1,
    ZIP,
    CMLNUMBER,
    INSURANCE_FILE_CNT
FROM Pol_Search_PER_03 t
WHERE t.Pol_type IN ('Live Policy', 'MTA Permanent')
;

  RETURN 'Loaded AGGNE.PRD.PURE_POLICY_SEARCH_BP_PER successfully';
END;
