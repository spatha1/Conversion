-- ==========================================================================
-- FNOL Bug: Vehicle Model field exceeds 30-character claims app limit
-- Claim    : C261000875   Policy: P00025578   DOL: 03-07-2026
-- Error    : VehicleItemAndPolicyCoveragesDTO.VehicleItem_ItemVehicleDetail
--            .ItemVehicle_ModelMaker — Character limit has been exceeded
--
-- Root cause:
--   Pure source data (CBP_VEHICLEDETAIL.CMCVModel / PER_VEHICLEDETAIL.MVCVModel)
--   contains vehicle model values that exceed 30 characters.
--   The conversion/attach SP passes these values as-is — correct behaviour.
--   The DCT claims app (OOB) enforces a hard 30-char limit on this field.
--   Fix owner: DCT team to extend OOB field limit, OR data team to shorten
--              model values at source in Pure before re-attach.
--
-- Scope (Pure source, all policy history):
--   BP: 244 policies, vehicles with model > 30 chars, max 84 chars
--   PP:  62 policies, vehicles with model > 30 chars, max 53 chars
-- ==========================================================================

-- *** PLACEHOLDERS — adjust before running ***
-- :from_date  — minimum policy expiry date filter  e.g. DATEADD('year', -2, CURRENT_DATE())
-- :to_date    — maximum policy expiry date filter  e.g. CURRENT_DATE()  (NULL = no upper limit)
-- :policy_no  — specific policy number for Q6/Q7   e.g. 'P00025578'
-- Set :inforce_only = TRUE to restrict to in-force policies only (expiry >= today)

SET from_date    = DATEADD('year', -2, CURRENT_DATE());   -- policies expired within 2 years
SET to_date      = NULL;                                  -- no upper expiry limit
SET inforce_only = FALSE;                                 -- FALSE = include expired ≤ 2yr
SET policy_no    = 'P00025578';


-- --------------------------------------------------------------------------
-- QUERY 1: BP — All vehicles where CMCVModel > 30 chars (Pure source)
-- --------------------------------------------------------------------------
SELECT
    pb.PUREPolicyNumber                     AS POLICY_NUMBER,
    pb.PUREExpiryDate                       AS EXPIRY_DATE,
    CASE WHEN pb.PUREExpiryDate >= CURRENT_DATE() THEN 'IN-FORCE' ELSE 'EXPIRED' END AS POLICY_STATUS,
    vd.CMCVRegNo                            AS REGO,
    vd.CMCVMake                             AS MAKE,
    vd.CMCVModel                            AS MODEL_FULL,
    LEN(vd.CMCVModel)                       AS MODEL_LEN
FROM AGGNE.PRD.policyattach_bp pb
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL vd
    ON pb.ExpiringID_P = vd.CBP_Policy_Binder_id
WHERE LEN(vd.CMCVModel) > 30
  AND pb.PUREExpiryDate >= $from_date          -- date filter placeholder
ORDER BY MODEL_LEN DESC, POLICY_NUMBER;


-- --------------------------------------------------------------------------
-- QUERY 2: BP — Policy-level summary (count of affected vehicles per policy)
-- --------------------------------------------------------------------------
SELECT
    pb.PUREPolicyNumber                          AS POLICY_NUMBER,
    MAX(pb.PUREExpiryDate)                       AS EXPIRY_DATE,
    CASE WHEN MAX(pb.PUREExpiryDate) >= CURRENT_DATE() THEN 'IN-FORCE' ELSE 'EXPIRED' END AS POLICY_STATUS,
    COUNT(DISTINCT vd.CMCVRegNo)                 AS VEHICLES_OVER_30_CHARS,
    MAX(LEN(vd.CMCVModel))                       AS MAX_MODEL_LEN,
    LISTAGG(DISTINCT vd.CMCVModel, ' | ')
        WITHIN GROUP (ORDER BY vd.CMCVModel)     AS AFFECTED_MODELS
FROM AGGNE.PRD.policyattach_bp pb
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL vd
    ON pb.ExpiringID_P = vd.CBP_Policy_Binder_id
WHERE LEN(vd.CMCVModel) > 30
  AND pb.PUREExpiryDate >= $from_date
GROUP BY pb.PUREPolicyNumber
ORDER BY VEHICLES_OVER_30_CHARS DESC, POLICY_NUMBER;


-- --------------------------------------------------------------------------
-- QUERY 3: PP MV — All vehicles where MVCVModel > 30 chars (Pure source)
-- --------------------------------------------------------------------------
SELECT
    pb.PUREPolicyNumber                     AS POLICY_NUMBER,
    pb.PUREExpiryDate                       AS EXPIRY_DATE,
    CASE WHEN pb.PUREExpiryDate >= CURRENT_DATE() THEN 'IN-FORCE' ELSE 'EXPIRED' END AS POLICY_STATUS,
    vd.MVCVRegNo                            AS REGO,
    vd.MVCVMake                             AS MAKE,
    vd.MVCVModel                            AS MODEL_FULL,
    LEN(vd.MVCVModel)                       AS MODEL_LEN
FROM AGGNE.PRD.policyattach_per pb
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL vd
    ON pb.ExpiringID_P = vd.PER_Policy_Binder_id
WHERE LEN(vd.MVCVModel) > 30
  AND pb.PUREExpiryDate >= $from_date
ORDER BY MODEL_LEN DESC, POLICY_NUMBER;


-- --------------------------------------------------------------------------
-- QUERY 4: Combined BP + PP summary (all policy history, no date filter)
-- --------------------------------------------------------------------------
WITH bp_affected AS (
    SELECT DISTINCT pb.PUREPolicyNumber AS POLICY_NUMBER, 'BP' AS LOB,
           pb.PUREExpiryDate,
           vd.CMCVModel AS MODEL, LEN(vd.CMCVModel) AS MODEL_LEN
    FROM AGGNE.PRD.policyattach_bp pb
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL vd
        ON pb.ExpiringID_P = vd.CBP_Policy_Binder_id
    WHERE LEN(vd.CMCVModel) > 30
),
pp_affected AS (
    SELECT DISTINCT pb.PUREPolicyNumber AS POLICY_NUMBER, 'PP' AS LOB,
           pb.PUREExpiryDate,
           vd.MVCVModel AS MODEL, LEN(vd.MVCVModel) AS MODEL_LEN
    FROM AGGNE.PRD.policyattach_per pb
    LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_VEHICLEDETAIL vd
        ON pb.ExpiringID_P = vd.PER_Policy_Binder_id
    WHERE LEN(vd.MVCVModel) > 30
),
all_affected AS (SELECT * FROM bp_affected UNION ALL SELECT * FROM pp_affected)
SELECT
    LOB,
    COUNT(DISTINCT POLICY_NUMBER)                                          AS TOTAL_POLICIES,
    SUM(CASE WHEN PUREExpiryDate >= CURRENT_DATE() THEN 1 ELSE 0 END)     AS INFORCE_POLICIES,
    SUM(CASE WHEN PUREExpiryDate <  CURRENT_DATE()
              AND PUREExpiryDate >= DATEADD('year',-2,CURRENT_DATE()) THEN 1 ELSE 0 END) AS EXPIRED_LE2YR,
    COUNT(*)                                                               AS TOTAL_VEHICLE_RECORDS,
    MAX(MODEL_LEN)                                                         AS MAX_CHARS,
    MIN(MODEL_LEN)                                                         AS MIN_CHARS_OVER_30
FROM all_affected
GROUP BY LOB
ORDER BY LOB;


-- --------------------------------------------------------------------------
-- QUERY 5: API response — check POLICY_ATTACH_TABLE XML for Model > 30 chars
-- Note: REGEXP_EXTRACT_ALL returns full tag e.g. <Model>Foo</Model>.
--       Subtract 15 chars overhead (<Model> = 7, </Model> = 8) to get true
--       model length. Threshold is therefore > 45 (30 + 15).
-- --------------------------------------------------------------------------
WITH latest_xml AS (
    SELECT POLICY_NUMBER, POLICY_ATTACH_XML, LOAD_TS,
           ROW_NUMBER() OVER (PARTITION BY POLICY_NUMBER ORDER BY LOAD_TS DESC) AS RNO
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
),
model_extract AS (
    SELECT
        lx.POLICY_NUMBER,
        lx.LOAD_TS,
        f.value::STRING                                          AS MODEL_TAG,
        REGEXP_SUBSTR(f.value::STRING, '<Model>([^<]+)</Model>', 1, 1, 'e', 1)
                                                                 AS MODEL_VALUE,
        LEN(REGEXP_SUBSTR(f.value::STRING, '<Model>([^<]+)</Model>', 1, 1, 'e', 1))
                                                                 AS MODEL_LEN
    FROM latest_xml lx,
    LATERAL FLATTEN(
        input => REGEXP_EXTRACT_ALL(lx.POLICY_ATTACH_XML, '<Model>[^<]+</Model>')
    ) f
    WHERE lx.RNO = 1
)
SELECT
    POLICY_NUMBER,
    MODEL_VALUE,
    MODEL_LEN,
    LOAD_TS
FROM model_extract
WHERE MODEL_LEN > 30
ORDER BY MODEL_LEN DESC, POLICY_NUMBER;


-- --------------------------------------------------------------------------
-- QUERY 6: Specific policy (Pure source) — replace $policy_no placeholder
-- --------------------------------------------------------------------------
SELECT
    pb.PUREPolicyNumber                                                    AS POLICY_NUMBER,
    vd.CMCVRegNo                                                           AS REGO,
    vd.CMCVMake                                                            AS MAKE,
    vd.CMCVModel                                                           AS MODEL_FULL,
    LEN(vd.CMCVModel)                                                      AS MODEL_LEN,
    CASE WHEN LEN(vd.CMCVModel) > 30 THEN 'EXCEEDS_30_CHAR' ELSE 'OK' END AS STATUS
FROM AGGNE.PRD.policyattach_bp pb
LEFT JOIN PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.CBP_VEHICLEDETAIL vd
    ON pb.ExpiringID_P = vd.CBP_Policy_Binder_id
WHERE pb.PUREPolicyNumber = $policy_no
ORDER BY MODEL_LEN DESC;


-- --------------------------------------------------------------------------
-- QUERY 7: Specific policy (API XML) — replace $policy_no placeholder
-- --------------------------------------------------------------------------
WITH latest_xml AS (
    SELECT POLICY_ATTACH_XML, LOAD_TS
    FROM AGGNE.PRD.POLICY_ATTACH_TABLE
    WHERE POLICY_NUMBER = $policy_no
    ORDER BY LOAD_TS DESC
    LIMIT 1
)
SELECT
    REGEXP_SUBSTR(f.value::STRING, '<Model>([^<]+)</Model>', 1, 1, 'e', 1) AS MODEL_IN_XML,
    LEN(REGEXP_SUBSTR(f.value::STRING, '<Model>([^<]+)</Model>', 1, 1, 'e', 1)) AS MODEL_LEN,
    CASE WHEN LEN(REGEXP_SUBSTR(f.value::STRING, '<Model>([^<]+)</Model>', 1, 1, 'e', 1)) > 30
         THEN 'EXCEEDS_30_CHAR' ELSE 'OK' END                              AS STATUS,
    lx.LOAD_TS
FROM latest_xml lx,
LATERAL FLATTEN(
    input => REGEXP_EXTRACT_ALL(lx.POLICY_ATTACH_XML, '<Model>[^<]+</Model>')
) f
ORDER BY MODEL_LEN DESC;
