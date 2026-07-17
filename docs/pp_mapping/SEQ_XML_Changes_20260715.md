# SEQ XML Changes — Old vs New (2026-07-15 manuscript fix)

9 of 18 sequences changed. All fixes are structural (tag placement/naming) — no new source data, same values.

---

## SEQ 5 / 11 / 16 — UnderwritingAdjustment (Building / HC / Motor, identical template)

**Old:**
```xml
<Recurring>
    <Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
```

**New:**
```xml
<Recurring>
    <sValue>{RECURRINGINDICATOR}</sValue>
</Recurring>
```

---

## SEQ 6 — HB_CLAUSE

**Old:**
```xml
<Clause>
  <Type>{DCCLAUSETYPE}</Type>
  <Indicator>1</Indicator>
  <Description>{DCINPUT}</Description>
  <DisableFlag>1</DisableFlag>
</Clause>
```

**New:**
```xml
<Clause>
  <Type>{DCCLAUSECODE}</Type>
  <StaticDescription>{DCCLAUSETYPE}</StaticDescription>
  <Value>{DCINPUT}</Value>
  <Description>{DCCLAUSETYPE} - {DCINPUT}</Description>
</Clause>
```

---

## SEQ 7 — RISK_Building_HB (only the clause-slot line changed)

**Old:**
```xml
</ClassCode>     {HB_CLAUSE}{HB_UW}     <ClaimsIncurred>{HBCLMINCD}</ClaimsIncurred>
```

**New:**
```xml
</ClassCode>     <Clauses><Type>Building</Type>{HB_CLAUSE}</Clauses>{HB_UW}     <ClaimsIncurred>{HBCLMINCD}</ClaimsIncurred>
```

---

## SEQ 12 — LOC_HC_CLAUSE

**Old:**
```xml
<Clause>
  <Type>{DCCLAUSETYPE}</Type>
  <Indicator>1</Indicator>
  <Description>{DCINPUT}</Description>
  <DisableFlag>1</DisableFlag>
</Clause>
```

**New:**
```xml
<Clause>
  <Type>{DCCLAUSECODE}</Type>
  <StaticDescription>{DCCLAUSETYPE}</StaticDescription>
  <Value>{DCINPUT}</Value>
  <Description>{DCCLAUSETYPE} - {DCINPUT}</Description>
</Clause>
```

---

## SEQ 13 — RISK_Building_HC

**Old:**
```xml
<UnspecifiedItemsAwayPremisesLimit>{UNSPECIFIEDITEMSAWAYLIMIT}</UnspecifiedItemsAwayPremisesLimit>
<HomeContentsTotal></HomeContentsTotal>
<SpecifiedContentsTotal></SpecifiedContentsTotal>  {HC_EXCEED_VALUES}  {HC_SPECIFIED_CONTENTS}  {SUBCOV}
...
<Premium>{HBEXPPREM}</Premium>
{HC_CLAUSE}  {UW}
</coverage>
```
(`<SpecifiedItemsPremises>{SPECIFIEDITEMSAWAY}</SpecifiedItemsPremises>` and
`<UnspecifiedItemsAwayPremises>{UNSPECIFIEDITEMSAWAY}</UnspecifiedItemsAwayPremises>` used to sit
just above `UnspecifiedItemsAwayPremisesLimit` as flat tags.)

**New:**
```xml
<UnspecifiedItemsAwayPremisesLimit>{UNSPECIFIEDITEMSAWAYLIMIT}</UnspecifiedItemsAwayPremisesLimit>
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
<HomeContentsTotal></HomeContentsTotal>
<SpecifiedContentsTotal></SpecifiedContentsTotal>  {HC_EXCEED_VALUES}  {HC_SPECIFIED_CONTENTS}  {SUBCOV}
...
<Premium>{HBEXPPREM}</Premium>
<Clauses><Type>ContentsAndStocks</Type>{HC_CLAUSE}</Clauses>  {UW}
</coverage>
```

---

## SEQ 17 — COM_CLAUSE (Motor)

**Old:**
```xml
<Clauses>
    <Type>Motor</Type>
    <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
    <SelectClauseDescription>{DCINPUT} </SelectClauseDescription>
    <IsClauseReadOnly>0</IsClauseReadOnly>
    <IsEditable>1</IsEditable>
    <Value>{DCINPUT}</Value>
    <DescriptionValue>{DCINPUT}</DescriptionValue>
</Clauses>
```
(emitted per-row — a policy with 2 Motor clauses got 2 of these `<Clauses>` blocks, not 1)

**New:**
```xml
<Clause>
    <Type>{DCCLAUSETYPE}</Type>
    <StaticDescription>{DCCLAUSETYPE}</StaticDescription>
    <Value>{DCINPUT}</Value>
    <Description>{DCINPUT}</Description>
    <IsClauseReadOnly>0</IsClauseReadOnly>
    <IsEditable>1</IsEditable>
</Clause>
```
(bare per row — the `<Clauses>` wrapper moves to Seq 18, once per policy. `Type`/`DCCLAUSETYPE` value
itself is UNCHANGED — our source codes like `PM_C07_MODSACCS` don't match anything in the manuscript;
flagged, needs a translation table from the client.)

---

## SEQ 18 — RISK_Building_PM (Motor)

**Old (Excess block):**
```xml
<VoluntaryExcess>{VOLUNTARYEXCESS}</VoluntaryExcess>
...
<Excess>
    <LessThanAge20/>
    <Age20To21/>
    <Age22To25/>
</Excess>
```

**New (Excess block):**
```xml
<Excess>
    <Standard/>
    <Voluntary>{VOLUNTARYEXCESS}</Voluntary>
    <AgeLessThan20/>
    <AgeBetween20To21/>
    <AgeBetween22To25/>
</Excess>
```
(the flat `<VoluntaryExcess>` tag is removed entirely — its value moves into `<Excess><Voluntary>`)

**Old (clause-slot line):**
```xml
<OccupancyID/>  {COM_CLAUSE}  {UW}  </risk>
```

**New (clause-slot line):**
```xml
<OccupancyID/>  <Clauses><Type>Motor</Type>{COM_CLAUSE}</Clauses>  {UW}  </risk>
```

---

## Deploy order

1. `BUGFIX_Clauses_Structure_HB_HC_Motor.sql` (views: `HB_CLAUSE`, `PER_HC_CLAUSE`, `COM_CLAUSE`)
2. `BUGFIX_PP_CONVERSION_RUN_V3_Clauses.sql` (the SP — includes seq 5/11/16, 6/7, 12/13, 17/18 all together)
