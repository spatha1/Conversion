-- ============================================================
-- Run seq 17 COM_CLAUSE — ready to execute
-- Template sourced from local PolicyConversion DB (post fix):
--   {CLAUSESSELECTION} → {DCCLAUSETYPE}
--   {SELECTCLAUSEDESCRIPTION} → {DCINPUT}
-- Source view: AGGNE.DEV.COM_CLAUSE
--   Columns: PUREPOLICYNUMBER, EXPIRINGID_P, DCCLAUSETYPE, DCINPUT
-- ============================================================

-- ── Step 1: Verify COM_CLAUSE view has data ───────────────────────────────
SELECT COUNT(*) AS COM_CLAUSE_ROWS FROM AGGNE.DEV.COM_CLAUSE;
-- Expected: > 0

-- ── Step 2: Check current stale COM_CLAUSE rows in target ────────────────
SELECT COUNT(*) AS STALE_ROWS,
       SUM(CASE WHEN PAYLOAD LIKE '%{%}%' THEN 1 ELSE 0 END) AS ROWS_WITH_TOKENS
FROM   AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'COM_CLAUSE';
-- These are the stale rows with {CLAUSESSELECTION} / {SELECTCLAUSEDESCRIPTION}

-- ── Step 3: Delete stale COM_CLAUSE rows ─────────────────────────────────
DELETE FROM AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'COM_CLAUSE';

-- ── Step 4: Re-run seq 17 with fixed template ─────────────────────────────
CALL AGGNE.DEV.DYNAMIC_XML_V1(
    'AGGNE.DEV.COM_CLAUSE',
    $$<Clauses>
	    <Type>Motor</Type>
	    <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
	    <SelectClauseDescription>{DCINPUT} </SelectClauseDescription>
	    <IsClauseReadOnly>0</IsClauseReadOnly>
	    <IsEditable>1</IsEditable>
	    <Value>{DCINPUT}</Value>
	    <DescriptionValue>{DCINPUT}</DescriptionValue>
	</Clauses>$$,
    'AGGNE.DEV.PER_COM_COVERAGES_TARGET',
    'COM_CLAUSE'
);

-- ── Step 5: Verify new COM_CLAUSE rows — no tokens ───────────────────────
SELECT COUNT(*) AS COM_CLAUSE_ROWS,
       SUM(CASE WHEN PAYLOAD LIKE '%{%}%' THEN 1 ELSE 0 END) AS ROWS_WITH_TOKENS
FROM   AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'COM_CLAUSE';
-- Expected: COM_CLAUSE_ROWS > 0, ROWS_WITH_TOKENS = 0

-- ── Step 6: Sample — confirm DCCLAUSETYPE and DCINPUT resolved ────────────
SELECT ID, LEFT(PAYLOAD, 300) AS PAYLOAD_PREVIEW
FROM   AGGNE.DEV.PER_COM_COVERAGES_TARGET
WHERE  ITR_TYPE = 'COM_CLAUSE'
LIMIT  3;
