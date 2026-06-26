/*══════════════════════════════════════════════════════════════════════════════
  PP TOKEN LINEAGE DIAGNOSTIC
  ─────────────────────────────────────────────────────────────────────────────
  Purpose : One row per (policy × token) showing value at every ETL layer.
            Identifies the FIRST layer where a value goes missing (GAP_LAYER).

  Layers  : PURE     = PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents  [RISK cols confirmed; HB/HC coverage cols best-guess — verify]
             STEP1    = AGGNE.DEV.Locationdetails_PER  (seq 14 risk building)
             STEP2    = AGGNE.DEV.HB_02 / HC_02 / Output_Coverage_PER
             VIEW     = AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD / PER_RISK_BUILDING_FINAL / PER_FINAL
             XML      = AGGNE.DEV.PER_BUILDING_TARGET / PER_HC_TARGET / PER_RISK_BUILDING_TARGET
                        AGGNE.DEV.PER_POLICY_MIGRATION_DCT  (account tokens)

  Scope   : Policies in AGGNE.DEV.PP_Conversion_FIxList
            (swap the pol CTE for a specific policy number if needed)

  READ-ONLY — no writes.
══════════════════════════════════════════════════════════════════════════════*/

WITH

/* ── Scope ──────────────────────────────────────────────────────────────── */
pol AS (
    SELECT TRIM(LEGACYPOLICYNUMBER) AS LEGACYPOLICYNUMBER
    FROM AGGNE.DEV.PP_Conversion_FIxList
),

/* ── PURE layer : PURE_SNAPSHOT.PER_HomeContents ─────────────────────────
   Join chain mirrors Sample_PER creation in DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql.
   RISK column names confirmed from that SP (t20.HCxxx).
   HB/HC coverage column names (marked TODO) follow the same HCxxx convention
   but are NOT in the SP — verify by running:
     SELECT * FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents LIMIT 1
   ─────────────────────────────────────────────────────────────────────────*/
pure AS (
    SELECT
        TRIM(t3.insurance_ref)                          AS LEGACYPOLICYNUMBER,
        -- HB/HC coverage: column names NOT confirmed — nulled until user runs
        --   DESC TABLE PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents
        -- then replace each NULL with CAST(t20.<actual_col> AS VARCHAR)
        NULL::VARCHAR                                   AS VOLUNTARYEXCESS,
        NULL::VARCHAR                                   AS STANDARDEXCESS,
        NULL::VARCHAR                                   AS IMPOSEDEXCESS,
        NULL::VARCHAR                                   AS EARTHQUAKEEXCESS,
        NULL::VARCHAR                                   AS FLOODEXCESS,
        NULL::VARCHAR                                   AS FLOODDAMAGE,
        NULL::VARCHAR                                   AS ACCIDENTALLOSSORDAMAGE,
        NULL::VARCHAR                                   AS SPECIFIEDITEMSAWAY,
        NULL::VARCHAR                                   AS UNSPECIFIEDITEMSAWAY,
        NULL::VARCHAR                                   AS UNSPECIFIEDITEMSAWAYLIMIT,
        NULL::VARCHAR                                   AS HOMEBUILDINGSLIMIT,
        NULL::VARCHAR                                   AS LANDLORDPROTECTIONS,
        NULL::VARCHAR                                   AS MINIMUMRENTALPERIOD,
        NULL::VARCHAR                                   AS WEEKLYRENT,
        -- RISK building (confirmed from Sample_PER creation in PURE-to-write SP)
        CAST(t20.HCNoStories                AS VARCHAR) AS STOREYS,
        CAST(t20.HCYearConstructed          AS VARCHAR) AS YEARBUILDINGCONSTRUCTED,
        CAST(t20.HCLastRewired              AS VARCHAR) AS YEARLASTREWIRED,
        CAST(t20.HCLastReplumb              AS VARCHAR) AS YEARLASTREPLUMBED
    FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file t3
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.insurance_file_risk_link t2
        ON t3.insurance_file_cnt = t2.insurance_file_cnt
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.risk t1
        ON t2.risk_cnt = t1.risk_cnt
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.GIS_Policy_Link t17
        ON t1.risk_cnt = t17.risk_id
    INNER JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_Policy_Binder t18
        ON t17.gis_policy_link_id = t18.gis_policy_link_id
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents t20
        ON t18.PER_Policy_Binder_id = t20.PER_Policy_Binder_id
    INNER JOIN pol ON TRIM(t3.insurance_ref) = pol.LEGACYPOLICYNUMBER
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(t3.insurance_ref) ORDER BY t18.PER_Policy_Binder_id) = 1
),

/* ── STEP 1 : Locationdetails_PER (source for seq 14 Risk Building tokens) ──
   PER_RISK_BUILDING_FINAL reads directly from Locationdetails_PER — not Sample_PER.
   Column names confirmed from PER_RISK_BUILDING_FINAL view source.
   ─────────────────────────────────────────────────────────────────────────*/
s1 AS (
    SELECT
        TRIM(PUREPOLICYNUMBER)              AS LEGACYPOLICYNUMBER,
        EXPIRINGID_P,
        CAST(STOREYS                        AS VARCHAR) AS STOREYS,
        CAST(YEARBUILDINGCONSTRUCTED        AS VARCHAR) AS YEARBUILDINGCONSTRUCTED,
        CAST(YEARLASTREWIRED                AS VARCHAR) AS YEARLASTREWIRED,
        CAST(YEARLASTREPLUMBED              AS VARCHAR) AS YEARLASTREPLUMBED,
        CAST(ROOFCONSTRUCTION               AS VARCHAR) AS ROOFCONST,
        CAST(MAINWALLCONSTRUCTION           AS VARCHAR) AS WALLCONST,
        CAST(FLOORCONSTRUCTION              AS VARCHAR) AS FLOORCONST,
        CAST(ALARMSYSTEMINSTALLED           AS VARCHAR) AS ALARMSYSTEM,
        CAST(DEADLOCKSINSTALLED             AS VARCHAR) AS DEADLOCKS,
        CAST(GRILLKEYLOCKINSTALLED          AS VARCHAR) AS GRILLKEYLOCK,
        CAST(SECURITYDETAILS                AS VARCHAR) AS SECURITYDETAILS,
        CAST(HOWOCCUPPIED                   AS VARCHAR) AS HOWOCCUP
    FROM AGGNE.DEV.Locationdetails_PER
    WHERE TRIM(PUREPOLICYNUMBER) IN (SELECT LEGACYPOLICYNUMBER FROM pol)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(PUREPOLICYNUMBER) ORDER BY EXPIRINGID_P) = 1
),

/* ── STEP 2a : HB_02 (Home Buildings cover) ─────────────────────────────── */
-- HB_02 only holds HB-specific coverage fields. Excess fields (VOLUNTARYEXCESS,
-- STANDARDEXCESS, etc.) are NOT in HB_02 — they live in HC_02. Section A excess
-- tokens therefore use s2_hc as the STEP2 source.
s2_hb AS (
    SELECT
        TRIM(PUREPOLICYNUMBER)           AS LEGACYPOLICYNUMBER,
        EXPIRINGID_P,
        CAST(HOMEBUILDINGSLIMIT          AS VARCHAR) AS HOMEBUILDINGSLIMIT,
        CAST(LANDLORDPROTECTIONS         AS VARCHAR) AS LANDLORDPROTECTIONS,
        CAST(MINIMUMRENTALPERIOD         AS VARCHAR) AS MINIMUMRENTALPERIOD,
        CAST(WEEKLYRENT                  AS VARCHAR) AS WEEKLYRENT
    FROM AGGNE.DEV.HB_02
    WHERE TRIM(PUREPOLICYNUMBER) IN (SELECT LEGACYPOLICYNUMBER FROM pol)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(PUREPOLICYNUMBER) ORDER BY EXPIRINGID_P) = 1
),

/* ── STEP 2b : HC_02 (Home Contents cover) ──────────────────────────────── */
-- HC_02 (DEV) columns confirmed from PER_HOME_BUILDING_PAYLOAD view:
--   VOLUNTARYEXCESS, ACCIDENTALLOSSORDAMAGE, SPECIFIEDITEMSAWAY,
--   UNSPECIFIEDITEMSAWAY, UNSPECIFIEDITEMSAWAYLIMIT.
-- STANDARDEXCESS / IMPOSEDEXCESS / EARTHQUAKEEXCESS / FLOODEXCESS /
--   FLOODDAMAGE are NOT columns in AGGNE.DEV.HC_02 — in the current
--   seq 13 template they are hardcoded empty (<Standard/> etc.) or
--   hardcoded 'Taken' (FloodDamage), so no token substitution occurs.
s2_hc AS (
    SELECT
        TRIM(PUREPOLICYNUMBER)           AS LEGACYPOLICYNUMBER,
        EXPIRINGID_P,
        CAST(VOLUNTARYEXCESS             AS VARCHAR) AS VOLUNTARYEXCESS,
        CAST(ACCIDENTALLOSSORDAMAGE      AS VARCHAR) AS ACCIDENTALLOSSORDAMAGE,
        CAST(SPECIFIEDITEMSAWAY          AS VARCHAR) AS SPECIFIEDITEMSAWAY,
        CAST(UNSPECIFIEDITEMSAWAY        AS VARCHAR) AS UNSPECIFIEDITEMSAWAY,
        CAST(UNSPECIFIEDITEMSAWAYLIMIT   AS VARCHAR) AS UNSPECIFIEDITEMSAWAYLIMIT
    FROM AGGNE.DEV.HC_02
    WHERE TRIM(PUREPOLICYNUMBER) IN (SELECT LEGACYPOLICYNUMBER FROM pol)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(PUREPOLICYNUMBER) ORDER BY EXPIRINGID_P) = 1
),

/* ── STEP 2c : Output_Coverage_PER (claims history + premium) ───────────── */
s2_ocp AS (
    SELECT
        TRIM(POLICYNUMBER)               AS LEGACYPOLICYNUMBER,
        EXPIRINGID_P,
        CAST(COALESCE(HBCLMCNT,  0)     AS VARCHAR) AS HBCLMCNT,
        CAST(COALESCE(HBCLMINCD, 0)     AS VARCHAR) AS HBCLMINCD,
        CAST(COALESCE(HCCLMCNT,  0)     AS VARCHAR) AS HCCLMCNT,
        CAST(COALESCE(HCCLMINCD, 0)     AS VARCHAR) AS HCCLMINCD,
        CAST(COALESCE(HMEXPPREM, 0)     AS VARCHAR) AS HMEXPPREM
    FROM AGGNE.DEV.Output_Coverage_PER
    WHERE TRIM(POLICYNUMBER) IN (SELECT LEGACYPOLICYNUMBER FROM pol)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(POLICYNUMBER) ORDER BY EXPIRINGID_P) = 1
),

/* ── VIEW layer : PER_HOME_BUILDING_PAYLOAD (seq 7 HB + seq 13 HC) ─────────
   PUREPOLICYNUMBER in this view is composite: LEGACYPOLICYNUMBER|CML|EXPID
   ─────────────────────────────────────────────────────────────────────────*/
vw_hb AS (
    SELECT
        SPLIT_PART(PUREPOLICYNUMBER, '|', 1) AS LEGACYPOLICYNUMBER,
        CAST(VOLUNTARYEXCESS                 AS VARCHAR) AS VOLUNTARYEXCESS,
        CAST(ACCIDENTALLOSSORDAMAGE          AS VARCHAR) AS ACCIDENTALLOSSORDAMAGE,
        CAST(SPECIFIEDITEMSAWAY              AS VARCHAR) AS SPECIFIEDITEMSAWAY,
        CAST(UNSPECIFIEDITEMSAWAY            AS VARCHAR) AS UNSPECIFIEDITEMSAWAY,
        CAST(UNSPECIFIEDITEMSAWAYLIMIT       AS VARCHAR) AS UNSPECIFIEDITEMSAWAYLIMIT,
        CAST(HOMEBUILDINGSLIMIT              AS VARCHAR) AS HOMEBUILDINGSLIMIT,
        CAST(LANDLORDPROTECTIONS             AS VARCHAR) AS LANDLORDPROTECTIONS,
        CAST(MINIMUMRENTALPERIOD             AS VARCHAR) AS MINIMUMRENTALPERIOD,
        CAST(WEEKLYRENT                      AS VARCHAR) AS WEEKLYRENT,
        CAST(HBCLMCNT                        AS VARCHAR) AS HBCLMCNT,
        CAST(HBCLMINCD                       AS VARCHAR) AS HBCLMINCD,
        CAST(EXPPREM                         AS VARCHAR) AS EXPPREM,
        CAST(HCCLMCNT                        AS VARCHAR) AS HCCLMCNT,
        CAST(HCCLMINCD                       AS VARCHAR) AS HCCLMINCD,
        CAST(HBEXPPREM                       AS VARCHAR) AS HBEXPPREM
        -- NOTE: STANDARDEXCESS, IMPOSEDEXCESS, EARTHQUAKEEXCESS, FLOODEXCESS, FLOODDAMAGE
        --       are not in AGGNE.DEV.HC_02 — hardcoded empty/Taken in the seq 13 template
    FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
    WHERE COVERAGE = 'Building'
      AND SPLIT_PART(PUREPOLICYNUMBER, '|', 1) IN (SELECT LEGACYPOLICYNUMBER FROM pol)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY SPLIT_PART(PUREPOLICYNUMBER,'|',1) ORDER BY PUREPOLICYNUMBER) = 1
),

/* ── VIEW layer : PER_RISK_BUILDING_FINAL (seq 14) ──────────────────────── */
vw_risk AS (
    SELECT
        TRIM(LEGACYPOLICYNUMBER)             AS LEGACYPOLICYNUMBER,
        CAST(STOREYS                         AS VARCHAR) AS STOREYS,
        CAST(YEARBUILDINGCONSTRUCTED         AS VARCHAR) AS YEARBUILDINGCONSTRUCTED,
        CAST(YEARLASTREWIRED                 AS VARCHAR) AS YEARLASTREWIRED,
        CAST(YEARLASTREPLUMBED               AS VARCHAR) AS YEARLASTREPLUMBED,
        CAST(ROOFCONSTRUCTION_FINAL          AS VARCHAR) AS ROOFCONSTRUCTION_FINAL,
        CAST(MAINWALLCONSTRUCTION_FINAL      AS VARCHAR) AS MAINWALLCONSTRUCTION_FINAL,
        CAST(FLOORCONSTRUCTION_FINAL         AS VARCHAR) AS FLOORCONSTRUCTION_FINAL,
        CAST(ALARMSYSTEMINSTALLED_FINAL      AS VARCHAR) AS ALARMSYSTEMINSTALLED_FINAL,
        CAST(DEADLOCKSINSTALLED_FINAL        AS VARCHAR) AS DEADLOCKSINSTALLED_FINAL,
        CAST(GRILLKEYLOCKINSTALLED_FINAL     AS VARCHAR) AS GRILLKEYLOCKINSTALLED_FINAL,
        CAST(SECURITYDETAILS                 AS VARCHAR) AS SECURITYDETAILS,
        CAST(HOWOCCUPPIED                    AS VARCHAR) AS HOWOCCUPPIED
    FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL
    WHERE TRIM(LEGACYPOLICYNUMBER) IN (SELECT LEGACYPOLICYNUMBER FROM pol)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(LEGACYPOLICYNUMBER) ORDER BY TRIM(LEGACYPOLICYNUMBER)) = 1
),

/* ── VIEW layer : PER_FINAL (feeds final XML SP for account tokens) ─────── */
vw_final AS (
    SELECT
        TRIM(LEGACYPOLICYNUMBER)             AS LEGACYPOLICYNUMBER,
        CAST(CMLLEGALENTITY                  AS VARCHAR) AS CMLLEGALENTITY,
        CAST(CMLNUMBER                       AS VARCHAR) AS CMLNUMBER,
        CAST(CSLNUMBER                       AS VARCHAR) AS CSLNUMBER,
        CAST(CML_LEGAL_ENTITY                AS VARCHAR) AS CML_LEGAL_ENTITY,
        CAST(ABN_NZBN                        AS VARCHAR) AS ABN_NZBN,
        CAST(PRIMARYRATINGSTATE              AS VARCHAR) AS PRIMARYRATINGSTATE,
        CAST(PAYMENT_METHOD                  AS VARCHAR) AS PAYMENT_METHOD,
        CAST(EFFECTIVEDATE                   AS VARCHAR) AS EFFECTIVEDATE,
        CAST(EXPIRATIONDATE                  AS VARCHAR) AS EXPIRATIONDATE,
        CAST(PHONE                           AS VARCHAR) AS PHONE,
        CAST(EMAIL                           AS VARCHAR) AS EMAIL,
        CAST(MAINCONTACT                     AS VARCHAR) AS MAINCONTACT,
        CAST(CSL_REGION                      AS VARCHAR) AS CSL_REGION,
        CAST(CSL_ZONE                        AS VARCHAR) AS CSL_ZONE,
        CAST(CSL_AREA_MANAGER                AS VARCHAR) AS CSL_AREA_MANAGER,
        CAST(CSL_MEMBER_STATUS               AS VARCHAR) AS CSL_MEMBER_STATUS,
        CAST(CSL_CREDIT_LIMIT                AS VARCHAR) AS CSL_CREDIT_LIMIT,
        CAST(STANDARD_INDUSTRY_CODE          AS VARCHAR) AS STANDARD_INDUSTRY_CODE,
        CAST(CML_RISK_ACCOUNT_MANAGER        AS VARCHAR) AS CML_RISK_ACCOUNT_MANAGER
    FROM AGGNE.DEV.PER_FINAL
    WHERE TRIM(LEGACYPOLICYNUMBER) IN (SELECT LEGACYPOLICYNUMBER FROM pol)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(LEGACYPOLICYNUMBER) ORDER BY TRIM(LEGACYPOLICYNUMBER)) = 1
),

/* ── XML layer : PER_BUILDING_TARGET (seq 7 HB resolved payload) ─────────── */
xml_hb AS (
    SELECT
        SPLIT_PART(ID, '|', 1)                   AS LEGACYPOLICYNUMBER,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS PAYLOAD
    FROM AGGNE.DEV.PER_BUILDING_TARGET
    WHERE ITR_TYPE = 'RISK_Building_HB'
    GROUP BY SPLIT_PART(ID, '|', 1)
),

/* ── XML layer : PER_HC_TARGET (seq 13 HC resolved payload) ─────────────── */
xml_hc AS (
    SELECT
        SPLIT_PART(ID, '|', 1)                   AS LEGACYPOLICYNUMBER,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS PAYLOAD
    FROM AGGNE.DEV.PER_HC_TARGET
    WHERE ITR_TYPE = 'RISK_Building_HC'
    GROUP BY SPLIT_PART(ID, '|', 1)
),

/* ── XML layer : PER_RISK_BUILDING_TARGET (seq 14 resolved payload) ─────── */
xml_risk AS (
    SELECT
        SPLIT_PART(ID, '|', 1)                   AS LEGACYPOLICYNUMBER,
        LISTAGG(PAYLOAD, '\n') WITHIN GROUP (ORDER BY PAYLOAD) AS PAYLOAD
    FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
    WHERE ITR_TYPE = 'RISK_Building'
    GROUP BY SPLIT_PART(ID, '|', 1)
),

/* ── XML layer : PER_POLICY_MIGRATION_DCT (final REQUEST_XML) ───────────── */
xml_final AS (
    SELECT
        TRIM(LEGACYPOLICYNUMBER)                    AS LEGACYPOLICYNUMBER,
        REGEXP_SUBSTR(REQUEST_XML, '<Name>([^<]+)</Name>',                                          1,1,'e',1) AS XML_CMLLEGALENTITY,
        REGEXP_SUBSTR(REQUEST_XML, '<CMLNumber>([^<]+)</CMLNumber>',                                1,1,'e',1) AS XML_CMLNUMBER,
        REGEXP_SUBSTR(REQUEST_XML, '<CSLNumber>([^<]+)</CSLNumber>',                                1,1,'e',1) AS XML_CSLNUMBER,
        REGEXP_SUBSTR(REQUEST_XML, '<CSLLegalEntityName>([^<]+)</CSLLegalEntityName>',              1,1,'e',1) AS XML_CSL_LEGAL_ENTITY,
        REGEXP_SUBSTR(REQUEST_XML, '<ABNNumber>([^<]+)</ABNNumber>',                                1,1,'e',1) AS XML_ABN_NZBN,
        REGEXP_SUBSTR(REQUEST_XML, '<PrimaryRatingState>([^<]+)</PrimaryRatingState>',              1,1,'e',1) AS XML_PRIMARYRATINGSTATE,
        REGEXP_SUBSTR(REQUEST_XML, '<BillClass>([^<]+)</BillClass>',                                1,1,'e',1) AS XML_PAYMENT_METHOD,
        REGEXP_SUBSTR(REQUEST_XML, '<CSLPhone>([^<]+)</CSLPhone>',                                  1,1,'e',1) AS XML_PHONE,
        REGEXP_SUBSTR(REQUEST_XML, '<CSLEmail>([^<]+)</CSLEmail>',                                  1,1,'e',1) AS XML_EMAIL,
        REGEXP_SUBSTR(REQUEST_XML, '<CSLContactName>([^<]+)</CSLContactName>',                      1,1,'e',1) AS XML_MAINCONTACT,
        REGEXP_SUBSTR(REQUEST_XML, '<RAMRegion>([^<]+)</RAMRegion>',                                1,1,'e',1) AS XML_CSL_REGION,
        REGEXP_SUBSTR(REQUEST_XML, '<StandardIndustryCode>([^<]+)</StandardIndustryCode>',          1,1,'e',1) AS XML_STANDARD_INDUSTRY_CODE,
        REGEXP_SUBSTR(REQUEST_XML, '<CMLRiskAccountManager>([^<]+)</CMLRiskAccountManager>',        1,1,'e',1) AS XML_CML_RISK_ACCOUNT_MANAGER
    FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
    WHERE TRIM(LEGACYPOLICYNUMBER) IN (SELECT LEGACYPOLICYNUMBER FROM pol)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY TRIM(LEGACYPOLICYNUMBER) ORDER BY TRIM(LEGACYPOLICYNUMBER)) = 1
)

/*══════════════════════════════════════════════════════════════════════════════
  MAIN RESULT — one row per (policy × token)
  Output columns:
    LEGACYPOLICYNUMBER | CONFIG_SEQ | COVERAGE_TYPE | TOKEN
    PURE_VALUE | STEP1_VALUE | STEP2_VALUE | VIEW_VALUE | XML_VALUE | GAP_LAYER
══════════════════════════════════════════════════════════════════════════════*/

/*──────────────────────────────────────────────────────────────────────────
  SECTION A : SEQ 7 — HB TOKENS
  Source chain: PURE → HB_02 (step2) → PER_HOME_BUILDING_PAYLOAD (view) → PER_BUILDING_TARGET (xml)
──────────────────────────────────────────────────────────────────────────*/
SELECT
    pol.LEGACYPOLICYNUMBER,
    7                           AS CONFIG_SEQ,
    'HB'                        AS COVERAGE_TYPE,
    '{VOLUNTARYEXCESS}'         AS TOKEN,
    pure.VOLUNTARYEXCESS        AS PURE_VALUE,
    NULL                        AS STEP1_VALUE,
    s2_hc.VOLUNTARYEXCESS       AS STEP2_VALUE,
    vw_hb.VOLUNTARYEXCESS       AS VIEW_VALUE,
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<Voluntary>([^<]+)</Voluntary>',1,1,'e',1) AS XML_VALUE,
    CASE
        WHEN xml_hb.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hb.PAYLOAD,'<Voluntary>([^<]+)</Voluntary>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.VOLUNTARYEXCESS  IS NULL OR vw_hb.VOLUNTARYEXCESS  = '' THEN 'VIEW'
        WHEN s2_hc.VOLUNTARYEXCESS  IS NULL OR s2_hc.VOLUNTARYEXCESS  = '' THEN 'STEP2_HC_02'
        WHEN pure.VOLUNTARYEXCESS   IS NULL OR pure.VOLUNTARYEXCESS   = '' THEN 'PURE'
        ELSE 'OK'
    END AS GAP_LAYER
FROM pol
LEFT JOIN pure   ON pure.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN s2_hc  ON s2_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{STANDARDEXCESS}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <Standard/> (empty) in HC template
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<Standard>([^<]+)</Standard>',1,1,'e',1),
    'HARDCODED_EMPTY_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{IMPOSEDEXCESS}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <Imposed/> (empty) in HC template
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<Imposed>([^<]+)</Imposed>',1,1,'e',1),
    'HARDCODED_EMPTY_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{EARTHQUAKEEXCESS}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <Earthquake/> (empty) in HC template
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<Earthquake>([^<]+)</Earthquake>',1,1,'e',1),
    'HARDCODED_EMPTY_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{FLOODEXCESS}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <Flood/> (empty) in HC template
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<Flood>([^<]+)</Flood>',1,1,'e',1),
    'HARDCODED_EMPTY_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{FLOODDAMAGE}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <FloodDamage>Taken</FloodDamage> in HC template
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<FloodDamage>([^<]+)</FloodDamage>',1,1,'e',1),
    'HARDCODED_TAKEN_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{ACCIDENTALLOSSORDAMAGE}',
    pure.ACCIDENTALLOSSORDAMAGE, NULL, s2_hc.ACCIDENTALLOSSORDAMAGE, vw_hb.ACCIDENTALLOSSORDAMAGE,
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<AccidentalLossOrDamage>([^<]+)</AccidentalLossOrDamage>',1,1,'e',1),
    CASE
        WHEN xml_hb.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hb.PAYLOAD,'<AccidentalLossOrDamage>([^<]+)</AccidentalLossOrDamage>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.ACCIDENTALLOSSORDAMAGE IS NULL OR vw_hb.ACCIDENTALLOSSORDAMAGE = '' THEN 'VIEW'
        WHEN s2_hc.ACCIDENTALLOSSORDAMAGE IS NULL OR s2_hc.ACCIDENTALLOSSORDAMAGE = '' THEN 'STEP2_HC_02'
        WHEN pure.ACCIDENTALLOSSORDAMAGE  IS NULL OR pure.ACCIDENTALLOSSORDAMAGE  = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure   ON pure.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN s2_hc  ON s2_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{HOMEBUILDINGSLIMIT}',
    pure.HOMEBUILDINGSLIMIT, NULL, s2_hb.HOMEBUILDINGSLIMIT, vw_hb.HOMEBUILDINGSLIMIT,
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<GlassLimit>([^<]+)</GlassLimit>',1,1,'e',1),
    CASE
        WHEN xml_hb.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hb.PAYLOAD,'<GlassLimit>([^<]+)</GlassLimit>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.HOMEBUILDINGSLIMIT IS NULL OR vw_hb.HOMEBUILDINGSLIMIT = '' THEN 'VIEW'
        WHEN s2_hb.HOMEBUILDINGSLIMIT IS NULL OR s2_hb.HOMEBUILDINGSLIMIT = '' THEN 'STEP2_HB_02'
        WHEN pure.HOMEBUILDINGSLIMIT  IS NULL OR pure.HOMEBUILDINGSLIMIT  = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure   ON pure.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN s2_hb  ON s2_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{LANDLORDPROTECTIONS}',
    pure.LANDLORDPROTECTIONS, NULL, s2_hb.LANDLORDPROTECTIONS, vw_hb.LANDLORDPROTECTIONS,
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<LandlordProtections>([^<]+)</LandlordProtections>',1,1,'e',1),
    CASE
        WHEN xml_hb.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hb.PAYLOAD,'<LandlordProtections>([^<]+)</LandlordProtections>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.LANDLORDPROTECTIONS IS NULL OR vw_hb.LANDLORDPROTECTIONS = '' THEN 'VIEW'
        WHEN s2_hb.LANDLORDPROTECTIONS IS NULL OR s2_hb.LANDLORDPROTECTIONS = '' THEN 'STEP2_HB_02'
        WHEN pure.LANDLORDPROTECTIONS  IS NULL OR pure.LANDLORDPROTECTIONS  = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure   ON pure.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN s2_hb  ON s2_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{HBCLMCNT}',
    NULL, NULL, s2_ocp.HBCLMCNT, vw_hb.HBCLMCNT,
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<NumberOfClaims>([^<]+)</NumberOfClaims>',1,1,'e',1),
    CASE
        WHEN xml_hb.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hb.PAYLOAD,'<NumberOfClaims>([^<]+)</NumberOfClaims>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.HBCLMCNT  IS NULL OR vw_hb.HBCLMCNT  = '' THEN 'VIEW'
        WHEN s2_ocp.HBCLMCNT IS NULL OR s2_ocp.HBCLMCNT = '' THEN 'STEP2_OCP'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s2_ocp ON s2_ocp.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 7,'HB','{EXPPREM}',
    NULL, NULL, s2_ocp.HMEXPPREM, vw_hb.EXPPREM,
    REGEXP_SUBSTR(xml_hb.PAYLOAD,'<Premium>([^<]+)</Premium>',1,1,'e',1),
    CASE
        WHEN xml_hb.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hb.PAYLOAD,'<Premium>([^<]+)</Premium>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.EXPPREM    IS NULL OR vw_hb.EXPPREM    = '' THEN 'VIEW'
        WHEN s2_ocp.HMEXPPREM IS NULL OR s2_ocp.HMEXPPREM = '' THEN 'STEP2_OCP'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s2_ocp ON s2_ocp.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hb ON xml_hb.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER

/*──────────────────────────────────────────────────────────────────────────
  SECTION B : SEQ 13 — HC TOKENS
  Source chain: PURE → HC_02 (step2) → PER_HOME_BUILDING_PAYLOAD (view) → PER_HC_TARGET (xml)
──────────────────────────────────────────────────────────────────────────*/
UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{VOLUNTARYEXCESS}',
    pure.VOLUNTARYEXCESS, NULL, s2_hc.VOLUNTARYEXCESS, vw_hb.VOLUNTARYEXCESS,
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<Voluntary>([^<]+)</Voluntary>',1,1,'e',1),
    CASE
        WHEN xml_hc.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hc.PAYLOAD,'<Voluntary>([^<]+)</Voluntary>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.VOLUNTARYEXCESS IS NULL OR vw_hb.VOLUNTARYEXCESS = '' THEN 'VIEW'
        WHEN s2_hc.VOLUNTARYEXCESS IS NULL OR s2_hc.VOLUNTARYEXCESS = '' THEN 'STEP2_HC_02'
        WHEN pure.VOLUNTARYEXCESS  IS NULL OR pure.VOLUNTARYEXCESS  = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure   ON pure.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN s2_hc  ON s2_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{STANDARDEXCESS}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <Standard/> (empty) in seq 13 template
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<Standard>([^<]+)</Standard>',1,1,'e',1),
    'HARDCODED_EMPTY_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{IMPOSEDEXCESS}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <Imposed/> (empty) in seq 13 template
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<Imposed>([^<]+)</Imposed>',1,1,'e',1),
    'HARDCODED_EMPTY_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{EARTHQUAKEEXCESS}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <Earthquake/> (empty) in seq 13 template
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<Earthquake>([^<]+)</Earthquake>',1,1,'e',1),
    'HARDCODED_EMPTY_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{FLOODEXCESS}',
    NULL, NULL, NULL,
    NULL,  -- not in HC_02 DEV; hardcoded <Flood/> (empty) in seq 13 template
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<Flood>([^<]+)</Flood>',1,1,'e',1),
    'HARDCODED_EMPTY_IN_TEMPLATE'
FROM pol
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{ACCIDENTALLOSSORDAMAGE}',
    pure.ACCIDENTALLOSSORDAMAGE, NULL, s2_hc.ACCIDENTALLOSSORDAMAGE, vw_hb.ACCIDENTALLOSSORDAMAGE,
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<AccidentalLossOrDamage>([^<]+)</AccidentalLossOrDamage>',1,1,'e',1),
    CASE
        WHEN xml_hc.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hc.PAYLOAD,'<AccidentalLossOrDamage>([^<]+)</AccidentalLossOrDamage>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.ACCIDENTALLOSSORDAMAGE IS NULL OR vw_hb.ACCIDENTALLOSSORDAMAGE = '' THEN 'VIEW'
        WHEN s2_hc.ACCIDENTALLOSSORDAMAGE IS NULL OR s2_hc.ACCIDENTALLOSSORDAMAGE = '' THEN 'STEP2_HC_02'
        WHEN pure.ACCIDENTALLOSSORDAMAGE  IS NULL OR pure.ACCIDENTALLOSSORDAMAGE  = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure   ON pure.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN s2_hc  ON s2_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{SPECIFIEDITEMSAWAY}',
    pure.SPECIFIEDITEMSAWAY, NULL, s2_hc.SPECIFIEDITEMSAWAY, vw_hb.SPECIFIEDITEMSAWAY,
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<SpecifiedItemsPremises>([^<]+)</SpecifiedItemsPremises>',1,1,'e',1),
    CASE
        WHEN xml_hc.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hc.PAYLOAD,'<SpecifiedItemsPremises>([^<]+)</SpecifiedItemsPremises>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.SPECIFIEDITEMSAWAY IS NULL OR vw_hb.SPECIFIEDITEMSAWAY = '' THEN 'VIEW'
        WHEN s2_hc.SPECIFIEDITEMSAWAY IS NULL OR s2_hc.SPECIFIEDITEMSAWAY = '' THEN 'STEP2_HC_02'
        WHEN pure.SPECIFIEDITEMSAWAY  IS NULL OR pure.SPECIFIEDITEMSAWAY  = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure   ON pure.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN s2_hc  ON s2_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{UNSPECIFIEDITEMSAWAY}',
    pure.UNSPECIFIEDITEMSAWAY, NULL, s2_hc.UNSPECIFIEDITEMSAWAY, vw_hb.UNSPECIFIEDITEMSAWAY,
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<UnspecifiedItemsAwayPremises>([^<]+)</UnspecifiedItemsAwayPremises>',1,1,'e',1),
    CASE
        WHEN xml_hc.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hc.PAYLOAD,'<UnspecifiedItemsAwayPremises>([^<]+)</UnspecifiedItemsAwayPremises>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.UNSPECIFIEDITEMSAWAY IS NULL OR vw_hb.UNSPECIFIEDITEMSAWAY = '' THEN 'VIEW'
        WHEN s2_hc.UNSPECIFIEDITEMSAWAY IS NULL OR s2_hc.UNSPECIFIEDITEMSAWAY = '' THEN 'STEP2_HC_02'
        WHEN pure.UNSPECIFIEDITEMSAWAY  IS NULL OR pure.UNSPECIFIEDITEMSAWAY  = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure   ON pure.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN s2_hc  ON s2_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{HCCLMCNT}',
    NULL, NULL, s2_ocp.HCCLMCNT, vw_hb.HCCLMCNT,
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<NumberOfClaims>([^<]+)</NumberOfClaims>',1,1,'e',1),
    CASE
        WHEN xml_hc.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hc.PAYLOAD,'<NumberOfClaims>([^<]+)</NumberOfClaims>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.HCCLMCNT  IS NULL OR vw_hb.HCCLMCNT  = '' THEN 'VIEW'
        WHEN s2_ocp.HCCLMCNT IS NULL OR s2_ocp.HCCLMCNT = '' THEN 'STEP2_OCP'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s2_ocp ON s2_ocp.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 13,'HC','{HBEXPPREM}',
    NULL, NULL, s2_ocp.HMEXPPREM, vw_hb.HBEXPPREM,
    REGEXP_SUBSTR(xml_hc.PAYLOAD,'<Premium>([^<]+)</Premium>',1,1,'e',1),
    CASE
        WHEN xml_hc.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_hc.PAYLOAD,'<Premium>([^<]+)</Premium>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_hb.HBEXPPREM  IS NULL OR vw_hb.HBEXPPREM  = '' THEN 'VIEW'
        WHEN s2_ocp.HMEXPPREM IS NULL OR s2_ocp.HMEXPPREM = '' THEN 'STEP2_OCP'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s2_ocp ON s2_ocp.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_hb  ON vw_hb.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_hc ON xml_hc.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER

/*──────────────────────────────────────────────────────────────────────────
  SECTION C : SEQ 14 — RISK BUILDING TOKENS
  Source chain: PURE → Sample_PER (step1) → PER_RISK_BUILDING_FINAL (view) → PER_RISK_BUILDING_TARGET (xml)
──────────────────────────────────────────────────────────────────────────*/
UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 14,'RISK','{STOREYS}',
    pure.STOREYS, s1.STOREYS, NULL, vw_risk.STOREYS,
    REGEXP_SUBSTR(xml_risk.PAYLOAD,'<NumberOfStories>([^<]+)</NumberOfStories>',1,1,'e',1),
    CASE
        WHEN xml_risk.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_risk.PAYLOAD,'<NumberOfStories>([^<]+)</NumberOfStories>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_risk.STOREYS IS NULL OR vw_risk.STOREYS = '' THEN 'VIEW'
        WHEN s1.STOREYS      IS NULL OR s1.STOREYS      = '' THEN 'STEP1_Locationdetails_PER'
        WHEN pure.STOREYS    IS NULL OR pure.STOREYS    = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure     ON pure.LEGACYPOLICYNUMBER     = pol.LEGACYPOLICYNUMBER
LEFT JOIN s1       ON s1.LEGACYPOLICYNUMBER       = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_risk  ON vw_risk.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_risk ON xml_risk.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 14,'RISK','{YEARBUILDINGCONSTRUCTED}',
    pure.YEARBUILDINGCONSTRUCTED, s1.YEARBUILDINGCONSTRUCTED, NULL, vw_risk.YEARBUILDINGCONSTRUCTED,
    REGEXP_SUBSTR(xml_risk.PAYLOAD,'<WhatYearWasTheBuildingConstructed>([^<]+)</WhatYearWasTheBuildingConstructed>',1,1,'e',1),
    CASE
        WHEN xml_risk.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_risk.PAYLOAD,'<WhatYearWasTheBuildingConstructed>([^<]+)</WhatYearWasTheBuildingConstructed>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_risk.YEARBUILDINGCONSTRUCTED IS NULL OR vw_risk.YEARBUILDINGCONSTRUCTED = '' THEN 'VIEW'
        WHEN s1.YEARBUILDINGCONSTRUCTED      IS NULL OR s1.YEARBUILDINGCONSTRUCTED      = '' THEN 'STEP1_Locationdetails_PER'
        WHEN pure.YEARBUILDINGCONSTRUCTED    IS NULL OR pure.YEARBUILDINGCONSTRUCTED    = '' THEN 'PURE'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN pure     ON pure.LEGACYPOLICYNUMBER     = pol.LEGACYPOLICYNUMBER
LEFT JOIN s1       ON s1.LEGACYPOLICYNUMBER       = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_risk  ON vw_risk.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_risk ON xml_risk.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 14,'RISK','{ROOFCONSTRUCTION_FINAL}',
    NULL, s1.ROOFCONST, NULL, vw_risk.ROOFCONSTRUCTION_FINAL,
    REGEXP_SUBSTR(xml_risk.PAYLOAD,'<RoofConstruction>([^<]+)</RoofConstruction>',1,1,'e',1),
    CASE
        WHEN xml_risk.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_risk.PAYLOAD,'<RoofConstruction>([^<]+)</RoofConstruction>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_risk.ROOFCONSTRUCTION_FINAL IS NULL OR vw_risk.ROOFCONSTRUCTION_FINAL = '' THEN 'VIEW'
        WHEN s1.ROOFCONST                   IS NULL OR s1.ROOFCONST                   = '' THEN 'STEP1_Locationdetails_PER'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s1       ON s1.LEGACYPOLICYNUMBER       = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_risk  ON vw_risk.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_risk ON xml_risk.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 14,'RISK','{MAINWALLCONSTRUCTION_FINAL}',
    NULL, s1.WALLCONST, NULL, vw_risk.MAINWALLCONSTRUCTION_FINAL,
    REGEXP_SUBSTR(xml_risk.PAYLOAD,'<MainWallConstruction>([^<]+)</MainWallConstruction>',1,1,'e',1),
    CASE
        WHEN xml_risk.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_risk.PAYLOAD,'<MainWallConstruction>([^<]+)</MainWallConstruction>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_risk.MAINWALLCONSTRUCTION_FINAL IS NULL OR vw_risk.MAINWALLCONSTRUCTION_FINAL = '' THEN 'VIEW'
        WHEN s1.WALLCONST                       IS NULL OR s1.WALLCONST                       = '' THEN 'STEP1_Locationdetails_PER'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s1       ON s1.LEGACYPOLICYNUMBER       = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_risk  ON vw_risk.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_risk ON xml_risk.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 14,'RISK','{FLOORCONSTRUCTION_FINAL}',
    NULL, s1.FLOORCONST, NULL, vw_risk.FLOORCONSTRUCTION_FINAL,
    REGEXP_SUBSTR(xml_risk.PAYLOAD,'<FloorConstruction>([^<]+)</FloorConstruction>',1,1,'e',1),
    CASE
        WHEN xml_risk.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_risk.PAYLOAD,'<FloorConstruction>([^<]+)</FloorConstruction>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_risk.FLOORCONSTRUCTION_FINAL IS NULL OR vw_risk.FLOORCONSTRUCTION_FINAL = '' THEN 'VIEW'
        WHEN s1.FLOORCONST                   IS NULL OR s1.FLOORCONST                   = '' THEN 'STEP1_Locationdetails_PER'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s1       ON s1.LEGACYPOLICYNUMBER       = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_risk  ON vw_risk.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_risk ON xml_risk.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 14,'RISK','{ALARMSYSTEMINSTALLED_FINAL}',
    NULL, s1.ALARMSYSTEM, NULL, vw_risk.ALARMSYSTEMINSTALLED_FINAL,
    REGEXP_SUBSTR(xml_risk.PAYLOAD,'<WhatTypeOfAlarmSystemIsInstalled>([^<]+)</WhatTypeOfAlarmSystemIsInstalled>',1,1,'e',1),
    CASE
        WHEN xml_risk.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_risk.PAYLOAD,'<WhatTypeOfAlarmSystemIsInstalled>([^<]+)</WhatTypeOfAlarmSystemIsInstalled>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_risk.ALARMSYSTEMINSTALLED_FINAL IS NULL OR vw_risk.ALARMSYSTEMINSTALLED_FINAL = '' THEN 'VIEW'
        WHEN s1.ALARMSYSTEM                     IS NULL OR s1.ALARMSYSTEM                     = '' THEN 'STEP1_Locationdetails_PER'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s1       ON s1.LEGACYPOLICYNUMBER       = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_risk  ON vw_risk.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_risk ON xml_risk.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 14,'RISK','{SECURITYDETAILS}',
    NULL, s1.SECURITYDETAILS, NULL, vw_risk.SECURITYDETAILS,
    REGEXP_SUBSTR(xml_risk.PAYLOAD,'<SecurityMeasures>([^<]+)</SecurityMeasures>',1,1,'e',1),
    CASE
        WHEN xml_risk.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_risk.PAYLOAD,'<SecurityMeasures>([^<]+)</SecurityMeasures>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_risk.SECURITYDETAILS IS NULL OR vw_risk.SECURITYDETAILS = '' THEN 'VIEW'
        WHEN s1.SECURITYDETAILS      IS NULL OR s1.SECURITYDETAILS      = '' THEN 'STEP1_Locationdetails_PER'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s1       ON s1.LEGACYPOLICYNUMBER       = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_risk  ON vw_risk.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_risk ON xml_risk.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT
    pol.LEGACYPOLICYNUMBER, 14,'RISK','{HOWOCCUPPIED}',
    NULL, s1.HOWOCCUP, NULL, vw_risk.HOWOCCUPPIED,
    REGEXP_SUBSTR(xml_risk.PAYLOAD,'<HomeBuildingOccupied>([^<]+)</HomeBuildingOccupied>',1,1,'e',1),
    CASE
        WHEN xml_risk.PAYLOAD IS NULL
          OR REGEXP_SUBSTR(xml_risk.PAYLOAD,'<HomeBuildingOccupied>([^<]+)</HomeBuildingOccupied>',1,1,'e',1) IS NULL THEN 'XML/TARGET'
        WHEN vw_risk.HOWOCCUPPIED IS NULL OR vw_risk.HOWOCCUPPIED = '' THEN 'VIEW'
        WHEN s1.HOWOCCUP          IS NULL OR s1.HOWOCCUP          = '' THEN 'STEP1_Locationdetails_PER'
        ELSE 'OK'
    END
FROM pol
LEFT JOIN s1       ON s1.LEGACYPOLICYNUMBER       = pol.LEGACYPOLICYNUMBER
LEFT JOIN vw_risk  ON vw_risk.LEGACYPOLICYNUMBER  = pol.LEGACYPOLICYNUMBER
LEFT JOIN xml_risk ON xml_risk.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

/*──────────────────────────────────────────────────────────────────────────
  SECTION D : ACCOUNT / POLICY TOKENS (final XML SP)
  Source chain: PER_FINAL (view) → PER_POLICY_MIGRATION_DCT (xml/REQUEST_XML)
  STEP1/STEP2/PURE not applicable — PER_FINAL is the terminal staging table
──────────────────────────────────────────────────────────────────────────*/
UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{CMLLEGALENTITY}',
    NULL, NULL, NULL, vw_final.CMLLEGALENTITY, xml_final.XML_CMLLEGALENTITY,
    CASE WHEN xml_final.XML_CMLLEGALENTITY IS NULL OR xml_final.XML_CMLLEGALENTITY = '' THEN 'XML/DCT'
         WHEN vw_final.CMLLEGALENTITY      IS NULL OR vw_final.CMLLEGALENTITY      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{CSL_LEGAL_ENTITY}',
    NULL, NULL, NULL, vw_final.CML_LEGAL_ENTITY, xml_final.XML_CSL_LEGAL_ENTITY,
    CASE WHEN xml_final.XML_CSL_LEGAL_ENTITY IS NULL OR xml_final.XML_CSL_LEGAL_ENTITY = '' THEN 'XML/DCT'
         WHEN vw_final.CML_LEGAL_ENTITY      IS NULL OR vw_final.CML_LEGAL_ENTITY      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{CMLNUMBER}',
    NULL, NULL, NULL, vw_final.CMLNUMBER, xml_final.XML_CMLNUMBER,
    CASE WHEN xml_final.XML_CMLNUMBER IS NULL OR xml_final.XML_CMLNUMBER = '' THEN 'XML/DCT'
         WHEN vw_final.CMLNUMBER      IS NULL OR vw_final.CMLNUMBER      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{CSLNUMBER}',
    NULL, NULL, NULL, vw_final.CSLNUMBER, xml_final.XML_CSLNUMBER,
    CASE WHEN xml_final.XML_CSLNUMBER IS NULL OR xml_final.XML_CSLNUMBER = '' THEN 'XML/DCT'
         WHEN vw_final.CSLNUMBER      IS NULL OR vw_final.CSLNUMBER      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{ABN_NZBN}',
    NULL, NULL, NULL, vw_final.ABN_NZBN, xml_final.XML_ABN_NZBN,
    CASE WHEN xml_final.XML_ABN_NZBN IS NULL OR xml_final.XML_ABN_NZBN = '' THEN 'XML/DCT'
         WHEN vw_final.ABN_NZBN      IS NULL OR vw_final.ABN_NZBN      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{PRIMARYRATINGSTATE}',
    NULL, NULL, NULL, vw_final.PRIMARYRATINGSTATE, xml_final.XML_PRIMARYRATINGSTATE,
    CASE WHEN xml_final.XML_PRIMARYRATINGSTATE IS NULL OR xml_final.XML_PRIMARYRATINGSTATE = '' THEN 'XML/DCT'
         WHEN vw_final.PRIMARYRATINGSTATE      IS NULL OR vw_final.PRIMARYRATINGSTATE      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{PAYMENT_METHOD}',
    NULL, NULL, NULL, vw_final.PAYMENT_METHOD, xml_final.XML_PAYMENT_METHOD,
    CASE WHEN xml_final.XML_PAYMENT_METHOD IS NULL OR xml_final.XML_PAYMENT_METHOD = '' THEN 'XML/DCT'
         WHEN vw_final.PAYMENT_METHOD      IS NULL OR vw_final.PAYMENT_METHOD      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{PHONE}',
    NULL, NULL, NULL, vw_final.PHONE, xml_final.XML_PHONE,
    CASE WHEN xml_final.XML_PHONE IS NULL OR xml_final.XML_PHONE = '' THEN 'XML/DCT'
         WHEN vw_final.PHONE      IS NULL OR vw_final.PHONE      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{EMAIL}',
    NULL, NULL, NULL, vw_final.EMAIL, xml_final.XML_EMAIL,
    CASE WHEN xml_final.XML_EMAIL IS NULL OR xml_final.XML_EMAIL = '' THEN 'XML/DCT'
         WHEN vw_final.EMAIL      IS NULL OR vw_final.EMAIL      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{MAINCONTACT}',
    NULL, NULL, NULL, vw_final.MAINCONTACT, xml_final.XML_MAINCONTACT,
    CASE WHEN xml_final.XML_MAINCONTACT IS NULL OR xml_final.XML_MAINCONTACT = '' THEN 'XML/DCT'
         WHEN vw_final.MAINCONTACT      IS NULL OR vw_final.MAINCONTACT      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{CSL_REGION}',
    NULL, NULL, NULL, vw_final.CSL_REGION, xml_final.XML_CSL_REGION,
    CASE WHEN xml_final.XML_CSL_REGION IS NULL OR xml_final.XML_CSL_REGION = '' THEN 'XML/DCT'
         WHEN vw_final.CSL_REGION      IS NULL OR vw_final.CSL_REGION      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

UNION ALL SELECT pol.LEGACYPOLICYNUMBER, 99,'ACCOUNT','{STANDARD_INDUSTRY_CODE}',
    NULL, NULL, NULL, vw_final.STANDARD_INDUSTRY_CODE, xml_final.XML_STANDARD_INDUSTRY_CODE,
    CASE WHEN xml_final.XML_STANDARD_INDUSTRY_CODE IS NULL OR xml_final.XML_STANDARD_INDUSTRY_CODE = '' THEN 'XML/DCT'
         WHEN vw_final.STANDARD_INDUSTRY_CODE      IS NULL OR vw_final.STANDARD_INDUSTRY_CODE      = '' THEN 'VIEW_PER_FINAL'
         ELSE 'OK' END
FROM pol LEFT JOIN vw_final ON vw_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER
         LEFT JOIN xml_final ON xml_final.LEGACYPOLICYNUMBER = pol.LEGACYPOLICYNUMBER

ORDER BY
    LEGACYPOLICYNUMBER,
    CONFIG_SEQ,
    COVERAGE_TYPE,
    TOKEN
;

/*══════════════════════════════════════════════════════════════════════════════
  USEFUL QUICK-FILTER VARIANTS

  1. Gaps only (tokens where value is dropped somewhere):
       WHERE GAP_LAYER NOT IN ('OK') AND GAP_LAYER NOT LIKE 'OK%'

  2. P1 bug tokens (the 5 excess cols missing from view):
       WHERE TOKEN IN ('{STANDARDEXCESS}','{IMPOSEDEXCESS}','{EARTHQUAKEEXCESS}',
                       '{FLOODEXCESS}','{FLOODDAMAGE}')

  3. Single policy test run:
       Replace pol CTE with:   pol AS (SELECT 'PP123456' AS LEGACYPOLICYNUMBER)

  4. Summary — gap count by token across all policies:
       SELECT TOKEN, COVERAGE_TYPE, CONFIG_SEQ, GAP_LAYER, COUNT(*) AS POLICY_COUNT
       FROM (<this full query>)
       WHERE GAP_LAYER NOT LIKE 'OK%'
       GROUP BY TOKEN, COVERAGE_TYPE, CONFIG_SEQ, GAP_LAYER
       ORDER BY POLICY_COUNT DESC, CONFIG_SEQ, TOKEN

  5. PURE column name errors — if query fails on "pure" CTE:
       Run:  SELECT * FROM PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents LIMIT 1
       to see actual column names and update the pure CTE accordingly.
══════════════════════════════════════════════════════════════════════════════*/
