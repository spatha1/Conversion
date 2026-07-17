# PP_CONVERSION_RUN — V1 → V2 changes (2026-07-15)

V1 backup: `PP_CONVERSION_RUN_V1_BACKUP_20260715_pre_seq13_18_fix.sql` (full pre-fix procedure)
V2 fix to deploy: `../bugfixes/BUGFIX_HC_POR_SPE_SubCoverage_And_Motor_Excess.sql` (full procedure, only these two sequences changed)

Only seq 13 and seq 18 changed. All other 16 sequences are byte-for-byte identical between V1 and V2.

## Seq 13 (RISK_Building_HC → PER_HC_TARGET)

**Removed** (flat tags, matched no field in the live DCT manuscript):
```xml
<SpecifiedItemsPremises>{SPECIFIEDITEMSAWAY}</SpecifiedItemsPremises>
<UnspecifiedItemsAwayPremises>{UNSPECIFIEDITEMSAWAY}</UnspecifiedItemsAwayPremises>
```

**Added** (nested sub-coverages, matching the manuscript's real paths — `coverage[Type="SPE_SD"]/sValue` and `coverage[Type="POR_SD"]/sValue`):
```xml
<coverage>
    <Type>SPE_SD</Type>
    <Indicator>{SPE_SD_INDICATOR}</Indicator>
    <sValue>{SPECIFIEDITEMSAWAY}</sValue>
    <Code>HCSPE_SD</Code>
    <Description>Specified Items</Description>
</coverage>

<coverage>
    <Type>POR_SD</Type>
    <Indicator>{POR_SD_INDICATOR}</Indicator>
    <sValue>{UNSPECIFIEDITEMSAWAY}</sValue>
    <Code>HCPOR_SD</Code>
    <Description>Portable Items</Description>
</coverage>
```

**Unchanged**: `<UnspecifiedItemsAwayPremisesLimit>{UNSPECIFIEDITEMSAWAYLIMIT}</UnspecifiedItemsAwayPremisesLimit>` — confirmed correct at its existing flat path.

New tokens `{SPE_SD_INDICATOR}` / `{POR_SD_INDICATOR}` require `PER_HOME_BUILDING_PAYLOAD` to already have those columns (deployed earlier today via the amended `BUGFIX_HB_INDICATOR_WrongSourceTable.sql`).

## Seq 18 (RISK_Building_PM → PER_COM_COVERAGES_TARGET)

**Removed** (flat tag directly under `<risk>`, matched no field in the manuscript at all):
```xml
<VoluntaryExcess>{VOLUNTARYEXCESS}</VoluntaryExcess>
```

**Changed** — the existing `<Excess>` block (previously 3 empty age-band fields with wrong tag names) now correctly holds Voluntary + Standard, and the age-band tags are renamed to match the manuscript:

Before:
```xml
<Excess>
    <LessThanAge20/>
    <Age20To21/>
    <Age22To25/>
</Excess>
```

After:
```xml
<Excess>
    <Standard/>
    <Voluntary>{VOLUNTARYEXCESS}</Voluntary>
    <AgeLessThan20/>
    <AgeBetween20To21/>
    <AgeBetween22To25/>
</Excess>
```

`<Standard/>` stays empty — no Standard Excess column exists in `PM_03` (checked live). `AgeLessThan20`/`AgeBetween20To21`/`AgeBetween22To25` stay empty too — same reason, only `VOLUNTARYEXCESS` exists at source.

## Rollback
If V2 causes issues, redeploy `PP_CONVERSION_RUN_V1_BACKUP_20260715_pre_seq13_18_fix.sql` as-is — it's a complete, ready-to-run `CREATE OR REPLACE PROCEDURE`.
