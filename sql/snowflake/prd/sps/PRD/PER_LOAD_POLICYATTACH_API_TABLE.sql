-- SP: AGGNE.PRD.PER_LOAD_POLICYATTACH_API_TABLE
-- Signature: ()
-- Language:  SQL
-- Collected: 2026-06-25


BEGIN 

DELETE FROM AGGNE.PRD.POLICY_ATTACH_TABLE  where policy_number in (
SELECT distinct legacypolicynumber FROM AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT );


UPDATE AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT t1
SET
    effectivedate  = t2.sd,
    expirationdate = t2.ed
FROM AGGNE.PRD.POLICYATTACH_PER_V1 t2
WHERE t1.ID = CONCAT(
        TRIM(t2.purepolicynumber), '|',
        TRIM(t2.cmlnumber), '|',
        t2.expiringid_p_list, '|',
        t2.insurance_file_cnt_list
    );
    
 -- 4) INSERT (reload / migrate)
 
INSERT INTO AGGNE.PRD.POLICY_ATTACH_TABLE  
  (
    ID,
    POLICY_NUMBER,
    POLICY_ATTACH_XML,
    POLICYEFFECTIVEDATE,
    POLICYEXPIRATIONDATE,
    LOAD_TS
  )
    SELECT
     T1.ID,
     T1.legacypolicynumber,
     T1.response_xml,
     TRIM(TO_CHAR(effectivedate, 'YYYY-MM-DD')),
     TRIM(TO_CHAR(expirationdate, 'YYYY-MM-DD')),
     T1.created_at AS load_ts
    FROM AGGNE.PRD_XML.PA_PER_POLICYATTACH_MIGRATION_DCT T1 
    WHERE RESPONSE_XML IS NOT NULL;



create or replace temp table  AGGNE.PRD.TEMP_POLICYATTACH_PER_V1 as
SELECT  CONCAT(
            TRIM(PUREPOLICYNUMBER),
            '|',
            TRIM(CMLNUMBER),
            '|',
            TRIM(EXPIRINGID_P_LIST),
            '|',
            TRIM(INSURANCE_FILE_CNT_LIST)
        ) as id ,* FROM AGGNE.PRD.POLICYATTACH_PER_V1 
;

update AGGNE.PRD.POLICY_ATTACH_TABLE t1 set t1.POLICYEFFECTIVEDATE=REPLACE(SD, 'M', ''),t1.POLICYEXPIRATIONDATE=REPLACE(ED, 'M', '') from  AGGNE.PRD.TEMP_POLICYATTACH_PER_V1 t2 where t1.id=t2.id
;

 RETURN 'Prod API Attach Table Loaded Successfully';
 
END
;
