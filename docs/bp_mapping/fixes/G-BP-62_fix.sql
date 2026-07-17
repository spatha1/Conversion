-- ============================================================================
-- G-BP-62 fix — SEQ 23 (BP_LINE_SV), Stock Vehicles: GLS_SD (Windscreen/Glass)
-- limit sent blank (ATP-10842, "SV 'Is Windscreen Glass Excess Taken' is
-- incorrect in Clarity")
-- ============================================================================
-- REOPENED 2026-07-11 after the user shared a real ticket screenshot showing
-- the actual defect: <sValue>Taken</sValue> and <Indicator>1</Indicator> are
-- both correct, but <limit><Type>GLS_SD</Type><iValue/></limit> is genuinely
-- blank. The earlier trace (Indicator/sValue internally consistent, matches
-- SAS/SP) was real but answered the wrong question — the ticket title is
-- misleading; the actual client complaint is the missing limit.
--
-- Root cause: manuscript (Carrier_CoverageLibrary_Data_1_0_0_0.xml) defines
-- this as a DERIVED value, not something to leave blank:
--
--   StockVehiclesInput.LegalLiabilityLimitWindscreenGlass (GLS_SD/limit/iValue)
--     value = StockVehiclesInput.WindscreenAndWindowGlassExcess (Excess/WindscreenAndWindowGlass)
--
--   StockVehiclesInput.WindscreenAndWindowGlassExcess (Excess/WindscreenAndWindowGlass)
--     value = StockVehiclesPrivate.WindscreenAndWindowGlassExcessConditional
--
--   StockVehiclesPrivate.WindscreenAndWindowGlassExcessConditional:
--     IF (StockVehiclesInput.Indicator = False) OR (GLS_SD.Indicator = False) THEN 0
--     ELSE IF LossOrDamageLimit >= 100001 THEN <MaxLength.MinimumOneThousand>
--     ELSE <MaxLength.MaximumFiveHundred>
--
-- Both GLS_SD/limit/iValue and Excess/WindscreenAndWindowGlass are marked
-- readOnly="True" in the manuscript, but that does NOT mean DC backfills them
-- for a bulk import that arrives blank — we have direct precedent this
-- session (G-BP-18's DFW_SD sValue, also readOnly + formula-driven) where a
-- blank/wrong sent value stayed wrong until conversion sent the correct
-- computed value itself. Treating this the same way.
--
-- IMPORTANT — unverified constants: MaxLength.MinimumOneThousand and
-- MaxLength.MaximumFiveHundred are not defined anywhere in the manuscript
-- files available to us; their numeric values (1000 and 500) are INFERRED
-- from this manuscript's otherwise-literal naming convention (e.g.
-- MaxLength.MinimumZero = 0 elsewhere), not confirmed against DC's actual
-- constant table. Verify against a real DCT quote/policy showing this field
-- correctly populated before treating this as final.
--
-- All 3 driving inputs (STOCKVEHICLES_IND, UVGLASSREMOVAL_IND, LOSSDAMAGELIMIT)
-- are already sent correctly elsewhere in this same SEQ 23 template — this is
-- purely a missing derivation, not a missing source field.
--
-- Scope: view (add GLSLIMIT to LINE_SV_PAYLOAD) + config (populate both
-- GLS_SD/limit/iValue and Excess/WindscreenAndWindowGlass with it, since the
-- manuscript chains one from the other and it's unclear which one DC actually
-- persists from on import — sending both keeps them consistent either way).
-- Status: DRAFTED, NOT APPLIED. SAFE_MODE — wait for explicit go-ahead before running.
-- Whitespace confirmed byte-exact via live pull immediately before drafting.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- STEP 1 (Snowflake) — add GLSLIMIT to LINE_SV_PAYLOAD
-- ---------------------------------------------------------------------------
-- Re-pull GET_DDL('VIEW','AGGNE.DEV.LINE_SV_PAYLOAD') immediately before
-- applying and diff against this — only change is GLSLIMIT added to the
-- column list and computed in the final SELECT, right after TPO_INDICATOR.

create or replace view LINE_SV_PAYLOAD(
	PUREPOLICYNUMBER,
	LINE_SV_UW,
	LINE_SV_CLAUSE,
	PROTECTIONTYPE,
	STOCKVEHICLES_IND,
	LOSSDAMAGELIMIT,
	VOLUNTARYEXCESS,
	EXCESSWAIVERFORWINDSCREEN,
	UVGLASSREMOVAL_IND,
	NOFVEHWATERCRAFTSHELD,
	AVERAGEVALUEOFTHEVEH,
	COM_INDICATOR,
	TPO_INDICATOR,
	GLSLIMIT,   -- NEW
	DOYOUHAVEADEALERSLICENSE,
	MAXIMUMESTIMATEDVALUE,
	SVCLMCNT,
	SVCLMINCD,
	SVEXPPREM,
	EXP_PREM_SVGLS_SD,
	EXP_PREM_SVLIA_SD,
	EXP_PREM_SVTPO_SD,
	EXP_PREM_SVSTD_ST,
	EXP_PREM_SVSTD_SD,
	LOAD_DATE
) as

 with cte_SAMPLE_CBP_LOCATION as
(
select distinct PUREPOLICYNUMBER,cmlnumber,EXPIRINGID_P from AGGNE.DEV.SAMPLE_CBP WHERE EXPIRYDATE>='2026-01-01'
),cte_COVERAGES as
(
select distinct PUREPOLICYNUMBER,cmlnumber,EXPIRINGID_P,
CASE  WHEN DESCRIPTION ='Comprehensive - Market Value' THEN 'ComprehensiveMarket'
 WHEN DESCRIPTION ='Comprehensive - Agreed Value' THEN 'ComprehensiveAgreedValue'
 WHEN DESCRIPTION ='Fire and Theft' THEN 'FireandTheft'
 WHEN DESCRIPTION ='Comprehensive' THEN 'FullComprehensive'
 WHEN DESCRIPTION ='Third Party Only' THEN 'ThirdPartyOnly'
 WHEN DESCRIPTION ='Third Party, Fire and Theft' THEN 'ThirdPartyFireandTheft'
ELSE DESCRIPTION END AS PROTECTIONTYPE ,
CAST(COALESCE(STOCKVEHICLES_IND,'0') AS VARCHAR) AS STOCKVEHICLES_IND,
CAST(COALESCE(LOSSDAMAGELIMIT ,0) AS VARCHAR) AS LOSSDAMAGELIMIT ,
CAST(VOLUNTARYEXCESS  AS VARCHAR) AS VOLUNTARYEXCESS ,
CASE WHEN EXCESSWAIVERFORWINDSCREEN ='Taken' THEN 'Taken' ELSE 'NotTaken' END AS EXCESSWAIVERFORWINDSCREEN ,
CAST(COALESCE(UVGLASSEXCESSREMOVAL ,'0') AS VARCHAR) AS UVGLASSREMOVAL_IND ,
CAST(COALESCE(NOFVEHWATERCRAFTSHELD ,0) AS VARCHAR) AS NOFVEHWATERCRAFTSHELD ,
CAST(COALESCE(AVERAGEVALUEOFTHEVEH ,0) AS VARCHAR) AS AVERAGEVALUEOFTHEVEH ,
CAST(COALESCE(DOYOUHAVEADEALERSLICENSE ,'0') AS VARCHAR) AS DOYOUHAVEADEALERSLICENSE ,
CAST(COALESCE(MAXIMUMESTIMATEDVALUE ,0) AS VARCHAR) AS MAXIMUMESTIMATEDVALUE
from AGGNE.DEV.Line_SV_Coverage T1 WHERE EXPIRYDATE>='2026-01-01'  --738
)
, CTE_EXCESS AS(
SELECT
    CAST(trim(T2.PUREPOLICYNUMBER) ||'|' || TRIM(T2.cmlnumber) ||'|' || TRIM(T2.EXPIRINGID_P) AS VARCHAR) AS PUREPOLICYNUMBER,
t2.PUREPOLICYNUMBER AS LEGACYPOLICYNUMBER,T2.cmlnumber,T2.EXPIRINGID_P,
CAST(COALESCE(PROTECTIONTYPE ,'0') AS VARCHAR) AS PROTECTIONTYPE ,
CAST(COALESCE(STOCKVEHICLES_IND,0) AS VARCHAR) AS STOCKVEHICLES_IND,
CAST(COALESCE(LOSSDAMAGELIMIT ,0) AS VARCHAR) AS LOSSDAMAGELIMIT ,
CAST(VOLUNTARYEXCESS  AS VARCHAR) AS VOLUNTARYEXCESS ,
CAST(COALESCE(EXCESSWAIVERFORWINDSCREEN ,'No') AS VARCHAR) AS EXCESSWAIVERFORWINDSCREEN ,
CAST(COALESCE(UVGLASSREMOVAL_IND ,0) AS VARCHAR) AS UVGLASSREMOVAL_IND ,
CAST(COALESCE(NOFVEHWATERCRAFTSHELD ,0) AS VARCHAR) AS NOFVEHWATERCRAFTSHELD ,
CAST(COALESCE(AVERAGEVALUEOFTHEVEH ,0) AS VARCHAR) AS AVERAGEVALUEOFTHEVEH ,
CAST(COALESCE(DOYOUHAVEADEALERSLICENSE ,'0') AS VARCHAR) AS DOYOUHAVEADEALERSLICENSE ,
CAST(COALESCE(MAXIMUMESTIMATEDVALUE ,0) AS VARCHAR) AS MAXIMUMESTIMATEDVALUE
FROM
cte_SAMPLE_CBP_LOCATION T1
INNER JOIN cte_COVERAGES T2 ON
 TRIM(T1.PUREPOLICYNUMBER)=TRIM(T2.PUREPOLICYNUMBER)  --WITH 737,WITHOUT 1054
)
,CTE_LISTAGG AS(
SELECT DISTINCT
  ID,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_LINE_SV_UW' THEN payload END, '\n') AS LINE_SV_UW,
  LISTAGG(CASE WHEN ITR_TYPE = 'BP_LINE_SV_CLAUSE' THEN payload END, '\n') AS LINE_SV_CLAUSE,
  CAST(LOAD_DATE AS DATE) AS LOAD_DATE
FROM AGGNE.DEV.LINE_SV_Target
WHERE ITR_TYPE IN ('BP_LINE_SV_UW','BP_LINE_SV_CLAUSE')
GROUP BY ID, CAST(LOAD_DATE AS DATE)
)
,SUB_COV_PREM AS (
SELECT
  PUREPOLICYNUMBER,
SVGLS_SD,
SVLIA_SD,
SVTPO_SD,
SVSTD_ST,
SVSTD_SD
FROM (
  SELECT PUREPOLICYNUMBER, SUB_COVERAGE, EXPPREMIUM
  FROM AGGNE.DEV.VW_OUTPUT_SUBCOVERAGE_BSP
) src
PIVOT (
  SUM(EXPPREMIUM) FOR SUB_COVERAGE IN (
    ('SVGLS_SD') AS SVGLS_SD,
    ('SVLIA_SD') AS SVLIA_SD,
    ('SVTPO_SD') AS SVTPO_SD,
    ('SVSTD_ST') AS SVSTD_ST,
    ('SVSTD_SD') AS SVSTD_SD
  )
) p
)
SELECT distinct
T1.PUREPOLICYNUMBER,
CASE WHEN LINE_SV_UW IS NOT NULL AND LINE_SV_UW<> '' THEN CAST(LINE_SV_UW AS VARCHAR) ELSE '' END AS LINE_SV_UW,
-- CAST(LINE_SV_UW AS VARCHAR) AS LINE_SV_UW,
CASE WHEN LINE_SV_CLAUSE IS NOT NULL AND LINE_SV_CLAUSE<> '' THEN '<Clauses><Type>StockVehicles</Type>'||CAST(LINE_SV_CLAUSE AS VARCHAR)||'</Clauses>' ELSE '' END AS LINE_SV_CLAUSE,
-- CAST(LINE_SV_CLAUSE AS VARCHAR) AS LINE_SV_CLAUSE,
CAST(COALESCE(PROTECTIONTYPE ,'') AS VARCHAR) AS PROTECTIONTYPE ,
CAST(CAST(COALESCE(STOCKVEHICLES_IND,0)AS NUMBER(10,0)) AS VARCHAR) AS STOCKVEHICLES_IND,
CAST(CAST(COALESCE(LOSSDAMAGELIMIT ,0)AS NUMBER(10,0)) AS VARCHAR) AS LOSSDAMAGELIMIT ,
CAST(CAST(COALESCE(VOLUNTARYEXCESS ,0)AS NUMBER(10,0)) AS VARCHAR) AS VOLUNTARYEXCESS ,
CAST(COALESCE(EXCESSWAIVERFORWINDSCREEN ,'No') AS VARCHAR) AS EXCESSWAIVERFORWINDSCREEN ,
CAST(CAST(COALESCE(UVGLASSREMOVAL_IND ,0)AS NUMBER(10,0))  AS VARCHAR) AS UVGLASSREMOVAL_IND ,
CAST(CAST(COALESCE(NOFVEHWATERCRAFTSHELD ,0)AS NUMBER(10,0))  AS VARCHAR) AS NOFVEHWATERCRAFTSHELD ,
CAST(CAST(COALESCE(AVERAGEVALUEOFTHEVEH ,0)AS NUMBER(10,0))  AS VARCHAR) AS AVERAGEVALUEOFTHEVEH ,
CASE WHEN PROTECTIONTYPE='FullComprehensive' THEN CAST('1' AS VARCHAR) ELSE CAST('0' AS VARCHAR) END AS COM_INDICATOR,
CASE WHEN PROTECTIONTYPE='ThirdPartyOnly' THEN CAST('1' AS VARCHAR) ELSE CAST('0' AS VARCHAR) END AS TPO_INDICATOR,
CASE   -- NEW: GLSLIMIT, matches StockVehiclesPrivate.WindscreenAndWindowGlassExcessConditional
    WHEN COALESCE(STOCKVEHICLES_IND,0) = 0 OR COALESCE(UVGLASSREMOVAL_IND,0) = 0 THEN CAST('0' AS VARCHAR)
    WHEN CAST(COALESCE(LOSSDAMAGELIMIT,0) AS NUMBER(10,0)) >= 100001 THEN CAST('1000' AS VARCHAR)
    ELSE CAST('500' AS VARCHAR)
END AS GLSLIMIT,
CAST(COALESCE(DOYOUHAVEADEALERSLICENSE ,'') AS VARCHAR) AS DOYOUHAVEADEALERSLICENSE ,
CAST(CAST(COALESCE(MAXIMUMESTIMATEDVALUE ,0) AS NUMBER(10,0)) AS VARCHAR) AS MAXIMUMESTIMATEDVALUE ,
CAST(CAST(COALESCE(T4.SVCLMCNT ,0)AS NUMBER(10,0))  AS VARCHAR) AS SVCLMCNT,
CAST(CAST(COALESCE(T4.SVCLMINCD ,0)AS NUMBER(10,0))  AS VARCHAR) AS SVCLMINCD,
CAST(COALESCE(T4.SVEXPPREM ,0) AS VARCHAR) AS SVEXPPREM,
CAST(COALESCE(CAST(SVGLS_SD AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_SVGLS_SD,
CAST(COALESCE(CAST(SVLIA_SD AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_SVLIA_SD,
CAST(COALESCE(CAST(SVTPO_SD AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_SVTPO_SD,
CAST(COALESCE(CAST(SVSTD_ST AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_SVSTD_ST,
CAST(COALESCE(CAST(SVSTD_SD AS NUMBER(36,3)),0)AS VARCHAR) AS EXP_PREM_SVSTD_SD,
CAST(GETDATE() AS DATE) AS LOAD_DATE
FROM CTE_EXCESS T1
-- INNER JOIN  AGGNE.DEV.LINE_SV_Target T2 ON T1.PUREPOLICYNUMBER=T2.ID
LEFT JOIN CTE_LISTAGG T3 ON T1.PUREPOLICYNUMBER = T3.ID
LEFT JOIN AGGNE.DEV.VW_OUTPUT_COVERAGE_BSP T4 ON T1.PUREPOLICYNUMBER=T4.PUREPOLICYNUMBER
LEFT JOIN SUB_COV_PREM T5 ON T1.PUREPOLICYNUMBER=T5.PUREPOLICYNUMBER;

-- POST-CHECK (Snowflake)
-- SELECT UVGLASSREMOVAL_IND, LOSSDAMAGELIMIT, GLSLIMIT, COUNT(*)
-- FROM AGGNE.DEV.LINE_SV_PAYLOAD GROUP BY 1,2,3 ORDER BY 4 DESC;
-- Expect: UVGLASSREMOVAL_IND='0' -> GLSLIMIT='0' always;
--         UVGLASSREMOVAL_IND='1' AND LOSSDAMAGELIMIT<100001 -> GLSLIMIT='500';
--         UVGLASSREMOVAL_IND='1' AND LOSSDAMAGELIMIT>=100001 -> GLSLIMIT='1000'.


-- ============================================================================
-- STEP 2 (Azure SQL, dbo.ConversionConfig) — SEQ 23 token wiring
-- ============================================================================

-- PRE-CHECK
SELECT SequenceID, ScriptName,
       CASE WHEN CHARINDEX('<WindscreenAndWindowGlass/>', ConversionScript) > 0 THEN 'PRESENT' ELSE 'MISSING' END AS TOPLEVEL_EMPTY_TAG,
       CASE WHEN CHARINDEX('<Type>GLS_SD</Type>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + '<iValue/>', ConversionScript) > 0 THEN 'PRESENT' ELSE 'MISSING' END AS GLS_LIMIT_EMPTY_TAG
FROM dbo.ConversionConfig
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV';
-- Expect both PRESENT

-- UPDATE
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(
        REPLACE(ConversionScript,
            '<WindscreenAndWindowGlass/>',
            '<WindscreenAndWindowGlass>{GLSLIMIT}</WindscreenAndWindowGlass>'),
        '<Type>GLS_SD</Type>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + '<iValue/>',
        '<Type>GLS_SD</Type>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + '<iValue>{GLSLIMIT}</iValue>')
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV'
  AND CHARINDEX('<WindscreenAndWindowGlass/>', ConversionScript) > 0
  AND CHARINDEX('<Type>GLS_SD</Type>' + CHAR(13) + CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + '<iValue/>', ConversionScript) > 0;

-- POST-CHECK
SELECT SequenceID, ScriptName, ConversionScript
FROM dbo.ConversionConfig
WHERE SequenceID = 23 AND ScriptName = 'BP_LINE_SV';
-- Expect: both the top-level Excess/WindscreenAndWindowGlass and GLS_SD's
-- limit/iValue now reference {GLSLIMIT}.

-- IMPORTANT: run STEP 1 (view) before STEP 2 (config) — the config references
-- {GLSLIMIT}, which only resolves once LINE_SV_PAYLOAD produces that column.
