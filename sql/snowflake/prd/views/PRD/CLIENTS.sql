create or replace view CLIENTS(
	ID,
	ORIONACCOUNTREF,
	CODE,
	NAME,
	TYPECODE,
	TYPEDESCRIPTION,
	BRANCHCODE,
	BRANCHNAME,
	SUBBRANCHCODE,
	SUBBRANCHNAME,
	LEADAGENTCODE,
	LEADAGENTNAME,
	ACCOUNTEXECCODE,
	ACCOUNTEXECNAME,
	CURRENCYCODE,
	CURRENCYDESCRIPTION,
	PAYMENTMETHOD,
	REMINDERTYPECODE,
	REMINDERTYPEDESCRIPTION,
	SERVICELEVELCODE,
	SERVICELEVELDESCRIPTION,
	TERMSOFPAYMENT,
	RENEWALSTOPREASONCODE,
	RENEWALSTOPREASONDESCRIPTION,
	SEASONALGIFTCODE,
	SEASONALGIFTDESCRIPTION,
	AREACODE,
	AREADESCRIPTION,
	FILECODE,
	CCJS,
	ADDRESS_CNT,
	CORRESPONDENCEADDRESS1,
	CORRESPONDENCEADDRESS2,
	CORRESPONDENCEADDRESS3,
	CORRESPONDENCEADDRESS4,
	CORRESPONDENCEPOSTCODE,
	PREFERREDCORRESPONDENCETYPECODE,
	PREFERREDCORRESPONDENCETYPEDESCRIPTION
) as 
SELECT distinct 
        party.party_cnt                 as id,
        party.party_cnt                 as orionaccountref, 
        trim(party.shortname)           as code,
        party.resolved_name             as name,
        party_type.code                 as typecode,
        party_type.description          as typedescription,
        source.code                     as branchcode,
        source.description              as branchname,
        sub_branch.code                 as subbranchcode,
        sub_branch.description          as subbranchname,
        leadagent.shortname             as leadagentcode,
        leadagent.resolved_name         as leadagentname,
        accountexec.shortname           as accountexeccode,
        accountexec.resolved_name       as accountexecname,
        currency.code                   as currencycode,
        currency.description            as currencydescription,
        party.payment_method_code       as paymentmethod,
        reminder_type.code              as remindertypecode,
        reminder_type.description       as remindertypedescription,
        service_level.code              as servicelevelcode,
        service_level.description       as serviceleveldescription,
        party.payment_term_code         as termsofpayment,
        renewal_stop_code.code          as renewalstopreasoncode,
        renewal_stop_code.description   as renewalstopreasondescription,
        seasonal_gift.code              as seasonalgiftcode,
        seasonal_gift.description       as seasonalgiftdescription,
        area.code                       as areacode,
        area.description                as areadescription,
        party.file_code                 as filecode,
        party.ccjs                      as ccjs,
        address.address_cnt,
        address.address1                as correspondenceaddress1,
        address.address2                as correspondenceaddress2,
        address.address3                as correspondenceaddress3,
        address.address4                as correspondenceaddress4,
        address.postal_code             as correspondencepostcode,
        contact_type.code               as preferredcorrespondencetypecode,
        contact_type.description        as preferredcorrespondencetypedescription
FROM    PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party as party
        JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party_address_usage as party_address_usage 
            ON party.party_cnt = party_address_usage.party_cnt
        JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.address as address 
            ON party_address_usage.address_cnt = address.address_cnt
        JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.address_usage_type as address_usage_type 
            ON party_address_usage.address_usage_type_id = address_usage_type.address_usage_type_id
        JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.currency as currency 
            ON party.currency_id = currency.currency_id
        JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party_type as party_type 
            ON party.party_type_id = party_type.party_type_id
        JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.source as source 
            ON party.source_id = source .source_id
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.area as area 
            ON party.area_id = area.area_id
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.contact_type as contact_type 
            ON party.correspondence_type_id = contact_type.contact_type_id
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party as accountexec 
            ON party.consultant_cnt = accountexec.party_cnt
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.party as leadagent 
            ON party.agent_cnt = leadagent.party_cnt
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.reminder_type as reminder_type 
            ON party.reminder_type_id = reminder_type.reminder_type_id
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.renewal_stop_code as renewal_stop_code 
            ON party.renewal_stop_code_id = renewal_stop_code.renewal_stop_code_id
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.seasonal_gift as seasonal_gift 
            ON party.seasonal_gift_id = seasonal_gift.seasonal_gift_id
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.service_level as service_level 
            ON party.service_level_id = service_level.service_level_id
        LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.sub_branch as sub_branch 
            ON party.sub_branch_id = sub_branch.sub_branch_id
WHERE   TRIM(UPPER(address_usage_type.code)) = '3131 XCO' 
    AND TRIM(UPPER(party_type.code)) IN ('PC', 'CC', 'GC') 
    AND TRIM(party.is_deleted) = 0
    QUALIFY ROW_NUMBER() OVER (PARTITION BY party.shortname ORDER BY address.address_cnt DESC) = 1
;