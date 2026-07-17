-- ============================================================
-- PP Conversion — client question queries, all in one place
-- Originally 18 items (16 original + G-40, G-45 added 2026-07-09). Now 10 — 8 items removed
-- 2026-07-09 (see docs/pp_mapping/GAP_CATEGORIZATION.md and VALIDATION_RULES.md for the full
-- reasoning per gap). Removed as NOT genuine client questions right now:
--   - "10. State" (G-01) — fixable ourselves, no business decision needed (DCT has no NZ option,
--     Country already carries it).
--   - "11. HB Excess Breakdown" (G-23) / "13. Risk-Level Excess Breakdown" (G-34) — likely
--     DCT-readOnly fields (8/8 other coverage types confirmed readOnly in CoverageLibrary), though
--     NOT directly confirmed for Personal Home Building — removed on balance of evidence, not proof.
--   - "15. Risk-Assessment Answers" (6 fields, G-35) — 5/6 hardcoded values match their own
--     manuscript-declared DCT default exactly; very likely a deliberate "no PURE source, use DCT's
--     default" choice, not a bug.
--   - "5. UW Adjustments (one-off)", "6. Premium (Home)", "9. HB UW Adjustments", "12. Glass Limit"
--     — no DCT validation error on quote creation, no client-reported ticket behind any of them.
--     Per standing rule: hold these until an actual client bug surfaces, don't chase them
--     speculatively. (Note: #6 mirrors the SAME zero-premium pattern as G-42/Motor, which IS a
--     confirmed bug from live-payload inspection — worth reopening #6 if G-42 gets escalated.)
-- Kept — both trace to an actual client-reported ticket, not just our own internal finding:
--   - "17. HC Specified Items Away From the Premises" (G-40) -> ATP-11107
--   - "18. Legacy Start Date" (G-45) -> ATP-10962
--
-- Each block returns the same 8 columns so results can be read/exported consistently:
--   FIELD | PATH | DCT_VALUES | PURE_VALUE | DCT_VALUE_SENT | MAPPED | IMPACTED_COUNT | QUESTION
--
-- Read-only against AGGNE.DEV. Run the whole thing as one UNION ALL, or lift any single block out.
-- Numbers will reflect TODAY's data — a re-run after a new batch may not exactly match the counts
-- quoted in the emails, which were captured on their original validation date. That's expected;
-- re-verify against live data per the project's standing rule, don't assume the old count still holds.
-- ============================================================

-- 1. Body Type
-- CORRECTED after checking the view's actual CASE logic (PER_COM_PAYLOAD.sql line ~182): the view
-- ALREADY maps source 'Cab Chassis' -> 'CabChassis' (no space) — that mapping isn't missing. The
-- real problem is 'CabChassis' still isn't one of DCT's 17 valid codes below, so it's a wrong-target
-- question, not an unmapped-source question. Separately, the CASE has no branch for 'Other' at all,
-- so it silently falls to the ELSE '' branch and becomes indistinguishable from genuinely-blank
-- source data — PURE_VALUE '(blank)' below is a mix of both; can't be split apart without joining
-- back to PM_03 (the source), which the "5. Motor Coverage Selections"-style detail query below would need.
SELECT 'Body Type' AS FIELD, 'risk/BodyType' AS PATH,
       'Bus, Convertible, Coupe, Hatchback, PrimeMover, Sedan, Utility, Van, Wagon, TowTruck, Transporter, MobilePlant, Motorcycle, Trailer, CamperVan, Caravan, Forklift' AS DCT_VALUES,
       COALESCE(NULLIF(TRIM(BODYTYPE),''),'(blank — includes both genuinely-blank source AND ''Other'', which the view''s CASE also blanks)') AS PURE_VALUE,
       COALESCE(NULLIF(TRIM(BODYTYPE),''),'(blank — includes both genuinely-blank source AND ''Other'', which the view''s CASE also blanks)') AS DCT_VALUE_SENT,
       'No' AS MAPPED, COUNT(*) AS IMPACTED_COUNT,
       'The view already maps "Cab Chassis" -> "CabChassis", but "CabChassis" still is not one of DCT''s 17 valid codes — what should it map to instead? Separately, "Other" has no mapping at all and silently becomes blank — what should it map to?' AS QUESTION
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE BODYTYPE NOT IN ('Bus','Convertible','Coupe','Hatchback','PrimeMover','Sedan','Utility','Van','Wagon',
                        'TowTruck','Transporter','MobilePlant','Motorcycle','Trailer','CamperVan','Caravan','Forklift')
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 2. Number of Cylinders
SELECT 'Number of Cylinders', 'risk/NumberOfCylinders', '1-16',
       COALESCE(NULLIF(TRIM(NUMBEROFCYLINDERS),''),'(blank)'), COALESCE(NULLIF(TRIM(NUMBEROFCYLINDERS),''),'(blank)'),
       'No', COUNT(*),
       'Should this field be left blank for engine-less vehicles, or is a different value expected?'
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE TRY_TO_NUMBER(NUMBEROFCYLINDERS) NOT BETWEEN 1 AND 16 OR NUMBEROFCYLINDERS IS NULL
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 3. Voluntary Excess (Motor)
SELECT 'Voluntary Excess', 'risk/VoluntaryExcess', '0, 250, 500, 750, 1000, 1250, 1500',
       VOLUNTARYEXCESS, VOLUNTARYEXCESS, 'No', COUNT(*),
       'What should an excess above $1,000 be mapped to?'
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE VOLUNTARYEXCESS NOT IN ('0','250','500','750','1000','1250','1500')
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 4. Age of Youngest Regular Driver
SELECT 'Age of Youngest Regular Driver', 'risk/AgeOfYoungestRegularDriver', '17-99',
       COALESCE(NULLIF(TRIM(AGEOFYOUNGESTREGULARDRIVER),''),'(blank)'), COALESCE(NULLIF(TRIM(AGEOFYOUNGESTREGULARDRIVER),''),'(blank)'),
       'No', COUNT(*),
       'Is 16 or 17 the correct minimum age for this field?'
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE COALESCE(TRIM(AGEOFYOUNGESTREGULARDRIVER),'')='' OR TRY_TO_NUMBER(AGEOFYOUNGESTREGULARDRIVER) < 17
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 7. Motor Clause Codes — legacy CM_* codes not recognized
-- DCT_VALUES lists the 10 PM_* codes confirmed valid in the manuscript check (seq17_vq.sql G-38) —
-- this is what was actually confirmed, not necessarily DCT's complete PM_* list, so it's narrower
-- than a normal dropdown enumeration (unlike Body Type's 17, which is the full accepted set).
SELECT 'Motor Clause Codes', 'Clauses/ClausesSelection',
       'PMAVCaravancontents, PMMVCaravancontents, PMLearnerextension, PMAdditionalbenefit4increase, PMAdditionalbenefit7increase, PMAdditionalbenefit11increase, PMAdditionalbenefit12increase, PMGeneralexclusionproperty, PMGeneralexclusionliability, PMGeneralextension',
       DCCLAUSETYPE, DCCLAUSETYPE, 'No', COUNT(*),
       'Please confirm (or correct) the likely current-code pairing for this legacy code.'
FROM AGGNE.DEV.COM_CLAUSE
WHERE DCCLAUSETYPE LIKE 'CM_%' OR DCCLAUSETYPE LIKE 'FV%'
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 8. Landlords Protections Indicator
-- IMPORTANT correction found while removing hardcoded text: there are TWO different Landlords
-- representations in the live payload. The RISK_Building_HB coverage node has its own
-- <LandlordProtections> tag, which ALREADY VARIES CORRECTLY (67 Taken / 1,250 Not Taken / 514
-- blank, confirmed live) — this is NOT the always-broken field the original finding described.
-- The actual broken one is the separate Building_SubCov sub-coverage block (CODE=HBLLB_SD), whose
-- <Indicator> is hardcoded 1 regardless of occupancy — that's what this row measures.
SELECT 'Landlords Protections Indicator (Building_SubCov HBLLB_SD block — NOT the working RISK_Building_HB.LandlordProtections tag)',
       'coverage/Indicator (Building_SubCov, CODE=HBLLB_SD)', '1, 0',
       T2.HOWOCCUPPIED, REGEXP_SUBSTR(T1.PAYLOAD, '<Indicator>(.*?)</Indicator>', 1, 1, 'e'),
       'No', COUNT(*),
       'RISK_Building_HB already has a working LandlordProtections tag (Taken/Not Taken/blank) — is this separate HBLLB_SD sub-coverage block redundant and safe to drop, or does DCT actually read this one?'
FROM AGGNE.DEV.PER_BUILDING_TARGET T1
JOIN AGGNE.DEV.PER_RISK_BUILDING_FINAL T2 ON T1.ID = T2.PUREPOLICYNUMBER
WHERE T1.ITR_TYPE = 'Building_SubCov' AND T1.PAYLOAD ILIKE '%HBLLB_SD%' AND T2.HOWOCCUPPIED ILIKE '%owner%'
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 14. SIC Code — live-extracted, not typed from memory: every row currently carries the literal
-- text below verbatim (confirmed identical across all 1,392 risk nodes when grouped).
SELECT 'SIC Code', 'risk/SICCode', 'N/A (free text)',
       REGEXP_SUBSTR(PAYLOAD, '<SICCode>(.*?)</SICCode>', 1, 1, 'e') AS PURE_VALUE,
       REGEXP_SUBSTR(PAYLOAD, '<SICCode>(.*?)</SICCode>', 1, 1, 'e') AS DCT_VALUE_SENT,
       'No', COUNT(*),
       'Should this be blank, or is a specific value expected for personal policies?'
FROM AGGNE.DEV.PER_RISK_BUILDING_TARGET
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 16. Motor Coverage Selections — live-extracted from PER_COM_COVERAGES_TARGET (ITR_TYPE='Risk_CM',
-- the actual Motor sub-coverage payload), joined to PROTECTIONTYPE via composite policy key, instead
-- of a typed description of which codes are "wrong". DCT_VALUES/PATH use the real DCT codes
-- (CMP_SD/PCH_SD/FTL_SD/LIA_SD/COR_SD/TFT_SD/TPO_SD/ULG_SD) confirmed live from the payload's <Type>
-- tags, not the friendly names typed from memory.
SELECT 'Motor Coverage Selections — ThirdPartyOnly policies', 'coverage/Indicator (Risk_CM: CMP_SD/PCH_SD/COR_SD/ULG_SD)',
       'CMP_SD, PCH_SD, FTL_SD, LIA_SD, COR_SD, TFT_SD, TPO_SD, ULG_SD',
       'ThirdPartyOnly' AS PURE_VALUE,
       REGEXP_SUBSTR(T1.PAYLOAD, '<Type>(.*?)</Type>', 1, 1, 'e') || '=' || REGEXP_SUBSTR(T1.PAYLOAD, '<Indicator>(.*?)</Indicator>', 1, 1, 'e') AS DCT_VALUE_SENT,
       'No', COUNT(*),
       'Which of the 8 coverages should apply to which protection type?'
FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET T1
JOIN AGGNE.DEV.PER_COM_PAYLOAD T2 ON T1.ID = T2.PUREPOLICYNUMBER
WHERE T1.ITR_TYPE = 'Risk_CM' AND T2.PROTECTIONTYPE = 'ThirdPartyOnly'
  AND REGEXP_SUBSTR(T1.PAYLOAD, '<Type>(.*?)</Type>', 1, 1, 'e') IN ('CMP_SD','PCH_SD','COR_SD','ULG_SD')
GROUP BY 1,2,3,4,5,6,8
UNION ALL
SELECT 'Motor Coverage Selections — Comprehensive policies', 'coverage/Indicator (Risk_CM: TPO_SD)',
       'CMP_SD, PCH_SD, FTL_SD, LIA_SD, COR_SD, TFT_SD, TPO_SD, ULG_SD',
       'Comprehensive (Agreed/Market Value)' AS PURE_VALUE,
       REGEXP_SUBSTR(T1.PAYLOAD, '<Type>(.*?)</Type>', 1, 1, 'e') || '=' || REGEXP_SUBSTR(T1.PAYLOAD, '<Indicator>(.*?)</Indicator>', 1, 1, 'e') AS DCT_VALUE_SENT,
       'No', COUNT(*),
       'Which of the 8 coverages should apply to which protection type?'
FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET T1
JOIN AGGNE.DEV.PER_COM_PAYLOAD T2 ON T1.ID = T2.PUREPOLICYNUMBER
WHERE T1.ITR_TYPE = 'Risk_CM' AND T2.PROTECTIONTYPE LIKE 'Comprehensive%'
  AND REGEXP_SUBSTR(T1.PAYLOAD, '<Type>(.*?)</Type>', 1, 1, 'e') = 'TPO_SD'
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 17. HC Specified Items Away From the Premises — itemized list missing from the PAYLOAD (G-40)
-- IMPORTANT correction found while removing hardcoded text: AGGNE.DEV.HC_AWAY DOES exist (1,278
-- item rows, 495 policies, real descriptions/values like 'Yellow Gold Diamond Ring' $7,500) — the
-- source-side extraction from PURE already happened. What's actually missing is a downstream
-- view/target/template to carry HC_AWAY's rows into the DCT payload — not a source-data gap.
SELECT 'Specified Items Away From the Premises', 'coverage/SpecifiedItemsPremises (item detail)', 'N/A (item list)',
       CAST((SELECT COUNT(*) FROM AGGNE.DEV.HC_AWAY) AS VARCHAR) || ' items across ' ||
         CAST((SELECT COUNT(DISTINCT PUREPOLICYNUMBER) FROM AGGNE.DEV.HC_AWAY) AS VARCHAR) ||
         ' policies exist in HC_AWAY (source), e.g. "' ||
         (SELECT MIN(DESCRIPTION) FROM AGGNE.DEV.HC_AWAY) || '"' AS PURE_VALUE,
       'not present anywhere in the payload — no view/target consumes HC_AWAY today' AS DCT_VALUE_SENT,
       'No', COUNT(*),
       'HC_AWAY already has the item-level data — what DCT node/shape should carry it into the payload?'
FROM AGGNE.DEV.PER_HOME_BUILDING_PAYLOAD
WHERE SPECIFIEDITEMSAWAY = 'Taken'
GROUP BY 1,2,3,4,5,6,8

UNION ALL

-- 18. Legacy Start Date — field identity unclear (G-45, new 2026-07-09)
-- (one representative sample row; MEMBERSHIPSYSTEMDATE always equals INCEPTIONDATE in current data)
SELECT 'Legacy Start Date', 'Policy header (exact field unconfirmed)', 'N/A',
       CAST(MIN(MEMBERSHIPSYSTEMDATE) AS VARCHAR) || ' (sample)', CAST(MIN(INCEPTIONDATE) AS VARCHAR) || ' (sample)',
       'Unclear', COUNT(*),
       'Which specific date field is "Legacy Start Date" — MembershipSystemDate, InceptionDate, or something else?'
FROM AGGNE.DEV.PER_FINAL
WHERE MEMBERSHIPSYSTEMDATE IS NOT NULL

ORDER BY 1;
