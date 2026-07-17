"""
PP XML Field Validator -- look up a policy by number (pulls its real generated XML from
AGGNE.DEV.PER_POLICY_MIGRATION_DCT) or paste an XML fragment directly, and check it against:
  1. AGGNE.DEV.PP_XML_VALIDATION_RULES (mandatory / valid-value rules, XML layer)
  2. AGGNE.DEV.PP_SOURCE_VALIDATION_REPORT (known Pure/View-layer issues for that policy,
     if a LegacyPolicyNumber tag is found)

How to add a new rule: don't edit this file. INSERT a row into PP_XML_VALIDATION_RULES
(XML layer) or PP_SOURCE_VALIDATION_RULES (Pure/View layer) -- both engines already run
independently; this page is a read-only viewer over their live results plus one-off ad-hoc
checks against whatever XML is looked up or pasted.
"""
import re
import streamlit as st
import xml.etree.ElementTree as ET
from snowflake.snowpark.context import get_active_session

# Known, already-diagnosed template quirks that produce technically-malformed XML but are
# tolerated downstream -- auto-corrected here so one cosmetic issue doesn't block validating
# everything else. Each entry is (pattern, replacement, description shown to the user).
# Real fix for the underlying SP bug: sql/snowflake/1_conversion/PP/bugfixes/
# BUGFIX_SessionCloseRq_Mismatched_Tag.sql -- this is a display-layer workaround, not a substitute.
KNOWN_QUIRKS = [
    (r"</Session\.closeRq>", "<Session.closeRq/>", "Session.closeRq stray closing tag (no opener) -> self-closed"),
]


def autocorrect_known_quirks(xml_text: str):
    applied = []
    for pattern, replacement, desc in KNOWN_QUIRKS:
        if re.search(pattern, xml_text):
            xml_text = re.sub(pattern, replacement, xml_text)
            applied.append(desc)
    return xml_text, applied

st.set_page_config(page_title="PP XML Validator", layout="wide")
st.title("PP XML Field Validator")
st.caption(
    "Look up a policy by number (pulls its real generated XML) or paste an XML fragment "
    "directly. Checks every field found against the active PP_XML_VALIDATION_RULES "
    "(mandatory + valid-value rules), and if a LegacyPolicyNumber is known, also shows any "
    "known Pure/View-layer source issues for that policy."
)

session = get_active_session()


def validate_and_render(xml_text: str, policy_hint: str | None = None):
    xml_text, quirks_applied = autocorrect_known_quirks(xml_text)
    if quirks_applied:
        for desc in quirks_applied:
            st.warning(f"Auto-corrected a known template quirk before validating: {desc}")

    try:
        root = ET.fromstring(f"<ROOT>{xml_text}</ROOT>")
    except ET.ParseError as e:
        st.error(f"XML parse error: {e}")
        return

    tag_to_values = {}
    for el in root.iter():
        if len(el) == 0:
            tag_to_values.setdefault(el.tag, []).append((el.text or "").strip())

    rules_df = session.sql(
        """
        SELECT FIELD_NAME, XML_TAG, PAYLOAD_TYPE, IS_REQUIRED, VALID_VALUES, NOTES
        FROM AGGNE.DEV.PP_XML_VALIDATION_RULES
        WHERE ACTIVE = TRUE
        """
    ).to_pandas()

    issues = []
    for _, rule in rules_df.iterrows():
        tag = rule["XML_TAG"]
        if tag not in tag_to_values:
            continue
        valid_list = rule["VALID_VALUES"]
        for val in tag_to_values[tag]:
            if rule["IS_REQUIRED"] and not val:
                issues.append(
                    {
                        "Field": rule["FIELD_NAME"],
                        "Tag": tag,
                        "Payload": rule["PAYLOAD_TYPE"],
                        "Value": val,
                        "Issue": "BLANK_REQUIRED",
                        "Rule Notes": rule["NOTES"],
                    }
                )
            elif valid_list is not None and val and val not in valid_list:
                issues.append(
                    {
                        "Field": rule["FIELD_NAME"],
                        "Tag": tag,
                        "Payload": rule["PAYLOAD_TYPE"],
                        "Value": val,
                        "Issue": "INVALID_CODE",
                        "Rule Notes": rule["NOTES"],
                    }
                )

    policy_no = policy_hint
    if not policy_no:
        for val in tag_to_values.get("LegacyPolicyNumber", []):
            if val:
                policy_no = val
                break

    if policy_no:
        st.info(f"Policy: **{policy_no}** — cross-checking Pure/View source data")
        safe_policy = policy_no.replace("'", "''")
        source_df = session.sql(
            f"""
            SELECT FIELD_NAME, LAYER, SOURCE_OBJECT, EXTRACTED_VALUE, ISSUE_TYPE, NOTES
            FROM AGGNE.DEV.PP_SOURCE_VALIDATION_REPORT
            WHERE LEGACY_POLICY_NO = '{safe_policy}'
            """
        ).to_pandas()
        if len(source_df):
            st.subheader(f"Known Pure/View source issues for {policy_no}")
            st.dataframe(source_df, use_container_width=True)
        else:
            st.success(f"No known Pure/View source issues on record for {policy_no}.")

    st.subheader(f"XML-layer issues found: {len(issues)}")
    if issues:
        st.dataframe(issues, use_container_width=True)
    else:
        st.success("No issues found against active XML validation rules.")

    with st.expander(f"All {len(tag_to_values)} distinct fields found in the XML"):
        st.write(sorted(tag_to_values.keys()))


mode = st.radio("Input method", ["Look up by Policy Number", "Paste XML"], horizontal=True)

if mode == "Look up by Policy Number":
    policy_input = st.text_input("Legacy Policy Number", placeholder="P00000217")
    if st.button("Load & Validate", type="primary") and policy_input.strip():
        safe = policy_input.strip().replace("'", "''")
        result = session.sql(
            f"""
            SELECT REQUEST_XML
            FROM AGGNE.DEV.PER_POLICY_MIGRATION_DCT
            WHERE TRIM(LEGACYPOLICYNUMBER) = '{safe}'
            LIMIT 1
            """
        ).to_pandas()
        if len(result) == 0:
            st.error(f"No generated XML found for policy '{policy_input.strip()}' in AGGNE.DEV.PER_POLICY_MIGRATION_DCT.")
        else:
            xml_text = result.iloc[0]["REQUEST_XML"]
            with st.expander("Raw XML (as pulled from DEV)"):
                st.code(xml_text, language="xml")
            validate_and_render(xml_text, policy_hint=policy_input.strip())

else:
    xml_text = st.text_area("Paste XML", height=320, placeholder="<location>...</location>")
    if st.button("Validate", type="primary") and xml_text.strip():
        validate_and_render(xml_text)
