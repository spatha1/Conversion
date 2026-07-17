"""Parse a Duck Creek ManuScript.getModelImage response into a flat field index.

Walks the <object>/<public> tree, accumulating each object's own `path`
attribute to build the full instance-XML path for every leaf field, and
captures type / maxLength / required / allowed-options (enum) info.

Usage: python parse_manuscript.py <manuscript_xml_path> <output_json_path>
"""
import sys
import json
from lxml import etree


def parse_manuscript(xml_path):
    parser = etree.XMLParser(huge_tree=True)
    tree = etree.parse(xml_path, parser)
    root = tree.getroot()

    model = root.find(".//model")
    if model is None:
        raise ValueError("No <model> element found -- not a getModelImageRs response?")

    fields = []

    def walk(node, path_stack, id_stack):
        tag = etree.QName(node).localname
        own_path = node.get("path")
        own_id = node.get("id")

        new_path_stack = path_stack
        new_id_stack = id_stack
        if own_path:
            new_path_stack = path_stack + [own_path]
        if own_id:
            new_id_stack = id_stack + [own_id]

        if tag == "public":
            field_type = node.get("type")
            definition = node.find("definition")
            max_length = None
            required = False
            options = []
            code_ref = None
            caption = None
            if definition is not None:
                ml = definition.find("maxLength")
                if ml is not None and ml.get("value") is not None:
                    max_length = ml.get("value")
                req = definition.find("required")
                if req is not None:
                    required = True
                opts_el = definition.find("options")
                if opts_el is not None:
                    code_ref = opts_el.get("codeRef")
                    for opt in opts_el.findall("option"):
                        if opt.get("value") is not None:
                            options.append(opt.get("value"))
                cap = definition.find("caption")
                if cap is not None and cap.get("value") is not None:
                    caption = cap.get("value")

            fields.append({
                "id": own_id,
                "full_path": "/".join(new_path_stack),
                "type": field_type,
                "maxLength": max_length,
                "required": required,
                "options": options,
                "codeRef": code_ref,
                "caption": caption,
            })
            # public nodes can still have children in some schemas; keep walking
            for child in node:
                walk(child, new_path_stack, new_id_stack)
            return

        for child in node:
            walk(child, new_path_stack, new_id_stack)

    walk(model, [], [])
    return fields


if __name__ == "__main__":
    xml_path = sys.argv[1]
    out_path = sys.argv[2]
    fields = parse_manuscript(xml_path)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(fields, f, indent=None)
    print(f"Parsed {len(fields)} public fields -> {out_path}")

    # quick stats
    with_options = sum(1 for f in fields if f["options"])
    with_coderef = sum(1 for f in fields if f["codeRef"])
    print(f"  fields with explicit <options> list: {with_options}")
    print(f"  fields with codeRef (external code table): {with_coderef}")
