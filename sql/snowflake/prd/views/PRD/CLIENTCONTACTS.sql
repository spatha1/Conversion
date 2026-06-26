create or replace secure view CLIENTCONTACTS(
	CLIENTID,
	TYPECODE,
	TYPEDESCRIPTION,
	DESCRIPTION,
	AREACODE,
	NUMBEROREMAILORWEB,
	EXTENSION
) as 
select
    PCU.PARTY_CNT as  ClientID,
    CONT.code as TypeCode,
    CONT.description       TypeDescription,
    CON.description             Description,
    CON.area_code               AreaCode,
    CON.number                  NumberOrEmailOrWeb,
    CON.extension               Extension
    from PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PARTY_CONTACT_USAGE PCU
    inner join PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CONTACT CON on PCU.contact_cnt = CON.contact_cnt
    inner join PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CONTACT_TYPE CONT on CON.contact_type_id = CONT.contact_type_id
    where CONT.is_contact_type = 1 or CONT.is_correspondence_type = 1;