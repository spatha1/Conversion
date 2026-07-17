-- BUG: Clause data for ALL THREE risk types (Building, ContentsAndStocks, Motor) is going to the
-- wrong XML structure -- not just the 4 new HC clause codes flagged on the 2026-07-15 call.
--
-- Manuscript requirement (confirmed live via ManuScript.getModelImageRq, Carrier_PP_AU_VM_1_0_0_0):
-- every clause must be nested as  Clauses[Type="X"]/Clause/{Type, StaticDescription, Value,
-- Description}  -- ONE <Clauses> wrapper per coverage, containing one <Clause> child per selected
-- clause.
--
-- CONFIRMED LIVE (real generated XML): HB (seq 6) and HC (seq 12) emit BARE <Clause> tags with NO
-- <Clauses> wrapper at all -- e.g. "...</ClassCode>  <Clause><Type>HB Solar cells
-- extension</Type><Indicator>1</Indicator><Description>8200</Description>...". Motor (seq 17) DOES
-- have a <Clauses><Type>Motor</Type> wrapper, but puts fields directly on <Clauses> instead of
-- nesting a <Clause> child, AND (because COM_CLAUSE is LISTAGG-aggregated, one row per clause) that
-- wrapper is emitted PER ROW -- a policy with 2 Motor clauses would get 2 separate <Clauses> blocks
-- instead of 1 <Clauses> containing 2 <Clause> children. Fixed by moving the wrapper up to the
-- seq 7/13/18 (parent) level, around the whole aggregated {HB_CLAUSE}/{HC_CLAUSE}/{COM_CLAUSE}
-- token, and having seq 6/12/17 emit only the bare per-row <Clause> content.
--
-- ALSO FOUND: HB_CLAUSE/PER_HC_CLAUSE hold the clause's READABLE CAPTION in DCCLAUSETYPE (e.g.
-- "HB Solar cells extension"), not the short CODE the manuscript's Clause/Type field actually
-- expects (e.g. "HBSolarcellsextension" -- confirmed via the manuscript's own dropdown option
-- list). Added a caption->code lookup for all 9 Building + 4 HC codes (the full, confirmed lists).
-- Motor's source (COM_CLAUSE.DCCLAUSETYPE, e.g. "PM_C07_MODSACCS") uses a DIFFERENT code scheme
-- that doesn't match ANY value in the manuscript's clause option list at all (checked -- zero
-- matches for the PM_C0x/CM_C0x pattern anywhere in the manuscript) -- this looks like a stale/
-- legacy Pure code with no current DCT equivalent. NOT fixed here -- passed through unchanged,
-- flagged for the client/policy team: Motor clause Type values need a translation table from them,
-- we cannot derive one. Also filtered out 'NA' and NULL clause rows in COM_CLAUSE (garbage rows
-- that shouldn't be converted as if they were real clause selections).
--
-- StaticDescription = the caption text (unchanged data, correct location).
-- Value = DCINPUT (the entered amount/text, unchanged data, correct location).
-- Description (DescriptionWithValue) = StaticDescription || ' - ' || Value as a reasonable
-- default composition -- the manuscript has per-clause phrasing templates (e.g. "The maximum we
-- will pay for loss or damage to fixed solar photovoltaic... is |1") we are NOT attempting to
-- reproduce here; flag to the client if exact wording matters.

-- ============================================================
-- SECTION 1: VIEW FIXES
-- ============================================================

-- HB_CLAUSE: add DCCLAUSECODE (caption -> manuscript code lookup, all 9 confirmed Building codes)
CREATE OR REPLACE VIEW HB_CLAUSE(
	PUREPOLICYNUMBER,
	PUREPOLICYBINDERID,
	EXPIRINGID_P,
	DCCLAUSETYPE,
	DCCLAUSECODE,
	DCINPUT
) as

SELECT DISTINCT
CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
CAST(T1.PUREPOLICYBINDERID AS VARCHAR) AS PUREPOLICYBINDERID,
CAST(T2.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
CAST(DCCLAUSETYPE AS VARCHAR) AS DCCLAUSETYPE,
-- NEW: caption -> manuscript code lookup (Carrier_PP_AU_VM_1_0_0_0, BuildingRiskClausesInput.SelectClause options)
CASE TRIM(DCCLAUSETYPE)
    WHEN 'HB Excess free glass claims'                     THEN 'HBExcessfreeglassclaims'
    WHEN 'HB Unattended building'                          THEN 'HBUnattendedbuilding'
    WHEN 'HB Inclusion of jetty'                            THEN 'HBInclusionofjetty'
    WHEN 'HB Domestic liability'                            THEN 'HBDomesticliability'
    WHEN 'HB Additional benefit increase - Part B, 8'      THEN 'HBAdditionalbenefitincreasePartB8'
    WHEN 'HB Additional benefit increase - Part B, 9'      THEN 'HBAdditionalbenefitincreasePartB9'
    WHEN 'HB Retaining walls extension'                     THEN 'HBRetainingwallsextension'
    WHEN 'HB Solar cells extension'                         THEN 'HBSolarcellsextension'
    WHEN 'HB Definition limitation'                         THEN 'HBDefinitionlimitation'
    ELSE NULL  -- unmapped caption -- surfaces as blank Type rather than sending a wrong/guessed code
END AS DCCLAUSECODE,
REPLACE(REPLACE(REPLACE(CAST(DCINPUT AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
FROM AGGNE.DEV.CLAUSES T1
INNER  JOIN AGGNE.DEV.HB_02 T2 ON trim(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND TRIM(T1.PUREPOLICYBINDERID)=TRIM(T2.EXPIRINGID_P)
WHERE T1.COVERAGE='HB' AND _IS_CURRENT='TRUE';


-- PER_HC_CLAUSE: add DCCLAUSECODE (caption -> manuscript code lookup, all 4 confirmed HC codes)
CREATE OR REPLACE VIEW PER_HC_CLAUSE(
	PUREPOLICYNUMBER,
	PUREPOLICYBINDERID,
	EXPIRINGID_P,
	DCCLAUSETYPE,
	DCCLAUSECODE,
	DCINPUT
) as

SELECT DISTINCT
CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
CAST(T1.PUREPOLICYBINDERID AS VARCHAR) AS PUREPOLICYBINDERID,
CAST(T2.EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
CAST(DCCLAUSETYPE AS VARCHAR) AS DCCLAUSETYPE,
-- NEW: caption -> manuscript code lookup (Carrier_PP_AU_VM_1_0_0_0, HomeContentsClausesInput.SelectClause options)
CASE TRIM(DCCLAUSETYPE)
    WHEN 'HC Specified items ≥ $15k'                        THEN 'HCSpecifieditems15k'
    WHEN 'HC Unattended contents'                            THEN 'HCUnattendedcontents'
    WHEN 'HC Additional benefit increase - Part A, 4'       THEN 'HCAdditionalbenefitincreasePartA4'
    WHEN 'HC Definition extension'                           THEN 'HCDefinitionextension'
    ELSE NULL  -- unmapped caption -- surfaces as blank Type rather than sending a wrong/guessed code
END AS DCCLAUSECODE,
REPLACE(REPLACE(REPLACE(CAST(DCINPUT AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
FROM AGGNE.DEV.CLAUSES T1
INNER  JOIN AGGNE.DEV.HC_02 T2 ON trim(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER) AND TRIM(T1.PUREPOLICYBINDERID)=TRIM(T2.EXPIRINGID_P)
WHERE T1.COVERAGE='HC' AND _IS_CURRENT='TRUE';


-- COM_CLAUSE: filter out 'NA'/NULL garbage clause rows. DCCLAUSETYPE (Motor code) left UNCHANGED --
-- see header note, no manuscript-valid code exists for these values, need client input.
CREATE OR REPLACE VIEW COM_CLAUSE(
	PUREPOLICYNUMBER,
	EXPIRINGID_P,
	DCCLAUSETYPE,
	DCINPUT
) as
SELECT DISTINCT
CAST(trim(PUREPOLICYNUMBER) ||'|' || TRIM(cmlnumber) ||'|' || TRIM(EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
CAST(EXPIRINGID_P AS VARCHAR) AS EXPIRINGID_P,
CAST(CLAUSE_TEXT AS VARCHAR) AS DCCLAUSETYPE,
REPLACE(REPLACE(REPLACE(CAST(CLAUSE_DESC AS VARCHAR), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') AS DCINPUT
FROM AGGNE.DEV.PM_03
WHERE EXPIRYDATE>='2026-01-01'
  -- NEW: exclude garbage/placeholder clause rows (confirmed live: 'NA' and NULL both present in
  -- CLAUSE_TEXT) -- these aren't real clause selections and shouldn't be converted as if they were.
  AND CLAUSE_TEXT IS NOT NULL
  AND TRIM(CLAUSE_TEXT) <> 'NA';

-- Verify (run after deploy):
-- SELECT DCCLAUSETYPE, DCCLAUSECODE FROM AGGNE.DEV.HB_CLAUSE;      -- expect DCCLAUSECODE populated for all rows
-- SELECT DCCLAUSETYPE, DCCLAUSECODE FROM AGGNE.DEV.PER_HC_CLAUSE;  -- expect DCCLAUSECODE populated for all rows
-- SELECT DISTINCT DCCLAUSETYPE FROM AGGNE.DEV.COM_CLAUSE;          -- expect no 'NA'/NULL rows
