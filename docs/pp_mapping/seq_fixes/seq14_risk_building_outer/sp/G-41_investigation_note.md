# G-41 — YearLastReWired / YearLastRePlumbed blank for old buildings

**Status:** Needs investigation before a fix can be drafted.

View (`PER_RISK_BUILDING_FINAL`) and seq 14 config token are both confirmed correct — 558 of 584
buildings aged 41+ (95.5%) still show blank, which contradicts the manuscript's stated rule
(blank only applies to buildings <41 years old). Root cause is upstream of the view, in whatever
populates the Locationdetails_PER-equivalent source columns — not yet located.

**Next step:** trace where YEARLASTREWIRED/YEARLASTREPLUMBED get populated before
PER_RISK_BUILDING_FINAL (likely the Pure-to-Write SP) and check the age-gate condition there.
