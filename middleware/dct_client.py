import requests
from middleware.config import DCT

# Default urllib/requests User-Agent gets silently WAF-rejected by the DCT
# server ("Request Rejected") -- a browser-style UA is required.
_BROWSER_USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)


def post_policy(xml_payload: str, policy_number: str, env: str = "dev") -> dict:
    """POST a single policy request XML directly to the DCTServer.aspx endpoint.

    env: "dev" or "uat" -- selects DCT_DEV_URL / DCT_UAT_URL from config.
    """
    url = DCT["dev_url"] if env == "dev" else DCT["uat_url"]
    headers = {
        "Content-Type": "text/xml",
        "User-Agent": _BROWSER_USER_AGENT,
    }
    response = requests.post(
        url,
        data=xml_payload.encode("utf-8"),
        headers=headers,
        timeout=DCT["timeout"],
    )
    response.raise_for_status()
    return {"policy_number": policy_number, "status_code": response.status_code, "response": response.text}
