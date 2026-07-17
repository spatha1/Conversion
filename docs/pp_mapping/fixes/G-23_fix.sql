-- ============================================================
-- G-23 — HB Excess sub-tags empty (Standard/Imposed/Earthquake/Flood/Glass) (seq 7, P2)
-- LIKELY FALSE POSITIVE — re-investigated, the premise doesn't hold up. NOT A CODE FIX.
-- ============================================================

-- ---------- Original claim ----------
-- "HB_02 carries STANDARDEXCESS/IMPOSEDEXCESS/EARTHQUAKEEXCESS/FLOODEXCESS but the view doesn't
-- expose them" — implying real data exists and is being dropped.

-- ---------- Re-investigated — the premise is false ----------
-- Checked AGGNE.DEV.HB_02's actual columns: no STANDARDEXCESS / IMPOSEDEXCESS / EARTHQUAKEEXCESS /
-- FLOODEXCESS columns exist. Full column list:
--   PUREPOLICYNUMBER, EXPIRINGID_P, CMLNUMBER, EFFECTIVEDATE, COUNTRY, PRODUCT,
--   ACCIDENTALLOSSORDAMAGE, FLOODDAMAGE, VOLUNTARYEXCESS, HOMEBUILDINGSLIMIT,
--   ACCIDENTALLOSSORDAMAGELIMIT, LANDSLIDELIMIT, MINIMUMRENTALPERIOD, WEEKLYRENT,
--   LANDLORDPROTECTIONS
-- Also checked PRD_T5_EXTERNAL_AGGNE.PURE_SNAPSHOT.PER_HomeContents and
-- AGGNE.DEV.Locationdetails_PER — neither has any excess-related column beyond VoluntaryExcess.
-- Also checked the client's original SAS (SAS/txt/HomeBuilding_coversionscriptCapricorn.txt) —
-- it only ever computes VoluntaryExcess (banded from HCHBExVoluntary). No StandardExcess /
-- ImposedExcess / EarthquakeExcess / FloodExcess concept exists anywhere in the client's source
-- logic either.
-- VoluntaryExcess IS correctly wired ({VOLUNTARYEXCESS}) — that's the only excess concept that
-- actually exists in this product's Pure data model.

-- ---------- Likely explanation ----------
-- These 5 empty tags are probably DCT template boilerplate inherited from a shared/SME coverage
-- schema (same class as the ~40 commercial screening tags and the 9 business stock-limit tags
-- already flagged elsewhere in seq 13/14 as "confirm inapplicable") — not a case of real data
-- being dropped.

-- ---------- ASK — do not silently close this as resolved ----------
-- Confirm with Aggne policy team / client that these 5 excess sub-tags are genuinely inapplicable
-- to PP Home Building (i.e. Pure/PDS simply doesn't break excess into Standard/Imposed/
-- Earthquake/Flood/Glass components for this product) before marking this permanently closed.
-- If confirmed inapplicable, no code change is needed — the tags are correctly empty.

-- ---------- Verify (informational) ----------
-- SELECT * FROM AGGNE.DEV.HB_02 LIMIT 0;  -- confirms current column list, re-check if schema changes
