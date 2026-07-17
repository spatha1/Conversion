-- ============================================================
-- ATP-10963 — Redbook vehicles: Year/Make/Model gap analysis
-- Scope : policies in the current UAT batch (AGGNE.UAT.PER_POLICY_MIGRATION_DCT)
--
-- ROOT CAUSE (confirmed 2026-07-06):
--   Raw Pure extract PM_01 HAS Year/Make/Model for all Redbook vehicles.
--   The conversion Pure-to-Write SP blanks them when MVRBVehicleKey is present:
--     CASE WHEN MVRBVehicleKey <> '' THEN '' ELSE Make  END AS Make
--     CASE WHEN MVRBVehicleKey <> '' THEN '' ELSE Model END AS Model
--     CASE WHEN MVRBVehicleKey <> '' THEN 0  ELSE Year  END AS Year
--     (same for EngineSize, GrossVehicleMass)
--   Old SAS assumption: DCT resolves details from the Redbook key.
--   Policy team confirmed DCT uses the key for MARKET VALUE only.
--   Same bug family as ATP-10466/10497/10507 (fixed on the attach side).
-- ============================================================

-- ── 1. Vehicle-level gap: PM_01 (raw Pure) vs PM_03 (staged) ──
SELECT
    TRIM(P3.PUREPOLICYNUMBER)                  AS LEGACY_POLICY_NUMBER,
    F.EFFECTIVEDATE                            AS POLICY_EFFECTIVE_DATE,
    P3.REGISTRATIONNUMBER,
    P3.MVRBVEHICLEKEY                          AS REDBOOK_KEY,
    P1.YEAR                                    AS YEAR_IN_PURE,
    P1.MAKE                                    AS MAKE_IN_PURE,
    P1.MODEL                                   AS MODEL_IN_PURE,
    P3.YEAR                                    AS YEAR_AFTER_STAGING,
    P3.MAKE                                    AS MAKE_AFTER_STAGING,
    P3.MODEL                                   AS MODEL_AFTER_STAGING
FROM  AGGNE.DEV.PM_03 P3
JOIN  AGGNE.DEV.PM_01 P1
      ON  TRIM(P1.PUREPOLICYNUMBER) = TRIM(P3.PUREPOLICYNUMBER)
      AND TRIM(P1.EXPIRINGID_P)     = TRIM(P3.EXPIRINGID_P)
      AND P1.VEHICLEID              = P3.VEHICLEID
LEFT JOIN AGGNE.UAT.PER_FINAL F
      ON  TRIM(F.LEGACYPOLICYNUMBER) = TRIM(P3.PUREPOLICYNUMBER)
WHERE TRIM(P3.PUREPOLICYNUMBER) IN (
        SELECT DISTINCT TRIM(LEGACYPOLICYNUMBER)
        FROM   AGGNE.UAT.PER_POLICY_MIGRATION_DCT )
  AND TRIM(COALESCE(P3.MVRBVEHICLEKEY,'')) <> ''            -- Redbook key present
  AND NOT (P3.YEAR <> 0 AND P3.MAKE <> '' AND P3.MODEL <> '') -- YMM blanked in staging
ORDER BY LEGACY_POLICY_NUMBER, P3.REGISTRATIONNUMBER;

-- ── 2. Policy-level summary with effective date ─────────────
SELECT
    TRIM(P3.PUREPOLICYNUMBER)                  AS LEGACY_POLICY_NUMBER,
    MAX(F.EFFECTIVEDATE)                       AS POLICY_EFFECTIVE_DATE,
    COUNT(*)                                   AS AFFECTED_VEHICLES
FROM  AGGNE.DEV.PM_03 P3
LEFT JOIN AGGNE.UAT.PER_FINAL F
      ON  TRIM(F.LEGACYPOLICYNUMBER) = TRIM(P3.PUREPOLICYNUMBER)
WHERE TRIM(P3.PUREPOLICYNUMBER) IN (
        SELECT DISTINCT TRIM(LEGACYPOLICYNUMBER)
        FROM   AGGNE.UAT.PER_POLICY_MIGRATION_DCT )
  AND TRIM(COALESCE(P3.MVRBVEHICLEKEY,'')) <> ''
  AND NOT (P3.YEAR <> 0 AND P3.MAKE <> '' AND P3.MODEL <> '')
GROUP BY 1
ORDER BY 2, 1;
