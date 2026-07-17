create or replace view VW_TEST_POLICYCONVERSION_LIST(
	LEGACYPOLICYNUMBER
) as
select  distinct LEGACYPOLICYNUMBER  from (
select distinct T1.LEGACYPOLICYNUMBER from AGGNE.DEV.VW_SAMPLE_FINAL  T1

INNER JOIN AGGNE.DEV.Control_ExpiryDay C
  ON C.RuleName = 'POLICY_EXPIRY'
 AND C.IsActive = TRUE
, LATERAL FLATTEN(INPUT => SPLIT(C.ExpiryDays, ',')) F
WHERE 
    (
        -- Case 1: ExpiryDays = 0 → allow all dates
        TO_NUMBER(F.VALUE) = 0
    )
    OR
    (
        -- Case 2: Specific days (58,59,60)
        T1.EFFECTIVEDATE = DATEADD(day, TO_NUMBER(F.VALUE), CURRENT_DATE)
    )


-- where    EFFECTIVEDATE BETWEEN CURRENT_DATE AND DATEADD(DAY, 60, CURRENT_DATE)   


union all
select distinct trim(LegacyPolicyNumber) from(
select ' P00024481' LegacyPolicyNumber union all
select ' P00005753'union all
select ' P00029340'union all
select ' P00018756'union all
select ' P00007360'union all
select ' P00020537'union all
select ' P00033809'union all
select ' P00013608'union all
select ' P00026606'union all
select ' P00034062'union all
select ' P00000889'union all
select ' P00016008'union all
select ' P00018945'union all
select ' P00029953'union all
select ' P00018802'union all
select ' P00000302'union all
select ' P00000174'union all
select ' P00000043'union all
select ' P00000470'union all
select ' P00000100'union all
select ' P00006358'union all
select ' P00025457'union all
select ' P00031772'union all
select ' P00007819'union all
select ' P00008694'union all
select ' P00005253'union all
select ' P00000446'union all
select ' P00023302'union all
select ' P00036620'union all
select ' P00023770'union all
select ' P00036222'union all
select ' P00030774'union all
select ' P00017370'union all
select ' P00013082'union all
select ' P00008901'union all
select ' P00024249'union all
select ' P00010306'union all
select ' P00016061'union all
select ' P00013014'union all
select ' P00028687'union all
select ' P00017571'union all
select ' P00012646'union all
select ' P00014750'union all
select ' P00001192'union all
select ' P00010591'union all
select ' P00001251'union all
select ' P00009639'union all
select ' P00005098'union all
select ' P00005475'union all
select ' P00008274'union all
select ' P00020020'union all
select ' P00031349'union all
select ' P00026054'union all
select ' P00000997'union all
select ' P00025098'union all
select ' P00008001'union all
select ' P00010642'union all
select ' P00002408'union all
select ' P00025772'union all
select ' P00029209'union all
select ' P00034463'union all
select ' P00031957'union all
select ' P00010423'union all
select ' P00009160'union all
select ' P00002216'union all
select ' P00008189'union all
select ' P00019128'union all
select ' P0001042'union all
select ' P00025344'union all
select ' P00007704'union all
select ' P00030758'union all
select ' P00017038'union all
select ' P00002074'union all
select ' P00000510'union all
select ' P00001271'union all
select ' P00007145'union all
select ' P00012077'union all
select ' P00007634'union all
select ' P00005468'union all
select ' P00008714'union all
select ' P00006847'union all
select ' P00006578'union all
select ' P00010595'union all
select ' P00009040'union all
select ' P00010544'union all
select ' P00006923'union all
select ' P00006716'union all
select ' P00023084'union all
select ' P00035063'union all
select ' P00006260'union all
select ' P00001861'union all
select ' P00006512'union all
select ' P00006280'union all
select ' P00002676'union all
select ' P00017919'union all
select ' P00001641'union all
select ' P00005154'union all
select ' P00021190'union all
select ' P00006981'union all
select ' P00000004'union all
select ' P00031164'union all
select ' P00008241'union all
select ' P00018525'union all
select ' P00008242'union all
select ' P00024617'union all
select ' P00023792'union all
select ' P00025377'union all
select ' P00011628'union all
select ' P00010856'union all
select ' P00010828'union all
select ' P00010851'union all
select ' P00008247'union all
select ' P00030197'union all
select ' P00021665'union all
select ' P00018221'union all
select ' P00012556'union all
select ' P00034912'union all
select ' P00016973'union all
select ' P00020446'union all
select ' P00008244'union all
select ' P00010202'union all
select ' P00034822'union all
select ' P00008243'union all
select ' P00008251'union all
select ' P00008248'union all
select ' P00008249'union all
select ' P00011618'union all
select ' P00012567'union all
select ' P00002713'union all
select ' P00009022'union all
select ' P00010011'union all
select ' P00032208'union all
select ' P00024673'union all
select ' P00015017'union all
select ' P00009673'union all
select ' P00003106'union all
select ' P00003131'union all
select ' P00036185'union all
select ' P00007105'
)
);