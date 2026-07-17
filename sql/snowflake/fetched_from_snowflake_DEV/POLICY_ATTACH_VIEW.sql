create or replace view POLICY_ATTACH_VIEW(
	POLICY_KEY,
	POLICY_NUMBER,
	POLICY_ATTACH_XML,
	POLICYEFFECTIVEDATE,
	POLICYEXPIRATIONDATE,
	LOAD_TS
) as
select null as policy_key,TRIM(SPLIT_PART(legacypolicynumber, '|', 1), '"') AS policy_number,response_xml as policy_attach_xml,effectivedate as policyeffectivedate,expirationdate as policyexpirationdate, load_ts from (select legacypolicynumber,request_xml,response_xml,effectivedate,expirationdate,created_at as load_ts from Aggne.dev.policyattach_migration_dct where to_date(created_at)= '2026-02-01' and response_xml is not null) a;