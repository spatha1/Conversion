-- Add 2 manuscript-sourced rules to PP_XML_VALIDATION_RULES (2026-07-14).
--
-- Both fields already exist and are wired in the live template (AGGNE.DEV.PP_CONVERSION_RUN,
-- Seq 18 / RISK_Building_PM) -- confirmed live: <MarketValueWithoutAccessories>
-- {MVVALUEWITHOUTACCESSORIES}</MarketValueWithoutAccessories> and <ValueWithoutAccessories>
-- {AVVALUEWITHOUTACCESSORIES}</ValueWithoutAccessories> -- just not yet tracked by the
-- validation engine. Confirmed 0 existing rows for either before this insert.
--
-- Manuscript paths (as given):
--   data/policy/line[Type="PPAU"]/risk[Type="Motor"]/MarketValueWithoutAccessories
--   data/policy/line[Type="PPAU"]/risk[Type="Motor"]/ValueWithoutAccessories
--
-- Free-text/numeric amount fields, no enum constraint -- same treatment as other numeric
-- passthroughs in this table (e.g. YearBuilt, NumberOfStoreys): IS_REQUIRED only, no VALID_VALUES.

INSERT INTO AGGNE.DEV.PP_XML_VALIDATION_RULES
  (RULE_VERSION, FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES, ACTIVE, CREATED_BY, CREATED_AT)
SELECT '1.0', 'MarketValueWithoutAccessories', 'MarketValueWithoutAccessories', 'RISK_Building_PM', FALSE,
    NULL,
    'Manuscript path: data/policy/line[Type="PPAU"]/risk[Type="Motor"]/MarketValueWithoutAccessories. Source: PER_COM_PAYLOAD.MVVALUEWITHOUTACCESSORIES.',
    TRUE, '', CURRENT_TIMESTAMP()
UNION ALL
SELECT '1.0', 'ValueWithoutAccessories', 'ValueWithoutAccessories', 'RISK_Building_PM', FALSE,
    NULL,
    'Manuscript path: data/policy/line[Type="PPAU"]/risk[Type="Motor"]/ValueWithoutAccessories. Source: PER_COM_PAYLOAD.AVVALUEWITHOUTACCESSORIES (agreed value without accessories).',
    TRUE, '', CURRENT_TIMESTAMP();

-- Verify:
SELECT RULE_ID, FIELD_NAME, XML_TAG, PAYLOAD_TYPE
FROM AGGNE.DEV.PP_XML_VALIDATION_RULES
WHERE FIELD_NAME IN ('MarketValueWithoutAccessories','ValueWithoutAccessories');
