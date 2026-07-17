-- ============================================================
-- G-BP-69 fix -- SEQ 1 AddressVerified missing entirely (seq 1, P2, config-only)
-- Server : aggneswiftconversion-dev.database.windows.net
-- DB     : Capricorn-Dev-SwiftConversion
-- Target : dbo.ConversionConfig  SEQ 1  (ScriptName = 'BP_ACC_LOC')
--
-- Root cause: SEQ 1's ConversionScript has no <AddressVerified> tag at all -- not an empty tag
-- (like Address2 was before G-BP-67), the field is simply absent from the template.
--
-- Manuscript (Carrier_Package_Data_CW_1_0_0_0.xml, LocationOutput.AddressVerified):
--   <public id="LocationOutput.AddressVerified" path="AddressVerified" type="boolean">
--     <definition><caption value="Address Verified" /></definition>
--     <rules><default value="0" /></rules>
--   </public>
-- DC xpath: data/account/location/AddressVerified
--
-- Same ATP-9994 mechanism as G-BP-68's PropertyRiskProfile reset: AddressVerified tracks whether
-- DC's own address-verification/geocoding workflow has completed for this location. Defaults to 0
-- (unverified); DC's own process presumably flips it to 1 once verification succeeds.
--
-- Fix: add the literal <AddressVerified>0</AddressVerified> node, matching the manuscript's own
-- documented default -- no Pure data or client decision needed. Anchored on the adjacent existing
-- <AddressOverride>1</AddressOverride> tag so the REPLACE is whitespace-agnostic.
-- NOT YET APPLIED.
-- ============================================================

-- ── PRE-CHECK ────────────────────────────────────────────────
-- Expected before fix: has_address_override = 1, has_address_verified = 0
SELECT
    SequenceID,
    ScriptName,
    CHARINDEX('<AddressOverride>1</AddressOverride>', ConversionScript) AS has_address_override,
    CHARINDEX('<AddressVerified>', ConversionScript) AS has_address_verified
FROM dbo.ConversionConfig
WHERE SequenceID = 1 AND ScriptName = 'BP_ACC_LOC';

-- ── UPDATE — Insert <AddressVerified>0</AddressVerified> after <AddressOverride> ──
UPDATE dbo.ConversionConfig
SET ConversionScript = REPLACE(
    ConversionScript,
    '<AddressOverride>1</AddressOverride>',
    '<AddressOverride>1</AddressOverride>' + CHAR(13) + CHAR(10) + CHAR(9) + '<AddressVerified>0</AddressVerified>'
)
WHERE SequenceID = 1 AND ScriptName = 'BP_ACC_LOC'
  AND CHARINDEX('<AddressOverride>1</AddressOverride>', ConversionScript) > 0
  AND CHARINDEX('<AddressVerified>', ConversionScript) = 0;

-- ── POST-CHECK ───────────────────────────────────────────────
-- Expected after fix: has_address_verified > 0
SELECT
    SequenceID,
    ScriptName,
    CHARINDEX('<AddressOverride>1</AddressOverride>', ConversionScript) AS has_address_override,
    CHARINDEX('<AddressVerified>0</AddressVerified>', ConversionScript) AS has_address_verified
FROM dbo.ConversionConfig
WHERE SequenceID = 1 AND ScriptName = 'BP_ACC_LOC';

-- ── Companion ────────────────────────────────────────────────
-- Can be applied in the same session as fixes/G-BP-67_fix.sql (Address2) -- both touch SEQ 1's
-- ConversionScript, no conflict between the two REPLACE targets.
