# PP DEV Batch — Full 46-Policy Matrix (2026-07-16)

Every policy from the UAT pilot batch, re-submitted to DCT DEV and cross-checked against the source
tables. DEV Quote/premium columns are from the original batch run; the 9 policies that had a DCT-side
failure were re-tested separately (see Status column) and their actual quote numbers from those
re-tests are documented in the Teams write-ups, not repeated here to keep this table matched to the
INSERT script's data.

**Party ID Blank** = `InputClientID` was empty in the request (the known culture=en-NZ Express crash
workaround item, confirmed resolved via PartyID substitution — still worth spot-checking, not the
same issue as the AU PartyID blocker below).

**Status legend:**
- **OK** — clean submission, no DCT-side failure.
- **AU PartyID blocker** — `InputClientID` is populated but references a party that doesn't exist in
  DCT; premium never computes. Not fixable in PP's own SP — traces to the separate Party Conversion
  pipeline. Not expected to recur in UAT (per team's read) — if it does, Party Conversion needs
  re-running before the affected policies are re-converted.
- **NZ phone warning** — `ErrInvalidNZPhnNbr` still appears in the response, but it's
  `BusinessErrorType="Warning"`, not blocking: DCT still closes the session and computes a real
  premium for 4 of 5. Root cause is in DCT's Party platform validation (not the policy manuscript),
  escalated separately. One policy (P00034444) shows $0 and needs its own check before being called
  clean.

| # | Legacy Policy | UAT Quote | UAT Status | DEV Quote | Party ID Blank | Vehicle Prem | Property Prem | Data Scenarios | Status |
|---|---|---|---|---|---|---|---|---|---|
| 1 | P00000371 | Q0115015 | Refer | Q0132761 | No | 2345.82 | 2650.97 | Vehicle, HC-Specified | OK |
| 2 | P00001380 | Q0115023 | Refer | Q0132762 | Yes | 5623.34 | 8208.09 | Vehicle | OK |
| 3 | P00007821 | Q0115026 | Approve | Q0132763 | No | - | - | Vehicle | AU PartyID blocker |
| 4 | P00009655 | Q0115027 | Refer | Q0132764 | Yes | 2581.22 | 6616.58 | Vehicle, HB-UW, HC-UW, HC-Clause, HC-Specified | OK |
| 5 | P00009818 | Q0115028 | Refer | Q0132765 | No | 0 | 5835.29 | HC-Specified | OK |
| 6 | P00009965 | Q0114981 | Approve | Q0132766 | Yes | 4090.12 | 0 | Vehicle | OK |
| 7 | P00010132 | Q0115020 | Approve | Q0132767 | No | 4919.68 | 0 | Vehicle | OK |
| 8 | P00010162 | Q0114998 | Refer | Q0132768 | No | 14921.6 | 14678.13 | Vehicle | OK (separate open PartyID/CML00001418 item — see notes) |
| 9 | P00010168 | Q0115008 | Refer | Q0132769 | Yes | 8787.93 | 5052.73 | Vehicle, HC-Exceed, HC-Specified | OK |
| 10 | P00014342 | Q0115017 | Refer | Q0132770 | Yes | 0 | 9336.42 | HB-UW, HC-UW | OK |
| 11 | P00017446 | Q0115019 | Refer | Q0132771 | No | - | - | Vehicle, HB-UW, HC-UW, HC-Clause, PM-Clause, HC-Specified | AU PartyID blocker |
| 12 | P00017491 | Q0115025 | Refer | Q0132772 | Yes | 0 | 4104.9 | - | OK |
| 13 | P00018498 | Q0114995 | Refer | Q0132773 | No | 0 | 3799.2 | - | OK |
| 14 | P00018499 | Q0115003 | Refer | Q0132774 | No | 0 | 2615.34 | - | OK |
| 15 | P00020329 | Q0115012 | Refer | Q0132775 | No | 0 | 6380.41 | - | OK |
| 16 | P00023281 | Q0115014 | Refer | Q0132776 | Yes | 0 | 5935.34 | - | OK |
| 17 | P00023285 | Q0114983 | Refer | Q0132777 | No | 0 | 7965.31 | - | OK |
| 18 | P00024003 | Q0115021 | Refer | Q0132778 | No | 0 | 2917.97 | - | OK |
| 19 | P00026339 | Q0114997 | Approve | Q0132779 | No | 3234.54 | 0 | Vehicle | OK (client-reported CommercialVehicle mislabel — fixed) |
| 20 | P00026345 | Q0115006 | Refer | Q0132780 | No | 6103.14 | 4029.37 | Vehicle | OK (client-reported CommercialVehicle mislabel — fixed) |
| 21 | P00026440 | Q0114985 | Approve | Q0132781 | No | 2767.68 | 0 | Vehicle, PM-UW | OK |
| 22 | P00026511 | Q0115024 | Refer | Q0132782 | No | 0 | 3948.48 | - | OK |
| 23 | P00026578 | Q0114996 | Refer | Q0132783 | No | 0 | 3763.84 | HC-Specified | OK |
| 24 | P00026579 | Q0115001 | Refer | Q0132784 | Yes | 0 | 487.17 | - | OK |
| 25 | P00026585 | Q0115010 | Refer | Q0132785 | No | 5166.84 | 4068.59 | Vehicle | OK |
| 26 | P00026586 | Q0114978 | Refer | Q0132786 | No | 8276.8 | 11887.73 | Vehicle, HC-Specified | OK |
| 27 | P00026642 | Q0115018 | Approve | Q0132787 | No | 8708.53 | 0 | Vehicle | OK |
| 28 | P00026900 | Q0114992 | Refer | Q0132788 | No | - | - | HB-UW, HC-UW, HC-Specified | AU PartyID blocker |
| 29 | P00026916 | Q0115002 | Refer | Q0132789 | No | 0 | 6387.59 | HC-Specified | OK |
| 30 | P00027855 | Q0115011 | Approve | Q0132790 | No | 401.01 | 0 | Vehicle | OK |
| 31 | P00029182 | Q0114980 | Refer | Q0132791 | Yes | 0 | 15406.62 | HB-UW, HC-UW, HC-Specified | OK |
| 32 | P00030024 | Q0115013 | Refer | Q0132792 | Yes | 3283.49 | 6157.2 | Vehicle | OK |
| 33 | P00030171 | Q0114994 | Refer | Q0132793 | Yes | 1714.81 | 4122.51 | Vehicle | NZ phone warning (premium OK) |
| 34 | P00030895 | Q0115004 | Refer | Q0132794 | No | 0 | 3366.82 | - | OK |
| 35 | P00034443 | Q0114999 | Refer | Q0132795 | Yes | 1453.86 | 5531.82 | Vehicle, HC-Specified | NZ phone warning (premium OK) |
| 36 | P00034444 | Q0115007 | Approve | Q0132796 | Yes | 0 | 0 | HB-UW | NZ phone warning — **$0 premium, needs check** |
| 37 | P00034447 | Q0115016 | Refer | Q0132797 | Yes | 0 | 2931.6 | HB-UW | NZ phone warning (premium OK) |
| 38 | P00034501 | Q0115022 | Approve | Q0132798 | No | - | - | Vehicle | AU PartyID blocker |
| 39 | P00034504 | Q0114979 | Refer | Q0132799 | No | 0 | 5154 | - | OK |
| 40 | P00034510 | Q0115009 | Approve | Q0132800 | No | 1008 | 0 | Vehicle | OK |
| 41 | P00034514 | Q0114991 | Refer | Q0132801 | No | 0 | 3615.98 | - | OK |
| 42 | P00034531 | Q0115000 | Refer | Q0132802 | No | 0 | 1179.52 | - | OK |
| 43 | P00034535 | Q0114982 | Approve | Q0132803 | No | 5965.02 | 0 | Vehicle | OK |
| 44 | P00034541 | Q0115029 | Refer | Q0132804 | No | 0 | 1679.78 | - | OK |
| 45 | P00034583 | Q0114993 | Approve | Q0132805 | Yes | 291 | 0 | Vehicle | NZ phone warning (premium OK) |
| 46 | P00036708 | Q0115005 | Approve | Q0132806 | No | 6376.8 | 0 | Vehicle, PM-UW | OK |

## Summary counts

- **46** total policies
- **38** clean (OK)
- **4** AU PartyID blocker — not fixed, escalated separately, premium doesn't compute
- **5** NZ phone warning — non-blocking for 4, premium computes fine; 1 (P00034444) needs a check
- **13** blank Party ID (culture=en-NZ workaround scope)
- **24** have vehicles (Motor coverage)
- **7** Home Building UW adjustment, **5** Home Contents UW adjustment, **2** Vehicle UW adjustment
- **2** Home Contents clause, **1** Motor clause
- **1** Home Contents items-over-limit, **11** Home Contents specified items

## Data source

Built from `uat_batch_dev_results.json` (original batch run) merged with live lookups against
`BUILDING_UW`, `PER_HC_BUILDING_UW`, `PER_PM_BUILDING_UW`, `HB_CLAUSE`, `PER_HC_CLAUSE`, `COM_CLAUSE`,
`PER_HC_ITEMS_EXCEED_VALUE`, `PER_HC_SPECIFIEDCONTENTS`, `PM_03`. Same source data used to build
[UI_Test_Matrix_20260716.md](UI_Test_Matrix_20260716.md).
