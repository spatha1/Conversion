create or replace secure view CLIENTSCORPORATE(
	CLIENTID,
	TRADINGNAME,
	BUSINESS,
	TRADE,
	SICCODE,
	SICDESCRIPTION,
	COMPANYREG,
	NUMBEROFOFFICES,
	NUMBEROFEMPLOYEES,
	TRADINGSINCE,
	WAGEROLL,
	VATCODE,
	TURNOVER,
	FINANCIALYEAR,
	MAINCONTACT
) as 
SELECT
    t1.*,
    MC.description AS MainContact
FROM (
    SELECT
        Party.party_cnt                             AS ClientID,
        Party.name                                  AS TradingName,
        Party_Corporate_Client.party_business_id    AS Business,
        Party_Corporate_Client.trade_code           AS Trade,
        SIC_Code.code                               AS SICCode,
        SIC_Code.description                        AS SICDescription,
        Party_Corporate_Client.company_reg          AS CompanyReg,
        Party_Corporate_Client.no_of_offices        AS NumberOfOffices,
        Party_Corporate_Client.no_of_employees      AS NumberOfEmployees,
        Party_Corporate_Client.trading_since_date   AS TradingSince,
        Party_Corporate_Client.wage_roll            AS WageRoll,
        Party.tax_number                            AS VATCode,
        Party_Corporate_Client.turnover             AS Turnover,
        Party_Corporate_Client.financial_year       AS FinancialYear
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PARTY Party
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PARTY_TYPE Party_Type
        ON Party.party_type_id = Party_Type.party_type_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PARTY_CORPORATE_CLIENT Party_Corporate_Client
        ON Party.party_cnt = Party_Corporate_Client.party_cnt
    LEFT OUTER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.SIC_CODE SIC_Code
        ON Party_Corporate_Client.SIC_code_id = SIC_Code.SIC_code_id
    WHERE TRIM(UPPER(Party_Type.code)) = 'CC'
) t1
LEFT JOIN (
    SELECT
        Contact.description,
        Party_Contact_Usage.party_cnt
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CONTACT Contact
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CONTACT_TYPE Contact_Type
        ON Contact.contact_type_id = Contact_Type.contact_type_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PARTY_CONTACT_USAGE Party_Contact_Usage
        ON Contact.contact_cnt = Party_Contact_Usage.contact_cnt
    WHERE TRIM(UPPER(Contact_Type.code)) = 'MAIN'
) MC
    ON t1.ClientID = MC.party_cnt;