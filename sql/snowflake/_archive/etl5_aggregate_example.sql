-- ETL5 pattern: LISTAGG to combine XML fragments by policy number.
-- Replace <OUTPUT_TABLE> and <POLICY_KEY> with actual names per config entry.

CREATE OR REPLACE VIEW V_AGG_<ENTITY> AS
SELECT
    policy_number,
    LISTAGG(xml_fragment, '') WITHIN GROUP (ORDER BY seq_num) AS xml_aggregated
FROM <OUTPUT_TABLE>
GROUP BY policy_number;
