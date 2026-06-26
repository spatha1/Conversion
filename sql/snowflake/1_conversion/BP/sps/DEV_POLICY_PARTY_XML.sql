CREATE OR REPLACE PROCEDURE "POLICY_PARTY_XML"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
 
 BEGIN

  TRUNCATE TABLE POLICY_XML_SCRIPT;

    -- Assign the XML template
    LET v_template TEXT :=  ''<ArrayOfExternalPolicySearchDTO xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                xsi:noNamespaceSchemaLocation="">
  <ExternalPolicySearchDTO>
    <PolicySearchType>{POLICYMAPPEDLOB}</PolicySearchType>
    <ManuscriptID>{MANUSCRIPTID}</ManuscriptID>
    <PolicyMappedLOB>{POLICYMAPPEDLOB}</PolicyMappedLOB>
    <ClaimPolicyType>{POLICYMAPPEDLOB}</ClaimPolicyType>
    <City>{CITY}</City>
    <ExternalPolicySearchID>{EXTERNALPOLICYSEARCHID}</ExternalPolicySearchID>
    <FirstName>{FIRSTNAME}</FirstName>
    <LastName>{LASTNAME}</LastName>
    <LineOfBusiness>{LINEOFBUSINESS}</LineOfBusiness>
    <OrganizationName>{ORGANIZATIONNAME}</OrganizationName>
    <PolicyEffectiveDate>{POLICYEFFECTIVEDATE}</PolicyEffectiveDate>
    <PolicyExpirationDate>{POLICYEXPIRATIONDATE}</PolicyExpirationDate>
    <PolicyNumber>{EXTERNALPOLICYSEARCHID}</PolicyNumber>
    <PolicyTransactionType>{POLICYTRANSACTIONTYPE}</PolicyTransactionType>
    <PolicyStatus>{POLICYSTATUS}</PolicyStatus>
    <RecordDeleteIndicator>{RECORDDELETEINDICATOR}</RecordDeleteIndicator>
    <State>{STATE}</State>
    <DefaultCurrency>{DEFAULTCURRENCY}</DefaultCurrency>
    <Country>{COUNTRY}</Country>
    <Street>{STREET}</Street>
    <AdditionalAddress1>{ADDITIONALADDRESS1}</AdditionalAddress1>
    <Zip>{ZIP}</Zip>
  </ExternalPolicySearchDTO>
</ArrayOfExternalPolicySearchDTO>'';

    -- Assign the dynamic SQL using SELECT INTO
   LET v_sql TEXT := ( SELECT 
        ''INSERT INTO POLICY_XML_SCRIPT SELECT DISTINCT  EXTERNALPOLICYSEARCHID, '' ||
        LISTAGG(''REPLACE('', '''') || 
        '''''''' || :v_template || '''''''' ||
        LISTAGG('', ''''{'' || (column_name) || ''}'''', IFNULL ('' || column_name || '',''''''''))'', '''') ||
        '' ,POLICYEFFECTIVEDATE,POLICYEXPIRATIONDATE FROM AGGNE.DEV.PURE_POLICY_SEARCH_BP_PER ''
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_name = ''PURE_POLICY_SEARCH_BP_PER''
      AND table_schema = ''DEV''
      AND table_catalog = ''AGGNE''
    ORDER BY ordinal_position
    );

    --return v_sql ;
    -- Execute the dynamic SQL
    EXECUTE IMMEDIATE v_sql;

    --RETURN ''XML script generation and insertion completed.'';
END;
';