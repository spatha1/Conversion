"""Build COVERAGE_DROPDOWN.html from PL101 Excel files."""
import json, re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCRATCHPAD = Path(r"C:\Users\Admin-1\AppData\Local\Temp\claude\c--Users-Admin-1-Desktop-Conversion\c6f0c505-d521-49cf-82be-47aa8e1dd3a8\scratchpad")
OUT = ROOT / "sql" / "snowflake" / "prd" / "COVERAGE_DROPDOWN.html"

import openpyxl

def clean(v):
    if v is None: return ''
    return str(v).strip().replace('\n', ' | ').replace('\r', '').replace('\xa0', '')

def extract_cov_type(xpath):
    if not xpath: return None
    m = re.search(r'coverage\[Type="([^"]+)"\]', xpath)
    return m.group(1) if m else None

def read_all_sheets(path):
    wb = openpyxl.load_workbook(path, data_only=True)
    result = {}
    for sheet_name in wb.sheetnames:
        ws = wb[sheet_name]
        rows = [list(r) for r in ws.iter_rows(values_only=True)]
        header_idx = 0
        for i, r in enumerate(rows[:5]):
            vals = [str(v).strip() if v else '' for v in r]
            if any(k in vals for k in ['Field ID','Caption DC','Screen -DC','S.No']):
                header_idx = i; break
        headers = [str(h).strip() if h else f'c{j}' for j,h in enumerate(rows[header_idx])]
        norm = {}
        for h in headers:
            hl = h.lower()
            if 'field id' in hl or 'field in dc' in hl: norm[h] = 'field_id'
            elif 'caption' in hl: norm[h] = 'caption'
            elif 'data type' in hl: norm[h] = 'dtype'
            elif 'input type' in hl: norm[h] = 'input_type'
            elif 'options' in hl: norm[h] = 'options'
            elif 'required' in hl: norm[h] = 'required'
            elif 'default' in hl: norm[h] = 'default'
            elif 'path' in hl or 'xpath' in hl: norm[h] = 'xpath'
            elif 'rating' in hl or 'impact' in hl: norm[h] = 'rating'
            elif 'comment' in hl: norm[h] = 'comments'
            elif 'screen' in hl: norm[h] = 'screen'
            else: norm[h] = h.lower().replace(' ', '_')
        out = []
        for row in rows[header_idx+1:]:
            if not any(c is not None and str(c).strip() not in ('', 'None', '\xa0') for c in row):
                continue
            d = {}
            for j, h in enumerate(headers):
                if j < len(row):
                    v = row[j]
                    if v is not None and str(v).strip() not in ('', '\xa0', 'None'):
                        key = norm.get(h, h.lower().replace(' ', '_'))
                        d[key] = str(v).strip()
            if d: out.append(d)
        result[sheet_name] = out
    return result

def make_fields(rows, cov_map=None, single_key=None):
    by_cov = {}
    for r in rows:
        xp = clean(r.get('xpath', ''))
        caption = clean(r.get('caption', ''))
        if not caption or not xp: continue
        ct = extract_cov_type(xp)
        if single_key:
            key = single_key
        elif cov_map:
            key = cov_map.get(ct, ct or 'OTHER')
        else:
            key = ct or 'OTHER'
        raw_opts = r.get('options', '') or ''
        # Normalise: strip NA/same-as-caption noise, split multi-line into list
        opts_clean = str(raw_opts).strip().replace('\xa0', '')
        if opts_clean.lower() in ('na', 'n/a', '', caption.lower()):
            opts_list = []
        else:
            lines = [v.strip() for v in opts_clean.split('\n') if v.strip() and v.strip().lower() not in ('select', 'na', 'n/a')]
            opts_list = lines if len(lines) > 1 else ([opts_clean] if opts_clean else [])
        entry = {
            'caption': caption,
            'dtype': clean(r.get('dtype', '')),
            'input_type': clean(r.get('input_type', '')),
            'required': clean(r.get('required', '')),
            'default': clean(r.get('default', '')),
            'options': opts_list,
            'xpath': xp,
            'rating': clean(r.get('rating', '')),
            'comment': clean(r.get('comments', '')),
        }
        by_cov.setdefault(key, []).append(entry)
    return by_cov

LINECOV_MAP = {
    'GeneralProperty': 'GP', 'GoodsInTransit': 'GT', 'GoodsinTransit': 'GT',
    'PublicProductLiability': 'PPL', 'ProfessionalProtection': 'PF',
    'LegalExpenses': 'LE', 'TaxAudit': 'TA',
    'CustomerVehicles': 'CV', 'StockVehicles': 'SV',
}
PPLOCCOV_MAP = {'Building': 'HB', 'ContentsAndStocks': 'HC'}

bp_path = ROOT / "files" / "pl101" / "Conversion_Mapping_BP_PL101_V2.xlsx"
pp_path = ROOT / "files" / "pl101" / "Conversion_Mapping_PP_PL101_V1.xlsx"

print("Reading BP PL101...")
bp_data = read_all_sheets(bp_path)
print("Reading PP PL101...")
pp_data = read_all_sheets(pp_path)

bp_line_fields = make_fields(bp_data['Line Protection'], LINECOV_MAP)
pp_loc_fields  = make_fields(pp_data['Location Protection'], PPLOCCOV_MAP)
pp_pm_fields   = make_fields(pp_data['Private Motor Vehicles'], single_key='PM')

pl101 = {
    'BP': {
        'GP':  bp_line_fields.get('GP', []),
        'GT':  bp_line_fields.get('GT', []),
        'PPL': bp_line_fields.get('PPL', []),
        'PF':  bp_line_fields.get('PF', []),
        'LE':  bp_line_fields.get('LE', []),
        'TA':  bp_line_fields.get('TA', []),
        'CV':  bp_line_fields.get('CV', []),
        'SV':  bp_line_fields.get('SV', []),
    },
    'PP': {
        'HB': pp_loc_fields.get('HB', []),
        'HC': pp_loc_fields.get('HC', []),
        'PM': pp_pm_fields.get('PM', []),
    }
}

for lob, covs in pl101.items():
    for k, fields in covs.items():
        print(f"  {lob}.{k}: {len(fields)} fields")

pl101_js = json.dumps(pl101, ensure_ascii=False, separators=(',', ':'))
print(f"PL101 JSON size: {len(pl101_js):,} chars")

# ===== BUILD HTML =====
HTML_PARTS = []

HTML_PARTS.append(r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Policy Attach — Coverage & DCT Reference</title>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --bp:#1e40af;--bp-bg:#dbeafe;--pp:#065f46;--pp-bg:#d1fae5;
  --dark:#0f172a;--mid:#1e293b;--accent:#2563eb;
  --g1:#f8fafc;--g2:#f1f5f9;--g3:#e2e8f0;--g4:#94a3b8;--g5:#475569;
  --text:#1e293b;--r:8px;--sh:0 1px 4px rgba(0,0,0,.08)
}
body{font-family:'Segoe UI',system-ui,sans-serif;background:#eef2f7;color:var(--text);min-height:100vh}

/* HEADER */
.ah{background:linear-gradient(135deg,#0f172a,#1e3a5f);color:#fff;padding:0 28px;
    display:flex;align-items:center;gap:14px;height:58px;border-bottom:1px solid rgba(255,255,255,.08)}
.ah h1{font-size:1.05rem;font-weight:700;letter-spacing:-.01em}
.ah .sp{flex:1}
.hpills{display:flex;gap:7px}
.hp{background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.12);border-radius:20px;padding:3px 10px;font-size:.7rem;color:#cbd5e1}
.hp.live{background:rgba(16,185,129,.15);border-color:rgba(16,185,129,.3);color:#6ee7b7}

/* STAT BAR */
.sb{background:var(--mid);color:#fff;display:flex;overflow-x:auto;border-bottom:1px solid rgba(255,255,255,.06)}
.si{flex:1;min-width:110px;padding:10px 16px;border-right:1px solid rgba(255,255,255,.06);text-align:center}
.si .n{font-size:1.3rem;font-weight:800;color:#60a5fa;line-height:1}
.si .l{font-size:.62rem;color:#94a3b8;text-transform:uppercase;letter-spacing:.05em;margin-top:3px}

/* TABS */
.tb{background:#fff;border-bottom:2px solid var(--g3);display:flex;padding:0 28px}
.tbtn{padding:11px 18px;font-size:.84rem;font-weight:600;border:none;background:none;cursor:pointer;
      color:var(--g4);border-bottom:2px solid transparent;margin-bottom:-2px;
      display:flex;align-items:center;gap:7px;transition:color .15s,border-color .15s}
.tbtn:hover{color:var(--accent)}
.tbtn.active{color:var(--accent);border-bottom-color:var(--accent)}
.tbtn .bdg{background:#e2e8f0;color:#475569;border-radius:10px;padding:1px 7px;font-size:.67rem;font-weight:700}
.tbtn.active .bdg{background:#dbeafe;color:var(--accent)}

/* MAIN */
.main{padding:18px 28px}
.pane{display:none}.pane.active{display:block}

/* CTRL STRIP */
.cs{background:#fff;border:1px solid var(--g3);border-radius:var(--r);padding:13px 18px;
    display:flex;gap:14px;align-items:flex-end;flex-wrap:wrap;margin-bottom:16px;box-shadow:var(--sh)}
.cg{display:flex;flex-direction:column;gap:5px}
.cg label{font-size:.67rem;font-weight:800;color:var(--g5);text-transform:uppercase;letter-spacing:.05em}
select{border:1.5px solid var(--g3);border-radius:6px;padding:8px 32px 8px 12px;font-size:.88rem;
       background:#fff;cursor:pointer;appearance:none;min-width:220px;
       background-image:url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6'%3E%3Cpath d='M0 0l5 6 5-6z' fill='%2364748b'/%3E%3C/svg%3E");
       background-repeat:no-repeat;background-position:right 12px center;transition:border-color .15s}
select:focus{outline:none;border-color:var(--accent)}
.srch{border:1.5px solid var(--g3);border-radius:6px;padding:8px 12px;font-size:.88rem;min-width:200px}
.srch:focus{outline:none;border-color:var(--accent)}

/* CARD GRID */
.cgrid{display:flex;gap:9px;flex-wrap:wrap;margin-bottom:16px}
.cc{background:#fff;border:1.5px solid var(--g3);border-radius:var(--r);padding:11px 14px;
    min-width:120px;cursor:pointer;transition:border-color .15s,box-shadow .15s,transform .1s}
.cc:hover{border-color:var(--accent);box-shadow:0 4px 12px rgba(37,99,235,.1);transform:translateY(-1px)}
.cc.active{border-color:var(--accent);background:#eff6ff}
.cc .ck{font-size:.7rem;font-weight:800;color:var(--g4);text-transform:uppercase;letter-spacing:.06em;margin-bottom:3px}
.cc .cn{font-size:.86rem;font-weight:700;color:var(--dark);line-height:1.2}
.cc .cm{font-size:.68rem;color:var(--g4);margin-top:3px}
.cc.active .ck{color:var(--accent)}
.lchip{display:inline-block;background:var(--g2);border:1px solid var(--g3);color:var(--g5);
       border-radius:10px;padding:1px 7px;font-size:.63rem;font-weight:600;margin-top:3px}

/* PANEL */
.panel{background:#fff;border:1px solid var(--g3);border-radius:var(--r);overflow:hidden;box-shadow:var(--sh)}
.ph{background:linear-gradient(135deg,#0f172a,#1e3a5f);color:#fff;padding:11px 18px;
    display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.ph h2{font-size:.93rem;font-weight:700;flex:1}
.pm{font-size:.7rem;color:#94a3b8}
.lbdg{display:inline-block;padding:2px 11px;border-radius:20px;font-size:.7rem;font-weight:800;letter-spacing:.05em}
.lbdg.BP{background:var(--bp-bg);color:var(--bp)}
.lbdg.PP{background:var(--pp-bg);color:var(--pp)}

table{width:100%;border-collapse:collapse}
thead{background:var(--g1);position:sticky;top:0;z-index:1}
th{padding:8px 11px;text-align:left;font-size:.67rem;font-weight:800;color:var(--g5);
   text-transform:uppercase;letter-spacing:.06em;border-bottom:2px solid var(--g3);white-space:nowrap}
td{padding:9px 11px;font-size:.82rem;border-bottom:1px solid var(--g2);vertical-align:top}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#fafbff}
td.num{color:var(--g4);font-size:.7rem;white-space:nowrap}

/* PILLS */
.cpill{display:inline-block;background:var(--dark);color:#fff;padding:2px 8px;border-radius:4px;
       font-family:Consolas,monospace;font-size:.75rem;font-weight:600;letter-spacing:.02em}
.tpill{display:inline-block;background:#e0f2fe;color:#0369a1;padding:2px 7px;border-radius:4px;
       font-family:monospace;font-size:.72rem}
.dpill{display:inline-block;background:var(--g2);color:var(--g5);padding:1px 6px;border-radius:4px;
       font-family:monospace;font-size:.71rem;border:1px solid var(--g3)}
.pfield{display:inline-block;background:#f0fdf4;color:#065f46;padding:2px 6px;border-radius:3px;
        font-family:monospace;font-size:.72rem;border:1px solid #bbf7d0}
.xp{font-family:Consolas,monospace;font-size:.71rem;color:#475569;max-width:340px;
    overflow-wrap:break-word;word-break:break-all}
.cc-cell{color:var(--g4);font-size:.78rem;font-style:italic}
.nzbdg{display:inline-block;background:#fef3c7;color:#92400e;font-size:.63rem;font-weight:700;
       padding:1px 6px;border-radius:10px;margin-left:3px}
.ryes{color:#059669;font-weight:700;font-size:.73rem}
.rro{color:var(--g4);font-size:.73rem}
.rtyes{color:#7c3aed;font-size:.73rem;font-weight:700}
.tin{background:#ede9fe;color:#6d28d9;padding:1px 5px;border-radius:4px;font-size:.68rem;margin-left:3px}
.tout{background:#fce7f3;color:#9d174d;padding:1px 5px;border-radius:4px;font-size:.68rem;margin-left:3px}
.olist{display:flex;flex-wrap:wrap;gap:3px;max-width:220px}
.oval{display:inline-block;background:#f0f9ff;color:#0369a1;border:1px solid #bae6fd;border-radius:4px;padding:1px 6px;font-size:.69rem;white-space:nowrap}
.omore{display:inline-block;background:#f1f5f9;color:#94a3b8;border-radius:4px;padding:1px 6px;font-size:.68rem;font-style:italic}

/* STAGING STRIP */
.ss{background:var(--g1);border-top:1px solid var(--g3);padding:9px 14px;display:flex;gap:20px;flex-wrap:wrap}
.ss .sl{font-size:.7rem;color:var(--g5)}
.ss span{font-weight:700;color:#1e40af;font-family:monospace}

/* FLOW BOX */
.fbox{background:#fff;border:1px solid var(--g3);border-radius:var(--r);padding:14px 18px;
      margin-top:16px;box-shadow:var(--sh)}
.fbox h3{font-size:.68rem;color:var(--g5);font-weight:800;text-transform:uppercase;letter-spacing:.06em;margin-bottom:9px}
.fsteps{display:flex;align-items:center;gap:5px;flex-wrap:wrap}
.fs{background:#eff6ff;border:1px solid #bfdbfe;border-radius:6px;padding:4px 9px;font-family:monospace;font-size:.72rem;color:#1e40af}
.fa{color:var(--g4);font-size:.88rem}

/* PL101 INTRO */
.plintro{background:linear-gradient(135deg,#1e3a5f,#0f172a);color:#fff;border-radius:var(--r);
         padding:15px 18px;margin-bottom:14px;display:flex;gap:18px;align-items:center}
.plintro h2{font-size:.93rem;font-weight:700}
.plintro p{font-size:.76rem;color:#94a3b8;margin-top:3px}
.plstats{margin-left:auto;display:flex;gap:14px}
.plst{text-align:center}
.plst .n{font-size:1.25rem;font-weight:800;color:#60a5fa}
.plst .l{font-size:.6rem;color:#94a3b8}

/* SCROLLABLE */
.tw{overflow-x:auto;max-height:500px;overflow-y:auto}

@media(max-width:768px){
  .main{padding:12px 12px}
  .cs{padding:11px 12px}
  .ah{padding:0 12px}
  .tb{padding:0 12px}
}
</style>
</head>
<body>

<header class="ah">
  <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#60a5fa" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="3"/><path d="M9 9h6M9 12h6M9 15h4"/></svg>
  <h1>Policy Attach &mdash; Coverage &amp; DCT Reference</h1>
  <div class="sp"></div>
  <div class="hpills">
    <span class="hp live">AGGNE.PRD</span>
    <span class="hp">PRD_XML</span>
    <span class="hp">PL101 V2/V1</span>
    <span class="hp">2026-06-25</span>
  </div>
</header>

<div class="sb">
  <div class="si"><div class="n">8</div><div class="l">BP Line Covs</div></div>
  <div class="si"><div class="n">6</div><div class="l">BP Risk Covs</div></div>
  <div class="si"><div class="n">3</div><div class="l">PP Coverages</div></div>
  <div class="si"><div class="n">92</div><div class="l">Sub-Codes</div></div>
  <div class="si"><div class="n">180+</div><div class="l">PL101 Fields</div></div>
  <div class="si"><div class="n">22</div><div class="l">PRD Stored Procs</div></div>
  <div class="si"><div class="n">553</div><div class="l">PRD Objects</div></div>
</div>

<div class="tb">
  <button class="tbtn active" onclick="switchTab('cov')" id="tab-cov">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><rect x="3" y="3" width="18" height="18" rx="3"/><path d="M9 9h6M9 12h6M9 15h4"/></svg>
    Coverage Map &amp; Sub-Codes <span class="bdg">11 groups</span>
  </button>
  <button class="tbtn" onclick="switchTab('pl101')" id="tab-pl101">
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
    PL101 &mdash; DCT Field Rules <span class="bdg">11 screens</span>
  </button>
</div>

<div class="main">

<!-- TAB 1: COVERAGE MAP -->
<div class="pane active" id="pane-cov">
  <div class="cs">
    <div class="cg">
      <label>Line of Business</label>
      <select id="selLOB" onchange="onLOBChange()">
        <option value="">&#8212; Select LOB &#8212;</option>
        <option value="BP">BP &#8212; Business Pack</option>
        <option value="PP">PP &#8212; Personal Pack</option>
      </select>
    </div>
    <div class="cg">
      <label>Coverage Group</label>
      <select id="selCov" onchange="onCovChange()" disabled>
        <option value="">&#8212; Select Coverage &#8212;</option>
      </select>
    </div>
  </div>

  <div id="cardRow" class="cgrid" style="display:none"></div>

  <div id="covArea" class="panel" style="display:none">
    <div class="ph">
      <h2 id="covTitle">Sub-Coverages</h2>
      <span class="pm" id="covMeta"></span>
    </div>
    <div class="tw">
      <table>
        <thead><tr><th>#</th><th>Code</th><th>Type</th><th>Description</th><th>PURE / PRD Field</th><th>Condition</th></tr></thead>
        <tbody id="covBody"></tbody>
      </table>
    </div>
    <div class="ss" id="covStaging"></div>
  </div>

  <div class="fbox">
    <h3>Policy Attach Pipeline &#8212; 7 Steps (BP; PP mirrors same structure)</h3>
    <div style="overflow-x:auto">
    <table style="border-collapse:collapse;width:100%;font-size:.78rem;margin-top:6px">
      <thead>
        <tr style="background:#f1f5f9">
          <th style="padding:6px 10px;text-align:left;border-bottom:2px solid #e2e8f0;color:#475569;font-size:.67rem;text-transform:uppercase;letter-spacing:.05em;white-space:nowrap">Step</th>
          <th style="padding:6px 10px;text-align:left;border-bottom:2px solid #e2e8f0;color:#475569;font-size:.67rem;text-transform:uppercase;letter-spacing:.05em">Name</th>
          <th style="padding:6px 10px;text-align:left;border-bottom:2px solid #e2e8f0;color:#475569;font-size:.67rem;text-transform:uppercase;letter-spacing:.05em">SP / Script</th>
          <th style="padding:6px 10px;text-align:left;border-bottom:2px solid #e2e8f0;color:#475569;font-size:.67rem;text-transform:uppercase;letter-spacing:.05em">Location</th>
          <th style="padding:6px 10px;text-align:left;border-bottom:2px solid #e2e8f0;color:#475569;font-size:.67rem;text-transform:uppercase;letter-spacing:.05em">Notes</th>
        </tr>
      </thead>
      <tbody>
        <tr style="border-bottom:1px solid #f1f5f9"><td style="padding:7px 10px;white-space:nowrap"><span style="background:#1e40af;color:#fff;padding:2px 8px;border-radius:4px;font-weight:700;font-size:.72rem">1</span></td><td style="padding:7px 10px;font-weight:600">Pure To Write</td><td style="padding:7px 10px;font-family:monospace;font-size:.75rem;color:#1e40af">AGGNE.PRD.SP_POLCIY_ATTACH_PURE_TO_WRITE_LOAD</td><td style="padding:7px 10px"><span style="background:#ede9fe;color:#6d28d9;padding:1px 7px;border-radius:4px;font-size:.7rem">Snowflake PRD</span></td><td style="padding:7px 10px;color:#475569;font-size:.76rem">Extracts all PURE source tables into PRD _POLICYATTACH staging tables</td></tr>
        <tr style="border-bottom:1px solid #f1f5f9;background:#fafbff"><td style="padding:7px 10px;white-space:nowrap"><span style="background:#1e40af;color:#fff;padding:2px 8px;border-radius:4px;font-weight:700;font-size:.72rem">2</span></td><td style="padding:7px 10px;font-weight:600">DateDim &amp; Identifier Setup</td><td style="padding:7px 10px;font-family:monospace;font-size:.75rem;color:#1e40af">AGGNE.PRD.SP_Datedim_Identifier_Setup</td><td style="padding:7px 10px"><span style="background:#ede9fe;color:#6d28d9;padding:1px 7px;border-radius:4px;font-size:.7rem">Snowflake PRD</span></td><td style="padding:7px 10px;color:#475569;font-size:.76rem">Builds start&#8209;date&#8209;to&#8209;end&#8209;date <strong>DOL combinations</strong> per policy (~10 per policy). Any future DOL fits one combination. Re&#8209;runs if new transactions arrive.</td></tr>
        <tr style="border-bottom:1px solid #f1f5f9"><td style="padding:7px 10px;white-space:nowrap"><span style="background:#1e40af;color:#fff;padding:2px 8px;border-radius:4px;font-weight:700;font-size:.72rem">3</span></td><td style="padding:7px 10px;font-weight:600">Load Views</td><td style="padding:7px 10px;font-family:monospace;font-size:.75rem;color:#065f46">HB_BP_PolicyAttach_LoadViews<br><span style="color:#94a3b8">&#8627; PolicyAttach_LoadViews_and_LoadBucket</span></td><td style="padding:7px 10px"><span style="background:#d1fae5;color:#065f46;padding:1px 7px;border-radius:4px;font-size:.7rem">Conversion DB</span></td><td style="padding:7px 10px;color:#475569;font-size:.76rem">Loads config source tables into Snowflake views (the _IDENTIFIER + sub-coverage views)</td></tr>
        <tr style="border-bottom:1px solid #f1f5f9;background:#fafbff"><td style="padding:7px 10px;white-space:nowrap"><span style="background:#1e40af;color:#fff;padding:2px 8px;border-radius:4px;font-weight:700;font-size:.72rem">4</span></td><td style="padding:7px 10px;font-weight:600">Final Data Load</td><td style="padding:7px 10px;font-family:monospace;font-size:.75rem;color:#1e40af">AGGNE.PRD.LOAD_PA_BP_FINAL_OUPUT</td><td style="padding:7px 10px"><span style="background:#ede9fe;color:#6d28d9;padding:1px 7px;border-radius:4px;font-size:.7rem">Snowflake PRD</span></td><td style="padding:7px 10px;color:#475569;font-size:.76rem">Calls DYNAMIC_XML_V1 per config row; writes XML into *_TARGET tables; assembles into PRD_XML final table</td></tr>
        <tr style="border-bottom:1px solid #f1f5f9"><td style="padding:7px 10px;white-space:nowrap"><span style="background:#1e40af;color:#fff;padding:2px 8px;border-radius:4px;font-weight:700;font-size:.72rem">5</span></td><td style="padding:7px 10px;font-weight:600">Final XML Load</td><td style="padding:7px 10px;font-family:monospace;font-size:.75rem;color:#1e40af">AGGNE.PRD.POLICYATTACH_LOAD_FINALDATA_XML</td><td style="padding:7px 10px"><span style="background:#ede9fe;color:#6d28d9;padding:1px 7px;border-radius:4px;font-size:.7rem">Snowflake PRD</span></td><td style="padding:7px 10px;color:#475569;font-size:.76rem">Loads XML data into <span style="font-family:monospace;font-size:.73rem">PRD_XML.POLICYATTACH_MIGRATION_DCT</span> final table</td></tr>
        <tr style="border-bottom:1px solid #f1f5f9;background:#fafbff"><td style="padding:7px 10px;white-space:nowrap"><span style="background:#1e40af;color:#fff;padding:2px 8px;border-radius:4px;font-weight:700;font-size:.72rem">6</span></td><td style="padding:7px 10px;font-weight:600">Final Run (DCT)</td><td style="padding:7px 10px;font-family:monospace;font-size:.75rem;color:#065f46">PolicyAttach_FinalRun<br><span style="color:#94a3b8">&#8627; POLICYATTACH_UAT_BUCKET<br>&#8627; PolicyAttach_PRD_Request_Load_V1</span></td><td style="padding:7px 10px"><span style="background:#d1fae5;color:#065f46;padding:1px 7px;border-radius:4px;font-size:.7rem">Conversion DB</span></td><td style="padding:7px 10px;color:#475569;font-size:.76rem">Gets identifier + bucket from final table; POSTs DCT request with <strong>LegacyPolicyNumber + DOL</strong> per combination</td></tr>
        <tr><td style="padding:7px 10px;white-space:nowrap"><span style="background:#1e40af;color:#fff;padding:2px 8px;border-radius:4px;font-weight:700;font-size:.72rem">7</span></td><td style="padding:7px 10px;font-weight:600">Load API Table</td><td style="padding:7px 10px;font-family:monospace;font-size:.75rem;color:#1e40af">AGGNE.PRD.Load_PolicyAttach_API_Table</td><td style="padding:7px 10px"><span style="background:#ede9fe;color:#6d28d9;padding:1px 7px;border-radius:4px;font-size:.7rem">Snowflake PRD</span></td><td style="padding:7px 10px;color:#475569;font-size:.76rem">Loads DCT API response from XML table into API response table for tracking</td></tr>
      </tbody>
    </table>
    </div>
    <div style="margin-top:10px;padding:8px 12px;background:#fef9c3;border:1px solid #fde68a;border-radius:6px;font-size:.76rem;color:#78350f">
      <strong>DOL Combination Design:</strong> Each policy generates ~10 start&#8209;to&#8209;end date combinations (Step 2) so any future Date of Loss falls within one. If a new transaction is added, Step 2 regenerates all combinations for that policy to cover the new DOL. This avoids re&#8209;running attach for every new DOL individually.
    </div>
  </div>
</div>

<!-- TAB 2: PL101 -->
<div class="pane" id="pane-pl101">
  <div class="plintro">
    <div style="font-size:1.8rem;opacity:.55">&#128203;</div>
    <div>
      <h2>PL101 &#8212; DuckCreek Field Specification</h2>
      <p>DC xpaths, data types, required flags &amp; rating impact from Conversion_Mapping_BP_PL101_V2.xlsx &amp; Conversion_Mapping_PP_PL101_V1.xlsx</p>
    </div>
    <div class="plstats">
      <div class="plst"><div class="n" id="plTotal">0</div><div class="l">Total Fields</div></div>
      <div class="plst"><div class="n" id="plRating">0</div><div class="l">Affect Rating</div></div>
    </div>
  </div>

  <div class="cs">
    <div class="cg">
      <label>Line of Business</label>
      <select id="plLOB" onchange="plOnLOB()">
        <option value="">&#8212; Select LOB &#8212;</option>
        <option value="BP">BP &#8212; Business Pack</option>
        <option value="PP">PP &#8212; Personal Pack</option>
      </select>
    </div>
    <div class="cg">
      <label>Coverage / Screen</label>
      <select id="plCov" onchange="plOnCov()" disabled>
        <option value="">&#8212; Select Coverage &#8212;</option>
      </select>
    </div>
    <div class="cg">
      <label>Search Fields</label>
      <input class="srch" id="plSearch" type="text" placeholder="Filter by caption or xpath..." oninput="plFilter()">
    </div>
  </div>

  <div id="plCardRow" class="cgrid" style="display:none"></div>

  <div id="plArea" class="panel" style="display:none">
    <div class="ph">
      <h2 id="plTitle">DC Field Rules</h2>
      <span class="pm" id="plMeta"></span>
    </div>
    <div class="tw">
      <table>
        <thead><tr>
          <th>#</th><th>Field Caption</th><th>Type</th><th>Input</th>
          <th>Required</th><th>Default</th><th>Options / Values</th><th>DC xpath</th><th>Rating</th>
        </tr></thead>
        <tbody id="plBody"></tbody>
      </table>
    </div>
    <div id="plFoot" style="padding:7px 14px;font-size:.69rem;color:#94a3b8;background:#f8fafc;border-top:1px solid #e2e8f0"></div>
  </div>
</div>

</div><!-- /main -->

<script>
const DATA={BP:{BB:{label:"BB — Business Buildings",level:"Risk / Location",stagingTable:"AGGNE.PRD.LOCATION_BB_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LOCATION_BB_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_BUILDING_SUBCOVERAGES",targetTable:"AGGNE.PRD.PA_RISK_BUILDING_TARGET",subs:[{code:"BBGLS_SD",type:"GLS_SD",desc:"Glass",field:"FIXEDGLASS, glass",cond:"glass ≠ 'Not Taken'"},{code:"BBFLD_SD",type:"FLD_SD",desc:"Flood",field:"BBFLOODPROTECTION, flooddamage",cond:"flooddamage ≠ 'Not Taken'"},{code:"BBLOR_SD",type:"LOR_SD",desc:"Loss of Rent",field:"LOSSOFRENTLIMIT",cond:"limit ≠ 0"},{code:"BBACC_SD",type:"ACC_SD",desc:"Accidental Damage",field:"ACCIDENTALLOSSORDAMAGELIMIT",cond:"limit ≠ 0"},{code:"BBSTD_SD",type:"STD_SD",desc:"Standard",field:"BUSINESSBUILDINGSLIMIT",cond:"always included"},{code:"BBSTD_BF",type:"STD_BF",desc:"Bushfire",field:"BUSINESSBUILDINGSLIMIT",cond:"always"},{code:"BBSTD_CY",type:"STD_CY",desc:"Cyclone",field:"BUSINESSBUILDINGSLIMIT",cond:"always"},{code:"BBSTD_EQ",type:"STD_EQ",desc:"Earthquake",field:"BUSINESSBUILDINGSLIMIT",cond:"always"},{code:"BBSTD_ST",type:"STD_ST",desc:"Storm",field:"BUSINESSBUILDINGSLIMIT",cond:"always"},{code:"BBLND_SD",type:"LND_SD",desc:"Landslide",field:"LANDSLIDELIMIT",cond:"NZ only + limit ≠ 0",nz:true}]},BC:{label:"BC — Business Contents / Stocks",level:"Risk / Location",stagingTable:"AGGNE.PRD.LOCATION_BC_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LOCATION_BC_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_RISK_BUILDING_BC_COVERAGES",targetTable:"AGGNE.PRD.PA_RISK_BUILDING_BC_TARGET",subs:[{code:"BCSTD_SD",type:"STD_SD",desc:"Standard Contents & Stocks",field:"CONTENTSLIMIT",cond:"always"},{code:"BCFLD_SD",type:"FLD_SD",desc:"Flood",field:"BCFLOODPROTECTION",cond:"≠ 0"},{code:"BCPER_SD",type:"PER_SD",desc:"Personal Effects (Handtools)",field:"PERSONALEFFECTSLIMIT",cond:"≠ 0"},{code:"BCMFL_SD",type:"MFL_SD",desc:"Motor Fuels",field:"MOTORFUELSLIMIT",cond:"≠ 0"},{code:"BCEMP_SD",type:"EMP_SD",desc:"Employee Tools of Trade",field:"EMPLOYEETOOLSOFTRADELIMIT",cond:"≠ 0"},{code:"BCVIS_SD",type:"VIS_SD",desc:"Vehicles in Stock",field:"VEHICLESINSTOCKLIMIT",cond:"≠ 0"},{code:"BCCUV_SD",type:"CUV_SD",desc:"Customers Vehicles",field:"CUSTOMERSVEHICLESLIMIT",cond:"≠ 0"},{code:"BCWIS_SD",type:"WIS_SD",desc:"Watercraft in Stock (<8m)",field:"WATERCRAFTINSTOCKUNDER8MLIMIT",cond:"≠ 0"},{code:"BCCUW_SD",type:"CUW_SD",desc:"Customers Watercraft (<8m)",field:"CUSTOMERSWATERCRAFTUNDER8MLIMIT",cond:"≠ 0"},{code:"BCACC_SD",type:"ACC_SD",desc:"Accidental Damage",field:"ACCIDENTALLOSSORDAMAGELIMIT",cond:"≠ 0"},{code:"BCHAL_SD",type:"HAL_SD",desc:"Hail",field:"HAILDAMAGE",cond:"≠ 0"},{code:"BCLND_SD",type:"LND_SD",desc:"Landslide",field:"LANDSLIDELIMIT",cond:"NZ only",nz:true},{code:"BCSWP_SD",type:"SWP_SD",desc:"Stock & Works in Progress",field:"STOCKLIMITEXVEHICLESWATERCRAFT",cond:"≠ 0"}]},BI:{label:"BI — Business Interruption",level:"Risk / Location",stagingTable:"AGGNE.PRD.LOCATION_BI_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LOCATION_BI_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_RISK_BUILDING_BI_COVERAGES",targetTable:"AGGNE.PRD.PA_RISK_BUILDING_BI_TARGET",subs:[{code:"BICLP_SD",type:"CLP_SD",desc:"Claim Preparation",field:"BICLAIMSPREPCOST",cond:"≠ 0"},{code:"BIACR_SD",type:"ACR_SD",desc:"Accounts Receivable",field:"BIRECEIVABLES",cond:"≠ 0"},{code:"BIICW_SD",type:"ICW_SD",desc:"Increased Cost of Working",field:"BICOSTOFWORKING",cond:"≠ 0"}]},BG:{label:"BG — Business Glass / Goods",level:"Risk / Location",stagingTable:"AGGNE.PRD.LOCATION_BG_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LOCATION_BG_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_RISK_BUILDING_BG_COVERAGES",targetTable:"AGGNE.PRD.PA_RISK_BUILDING_BG_TARGET",subs:[{code:"BGALC_SD",type:"ALC_SD",desc:"Alcohol",field:"ALCOHOLLIMIT",cond:"≠ 0"},{code:"BGCUV_SD",type:"CUV_SD",desc:"Customer Vehicles / Watercraft",field:"CUSTOMERVEHICLESWATERCRAFTLIMIT",cond:"≠ 0"},{code:"BGMFL_SD",type:"MFL_SD",desc:"Motor Fuels",field:"MOTORFUELSLIMIT",cond:"≠ 0"},{code:"BGPER_SD",type:"PER_SD",desc:"Personal Effects",field:"PERSONALEFFECTSLIMIT",cond:"≠ 0"},{code:"BGMVH_SD",type:"MVH_SD",desc:"Stock Vehicles / Watercraft",field:"STOCKVEHICLESWATERCRAFTLIMIT",cond:"≠ 0"},{code:"BGTOB_SD",type:"TOB_SD",desc:"Tobacco",field:"TOBACCOLIMIT",cond:"≠ 0"},{code:"BGEMP_SD",type:"EMP_SD",desc:"Employee Handtools",field:"CONTENTSSTOCKEMPLOYEETOOLSLIMIT",cond:"≠ 0"},{code:"BGETH_SD",type:"ETH_SD",desc:"Employee Theft",field:"EMPLOYEETHEFTLIMIT",cond:"≠ 0"}]},EN:{label:"EN — Equipment / Engineering",level:"Risk / Location",stagingTable:"AGGNE.PRD.LOCATION_EN_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LOCATION_EN_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_RISK_BUILDING_EN_COVERAGES",targetTable:"AGGNE.PRD.PA_RISK_BUILDING_EN_TARGET",subs:[{code:"ENCWS_SD",type:"CWS_SD",desc:"Car Wash",field:"ENCARWASHVALUE",cond:"≠ 0"},{code:"ENDET_SD",type:"DET_SD",desc:"Deterioration of Stock",field:"ENSTOCKDETERIORATION",cond:"≠ 0"},{code:"ENICW_SD",type:"ICW_SD",desc:"Increased Cost of Working",field:"ENINCREASECOST",cond:"≠ 0"},{code:"ENLOI_SD",type:"LOI_SD",desc:"Loss of Information",field:"ENLOSSINFO",cond:"≠ 0"},{code:"ENMAC_SD",type:"MAC_SD",desc:"Machinery",field:"ENMACHINERYECEVALUE",cond:"≠ 0"}]},MY:{label:"MY — Money",level:"Risk / Location",stagingTable:"AGGNE.PRD.LOCATION_MONEY_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LOCATION_MONEY_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_RISK_BUILDING_MONEY_COVERAGES",targetTable:"AGGNE.PRD.PA_RISK_BUILDING_MONEY_TARGET",subs:[{code:"MYMSO_SD",type:"MSO_SD",desc:"Money at Situation (outside business hours)",field:"MYOUTSIDEBUSHOURS",cond:"≠ 0"},{code:"MYMSS_SD",type:"MSS_SD",desc:"Money in secure safe / strongroom",field:"MYLOCKEDSAFE",cond:"≠ 0"},{code:"MYMPC_SD",type:"MPC_SD",desc:"Money in personal custody (outside bus. hours)",field:"MYOUTSIDEBUSHOURSPRIVATE",cond:"≠ 0"},{code:"MYMIT_SD",type:"MIT_SD",desc:"Money in Transit",field:"MYINTRANSIT",cond:"≠ 0"},{code:"MYEMP_SD",type:"EMP_SD",desc:"Employee Dishonesty",field:"EMPLOYEEDISHONESTYLIMIT",cond:"≠ 0"},{code:"MYMSB_SD",type:"MSB_SD",desc:"Money at Situation (during business hours)",field:"MYDURINGBUSHOURS",cond:"≠ 0"}]},CV:{label:"CV — Commercial Vehicles",level:"Line (Policy)",stagingTable:"AGGNE.PRD.LINE_CV_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LINE_CV_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_LINE_CV_PAYLOAD",targetTable:"AGGNE.PRD.PA_LINE_CV_TARGET",subs:[{code:"CVSTD_SD",type:"STD_SD",desc:"Comprehensive Standard",field:"CVSUMPROTECTED",cond:"always"}]},GP:{label:"GP — General Property",level:"Line (Policy)",stagingTable:"AGGNE.PRD.LINE_GP_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LINE_GP_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_LINE_GP_PAYLOAD",targetTable:"AGGNE.PRD.PA_LINE_GP_TARGET",subs:[{code:"GPUNT_SD",type:"UNT_SD",desc:"Unspecified Tools",field:"UNSPECIFIEDTOOLSLIMIT",cond:"≠ 0"},{code:"GPFLD_SD",type:"FLD_SD",desc:"Flood",field:"GPFLOODPROTECTION",cond:"= 'Taken'"},{code:"GPUNS_SD",type:"UNS_SD",desc:"Unspecified Stock",field:"UNSPECIFIEDSTOCKLIMIT",cond:"≠ 0"},{code:"GPSPT_SD",type:"SPT_SD",desc:"Specified Tools",field:"GPSPECIFIEDTOOLS",cond:"≠ 0"}]},GT:{label:"GT — Goods in Transit",level:"Line (Policy)",stagingTable:"AGGNE.PRD.LINE_GT_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LINE_GT_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_LINE_GT_PAYLOAD",targetTable:"AGGNE.PRD.PA_LINE_GT_TARGET",subs:[{code:"GTSTD_SD",type:"STD_SD",desc:"Standard",field:"(transit limit)",cond:"always"}]},LE:{label:"LE — Legal Expenses",level:"Line (Policy)",stagingTable:"AGGNE.PRD.LINE_PUBLICLIABILITY_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LINE_PUBLICLIABILITY_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_LINE_LE_PAYLOAD",targetTable:"AGGNE.PRD.PA_LINE_LE_TARGET",subs:[{code:"LESTD_SD",type:"STD_SD",desc:"Legal Expenses Standard",field:"(liability limit)",cond:"always"}]},PF:{label:"PF — Professional Protection",level:"Line (Policy)",stagingTable:"AGGNE.PRD.LINE_PROFESSIONALPROTECTION_POLICYATTACH",identifierView:"AGGNE.PRD.LINE_PROFESSIONALPROTECTION_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_LINE_PF_PAYLOAD",targetTable:"AGGNE.PRD.PA_LINE_PF_TARGET",subs:[{code:"PFSTD_SD",type:"STD_SD",desc:"Standard",field:"PROFESSIONALPROTECTIONLIMIT",cond:"always"},{code:"PFVHB_SD",type:"VHB_SD",desc:"Vehicle Breakdown",field:"PIBREAKDOWNLIMIT, VEHBREAK_IND",cond:"VEHBREAK_IND=1"},{code:"PFCCA_SD",type:"CCA_SD",desc:"Contractors & Subcontractors",field:"CONTRACTORSANDSUBCONTRACTORSLIMIT",cond:"ind=1"},{code:"PFCSL_SD",type:"CSL_SD",desc:"Vehicle Assessment",field:"PIASSESSMENTLIMIT, VEHASS_IND",cond:"VEHASS_IND=1"},{code:"PFROL_SD",type:"ROL_SD",desc:"Retroactive",field:"RETROACTIVELIMIT, RETROACTIVE_IND",cond:"ind=1"}]},PPL:{label:"PPL — Public / Products Liability",level:"Line (Policy)",stagingTable:"AGGNE.PRD.LINE_PUBLICLIABILITY_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LINE_PUBLICLIABILITY_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_LINE_PPL_PAYLOAD",targetTable:"AGGNE.PRD.PA_LINE_PPL_TARGET",subs:[{code:"PPSTD_SD",type:"STD_SD",desc:"Standard",field:"PRODUCTSANDPUBLICLIABILITYLIMIT",cond:"always"},{code:"PPLHA_SD",type:"LHA_SD",desc:"Hired / Assumed Liability",field:"ASSUMEDLIABILITYLIMIT",cond:"= 'Yes'"},{code:"PPCCA_SD",type:"CCA_SD",desc:"Contractors & Subcontractors",field:"CONTRACTANDSUBCONLIMIT",cond:"= 'Yes'"},{code:"PPDFW_SD",type:"DFW_SD",desc:"Defective / Faulty Work",field:"COSTOFRECTIFYINGLIMIT",cond:"= 'Yes'"},{code:"PPGHO_SD",type:"GHO_SD",desc:"Equipment / Goods Hired Out",field:"EQUIPMENTGOODSLIMIT",cond:"= 'Yes'"},{code:"PPPOO_SD",type:"POO_SD",desc:"Property Owners",field:"PROPERTYOWNERSLIABILITYLIMIT",cond:"= 'Yes'"},{code:"PPRFW_SD",type:"RFW_SD",desc:"Rectifying Faulty Work",field:"COSTOFRECTIFYINGLIMIT",cond:"≠ 0"},{code:"PPRUF_SD",type:"RUF_SD",desc:"Run-off Liability",field:"COSTOFRECTIFYINGLIMIT",cond:"≠ 0"},{code:"PPSTB_SD",type:"STB_SD",desc:"Statutory Body",field:"(statutory limit)",cond:"≠ 0"},{code:"PPCCC_SD",type:"CCC_SD",desc:"Property in Care/Custody/Control",field:"CONTRACTANDAGREEMENTUNDERWRITER",cond:"set"}]},SV:{label:"SV — Stock Vehicles",level:"Line (Policy)",stagingTable:"AGGNE.PRD.LINE_SV_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LINE_SV_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_LINE_SV_PAYLOAD",targetTable:"AGGNE.PRD.PA_LINE_SV_TARGET",subs:[{code:"SVSTD_SD",type:"STD_SD",desc:"Comprehensive Standard",field:"LOSSDAMAGELIMIT",cond:"always"},{code:"SVSTD_ST",type:"STD_ST",desc:"Storm",field:"LOSSDAMAGELIMIT",cond:"always"},{code:"SVLIA_SD",type:"LIA_SD",desc:"Liability",field:"LOSSDAMAGELIMIT",cond:"Comprehensive"},{code:"SVTPO_SD",type:"TPO_SD",desc:"Third Party Only",field:"LOSSDAMAGELIMIT",cond:"TPO type"},{code:"SVGLS_SD",type:"GLS_SD",desc:"Glass",field:"EXCESSWAIVERFORWINDSCREEN",cond:"= 'Yes'"}]},TA:{label:"TA — Tax Audit",level:"Line (Policy)",stagingTable:"AGGNE.PRD.LINE_TA_COVERAGE_POLICYATTACH",identifierView:"AGGNE.PRD.LINE_TA_COVERAGE_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_LINE_TA_PAYLOAD",targetTable:"AGGNE.PRD.PA_LINE_TA_TARGET",subs:[{code:"TASTD_SD",type:"STD_SD",desc:"Tax Audit Standard",field:"(audit limit)",cond:"always"}]}},PP:{HB:{label:"HB — Home Buildings",level:"Risk / Location",stagingTable:"AGGNE.PRD.HB_02_POLICYATTACH",identifierView:"AGGNE.PRD.HB_02_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_PER_BB_SUBCOVERAGES",targetTable:"AGGNE.PRD.PA_PER_BUILDING_TARGET",subs:[{code:"HBBFL_SD",type:"BFL_SD",desc:"Flood",field:"HOMEBUILDINGSLIMIT, FLOODDAMAGE",cond:"= 'Taken'"},{code:"HBBLD_SD",type:"BLD_SD",desc:"Standard",field:"HOMEBUILDINGSLIMIT",cond:"≠ 0"},{code:"HBBAD_SD",type:"BAD_SD",desc:"Accidental Damage",field:"ACCIDENTALLOSSORDAMAGELIMIT",cond:"= 'Taken'"},{code:"HBBLD_BF",type:"BLD_BF",desc:"Bushfire",field:"HOMEBUILDINGSLIMIT",cond:"≠ 0"},{code:"HBBLD_CY",type:"BLD_CY",desc:"Cyclone",field:"HOMEBUILDINGSLIMIT",cond:"≠ 0"},{code:"HBBLD_EQ",type:"BLD_EQ",desc:"Earthquake",field:"HOMEBUILDINGSLIMIT",cond:"≠ 0"},{code:"HBBLD_ST",type:"BLD_ST",desc:"Storm",field:"HOMEBUILDINGSLIMIT",cond:"≠ 0"},{code:"HBBLI_SD",type:"BLI_SD",desc:"Building Liability",field:"HOMEBUILDINGSLIMIT",cond:"≠ 0"},{code:"HBLLB_SD",type:"LLB_SD",desc:"Landlord Protection",field:"LANDLORDPROTECTIONS",cond:"= 'Taken'"},{code:"HBBLN_SD",type:"BLN_SD",desc:"Landslide",field:"LANDSLIDELIMIT",cond:"NZ only",nz:true}]},HC:{label:"HC — Home Contents",level:"Risk / Location",stagingTable:"AGGNE.PRD.HC_02_POLICYATTACH",identifierView:"AGGNE.PRD.HC_02_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_PER_HC_SUBCOVERAGES",targetTable:"AGGNE.PRD.PA_PER_HC_TARGET",subs:[{code:"HCCNT_SD",type:"CNT_SD",desc:"Standard",field:"HOMECONTENTSLIMIT_NEW",cond:"≠ 0"},{code:"HCCAD_SD",type:"CAD_SD",desc:"Accidental Damage",field:"ACCIDENTALLOSSORDAMAGELIMIT",cond:"= 'Taken'"},{code:"HCSPE_SD",type:"SPE_SD",desc:"Specified Items",field:"HCOTHITEMSTOTAL",cond:"SPECIFIEDITEMSAWAY='Taken'"},{code:"HCCNT_BF",type:"CNT_BF",desc:"Bushfire",field:"HOMECONTENTSLIMIT_NEW",cond:"≠ 0"},{code:"HCCNT_CY",type:"CNT_CY",desc:"Cyclone",field:"HOMECONTENTSLIMIT_NEW",cond:"≠ 0"},{code:"HCCNT_EQ",type:"CNT_EQ",desc:"Earthquake",field:"HOMECONTENTSLIMIT_NEW",cond:"≠ 0"},{code:"HCCNT_ST",type:"CNT_ST",desc:"Storm",field:"HOMECONTENTSLIMIT_NEW",cond:"≠ 0"},{code:"HCPOR_SD",type:"POR_SD",desc:"Portable Items (away from home)",field:"(no iValue)",cond:"when present"},{code:"HCCFL_SD",type:"CFL_SD",desc:"Flood",field:"HCHOMEHOBBYFARMFLOODPROTECTION",cond:"= 'Taken'"},{code:"HCCLI_SD",type:"CLI_SD",desc:"Contents Liability",field:"HOMECONTENTSLIMIT_NEW",cond:"≠ 0"},{code:"HCCLN_SD",type:"CLN_SD",desc:"Landslide",field:"LANDSLIDELIMIT",cond:"NZ only",nz:true}]},PM:{label:"PM — Private Motor (per vehicle)",level:"Per Vehicle",stagingTable:"AGGNE.PRD.PM_03_POLICYATTACH",identifierView:"AGGNE.PRD.PM_03_POLICYATTACH_IDENTIFIER",subCovView:"AGGNE.PRD.PA_PER_COM_COVERAGES",targetTable:"AGGNE.PRD.PA_PER_COM_COVERAGES_TARGET",subs:[{code:"PMCMP_SD",type:"CMP_SD",desc:"Comprehensive — Market Value",field:"MARKETVALUEWITHACCESSORIESAMOUNT",cond:"ProtectionType='Comprehensive - Market Value'"},{code:"PMCMP_SD",type:"CMP_SD",desc:"Comprehensive — Agreed Value",field:"AGREEDVALUEDESCRIPTIONVALUE",cond:"ProtectionType='Comprehensive - Agreed Value'"},{code:"PMCOR_SD",type:"COR_SD",desc:"Choice of Repair",field:"(no iValue)",cond:"CHOICEOFREPAIR='Taken'"},{code:"PMFTL_SD",type:"FTL_SD",desc:"Fire & Theft (no Liability)",field:"MARKETVALUEWITHACCESSORIESAMOUNT",cond:"ProtectionType='Fire and Theft'"},{code:"PMLIA_SD",type:"LIA_SD",desc:"Comprehensive Liability",field:"MARKETVALUEWITHACCESSORIESAMOUNT",cond:"Comprehensive type"},{code:"PMPCH_SD",type:"PCH_SD",desc:"Car Hire After Incident",field:"(no iValue)",cond:"HIRECARHIREAFTERINCIDENT='Taken'"},{code:"PMTFT_SD",type:"TFT_SD",desc:"Third Party Fire & Theft",field:"MARKETVALUEWITHACCESSORIESAMOUNT",cond:"ProtectionType='Third Party, Fire and Theft'"},{code:"PMTPO_SD",type:"TPO_SD",desc:"Third Party Only",field:"MARKETVALUEWITHACCESSORIESAMOUNT",cond:"ProtectionType='Third Party Only'"},{code:"PMULG_SD",type:"ULG_SD",desc:"Unlimited Glass",field:"(no iValue)",cond:"EXCESSWAIVERFORGLASS='Yes'"}]}}};
""")

HTML_PARTS.append(f"const PL101={pl101_js};\n")

HTML_PARTS.append(r"""
const PL101_LABELS={BP:{GP:"GP — General Property",GT:"GT — Goods in Transit",PPL:"PPL — Public/Products Liability",PF:"PF — Professional Protection",LE:"LE — Legal Expenses",TA:"TA — Tax Audit",CV:"CV — Commercial Vehicles",SV:"SV — Stock Vehicles"},PP:{HB:"HB — Home Buildings",HC:"HC — Home Contents",PM:"PM — Private Motor Vehicles"}};

function switchTab(n){
  document.querySelectorAll('.pane').forEach(p=>p.classList.remove('active'));
  document.querySelectorAll('.tbtn').forEach(b=>b.classList.remove('active'));
  document.getElementById('pane-'+n).classList.add('active');
  document.getElementById('tab-'+n).classList.add('active');
  if(n==='pl101')updateStats();
}
function updateStats(){
  let t=0,r=0;
  for(const lob of['BP','PP'])for(const k of Object.keys(PL101[lob]||{}))for(const f of PL101[lob][k]){t++;if((f.rating||'').toLowerCase().includes('yes'))r++;}
  document.getElementById('plTotal').textContent=t;
  document.getElementById('plRating').textContent=r;
}

// ---- COVERAGE TAB ----
function onLOBChange(){
  const lob=document.getElementById('selLOB').value;
  const sel=document.getElementById('selCov');
  sel.innerHTML='<option value="">— Select Coverage —</option>';
  document.getElementById('covArea').style.display='none';
  document.getElementById('cardRow').style.display='none';
  if(!lob){sel.disabled=true;return;}
  Object.keys(DATA[lob]).forEach(k=>{const o=document.createElement('option');o.value=k;o.textContent=DATA[lob][k].label;sel.appendChild(o);});
  sel.disabled=false;renderCards(lob,'cardRow',DATA[lob],onCovChange,'selCov');
}
function onCovChange(){
  const lob=document.getElementById('selLOB').value;
  const key=document.getElementById('selCov').value;
  if(!lob||!key){document.getElementById('covArea').style.display='none';return;}
  const g=DATA[lob][key];
  document.getElementById('covArea').style.display='block';
  document.getElementById('covTitle').innerHTML=`<span class="lbdg ${lob}">${lob}</span>&nbsp; ${g.label} &nbsp;<span class="lchip">${g.level}</span>`;
  document.getElementById('covMeta').textContent=`${g.subs.length} sub-coverages`;
  const tbody=document.getElementById('covBody');tbody.innerHTML='';
  g.subs.forEach((s,i)=>{
    const tr=document.createElement('tr');
    tr.innerHTML=`<td class="num">${i+1}</td><td><span class="cpill">${s.code}</span></td><td><span class="tpill">${s.type}</span></td><td>${s.desc}${s.nz?'<span class="nzbdg">NZ</span>':''}</td><td>${s.field.split(',').map(f=>`<span class="pfield">${f.trim()}</span>`).join(' ')}</td><td class="cc-cell">${s.cond}</td>`;
    tbody.appendChild(tr);
  });
  document.getElementById('covStaging').innerHTML=`<div class="sl">Staging: <span>${g.stagingTable}</span></div><div class="sl">Identifier: <span>${g.identifierView}</span></div><div class="sl">Sub-Cov View: <span>${g.subCovView}</span></div><div class="sl">Target: <span>${g.targetTable}</span></div>`;
  syncCards('cardRow',DATA[lob],key);
}

// ---- PL101 TAB ----
let _plRows=[];
function plOnLOB(){
  const lob=document.getElementById('plLOB').value;
  const sel=document.getElementById('plCov');
  sel.innerHTML='<option value="">— Select Coverage —</option>';
  document.getElementById('plArea').style.display='none';
  document.getElementById('plCardRow').style.display='none';
  if(!lob){sel.disabled=true;return;}
  const labs=PL101_LABELS[lob]||{};
  Object.keys(PL101[lob]||{}).forEach(k=>{const o=document.createElement('option');o.value=k;o.textContent=labs[k]||k;sel.appendChild(o);});
  sel.disabled=false;
  renderCards(lob,'plCardRow',null,plOnCov,'plCov',true);
}
function plOnCov(){
  const lob=document.getElementById('plLOB').value;
  const key=document.getElementById('plCov').value;
  document.getElementById('plSearch').value='';
  if(!lob||!key){document.getElementById('plArea').style.display='none';return;}
  _plRows=(PL101[lob]||{})[key]||[];
  const labs=PL101_LABELS[lob]||{};
  document.getElementById('plTitle').innerHTML=`<span class="lbdg ${lob}">${lob}</span>&nbsp; ${labs[key]||key}`;
  document.getElementById('plArea').style.display='block';
  renderPL(_plRows);
  syncCards('plCardRow',PL101[lob],key);
}
function plFilter(){
  const q=document.getElementById('plSearch').value.toLowerCase();
  const filtered=q?_plRows.filter(r=>(r.caption||'').toLowerCase().includes(q)||(r.xpath||'').toLowerCase().includes(q)):_plRows;
  renderPL(filtered);
}
function renderPL(rows){
  const tbody=document.getElementById('plBody');tbody.innerHTML='';
  rows.forEach((r,i)=>{
    const ro=(r.input_type||'').toLowerCase().includes('read');
    const req=(r.required||'').toLowerCase()==='yes'||(r.required||'').toLowerCase()==='y';
    const rating=(r.rating||'').toLowerCase().includes('yes');
    const isIn=(r.field_id||'').includes('Input.');
    const isOut=(r.field_id||'').includes('Output.');
    let reqH=req?'<span class="ryes">✓ Required</span>':(ro?'<span class="rro">Read-only</span>':`<span class="rro">${r.required||'—'}</span>`);
    let tag=isIn?'<span class="tin">In</span>':isOut?'<span class="tout">Out</span>':'';
    const def=(r.default&&r.default!=='NA'&&r.default!=='N/A')?r.default:'';
    const opts=r.options||[];
    let optsH='—';
    if(opts.length===1){optsH=`<span class="dpill">${opts[0]}</span>`;}
    else if(opts.length>1){
      const shown=opts.slice(0,5).map(v=>`<span class="oval">${v}</span>`).join('');
      const more=opts.length>5?`<span class="omore">+${opts.length-5} more</span>`:'';
      optsH=`<div class="olist">${shown}${more}</div>`;
    }
    const tr=document.createElement('tr');
    tr.innerHTML=`<td class="num">${i+1}</td>
      <td>${r.caption||'—'}${tag}</td>
      <td>${r.dtype?`<span class="dpill">${r.dtype}</span>`:'—'}</td>
      <td style="font-size:.72rem;color:#475569">${r.input_type||'—'}</td>
      <td>${reqH}</td>
      <td>${def?`<span class="dpill">${def}</span>`:'—'}</td>
      <td>${optsH}</td>
      <td class="xp">${r.xpath||'—'}</td>
      <td>${rating?'<span class="rtyes">◼ Yes</span>':'<span style="color:#94a3b8;font-size:.71rem">No</span>'}</td>`;
    tbody.appendChild(tr);
  });
  const rc=rows.filter(r=>(r.rating||'').toLowerCase().includes('yes')).length;
  document.getElementById('plMeta').textContent=`${rows.length} fields`;
  document.getElementById('plFoot').textContent=`${rows.length} fields · ${rc} affect rating · Source: PL101 V2/V1`;
}

// ---- SHARED CARD HELPERS ----
function renderCards(lob,rowId,dataset,onChangeFn,selId,usePL101=false){
  const row=document.getElementById(rowId);row.innerHTML='';row.style.display='flex';
  const src=usePL101?(PL101[lob]||{}):dataset;
  const labs=usePL101?(PL101_LABELS[lob]||{}):{};
  Object.keys(src).forEach(k=>{
    const g=src[k];
    const subs=Array.isArray(g)?g:(g.subs||[]);
    const count=Array.isArray(g)?g.length:subs.length;
    const name=Array.isArray(g)?(labs[k]||k):(g.label||labs[k]||k);
    const level=Array.isArray(g)?null:g.level;
    const ratingCount=Array.isArray(g)?g.filter(f=>(f.rating||'').toLowerCase().includes('yes')).length:null;
    const div=document.createElement('div');
    div.className='cc';
    div.onclick=()=>{document.getElementById(selId).value=k;onChangeFn();};
    div.innerHTML=`<div class="ck">${k}</div>
      <div class="cn">${name.replace(/^[A-Z0-9]+ — /,'')}</div>
      <div class="cm">${Array.isArray(g)?`${count} fields${ratingCount?' · '+ratingCount+' rate':''}`:`${count} sub-cov`}</div>
      ${level?`<span class="lchip">${level}</span>`:''}`;
    row.appendChild(div);
  });
}
function syncCards(rowId,dataset,activeKey){
  document.querySelectorAll(`#${rowId} .cc`).forEach((c,i)=>{
    c.classList.toggle('active',Object.keys(dataset)[i]===activeKey);
  });
}
</script>
</body>
</html>
""")

html = ''.join(HTML_PARTS)
OUT.write_text(html, encoding='utf-8')
print(f"Written: {OUT}")
print(f"Size: {len(html):,} chars")
