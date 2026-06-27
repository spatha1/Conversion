-- ============================================================
-- Floor Construction — Source-to-DCT Mapping Table
-- PRD_T5 source: HCfloorConstruction in
--   PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents
--   (loaded as FLOORCONST numeric code + FLOORCONSTRUCTION string
--    into AGGNE.DEV.LOCATIONDETAILS_PER by the ETL)
-- ============================================================
-- CLIENT OUTREACH REQUIRED:
--   ~991 rows have FLOORCONST IS NULL (HCfloorConstruction was NULL in Pure).
--   PP PL101 has no default for Floor Construction.
--   Business must decide the default before conversion can proceed.
-- ============================================================

SELECT
    'HCfloorConstruction'                              AS PRD_T5_FIELD,
    'PER_HomeContents'                                 AS PRD_T5_TABLE,
    L.FLOORCONST                                       AS SOURCE_CODE,
    COALESCE(L.FLOORCONSTRUCTION, '(NULL / not set)') AS SOURCE_VALUE,

    CASE
        WHEN L.FLOORCONSTRUCTION IS NULL                          THEN NULL
        WHEN L.FLOORCONSTRUCTION = 'Concrete'                    THEN 'Concrete'
        WHEN L.FLOORCONSTRUCTION = 'Other'                       THEN 'Other'
        WHEN L.FLOORCONSTRUCTION ILIKE 'Wood - Concrete Footings' THEN 'WoodConcreteFootings'
        WHEN L.FLOORCONSTRUCTION ILIKE 'Wood - Stilts'           THEN 'WoodStilts'
        WHEN L.FLOORCONSTRUCTION ILIKE 'Wood - Stumps'           THEN 'WoodStumps'
        ELSE L.FLOORCONSTRUCTION
    END AS DCT_VALUE,

    CASE
        WHEN L.FLOORCONSTRUCTION IS NULL
            THEN 'GAP — NULL in Pure; no PP PL101 default exists; CLIENT DECISION REQUIRED'
        WHEN L.FLOORCONSTRUCTION = 'Concrete'                    THEN 'Mapped'
        WHEN L.FLOORCONSTRUCTION = 'Other'                       THEN 'Mapped'
        WHEN L.FLOORCONSTRUCTION ILIKE 'Wood - Concrete Footings' THEN 'Mapped'
        WHEN L.FLOORCONSTRUCTION ILIKE 'Wood - Stilts'           THEN 'Mapped'
        WHEN L.FLOORCONSTRUCTION ILIKE 'Wood - Stumps'           THEN 'Mapped'
        ELSE 'GAP — no matching PP PL101 option; client to confirm correct enum'
    END AS COMMENT,

    COUNT(*)                                           AS POLICY_ROWS

FROM AGGNE.DEV.LOCATIONDETAILS_PER L
GROUP BY
    L.FLOORCONST,
    L.FLOORCONSTRUCTION
ORDER BY
    L.FLOORCONST NULLS LAST;
