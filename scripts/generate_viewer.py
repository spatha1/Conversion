#!/usr/bin/env python3
"""
Generate BP_PureToWrite_Viewer.html
Standalone interactive SAS vs Snowflake comparison for the BP Pure-to-Write SP.
"""
import re, json, os

SP_PATH = r'C:\Users\Admin-1\Desktop\Conversion\sql\snowflake\1_conversion\BP\sps\DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD_LIVE.sql'
OUT_PATH = r'C:\Users\Admin-1\Desktop\Conversion\docs\BP_PureToWrite_Viewer.html'

# ---------------------------------------------------------------------------
# READ SP
# ---------------------------------------------------------------------------
print("Reading SP...")
with open(SP_PATH, encoding='utf-8') as f:
    sp_text = f.read()
print(f"  {len(sp_text):,} chars, {sp_text.count(chr(10)):,} lines")

# ---------------------------------------------------------------------------
# EXTRACT SECTIONS  (skip commented-out --; lines)
# ---------------------------------------------------------------------------
PAT = re.compile(
    r'^(?![ \t]*--)[ \t]*;?[ \t]*CREATE[ \t]+OR[ \t]+REPLACE[ \t]+TRANSIENT[ \t]+TABLE[ \t]+AGGNE\.DEV\.(\w+)',
    re.IGNORECASE | re.MULTILINE
)
matches = list(PAT.finditer(sp_text))
print(f"  {len(matches)} active transient table CREATE statements found")

sections_by_name = {}
for i, m in enumerate(matches):
    name = m.group(1).upper()
    start = m.start()
    end = matches[i+1].start() if i+1 < len(matches) else len(sp_text)
    sql_raw = sp_text[start:end].strip()
    line_num = sp_text[:start].count('\n') + 1
    if name not in sections_by_name:
        sections_by_name[name] = {
            'name': m.group(1),          # preserve original casing
            'nameUpper': name,
            'line': line_num,
            'sql': sql_raw,
        }

print(f"  {len(sections_by_name)} unique sections")

# ---------------------------------------------------------------------------
# GROUPS
# ---------------------------------------------------------------------------
GROUPS = [
    {'id': 'sampling',      'label': 'Policy Sampling',              'icon': '📋', 'tables': [
        'SAMPLE_1','SAMPLE_PER','SAMPLE_PER_APPLICANT','SAMPLE_CBP','SAMPLE_CBP_',
        'SAMPLE_CBP_APPLICANT','SAMPLE_CBP_BUSINESS','SAMPLE_CBP_BUSINESSDETAIL',
        'SAMPLE_BP_CBP','SAMPLE_BP_PER','SAMPLE_FINAL',
    ]},
    {'id': 'add_interest',  'label': 'Additional Interest',          'icon': '🏦', 'tables': [
        'AI_01','AI_LOC','LOCATION_TRANSPOSED','AI_02','AI_LINE',
        'LINE_TRANSPOSED','AI_03','NO_LOC_LINE','AI_MERGED','ADDITIONAL_INTEREST',
    ]},
    {'id': 'claim_history', 'label': 'Claim History',                'icon': '📜', 'tables': [
        'CBP_CLAIMHISTORY_A','CBP_CLAIMHISTORY_B','CBP_CLAIMHISTORY_C','CBP_CLAIMHISTORY_D',
        'PER_CLAIMHISTORY_A','PER_CLAIMHISTORY_B','PER_CLAIMHISTORY_C','PER_CLAIMHISTORY_D',
        'CLAIMHISTORY',
    ]},
    {'id': 'competitor',    'label': 'Competitor & Disclosure',      'icon': '🤝', 'tables': [
        'CBP_COMPETITOR_INFORMATION','PER_COMPETITOR_INFORMATION','COMPETITOR_INFORMATION',
        'CBP_DUTY_DISCLOSURE','DUTY_DISCLOSURE',
    ]},
    {'id': 'biz_info',      'label': 'Business Info & ANZSIC',       'icon': '🏢', 'tables': [
        'BUSINESS_PROTECTIONS_01','BUSINESS_PROTECTIONS_02','PROTECTION_TERM',
        'ANZSIC_RANK_01','ANZSIC_RANK_02','ANZSIC_RANK_03','ANZSIC_RANK_04',
        'BUSINESS_INFO_01','BUSINESS_INFO_02','BUSINESSDETAILS_FINAL',
    ]},
    {'id': 'comm_vehicles', 'label': 'Commercial Vehicles',          'icon': '🚛', 'tables': [
        'SAMPLE_CBP_COMMERCIALVECHICLE','CM_01','CM_02','CM_03',
    ]},
    {'id': 'fleet',         'label': 'Fleet Vehicles',               'icon': '🚌', 'tables': [
        'SAMPLE_CBP_FLEETVEHICLE','FL_01','VEHICLECOVERAGES_FLEETVEHICLE',
    ]},
    {'id': 'location',      'label': 'Location',                     'icon': '📍', 'tables': [
        'SAMPLE_CBP_LOCATION','SAMPLE_CBP_LOCATIONDETAIL','LOCATION_01','LOCATIONDETAILS_PER',
    ]},
    {'id': 'cv_gp_gt',      'label': 'Commercial Building / Property','icon': '🏗️', 'tables': [
        'CV_01','LINE_CV_COVERAGE',
        'GP_01','GP_SPSTOCK','GP_OTHERPROP','GP','LINE_GP_COVERAGE',
        'GT_01','LINE_GT_COVERAGE',
    ]},
    {'id': 'liability',     'label': 'Liability & Legal',             'icon': '⚖️', 'tables': [
        'LE_01','LINE_LE_COVERAGE',
        'PF_01','LINE_PROFESSIONALPROTECTION_COVERAGE',
        'PP_01','LINE_PUBLICLIABILITY_COVERAGE',
        'SV_01','LINE_SV_COVERAGE',
    ]},
    {'id': 'bldg_contents', 'label': 'Building & Contents',          'icon': '🏠', 'tables': [
        'TA_01','BB_01','LOCATION_BB_COVERAGE','BG_01','BC_01',
    ]},
    {'id': 'bi',            'label': 'Business Interruption',        'icon': '📊', 'tables': [
        'BI_01','LOCATION_BI_COVERAGE',
    ]},
    {'id': 'engineering',   'label': 'Engineering',                  'icon': '⚙️', 'tables': [
        'EN_01','LOCATION_EN_COVERAGE',
    ]},
    {'id': 'private_motor', 'label': 'Private Motor',                'icon': '🚗', 'tables': [
        'SAMPLE_PRIVATEMOTOR_PER','MY_01','PM_01','PM_02','PM_03',
    ]},
    {'id': 'manual_ref',    'label': 'Manual Referrals',             'icon': '📝', 'tables': [
        'MANUALREF_01_BSP','ADJUSTMENTNOTE_01_BSP','MANUALREF_BSP',
        'MANUALREF_01_PER','ADJUSTMENTNOTE_01_PER','ADJUSTMENTNOTE_PER',
        'MANUALREF_02_PER','MANUALREF_PER',
    ]},
    {'id': 'policy_admin',  'label': 'Policy Admin',                 'icon': '🗂️', 'tables': [
        'ACCOUNT_HANDLER','CLAUSES',
    ]},
]

# ---------------------------------------------------------------------------
# SAS SNIPPETS FOR FIXED SECTIONS
# ---------------------------------------------------------------------------
SAS_KNOWN = {
    'CBP_CLAIMHISTORY_B': {
        'code': """\
/* CBP_CLAIMHISTORY_b  SAS DATA Step */
/* Source: BP SAS conversion script (Capricorn) */

DATA CBP_CLAIMHISTORY_b;
  SET CBP_CLAIMHISTORY_a;

  /* Step 1: Derive Line from numeric Line_Temp code */
  IF Line_temp IN (1,2,3)                  THEN Line = 'Motor';
  ELSE IF Line_temp IN (4,5)               THEN Line = 'Liability';
  ELSE IF Line_temp IN (6,7,8,9,10,11,12,13) THEN Line = 'Property';
  ELSE                                          Line = 'Other';

  /* Step 2: Classify Cause using Line (SAS — last matching IF wins) */

  /* Motor */
  IF Line='Motor' AND INDEX(UPCASE(Cause_Temp),'AT FAULT')>0
    THEN Cause = 'At Fault';
  /* Next IF runs AFTER the above — overrides when NOT AT FAULT found */
  IF Line='Motor' AND INDEX(UPCASE(Cause_Temp),'NOT AT FAULT')>0
    THEN Cause = 'Not At Fault';           /* last IF wins: correct */
  IF Line='Motor' AND (INDEX(UPCASE(Cause_Temp),'THEFT')>0
    OR INDEX(UPCASE(Cause_Temp),'BURGLAR')>0)
    THEN Cause = 'Theft';

  /* Property */
  IF Line='Property' AND INDEX(UPCASE(Cause_Temp),'FIRE')>0   THEN Cause='Fire';
  IF Line='Property' AND INDEX(UPCASE(Cause_Temp),'FLOOD')>0  THEN Cause='Flood';
  IF Line='Property' AND INDEX(UPCASE(Cause_Temp),'BURGLAR')>0 THEN Cause='Burglary';

  /* Liability */
  IF Line='Liability' AND INDEX(UPCASE(Cause_Temp),'PROPERT')>0
    THEN Cause='Customer Property Damage';
  IF Line='Liability' AND INDEX(UPCASE(Cause_Temp),'INJUR')>0
    THEN Cause='Customer Injury';
RUN;""",
        'fixes': [
            "[C2-CBP] NOT AT FAULT / AT FAULT order: 'NOT AT FAULT' contains the substring 'AT FAULT'. In SAS, sequential IFs run in order — last matching IF wins, so NOT AT FAULT correctly overrides AT FAULT. In SQL CASE WHEN, first matching WHEN wins — original code had AT FAULT first, misclassifying NOT AT FAULT claims. Fix: put NOT AT FAULT BEFORE AT FAULT in CASE WHEN.",
            "[C3-CBP] Lateral alias restriction: Snowflake cannot reference a column alias defined earlier in the same SELECT clause. Line was computed from Line_temp and immediately used by the Cause CASE in the same SELECT — illegal. Fix: two nested subqueries — inner derives Line from Line_temp; outer references Line to compute Cause.",
        ],
        'status': 'fixed',
    },
    'LE_01': {
        'code': """\
/* LE_01  Legal Expenses Cover  SAS DATA Step */
/* Source: BP SAS conversion script (Capricorn) */

DATA LE_01;
  SET source;

  /* LegalDisputeActions */
  /* SAS: . is the missing/null value  */
  IF LELegalDispute IN (., 2)  THEN LegalDisputeActions = '';  /* null or No */
  ELSE IF LELegalDispute = 1   THEN LegalDisputeActions = 'Yes';

  /* Redundancies */
  IF LERedundancies IN (., 2)  THEN Redundancies = '';         /* null or No */
  ELSE IF LERedundancies = 1   THEN Redundancies = 'Yes';

  /* ... other LE fields ... */
RUN;""",
        'fixes': [
            "[Fix 1] LegalDisputeActions: SAS IN (., 2) — the dot (.) is SAS missing value, equivalent to NULL in SQL. SQL must use (t3.LELegalDispute IS NULL OR t3.LELegalDispute = 2). Writing IN (NULL, 2) is WRONG — NULL never matches IN comparisons in SQL.",
            "[Fix 2] Redundancies: same IS NULL pattern applied to LERedundancies → Redundancies field.",
        ],
        'status': 'fixed',
    },
    'SV_01': {
        'code': """\
/* SV_01  Special / Unregistered Vehicles Cover  SAS DATA Step */
/* Source: BP SAS conversion script (Capricorn) */

DATA SV_01;
  SET source;

  /* DoYouHaveADealersLicense */
  /* SAS: . (missing) and 2 (No) both map to empty string */
  IF UVDealersLicence IN (., 2)  THEN DoYouHaveADealersLicense = '';
  ELSE IF UVDealersLicence = 1   THEN DoYouHaveADealersLicense = 'Yes';

  /* ... other SV fields ... */
RUN;""",
        'fixes': [
            "[Fix 3] DoYouHaveADealersLicense: SAS IN (., 2) uses dot for missing value. SQL equivalent: (t3.UVDealersLicence IS NULL OR t3.UVDealersLicence = 2).",
        ],
        'status': 'fixed',
    },
    'BI_01': {
        'code': """\
/* BI_01  Business Interruption  SAS DATA Step */
/* Source: BP SAS conversion script (Capricorn) */

DATA BI_01;
  SET source;

  /* VoluntaryExcess — SAS sequential IF (last matching IF wins) */
  IF BIVoluntary = ''                     THEN VoluntaryExcess = '';
  IF BIVoluntary = 0                      THEN VoluntaryExcess = 'N/A';
  IF BIVoluntary = '' AND BIGrossProfit>0 THEN VoluntaryExcess = 'N/A';
  ELSE VoluntaryExcess = '5 days';

  /* Effective priority (last wins):
       GrossProfit>0 AND empty  =>  N/A       (highest)
       Voluntary = 0            =>  N/A
       Voluntary = ''           =>  ''
       else                     =>  5 days    (lowest)
  */
RUN;""",
        'fixes': [
            "[Fix 4] VoluntaryExcess CASE order: SAS last-IF-wins means 'BIVoluntary empty AND BIGrossProfit>0 → N/A' has highest priority. SQL CASE first-WHEN-wins must mirror this: the GrossProfit check MUST appear first, before the simple empty-string check. Original code had them reversed.",
        ],
        'status': 'fixed',
    },
    'CM_02': {
        'code': """\
/* CM_02  Commercial Vehicles — Override carry-through  SAS DATA Step */
/* Source: BP SAS conversion script (Capricorn) */

DATA CM_02;
  SET CM_01;

  /* If no Redbook vehicle key found, set Override = Yes */
  IF CMRBVehicleKey = '' THEN Override = 'Yes';
  /* If Redbook key exists, keep the Override value from PURE source */
RUN;""",
        'fixes': [
            "[Fix 5] Override carry-through: original SQL set Override = 'Yes' unconditionally, discarding the PURE source value when a Redbook key existed. Fix: CASE WHEN CMRBVehicleKey is empty THEN 'Yes' ELSE carry through the existing Override column from the source.",
        ],
        'status': 'fixed',
    },
}

# ---------------------------------------------------------------------------
# DESCRIPTIONS
# ---------------------------------------------------------------------------
DESCS = {
    'SAMPLE_PER':'Initial PER (personal) policy sample from PURE source, filtered by policy type and date range',
    'SAMPLE_PER_APPLICANT':'Applicant-level join to sampled PER policies',
    'SAMPLE_CBP_':'Initial CBP (commercial business package) policy sample',
    'SAMPLE_CBP_BUSINESS':'Business-level attributes for sampled CBP policies',
    'SAMPLE_CBP_BUSINESSDETAIL':'Detailed business information for CBP policies',
    'SAMPLE_CBP_COMMERCIALVECHICLE':'Commercial vehicle records linked to CBP policies',
    'SAMPLE_CBP_FLEETVEHICLE':'Fleet vehicle records linked to CBP policies',
    'SAMPLE_CBP_LOCATION':'Location records for CBP policies',
    'SAMPLE_CBP_LOCATIONDETAIL':'Detailed location attributes for CBP policies',
    'SAMPLE_BP_CBP':'Business Package CBP sample — includes line-level coverage indicators (RLCV, RLGP, RLGT …)',
    'SAMPLE_BP_PER':'Business Package PER sample — includes line-level coverage indicators',
    'SAMPLE_FINAL':'Final merged sample combining CBP and PER base policy data',
    'SAMPLE_PRIVATEMOTOR_PER':'Private Motor PER policy sample',
    'AI_LOC':'Additional Interest — location pre-aggregation',
    'LOCATION_TRANSPOSED':'Location data transposed from rows to columns',
    'AI_02':'Additional Interest — step 2 joins',
    'AI_LINE':'Additional Interest — line-level records',
    'LINE_TRANSPOSED':'Line data transposed from rows to columns',
    'AI_03':'Additional Interest — step 3 with AI type classification',
    'NO_LOC_LINE':'Policies with no location/line match — separate handling path',
    'AI_MERGED':'All Additional Interest records merged (loc + line + no-loc)',
    'ADDITIONAL_INTEREST':'Final Additional Interest output table',
    'CBP_CLAIMHISTORY_A':'Claim History — raw CBP claims from PURE source (numeric Line_temp codes)',
    'CBP_CLAIMHISTORY_B':'Claim History — Line classification (Motor/Liability/Property) and Cause string mapping from numeric codes',
    'CBP_CLAIMHISTORY_C':'Claim History — CBP policy join and enrichment',
    'CBP_CLAIMHISTORY_D':'Claim History — CBP pivoted final output (ClaimHistory1 … ClaimHistory5)',
    'PER_CLAIMHISTORY_B':'Claim History — PER Line/Cause classification (same pattern as CBP_b)',
    'PER_CLAIMHISTORY_C':'Claim History — PER policy join and enrichment',
    'PER_CLAIMHISTORY_D':'Claim History — PER pivoted final output',
    'CLAIMHISTORY':'Claim History — merged CBP + PER final output table',
    'CBP_COMPETITOR_INFORMATION':'Competitor insurer details for CBP policies',
    'PER_COMPETITOR_INFORMATION':'Competitor insurer details for PER policies',
    'COMPETITOR_INFORMATION':'Merged competitor information (CBP + PER)',
    'CBP_DUTY_DISCLOSURE':'Duty of Disclosure flag for CBP policies',
    'DUTY_DISCLOSURE':'Final Duty of Disclosure output',
    'BUSINESS_PROTECTIONS_01':'Business Protections cover — step 1',
    'BUSINESS_PROTECTIONS_02':'Business Protections cover — step 2 deduplication',
    'PROTECTION_TERM':'Protection period / term derivation',
    'ANZSIC_RANK_01':'ANZSIC industry classification — step 1 initial ranking by coverage count',
    'ANZSIC_RANK_02':'ANZSIC — step 2 primary industry selection',
    'ANZSIC_RANK_03':'ANZSIC — step 3',
    'ANZSIC_RANK_04':'ANZSIC — step 4 final code assignment',
    'BUSINESS_INFO_01':'Business details aggregation — step 1',
    'BUSINESS_INFO_02':'Business details aggregation — step 2',
    'BUSINESSDETAILS_FINAL':'Final business details output (ANZSIC + business attributes)',
    'CM_01':'Commercial Vehicles — step 1: Redbook lookup and raw vehicle attribute mapping',
    'CM_02':'Commercial Vehicles — step 2: Override flag carry-through from PURE source',
    'CM_03':'Commercial Vehicles — step 3: final formatting and field selection',
    'FL_01':'Fleet Vehicles — vehicle attribute mapping and coverage derivation',
    'VEHICLECOVERAGES_FLEETVEHICLE':'Fleet Vehicle coverage line output table',
    'LOCATION_01':'Location — step 1 attribute mapping',
    'LOCATIONDETAILS_PER':'Location details for PER policies',
    'CV_01':'Commercial Building — Contents Value (CV) coverage',
    'LINE_CV_COVERAGE':'CV coverage indicator line output',
    'GP_SPSTOCK':'General Property — Special Stock sub-section',
    'GP_OTHERPROP':'General Property — Other Property sub-section',
    'GP':'General Property — merged SP Stock + Other Property',
    'LINE_GP_COVERAGE':'GP coverage indicator line output',
    'GT_01':'Glass & Theft (GT) coverage',
    'LINE_GT_COVERAGE':'GT coverage indicator line output',
    'LE_01':'Legal Expenses (LE) coverage — LegalDisputeActions + Redundancies fields',
    'LINE_LE_COVERAGE':'LE coverage indicator line output',
    'PF_01':'Professional Fees / Management Liability (PF) coverage',
    'LINE_PROFESSIONALPROTECTION_COVERAGE':'PF coverage indicator line output',
    'PP_01':'Product & Public Liability (PP) coverage',
    'LINE_PUBLICLIABILITY_COVERAGE':'PP coverage indicator line output',
    'SV_01':'Special / Unregistered Vehicles (SV) coverage — DoYouHaveADealersLicense',
    'LINE_SV_COVERAGE':'SV coverage indicator line output',
    'TA_01':'Transit / Goods in Transit (TA) coverage',
    'BB_01':'Burglary & Theft (BB) building coverage',
    'LOCATION_BB_COVERAGE':'BB coverage by location',
    'BC_01':'Building & Contents (BC) coverage',
    'BI_01':'Business Interruption (BI) — VoluntaryExcess and core BI fields',
    'LOCATION_BI_COVERAGE':'BI coverage by location',
    'EN_01':'Engineering / Machinery Breakdown (EN) coverage',
    'LOCATION_EN_COVERAGE':'EN coverage by location',
    'PM_01':'Private Motor — step 1: vehicle and primary coverage attributes',
    'PM_02':'Private Motor — step 2: driver details and additional coverages',
    'PM_03':'Private Motor — step 3: final output formatting',
    'MANUALREF_01_BSP':'Manual Referrals — Business Packages step 1',
    'ADJUSTMENTNOTE_01_BSP':'Adjustment Notes — Business Packages step 1',
    'MANUALREF_01_PER':'Manual Referrals — PER step 1',
    'ADJUSTMENTNOTE_01_PER':'Adjustment Notes — PER step 1',
    'ADJUSTMENTNOTE_PER':'Adjustment Notes — PER merged',
    'MANUALREF_02_PER':'Manual Referrals — PER step 2',
    'MANUALREF_PER':'Manual Referrals — PER final',
    'SAMPLE_1':'Initial policy sample — step 1 base filter',
    'SAMPLE_CBP':'CBP policy sample (pre-detail)',
    'SAMPLE_CBP_APPLICANT':'CBP applicant-level sample',
    'AI_01':'Additional Interest — step 1 raw extraction',
    'PER_CLAIMHISTORY_A':'Claim History — raw PER claims from PURE source (numeric Line_temp codes)',
    'GP_01':'General Property — step 1 base extraction',
    'BG_01':'Burglary / Glass — coverage data step 1',
    'MY_01':'Motor / Machinery — intermediate coverage step',
    'MANUALREF_BSP':'Manual Referrals — Business Packages merged',
    'ACCOUNT_HANDLER':'Account Handler details linked to policy',
    'CLAUSES':'Policy clauses / endorsements',
}

# ---------------------------------------------------------------------------
# BUILD DATA
# ---------------------------------------------------------------------------
js_sections = []
js_groups   = []
seen_in_group = set()

for g in GROUPS:
    items_for_group = []
    for tname in g['tables']:
        sec = sections_by_name.get(tname)
        if sec is None:
            # try trimming trailing underscore or check alternate casing
            continue
        sas_info = SAS_KNOWN.get(tname, None)
        slug = tname.lower().replace('_', '-')
        if slug in seen_in_group:
            continue
        seen_in_group.add(slug)

        entry = {
            'id':       slug,
            'name':     sec['name'],
            'group':    g['id'],
            'line':     sec['line'],
            'sql':      sec['sql'],
            'desc':     DESCS.get(tname, ''),
            'sasCode':  sas_info['code']  if sas_info else None,
            'fixes':    sas_info['fixes'] if sas_info else [],
            'status':   sas_info['status'] if sas_info else 'pending',
        }
        js_sections.append(entry)
        items_for_group.append({
            'id':     slug,
            'name':   sec['name'],
            'status': entry['status'],
        })

    if items_for_group:
        js_groups.append({
            'id':    g['id'],
            'label': g['label'],
            'icon':  g['icon'],
            'items': items_for_group,
        })

# Sections not assigned to any group (catch-all)
ungrouped = []
for name_upper, sec in sections_by_name.items():
    slug = name_upper.lower().replace('_', '-')
    if slug not in seen_in_group:
        ungrouped.append(sec['name'])
if ungrouped:
    print(f"  Ungrouped tables: {ungrouped}")

sections_json = json.dumps(js_sections, ensure_ascii=False, separators=(',', ':'))
groups_json   = json.dumps(js_groups,   ensure_ascii=False, separators=(',', ':'))

print(f"  {len(js_sections)} sections in {len(js_groups)} groups")

# ---------------------------------------------------------------------------
# HTML TEMPLATE
# ---------------------------------------------------------------------------
html_out = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>BP Pure→Write: SAS vs Snowflake</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;font-size:14px;background:#f0f2f5;color:#1a1a2e;height:100vh;display:flex;flex-direction:column}
/* HEADER */
#header{background:#1a1a2e;color:#fff;padding:12px 20px;display:flex;align-items:center;gap:16px;flex-shrink:0;box-shadow:0 2px 8px rgba(0,0,0,.35)}
#header h1{font-size:16px;font-weight:600;letter-spacing:.3px}
#header .sub{font-size:11px;color:#8892b0;margin-top:2px}
#search{margin-left:auto;padding:6px 12px;border:none;border-radius:6px;background:#2d3561;color:#cdd6f4;width:220px;font-size:13px;outline:none}
#search::placeholder{color:#6272a4}
#search:focus{background:#3d4571}
/* LAYOUT */
#app{display:flex;flex:1;overflow:hidden}
/* SIDEBAR */
#sidebar{width:270px;flex-shrink:0;background:#1e2035;overflow-y:auto;border-right:1px solid #2d3561;display:flex;flex-direction:column}
.group-header{padding:8px 14px 4px;font-size:10px;font-weight:700;color:#6272a4;letter-spacing:1px;text-transform:uppercase;margin-top:6px}
.group-header span{margin-right:5px}
.nav-item{display:flex;align-items:center;gap:6px;padding:5px 14px 5px 22px;cursor:pointer;color:#cdd6f4;font-size:12.5px;border-left:3px solid transparent;transition:background .12s}
.nav-item:hover{background:#2d3561;color:#fff}
.nav-item.active{background:#2d3561;border-left-color:#bd93f9;color:#fff;font-weight:600}
.nav-item.hidden{display:none}
.badge-fixed{width:8px;height:8px;border-radius:50%;background:#ff5555;flex-shrink:0}
.badge-pending{width:8px;height:8px;border-radius:50%;background:#44475a;flex-shrink:0}
/* MAIN */
#main{flex:1;overflow-y:auto;padding:24px;display:flex;flex-direction:column;gap:0}
#welcome{display:flex;flex-direction:column;align-items:center;justify-content:center;flex:1;color:#6272a4;text-align:center;gap:12px}
#welcome h2{font-size:22px;color:#8892b0}
#welcome p{max-width:480px;line-height:1.6;font-size:13px}
/* SECTION PANEL */
#panel{display:none;flex-direction:column;gap:16px}
#panel.visible{display:flex}
.panel-header{background:#fff;border-radius:10px;padding:16px 20px;box-shadow:0 1px 4px rgba(0,0,0,.08)}
.panel-title{font-size:18px;font-weight:700;color:#1a1a2e;margin-bottom:4px}
.panel-meta{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:8px}
.tag{padding:3px 10px;border-radius:12px;font-size:11px;font-weight:600}
.tag-line{background:#e8eaf6;color:#3949ab}
.tag-fixed{background:#ffebee;color:#c62828}
.tag-pending{background:#f3f4f6;color:#6b7280}
.tag-group{background:#e8f5e9;color:#2e7d32}
.panel-desc{font-size:13px;color:#555;line-height:1.5}
/* CODE PANELS */
.code-panels{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.code-panel{background:#fff;border-radius:10px;overflow:hidden;box-shadow:0 1px 4px rgba(0,0,0,.08)}
.code-panel-header{padding:10px 16px;font-size:12px;font-weight:700;letter-spacing:.5px;display:flex;align-items:center;gap:8px}
.sas-header{background:#1e3a5f;color:#90caf9}
.sql-header{background:#1a3a1a;color:#a5d6a7}
.no-sas-header{background:#2d2d2d;color:#9e9e9e}
.code-body{overflow:auto;max-height:520px}
pre.code{font-family:'Cascadia Code','Fira Code','Consolas',monospace;font-size:11.5px;line-height:1.55;padding:14px 16px;white-space:pre;tab-size:2;background:#282a36;color:#f8f8f2}
pre.code-sas{background:#0d2035;color:#cce7ff}
pre.code-no-sas{background:#1a1a1a;color:#555;font-style:italic}
/* FIX NOTES */
.fix-notes{background:#fff;border-radius:10px;padding:16px 20px;box-shadow:0 1px 4px rgba(0,0,0,.08)}
.fix-notes h3{font-size:13px;font-weight:700;color:#c62828;margin-bottom:10px;display:flex;align-items:center;gap:6px}
.fix-note{background:#fff8f8;border-left:3px solid #ef9a9a;padding:8px 12px;border-radius:0 6px 6px 0;margin-bottom:8px;font-size:12.5px;line-height:1.6;color:#333}
.fix-note:last-child{margin-bottom:0}
/* SCROLLBAR */
::-webkit-scrollbar{width:6px;height:6px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:#44475a;border-radius:3px}
</style>
</head>
<body>

<div id="header">
  <div>
    <h1>BP Pure&#8594;Write: SAS vs Snowflake</h1>
    <div class="sub">DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD &nbsp;&#x2022;&nbsp; All 6 fixes applied</div>
  </div>
  <input id="search" type="text" placeholder="Search tables..." oninput="filterNav(this.value)">
</div>

<div id="app">
  <div id="sidebar" id="sidebar"></div>
  <div id="main">
    <div id="welcome">
      <h2>BP Pure&#8594;Write Viewer</h2>
      <p>Select a table from the left sidebar to see the SAS source logic alongside the Snowflake SP implementation. Sections marked with a red dot contain confirmed fixes versus the original SAS logic.</p>
      <p style="margin-top:8px;font-size:12px;color:#44475a">&#x25CF; Red dot = Fix applied &nbsp; &#x25CF; Grey dot = Not yet cross-verified against SAS</p>
    </div>
    <div id="panel">
      <div class="panel-header">
        <div class="panel-title" id="ptitle"></div>
        <div class="panel-meta" id="pmeta"></div>
        <div class="panel-desc" id="pdesc"></div>
      </div>
      <div class="code-panels">
        <div class="code-panel">
          <div class="code-panel-header sas-header" id="sas-hdr">&#9654; SAS Logic</div>
          <div class="code-body"><pre class="code code-sas" id="sas-code"></pre></div>
        </div>
        <div class="code-panel">
          <div class="code-panel-header sql-header">&#9654; Snowflake SP (DEV)</div>
          <div class="code-body"><pre class="code" id="sql-code"></pre></div>
        </div>
      </div>
      <div class="fix-notes" id="fix-notes" style="display:none">
        <h3>&#9888; Fix Notes</h3>
        <div id="fix-list"></div>
      </div>
    </div>
  </div>
</div>

<script>
const SECTIONS = """ + sections_json + r""";
const GROUPS   = """ + groups_json   + r""";

const secById = {};
SECTIONS.forEach(s => secById[s.id] = s);

// ---- BUILD SIDEBAR ----
const sidebar = document.getElementById('sidebar');
GROUPS.forEach(g => {
  const hdr = document.createElement('div');
  hdr.className = 'group-header';
  hdr.innerHTML = `<span>${g.icon}</span>${g.label}`;
  sidebar.appendChild(hdr);
  g.items.forEach(item => {
    const div = document.createElement('div');
    div.className = 'nav-item';
    div.dataset.id = item.id;
    const dot = document.createElement('span');
    dot.className = item.status === 'fixed' ? 'badge-fixed' : 'badge-pending';
    div.appendChild(dot);
    const lbl = document.createElement('span');
    lbl.textContent = item.name;
    div.appendChild(lbl);
    div.addEventListener('click', () => showSection(item.id));
    sidebar.appendChild(div);
  });
});

// ---- SHOW SECTION ----
function showSection(id) {
  const sec = secById[id];
  if (!sec) return;

  // update nav
  document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
  const navEl = document.querySelector(`.nav-item[data-id="${id}"]`);
  if (navEl) navEl.classList.add('active');

  document.getElementById('welcome').style.display = 'none';
  const panel = document.getElementById('panel');
  panel.className = 'visible';

  // header
  document.getElementById('ptitle').textContent = sec.name;
  const meta = document.getElementById('pmeta');
  meta.innerHTML = '';
  meta.appendChild(mkTag(`Line ${sec.line}`, 'tag-line'));
  meta.appendChild(mkTag(groupLabel(sec.group), 'tag-group'));
  if (sec.status === 'fixed') meta.appendChild(mkTag('FIXED', 'tag-fixed'));
  else meta.appendChild(mkTag('Pending SAS Verification', 'tag-pending'));
  document.getElementById('pdesc').textContent = sec.desc || '';

  // SAS panel
  const sasHdr = document.getElementById('sas-hdr');
  const sasCode = document.getElementById('sas-code');
  if (sec.sasCode) {
    sasHdr.className = 'code-panel-header sas-header';
    sasHdr.textContent = '▶ SAS Logic';
    sasCode.className = 'code code-sas';
    sasCode.textContent = sec.sasCode;
  } else {
    sasHdr.className = 'code-panel-header no-sas-header';
    sasHdr.textContent = '▶ SAS Logic  (not yet mapped)';
    sasCode.className = 'code code-no-sas';
    sasCode.textContent = 'SAS logic for this section has not yet been cross-verified.\n\nSAS source files:\n  Businessbuilding, businessContents and Money\n    conversionscriptCapricorn.txt\n  PrivateMotor_conversionscriptCapricorn.txt';
  }

  // SQL panel
  document.getElementById('sql-code').textContent = sec.sql;

  // Fix notes
  const fixNotes = document.getElementById('fix-notes');
  const fixList  = document.getElementById('fix-list');
  if (sec.fixes && sec.fixes.length > 0) {
    fixNotes.style.display = '';
    fixList.innerHTML = '';
    sec.fixes.forEach(f => {
      const d = document.createElement('div');
      d.className = 'fix-note';
      d.textContent = f;
      fixList.appendChild(d);
    });
  } else {
    fixNotes.style.display = 'none';
  }
}

function mkTag(text, cls) {
  const s = document.createElement('span');
  s.className = 'tag ' + cls;
  s.textContent = text;
  return s;
}

function groupLabel(gid) {
  const g = GROUPS.find(x => x.id === gid);
  return g ? g.label : gid;
}

// ---- SEARCH / FILTER ----
function filterNav(q) {
  q = q.trim().toLowerCase();
  document.querySelectorAll('.nav-item').forEach(el => {
    const name = el.querySelector('span:last-child').textContent.toLowerCase();
    el.classList.toggle('hidden', q && !name.includes(q));
  });
}

// Auto-select first item
if (SECTIONS.length > 0) showSection(SECTIONS[0].id);
</script>
</body>
</html>
"""

# ---------------------------------------------------------------------------
# WRITE OUTPUT
# ---------------------------------------------------------------------------
os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
with open(OUT_PATH, 'w', encoding='utf-8') as f:
    f.write(html_out)

size_kb = os.path.getsize(OUT_PATH) / 1024
print(f"\nWrote: {OUT_PATH}")
print(f"  Size: {size_kb:.0f} KB")
print("Done.")
