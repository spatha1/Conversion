create or replace view CLAIMS(
	ID,
	POLICYID,
	POLICYNUMBER,
	HANDLERCODE,
	HANDLERDESCRIPTION,
	PROGRESSSTATUSCODE,
	PROGRESSSTATUSDESCRIPTION,
	CLAIMSTATUS,
	CLAIMOPEN,
	CLAIMSTATUSDATE,
	CLAIMSTATUSTIME,
	DESCRIPTION,
	PRIMARYCAUSECODE,
	PRIMARYCAUSEDESCRIPTION,
	SECONDARYCAUSECODE,
	SECONDARYCAUSEDESCRIPTION,
	CATASTROPHECODE,
	CATASTROPHEDESCRIPTION,
	TOWNCODE,
	TOWNDESCRIPTION,
	LOSSDATE,
	LOSSTIME,
	LOSSTODATE,
	LOSSTOTIME,
	REPORTEDDATE,
	REPORTEDTIME,
	REPORTEDTODATE,
	LASTMODIFIEDDATE,
	LASTMODIFIEDTIME,
	CURRENCYCODE,
	CURRENCYDESCRIPTION,
	RISKTYPECODE,
	RISKTYPEDESCRIPTION,
	RISKGROUPID,
	INFORMATION,
	LIKELYTOCLAIM,
	CLIENTCLAIMNUMBER,
	CLIENTID,
	CLIENTNAME,
	CLIENTSHORTNAME,
	CLIENTADDRESS1,
	CLIENTADDRESS2,
	CLIENTADDRESS3,
	CLIENTADDRESS4,
	CLIENTPOSTCODE,
	CLIENTHOMETELEPHONE,
	CLIENTOFFICETELEPHONE,
	CLIENTFAX,
	CLIENTMOBILE,
	CLIENTEMAIL,
	INSURERCLAIMNUMBER,
	INSURERNAME,
	INSURERSHORTNAME,
	INSURERADDRESS1,
	INSURERADDRESS2,
	INSURERADDRESS3,
	INSURERADDRESS4,
	INSURERPOSTCODE,
	INSURERTELEPHONE,
	INSURERFAX,
	INSURERCONTACT,
	INSUREREMAIL,
	VATREGISTERED,
	VATREGISTRATIONNUMBER,
	USERDEFINEDFIELDA,
	USERDEFINEDFIELDB,
	USERDEFINEDFIELDC,
	USERDEFINEDFIELDD,
	USERDEFINEDFIELDE,
	LOCATION,
	PERILDESCRIPTION,
	INITIALRESERVE,
	REVISEDRESERVE,
	PAIDTODATE,
	RESERVETYPE,
	CURRENTRESERVE,
	DRIVERNAME,
	DRIVERSEX
) as
SELECT 
  t1.claim_id AS ID
	,t1.policy_id AS PolicyID
	,t1.Policy_Number AS PolicyNumber
	,t6.code AS HandlerCode
	,t6.description AS HandlerDescription
	,t8.code AS ProgressStatusCode
	,t8.description AS ProgressStatusDescription
	,(
		CASE t1.claim_status_id
			WHEN 1
				THEN 'Provisional Open Claim'
			WHEN 2
				THEN 'Live Open Claim'
			WHEN 3
				THEN 'Closed'
			WHEN 4
				THEN 'Re-Opened'
			WHEN 5
				THEN 'Re-Closed'
			ELSE NULL
			END
		) AS ClaimStatus
	,(
		CASE t1.claim_status_id
			WHEN 1
				THEN 'Open'
			WHEN 2
				THEN 'Open'
			WHEN 3
				THEN 'Closed'
			WHEN 4
				THEN 'Open'
			WHEN 5
				THEN 'Closed'
			ELSE NULL
			END
		) AS ClaimOpen
	,
	--PN 40525
	TO_CHAR(t1.Claims_Status_Date::DATE, 'YYYY-MM-DD') AS ClaimStatusDate
	,TO_CHAR(t1.Claims_Status_Date, 'HH24:MI:SS') AS ClaimStatusTime
	,t1.description AS Description
	,t7.code AS PrimaryCauseCode
	,t7.description AS PrimaryCauseDescription
	,t10.code AS SecondaryCauseCode
	,t10.description AS SecondaryCauseDescription
	,t2.code AS CatastropheCode
	,t2.description AS CatastropheDescription
	,t11.code AS TownCode
	,t11.description AS TownDescription
	,TO_CHAR(t1.loss_from_date::DATE, 'YYYY-MM-DD') AS LossDate
	,TO_CHAR(t1.loss_from_date, 'HH24:MI:SS') AS LossTime
	,TO_CHAR(t1.loss_to_date::DATE, 'YYYY-MM-DD') AS LossToDate
	,TO_CHAR(t1.loss_to_date, 'HH24:MI:SS') AS LossToTime
	,TO_CHAR(t1.reported_date::DATE, 'YYYY-MM-DD') AS ReportedDate
	,TO_CHAR(t1.reported_date, 'HH24:MI:SS') AS ReportedTime
	,t1.reported_to_date ReportedToDate
	,TO_CHAR(t1.last_modified_date::DATE, 'YYYY-MM-DD') AS LastModifiedDate
	,TO_CHAR(t1.last_modified_date, 'HH24:MI:SS') AS LastModifiedTime
	,t5.code AS CurrencyCode
	,t5.description AS CurrencyDescription
	,t9.code AS RiskTypeCode
	,t9.description AS RiskTypeDescription
	,t9.risk_group_id AS RiskGroupID
	,t1.info_only AS Information
	,t1.likely_claim AS LikelyToClaim
	,t1.claim_number AS ClientClaimNumber
	,t1.Client_id AS ClientID
	,t1.client_name AS ClientName
	,t1.Client_short_name AS ClientShortName
	,t3.address1 AS ClientAddress1
	,t3.address2 AS ClientAddress2
	,t3.address3 AS ClientAddress3
	,t3.address4 AS ClientAddress4
	,t3.postal_code AS ClientPostCode
	,t1.client_tel_no AS ClientHomeTelephone
	,t1.client_tel_no_off AS ClientOfficeTelephone
	,t1.client_fax_no AS ClientFax
	,t1.client_mobile_no AS ClientMobile
	,t1.client_email AS ClientEmail
	,t1.insurer_claim_number AS InsurerClaimNumber
	,t1.insurer_name AS InsurerName
	,t1.Insurer_short_name AS InsurerShortName
	,t4.address1 AS InsurerAddress1
	,t4.address2 AS InsurerAddress2
	,t4.address3 AS InsurerAddress3
	,t4.address4 AS InsurerAddress4
	,t4.postal_code AS InsurerPostCode
	,t1.insurer_tel_no AS InsurerTelephone
	,t1.insurer_fax_no AS InsurerFax
	,t1.insurer_contact AS InsurerContact
	,t1.insurer_email AS InsurerEmail
	,t1.VAT_registered AS VATRegistered
	,t1.VAT_reg_no AS VATRegistrationNumber
	,t1.user_defined_field_A AS UserDefinedFieldA
	,t1.user_defined_field_B AS UserDefinedFieldB
	,t1.user_defined_field_C AS UserDefinedFieldC
	,t1.user_defined_field_D AS UserDefinedFieldD
	,t1.user_defined_field_E AS UserDefinedFieldE
	,t1.Location AS Location
	,t12.description AS PerilDescription
	,t13.Initial_Reserve AS InitialReserve
	,t13.Revised_Reserve AS RevisedReserve
	,t13.Paid_to_Date AS PaidToDate
	,t14.Description AS ReserveType
	,(
		CASE 
			WHEN NVL(t13.revised_reserve_entered, 0) = 0
				THEN (
						CASE 
							WHEN NVL(t13.revised_reserve, CAST(0 AS DECIMAL(19,4))) = CAST(0 AS DECIMAL(19,4))
								THEN (NVL(t13.initial_reserve, CAST(0 AS DECIMAL(19,4))) - NVL(t13.paid_to_date, CAST(0 AS DECIMAL(19,4))))
							ELSE (NVL(t13.revised_reserve, CAST(0 AS DECIMAL(19,4))) - NVL(t13.paid_to_date, CAST(0 AS DECIMAL(19,4))))
							END
						)
			ELSE (NVL(t13.revised_reserve, CAST(0 AS DECIMAL(19,4))) - NVL(t13.paid_to_date, CAST(0 AS DECIMAL(19,4))))
			END
		) AS CurrentReserve
	,
	/* USE FOR BROKING DATA TRANSFERS

    (

        select max(Party_Claim.name)

        from Party_Claim

        inner join Claim_Party_Type on Party_Claim.claim_party_type_id = Claim_Party_Type.claim_party_type_id

        inner join Peril_Party on Party_Claim.party_claim_id = Peril_Party.party_claim_id

        where Claim_Party_Type.code = 'DRV'

        and Peril_Party.claim_id = Claim.claim_id

    ) as DriverName

    */
	/* USE BEFORE VERSION 1.6.11

    (

        select max(Party_Claim.name)

        from Party_Claim

        inner join Claim_Party_Type on Party_Claim.claim_party_type_id = Claim_Party_Type.claim_party_type_id

        inner join Claim_Party_Claim on Party_Claim.party_claim_id = Claim_Party_Claim.party_claim_id

        where Claim_Party_Type.code = 'OTDRIVER'

        and Claim_Party_Claim.claim_id = Claim.claim_id

    ) as DriverName

    */
	/* DO NOT USE UNTIL VERSION 1.6.11*/
	(
		SELECT TOP 1 Party.resolved_name
		FROM prd_t5_external_aggne.pure.Party
		INNER JOIN prd_t5_external_aggne.pure.Party_Type ON Party.party_type_id = Party_Type.party_type_id
		INNER JOIN prd_t5_external_aggne.pure.Claim_Party_Link ON Party.party_cnt = Claim_Party_Link.party_cnt
		WHERE Party_Type.code = 'OTDRIVER'
			AND Claim_Party_Link.claim_id = t1.claim_id
		) AS DriverName
	,(
		SELECT TOP 1 Party_Other.gender
		FROM prd_t5_external_aggne.pure.Party
		JOIN prd_t5_external_aggne.pure.Party_Type ON Party.party_type_id = Party_Type.party_type_id
		JOIN prd_t5_external_aggne.pure.Party_Other ON Party.party_cnt = Party_Other.party_cnt
		JOIN prd_t5_external_aggne.pure.Claim_Party_Link ON Party.party_cnt = Claim_Party_Link.party_cnt
		WHERE Party_Type.code = 'OTDRIVER'
			AND Claim_Party_Link.claim_id = t1.claim_id
		) AS DriverSex
FROM prd_t5_external_aggne.pure.Claim t1
-- To Parents
LEFT OUTER JOIN prd_t5_external_aggne.pure.Catastrophe_Code t2 ON t1.catastrophe_code_id = t2.catastrophe_code_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.Claim_Address t3 ON t1.client_address = t3.address_cnt
LEFT OUTER JOIN prd_t5_external_aggne.pure.Claim_Address t4 ON t1.insurer_address = t4.address_cnt
LEFT OUTER JOIN prd_t5_external_aggne.pure.Currency t5 ON t1.currency_id = t5.currency_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.Handler t6 ON t1.handler_id = t6.handler_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.primary_cause t7 ON t1.primary_cause_id = t7.primary_cause_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.progress_status t8 ON t1.progress_status_id = t8.progress_status_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.Risk_Code t9 ON t1.risk_type_id = t9.risk_code_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.secondary_cause t10 ON t1.secondary_cause_id = t10.secondary_cause_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.Town t11 ON t1.town = t11.town_id
-- To Children
LEFT OUTER JOIN prd_t5_external_aggne.pure.Claim_Peril t12 ON t12.claim_id = t1.claim_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.Reserve t13 ON t13.claim_peril_id = t12.claim_peril_id
LEFT OUTER JOIN prd_t5_external_aggne.pure.Reserve_Type t14 ON t13.reserve_type_id = t14.reserve_type_id;