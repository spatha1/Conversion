-- ============================================================
-- G-02 fix — YMM filter silently dropped vehicles missing Year/Make/Model (seq 18, Motor, P1)
-- Decision (2026-07-09, client-approved): never silently drop a record for one bad field —
-- see docs/pp_mapping/VALIDATION_RULES.md, Process Rule PR-01.
--
-- STATUS: part 1 (view fix) already applied inline in the repo. Part 2 (validation rule) is
-- still a draft/follow-up — listed here so both pieces of this gap stay together for batch review.
-- ============================================================

-- ---------- 1. Snowflake — sql/snowflake/1_conversion/PP/views/PER_COM_PAYLOAD.sql ----------
-- APPLIED 2026-07-09: removed the filter from cte_COVERAGES.
--   Retired: FROM AGGNE.DEV.PM_03 T1 WHERE YEAR<>0 and make<>'' and MODEL<>''
--   Now:     FROM AGGNE.DEV.PM_03 T1        (no filter — every vehicle flows through)
-- See the view file itself for the full comment explaining the decision.

-- ---------- 2. Validation report — PP_XML_VALIDATION_RULES / SP_PP_XML_VALIDATE ----------
-- FOLLOW-UP, NOT YET DRAFTED: confirm whether the existing rule table already has a generic
-- BLANK_REQUIRED check that will catch Year=0 / Make='' / Model='' now that these vehicles
-- reach the view, or whether an explicit rule row needs to be added for these three fields.
-- Exact INSERT statement needs the live PP_XML_VALIDATION_RULES schema — pull that before
-- drafting this part (don't guess the column layout).

-- ---------- 3. Verify after rebuild ----------
-- CALL AGGNE.DEV.SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD();
-- SELECT COUNT(*) AS TOTAL_VEHICLES_IN_VIEW FROM AGGNE.DEV.PER_COM_PAYLOAD;
-- -- should now include the ~3,589 vehicles previously dropped (minus any genuinely still-blank ones)
-- SELECT COUNT(*) AS STILL_BLANK_YMM FROM AGGNE.DEV.PER_COM_PAYLOAD
-- WHERE YEAR = '0' OR TRIM(MAKE) = '' OR TRIM(MODEL) = '';
-- -- this count is what the validation report must now catch
