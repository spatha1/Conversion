-- CR: Add <AddressVerified> to the location block (data/account/location/AddressVerified)
--
-- Requested 2026-07-13 (Client CR, not a client-reported bug). Client's own example XML shows this
-- tag missing from the <location> group entirely:
--
--   <location>
--       <Number>2</Number>
--       <address>...</address>
--       <GeocodeStatusDisplay>Unverified</GeocodeStatusDisplay>
--       <LocationType/>
--       <BusinessType/>
--       <AddressOverride>1</AddressOverride>
--   </location>
--
-- Requested as a hardcoded default (0), not a source-driven token -- same pattern as the existing
-- <GeocodeStatusDisplay>Unverified</GeocodeStatusDisplay> literal in this same block.
--
-- Confirmed live (2026-07-13):
--   - Only one config row references this block: PP_ConversionConfig.ConversionConfigId = 3
--     (SequenceID 3, ScriptName 'ACC_LOC').
--   - No existing reference to AddressVerified anywhere in PP_ConversionConfig today.
--   - The <City> tag in this same block (token {SUBURB}) is NOT a gap -- confirmed 0 blank across
--     all 3,939 policies and all location numbers (1-9) in AGGNE.DEV.PER_POLICY_MIGRATION_DCT.
--     Raised during this same conversation as a suspected "Suburb blank" issue and ruled out.
--
-- Run on: Capricorn-Dev-SwiftConversion (SQL Server), dbo.PP_ConversionConfig
-- Deployment DB, DB not accessible for direct writes from this session -- run manually.

-- Exact live bytes confirmed 2026-07-13 via direct SELECT of ConversionScript (repr'd to show
-- whitespace/line-endings): '...<AddressOverride>{ADDRESSOVERRIDE}</AddressOverride>\n\t\t\t</location>'
-- i.e. LF only (not CRLF), 4 tabs before <AddressOverride>, 3 tabs before </location>.
-- AddressVerified is hardcoded ('0'), same as requested -- not a token.

UPDATE PP_ConversionConfig
SET ConversionScript = REPLACE(
        ConversionScript,
        '<AddressOverride>{ADDRESSOVERRIDE}</AddressOverride>' + CHAR(10) + CHAR(9) + CHAR(9) + CHAR(9) + '</location>',
        '<AddressOverride>{ADDRESSOVERRIDE}</AddressOverride>' + CHAR(10) +
        CHAR(9) + CHAR(9) + CHAR(9) + CHAR(9) + '<AddressVerified>0</AddressVerified>' + CHAR(10) +
        CHAR(9) + CHAR(9) + CHAR(9) + '</location>'
    )
WHERE ConversionConfigId = 3;

-- Verify the replace actually matched (row should show the new tag present, and the same
-- occurrence-count as AddressOverride, i.e. once per <location> block in the template):
SELECT
    ConversionConfigId,
    CASE WHEN ConversionScript LIKE '%<AddressVerified>0</AddressVerified>%' THEN 'OK' ELSE 'NOT APPLIED' END AS STATUS
FROM PP_ConversionConfig
WHERE ConversionConfigId = 3;

-- After this config change, PP_CONVERSION_RUN must be regenerated from config (same two-source-drift
-- step needed for every prior config change -- e.g. G-20) before it reaches the real generated XML.
-- Not run yet -- CR flagged as not impacting the current batch, no urgency to re-run today.
