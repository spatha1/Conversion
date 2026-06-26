CREATE OR REPLACE PROCEDURE "SP_LOAD_PURE_POLICY_BP"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS '
BEGIN
  -- 1) Ensure target table exists (simple, compatible schema)
  CREATE OR REPLACE TABLE  AGGNE.DEV.PURE_POLICY_SEARCH_BP_PER (
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
      CMLNumber               VARCHAR
  );

  -- 2) Fresh load (truncate + insert)
  TRUNCATE TABLE AGGNE.DEV.PURE_POLICY_SEARCH_BP_PER;

  -- 3) Insert Business + Personal (your union logic)
  INSERT INTO AGGNE.DEV.PURE_POLICY_SEARCH_BP_PER (
    PolicySearchType, ManuscriptID, PolicyMappedLOB, ClaimPolicyType, City,
    ExternalPolicySearchID, FirstName, LastName, LineOfBusiness, OrganizationName,
    PolicyEffectiveDate, PolicyExpirationDate, PUREPolicyNumber, PolicyTransactionType,
    PolicyStatus, RecordDeleteIndicator, State, DefaultCurrency, Country, Street,
    AdditionalAddress1, Zip, CMLNumber
  )

  ----BSP Policies----------
  SELECT
      TRIM(t19."code")                         AS PolicySearchType,
      ''PURE''                                  AS ManuscriptID,
      ''CarrierBusinessPackageAU''              AS PolicyMappedLOB,
      ''ANZBU''                                 AS ClaimPolicyType,
      TRIM(t20."RLSuburb")                      AS City,
      TRIM(t3."insurance_ref")                  AS ExternalPolicySearchID,
      TRIM(t29.maincontact)                     AS FirstName,
      TRIM(t20."ClientRLTradingName")           AS LastName,
      ''LB8''                                   AS LineOfBusiness,
      TRIM(t20."ClientRLTradingName")           AS OrganizationName,
      TO_CHAR(t3."cover_start_date"::DATE, ''YYYY-MM-DD'') AS PolicyEffectiveDate,
      TO_CHAR(t3."expiry_date"::DATE, ''YYYY-MM-DD'')      AS PolicyExpirationDate,
      TRIM(t3."insurance_ref")                  AS PUREPolicyNumber,
      t16."description"                         AS PolicyTransactionType,
      ''161''                                   AS PolicyStatus,
      ''false''                                 AS RecordDeleteIndicator,
      TRIM(t20."RLState")                       AS State,
      CASE WHEN TRIM(t13."description") = ''Australia'' THEN ''AUD'' ELSE ''NZ'' END AS DefaultCurrency,
      TRIM(t13."description")                   AS Country,
      UPPER(TRIM(t20."RLStreet"))               AS Street,
      TRIM(t30.correspondenceaddress3)          AS AdditionalAddress1,
      TRIM(t20."RLPostCode")                    AS Zip,
      TRIM(t14."shortname")                     AS CMLNumber
  FROM DEV_T5_EXTERNAL_AGGNE.PURE.Risk                          t1
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Risk_Folder              t0  ON t1."risk_folder_cnt"               = t0."risk_folder_cnt"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.insurance_file_risk_link t2  ON t1."risk_cnt"                      = t2."risk_cnt"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Insurance_File           t3  ON t2."insurance_file_cnt"            = t3."insurance_file_cnt"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.GIS_Policy_Link          t6  ON t3."insured_cnt"                    = t6."party_cnt"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.CAPPARTY_Policy_Binder   t7  ON t6."gis_policy_link_id"             = t7."gis_policy_link_id"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.CAPPARTY_MEMBERCSL       t9  ON t7."CAPPARTY_Policy_Binder_id"      = t9."CAPPARTY_Policy_Binder_id"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Party                    t14 ON t3."insured_cnt"                    = t14."party_cnt"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.ClientContacts           t10 ON t6."party_cnt"                      = t10.clientid
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Source                   t13 ON t3."source_id"                      = t13."source_id"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Risk_Status              t15 ON t1."risk_status_id"                 = t15."risk_status_id"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.insurance_file_status    t16 ON t3."insurance_file_status_id"       = t16."insurance_file_status_id"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.GIS_Policy_Link          t17 ON t1."risk_cnt"                       = t17."risk_id"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.CBP_Policy_Binder        t18 ON t17."gis_policy_link_id"            = t18."gis_policy_link_id"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Product                  t19 ON t3."product_id"                     = t19."product_id"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.CBP_RiskSelection        t20 ON t18."CBP_Policy_Binder_id"          = t20."CBP_Policy_Binder_id"
  LEFT  JOIN AGGNE.DEV.DIM_PARTY_CML_CSL                         t29 ON TRIM(t14."shortname")               = TRIM(t29.CMLNUMBER)
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Clients                  t30 ON t30."ID"                            = t10.ClientID
  WHERE
       SUBSTR(t3."insurance_ref", 1, 1) = ''P''
   AND t3."insurance_file_type_id" <> 3
   AND t16."insurance_file_status_id" NOT IN (1, 2)
   AND t15."risk_status_id" IN (1, 3)
   AND t3."insurance_ref" NOT IN (
        SELECT DISTINCT t13."insurance_ref"
        FROM DEV_T5_EXTERNAL_AGGNE.PURE.Risk t11
        INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.insurance_file_risk_link t12 ON t11."risk_cnt" = t12."risk_cnt"
        INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Insurance_File t13 ON t12."insurance_file_cnt" = t13."insurance_file_cnt"
        WHERE t13."expiry_date"::DATE > CURRENT_DATE()
          AND t13."insurance_file_type_id" = 8
   )
   AND (
      (SELECT COUNT(DISTINCT ins."insurance_file_cnt")
         FROM DEV_T5_EXTERNAL_AGGNE.PURE.Insurance_File ins
        WHERE ins."insurance_ref" = t3."insurance_ref") = 1
      OR
      t3."insurance_file_cnt" = (
          SELECT MAX(ins."insurance_file_cnt")
            FROM DEV_T5_EXTERNAL_AGGNE.PURE.Insurance_File ins
            LEFT JOIN DEV_T5_EXTERNAL_AGGNE.PURE.insurance_file_status status
              ON ins."insurance_file_status_id" = status."insurance_file_status_id"
           WHERE ins."insurance_ref" = t3."insurance_ref"
             AND status."insurance_file_status_id" <> 1
      )
   )
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ExternalPolicySearchID
    ORDER BY PolicyEffectiveDate DESC NULLS LAST, t3."insurance_file_cnt" DESC
  ) = 1

  UNION ALL

  ----PER Policies----------
  SELECT
      TRIM(t19."code")                         AS PolicySearchType,
      ''PURE''                                  AS ManuscriptID,
      ''CarrierBusinessPackageAU''              AS PolicyMappedLOB,
      ''ANZPE''                                 AS ClaimPolicyType,
      TRIM(t20."RLSuburb")                      AS City,
      TRIM(t3."insurance_ref")                  AS ExternalPolicySearchID,
      TRIM(t29.maincontact)                     AS FirstName,
      TRIM(t29.maincontact)                     AS LastName,
      ''LB8''                                   AS LineOfBusiness,
      NULL                                      AS OrganizationName,
      TO_CHAR(t3."cover_start_date"::DATE, ''YYYY-MM-DD'') AS PolicyEffectiveDate,
      TO_CHAR(t3."expiry_date"::DATE, ''YYYY-MM-DD'')      AS PolicyExpirationDate,
      TRIM(t3."insurance_ref")                  AS PUREPolicyNumber,
      t16."description"                         AS PolicyTransactionType,
      ''161''                                   AS PolicyStatus,
      ''false''                                 AS RecordDeleteIndicator,
      TRIM(t20."RLState")                       AS State,
      CASE WHEN TRIM(t13."description") = ''Australia'' THEN ''AUD'' ELSE ''NZ'' END AS DefaultCurrency,
      TRIM(t13."description")                   AS Country,
      UPPER(TRIM(t20."RLStreet"))               AS Street,
      TRIM(t30.correspondenceaddress3)          AS AdditionalAddress1,
      TRIM(t20."RLPostCode")                    AS Zip,
      TRIM(t14."shortname")                     AS CMLNumber
  FROM DEV_T5_EXTERNAL_AGGNE.PURE.Risk                          t1
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Risk_Folder              t0  ON t1."risk_folder_cnt"               = t0."risk_folder_cnt"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.insurance_file_risk_link t2  ON t1."risk_cnt"                      = t2."risk_cnt"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Insurance_File           t3  ON t2."insurance_file_cnt"            = t3."insurance_file_cnt"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.GIS_Policy_Link          t6  ON t3."insured_cnt"                    = t6."party_cnt"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.CAPPARTY_Policy_Binder   t7  ON t6."gis_policy_link_id"             = t7."gis_policy_link_id"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.CAPPARTY_MEMBERCSL       t9  ON t7."CAPPARTY_Policy_Binder_id"      = t9."CAPPARTY_Policy_Binder_id"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Party                    t14 ON t3."insured_cnt"                    = t14."party_cnt"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.ClientContacts           t10 ON t6."party_cnt"                      = t10.clientid
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Source                   t13 ON t3."source_id"                      = t13."source_id"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Risk_Status              t15 ON t1."risk_status_id"                 = t15."risk_status_id"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.insurance_file_status    t16 ON t3."insurance_file_status_id"       = t16."insurance_file_status_id"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.GIS_Policy_Link          t17 ON t1."risk_cnt"                       = t17."risk_id"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.PER_POLICY_BINDER        t18 ON t17."gis_policy_link_id"            = t18."gis_policy_link_id"
  INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Product                  t19 ON t3."product_id"                     = t19."product_id"
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.PER_RISKSELECTION        t20 ON t18."PER_Policy_Binder_id"          = t20."PER_Policy_Binder_id"
  LEFT  JOIN AGGNE.DEV.DIM_PARTY_CML_CSL                         t29 ON TRIM(t14."shortname")               = TRIM(t29.CMLNUMBER)
  LEFT  JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Clients                  t30 ON t30."ID"                            = t10.ClientID
  WHERE
       SUBSTR(t3."insurance_ref", 1, 1) = ''P''
   AND t3."insurance_file_type_id" <> 3
   AND t16."insurance_file_status_id" NOT IN (1, 2)
   AND t15."risk_status_id" IN (1, 3)
   AND t3."insurance_ref" NOT IN (
        SELECT DISTINCT t13."insurance_ref"
        FROM DEV_T5_EXTERNAL_AGGNE.PURE.Risk t11
        INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.insurance_file_risk_link t12 ON t11."risk_cnt" = t12."risk_cnt"
        INNER JOIN DEV_T5_EXTERNAL_AGGNE.PURE.Insurance_File t13 ON t12."insurance_file_cnt" = t13."insurance_file_cnt"
        WHERE t13."expiry_date"::DATE > CURRENT_DATE()
          AND t13."insurance_file_type_id" = 8
   )
   AND (
      (SELECT COUNT(DISTINCT ins."insurance_file_cnt")
         FROM DEV_T5_EXTERNAL_AGGNE.PURE.Insurance_File ins
        WHERE ins."insurance_ref" = t3."insurance_ref") = 1
      OR
      t3."insurance_file_cnt" = (
          SELECT MAX(ins."insurance_file_cnt")
            FROM DEV_T5_EXTERNAL_AGGNE.PURE.Insurance_File ins
            LEFT JOIN DEV_T5_EXTERNAL_AGGNE.PURE.insurance_file_status status
              ON ins."insurance_file_status_id" = status."insurance_file_status_id"
           WHERE ins."insurance_ref" = t3."insurance_ref"
             AND status."insurance_file_status_id" <> 1
      )
   )
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ExternalPolicySearchID
    ORDER BY PolicyEffectiveDate DESC NULLS LAST, t3."insurance_file_cnt" DESC
  ) = 1
  ;

  RETURN ''Loaded AGGNE.DEV.PURE_POLICY_SEARCH_BP_PER successfully'';
END;
';