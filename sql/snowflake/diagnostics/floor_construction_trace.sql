-- ============================================================
-- Floor Construction trace — Pure source → staging → DCT target
-- Replace the policy number in the WHERE clause to look up any policy
-- ============================================================
--
-- Stage 1  LOCATIONDETAILS_PER   : raw numeric code loaded from Pure snapshot
-- Stage 2  PER_RISK_BUILDING_FINAL : mapped to DCT enum string
-- Stage 3  PER_RISK_BUILDING_TARGET: final XML payload sent to DCT
--
-- FLOORCONST numeric → string mapping (from staging):
--   1 = Concrete
--   2 = Other
--   3 = Wood - Concrete Footings  →  DCT: WoodConcreteFootings
--   4 = Wood - Stumps             →  DCT: WoodStumps
--   5 = Wood - Stilts             →  DCT: WoodStilts
--   NULL = not set in Pure (no default in PL101)
-- ============================================================

SELECT
    TRIM(L.PUREPOLICYNUMBER)          AS POLICY_NUMBER,
    L.EXPIRINGID_P,
    L.RISKNUMBER,

    -- Stage 1: Pure source (numeric code)
    L.FLOORCONST                      AS PURE_CODE,
    L.FLOORCONSTRUCTION               AS PURE_STRING,

    -- Stage 2: DCT enum after conversion mapping
    F.FLOORCONSTRUCTION_FINAL         AS DCT_ENUM,

    -- Stage 3: Value inside the XML payload written to target
    REGEXP_SUBSTR(
        T.PAYLOAD,
        '<FloorConstruction>([^<]*)</FloorConstruction>',
        1, 1, 'e'
    )                                 AS XML_VALUE

FROM AGGNE.DEV.LOCATIONDETAILS_PER L

LEFT JOIN AGGNE.DEV.PER_RISK_BUILDING_FINAL F
    ON  TRIM(L.PUREPOLICYNUMBER) = SPLIT_PART(F.PUREPOLICYNUMBER, '|', 1)
    AND L.EXPIRINGID_P           = TRY_TO_NUMBER(SPLIT_PART(F.PUREPOLICYNUMBER, '|', 3))

LEFT JOIN AGGNE.DEV.PER_RISK_BUILDING_TARGET T
    ON  T.ID       = F.PUREPOLICYNUMBER
    AND T.ITR_TYPE = 'RISK_Building'

WHERE TRIM(L.PUREPOLICYNUMBER) = 'P00002676'   -- ← change policy number here

ORDER BY L.RISKNUMBER;
